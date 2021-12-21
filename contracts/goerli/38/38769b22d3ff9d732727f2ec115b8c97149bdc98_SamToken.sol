/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract SamToken{

    constructor() {
        myName = "Sam_Token";
        mySymbol = "STX";
        myDecimals = 0;
        myTotalSupply = 1000;
        balances[msg.sender] = myTotalSupply;   // deployer
        
    }

    string myName;
    function name() public view returns (string memory){
        return myName;
    }
    string mySymbol;
    function symbol() public view returns (string memory) {
        return mySymbol;
    }
    uint8 myDecimals;
    function decimals() public view returns (uint8) {
        return myDecimals;
    }
    uint256 myTotalSupply;
    function totalSupply() public view returns (uint256) {
        return myTotalSupply;
    }
    mapping(address => uint256) balances;
    function balanceOf(address _user) public view returns (uint256 balance){
        return balances[_user];
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf(msg.sender) >= _value, "Insufficient balance");
   //  require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;

    }
}