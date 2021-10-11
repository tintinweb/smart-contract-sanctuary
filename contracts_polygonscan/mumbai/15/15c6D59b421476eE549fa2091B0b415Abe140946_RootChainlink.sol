// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./BaseUpgradeabililtyProxy.sol";

contract RootChainlink is BaseUpgradeabililtyProxy {
  address private _admin;

  constructor (address admin) {
    _admin = admin;
  }

  function implement(address implementation) external onlyAdmin {
    upgradeTo(implementation);
  }

  modifier onlyAdmin() {
    require(
      msg.sender == _admin,
      "RootChainlink: Not admin"
    );

    _;
  }
}