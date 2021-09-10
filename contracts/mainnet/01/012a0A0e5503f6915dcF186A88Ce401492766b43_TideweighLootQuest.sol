// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IERC2981.sol";
import "./Base64.sol";
import "./LootInterface.sol";
import "./OwnableWithoutRenounce.sol";
import "./StringsSpecialHex.sol";

/* Functionality used to whitelist OpenSea trading address */

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title Quest for Loot (for Adventurers)
 *
 * An art project (some might be tempted to call it a game) based on https://www.lootproject.com/
 */
contract TideweighLootQuest is ERC721Enumerable, OwnableWithoutRenounce, ReentrancyGuard, Pausable, IERC2981 {

    // The quest has been started by the owner
    event QuestStarted(address indexed by, uint256 indexed questTokenId);

    // Someone contributed to the solution of a quest (this may or may not have solved the quest)
    event QuestContributed(address indexed contributor, uint256 indexed questTokenId, uint256 lootTokenId, uint256 lootIdx); 

    // The quest is solved, i.e., all the Loot required by the quest has been provided
    event QuestSolved(uint256 indexed questTokenId);

    // A reward has been offered for the next person who contributes to the quest's progress
    event RewardOffered(address indexed by, uint256 indexed questTokenId, uint256 amount);

    // The reward giver has changed his mind and cancelled the reward
    event RewardCancelled(address indexed by, uint256 indexed questTokenId);

    // Someone has contributed to the quest's progress and gets the reward, if one is being offered
    event RewardClaimed(address indexed by, uint256 indexed questTokenId, uint256 amount);

    LootInterface public lootContract;

    string[] private locomotion = [
        "Fly",
        "Walk",
        "Crawl",
        "Run",
        "Teleport",
        "Head"
    ];

    string[] private interlocutorPrefix = [
        "Old ",
        "Ancient ",
        "Wise ",
        "Mean ",
        "Angry ",
        "Big ",
        "Grumpy ",
        "Spindly ",
        "Mighty "
    ];

    string[] private interlocutorName = [
        // order of the names matters, to get the applicable "standard" possessive pronoun
        "Nardok", // 0
        "Argul",
        "Hagalbar",
        "Igor",
        "Henndar",
        "Rorik",
        "Yagul",
        "Engar",
        "Freya", // 8
        "Nyssa",
        "Galadrya",
        "Renalee",
        "Vixen",
        "Everen",
        "Ciradyl",
        "Faelyn",
        "Skytaker", //16 
        "Skeltor",
        "Arachnon",
        "Gorgo",
        "Hydratis",
        "Cerberis",
        "Typhox",
        "Fenryr"
    ];

    string[] private interlocutorPossessive = [
        "His ",
        "Her ",
        "Its "
    ];

    string[] private locationPrefix = [
        "Barren ",
        "Bleak ",
        "Desolate ",
        "Tenebrous ",
        "Mournful ",
        "Gray ",
        "Dark ",
        "Unknowable "
    ];    

    string[] private locationName = [
        "Sea ",
        "City ",
        "Mountain ",
        "Cave ",
        "Swamp ",
        "Desert ",
        "Abode ",
        "Pass ",
        "Forest "
    ];

    string[] private locationSuffix = [
        "of Doom",
        "of Passing",
        "of Death",
        "of Demise",
        "of Fate",
        "of Passage",
        "of Fears"
    ];

    string[] private lostEntityPrefix = [
        "mystical ",
        "ancient ",
        "enigmatic ",
        "transcendental ",
        "unfathomable ",
        "" // intentionally left blank
    ];

    string[] private lostEntityClass = [
        "brother",
        "sister",
        "living sword",
        "dragon",
        "pet",
        "sentient staff",
        "animate artefact"
    ];

    string[] private lostAction = [
        " disappeared",
        " vanished",
        " faded",
        " gone missing",
        " dematerialized",
        " withered"
    ];

    string[] private gratitudePrefix = [
        "eternal ",
        "unbounded ",
        "infinite ",
        "endless ",
        "immeasurable "
    ];

    string[] private gratitudeType = [
        "thanks!",
        "gratitude!",
        "appreciation!",
        "respect!",
        "affection!",
        "trust!"
    ];

    address public proxyRegistryAddress; // OpenSea trading proxy. Zero indicates that OpenSea whitelisting is disabled

    mapping(uint256 => uint256) public usedUpLoot; // Tracks the Loot that has been used up to solve Quests

    mapping(uint256 => uint256) public requiredLootResolutionStatus; // Tracks how much of the required Loot has been provided

    mapping(uint256 => uint256) public questToRewardAmountMap; // Tracks how much reward is on offer for a quest's resolution

    mapping(uint256 => address) public questToRewardSourceMap; // Tracks who offered the reward for a quest's resolution

    uint256 public artistShare = 0; // ETH owed to the artist

    // order matters from here on, to pack the fields

    uint16 royalty = 10;    // Royalty expected by the artist on secondary transfers (IERC2981)

    uint16 public tokensLeftForSale = 1000; // Maximum number of tokens that can be acquired without owning Loot

    uint16 public tokensLeftForPromotion = 100; // Maximum number of tokens that can be handed out by the owner for promotional purposes

    uint64 public minimumReward = 0.01 ether;
    uint64 public maximumReward = 1 ether;
    uint64 public minimumMintPrice = 0.5 ether;

    constructor(string memory name, string memory symbol, uint256 initialTokensForOwner, address _proxyRegistryAddress, address _lootContract) ERC721(name, symbol) {

        proxyRegistryAddress = _proxyRegistryAddress;
        lootContract = LootInterface(_lootContract);

        for(uint256 cnt = 0; cnt < initialTokensForOwner; cnt++) {
            _safeMint(_msgSender(), totalSupply()+1);
        }

    }

    //
    // ERC165 interface implementation
    //

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId)
            || interfaceId == type(IERC2981).interfaceId
            || interfaceId == 0x7f5828d0; // Ownable
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading - if we have a valid proxy registry address on file
        if (proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

    // 
    // ERC721 functions
    //

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mintQuest(address recipient) internal nonReentrant {
        require(totalSupply() < 10000 , "All quests have been set");
        require(balanceOf(recipient) < 3, "Can hold max 3 quests at once");
        _safeMint(recipient, totalSupply()+1);

    }

    /**
     * @dev Claim Quest for free if you're a holder of Loot
     *
     */
    function claimQuestAsLootHolder() public {
        require(lootContract.balanceOf(_msgSender()) > 0, "Must hold Loot (for Adventurers) to claim for free");
        mintQuest(_msgSender());
    }

    /**
     * @dev Pay for a Quest for free if you want a token but don't hold any Loot
     *
     */
    function mint() public payable {
        require(tokensLeftForSale > 0, "No more tokens for sale");
        require(msg.value >= minimumMintPrice, "Insufficient ether provided");
        artistShare += msg.value;
        tokensLeftForSale -= 1;
        mintQuest(_msgSender());
    }
    
    /**
     * @dev Some quests are available for promotional purposes
     *
     */
    function mintPromotion(address recipient) public onlyOwner {
        require(recipient != address(0), "ERC721: mint to the zero address");
        require(tokensLeftForPromotion > 0, "No more tokens for promotion");
        tokensLeftForPromotion -= 1;
        mintQuest(recipient);
    }
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function lcgRandom(uint256 xk) internal pure returns (uint256 xkplusone) {
        return (16807 * (xk % 2147483647)) % 2147483647;
    }
    
    function pluckIndex(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (uint256 index) {
        return  random(string(abi.encodePacked(keyPrefix, Strings.toString(tokenId)))) % sourceArray.length;
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        return sourceArray[pluckIndex(tokenId, keyPrefix, sourceArray)];
    }

    function getLocomotion(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Locomotion", locomotion);
    }

    function getInterlocutorPrefix(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "InterlocutorPrefix", interlocutorPrefix);
    }

    function getInterlocutorName(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "InterlocutorName", interlocutorName);
    }

    function getInterlocutorPossessive(uint256 tokenId) public view returns (string memory) {
        return interlocutorPossessive[pluckIndex(tokenId, "InterlocutorName", interlocutorName) / 8]; // the use of interlocutorName here is correct
    }

    function getLocationPrefix(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "LocationPrefix", locationPrefix);
    }

    function getLocationName(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "LocationName", locationName);
    }

    function getLocationSuffix(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "LocationSuffix", locationSuffix);
    }

    function getLostEntityPrefix(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LostEntityPrefix", lostEntityPrefix);
    }

    function getLostEntityClass(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LostEntityClass", lostEntityClass);
    }

    function getLostAction(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LostAction", lostAction);
    }

    function getGratitudePrefix(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "GratitudePrefix", gratitudePrefix);
    }

    function getGratitudeType(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "GratitudeType", gratitudeType);
    }

    function getInterlocutor(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(getInterlocutorPrefix(tokenId), getInterlocutorName(tokenId)));
    }

    function getLocation(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(getLocationPrefix(tokenId), getLocationName(tokenId), getLocationSuffix(tokenId)));
    }

    function getLostEntity(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(getLostEntityPrefix(tokenId), getLostEntityClass(tokenId)));
    }

    function getDifficulty(uint256 tokenId) public pure returns (uint256 difficulty) {
        uint256 r = random(string(abi.encodePacked("Difficulty", Strings.toString(tokenId)))) % 100;
        if(     r <  5) return 1;
        else if(r < 20) return 2;
        else if(r < 45) return 3;
        else if(r < 70) return 4;
        else if(r < 85) return 5;
        else if(r < 95) return 6;
        else if(r < 99) return 7;
        else            return 8;
    }

    /**
     * @dev Returns mask of requires loot indices
     *
     * lootIdxMask defined analogously to lootIdx as for solveQuest, where the value of each activated bit = (1 << lootIdx)
     */
    function getRequiredLootIdxMask(uint256 tokenId) public pure returns (uint256 lootIdxMask) {
        uint256 difficulty = getDifficulty(tokenId);
        uint256 chosen = 0;
        lootIdxMask = 0;
        uint256 randTmp = random(string(abi.encodePacked("Loots", Strings.toString(tokenId))));
        while(chosen < difficulty) { // need to iterate in a random fashion
            randTmp = lcgRandom(randTmp);
            uint256 newlyChosenPosition = uint256(randTmp) % 8;
            if(lootIdxMask & (1 << newlyChosenPosition) == 0) {
                // Loot was not chosen previously, do so now
                lootIdxMask |= (1 << newlyChosenPosition);
                chosen += 1;
            }
        }
    }

    /**
     * @dev Enumeration of loot indices
     *
     * lootIdx defined identically as for solveQuest
     *
     * position must be in [0, difficulty)
     */
    function getRequiredLootIdx(uint256 tokenId, uint256 position) public pure returns (uint256 lootIdx) {
        uint lootIdxMask = getRequiredLootIdxMask(tokenId);
        uint256 cnt = 0;
        for(uint i = 0; i < 8; i++) {
            if(lootIdxMask & (1 << i) != 0) {
                if(cnt == position) return i;
                cnt++;
            }
        }
        revert("Must stay below difficulty"); // If we arrive here, the caller requested an impossible position at the given difficulty level
    }

    /**
     * @dev Multiplicity of each lootIdx
     *
     * lootIdx defined identically as for solveQuest
     */
    function getRequiredLootIdxMultiplicity(uint256 tokenId, uint256 requiredLootIdx) public pure returns (uint256 multiplicity) {
        if(getRequiredLootIdxMask(tokenId) & (1 << requiredLootIdx) == 0) return 0;
        uint256 r = random(string(abi.encodePacked("Multiplicity", Strings.toString(tokenId + 27644437 * requiredLootIdx)))) % 100;
        if(     r < 60) return 1;
        else if(r < 90) return 2;
        else            return 3;
    }

    function lookupLootName(uint256 lootTokenId, uint256 lootIdx) internal view returns (string memory) {
        string memory loot;
        if(     lootIdx == 0) loot = lootContract.getWeapon(lootTokenId);
        else if(lootIdx == 1) loot = lootContract.getChest(lootTokenId);
        else if(lootIdx == 2) loot = lootContract.getHead(lootTokenId);
        else if(lootIdx == 3) loot = lootContract.getWaist(lootTokenId);
        else if(lootIdx == 4) loot = lootContract.getFoot(lootTokenId);
        else if(lootIdx == 5) loot = lootContract.getHand(lootTokenId);
        else if(lootIdx == 6) loot = lootContract.getNeck(lootTokenId);
        else if(lootIdx == 7) loot = lootContract.getRing(lootTokenId);
        return loot;
    }

    /**
     * @dev Required Loot
     *
     * lootIdx defined identically as for solveQuest
     * variantIdx must stay below lootIdxMultiplicity for chosen lootIdx
     */
    function getRequiredLoot(uint256 questTokenId, uint256 requiredLootIdx, uint256 variantIdx) public view returns (string memory) {
        require(variantIdx < getRequiredLootIdxMultiplicity(questTokenId, requiredLootIdx), "Loot must be required");
        bytes32[3] memory requiredLoot;
        uint256 variantsFounds = 0;
        uint256 samplingLootPrng = random(string(abi.encodePacked("SamplingLoot", Strings.toString(questTokenId + 27644437 * requiredLootIdx))));
        do {
            uint256 samplingLootTokenId = 1 + (samplingLootPrng % 7777);
            string memory candidateLoot = lookupLootName(samplingLootTokenId, requiredLootIdx);
            bool alreadyKnown = false;
            for(uint256 lookback = 0; lookback < requiredLoot.length; lookback++) {
                if(keccak256(abi.encodePacked(candidateLoot)) == requiredLoot[lookback]) {
                    alreadyKnown = true;
                }
            }
            if(!alreadyKnown) {
                requiredLoot[variantsFounds] = keccak256(abi.encodePacked(candidateLoot));
                variantsFounds += 1;
                if(variantIdx < variantsFounds) return candidateLoot;
            }
            samplingLootPrng = lcgRandom(samplingLootPrng);
        } while(true);
        return ""; // this can actually never happen...
    }

    function buildAttributes(uint256 tokenId, bool questSolved) internal pure returns (string memory) {
        string memory questStatus;
        if(questSolved) {
            questStatus = "Solved";
        } else {
            questStatus = "Open";
        }
        return string(abi.encodePacked('"attributes": [{ "trait_type": "Quest", "value": "', questStatus, '" }, { "trait_type": "Difficulty", "value": ', Strings.toString(getDifficulty(tokenId)),' }],'));
    }

    function buildRequiredLootList(uint256 tokenId) internal view returns (string memory result, uint256 nextLineY) {
        string[64] memory parts;
        uint256 partCounter = 0;
        nextLineY = 120;
        uint256 difficulty = getDifficulty(tokenId);
        for(uint256 loot = 0; loot < difficulty; loot++) {
            parts[partCounter++] = string(abi.encodePacked('</text><text x="10" y="', Strings.toString(nextLineY) ,'" class="base">'));
            uint256 requiredLootIdx = getRequiredLootIdx(tokenId, loot);
            uint256 variants = getRequiredLootIdxMultiplicity(tokenId, requiredLootIdx);
            for(uint256 variantIdx = 0; variantIdx < variants; variantIdx++) {
                parts[partCounter++] = getRequiredLoot(tokenId, requiredLootIdx, variantIdx);
                if(variantIdx + 1 < variants) {
                    if(variantIdx == 1) {
                        nextLineY += 20;
                        parts[partCounter++] = string(abi.encodePacked(',</text><text x="10" y="', Strings.toString(nextLineY) ,'" class="base">or '));
                    } else {
                        parts[partCounter++] = ', or ';
                    }
                }
            }
            nextLineY += 20;
        }
        for(uint256 assemblyPart = 0; assemblyPart < partCounter; assemblyPart++) {
            result = string(abi.encodePacked(result, parts[assemblyPart]));
        }
    }
    function buildGraphics(uint256 tokenId) internal pure returns (string memory) {
        string[6] memory parts;
        parts[ 0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500"><style>.base{fill:black;font-family:serif;font-size:14px;} .bold{font-weight:bold;}';
        for(uint256 i = 1; i <= 4; i++) {
            parts[i] = string(abi.encodePacked(' .st', Strings.toString(i),'{fill:#',StringsSpecialHex.toHexStringWithoutPrefixWithoutLengthCheck(uint24(random(Strings.toString(tokenId*7841+i))), 3),';stroke-miterlimit:10;}'));
        }
        parts[ 5] = '</style><rect width="100%" height="100%" fill="lightgray" /><path class="st1" d="M343.7,364.7c0,0,0,33.5,0,49c0,13.6,49.1,38.4,49.1,38.4v-87.4H343.7z"/><rect x="343.7" y="309.7" class="st2" width="49.1" height="55"/><path class="st3" d="M441.8,364.7c0,0,0,33.5,0,49c0,13.6-49.1,38.4-49.1,38.4v-87.4H441.8z"/><rect x="392.8" y="309.7" class="st4" width="49.1" height="55"/><text x="10" y="20" class="base">';
        return string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        bool questSolved = isQuestSolved(tokenId);
        
        string[3] memory questNameParts;
        questNameParts[ 0] = getInterlocutor(tokenId);
        questNameParts[ 1] = ' in the ';
        questNameParts[ 2] = getLocation(tokenId);
        string memory questName = string(abi.encodePacked(questNameParts[0], questNameParts[1], questNameParts[2]));

        (string memory lootList, uint256 nextLineY) = buildRequiredLootList(tokenId);
        string[20] memory parts;
        parts[ 0] = buildGraphics(tokenId);
        parts[ 1] = getLocomotion(tokenId);
        parts[ 2] = ' to ';
        // insert questName here
        parts[ 3] = '. </text><text x="10" y="40" class="base">';
        parts[ 4] = getInterlocutorPossessive(tokenId);
        parts[ 5] = getLostEntity(tokenId);
        parts[ 6] = ' has ';
        parts[ 7] = getLostAction(tokenId);
        parts[ 8] = '. </text><text x="10" y="60" class="base">';
        parts[ 9] = 'To help the ';
        parts[10] = getLostEntityClass(tokenId);
        parts[11] = ', use all of the items on the list below. </text><text x="10" y="80" class="base">You\'ll be rewarded with ';
        parts[12] = getGratitudePrefix(tokenId);
        parts[13] = getGratitudeType(tokenId);
        parts[14] = lootList;
        if(questSolved) {
            parts[18] = string(abi.encodePacked('</text><text x="10" y="', Strings.toString(nextLineY + 20),'" class="base bold">Quest successfully solved!'));
        }
        parts[19] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], questName, parts[3], parts[4], parts[5], parts[6], parts[7]));
        output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));
        output = string(abi.encodePacked(output, parts[15], parts[16], parts[17], parts[18], parts[19]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Quest #', 
            Strings.toString(tokenId), 
            ' - ',
            questName,
            '", ', 
            buildAttributes(tokenId, questSolved),
            ' "description": "Each Quest is randomly generated on chain. Solve it by using the appropriate Loot (for Adventurers), or reward others to do so.", "image": "data:image/svg+xml;base64,', 
            Base64.encode(bytes(output)), 
            '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    /**
     * @dev Solve a quest, or contribute to the quest's solution
     *
     * lootIdx:
     *   0 = weapon
     *   1 = chest
     *   2 = head
     *   3 = waist
     *   4 = foot
     *   5 = hand
     *   6 = neck
     *   7 = ring
     */
    function solveQuest(uint256 questTokenId, uint256 lootIdx, uint256 variantIdx, uint256 providedLootTokenId) external whenNotPaused {
        require(_msgSender() == lootContract.ownerOf(providedLootTokenId), "Can only apply own(ed) Loot");
        getRequiredLootIdxMask(questTokenId) & (1 << lootIdx);
        require(requiredLootResolutionStatus[questTokenId / 32] & ((1 << lootIdx) << (8 * (questTokenId % 32))) == 0, "Loot must still be missing");
        require(usedUpLoot[providedLootTokenId / 32] & ((1 << lootIdx) << (8 * (providedLootTokenId % 32))) == 0, "Provided Loot was used before");

        if(((requiredLootResolutionStatus[questTokenId / 32] >> (8 * (questTokenId % 32)))) & 0xff == 0) {
            require(_msgSender() == ownerOf(questTokenId), "Only owner can begin quest");
            emit QuestStarted(_msgSender(), questTokenId);
        }
        
        string memory providedLoot = lookupLootName(providedLootTokenId, lootIdx);
        string memory requiredLoot = getRequiredLoot(questTokenId, lootIdx, variantIdx);
        require(keccak256(abi.encodePacked(providedLoot)) == keccak256(abi.encodePacked(requiredLoot)), "Matching loot must be provided");

        requiredLootResolutionStatus[questTokenId / 32] |= ((1 << lootIdx) << (8 * (questTokenId % 32))); // Mark required Loot as provided
        usedUpLoot[providedLootTokenId / 32] |= ((1 << lootIdx) << (8 * (providedLootTokenId % 32))); // Mark provided Loot as used up

        emit QuestContributed(_msgSender(), questTokenId, providedLootTokenId, lootIdx);

        if(isQuestSolved(questTokenId)) {
            emit QuestSolved(questTokenId);
        }

        uint256 reward = questToRewardAmountMap[questTokenId];
        if(reward > 0) {
            // Zero out the applicable reward, to prevent a reentrancy attack
            delete questToRewardAmountMap[questTokenId];
            delete questToRewardSourceMap[questTokenId];

            emit RewardClaimed(_msgSender(), questTokenId, reward);
            // The following MUST be the very last action that we're doing here
            payable(_msgSender()).transfer(reward);
        }

    }

    /**
     * @dev Get resolution state of quest
     */
    function isQuestSolved(uint256 questTokenId) public view returns (bool solved) {
        return ((requiredLootResolutionStatus[questTokenId / 32] >> (8 * (questTokenId % 32)))) & 0xff
            == getRequiredLootIdxMask(questTokenId);
    }

    /**
     * @dev set allowed reward bounds
     */
    function setRewardBounds(uint64 _minimumReward, uint64 _maximumReward) external onlyOwner {
        minimumReward = _minimumReward;
        maximumReward = _maximumReward;
    }

    /**
     * @dev Offer a reward to the next person who contributes to a quest's resolution
     */
    function offerReward(uint256 questTokenId) external payable whenNotPaused {
        require(msg.value <= maximumReward, "This is not a bank");
        require(msg.value >= minimumReward, "Seriously, that\'s all?");
        require(questToRewardSourceMap[questTokenId] == address(0) && questToRewardAmountMap[questTokenId] == 0, "Only 1 active reward per quest");
        
        uint256 reward = (100 - royalty) * msg.value / 100;
        questToRewardAmountMap[questTokenId] = reward;
        questToRewardSourceMap[questTokenId] = _msgSender();
        artistShare += msg.value - reward; // The artist gets the rest - after all, this Quest is all about Loot ;-)
        
        emit RewardOffered(_msgSender(), questTokenId, msg.value);
    }

    /**
     * @dev If someone really changes his mind, give back the reward - minus the Loot that the artist has already got, sorry...
     */
    function cancelReward(uint256 questTokenId) external whenNotPaused {
        require(questToRewardSourceMap[questTokenId] == _msgSender(), "Must have offered the reward");

        uint256 reward = questToRewardAmountMap[questTokenId];

        // Zero out the applicable reward, to prevent a reentrancy attack
        delete questToRewardAmountMap[questTokenId];
        delete questToRewardSourceMap[questTokenId];

        emit RewardCancelled(_msgSender(), questTokenId);
        
        // The following MUST be the very last action that we're doing here
        payable(_msgSender()).transfer(reward);
    }

    /**
     * @dev Withdraw artist share of funds
     *
     */
    function withdrawArtistShare() external onlyOwner {
        uint256 withdrawal = artistShare;
        artistShare -= withdrawal;
        payable(owner()).transfer(withdrawal);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Used here to implement pausing of contract
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Pause contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    //
    // ERC2981 royalties interface implementation
    //

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */

    function royaltyInfo(uint256 /* _tokenId */, uint256 _value) external view override returns (address receiver, uint256 royaltyAmount) {
        return (owner(), royalty * _value / 100);
    }

    /**
     * @dev Update expected royalty
     */
    function setRoyaltyInfo(uint16 percentage) external onlyOwner {
        royalty = percentage;
    }

    /**
     * @dev set minimum price for paid mints
     */
    function setMinimumMintPrice(uint64 _minimumMintPrice) external onlyOwner {
        minimumMintPrice = _minimumMintPrice;
    }

    //
    // OpenSea registry functions
    //

    /* @dev Update the OpenSea proxy registry address
     *
     * Zero address is allowed, and disables the whitelisting
     *
     */
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface LootInterface {

    function getWeapon(uint256 tokenId) external view returns (string memory);
    
    function getChest(uint256 tokenId) external view returns (string memory);
    
    function getHead(uint256 tokenId) external view returns (string memory);
    
    function getWaist(uint256 tokenId) external view returns (string memory);

    function getFoot(uint256 tokenId) external view returns (string memory);
    
    function getHand(uint256 tokenId) external view returns (string memory);
    
    function getNeck(uint256 tokenId) external view returns (string memory);
    
    function getRing(uint256 tokenId) external view returns (string memory);
    
    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
abstract contract OwnableWithoutRenounce is Context {
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
 * @dev String operations.
 */
library StringsSpecialHex {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexStringWithoutPrefixWithoutLengthCheck(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = 2 * length; i > 0; --i) {
            buffer[i-1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}