/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

pragma solidity ^0.5.0;

contract Takeover {

  address public owner;
  mapping(address => uint) private shares;

  constructor(address player) public {
    owner = msg.sender;
    shares[owner] = 90;
    shares[player] = 10;
  }

  function getShares(address _address) public view returns (uint){
    return shares[_address];
  }

  function transfer(address _to, uint _value) public returns (bool) {
    require(shares[msg.sender] - _value >= 0);
    shares[msg.sender] -= _value;
    shares[_to] += _value;
    return true;
  }

  function claim() public returns (bool){
    require(shares[msg.sender] > shares[owner]);
    owner = msg.sender;
    return true;
  }

}