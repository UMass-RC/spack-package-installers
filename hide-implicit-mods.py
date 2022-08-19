#!/usr/bin/env python3

import os
import subprocess
import json

"""
hide implicit spack modules from lmod
"""

def remove_empty_lines(string: str) -> str:
    return os.linesep.join([line for line in string.splitlines() if line])

def purge_element(_list: list, elem_to_purge) -> list:
    return [elem for elem in _list if elem != elem_to_purge]

def multiline_str(*argv: str) -> str:
    argv = purge_element(argv, None)
    try:
        return '\n'.join(argv)
    except TypeError:
        bigstr = ''
        for x in argv:
            bigstr = bigstr + '\n'.join(x)
        return bigstr

def indent(string: str, n=1) -> str:
    for i in range(n):
        string = '\t' + string # add tab to first line
        string = string.replace('\n', '\n\t') # add tab to all other lines
    return string

class ShellRunner:
    """
    spawn this with a shell command, then you have access to stdout, stderr, exit code,
    along with a boolean of whether or not the command was a success (exit code 0)
    and if you use str(your_shell_runner), you get a formatted report of all the above
    """
    def __init__(self, command: str, timeout_s: int):
        self.command = command
        self.timeout_s = timeout_s
        # defined by run():
        self.stdout = None
        self.stderr = None
        self.exit_code = None
        self.success = None

    @property
    def command_report(self):
        return multiline_str(
            "command:",
            indent(self.command),
            f"exit code: {self.exit_code}",
            '',
            "stdout:",
            indent(self.stdout),
            '',
            "stderr:",
            indent(self.stderr),
        )

    def run(self):
        try:
            process = subprocess.run(
                self.command,
                capture_output=True,
                shell=True,
                timeout=self.timeout_s,
                check=False
            )
            # process.std* returns a bytes object
            self.stdout = remove_empty_lines(str(process.stdout, 'UTF-8'))
            self.stderr = remove_empty_lines(str(process.stderr, 'UTF-8'))
            self.exit_code = process.returncode
        except subprocess.TimeoutExpired as timeout_err:
            try:
                self.stdout = remove_empty_lines(str(timeout_err.stdout, 'UTF-8'))
            except TypeError:
                self.stdout = ''
            try:
                self.stderr = remove_empty_lines(str(timeout_err.stderr, 'UTF-8'))
            except TypeError:
                pass
            self.stderr = multiline_str(self.stderr, f"timeout after {self.timeout_s} seconds!")
            self.exit_code = 1
        self.success = self.exit_code == 0

    def __str__(self):
        return self.command_report

def main():
    command = ShellRunner("spack find --json --implicit target=x86_64", 300)
    command.run()
    if not command.success:
        print(command)
        return
    modules_json = command.stdout
    modules_json_parser = json.loads(modules_json)
    new_modulerc_text = ''
    modulerc_original_text = ''
    with open("/modules/modulefiles/.modulerc", 'r') as modulerc:
        modulerc_original_text = modulerc.read()
    for module in modules_json_parser:
        lmod_name = f"{module['name']}/{module['version']}"
        hide_this_module = f"hide-version {lmod_name}\n"
        if hide_this_module not in modulerc_original_text:
            new_modulerc_text = new_modulerc_text + hide_this_module
    if new_modulerc_text:
        print(new_modulerc_text)
    else:
        print('no modules to hide')
    with open("/modules/modulefiles/.modulerc", 'a') as modulerc:
        modulerc.write(new_modulerc_text)

if __name__=="__main__":
    main()