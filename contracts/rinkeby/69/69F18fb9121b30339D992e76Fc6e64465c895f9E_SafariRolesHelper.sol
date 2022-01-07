// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

contract SafariRolesHelper {
  address internal whitelist;

  constructor(address _whitelist) {
    whitelist = _whitelist;
  }

  function supportsInterface(bytes4 id) external pure returns(bool) {
    return (id == 0x80ac58cd);
  }

  function balanceOf(address holder) external view returns(uint256) {
    ISafariOGWhitelist whitelist = ISafariOGWhitelist(whitelist);
    return whitelist.balanceOf(holder);
  }

}

contract ISafariOGWhitelist {
  function balanceOf(address holder) external view returns(uint256) {}
}