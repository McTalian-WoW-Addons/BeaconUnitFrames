import os
import re

scripts_dir = os.path.dirname(os.path.abspath(__file__))
root_dir = os.path.dirname(scripts_dir)
README_md_file = os.path.join(root_dir, "README.md")
README_bb_file = os.path.join(root_dir, "README.bb")


def convert_md_line_to_bb(line):
    """Convert a single markdown line to BBCode."""
    # Remove trailing newline for processing
    line = line.rstrip("\n")

    # Handle headers
    if line.startswith("#"):
        # Count the number of # characters
        header_level = len(line) - len(line.lstrip("#"))
        header_text = line.lstrip("# ").strip()

        if header_level == 1:
            # Main title - SIZE=6
            return f"[SIZE=6]{header_text}[/SIZE]\n"
        elif header_level == 2:
            # Section headers - SIZE=5
            return f"[SIZE=5]{header_text}[/SIZE]\n"
        elif header_level == 3:
            # Subsection headers - SIZE=4
            return f"[SIZE=4]{header_text}[/SIZE]\n"
        elif header_level == 4:
            # Subsection headers - SIZE=3
            return f"[SIZE=3]{header_text}[/SIZE]\n"
        elif header_level == 5:
            # Subsection headers - SIZE=2
            return f"[SIZE=2]{header_text}[/SIZE]\n"
        else:
            # Smaller headers - just bold
            return f"[B]{header_text}[/B]\n"

    # Handle italic text (emphasis)
    if line.startswith("_") and line.endswith("_"):
        italic_text = line[1:-1]
        return f"[I]{italic_text}[/I]\n"

    # Handle bullet points
    if line.startswith("* ") or line.startswith("- "):
        return f"[*]{line[2:]}\n"

    # Handle links in markdown format [text](url)
    link_pattern = r"\[([^\]]+)\]\(([^)]+)\)"
    line = re.sub(link_pattern, r"[URL=\2]\1[/URL]", line)

    # Handle inline code with backticks
    line = re.sub(r"`([^`]+)`", r'[FONT="Courier New"]\1[/FONT]', line)

    # Handle bold text **text**
    line = re.sub(r"\*\*([^*]+)\*\*", r"[B]\1[/B]", line)

    # Handle italic text *text*
    line = re.sub(r"\*([^*]+)\*", r"[I]\1[/I]", line)

    # Return the line with newline
    return line + "\n" if line else "\n"


def convert_readme_to_bb():
    """Convert the entire README.md to BBCode and write to README.bb."""
    converted_lines = []
    in_list = False

    with open(README_md_file, "r") as f:
        lines = f.readlines()

    for i, line in enumerate(lines):
        # Check if we're starting or ending a list
        is_list_item = line.strip().startswith("* ") or line.strip().startswith("- ")
        list_char = "* " if line.strip().startswith("* ") else "- "
        next_is_list = i + 1 < len(lines) and lines[i + 1].strip().startswith(list_char)

        # Start list if this is first list item
        if is_list_item and not in_list:
            converted_lines.append("[LIST]\n")
            in_list = True

        # Convert the line
        converted_line = convert_md_line_to_bb(line)
        converted_lines.append(converted_line)

        # End list if this was last list item
        if is_list_item and not next_is_list and in_list:
            converted_lines.append("[/LIST]\n")
            in_list = False

    # Write to README.bb file
    with open(README_bb_file, "w") as f:
        f.writelines(converted_lines)

    print("Converted README.md to README.bb")
    return converted_lines


if __name__ == "__main__":
    convert_readme_to_bb()
