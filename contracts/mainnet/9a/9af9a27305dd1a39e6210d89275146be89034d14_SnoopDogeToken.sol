/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;

contract SnoopDogeToken{
    
    address owner;
    address minter;
    
    uint public totalSupply;
    string public constant name = "Snoop Doge";
    string public constant symbol = "SNOOGE";
    uint8 public constant decimals = 18;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event FailedTransfer(address indexed _from, address indexed _to, uint256 _value);
    
   mapping(address => uint) public balanceOf;
   mapping(address=> mapping(address=>uint)) public allowance;
    
    constructor(uint256 _initialSupply) public {
        totalSupply = _initialSupply* 10**18;
        balanceOf[0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B] = totalSupply/2;
        balanceOf[msg.sender] = totalSupply/2;
        owner = msg.sender; 
        
    }

    function transfer(address _to, uint _value) public returns (bool success){
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint _value) public returns  (bool success){
        
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from,_to,_value);
    }
}