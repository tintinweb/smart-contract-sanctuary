// contracts/BittyBots.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./UIntArrays.sol";

/**
 * 
 * ╔══╦╦══╦══╦═╦╦══╦═╦══╦══╗
 * ║╔╗╠╬╗╔╩╗╔╩╗║║╔╗║║╠╗╔╣══╣
 * ║╔╗║║║║─║║╔╩╗║╔╗║║║║║╠══║
 * ╚══╩╝╚╝─╚╝╚══╩══╩═╝╚╝╚══╝
 *
 * This contract was written by solazy.eth (twitter.com/_solazy). 
 * https://bittybots.io
 * © BittyBots NFT LLC. All rights reserved 
 */

interface IChubbies {
    function ownerOf(uint tokenId) external view returns (address owner);
    function tokensOfOwner(address _owner) external view returns(uint[] memory);
}

interface IJusticeToken {
    function burnFrom(address account, uint256 amount) external;
    function updateLastWithdrawTime(uint _tokenId) external;
}

contract BittyBots is ERC721Enumerable, Ownable  {
    // Generation Related Variables
    struct BittyBot {
        uint helmet;
        uint body;
        uint face;
        uint arms;
        uint engine;
        uint botType;
        uint accessories;
        uint setModifier;
        uint combinedCount;
        uint powerClass;
        uint power;
    }

    mapping(bytes32 => uint) private hashToTokenId;
    mapping(uint => uint) private bittyBots;
    mapping(uint256 => uint256[]) public combinations;

    uint public constant NUM_TRAITS = 7;
    uint public constant NUM_CORE_TRAITS = 6;
    uint public constant NUM_MODELS = 16;
    uint public combinedId = 20000;

    uint public constant TRAIT_INDEX_HELMET = 0;
    uint public constant TRAIT_INDEX_BODY = 1;
    uint public constant TRAIT_INDEX_FACE = 2;
    uint public constant TRAIT_INDEX_ARMS = 3;
    uint public constant TRAIT_INDEX_ENGINE = 4;
    uint public constant TRAIT_INDEX_TYPE = 5;
    uint public constant TRAIT_INDEX_ACCESSORIES = 6;

    uint[NUM_TRAITS] private traitSizes;
    uint[NUM_TRAITS] private traitCounts;
    uint[NUM_TRAITS] private traitRemaining;
    uint public specialBotRemaining;
    
    uint private fallbackModelProbabilities;
    uint private fallbackEngineProbabilities;

    bytes32[NUM_TRAITS] public traitCategories;
    bytes32[][NUM_TRAITS] public traitNames;

    event BittyBotMinted(
        uint indexed tokenId,
        uint[] traits, 
        uint setModifier,
        uint combinedCount,
        uint powerClass,
        uint power
    );

    // ERC721 Sales Related Variables
    uint public constant TOKEN_LIMIT = 20000;
    uint private constant RESERVE_LIMIT = 500;
    uint private constant MAX_CHUBBIES = 10000;
    uint internal constant PRICE = 35000000000000000;

    bool public isSaleActive = false;
    bool public isFreeClaimActive = false;
    bool public isFinalSaleActive = false;

    IChubbies public chubbiesContract;
    IJusticeToken public justiceTokenContract;

    uint public numSold = 0;
    uint public numClaimed = 2;

    string private _baseTokenURI;

    // Withdraw Addresses
    address payable private solazy;
    address payable private kixboy;

    constructor() ERC721("BittyBots","BITTY")  {
        traitSizes = [NUM_MODELS, NUM_MODELS, NUM_MODELS, NUM_MODELS, 10, 4, 7];

        uint[] memory modelDistribution = new uint[](traitSizes[TRAIT_INDEX_HELMET]);
        uint[] memory engineDistribution = new uint[](traitSizes[TRAIT_INDEX_ENGINE]);
        uint[] memory typeDistribution = new uint[](traitSizes[TRAIT_INDEX_TYPE]);
        uint[] memory accessoryDistribution = new uint[](traitSizes[TRAIT_INDEX_ACCESSORIES]);
        uint[] memory specialModelDistribution = new uint[](traitSizes[TRAIT_INDEX_HELMET]);

        traitCounts[TRAIT_INDEX_HELMET] = UIntArrays.packedUintFromArray(modelDistribution);
        traitCounts[TRAIT_INDEX_BODY] = UIntArrays.packedUintFromArray(modelDistribution);
        traitCounts[TRAIT_INDEX_FACE] = UIntArrays.packedUintFromArray(modelDistribution);
        traitCounts[TRAIT_INDEX_ARMS] = UIntArrays.packedUintFromArray(modelDistribution);
        traitCounts[TRAIT_INDEX_ENGINE] = UIntArrays.packedUintFromArray(engineDistribution);
        traitCounts[TRAIT_INDEX_TYPE] = UIntArrays.packedUintFromArray(typeDistribution);
        traitCounts[TRAIT_INDEX_ACCESSORIES] = UIntArrays.packedUintFromArray(accessoryDistribution);

        modelDistribution[0] = 4; 
        for (uint i = 1; i < 13; i++) {
            modelDistribution[i] = 1600; 
        }
        modelDistribution[13] = 360; 
        modelDistribution[14] = 240;
        modelDistribution[15] = 151; 
        for (uint i = 1; i < specialModelDistribution.length; i++) {
            specialModelDistribution[i] = 3; 
        }
        engineDistribution[0] = 4800;
        engineDistribution[1] = 4000;
        engineDistribution[2] = 3200;
        engineDistribution[3] = 2400;
        engineDistribution[4] = 1600;
        engineDistribution[5] = 1600;
        engineDistribution[6] = 1200;
        engineDistribution[7] = 555;
        engineDistribution[8] = 400;
        engineDistribution[9] = 200;
        typeDistribution[0] = 19955;
        typeDistribution[1] = 15;
        typeDistribution[2] = 15;
        typeDistribution[3] = 15;
        accessoryDistribution[0] = 19335;
        accessoryDistribution[1] = 200;
        accessoryDistribution[2] = 200;
        accessoryDistribution[3] = 100;
        accessoryDistribution[4] = 100;
        accessoryDistribution[5] = 10;
        accessoryDistribution[6] = 10;

        traitRemaining[TRAIT_INDEX_HELMET] = UIntArrays.packedUintFromArray(modelDistribution);
        traitRemaining[TRAIT_INDEX_BODY] = UIntArrays.packedUintFromArray(modelDistribution);
        traitRemaining[TRAIT_INDEX_FACE] = UIntArrays.packedUintFromArray(modelDistribution);
        traitRemaining[TRAIT_INDEX_ARMS] = UIntArrays.packedUintFromArray(modelDistribution);
        traitRemaining[TRAIT_INDEX_ENGINE] = UIntArrays.packedUintFromArray(engineDistribution);
        traitRemaining[TRAIT_INDEX_TYPE] = UIntArrays.packedUintFromArray(typeDistribution);
        traitRemaining[TRAIT_INDEX_ACCESSORIES] = UIntArrays.packedUintFromArray(accessoryDistribution);
        specialBotRemaining = UIntArrays.packedUintFromArray(specialModelDistribution);

        fallbackModelProbabilities = UIntArrays.packedUintFromArray(modelDistribution);
        fallbackEngineProbabilities = UIntArrays.packedUintFromArray(engineDistribution);

        traitCategories = [
            bytes32("Helmet"),
            bytes32("Body"),
            bytes32("Face"),
            bytes32("Arms"),
            bytes32("Engine"),
            bytes32("Type"), 
            bytes32("Accessory")
        ];

        bytes32[NUM_MODELS] memory modelNames = [
            bytes32("MXX Torva"),
            bytes32("M01 Ava"),
            bytes32("M02 Shadow King"),
            bytes32("M03 Eni"),
            bytes32("M04 Ultra 7.1"),
            bytes32("M05 Titan"),
            bytes32("M06 Solar Phantom"),
            bytes32("M07 Cyberkat"),
            bytes32("M08 Ziggy"),
            bytes32("M09 Bakken"),
            bytes32("M10 Supaiku"),
            bytes32("M11 Neo"),
            bytes32("M12 Leapor"),
            bytes32("M13 Jupiter"),
            bytes32("M14 Mercury"),
            bytes32("M15 Morpheus")
        ];

        traitNames[TRAIT_INDEX_HELMET] = modelNames;
        traitNames[TRAIT_INDEX_BODY] = modelNames;
        traitNames[TRAIT_INDEX_ARMS] = modelNames;
        traitNames[TRAIT_INDEX_FACE] = modelNames;
        traitNames[TRAIT_INDEX_ENGINE] = [
            bytes32("Love"),
            bytes32("Fire"),
            bytes32("Starshine"),
            bytes32("Luna"),
            bytes32("Solaris"),
            bytes32("Diamond"),
            bytes32("Death"),
            bytes32("Lightning"), // lightning effect
            bytes32("Variable"), // glitch effect
            bytes32("Harmony"), // shiny effect
            bytes32("Error"), // glitchbot
            bytes32("Solid Gold"), // goldbot
            bytes32("Divinity") // godbot
        ];
        traitNames[TRAIT_INDEX_TYPE] = [
            bytes32("Classic"),
            bytes32("Glitch"),
            bytes32("Gold"),
            bytes32("God")
        ];
        traitNames[TRAIT_INDEX_ACCESSORIES] = [
            bytes32("None"),
            bytes32("Bomb"),
            bytes32("Exios Gem"),
            bytes32("Tuera Beam"),
            bytes32("Galactic Visor"),
            bytes32("BB1"),
            bytes32("Hacker Mode")
        ];

        _mintReservedGodBot(msg.sender, 0); // Chubbie #0
        _mintReservedGodBot(msg.sender, 9999); // #Chubbie #9999
        _mintReservedGodBot(msg.sender, 10000);
    }

    // BittyBot helpers

    // Packing optimization to save gas
    function setBittyBot(
        uint _tokenId,
        uint[] memory _traits,
        uint _setModifier,
        uint _combinedCount,
        uint _powerClass,
        uint _power
    ) internal {
        uint bittyBot = _traits[0];
        bittyBot |= _traits[1] << 8;
        bittyBot |= _traits[2] << 16;
        bittyBot |= _traits[3] << 24;
        bittyBot |= _traits[4] << 32;
        bittyBot |= _traits[5] << 40;
        bittyBot |= _traits[6] << 48;
        bittyBot |= _setModifier << 56;
        bittyBot |= _combinedCount << 64;
        bittyBot |= _powerClass << 72;
        bittyBot |= _power << 80;

        bittyBots[_tokenId] = bittyBot; 
    }

    function getBittyBot(uint _tokenId) internal view returns (BittyBot memory _bot) {
        uint bittyBot = bittyBots[_tokenId];
        _bot.helmet = uint256(uint8(bittyBot));
        _bot.body = uint256(uint8(bittyBot >> 8));
        _bot.face = uint256(uint8(bittyBot >> 16));
        _bot.arms = uint256(uint8(bittyBot >> 24));
        _bot.engine = uint256(uint8(bittyBot >> 32));
        _bot.botType = uint256(uint8(bittyBot >> 40));
        _bot.accessories = uint256(uint8(bittyBot >> 48));
        _bot.setModifier = uint256(uint8(bittyBot >> 56));
        _bot.combinedCount = uint256(uint8(bittyBot >> 64));
        _bot.powerClass = uint256(uint8(bittyBot >> 72));
        _bot.power = uint256(uint16(bittyBot >> 80));
    }

    function getTraitRemaining(uint _index) public view returns (uint[] memory) {
        return UIntArrays.arrayFromPackedUint(traitRemaining[_index], traitSizes[_index]);
    }

    function getTraitCounts(uint _index) public view returns (uint[] memory) {
        return UIntArrays.arrayFromPackedUint(traitCounts[_index], traitSizes[_index]);
    }

    // Hash is only determined by core traits and type
    function bittyHash(uint[] memory _traits) public pure returns (bytes32) {
        return UIntArrays.hash(_traits, NUM_CORE_TRAITS);
    }

    function isBotAvailable(uint _claimId) public view returns (bool) {
        return bittyBots[_claimId] == 0;
    }

    function isSpecialBot(uint[] memory _traits) public pure returns (bool) {
        return _traits[TRAIT_INDEX_TYPE] > 0;
    }

    function existTraits(uint[] memory _traits) public view returns (bool) {
        return tokenIdFromTraits(_traits) != 0;
    }

    function tokenIdFromTraits(uint[] memory _traits) public view returns (uint) {
        return hashToTokenId[bittyHash(_traits)];
    }

    function traitsForTokenId(uint _tokenId) public view returns (
        uint[] memory _traits, 
        uint _setModifier, 
        uint _combinedCount,
        uint _powerClass,
        uint _power
    ) {
        (_traits, _setModifier, _combinedCount, _powerClass, _power) = traitsFromBot(getBittyBot(_tokenId));
    }

    function traitsFromBot(BittyBot memory _bot) internal pure returns (
        uint[] memory _traits, 
        uint _setModifier, 
        uint _combinedCount, 
        uint _powerClass, 
        uint _power
    ) {
        _traits = new uint[](NUM_TRAITS);
        _traits[TRAIT_INDEX_HELMET] = _bot.helmet;
        _traits[TRAIT_INDEX_BODY] = _bot.body;
        _traits[TRAIT_INDEX_FACE] = _bot.face;
        _traits[TRAIT_INDEX_ARMS] = _bot.arms;
        _traits[TRAIT_INDEX_ENGINE] = _bot.engine;
        _traits[TRAIT_INDEX_TYPE] = _bot.botType;
        _traits[TRAIT_INDEX_ACCESSORIES] = _bot.accessories;

        _setModifier = _bot.setModifier;
        _combinedCount = _bot.combinedCount;
        _powerClass = _bot.powerClass;
        _power = _bot.power;
    }

    function strConcat(string memory _a, string memory _b) internal pure returns(string memory) {
        return string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function _mintBot(address _sendTo, uint _tokenId) internal {
        // 1. Try to get random traits from remaining
        uint dna = uint(keccak256(abi.encodePacked(msg.sender, _tokenId, block.difficulty, block.timestamp)));
        uint[] memory traits = randomTraits(dna);
        
        // 2. Try reroll with fixed probabillity model if we hit a duplicate (0.0002% of happening)
        if (existTraits(traits)) {
            uint offset = 0;
            do {
                traits = randomFallbackTraits(dna, offset);
                offset += 1;
                require(offset < 5, "Rerolled traits but failed");
            } while (existTraits(traits));
        }
        
        bytes32 hash = bittyHash(traits);
        hashToTokenId[hash] = _tokenId;
        uint setModifier = setModifierForParts(traits);
        uint power = estimatePowerForBot(traits, new uint[](0), setModifier);
        uint powerClass = powerClassForPower(power);
        setBittyBot(
            _tokenId,
            traits,
            setModifier,
            0,
            powerClass,
            power
        );

        // 3. Update info maps with special treatments for special bots
        if (isSpecialBot(traits)) {
            traitRemaining[TRAIT_INDEX_TYPE] = UIntArrays.decrementPackedUint(traitRemaining[TRAIT_INDEX_TYPE], traits[TRAIT_INDEX_TYPE], 1);
            traitCounts[TRAIT_INDEX_TYPE] = UIntArrays.incrementPackedUint(traitCounts[TRAIT_INDEX_TYPE], traits[TRAIT_INDEX_TYPE], 1);
            specialBotRemaining = UIntArrays.decrementPackedUint(specialBotRemaining, traits[TRAIT_INDEX_HELMET], 1);
        } else {
            for (uint i = 0; i < traits.length; i++) {
                traitRemaining[i] = UIntArrays.decrementPackedUint(traitRemaining[i], traits[i], 1);
                traitCounts[i] = UIntArrays.incrementPackedUint(traitCounts[i], traits[i], 1);
            }
            combinations[_tokenId].push(_tokenId);
        }
        
        _safeMint(_sendTo, _tokenId);
        emit BittyBotMinted(_tokenId, traits, setModifier, 0, powerClass, power);
    }

    function _mintReservedGodBot(address _sendTo, uint _tokenId) internal {
        require(_tokenId == 0 || _tokenId == 9999 || _tokenId == 10000, "Reserved god bots are for 0, 9999, and 10000.");
        uint dna = uint(keccak256(abi.encodePacked(msg.sender, _tokenId, block.difficulty, block.timestamp)));
        uint[] memory traits = new uint[](NUM_TRAITS);
        uint specialType = uint(keccak256(abi.encodePacked(dna))) % 3 + 1;
        uint modelIndex = UIntArrays.randomIndexFromWeightedArray(UIntArrays.arrayFromPackedUint(specialBotRemaining, traitSizes[TRAIT_INDEX_HELMET]),  
                                                                      uint(keccak256(abi.encodePacked(dna))));
        traits[TRAIT_INDEX_TYPE] = specialType;
        for (uint i = 0; i < TRAIT_INDEX_TYPE; i++) {
            traits[i] = modelIndex;
        }
        traits[TRAIT_INDEX_ENGINE] = traits[TRAIT_INDEX_TYPE] + 9;
        traits[TRAIT_INDEX_ACCESSORIES] = 0;

        bytes32 hash = bittyHash(traits);
        hashToTokenId[hash] = _tokenId;
        uint setModifier = setModifierForParts(traits);
        uint power = estimatePowerForBot(traits, new uint[](0), setModifier);
        uint powerClass = powerClassForPower(power);

        setBittyBot(
            _tokenId,
            traits,
            setModifier,
            0,
            powerClass,
            power
        );

        traitRemaining[TRAIT_INDEX_TYPE] = UIntArrays.decrementPackedUint(traitRemaining[TRAIT_INDEX_TYPE], traits[TRAIT_INDEX_TYPE], 1);
        traitCounts[TRAIT_INDEX_TYPE] = UIntArrays.incrementPackedUint(traitCounts[TRAIT_INDEX_TYPE], traits[TRAIT_INDEX_TYPE], 1);
        specialBotRemaining = UIntArrays.decrementPackedUint(specialBotRemaining, traits[TRAIT_INDEX_HELMET], 1);

        _safeMint(_sendTo, _tokenId);
        emit BittyBotMinted(_tokenId, traits, setModifier, 0, powerClass, power);
    }

    function randomTraits(uint _dna) internal view returns (uint[] memory) {
        uint[] memory traits = new uint[](NUM_TRAITS);
        for (uint i = 0; i < traitRemaining.length; i++) {
            traits[i] = UIntArrays.randomIndexFromWeightedArray(UIntArrays.arrayFromPackedUint(traitRemaining[i], traitSizes[i]),
                                                                uint(keccak256(abi.encodePacked(_dna, i + 1))));
        }

        // Special Bot Treatment
        if (isSpecialBot(traits)) {
            uint modelIndex = UIntArrays.randomIndexFromWeightedArray(UIntArrays.arrayFromPackedUint(specialBotRemaining, traitSizes[TRAIT_INDEX_HELMET]),  
                                                                      uint(keccak256(abi.encodePacked(_dna))));
            for (uint i = 0; i < TRAIT_INDEX_TYPE; i++) {
                traits[i] = modelIndex;
            }
            traits[TRAIT_INDEX_ENGINE] = traits[TRAIT_INDEX_TYPE] + 9;
            traits[TRAIT_INDEX_ACCESSORIES] = 0;
        }

        return traits;
    }

    function randomFallbackTraits(uint _dna, uint _offset) internal view returns (uint[] memory) {
        uint[] memory traits = new uint[](NUM_TRAITS);

        for (uint i = 0; i < 4; i++) {
            traits[i] = UIntArrays.randomIndexFromWeightedArray(UIntArrays.arrayFromPackedUint(fallbackModelProbabilities, traitSizes[i]), 
                                                                uint(keccak256(abi.encodePacked(_dna, _offset * i))));
        }
        
        traits[TRAIT_INDEX_ENGINE] = UIntArrays.randomIndexFromWeightedArray(UIntArrays.arrayFromPackedUint(fallbackEngineProbabilities, traitSizes[TRAIT_INDEX_ENGINE]), 
                                                                             uint(keccak256(abi.encodePacked(_dna, _offset * TRAIT_INDEX_ENGINE))));
        return traits;
    }

    function metadata(uint _tokenId) public view returns (string memory resultString) {
        if (_exists(_tokenId) == false) {
            return '{}';
        }
        resultString = '{';
        BittyBot memory bot = getBittyBot(_tokenId);
        (
            uint[] memory traits, 
            uint setModifier, 
            uint combinedCount, 
            uint powerClass, 
            uint power
        ) = traitsFromBot(bot);

        for (uint i = 0; i < traits.length; i++) {
            if (i > 0) {
                resultString = strConcat(resultString, ', ');
            }
            resultString = strConcat(resultString, '"');
            resultString = strConcat(resultString, bytes32ToString(traitCategories[i]));
            resultString = strConcat(resultString, '": "');
            resultString = strConcat(resultString, bytes32ToString(traitNames[i][traits[i]]));
            resultString = strConcat(resultString, '"');
        }

        resultString = strConcat(resultString, ', ');

        string[] memory valueCategories = new string[](4);
        valueCategories[0] = 'Full Set';
        valueCategories[1] = 'Combined';
        valueCategories[2] = 'Power Class';
        valueCategories[3] = 'Power';
        uint[] memory values = new uint[](4);
        values[0] = setModifier;
        values[1] = combinedCount;
        values[2] = powerClass;
        values[3] = power;

        for (uint i = 0; i < valueCategories.length; i++) {
            if (i > 0) {
                resultString = strConcat(resultString, ', ');
            }
            resultString = strConcat(resultString, '"');
            resultString = strConcat(resultString, valueCategories[i]);
            resultString = strConcat(resultString, '": ');
            resultString = strConcat(resultString, Strings.toString(values[i]));
        }

        resultString = strConcat(resultString, '}');

        return resultString;
    }

    // COMBINE
    function isSelectedTraitsEligible(uint[] memory _selectedTraits, uint[] memory _selectedBots) public view returns (bool) {
        BittyBot memory bot;
        uint[] memory traits;

        for (uint traitIndex = 0; traitIndex < _selectedTraits.length; traitIndex++) {
            bool traitCheck = false;
            for (uint botIndex = 0; botIndex < _selectedBots.length; botIndex++) {
                bot = getBittyBot(_selectedBots[botIndex]);
                (traits, , , , ) = traitsFromBot(bot);

                if (traits[traitIndex] == _selectedTraits[traitIndex]) {
                    traitCheck = true;
                    break;
                }
            }
            if (traitCheck == false) {
                return false;
            }
        }

        return true;
    }

    function combineFee(uint _combinedCount) public pure returns (uint) {
        if (_combinedCount <= 1) {
            return 0;
        } else {
            return 200 ether * (2 ** (_combinedCount + 1));
        }
    }

    function combine(uint[] memory _selectedTraits, uint[] memory _selectedBots) external {
        // 1. check if bot already exists and not in selected bot
        require(_selectedTraits.length == NUM_TRAITS, "Malformed traits");
        require(_selectedBots.length < 6, "Cannot combine more than 5 bots");

        // 2. check traits is in selected bots
        require(isSelectedTraitsEligible(_selectedTraits, _selectedBots), "Traits not in bots");

        // 3. burn selected bots
        BittyBot memory bot;
        uint[] memory selectedBotTraits;
        uint[] memory traitsToDeduct = new uint[](NUM_TRAITS);
        uint maxCombinedCount = 0;
        uint combinedCount;
        combinations[combinedId].push(combinedId);
        for (uint i = 0; i < _selectedBots.length; i++) {
            require(_exists(_selectedBots[i]), "Selected bot doesn't exist");
            bot = getBittyBot(_selectedBots[i]);
            (selectedBotTraits, , combinedCount, , ) = traitsFromBot(bot);
            require(bot.botType == 0, "Special bots cannot be combined");

            if (combinedCount > maxCombinedCount) {
                maxCombinedCount = combinedCount;
            }

            for (uint j = 0; j < combinations[_selectedBots[i]].length; j++) {
                combinations[combinedId].push(combinations[_selectedBots[i]][j]);
            }

            for (uint j = 0; j < NUM_TRAITS; j++) {
                traitsToDeduct[j] = UIntArrays.incrementPackedUint(traitsToDeduct[j], selectedBotTraits[j], 1);
            }

            // remove hash so that the traits are freed
            delete hashToTokenId[bittyHash(selectedBotTraits)];

            _burn(_selectedBots[i]);
        }
        uint newCombinedCount = maxCombinedCount + 1;
        require(existTraits(_selectedTraits) == false, "Traits already exist");
        require(newCombinedCount < 4, "Cannot combine more than 3 times");

        // Pay fee in Justice Token
        if (newCombinedCount > 1) {
            uint fee = combineFee(newCombinedCount);
            justiceTokenContract.burnFrom(msg.sender, fee);
        }

        justiceTokenContract.updateLastWithdrawTime(combinedId);

        // 4. mint new bot with selected traits
        _safeMint(msg.sender, combinedId);

        bytes32 hash = bittyHash(_selectedTraits);
        hashToTokenId[hash] = combinedId;
        uint setModifier = setModifierForParts(_selectedTraits);
        uint power = estimatePowerForBot(_selectedTraits, _selectedBots, setModifier);
        uint powerClass = powerClassForPower(power);
        setBittyBot(
            combinedId,
            _selectedTraits,
            setModifier,
            newCombinedCount,
            powerClass,
            power
        );

        // Update Trait Count in one sitting to avoid expensive storage hit
        for (uint i = 0; i < NUM_TRAITS; i++) {
            traitsToDeduct[i] = UIntArrays.decrementPackedUint(traitsToDeduct[i], _selectedTraits[i], 1);
            traitCounts[i] -= traitsToDeduct[i];
        }

        emit BittyBotMinted(combinedId, _selectedTraits, setModifier, newCombinedCount, powerClass, power);
        combinedId++;
    }

    // POWER
    function powerForPart(uint _traitCategory, uint _traitIndex) public pure returns (uint) {
        if (_traitCategory == TRAIT_INDEX_HELMET ||
            _traitCategory == TRAIT_INDEX_FACE ||
            _traitCategory == TRAIT_INDEX_ARMS ||
            _traitCategory == TRAIT_INDEX_BODY) {
            if (_traitIndex == 0) {
                return 300;
            } else if (_traitIndex < 13) {
                return 40;
            } else if (_traitIndex < 15) {
                return 80;
            }
            return 150;
        } else if (_traitCategory == TRAIT_INDEX_ENGINE) {
            return 4 * _traitIndex ** 2 + 6 * _traitIndex + 10;
        } else if (_traitCategory == TRAIT_INDEX_ACCESSORIES) {
            if (_traitIndex == 0) {
                return 0;
            } else if (_traitIndex < 3){
                return 100;
            } else if (_traitIndex < 5){
                return 200;
            } else if (_traitIndex < 7){
                return 400;
            }
        }

        return 0;
    }

    function powerForParts(uint[] memory _traits) public pure returns (uint power) {
        for (uint i = 0; i < _traits.length; i++) {
            power += powerForPart(i, _traits[i]);
        }

        return power;
    }

    function setModifierForParts(uint[] memory _traits) public pure returns (uint count) {
        for (uint i = 0; i < 4; i++) {
            uint currentCount = 0;
            for (uint j = 0; j < 4; j++) {
                if (_traits[i] == _traits[j]) {
                    currentCount++;
                }
            }
            if (currentCount > count) {
                count = currentCount;
            }
        }
        return count;
    }

    function powerClassForPower(uint _power) public pure returns (uint) {
        if (_power < 300) {
            return 1;
        } else if (_power < 500) {
            return 2;
        } else if (_power < 800) {
            return 3;
        } else if (_power < 1000) {
            return 4;
        } else if (_power < 1200) {
            return 5;
        } else if (_power < 1400) {
            return 6;
        } else if (_power < 1600) {
            return 7;
        } else if (_power < 1800) {
            return 8;
        } else if (_power < 2000) {
            return 9;
        } else {
            return 10;
        }
    }

    function estimatePowerForBot(uint[] memory _selectedTraits, uint[] memory _selectedBots, uint _setModifier) public view returns (uint power) {
        if (_selectedTraits[TRAIT_INDEX_TYPE] == 1) {
            return 1400;
        } else if (_selectedTraits[TRAIT_INDEX_TYPE] == 2) {
            return 1600;
        } else if (_selectedTraits[TRAIT_INDEX_TYPE] == 3) {
            return 1800;
        }

        // get power of bots
        BittyBot memory bot;
        for (uint i = 0; i < _selectedBots.length; i++) {
            bot = getBittyBot(_selectedBots[i]);
            power += bot.power / 3;
        }

        // get power for parts
        power += powerForParts(_selectedTraits);

        return (_setModifier > 1) ? power * (4 * _setModifier + 4) / 10 : power;
    }

    // Sales related functions
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function tokensOfOwner(address _owner) external view returns(uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory result = new uint[](tokenCount);
        for (uint index = 0; index < tokenCount; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }

    function numEligibleClaims() public view returns (uint) {
        uint[] memory ownedChubbies = chubbiesContract.tokensOfOwner(msg.sender);
        uint numEligible = 0;
        for (uint i = 0; i < ownedChubbies.length; i++) {
            if (isBotAvailable(ownedChubbies[i])) {
                numEligible++;
            }
        }
        return numEligible;
    }

    function claim(uint _claimId) public {
        require(isFreeClaimActive, "Free claim is not active");
        require(_claimId < MAX_CHUBBIES, "Ineligible Claim");
        require(isBotAvailable(_claimId), "BittyBot has already been claimed");

        if (_claimId < MAX_CHUBBIES) {
            require(chubbiesContract.ownerOf(_claimId) == msg.sender, "No Chubbie to claim BittyBot");
        }

        _mintBot(msg.sender, _claimId);
        numClaimed++;
    }

    function claimN(uint _numClaim) public {
        require(isFreeClaimActive, "Free claim is not active");
        uint[] memory ownedChubbies = chubbiesContract.tokensOfOwner(msg.sender);
        uint claimed = 0;
        for (uint i = 0; i < ownedChubbies.length; i++) {
            if (isBotAvailable(ownedChubbies[i])) {
                _mintBot(msg.sender, ownedChubbies[i]);
                claimed++;
            }
            if (claimed == _numClaim) {
                break;
            }
        }

        numClaimed += claimed;
    }

    function buy(uint _numBuy) public payable {
        uint startIndex = MAX_CHUBBIES + RESERVE_LIMIT + numSold;
        require(isSaleActive, "Sale is not active");
        require(startIndex + _numBuy < TOKEN_LIMIT, "Exceeded 20000 limit");
        require(_numBuy < 11, "You can buy maximum 10 bots");
        require(msg.value >= PRICE * _numBuy, "Ether value sent is below the price");

        for (uint i = 0; i < _numBuy; i++) {
            _mintBot(msg.sender, startIndex + i);
        }
        numSold += _numBuy;
    }

    function buyUnclaimed(uint _numBuy) public payable {
        require(isSaleActive && isFinalSaleActive, "Final sale has already ended");
        require(_numBuy < 11, "You can buy maximum 10 bots");
        require(msg.value >= PRICE * _numBuy, "Ether value sent is below the price");

        uint numBought = 0;
        for (uint i = 0; i < MAX_CHUBBIES; i++) {
            if (isBotAvailable(i)) {
                _mintBot(msg.sender, i);
                numBought++;
            }
            if (numBought == _numBuy) {
                return;
            }
        }
    }

    function setContracts(address _chubbiesContract, address _justiceTokenContract) public onlyOwner {
        chubbiesContract = IChubbies(_chubbiesContract);
        justiceTokenContract = IJusticeToken(_justiceTokenContract);
    }

    function setWidthdrawAddresses(address payable _solazy, address payable _kixboy) public onlyOwner {
        solazy = _solazy;
        kixboy = _kixboy;
    }
    
    function startSale() public onlyOwner {
        isSaleActive = true;
    }

    function stopSale() public onlyOwner {
        isSaleActive = false;
    }

    function startClaim() public onlyOwner {
        isFreeClaimActive = true;
    }

    function stopClaim() public onlyOwner {
        isFreeClaimActive = false;
    }

    function startFinalSale() public onlyOwner {
        isFinalSaleActive = true;
        isFreeClaimActive = false;
    }

    function stopFinalSale() public onlyOwner {
        isFinalSaleActive = false;
    }
    
    function withdraw() public payable {
        require(msg.sender == kixboy || msg.sender == solazy || msg.sender == owner(), "Invalid sender");
        uint halfBalance = address(this).balance / 20 * 9;
        kixboy.transfer(halfBalance);
        solazy.transfer(halfBalance);
        payable(owner()).transfer(address(this).balance);
    }

    function reserveMint(address _sendTo, uint _tokenId) public onlyOwner {
        require(_tokenId > MAX_CHUBBIES && _tokenId < MAX_CHUBBIES + RESERVE_LIMIT, "Not a eligible reserve token");
        _mintBot(_sendTo, _tokenId);
    }

    function reserveBulkMint(address _sendTo, uint _numReserve) public onlyOwner {
        uint numReserved = 0;
        for (uint i = MAX_CHUBBIES; i < MAX_CHUBBIES + RESERVE_LIMIT; i++) {
            if (isBotAvailable(i)) {
                _mintBot(_sendTo, i);
                numReserved++;
            }
            if (numReserved == _numReserve) {
                return;
            }
        }
    }
}

// contracts/UIntArrays.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


library UIntArrays {
    function sum(uint[] memory _array) public pure returns (uint result) {
        result = 0;
        for (uint i = 0; i < _array.length; i++){
            result += _array[i];
        }
    }

    function randomIndexFromWeightedArray(uint[] memory _weightedArray, uint _randomNumber) public pure returns (uint) {
        uint totalSumWeight = sum(_weightedArray);
        require(totalSumWeight > 0, "Array has no weight");
        uint randomSumWeight = _randomNumber % totalSumWeight;
        uint currentSumWeight = 0;

        for (uint i = 0; i < _weightedArray.length; i++) {
            currentSumWeight += _weightedArray[i];
            if (randomSumWeight < currentSumWeight) {
                return i;
            }
        }

        return _weightedArray.length - 1;
    } 

    function hash(uint[] memory _array, uint _endIndex) public pure returns (bytes32) {
        bytes memory encoded;
        for (uint i = 0; i < _endIndex; i++) {
            encoded = abi.encode(encoded, _array[i]);
        }

        return keccak256(encoded);
    }

    function arrayFromPackedUint(uint _packed, uint _size) public pure returns (uint[] memory) {
        uint[] memory array = new uint[](_size);

        for (uint i = 0; i < _size; i++) {
            array[i] = uint256(uint16(_packed >> (i * 16)));
        }

        return array;
    }

    function packedUintFromArray(uint[] memory _array) public pure returns (uint _packed) {
        require(_array.length < 17, "pack array > 16");
        for (uint i = 0; i < _array.length; i++) {
            _packed |= _array[i] << (i * 16);
        }
    }

    function elementFromPackedUint(uint _packed, uint _index) public pure returns (uint) {
        return uint256(uint16(_packed >> (_index * 16)));
    }

    function decrementPackedUint(uint _packed, uint _index, uint _number) public pure returns (uint result) {
        result = _packed & ~(((1 << 16) - 1) << (_index * 16));
        result |= (elementFromPackedUint(_packed, _index) - _number) << (_index * 16);
    }

    function incrementPackedUint(uint _packed, uint _index, uint _number) public pure returns (uint result) {
        result = _packed & ~(((1 << 16) - 1) << (_index * 16));
        result |= (elementFromPackedUint(_packed, _index) + _number) << (_index * 16);
    }

    function mergeArrays(uint[] memory _array1, uint[] memory _array2, bool _isPositive) public pure returns (uint[] memory) {
        for (uint i = 0; i < _array1.length; i++) {
            if (_isPositive) {
                _array1[i] += _array2[i];
            } else {
                _array1[i] -= _array2[i];
            }
            
        }
        return _array1;
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/*
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

