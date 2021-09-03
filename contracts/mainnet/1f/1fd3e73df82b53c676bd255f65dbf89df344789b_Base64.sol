/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: Unlicense

/*

    Synthetic Loot
    
    This contract creates a "virtual NFT" of Loot based
    on a given wallet address. 
    
    Because the wallet address is used as the deterministic 
    seed, there can only be one Loot bag per wallet. 
    
    Because it's not a real NFT, there is no 
    minting, transferability, etc.
    
    Creators building on top of Loot can choose to recognize 
    Synthetic Loot as a way to allow a wider range of 
    adventurers to participate in the ecosystem, while
    still being able to differentiate between 
    "original" Loot and Synthetic Loot.
    
    Anyone with an Ethereum wallet has Synthetic Loot.
    
    -----
    
    Also optionally returns data in LootComponents format:
    
    Call weaponComponents(), chestComponents(), etc. to get 
    an array of attributes that correspond to the item. 
    
    The return format is:
    
    uint256[5] =>
        [0] = Item ID
        [1] = Suffix ID (0 for none)
        [2] = Name Prefix ID (0 for none)
        [3] = Name Suffix ID (0 for none)
        [4] = Augmentation (0 = false, 1 = true)
    
    See the item and attribute tables below for corresponding IDs.
    
    The original LootComponents contract is at address:
    0x3eb43b1545a360d1D065CB7539339363dFD445F3

*/

pragma solidity ^0.8.4;

contract SyntheticLesserLoot {

    string[] private weapons = [
        "Hammer",
        "Axe",
        "Bow",
        "Rusty Katana",
        "Rusty Sword",
        "Tree Branch",
        "Sword",
        "Wand",
        "Book"
    ];
    
    string[] private chestArmor = [
        "Robe",
        "Shirt",
        "Leather Armor",
        "Coat",
        "Sweater",
        "Rags"
    ];
    
    string[] private headArmor = [
        "Rusty Helm",
        "Helm",
        "Headband",
        "Cap",
        "Hood"
    ];
    
    string[] private waistArmor = [
        "Belt",
        "Wool Sash",
        "Linen Sash",
        "Sash"
    ];
    
    string[] private footArmor = [
        "Rusty Greaves",
        "Greaves",
        "Chain Boots",
        "Heavy Boots",
        "Leather Boots",
        "Slippers",
        "Wool Shoes",
        "Shoes"
    ];
    
    string[] private handArmor = [
        "Rusty Gauntlets",
        "Gauntlets",
        "Gloves",
        "Leather Gloves",
        "Wool Gloves"
    ];
    
    string[] private necklaces = [
        "Rusty Necklace",
        "Rusty Amulet",
        "Rusty Pendant"
    ];
    
    string[] private rings = [
        "Rusty Ring",
        "Ring"
    ];
    
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function weaponComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "WEAPON", weapons);
    }
    
    function chestComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "CHEST", chestArmor);
    }
    
    function headComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "HEAD", headArmor);
    }
    
    function waistComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "WAIST", waistArmor);
    }

    function footComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "FOOT", footArmor);
    }
    
    function handComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "HAND", handArmor);
    }
    
    function neckComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "NECK", necklaces);
    }
    
    function ringComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "RING", rings);
    }
    
    function getWeapon(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "WEAPON", weapons);
    }
    
    function getChest(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "CHEST", chestArmor);
    }
    
    function getHead(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "HEAD", headArmor);
    }
    
    function getWaist(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "WAIST", waistArmor);
    }

    function getFoot(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "FOOT", footArmor);
    }
    
    function getHand(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "HAND", handArmor);
    }
    
    function getNeck(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "NECK", necklaces);
    }
    
    function getRing(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "RING", rings);
    }
    
    function pluckName(address walletAddress, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, abi.encodePacked(walletAddress))));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function pluck(address walletAddress, string memory keyPrefix, string[] memory sourceArray) internal view returns (uint256[5] memory) {
        uint256[5] memory components;
        
        uint256 rand = random(string(abi.encodePacked(keyPrefix, abi.encodePacked(walletAddress))));
        
        components[0] = rand % sourceArray.length;
        components[1] = 0;
        components[2] = 0;
        return components;
    }
    
    function tokenURI(address walletAddress) public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getWeapon(walletAddress);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getChest(walletAddress);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getHead(walletAddress);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getWaist(walletAddress);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getFoot(walletAddress);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getHand(walletAddress);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getNeck(walletAddress);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getRing(walletAddress);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag 0x', toAsciiString(walletAddress), '", "description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    // https://ethereum.stackexchange.com/a/8447
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    // https://ethereum.stackexchange.com/a/8447
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}