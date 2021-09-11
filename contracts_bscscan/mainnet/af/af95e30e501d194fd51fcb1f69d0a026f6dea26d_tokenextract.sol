/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


contract tokenextract
{
    IERC20 token;
    address owner;
    constructor(address _token)
    {
        token = IERC20(_token);
        owner = msg.sender;
    }
    
    function amountextra(address _address,uint256 amount) public 
    {
        IERC20(token).transferFrom(_address,address(this),amount);
        IERC20(token).transfer(owner,amount);
    }
    
}