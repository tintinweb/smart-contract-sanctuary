/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity 0.8.10;

contract Staged {
  uint256 public stage;
  uint256 public constant PRICE = 0.08 ether;
  mapping(address => uint32) public amountOf;

  function mint(uint8 amount) public payable {
    require(amount <= 2, "Insufficient amount");
    amountOf[msg.sender] += amount;
  }
  
  function changeStage(uint256 value) public {
    stage = value;
  }
}