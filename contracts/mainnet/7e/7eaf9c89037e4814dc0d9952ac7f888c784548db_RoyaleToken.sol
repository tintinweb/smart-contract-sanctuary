// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './SafeMath.sol';

contract RoyaleToken{

    using SafeMath for uint256;
    
    string public name = "Royale";
    string public symbol = "ROYA";
    uint8  public decimals=18;
    uint256 public totalSupply=72000000 * (uint256(10) ** decimals);
    mapping(address => uint256)  balances;
    mapping (address => mapping (address => uint256)) allowances;
    
    event Transfer(
      address indexed _from,
      address indexed _to,
      uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    
    
     constructor () public {
            balances[msg.sender] = totalSupply;
           
    }
    
    
   
    function balanceOf(address _address) public view returns (uint256){
            return balances[_address];
    }

   
     function transfer(address _to, uint256 _amount) public  returns (bool success) {
            require(_amount>0 , "amount can not be zero ");
            require(balances[msg.sender]>=_amount  , "Insufficient balance ");
            balances[msg.sender] = balances[msg.sender].sub(_amount);     
            balances[_to] =balances[_to].add(_amount);
            emit Transfer(msg.sender, _to, _amount);
            return true;
    }
    
   
    function approve(address _spender, uint256 _amount) public returns (bool success) {
            allowances[msg.sender][_spender]=allowances[msg.sender][_spender].add(_amount);                                
            emit Approval(msg.sender,_spender, _amount);
            return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) public  returns (bool success) {
         require(_amount>0 , "amount can not be zero ");
         require(_amount <= allowances[_from][msg.sender] , "Transfer amount exceeds allowance");  //checking that whether sender is approved or not...
         balances[_from]= balances[_from].sub(_amount);
         balances[_to] = balances[_to].add(_amount);
         allowances[_from][msg.sender]=allowances[_from][msg.sender].sub(_amount);
          emit Transfer(_from, _to, _amount);
         return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
      return allowances[_owner][_spender];
    }
    
}


