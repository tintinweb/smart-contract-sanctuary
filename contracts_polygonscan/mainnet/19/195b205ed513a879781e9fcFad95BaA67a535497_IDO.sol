/**
 *Submitted for verification at polygonscan.com on 2021-08-09
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

  mapping(address => uint256) public boughts;

  function buyToken() public payable {
    uint256 min = 1 ether;
    uint256 max = 235 ether;
    uint256 amount = msg.value;
    address sender = msg.sender;
    require(amount >= min, "TOO_SMALL");
    require(amount + boughts[sender] <= max, "TOO_BIG");
    
    sim.transfer(sender, amount * 100);
    boughts[sender] += amount;
  }

  function withdrawMatic() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawToken(uint256 amount, IERC20 erc20) public onlyOwner {
    erc20.transfer(owner, amount);
  }
}