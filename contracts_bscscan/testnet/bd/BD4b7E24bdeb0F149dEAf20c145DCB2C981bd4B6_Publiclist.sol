/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;

// copyright: UMAprotocol
// URL:  https://github.com/UMAprotocol/protocol/blob/master/packages/core/contracts/common/implementation/AddressPubliclist.sol

interface IPubliclist {
    function addToPubliclist(address newElement) external;

    function removeFromPubliclist(address newElement) external;

    function isOnPubliclist(address newElement) external view returns (bool);

    function getPubliclist() external view returns (address[] memory);
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
 * @title A contract to track a publiclist of addresses.
 */
contract Publiclist is IPubliclist, Lockable {
    enum Status { None, In, Out }
    mapping(address => Status) public publiclist;

    address public market;
    address[] public publiclistIndices;

    event AddedToPubliclist(address indexed addedAddress);
    event RemovedFromPubliclist(address indexed removedAddress);

    modifier onlyMarket() {
        require( market == msg.sender, "caller is not the public market" );
        _;
    }

    constructor(address _market) {
        market = _market;
    }

    /**
     * @notice Adds an address to the publiclist.
     * @param newElement the new address to add.
     */
    function addToPubliclist(address newElement) external override nonReentrant() onlyMarket() {
        // Ignore if address is already included
        if (publiclist[newElement] == Status.In) {
            return;
        }

        // Only append new addresses to the array, never a duplicate
        if (publiclist[newElement] == Status.None) {
            publiclistIndices.push(newElement);
        }

        publiclist[newElement] = Status.In;

        emit AddedToPubliclist(newElement);
    }

    /**
     * @notice Removes an address from the publiclist.
     * @param elementToRemove the existing address to remove.
     */
    function removeFromPubliclist(address elementToRemove) external override nonReentrant() onlyMarket() {
        if (publiclist[elementToRemove] != Status.Out) {
            publiclist[elementToRemove] = Status.Out;
            emit RemovedFromPubliclist(elementToRemove);
        }
    }

    /**
     * @notice Checks whether an address is on the publiclist.
     * @param elementToCheck the address to check.
     * @return True if `elementToCheck` is on the publiclist, or False.
     */
    function isOnPubliclist(address elementToCheck) external view override nonReentrantView() returns (bool) {
        return publiclist[elementToCheck] == Status.In;
    }

    /**
     * @notice Gets all addresses that are currently included in the publiclist.
     * @dev Note: This method skips over, but still iterates through addresses. It is possible for this call to run out
     * of gas if a large number of addresses have been removed. To reduce the likelihood of this unlikely scenario, we
     * can modify the implementation so that when addresses are removed, the last addresses in the array is moved to
     * the empty index.
     * @return activePubliclist the list of addresses on the publiclist.
     */
    function getPubliclist() external view override nonReentrantView() returns (address[] memory activePubliclist) {
        // Determine size of publiclist first
        uint256 activeCount = 0;
        for (uint256 i = 0; i < publiclistIndices.length; i++) {
            if (publiclist[publiclistIndices[i]] == Status.In) {
                activeCount++;
            }
        }

        // Populate publiclist
        activePubliclist = new address[](activeCount);
        activeCount = 0;
        for (uint256 i = 0; i < publiclistIndices.length; i++) {
            address addr = publiclistIndices[i];
            if (publiclist[addr] == Status.In) {
                activePubliclist[activeCount] = addr;
                activeCount++;
            }
        }
    }
}