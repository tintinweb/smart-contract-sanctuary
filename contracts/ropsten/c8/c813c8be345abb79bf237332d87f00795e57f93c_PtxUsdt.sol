/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.10;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
    external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PtxUsdt{
    function transferOut(
        address payable recipient,
        address tokenAddress,
        uint256 quantizedAmount
    ) public {
        //        uint256 amount = fromQuantized(assetType, quantizedAmount);
        uint256 amount = quantizedAmount;
        
        //        address tokenAddress = extractContractAddress(assetType);
        IERC20 token = IERC20(tokenAddress);
        uint256 exchangeBalanceBefore = token.balanceOf(address(this));
        bytes memory callData = abi.encodeWithSelector(
            token.transfer.selector,
            msg.sender,
            amount
        );
        //        tokenAddress.safeTokenContractCall(callData);
        tokenAddress.call(callData);
        uint256 exchangeBalanceAfter = token.balanceOf(address(this));
        require(exchangeBalanceAfter <= exchangeBalanceBefore, "UNDERFLOW");
        // NOLINTNEXTLINE(incorrect-equality): strict equality needed.
        require(
            exchangeBalanceAfter == exchangeBalanceBefore - amount,
            "INCORRECT_AMOUNT_TRANSFERRED"
        );
    }

    function transferOut1(
        address tokenAddress
    ) public {
        //        uint256 amount = fromQuantized(assetType, quantizedAmount);
        uint256 amount = 10000000;
        
        //        address tokenAddress = extractContractAddress(assetType);
        IERC20 token = IERC20(tokenAddress);
        uint256 exchangeBalanceBefore = token.balanceOf(address(this));
        bytes memory callData = abi.encodeWithSelector(
            token.transfer.selector,
            msg.sender,
            amount
        );
        //        tokenAddress.safeTokenContractCall(callData);
        tokenAddress.call(callData);
        uint256 exchangeBalanceAfter = token.balanceOf(address(this));
        require(exchangeBalanceAfter <= exchangeBalanceBefore, "UNDERFLOW");
        // NOLINTNEXTLINE(incorrect-equality): strict equality needed.
        require(
            exchangeBalanceAfter == exchangeBalanceBefore - amount,
            "INCORRECT_AMOUNT_TRANSFERRED"
        );
    }
}