/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./factory.sol";
import "./headFactory.sol";
import "./tireFactory.sol";
import "./utils.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CL is ERC721Enumerable, ReentrancyGuard, Ownable {

    bool public claimable;
    
    uint256 private balance;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _reservedTokenIds;    
    
    uint256 public reset_timing = 10;
    uint256 private constant MAX_CHAIN_BIKERZ = 10000;
    uint256 private constant MINT_PRICE = 0.03 ether;

    struct STATS {
        uint256 savedRep;
        uint256 mintBlock;
        uint256 challengedBlock;
        uint256 ownedBy;
        uint8 rank;
    }
    mapping (uint256 => STATS) public statsMap;
    
    string[] private prefix = [
        "Beelzebub",
        "Bewitched",
        "Blood",
        "Bone",
        "Brimstone",
        "Cursed",
        "Dead",
        "Death",
        "Devil's",
        "Diabolus",
        "Fighting",
        "Flaming",
        "Ghost",
        "Grave",
        "Green",
        "Gypsy",
        "Hellborn",
        "Hellfire",
        "Highway",
        "Insane",
        "Lucifer's",
        "Mad",
        "Pit",
        "Pukin'",
        "Satan's",
        "Scarlet",
        "Skeleton",
        "Steel",
        "Stoned",
        "Talon",
        "Winged"
    ];
    
    string[] private groups = [
        "Archers",
        "Assassins",
        "Barbarians",
        "Berserkers",
        "Boys",
        "Clowns",
        "Crazies",
        "Crew",
        "Crowns",
        "Crusaders",
        "Destroyers",
        "Disciples",
        "Dukes",
        "Earls",
        "Executioners",
        "Gang",
        "Gladiators",
        "Goons",
        "Headhunters",
        "Highwaymen",
        "Imperials",
        "Jesters",
        "Killers",
        "Kings",
        "Ladies",
        "Lancers",
        "Mafia",
        "Marauders",
        "Merlins",
        "Monarchs",
        "Necromancers",
        "Nobles",
        "Outlaws",
        "Pagans",
        "Pharoahs",
        "Posse",
        "Psychos",
        "Queens",
        "Raiders",
        "Rangers",
        "Reapers",
        "Rebels",
        "Renegades",
        "Rogues",
        "Royals",
        "Sentinels",
        "Sorcerors",
        "Spartans",
        "Squad",
        "Stompers",
        "Sultans",
        "Syndicate",
        "Thugs",
        "Tribe",
        "Vikings",
        "Warlocks"
        "Alligators",
        "Barracudas",
        "Bats",
        "Black Widows",
        "Cobras",
        "Devils",
        "Eagles",
        "Electric Eels",
        "Falcons",
        "Foxes",
        "Genies",
        "Ghouls",
        "Gremlins",
        "Griffons",
        "Hammerheads",
        "Hawks",
        "Hellcats",
        "Hellhounds",
        "Hogs",
        "Hyenas",
        "Krakens",
        "Lizards",
        "Morays",
        "Orcas",
        "Panthers",
        "Pelicans",
        "Rats",
        "Roaches",
        "Rooks",
        "Serpents",
        "Sharks",
        "Snakes",
        "Spiders",
        "Stallions",
        "Stingrays",
        "Tarantulas",
        "Thunderbirds",
        "Tigers",
        "Unicorns",
        "Vampires",
        "Vipers",
        "Vultures",
        "Wasps",
        "Werewolves",
        "Wolverines",
        "Wolves",
        "Wyverns"
    ];

    
    string[] private heads = [
        "Helmet",
        "Helmet",
        "Helmet",
        "Helmet",
        "Helmet",
        "Helmet",
        "Helmet",
        "Helmet",
        "Helmet",
        "Helmet",
        "Helmet",
        "Straight long hair",
        "Pigtails",
        "Half Buzzed",
        "Blue Vertical",
        "Techno Horns",
        "Beanie",
        "Cowboy"
    ];    

    string[] private ranks = [
        "Recruit",
        "Thug",
        "Gangster",
        "Muscle",
        "Boss",
        "Vice",
        "Owner",
        "Deity"
    ];    

    string[] private weapons = [
        "Chains",
        "Chainsaw",
        "Molotov Cocktail",
        "Machine Gun",
        "Anti-Tank Missile"
    ];
        
    function reputation(uint256 tokenID) public view returns (uint256) { 
        //last time there was an event
        uint256 lastBlock = statsMap[tokenID].mintBlock;

        if (lastBlock == 0) {
            return 0;
        }
        
        //for every 6000 blocks after last event, rep increases
        uint256 delta = block.number - lastBlock;        
        uint256 repByDay = delta / reset_timing;
        
        return repByDay + statsMap[tokenID].savedRep;
    }

    function challenge(uint256 tokenId, uint256 battleId) public returns (string memory){
        require(statsMap[tokenId].ownedBy < 1);
        require(ownerOf(tokenId) == (msg.sender));
        require(_tokenIds.current() > battleId);
        require(((block.number - statsMap[tokenId].challengedBlock) > reset_timing));
        require(((block.number - statsMap[battleId].challengedBlock) > reset_timing));

        uint256 p1WeaponLevel = getWeaponLevel(tokenId);
        uint256 p1Reputation = reputation(tokenId);
        uint256 p2WeaponLevel = getWeaponLevel(battleId);
        uint256 p2Reputation = reputation(battleId);

        bool win = utils.challenge(tokenId, battleId, p1WeaponLevel, p1Reputation, p2WeaponLevel, p2Reputation);
        statsMap[tokenId].challengedBlock = block.number;       
        statsMap[battleId].challengedBlock = block.number;

        //Challenger Wins
        if (win) {            
            statsMap[battleId].ownedBy = tokenId;
            statsMap[tokenId].rank = statsMap[tokenId].rank + 1;
            statsMap[tokenId].savedRep = statsMap[tokenId].savedRep + reputation(battleId);
            return string("Win");
        }

        return string("Lost");
    }

    function getPrefix(uint256 tokenId) private view returns (string memory) {
        return pluck(tokenId, "PREFIX", prefix);
    }
        
    function getGroup(uint256 tokenId) private view returns (string memory) {
        return pluck(tokenId, "GROUP", groups);
    }
    
    function getGang(uint256 tokenId) public view returns (string memory) { 
        if (statsMap[tokenId].ownedBy > 0) {
            return getGang(statsMap[tokenId].ownedBy);
        }

        return string(abi.encodePacked(getPrefix(tokenId), " ", getGroup(tokenId)));
    }

    function getWeaponLevel(uint256 tokenId) private view returns (uint256) {        
        uint256 rand = utils.random(string(abi.encodePacked("WEAPON", utils.toString(tokenId))));
        uint256 itemNum = rand % weapons.length;
        return itemNum;
    }    

    function getWeapon(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WEAPON", weapons);
    }    
    
    function getOwned(uint256 tokenId) public view returns (string memory) {
        if (statsMap[tokenId].ownedBy > 0) {
            return string(abi.encodePacked("Owned By: ", utils.toString(statsMap[tokenId].ownedBy)));
        }
        return "";
    }    

    function getHead(uint256 tokenId) public view returns (string memory) {      
        return pluck(tokenId, "HEAD", heads);
    }        

    function getHeadLevel(uint256 tokenId) internal view returns (uint256)  {
        uint256 rand = utils.random(string(abi.encodePacked("HEAD", utils.toString(tokenId))));
        uint256 itemNum = rand % heads.length;      
        return itemNum;
    }

    function getRank(uint256 tokenId) public view returns (string memory) {     
        if (statsMap[tokenId].rank > ranks.length) {
            return ranks[ranks.length - 1];
        }
        else {
            string memory output = ranks[statsMap[tokenId].rank - 1];
            return output;
        }
    }    


    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory)  {
        uint256 rand = utils.random(string(abi.encodePacked(keyPrefix, utils.toString(tokenId))));
        uint256 itemNum = rand % sourceArray.length;        
        string memory output = sourceArray[itemNum];
        return output;
    }
    
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[14] memory parts;       
                               
        parts[0] = animFactory.draw(getHeadLevel(tokenId)-1, tokenId);                
        parts[1] = headFactory.draw(getHeadLevel(tokenId)-1);
        parts[2] = tireFactory.draw();        
        parts[3] = '<text x="10" y="140" class="base">';
        parts[4] = getWeapon(tokenId);
        parts[5] = '</text><text x="10" y="160" class="base">';
        parts[6] = getGang(tokenId);
        parts[7] = '</text><text x="10" y="180" class="base">';        
        parts[8] = string(abi.encodePacked("Reputation: ", utils.toString(reputation(tokenId))));        
        parts[9] = '</text><text x="100" y="20" class="base owned">';        
        parts[10] = getOwned(tokenId);        
        parts[11] = '</text><text x="10" y="20" class="base neon">';      
        parts[12] = getRank(tokenId);      
        parts[13] = '</text></svg>';  

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[10], parts[11], parts[12], parts[13]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Biker #', utils.toString(tokenId), '", "description": "Chain Bikerz is a NFT game stored on chain. Players may challenge to get into the lead.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }


    function mintPublicSale(uint256 _count) external payable nonReentrant returns (uint256, uint256) {
        require(_tokenIds.current() + _count <= MAX_CHAIN_BIKERZ, "All gone");
        require(_count * MINT_PRICE == msg.value, "Eth too low");

        uint256 firstMintedId = _tokenIds.current() + 1;

        for (uint256 i = 0; i < _count; i++) {
            _tokenIds.increment();
            mint(_tokenIds.current());
        }

        statsMap[_tokenIds.current()].mintBlock = block.number;
        statsMap[_tokenIds.current()].rank = 1;

        return (firstMintedId, _count);
    }


    function mint(uint256 tokenId) internal {
        statsMap[tokenId].mintBlock = block.number;
        statsMap[tokenId].rank = 1;

        _safeMint(msg.sender, tokenId);
    }    
    
    function withdraw() public onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        require(success, "Withdrawal failed");
    }
    
    constructor() ERC721("Cl", "CL") Ownable() {}
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library animFactory {


    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function toString(uint256 value) public pure returns (string memory) {
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

  

  function draw(uint256 headLevel, uint256 tokenId) public pure returns (string memory) {
    string[9] memory helmet_colors = [
      "#555555;", //grey
      "#ff0500;", //red
      "#00ff3c;", //green
      "#009cff;", //lightblue
      "#6d39df;", //purple
      "#df39c0;", //pink
      "#d9df39;", //yellow
      "#64e5c9;", //teal
      "#ff9200;" //orange
    ];

    string[17] memory cycle_color = [
      "#0022ff;", 
      "#1533f6d9;", 
      "#1533f6b0;", 
      "#1533f687;", 
      "#1533f65c;", 
      "#1533f61c;", 
      "#4809b9c7;", 
      "#085642;", 
      "#152e2a;", 
      "#555555;", 
      "#ff0500;", 
      "#00ff3c;", 
      "#009cff;",
      "#6d39df;", 
      "#df39c0;",
      "#64e5c9;",
      "#ff9200;"
    ];

     string memory color = "auto;";
     if (headLevel < 10) {
       color = helmet_colors[headLevel];
     }
     uint256 colorCycle = tokenId % 16;
     string memory color2 = cycle_color[colorCycle];
     string memory custom_colors_css = string(abi.encodePacked(".color1 { fill: ", color, " } .color2 { fill: ", color2, " }"));
     string memory anim1 = _getCycle();
     string memory top = '<svg version="1.1" width="200" height="200" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" preserveAspectRatio="xMinYMin meet" shape-rendering="crispEdges"><rect width="100%" height="100%" fill="grey" />';
     string memory styles = '.base { fill: white; font-family: serif; font-size: 14px; } .neon { fill: #00ff6b; } .owned { fill: #ff2121; } #tire1, #tire2, #tire3 { opacity: 0; -webkit-animation-duration: 0.75s; animation-duration: 0.75s; -webkit-animation-iteration-count: infinite; animation-iteration-count: infinite; -webkit-animation-timing-function: steps(1); animation-timing-function: steps(1); } @-webkit-keyframes shapes-1 { 0% { opacity: 1; } 33.33333% { opacity: 0; } } @keyframes shapes-1 { 0% { opacity: 1; } 33.33333% { opacity: 0; } } :nth-child(1) { -webkit-animation-name: shapes-1; animation-name: shapes-1; } @-webkit-keyframes shapes-2 { 33.33333% { opacity: 1; } 66.66667% { opacity: 0; } } @keyframes shapes-2 { 33.33333% { opacity: 1; } 66.66667% { opacity: 0; } } :nth-child(2) { -webkit-animation-name: shapes-2; animation-name: shapes-2; } @-webkit-keyframes shapes-3 { 66.66667% { opacity: 1; } 100% { opacity: 0; } } @keyframes shapes-3 { 66.66667% { opacity: 1; } 100% { opacity: 0; } } :nth-child(3) { -webkit-animation-name: shapes-3; animation-name: shapes-3; }';
    return string(abi.encodePacked(top, '<style> ',styles, custom_colors_css, ';</style><g transform="scale(2 2)  translate(42 20)">', anim1, '</g>'));
  }

  function _getCycle() internal pure returns (string memory) {
    string memory cycle =    
        unicode'<rect x="4" y="0" width="1" height="1" fill="#555555" />'
        unicode'<rect x="5" y="0" width="1" height="1" fill="#555555" />'
        unicode'<rect x="6" y="0" width="1" height="1" fill="#555555" />'
        unicode'<rect x="7" y="0" width="1" height="1" fill="#555555" />'
        unicode'<rect x="8" y="0" width="1" height="1" fill="#555555" />'
        unicode'<rect x="9" y="0" width="1" height="1" fill="#555555" />'
        unicode'<rect x="10" y="0" width="1" height="1" fill="#555555" />'
        unicode'<rect x="11" y="0" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="3" y="1" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="1" width="1" height="1" fill="#555555" />'
        unicode'<rect x="5" y="1" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="1" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="1" width="1" height="1" fill="#555555" />'
        unicode'<rect x="8" y="1" width="1" height="1" fill="#555555" />'
        unicode'<rect x="9" y="1" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="1" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="1" width="1" height="1" fill="#555555" />'
        unicode'<rect x="12" y="1" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="2" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="3" y="2" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="2" width="1" height="1" fill="#555555" />'
        unicode'<rect x="5" y="2" width="1" height="1" fill="#555555" />'
        unicode'<rect x="6" y="2" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="7" y="2" width="1" height="1" fill="#555555" />'
        unicode'<rect x="8" y="2" width="1" height="1" fill="#555555" />'
        unicode'<rect x="9" y="2" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="10" y="2" width="1" height="1" fill="#555555" />'
        unicode'<rect x="11" y="2" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="2" width="1" height="1" fill="#000000" />'
        unicode'<rect x="2" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="3" y="3" width="1" height="1" fill="#555555" />'
        unicode'<rect x="4" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="3" width="1" height="1" fill="#555555" />'
        unicode'<rect x="6" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="9" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="3" width="1" height="1" fill="#555555" />'
        unicode'<rect x="11" y="3" width="1" height="1" fill="#555555" />'
        unicode'<rect x="12" y="3" width="1" height="1" fill="#555555" />'
        unicode'<rect x="13" y="3" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="4" width="1" height="1" fill="#000000" />'
        unicode'<rect x="3" y="4" width="1" height="1" fill="#555555" />'
        unicode'<rect x="4" y="4" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="4" width="1" height="1" fill="#555555" />'
        unicode'<rect x="6" y="4" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="4" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="4" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="9" y="4" width="1" height="1" fill="#555555" />'
        unicode'<rect x="10" y="4" width="1" height="1" fill="#555555" />'
        unicode'<rect x="11" y="4" width="1" height="1" fill="#555555" />'
        unicode'<rect x="12" y="4" width="1" height="1" fill="#555555" />'
        unicode'<rect x="13" y="4" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="5" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="5" width="1" height="1" fill="#555555" />'
        unicode'<rect x="3" y="5" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="5" width="1" height="1" fill="#555555" />'
        unicode'<rect x="5" y="5" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="5" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="5" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="5" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="9" y="5" width="1" height="1" fill="#555555" />'
        unicode'<rect x="10" y="5" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="5" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="5" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="13" y="5" width="1" height="1" fill="#555555" />'
        unicode'<rect x="14" y="5" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="6" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="6" width="1" height="1" fill="#555555" />'
        unicode'<rect x="3" y="6" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="6" width="1" height="1" fill="#555555" />'
        unicode'<rect x="5" y="6" width="1" height="1" fill="#555555" />'
        unicode'<rect x="6" y="6" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="6" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="6" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="9" y="6" width="1" height="1" fill="#555555" />'
        unicode'<rect x="10" y="6" width="1" height="1" fill="#555555" />'
        unicode'<rect x="11" y="6" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="6" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="13" y="6" width="1" height="1" fill="#555555" />'
        unicode'<rect x="14" y="6" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="3" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="7" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="7" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="7" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="8" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="9" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="10" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="11" y="7" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="13" y="7" width="1" height="1" fill="#555555" />'
        unicode'<rect x="14" y="7" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="8" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="8" width="1" height="1" fill="#000000" />'
        unicode'<rect x="3" y="8" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="8" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="5" y="8" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="3" y="25" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="3" y="26" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="6" y="8" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="7" y="8" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="8" y="8" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="9" y="8" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="10" y="8" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="11" y="8" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="12" y="8" width="1" height="1" fill="#000000" />'
        unicode'<rect x="13" y="8" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="14" y="8" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="9" width="1" height="1" fill="#555555" />'
        unicode'<rect x="3" y="9" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="4" y="9" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="5" y="9" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="6" y="9" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="7" y="9" width="1" height="1" fill="#A3101F" />'
        unicode'<rect x="8" y="9" width="1" height="1" fill="#A3101F" />'
        unicode'<rect x="9" y="9" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="10" y="9" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="11" y="9" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="12" y="9" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="13" y="9" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="10" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="10" width="1" height="1" fill="#555555" />'
        unicode'<rect x="3" y="10" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="4" y="10" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="5" y="10" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="6" y="10" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="7" y="10" width="1" height="1" fill="#A3101F" />'
        unicode'<rect x="8" y="10" width="1" height="1" fill="#A3101F" />'
        unicode'<rect x="9" y="10" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="10" y="10" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="11" y="10" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="12" y="10" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="13" y="10" width="1" height="1" fill="#555555" />'
        unicode'<rect x="14" y="10" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="0" y="11" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="11" width="1" height="1" fill="#555555" />'
        unicode'<rect x="2" y="11" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="3" y="11" width="1" height="1" fill="#555555" />'
        unicode'<rect x="4" y="11" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="5" y="11" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="6" y="11" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="7" y="11" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="8" y="11" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="9" y="11" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="10" y="11" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="11" y="11" width="1" height="1" class="color2" fill="#1533F6" />'
        unicode'<rect x="12" y="11" width="1" height="1" fill="#555555" />'
        unicode'<rect x="13" y="11" width="1" height="1" fill="#5A6FF2" />'
        unicode'<rect x="14" y="11" width="1" height="1" fill="#555555" />'
        unicode'<rect x="0" y="12" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="12" width="1" height="1" fill="#555555" />'
        unicode'<rect x="2" y="12" width="1" height="1" fill="#555555" />'
        unicode'<rect x="3" y="12" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="9" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="12" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="12" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="13" y="12" width="1" height="1" fill="#555555" />'
        unicode'<rect x="14" y="12" width="1" height="1" fill="#555555" />'
        unicode'<rect x="0" y="13" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="13" width="1" height="1" fill="#555555" />'
        unicode'<rect x="2" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="3" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="9" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="13" width="1" height="1" fill="#555555" />'
        unicode'<rect x="11" y="13" width="1" height="1" fill="#555555" />'
        unicode'<rect x="12" y="13" width="1" height="1" fill="#000000" />'
        unicode'<rect x="13" y="13" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="14" y="13" width="1" height="1" fill="#555555" />'
        unicode'<rect x="1" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="2" y="14" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="3" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="14" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="5" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="9" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="14" width="1" height="1" fill="#555555" />'
        unicode'<rect x="11" y="14" width="1" height="1" fill="#555555" />'
        unicode'<rect x="12" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="13" y="14" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="14" y="14" width="1" height="1" fill="#000000" />'
        unicode'<rect x="0" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="15" width="1" height="1" fill="#555555" />'
        unicode'<rect x="2" y="15" width="1" height="1" fill="#555555" />'
        unicode'<rect x="3" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="5" y="15" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="7" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="8" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="9" y="15" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="11" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="12" y="15" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="13" y="15" width="1" height="1" fill="#555555" />'
        unicode'<rect x="14" y="15" width="1" height="1" fill="#555555" />'
        unicode'<rect x="0" y="16" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="16" width="1" height="1" fill="#452408" />'
        unicode'<rect x="2" y="16" width="1" height="1" fill="#302E49" />'
        unicode'<rect x="3" y="16" width="1" height="1" fill="#452408" />'
        unicode'<rect x="4" y="16" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="16" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="16" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="16" width="1" height="1" fill="#452408" />'
        unicode'<rect x="13" y="16" width="1" height="1" fill="#302E49" />'
        unicode'<rect x="14" y="16" width="1" height="1" fill="#452408" />'
        unicode'<rect x="1" y="17" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="17" width="1" height="1" fill="#302E49" />'
        unicode'<rect x="3" y="17" width="1" height="1" fill="#302E49" />'
        unicode'<rect x="4" y="17" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="17" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="17" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="17" width="1" height="1" fill="#555555" />'
        unicode'<rect x="13" y="17" width="1" height="1" fill="#302E49" />'
        unicode'<rect x="14" y="17" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="18" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="18" width="1" height="1" fill="#452408" />'
        unicode'<rect x="3" y="18" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="18" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="18" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="18" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="18" width="1" height="1" fill="#000000" />'
        unicode'<rect x="13" y="18" width="1" height="1" fill="#000000" />'
        unicode'<rect x="14" y="18" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="19" width="1" height="1" fill="#452408" />'
        unicode'<rect x="3" y="19" width="1" height="1" fill="#452408" />'
        unicode'<rect x="4" y="19" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="19" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="19" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="19" width="1" height="1" fill="#452408" />'
        unicode'<rect x="13" y="19" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="20" width="1" height="1" fill="#452408" />'
        unicode'<rect x="3" y="20" width="1" height="1" fill="#452408" />'
        unicode'<rect x="4" y="20" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="20" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="20" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="12" y="20" width="1" height="1" fill="#452408" />'
        unicode'<rect x="13" y="20" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="21" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="21" width="1" height="1" fill="#302E49" />'
        unicode'<rect x="3" y="21" width="1" height="1" fill="#555555" />'
        unicode'<rect x="4" y="21" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="21" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="21" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="21" width="1" height="1" fill="#555555" />'
        unicode'<rect x="13" y="21" width="1" height="1" fill="#452408" />'
        unicode'<rect x="14" y="21" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="22" width="1" height="1" fill="#000000" />'
        unicode'<rect x="2" y="22" width="1" height="1" fill="#000000" />'
        unicode'<rect x="3" y="22" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="22" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="22" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="22" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="22" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="13" y="22" width="1" height="1" fill="#452408" />'
        unicode'<rect x="14" y="22" width="1" height="1" fill="#000000" />'
        unicode'<rect x="1" y="23" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="23" width="1" height="1" fill="#555555" />'
        unicode'<rect x="3" y="23" width="1" height="1" fill="#555555" />'
        unicode'<rect x="4" y="23" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="23" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="23" width="1" height="1" fill="#302E49" />'
        unicode'<rect x="12" y="23" width="1" height="1" fill="#555555" />'
        unicode'<rect x="13" y="23" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="14" y="23" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="1" y="24" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="2" y="24" width="1" height="1" fill="#000000" />'
        unicode'<rect x="3" y="24" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="24" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="24" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="24" width="1" height="1" fill="#555555" />'
        unicode'<rect x="12" y="24" width="1" height="1" fill="#000000" />'
        unicode'<rect x="13" y="24" width="1" height="1" fill="#000000" />'
        unicode'<rect x="14" y="24" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="4" y="25" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="25" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="25" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="4" y="26" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="26" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="26" width="1" height="1" fill="#CCCCCB" />'
        unicode'<rect x="4" y="27" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="27" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="28" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="28" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="29" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="30" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="31" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="32" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="32" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="33" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="33" width="1" height="1" fill="#000000" />'
        unicode'<rect x="3" y="34" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="34" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="34" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="34" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="34" width="1" height="1" fill="#000000" />'
        unicode'<rect x="9" y="34" width="1" height="1" fill="#000000" />'
        unicode'<rect x="12" y="34" width="1" height="1" fill="#000000" />'
        unicode'<rect x="2" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="9" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="35" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="36" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="36" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="36" width="1" height="1" fill="#000000" />'
        unicode'<rect x="10" y="36" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="36" width="1" height="1" fill="#000000" />'
        unicode'<rect x="4" y="37" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="37" width="1" height="1" fill="#000000" />'
        unicode'<rect x="8" y="37" width="1" height="1" fill="#000000" />'
        unicode'<rect x="9" y="37" width="1" height="1" fill="#000000" />';
    return cycle;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library headFactory {

  function draw(uint256 number) public pure returns (string memory) {
     string memory head = _getHelmet(number);
     return string(head);
  }

  function _getHelmet(uint256 number) internal pure returns (string memory) {
    string memory helmet = 
      unicode'<g transform="scale(2 2)  translate(42 13)">'
      unicode'<rect x="7" y="3" width="1" height="1" fill="#30323F" />'
      unicode'<rect x="8" y="3" width="1" height="1" fill="#30323F" />'
      unicode'<rect x="6" y="4" width="1" height="1" fill="#30323F" />'
      unicode'<rect x="7" y="4" width="1" height="1" class="color1" fill="#555555" />'
      unicode'<rect x="8" y="4" width="1" height="1" class="color1" fill="#555555" />'
      unicode'<rect x="9" y="4" width="1" height="1" fill="#30323F" />'
      unicode'<rect x="6" y="5" width="1" height="1" fill="#000000" />'
      unicode'<rect x="7" y="5" width="1" height="1" class="color1" fill="#555555" />'
      unicode'<rect x="8" y="5" width="1" height="1" class="color1" fill="#555555" />'
      unicode'<rect x="9" y="5" width="1" height="1" fill="#000000" />'
      unicode'<rect x="6" y="6" width="1" height="1" fill="#000000" />'
      unicode'<rect x="7" y="6" width="1" height="1" fill="#000000" />'
      unicode'<rect x="8" y="6" width="1" height="1" fill="#000000" />'
      unicode'<rect x="9" y="6" width="1" height="1" fill="#000000" />'
      unicode'</g>'; 
      string memory beanie =       
        unicode'<g transform="scale(2 2)  translate(42 13)">'
        unicode'<rect x="7" y="2" width="1" height="1" fill="#9848BB" />'
        unicode'<rect x="8" y="2" width="1" height="1" fill="#9848BB" />'
        unicode'<rect x="9" y="2" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="3" width="1" height="1" fill="#9848BB" />'
        unicode'<rect x="8" y="3" width="1" height="1" fill="#9848BB" />'
        unicode'<rect x="9" y="3" width="1" height="1" fill="#9848BB" />'
        unicode'<rect x="6" y="4" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="7" y="4" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="8" y="4" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="9" y="4" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="10" y="4" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="5" y="5" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="6" y="5" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="7" y="5" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="8" y="5" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="9" y="5" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="10" y="5" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="5" y="6" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="6" y="6" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="7" y="6" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="8" y="6" width="1" height="1" fill="#3B7B2B" />'
        unicode'<rect x="9" y="6" width="1" height="1" fill="#244D1A" />'
        unicode'<rect x="10" y="6" width="1" height="1" fill="#3B7B2B" />'
        unicode'</g>';
        string memory blue_vertical = 
          unicode'<g transform="scale(2 2)  translate(42 13)">'
          unicode'<rect x="8" y="0" width="1" height="1" fill="#34A0B3" />'
          unicode'<rect x="7" y="1" width="1" height="1" fill="#34A0B3" />'
          unicode'<rect x="8" y="1" width="1" height="1" fill="#34A0B3" />'
          unicode'<rect x="10" y="1" width="1" height="1" fill="#34A0B3" />'
          unicode'<rect x="4" y="2" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="5" y="2" width="1" height="1" fill="#34A0B3" />'
          unicode'<rect x="6" y="2" width="1" height="1" fill="#34A0B3" />'
          unicode'<rect x="7" y="2" width="1" height="1" fill="#61E8FF" />'
          unicode'<rect x="8" y="2" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="9" y="2" width="1" height="1" fill="#61E8FF" />'
          unicode'<rect x="10" y="2" width="1" height="1" fill="#61E8FF" />'
          unicode'<rect x="5" y="3" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="6" y="3" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="7" y="3" width="1" height="1" fill="#61E8FF" />'
          unicode'<rect x="8" y="3" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="9" y="3" width="1" height="1" fill="#61E8FF" />'
          unicode'<rect x="10" y="3" width="1" height="1" fill="#34A0B3" />'
          unicode'<rect x="5" y="4" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="6" y="4" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="7" y="4" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="8" y="4" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="9" y="4" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="6" y="5" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="7" y="5" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="8" y="5" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="9" y="5" width="1" height="1" fill="#547D84" />'
          unicode'<rect x="6" y="6" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="7" y="6" width="1" height="1" fill="#EEC39A" />'
          unicode'<rect x="8" y="6" width="1" height="1" fill="#EEC39A" />'
          unicode'</g>';
        string memory half_buzzed = 
          unicode'<g transform="scale(2 2)  translate(42 13)">'
          unicode'<rect x="7" y="2" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="8" y="2" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="6" y="3" width="1" height="1" fill="#5435FB" />'
          unicode'<rect x="7" y="3" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="8" y="3" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="9" y="3" width="1" height="1" fill="#786C7A" />'
          unicode'<rect x="5" y="4" width="1" height="1" fill="#5435FB" />'
          unicode'<rect x="6" y="4" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="7" y="4" width="1" height="1" fill="#E1D69A" />'
          unicode'<rect x="8" y="4" width="1" height="1" fill="#E1D69A" />'
          unicode'<rect x="9" y="4" width="1" height="1" fill="#786C7A" />'
          unicode'<rect x="5" y="5" width="1" height="1" fill="#5435FB" />'
          unicode'<rect x="6" y="5" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="7" y="5" width="1" height="1" fill="#E1D69A" />'
          unicode'<rect x="8" y="5" width="1" height="1" fill="#E1D69A" />'
          unicode'<rect x="9" y="5" width="1" height="1" fill="#E1D69A" />'
          unicode'<rect x="5" y="6" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="6" y="6" width="1" height="1" fill="#3314D3" />'
          unicode'<rect x="7" y="6" width="1" height="1" fill="#E1D69A" />'
          unicode'<rect x="8" y="6" width="1" height="1" fill="#E1D69A" />'
          unicode'<rect x="9" y="6" width="1" height="1" fill="#E1D69A" />'
          unicode'</g>';

      string memory horns = 
        unicode'<g transform="scale(2 2)  translate(42 13)">'
        unicode'<rect x="5" y="3" width="1" height="1" fill="#53676B" />'
        unicode'<rect x="10" y="3" width="1" height="1" fill="#53676B" />'
        unicode'<rect x="6" y="4" width="1" height="1" fill="#53676B" />'
        unicode'<rect x="7" y="4" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="8" y="4" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="9" y="4" width="1" height="1" fill="#53676B" />'
        unicode'<rect x="6" y="5" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="7" y="5" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="8" y="5" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="9" y="5" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="6" y="6" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="7" y="6" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="8" y="6" width="1" height="1" fill="#FFF7E9" />'
        unicode'<rect x="9" y="6" width="1" height="1" fill="#FFF7E9" />'
        unicode'</g>';
      string memory pigtails = 
        unicode'<g transform="scale(2 2)  translate(42 13)">'
        unicode'<rect x="6" y="3" width="1" height="1" fill="#EF34C9" />'
        unicode'<rect x="7" y="3" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="8" y="3" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="9" y="3" width="1" height="1" fill="#EF34C9" />'
        unicode'<rect x="6" y="4" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="7" y="4" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="8" y="4" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="9" y="4" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="5" y="5" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="6" y="5" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="7" y="5" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="8" y="5" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="9" y="5" width="1" height="1" fill="#EF34C9" />'
        unicode'<rect x="10" y="5" width="1" height="1" fill="#EF34C9" />'
        unicode'<rect x="3" y="6" width="1" height="1" fill="#EF34C9" />'
        unicode'<rect x="4" y="6" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="5" y="6" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="6" width="1" height="1" fill="#FF53DD" />'
        unicode'<rect x="7" y="6" width="1" height="1" fill="#CB9B4F" />'
        unicode'<rect x="8" y="6" width="1" height="1" fill="#CB9B4F" />'
        unicode'<rect x="9" y="6" width="1" height="1" fill="#EF34C9" />'
        unicode'<rect x="10" y="6" width="1" height="1" fill="#000000" />'
        unicode'<rect x="11" y="6" width="1" height="1" fill="#FF53DD" />'
        unicode'</g>';

      string memory straight_long =
        unicode'<g transform="scale(2 2)  translate(42 13)">'
        unicode'<rect x="6" y="2" width="1" height="1" class="color1" fill="#555555" />'
        unicode'<rect x="7" y="2" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="8" y="2" width="1" height="1" class="color1" fill="#555555" />'
        unicode'<rect x="9" y="2" width="1" height="1" class="color1" fill="#555555" />'
        unicode'<rect x="6" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="7" y="3" width="1" height="1" fill="#222122" />'
        unicode'<rect x="8" y="3" width="1" height="1" fill="#971BC3" />'
        unicode'<rect x="9" y="3" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="6" y="4" width="1" height="1" fill="#222122" />'
        unicode'<rect x="7" y="4" width="1" height="1" fill="#222122" />'
        unicode'<rect x="8" y="4" width="1" height="1" fill="#971BC3" />'
        unicode'<rect x="9" y="4" width="1" height="1" fill="#040404" />'
        unicode'<rect x="5" y="5" width="1" height="1" fill="#30323F" />'
        unicode'<rect x="6" y="5" width="1" height="1" fill="#BB44E6" />'
        unicode'<rect x="7" y="5" width="1" height="1" fill="#222122" />'
        unicode'<rect x="8" y="5" width="1" height="1" fill="#040404" />'
        unicode'<rect x="9" y="5" width="1" height="1" fill="#040404" />'
        unicode'<rect x="7" y="6" width="1" height="1" fill="#EEC39A" />'
        unicode'<rect x="8" y="6" width="1" height="1" fill="#EEC39A" />'
        unicode'</g>';
      string memory cowboy = 
        unicode'<g transform="scale(2 2)  translate(42 13)">'
        unicode'<rect x="7" y="0" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="8" y="0" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="6" y="1" width="1" height="1" fill="#543D27" />'
        unicode'<rect x="7" y="1" width="1" height="1" fill="#543D27" />'
        unicode'<rect x="8" y="1" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="9" y="1" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="6" y="2" width="1" height="1" fill="#543D27" />'
        unicode'<rect x="7" y="2" width="1" height="1" fill="#543D27" />'
        unicode'<rect x="8" y="2" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="9" y="2" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="4" y="3" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="3" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="6" y="3" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="7" y="3" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="8" y="3" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="9" y="3" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="10" y="3" width="1" height="1" fill="#785B3F" />'
        unicode'<rect x="5" y="4" width="1" height="1" fill="#000000" />'
        unicode'<rect x="6" y="4" width="1" height="1" fill="#2B1F12" />'
        unicode'<rect x="7" y="4" width="1" height="1" fill="#2B1F12" />'
        unicode'<rect x="8" y="4" width="1" height="1" fill="#2B1F12" />'
        unicode'<rect x="9" y="4" width="1" height="1" fill="#2B1F12" />'
        unicode'<rect x="10" y="4" width="1" height="1" fill="#000000" />'
        unicode'<rect x="5" y="5" width="1" height="1" fill="#9DFAFF" />'
        unicode'<rect x="6" y="5" width="1" height="1" fill="#6A4C2E" />'
        unicode'<rect x="7" y="5" width="1" height="1" fill="#6A4C2E" />'
        unicode'<rect x="8" y="5" width="1" height="1" fill="#6A4C2E" />'
        unicode'<rect x="9" y="5" width="1" height="1" fill="#6A4C2E" />'
        unicode'<rect x="10" y="5" width="1" height="1" fill="#9DFAFF" />'
        unicode'<rect x="6" y="6" width="1" height="1" fill="#222222" />'
        unicode'<rect x="7" y="6" width="1" height="1" fill="#6A4C2E" />'
        unicode'<rect x="8" y="6" width="1" height="1" fill="#6A4C2E" />'
        unicode'<rect x="9" y="6" width="1" height="1" fill="#594310" />'
        unicode'</g>';

      string[17] memory heads = [
        helmet,
        helmet,
        helmet,
        helmet,
        helmet,
        helmet,
        helmet,
        helmet,
        helmet,
        helmet,
        straight_long,
        pigtails,
        half_buzzed,
        blue_vertical,
        horns,
        beanie,
        cowboy
      ];
      return heads[number];    
  }  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library tireFactory {

  function draw() public pure returns (string memory) {
     string memory tires = _getTires();
    return string(tires);
  }

  function _getTires() internal pure returns (string memory) {
    string memory tires =     
            unicode'<g transform="scale(2 2)  translate(47 36)">'
            unicode'<g id="tire1">'
            unicode'<rect x="0" y="0" width="6" height="18" fill="#000000" />'
            unicode'<rect x="1" y="0" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="0" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="0" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="1" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="2" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="2" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="2" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="3" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="3" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="3" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="3" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="4" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="5" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="6" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="7" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="8" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="9" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="9" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="9" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="9" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="10" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="10" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="10" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="10" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="11" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="11" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="11" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="13" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="14" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="16" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="17" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="17" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="17" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="17" width="1" height="1" fill="#30323F" />'
            unicode'</g>'
            unicode'<g id="tire2">'
            unicode'<rect x="0" y="0" width="6" height="18" fill="#000" />'
            unicode'<rect x="1" y="0" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="0" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="0" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="2" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="0" y="3" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="4" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="4" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="4" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="5" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="7" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="9" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="10" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="10" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="10" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="11" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="11" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="11" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="11" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="12" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="12" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="12" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="12" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="13" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="13" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="13" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="14" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="17" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="17" width="1" height="1" fill="#30323F" />'
            unicode'</g>'
            unicode'<g id="tire3">'
            unicode'<rect x="0" y="0" width="6" height="18" fill="#000000" />'
            unicode'<rect x="2" y="0" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="3" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="3" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="4" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="7" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="0" y="8" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="9" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="9" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="9" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="9" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="10" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="11" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="12" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="14" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="15" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="15" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="15" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="16" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="16" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="16" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="16" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="1" y="17" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="2" y="17" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="3" y="17" width="1" height="1" fill="#30323F" />'
            unicode'<rect x="4" y="17" width="1" height="1" fill="#30323F" />'
            unicode'</g>'
            unicode'</g>';
          return tires;
        }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library utils {


    function challenge(uint256 tokenId, uint256 battleId, uint256 p1WeaponLevel, uint256 p1Reputation, uint256 p2WeaponLevel, uint256 p2Reputation) public view returns (bool){
        require(tokenId != battleId, "Err");

        uint256 p1Luck = 50 + p1WeaponLevel + p1Reputation;        
        uint256 p1Rand = random(string(abi.encodePacked(toString(block.number), toString(tokenId), "CHALLENGER")));
        uint256 p1Draw = p1Rand % p1Luck;

        uint256 p2Luck = 50 + p2WeaponLevel + p2Reputation;
        uint256 p2Rand = random(string(abi.encodePacked(toString(block.number), toString(battleId), "CHALLENGED")));
        uint256 p2Draw = p2Rand % p2Luck;

        //Challenger Wins
        if (p1Draw > p2Draw) {            
            return true;
        }

        return false;
    }
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function toString(uint256 value) public pure returns (string memory) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}