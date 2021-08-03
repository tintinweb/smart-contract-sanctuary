/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

/*
*  FlashBorrowerExample is a simple smart contract that enables
*  to borrow and returns a flash loan.
*/
contract FlashBorrowerExample is IERC3156FlashBorrower {
    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        
        // Set the allowance to payback the flash loan
        IERC20(token).approve(msg.sender, MAX_INT);
        
        // Build your trading business logic here
        // e.g., sell on uniswapv2
        // e.g., buy on uniswapv3

        // Return success to the lender, he will transfer get the funds back if allowance is set accordingly
        return keccak256('ERC3156FlashBorrower.onFlashLoan');
    }
}