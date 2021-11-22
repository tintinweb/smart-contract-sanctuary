// SPDX-License-Identifier: CC0-1.0

/// @title Simple map generator that spits out procedural dungeons

/*****************************************************
0000000                                        0000000
0001100  Crypts and Caverns                    0001100
0001100     9000 generative on-chain dungeons  0001100
0003300                                        0003300
*****************************************************/

pragma solidity ^0.8.0;

import { IDungeons } from './interfaces/IDungeons.sol';

contract dungeonsGenerator {

    struct EntityData {
        uint8[] x;
        uint8[] y;
        uint8[] entityType; // 0-255
    }

    struct Settings {
            uint256 size;      // Size of dungeon (e.g. 9 -> 9x9)
            uint256 length;     // Number of uint256 arrays we need
            uint256 seed;
            uint256 counter;   // Increment this to make sure we always get a unique value back from random()
    }


    struct RoomSettings {   // Helper struct so we don't run out of variables
        uint256 minRooms;
        uint256 maxRooms;
        uint256 minRoomSize;
        uint256 maxRoomSize;
    }

    struct Room {
        // Used for passing rooms around
        uint256 x;    // Top left corner x
        uint256 y;    // Top left corner y
        uint256 width;
        uint256 height;
    }

    // Constants for each direction (for caverns dungeons
    int8[] directionsX = [int8(-1), int8(0), int8(1), int8(0)];    // Left, Up, Right, Down
    int8[] directionsY = [int8(0), int8(1), int8(0), int8(-1)];    // Left, Up, Right, Down

    /** 
    * @dev Returns a series of integers with each byte representing a tile on a map starting at 0,0 
    * Example: bytes private layout = 0x11111111111111111100110110101011111111011111001111  // Placeholder dungeon layout
    */
    function getLayout(uint256 seed, uint256 size) external view returns (bytes memory, uint8) {
        Settings memory settings = Settings(size, getLength(size), seed, 0);
        uint8 structure;
        if(uint256(random(settings.seed << settings.counter++, 0, 100)) > 30) {
            // Room-based dungeon
            structure = 0;
            
            // Generate Rooms
            (Room[] memory rooms, uint256[] memory floor) = generateRooms(settings);

            // Generate Hallways
            uint256[] memory hallways = generateHallways(settings, rooms);
            
            // Combine floor and hallway tiles
            return (toBytes(addBits(floor, hallways)), structure);  
        } else {
            // Caverns-based dungeon
            structure = 1;
            uint256[] memory cavern = generateCavern(settings);
            return(toBytes(cavern), structure);
        }
    }

    /** 
    * @dev Returns a series of integers with each byte representing a tile on a map starting at 0,0 
    * Example: bytes private layout = 0x11111111111111111100110110101011111111011111001111  // Placeholder dungeon layout
    */
    function getEntities(uint256 seed, uint256 size) external view returns (uint8[] memory, uint8[] memory, uint8[] memory) {
        /* Generate entities and shove them into arrays */
        (uint256[] memory points, uint256[] memory doors) = generateEntities(seed, size);
       
        return parseEntities(size, points, doors);
    }

    /** 
    * @dev Returns a byte array with each bit representing an entity tile on a map (e.g. point or doors) starting at 0,0 
    * Example: bytes private layout = 0x11111111111111111100110110101011111111011111001111  // Placeholder dungeon layout
    */
    function getEntitiesBytes(uint256 seed, uint256 size) external view returns (bytes memory, bytes memory) {
        (uint256[] memory points, uint256[] memory doors) = generateEntities(seed, size);
        return (toBytes(points), toBytes(doors));
    }

    /** 
    * @dev Returns a byte array with each bit representing a point of interest on a map starting at 0,0 
    * Example: bytes private points = 0x11111111111111111100110110101011111111011111001111 
    */
    function getPoints(uint256 seed, uint256 size) external view returns (bytes memory, uint256 numPoints) {
        (uint256[] memory points, ) = generateEntities(seed, size);
        return (toBytes(points), count(points));
    }

    /** 
    * @dev Returns a byte array with each bit representing an door on a map starting at 0,0 
    * Example: bytes private doors = 0x11111111111111111100110110101011111111011111001111 
    */
    function getDoors(uint256 seed, uint256 size) external view returns (bytes memory, uint256 numDoors) {
        ( , uint256[] memory doors) = generateEntities(seed, size);
        return (toBytes(doors), count(doors));
    }



    /* Runs through dungeon generation and lays out entities */
    function generateEntities(uint256 seed, uint256 size) internal view returns (uint256[] memory, uint256[] memory ) {
        /* Generate base info */
        Settings memory settings = Settings(size, getLength(size), seed, 0);

        if(uint256(random(settings.seed + settings.counter++, 0, 100)) > 30) {
            // Generate Rooms (where we can place points of interest)
            (Room[] memory rooms, uint256[] memory floor) = generateRooms(settings);
            
            // Generate Hallways
            uint256[] memory hallways = generateHallways(settings, rooms);
            
            // Remove floor tiles from hallways: hallways & ~(floor); 
            hallways = subtractBits(hallways, floor);

            // Generate entities
            // Make sure we don't process an empty array (rooms will never be empty but hallways can)
            uint256[] memory hallwayPoints = count(hallways) > 0 ? generatePoints(settings, hallways, 40 / sqrt(count(hallways))) : new uint256[](hallways.length);    // Return empty map if hallways are empty
            return(generatePoints(settings, floor, 12 / sqrt(settings.size - 6)), hallwayPoints); 
        } else {
            // Caverns-based dungeon 
            uint256[] memory cavern = generateCavern(settings);
            uint256 numTiles = count(cavern);

            // Feed it to doors and points (because everything is a hallway)
            uint256[] memory points = generatePoints(settings, cavern, 12 / sqrt(numTiles - 6));
            uint256[] memory doors = generatePoints(settings, cavern, 40 / sqrt(numTiles));

            subtractBits(points, doors);    // De-dupe and favor points over doors: points & ~(door);
            return(points, doors);
        }
    }

    
    function generateRooms(Settings memory settings) internal pure returns(Room[] memory, uint256[] memory) {
        // Setup constraints for creating rooms (e.g. minRoomSize)

        RoomSettings memory roomSettings = RoomSettings(settings.size / 3, settings.size / 1, 2, settings.size / 3);
        
        uint256[] memory floor = new uint256[](settings.length); // For this implementation we only need a length of 3
        
        // How many rooms should we create?
        uint256 numRooms = uint256(random(settings.seed + settings.counter++, roomSettings.minRooms, roomSettings.maxRooms));

        Room[] memory rooms = new Room[](numRooms);

        uint256 safetyCheck = 256;   // Safety check in case we get stuck trying to place un placeable rooms

        while(numRooms > 0) {
            bool valid = true;     // Is this a valid room placement? (default to true to save calculations below)
            Room memory current = Room(0, 0, uint256(random(settings.seed + settings.counter++, roomSettings.minRoomSize, roomSettings.maxRoomSize)), uint8(random(settings.seed + settings.counter++, roomSettings.minRoomSize, roomSettings.maxRoomSize)));
            // Pick a random width and height for the room

            // Pick a random location for the room (we only need top/left because we get bottom right from w/h)
            current.x = uint256(random(settings.seed + settings.counter++, 1, settings.size-1 - current.width));
            current.y = uint256(random(settings.seed + settings.counter++, 1, settings.size-1 - current.height));

            if(rooms[0].x != 0) {    // We can't check for non-empty array in Solidity so this is the closest thing we can check
                // There is at least one room so we need to check against current list of rooms to make sure there's no overlap

                for(uint256 i = 0; i < rooms.length - numRooms; i++) {
                    // Check if the current position fits within an existing room
                    if(rooms[i].x-1 < current.x+current.width && rooms[i].x+rooms[i].width+1 > current.x && rooms[i].y-1 < current.x+current.height && rooms[i].y+rooms[i].height > current.y) {
                        valid = false;   // We've detected overlap, flag so we don't place a room here
                    }
                }
            }

            // We found a room without overlap, let's place it!
            if(valid) {
                rooms[rooms.length - numRooms] = current;
                // Update floor tiles
                for(uint256 y = current.y; y < current.y+current.height; y++) {
                    for(uint256 x = current.x; x < current.x+current.width; x++) {
                        floor = setBit(floor, y*settings.size+x);   // Populate each bit of the room (from room[i]y -> room[i]y+h) to 1
                    }
                }

                numRooms--;
            }

            if(safetyCheck == 0) {  // Make sure we don't enter an infinite loop trying to place rooms w/ no space
                break;
            }

            safetyCheck--;  

        }

        return (rooms, floor);
    }

    function generateCavern(Settings memory settings) internal view returns (uint256[] memory) {
    // Tunneling - creates caves, mountains, etc.
        uint256[] memory cavern = new uint256[](settings.length); // For this app we only need a length of 2;  // Start with all walls (blank map)
        uint256 lastDirection;
        uint256 nextDirection;

        uint256 x;
        uint256 y;

        // Cut out holes
        uint256 holes = settings.size / 2;

        for(uint256 i = 0; i < holes; i++) {
            // Pick a randaom starting location
            x = uint256(random(settings.seed << settings.counter++, 0, settings.size));
            y = uint256(random(settings.seed << settings.counter++, 0, settings.size));
        
            do {
                // Cut current spot out of walls
                setBit(cavern, y*settings.size + x);

                if(lastDirection == 0) {
                    // This is our first time through, pick a random direction
                    nextDirection = uint256(random(settings.seed << settings.counter++, 1, 4));
                    lastDirection = nextDirection;
                } else {
                    // We have a last direction so use weighted probability to determine where to go next
                    uint256 directionSeed = uint256(random(settings.seed << settings.counter++, 0, 100));
                    
                    if(directionSeed <= 25) {
                        // Turn right
                        if(lastDirection == 3) {
                            nextDirection = 0;  // (go back to first direction in our aray to avoid overflows)
                        } else {
                            nextDirection = lastDirection + 1;
                        }
                    } else if(directionSeed <= 50) {
                        // Turn left
                        if(lastDirection == 0) {
                            nextDirection = 3;  // (go to the last direction in our array to avoid overflow)
                        } else {
                            nextDirection = lastDirection - 1;
                        }
                    } else {
                        // Keep moving forward in the same direction
                        nextDirection = lastDirection;
                    } 
                }
   
                // if((x != 0 && nextDirection != 0) || (y != 0 && nextDirection != 3) || (x != settings.size && nextDirection != 1) || (y != settings.size && nextDirection != 1)) {
                    x = getDirection(x, directionsX[nextDirection]);
                    y = getDirection(y, directionsY[nextDirection]);
                // } 
            } while (x > 0 && y > 0 && x < settings.size && y < settings.size); // Stop when we hit an edge

        }

        return(cavern);
    }

    function generateHallways(Settings memory settings, Room[] memory rooms) internal pure returns(uint256[] memory) {
    // Connect each room with a hallway so we don't have hanging/floating rooms
        // Number of hallways is always 1 less than number of rooms
        uint256[] memory hallTiles = new uint256[](settings.length); // For this app we only need a length of 2;

        // Only place hallways if we have more than one         
        if(rooms.length > 1) {
            
            // Set first room as 'previous' (because we have to connect two rooms together)
            uint256 previousX = rooms[0].x + (rooms[0].width / 2);
            uint256 previousY = rooms[0].y + (rooms[0].height / 2);

            for(uint256 i = 1; i < rooms.length; i++) {
                uint256 currentX = rooms[i].x + (rooms[i].width / 2);
                uint256 currentY = rooms[i].y + (rooms[i].height / 2);

                // Figure out what type of hallway to place
                if(currentX == previousX) {
                    // Rooms are lined up, make a vertical straight hallway
                    hallTiles = vHallway(settings.size, currentY, previousY, previousX, hallTiles);
                } else if(currentY == previousY) {
                    // Rooms are lined up, make a horizontal straight hallway
                    hallTiles = hHallway(settings.size, currentX, previousX, previousY, hallTiles);
                } else {
                    // Rooms aren't lined up so we need to draw two hallways
                    // Flip a coin to decide which we do first

                    // We need two hallways (w/ right angle)
                    if(random(settings.seed + settings.counter++, 1, 2) == 2) {
                        hallTiles = hHallway(settings.size, currentX, previousX, previousY, hallTiles);
                        hallTiles = vHallway(settings.size, previousY, currentY, currentX, hallTiles);
                    } else {
                        // Vertical first
                        hallTiles = vHallway(settings.size, currentY, previousY, previousX, hallTiles);
                        hallTiles = hHallway(settings.size, previousX, currentX, currentY, hallTiles);
                    }
                }

                previousX = currentX; // Process the next room
                previousY = currentY;
            }
        }

        return hallTiles;
    }

    function vHallway(uint256 size, uint256 y1, uint256 y2, uint256 x, uint256[] memory hallTiles) internal pure returns(uint256[] memory) {
        // Draw a vertical tunnel from the center of one room to another (so x is always the same)
        uint256 min = minimum(y1, y2);
        uint256 max = maximum(y1, y2);

        for(uint256 y = min; y < max; y++) {
            // Place individual tiles
            hallTiles = setBit(hallTiles, (y*size)+x);      // Place a '0' for each hallway tile.
        }
        
        return hallTiles;
    }

     function hHallway(uint256 size, uint256 x1, uint256 x2, uint256 y, uint256[] memory hallTiles) internal pure returns(uint256[] memory ) {
        // Draw a horizontal tunnel from the center of one room to another (so y is always the same)
        uint256 min = minimum(x1, x2);
        uint256 max = maximum(x1, x2);

        for(uint256 x = min; x < max; x++) {
            // Place individual tiles
            hallTiles = setBit(hallTiles, (y*size)+x);      // Place a '0' for each hallway tile.
        }
        
        return hallTiles;
    }

    function generatePoints(Settings memory settings, uint256[] memory map, uint256 probability) internal pure returns(uint256[] memory) {
        uint256[] memory points = new uint256[](settings.length);
        
        // Calculate max points based on floor tiles
        uint256 prob = random(settings.seed + settings.counter++, 0, probability);

        if(prob == 0) {
            prob = 1;   // Fix to avoid zero probability because solidity rounds down, not up so we do
        }
        
        uint256 counter = 0;
        // Loop through each tile on the map
        while(counter < settings.size ** 2) {
            // Check if this is a floor tile (vs a wall)
            if(getBit(map, counter) == 1) {
                uint256 rand = random(settings.seed + settings.counter++, 0, 100);
                if(rand <= prob) {
                    points = setBit(points, counter);
                }
            }
            counter++;
        }

        return(points);
    }

    function countEntities(uint8[] memory entities) external pure returns(uint256, uint256) {
        uint256 points = 0;
        uint256 doors = 0;
        for(uint256 i = 0; i < entities.length; i++) {
            if(entities[i] == 0) {
                points++;
            } else {
                doors++;
            }
        }
        return(points, doors);
    }

    function parseEntities(uint256 size, uint256[] memory points, uint256[] memory doors) private pure returns(uint8[] memory, uint8[] memory, uint8[] memory) {
        // Iterate through each map and returns an array for each entitiy type.
        // 0 - Doors
        // 1 - Points
        uint256 entityCount = count(doors)+count(points);
        uint8[] memory x = new uint8[](entityCount);
        uint8[] memory y = new uint8[](entityCount);
        uint8[] memory entityType = new uint8[](entityCount);

        uint256 counter = 0;

        // Shove points into arrays so we can return them
        for(uint256 _y = 0; _y < size; _y++) {
            for(uint256 _x = 0; _x < size; _x++) {
                if(getBit(doors, counter) == 1) {
                    x[entityCount-1] = uint8(_x);
                    y[entityCount-1] = uint8(_y);
                    entityType[entityCount-1] = 0;   // Hardcoded for doors
                    entityCount--;
                }

                if(getBit(points, counter) == 1) {
                    x[entityCount-1] = uint8(_x);
                    y[entityCount-1] = uint8(_y);
                    entityType[entityCount-1] = 1;   // Hardcoded for points
                    entityCount--;
                }

                counter++;
            }
        }

        return(x, y, entityType);
    }
    

    /* Utility Functions */
    /* Bitwise Helper Functions (credit: cjpais) */
    function getBit(uint256[] memory map, uint256 position) internal pure returns(uint256) {
    // Returns whether a bit is set or off at a given position in our map
        (uint256 quotient, uint256 remainder) = getDivided(position, 256);
        require(position <= 255 + (quotient * 256));
        return (map[quotient] >> (255 - remainder)) & 1;
    }

    function setBit(uint256[] memory map, uint256 position) internal pure returns(uint256[] memory) {
    // Writes a wall bit (1) at a given position and returns the updated map
        (uint256 quotient, uint256 remainder) = getDivided(position, 256);
        require(position <= 255 + (quotient * 256));
        map[quotient] = map[quotient] | (1 << (255 - remainder));

        return (map);
    }

    function addBits(uint256[] memory first, uint256[] memory second) internal pure returns(uint256[] memory) {
    // Combines two maps by 'OR'ing the two together
        require(first.length == second.length);

        for (uint256 i = 0; i < first.length; i++) {
            first[i] = first[i] | second[i];
        }

        return first;
    }

    function subtractBits(uint256[] memory first, uint256[] memory second) internal pure returns(uint256[] memory) {
    // Removes the second map from the first by 'AND'ing the two together
        require(first.length == second.length);

        for (uint256 i = 0; i < first.length; i++) {
            first[i] = first[i] & ~(second[i]);
        }

        return first;
    }

    function toBytes(uint256[] memory map) internal pure returns (bytes memory) {
    // Combines two maps into a single bytes array to be returned 
        bytes memory output;

        for (uint256 i = 0; i < map.length; i++) {
            output = abi.encodePacked(output, map[i]);
        }

        return output;
    } 

    function count(uint256[] memory map) internal pure returns(uint256) {
    // Function to count the total number of set bits in input (similar to an array .length)
    // Uses Brian Kernighans algorithm

        // Make a copy of the map so we don't clobber the original
        uint256 curr;
        uint256 result = 0;

        for (uint256 i = 0; i < map.length; i++) {
            curr = map[i];

            while (curr != 0) {
                curr = curr & (curr - 1);
                result++;
            }
        }

        return result;
    }

    function getDivided(uint256 numerator, uint256 denominator) public pure returns (uint256 quotient, uint256 remainder) {
    // Divide - Return quotient and remainder
        require(denominator > 0);
        quotient = numerator / denominator;
        remainder = numerator - denominator * quotient;
    }

    /* Dungeon directions */
    function getDirection(uint256 pos, int8 direction) internal pure returns (uint256) {
    // Helper function to map directions (because  uint256/int8 can't be added / subtracted)
        if(direction == 0) {
            return(pos);
        } else if(direction == 1) {
            return(pos+1);
        } else {    // (direction == -1)
            if(pos == 0) {
                return(0);  // Fix in case we try to move outside the bounds
            }
            return(pos-1);
        }
    }

    function getLength(uint256 size) public pure returns (uint256) {
    // Determine how many uint256's we need for our array
        return ((size ** 2) / 256) + 1;    // Always add 1 because solidity rounds down
    }

    /*  RNG and Math Helper Functions */
    function random(uint256 input, uint256 min, uint256 max) internal pure returns (uint256) {
    // Returns a random (deterministic) seed between 0-range based on an arbitrary set of inputs
        uint256 num;

        if(max != min) {
            num = max - min;
        } else {
            // max/min being the same causes modulo by zero error 
            num = 1;
        }
        
        uint256 output = uint256(keccak256(abi.encodePacked(input))) % (num) + min;
        return output;
    }

    function maximum(uint256 one, uint256 two) internal pure returns(uint256 max) {
    // Return the larger of two numbers
        if(one > two) {
            return one;
        } else if(one <= two) {
            return two;
        }
    }
    function minimum(uint256 one, uint256 two) internal pure returns(uint256 min) {
    // Return the smaller of two numbers
        if(one > two) {
            return two;
        } else if(one <= two) {
            return one;
        }
    }

    function abs(uint256 one, uint256 two) internal pure returns(uint256 result) {
    // Returns the absolute value of subtracting two numbers
        if(one >= two) {
            return(one - two);
        } else {
            return(two - one);
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
    // Returns the square root of a number
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Crypts and Caverns

/*****************************************************
0000000                                        0000000
0001100  Crypts and Caverns                    0001100
0001100     9000 generative on-chain dungeons  0001100
0003300                                        0003300
*****************************************************/

pragma solidity ^0.8.0;

interface IDungeons {
    struct Dungeon {
        uint8 size;
        uint8 environment;
        uint8 structure;  // crypt or cavern
        uint8 legendary;
        bytes layout;
        EntityData entities;
        string affinity;
        string dungeonName;
    }

    struct EntityData {
        uint8[] x;
        uint8[] y;
        uint8[] entityType;
    }

    function claim(uint256 tokenId) external payable;
    function claimMany(uint256[] memory tokenArray) external payable;
    function ownerClaim(uint256 tokenId) external payable;
    function mint() external payable;
    function openClaim() external;
    function withdraw(address payable recipient, uint256 amount) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getLayout(uint256 tokenId) external view returns (bytes memory);
    function getSize(uint256 tokenId) external view returns (uint8);
    function getEntities(uint256 tokenId) external view returns (uint8[] memory, uint8[] memory, uint8[] memory);
    function getEnvironment(uint256 tokenId) external view returns (uint8);
    function getName(uint256 tokenId) external view returns (string memory);
    function getNumPoints(uint256 tokenId) external view returns (uint256);
    function getNumDoors(uint256 tokenId) external view returns (uint256);
    function getSvg(uint256 tokenId) external view returns (string memory);
}