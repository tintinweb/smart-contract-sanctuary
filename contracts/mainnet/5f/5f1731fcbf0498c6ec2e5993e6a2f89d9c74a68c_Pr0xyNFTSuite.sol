// SPDX-License-Identifier: MIT

// Contract by pr0xy.io

pragma solidity ^0.8.7;

import "./AccessControl.sol";

contract Pr0xyNFTSuite is AccessControl {
  using Strings for uint256;

  address public vault = 0x5404980C4e40310073f4c959E91bA94c4C47Ca03;
  bool public active = false;
  uint256 public limit = 10;
  uint256 public price = 1 ether;
  uint256 public registrees = 0;

  mapping(uint256 => bool) private guilds;

  bytes32 public constant ADMIN = keccak256("ADMIN");

  constructor(address[] memory admins) {
    for(uint256 i; i < admins.length; i++){
       _setupRole(ADMIN, admins[i]);
    }
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function setActive(bool _active) public adminOnly {
    active = _active;
  }

  function setLimit(uint256 _limit) public adminOnly {
    limit = _limit;
  }

  function setPrice(uint256 _price) public adminOnly {
    price = _price;
  }

  function setVault(address _vault) public adminOnly {
    vault = _vault;
  }

  function addGuild(uint256 _guild) public adminOnly {
    guilds[_guild] = true;
    registrees++;
  }

  function removeGuild(uint256 _guild) public adminOnly {
    guilds[_guild] = false;
    registrees--;
  }

  function isGuildRegistered(uint256 _guild) public returns (bool)  {
    return guilds[_guild];
  }

  function register(uint256 _guild) public payable {
    require( active, 'Not Active');
    require( !guilds[_guild], 'Guild Registered');
    require( registrees + 1 <= limit, 'Supply Denied');
    require( msg.value >= price, 'Ether Amount Denied');

    guilds[_guild] = true;
    registrees++;
  }

  function withdraw() public payable adminOnly {
    uint256 _payout = address(this).balance;
    require(payable(vault).send(_payout));
  }

  modifier adminOnly() {
    require(hasRole(ADMIN, msg.sender), 'Admin Only');
    _;
  }
}