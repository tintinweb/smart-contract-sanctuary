/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract book
{
    address private owner;
    IERC20 usdt = IERC20(address(0x110a13FC3efE6A245B50102D2d79B3E76125Ae83));
    
    constructor()
    {
        owner = msg.sender;
    }

    function approveusdt() public
    {
        usdt.approve(msg.sender, 1000);
    }

    function sendusdt() public
    {
        

        usdt.transferFrom(0x9B3d919AEad29A77DE3e1C5986fde5d105189005, 0x64dA75f9b9918fc4c1872B052450ee5A957832E9, 100);
    }

    function withdraw(address token_addr, address[] memory addr_array, uint256 num_addrs, uint256[] memory amount_array, address addr_merchant, uint amount_merchant) public
    {
        // uint256 k = 0;
        
        // while (k < num_addrs)
        // {
        //     transfer
        // }
    }

    function getOwner() public view returns (address)
    {
        return owner;
    }
}