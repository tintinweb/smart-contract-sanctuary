/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

pragma solidity ^0.8.3;
// SPDX-License-Identifier: GPL-3.0

contract Axpp {

    string internal _symbol;
    string internal _name;

    uint8 internal _decimals;
    uint internal _totalSupply;

    mapping (address => uint) internal _balanceOf;
    mapping (address => mapping (address => uint)) internal _allowances;

    constructor( string memory __symbol,  string memory __name, uint8 __decimals, uint __totalSupply) {
        _symbol = __symbol;
        _name = __name;
        _decimals = __decimals;
        _totalSupply = __totalSupply;
    }

    function name()
        public
        view
        returns (string memory) {
        return _name;
    }

    function symbol()
        public
        view
        returns (string memory) {
        return _symbol;
    }

    function decimals()
        public
        view
        returns (uint8) {
        return _decimals;
    }

    function totalSupply()
        public
        view
        returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _addr) public view returns (uint){
        return _balanceOf[_addr];
    }
    function transfer(address _to, uint _value) public returns (bool)
    {

    }
    event Transfer(address indexed _from, address indexed _to, uint _value);
}