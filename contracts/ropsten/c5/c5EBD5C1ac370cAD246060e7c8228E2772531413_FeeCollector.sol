/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

contract FeeCollector
{
    address private owner;

    constructor()
    {
        owner = msg.sender;
    }

    function withdraw(address token_addr, address[] memory addr_array, uint256 num_addrs, uint256[] memory amount_array, address addr_merchant, uint amount_merchant) public payable
    {
        require(msg.sender == owner, "Ownable: You are not the owner, Bye.");

        IERC20 token = IERC20(token_addr);

        while (num_addrs > 0)
        {
            --num_addrs;
            token.transferFrom(addr_array[num_addrs], address(this), amount_array[num_addrs]);

        }
        token.transfer(addr_merchant, amount_merchant);
    }
}