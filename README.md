# GuusSummonManager Addon

A WoW Classic addon for managing multiboxing characters with warlock summoning, spawning level 60 characters, and group management for multibox crews.

## Features

### Warlock Management
- **Add/Remove warlocks** to a persistent list
- **Spawn Warlock** button - Executes: `.z spawn <warlockName>`
- **Uninvite Warlock** button - Executes: `.z uninvite <warlockName>`
- Multiple warlocks can be managed from the same window
- **Use Portal** button - Executes: `.z use` for portal interactions

### Level 60 Character Management
- **Add/Remove level 60 characters** to a persistent list
- **Spawn** button for each level 60 - Executes: `.z spawn <characterName>`
- **Uninvite** button for each level 60 - Executes: `.z uninvite <characterName>`
- Useful for spawning backup characters quickly

### General Character Management
- **Add/Remove characters** to persistent invite list
- **Invite** button for each character - Executes: `.z invite <characterName>`
- **Teleport** button for each character - Executes: `.z teleport <characterName>`
- **Uninvite** button for each character - Executes: `.z uninvite <characterName>`

## Commands

- `/gsm` - Open/Close the main window (toggle)
- `/summon` - Alias for `/gsm`
- Minimap icon - Click to toggle window visibility

## How to Use

1. **Open the window**: `/gsm`
2. **Add Warlocks**:
   - Enter warlock name in "Add warlock:" field
   - Click "Add" button
   - Use spawn/uninvite buttons as needed
3. **Add Level 60s**:
   - Enter character name in "Add level 60:" field
   - Click "Add" button
   - Use spawn/uninvite buttons as needed
4. **Add Characters for Invite**:
   - Enter character name in "Add character:" field
   - Click "Add" button
   - Use invite/teleport/uninvite buttons as needed

## Data Storage

All data is automatically saved in SavedVariables:
- **Warlocks List**: `GuusSummonManager.warlockList` 
- **Level 60 List**: `GuusSummonManager.level60List`
- **Character List**: `GuusSummonManager.characterList`
- **Configuration**: `GuusSummonManager_Config` (minimap icon position, etc.)

Data persists across game sessions and addon reloads.

## Slash Commands

Execute custom slash commands by entering them in the debug field (if enabled) or typing directly:

- `/gsm show` - Show window
- `/gsm menu` - Toggle window (same as `/gsm`)
- `/gsm list` - Display all saved data
- `/gsm debug` - Toggle debug mode for troubleshooting

## Minimap Icon

A minimap icon is available for quick window toggling. Click it to show/hide the main window.

## Multiboxing Support

Perfect for managing multibox crews:
- Keep multiple warlocks spawned for different group compositions
- Quickly spawn all your level 60s
- Easily invite entire character rosters
- All commands are frame-based for reliability across fast interactions

