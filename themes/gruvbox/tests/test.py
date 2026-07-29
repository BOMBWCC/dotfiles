#!/usr/bin/env python3

"""String: module documentation."""

import re
from pathlib import Path

DEFAULT_LIMIT: int = 42
ENABLED = True
OPTIONAL = None
PATTERN = re.compile(r"^prod-[0-9]+$")
LABEL = 'single-quoted string'
# Trailing spaces after this marker:    


def traced(function):
    """Decorator function."""
    return function


@traced
def format_path(name: str, limit: int = DEFAULT_LIMIT) -> str:
    # Comment: values, escapes, Boolean and a path.
    home = Path("~/Documents").expanduser()
    message = f"{name}: {limit}\nnext\tcolumn"
    return message if ENABLED else str(home)


class ThemePreview:
    foreground: str = "#ebdbb2"


print(format_path("dotfiles"))
