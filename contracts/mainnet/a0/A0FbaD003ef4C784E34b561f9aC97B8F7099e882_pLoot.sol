// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTProjectERC721{
  function balanceOf(address) external view returns (uint256) {}
}

contract CryptoPunkSC{
  mapping (address => uint256) public balanceOf;
}

contract pLoot is ERC721Enumerable, ReentrancyGuard, Ownable {
    // Private Variables
    uint256 public maxSupply = 7700;
    uint256 public devAllocation = 300;

    // NFT Allocation
    uint256 public maxPerAddress = 20;
    
    // Define Struct
    struct smartContractDetails { 
      address smartContractAddress;
      uint8 smartContractType; // 0  ERC-721, 1 CryptoPunks
    }

    //Smart Contract's Address mapping
    mapping(string => smartContractDetails) public smartContractAddresses;

    // Loot Packs
    string[] private lootPack1 = [
      "PEGZ",
      "Meebits",
      "Deafbeef",
      "CryptoPunks",
      "Autoglyphs",
      "Avid Lines",
      "Bored Ape Yacht Club",
      "BEEPLE - GENESIS COLLECTION",
      "Damien Hirst - The Currency"
    ];

    string[] private lootPack2 = [
      "Blitmap",
      "VeeFriends",
      "The Sevens",
      "PUNKS Comic",
      "MetaHero Universe",
      "Bored Ape Kennel Club",
      "Loot (for Adventurers)",
      "Mutant Ape Yacht Club",
      "The Mike Tyson NFT Collection"
    ];
    
    string[] private lootPack3 = [
      "0N1 Force",
      "CyberKongz",
      "The n Project",
      "Cryptovoxels",
      "Cool Cats NFT",
      "World of Women",
      "Pudgy Penguins",
      "Solvency by Ezra Miller",
      "Tom Sachs Rocket Factory"
    ];
    
    string[] private lootPack4 = [
      "Chiptos",
      "SupDucks",
      "Hashmasks",
      "FLUF World",
      "Lazy Lions",
      "Plasma Bears",
      "SpacePunksClub",
      "The Doge Pound",
      "Rumble Kong League"
    ];
    
    string[] private lootPack5 = [
      "GEVOLs",
      "Stoner Cats",
      "The CryptoDads",
      "BullsOnTheBlock",
      "Wicked Ape Bone Club",
      "BASTARD GAN PUNKS V2",
      "Bloot (not for Weaks)",
      "Lonely Alien Space Club",
      "Koala Intelligence Agency"
    ];
    
    string[] private lootPack6 = [
      "thedudes",
      "Super Yeti",
      "Spookies NFT",
      "Arabian Camels",
      "Untamed Elephants",
      "Rogue Society Bots",
      "Slumdoge Billionaires",
      "Crypto-Pills by Micha Klein",
      "Official MoonCats - Acclimated"
    ];
    
    string[] private lootPack7 = [
      "GOATz",
      "Sushiverse",
      "FusionApes",
      "CHIBI DINOS",
      "DystoPunks V2",
      "The Alien Boy",
      "LightSuperBunnies",
      "Creature World NFT",
      "SympathyForTheDevils"
    ];
    
    string[] private lootPack8 = [
      "Chubbies",
      "Animetas",
      "DeadHeads",
      "Incognito",
      "Party Penguins",
      "Krazy Koalas NFT",
      "Crazy Lizard Army",
      "Goons of Balatroon",
      "The Vogu Collective"
    ];

    // Constructor
    constructor() ERC721("pLoot (for NFT Collectors)", "pLoot") Ownable() 
    {
      initSmartContractMapping();
    }

    function initSmartContractMapping() private
    { 
      // Initialize smart contract Mapping
      smartContractAddresses["Bored Ape Yacht Club"] = smartContractDetails(address(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D),0);
      smartContractAddresses["Meebits"] = smartContractDetails(address(0x7Bd29408f11D2bFC23c34f18275bBf23bB716Bc7),0);
      smartContractAddresses["Deafbeef"] = smartContractDetails(address(0xd754937672300Ae6708a51229112dE4017810934),1);
      smartContractAddresses["CryptoPunks"] = smartContractDetails(address(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB),0);
      smartContractAddresses["Autoglyphs"] = smartContractDetails(address(0xd4e4078ca3495DE5B1d4dB434BEbc5a986197782),0);
      smartContractAddresses["Avid Lines"] = smartContractDetails(address(0xDFAcD840f462C27b0127FC76b63e7925bEd0F9D5),0);
      smartContractAddresses["PEGZ"] = smartContractDetails(address(0x1eFf5ed809C994eE2f500F076cEF22Ef3fd9c25D),0);
      smartContractAddresses["BEEPLE - GENESIS COLLECTION"] = smartContractDetails(address(0x12F28E2106CE8Fd8464885B80EA865e98b465149),0);
      smartContractAddresses["Damien Hirst - The Currency"] = smartContractDetails(address(0xaaDc2D4261199ce24A4B0a57370c4FCf43BB60aa),0);
      smartContractAddresses["Blitmap"] = smartContractDetails(address(0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63),0);
      smartContractAddresses["VeeFriends"] = smartContractDetails(address(0xa3AEe8BcE55BEeA1951EF834b99f3Ac60d1ABeeB),0);
      smartContractAddresses["PUNKS Comic"] = smartContractDetails(address(0xd0A07a76746707f6D6d36D9d5897B14a8e9ED493),0);
      smartContractAddresses["Bored Ape Kennel Club"] = smartContractDetails(address(0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623),0);
      smartContractAddresses["The Sevens"] = smartContractDetails(address(0xf497253C2bB7644ebb99e4d9ECC104aE7a79187A),0);
      smartContractAddresses["Loot (for Adventurers)"] = smartContractDetails(address(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7),0);
      smartContractAddresses["Mutant Ape Yacht Club"] = smartContractDetails(address(0x60E4d786628Fea6478F785A6d7e704777c86a7c6),0);
      smartContractAddresses["MetaHero Universe"] = smartContractDetails(address(0x6dc6001535e15b9def7b0f6A20a2111dFA9454E2),0);
      smartContractAddresses["The Mike Tyson NFT Collection"] = smartContractDetails(address(0x40fB1c0f6f73B9fc5a81574FF39d27e0Ba06b17b),0);
      smartContractAddresses["0N1 Force"] = smartContractDetails(address(0x3bf2922f4520a8BA0c2eFC3D2a1539678DaD5e9D),0);
      smartContractAddresses["CyberKongz"] = smartContractDetails(address(0x57a204AA1042f6E66DD7730813f4024114d74f37),0);
      smartContractAddresses["The n Project"] = smartContractDetails(address(0x05a46f1E545526FB803FF974C790aCeA34D1f2D6),0);
      smartContractAddresses["Cryptovoxels"] = smartContractDetails(address(0x79986aF15539de2db9A5086382daEdA917A9CF0C),0);
      smartContractAddresses["Cool Cats NFT"] = smartContractDetails(address(0x1A92f7381B9F03921564a437210bB9396471050C),0);
      smartContractAddresses["World of Women"] = smartContractDetails(address(0xe785E82358879F061BC3dcAC6f0444462D4b5330),0);
      smartContractAddresses["Pudgy Penguins"] = smartContractDetails(address(0xBd3531dA5CF5857e7CfAA92426877b022e612cf8),0);
      smartContractAddresses["Solvency by Ezra Miller"] = smartContractDetails(address(0x82262bFba3E25816b4C720F1070A71C7c16A8fc4),0);
      smartContractAddresses["Tom Sachs Rocket Factory"] = smartContractDetails(address(0x11595fFB2D3612d810612e34Bc1C2E6D6de55d26),0);
      smartContractAddresses["Rumble Kong League"] = smartContractDetails(address(0xEf0182dc0574cd5874494a120750FD222FdB909a),0);
      smartContractAddresses["Chiptos"] = smartContractDetails(address(0xf3ae416615A4B7c0920CA32c2DfebF73d9D61514),0);
      smartContractAddresses["SupDucks"] = smartContractDetails(address(0x3Fe1a4c1481c8351E91B64D5c398b159dE07cbc5),0);
      smartContractAddresses["Hashmasks"] = smartContractDetails(address(0xC2C747E0F7004F9E8817Db2ca4997657a7746928),0);
      smartContractAddresses["SpacePunksClub"] = smartContractDetails(address(0x45DB714f24f5A313569c41683047f1d49e78Ba07),0);
      smartContractAddresses["The Doge Pound"] = smartContractDetails(address(0xF4ee95274741437636e748DdAc70818B4ED7d043),0);
      smartContractAddresses["Lazy Lions"] = smartContractDetails(address(0x8943C7bAC1914C9A7ABa750Bf2B6B09Fd21037E0),0);
      smartContractAddresses["Plasma Bears"] = smartContractDetails(address(0x909899c5dBb5002610Dd8543b6F638Be56e3B17E),0);
      smartContractAddresses["FLUF World"] = smartContractDetails(address(0xCcc441ac31f02cD96C153DB6fd5Fe0a2F4e6A68d),0);
      smartContractAddresses["GEVOLs"] = smartContractDetails(address(0x34b4Df75a17f8B3a6Eff6bBA477d39D701f5e92c),0);
      smartContractAddresses["Stoner Cats"] = smartContractDetails(address(0xD4d871419714B778eBec2E22C7c53572b573706e),0);
      smartContractAddresses["The CryptoDads"] = smartContractDetails(address(0xECDD2F733bD20E56865750eBcE33f17Da0bEE461),0);
      smartContractAddresses["BullsOnTheBlock"] = smartContractDetails(address(0x3a8778A58993bA4B941f85684D74750043A4bB5f),0);
      smartContractAddresses["Wicked Ape Bone Club"] = smartContractDetails(address(0xbe6e3669464E7dB1e1528212F0BfF5039461CB82),0);
      smartContractAddresses["BASTARD GAN PUNKS V2"] = smartContractDetails(address(0x31385d3520bCED94f77AaE104b406994D8F2168C),0);
      smartContractAddresses["Bloot (not for Weaks)"] = smartContractDetails(address(0x4F8730E0b32B04beaa5757e5aea3aeF970E5B613),0);
      smartContractAddresses["Lonely Alien Space Club"] = smartContractDetails(address(0x343f999eAACdFa1f201fb8e43ebb35c99D9aE0c1),0);
      smartContractAddresses["Koala Intelligence Agency"] = smartContractDetails(address(0x3f5FB35468e9834A43dcA1C160c69EaAE78b6360),0);
      smartContractAddresses["Super Yeti"] = smartContractDetails(address(0x3F0785095A660fEe131eEbcD5aa243e529C21786),0);
      smartContractAddresses["Spookies NFT"] = smartContractDetails(address(0x5e34dAcDa29837F2f220D3d1aEAAabD1eDCa5BD1),0);
      smartContractAddresses["Arabian Camels"] = smartContractDetails(address(0x3B3Bc9b1dD9F3C8716Fff083947b8769e2ff9781),0);
      smartContractAddresses["Untamed Elephants"] = smartContractDetails(address(0x613E5136a22206837D12eF7A85f7de2825De1334),0);
      smartContractAddresses["Rogue Society Bots"] = smartContractDetails(address(0xc6735852E181A55F736e9Db62831Dc63ef8C449a),0);
      smartContractAddresses["Slumdoge Billionaires"] = smartContractDetails(address(0x312d09D1160316A0946503391B3D1bcBC583181b),0);
      smartContractAddresses["Crypto-Pills by Micha Klein"] = smartContractDetails(address(0x7DD04448c6CD405345D03529Bff9749fd89F8F4F),0);
      smartContractAddresses["Official MoonCats - Acclimated"] = smartContractDetails(address(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69),0);
      smartContractAddresses["thedudes"] = smartContractDetails(address(0xB0cf7Da8dc482997525BE8488B9caD4F44315422),0);
      smartContractAddresses["Sushiverse"] = smartContractDetails(address(0x06aF447c72E18891FB65450f41134C00Cf7Ac28c),0);
      smartContractAddresses["FusionApes"] = smartContractDetails(address(0xEA6504BA9ec2352133e6A194bB35ad4B1a3b68e7),0);
      smartContractAddresses["CHIBI DINOS"] = smartContractDetails(address(0xe12EDaab53023c75473a5A011bdB729eE73545e8),0);
      smartContractAddresses["DystoPunks V2"] = smartContractDetails(address(0xbEA8123277142dE42571f1fAc045225a1D347977),0);
      smartContractAddresses["The Alien Boy"] = smartContractDetails(address(0x4581649aF66BCCAeE81eebaE3DDc0511FE4C5312),0);
      smartContractAddresses["LightSuperBunnies"] = smartContractDetails(address(0x3a3fBa79302144f06f49ffde69cE4b7F6ad4DD3d),0);
      smartContractAddresses["Creature World NFT"] = smartContractDetails(address(0xc92cedDfb8dd984A89fb494c376f9A48b999aAFc),0);
      smartContractAddresses["SympathyForTheDevils"] = smartContractDetails(address(0x36d02DcD463Dfd71E4a07d8Aa946742Da94e8D3a),0);
      smartContractAddresses["GOATz"] = smartContractDetails(address(0x3EAcf2D8ce91b35c048C6Ac6Ec36341aaE002FB9),0);
      smartContractAddresses["Chubbies"] = smartContractDetails(address(0x1DB61FC42a843baD4D91A2D788789ea4055B8613),0);
      smartContractAddresses["Animetas"] = smartContractDetails(address(0x18Df6C571F6fE9283B87f910E41dc5c8b77b7da5),0);
      smartContractAddresses["DeadHeads"] = smartContractDetails(address(0x6fC355D4e0EE44b292E50878F49798ff755A5bbC),0);
      smartContractAddresses["Party Penguins"] = smartContractDetails(address(0x31F3bba9b71cB1D5e96cD62F0bA3958C034b55E9),0);
      smartContractAddresses["Krazy Koalas NFT"] = smartContractDetails(address(0x8056aD118916db0fEef1c8B82744Fa37E5d57CC0),0);
      smartContractAddresses["Crazy Lizard Army"] = smartContractDetails(address(0x86f6Bf16F495AFc065DA4095Ac12ccD5e83a8c85),0);
      smartContractAddresses["Goons of Balatroon"] = smartContractDetails(address(0x8442DD3e5529063B43C69212d64D5ad67B726Ea6),0);
      smartContractAddresses["The Vogu Collective"] = smartContractDetails(address(0x18c7766A10df15Df8c971f6e8c1D2bbA7c7A410b),0);
      smartContractAddresses["Incognito"] = smartContractDetails(address(0x3F4a885ED8d9cDF10f3349357E3b243F3695b24A),0);
    }

    // Balance Check
    function checkHodler(uint256 tokenID, string memory projectName) public view returns (bool)
    {
      address hodlerAddress = ownerOf(tokenID);
      if (smartContractAddresses[projectName].smartContractType == 0)
      {
        NFTProjectERC721 projInstance = NFTProjectERC721(smartContractAddresses[projectName].smartContractAddress);
        if (projInstance.balanceOf(hodlerAddress) > 0)
        {
          return true;
        }
        else
        {
          return false;
        }
      }
      else if (smartContractAddresses[projectName].smartContractType == 1)
      {
        CryptoPunkSC projInstance = CryptoPunkSC(smartContractAddresses[projectName].smartContractAddress);
        if (projInstance.balanceOf(hodlerAddress) > 0)
        {
          return true;
        }
        else
        {
          return false;
        }
      }
      else
      {
        revert("Invalid Contract Details!");
      }
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getLoot1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack1", lootPack1);
    }
    
    function getLoot2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack2", lootPack2);
    }
    
    function getLoot3(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack3", lootPack3);
    }
    
    function getLoot4(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack4", lootPack4);
    }

    function getLoot5(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack5", lootPack5);
    }
    
    function getLoot6(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack6", lootPack6);
    }
    
    function getLoot7(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack7", lootPack7);
    }
    
    function getLoot8(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LootPack8", lootPack8);
    }
    
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        
        bool diamondHands = true;
        
        string[2] memory spanStrings;
        
        spanStrings[0] = '</tspan><tspan x="40" dy="1.4em">';
        
        spanStrings[1] = '</tspan><tspan x="275" dy="1.4em">';

        string[36] memory parts;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base{fill:white;font-family:ui-monospace;font-size:14px}</style><style>.black{fill:black;font-family:ui-monospace;font-size:14px}</style><g id="columnGroup"> <rect width="100%" height="100%" fill="black" /> <text y="60" font-size="15px" class="base"> <tspan x="23" dy="1em">';

        parts[1] = toAsciiString(ownerOf(tokenId));

        parts[2] = '</tspan></text><line x1="30" y1="90" x2="300" y2="90" stroke="white" class="base" stroke-width="1.5"/><text x="100" y="100" font-size="15px" class="base"><tspan x="40" dy="1.25em">';
        
        parts[3] = getLoot1(tokenId);

        parts[4] = spanStrings[0];

        parts[5] = getLoot2(tokenId);
      
        parts[6] = spanStrings[0];

        parts[7] = getLoot3(tokenId);
        
        parts[8] = spanStrings[0];

        parts[9] = getLoot4(tokenId);

        parts[10] = spanStrings[0];

        parts[11] = getLoot5(tokenId);

        parts[12] = spanStrings[0];

        parts[13] = getLoot6(tokenId);

        parts[14] = spanStrings[0];

        parts[15] = getLoot7(tokenId);

        parts[16] = spanStrings[0];

        parts[17] = getLoot8(tokenId);

        parts[18] = '</tspan></text><text x="100" y="100" font-size="15px" class="black"><tspan x="275" dy="1.25em">';

        if (checkHodler(tokenId, getLoot1(tokenId)))
        {
          parts[19] = unicode'✅';
        }
        else
        {
          parts[19] = 'X';
          diamondHands = false;
        }

        parts[20] = spanStrings[1];

        if (checkHodler(tokenId, getLoot2(tokenId)))
        {
          parts[21] = unicode'✅';
        }
        else
        {
          parts[21] = 'X';
          diamondHands = false;
        }

        parts[22] = spanStrings[1];

        if (checkHodler(tokenId, getLoot3(tokenId)))
        {
          parts[23] = unicode'✅';
        }
        else
        {
          parts[23] = 'X';
          diamondHands = false;
        }

        parts[24] = spanStrings[1];

        if (checkHodler(tokenId, getLoot4(tokenId)))
        {
          parts[25] = unicode'✅';
        }
        else
        {
          parts[25] = 'X';
          diamondHands = false;
        }

        parts[26] = spanStrings[1];

        if (checkHodler(tokenId, getLoot5(tokenId)))
        {
          parts[27] = unicode'✅';
        }
        else
        {
          parts[27] = 'X';
          diamondHands = false;
        }

        parts[28] = spanStrings[1];

        if (checkHodler(tokenId, getLoot6(tokenId)))
        {
          parts[29] = unicode'✅';
        }
        else
        {
          parts[29] = 'X';
          diamondHands = false;
        }

        parts[30] = spanStrings[1];

        if (checkHodler(tokenId, getLoot7(tokenId)))
        {
          parts[31] = unicode'✅';
        }
        else
        {
          parts[32] = 'X';
          diamondHands = false;
        }

        parts[33] = spanStrings[1];

        if (checkHodler(tokenId, getLoot8(tokenId)))
        {
          parts[34] = unicode'✅';
        }
        else
        {
          parts[34] = 'X';
          diamondHands = false;
        }
        
        if (diamondHands)
        {
            parts[35] = unicode'</tspan></text><text x="150" y="280" font-size="15px" class="black"> <tspan>💎🙌</tspan></text></g></svg>';
        }
        else 
        {
            parts[35] = '</tspan></text></g></svg>'; 
        }
        
        string memory output = string(abi.encodePacked(parts[0], '0x', parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        output = string(abi.encodePacked(output, parts[17], parts[18], parts[19], parts[20], parts[21], parts[22], parts[23], parts[24]));
        output = string(abi.encodePacked(output, parts[25], parts[26], parts[27], parts[28], parts[29], parts[30], parts[31], parts[32]));
        output = string(abi.encodePacked(output, parts[33], parts[34], parts[35]));

        string memory json = Base64.encode(
                  bytes(string(
                    abi.encodePacked(
                      '{"name": "Loot Bag #', toString(tokenId), 
                      '", "description": "pLoot is a personalised & randomized adventurer gear for NFT collectors generated and stored on chain. Collect NFTs in the loot bag & refresh metadata to get green ticks. Collect all of the NFTs in the loot bag to get diamond hands!", "image": "data:image/svg+xml;base64,',
                      Base64.encode(bytes(output)),
                      '"}'))));
        
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function tokensOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 count = balanceOf(_owner);
        uint256[] memory result = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }

    // Mint Function
    function claimFreeLootBag(uint256 qty) public {
        require((qty + balanceOf(msg.sender)) <= maxPerAddress, "You have reached your minting limit.");
        require((qty + totalSupply()) <= maxSupply, "Qty exceeds total supply.");
        // Mint the NFTs
        for (uint256 i = 0; i < qty; i++) 
        {
          uint256 mintIndex = totalSupply();
          _safeMint(msg.sender, mintIndex);
        }
    }

    // Pure Helper functions
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

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

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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

    // Admin Functions
    function modifySmartContractAddressMap(string memory projectName, address projAddress, uint8 projType) public onlyOwner {
      smartContractAddresses[projectName] = smartContractDetails(projAddress,projType);
    }

    function deleteSmartContractAddressMap(string memory projectName) public onlyOwner {
      delete smartContractAddresses[projectName];
    }

    function devCreateLootBag(uint256 qty) public onlyOwner {
        require(totalSupply() >= maxSupply, "Dev not allowed to mint!");
        require((totalSupply() + qty) <= (maxSupply + devAllocation), "Dev allocation exceeded!");
        for (uint256 i = 0; i < qty; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    // Withdraw function
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Receive ether function
    receive() external payable {} 
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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

