pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/upgrades-core/contracts/Initializable.sol";

contract Physio is Initializable {
    bool private initialized;

    struct PhysioNFT {
        string token_id;
        string chain;
        int quantity;
        address _address_sc;
    }

    mapping(string => PhysioNFT) public allPhysios;

    function initialize() public initializer {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
    }

    function makePhysio(string memory _token_id, string memory _chain, address _address_sc, int _quantity) public {
        string memory index = string(abi.encodePacked(_token_id, _chain, _address_sc));
        if (allPhysios[index].quantity > 0) {
            allPhysios[index].quantity += _quantity;
        } else {
            allPhysios[index] = PhysioNFT(_token_id, _chain, _quantity, _address_sc);
        }
    }

    function getTotalPhysios(string memory _token_id, string memory _chain, address _address_sc) public view returns (int) {
        string memory index = string(abi.encodePacked(_token_id, _chain, _address_sc));
        return allPhysios[index].quantity;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}