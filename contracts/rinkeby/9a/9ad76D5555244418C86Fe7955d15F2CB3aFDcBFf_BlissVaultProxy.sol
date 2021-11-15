pragma solidity ^0.6.0;



contract BlissVaultProxy {
  bytes32 private constant implementationPosition = bytes32(uint256(keccak256("bliss.vault.impl")) - 1);
  bytes32 private constant proxyOwnerPosition = bytes32(uint256(keccak256("bliss.vault.owner")) - 1);

  constructor() public {
    _setUpgradeabilityOwner(msg.sender);
  }

  function setup(address _implementation) external {
    require(msg.sender == proxyOwner());
    _setImplementation(_implementation);
  }

  function setupOwner(address _newOwner) external {
    require(msg.sender == proxyOwner());
    _setUpgradeabilityOwner(_newOwner);
  }

  // setter to set the position of an implementation from the implementation position onwards
  function _setImplementation(address _newImplementation) internal {
    require(msg.sender == proxyOwner());
    bytes32 position = implementationPosition;

    assembly {
      sstore(position, _newImplementation)
    }
  }

  // retrieving the address at the implementation position
  function implementation() public view returns (address impl) {
    bytes32 position = implementationPosition;
    assembly {
      impl := sload(position)
    }
  }

  function proxyOwner() public view returns (address owner) {
    bytes32 position = proxyOwnerPosition;
    assembly {
      owner := sload(position)
    }
  }

  function _setUpgradeabilityOwner(address _newProxyOwner) private {
    bytes32 position = proxyOwnerPosition;
    assembly {
      sstore(position, _newProxyOwner)
    }
  }

  fallback() external payable {
    address addr = implementation();

    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), addr, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
    }
  }
}

