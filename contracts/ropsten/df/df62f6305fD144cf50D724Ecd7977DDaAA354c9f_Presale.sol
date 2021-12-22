//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
//import "hardhat/console.sol";

interface IToken {
  function transfer(
                    address receiver,
                    uint256 numTokens
                    ) external payable returns (bool);
}

contract Presale {
  //uint256 can over/underflow, so SafeMath prevents fuckups
  //Usings at top
  using SafeMath for uint256;

  //Public can be access from outside the contract
  //View is constant
  //Events can trigger external applications
  address public tokenAddress;
  address public routerAddress;
  uint256 public constant MAXSALE = 9999999 ether;
  uint256 public constant MAXALLOCATION = 9999999 ether;
  uint256 public currentSale = 0 ether;
  uint256 public presaleStartTime;
  uint256 public presaleStartTime2;
  address payable public deployerAddress;
  bool public open = false;

  mapping(address => uint256) originalTokenBalances;
  mapping(address => uint256) tokenBalances;
  mapping(address => uint256) tokenBalances2;

  constructor(address tokenAddress_, uint256 timestamp, uint256 timestamp2){
    deployerAddress = payable(msg.sender);
    tokenAddress = tokenAddress_;
    presaleStartTime = timestamp;
    presaleStartTime2 = timestamp2;
  }

  function maxSale() public pure returns (uint256) {
    return MAXSALE;
  }

  function maxAllocation() public pure returns (uint256) {
    return MAXALLOCATION;
  }

  function getCurrentSale() public view returns (uint256) {
    return currentSale;
  }

  function getOpen() public view returns (bool) {
    return open;
  }

  function setOpen(bool newValue) public returns (bool) {
    require(msg.sender == deployerAddress, "Bad address");
    open = newValue;
    return true;
  }

  function setCurrentSale(uint256 amount) public returns (uint256) {
    //Used to close the sale
    require(msg.sender == deployerAddress, "Only deployer can use this function");
    currentSale = amount;
    return currentSale;
  }

  function viewOriginalAllocation(address userAddress) public view returns (uint256) {
    return originalTokenBalances[userAddress];
  }

  function viewAllocation(address userAddress) public view returns (uint256) {
    return tokenBalances[userAddress];
  }

  function viewAllocation2(address userAddress) public view returns (uint256) {
    return tokenBalances2[userAddress];
  }

  function claimTokens() public returns (bool) {
    require(block.timestamp >= presaleStartTime, "Bad block timestamp");
    require(tokenBalances[msg.sender] > 0, "No tokens to claim");
    IToken(tokenAddress).transfer(msg.sender, tokenBalances[msg.sender]);
    tokenBalances[msg.sender] = 0;
    return true;
  }

  function claimTokens2() public returns (bool) {
    require(block.timestamp >= presaleStartTime2, "Bad block timestamp");
    require(tokenBalances2[msg.sender] > 0, "No tokens to claim");
    IToken(tokenAddress).transfer(msg.sender, tokenBalances[msg.sender] + tokenBalances2[msg.sender]);
    tokenBalances2[msg.sender] = 0;
    tokenBalances[msg.sender] = 0;
    return true;
  }

  function releaseEther(uint256 amount) public returns (bool) {
    require(msg.sender == deployerAddress, "Address does not match deployer address");
    deployerAddress.transfer(amount);
    return true;
  }

  receive() external payable {
    // On receive ether
    require(msg.value >= 0.001 ether, "Must send more than minimum allocation");
    require(originalTokenBalances[msg.sender] == 0, "Already participated in presale");
    require(currentSale + msg.value < MAXSALE, "Sale cannot exceed capacity");
    require(open == true || deployerAddress == msg.sender);

    tokenBalances[msg.sender] = msg.value * 50;
    tokenBalances2[msg.sender] = msg.value * 50;
    originalTokenBalances[msg.sender] = msg.value * 100;
    currentSale = currentSale + (msg.value * 100);
  }
}

library SafeMath {
  //SafeMath library to prevent math fuckups
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}