// contracts/utilities/TreasuryDAO.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreasuryDAO {
  string public name;

  address public owner;
  uint256 public totalShares;

  address public changeDAO;
  address public community;

  address[] public tokens;
  uint256 public totalFunds;

  mapping(address => uint256) public shares;
  uint256 public shareUnit;
  uint256 public thumbs;
  mapping(address => uint256) public lastShares;

  constructor(string memory name_) {
    name = name_;
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Permission denied");
    _;
  }

  function addShare(address account, uint256 share) internal {
    require(account != address(0), "Invalid account");
    require(shares[account] == 0, "Share exists");
    totalShares += share;
    shares[account] = share;
    lastShares[account] = shareUnit;
  }

  function addShares(address[] memory accounts, uint256[] memory sharings) external onlyOwner {
    require(accounts.length == sharings.length, "Invalid counts");
    require(accounts.length < 256, "Invalid length");
    for (uint8 i = 0; i < accounts.length; i++) {
      addShare(accounts[i], sharings[i]);
    }
  }

  function removeShare(address account) internal {
    require(shares[account] > 0, "Invalid share");
    uint256 share = shares[account];
    delete shares[account];
    totalShares -= share;
    if (shareUnit > lastShares[account]) {
      uint256 refund = (shareUnit - lastShares[account]) * share;
      lastShares[account] = shareUnit;
      addFund(refund);
    }
  }

  function removeShares(address[] memory accounts) external onlyOwner {
    require(accounts.length < 256, "Invalid length");
    for (uint8 i = 0; i < accounts.length; i++) {
      removeShare(accounts[i]);
    }
  }

  function addFund(uint256 amount) internal {
    require(totalShares > 0, "No shares");
    totalFunds += amount;
    uint256 newAmount = amount + thumbs;
    uint256 newUnit = newAmount / totalShares;
    shareUnit += newUnit;
    thumbs = newAmount - (newUnit * totalShares);
  }

  function getAllocation(address account) public view returns (uint256 allocation) {
    allocation = (shareUnit - lastShares[account]) * shares[account];
  }

  function withdraw() external {
    uint256 allocation = getAllocation(msg.sender);
    require(allocation > 0, "Funds empty");
    lastShares[msg.sender] = shareUnit;
    payable(msg.sender).transfer(allocation);
  }

  function raise() external payable {
    addFund(msg.value);
  }
}