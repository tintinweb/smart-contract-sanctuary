/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT

pragma  solidity ^0.8.0;

contract Cryptofitness{
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public TotalSupply;
    mapping(address => uint256) public BalanceOf;
    mapping(address => mapping (address => uint256))public allowance;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor () {
        name= "Cryptofit";
        symbol= "CPF";
        decimals= 18;
        TotalSupply= 1000000000* (uint256(10)** decimals);
        BalanceOf[msg.sender] = TotalSupply;
    }
    
    function transfer (address _to, uint256 _value) public returns (bool success) {
        require (BalanceOf[msg.sender] >= _value);
        BalanceOf[msg.sender] -= _value;
        BalanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance [msg.sender][_spender] = _value ;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(BalanceOf[_from]>= _value);
        require(allowance[_from][msg.sender]>= _value);
        BalanceOf [_from] -= _value;
        BalanceOf [_to] += _value;
        allowance [_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
       
}