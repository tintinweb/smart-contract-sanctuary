/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

contract erc20 {


    /*
     * Global variables
     */

    mapping (address => uint256) _balance;
    mapping (address => mapping( address => uint256)) _allowed;
    

    string _name;
    string _symbol;
    uint256 _totalSupply;
    uint8 _decimals;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    

    constructor (string memory _tokenName, string memory _tokenSymbol, uint256 _tokenSupply, uint8 _tokenDecimals) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _totalSupply = _tokenSupply;
        _decimals = _tokenDecimals;

        _balance[msg.sender] = _totalSupply;
    }
    
    /*
     * Read functions
     */

    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public view returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balance[_owner];
    }


    /*
     * Write functions
     */


    function transfer (address _to, uint256 _value) public returns(bool success) {
        require (balanceOf(msg.sender) >= _value);

        _balance[msg.sender] = _balance[msg.sender] - _value;
        _balance[_to] = _balance[_to] + _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function approve (address _spender, uint256 _value) public returns(bool success) {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function transferFrom (address _from, address _to, uint256 _value) public returns(bool success) {
        require (balanceOf(_from) >= _value);
        require (_allowed[_from][msg.sender] >= _value);

        _balance[_from] = _balance[_from] - _value;
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender] - _value;
        _balance[_to] = _balance[_to] + _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }


}