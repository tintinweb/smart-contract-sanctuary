// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./ERC20.sol";

interface MasterChef {
    function userInfo(uint256, address)
        external
        view
        returns (uint256, uint256);
}

contract StakedBaskEth {
    // BASK/ETH
    IERC20 public constant votes = IERC20(
        0x34D25a4749867eF8b62A0CD1e2d7B4F7aF167E01
    );

    // Masterchef contract
    MasterChef public constant chef = MasterChef(
        0xDB9daa0a50B33e4fe9d0ac16a1Df1d335F96595e
    );

    // Pool 2 is the staked BASK/ETH
    uint256 public constant pool = uint256(2);

    // Using 9 decimals as we're square rooting the votes
    function decimals() external pure returns (uint8) {
        return uint8(9);
    }

    function name() external pure returns (string memory) {
        return "Staked BASK/ETH";
    }

    function symbol() external pure returns (string memory) {
        return "sBASKETH";
    }

    function totalSupply() external view returns (uint256) {
        return votes.totalSupply();
    }

    function balanceOf(address _voter) external view returns (uint256) {
        (uint256 _votes, ) = chef.userInfo(pool, _voter);
        return _votes;
    }

    constructor() {}
}