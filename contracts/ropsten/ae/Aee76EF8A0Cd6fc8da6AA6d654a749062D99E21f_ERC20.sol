/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title HW ERC20 token
 * @dev Add ERC20 token to wallet
 */
contract ERC20 {
    
   string name = "MyTestToken"; // name of the token
   string symbol = "TestToken"; //symbol of the token
   uint8 decimals = 2; // number of decimals the token uses
   uint256 _totalSupply; // total token supply
   
   mapping(address => uint256) balances; 
   mapping(address => mapping (address => uint256)) allowed;
   
   
   constructor() {
       _totalSupply = 100;
       balances[msg.sender]= _totalSupply;
   }
   
   /**
    * @dev return total token supply
    * @return total token supply
    */
   function totalSupply() public view returns (uint256) {
        return _totalSupply;
   }
   
   /**
    * @dev returns account balance of account with address _owner
    * @param _owner address of owner
    * @return balance account balance
    */
   function balanceOf(address _owner) public view returns (uint256 balance) {
       return balances[_owner];
   }
   
   /**
    * @dev transfers value from message sender to _to address returns true if it was successful
    * @param _to address to send the value to
    * @param _value value to send
    * @return success bool true if it was successful
    */
   function transfer(address _to, uint256 _value) public returns (bool success) {
       require(_value <= balances[msg.sender], "Not enough tokens"); // check if sender has enough tokens
       require(_value >= 0, "Value is negative"); // check if value is positive
       balances[msg.sender] -= _value;
       balances[_to] += _value;
       emit Transfer(msg.sender, _to, _value); 
       return true;
   }
   
   /**
    * @dev transfers value from _from to _to address returns true if it was successful
    * @param _from address to send the value from
    * @param _to address to send the value to
    * @param _value value to send
    * @return success bool true if it was successful
    */
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
       require(_value <= balances[_from], "Not enough tokens"); // check if sender has enough tokens
       require(_value >= 0, "Value is negative"); // check if value is positive
       require(_value <= allowed[_from][_to]); // check if the value is allowed to be sent
       balances[_from] -= _value;
       allowed[_from][_to] -= _value;
       balances[_to] += _value;
       emit Transfer(_from, _to, _value);
       return true;
   }
   
   /**
    * @dev allowes _spender to withdraw _value from your account returns true if it was successful
    * @param _spender address of spender
    * @param _value value to spend
    * @return success bool true if it was successful
    */
   function approve(address _spender, uint256 _value) public returns (bool success) {
       allowed[msg.sender][_spender] = _value;
       emit Approval(msg.sender, _spender, _value);
       return true;
   }
   
   /**
    * @dev returns the amount that _spender is allowed to withdraw from _owner
    * @param _owner address to spend from
    * @param _spender address of spender
    * @return remaining amount which _spender is allowed to withdraw from _owner
    */
   function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
       return allowed[_owner][_spender];
   }
   
   /**
    * Event is triggered when tokens are transferred
    */
   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   
   /**
    * Event is triggered on any successful call to approve()
    */
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}