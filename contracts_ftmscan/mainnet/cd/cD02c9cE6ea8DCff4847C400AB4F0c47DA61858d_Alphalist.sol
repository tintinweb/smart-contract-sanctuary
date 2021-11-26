/**
 *Submitted for verification at FtmScan.com on 2021-11-26
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;

// copyright: UMAprotocol
// URL:  https://github.com/UMAprotocol/protocol/blob/master/packages/core/contracts/common/implementation/AddressAlphalist.sol

interface IOwnable {

  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}

contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view override returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}

interface IAlphalist {
    function addToAlphalist(address newElement) external;

    function removeFromAlphalist(address newElement) external;

    function isOnAlphalist(address newElement) external view returns (bool);

    function getAlphalist() external view returns (address[] memory);
}

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Lockable {
    bool private _notEntered;

    constructor() {
        // Storing an initial non-zero value makes deployment a bit more expensive, but in exchange the refund on every
        // call to nonReentrant will be lower in amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to increase the likelihood of the full
        // refund coming into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant` function is not supported. It is possible to
     * prevent this from happening by making the `nonReentrant` function external, and making it call a `private`
     * function that does the actual state modification.
     */
    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a `nonReentrant()` state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every `nonReentrant()` method.
    // On entry into a function, `_preEntranceCheck()` should always be called to check if the function is being
    // re-entered. Then, if the function modifies state, it should call `_postEntranceSet()`, perform its logic, and
    // then call `_postEntranceReset()`.
    // View-only methods can simply call `_preEntranceCheck()` to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

/**
 * @title A contract to track a alphalist of addresses.
 */
contract Alphalist is IAlphalist, Ownable, Lockable {
    enum Status { None, In, Out }
    mapping(address => Status) public alphalist;

    address[] public alphalistIndices;

    event AddedToAlphalist(address indexed addedAddress);
    event RemovedFromAlphalist(address indexed removedAddress);

    /**
     * @notice Adds an address to the alphalist.
     * @param newElement the new address to add.
     */
    function addToAlphalist(address newElement) external override nonReentrant() onlyOwner {
        // Ignore if address is already included
        if (alphalist[newElement] == Status.In) {
            return;
        }

        // Only append new addresses to the array, never a duplicate
        if (alphalist[newElement] == Status.None) {
            alphalistIndices.push(newElement);
        }

        alphalist[newElement] = Status.In;

        emit AddedToAlphalist(newElement);
    }

    /**
     * @notice Removes an address from the alphalist.
     * @param elementToRemove the existing address to remove.
     */
    function removeFromAlphalist(address elementToRemove) external override nonReentrant() onlyOwner {
        if (alphalist[elementToRemove] != Status.Out) {
            alphalist[elementToRemove] = Status.Out;
            emit RemovedFromAlphalist(elementToRemove);
        }
    }

    /**
     * @notice Checks whether an address is on the alphalist.
     * @param elementToCheck the address to check.
     * @return True if `elementToCheck` is on the alphalist, or False.
     */
    function isOnAlphalist(address elementToCheck) external view override nonReentrantView() returns (bool) {
        return alphalist[elementToCheck] == Status.In;
    }

    /**
     * @notice Gets all addresses that are currently included in the alphalist.
     * @dev Note: This method skips over, but still iterates through addresses. It is possible for this call to run out
     * of gas if a large number of addresses have been removed. To reduce the likelihood of this unlikely scenario, we
     * can modify the implementation so that when addresses are removed, the last addresses in the array is moved to
     * the empty index.
     * @return activeAlphalist the list of addresses on the alphalist.
     */
    function getAlphalist() external view override nonReentrantView() returns (address[] memory activeAlphalist) {
        // Determine size of alphalist first
        uint256 activeCount = 0;
        for (uint256 i = 0; i < alphalistIndices.length; i++) {
            if (alphalist[alphalistIndices[i]] == Status.In) {
                activeCount++;
            }
        }

        // Populate alphalist
        activeAlphalist = new address[](activeCount);
        activeCount = 0;
        for (uint256 i = 0; i < alphalistIndices.length; i++) {
            address addr = alphalistIndices[i];
            if (alphalist[addr] == Status.In) {
                activeAlphalist[activeCount] = addr;
                activeCount++;
            }
        }
    }
}