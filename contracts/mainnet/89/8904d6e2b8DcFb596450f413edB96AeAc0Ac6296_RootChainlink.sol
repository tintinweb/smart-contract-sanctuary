// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./BaseUpgradeabililtyProxy.sol";

contract RootChainlink is BaseUpgradeabililtyProxy {
  address private _admin;

  constructor (address admin) {
    _setAdmin(admin);
  }

  function implement(address implementation) external onlyAdmin {
    upgradeTo(implementation);
  }

  function setAdmin(address admin) external onlyAdmin {
    _setAdmin(admin);
  }

  function _setAdmin(address admin) internal {
    _admin = admin;
  }

  modifier onlyAdmin() {
    require(
      msg.sender == _admin,
      "RootChainlink: Not admin"
    );

    _;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
import {UpgradesAddress} from "./Address.sol";

contract BaseUpgradeabililtyProxy {
  // solhint-disable-next-line no-empty-blocks
  function initialize() public virtual {}

  bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  event Upgraded(address indexed implementation);
  event ValueReceived(address user, uint amount);

  function implementation() public view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      impl := sload(slot)
    }
  }

  function upgradeTo(address newImplementation) internal {
    setImplementation(newImplementation);

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory reason) = newImplementation.delegatecall(abi.encodeWithSignature("initialize()"));
    require(success, string(reason));

    emit Upgraded(newImplementation);
  }

  function setImplementation(address newImplementation) internal {
    require(UpgradesAddress.isContract(newImplementation),
      "Cannot set a proxy implementation to a non-contract address");
    bytes32 slot = IMPLEMENTATION_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newImplementation)
    }
  }

  receive() external payable {
    emit ValueReceived(msg.sender, msg.value);
  }

  // solhint-disable-next-line no-complex-fallback
  fallback () external payable {
    address _impl = implementation();
    require(_impl != address(0), "implementation not set");

    // solhint-disable-next-line no-inline-assembly
    assembly {
      calldatacopy(0, 0, calldatasize())

      let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

      returndatacopy(0, 0, returndatasize())

      switch result
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

library UpgradesAddress {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }
}