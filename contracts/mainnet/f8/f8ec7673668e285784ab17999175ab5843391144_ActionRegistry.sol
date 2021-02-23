/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

interface ITypes {
  struct Call {
    address to;
    uint96 value;
    bytes data;
  }

  struct CallReturn {
    bool ok;
    bytes returnData;
  }
}

interface IActionRegistry {

  // events
  event AddedSelector(address account, bytes4 selector);
  event RemovedSelector(address account, bytes4 selector);
  event AddedSpender(address account, address spender);
  event RemovedSpender(address account, address spender);

  struct AccountSelectors {
    address account;
    bytes4[] selectors;
  }

  struct AccountSpenders {
    address account;
    address[] spenders;
  }

  function isValidAction(ITypes.Call[] calldata calls) external view returns (bool valid);
  function addSelector(address account, bytes4 selector) external;
  function removeSelector(address account, bytes4 selector) external;
  function addSpender(address account, address spender) external;
  function removeSpender(address account, address spender) external;
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 *
 * In order to transfer ownership, a recipient must be specified, at which point
 * the specified recipient can call `acceptOwnership` and take ownership.
 */

contract TwoStepOwnable {
  address private _owner;

  address private _newPotentialOwner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initialize contract by setting transaction submitter as initial owner.
   */
  constructor() public {
    _owner = tx.origin;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows a new account (`newOwner`) to accept ownership.
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(
      newOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }

  /**
   * @dev Cancel a transfer of ownership to a new account.
   * Can only be called by the current owner.
   */
  function cancelOwnershipTransfer() public onlyOwner {
    delete _newPotentialOwner;
  }

  /**
   * @dev Transfers ownership of the contract to the caller.
   * Can only be called by a new potential owner set by the current owner.
   */
  function acceptOwnership() public {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }
}


interface IERC20 {
  function approve(address spender, uint256 amount) external returns (bool);
}

contract ActionRegistry is IActionRegistry, TwoStepOwnable {

  mapping(address => bytes4[]) internal _functionSelectors;
  mapping(address => mapping(bytes4 => uint256)) public _functionSelectorIndices;

  mapping(address => address[]) internal _accountSpenders;
  mapping(address => mapping(address => uint256)) public _spenderIndices;

  function isValidAction(
    ITypes.Call[] calldata calls
  ) external override view returns (bool valid) {
    valid = true;
    for (uint256 i = 0; i < calls.length; i++) {

      valid = _validCall(calls[i].to, calls[i].data);

      if (!valid) {
        break;
      }
    }
  }

  function _validCall(address to, bytes calldata callData) internal view returns (bool) {
    if (callData.length < 4) {
      return false;
    }

    bytes memory functionSelectorBytes = abi.encodePacked(callData[:4], bytes28(0));
    bytes4 functionSelector = abi.decode(functionSelectorBytes, (bytes4));

    uint256 functionSelectorIndex = _functionSelectorIndices[to][functionSelector];

    if (functionSelectorIndex == 0) {
      return false;
    }

    if (functionSelector == IERC20.approve.selector) {
      bytes memory argumentBytes = abi.encodePacked(callData[4:], bytes28(0));

      if (argumentBytes.length < 68) {
        return false;
      }

      (address spender,) = abi.decode(argumentBytes, (address, uint256));
      uint256 spenderIndex = _spenderIndices[to][spender];

      if (spenderIndex == 0) {
        return false;
      }
    }

    return true;
  }


  function getAccountSpenders(address account) public view returns (address[] memory spenders) {
    spenders = _accountSpenders[account];
  }

  function getAccountSelectors(address account) public view returns (bytes4[] memory selectors) {
    selectors = _functionSelectors[account];
  }

  function addSelector(address account, bytes4 selector) external override onlyOwner {
    _addSelector(account, selector);
  }

  function removeSelector(address account, bytes4 selector) external override onlyOwner {
    _removeSelector(account, selector);
  }

  function addSelectorsAndSpenders(
    AccountSelectors[] memory accountSelectors,
    AccountSpenders[] memory accountSpenders
  ) public onlyOwner {
    _addAccountSelectors(accountSelectors);
    _addAccountSpenders(accountSpenders);
  }

  function _addAccountSelectors(AccountSelectors[] memory accountSelectors) public onlyOwner {
    for (uint256 i = 0; i < accountSelectors.length; i++) {
      for (uint256 j = 0; j < accountSelectors[i].selectors.length; j++) {
        _addSelector(accountSelectors[i].account, accountSelectors[i].selectors[j]);
      }
    }
  }

  function _addAccountSpenders(AccountSpenders[] memory accountSpenders) public onlyOwner {
    for (uint256 i = 0; i < accountSpenders.length; i++) {
      for (uint256 j = 0; j < accountSpenders[i].spenders.length; j++) {
        _addSpender(accountSpenders[i].account, accountSpenders[i].spenders[j]);
      }
    }
  }


  function _addSelector(address account, bytes4 selector) internal {
    require(
      _functionSelectorIndices[account][selector] == 0,
      "Selector for the provided account already exists."
    );

    _functionSelectors[account].push(selector);
    _functionSelectorIndices[account][selector] = _functionSelectors[account].length;

    emit AddedSelector(account, selector);
  }

  function _removeSelector(address account, bytes4 selector) internal {
    uint256 removedSelectorIndex = _functionSelectorIndices[account][selector];

    require(
      removedSelectorIndex != 0,
      "No selector found for the provided account."
    );

    // swap account to remove with the last one then pop from the array.
    bytes4 lastSelector = _functionSelectors[account][_functionSelectors[account].length - 1];
    _functionSelectors[account][removedSelectorIndex - 1] = lastSelector;
    _functionSelectorIndices[account][lastSelector] = removedSelectorIndex;
    _functionSelectors[account].pop();
    delete _functionSelectorIndices[account][selector];

    emit RemovedSelector(account, selector);
  }

  function addSpender(address account, address spender) external override onlyOwner {
    _addSpender(account, spender);
  }

  function removeSpender(address account, address spender) external override onlyOwner {
    _removeSpender(account, spender);
  }

  function _addSpender(address account, address spender) internal {
    require(
      _spenderIndices[account][spender] == 0,
      "Spender for the provided account already exists."
    );

    _accountSpenders[account].push(spender);
    _spenderIndices[account][spender] = _accountSpenders[account].length;

    emit AddedSpender(account, spender);
  }

  function _removeSpender(address account, address spender) internal {
    uint256 removedSpenderIndex = _spenderIndices[account][spender];

    require(
      removedSpenderIndex != 0,
      "No spender found for the provided account."
    );

    // swap account to remove with the last one then pop from the array.
    address lastSpender = _accountSpenders[account][_accountSpenders[account].length - 1];
    _accountSpenders[account][removedSpenderIndex - 1] = lastSpender;
    _spenderIndices[account][lastSpender] = removedSpenderIndex;
    _accountSpenders[account].pop();
    delete _spenderIndices[account][spender];

    emit RemovedSpender(account, spender);
  }
}