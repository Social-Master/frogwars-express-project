import os
import re
import time
import pickle
import imageio.v2 as imageio
from collections import defaultdict
from argparse import ArgumentParser

from flatland.envs.rail_env import RailEnvActions
from flatland.utils.rendertools import RenderTool
from PIL import Image, ImageDraw, ImageFont

class OutputLogManager():
    def __init__(self) -> None:
        self.logs = []

    def add(self,info) -> None:
        """ add info from a timestep to the log """
        self.logs.append(info)

    def save(self, filepath) -> None:
        """ save output log to local drive """
        with open(filepath, "w") as f:
            # ADDED: 'energy' to the end of the CSV header
            f.write("agent;timestep;position;direction;status;given_command;energy\n")
            for log in self.logs:
                f.write(log)

def parse_clingo_output(filepath):
    """
    Parses a Clingo text output file to extract actions and energy per timestep.
    Returns dictionaries mapping timestep -> {agent_id: value}
    """
    action_map = {
        "move_forward": RailEnvActions.MOVE_FORWARD,
        "move_right": RailEnvActions.MOVE_RIGHT,
        "move_left": RailEnvActions.MOVE_LEFT,
        "wait": RailEnvActions.STOP_MOVING
    }
    
    actions_by_timestep = defaultdict(dict)
    energy_by_timestep = defaultdict(dict) # ADDED: dictionary for energy
    max_timestep = 0
    
    with open(filepath, 'r') as f:
        content = f.read()
        
    # Regex to capture: action(train(ID),action_name,timestep)
    pattern = r"action\(train\((\d+)\),([a-z_]+),(\d+)\)"
    matches = re.findall(pattern, content)
    
    for agent_id, action_str, timestep in matches:
        t = int(timestep)
        a_id = int(agent_id)
        
        if action_str in action_map:
            actions_by_timestep[t][a_id] = action_map[action_str]
            max_timestep = max(max_timestep, t)

    # ADDED: Regex to capture: energy(ID,timestep,amount)
    energy_pattern = r"energy\((\d+),(\d+),(\d+)\)"
    energy_matches = re.findall(energy_pattern, content)
    
    for agent_id, timestep, energy_val in energy_matches:
        t = int(timestep)
        a_id = int(agent_id)
        e_val = int(energy_val)
        energy_by_timestep[t][a_id] = e_val
        max_timestep = max(max_timestep, t)
            
    return actions_by_timestep, energy_by_timestep, max_timestep # ADDED: return energy dict


def main():
    parser = ArgumentParser(description="Replay a pure Clingo output in Flatland to generate a GIF and CSV paths.")
    parser.add_argument('env', type=str, help='Path to the Flatland environment .pkl file')
    parser.add_argument('solution', type=str, help='Path to the Clingo solution text file')
    args = parser.parse_args()

    # 1. Parse the actions and energy from the text file
    print(f"Parsing actions and energy from {args.solution}...")
    actions_by_timestep, energy_by_timestep, max_timestep = parse_clingo_output(args.solution)
    print(f"Found events up to timestep {max_timestep}.")

    # 2. Load the environment
    print(f"Loading environment from {args.env}...")
    with open(args.env, "rb") as f:
        env = pickle.load(f)

    # 3. Setup the renderer
    env_renderer = RenderTool(env, gl="PILSVG")
    env_renderer.reset()
    
    os.makedirs("tmp/frames", exist_ok=True)
    images = []

    log = OutputLogManager()
    state_map = {0:'waiting', 1:'ready to depart', 2:'malfunction (off map)', 3:'moving', 4:'stopped', 5:'malfunction (on map)', 6:'done'}
    dir_map = {0:'n', 1:'e', 2:'s', 3:'w'}
    rail_action_to_str = {
        RailEnvActions.MOVE_LEFT: 'move_left',
        RailEnvActions.MOVE_FORWARD: 'move_forward',
        RailEnvActions.MOVE_RIGHT: 'move_right',
        RailEnvActions.STOP_MOVING: 'wait'
    }

    # 4. Step through the environment and render
    print("Simulating and rendering frames...")
    for t in range(max_timestep + 1):
        action_dict = actions_by_timestep.get(t, {})
        energy_dict = energy_by_timestep.get(t, {}) # ADDED: pull energy for this timestep
        
        for a, action in action_dict.items():
            pos = env.agents[a].position
            direction = dir_map.get(env.agents[a].direction, str(env.agents[a].direction))
            state = state_map.get(env.agents[a].state, str(env.agents[a].state))
            cmd = rail_action_to_str.get(action, "wait")
            
            # ADDED: lookup energy, default to 0 if not present in the output
            energy_val = energy_dict.get(a, 0) 
            
            # ADDED: append energy_val to the CSV row
            log.add(f'{a};{t};{pos};{direction};{state};{cmd};{energy_val}\n')

        _, _, done, _ = env.step(action_dict)
        
        # Render image
        filename = f"tmp/frames/replay_frame_{t:04d}.png"
        env_renderer.render_env(show=False, show_observations=False, show_predictions=False)
        env_renderer.gl.save_image(filename)
        
        with Image.open(filename) as img:
            draw = ImageDraw.Draw(img)
            padding = 10
            font_size = int(min(img.width, img.height) * 0.10)
            try:
                font = ImageFont.truetype("modules/LiberationMono-Regular.ttf", font_size)
            except IOError:
                font = ImageFont.load_default()
            
            text = f"{t}"
            size = font.getbbox(text)
            text_width = size[2] - size[0]
            text_position = (img.width - text_width - padding, padding)
            
            x, y = text_position
            border_color = "black"
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)]:
                draw.text((x + dx, y + dy), text, fill=border_color, font=font)
            
            draw.text(text_position, text, fill="red", font=font)
            img.save(filename)

        images.append(imageio.imread(filename))

        if done['__all__']:
            print(f"All agents reached their targets! Ending simulation early at timestep {t}.")
            break

    # 5. Compile into a GIF and save CSV
    stamp = int(time.time())
    out_dir = f"output/replay_{stamp}"
    os.makedirs(out_dir, exist_ok=True)
    
    gif_path = f"{out_dir}/animation.gif"
    print(f"Saving GIF to {gif_path}...")
    imageio.mimsave(gif_path, images, format='GIF', loop=0, duration=240)
    
    csv_path = f"{out_dir}/paths.csv"
    print(f"Saving paths CSV to {csv_path}...")
    log.save(csv_path)
    
    env_renderer.close_window()
    print("Done!")

if __name__ == "__main__":
    main()