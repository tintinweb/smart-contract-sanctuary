/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
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


contract Battle{
    
    address ttAddress;
    
    
    constructor(address add) public {
        ttAddress = add;
    }
    
    
    function fight() external returns(bool){
        IERC20 tt = IERC20(ttAddress);
        tt.transfer(msg.sender,1);
        return true;
    }
    
}