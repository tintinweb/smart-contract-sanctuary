// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IERC165 } from '../shared/Diamond/interfaces/IERC165.sol';
import { IDiamondCut } from '../shared/Diamond/interfaces/IDiamondCut.sol';
import { IDiamondLoupe } from '../shared/Diamond/interfaces/IDiamondLoupe.sol';
import { IERC173 } from '../shared/Diamond/interfaces/IERC173.sol';
import { IERC20Mintable } from './interfaces/IERC20Mintable.sol';

import { LibDiamond } from '../shared/Diamond/libraries/LibDiamond.sol';
import { AppStorage } from './libraries/LibAppStorage.sol';

contract InitDiamond {
  AppStorage internal s;

  /// @notice initial args to be passed when cutting diamond
  struct Args {
    /// token that is being minted
    address token;
    /// deb address for dev funds
    address devAddress;
    /// locking period in human readable days
    uint256 lockingPeriodDays;
  }

  /// @notice init the Diamond
  /// @param _args the ards being passed into the diamond
  function init(Args memory _args) external {
    // set initial state
    s.token = IERC20Mintable(_args.token);
    s.lockingPeriod = _args.lockingPeriodDays * 1 days;
    s.devAddress = _args.devAddress;
    s.devMint = true;
    s.rewardPercent = 33;

    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    // adding ERC165 data
    ds.supportedInterfaces[type(IERC165).interfaceId] = true;
    ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
    ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
    ds.supportedInterfaces[type(IERC173).interfaceId] = true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface IERC165 {
  /// @notice Query if a contract implements an interface
  /// @param interfaceId The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
  enum FacetCutAction {
    Add,
    Replace,
    Remove,
    Polish
  }

  struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
  }

  /// @notice Add/replace/remove any number of functions and optionally execute
  ///         a function with delegatecall
  /// @param _diamondCut Contains the facet addresses and function selectors
  /// @param _init The address of the contract or facet to execute _calldata
  /// @param _calldata A function call, including function selector and arguments
  ///                  _calldata is executed with delegatecall on _init
  function diamondCut(
    FacetCut[] calldata _diamondCut,
    address _init,
    bytes calldata _calldata
  ) external;

  event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
  /// These functions are expected to be called frequently
  /// by tools.

  struct Facet {
    address facetAddress;
    bytes4[] functionSelectors;
    bool polished;
  }

  /// @notice Gets all facet addresses and their four byte function selectors.
  /// @return facets_ Facet
  function facets() external view returns (Facet[] memory facets_);

  /// @notice Gets all the function selectors supported by a specific facet.
  /// @param _facet The facet address.
  /// @return facetFunctionSelectors_
  function facetFunctionSelectors(address _facet)
    external
    view
    returns (bytes4[] memory facetFunctionSelectors_);

  /// @notice Get all the facet addresses used by a diamond.
  /// @return facetAddresses_
  function facetAddresses()
    external
    view
    returns (address[] memory facetAddresses_);

  /// @notice Gets the facet that supports the given selector.
  /// @dev If facet is not found return address(0).
  /// @param _functionSelector The function selector.
  /// @return facetAddress_ The facet address.
  function facetAddress(bytes4 _functionSelector)
    external
    view
    returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
  /// @dev This emits when ownership of a contract changes.
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /// @notice Get the address of the owner
  /// @return owner_ The address of the owner.
  function owner() external view returns (address owner_);

  /// @notice Set the address of the new owner of the contract
  /// @dev Set _newOwner to address(0) to renounce any ownership.
  /// @param _newOwner The address of the new owner of the contract
  function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Mintable {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function mint(address _to, uint256 _amount) external;

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of Diamond facet.
* This is gas optimized by reducing storage reads and storage writes.
* This code is as complex as it is to reduce gas costs.
/******************************************************************************/

import { IDiamondCut } from '../interfaces/IDiamondCut.sol';

library LibDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION =
    keccak256('diamond.standard.diamond.storage');

  struct DiamondStorage {
    // maps function selectors to the facets that execute the functions.
    // and maps the selectors to their position in the selectorSlots array.
    // func selector => address facet, selector position
    mapping(bytes4 => bytes32) facets;
    /// maps the polished facets, these facets cant be changed
    mapping(bytes4 => bool) polishedFacets;
    // array of slots of function selectors.
    // each slot holds 8 function selectors.
    mapping(uint256 => bytes32) selectorSlots;
    // The number of function selectors in selectorSlots
    uint16 selectorCount;
    // owner of the contract
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
    address contractOwner;
    // checks if whole diamond is polished
    bool polished;
  }

  function diamondStorage() internal pure returns (DiamondStorage storage ds_) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    DiamondStorage storage ds;

    assembly {
      ds.slot := position
    }

    ds_ = ds;
  }

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  function setContractOwner(address _newOwner) internal {
    DiamondStorage storage ds = diamondStorage();
    address previousOwner = ds.contractOwner;
    ds.contractOwner = _newOwner;
    emit OwnershipTransferred(previousOwner, _newOwner);
  }

  function contractOwner() internal view returns (address contractOwner_) {
    contractOwner_ = diamondStorage().contractOwner;
  }

  function enforceIsContractOwner() internal view {
    require(
      msg.sender == diamondStorage().contractOwner,
      'LibDiamond: Must be contract owner'
    );
  }

  modifier onlyOwner {
    require(
      msg.sender == diamondStorage().contractOwner,
      'LibDiamond: Must be contract owner'
    );
    _;
  }

  event DiamondCut(
    IDiamondCut.FacetCut[] _diamondCut,
    address _init,
    bytes _calldata
  );

  bytes32 constant CLEAR_ADDRESS_MASK =
    bytes32(uint256(0xffffffffffffffffffffffff));
  bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

  // Internal function version of diamondCut
  // This code is almost the same as the external diamondCut,
  // except it is using 'Facet[] memory _diamondCut' instead of
  // 'Facet[] calldata _diamondCut'.
  // The code is duplicated to prevent copying calldata to memory which
  // causes an error for a two dimensional array.
  function diamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    DiamondStorage storage ds = diamondStorage();
    uint256 originalSelectorCount = ds.selectorCount;
    uint256 selectorCount = originalSelectorCount;
    bytes32 selectorSlot;
    // Check if last selector slot is not full
    if (selectorCount % 8 > 0) {
      // get last selectorSlot
      selectorSlot = ds.selectorSlots[selectorCount / 8];
    }
    // loop through diamond cut
    for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
      (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
        selectorCount,
        selectorSlot,
        _diamondCut[facetIndex].facetAddress,
        _diamondCut[facetIndex].action,
        _diamondCut[facetIndex].functionSelectors
      );
    }
    if (selectorCount != originalSelectorCount) {
      ds.selectorCount = uint16(selectorCount);
    }
    // If last selector slot is not full
    if (selectorCount % 8 > 0) {
      ds.selectorSlots[selectorCount / 8] = selectorSlot;
    }
    emit DiamondCut(_diamondCut, _init, _calldata);
    initializeDiamondCut(_init, _calldata);
  }

  function addReplaceRemoveFacetSelectors(
    uint256 _selectorCount,
    bytes32 _selectorSlot,
    address _newFacetAddress,
    IDiamondCut.FacetCutAction _action,
    bytes4[] memory _selectors
  ) internal returns (uint256, bytes32) {
    DiamondStorage storage ds = diamondStorage();
    require(!ds.polished, 'LibDiamondCut: Cant change polished diamond');
    require(
      _selectors.length > 0,
      'LibDiamondCut: No selectors in facet to cut'
    );
    bytes32 selectorSlotRef = _selectorSlot;
    uint256 selectorCountRef = _selectorCount;
    // add functions
    if (_action == IDiamondCut.FacetCutAction.Add) {
      require(
        _newFacetAddress != address(0),
        "LibDiamondCut: Add facet can't be address(0)"
      );
      for (
        uint256 selectorIndex;
        selectorIndex < _selectors.length;
        selectorIndex++
      ) {
        bytes4 selector = _selectors[selectorIndex];
        bytes32 oldFacet = ds.facets[selector];
        require(
          address(bytes20(oldFacet)) == address(0),
          "LibDiamondCut: Can't add function that already exists"
        );
        // add facet for selector
        ds.facets[selector] =
          bytes20(_newFacetAddress) |
          bytes32(selectorCountRef);
        uint256 selectorInSlotPosition = (selectorCountRef % 8) * 32;
        // clear selector position in slot and add selector
        selectorSlotRef =
          (selectorSlotRef & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
          (bytes32(selector) >> selectorInSlotPosition);
        // if slot is full then write it to storage
        if (selectorInSlotPosition == 224) {
          ds.selectorSlots[selectorCountRef / 8] = selectorSlotRef;
          selectorSlotRef = 0;
        }
        selectorCountRef++;
      }
    } else if (_action == IDiamondCut.FacetCutAction.Replace) {
      require(
        _newFacetAddress != address(0),
        "LibDiamondCut: Replace facet can't be address(0)"
      );
      enforceHasContractCode(
        _newFacetAddress,
        'LibDiamondCut: Replace facet has no code'
      );
      for (
        uint256 selectorIndex;
        selectorIndex < _selectors.length;
        selectorIndex++
      ) {
        bytes4 selector = _selectors[selectorIndex];
        bytes32 oldFacet = ds.facets[selector];
        address oldFacetAddress = address(bytes20(oldFacet));
        bool isPolished = ds.polishedFacets[selector];

        // only useful if immutable functions exist
        require(
          oldFacetAddress != address(this),
          "LibDiamondCut: Can't replace immutable function"
        );
        require(!isPolished, "LibDiamondCut: Can't replace polished facets");
        require(
          oldFacetAddress != _newFacetAddress,
          "LibDiamondCut: Can't replace function with same function"
        );
        require(
          oldFacetAddress != address(0),
          "LibDiamondCut: Can't replace function that doesn't exist"
        );
        // replace old facet address
        ds.facets[selector] =
          (oldFacet & CLEAR_ADDRESS_MASK) |
          bytes20(_newFacetAddress);
      }
    } else if (_action == IDiamondCut.FacetCutAction.Remove) {
      require(
        _newFacetAddress == address(0),
        'LibDiamondCut: Remove facet address must be address(0)'
      );
      uint256 selectorSlotCount = selectorCountRef / 8;
      uint256 selectorInSlotIndex = (selectorCountRef % 8) - 1;
      for (
        uint256 selectorIndex;
        selectorIndex < _selectors.length;
        selectorIndex++
      ) {
        if (selectorSlotRef == 0) {
          // get last selectorSlot
          selectorSlotCount--;
          selectorSlotRef = ds.selectorSlots[selectorSlotCount];
          selectorInSlotIndex = 7;
        }
        bytes4 lastSelector;
        uint256 oldSelectorsSlotCount;
        uint256 oldSelectorInSlotPosition;
        // adding a block here prevents stack too deep error
        {
          bytes4 selector = _selectors[selectorIndex];
          bytes32 oldFacet = ds.facets[selector];
          bool isPolished = ds.polishedFacets[selector];

          require(
            address(bytes20(oldFacet)) != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
          );
          // only useful if immutable functions exist
          require(
            address(bytes20(oldFacet)) != address(this),
            "LibDiamondCut: Can't remove immutable function"
          );
          // cant remove polished facet
          require(!isPolished, "LibDiamondCut: Can't remove polished facets");
          // replace selector with last selector in ds.facets
          // gets the last selector
          lastSelector = bytes4(selectorSlotRef << (selectorInSlotIndex * 32));
          if (lastSelector != selector) {
            // update last selector slot position info
            ds.facets[lastSelector] =
              (oldFacet & CLEAR_ADDRESS_MASK) |
              bytes20(ds.facets[lastSelector]);
          }
          delete ds.facets[selector];
          uint256 oldSelectorCount = uint16(uint256(oldFacet));
          oldSelectorsSlotCount = oldSelectorCount / 8;
          oldSelectorInSlotPosition = (oldSelectorCount % 8) * 32;
        }
        if (oldSelectorsSlotCount != selectorSlotCount) {
          bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
          // clears the selector we are deleting and puts the last selector in its place.
          oldSelectorSlot =
            (oldSelectorSlot &
              ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
            (bytes32(lastSelector) >> oldSelectorInSlotPosition);
          // update storage with the modified slot
          ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
        } else {
          // clears the selector we are deleting and puts the last selector in its place.
          selectorSlotRef =
            (selectorSlotRef &
              ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
            (bytes32(lastSelector) >> oldSelectorInSlotPosition);
        }
        if (selectorInSlotIndex == 0) {
          delete ds.selectorSlots[selectorSlotCount];
          selectorSlotRef = 0;
        }
        selectorInSlotIndex--;
      }
      selectorCountRef = selectorSlotCount * 8 + selectorInSlotIndex + 1;
    } else if (_action == IDiamondCut.FacetCutAction.Polish) {
      for (
        uint256 selectorIndex;
        selectorIndex < _selectors.length;
        selectorIndex++
      ) {
        bytes4 selector = _selectors[selectorIndex];
        bytes32 facet = ds.facets[selector];
        address facetAddress = address(bytes20(facet));
        bool isPolished = ds.polishedFacets[selector];

        // only useful if immutable functions exist
        require(
          facetAddress != address(this),
          "LibDiamondCut: Can't polish immutable function"
        );
        require(!isPolished, 'LibDiamondCut: Facet already polished');

        ds.polishedFacets[selector] = true;
      }
    } else {
      revert('LibDiamondCut: Incorrect FacetCutAction');
    }
    return (selectorCountRef, selectorSlotRef);
  }

  function initializeDiamondCut(address _init, bytes memory _calldata)
    internal
  {
    if (_init == address(0)) {
      require(
        _calldata.length == 0,
        'LibDiamondCut: _init is address(0) but_calldata is not empty'
      );
    } else {
      require(
        _calldata.length > 0,
        'LibDiamondCut: _calldata is empty but _init is not address(0)'
      );
      if (_init != address(this)) {
        enforceHasContractCode(
          _init,
          'LibDiamondCut: _init address has no code'
        );
      }
      (bool success, bytes memory error) = _init.delegatecall(_calldata);
      if (!success) {
        if (error.length > 0) {
          // bubble up the error
          revert(string(error));
        } else {
          revert('LibDiamondCut: _init function reverted');
        }
      }
    }
  }

  function enforceHasContractCode(
    address _contract,
    string memory _errorMessage
  ) internal view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    require(contractSize > 0, _errorMessage);
  }

  function polishDiamond() internal {
    DiamondStorage storage ds = diamondStorage();
    require(!ds.polished, 'LibDiamondCut: Diamond already polished');
    ds.polished = true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { IStakePolicy } from '../interfaces/IStakePolicy.sol';
import { IERC20Mintable } from '../interfaces/IERC20Mintable.sol';
import { LibDiamond } from '../../shared/Diamond/libraries/LibDiamond.sol';
// reward precision
uint256 constant ACC_REWARD_PRECISION = 1e18;

// max allocation points
uint256 constant MAX_ALLOC_POINT = 100000; // Safety check

// struct for the pool info
struct PoolInfo {
  /// LP token in the pool
  address lpToken;
  /// accumulated tokens per share
  uint128 accTokenPerShare;
  /// last block to have reward minted
  uint64 lastRewardBlock;
  /// allocation points for reward percentage
  uint64 allocPoint;
  /// deposit fee form 0 = 100;
  uint16 depositFee;
  /// total deposited
  uint256 totalDeposited;
  /// the policy that decides the staked tokens fate
  IStakePolicy stakePolicy;
}

/// struct for the lock info
struct LockInfo {
  /// amount locked
  uint256 amount;
  /// when locked
  uint256 timestamp;
}

/// struct for the users lock info
struct UserLockInfo {
  /// array of lock info
  LockInfo[] lockInfo;
  /// unclaimed amount
  uint256 unclaimed;
  /// last claimed id
  uint256 lastClaimed;
}

/// struct for the user info
struct UserInfo {
  /// amount user has staked minus fees
  uint256 amount;
  /// amount the amount of reward owed to user per block
  int256 rewardDebt;
  /// last token per share for user
  uint256 lastTokenPerShare;
}

/// struct for teh app state
struct AppStorage {
  /// token being minted in pools
  IERC20Mintable token;
  /// dev address where dev funds go
  address devAddress;
  /// bool to decide if the the devs get minted funds
  bool devMint;
  /// the period of how long the reward funds are locked
  uint256 lockingPeriod;
  /// the record of user info
  mapping(uint256 => mapping(address => UserInfo)) userInfo;
  /// the lock info for users
  mapping(address => UserLockInfo) userLockInfo;
  /// total allocation points
  uint256 totalAllocPoint;
  /// reward tokens per block
  uint256 rewardPerBlock;
  /// the percentage of reward that doesn't get locked
  uint256 rewardPercent;
  /// information on the pools
  PoolInfo[] poolInfo;
  /// list of liquidity pool tokens
  mapping(address => bool) lpTokens;
  /// app pause status
  bool paused;
}

/// @notice app storage library for mapping state
library LibAppStorage {
  function diamondStorage() internal pure returns (AppStorage storage ds_) {
    AppStorage storage ds;

    assembly {
      ds.slot := 0
    }
    ds_ = ds;
  }

  function abs(int256 x) internal pure returns (uint256 abs_) {
    abs_ = uint256(x >= 0 ? x : -x);
  }
}

/// @notice modifiers used in application
contract Modifiers {
  AppStorage internal s;

  /// @notice modifier to check if pools contain liquidity pool
  modifier nonDuplicated(address _lpToken) {
    require(
      s.lpTokens[_lpToken] == false,
      'Modifiers: cant use the same LP token'
    );
    _;
  }

  /// @notice modifier to make a function callable only when the contract is not paused.
  modifier whenNotPaused {
    require(!s.paused, 'Modifiers: paused');
    _;
  }

  /// @notice modifier to make a function callable only when the contract is paused.
  modifier whenPaused {
    require(s.paused, 'Modifiers: not paused');
    _;
  }

  modifier onlyOwner {
    LibDiamond.enforceIsContractOwner();
    _;
  }

  modifier onlyThis {
    require(
      msg.sender == address(this),
      'Modifiers: can only be called by diamond'
    );
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IStakePolicy {
  function deposit(
    uint256 _amount,
    address _owner,
    uint16 _depositFee
  ) external returns (uint256 amount_);

  function withdraw(uint256 _amount, address _owner) external;

  function setFeeAddress(address _feeAddress) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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