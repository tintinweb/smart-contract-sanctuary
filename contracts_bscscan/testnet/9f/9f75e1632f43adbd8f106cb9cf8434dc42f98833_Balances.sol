/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract Balances {
    function getBalances(address user, address[] calldata tokens) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == address(0)) {
                // Get Native coin balance
                result[i] = user.balance;
            } else {
                // Get ERC20 token balance
                result[i] = IERC20(tokens[i]).balanceOf(user);
            }
        }

        return result;
    }
}