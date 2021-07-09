// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { Ownable } from  "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Delegator
 * @author Railgun Contributors
 * @notice 'Owner' contract for all railgun contracts
 * delegates permissions to other contracts (voter, role)
 */
contract Delegator is Ownable {
  /*
  Mapping structure is calling address => contract => function signature
  0 is used as a wildcard, so permission for contract 0 is permission for
  any contract, and permission for function signature 0 is permission for
  any function.

  Comments below use * to signify wildcard and . notation to seperate address/contract/function.

  caller.*.* allows caller to call any function on any contract
  caller.X.* allows caller to call any function on contract X
  caller.*.Y allows caller to call function Y on any contract
  */
  mapping(
    address => mapping(
      address => mapping(bytes4 => bool)
    )
  ) public permissions;

  event GrantPermission(address indexed caller, address indexed contractAddress, bytes4 indexed selector);
  event RevokePermission(address indexed caller, address indexed contractAddress, bytes4 indexed selector);

  /**
   * @notice Sets initial admin
   */
  constructor(address _admin) {
    Ownable.transferOwnership(_admin);
  }

  /**
   * @notice Sets permission bit
   * @dev See comment on permissions mapping for wildcard format
   * @param _caller - caller to set permissions for
   * @param _contract - contract to set permissions for
   * @param _selector - selector to set permissions for
   * @param _permission - permission bit to set
   */
  function setPermission(
    address _caller,
    address _contract,
    bytes4 _selector,
    bool _permission
   ) public onlyOwner {
    // If permission set is different to new permission then we execute, otherwise skip
    if (permissions[_caller][_contract][_selector] != _permission) {
      // Set permission bit
      permissions[_caller][_contract][_selector] = _permission;

      // Emit event
      if (_permission) {
        emit GrantPermission(_caller, _contract, _selector);
      } else {
        emit RevokePermission(_caller, _contract, _selector);
      }
    }
  }

  /**
   * @notice Checks if caller has permission to execute function
   * @param _caller - caller to check permissions for
   * @param _contract - contract to check
   * @param _selector - function signature to check
   * @return if caller has permission
   */
  function checkPermission(address _caller, address _contract, bytes4 _selector) public view returns (bool) {
    /* 
    See comment on permissions mapping for structure
    Comments below use * to signify wildcard and . notation to seperate contract/function
    */
    return (
      _caller == Ownable.owner()
      || permissions[_caller][_contract][_selector] // Owner always has global permissions
      || permissions[_caller][_contract][0x0] // Permission for function is given
      || permissions[_caller][address(0)][_selector] // Permission for _contract.* is given
      || permissions[_caller][address(0)][0x0] // Global permission is given
    );
  }

  /**
   * @notice Calls function
   * @dev calls to functions on this contract are intercepted and run directly
   * this is so the voting contract doesn't need to have special cases for calling
   * functions other than this one.
   * @param _contract - contract to call
   * @param _data - calldata to pass to contract
   * @return success - whether call succeeded
   * @return returnData - return data from function call
   */
  function callContract(address _contract, bytes calldata _data, uint256 _value) public returns (bool success, bytes memory returnData) {
    // Get selector
    bytes4 selector = bytes4(_data);

    // Intercept calls to this contract
    if (_contract == address(this)) {
      if (selector == this.setPermission.selector) {
        // Decode call data
        (
          address caller,
          address calledContract,
          bytes4 _permissionSelector,
          bool permission
        ) = abi.decode(abi.encodePacked(_data[4:]), (address, address, bytes4, bool));

        // Call setPermission
        setPermission(caller, calledContract, _permissionSelector, permission);

        // Return success with empty returndata bytes
        bytes memory empty;
        return (true, empty);
      } else if (selector == this.transferOwnership.selector) {
        // Decode call data
        (
          address newOwner
        ) = abi.decode(abi.encodePacked(_data[4:]), (address));

        // Call transferOwnership
        Ownable.transferOwnership(newOwner);

        // Return success with empty returndata bytes
        bytes memory empty;
        return (true, empty);
      } else if (selector == this.renounceOwnership.selector) {
        // Call renounceOwnership
        Ownable.renounceOwnership();

        // Return success with empty returndata bytes
        bytes memory empty;
        return (true, empty);
      } else { 
        // Return failed with empty returndata bytes
        bytes memory empty;
        return (false, empty);
      }
    }

    // Check permissions
    require(checkPermission(msg.sender, _contract, selector), "Delegator: Caller doesn't have permission");

    // Call external contract and return
    // solhint-disable-next-line avoid-low-level-calls
    return _contract.call{value: _value}(_data);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1600
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}