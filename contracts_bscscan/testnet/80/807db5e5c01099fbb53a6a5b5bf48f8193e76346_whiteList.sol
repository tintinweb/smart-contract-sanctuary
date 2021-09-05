/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

pragma solidity ^0.4.19;

/**
 * @title BitGuildWhitelist
 * A small smart contract to provide whitelist functionality and storage
 */
contract whiteList {

  address admin;

  mapping (address => bool) public whitelist;
  uint256 public totalWhitelisted = 0;

  event AddressWhitelisted(address indexed user, bool whitelisted);

  function BitGuildWhitelist() public {
    admin = msg.sender;
  }

  // Doesn't accept eth
  function () external payable {
    revert();
  }

  // Allows an admin to update whitelist
  function whitelistAddress(address[] _users, bool _whitelisted) public {
    require(msg.sender == admin);
    for (uint i = 0; i < _users.length; i++) {
      if (whitelist[_users[i]] == _whitelisted) continue;
      if (_whitelisted) {
        totalWhitelisted++;
      } else {
        if (totalWhitelisted > 0) {
          totalWhitelisted--;
        }
      }
      AddressWhitelisted(_users[i], _whitelisted);
      whitelist[_users[i]] = _whitelisted;
    }
  }
}