# Node-OS
A feature packed ComputerCraft OS with smart homes/bases, hive minds, and robot swarms in mind.
While everything is working so far, I still plan to make a better UI.
Screenshots soon.

More Details later on usage, I don't have the time at the moment sadly.

## Features:
Probably will forget alot here. I have worked on this for a while before saving this on github.
  * Tons of advanced features, and configurations. 
  * Very lag friendly.
  * Automate alot of things in minecraft with all the rich data. Make a coal robot, or a iron mining robot to scan and mine for iron, and remotely control it with node.os
  * You can install easily with installToDisk, or run it at boot from a disk or pocket pc in a disk drive.
  * In game update system from master to clients.
  * Startup scripts, and drivers load at boot to support any perihperal and add functionality.
  * Password protected logins.
  * File shares.
  * Computer Groups / Organizational Units
  * Networking and discovery commands.
  * Device pairing.
  * Remote messaging.
  * Supports plug and play peripherals.
  * Supports speaker peripheral.
  * Supports all monitors.
  * If you have GPS satelites, will automatically track position.
  * All map data gathered by users are shared to all suers meaning lots of map data can be gathered. (Try connecting plethora sensors to give your nodeos network more data about the world around it.)
  * Built in mapping and and entity tracking systems.
  * Master server stores a master hive map data that will update from users, and moded peripherals.
  * Store nav points, and navigate back to them.
  * Share nav points with friends!
  * Nav to a friend, or a mob if your map data contains it. (If using plethora sensor it will keep track of mobs.)
  * Navigate to scanned blocks in map data, like iron, or daimonds $$$. (If using plethora scanner it will automatically start building map data when it is connected)
  * Distance aware remote commands. (IE: "!<Computer ID> command" or "! command" for closest pc.)
  * In/out of range redstone triggers. (IE: A base door that recognizes you and if paired will open the door when close, or run a script.)
  * Remote redstone commands like "!open/on/start/toggle/pulse 2" and far more in depth usage I can't cover here.
  * Remote Display to other computers monitors to show screens to friends.
  * (WIP) Slave Bots. Auto gathering/mining robots, 3d printer swarms, delivery/fetch drones, or do anything for you. got somewhere, upload a virus, blow up the base and escape! with simple command syntax.


## Mod Support:
  * SG-Craft
    * Dial, save, and share Stargate destinations between users.
    * Or automatically give it to a user on approach using clever scripting.
    * Remotely or locally get the status of the stargate.
    * Trigger commands for the stargate driver on approach events.
    * Automatically open iris if computer is paired.
    * Could probably make a malp out of a turtle that will auto dial and test places, and return if players or mobs or resources are around.

  * Plethora
    * AR Glasses display NodeOs hud, and Navigation. (More helpful overlay data comming soon.)
    * Sensors when conencted will seemelesly stream entity data to the nodeOs networks hive map data.
    * Scanners when connected will additionally stream block data, 8 blocks, in all directions, to the hive map data.
    * If using the kinetic augment you can use a command to take control of your body to run to a destination location, resource, player.
    * (WIP) Remote control other players or mobs using node os, or make a auto defence system to take over your body when in danger.

  * Web Displays (Broken on latest)
  * If you have plethora and a block scanner, entity scanner, or are a turtle, AND you have loc, you will be mapping the world around you.

## Commands:
  * help
  * There are alot of commands, can't put them here for now but will write this in the future.
