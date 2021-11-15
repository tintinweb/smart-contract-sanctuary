/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./LootComponents.sol";
import "./Base64.sol";
import "./Glory.sol";
import "./Trophy.sol";
import "./Utils.sol";

contract BountiesForAdventurers is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Ownable
{
    string[] Prefixes = [
        unicode"𝕍𝔼ℕ𝔾𝔼𝔽𝕌𝕃",
        unicode"ℂ𝕆ℝℝ𝕌ℙ𝕋𝔼𝔻",
        unicode"ℝ𝔸𝕍𝔼ℕ𝕆𝕌𝕊",
        unicode"𝔽𝕆ℝ𝕊𝔸𝕂𝔼ℕ",
        unicode"𝕀ℕ𝔽𝔼ℝℕ𝔸𝕃",
        unicode"ℙ𝕆𝕊𝕊𝔼𝕊𝕊𝔼𝔻",
        unicode"𝕍𝕀ℂ𝕀𝕆𝕌𝕊",
        unicode"ℝ𝔸𝔹𝕀𝔻",
        unicode"𝕄𝔸𝔻𝔻𝔼ℕ𝔼𝔻",
        unicode"𝔹𝕃𝕆𝕆𝔻𝕋ℍ𝕀ℝ𝕊𝕋𝕐",
        unicode"ℙ𝕌𝕋ℝ𝕀𝔻",
        unicode"𝔾ℝ𝕀𝕊𝕃𝕐",
        unicode"𝕄𝕌𝕋𝔸ℕ𝕋",
        unicode"𝕊𝔸𝕍𝔸𝔾𝔼",
        unicode"𝕎ℝ𝔼𝕋ℂℍ𝔼𝔻",
        unicode"𝔽𝔼ℝ𝔸𝕃",
        unicode"𝔸ℕℂ𝕀𝔼ℕ𝕋",
        unicode"𝔹𝔼𝕎𝕀𝕋ℂℍ𝔼𝔻"
    ];

    string[] HeroicMonsters = [
        unicode"ℝ𝔸ℙ𝕋𝕆ℝ",
        unicode"𝕄𝔸ℕ𝔻ℝ𝔸𝔾𝕆ℝ𝔸",
        unicode"𝕊𝔸𝕃𝔸𝕄𝔸ℕ𝔻𝔼ℝ",
        unicode"𝔽𝕀𝔼ℕ𝔻",
        unicode"𝔹𝔸ℕ𝕊ℍ𝔼𝔼",
        unicode"ℙℍ𝕆𝔼ℕ𝕀𝕏",
        unicode"𝕀ℂ𝔼 𝕊ℙ𝕀𝔻𝔼ℝ",
        unicode"𝕃𝔼ℙℝ𝔼ℂℍ𝔸𝕌ℕ",
        unicode"𝕀𝕄ℙ",
        unicode"𝕊𝔸𝔹ℝ𝔼𝕋𝕆𝕆𝕋ℍ",
        unicode"𝕋ℝ𝕆𝕃𝕃",
        unicode"𝔻ℝ𝔸𝕌𝔾ℝ",
        unicode"ℤ𝕆𝕄𝔹𝕀𝔼",
        unicode"𝔾ℍ𝕆𝕌𝕃",
        unicode"𝔾ℍ𝕆𝕊𝕋",
        unicode"ℍ𝔼𝕃𝕃ℍ𝕆𝕌ℕ𝔻",
        unicode"𝔻𝔼𝔼ℙ 𝔾ℕ𝕆𝕄𝔼",
        unicode"𝔾𝕆𝔹𝕃𝕀ℕ",
        unicode"𝕊𝔸𝕋𝕐ℝ",
        unicode"𝕂𝕆𝔹𝕆𝕃𝔻",
        unicode"𝔻ℝ𝕐𝔸𝔻",
        unicode"𝕆ℝℂ",
        unicode"𝕎𝕀𝔾ℍ𝕋",
        unicode"𝕐𝔼𝕋𝕀",
        unicode"𝕊ℙ𝕀𝔻𝔼ℝ 𝕄𝕆ℕ𝕂𝔼𝕐"
    ];

    string[] EpicMonsters = [
        unicode"𝕆𝕎𝕃𝔹𝔼𝔸ℝ",
        unicode"ℍ𝔸𝔾",
        unicode"𝕆𝔾ℝ𝔼",
        unicode"𝕊𝔼𝔸 𝕊𝔼ℝℙ𝔼ℕ𝕋",
        unicode"𝕎𝕀𝕋ℂℍ",
        unicode"𝕎ℝ𝔸𝕀𝕋ℍ",
        unicode"𝕎𝕌ℝ𝕄",
        unicode"𝕎𝕐𝕍𝔼ℝℕ",
        unicode"𝔾ℝ𝕀𝔽𝔽𝕀ℕ",
        unicode"ℍ𝕀ℙℙ𝕆𝔾ℝ𝕀𝔽𝔽",
        unicode"𝔹𝕌𝔾𝔹𝔼𝔸ℝ",
        unicode"𝕀ℕℂ𝕌𝔹𝕌𝕊",
        unicode"𝔻𝔼𝕄𝕆ℕ",
        unicode"ℂℍ𝕌ℙ𝔸ℂ𝔸𝔹ℝ𝔸",
        unicode"𝔸𝕃𝕀𝔼ℕ",
        unicode"𝕍𝔸𝕄ℙ𝕀ℝ𝔼",
        unicode"𝕎𝔼ℝ𝔼𝕎𝕆𝕃𝔽",
        unicode"𝕊𝔸𝕊ℚ𝕌𝔸𝕋ℂℍ",
        unicode"𝔼ℕ𝕋",
        unicode"ℂ𝔼ℕ𝕋𝔸𝕌ℝ",
        unicode"ℂ𝕆ℂ𝕂𝔸𝕋ℝ𝕀ℂ𝔼",
        unicode"𝔾𝕆𝕃𝔼𝕄",
        unicode"𝔻𝔸ℝ𝕂 𝔼𝕃𝔽",
        unicode"ℍ𝕆𝔹𝔾𝕆𝔹𝕃𝕀ℕ",
        unicode"𝕄𝕀ℕ𝕆𝕋𝔸𝕌ℝ",
        unicode"ℕ𝔼ℂℝ𝕆𝕄𝔸ℕℂ𝔼ℝ",
        unicode"𝕊𝕋𝕆ℕ𝔼 𝔾𝕀𝔸ℕ𝕋",
        unicode"𝔽ℝ𝕆𝕊𝕋 𝔾𝕀𝔸ℕ𝕋",
        unicode"ℍ𝕀𝕃𝕃 𝔾𝕀𝔸ℕ𝕋"
    ];

    string[] LegendaryMonsters = [
        unicode"𝔻ℝ𝔸𝔾𝕆ℕ",
        unicode"𝔹𝔸𝕊𝕀𝕃𝕀𝕊𝕂",
        unicode"𝔻ℝ𝔸𝔾𝕆ℕ 𝕋𝕌ℝ𝕋𝕃𝔼",
        unicode"𝕄𝔸ℕ𝔹𝔼𝔸ℝℙ𝕀𝔾",
        unicode"𝕃𝔼𝕍𝕀𝔸𝕋ℍ𝔸ℕ",
        unicode"ℂℍ𝕀𝕄𝔼ℝ𝔸",
        unicode"ℍ𝕐𝔻ℝ𝔸",
        unicode"𝕊ℙℍ𝕀ℕ𝕏",
        unicode"𝔾𝕆ℝ𝔾𝕆ℕ",
        unicode"𝔸𝔹𝔸𝔻𝔻𝕆ℕ",
        unicode"𝕂ℝ𝔸𝕂𝔼ℕ",
        unicode"𝕄𝔸ℕ𝕋𝕀ℂ𝕆ℝ𝔼",
        unicode"ℙ𝕀𝕋 𝔽𝕀𝔼ℕ𝔻",
        unicode"ℂ𝕃𝕆𝕌𝔻 𝔾𝕀𝔸ℕ𝕋",
        unicode"𝕊𝕋𝕆ℝ𝕄 𝔾𝕀𝔸ℕ𝕋",
        unicode"𝔽𝕀ℝ𝔼 𝔾𝕀𝔸ℕ𝕋",
        unicode"𝕄𝔼𝔻𝕌𝕊𝔸",
        unicode"𝔸ℝℂℍ𝕄𝔸𝔾𝔼",
        unicode"𝕃𝕀ℂℍ",
        unicode"𝔻𝕁𝕀ℕℕ",
        unicode"ℝ𝔼𝕍𝔼ℕ𝔸ℕ𝕋",
        unicode"𝔻𝔼𝕍𝕆𝕌ℝ𝔼ℝ"
    ];

    // Loot contract is available at https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7
    // address public lootContractAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
    // address public goldContractAddress = 0x32353A6C91143bfd6C7d363B546e62a9A2489A20;
    IERC721Enumerable private _lootContract;
    IERC721Enumerable private _mlootContract;
    IERC20 private _goldContract;
    GloryForAdventurers private _gloryContract;
    LootComponents private _lootComponentsContract;
    TrophiesForAdventurers private _trophyContract;

    uint256 constant private decimals = 10 ** 18;
    uint256 constant private maxItems = 24;

    uint256 constant private _heroicItemRolls = 6;
    uint256 constant private _epicItemRolls = 12;
    uint256 constant private _legendaryItemRolls = 24;

    uint256 constant private _heroicBountyGoldCost = 100;
    uint256 constant private _epicBountyGoldCost = 300;
    uint256 constant private _legendaryBountyGoldCost = 1000;

    uint256 constant private _heroicGloryReward = 1000;
    uint256 constant private _epicGloryReward = 3000;
    uint256 constant private _legendaryGloryReward = 10000;

    // Pledges are stored as such: lootTokensPledged[bountyId][pledgeNum] = lootTokenId
    uint256[][] private lootTokensPledged;
    uint256 private maxTokenCounter = 0;

    uint256 private _heroicTokenIdCounter = 0;
    uint256 private _epicTokenIdCounter = 1;
    uint256 private _legendaryTokenIdCounter = 2;


    constructor(address lootContractAddress, address lootComponentAddress, address goldContractAddress, address gloryContractAddress, address mlootContractAddress, address trophiesContractAddress)
        ERC721("Bounties (For Adventurers)", "BTY")
    {
        _lootContract = IERC721Enumerable(lootContractAddress);
        _lootComponentsContract = LootComponents(lootComponentAddress);
        _goldContract = IERC20(goldContractAddress);
        _goldContract.approve(address(this), 999999999999 * decimals);
        _mlootContract = IERC721Enumerable(mlootContractAddress);
        _gloryContract = GloryForAdventurers(gloryContractAddress);
        _trophyContract = TrophiesForAdventurers(trophiesContractAddress);
    }

    function getGloryReward(uint256 tokenId) public pure returns(uint256) {
        return [_heroicGloryReward, _epicGloryReward, _legendaryGloryReward][Utils.getDifficulty(tokenId)];
    }

    function getGoldReward(uint256 tokenId) public pure returns(uint256) {
        return [_heroicBountyGoldCost, _epicBountyGoldCost, _legendaryBountyGoldCost][Utils.getDifficulty(tokenId)];
    }

    function getRandomItem(uint8 itemNum, uint256 tokenId)
        private
        view
        returns (uint256[6] memory)
    {
        uint256 rand = Utils.random(
            string(abi.encodePacked(Utils.toString(itemNum), Utils.toString(tokenId)))
        );
        uint256 itemType = rand % 8;
        uint256 seed = tokenId * itemNum;
        return
        [
            _lootComponentsContract.weaponComponents,
            _lootComponentsContract.chestComponents,
            _lootComponentsContract.headComponents,
            _lootComponentsContract.waistComponents,
            _lootComponentsContract.footComponents,
            _lootComponentsContract.handComponents,
            _lootComponentsContract.neckComponents,
            _lootComponentsContract.ringComponents
        ][itemType](seed);
    }

    function getBountyMonster(uint256 tokenId) public view returns (string memory) {
        uint256 rand1 = Utils.random(
            string(abi.encodePacked(Utils.toString(tokenId)))
        );
        uint256 rand2 = Utils.random(
            string(abi.encodePacked(Utils.toString(tokenId * tokenId)))
        );
        uint256 difficulty = Utils.getDifficulty(tokenId);
        uint256 prefixIndex = rand1 % Prefixes.length;
        uint256 monsterIndex;
        if (difficulty == 0) {
            monsterIndex = rand2 % HeroicMonsters.length;
            return string(abi.encodePacked(Prefixes[prefixIndex], ' ', HeroicMonsters[monsterIndex]));
        }
        if (difficulty == 1) {
            monsterIndex = rand2 % EpicMonsters.length;
            return string(abi.encodePacked(Prefixes[prefixIndex], ' ', EpicMonsters[monsterIndex]));
        }
        monsterIndex = rand2 % LegendaryMonsters.length;
        return string(abi.encodePacked(Prefixes[prefixIndex], ' ', LegendaryMonsters[monsterIndex]));
    }

    function mintHeroicBounty() public {
        _goldContract.transferFrom(msg.sender, address(this), _heroicBountyGoldCost * decimals);
        _safeMint(msg.sender, _heroicTokenIdCounter);
        if (maxTokenCounter <= _heroicTokenIdCounter) {
            for (uint i = maxTokenCounter; i <= _heroicTokenIdCounter; i += 1) {
                // I literally don't know how to make this work without
                // initializing with a non-empty array so fuck it
                lootTokensPledged.push([0]);
                maxTokenCounter += 1;
            }
        }
        _heroicTokenIdCounter += 3;
    }

    function mintEpicBounty() public {
        _goldContract.transferFrom(msg.sender, address(this), _epicBountyGoldCost * decimals);
        _safeMint(msg.sender, _epicTokenIdCounter);
        if (maxTokenCounter <= _epicTokenIdCounter) {
            for (uint i = maxTokenCounter; i <= _epicTokenIdCounter; i += 1) {
                lootTokensPledged.push([0]);
                maxTokenCounter += 1;
            }
        }
        _epicTokenIdCounter += 3;
    }

    function mintLegendaryBounty() public {
        _goldContract.transferFrom(msg.sender, address(this), _legendaryBountyGoldCost * decimals);
        _safeMint(msg.sender, _legendaryTokenIdCounter);
        if (maxTokenCounter <= _legendaryTokenIdCounter) {
            for (uint i = maxTokenCounter; i <= _legendaryTokenIdCounter; i += 1) {
                lootTokensPledged.push([0]);
                maxTokenCounter += 1;
            }
        }
        _legendaryTokenIdCounter += 3;
    }

    function isMinted(uint256 tokenId) public view returns (bool) {
        return [
            _heroicTokenIdCounter,
            _epicTokenIdCounter,
            _legendaryTokenIdCounter
        ][Utils.getDifficulty(tokenId)] > tokenId;
    }

    function getItemSlotForTokenId(uint256 itemSlot, uint256 tokenId) private view returns (uint256[6] memory) {
        require(itemSlot > 0, 'ITEM_SLOT_MUST_BE_GREATER_THAN_ZERO');
        return [
            _lootComponentsContract.weaponComponents,
            _lootComponentsContract.chestComponents,
            _lootComponentsContract.headComponents,
            _lootComponentsContract.waistComponents,
            _lootComponentsContract.footComponents,
            _lootComponentsContract.handComponents,
            _lootComponentsContract.neckComponents,
            _lootComponentsContract.ringComponents
        ][itemSlot - 1](tokenId);
    }

    function getComponentsRemaining(uint256 tokenId) public view returns(uint256[6][maxItems] memory) {
        require(isMinted(tokenId), 'BOUNTY_NOT_MINTED');

        uint256[6][maxItems] memory requiredItems = getBountyRequirements(tokenId);
        bool[maxItems] memory isItemPledged;
        for (uint256 itemNum = 0; itemNum < maxItems; itemNum += 1) {
            uint256[] memory pledgedLoots = lootTokensPledged[tokenId];
            uint256[6] memory requiredItem = requiredItems[itemNum];

            // Skip if empty requirement
            if (requiredItem[5] == 0) {
                isItemPledged[itemNum] = true;
                continue;
            }

            for (uint256 lootNum = 1; lootNum < pledgedLoots.length; lootNum += 1) {
                uint256 pledgedLootId = pledgedLoots[lootNum];
                uint256[6] memory pledgedItem = getItemSlotForTokenId(requiredItem[5], pledgedLootId);
                if (pledgedItem[0] == requiredItem[0]) {
                    isItemPledged[itemNum] = true;
                }
            }
        }

        uint256[6][maxItems] memory componentsRemaining;
        for (uint256 i = 0; i < maxItems; i += 1) {
            if (!isItemPledged[i]) {
                componentsRemaining[i] = requiredItems[i];
            }
        }

        return componentsRemaining;
    }

    function getItemsRemaining(uint256 tokenId) public view returns(string[maxItems] memory) {
        require(isMinted(tokenId), 'BOUNTY_NOT_MINTED');

        uint256[6][maxItems] memory componentsRemaining = getComponentsRemaining(tokenId);
        string[maxItems] memory itemsRemaining;
        for (uint256 i = 0; i < maxItems; i += 1) {
            if (componentsRemaining[i][5] > 0) {
                itemsRemaining[i] = _lootComponentsContract.getItemName(componentsRemaining[i][0], componentsRemaining[i][5]);
            }
        }

        return itemsRemaining;
    }

    function areBountyRequirementsMet(uint256 tokenId) public view returns (bool) {
        string[maxItems] memory itemsRemaining = getItemsRemaining(tokenId);

        for (uint256 i = 0; i < maxItems; i += 1) {
            if (bytes(itemsRemaining[i]).length > 0) {
                return false;
            }
        }

        return true;
    }

    function getLootPledgedToBounty(uint256 tokenId) public view returns (uint256[] memory) {
        return lootTokensPledged[tokenId];
    }

    function completeBounty(uint256 tokenId) public {
        require(
            _msgSender() == ownerOf(tokenId),
            "MUST_OWN_BOUNTY_TOKEN"
        );
        require(
            areBountyRequirementsMet(tokenId),
            "BOUNTY_REQUIREMENTS_NOT_MET"
        );

        // Mint GLORY
        uint256 gloryReward = getGloryReward(tokenId);
        uint256 goldReward = getGoldReward(tokenId);
        uint256 numRecipients = lootTokensPledged[tokenId].length;
        uint256 gloryPerRecipient = (gloryReward * decimals) / numRecipients;
        uint256 goldPerRecipient = (goldReward * decimals) / (numRecipients - 1);

        // Bounty minter gets glory
        _gloryContract.mint(msg.sender, gloryPerRecipient);

        // All participants get glory and gold
        for (uint256 i = 1; i < numRecipients; i += 1) {
            uint256 lootTokenId = lootTokensPledged[tokenId][i];
            address ownerOfLoot;
            if (lootTokenId <= 8000) {
                ownerOfLoot = _lootContract.ownerOf(lootTokensPledged[tokenId][i]);
            } else {
                ownerOfLoot = _mlootContract.ownerOf(lootTokensPledged[tokenId][i]);
            }
            _gloryContract.mint(ownerOfLoot, gloryPerRecipient);
            _goldContract.transfer(ownerOfLoot, goldPerRecipient);
        }
        // TODO: Mint Trophy



        _burn(tokenId);

    }

    function pledgeLootToBounty(uint256 lootTokenId, uint256 bountyTokenId) public {
        require(isMinted(bountyTokenId), 'BOUNTY_NOT_MINTED');
        if (lootTokenId <= 8000) {
            require(
                _msgSender() == _lootContract.ownerOf(lootTokenId),
                "MUST_OWN_LOOT_TOKEN"
            );
        } else {
            require(
                _msgSender() == _mlootContract.ownerOf(lootTokenId),
                "MUST_OWN_LOOT_TOKEN"
            );
        }
        for (uint256 i = 1; i < lootTokensPledged[bountyTokenId].length; i += 1) {
            require(lootTokenId != lootTokensPledged[bountyTokenId][i], 'LOOT_ALREADY_PLEDGED');
        }

        uint256[6][maxItems] memory requiredItems = getComponentsRemaining(bountyTokenId);
        bool hasRequiredLoot = false;
        for  (uint i = 0; i < maxItems; i += 1) {
            uint256[6] memory requiredItem = requiredItems[i];
            if (requiredItem[5] == 0) {
                continue;
            }
            uint256[6] memory lootItem = getItemSlotForTokenId(requiredItem[5], lootTokenId);
            if (requiredItem[0] == lootItem[0]) {
                hasRequiredLoot = true;
                break;
            }
        }
        require(hasRequiredLoot, 'LOOT_MUST_CONTAIN_UNMET_ITEM_REQUIREMENT');

        lootTokensPledged[bountyTokenId].push(lootTokenId);
    }

    function compareItems(uint256[6] memory item1, uint256[6] memory item2)
        private
        pure
        returns (bool)
    {
        return
            item1[0] == item2[0] &&
            item1[1] == item2[1] &&
            item1[2] == item2[2] &&
            item1[3] == item2[3] &&
            item1[4] == item2[4];
    }

    function getBountyRequirements(uint256 tokenId)
        public
        view
        returns (uint256[6][maxItems] memory)
    {
        uint256 difficulty = Utils.getDifficulty(tokenId);
        uint256 itemCount = [_heroicItemRolls, _epicItemRolls, _legendaryItemRolls][difficulty];
        uint256[6][maxItems] memory requiredItems;
        for (uint8 i = 0; i < itemCount; i += 1) {
            uint256[6] memory item = getRandomItem(i, tokenId);
            bool isDupe = false;
            for (uint8 j = 0; j < i; j += 1) {
                if (compareItems(item, requiredItems[j])) {
                    isDupe = true;
                    break;
                }
            }
            if (isDupe) {
                continue;
            }
            requiredItems[i] = item;
        }
        return requiredItems;
    }

    function getBountyRequirementsText(uint256 tokenId)
        public
        view
        returns (string[maxItems] memory)
    {
        uint256[6][maxItems] memory reqs = getBountyRequirements(tokenId);
        string[maxItems] memory reqStrings;
        for (uint i = 0; i < maxItems; i += 1) {
            if (reqs[i][5] > 0) {
                reqStrings[i] = _lootComponentsContract.getItemName(reqs[i][0], reqs[i][5]);
            }
        }
        return reqStrings;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory monster = getBountyMonster(tokenId);
        string[maxItems] memory itemReqs = this.getBountyRequirementsText(tokenId);
        string memory questType = [unicode' ℍ𝔼ℝ𝕆𝕀ℂ ', unicode'n ❗️𝔼ℙ𝕀ℂ❗️ ',  unicode' ‼️𝕃𝔼𝔾𝔼ℕ𝔻𝔸ℝ𝕐‼️ '][Utils.getDifficulty(tokenId)];
        string memory questTypeAttribute = ['Heroic', 'Epic', 'Legendary'][Utils.getDifficulty(tokenId)];
        string memory gloryReward = [unicode'𝟙,𝟘𝟘𝟘', unicode'𝟛,𝟘𝟘𝟘', unicode'𝟙𝟘,𝟘𝟘𝟘'][Utils.getDifficulty(tokenId)];
        string memory goldReward = [unicode'1𝟘𝟘', unicode'𝟛𝟘𝟘', unicode'𝟙,𝟘𝟘𝟘'][Utils.getDifficulty(tokenId)];
        
        string memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 12px; }</style><rect width="100%" height="100%" fill="black" />';
        output = string(abi.encodePacked(output, '<text x="10" y="20" class="base">A', questType, 'bounty has been posted to slay the</text><text x="10" y="35" class="base">'));
        output = string(abi.encodePacked(output, monster));
        output = string(abi.encodePacked(output, ' terrorizing our lands!</text><text x="10" y="70" class="base">'));
        output = string(abi.encodePacked(output, 'To complete the bounty, gather your fellow adventurers</text><text x="10" y="85" class="base">who hold the required items:</text>'));

        uint256 line = 0;
        uint256 xPos = 10;
        for (uint256 i = 0; i < maxItems; i += 1) {
            if (bytes(itemReqs[i]).length != 0) {
                uint256 yPos = (line * 15) + 120;
                output = string(abi.encodePacked(output, '<text x="', uint2str(xPos),'" y="', uint2str(yPos), '" class="base">', itemReqs[i], '</text>'));
                if (line == 10) {
                    line = 0;
                    xPos = 165;
                } else {
                    line += 1;
                }
            } else {
                output = string(abi.encodePacked(output, ''));
            }
        }

        output = string(abi.encodePacked(
            output,
            unicode'<text x="10" y="325" class="base">The party will split ✨',
            gloryReward,
            unicode' 𝔾𝕃𝕆ℝ𝕐✨ and 💰',
            goldReward,
            unicode' 𝔸𝔾𝕃𝔻💰</text><text x="10" y="340" class="base">upon completion.</text></svg>'));

        string memory attributes = string(abi.encodePacked('"attributes": [{ "trait_type": "Bounty Type", "value": "', questTypeAttribute, '" }]}'));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Bounty #',
                        Utils.toString(tokenId),
                        '", "description": "Bounties can be redeemed for glory when multiple adventurers coordinate to fulfill the required items.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '", ',
                        attributes
                    )
                )
            )
        );
        return json;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract GloryForAdventurers is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Glory (for Adventurers)", "GLORY") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function setBountyAsMinter(address bountyContractAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, bountyContractAddress);
    }
}

/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: Unlicense

/*

    LootComponents.sol
    
    This is a utility contract to make it easier for other
    contracts to work with Loot properties.
    
    Call weaponComponents(), chestComponents(), etc. to get 
    an array of attributes that correspond to the item. 
    
    The return format is:
    
    uint256[6] =>
        [0] = Item ID
        [1] = Suffix ID (0 for none)
        [2] = Name Prefix ID (0 for none)
        [3] = Name Suffix ID (0 for none)
        [4] = Augmentation (0 = false, 1 = true)
        [5] = Item Slot (1-8, 0 reserved for null state)
            weapons - 1
            chestArmor - 2
            headArmor - 3
            waistArmor - 4
            footArmor - 5
            handArmor - 6
            necklaces - 7
            rings - 8
    
    See the item and attribute tables below for corresponding IDs.

*/

pragma solidity ^0.8.4;

contract LootComponents {

    string[] private nil = [''];

    string[] private weapons = [
        "Warhammer",            // 0
        "Quarterstaff",         // 1
        "Maul",                 // 2
        "Mace",                 // 3
        "Club",                 // 4
        "Katana",               // 5
        "Falchion",             // 6
        "Scimitar",             // 7
        "Long Sword",           // 8
        "Short Sword",          // 9
        "Ghost Wand",           // 10
        "Grave Wand",           // 11
        "Bone Wand",            // 12
        "Wand",                 // 13
        "Grimoire",             // 14
        "Chronicle",            // 15
        "Tome",                 // 16
        "Book"                  // 17
    ];
    
    string[] private chestArmor = [
        "Divine Robe",          // 0
        "Silk Robe",            // 1
        "Linen Robe",           // 2
        "Robe",                 // 3
        "Shirt",                // 4
        "Demon Husk",           // 5
        "Dragonskin Armor",     // 6
        "Studded Leather Armor",// 7
        "Hard Leather Armor",   // 8
        "Leather Armor",        // 9
        "Holy Chestplate",      // 10
        "Ornate Chestplate",    // 11
        "Plate Mail",           // 12
        "Chain Mail",           // 13
        "Ring Mail"             // 14
    ];
    
    string[] private headArmor = [
        "Ancient Helm",         // 0
        "Ornate Helm",          // 1
        "Great Helm",           // 2
        "Full Helm",            // 3
        "Helm",                 // 4
        "Demon Crown",          // 5
        "Dragon's Crown",       // 6
        "War Cap",              // 7
        "Leather Cap",          // 8
        "Cap",                  // 9
        "Crown",                // 10
        "Divine Hood",          // 11
        "Silk Hood",            // 12
        "Linen Hood",           // 13
        "Hood"                  // 14
    ];
    
    string[] private waistArmor = [
        "Ornate Belt",          // 0
        "War Belt",             // 1
        "Plated Belt",          // 2
        "Mesh Belt",            // 3
        "Heavy Belt",           // 4
        "Demonhide Belt",       // 5
        "Dragonskin Belt",      // 6
        "Studded Leather Belt", // 7
        "Hard Leather Belt",    // 8
        "Leather Belt",         // 9
        "Brightsilk Sash",      // 10
        "Silk Sash",            // 11
        "Wool Sash",            // 12
        "Linen Sash",           // 13
        "Sash"                  // 14
    ];
    
    string[] private footArmor = [
        "Holy Greaves",         // 0
        "Ornate Greaves",       // 1
        "Greaves",              // 2
        "Chain Boots",          // 3
        "Heavy Boots",          // 4
        "Demonhide Boots",      // 5
        "Dragonskin Boots",     // 6
        "Studded Leather Boots",// 7
        "Hard Leather Boots",   // 8
        "Leather Boots",        // 9
        "Divine Slippers",      // 10
        "Silk Slippers",        // 11
        "Wool Shoes",           // 12
        "Linen Shoes",          // 13
        "Shoes"                 // 14
    ];
    
    string[] private handArmor = [
        "Holy Gauntlets",       // 0
        "Ornate Gauntlets",     // 1
        "Gauntlets",            // 2
        "Chain Gloves",         // 3
        "Heavy Gloves",         // 4
        "Demon's Hands",        // 5
        "Dragonskin Gloves",    // 6
        "Studded Leather Gloves",// 7
        "Hard Leather Gloves",  // 8
        "Leather Gloves",       // 9
        "Divine Gloves",        // 10
        "Silk Gloves",          // 11
        "Wool Gloves",          // 12
        "Linen Gloves",         // 13
        "Gloves"                // 14
    ];
    
    string[] private necklaces = [
        "Necklace",             // 0
        "Amulet",               // 1
        "Pendant"               // 2
    ];
    
    string[] private rings = [
        "Gold Ring",            // 0
        "Silver Ring",          // 1
        "Bronze Ring",          // 2
        "Platinum Ring",        // 3
        "Titanium Ring"         // 4
    ];
    
    string[] private suffixes = [
        // <no suffix>          // 0
        "of Power",             // 1
        "of Giants",            // 2
        "of Titans",            // 3
        "of Skill",             // 4
        "of Perfection",        // 5
        "of Brilliance",        // 6
        "of Enlightenment",     // 7
        "of Protection",        // 8
        "of Anger",             // 9
        "of Rage",              // 10
        "of Fury",              // 11
        "of Vitriol",           // 12
        "of the Fox",           // 13
        "of Detection",         // 14
        "of Reflection",        // 15
        "of the Twins"          // 16
    ];
    
    string[] private namePrefixes = [
        // <no name>            // 0
        "Agony",                // 1
        "Apocalypse",           // 2
        "Armageddon",           // 3
        "Beast",                // 4
        "Behemoth",             // 5
        "Blight",               // 6
        "Blood",                // 7
        "Bramble",              // 8
        "Brimstone",            // 9
        "Brood",                // 10
        "Carrion",              // 11
        "Cataclysm",            // 12
        "Chimeric",             // 13
        "Corpse",               // 14
        "Corruption",           // 15
        "Damnation",            // 16
        "Death",                // 17
        "Demon",                // 18
        "Dire",                 // 19
        "Dragon",               // 20
        "Dread",                // 21
        "Doom",                 // 22
        "Dusk",                 // 23
        "Eagle",                // 24
        "Empyrean",             // 25
        "Fate",                 // 26
        "Foe",                  // 27
        "Gale",                 // 28
        "Ghoul",                // 29
        "Gloom",                // 30
        "Glyph",                // 31
        "Golem",                // 32
        "Grim",                 // 33
        "Hate",                 // 34
        "Havoc",                // 35
        "Honour",               // 36
        "Horror",               // 37
        "Hypnotic",             // 38
        "Kraken",               // 39
        "Loath",                // 40
        "Maelstrom",            // 41
        "Mind",                 // 42
        "Miracle",              // 43
        "Morbid",               // 44
        "Oblivion",             // 45
        "Onslaught",            // 46
        "Pain",                 // 47
        "Pandemonium",          // 48
        "Phoenix",              // 49
        "Plague",               // 50
        "Rage",                 // 51
        "Rapture",              // 52
        "Rune",                 // 53
        "Skull",                // 54
        "Sol",                  // 55
        "Soul",                 // 56
        "Sorrow",               // 57
        "Spirit",               // 58
        "Storm",                // 59
        "Tempest",              // 60
        "Torment",              // 61
        "Vengeance",            // 62
        "Victory",              // 63
        "Viper",                // 64
        "Vortex",               // 65
        "Woe",                  // 66
        "Wrath",                // 67
        "Light's",              // 68
        "Shimmering"            // 69  
    ];
    
    string[] private nameSuffixes = [
        // <no name>            // 0
        "Bane",                 // 1
        "Root",                 // 2
        "Bite",                 // 3
        "Song",                 // 4
        "Roar",                 // 5
        "Grasp",                // 6
        "Instrument",           // 7
        "Glow",                 // 8
        "Bender",               // 9
        "Shadow",               // 10
        "Whisper",              // 11
        "Shout",                // 12
        "Growl",                // 13
        "Tear",                 // 14
        "Peak",                 // 15
        "Form",                 // 16
        "Sun",                  // 17
        "Moon"                  // 18
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function weaponComponents(uint256 tokenId) public view returns (uint256[6] memory) {
        return pluck(tokenId, "WEAPON", weapons, 1);
    }
    
    function chestComponents(uint256 tokenId) public view returns (uint256[6] memory) {
        return pluck(tokenId, "CHEST", chestArmor, 2);
    }
    
    function headComponents(uint256 tokenId) public view returns (uint256[6] memory) {
        return pluck(tokenId, "HEAD", headArmor, 3);
    }
    
    function waistComponents(uint256 tokenId) public view returns (uint256[6] memory) {
        return pluck(tokenId, "WAIST", waistArmor, 4);
    }

    function footComponents(uint256 tokenId) public view returns (uint256[6] memory) {
        return pluck(tokenId, "FOOT", footArmor, 5);
    }
    
    function handComponents(uint256 tokenId) public view returns (uint256[6] memory) {
        return pluck(tokenId, "HAND", handArmor, 6);
    }
    
    function neckComponents(uint256 tokenId) public view returns (uint256[6] memory) {
        return pluck(tokenId, "NECK", necklaces, 7);
    }
    
    function ringComponents(uint256 tokenId) public view returns (uint256[6] memory) {
        return pluck(tokenId, "RING", rings, 8);
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray, uint256 itemSlot) internal view returns (uint256[6] memory) {
        uint256[6] memory components;
        
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        
        components[0] = rand % sourceArray.length;
        components[1] = 0;
        components[2] = 0;
        components[5] = itemSlot;
        
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            components[1] = (rand % suffixes.length) + 1;
        }
        if (greatness >= 19) {
            components[2] = (rand % namePrefixes.length) + 1;
            components[3] = (rand % nameSuffixes.length) + 1;
            if (greatness == 19) {
                // ...
            } else {
                components[4] = 1;
            }
        }
        return components;
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

    // Pass in (item[0], item[5])
    function getItemName(uint256 itemNum, uint256 itemSlot) public view returns (string memory) {
        return [
            nil, // null case
            weapons,
            chestArmor,
            headArmor,
            waistArmor,
            footArmor,
            handArmor,
            necklaces,
            rings
        ][itemSlot][itemNum];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./Base64.sol";
import "./Utils.sol";

contract TrophiesForAdventurers is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl {
    string[] Prefixes = [
        unicode"𝕍𝔼ℕ𝔾𝔼𝔽𝕌𝕃",
        unicode"ℂ𝕆ℝℝ𝕌ℙ𝕋𝔼𝔻",
        unicode"ℝ𝔸𝕍𝔼ℕ𝕆𝕌𝕊",
        unicode"𝔽𝕆ℝ𝕊𝔸𝕂𝔼ℕ",
        unicode"𝕀ℕ𝔽𝔼ℝℕ𝔸𝕃",
        unicode"ℙ𝕆𝕊𝕊𝔼𝕊𝕊𝔼𝔻",
        unicode"𝕍𝕀ℂ𝕀𝕆𝕌𝕊",
        unicode"ℝ𝔸𝔹𝕀𝔻",
        unicode"𝕄𝔸𝔻𝔻𝔼ℕ𝔼𝔻",
        unicode"𝔹𝕃𝕆𝕆𝔻𝕋ℍ𝕀ℝ𝕊𝕋𝕐",
        unicode"ℙ𝕌𝕋ℝ𝕀𝔻",
        unicode"𝔾ℝ𝕀𝕊𝕃𝕐",
        unicode"𝕄𝕌𝕋𝔸ℕ𝕋",
        unicode"𝕊𝔸𝕍𝔸𝔾𝔼",
        unicode"𝕎ℝ𝔼𝕋ℂℍ𝔼𝔻",
        unicode"𝔽𝔼ℝ𝔸𝕃",
        unicode"𝔸ℕℂ𝕀𝔼ℕ𝕋",
        unicode"𝔹𝔼𝕎𝕀𝕋ℂℍ𝔼𝔻"
    ];

    string[] HeroicMonsters = [
        unicode"ℝ𝔸ℙ𝕋𝕆ℝ",
        unicode"𝕄𝔸ℕ𝔻ℝ𝔸𝔾𝕆ℝ𝔸",
        unicode"𝕊𝔸𝕃𝔸𝕄𝔸ℕ𝔻𝔼ℝ",
        unicode"𝔽𝕀𝔼ℕ𝔻",
        unicode"𝔹𝔸ℕ𝕊ℍ𝔼𝔼",
        unicode"ℙℍ𝕆𝔼ℕ𝕀𝕏",
        unicode"𝕀ℂ𝔼 𝕊ℙ𝕀𝔻𝔼ℝ",
        unicode"𝕃𝔼ℙℝ𝔼ℂℍ𝔸𝕌ℕ",
        unicode"𝕀𝕄ℙ",
        unicode"𝕊𝔸𝔹ℝ𝔼𝕋𝕆𝕆𝕋ℍ",
        unicode"𝕋ℝ𝕆𝕃𝕃",
        unicode"𝔻ℝ𝔸𝕌𝔾ℝ",
        unicode"ℤ𝕆𝕄𝔹𝕀𝔼",
        unicode"𝔾ℍ𝕆𝕌𝕃",
        unicode"𝔾ℍ𝕆𝕊𝕋",
        unicode"ℍ𝔼𝕃𝕃ℍ𝕆𝕌ℕ𝔻",
        unicode"𝔻𝔼𝔼ℙ 𝔾ℕ𝕆𝕄𝔼",
        unicode"𝔾𝕆𝔹𝕃𝕀ℕ",
        unicode"𝕊𝔸𝕋𝕐ℝ",
        unicode"𝕂𝕆𝔹𝕆𝕃𝔻",
        unicode"𝔻ℝ𝕐𝔸𝔻",
        unicode"𝕆ℝℂ",
        unicode"𝕎𝕀𝔾ℍ𝕋",
        unicode"𝕐𝔼𝕋𝕀",
        unicode"𝕊ℙ𝕀𝔻𝔼ℝ 𝕄𝕆ℕ𝕂𝔼𝕐"
    ];

    string[] EpicMonsters = [
        unicode"𝕆𝕎𝕃𝔹𝔼𝔸ℝ",
        unicode"ℍ𝔸𝔾",
        unicode"𝕆𝔾ℝ𝔼",
        unicode"𝕊𝔼𝔸 𝕊𝔼ℝℙ𝔼ℕ𝕋",
        unicode"𝕎𝕀𝕋ℂℍ",
        unicode"𝕎ℝ𝔸𝕀𝕋ℍ",
        unicode"𝕎𝕌ℝ𝕄",
        unicode"𝕎𝕐𝕍𝔼ℝℕ",
        unicode"𝔾ℝ𝕀𝔽𝔽𝕀ℕ",
        unicode"ℍ𝕀ℙℙ𝕆𝔾ℝ𝕀𝔽𝔽",
        unicode"𝔹𝕌𝔾𝔹𝔼𝔸ℝ",
        unicode"𝕀ℕℂ𝕌𝔹𝕌𝕊",
        unicode"𝔻𝔼𝕄𝕆ℕ",
        unicode"ℂℍ𝕌ℙ𝔸ℂ𝔸𝔹ℝ𝔸",
        unicode"𝔸𝕃𝕀𝔼ℕ",
        unicode"𝕍𝔸𝕄ℙ𝕀ℝ𝔼",
        unicode"𝕎𝔼ℝ𝔼𝕎𝕆𝕃𝔽",
        unicode"𝕊𝔸𝕊ℚ𝕌𝔸𝕋ℂℍ",
        unicode"𝔼ℕ𝕋",
        unicode"ℂ𝔼ℕ𝕋𝔸𝕌ℝ",
        unicode"ℂ𝕆ℂ𝕂𝔸𝕋ℝ𝕀ℂ𝔼",
        unicode"𝔾𝕆𝕃𝔼𝕄",
        unicode"𝔻𝔸ℝ𝕂 𝔼𝕃𝔽",
        unicode"ℍ𝕆𝔹𝔾𝕆𝔹𝕃𝕀ℕ",
        unicode"𝕄𝕀ℕ𝕆𝕋𝔸𝕌ℝ",
        unicode"ℕ𝔼ℂℝ𝕆𝕄𝔸ℕℂ𝔼ℝ",
        unicode"𝕊𝕋𝕆ℕ𝔼 𝔾𝕀𝔸ℕ𝕋",
        unicode"𝔽ℝ𝕆𝕊𝕋 𝔾𝕀𝔸ℕ𝕋",
        unicode"ℍ𝕀𝕃𝕃 𝔾𝕀𝔸ℕ𝕋"
    ];

    string[] LegendaryMonsters = [
        unicode"𝔻ℝ𝔸𝔾𝕆ℕ",
        unicode"𝔹𝔸𝕊𝕀𝕃𝕀𝕊𝕂",
        unicode"𝔻ℝ𝔸𝔾𝕆ℕ 𝕋𝕌ℝ𝕋𝕃𝔼",
        unicode"𝕄𝔸ℕ𝔹𝔼𝔸ℝℙ𝕀𝔾",
        unicode"𝕃𝔼𝕍𝕀𝔸𝕋ℍ𝔸ℕ",
        unicode"ℂℍ𝕀𝕄𝔼ℝ𝔸",
        unicode"ℍ𝕐𝔻ℝ𝔸",
        unicode"𝕊ℙℍ𝕀ℕ𝕏",
        unicode"𝔾𝕆ℝ𝔾𝕆ℕ",
        unicode"𝔸𝔹𝔸𝔻𝔻𝕆ℕ",
        unicode"𝕂ℝ𝔸𝕂𝔼ℕ",
        unicode"𝕄𝔸ℕ𝕋𝕀ℂ𝕆ℝ𝔼",
        unicode"ℙ𝕀𝕋 𝔽𝕀𝔼ℕ𝔻",
        unicode"ℂ𝕃𝕆𝕌𝔻 𝔾𝕀𝔸ℕ𝕋",
        unicode"𝕊𝕋𝕆ℝ𝕄 𝔾𝕀𝔸ℕ𝕋",
        unicode"𝔽𝕀ℝ𝔼 𝔾𝕀𝔸ℕ𝕋",
        unicode"𝕄𝔼𝔻𝕌𝕊𝔸",
        unicode"𝔸ℝℂℍ𝕄𝔸𝔾𝔼",
        unicode"𝕃𝕀ℂℍ",
        unicode"𝔻𝕁𝕀ℕℕ",
        unicode"ℝ𝔼𝕍𝔼ℕ𝔸ℕ𝕋",
        unicode"𝔻𝔼𝕍𝕆𝕌ℝ𝔼ℝ"
    ];


    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC721("Trophies", "TROPHY") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
    }

    function setBountyAsMinter(address bountyContractAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, bountyContractAddress);
    }

    function getBountyMonster(uint256 tokenId) public view returns (string memory) {
        uint256 rand1 = Utils.random(
            string(abi.encodePacked(Utils.toString(tokenId)))
        );
        uint256 rand2 = Utils.random(
            string(abi.encodePacked(Utils.toString(tokenId * tokenId)))
        );
        uint256 difficulty = Utils.getDifficulty(tokenId);
        uint256 prefixIndex = rand1 % Prefixes.length;
        uint256 monsterIndex;
        if (difficulty == 0) {
            monsterIndex = rand2 % HeroicMonsters.length;
            return string(abi.encodePacked(Prefixes[prefixIndex], ' ', HeroicMonsters[monsterIndex]));
        }
        if (difficulty == 1) {
            monsterIndex = rand2 % EpicMonsters.length;
            return string(abi.encodePacked(Prefixes[prefixIndex], ' ', EpicMonsters[monsterIndex]));
        }
        monsterIndex = rand2 % LegendaryMonsters.length;
        return string(abi.encodePacked(Prefixes[prefixIndex], ' ', LegendaryMonsters[monsterIndex]));
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory questTypeAttribute = ['Heroic', 'Epic', 'Legendary'][Utils.getDifficulty(tokenId)];
        string memory questType = [unicode' ℍ𝔼ℝ𝕆𝕀ℂ ', unicode'n ❗️𝔼ℙ𝕀ℂ❗️ ',  unicode' ‼️𝕃𝔼𝔾𝔼ℕ𝔻𝔸ℝ𝕐‼️ '][Utils.getDifficulty(tokenId)];
        string memory monster = getBountyMonster(tokenId);

        string memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        output = string(abi.encodePacked(
          output,
          '<text x="10" y="20" class="base">The severed head of a ',
          monster,
          '</text><text x="10" y="40" class="base">slain as part of a', questType, 'bounty.</text></svg>'));

        string memory attributes = string(abi.encodePacked('"attributes": [{ "trait_type": "Bounty Type", "value": "', questTypeAttribute, '" }]}'));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Trophy #',
                        Utils.toString(tokenId),
                        '", "description": "Trophies are tokens of heroism gained from completing bounties with fellow adventurers.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '", ',
                        attributes
                    )
                )
            )
        );
        return json;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library Utils {
    function getDifficulty(uint256 tokenId) internal pure returns (uint256) {
        return tokenId % 3;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
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

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
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

