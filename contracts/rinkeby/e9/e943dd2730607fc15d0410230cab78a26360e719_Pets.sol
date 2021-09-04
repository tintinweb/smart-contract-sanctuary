pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

//SPDX-License-Identifier: UNLICENSED

import "./ERC721.sol";

contract Pets is ERC721, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    constructor() ERC721("Pet (for Adventurers)", "PETS") {}
    address public lootAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
    LootInterface lootContract = LootInterface(lootAddress);

    string public PROVENANCE = "";

    uint256 public maxSupply = 10;
    uint256 public currentSupply = 0;


    uint256 public lootersPrice = 10000000000000000; // 0.01 ETH
    uint256 public publicPrice = 2000000000000; // 0.02 ETH

    string[] private Type = [
    "goblin", "goblin", "goblin", "goblin", "goblin", "goblin",
    "python", "python", "python", "python",
    "werewolf", "werewolf",
    "lion", "lion",
    "minotaur", "minotaur",
    "phoenix",
    "ghost", "ghost",
    "griffin",
    "raven", "raven",
    "hydra",
    "dragon",
    "imp", "imp", "imp", "imp",
    "ghoul", "ghoul",
    "fairy",
    "gnome", "gnome", "gnome", "gnome", "gnome",
    "troll", "troll", "troll", "troll",
    "sea serpent",
    "yeti",
    "mermaid", "mermaid",
    "bat", "bat", "bat",
    "ogre", "ogre",
    "spider", "spider", "spider", "spider", "spider",
    "golem",
    "turtle", "turtle",
    "cerberus",
    "harpie", "harpie",
    "kraken",
    "nian",
    "owl", "owl", "owl",
    "zouwu",
    "ape",
    "cow", "cow", "cow", "cow", "cow", "cow", "cow",
    "donkey", "donkey", "donkey", "donkey", "donkey",
    "crab", "crab", "crab",
    "sea lion", "sea lion",
    "toad", "toad", "toad", "toad",
    "lizard", "lizard", "lizard", "lizard",
    "wisp",
    "panda", "panda",
    "jellyfish", "jellyfish"
    ];

    string[] private rarities = [
    "Mythical",
    "Legendary", "Legendary",
    "Epic", "Epic", "Epic", "Epic",
    "Rare", "Rare", "Rare", "Rare", "Rare", "Rare", "Rare", "Rare",
    "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common", "Common"
    ];

    string[] private moods = [
    "Gloomy", "Gloomy", "Gloomy", "Gloomy",
    "Bossy",
    "Curious", "Curious",
    "Whiny", "Whiny", "Whiny", "Whiny", "Whiny", "Whiny",
    "Impulsive", "Impulsive",
    "Thorough", "Thorough", "Thorough",
    "Liar", "Liar",
    "Shameless",
    "Imaginative",
    "Harsh", "Harsh", "Harsh", "Harsh",
    "Forgiving", "Forgiving", "Forgiving", "Forgiving",
    "Proud",
    "Listless", "Listless", "Listless", "Listless", "Listless", "Listless",
    "Humorous", "Humorous",
    "Sadistic",
    "Generous", "Generous", "Generous", "Generous",
    "Irreligious",
    "Solitary", "Solitary", "Solitary", "Solitary",
    "Aggressive",
    "Friendly",
    "Calm"
    ];


    function getType(uint256 tokenId) public view returns (string memory) {
        if (tokenId == 0) {
            return "Pegasus";
        }
        if (tokenId == maxSupply - 1) {
            return "Demon";
        }
        return pluck(tokenId, "Type", Type);
    }

    function getRarity(uint256 tokenId) public view returns (string memory) {
        if (tokenId == 0) {
            return "Godly";
        }
        if (tokenId == maxSupply - 1) {
            return "Hellish";
        }
        return pluck(tokenId, "Rarity", rarities);
    }

    function getMood(uint256 tokenId) public view returns (string memory) {
        if (tokenId == 0 || tokenId == maxSupply - 1) {
            return "Charismatic";
        }
        return pluck(tokenId, "Mood", moods);
    }

    function random(string memory input) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input))) % 31;
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal view returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );

        string memory output = sourceArray[rand % sourceArray.length];

        return output;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function deposit() public payable onlyOwner {}


    function setLootersPrice(uint256 newPrice) public onlyOwner {
        lootersPrice = newPrice;
    }

    function setPublicPrice(uint256 newPrice) public onlyOwner {
        publicPrice = newPrice;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setProvenance(string memory prov) public onlyOwner {
        PROVENANCE = prov;
    }

    // Loot owners minting
    function mintWithLoot(uint lootId) public payable nonReentrant {
        require(lootContract.ownerOf(lootId) == msg.sender, "This Loot is not owned by the minter");
        require(lootersPrice <= msg.value, "Not enough Ether sent");
        require(currentSupply < maxSupply, "All pets are minted");
        _safeMint(msg.sender, currentSupply);
        currentSupply += 1;
    }

    // Public minting
    function mint() public payable nonReentrant {
        require(publicPrice <= msg.value, "Not enough Ether sent");
        require(currentSupply < maxSupply, "All pets are minted");

        _safeMint(msg.sender, currentSupply);
        currentSupply += 1;
    }

    function toString(uint256 value) internal pure returns (string memory) {
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

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory rarity = getRarity(tokenId);

        string memory info = " font-family: serif; font-size: 14px; ";
        string[7] memory parts;
        parts[0] = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.Godly { fill: white;', info,'}.Hellish { fill: white;', info, '}.Mythical { fill: #e8b23d; ', info, '}.Legendary { fill: #e8b23d;', info, ' }.Epic { fill: #b935d2;', info, abi.encodePacked(' }.Rare { fill: #6699cc;', info, '}.Common { fill: #6a7b7e;', info, '}',' }.base { fill: white;', info, '},</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="', rarity, '">')));

        parts[1] = rarity;

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getType(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getMood(tokenId);

        parts[6] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        //output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Pet #', toString(tokenId), '", "description": "Pets are randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Pets in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '","attributes":[{"trait_type":"Rarity","value":"', parts[1], '"},{"trait_type":"Type","value": "', parts[3], '"},{"trait_type": "Mood","value": "', parts[5], '"}]}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
}