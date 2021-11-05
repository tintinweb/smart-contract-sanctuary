/**
 *Submitted for verification at polygonscan.com on 2021-11-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Multisend {
    constructor() {
        //something here
    }
    function airdrop(IERC20 _token, uint256 _amount, address[] calldata _recipients) external {
        for(uint256 i = 0; i < _recipients.length; i++){
            _token.transferFrom(msg.sender,_recipients[i], _amount);
        }
    }
}