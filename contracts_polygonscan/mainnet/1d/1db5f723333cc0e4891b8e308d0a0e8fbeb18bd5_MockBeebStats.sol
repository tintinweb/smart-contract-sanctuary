/**
 *Submitted for verification at polygonscan.com on 2021-07-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IBeebStats {
    /**
     * @dev Returns game info.
     */
    function info(uint256 tokenId)
        external
        view
        returns (
            uint256 totalSupply,
            uint256 totalBurn,
            uint256 totalFusion,
            uint256[] memory otherInfo
        );

    /**
     * @dev Returns MeebMaster stats from the token ID
     */
    function stats(uint256 tokenId)
        external
        view
        returns (
            uint16[] memory pvpStats,
            uint16 luckStat,
            uint16 productivityStat,
            uint256 otherStats
        );
}

contract MockBeebStats is IBeebStats {
    function info(uint256 tokenId)
        external
        view
        override
        returns (
            uint256 totalSupply,
            uint256 totalBurn,
            uint256 totalFusion,
            uint256[] memory otherInfo
        )
    {}

    function stats(uint256 tokenId)
        external
        view
        override
        returns (
            uint16[] memory pvpStats,
            uint16 luckStat,
            uint16 productivityStat,
            uint256 otherStats
        )
    {
        if (tokenId % 6 == 1) productivityStat = 100;
        else if (tokenId % 6 == 2) productivityStat = 200;
        else if (tokenId % 6 == 3) productivityStat = 300;
        else if (tokenId % 6 == 4) productivityStat = 400;
        else if (tokenId % 6 == 5) productivityStat = 500;
    }
}