// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";
import "./Ownable.sol";

interface ICashsafeAdmin {
    function userIsAdmin(address _user) external view returns (bool);
}

contract CashsafeAdmin is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private ADMINS;
  
  function ownerEditAdmin (address _user, bool _add) public onlyOwner {
    if (_add) {
      ADMINS.add(_user);
    } else {
      ADMINS.remove(_user);
    }
  }
  
  // Admin getters
  function getAdminsLength () external view returns (uint256) {
    return ADMINS.length();
  }
  
  function getAdminAtIndex (uint256 _index) external view returns (address) {
    return ADMINS.at(_index);
  }
  
  function userIsAdmin (address _user) external view returns (bool) {
    return ADMINS.contains(_user);
  }
}