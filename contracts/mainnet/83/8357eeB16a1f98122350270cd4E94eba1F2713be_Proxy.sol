pragma solidity 0.6.2;

import 'StorageStructure.sol';

/**
 * https://eips.ethereum.org/EIPS/eip-897
 * Credits: OpenZeppelin Labs
 */
contract Proxy is StorageStructure {
  string public version;
  address public implementation;
  uint256 public constant proxyType = 2;

  /**
   * @dev This event will be emitted every time the implementation gets upgraded
   * @param version representing the version name of the upgraded implementation
   * @param implementation representing the address of the upgraded implementation
   */
  event Upgraded(string version, address indexed implementation);

  /**
   * @dev constructor that sets the manager address
   */
  constructor() public {
    manager = msg.sender;
  }

  /**
   * @dev Upgrades the implementation address
   * @param _newImplementation address of the new implementation
   */
  function upgradeTo(
    string calldata _version,
    address _newImplementation
  ) external onlyManager {
    require(implementation != _newImplementation);
    _setImplementation(_version, _newImplementation);
  }

  /**
   * @dev Fallback function allowing to perform a delegatecall
   * to the given implementation. This function will return
   * whatever the implementation call returns
   */
  fallback () external {
    address _impl = implementation;
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

  /**
   * @dev Sets the address of the current implementation
   * @param _newImp address of the new implementation
   */
  function _setImplementation(string memory _version, address _newImp) internal {
    version = _version;
    implementation = _newImp;
    emit Upgraded(version, implementation);
  }
}