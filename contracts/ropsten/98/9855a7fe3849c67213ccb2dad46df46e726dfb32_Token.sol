/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT

//Create a cryptocurrency
//store it in wallet 
// List it on a decentralized exchange 

pragma solidity ^0.8.6;

contract Token {
 
string public name; // the name of the cryptocurrency
string public symbol; // symbol of our cryptocurrency
uint256 public totalSupply ;
uint256 public decimals;

 mapping(address => uint) public  balanceOf;
 mapping(address => mapping (address => uint)) public allowence;
 
 event transfer(address indexed from , address indexed to ,  uint256 value);
 event approval(address indexed owner , address indexed spender ,uint256 value);


constructor(string memory _name , string memory _symbol , uint _totalSupply , uint _decimals){
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupply ;
    decimals = _decimals;
    balanceOf[msg.sender] = totalSupply;
    
    
}

function Transfer(address _to , uint _value) external returns(bool success){
    
    require(_to != address(0));
    internalTransfer(msg.sender , _to , _value);
    return true;
    
}

function internalTransfer(address _from , address _to , uint _value) internal {
    
    require(balanceOf[_from] >= _value);
    balanceOf[_from] = balanceOf[_from] - (_value);
    balanceOf[_to] = balanceOf[_to] + (_value);
    emit transfer(_from , _to , _value);
}


function approve(address _spender , uint256 _value) external returns (bool){
    require(_spender != address(0));
    allowence[msg.sender][_spender] = _value;
    emit approval(msg.sender , _spender , _value);
    return true;
}

function transferFrom(address _from , address _to , uint256 _value ) external returns(bool){
    require( _value <= balanceOf[_from]);
    require(_value <= allowence[_from][msg.sender]);
    
    allowence[_from][msg.sender] = allowence[_from][msg.sender] - (_value);
    internalTransfer(_from , _to , _value);
    return true;
    
    
}

        

}