/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    string public name="My Great Tokenx";
    string public symbol="MGTx";
    uint256 public decimals=18;
    uint256 public totalSupply=10000000000000000000000;

    mapping(address=>uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
 
    
    constructor() {
        balanceOf[msg.sender]=totalSupply;
    }
    
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Ensure sending is to valid address! 0x0 address cane be used to burn() 
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }
    
    function transfer(address _to,  uint _value) external returns (bool){
        require(balanceOf[msg.sender]>=_value , "Low balance");
        _transfer(msg.sender, _to,_value);
        
        //balanceOf[msg.sender] =balanceOf[msg.sender]-_value;
        //balanceOf[_to] =balanceOf[_to]+_value;
        //emit Transfer(msg.sender, _to,_value);
        return true;
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