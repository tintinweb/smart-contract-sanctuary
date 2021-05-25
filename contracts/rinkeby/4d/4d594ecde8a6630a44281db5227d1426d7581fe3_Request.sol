/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

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

contract Request is Initializable {
    address public owner;

    function initialize() public initializer {
        owner = msg.sender;
    }

    uint256 public x;

    uint256 private delay = 3 days;

    bool public ordered = false;

    uint256 public orderTime;

    uint256 public x_preparation;

    modifier onlyOwner {
        require(msg.sender == owner, "Onwer required");
        _;
    }

    function requestChangeX(uint256 _x) public onlyOwner {
        require(!ordered, "Ordered");
        x_preparation = _x;
        orderTime = block.timestamp;
        ordered = true;
    }

    function executeRequest() public onlyOwner {
        require(ordered, "Not Ordered");
        // 不会溢出
        require(block.timestamp > orderTime + delay, "Invalid time");
        x = x_preparation;
        x_preparation = 0;
        orderTime = block.timestamp;
        ordered = false;
    }
}