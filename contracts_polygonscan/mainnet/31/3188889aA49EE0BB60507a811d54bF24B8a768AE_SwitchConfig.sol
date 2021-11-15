// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import './modules/Initializable.sol';

contract SwitchConfig is Initializable {
    address public owner;
    address public dev;
    address public admin;

    event OwnerChanged(address indexed _user, address indexed _old, address indexed _new);
    event DevChanged(address indexed _user, address indexed _old, address indexed _new);
    event AdminChanged(address indexed _user, address indexed _old, address indexed _new);

    function initialize() external initializer {
        owner = msg.sender;
        dev = msg.sender;
        admin = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'SwitchConfig: Only Owner');
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "SwitchConfig: FORBIDDEN");
        _;
    }
    
    modifier onlyDev() {
        require(msg.sender == dev || msg.sender == owner, "SwitchConfig: FORBIDDEN");
        _;
    }

    function changeOwner(address _user) external onlyOwner {
        require(owner != _user, 'SwitchConfig: NO CHANGE');
        emit OwnerChanged(msg.sender, owner, _user);
        owner = _user;
    }

    function changeDev(address _user) external onlyDev {
        require(dev != _user, 'SwitchConfig: NO CHANGE');
        emit DevChanged(msg.sender, dev, _user);
        dev = _user;
    }

    function changeAdmin(address _user) external onlyAdmin {
        require(admin != _user, 'SwitchConfig: NO CHANGE');
        emit AdminChanged(msg.sender, admin, _user);
        admin = _user;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;


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

