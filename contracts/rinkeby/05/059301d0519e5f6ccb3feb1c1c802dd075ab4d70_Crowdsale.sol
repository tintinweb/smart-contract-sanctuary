/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

pragma solidity 0.4.24;

contract Crowdsale {
   bool public icoCompleted;
   uint256 public icoStartTime;
   uint256 public icoEndTime;
   uint256 public tokenRate;
   address public tokenAddress;
   uint256 public fundingGoal;
   address public owner;
   modifier whenIcoCompleted {
      require(icoCompleted);
      _;
   }
   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }
   function () public payable {
      buy();
   }
   constructor(uint256 _icoStart, uint256 _icoEnd, uint256 _tokenRate, address _tokenAddress, uint256 _fundingGoal) public {
      require(_icoStart != 0 &&
      _icoEnd != 0 &&
      _icoStart < _icoEnd &&
      _tokenRate != 0 &&
      _tokenAddress != address(0) &&
      _fundingGoal != 0);
      icoStartTime = _icoStart;
      icoEndTime = _icoEnd;
      tokenRate = _tokenRate;
      tokenAddress = _tokenAddress;
      fundingGoal = _fundingGoal;
      owner = msg.sender;
   }
   function buy() public payable {
      uint256 tokensToBuy;
      tokensToBuy = msg.value * 1e5 / 1 ether * tokenRate;
   }
   function extractEther() public whenIcoCompleted onlyOwner {
      owner.transfer(address(this).balance);
   }
}