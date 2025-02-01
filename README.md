# LibraryMixin

**LibraryMixin** is an enhanced library versioning and management system for World of Warcraft addons. It allows developers to register, retrieve, update, lock, and remove libraries with ease. With additional features such as dependency management and optional callback integration, LibraryMixin offers a modern approach compared to legacy systems.

## Features

- **Version Control:** Libraries are only updated if the new version is higher (or force-updated).
- **Protected Names:** Reserved names ensure there is no conflict with internal methods.
- **Library Management:** Check existence, list, remove, and update libraries effortlessly.
- **Locking Mechanism:** Lock libraries to prevent accidental updates or removals.
- **Dependency Management:** Register and verify dependencies between libraries.
- **Optional Callbacks:** Integrate with external callback systems if needed.

## Installation

1. **Download or clone the repository.**
2. **Place the `LibraryMixin` folder in your World of Warcraft `Interface/AddOns/` directory.**
3. **Restart World of Warcraft or reload the UI.**
