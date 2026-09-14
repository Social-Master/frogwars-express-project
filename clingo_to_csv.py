import re
import csv
import argparse
import pickle
from collections import defaultdict
from flatland.envs.rail_env import RailEnvActions

def parse_clingo_output(filepath):
    """
    Parses a Clingo text output file to extract actions, positions, speeds, and energy.
    Returns a dictionary mapping: data[agent][timestep] = {properties...}
    and the maximum timestep found.
    """
    data = defaultdict(lambda: defaultdict(dict))
    max_timestep = 0
    
    with open(filepath, 'r') as f:
        content = f.read()

    # Regex pattern for position: position(agent,(y,x),timestep,direction)
    pos_pattern = re.compile(r'position\((\d+),\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)\s*,\s*(\d+)\s*,\s*([a-z]+)\)')
    for m in pos_pattern.finditer(content):
        agent, y, x, t, d = (int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4)), m.group(5))
        data[agent][t]['position'] = f"({y}, {x})"
        data[agent][t]['direction'] = d
        max_timestep = max(max_timestep, t)

    # Regex pattern for action: action(train(agent),command,timestep)
    act_pattern = re.compile(r'action\(train\((\d+)\),\s*([a-z_]+)\s*,\s*(\d+)\)')
    for m in act_pattern.finditer(content):
        agent, cmd, t = (int(m.group(1)), m.group(2), int(m.group(3)))
        data[agent][t]['given_command'] = cmd
        max_timestep = max(max_timestep, t)
        
    # Regex pattern for temp_speed: temp_speed(agent,timestep,speed)
    spd_pattern = re.compile(r'temp_speed\((\d+),\s*(\d+)\s*,\s*(\d+)\)')
    for m in spd_pattern.finditer(content):
        agent, t, spd = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
        data[agent][t]['temp_speed'] = spd
        max_timestep = max(max_timestep, t)
        
    # Regex pattern for energy: energy(agent,timestep,energy_val)
    nrg_pattern = re.compile(r'energy\((\d+),\s*(\d+)\s*,\s*(-?\d+)\)')
    for m in nrg_pattern.finditer(content):
        agent, t, nrg = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
        data[agent][t]['energy'] = nrg
        max_timestep = max(max_timestep, t)
        
    return data, max_timestep

def generate_csv_with_env(data, max_timestep, env_path, output_path, is_mixed=False):
    """
    Steps through the Flatland environment using Clingo's actions to extract 
    the live agent status, then writes the flattened timeline to a CSV.
    """
    # 1. Load the environment
    with open(env_path, "rb") as f:
        env = pickle.load(f)

    # 2. Setup mappings for Flatland interaction
    clingo_to_flatland_action = {
        "move_forward": RailEnvActions.MOVE_FORWARD,
        "move_right": RailEnvActions.MOVE_RIGHT,
        "move_left": RailEnvActions.MOVE_LEFT,
        "wait": RailEnvActions.STOP_MOVING
    }
    
    state_map = {
        0: 'waiting', 1: 'ready to depart', 2: 'malfunction (off map)', 
        3: 'moving', 4: 'stopped', 5: 'malfunction (on map)', 6: 'done'
    }

    # 3. Step through simulation and inject status into our data dictionary
    for t in range(max_timestep + 1):
        action_dict = {}
        
        # Build the action dictionary for this specific timestep
        for agent_id, agent_data in data.items():
            if t in agent_data and 'given_command' in agent_data[t]:
                cmd_str = agent_data[t]['given_command']
                if cmd_str in clingo_to_flatland_action:
                    action_dict[agent_id] = clingo_to_flatland_action[cmd_str]
        
        # Record the state for all agents at this timestep before taking the action
        for agent_id, agent_info in enumerate(env.agents):
            if t in data[agent_id]:
                data[agent_id][t]['status'] = state_map.get(agent_info.state, 'unknown')
        
        # Advance the simulation
        if action_dict:
            _, _, done, _ = env.step(action_dict)
            if done.get('__all__', False):
                break

    # 4. Flatten the enriched dictionary and sort chronologically
    rows = []
    for agent, t_data in data.items():
        for t, props in t_data.items():
            rows.append({
                'agent': agent,
                'timestep': t,
                'position': props.get('position', ''),
                'direction': props.get('direction', ''),
                'status': props.get('status', 'N/A'),
                'given_command': props.get('given_command', ''),
                'temp_speed': props.get('temp_speed', ''),
                'energy': props.get('energy', '')
            })
            
    rows.sort(key=lambda x: (x['timestep'], x['agent']))
    
    # 5. Write to CSV
    with open(output_path, 'w', newline='') as f:
        if is_mixed:
            fieldnames = ['agent', 'timestep', 'position', 'direction', 'status', 'given_command', 'temp_speed', 'energy']
        else:
            fieldnames = ['agent', 'timestep', 'position', 'direction', 'status', 'given_command']
            
        writer = csv.DictWriter(f, fieldnames=fieldnames, delimiter=';')
        writer.writeheader()
        
        for row in rows:
            filtered_row = {k: v for k, v in row.items() if k in fieldnames}
            writer.writerow(filtered_row)

def main():
    parser = argparse.ArgumentParser(description="Convert Clingo output to CSV with Flatland status validation.")
    parser.add_argument('env_file', type=str, help='Path to the Flatland environment .pkl file')
    parser.add_argument('input_file', type=str, help='Path to the Clingo output text file')
    parser.add_argument('output_file', type=str, help='Path for the destination CSV file')
    parser.add_argument('--mixed', action='store_true', help='Include temp_speed and energy columns')
    
    args = parser.parse_args()
    
    print(f"Parsing {args.input_file}...")
    parsed_data, max_t = parse_clingo_output(args.input_file)
    
    print(f"Stepping through {args.env_file} and writing data to {args.output_file}...")
    generate_csv_with_env(parsed_data, max_t, args.env_file, args.output_file, is_mixed=args.mixed)
    print("Done!")

if __name__ == "__main__":
    main()