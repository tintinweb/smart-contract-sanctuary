/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract SwapErc20 {
    
    mapping(address => uint256) private _sellers;
    
    constructor() {
    
    }
    
    function swap(IERC20 amsErc, address seller, address recipient, uint256 amount) external returns (bool) {
        amsErc.transferFrom(seller, recipient, amount);
        return true;
    }
    
}