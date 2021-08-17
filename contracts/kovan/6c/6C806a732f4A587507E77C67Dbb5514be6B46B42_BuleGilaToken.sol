/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


//   ____        _         _____ _ _         _______    _              
//  |  _ \      | |       / ____ ( ) |       |__   __|  | |             
//  | |_) |_   _| | ___  | |  __ _| | __ _     | | ___ | | _____ _ __  
//  |  _ <| | | | |/ _ \ | | |_ | | |/ _` |    | |/ _ \| |/ / _ \ '_ \ 
//  | |_) | |_| | |  __/ | |__| | | | (_| |    | | (_) |   <  __/ | | |
//  |____/ \__,_|_|\___|  \_____|_|_|\__,_|    |_|\___/|_|\_\___|_| |_|                                                                  

contract BuleGilaToken {
// ----------------------------------------------------------------------------
// Sample token contract
//
// Symbol        : 
// Name          : Gule Gila Token
// Total supply  : 275,000,000 (275 Millones)
// Decimals      : 18
// Owner Account : 0x6009f738dcF7194EfddDfc3B13Ce325e21A05175
//
// Enjoy.
//
// (c) by Wayan Sukarno 2020. MIT Licence.
// ----------------------------------------------------------------------------

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "Bule Gila Token";
        symbol = "Bugil";
        decimals = 18;
        totalSupply = 275000000000000000000000000; 
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }

}