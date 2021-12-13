//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./interfaces/IRarityHomestead.sol";

contract RHBulkUpkeepAndTransfer {
    IRarityHomestead constant rh =
        IRarityHomestead(0xEf86d4Ba2a6Bd9038a2ACee23155FBC64f530e55);

    function upkeepPlots(uint256 _summonerId, uint256[] calldata _tokenIds)
        external
    {
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