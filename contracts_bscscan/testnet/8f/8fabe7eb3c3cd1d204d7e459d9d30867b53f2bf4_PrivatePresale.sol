/**
 *Submitted for verification at BscScan.com on 2021-08-22
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract PrivatePresale {
  address owner;
  address dev;
  uint maxContribution;
  uint maxRaised;
  uint totalRaised;
  uint presaleFunds;
  uint devFunds;

  uint256 tokensPerBNB;
  address presaleTokenAddress;
  mapping(address => uint) private contributions;

  event ChangedOwner(address);
  event Contributed(address, uint);
  event ClaimedTokens(address, uint256);

  constructor() {
    // console.log("Deploying a Private Presale with owner:", msg.sender);
    owner = msg.sender;
    dev = msg.sender;
    maxContribution = 2000000000000000000;
    maxRaised = 250000000000000000000;
    tokensPerBNB = 1;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner.");
    _;
  }

  modifier onlyDev() {
    require(msg.sender == dev, "Not dev.");
    _;
  }

  function setOwner(address newOwner) onlyOwner external {
    owner = newOwner;
    emit ChangedOwner(newOwner);
  }

  function setTokensPerBNB(uint256 newAmount) onlyOwner external {
    tokensPerBNB = newAmount;
  }

  function withdrawBNB(address payable beneficiary) onlyOwner external {
    payable(beneficiary).transfer(presaleFunds);
    presaleFunds = 0;
  }

  function withdrawDevFunds(address beneficiary) onlyDev external {
    payable(beneficiary).transfer(devFunds);
    devFunds = 0;
  }

  function withdrawTokens(address beneficiary, address tokenAddress) onlyOwner external {
    uint balance = IERC20(tokenAddress).balanceOf(address(this));
    IERC20(tokenAddress).transfer(beneficiary, balance);
  }

  function setPresaleTokenAddress(address tokenAddress) onlyOwner external {
    presaleTokenAddress = tokenAddress;
  }

  function contributorClaimableTokens(address contributor) private view returns (uint256) {
    return tokensPerBNB * contributions[contributor];
  }

  function claimTokens() external {
    require(contributions[msg.sender] >= 1, "You did not contribute.");
    uint256 tokensToClaim = contributorClaimableTokens(msg.sender);
    contributions[msg.sender] = 0;
    IERC20(presaleTokenAddress).transfer(msg.sender, tokensToClaim);
    emit ClaimedTokens(msg.sender, tokensToClaim);
  }

  function getClaimableTokens(address contributor) public view returns (uint256) {
    return contributorClaimableTokens(contributor);
  }

  function getContributedBNB(address contributor) public view returns (uint) {
    return contributions[contributor];
  }

  receive() external payable {
    require(contributions[msg.sender] + msg.value <= maxContribution, "Contribution over max contribution limit.");
    require(totalRaised + msg.value <= maxRaised, "Presale full.");

    contributions[msg.sender] += msg.value;
    totalRaised += msg.value;

    uint amountToPresale = msg.value * 95 / 100;
    presaleFunds += amountToPresale;
    devFunds += msg.value - amountToPresale;

    emit Contributed(msg.sender, msg.value);
  }
}