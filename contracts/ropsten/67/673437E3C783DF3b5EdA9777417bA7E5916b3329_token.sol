/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract token{

    string constant public name = "Peter";
    string constant public symbol = "*";
    uint8 constant public decimals = 7;
    uint totalSupply = 0;
    mapping(address => uint8) balances;

    function mint(address owner, uint8 value)public{
        totalSupply += value;
        balances[owner] += value;
    }

    function balanceOf(address owner)public view returns(uint){
        return(balances[owner]);
    }
    function balanceOf() public view returns(uint){
        return balances[msg.sender];
    }
}