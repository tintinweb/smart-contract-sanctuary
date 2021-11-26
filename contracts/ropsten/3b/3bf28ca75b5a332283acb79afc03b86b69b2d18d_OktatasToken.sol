/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract OktatasToken {

    // propertik
    string _name;
    string _symbol;
    uint8 _decimals; 
    uint256 _supply;
    mapping(address => uint256) _balances;
    uint256 testInt;
    address testAddress;

    // Creator: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // Alice: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // Bob: 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db

    // constructor
    constructor(string memory __name, string memory __symbol, uint8 __decimals, uint256 __supply){
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
        mint(msg.sender, __supply);
    }

    // esemenyek
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    // a token neve
    function name() public view returns (string memory) {
        return _name;
    }

    // szimbolum
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // helyiertekek szama
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // visszadja az aktualis tokenek szamat
    function totalSupply() public view returns (uint256) {
        return _supply;
    }

    // valakinek hany darab tokenje van
    function balanceOf(address _owner) public view returns (uint256 balance)
    {
        return _balances[_owner];
    }

    // transferaljunk valakitol valakinek tokent
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require (_balances[msg.sender] >= _value, "nincs eleg balance");

        _balances[msg.sender] = _balances[msg.sender] - _value;   
        _balances[_to] = _balances[_to] + _value;   

        emit Transfer(msg.sender,_to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        address xx = _from;
        xx = _to;
        uint256 zz = _value;
        zz += 1;
        testInt = zz;
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        address xx = _spender;
        xx = _spender;
        uint256 zz = _value;
        zz += 1;
        testInt = zz;
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        address xx = _owner;
        xx = testAddress;
        xx = _spender;
        return 0;
    }

    // uj token eloallitas
    function mint(address _to, uint256 _amount) public {
        _balances[_to] += _amount;
        _supply += _amount;
    }

}