/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract SampleToken {
  //set a state variable name
  string public name = "SampleToken";
  string public symbol = "SMLT";
  string public standard = "Sample Token v1.0";
  uint256 public decimals = 18;
  uint256 public totalSupply;

  //key is the address of the account that has the token balance
  //uint256 is the amount of tokens owned by the address
  mapping (address => uint256) public balanceOf;
  //this keeps track of an account owner to keep track of its approval
  //AccountA approving accountB with valueC
  mapping(address => mapping(address => uint256)) public allowance;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);


  constructor(uint256 _initialSupply) public {
    totalSupply = _initialSupply;

    //initialize the balance of the account that has the token balance
    balanceOf[msg.sender] = _initialSupply;
  }

  //function to transfer tokens to another account, by the owner of the account
  //Making the call by yourself
  function transfer(address _to, uint256 _value) public returns(bool success){
    require(balanceOf[msg.sender] >= _value);
    balanceOf[_to] += _value;
    balanceOf[msg.sender] -= _value;

    emit Transfer(msg.sender, _to, _value);

    return true;
  }

  //Delegated functions to transfer tokens to another account, by the owner of the account
  //function for exchange to transfer token to another account on your behalf
  //The transferFrom allow us to handle the delegated transfer
  //The transferFrom acts like transfer, but on behalf of the account that has the token balance/ on my behalf
  function transferFrom(address _from, address _to, uint256 _value) public returns(bool success){
    //require _from has enough tokens to transfer
    require(balanceOf[_from] >= _value);
    //require allowance is big enough to transfer, that is to check if the amount is allowed
    require(allowance[_from][msg.sender] >= _value);
    //move money arround by changing the balance
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    //update the allowance
    allowance[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    //emit event
    return true;
  }

  //The amount the spender is allowed to withdraw from the owner

  //function to approve exchange to transfer tokens to another account on your behalf
  //msg.sender is the owner of the token which is you
  //approve and store the amount approved in the allowance state variable
  function approve(address _spender, uint256 _value) public returns (bool success){
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

}