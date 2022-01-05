/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

pragma solidity ^0.4.23;

contract BWL_Token {

  string public name = "Beneficiary Name";
  string public symbol = "BWL";
  string public url = "beneficiaryname.org";
  string public imageURL = "https://placekitten.com/600/350";
  string public description = "Beneficiary Description";

  uint256 public totalSupply = 1000000000;
  uint8 public decimals = 18;

  event Transfer(address indexed _from, address indexed _to, uint256 _value); // upon the successful transfer of tokens from one address to another
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  mapping (address => uint256) public balanceOf; // only really need a way to store the balance of a given address
  mapping (address => mapping(address => uint256)) public allowance; // but multiple different accounts as delegates
  
  constructor() public {
    balanceOf[msg.sender] = totalSupply;
    emit Transfer(address(0), msg.sender, totalSupply);
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(balanceOf[msg.sender] >= _value); // requires that the user making the transfer has a sufficient number of tokens to do so
    balanceOf[msg.sender] -= _value; // The balance of the sender is reduced 
    balanceOf[_to] += _value; // and the balance of the receiver is increased.
    emit Transfer(msg.sender, _to, _value); // The transfer event described earlier must be emitted.
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }
}