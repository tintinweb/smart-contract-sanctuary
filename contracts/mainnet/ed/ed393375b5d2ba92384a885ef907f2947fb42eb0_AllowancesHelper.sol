/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IERC20 {
    function allowance(address spender, address owner)
        external
        view
        returns (uint256);
}

contract AllowancesHelper {
    struct Allowance {
        address owner;
        address spender;
        uint256 amount;
        address token;
    }

    function allowances(
        address ownerAddress,
        address[] memory tokensAddresses,
        address[] memory spenderAddresses
    ) external view returns (Allowance[] memory) {
        uint256 spenderIdx;
        uint256 tokenIdx;
        uint256 numberOfAllowances;

        // Calculate number of allowances
        for (tokenIdx = 0; tokenIdx < tokensAddresses.length; tokenIdx++) {
            for (
                spenderIdx = 0;
                spenderIdx < spenderAddresses.length;
                spenderIdx++
            ) {
                address tokenAddress = tokensAddresses[tokenIdx];
                address spenderAddress = spenderAddresses[spenderIdx];
                IERC20 token = IERC20(tokenAddress);
                uint256 amount = token.allowance(ownerAddress, spenderAddress);
                if (amount > 0) {
                    numberOfAllowances++;
                }
            }
        }

        Allowance[] memory _allowances = new Allowance[](numberOfAllowances);

        // Fetch allowances
        for (tokenIdx = 0; tokenIdx < tokensAddresses.length; tokenIdx++) {
            for (
                spenderIdx = 0;
                spenderIdx < spenderAddresses.length;
                spenderIdx++
            ) {
                uint256 allowanceIdx;
                address spenderAddress = spenderAddresses[spenderIdx];
                address tokenAddress = tokensAddresses[tokenIdx];
                IERC20 token = IERC20(tokenAddress);
                uint256 amount = token.allowance(ownerAddress, spenderAddress);
                if (amount > 0) {
                    Allowance memory allowance =
                        Allowance({
                            owner: ownerAddress,
                            spender: spenderAddress,
                            amount: amount,
                            token: tokenAddress
                        });
                    _allowances[allowanceIdx] = allowance;
                }
            }
        }
        return _allowances;
    }
}