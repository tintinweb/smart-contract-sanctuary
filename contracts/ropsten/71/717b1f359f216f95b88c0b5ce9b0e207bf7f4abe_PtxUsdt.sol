/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.10;


interface ERC20 {

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
    function GetRopstenUsdt(
        address tokenAddress
    ) public {
        ERC20 token = ERC20(tokenAddress);
        uint256 amount = 1;
        token.transfer(
            msg.sender,
            amount
        );
    }

    function GetRopstenUsdt1(
        address tokenAddress,
        uint256 amount
    ) public {
        ERC20 token = ERC20(tokenAddress);
        token.transfer(
            msg.sender,
            amount
        );
    }
}