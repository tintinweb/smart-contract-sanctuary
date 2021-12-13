//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./interfaces/IRarityHomestead.sol";
import "./interfaces/IRarity.sol";

contract RHBulkUpkeepAndTransfer {
    IRarityHomestead constant rh =
        IRarityHomestead(0xEf86d4Ba2a6Bd9038a2ACee23155FBC64f530e55);
    IRarity constant rm = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

    function _isApprovedOrOwnerOfSummoner(uint256 _summoner)
        internal
        view
        returns (bool)
    {
        return
            rm.getApproved(_summoner) == msg.sender ||
            rm.ownerOf(_summoner) == msg.sender ||
            rm.isApprovedForAll(rm.ownerOf(_summoner), msg.sender);
    }

    function upkeepPlots(uint256 _summonerId, uint256[] calldata _tokenIds)
        external
    {
        require(_isApprovedOrOwnerOfSummoner(_summonerId));
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            rh.upkeepPlot(_summonerId, tokenId);
        }
    }

    function safeTransferFrom(
        uint256 from,
        uint256 to,
        uint256[] memory tokenIds
    ) public {
        require(_isApprovedOrOwnerOfSummoner(from));
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            rh.safeTransferFrom(from, to, tokenId);
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IRarityHomestead {
    function PLOT_GOLD_PRICE() external view returns (uint256);

    function _tokenIdCounter() external view returns (uint256);

    function approve(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) external;

    function balanceOf(uint256 owner) external view returns (uint256);

    function changePlots(
        uint256 _summonerId,
        uint256[] memory _tokenIds,
        uint128[] memory _ts
    ) external;

    function claimPlots(
        uint256 _summonerId,
        int128[] memory _xs,
        int128[] memory _ys,
        uint128[] memory _ts,
        bool _preApproved
    ) external;

    function getApproved(uint256 tokenId) external view returns (uint256);

    function goldExecutor() external view returns (uint256);

    function goldKeeper() external view returns (uint256);

    function isApprovedForAll(uint256 owner, uint256 operator)
        external
        view
        returns (bool);

    function latestUpkeep(uint256 _summonerId)
        external
        view
        returns (
            uint256,
            int128,
            int128
        );

    function name() external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (uint256);

    function plot_id_at(int128, int128) external view returns (uint256);

    function plots(uint256)
        external
        view
        returns (
            int128 x,
            int128 y,
            uint128 t,
            uint256 upkeep_log,
            uint128 upkeep_count,
            bool exists
        );

    function plotsBetween(
        int128 x1,
        int128 y1,
        int128 x2,
        int128 y2
    ) external view returns (int256[] memory);

    function rarityGoldContract() external view returns (address);

    function rm() external view returns (address);

    function safeTransferFrom(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(
        uint256 from,
        uint256 operator,
        bool approved
    ) external;

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(uint256 owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) external;

    function typeOf(uint256 _tokenId) external view returns (uint128);

    function upkeepAll(uint256 _summonerId) external;

    function upkeepPlot(uint256 _summonerId, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.10;

interface IRarity {
    // ERC721
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    // Rarity
    event summoned(address indexed owner, uint256 _class, uint256 summoner);
    event leveled(address indexed owner, uint256 level, uint256 summoner);

    function next_summoner() external returns (uint256);

    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function xp(uint256) external view returns (uint256);

    function adventurers_log(uint256) external view returns (uint256);

    function class(uint256) external view returns (uint256);

    function level(uint256) external view returns (uint256);

    function adventure(uint256 _summoner) external;

    function spend_xp(uint256 _summoner, uint256 _xp) external;

    function level_up(uint256 _summoner) external;

    function summoner(uint256 _summoner)
        external
        view
        returns (
            uint256 _xp,
            uint256 _log,
            uint256 _class,
            uint256 _level
        );

    function summon(uint256 _class) external;

    function xp_required(uint256 curent_level)
        external
        pure
        returns (uint256 xp_to_next_level);

    function tokenURI(uint256 _summoner) external view returns (string memory);

    function classes(uint256 id)
        external
        pure
        returns (string memory description);
}