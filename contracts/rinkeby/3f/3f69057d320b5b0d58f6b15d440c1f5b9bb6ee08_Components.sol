// SPDX-License-Identifier: Unlicense

/*

    Components.sol
    
    This is a utility contract to make it easier for other
    contracts to work with Loot properties.
    
    Call weaponComponents(), clothesComponents(), etc. to get 
    an array of attributes that correspond to the item. 
    
    The return format is:
    
    uint8[5] =>
        [0] = Item ID
        [1] = Suffix ID (0 for none)
        [2] = Name Prefix ID (0 for none)
        [3] = Name Suffix ID (0 for none)
        [4] = Augmentation (0 = false, 1 = true)
    
    See the item and attribute tables below for corresponding IDs.

*/

pragma solidity ^0.8.4;

import './Ownable.sol';

import { toString } from './MetadataUtils.sol';

library ComponentTypes {
    uint8 internal constant WEAPON = 0x0;
    uint8 internal constant CLOTHES = 0x1;
    uint8 internal constant VEHICLE = 0x2;
    uint8 internal constant WAIST = 0x3;
    uint8 internal constant FOOT = 0x4;
    uint8 internal constant HAND = 0x5;
    uint8 internal constant DRUGS = 0x6;
    uint8 internal constant NECK = 0x7;
    uint8 internal constant RING = 0x8;
    uint8 internal constant ACCESSORY = 0x9;
    uint8 internal constant NAME_PREFIX = 0xa;
    uint8 internal constant NAME_SUFFIX = 0xb;
    uint8 internal constant SUFFIX = 0xc;
}

contract Components is Ownable {
    string constant UnexpectedComponent = 'unexpected component type';

    string[10] internal slots = [
        'Weapon',
        'Clothes',
        'Vehicle',
        'Waist',
        'Foot',
        'Hand',
        'Drugs',
        'Neck',
        'Ring',
        'Accessory'
    ];

    string[9] internal slotKeys = ['WEAPON', 'CLOTHES', 'VEHICLE', 'WAIST', 'FOOT', 'HAND', 'DRUGS', 'NECK', 'RING'];
    uint256[9] internal slotLens = [18, 20, 17, 16, 17, 14, 19, 3, 7];

    string[] public weapons = [
        'Pocket Knife', // 0
        'Chain', // 1
        'Knife', // 2
        'Crowbar', // 3
        'Handgun', // 4
        'AK47', // 5
        'Shovel', // 6
        'Baseball Bat', // 7
        'Tire Iron', // 8
        'Police Baton', // 9
        'Pepper Spray', // 10
        'Razor Blade', // 11
        'Chain', // 12
        'Taser', // 13
        'Brass Knuckles', // 14
        'Shotgun', // 15
        'Glock', // 16
        'Uzi' // 17
    ];

    string[] public clothes = [
        'White T Shirt', // 0
        'Black T Shirt', // 1
        'White Hoodie', // 2
        'Black Hoodie', // 3
        'Bulletproof Vest', // 4
        '3 Piece Suit', // 5
        'Checkered Shirt', // 6
        'Bikini', // 7
        'Golden Shirt', // 8
        'Leather Vest', // 9
        'Blood Stained Shirt', // 10
        'Police Uniform', // 11
        'Combat Jacket', // 12
        'Basketball Jersey', // 13
        'Track Suit', // 14
        'Trenchcoat', // 15
        'White Tank Top', // 16
        'Black Tank Top', // 17
        'Shirtless', // 18
        'Naked' // 19
    ];

    string[] public vehicle = [
        'Dodge', // 0
        'Porsche', // 1
        'Tricycle', // 2
        'Scooter', // 3
        'ATV', // 4
        'Push Bike', // 5
        'Electric Scooter', // 6
        'Golf Cart', // 7
        'Chopper', // 8
        'Rollerblades', // 9
        'Lowrider', // 10
        'Camper', // 11
        'Rolls Royce', // 12
        'BMW M3', // 13
        'Bike', // 14
        'C63 AMG', // 15
        'G Wagon' // 16
    ];

    string[] public waistArmor = [
        'Gucci Belt', // 0
        'Versace Belt', // 1
        'Studded Belt', // 2
        'Taser Holster', // 3
        'Concealed Holster', // 4
        'Diamond Belt', // 5
        'D Ring Belt', // 6
        'Suspenders', // 7
        'Military Belt', // 8
        'Metal Belt', // 9
        'Pistol Holster', // 10
        'SMG Holster', // 11
        'Knife Holster', // 12
        'Laces', // 13
        'Sash', // 14
        'Fanny Pack' // 15
    ];

    string[] public footArmor = [
        'Black Air Force 1s', // 0
        'White Forces', // 1
        'Air Jordan 1 Chicagos', // 2
        'Gucci Tennis 84', // 3
        'Air Max 95', // 4
        'Timberlands', // 5
        'Reebok Classics', // 6
        'Flip Flops', // 7
        'Nike Cortez', // 8
        'Dress Shoes', // 9
        'Converse All Stars', // 10
        'White Slippers', // 11
        'Gucci Slides', // 12
        'Alligator Dress Shoes', // 13
        'Socks', // 14
        'Open Toe Sandals', // 15
        'Barefoot' // 16
    ];

    string[] public handArmor = [
        'Rubber Gloves', // 0
        'Baseball Gloves', // 1
        'Boxing Gloves', // 2
        'MMA Wraps', // 3
        'Winter Gloves', // 4
        'Nitrile Gloves', // 5
        'Studded Leather Gloves', // 6
        'Combat Gloves', // 7
        'Leather Gloves', // 8
        'White Gloves', // 9
        'Black Gloves', // 10
        'Kevlar Gloves', // 11
        'Surgical Gloves', // 12
        'Fingerless Gloves' // 13
    ];

    string[] public necklaces = [
        'Bronze Chain', // 0
        'Silver Chain', // 1
        'Gold Chain' // 2
    ];

    string[] public rings = [
        'Gold Ring', // 0
        'Silver Ring', // 1
        'Diamond Ring', // 2
        'Platinum Ring', // 3
        'Titanium Ring', // 4
        'Pinky Ring', // 5
        'Thumb Ring' // 6
    ];

    string[] public drugs = [
        'Weed', // 0
        'Cocaine', // 1
        'Ludes', // 2
        'Acid', // 3
        'Speed', // 4
        'Heroin', // 5
        'Oxycontin', // 6
        'Zoloft', // 7
        'Fentanyl', // 8
        'Krokodil', // 9
        'Coke', // 10
        'Crack', // 11
        'PCP', // 12
        'LSD', // 13
        'Shrooms', // 14
        'Soma', // 15
        'Xanax', // 16
        'Molly', // 17
        'Adderall' // 18
    ];

    string[] public accessories;

    string[] public suffixes = [
        // <no suffix>          // 0
        'from the Bayou', // 1
        'from Atlanta', // 2
        'from Compton', // 3
        'from Oakland', // 4
        'from SOMA', // 5
        'from Hong Kong', // 6
        'from London', // 7
        'from Chicago', // 8
        'from Brooklyn', // 9
        'from Detroit', // 10
        'from Mob Town', // 11
        'from Murdertown', // 12
        'from Sin City', // 13
        'from Big Smoke', // 14
        'from the Backwoods', // 15
        'from the Big Easy', // 16
        'from Queens', // 17
        'from BedStuy', // 18
        'from Buffalo' // 19
    ];
    uint256 private constant suffixesLength = 19;

    string[] public namePrefixes = [
        // <no name>            // 0
        'OG', // 1
        'King of the Street', // 2
        'Cop Killer', // 3
        'Blasta', // 4
        'Lil', // 5
        'Big', // 6
        'Tiny', // 7
        'Playboi', // 8
        'Snitch boi', // 9
        'Kingpin', // 10
        'Father of the Game', // 11
        'Son of the Game', // 12
        'Loose Trigger Finger', // 13
        'Slum Prince', // 14
        'Corpse', // 15
        'Mother of the Game', // 16
        'Daughter of the Game', // 17
        'Slum Princess', // 18
        'Da', // 19
        'Notorious', // 20
        'The Boss of Bosses', // 21
        'The Dog Killer', // 22
        'The Killer of Dog Killer', // 23
        'Slum God', // 24
        'Candyman', // 25
        'Candywoman', // 26
        'The Butcher', // 27
        'Yung Capone', // 28
        'Yung Chapo', // 29
        'Yung Blanco', // 30
        'The Fixer', // 31
        'Jail Bird', // 32
        'Corner Cockatoo', // 33
        'Powder Prince', // 34
        'Hippie', // 35
        'John E. Dell', // 36
        'The Burning Man', // 37
        'The Burning Woman', // 38
        'Kid of the Game', // 39
        'Street Queen', // 40
        'The Killer of Dog Killers Killer', // 41
        'Slum General', // 42
        'Mafia Prince', // 43
        'Crooked Cop', // 44
        'Street Mayor', // 45
        'Undercover Cop', // 46
        'Oregano Farmer', // 47
        'Bloody', // 48
        'High on the Supply', // 49
        'The Orphan', // 50
        'The Orphan Maker', // 51
        'Ex Boxer', // 52
        'Ex Cop', // 53
        'Ex School Teacher', // 54
        'Ex Priest', // 55
        'Ex Engineer', // 56
        'Street Robinhood', // 57
        'Hell Bound', // 58
        'SoundCloud Rapper', // 59
        'Gang Leader', // 60
        'The CEO', // 61
        'The Freelance Pharmacist', // 62
        'Soccer Mom', // 63
        'Soccer Dad' // 64
    ];
    uint256 private constant namePrefixesLength = 64;

    string[] public nameSuffixes = [
        // <no name>            // 0
        'Feared', // 1
        'Baron', // 2
        'Vicious', // 3
        'Killer', // 4
        'Fugitive', // 5
        'Triggerman', // 6
        'Conman', // 7
        'Outlaw', // 8
        'Assassin', // 9
        'Shooter', // 10
        'Hitman', // 11
        'Bloodstained', // 12
        'Punishment', // 13
        'Sin', // 14
        'Smuggled', // 15
        'LastResort', // 16
        'Contraband', // 17
        'Illicit' // 18
    ];
    uint256 private constant nameSuffixesLength = 18;

    event AddComponent(uint256 id, uint256 componentType, string component);

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function seed(uint256 tokenId, uint8 componentType) public view returns (uint256, uint256) {
        uint256 rand = random(string(abi.encodePacked(slotKeys[componentType], toString(tokenId))));
        return (rand, rand % 21);
    }

    function pluck(uint256 rand, uint256 sourceArrayLength) internal pure returns (uint8[5] memory) {
        uint8[5] memory components;
        uint256 greatness = rand % 21;

        components[0] = uint8(rand % sourceArrayLength);
        components[1] = 0;
        components[2] = 0;

        if (greatness > 14) {
            components[1] = uint8((rand % suffixesLength) + 1);
        }
        if (greatness >= 19) {
            components[2] = uint8((rand % namePrefixesLength) + 1);
            components[3] = uint8((rand % nameSuffixesLength) + 1);
            if (greatness == 19) {
                // ...
            } else {
                components[4] = 1;
            }
        }

        return components;
    }

    function items(uint256 tokenId) external view returns (uint8[5][9] memory items_) {
        string memory id = toString(tokenId);

        for (uint8 i = 0; i < 9; i++) {
            uint256 rand = random(string(abi.encodePacked(slotKeys[i], id)));
            items_[i] = pluck(rand, slotLens[i]);
        }
    }

    function title(uint256 hustlerId) external view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked('OG', hustlerId)));
        // We subtract two to remove the soccer mom/dad prefixes
        return prefix(uint8((rand % (namePrefixesLength - 2)) + 1), uint8((rand % nameSuffixesLength) + 1));
    }

    function addComponent(uint8 componentType, string calldata component) external onlyOwner returns (uint8) {
        string[] storage arr;
        if (componentType == ComponentTypes.WEAPON) {
            arr = weapons;
        } else if (componentType == ComponentTypes.CLOTHES) {
            arr = clothes;
        } else if (componentType == ComponentTypes.VEHICLE) {
            arr = vehicle;
        } else if (componentType == ComponentTypes.WAIST) {
            arr = waistArmor;
        } else if (componentType == ComponentTypes.FOOT) {
            arr = footArmor;
        } else if (componentType == ComponentTypes.HAND) {
            arr = handArmor;
        } else if (componentType == ComponentTypes.DRUGS) {
            arr = drugs;
        } else if (componentType == ComponentTypes.NECK) {
            arr = necklaces;
        } else if (componentType == ComponentTypes.RING) {
            arr = rings;
        } else if (componentType == ComponentTypes.ACCESSORY) {
            arr = accessories;
        } else if (componentType == ComponentTypes.NAME_PREFIX) {
            arr = namePrefixes;
        } else if (componentType == ComponentTypes.NAME_SUFFIX) {
            arr = nameSuffixes;
        } else if (componentType == ComponentTypes.SUFFIX) {
            arr = suffixes;
        } else {
            revert(UnexpectedComponent);
        }

        require(arr.length < 255, 'component full');
        arr.push(component);
        uint8 id = uint8(arr.length) - 1;

        // prefix/suffix components are handled differently since they aren't always set.
        if (
            componentType == ComponentTypes.NAME_PREFIX ||
            componentType == ComponentTypes.NAME_SUFFIX ||
            componentType == ComponentTypes.SUFFIX
        ) {
            id = id + 1;
        }

        emit AddComponent(id, componentType, component);

        return id;
    }

    // Returns the "vanilla" item name w/o any prefix/suffixes or augmentations
    function name(uint8 componentType, uint256 idx) public view returns (string memory) {
        if (componentType == ComponentTypes.WEAPON) {
            return weapons[idx];
        } else if (componentType == ComponentTypes.CLOTHES) {
            return clothes[idx];
        } else if (componentType == ComponentTypes.VEHICLE) {
            return vehicle[idx];
        } else if (componentType == ComponentTypes.WAIST) {
            return waistArmor[idx];
        } else if (componentType == ComponentTypes.FOOT) {
            return footArmor[idx];
        } else if (componentType == ComponentTypes.HAND) {
            return handArmor[idx];
        } else if (componentType == ComponentTypes.DRUGS) {
            return drugs[idx];
        } else if (componentType == ComponentTypes.NECK) {
            return necklaces[idx];
        } else if (componentType == ComponentTypes.RING) {
            return rings[idx];
        } else if (componentType == ComponentTypes.ACCESSORY) {
            return accessories[idx];
        } else {
            revert(UnexpectedComponent);
        }
    }

    function prefix(uint8 prefixComponent, uint8 suffixComponent) public view returns (string memory) {
        if (prefixComponent == 0) {
            return '';
        }

        string memory namePrefixSuffix = namePrefixes[prefixComponent - 1];

        if (suffixComponent > 0) {
            namePrefixSuffix = string(abi.encodePacked(namePrefixSuffix, ' ', nameSuffixes[suffixComponent - 1]));
        }

        return namePrefixSuffix;
    }

    function suffix(uint8 suffixComponent) public view returns (string memory) {
        if (suffixComponent == 0) {
            return '';
        }

        return suffixes[suffixComponent - 1];
    }

    /// @notice Returns the attributes associated with this item.
    /// @dev Opensea Standards: https://docs.opensea.io/docs/metadata-standards
    function attributes(uint8[5] calldata components, uint8 componentType) external view returns (string memory) {
        string memory slot = slots[componentType];
        string memory res = string(abi.encodePacked('[', trait('Slot', slot)));

        string memory item = name(componentType, components[0]);
        res = string(abi.encodePacked(res, ', ', trait('Item', item)));

        if (components[1] > 0) {
            string memory data = suffixes[components[1] - 1];
            res = string(abi.encodePacked(res, ', ', trait('Suffix', data)));
        }

        if (components[2] > 0) {
            string memory data = namePrefixes[components[2] - 1];
            res = string(abi.encodePacked(res, ', ', trait('Name Prefix', data)));
        }

        if (components[3] > 0) {
            string memory data = nameSuffixes[components[3] - 1];
            res = string(abi.encodePacked(res, ', ', trait('Name Suffix', data)));
        }

        if (components[4] > 0) {
            res = string(abi.encodePacked(res, ', ', trait('Augmentation', 'Yes')));
        }

        res = string(abi.encodePacked(res, ']'));

        return res;
    }

    // Helper for encoding as json w/ trait_type / value from opensea
    function trait(string memory traitType, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked('{', '"trait_type": "', traitType, '", ', '"value": "', value, '"', '}'));
    }
}