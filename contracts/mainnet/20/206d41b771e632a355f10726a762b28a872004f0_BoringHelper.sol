/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract BoringHelper {
    struct Balance {
        IERC20 token;
        uint256 balance;
    }
    
    function findBalances(address who, address[] calldata addresses) public view returns (Balance[] memory) {
        Balance[] memory balances = new Balance[](addresses.length);

        uint256 len = addresses.length;
        for (uint256 i = 0; i < len; i++) {
            IERC20 token = IERC20(addresses[i]);
            balances[i].token = token;
            balances[i].balance = token.balanceOf(who);
        }

        return balances;
    }
}