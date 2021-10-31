/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

/*

    ████████████████████████████████████████
    ███████▓█████▓▓╬╬╬╬╬╬╬╬▓███▓╬╬╬╬╬╬╬▓╬╬▓█
    ████▓▓▓▓╬╬▓█████╬╬╬╬╬╬███▓╬╬╬╬╬╬╬╬╬╬╬╬╬█
    ███▓▓▓▓╬╬╬╬╬╬▓██╬╬╬╬╬╬▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓█
    ████▓▓▓╬╬╬╬╬╬╬▓█▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓█
    ███▓█▓███████▓▓███▓╬╬╬╬╬╬▓███████▓╬╬╬╬▓█
    ████████████████▓█▓╬╬╬╬╬▓▓▓▓▓▓▓▓╬╬╬╬╬╬╬█
    ███▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓█
    ████▓▓▓▓▓▓▓▓▓▓▓▓▓█▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓█
    ███▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓█
    █████▓▓▓▓▓▓▓▓█▓▓▓█▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓█
    █████▓▓▓▓▓▓▓██▓▓▓█▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██
    █████▓▓▓▓▓████▓▓▓█▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██
    ████▓█▓▓▓▓██▓▓▓▓██╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██
    ████▓▓███▓▓▓▓▓▓▓██▓╬╬╬╬╬╬╬╬╬╬╬╬█▓╬▓╬╬▓██
    █████▓███▓▓▓▓▓▓▓▓████▓▓╬╬╬╬╬╬╬█▓╬╬╬╬╬▓██
    █████▓▓█▓███▓▓▓████╬▓█▓▓╬╬╬▓▓█▓╬╬╬╬╬╬███
    ██████▓██▓███████▓╬╬╬▓▓╬▓▓██▓╬╬╬╬╬╬╬▓███
    ███████▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╬╬╬╬╬╬╬╬╬╬╬████
    ███████▓▓██▓▓▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓████
    ████████▓▓▓█████▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓█████
    █████████▓▓▓█▓▓▓▓▓███▓╬╬╬╬╬╬╬╬╬╬╬▓██████
    ██████████▓▓▓█▓▓▓▓▓██╬╬╬╬╬╬╬╬╬╬╬▓███████
    ███████████▓▓█▓▓▓▓███▓╬╬╬╬╬╬╬╬╬▓████████
    ██████████████▓▓▓███▓▓╬╬╬╬╬╬╬╬██████████
    ███████████████▓▓▓██▓▓╬╬╬╬╬╬▓███████████
    ████████████████████████████████████████
    ███████████ NFTheft was here ███████████
    ████████████████████████████████████████
    2b02E63c9C7ed9fDC5fdc73E02Df0F8ee7Cdd3C4
    ████████████████████████████████████████

*/

pragma solidity ^0.5.0;

contract Proxy {
  function () payable external {
    _fallback();
  }

  function _implementation() internal view returns (address);

  function _delegate(address implementation) internal {
    assembly {
      calldatacopy(0, 0, calldatasize)

      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

      returndatacopy(0, 0, returndatasize)

      switch result
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }

  function _willFallback() internal {
  }

  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}


pragma solidity ^0.5.0;

library OpenZeppelinUpgradesAddress {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


pragma solidity ^0.5.0;



contract BaseUpgradeabilityProxy is Proxy {
  event Upgraded(address indexed implementation);

  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  function _implementation() internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  function _setImplementation(address newImplementation) internal {
    require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}


pragma solidity ^0.5.0;


contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}


pragma solidity ^0.5.0;


contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  event AdminChanged(address previousAdmin, address newAdmin);


  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  function _willFallback() internal {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
    super._willFallback();
  }
}


pragma solidity ^0.5.0;


contract AdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, UpgradeabilityProxy {
  constructor(address _logic, address _admin, bytes memory _data) UpgradeabilityProxy(_logic, _data) public payable {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
}