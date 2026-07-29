//! Documentation comment for the module.

use std::collections::HashMap;

const DEFAULT_LIMIT: usize = 42;

#[derive(Debug, Clone)]
struct Theme<'a> {
    name: &'a str,
    enabled: bool,
}

impl<'a> Theme<'a> {
    pub fn new(name: &'a str) -> Self {
        Self {
            name,
            enabled: true,
        }
    }
}

fn main() {
    // Comment: types, numbers, strings, namespace and macro.
    let theme = Theme::new("gruvbox\ndark");
    let mut colors: HashMap<&str, &str> = HashMap::new();
    colors.insert("comment", "#928374");

    if theme.enabled && colors.len() < DEFAULT_LIMIT {
        println!("{theme:?}");
    }
}
