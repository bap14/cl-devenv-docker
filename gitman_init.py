#!/usr/bin/env python3

import os
import re
import sys

def clean_id(str):
  str = re.sub("^[^a-z0-9]*|[^a-z0-9]*$", "", str)
  str = str.replace(" ", "-")
  str = re.sub("[^a-z0-9_-]", "", str)
  str = str.strip()
  return str

def prompt_for_project_id():
  val = input("Project ID: ")
  val = clean_id(val)
  if len(val) == 0:
    val = prompt_for_project_id()
  return val

devenv_real_path = os.path.abspath(os.path.dirname(__file__))
project_id = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else ""

source_name = os.path.basename(os.path.dirname(os.getcwd()))
gitman_root = os.path.basename(os.path.dirname(os.path.dirname(os.path.realpath(__file__ + "../../"))))
persist_dir = gitman_root
gitman_location = os.path.basename(os.path.realpath(os.path.dirname(__file__)))
source_dir_from_persist_dir = gitman_location + "/" + source_name

print("Source Name .................. : {}".format(source_name))
print("Gitman Root .................. : {}".format(gitman_root))
print("Persistent Dir ............... : {}".format(persist_dir))
print("Gitman Location .............. : {}".format(gitman_location))
print("Source Dir from Persistent Dir : {}".format(source_dir_from_persist_dir))

if len(project_id) == 0:
  project_id = prompt_for_project_id()

project_id = clean_id(str=project_id)

print("Project ID ................... : {}".format(project_id))

# TODO: Set up the dev environment

# Link from source directory to persistent directory

# Create symlinks for things that don't change each project

# Copy sample configuration directories if they do not exist yet.

# Copy sample files to persistent directory if they do not exist yet.

# Generate database passwords if they don't exist
