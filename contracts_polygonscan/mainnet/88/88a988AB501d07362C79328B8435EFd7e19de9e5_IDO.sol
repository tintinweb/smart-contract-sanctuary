/**
 *Submitted for verification at polygonscan.com on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external;
}

contract IDO {
  IERC20 public sim;
  address public owner;
  address public admin;

  constructor(IERC20 _sim) {
    sim = _sim;
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  mapping(address => bool) public whiteList;

  function addWhiteList(address[] memory accounts) public onlyOwner {
    uint256 length = accounts.length;
    for (uint256 index = 0; index < length; index++) {
      whiteList[accounts[index]] = true;
    }
  }

  function removeWhiteList(address[] memory accounts) public onlyOwner {
    uint256 length = accounts.length;
    for (uint256 index = 0; index < length; index++) {
      whiteList[accounts[index]] = false;
    }
  }

  uint256 public ONE_MATIC_TO_TOKEN = 11 ether;
  
  function setPrice(uint256 newPrice) public onlyOwner {
    ONE_MATIC_TO_TOKEN = newPrice;
  }

  mapping(address => uint256) public boughts;
  mapping(address => uint256) public tokenBalances;

  function buyToken() public payable {
    uint256 min = 1 ether;
    uint256 max = 235 ether;
    uint256 amount = msg.value;
    address sender = msg.sender;
    require(amount >= min, "TOO_SMALL");
    require(amount + boughts[sender] <= max, "TOO_BIG");
    
    tokenBalances[sender] += amount * ONE_MATIC_TO_TOKEN / 1e18;
    boughts[sender] += amount;
  }

  function withdrawMatic() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawToken(uint256 amount, IERC20 erc20) public onlyOwner {
    erc20.transfer(owner, amount);
  }

  function setSim(IERC20 _sim) public onlyOwner {
    sim = _sim;
  }

  function payout(address[] memory accounts) public onlyOwner {
    for (uint256 index = 0; index < accounts.length; index++) {
      address account = accounts[index];
      uint256 balance = tokenBalances[account];
      sim.transfer(account, balance);
      tokenBalances[account] = 0;
    }
  }
}