// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Lockable.sol";

/**
 * @title A contract to track a whitelist of addresses.
 */
contract AddressWhitelist is Ownable, Lockable {
    enum Status { None, In, Out }
    mapping(address => Status) public whitelist;

    address[] public whitelistIndices;

    event AddedToWhitelist(address indexed addedAddress);
    event RemovedFromWhitelist(address indexed removedAddress);

    /**
     * @notice Adds an address to the whitelist.
     * @param newElement the new address to add.
     */
    function addToWhitelist(address newElement) external nonReentrant() onlyOwner {
        // Ignore if address is already included
        if (whitelist[newElement] == Status.In) {
            return;
        }

        // Only append new addresses to the array, never a duplicate
        if (whitelist[newElement] == Status.None) {
            whitelistIndices.push(newElement);
        }

        whitelist[newElement] = Status.In;

        emit AddedToWhitelist(newElement);
    }

    /**
     * @notice Removes an address from the whitelist.
     * @param elementToRemove the existing address to remove.
     */
    function removeFromWhitelist(address elementToRemove) external nonReentrant() onlyOwner {
        if (whitelist[elementToRemove] != Status.Out) {
            whitelist[elementToRemove] = Status.Out;
            emit RemovedFromWhitelist(elementToRemove);
        }
    }

    /**
     * @notice Checks whether an address is on the whitelist.
     * @param elementToCheck the address to check.
     * @return True if `elementToCheck` is on the whitelist, or False.
     */
    function isOnWhitelist(address elementToCheck) external view nonReentrantView() returns (bool) {
        return whitelist[elementToCheck] == Status.In;
    }

    /**
     * @notice Gets all addresses that are currently included in the whitelist.
     * @dev Note: This method skips over, but still iterates through addresses. It is possible for this call to run out
     * of gas if a large number of addresses have been removed. To reduce the likelihood of this unlikely scenario, we
     * can modify the implementation so that when addresses are removed, the last addresses in the array is moved to
     * the empty index.
     * @return activeWhitelist the list of addresses on the whitelist.
     */
    function getWhitelist() external view nonReentrantView() returns (address[] memory activeWhitelist) {
        // Determine size of whitelist first
        uint256 activeCount = 0;
        for (uint256 i = 0; i < whitelistIndices.length; i++) {
            if (whitelist[whitelistIndices[i]] == Status.In) {
                activeCount++;
            }
        }

        // Populate whitelist
        activeWhitelist = new address[](activeCount);
        activeCount = 0;
        for (uint256 i = 0; i < whitelistIndices.length; i++) {
            address addr = whitelistIndices[i];
            if (whitelist[addr] == Status.In) {
                activeWhitelist[activeCount] = addr;
                activeCount++;
            }
        }
    }
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Lockable {
    bool private _notEntered;

    constructor() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
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
    // On entry into a function, `_preEntranceCheck()` should always be called to check if the function is being re-entered.
    // Then, if the function modifies state, it should call `_postEntranceSet()`, perform its logic, and then call `_postEntranceReset()`.
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

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/StoreInterface.sol";
import "../interfaces/OracleAncillaryInterface.sol";
import "../interfaces/FinderInterface.sol";
import "../interfaces/IdentifierWhitelistInterface.sol";
import "../interfaces/OptimisticOracleInterface.sol";
import "./Constants.sol";

import "../../common/implementation/Testable.sol";
import "../../common/implementation/Lockable.sol";
import "../../common/implementation/FixedPoint.sol";
import "../../common/implementation/AddressWhitelist.sol";

/**
 * @title Optimistic Requester.
 * @notice Optional interface that requesters can implement to receive callbacks.
 * @dev this contract does _not_ work with ERC777 collateral currencies or any others that call into the receiver on
 * transfer(). Using an ERC777 token would allow a user to maliciously grief other participants (while also losing
 * money themselves).
 */
interface OptimisticRequester {
    /**
     * @notice Callback for proposals.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data of the price being requested.
     */
    function priceProposed(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external;

    /**
     * @notice Callback for disputes.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data of the price being requested.
     * @param refund refund received in the case that refundOnDispute was enabled.
     */
    function priceDisputed(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 refund
    ) external;

    /**
     * @notice Callback for settlement.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data of the price being requested.
     * @param price price that was resolved by the escalation process.
     */
    function priceSettled(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 price
    ) external;
}

/**
 * @title Optimistic Oracle.
 * @notice Pre-DVM escalation contract that allows faster settlement.
 */
contract OptimisticOracle is OptimisticOracleInterface, Testable, Lockable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    event RequestPrice(
        address indexed requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes ancillaryData,
        address currency,
        uint256 reward,
        uint256 finalFee
    );
    event ProposePrice(
        address indexed requester,
        address indexed proposer,
        bytes32 identifier,
        uint256 timestamp,
        bytes ancillaryData,
        int256 proposedPrice,
        uint256 expirationTimestamp,
        address currency
    );
    event DisputePrice(
        address indexed requester,
        address indexed proposer,
        address indexed disputer,
        bytes32 identifier,
        uint256 timestamp,
        bytes ancillaryData,
        int256 proposedPrice
    );
    event Settle(
        address indexed requester,
        address indexed proposer,
        address indexed disputer,
        bytes32 identifier,
        uint256 timestamp,
        bytes ancillaryData,
        int256 price,
        uint256 payout
    );

    mapping(bytes32 => Request) public requests;

    // Finder to provide addresses for DVM contracts.
    FinderInterface public finder;

    // Default liveness value for all price requests.
    uint256 public defaultLiveness;

    /**
     * @notice Constructor.
     * @param _liveness default liveness applied to each price request.
     * @param _finderAddress finder to use to get addresses of DVM contracts.
     * @param _timerAddress address of the timer contract. Should be 0x0 in prod.
     */
    constructor(
        uint256 _liveness,
        address _finderAddress,
        address _timerAddress
    ) public Testable(_timerAddress) {
        finder = FinderInterface(_finderAddress);
        _validateLiveness(_liveness);
        defaultLiveness = _liveness;
    }

    /**
     * @notice Requests a new price.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data representing additional args being passed with the price request.
     * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
     * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
     *               which could make sense if the contract requests and proposes the value in the same call or
     *               provides its own reward system.
     * @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
     * This can be changed with a subsequent call to setBond().
     */
    function requestPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external override nonReentrant() returns (uint256 totalBond) {
        require(getState(msg.sender, identifier, timestamp, ancillaryData) == State.Invalid, "requestPrice: Invalid");
        require(_getIdentifierWhitelist().isIdentifierSupported(identifier), "Unsupported identifier");
        require(_getCollateralWhitelist().isOnWhitelist(address(currency)), "Unsupported currency");
        require(timestamp <= getCurrentTime(), "Timestamp in future");
        require(ancillaryData.length <= ancillaryBytesLimit, "Invalid ancillary data");
        uint256 finalFee = _getStore().computeFinalFee(address(currency)).rawValue;
        requests[_getId(msg.sender, identifier, timestamp, ancillaryData)] = Request({
            proposer: address(0),
            disputer: address(0),
            currency: currency,
            settled: false,
            refundOnDispute: false,
            proposedPrice: 0,
            resolvedPrice: 0,
            expirationTime: 0,
            reward: reward,
            finalFee: finalFee,
            bond: finalFee,
            customLiveness: 0
        });

        if (reward > 0) {
            currency.safeTransferFrom(msg.sender, address(this), reward);
        }

        emit RequestPrice(msg.sender, identifier, timestamp, ancillaryData, address(currency), reward, finalFee);

        // This function returns the initial proposal bond for this request, which can be customized by calling
        // setBond() with the same identifier and timestamp.
        return finalFee.mul(2);
    }

    /**
     * @notice Set the proposal bond associated with a price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param bond custom bond amount to set.
     * @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
     * changed again with a subsequent call to setBond().
     */
    function setBond(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 bond
    ) external override nonReentrant() returns (uint256 totalBond) {
        require(getState(msg.sender, identifier, timestamp, ancillaryData) == State.Requested, "setBond: Requested");
        Request storage request = _getRequest(msg.sender, identifier, timestamp, ancillaryData);
        request.bond = bond;

        // Total bond is the final fee + the newly set bond.
        return bond.add(request.finalFee);
    }

    /**
     * @notice Sets the request to refund the reward if the proposal is disputed. This can help to "hedge" the caller
     * in the event of a dispute-caused delay. Note: in the event of a dispute, the winner still receives the other's
     * bond, so there is still profit to be made even if the reward is refunded.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     */
    function setRefundOnDispute(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external override nonReentrant() {
        require(
            getState(msg.sender, identifier, timestamp, ancillaryData) == State.Requested,
            "setRefundOnDispute: Requested"
        );
        _getRequest(msg.sender, identifier, timestamp, ancillaryData).refundOnDispute = true;
    }

    /**
     * @notice Sets a custom liveness value for the request. Liveness is the amount of time a proposal must wait before
     * being auto-resolved.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param customLiveness new custom liveness.
     */
    function setCustomLiveness(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 customLiveness
    ) external override nonReentrant() {
        require(
            getState(msg.sender, identifier, timestamp, ancillaryData) == State.Requested,
            "setCustomLiveness: Requested"
        );
        _validateLiveness(customLiveness);
        _getRequest(msg.sender, identifier, timestamp, ancillaryData).customLiveness = customLiveness;
    }

    /**
     * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
     * from this proposal. However, any bonds are pulled from the caller.
     * @param proposer address to set as the proposer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePriceFor(
        address proposer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) public override nonReentrant() returns (uint256 totalBond) {
        require(proposer != address(0), "proposer address must be non 0");
        require(
            getState(requester, identifier, timestamp, ancillaryData) == State.Requested,
            "proposePriceFor: Requested"
        );
        Request storage request = _getRequest(requester, identifier, timestamp, ancillaryData);
        request.proposer = proposer;
        request.proposedPrice = proposedPrice;

        // If a custom liveness has been set, use it instead of the default.
        request.expirationTime = getCurrentTime().add(
            request.customLiveness != 0 ? request.customLiveness : defaultLiveness
        );

        totalBond = request.bond.add(request.finalFee);
        if (totalBond > 0) {
            request.currency.safeTransferFrom(msg.sender, address(this), totalBond);
        }

        emit ProposePrice(
            requester,
            proposer,
            identifier,
            timestamp,
            ancillaryData,
            proposedPrice,
            request.expirationTime,
            address(request.currency)
        );

        // Callback.
        if (address(requester).isContract())
            try OptimisticRequester(requester).priceProposed(identifier, timestamp, ancillaryData) {} catch {}
    }

    /**
     * @notice Proposes a price value for an existing price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the proposer's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) external override returns (uint256 totalBond) {
        // Note: re-entrancy guard is done in the inner call.
        return proposePriceFor(msg.sender, requester, identifier, timestamp, ancillaryData, proposedPrice);
    }

    /**
     * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
     * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
     * @param disputer address to set as the disputer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was valid (the proposal was incorrect).
     */
    function disputePriceFor(
        address disputer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public override nonReentrant() returns (uint256 totalBond) {
        require(disputer != address(0), "disputer address must be non 0");
        require(
            getState(requester, identifier, timestamp, ancillaryData) == State.Proposed,
            "disputePriceFor: Proposed"
        );
        Request storage request = _getRequest(requester, identifier, timestamp, ancillaryData);
        request.disputer = disputer;

        uint256 finalFee = request.finalFee;
        uint256 bond = request.bond;
        totalBond = bond.add(finalFee);
        if (totalBond > 0) {
            request.currency.safeTransferFrom(msg.sender, address(this), totalBond);
        }

        StoreInterface store = _getStore();

        // Avoids stack too deep compilation error.
        {
            // Along with the final fee, "burn" part of the loser's bond to ensure that a larger bond always makes it
            // proportionally more expensive to delay the resolution even if the proposer and disputer are the same
            // party.
            uint256 burnedBond = _computeBurnedBond(request);

            // The total fee is the burned bond and the final fee added together.
            uint256 totalFee = finalFee.add(burnedBond);

            if (totalFee > 0) {
                request.currency.safeIncreaseAllowance(address(store), totalFee);
                _getStore().payOracleFeesErc20(address(request.currency), FixedPoint.Unsigned(totalFee));
            }
        }

        _getOracle().requestPrice(identifier, timestamp, _stampAncillaryData(ancillaryData, requester));

        // Compute refund.
        uint256 refund = 0;
        if (request.reward > 0 && request.refundOnDispute) {
            refund = request.reward;
            request.reward = 0;
            request.currency.safeTransfer(requester, refund);
        }

        emit DisputePrice(
            requester,
            request.proposer,
            disputer,
            identifier,
            timestamp,
            ancillaryData,
            request.proposedPrice
        );

        // Callback.
        if (address(requester).isContract())
            try OptimisticRequester(requester).priceDisputed(identifier, timestamp, ancillaryData, refund) {} catch {}
    }

    /**
     * @notice Disputes a price value for an existing price request with an active proposal.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the disputer's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was valid (the proposal was incorrect).
     */
    function disputePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external override returns (uint256 totalBond) {
        // Note: re-entrancy guard is done in the inner call.
        return disputePriceFor(msg.sender, requester, identifier, timestamp, ancillaryData);
    }

    /**
     * @notice Retrieves a price that was previously requested by a caller. Reverts if the request is not settled
     * or settleable. Note: this method is not view so that this call may actually settle the price request if it
     * hasn't been settled.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return resolved price.
     */
    function settleAndGetPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external override nonReentrant() returns (int256) {
        if (getState(msg.sender, identifier, timestamp, ancillaryData) != State.Settled) {
            _settle(msg.sender, identifier, timestamp, ancillaryData);
        }

        return _getRequest(msg.sender, identifier, timestamp, ancillaryData).resolvedPrice;
    }

    /**
     * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
     * the returned bonds as well as additional rewards.
     */
    function settle(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external override nonReentrant() returns (uint256 payout) {
        return _settle(requester, identifier, timestamp, ancillaryData);
    }

    /**
     * @notice Gets the current data structure containing all information about a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the Request data structure.
     */
    function getRequest(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view override returns (Request memory) {
        return _getRequest(requester, identifier, timestamp, ancillaryData);
    }

    /**
     * @notice Computes the current state of a price request. See the State enum for more details.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the State.
     */
    function getState(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view override returns (State) {
        Request storage request = _getRequest(requester, identifier, timestamp, ancillaryData);

        if (address(request.currency) == address(0)) {
            return State.Invalid;
        }

        if (request.proposer == address(0)) {
            return State.Requested;
        }

        if (request.settled) {
            return State.Settled;
        }

        if (request.disputer == address(0)) {
            return request.expirationTime <= getCurrentTime() ? State.Expired : State.Proposed;
        }

        return
            _getOracle().hasPrice(identifier, timestamp, _stampAncillaryData(ancillaryData, requester))
                ? State.Resolved
                : State.Disputed;
    }

    /**
     * @notice Checks if a given request has resolved, expired or been settled (i.e the optimistic oracle has a price).
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return boolean indicating true if price exists and false if not.
     */
    function hasPrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view override returns (bool) {
        State state = getState(requester, identifier, timestamp, ancillaryData);
        return state == State.Settled || state == State.Resolved || state == State.Expired;
    }

    /**
     * @notice Generates stamped ancillary data in the format that it would be used in the case of a price dispute.
     * @param ancillaryData ancillary data of the price being requested.
     * @param requester sender of the initial price request.
     * @return the stampped ancillary bytes.
     */
    function stampAncillaryData(bytes memory ancillaryData, address requester) public pure returns (bytes memory) {
        return _stampAncillaryData(ancillaryData, requester);
    }

    function _getId(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(requester, identifier, timestamp, ancillaryData));
    }

    function _settle(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) private returns (uint256 payout) {
        State state = getState(requester, identifier, timestamp, ancillaryData);

        // Set it to settled so this function can never be entered again.
        Request storage request = _getRequest(requester, identifier, timestamp, ancillaryData);
        request.settled = true;

        if (state == State.Expired) {
            // In the expiry case, just pay back the proposer's bond and final fee along with the reward.
            request.resolvedPrice = request.proposedPrice;
            payout = request.bond.add(request.finalFee).add(request.reward);
            request.currency.safeTransfer(request.proposer, payout);
        } else if (state == State.Resolved) {
            // In the Resolved case, pay either the disputer or the proposer the entire payout (+ bond and reward).
            request.resolvedPrice = _getOracle().getPrice(
                identifier,
                timestamp,
                _stampAncillaryData(ancillaryData, requester)
            );
            bool disputeSuccess = request.resolvedPrice != request.proposedPrice;
            uint256 bond = request.bond;

            // Unburned portion of the loser's bond = 1 - burned bond.
            uint256 unburnedBond = bond.sub(_computeBurnedBond(request));

            // Winner gets:
            // - Their bond back.
            // - The unburned portion of the loser's bond.
            // - Their final fee back.
            // - The request reward (if not already refunded -- if refunded, it will be set to 0).
            payout = bond.add(unburnedBond).add(request.finalFee).add(request.reward);
            request.currency.safeTransfer(disputeSuccess ? request.disputer : request.proposer, payout);
        } else {
            revert("_settle: not settleable");
        }

        emit Settle(
            requester,
            request.proposer,
            request.disputer,
            identifier,
            timestamp,
            ancillaryData,
            request.resolvedPrice,
            payout
        );

        // Callback.
        if (address(requester).isContract())
            try
                OptimisticRequester(requester).priceSettled(identifier, timestamp, ancillaryData, request.resolvedPrice)
            {} catch {}
    }

    function _getRequest(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) private view returns (Request storage) {
        return requests[_getId(requester, identifier, timestamp, ancillaryData)];
    }

    function _computeBurnedBond(Request storage request) private view returns (uint256) {
        // burnedBond = floor(bond / 2)
        return request.bond.div(2);
    }

    function _validateLiveness(uint256 _liveness) private pure {
        require(_liveness < 5200 weeks, "Liveness too large");
        require(_liveness > 0, "Liveness cannot be 0");
    }

    function _getOracle() internal view returns (OracleAncillaryInterface) {
        return OracleAncillaryInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
    }

    function _getCollateralWhitelist() internal view returns (AddressWhitelist) {
        return AddressWhitelist(finder.getImplementationAddress(OracleInterfaces.CollateralWhitelist));
    }

    function _getStore() internal view returns (StoreInterface) {
        return StoreInterface(finder.getImplementationAddress(OracleInterfaces.Store));
    }

    function _getIdentifierWhitelist() internal view returns (IdentifierWhitelistInterface) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }

    // Stamps the ancillary data blob with the optimistic oracle tag denoting what contract requested it.
    function _stampAncillaryData(bytes memory ancillaryData, address requester) internal pure returns (bytes memory) {
        return abi.encodePacked(ancillaryData, "OptimisticOracle", requester);
    }
}

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../common/implementation/FixedPoint.sol";

/**
 * @title Interface that allows financial contracts to pay oracle fees for their use of the system.
 */
interface StoreInterface {
    /**
     * @notice Pays Oracle fees in ETH to the store.
     * @dev To be used by contracts whose margin currency is ETH.
     */
    function payOracleFees() external payable;

    /**
     * @notice Pays oracle fees in the margin currency, erc20Address, to the store.
     * @dev To be used if the margin currency is an ERC20 token rather than ETH.
     * @param erc20Address address of the ERC20 token used to pay the fee.
     * @param amount number of tokens to transfer. An approval for at least this amount must exist.
     */
    function payOracleFeesErc20(address erc20Address, FixedPoint.Unsigned calldata amount) external;

    /**
     * @notice Computes the regular oracle fees that a contract should pay for a period.
     * @param startTime defines the beginning time from which the fee is paid.
     * @param endTime end time until which the fee is paid.
     * @param pfc "profit from corruption", or the maximum amount of margin currency that a
     * token sponsor could extract from the contract through corrupting the price feed in their favor.
     * @return regularFee amount owed for the duration from start to end time for the given pfc.
     * @return latePenalty for paying the fee after the deadline.
     */
    function computeRegularFee(
        uint256 startTime,
        uint256 endTime,
        FixedPoint.Unsigned calldata pfc
    ) external view returns (FixedPoint.Unsigned memory regularFee, FixedPoint.Unsigned memory latePenalty);

    /**
     * @notice Computes the final oracle fees that a contract should pay at settlement.
     * @param currency token used to pay the final fee.
     * @return finalFee amount due.
     */
    function computeFinalFee(address currency) external view returns (FixedPoint.Unsigned memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OracleAncillaryInterface {
    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param time unix timestamp for the price request.
     */

    function requestPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public virtual;

    /**
     * @notice Whether the price for `identifier` and `time` is available.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view virtual returns (bool);

    /**
     * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */

    function getPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view virtual returns (int256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

/**
 * @title Interface for whitelists of supported identifiers that the oracle can provide prices for.
 */
interface IdentifierWhitelistInterface {
    /**
     * @notice Adds the provided identifier as a supported identifier.
     * @dev Price requests using this identifier will succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function addSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Removes the identifier from the whitelist.
     * @dev Price requests using this identifier will no longer succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function removeSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Checks whether an identifier is on the whitelist.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     * @return bool if the identifier is supported (or not).
     */
    function isIdentifierSupported(bytes32 identifier) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OptimisticOracleInterface {
    // Struct representing the state of a price request.
    enum State {
        Invalid, // Never requested.
        Requested, // Requested, no other actions taken.
        Proposed, // Proposed, but not expired or disputed yet.
        Expired, // Proposed, not disputed, past liveness.
        Disputed, // Disputed, but no DVM price returned yet.
        Resolved, // Disputed and DVM price is available.
        Settled // Final price has been set in the contract (can get here from Expired or Resolved).
    }

    // Struct representing a price request.
    struct Request {
        address proposer; // Address of the proposer.
        address disputer; // Address of the disputer.
        IERC20 currency; // ERC20 token used to pay rewards and fees.
        bool settled; // True if the request is settled.
        bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
        int256 proposedPrice; // Price that the proposer submitted.
        int256 resolvedPrice; // Price resolved once the request is settled.
        uint256 expirationTime; // Time at which the request auto-settles without a dispute.
        uint256 reward; // Amount of the currency to pay to the proposer on settlement.
        uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
        uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
        uint256 customLiveness; // Custom liveness value set by the requester.
    }

    // This value must be <= the Voting contract's `ancillaryBytesLimit` value otherwise it is possible
    // that a price can be requested to this contract successfully, but cannot be disputed because the DVM refuses
    // to accept a price request made with ancillary data length of a certain size.
    uint256 public constant ancillaryBytesLimit = 8192;

    /**
     * @notice Requests a new price.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data representing additional args being passed with the price request.
     * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
     * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
     *               which could make sense if the contract requests and proposes the value in the same call or
     *               provides its own reward system.
     * @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
     * This can be changed with a subsequent call to setBond().
     */
    function requestPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Set the proposal bond associated with a price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param bond custom bond amount to set.
     * @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
     * changed again with a subsequent call to setBond().
     */
    function setBond(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 bond
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Sets the request to refund the reward if the proposal is disputed. This can help to "hedge" the caller
     * in the event of a dispute-caused delay. Note: in the event of a dispute, the winner still receives the other's
     * bond, so there is still profit to be made even if the reward is refunded.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     */
    function setRefundOnDispute(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual;

    /**
     * @notice Sets a custom liveness value for the request. Liveness is the amount of time a proposal must wait before
     * being auto-resolved.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param customLiveness new custom liveness.
     */
    function setCustomLiveness(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 customLiveness
    ) external virtual;

    /**
     * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
     * from this proposal. However, any bonds are pulled from the caller.
     * @param proposer address to set as the proposer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePriceFor(
        address proposer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) public virtual returns (uint256 totalBond);

    /**
     * @notice Proposes a price value for an existing price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the proposer's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
     * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
     * @param disputer address to set as the disputer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was value (the proposal was incorrect).
     */
    function disputePriceFor(
        address disputer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public virtual returns (uint256 totalBond);

    /**
     * @notice Disputes a price value for an existing price request with an active proposal.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the disputer's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was valid (the proposal was incorrect).
     */
    function disputePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Retrieves a price that was previously requested by a caller. Reverts if the request is not settled
     * or settleable. Note: this method is not view so that this call may actually settle the price request if it
     * hasn't been settled.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return resolved price.
     */
    function settleAndGetPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (int256);

    /**
     * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
     * the returned bonds as well as additional rewards.
     */
    function settle(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (uint256 payout);

    /**
     * @notice Gets the current data structure containing all information about a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the Request data structure.
     */
    function getRequest(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (Request memory);

    function getState(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (State);

    /**
     * @notice Checks if a given request has resolved or been settled (i.e the optimistic oracle has a price).
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the State.
     */
    function hasPrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library OracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./Timer.sol";

/**
 * @title Base class that provides time overrides, but only if being run in test mode.
 */
abstract contract Testable {
    // If the contract is being run on the test network, then `timerAddress` will be the 0x0 address.
    // Note: this variable should be set on construction and never modified.
    address public timerAddress;

    /**
     * @notice Constructs the Testable contract. Called by child contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(address _timerAddress) internal {
        timerAddress = _timerAddress;
    }

    /**
     * @notice Reverts if not running in test mode.
     */
    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set current Testable time to.
     */
    function setCurrentTime(uint256 time) external onlyIfTest {
        Timer(timerAddress).setCurrentTime(time);
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Timer(timerAddress).getCurrentTime();
        } else {
            return now; // solhint-disable-line not-rely-on-time
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title Library for fixed point arithmetic on uints
 */
library FixedPoint {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_SCALING_FACTOR = 10**18;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    struct Unsigned {
        uint256 rawValue;
    }

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
        return Unsigned(a.mul(FP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 mulRaw = a.rawValue.mul(b.rawValue);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
        if (mod != 0) {
            return Unsigned(mulFloor.add(1));
        } else {
            return Unsigned(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
        uint256 divFloor = aScaled.div(b.rawValue);
        uint256 mod = aScaled.mod(b.rawValue);
        if (mod != 0) {
            return Unsigned(divFloor.add(1));
        } else {
            return Unsigned(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    struct Signed {
        int256 rawValue;
    }

    function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
        require(a.rawValue >= 0, "Negative value provided");
        return Unsigned(uint256(a.rawValue));
    }

    function fromUnsigned(Unsigned memory a) internal pure returns (Signed memory) {
        require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
        return Signed(int256(a.rawValue));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
        return Signed(a.mul(SFP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 mulRaw = a.rawValue.mul(b.rawValue);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(mulTowardsZero.add(valueToAdd));
        } else {
            return Signed(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
        int256 divTowardsZero = aScaled.div(b.rawValue);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % b.rawValue;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(divTowardsZero.add(valueToAdd));
        } else {
            return Signed(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed memory a, uint256 b) internal pure returns (Signed memory output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }
}

pragma solidity ^0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint256 private currentTime;

    constructor() public {
        currentTime = now; // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../OptimisticOracle.sol";

// This is just a test contract to make requests to the optimistic oracle.
contract OptimisticRequesterTest is OptimisticRequester {
    OptimisticOracle optimisticOracle;
    bool public shouldRevert = false;

    // State variables to track incoming calls.
    bytes32 public identifier;
    uint256 public timestamp;
    bytes public ancillaryData;
    uint256 public refund;
    int256 public price;

    constructor(OptimisticOracle _optimisticOracle) public {
        optimisticOracle = _optimisticOracle;
    }

    function requestPrice(
        bytes32 _identifier,
        uint256 _timestamp,
        bytes memory _ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external {
        currency.approve(address(optimisticOracle), reward);
        optimisticOracle.requestPrice(_identifier, _timestamp, _ancillaryData, currency, reward);
    }

    function settleAndGetPrice(
        bytes32 _identifier,
        uint256 _timestamp,
        bytes memory _ancillaryData
    ) external returns (int256) {
        return optimisticOracle.settleAndGetPrice(_identifier, _timestamp, _ancillaryData);
    }

    function setBond(
        bytes32 _identifier,
        uint256 _timestamp,
        bytes memory _ancillaryData,
        uint256 bond
    ) external {
        optimisticOracle.setBond(_identifier, _timestamp, _ancillaryData, bond);
    }

    function setRefundOnDispute(
        bytes32 _identifier,
        uint256 _timestamp,
        bytes memory _ancillaryData
    ) external {
        optimisticOracle.setRefundOnDispute(_identifier, _timestamp, _ancillaryData);
    }

    function setCustomLiveness(
        bytes32 _identifier,
        uint256 _timestamp,
        bytes memory _ancillaryData,
        uint256 customLiveness
    ) external {
        optimisticOracle.setCustomLiveness(_identifier, _timestamp, _ancillaryData, customLiveness);
    }

    function setRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }

    function clearState() external {
        delete identifier;
        delete timestamp;
        delete refund;
        delete price;
    }

    function priceProposed(
        bytes32 _identifier,
        uint256 _timestamp,
        bytes memory _ancillaryData
    ) external override {
        require(!shouldRevert);
        identifier = _identifier;
        timestamp = _timestamp;
        ancillaryData = _ancillaryData;
    }

    function priceDisputed(
        bytes32 _identifier,
        uint256 _timestamp,
        bytes memory _ancillaryData,
        uint256 _refund
    ) external override {
        require(!shouldRevert);
        identifier = _identifier;
        timestamp = _timestamp;
        ancillaryData = _ancillaryData;
        refund = _refund;
    }

    function priceSettled(
        bytes32 _identifier,
        uint256 _timestamp,
        bytes memory _ancillaryData,
        int256 _price
    ) external override {
        require(!shouldRevert);
        identifier = _identifier;
        timestamp = _timestamp;
        ancillaryData = _ancillaryData;
        price = _price;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../common/implementation/FixedPoint.sol";
import "../../common/implementation/MultiRole.sol";
import "../../common/implementation/Withdrawable.sol";
import "../../common/implementation/Testable.sol";
import "../interfaces/StoreInterface.sol";

/**
 * @title An implementation of Store that can accept Oracle fees in ETH or any arbitrary ERC20 token.
 */
contract Store is StoreInterface, Withdrawable, Testable {
    using SafeMath for uint256;
    using FixedPoint for FixedPoint.Unsigned;
    using FixedPoint for uint256;
    using SafeERC20 for IERC20;

    /****************************************
     *    INTERNAL VARIABLES AND STORAGE    *
     ****************************************/

    enum Roles { Owner, Withdrawer }

    FixedPoint.Unsigned public fixedOracleFeePerSecondPerPfc; // Percentage of 1 E.g., .1 is 10% Oracle fee.
    FixedPoint.Unsigned public weeklyDelayFeePerSecondPerPfc; // Percentage of 1 E.g., .1 is 10% weekly delay fee.

    mapping(address => FixedPoint.Unsigned) public finalFees;
    uint256 public constant SECONDS_PER_WEEK = 604800;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event NewFixedOracleFeePerSecondPerPfc(FixedPoint.Unsigned newOracleFee);
    event NewWeeklyDelayFeePerSecondPerPfc(FixedPoint.Unsigned newWeeklyDelayFeePerSecondPerPfc);
    event NewFinalFee(FixedPoint.Unsigned newFinalFee);

    /**
     * @notice Construct the Store contract.
     */
    constructor(
        FixedPoint.Unsigned memory _fixedOracleFeePerSecondPerPfc,
        FixedPoint.Unsigned memory _weeklyDelayFeePerSecondPerPfc,
        address _timerAddress
    ) public Testable(_timerAddress) {
        _createExclusiveRole(uint256(Roles.Owner), uint256(Roles.Owner), msg.sender);
        _createWithdrawRole(uint256(Roles.Withdrawer), uint256(Roles.Owner), msg.sender);
        setFixedOracleFeePerSecondPerPfc(_fixedOracleFeePerSecondPerPfc);
        setWeeklyDelayFeePerSecondPerPfc(_weeklyDelayFeePerSecondPerPfc);
    }

    /****************************************
     *  ORACLE FEE CALCULATION AND PAYMENT  *
     ****************************************/

    /**
     * @notice Pays Oracle fees in ETH to the store.
     * @dev To be used by contracts whose margin currency is ETH.
     */
    function payOracleFees() external payable override {
        require(msg.value > 0, "Value sent can't be zero");
    }

    /**
     * @notice Pays oracle fees in the margin currency, erc20Address, to the store.
     * @dev To be used if the margin currency is an ERC20 token rather than ETH.
     * @param erc20Address address of the ERC20 token used to pay the fee.
     * @param amount number of tokens to transfer. An approval for at least this amount must exist.
     */
    function payOracleFeesErc20(address erc20Address, FixedPoint.Unsigned calldata amount) external override {
        IERC20 erc20 = IERC20(erc20Address);
        require(amount.isGreaterThan(0), "Amount sent can't be zero");
        erc20.safeTransferFrom(msg.sender, address(this), amount.rawValue);
    }

    /**
     * @notice Computes the regular oracle fees that a contract should pay for a period.
     * @dev The late penalty is similar to the regular fee in that is is charged per second over the period between
     * startTime and endTime.
     *
     * The late penalty percentage increases over time as follows:
     *
     * - 0-1 week since startTime: no late penalty
     *
     * - 1-2 weeks since startTime: 1x late penalty percentage is applied
     *
     * - 2-3 weeks since startTime: 2x late penalty percentage is applied
     *
     * - ...
     *
     * @param startTime defines the beginning time from which the fee is paid.
     * @param endTime end time until which the fee is paid.
     * @param pfc "profit from corruption", or the maximum amount of margin currency that a
     * token sponsor could extract from the contract through corrupting the price feed in their favor.
     * @return regularFee amount owed for the duration from start to end time for the given pfc.
     * @return latePenalty penalty percentage, if any, for paying the fee after the deadline.
     */
    function computeRegularFee(
        uint256 startTime,
        uint256 endTime,
        FixedPoint.Unsigned calldata pfc
    ) external view override returns (FixedPoint.Unsigned memory regularFee, FixedPoint.Unsigned memory latePenalty) {
        uint256 timeDiff = endTime.sub(startTime);

        // Multiply by the unscaled `timeDiff` first, to get more accurate results.
        regularFee = pfc.mul(timeDiff).mul(fixedOracleFeePerSecondPerPfc);

        // Compute how long ago the start time was to compute the delay penalty.
        uint256 paymentDelay = getCurrentTime().sub(startTime);

        // Compute the additional percentage (per second) that will be charged because of the penalty.
        // Note: if less than a week has gone by since the startTime, paymentDelay / SECONDS_PER_WEEK will truncate to
        // 0, causing no penalty to be charged.
        FixedPoint.Unsigned memory penaltyPercentagePerSecond =
            weeklyDelayFeePerSecondPerPfc.mul(paymentDelay.div(SECONDS_PER_WEEK));

        // Apply the penaltyPercentagePerSecond to the payment period.
        latePenalty = pfc.mul(timeDiff).mul(penaltyPercentagePerSecond);
    }

    /**
     * @notice Computes the final oracle fees that a contract should pay at settlement.
     * @param currency token used to pay the final fee.
     * @return finalFee amount due denominated in units of `currency`.
     */
    function computeFinalFee(address currency) external view override returns (FixedPoint.Unsigned memory) {
        return finalFees[currency];
    }

    /****************************************
     *   ADMIN STATE MODIFYING FUNCTIONS    *
     ****************************************/

    /**
     * @notice Sets a new oracle fee per second.
     * @param newFixedOracleFeePerSecondPerPfc new fee per second charged to use the oracle.
     */
    function setFixedOracleFeePerSecondPerPfc(FixedPoint.Unsigned memory newFixedOracleFeePerSecondPerPfc)
        public
        onlyRoleHolder(uint256(Roles.Owner))
    {
        // Oracle fees at or over 100% don't make sense.
        require(newFixedOracleFeePerSecondPerPfc.isLessThan(1), "Fee must be < 100% per second.");
        fixedOracleFeePerSecondPerPfc = newFixedOracleFeePerSecondPerPfc;
        emit NewFixedOracleFeePerSecondPerPfc(newFixedOracleFeePerSecondPerPfc);
    }

    /**
     * @notice Sets a new weekly delay fee.
     * @param newWeeklyDelayFeePerSecondPerPfc fee escalation per week of late fee payment.
     */
    function setWeeklyDelayFeePerSecondPerPfc(FixedPoint.Unsigned memory newWeeklyDelayFeePerSecondPerPfc)
        public
        onlyRoleHolder(uint256(Roles.Owner))
    {
        require(newWeeklyDelayFeePerSecondPerPfc.isLessThan(1), "weekly delay fee must be < 100%");
        weeklyDelayFeePerSecondPerPfc = newWeeklyDelayFeePerSecondPerPfc;
        emit NewWeeklyDelayFeePerSecondPerPfc(newWeeklyDelayFeePerSecondPerPfc);
    }

    /**
     * @notice Sets a new final fee for a particular currency.
     * @param currency defines the token currency used to pay the final fee.
     * @param newFinalFee final fee amount.
     */
    function setFinalFee(address currency, FixedPoint.Unsigned memory newFinalFee)
        public
        onlyRoleHolder(uint256(Roles.Owner))
    {
        finalFees[currency] = newFinalFee;
        emit NewFinalFee(newFinalFee);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

library Exclusive {
    struct RoleMembership {
        address member;
    }

    function isMember(RoleMembership storage roleMembership, address memberToCheck) internal view returns (bool) {
        return roleMembership.member == memberToCheck;
    }

    function resetMember(RoleMembership storage roleMembership, address newMember) internal {
        require(newMember != address(0x0), "Cannot set an exclusive role to 0x0");
        roleMembership.member = newMember;
    }

    function getMember(RoleMembership storage roleMembership) internal view returns (address) {
        return roleMembership.member;
    }

    function init(RoleMembership storage roleMembership, address initialMember) internal {
        resetMember(roleMembership, initialMember);
    }
}

library Shared {
    struct RoleMembership {
        mapping(address => bool) members;
    }

    function isMember(RoleMembership storage roleMembership, address memberToCheck) internal view returns (bool) {
        return roleMembership.members[memberToCheck];
    }

    function addMember(RoleMembership storage roleMembership, address memberToAdd) internal {
        require(memberToAdd != address(0x0), "Cannot add 0x0 to a shared role");
        roleMembership.members[memberToAdd] = true;
    }

    function removeMember(RoleMembership storage roleMembership, address memberToRemove) internal {
        roleMembership.members[memberToRemove] = false;
    }

    function init(RoleMembership storage roleMembership, address[] memory initialMembers) internal {
        for (uint256 i = 0; i < initialMembers.length; i++) {
            addMember(roleMembership, initialMembers[i]);
        }
    }
}

/**
 * @title Base class to manage permissions for the derived class.
 */
abstract contract MultiRole {
    using Exclusive for Exclusive.RoleMembership;
    using Shared for Shared.RoleMembership;

    enum RoleType { Invalid, Exclusive, Shared }

    struct Role {
        uint256 managingRole;
        RoleType roleType;
        Exclusive.RoleMembership exclusiveRoleMembership;
        Shared.RoleMembership sharedRoleMembership;
    }

    mapping(uint256 => Role) private roles;

    event ResetExclusiveMember(uint256 indexed roleId, address indexed newMember, address indexed manager);
    event AddedSharedMember(uint256 indexed roleId, address indexed newMember, address indexed manager);
    event RemovedSharedMember(uint256 indexed roleId, address indexed oldMember, address indexed manager);

    /**
     * @notice Reverts unless the caller is a member of the specified roleId.
     */
    modifier onlyRoleHolder(uint256 roleId) {
        require(holdsRole(roleId, msg.sender), "Sender does not hold required role");
        _;
    }

    /**
     * @notice Reverts unless the caller is a member of the manager role for the specified roleId.
     */
    modifier onlyRoleManager(uint256 roleId) {
        require(holdsRole(roles[roleId].managingRole, msg.sender), "Can only be called by a role manager");
        _;
    }

    /**
     * @notice Reverts unless the roleId represents an initialized, exclusive roleId.
     */
    modifier onlyExclusive(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Exclusive, "Must be called on an initialized Exclusive role");
        _;
    }

    /**
     * @notice Reverts unless the roleId represents an initialized, shared roleId.
     */
    modifier onlyShared(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Shared, "Must be called on an initialized Shared role");
        _;
    }

    /**
     * @notice Whether `memberToCheck` is a member of roleId.
     * @dev Reverts if roleId does not correspond to an initialized role.
     * @param roleId the Role to check.
     * @param memberToCheck the address to check.
     * @return True if `memberToCheck` is a member of `roleId`.
     */
    function holdsRole(uint256 roleId, address memberToCheck) public view returns (bool) {
        Role storage role = roles[roleId];
        if (role.roleType == RoleType.Exclusive) {
            return role.exclusiveRoleMembership.isMember(memberToCheck);
        } else if (role.roleType == RoleType.Shared) {
            return role.sharedRoleMembership.isMember(memberToCheck);
        }
        revert("Invalid roleId");
    }

    /**
     * @notice Changes the exclusive role holder of `roleId` to `newMember`.
     * @dev Reverts if the caller is not a member of the managing role for `roleId` or if `roleId` is not an
     * initialized, ExclusiveRole.
     * @param roleId the ExclusiveRole membership to modify.
     * @param newMember the new ExclusiveRole member.
     */
    function resetMember(uint256 roleId, address newMember) public onlyExclusive(roleId) onlyRoleManager(roleId) {
        roles[roleId].exclusiveRoleMembership.resetMember(newMember);
        emit ResetExclusiveMember(roleId, newMember, msg.sender);
    }

    /**
     * @notice Gets the current holder of the exclusive role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, exclusive role.
     * @param roleId the ExclusiveRole membership to check.
     * @return the address of the current ExclusiveRole member.
     */
    function getMember(uint256 roleId) public view onlyExclusive(roleId) returns (address) {
        return roles[roleId].exclusiveRoleMembership.getMember();
    }

    /**
     * @notice Adds `newMember` to the shared role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, SharedRole or if the caller is not a member of the
     * managing role for `roleId`.
     * @param roleId the SharedRole membership to modify.
     * @param newMember the new SharedRole member.
     */
    function addMember(uint256 roleId, address newMember) public onlyShared(roleId) onlyRoleManager(roleId) {
        roles[roleId].sharedRoleMembership.addMember(newMember);
        emit AddedSharedMember(roleId, newMember, msg.sender);
    }

    /**
     * @notice Removes `memberToRemove` from the shared role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, SharedRole or if the caller is not a member of the
     * managing role for `roleId`.
     * @param roleId the SharedRole membership to modify.
     * @param memberToRemove the current SharedRole member to remove.
     */
    function removeMember(uint256 roleId, address memberToRemove) public onlyShared(roleId) onlyRoleManager(roleId) {
        roles[roleId].sharedRoleMembership.removeMember(memberToRemove);
        emit RemovedSharedMember(roleId, memberToRemove, msg.sender);
    }

    /**
     * @notice Removes caller from the role, `roleId`.
     * @dev Reverts if the caller is not a member of the role for `roleId` or if `roleId` is not an
     * initialized, SharedRole.
     * @param roleId the SharedRole membership to modify.
     */
    function renounceMembership(uint256 roleId) public onlyShared(roleId) onlyRoleHolder(roleId) {
        roles[roleId].sharedRoleMembership.removeMember(msg.sender);
        emit RemovedSharedMember(roleId, msg.sender, msg.sender);
    }

    /**
     * @notice Reverts if `roleId` is not initialized.
     */
    modifier onlyValidRole(uint256 roleId) {
        require(roles[roleId].roleType != RoleType.Invalid, "Attempted to use an invalid roleId");
        _;
    }

    /**
     * @notice Reverts if `roleId` is initialized.
     */
    modifier onlyInvalidRole(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Invalid, "Cannot use a pre-existing role");
        _;
    }

    /**
     * @notice Internal method to initialize a shared role, `roleId`, which will be managed by `managingRoleId`.
     * `initialMembers` will be immediately added to the role.
     * @dev Should be called by derived contracts, usually at construction time. Will revert if the role is already
     * initialized.
     */
    function _createSharedRole(
        uint256 roleId,
        uint256 managingRoleId,
        address[] memory initialMembers
    ) internal onlyInvalidRole(roleId) {
        Role storage role = roles[roleId];
        role.roleType = RoleType.Shared;
        role.managingRole = managingRoleId;
        role.sharedRoleMembership.init(initialMembers);
        require(
            roles[managingRoleId].roleType != RoleType.Invalid,
            "Attempted to use an invalid role to manage a shared role"
        );
    }

    /**
     * @notice Internal method to initialize an exclusive role, `roleId`, which will be managed by `managingRoleId`.
     * `initialMember` will be immediately added to the role.
     * @dev Should be called by derived contracts, usually at construction time. Will revert if the role is already
     * initialized.
     */
    function _createExclusiveRole(
        uint256 roleId,
        uint256 managingRoleId,
        address initialMember
    ) internal onlyInvalidRole(roleId) {
        Role storage role = roles[roleId];
        role.roleType = RoleType.Exclusive;
        role.managingRole = managingRoleId;
        role.exclusiveRoleMembership.init(initialMember);
        require(
            roles[managingRoleId].roleType != RoleType.Invalid,
            "Attempted to use an invalid role to manage an exclusive role"
        );
    }
}

/**
 * Withdrawable contract.
 */

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./MultiRole.sol";

/**
 * @title Base contract that allows a specific role to withdraw any ETH and/or ERC20 tokens that the contract holds.
 */
abstract contract Withdrawable is MultiRole {
    using SafeERC20 for IERC20;

    uint256 private roleId;

    /**
     * @notice Withdraws ETH from the contract.
     */
    function withdraw(uint256 amount) external onlyRoleHolder(roleId) {
        Address.sendValue(msg.sender, amount);
    }

    /**
     * @notice Withdraws ERC20 tokens from the contract.
     * @param erc20Address ERC20 token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function withdrawErc20(address erc20Address, uint256 amount) external onlyRoleHolder(roleId) {
        IERC20 erc20 = IERC20(erc20Address);
        erc20.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Internal method that allows derived contracts to create a role for withdrawal.
     * @dev Either this method or `_setWithdrawRole` must be called by the derived class for this contract to function
     * properly.
     * @param newRoleId ID corresponding to role whose members can withdraw.
     * @param managingRoleId ID corresponding to managing role who can modify the withdrawable role's membership.
     * @param withdrawerAddress new manager of withdrawable role.
     */
    function _createWithdrawRole(
        uint256 newRoleId,
        uint256 managingRoleId,
        address withdrawerAddress
    ) internal {
        roleId = newRoleId;
        _createExclusiveRole(newRoleId, managingRoleId, withdrawerAddress);
    }

    /**
     * @notice Internal method that allows derived contracts to choose the role for withdrawal.
     * @dev The role `setRoleId` must exist. Either this method or `_createWithdrawRole` must be
     * called by the derived class for this contract to function properly.
     * @param setRoleId ID corresponding to role whose members can withdraw.
     */
    function _setWithdrawRole(uint256 setRoleId) internal onlyValidRole(setRoleId) {
        roleId = setRoleId;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;
import "../../common/implementation/FixedPoint.sol";
import "../../common/implementation/Testable.sol";
import "../interfaces/OracleInterface.sol";
import "../interfaces/VotingInterface.sol";

// A mock oracle used for testing. Exports the voting & oracle interfaces and events that contain no ancillary data.
abstract contract VotingInterfaceTesting is OracleInterface, VotingInterface, Testable {
    using FixedPoint for FixedPoint.Unsigned;

    // Events, data structures and functions not exported in the base interfaces, used for testing.
    event VoteCommitted(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData
    );

    event EncryptedVote(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        bytes encryptedVote
    );

    event VoteRevealed(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        int256 price,
        bytes ancillaryData,
        uint256 numTokens
    );

    event RewardsRetrieved(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        uint256 numTokens
    );

    event PriceRequestAdded(uint256 indexed roundId, bytes32 indexed identifier, uint256 time);

    event PriceResolved(
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        int256 price,
        bytes ancillaryData
    );

    struct Round {
        uint256 snapshotId; // Voting token snapshot ID for this round.  0 if no snapshot has been taken.
        FixedPoint.Unsigned inflationRate; // Inflation rate set for this round.
        FixedPoint.Unsigned gatPercentage; // Gat rate set for this round.
        uint256 rewardsExpirationTime; // Time that rewards for this round can be claimed until.
    }

    // Represents the status a price request has.
    enum RequestStatus {
        NotRequested, // Was never requested.
        Active, // Is being voted on in the current round.
        Resolved, // Was resolved in a previous round.
        Future // Is scheduled to be voted on in a future round.
    }

    // Only used as a return value in view methods -- never stored in the contract.
    struct RequestState {
        RequestStatus status;
        uint256 lastVotingRound;
    }

    function rounds(uint256 roundId) public view virtual returns (Round memory);

    function getPriceRequestStatuses(VotingInterface.PendingRequest[] memory requests)
        public
        view
        virtual
        returns (RequestState[] memory);

    function getPendingPriceRequestsArray() external view virtual returns (bytes32[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OracleInterface {
    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     */
    function requestPrice(bytes32 identifier, uint256 time) public virtual;

    /**
     * @notice Whether the price for `identifier` and `time` is available.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @return bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(bytes32 identifier, uint256 time) public view virtual returns (bool);

    /**
     * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */
    function getPrice(bytes32 identifier, uint256 time) public view virtual returns (int256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../../common/implementation/FixedPoint.sol";
import "./VotingAncillaryInterface.sol";

/**
 * @title Interface that voters must use to Vote on price request resolutions.
 */
abstract contract VotingInterface {
    struct PendingRequest {
        bytes32 identifier;
        uint256 time;
    }

    // Captures the necessary data for making a commitment.
    // Used as a parameter when making batch commitments.
    // Not used as a data structure for storage.
    struct Commitment {
        bytes32 identifier;
        uint256 time;
        bytes32 hash;
        bytes encryptedVote;
    }

    // Captures the necessary data for revealing a vote.
    // Used as a parameter when making batch reveals.
    // Not used as a data structure for storage.
    struct Reveal {
        bytes32 identifier;
        uint256 time;
        int256 price;
        int256 salt;
    }

    /**
     * @notice Commit a vote for a price request for `identifier` at `time`.
     * @dev `identifier`, `time` must correspond to a price request that's currently in the commit phase.
     * Commits can be changed.
     * @dev Since transaction data is public, the salt will be revealed with the vote. While this is the system’s expected behavior,
     * voters should never reuse salts. If someone else is able to guess the voted price and knows that a salt will be reused, then
     * they can determine the vote pre-reveal.
     * @param identifier uniquely identifies the committed vote. EG BTC/USD price pair.
     * @param time unix timestamp of the price being voted on.
     * @param hash keccak256 hash of the `price`, `salt`, voter `address`, `time`, current `roundId`, and `identifier`.
     */
    function commitVote(
        bytes32 identifier,
        uint256 time,
        bytes32 hash
    ) external virtual;

    /**
     * @notice Submit a batch of commits in a single transaction.
     * @dev Using `encryptedVote` is optional. If included then commitment is stored on chain.
     * Look at `project-root/common/Constants.js` for the tested maximum number of
     * commitments that can fit in one transaction.
     * @param commits array of structs that encapsulate an `identifier`, `time`, `hash` and optional `encryptedVote`.
     */
    function batchCommit(Commitment[] memory commits) public virtual;

    /**
     * @notice commits a vote and logs an event with a data blob, typically an encrypted version of the vote
     * @dev An encrypted version of the vote is emitted in an event `EncryptedVote` to allow off-chain infrastructure to
     * retrieve the commit. The contents of `encryptedVote` are never used on chain: it is purely for convenience.
     * @param identifier unique price pair identifier. Eg: BTC/USD price pair.
     * @param time unix timestamp of for the price request.
     * @param hash keccak256 hash of the price you want to vote for and a `int256 salt`.
     * @param encryptedVote offchain encrypted blob containing the voters amount, time and salt.
     */
    function commitAndEmitEncryptedVote(
        bytes32 identifier,
        uint256 time,
        bytes32 hash,
        bytes memory encryptedVote
    ) public virtual;

    /**
     * @notice snapshot the current round's token balances and lock in the inflation rate and GAT.
     * @dev This function can be called multiple times but each round will only every have one snapshot at the
     * time of calling `_freezeRoundVariables`.
     * @param signature  signature required to prove caller is an EOA to prevent flash loans from being included in the
     * snapshot.
     */
    function snapshotCurrentRound(bytes calldata signature) external virtual;

    /**
     * @notice Reveal a previously committed vote for `identifier` at `time`.
     * @dev The revealed `price`, `salt`, `address`, `time`, `roundId`, and `identifier`, must hash to the latest `hash`
     * that `commitVote()` was called with. Only the committer can reveal their vote.
     * @param identifier voted on in the commit phase. EG BTC/USD price pair.
     * @param time specifies the unix timestamp of the price is being voted on.
     * @param price voted on during the commit phase.
     * @param salt value used to hide the commitment price during the commit phase.
     */
    function revealVote(
        bytes32 identifier,
        uint256 time,
        int256 price,
        int256 salt
    ) public virtual;

    /**
     * @notice Reveal multiple votes in a single transaction.
     * Look at `project-root/common/Constants.js` for the tested maximum number of reveals.
     * that can fit in one transaction.
     * @dev For more information on reveals, review the comment for `revealVote`.
     * @param reveals array of the Reveal struct which contains an identifier, time, price and salt.
     */
    function batchReveal(Reveal[] memory reveals) public virtual;

    /**
     * @notice Gets the queries that are being voted on this round.
     * @return pendingRequests `PendingRequest` array containing identifiers
     * and timestamps for all pending requests.
     */
    function getPendingRequests()
        external
        view
        virtual
        returns (VotingAncillaryInterface.PendingRequestAncillary[] memory);

    /**
     * @notice Returns the current voting phase, as a function of the current time.
     * @return Phase to indicate the current phase. Either { Commit, Reveal, NUM_PHASES_PLACEHOLDER }.
     */
    function getVotePhase() external view virtual returns (VotingAncillaryInterface.Phase);

    /**
     * @notice Returns the current round ID, as a function of the current time.
     * @return uint256 representing the unique round ID.
     */
    function getCurrentRoundId() external view virtual returns (uint256);

    /**
     * @notice Retrieves rewards owed for a set of resolved price requests.
     * @dev Can only retrieve rewards if calling for a valid round and if the
     * call is done within the timeout threshold (not expired).
     * @param voterAddress voter for which rewards will be retrieved. Does not have to be the caller.
     * @param roundId the round from which voting rewards will be retrieved from.
     * @param toRetrieve array of PendingRequests which rewards are retrieved from.
     * @return total amount of rewards returned to the voter.
     */
    function retrieveRewards(
        address voterAddress,
        uint256 roundId,
        PendingRequest[] memory toRetrieve
    ) public virtual returns (FixedPoint.Unsigned memory);

    // Voting Owner functions.

    /**
     * @notice Disables this Voting contract in favor of the migrated one.
     * @dev Can only be called by the contract owner.
     * @param newVotingAddress the newly migrated contract address.
     */
    function setMigrated(address newVotingAddress) external virtual;

    /**
     * @notice Resets the inflation rate. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newInflationRate sets the next round's inflation rate.
     */
    function setInflationRate(FixedPoint.Unsigned memory newInflationRate) public virtual;

    /**
     * @notice Resets the Gat percentage. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newGatPercentage sets the next round's Gat percentage.
     */
    function setGatPercentage(FixedPoint.Unsigned memory newGatPercentage) public virtual;

    /**
     * @notice Resets the rewards expiration timeout.
     * @dev This change only applies to rounds that have not yet begun.
     * @param NewRewardsExpirationTimeout how long a caller can wait before choosing to withdraw their rewards.
     */
    function setRewardsExpirationTimeout(uint256 NewRewardsExpirationTimeout) public virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../../common/implementation/FixedPoint.sol";

/**
 * @title Interface that voters must use to Vote on price request resolutions.
 */
abstract contract VotingAncillaryInterface {
    struct PendingRequestAncillary {
        bytes32 identifier;
        uint256 time;
        bytes ancillaryData;
    }

    // Captures the necessary data for making a commitment.
    // Used as a parameter when making batch commitments.
    // Not used as a data structure for storage.
    struct CommitmentAncillary {
        bytes32 identifier;
        uint256 time;
        bytes ancillaryData;
        bytes32 hash;
        bytes encryptedVote;
    }

    // Captures the necessary data for revealing a vote.
    // Used as a parameter when making batch reveals.
    // Not used as a data structure for storage.
    struct RevealAncillary {
        bytes32 identifier;
        uint256 time;
        int256 price;
        bytes ancillaryData;
        int256 salt;
    }

    // Note: the phases must be in order. Meaning the first enum value must be the first phase, etc.
    // `NUM_PHASES_PLACEHOLDER` is to get the number of phases. It isn't an actual phase, and it should always be last.
    enum Phase { Commit, Reveal, NUM_PHASES_PLACEHOLDER }

    /**
     * @notice Commit a vote for a price request for `identifier` at `time`.
     * @dev `identifier`, `time` must correspond to a price request that's currently in the commit phase.
     * Commits can be changed.
     * @dev Since transaction data is public, the salt will be revealed with the vote. While this is the system’s expected behavior,
     * voters should never reuse salts. If someone else is able to guess the voted price and knows that a salt will be reused, then
     * they can determine the vote pre-reveal.
     * @param identifier uniquely identifies the committed vote. EG BTC/USD price pair.
     * @param time unix timestamp of the price being voted on.
     * @param hash keccak256 hash of the `price`, `salt`, voter `address`, `time`, current `roundId`, and `identifier`.
     */
    function commitVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash
    ) public virtual;

    /**
     * @notice Submit a batch of commits in a single transaction.
     * @dev Using `encryptedVote` is optional. If included then commitment is stored on chain.
     * Look at `project-root/common/Constants.js` for the tested maximum number of
     * commitments that can fit in one transaction.
     * @param commits array of structs that encapsulate an `identifier`, `time`, `hash` and optional `encryptedVote`.
     */
    function batchCommit(CommitmentAncillary[] memory commits) public virtual;

    /**
     * @notice commits a vote and logs an event with a data blob, typically an encrypted version of the vote
     * @dev An encrypted version of the vote is emitted in an event `EncryptedVote` to allow off-chain infrastructure to
     * retrieve the commit. The contents of `encryptedVote` are never used on chain: it is purely for convenience.
     * @param identifier unique price pair identifier. Eg: BTC/USD price pair.
     * @param time unix timestamp of for the price request.
     * @param hash keccak256 hash of the price you want to vote for and a `int256 salt`.
     * @param encryptedVote offchain encrypted blob containing the voters amount, time and salt.
     */
    function commitAndEmitEncryptedVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash,
        bytes memory encryptedVote
    ) public virtual;

    /**
     * @notice snapshot the current round's token balances and lock in the inflation rate and GAT.
     * @dev This function can be called multiple times but each round will only every have one snapshot at the
     * time of calling `_freezeRoundVariables`.
     * @param signature  signature required to prove caller is an EOA to prevent flash loans from being included in the
     * snapshot.
     */
    function snapshotCurrentRound(bytes calldata signature) external virtual;

    /**
     * @notice Reveal a previously committed vote for `identifier` at `time`.
     * @dev The revealed `price`, `salt`, `address`, `time`, `roundId`, and `identifier`, must hash to the latest `hash`
     * that `commitVote()` was called with. Only the committer can reveal their vote.
     * @param identifier voted on in the commit phase. EG BTC/USD price pair.
     * @param time specifies the unix timestamp of the price is being voted on.
     * @param price voted on during the commit phase.
     * @param salt value used to hide the commitment price during the commit phase.
     */
    function revealVote(
        bytes32 identifier,
        uint256 time,
        int256 price,
        bytes memory ancillaryData,
        int256 salt
    ) public virtual;

    /**
     * @notice Reveal multiple votes in a single transaction.
     * Look at `project-root/common/Constants.js` for the tested maximum number of reveals.
     * that can fit in one transaction.
     * @dev For more information on reveals, review the comment for `revealVote`.
     * @param reveals array of the Reveal struct which contains an identifier, time, price and salt.
     */
    function batchReveal(RevealAncillary[] memory reveals) public virtual;

    /**
     * @notice Gets the queries that are being voted on this round.
     * @return pendingRequests `PendingRequest` array containing identifiers
     * and timestamps for all pending requests.
     */
    function getPendingRequests() external view virtual returns (PendingRequestAncillary[] memory);

    /**
     * @notice Returns the current voting phase, as a function of the current time.
     * @return Phase to indicate the current phase. Either { Commit, Reveal, NUM_PHASES_PLACEHOLDER }.
     */
    function getVotePhase() external view virtual returns (Phase);

    /**
     * @notice Returns the current round ID, as a function of the current time.
     * @return uint256 representing the unique round ID.
     */
    function getCurrentRoundId() external view virtual returns (uint256);

    /**
     * @notice Retrieves rewards owed for a set of resolved price requests.
     * @dev Can only retrieve rewards if calling for a valid round and if the
     * call is done within the timeout threshold (not expired).
     * @param voterAddress voter for which rewards will be retrieved. Does not have to be the caller.
     * @param roundId the round from which voting rewards will be retrieved from.
     * @param toRetrieve array of PendingRequests which rewards are retrieved from.
     * @return total amount of rewards returned to the voter.
     */
    function retrieveRewards(
        address voterAddress,
        uint256 roundId,
        PendingRequestAncillary[] memory toRetrieve
    ) public virtual returns (FixedPoint.Unsigned memory);

    // Voting Owner functions.

    /**
     * @notice Disables this Voting contract in favor of the migrated one.
     * @dev Can only be called by the contract owner.
     * @param newVotingAddress the newly migrated contract address.
     */
    function setMigrated(address newVotingAddress) external virtual;

    /**
     * @notice Resets the inflation rate. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newInflationRate sets the next round's inflation rate.
     */
    function setInflationRate(FixedPoint.Unsigned memory newInflationRate) public virtual;

    /**
     * @notice Resets the Gat percentage. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newGatPercentage sets the next round's Gat percentage.
     */
    function setGatPercentage(FixedPoint.Unsigned memory newGatPercentage) public virtual;

    /**
     * @notice Resets the rewards expiration timeout.
     * @dev This change only applies to rounds that have not yet begun.
     * @param NewRewardsExpirationTimeout how long a caller can wait before choosing to withdraw their rewards.
     */
    function setRewardsExpirationTimeout(uint256 NewRewardsExpirationTimeout) public virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/implementation/FixedPoint.sol";
import "../../common/implementation/Testable.sol";
import "../interfaces/FinderInterface.sol";
import "../interfaces/OracleInterface.sol";
import "../interfaces/OracleAncillaryInterface.sol";
import "../interfaces/VotingInterface.sol";
import "../interfaces/VotingAncillaryInterface.sol";
import "../interfaces/IdentifierWhitelistInterface.sol";
import "./Registry.sol";
import "./ResultComputation.sol";
import "./VoteTiming.sol";
import "./VotingToken.sol";
import "./Constants.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

/**
 * @title Voting system for Oracle.
 * @dev Handles receiving and resolving price requests via a commit-reveal voting scheme.
 */
contract Voting is
    Testable,
    Ownable,
    OracleInterface,
    OracleAncillaryInterface, // Interface to support ancillary data with price requests.
    VotingInterface,
    VotingAncillaryInterface // Interface to support ancillary data with voting rounds.
{
    using FixedPoint for FixedPoint.Unsigned;
    using SafeMath for uint256;
    using VoteTiming for VoteTiming.Data;
    using ResultComputation for ResultComputation.Data;

    /****************************************
     *        VOTING DATA STRUCTURES        *
     ****************************************/

    // Identifies a unique price request for which the Oracle will always return the same value.
    // Tracks ongoing votes as well as the result of the vote.
    struct PriceRequest {
        bytes32 identifier;
        uint256 time;
        // A map containing all votes for this price in various rounds.
        mapping(uint256 => VoteInstance) voteInstances;
        // If in the past, this was the voting round where this price was resolved. If current or the upcoming round,
        // this is the voting round where this price will be voted on, but not necessarily resolved.
        uint256 lastVotingRound;
        // The index in the `pendingPriceRequests` that references this PriceRequest. A value of UINT_MAX means that
        // this PriceRequest is resolved and has been cleaned up from `pendingPriceRequests`.
        uint256 index;
        bytes ancillaryData;
    }

    struct VoteInstance {
        // Maps (voterAddress) to their submission.
        mapping(address => VoteSubmission) voteSubmissions;
        // The data structure containing the computed voting results.
        ResultComputation.Data resultComputation;
    }

    struct VoteSubmission {
        // A bytes32 of `0` indicates no commit or a commit that was already revealed.
        bytes32 commit;
        // The hash of the value that was revealed.
        // Note: this is only used for computation of rewards.
        bytes32 revealHash;
    }

    struct Round {
        uint256 snapshotId; // Voting token snapshot ID for this round.  0 if no snapshot has been taken.
        FixedPoint.Unsigned inflationRate; // Inflation rate set for this round.
        FixedPoint.Unsigned gatPercentage; // Gat rate set for this round.
        uint256 rewardsExpirationTime; // Time that rewards for this round can be claimed until.
    }

    // Represents the status a price request has.
    enum RequestStatus {
        NotRequested, // Was never requested.
        Active, // Is being voted on in the current round.
        Resolved, // Was resolved in a previous round.
        Future // Is scheduled to be voted on in a future round.
    }

    // Only used as a return value in view methods -- never stored in the contract.
    struct RequestState {
        RequestStatus status;
        uint256 lastVotingRound;
    }

    /****************************************
     *          INTERNAL TRACKING           *
     ****************************************/

    // Maps round numbers to the rounds.
    mapping(uint256 => Round) public rounds;

    // Maps price request IDs to the PriceRequest struct.
    mapping(bytes32 => PriceRequest) private priceRequests;

    // Price request ids for price requests that haven't yet been marked as resolved.
    // These requests may be for future rounds.
    bytes32[] internal pendingPriceRequests;

    VoteTiming.Data public voteTiming;

    // Percentage of the total token supply that must be used in a vote to
    // create a valid price resolution. 1 == 100%.
    FixedPoint.Unsigned public gatPercentage;

    // Global setting for the rate of inflation per vote. This is the percentage of the snapshotted total supply that
    // should be split among the correct voters.
    // Note: this value is used to set per-round inflation at the beginning of each round. 1 = 100%.
    FixedPoint.Unsigned public inflationRate;

    // Time in seconds from the end of the round in which a price request is
    // resolved that voters can still claim their rewards.
    uint256 public rewardsExpirationTimeout;

    // Reference to the voting token.
    VotingToken public votingToken;

    // Reference to the Finder.
    FinderInterface private finder;

    // If non-zero, this contract has been migrated to this address. All voters and
    // financial contracts should query the new address only.
    address public migratedAddress;

    // Max value of an unsigned integer.
    uint256 private constant UINT_MAX = ~uint256(0);

    // Max length in bytes of ancillary data that can be appended to a price request.
    // As of December 2020, the current Ethereum gas limit is 12.5 million. This requestPrice function's gas primarily
    // comes from computing a Keccak-256 hash in _encodePriceRequest and writing a new PriceRequest to
    // storage. We have empirically determined an ancillary data limit of 8192 bytes that keeps this function
    // well within the gas limit at ~8 million gas. To learn more about the gas limit and EVM opcode costs go here:
    // - https://etherscan.io/chart/gaslimit
    // - https://github.com/djrtwo/evm-opcode-gas-costs
    uint256 public constant ancillaryBytesLimit = 8192;

    bytes32 public snapshotMessageHash = ECDSA.toEthSignedMessageHash(keccak256(bytes("Sign For Snapshot")));

    /***************************************
     *                EVENTS                *
     ****************************************/

    event VoteCommitted(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData
    );

    event EncryptedVote(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        bytes encryptedVote
    );

    event VoteRevealed(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        int256 price,
        bytes ancillaryData,
        uint256 numTokens
    );

    event RewardsRetrieved(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        uint256 numTokens
    );

    event PriceRequestAdded(uint256 indexed roundId, bytes32 indexed identifier, uint256 time);

    event PriceResolved(
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        int256 price,
        bytes ancillaryData
    );

    /**
     * @notice Construct the Voting contract.
     * @param _phaseLength length of the commit and reveal phases in seconds.
     * @param _gatPercentage of the total token supply that must be used in a vote to create a valid price resolution.
     * @param _inflationRate percentage inflation per round used to increase token supply of correct voters.
     * @param _rewardsExpirationTimeout timeout, in seconds, within which rewards must be claimed.
     * @param _votingToken address of the UMA token contract used to commit votes.
     * @param _finder keeps track of all contracts within the system based on their interfaceName.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(
        uint256 _phaseLength,
        FixedPoint.Unsigned memory _gatPercentage,
        FixedPoint.Unsigned memory _inflationRate,
        uint256 _rewardsExpirationTimeout,
        address _votingToken,
        address _finder,
        address _timerAddress
    ) public Testable(_timerAddress) {
        voteTiming.init(_phaseLength);
        require(_gatPercentage.isLessThanOrEqual(1), "GAT percentage must be <= 100%");
        gatPercentage = _gatPercentage;
        inflationRate = _inflationRate;
        votingToken = VotingToken(_votingToken);
        finder = FinderInterface(_finder);
        rewardsExpirationTimeout = _rewardsExpirationTimeout;
    }

    /***************************************
                    MODIFIERS
    ****************************************/

    modifier onlyRegisteredContract() {
        if (migratedAddress != address(0)) {
            require(msg.sender == migratedAddress, "Caller must be migrated address");
        } else {
            Registry registry = Registry(finder.getImplementationAddress(OracleInterfaces.Registry));
            require(registry.isContractRegistered(msg.sender), "Called must be registered");
        }
        _;
    }

    modifier onlyIfNotMigrated() {
        require(migratedAddress == address(0), "Only call this if not migrated");
        _;
    }

    /****************************************
     *  PRICE REQUEST AND ACCESS FUNCTIONS  *
     ****************************************/

    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported. The length of the ancillary data
     * is limited such that this method abides by the EVM transaction gas limit.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     */
    function requestPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public override onlyRegisteredContract() {
        uint256 blockTime = getCurrentTime();
        require(time <= blockTime, "Can only request in past");
        require(_getIdentifierWhitelist().isIdentifierSupported(identifier), "Unsupported identifier request");
        require(ancillaryData.length <= ancillaryBytesLimit, "Invalid ancillary data");

        bytes32 priceRequestId = _encodePriceRequest(identifier, time, ancillaryData);
        PriceRequest storage priceRequest = priceRequests[priceRequestId];
        uint256 currentRoundId = voteTiming.computeCurrentRoundId(blockTime);

        RequestStatus requestStatus = _getRequestStatus(priceRequest, currentRoundId);

        if (requestStatus == RequestStatus.NotRequested) {
            // Price has never been requested.
            // Price requests always go in the next round, so add 1 to the computed current round.
            uint256 nextRoundId = currentRoundId.add(1);

            priceRequests[priceRequestId] = PriceRequest({
                identifier: identifier,
                time: time,
                lastVotingRound: nextRoundId,
                index: pendingPriceRequests.length,
                ancillaryData: ancillaryData
            });
            pendingPriceRequests.push(priceRequestId);
            emit PriceRequestAdded(nextRoundId, identifier, time);
        }
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function requestPrice(bytes32 identifier, uint256 time) public override {
        requestPrice(identifier, time, "");
    }

    /**
     * @notice Whether the price for `identifier` and `time` is available.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp of for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return _hasPrice bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view override onlyRegisteredContract() returns (bool) {
        (bool _hasPrice, , ) = _getPriceOrError(identifier, time, ancillaryData);
        return _hasPrice;
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function hasPrice(bytes32 identifier, uint256 time) public view override returns (bool) {
        return hasPrice(identifier, time, "");
    }

    /**
     * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp of for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */
    function getPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view override onlyRegisteredContract() returns (int256) {
        (bool _hasPrice, int256 price, string memory message) = _getPriceOrError(identifier, time, ancillaryData);

        // If the price wasn't available, revert with the provided message.
        require(_hasPrice, message);
        return price;
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function getPrice(bytes32 identifier, uint256 time) public view override returns (int256) {
        return getPrice(identifier, time, "");
    }

    /**
     * @notice Gets the status of a list of price requests, identified by their identifier and time.
     * @dev If the status for a particular request is NotRequested, the lastVotingRound will always be 0.
     * @param requests array of type PendingRequest which includes an identifier and timestamp for each request.
     * @return requestStates a list, in the same order as the input list, giving the status of each of the specified price requests.
     */
    function getPriceRequestStatuses(PendingRequestAncillary[] memory requests)
        public
        view
        returns (RequestState[] memory)
    {
        RequestState[] memory requestStates = new RequestState[](requests.length);
        uint256 currentRoundId = voteTiming.computeCurrentRoundId(getCurrentTime());
        for (uint256 i = 0; i < requests.length; i++) {
            PriceRequest storage priceRequest =
                _getPriceRequest(requests[i].identifier, requests[i].time, requests[i].ancillaryData);

            RequestStatus status = _getRequestStatus(priceRequest, currentRoundId);

            // If it's an active request, its true lastVotingRound is the current one, even if it hasn't been updated.
            if (status == RequestStatus.Active) {
                requestStates[i].lastVotingRound = currentRoundId;
            } else {
                requestStates[i].lastVotingRound = priceRequest.lastVotingRound;
            }
            requestStates[i].status = status;
        }
        return requestStates;
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function getPriceRequestStatuses(PendingRequest[] memory requests) public view returns (RequestState[] memory) {
        PendingRequestAncillary[] memory requestsAncillary = new PendingRequestAncillary[](requests.length);

        for (uint256 i = 0; i < requests.length; i++) {
            requestsAncillary[i].identifier = requests[i].identifier;
            requestsAncillary[i].time = requests[i].time;
            requestsAncillary[i].ancillaryData = "";
        }
        return getPriceRequestStatuses(requestsAncillary);
    }

    /****************************************
     *            VOTING FUNCTIONS          *
     ****************************************/

    /**
     * @notice Commit a vote for a price request for `identifier` at `time`.
     * @dev `identifier`, `time` must correspond to a price request that's currently in the commit phase.
     * Commits can be changed.
     * @dev Since transaction data is public, the salt will be revealed with the vote. While this is the system’s expected behavior,
     * voters should never reuse salts. If someone else is able to guess the voted price and knows that a salt will be reused, then
     * they can determine the vote pre-reveal.
     * @param identifier uniquely identifies the committed vote. EG BTC/USD price pair.
     * @param time unix timestamp of the price being voted on.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param hash keccak256 hash of the `price`, `salt`, voter `address`, `time`, current `roundId`, and `identifier`.
     */
    function commitVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash
    ) public override onlyIfNotMigrated() {
        require(hash != bytes32(0), "Invalid provided hash");
        // Current time is required for all vote timing queries.
        uint256 blockTime = getCurrentTime();
        require(
            voteTiming.computeCurrentPhase(blockTime) == VotingAncillaryInterface.Phase.Commit,
            "Cannot commit in reveal phase"
        );

        // At this point, the computed and last updated round ID should be equal.
        uint256 currentRoundId = voteTiming.computeCurrentRoundId(blockTime);

        PriceRequest storage priceRequest = _getPriceRequest(identifier, time, ancillaryData);
        require(
            _getRequestStatus(priceRequest, currentRoundId) == RequestStatus.Active,
            "Cannot commit inactive request"
        );

        priceRequest.lastVotingRound = currentRoundId;
        VoteInstance storage voteInstance = priceRequest.voteInstances[currentRoundId];
        voteInstance.voteSubmissions[msg.sender].commit = hash;

        emit VoteCommitted(msg.sender, currentRoundId, identifier, time, ancillaryData);
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function commitVote(
        bytes32 identifier,
        uint256 time,
        bytes32 hash
    ) public override onlyIfNotMigrated() {
        commitVote(identifier, time, "", hash);
    }

    /**
     * @notice Snapshot the current round's token balances and lock in the inflation rate and GAT.
     * @dev This function can be called multiple times, but only the first call per round into this function or `revealVote`
     * will create the round snapshot. Any later calls will be a no-op. Will revert unless called during reveal period.
     * @param signature  signature required to prove caller is an EOA to prevent flash loans from being included in the
     * snapshot.
     */
    function snapshotCurrentRound(bytes calldata signature)
        external
        override(VotingInterface, VotingAncillaryInterface)
        onlyIfNotMigrated()
    {
        uint256 blockTime = getCurrentTime();
        require(voteTiming.computeCurrentPhase(blockTime) == Phase.Reveal, "Only snapshot in reveal phase");
        // Require public snapshot require signature to ensure caller is an EOA.
        require(ECDSA.recover(snapshotMessageHash, signature) == msg.sender, "Signature must match sender");
        uint256 roundId = voteTiming.computeCurrentRoundId(blockTime);
        _freezeRoundVariables(roundId);
    }

    /**
     * @notice Reveal a previously committed vote for `identifier` at `time`.
     * @dev The revealed `price`, `salt`, `address`, `time`, `roundId`, and `identifier`, must hash to the latest `hash`
     * that `commitVote()` was called with. Only the committer can reveal their vote.
     * @param identifier voted on in the commit phase. EG BTC/USD price pair.
     * @param time specifies the unix timestamp of the price being voted on.
     * @param price voted on during the commit phase.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param salt value used to hide the commitment price during the commit phase.
     */
    function revealVote(
        bytes32 identifier,
        uint256 time,
        int256 price,
        bytes memory ancillaryData,
        int256 salt
    ) public override onlyIfNotMigrated() {
        require(voteTiming.computeCurrentPhase(getCurrentTime()) == Phase.Reveal, "Cannot reveal in commit phase");
        // Note: computing the current round is required to disallow people from revealing an old commit after the round is over.
        uint256 roundId = voteTiming.computeCurrentRoundId(getCurrentTime());

        PriceRequest storage priceRequest = _getPriceRequest(identifier, time, ancillaryData);
        VoteInstance storage voteInstance = priceRequest.voteInstances[roundId];
        VoteSubmission storage voteSubmission = voteInstance.voteSubmissions[msg.sender];

        // Scoping to get rid of a stack too deep error.
        {
            // 0 hashes are disallowed in the commit phase, so they indicate a different error.
            // Cannot reveal an uncommitted or previously revealed hash
            require(voteSubmission.commit != bytes32(0), "Invalid hash reveal");
            require(
                keccak256(abi.encodePacked(price, salt, msg.sender, time, ancillaryData, roundId, identifier)) ==
                    voteSubmission.commit,
                "Revealed data != commit hash"
            );
            // To protect against flash loans, we require snapshot be validated as EOA.
            require(rounds[roundId].snapshotId != 0, "Round has no snapshot");
        }

        // Get the frozen snapshotId
        uint256 snapshotId = rounds[roundId].snapshotId;

        delete voteSubmission.commit;

        // Get the voter's snapshotted balance. Since balances are returned pre-scaled by 10**18, we can directly
        // initialize the Unsigned value with the returned uint.
        FixedPoint.Unsigned memory balance = FixedPoint.Unsigned(votingToken.balanceOfAt(msg.sender, snapshotId));

        // Set the voter's submission.
        voteSubmission.revealHash = keccak256(abi.encode(price));

        // Add vote to the results.
        voteInstance.resultComputation.addVote(price, balance);

        emit VoteRevealed(msg.sender, roundId, identifier, time, price, ancillaryData, balance.rawValue);
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function revealVote(
        bytes32 identifier,
        uint256 time,
        int256 price,
        int256 salt
    ) public override {
        revealVote(identifier, time, price, "", salt);
    }

    /**
     * @notice commits a vote and logs an event with a data blob, typically an encrypted version of the vote
     * @dev An encrypted version of the vote is emitted in an event `EncryptedVote` to allow off-chain infrastructure to
     * retrieve the commit. The contents of `encryptedVote` are never used on chain: it is purely for convenience.
     * @param identifier unique price pair identifier. Eg: BTC/USD price pair.
     * @param time unix timestamp of for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param hash keccak256 hash of the price you want to vote for and a `int256 salt`.
     * @param encryptedVote offchain encrypted blob containing the voters amount, time and salt.
     */
    function commitAndEmitEncryptedVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash,
        bytes memory encryptedVote
    ) public override {
        commitVote(identifier, time, ancillaryData, hash);

        uint256 roundId = voteTiming.computeCurrentRoundId(getCurrentTime());
        emit EncryptedVote(msg.sender, roundId, identifier, time, ancillaryData, encryptedVote);
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function commitAndEmitEncryptedVote(
        bytes32 identifier,
        uint256 time,
        bytes32 hash,
        bytes memory encryptedVote
    ) public override {
        commitVote(identifier, time, "", hash);

        commitAndEmitEncryptedVote(identifier, time, "", hash, encryptedVote);
    }

    /**
     * @notice Submit a batch of commits in a single transaction.
     * @dev Using `encryptedVote` is optional. If included then commitment is emitted in an event.
     * Look at `project-root/common/Constants.js` for the tested maximum number of
     * commitments that can fit in one transaction.
     * @param commits struct to encapsulate an `identifier`, `time`, `hash` and optional `encryptedVote`.
     */
    function batchCommit(CommitmentAncillary[] memory commits) public override {
        for (uint256 i = 0; i < commits.length; i++) {
            if (commits[i].encryptedVote.length == 0) {
                commitVote(commits[i].identifier, commits[i].time, commits[i].ancillaryData, commits[i].hash);
            } else {
                commitAndEmitEncryptedVote(
                    commits[i].identifier,
                    commits[i].time,
                    commits[i].ancillaryData,
                    commits[i].hash,
                    commits[i].encryptedVote
                );
            }
        }
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function batchCommit(Commitment[] memory commits) public override {
        CommitmentAncillary[] memory commitsAncillary = new CommitmentAncillary[](commits.length);

        for (uint256 i = 0; i < commits.length; i++) {
            commitsAncillary[i].identifier = commits[i].identifier;
            commitsAncillary[i].time = commits[i].time;
            commitsAncillary[i].ancillaryData = "";
            commitsAncillary[i].hash = commits[i].hash;
            commitsAncillary[i].encryptedVote = commits[i].encryptedVote;
        }
        batchCommit(commitsAncillary);
    }

    /**
     * @notice Reveal multiple votes in a single transaction.
     * Look at `project-root/common/Constants.js` for the tested maximum number of reveals.
     * that can fit in one transaction.
     * @dev For more info on reveals, review the comment for `revealVote`.
     * @param reveals array of the Reveal struct which contains an identifier, time, price and salt.
     */
    function batchReveal(RevealAncillary[] memory reveals) public override {
        for (uint256 i = 0; i < reveals.length; i++) {
            revealVote(
                reveals[i].identifier,
                reveals[i].time,
                reveals[i].price,
                reveals[i].ancillaryData,
                reveals[i].salt
            );
        }
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function batchReveal(Reveal[] memory reveals) public override {
        RevealAncillary[] memory revealsAncillary = new RevealAncillary[](reveals.length);

        for (uint256 i = 0; i < reveals.length; i++) {
            revealsAncillary[i].identifier = reveals[i].identifier;
            revealsAncillary[i].time = reveals[i].time;
            revealsAncillary[i].price = reveals[i].price;
            revealsAncillary[i].ancillaryData = "";
            revealsAncillary[i].salt = reveals[i].salt;
        }
        batchReveal(revealsAncillary);
    }

    /**
     * @notice Retrieves rewards owed for a set of resolved price requests.
     * @dev Can only retrieve rewards if calling for a valid round and if the call is done within the timeout threshold
     * (not expired). Note that a named return value is used here to avoid a stack to deep error.
     * @param voterAddress voter for which rewards will be retrieved. Does not have to be the caller.
     * @param roundId the round from which voting rewards will be retrieved from.
     * @param toRetrieve array of PendingRequests which rewards are retrieved from.
     * @return totalRewardToIssue total amount of rewards returned to the voter.
     */
    function retrieveRewards(
        address voterAddress,
        uint256 roundId,
        PendingRequestAncillary[] memory toRetrieve
    ) public override returns (FixedPoint.Unsigned memory totalRewardToIssue) {
        if (migratedAddress != address(0)) {
            require(msg.sender == migratedAddress, "Can only call from migrated");
        }
        require(roundId < voteTiming.computeCurrentRoundId(getCurrentTime()), "Invalid roundId");

        Round storage round = rounds[roundId];
        bool isExpired = getCurrentTime() > round.rewardsExpirationTime;
        FixedPoint.Unsigned memory snapshotBalance =
            FixedPoint.Unsigned(votingToken.balanceOfAt(voterAddress, round.snapshotId));

        // Compute the total amount of reward that will be issued for each of the votes in the round.
        FixedPoint.Unsigned memory snapshotTotalSupply =
            FixedPoint.Unsigned(votingToken.totalSupplyAt(round.snapshotId));
        FixedPoint.Unsigned memory totalRewardPerVote = round.inflationRate.mul(snapshotTotalSupply);

        // Keep track of the voter's accumulated token reward.
        totalRewardToIssue = FixedPoint.Unsigned(0);

        for (uint256 i = 0; i < toRetrieve.length; i++) {
            PriceRequest storage priceRequest =
                _getPriceRequest(toRetrieve[i].identifier, toRetrieve[i].time, toRetrieve[i].ancillaryData);
            VoteInstance storage voteInstance = priceRequest.voteInstances[priceRequest.lastVotingRound];
            // Only retrieve rewards for votes resolved in same round
            require(priceRequest.lastVotingRound == roundId, "Retrieve for votes same round");

            _resolvePriceRequest(priceRequest, voteInstance);

            if (voteInstance.voteSubmissions[voterAddress].revealHash == 0) {
                continue;
            } else if (isExpired) {
                // Emit a 0 token retrieval on expired rewards.
                emit RewardsRetrieved(
                    voterAddress,
                    roundId,
                    toRetrieve[i].identifier,
                    toRetrieve[i].time,
                    toRetrieve[i].ancillaryData,
                    0
                );
            } else if (
                voteInstance.resultComputation.wasVoteCorrect(voteInstance.voteSubmissions[voterAddress].revealHash)
            ) {
                // The price was successfully resolved during the voter's last voting round, the voter revealed
                // and was correct, so they are eligible for a reward.
                // Compute the reward and add to the cumulative reward.

                FixedPoint.Unsigned memory reward =
                    snapshotBalance.mul(totalRewardPerVote).div(
                        voteInstance.resultComputation.getTotalCorrectlyVotedTokens()
                    );
                totalRewardToIssue = totalRewardToIssue.add(reward);

                // Emit reward retrieval for this vote.
                emit RewardsRetrieved(
                    voterAddress,
                    roundId,
                    toRetrieve[i].identifier,
                    toRetrieve[i].time,
                    toRetrieve[i].ancillaryData,
                    reward.rawValue
                );
            } else {
                // Emit a 0 token retrieval on incorrect votes.
                emit RewardsRetrieved(
                    voterAddress,
                    roundId,
                    toRetrieve[i].identifier,
                    toRetrieve[i].time,
                    toRetrieve[i].ancillaryData,
                    0
                );
            }

            // Delete the submission to capture any refund and clean up storage.
            delete voteInstance.voteSubmissions[voterAddress].revealHash;
        }

        // Issue any accumulated rewards.
        if (totalRewardToIssue.isGreaterThan(0)) {
            require(votingToken.mint(voterAddress, totalRewardToIssue.rawValue), "Voting token issuance failed");
        }
    }

    // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
    function retrieveRewards(
        address voterAddress,
        uint256 roundId,
        PendingRequest[] memory toRetrieve
    ) public override returns (FixedPoint.Unsigned memory) {
        PendingRequestAncillary[] memory toRetrieveAncillary = new PendingRequestAncillary[](toRetrieve.length);

        for (uint256 i = 0; i < toRetrieve.length; i++) {
            toRetrieveAncillary[i].identifier = toRetrieve[i].identifier;
            toRetrieveAncillary[i].time = toRetrieve[i].time;
            toRetrieveAncillary[i].ancillaryData = "";
        }

        return retrieveRewards(voterAddress, roundId, toRetrieveAncillary);
    }

    /****************************************
     *        VOTING GETTER FUNCTIONS       *
     ****************************************/

    /**
     * @notice Gets the queries that are being voted on this round.
     * @return pendingRequests array containing identifiers of type `PendingRequest`.
     * and timestamps for all pending requests.
     */
    function getPendingRequests()
        external
        view
        override(VotingInterface, VotingAncillaryInterface)
        returns (PendingRequestAncillary[] memory)
    {
        uint256 blockTime = getCurrentTime();
        uint256 currentRoundId = voteTiming.computeCurrentRoundId(blockTime);

        // Solidity memory arrays aren't resizable (and reading storage is expensive). Hence this hackery to filter
        // `pendingPriceRequests` only to those requests that have an Active RequestStatus.
        PendingRequestAncillary[] memory unresolved = new PendingRequestAncillary[](pendingPriceRequests.length);
        uint256 numUnresolved = 0;

        for (uint256 i = 0; i < pendingPriceRequests.length; i++) {
            PriceRequest storage priceRequest = priceRequests[pendingPriceRequests[i]];
            if (_getRequestStatus(priceRequest, currentRoundId) == RequestStatus.Active) {
                unresolved[numUnresolved] = PendingRequestAncillary({
                    identifier: priceRequest.identifier,
                    time: priceRequest.time,
                    ancillaryData: priceRequest.ancillaryData
                });
                numUnresolved++;
            }
        }

        PendingRequestAncillary[] memory pendingRequests = new PendingRequestAncillary[](numUnresolved);
        for (uint256 i = 0; i < numUnresolved; i++) {
            pendingRequests[i] = unresolved[i];
        }
        return pendingRequests;
    }

    /**
     * @notice Returns the current voting phase, as a function of the current time.
     * @return Phase to indicate the current phase. Either { Commit, Reveal, NUM_PHASES_PLACEHOLDER }.
     */
    function getVotePhase() external view override(VotingInterface, VotingAncillaryInterface) returns (Phase) {
        return voteTiming.computeCurrentPhase(getCurrentTime());
    }

    /**
     * @notice Returns the current round ID, as a function of the current time.
     * @return uint256 representing the unique round ID.
     */
    function getCurrentRoundId() external view override(VotingInterface, VotingAncillaryInterface) returns (uint256) {
        return voteTiming.computeCurrentRoundId(getCurrentTime());
    }

    /****************************************
     *        OWNER ADMIN FUNCTIONS         *
     ****************************************/

    /**
     * @notice Disables this Voting contract in favor of the migrated one.
     * @dev Can only be called by the contract owner.
     * @param newVotingAddress the newly migrated contract address.
     */
    function setMigrated(address newVotingAddress)
        external
        override(VotingInterface, VotingAncillaryInterface)
        onlyOwner
    {
        migratedAddress = newVotingAddress;
    }

    /**
     * @notice Resets the inflation rate. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newInflationRate sets the next round's inflation rate.
     */
    function setInflationRate(FixedPoint.Unsigned memory newInflationRate)
        public
        override(VotingInterface, VotingAncillaryInterface)
        onlyOwner
    {
        inflationRate = newInflationRate;
    }

    /**
     * @notice Resets the Gat percentage. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newGatPercentage sets the next round's Gat percentage.
     */
    function setGatPercentage(FixedPoint.Unsigned memory newGatPercentage)
        public
        override(VotingInterface, VotingAncillaryInterface)
        onlyOwner
    {
        require(newGatPercentage.isLessThan(1), "GAT percentage must be < 100%");
        gatPercentage = newGatPercentage;
    }

    /**
     * @notice Resets the rewards expiration timeout.
     * @dev This change only applies to rounds that have not yet begun.
     * @param NewRewardsExpirationTimeout how long a caller can wait before choosing to withdraw their rewards.
     */
    function setRewardsExpirationTimeout(uint256 NewRewardsExpirationTimeout)
        public
        override(VotingInterface, VotingAncillaryInterface)
        onlyOwner
    {
        rewardsExpirationTimeout = NewRewardsExpirationTimeout;
    }

    /****************************************
     *    PRIVATE AND INTERNAL FUNCTIONS    *
     ****************************************/

    // Returns the price for a given identifer. Three params are returns: bool if there was an error, int to represent
    // the resolved price and a string which is filled with an error message, if there was an error or "".
    function _getPriceOrError(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    )
        private
        view
        returns (
            bool,
            int256,
            string memory
        )
    {
        PriceRequest storage priceRequest = _getPriceRequest(identifier, time, ancillaryData);
        uint256 currentRoundId = voteTiming.computeCurrentRoundId(getCurrentTime());

        RequestStatus requestStatus = _getRequestStatus(priceRequest, currentRoundId);
        if (requestStatus == RequestStatus.Active) {
            return (false, 0, "Current voting round not ended");
        } else if (requestStatus == RequestStatus.Resolved) {
            VoteInstance storage voteInstance = priceRequest.voteInstances[priceRequest.lastVotingRound];
            (, int256 resolvedPrice) =
                voteInstance.resultComputation.getResolvedPrice(_computeGat(priceRequest.lastVotingRound));
            return (true, resolvedPrice, "");
        } else if (requestStatus == RequestStatus.Future) {
            return (false, 0, "Price is still to be voted on");
        } else {
            return (false, 0, "Price was never requested");
        }
    }

    function _getPriceRequest(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) private view returns (PriceRequest storage) {
        return priceRequests[_encodePriceRequest(identifier, time, ancillaryData)];
    }

    function _encodePriceRequest(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(identifier, time, ancillaryData));
    }

    function _freezeRoundVariables(uint256 roundId) private {
        Round storage round = rounds[roundId];
        // Only on the first reveal should the snapshot be captured for that round.
        if (round.snapshotId == 0) {
            // There is no snapshot ID set, so create one.
            round.snapshotId = votingToken.snapshot();

            // Set the round inflation rate to the current global inflation rate.
            rounds[roundId].inflationRate = inflationRate;

            // Set the round gat percentage to the current global gat rate.
            rounds[roundId].gatPercentage = gatPercentage;

            // Set the rewards expiration time based on end of time of this round and the current global timeout.
            rounds[roundId].rewardsExpirationTime = voteTiming.computeRoundEndTime(roundId).add(
                rewardsExpirationTimeout
            );
        }
    }

    function _resolvePriceRequest(PriceRequest storage priceRequest, VoteInstance storage voteInstance) private {
        if (priceRequest.index == UINT_MAX) {
            return;
        }
        (bool isResolved, int256 resolvedPrice) =
            voteInstance.resultComputation.getResolvedPrice(_computeGat(priceRequest.lastVotingRound));
        require(isResolved, "Can't resolve unresolved request");

        // Delete the resolved price request from pendingPriceRequests.
        uint256 lastIndex = pendingPriceRequests.length - 1;
        PriceRequest storage lastPriceRequest = priceRequests[pendingPriceRequests[lastIndex]];
        lastPriceRequest.index = priceRequest.index;
        pendingPriceRequests[priceRequest.index] = pendingPriceRequests[lastIndex];
        pendingPriceRequests.pop();

        priceRequest.index = UINT_MAX;
        emit PriceResolved(
            priceRequest.lastVotingRound,
            priceRequest.identifier,
            priceRequest.time,
            resolvedPrice,
            priceRequest.ancillaryData
        );
    }

    function _computeGat(uint256 roundId) private view returns (FixedPoint.Unsigned memory) {
        uint256 snapshotId = rounds[roundId].snapshotId;
        if (snapshotId == 0) {
            // No snapshot - return max value to err on the side of caution.
            return FixedPoint.Unsigned(UINT_MAX);
        }

        // Grab the snapshotted supply from the voting token. It's already scaled by 10**18, so we can directly
        // initialize the Unsigned value with the returned uint.
        FixedPoint.Unsigned memory snapshottedSupply = FixedPoint.Unsigned(votingToken.totalSupplyAt(snapshotId));

        // Multiply the total supply at the snapshot by the gatPercentage to get the GAT in number of tokens.
        return snapshottedSupply.mul(rounds[roundId].gatPercentage);
    }

    function _getRequestStatus(PriceRequest storage priceRequest, uint256 currentRoundId)
        private
        view
        returns (RequestStatus)
    {
        if (priceRequest.lastVotingRound == 0) {
            return RequestStatus.NotRequested;
        } else if (priceRequest.lastVotingRound < currentRoundId) {
            VoteInstance storage voteInstance = priceRequest.voteInstances[priceRequest.lastVotingRound];
            (bool isResolved, ) =
                voteInstance.resultComputation.getResolvedPrice(_computeGat(priceRequest.lastVotingRound));
            return isResolved ? RequestStatus.Resolved : RequestStatus.Active;
        } else if (priceRequest.lastVotingRound == currentRoundId) {
            return RequestStatus.Active;
        } else {
            // Means than priceRequest.lastVotingRound > currentRoundId
            return RequestStatus.Future;
        }
    }

    function _getIdentifierWhitelist() private view returns (IdentifierWhitelistInterface supportedIdentifiers) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/implementation/MultiRole.sol";
import "../interfaces/RegistryInterface.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Registry for financial contracts and approved financial contract creators.
 * @dev Maintains a whitelist of financial contract creators that are allowed
 * to register new financial contracts and stores party members of a financial contract.
 */
contract Registry is RegistryInterface, MultiRole {
    using SafeMath for uint256;

    /****************************************
     *    INTERNAL VARIABLES AND STORAGE    *
     ****************************************/

    enum Roles {
        Owner, // The owner manages the set of ContractCreators.
        ContractCreator // Can register financial contracts.
    }

    // This enum is required because a `WasValid` state is required
    // to ensure that financial contracts cannot be re-registered.
    enum Validity { Invalid, Valid }

    // Local information about a contract.
    struct FinancialContract {
        Validity valid;
        uint128 index;
    }

    struct Party {
        address[] contracts; // Each financial contract address is stored in this array.
        // The address of each financial contract is mapped to its index for constant time look up and deletion.
        mapping(address => uint256) contractIndex;
    }

    // Array of all contracts that are approved to use the UMA Oracle.
    address[] public registeredContracts;

    // Map of financial contract contracts to the associated FinancialContract struct.
    mapping(address => FinancialContract) public contractMap;

    // Map each party member to their their associated Party struct.
    mapping(address => Party) private partyMap;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event NewContractRegistered(address indexed contractAddress, address indexed creator, address[] parties);
    event PartyAdded(address indexed contractAddress, address indexed party);
    event PartyRemoved(address indexed contractAddress, address indexed party);

    /**
     * @notice Construct the Registry contract.
     */
    constructor() public {
        _createExclusiveRole(uint256(Roles.Owner), uint256(Roles.Owner), msg.sender);
        // Start with no contract creators registered.
        _createSharedRole(uint256(Roles.ContractCreator), uint256(Roles.Owner), new address[](0));
    }

    /****************************************
     *        REGISTRATION FUNCTIONS        *
     ****************************************/

    /**
     * @notice Registers a new financial contract.
     * @dev Only authorized contract creators can call this method.
     * @param parties array of addresses who become parties in the contract.
     * @param contractAddress address of the contract against which the parties are registered.
     */
    function registerContract(address[] calldata parties, address contractAddress)
        external
        override
        onlyRoleHolder(uint256(Roles.ContractCreator))
    {
        FinancialContract storage financialContract = contractMap[contractAddress];
        require(contractMap[contractAddress].valid == Validity.Invalid, "Can only register once");

        // Store contract address as a registered contract.
        registeredContracts.push(contractAddress);

        // No length check necessary because we should never hit (2^127 - 1) contracts.
        financialContract.index = uint128(registeredContracts.length.sub(1));

        // For all parties in the array add them to the contract's parties.
        financialContract.valid = Validity.Valid;
        for (uint256 i = 0; i < parties.length; i = i.add(1)) {
            _addPartyToContract(parties[i], contractAddress);
        }

        emit NewContractRegistered(contractAddress, msg.sender, parties);
    }

    /**
     * @notice Adds a party member to the calling contract.
     * @dev msg.sender will be used to determine the contract that this party is added to.
     * @param party new party for the calling contract.
     */
    function addPartyToContract(address party) external override {
        address contractAddress = msg.sender;
        require(contractMap[contractAddress].valid == Validity.Valid, "Can only add to valid contract");

        _addPartyToContract(party, contractAddress);
    }

    /**
     * @notice Removes a party member from the calling contract.
     * @dev msg.sender will be used to determine the contract that this party is removed from.
     * @param partyAddress address to be removed from the calling contract.
     */
    function removePartyFromContract(address partyAddress) external override {
        address contractAddress = msg.sender;
        Party storage party = partyMap[partyAddress];
        uint256 numberOfContracts = party.contracts.length;

        require(numberOfContracts != 0, "Party has no contracts");
        require(contractMap[contractAddress].valid == Validity.Valid, "Remove only from valid contract");
        require(isPartyMemberOfContract(partyAddress, contractAddress), "Can only remove existing party");

        // Index of the current location of the contract to remove.
        uint256 deleteIndex = party.contractIndex[contractAddress];

        // Store the last contract's address to update the lookup map.
        address lastContractAddress = party.contracts[numberOfContracts - 1];

        // Swap the contract to be removed with the last contract.
        party.contracts[deleteIndex] = lastContractAddress;

        // Update the lookup index with the new location.
        party.contractIndex[lastContractAddress] = deleteIndex;

        // Pop the last contract from the array and update the lookup map.
        party.contracts.pop();
        delete party.contractIndex[contractAddress];

        emit PartyRemoved(contractAddress, partyAddress);
    }

    /****************************************
     *         REGISTRY STATE GETTERS       *
     ****************************************/

    /**
     * @notice Returns whether the contract has been registered with the registry.
     * @dev If it is registered, it is an authorized participant in the UMA system.
     * @param contractAddress address of the financial contract.
     * @return bool indicates whether the contract is registered.
     */
    function isContractRegistered(address contractAddress) external view override returns (bool) {
        return contractMap[contractAddress].valid == Validity.Valid;
    }

    /**
     * @notice Returns a list of all contracts that are associated with a particular party.
     * @param party address of the party.
     * @return an array of the contracts the party is registered to.
     */
    function getRegisteredContracts(address party) external view override returns (address[] memory) {
        return partyMap[party].contracts;
    }

    /**
     * @notice Returns all registered contracts.
     * @return all registered contract addresses within the system.
     */
    function getAllRegisteredContracts() external view override returns (address[] memory) {
        return registeredContracts;
    }

    /**
     * @notice checks if an address is a party of a contract.
     * @param party party to check.
     * @param contractAddress address to check against the party.
     * @return bool indicating if the address is a party of the contract.
     */
    function isPartyMemberOfContract(address party, address contractAddress) public view override returns (bool) {
        uint256 index = partyMap[party].contractIndex[contractAddress];
        return partyMap[party].contracts.length > index && partyMap[party].contracts[index] == contractAddress;
    }

    /****************************************
     *           INTERNAL FUNCTIONS         *
     ****************************************/

    function _addPartyToContract(address party, address contractAddress) internal {
        require(!isPartyMemberOfContract(party, contractAddress), "Can only register a party once");
        uint256 contractIndex = partyMap[party].contracts.length;
        partyMap[party].contracts.push(contractAddress);
        partyMap[party].contractIndex[contractAddress] = contractIndex;

        emit PartyAdded(contractAddress, party);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../../common/implementation/FixedPoint.sol";

/**
 * @title Computes vote results.
 * @dev The result is the mode of the added votes. Otherwise, the vote is unresolved.
 */
library ResultComputation {
    using FixedPoint for FixedPoint.Unsigned;

    /****************************************
     *   INTERNAL LIBRARY DATA STRUCTURE    *
     ****************************************/

    struct Data {
        // Maps price to number of tokens that voted for that price.
        mapping(int256 => FixedPoint.Unsigned) voteFrequency;
        // The total votes that have been added.
        FixedPoint.Unsigned totalVotes;
        // The price that is the current mode, i.e., the price with the highest frequency in `voteFrequency`.
        int256 currentMode;
    }

    /****************************************
     *            VOTING FUNCTIONS          *
     ****************************************/

    /**
     * @notice Adds a new vote to be used when computing the result.
     * @param data contains information to which the vote is applied.
     * @param votePrice value specified in the vote for the given `numberTokens`.
     * @param numberTokens number of tokens that voted on the `votePrice`.
     */
    function addVote(
        Data storage data,
        int256 votePrice,
        FixedPoint.Unsigned memory numberTokens
    ) internal {
        data.totalVotes = data.totalVotes.add(numberTokens);
        data.voteFrequency[votePrice] = data.voteFrequency[votePrice].add(numberTokens);
        if (
            votePrice != data.currentMode &&
            data.voteFrequency[votePrice].isGreaterThan(data.voteFrequency[data.currentMode])
        ) {
            data.currentMode = votePrice;
        }
    }

    /****************************************
     *        VOTING STATE GETTERS          *
     ****************************************/

    /**
     * @notice Returns whether the result is resolved, and if so, what value it resolved to.
     * @dev `price` should be ignored if `isResolved` is false.
     * @param data contains information against which the `minVoteThreshold` is applied.
     * @param minVoteThreshold min (exclusive) number of tokens that must have voted for the result to be valid. Can be
     * used to enforce a minimum voter participation rate, regardless of how the votes are distributed.
     * @return isResolved indicates if the price has been resolved correctly.
     * @return price the price that the dvm resolved to.
     */
    function getResolvedPrice(Data storage data, FixedPoint.Unsigned memory minVoteThreshold)
        internal
        view
        returns (bool isResolved, int256 price)
    {
        FixedPoint.Unsigned memory modeThreshold = FixedPoint.fromUnscaledUint(50).div(100);

        if (
            data.totalVotes.isGreaterThan(minVoteThreshold) &&
            data.voteFrequency[data.currentMode].div(data.totalVotes).isGreaterThan(modeThreshold)
        ) {
            // `modeThreshold` and `minVoteThreshold` are exceeded, so the current mode is the resolved price.
            isResolved = true;
            price = data.currentMode;
        } else {
            isResolved = false;
        }
    }

    /**
     * @notice Checks whether a `voteHash` is considered correct.
     * @dev Should only be called after a vote is resolved, i.e., via `getResolvedPrice`.
     * @param data contains information against which the `voteHash` is checked.
     * @param voteHash committed hash submitted by the voter.
     * @return bool true if the vote was correct.
     */
    function wasVoteCorrect(Data storage data, bytes32 voteHash) internal view returns (bool) {
        return voteHash == keccak256(abi.encode(data.currentMode));
    }

    /**
     * @notice Gets the total number of tokens whose votes are considered correct.
     * @dev Should only be called after a vote is resolved, i.e., via `getResolvedPrice`.
     * @param data contains all votes against which the correctly voted tokens are counted.
     * @return FixedPoint.Unsigned which indicates the frequency of the correctly voted tokens.
     */
    function getTotalCorrectlyVotedTokens(Data storage data) internal view returns (FixedPoint.Unsigned memory) {
        return data.voteFrequency[data.currentMode];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/VotingInterface.sol";

/**
 * @title Library to compute rounds and phases for an equal length commit-reveal voting cycle.
 */
library VoteTiming {
    using SafeMath for uint256;

    struct Data {
        uint256 phaseLength;
    }

    /**
     * @notice Initializes the data object. Sets the phase length based on the input.
     */
    function init(Data storage data, uint256 phaseLength) internal {
        // This should have a require message but this results in an internal Solidity error.
        require(phaseLength > 0);
        data.phaseLength = phaseLength;
    }

    /**
     * @notice Computes the roundID based off the current time as floor(timestamp/roundLength).
     * @dev The round ID depends on the global timestamp but not on the lifetime of the system.
     * The consequence is that the initial round ID starts at an arbitrary number (that increments, as expected, for subsequent rounds) instead of zero or one.
     * @param data input data object.
     * @param currentTime input unix timestamp used to compute the current roundId.
     * @return roundId defined as a function of the currentTime and `phaseLength` from `data`.
     */
    function computeCurrentRoundId(Data storage data, uint256 currentTime) internal view returns (uint256) {
        uint256 roundLength = data.phaseLength.mul(uint256(VotingAncillaryInterface.Phase.NUM_PHASES_PLACEHOLDER));
        return currentTime.div(roundLength);
    }

    /**
     * @notice compute the round end time as a function of the round Id.
     * @param data input data object.
     * @param roundId uniquely identifies the current round.
     * @return timestamp unix time of when the current round will end.
     */
    function computeRoundEndTime(Data storage data, uint256 roundId) internal view returns (uint256) {
        uint256 roundLength = data.phaseLength.mul(uint256(VotingAncillaryInterface.Phase.NUM_PHASES_PLACEHOLDER));
        return roundLength.mul(roundId.add(1));
    }

    /**
     * @notice Computes the current phase based only on the current time.
     * @param data input data object.
     * @param currentTime input unix timestamp used to compute the current roundId.
     * @return current voting phase based on current time and vote phases configuration.
     */
    function computeCurrentPhase(Data storage data, uint256 currentTime)
        internal
        view
        returns (VotingAncillaryInterface.Phase)
    {
        // This employs some hacky casting. We could make this an if-statement if we're worried about type safety.
        return
            VotingAncillaryInterface.Phase(
                currentTime.div(data.phaseLength).mod(uint256(VotingAncillaryInterface.Phase.NUM_PHASES_PLACEHOLDER))
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../../common/implementation/ExpandedERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";

/**
 * @title Ownership of this token allows a voter to respond to price requests.
 * @dev Supports snapshotting and allows the Oracle to mint new tokens as rewards.
 */
contract VotingToken is ExpandedERC20, ERC20Snapshot {
    /**
     * @notice Constructs the VotingToken.
     */
    constructor() public ExpandedERC20("UMA Voting Token v1", "UMA", 18) {}

    /**
     * @notice Creates a new snapshot ID.
     * @return uint256 Thew new snapshot ID.
     */
    function snapshot() external returns (uint256) {
        return _snapshot();
    }

    // _transfer, _mint and _burn are ERC20 internal methods that are overridden by ERC20Snapshot,
    // therefore the compiler will complain that VotingToken must override these methods
    // because the two base classes (ERC20 and ERC20Snapshot) both define the same functions

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Snapshot) {
        super._transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal override(ERC20, ERC20Snapshot) {
        super._mint(account, value);
    }

    function _burn(address account, uint256 value) internal override(ERC20, ERC20Snapshot) {
        super._burn(account, value);
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

/**
 * @title Interface for a registry of contracts and contract creators.
 */
interface RegistryInterface {
    /**
     * @notice Registers a new contract.
     * @dev Only authorized contract creators can call this method.
     * @param parties an array of addresses who become parties in the contract.
     * @param contractAddress defines the address of the deployed contract.
     */
    function registerContract(address[] calldata parties, address contractAddress) external;

    /**
     * @notice Returns whether the contract has been registered with the registry.
     * @dev If it is registered, it is an authorized participant in the UMA system.
     * @param contractAddress address of the contract.
     * @return bool indicates whether the contract is registered.
     */
    function isContractRegistered(address contractAddress) external view returns (bool);

    /**
     * @notice Returns a list of all contracts that are associated with a particular party.
     * @param party address of the party.
     * @return an array of the contracts the party is registered to.
     */
    function getRegisteredContracts(address party) external view returns (address[] memory);

    /**
     * @notice Returns all registered contracts.
     * @return all registered contract addresses within the system.
     */
    function getAllRegisteredContracts() external view returns (address[] memory);

    /**
     * @notice Adds a party to the calling contract.
     * @dev msg.sender must be the contract to which the party member is added.
     * @param party address to be added to the contract.
     */
    function addPartyToContract(address party) external;

    /**
     * @notice Removes a party member to the calling contract.
     * @dev msg.sender must be the contract to which the party member is added.
     * @param party address to be removed from the contract.
     */
    function removePartyFromContract(address party) external;

    /**
     * @notice checks if an address is a party in a contract.
     * @param party party to check.
     * @param contractAddress address to check against the party.
     * @return bool indicating if the address is a party of the contract.
     */
    function isPartyMemberOfContract(address party, address contractAddress) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MultiRole.sol";
import "../interfaces/ExpandedIERC20.sol";

/**
 * @title An ERC20 with permissioned burning and minting. The contract deployer will initially
 * be the owner who is capable of adding new roles.
 */
contract ExpandedERC20 is ExpandedIERC20, ERC20, MultiRole {
    enum Roles {
        // Can set the minter and burner.
        Owner,
        // Addresses that can mint new tokens.
        Minter,
        // Addresses that can burn tokens that address owns.
        Burner
    }

    /**
     * @notice Constructs the ExpandedERC20.
     * @param _tokenName The name which describes the new token.
     * @param _tokenSymbol The ticker abbreviation of the name. Ideally < 5 chars.
     * @param _tokenDecimals The number of decimals to define token precision.
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) public ERC20(_tokenName, _tokenSymbol) {
        _setupDecimals(_tokenDecimals);
        _createExclusiveRole(uint256(Roles.Owner), uint256(Roles.Owner), msg.sender);
        _createSharedRole(uint256(Roles.Minter), uint256(Roles.Owner), new address[](0));
        _createSharedRole(uint256(Roles.Burner), uint256(Roles.Owner), new address[](0));
    }

    /**
     * @dev Mints `value` tokens to `recipient`, returning true on success.
     * @param recipient address to mint to.
     * @param value amount of tokens to mint.
     * @return True if the mint succeeded, or False.
     */
    function mint(address recipient, uint256 value)
        external
        override
        onlyRoleHolder(uint256(Roles.Minter))
        returns (bool)
    {
        _mint(recipient, value);
        return true;
    }

    /**
     * @dev Burns `value` tokens owned by `msg.sender`.
     * @param value amount of tokens to burn.
     */
    function burn(uint256 value) external override onlyRoleHolder(uint256(Roles.Burner)) {
        _burn(msg.sender, value);
    }

    /**
     * @notice Add Minter role to account.
     * @dev The caller must have the Owner role.
     * @param account The address to which the Minter role is added.
     */
    function addMinter(address account) external virtual override {
        addMember(uint256(Roles.Minter), account);
    }

    /**
     * @notice Add Burner role to account.
     * @dev The caller must have the Owner role.
     * @param account The address to which the Burner role is added.
     */
    function addBurner(address account) external virtual override {
        addMember(uint256(Roles.Burner), account);
    }

    /**
     * @notice Reset Owner role to account.
     * @dev The caller must have the Owner role.
     * @param account The new holder of the Owner role.
     */
    function resetOwner(address account) external virtual override {
        resetMember(uint256(Roles.Owner), account);
    }
}

pragma solidity ^0.6.0;

import "../../math/SafeMath.sol";
import "../../utils/Arrays.sol";
import "../../utils/Counters.sol";
import "./ERC20.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */
abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using SafeMath for uint256;
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping (address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // _transfer, _mint and _burn are the only functions where the balances are modified, so it is there that the
    // snapshots are updated. Note that the update happens _before_ the balance change, with the pre-modified value.
    // The same is true for the total supply and _mint and _burn.
    function _transfer(address from, address to, uint256 value) internal virtual override {
        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);

        super._transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal virtual override {
        _updateAccountSnapshot(account);
        _updateTotalSupplySnapshot();

        super._mint(account, value);
    }

    function _burn(address account, uint256 value) internal virtual override {
        _updateAccountSnapshot(account);
        _updateTotalSupplySnapshot();

        super._burn(account, value);
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private view returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        // solhint-disable-next-line max-line-length
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ERC20 interface that includes burn and mint methods.
 */
abstract contract ExpandedIERC20 is IERC20 {
    /**
     * @notice Burns a specific amount of the caller's tokens.
     * @dev Only burns the caller's tokens, so it is safe to leave this method permissionless.
     */
    function burn(uint256 value) external virtual;

    /**
     * @notice Mints tokens and adds them to the balance of the `to` address.
     * @dev This method should be permissioned to only allow designated parties to mint tokens.
     */
    function mint(address to, uint256 value) external virtual returns (bool);

    function addMinter(address account) external virtual;

    function addBurner(address account) external virtual;

    function resetOwner(address account) external virtual;
}

pragma solidity ^0.6.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

pragma solidity ^0.6.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../oracle/implementation/Finder.sol";
import "../oracle/implementation/Constants.sol";
import "../oracle/implementation/Voting.sol";

/**
 * @title A contract that executes a short series of upgrade calls that must be performed atomically as a part of the
 * upgrade process for Voting.sol.
 * @dev Note: the complete upgrade process requires more than just the transactions in this contract. These are only
 * the ones that need to be performed atomically.
 */
contract VotingUpgrader {
    // Existing governor is the only one who can initiate the upgrade.
    address public governor;

    // Existing Voting contract needs to be informed of the address of the new Voting contract.
    Voting public existingVoting;

    // New governor will be the new owner of the finder.

    // Finder contract to push upgrades to.
    Finder public finder;

    // Addresses to upgrade.
    address public newVoting;

    /**
     * @notice Removes an address from the whitelist.
     * @param _governor the Governor contract address.
     * @param _existingVoting the current/existing Voting contract address.
     * @param _newVoting the new Voting deployment address.
     * @param _finder the Finder contract address.
     */
    constructor(
        address _governor,
        address _existingVoting,
        address _newVoting,
        address _finder
    ) public {
        governor = _governor;
        existingVoting = Voting(_existingVoting);
        newVoting = _newVoting;
        finder = Finder(_finder);
    }

    /**
     * @notice Performs the atomic portion of the upgrade process.
     * @dev This method updates the Voting address in the finder, sets the old voting contract to migrated state, and
     * returns ownership of the existing Voting contract and Finder back to the Governor.
     */
    function upgrade() external {
        require(msg.sender == governor, "Upgrade can only be initiated by the existing governor.");

        // Change the addresses in the Finder.
        finder.changeImplementationAddress(OracleInterfaces.Oracle, newVoting);
        // Set current Voting contract to migrated.
        existingVoting.setMigrated(newVoting);

        // Transfer back ownership of old voting contract and the finder to the governor.
        existingVoting.transferOwnership(governor);
        finder.transferOwnership(governor);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/FinderInterface.sol";

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples of interfaces with implementations that Finder locates are the Oracle and Store interfaces.
 */
contract Finder is FinderInterface, Ownable {
    mapping(bytes32 => address) public interfacesImplemented;

    event InterfaceImplementationChanged(bytes32 indexed interfaceName, address indexed newImplementationAddress);

    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 of the interface name that is either changed or registered.
     * @param implementationAddress address of the implementation contract.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress)
        external
        override
        onlyOwner
    {
        interfacesImplemented[interfaceName] = implementationAddress;

        emit InterfaceImplementationChanged(interfaceName, implementationAddress);
    }

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the defined interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view override returns (address) {
        address implementationAddress = interfacesImplemented[interfaceName];
        require(implementationAddress != address(0x0), "Implementation not found");
        return implementationAddress;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../oracle/implementation/Finder.sol";
import "../oracle/implementation/Constants.sol";
import "../oracle/implementation/Voting.sol";

/**
 * @title A contract to track a whitelist of addresses.
 */
contract Umip3Upgrader {
    // Existing governor is the only one who can initiate the upgrade.
    address public existingGovernor;

    // Existing Voting contract needs to be informed of the address of the new Voting contract.
    Voting public existingVoting;

    // New governor will be the new owner of the finder.
    address public newGovernor;

    // Finder contract to push upgrades to.
    Finder public finder;

    // Addresses to upgrade.
    address public voting;
    address public identifierWhitelist;
    address public store;
    address public financialContractsAdmin;
    address public registry;

    constructor(
        address _existingGovernor,
        address _existingVoting,
        address _finder,
        address _voting,
        address _identifierWhitelist,
        address _store,
        address _financialContractsAdmin,
        address _registry,
        address _newGovernor
    ) public {
        existingGovernor = _existingGovernor;
        existingVoting = Voting(_existingVoting);
        finder = Finder(_finder);
        voting = _voting;
        identifierWhitelist = _identifierWhitelist;
        store = _store;
        financialContractsAdmin = _financialContractsAdmin;
        registry = _registry;
        newGovernor = _newGovernor;
    }

    function upgrade() external {
        require(msg.sender == existingGovernor, "Upgrade can only be initiated by the existing governor.");

        // Change the addresses in the Finder.
        finder.changeImplementationAddress(OracleInterfaces.Oracle, voting);
        finder.changeImplementationAddress(OracleInterfaces.IdentifierWhitelist, identifierWhitelist);
        finder.changeImplementationAddress(OracleInterfaces.Store, store);
        finder.changeImplementationAddress(OracleInterfaces.FinancialContractsAdmin, financialContractsAdmin);
        finder.changeImplementationAddress(OracleInterfaces.Registry, registry);

        // Transfer the ownership of the Finder to the new Governor now that all the addresses have been updated.
        finder.transferOwnership(newGovernor);

        // Inform the existing Voting contract of the address of the new Voting contract and transfer its
        // ownership to the new governor to allow for any future changes to the migrated contract.
        existingVoting.setMigrated(voting);
        existingVoting.transferOwnership(newGovernor);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../../common/implementation/Testable.sol";
import "../interfaces/OracleAncillaryInterface.sol";
import "../interfaces/IdentifierWhitelistInterface.sol";
import "../interfaces/FinderInterface.sol";
import "../implementation/Constants.sol";

// A mock oracle used for testing.
contract MockOracleAncillary is OracleAncillaryInterface, Testable {
    // Represents an available price. Have to keep a separate bool to allow for price=0.
    struct Price {
        bool isAvailable;
        int256 price;
        // Time the verified price became available.
        uint256 verifiedTime;
    }

    // The two structs below are used in an array and mapping to keep track of prices that have been requested but are
    // not yet available.
    struct QueryIndex {
        bool isValid;
        uint256 index;
    }

    // Represents a (identifier, time) point that has been queried.
    struct QueryPoint {
        bytes32 identifier;
        uint256 time;
        bytes ancillaryData;
    }

    // Reference to the Finder.
    FinderInterface private finder;

    // Conceptually we want a (time, identifier) -> price map.
    mapping(bytes32 => mapping(uint256 => mapping(bytes => Price))) private verifiedPrices;

    // The mapping and array allow retrieving all the elements in a mapping and finding/deleting elements.
    // Can we generalize this data structure?
    mapping(bytes32 => mapping(uint256 => mapping(bytes => QueryIndex))) private queryIndices;
    QueryPoint[] private requestedPrices;

    constructor(address _finderAddress, address _timerAddress) public Testable(_timerAddress) {
        finder = FinderInterface(_finderAddress);
    }

    // Enqueues a request (if a request isn't already present) for the given (identifier, time) pair.

    function requestPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public override {
        require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
        Price storage lookup = verifiedPrices[identifier][time][ancillaryData];
        if (!lookup.isAvailable && !queryIndices[identifier][time][ancillaryData].isValid) {
            // New query, enqueue it for review.
            queryIndices[identifier][time][ancillaryData] = QueryIndex(true, requestedPrices.length);
            requestedPrices.push(QueryPoint(identifier, time, ancillaryData));
        }
    }

    // Pushes the verified price for a requested query.
    function pushPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        int256 price
    ) external {
        verifiedPrices[identifier][time][ancillaryData] = Price(true, price, getCurrentTime());

        QueryIndex storage queryIndex = queryIndices[identifier][time][ancillaryData];
        require(queryIndex.isValid, "Can't push prices that haven't been requested");
        // Delete from the array. Instead of shifting the queries over, replace the contents of `indexToReplace` with
        // the contents of the last index (unless it is the last index).
        uint256 indexToReplace = queryIndex.index;
        delete queryIndices[identifier][time][ancillaryData];
        uint256 lastIndex = requestedPrices.length - 1;
        if (lastIndex != indexToReplace) {
            QueryPoint storage queryToCopy = requestedPrices[lastIndex];
            queryIndices[queryToCopy.identifier][queryToCopy.time][queryToCopy.ancillaryData].index = indexToReplace;
            requestedPrices[indexToReplace] = queryToCopy;
        }
    }

    // Checks whether a price has been resolved.
    function hasPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view override returns (bool) {
        require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
        Price storage lookup = verifiedPrices[identifier][time][ancillaryData];
        return lookup.isAvailable;
    }

    // Gets a price that has already been resolved.
    function getPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view override returns (int256) {
        require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
        Price storage lookup = verifiedPrices[identifier][time][ancillaryData];
        require(lookup.isAvailable);
        return lookup.price;
    }

    // Gets the queries that still need verified prices.
    function getPendingQueries() external view returns (QueryPoint[] memory) {
        return requestedPrices;
    }

    function _getIdentifierWhitelist() private view returns (IdentifierWhitelistInterface supportedIdentifiers) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../../common/implementation/Testable.sol";
import "../interfaces/OracleInterface.sol";
import "../interfaces/IdentifierWhitelistInterface.sol";
import "../interfaces/FinderInterface.sol";
import "../implementation/Constants.sol";

// A mock oracle used for testing.
contract MockOracle is OracleInterface, Testable {
    // Represents an available price. Have to keep a separate bool to allow for price=0.
    struct Price {
        bool isAvailable;
        int256 price;
        // Time the verified price became available.
        uint256 verifiedTime;
    }

    // The two structs below are used in an array and mapping to keep track of prices that have been requested but are
    // not yet available.
    struct QueryIndex {
        bool isValid;
        uint256 index;
    }

    // Represents a (identifier, time) point that has been queried.
    struct QueryPoint {
        bytes32 identifier;
        uint256 time;
    }

    // Reference to the Finder.
    FinderInterface private finder;

    // Conceptually we want a (time, identifier) -> price map.
    mapping(bytes32 => mapping(uint256 => Price)) private verifiedPrices;

    // The mapping and array allow retrieving all the elements in a mapping and finding/deleting elements.
    // Can we generalize this data structure?
    mapping(bytes32 => mapping(uint256 => QueryIndex)) private queryIndices;
    QueryPoint[] private requestedPrices;

    constructor(address _finderAddress, address _timerAddress) public Testable(_timerAddress) {
        finder = FinderInterface(_finderAddress);
    }

    // Enqueues a request (if a request isn't already present) for the given (identifier, time) pair.

    function requestPrice(bytes32 identifier, uint256 time) public override {
        require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
        Price storage lookup = verifiedPrices[identifier][time];
        if (!lookup.isAvailable && !queryIndices[identifier][time].isValid) {
            // New query, enqueue it for review.
            queryIndices[identifier][time] = QueryIndex(true, requestedPrices.length);
            requestedPrices.push(QueryPoint(identifier, time));
        }
    }

    // Pushes the verified price for a requested query.
    function pushPrice(
        bytes32 identifier,
        uint256 time,
        int256 price
    ) external {
        verifiedPrices[identifier][time] = Price(true, price, getCurrentTime());

        QueryIndex storage queryIndex = queryIndices[identifier][time];
        require(queryIndex.isValid, "Can't push prices that haven't been requested");
        // Delete from the array. Instead of shifting the queries over, replace the contents of `indexToReplace` with
        // the contents of the last index (unless it is the last index).
        uint256 indexToReplace = queryIndex.index;
        delete queryIndices[identifier][time];
        uint256 lastIndex = requestedPrices.length - 1;
        if (lastIndex != indexToReplace) {
            QueryPoint storage queryToCopy = requestedPrices[lastIndex];
            queryIndices[queryToCopy.identifier][queryToCopy.time].index = indexToReplace;
            requestedPrices[indexToReplace] = queryToCopy;
        }
    }

    // Checks whether a price has been resolved.
    function hasPrice(bytes32 identifier, uint256 time) public view override returns (bool) {
        require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
        Price storage lookup = verifiedPrices[identifier][time];
        return lookup.isAvailable;
    }

    // Gets a price that has already been resolved.
    function getPrice(bytes32 identifier, uint256 time) public view override returns (int256) {
        require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
        Price storage lookup = verifiedPrices[identifier][time];
        require(lookup.isAvailable);
        return lookup.price;
    }

    // Gets the queries that still need verified prices.
    function getPendingQueries() external view returns (QueryPoint[] memory) {
        return requestedPrices;
    }

    function _getIdentifierWhitelist() private view returns (IdentifierWhitelistInterface supportedIdentifiers) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/implementation/MultiRole.sol";
import "../../common/implementation/FixedPoint.sol";
import "../../common/implementation/Testable.sol";
import "../interfaces/FinderInterface.sol";
import "../interfaces/IdentifierWhitelistInterface.sol";
import "../interfaces/OracleInterface.sol";
import "./Constants.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Takes proposals for certain governance actions and allows UMA token holders to vote on them.
 */
contract Governor is MultiRole, Testable {
    using SafeMath for uint256;
    using Address for address;

    /****************************************
     *     INTERNAL VARIABLES AND STORAGE   *
     ****************************************/

    enum Roles {
        Owner, // Can set the proposer.
        Proposer // Address that can make proposals.
    }

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    struct Proposal {
        Transaction[] transactions;
        uint256 requestTime;
    }

    FinderInterface private finder;
    Proposal[] public proposals;

    /****************************************
     *                EVENTS                *
     ****************************************/

    // Emitted when a new proposal is created.
    event NewProposal(uint256 indexed id, Transaction[] transactions);

    // Emitted when an existing proposal is executed.
    event ProposalExecuted(uint256 indexed id, uint256 transactionIndex);

    /**
     * @notice Construct the Governor contract.
     * @param _finderAddress keeps track of all contracts within the system based on their interfaceName.
     * @param _startingId the initial proposal id that the contract will begin incrementing from.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(
        address _finderAddress,
        uint256 _startingId,
        address _timerAddress
    ) public Testable(_timerAddress) {
        finder = FinderInterface(_finderAddress);
        _createExclusiveRole(uint256(Roles.Owner), uint256(Roles.Owner), msg.sender);
        _createExclusiveRole(uint256(Roles.Proposer), uint256(Roles.Owner), msg.sender);

        // Ensure the startingId is not set unreasonably high to avoid it being set such that new proposals overwrite
        // other storage slots in the contract.
        uint256 maxStartingId = 10**18;
        require(_startingId <= maxStartingId, "Cannot set startingId larger than 10^18");

        // This just sets the initial length of the array to the startingId since modifying length directly has been
        // disallowed in solidity 0.6.
        assembly {
            sstore(proposals_slot, _startingId)
        }
    }

    /****************************************
     *          PROPOSAL ACTIONS            *
     ****************************************/

    /**
     * @notice Proposes a new governance action. Can only be called by the holder of the Proposer role.
     * @param transactions list of transactions that are being proposed.
     * @dev You can create the data portion of each transaction by doing the following:
     * ```
     * const truffleContractInstance = await TruffleContract.deployed()
     * const data = truffleContractInstance.methods.methodToCall(arg1, arg2).encodeABI()
     * ```
     * Note: this method must be public because of a solidity limitation that
     * disallows structs arrays to be passed to external functions.
     */
    function propose(Transaction[] memory transactions) public onlyRoleHolder(uint256(Roles.Proposer)) {
        uint256 id = proposals.length;
        uint256 time = getCurrentTime();

        // Note: doing all of this array manipulation manually is necessary because directly setting an array of
        // structs in storage to an an array of structs in memory is currently not implemented in solidity :/.

        // Add a zero-initialized element to the proposals array.
        proposals.push();

        // Initialize the new proposal.
        Proposal storage proposal = proposals[id];
        proposal.requestTime = time;

        // Initialize the transaction array.
        for (uint256 i = 0; i < transactions.length; i++) {
            require(transactions[i].to != address(0), "The `to` address cannot be 0x0");
            // If the transaction has any data with it the recipient must be a contract, not an EOA.
            if (transactions[i].data.length > 0) {
                require(transactions[i].to.isContract(), "EOA can't accept tx with data");
            }
            proposal.transactions.push(transactions[i]);
        }

        bytes32 identifier = _constructIdentifier(id);

        // Request a vote on this proposal in the DVM.
        OracleInterface oracle = _getOracle();
        IdentifierWhitelistInterface supportedIdentifiers = _getIdentifierWhitelist();
        supportedIdentifiers.addSupportedIdentifier(identifier);

        oracle.requestPrice(identifier, time);
        supportedIdentifiers.removeSupportedIdentifier(identifier);

        emit NewProposal(id, transactions);
    }

    /**
     * @notice Executes a proposed governance action that has been approved by voters.
     * @dev This can be called by any address. Caller is expected to send enough ETH to execute payable transactions.
     * @param id unique id for the executed proposal.
     * @param transactionIndex unique transaction index for the executed proposal.
     */
    function executeProposal(uint256 id, uint256 transactionIndex) external payable {
        Proposal storage proposal = proposals[id];
        int256 price = _getOracle().getPrice(_constructIdentifier(id), proposal.requestTime);

        Transaction memory transaction = proposal.transactions[transactionIndex];

        require(
            transactionIndex == 0 || proposal.transactions[transactionIndex.sub(1)].to == address(0),
            "Previous tx not yet executed"
        );
        require(transaction.to != address(0), "Tx already executed");
        require(price != 0, "Proposal was rejected");
        require(msg.value == transaction.value, "Must send exact amount of ETH");

        // Delete the transaction before execution to avoid any potential re-entrancy issues.
        delete proposal.transactions[transactionIndex];

        require(_executeCall(transaction.to, transaction.value, transaction.data), "Tx execution failed");

        emit ProposalExecuted(id, transactionIndex);
    }

    /****************************************
     *       GOVERNOR STATE GETTERS         *
     ****************************************/

    /**
     * @notice Gets the total number of proposals (includes executed and non-executed).
     * @return uint256 representing the current number of proposals.
     */
    function numProposals() external view returns (uint256) {
        return proposals.length;
    }

    /**
     * @notice Gets the proposal data for a particular id.
     * @dev after a proposal is executed, its data will be zeroed out, except for the request time.
     * @param id uniquely identify the identity of the proposal.
     * @return proposal struct containing transactions[] and requestTime.
     */
    function getProposal(uint256 id) external view returns (Proposal memory) {
        return proposals[id];
    }

    /****************************************
     *      PRIVATE GETTERS AND FUNCTIONS   *
     ****************************************/

    function _executeCall(
        address to,
        uint256 value,
        bytes memory data
    ) private returns (bool) {
        // Mostly copied from:
        // solhint-disable-next-line max-line-length
        // https://github.com/gnosis/safe-contracts/blob/59cfdaebcd8b87a0a32f87b50fead092c10d3a05/contracts/base/Executor.sol#L23-L31
        // solhint-disable-next-line no-inline-assembly

        bool success;
        assembly {
            let inputData := add(data, 0x20)
            let inputDataSize := mload(data)
            success := call(gas(), to, value, inputData, inputDataSize, 0, 0)
        }
        return success;
    }

    function _getOracle() private view returns (OracleInterface) {
        return OracleInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
    }

    function _getIdentifierWhitelist() private view returns (IdentifierWhitelistInterface supportedIdentifiers) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }

    // Returns a UTF-8 identifier representing a particular admin proposal.
    // The identifier is of the form "Admin n", where n is the proposal id provided.
    function _constructIdentifier(uint256 id) internal pure returns (bytes32) {
        bytes32 bytesId = _uintToUtf8(id);
        return _addPrefix(bytesId, "Admin ", 6);
    }

    // This method converts the integer `v` into a base-10, UTF-8 representation stored in a `bytes32` type.
    // If the input cannot be represented by 32 base-10 digits, it returns only the highest 32 digits.
    // This method is based off of this code: https://ethereum.stackexchange.com/a/6613/47801.
    function _uintToUtf8(uint256 v) internal pure returns (bytes32) {
        bytes32 ret;
        if (v == 0) {
            // Handle 0 case explicitly.
            ret = "0";
        } else {
            // Constants.
            uint256 bitsPerByte = 8;
            uint256 base = 10; // Note: the output should be base-10. The below implementation will not work for bases > 10.
            uint256 utf8NumberOffset = 48;
            while (v > 0) {
                // Downshift the entire bytes32 to allow the new digit to be added at the "front" of the bytes32, which
                // translates to the beginning of the UTF-8 representation.
                ret = ret >> bitsPerByte;

                // Separate the last digit that remains in v by modding by the base of desired output representation.
                uint256 leastSignificantDigit = v % base;

                // Digits 0-9 are represented by 48-57 in UTF-8, so an offset must be added to create the character.
                bytes32 utf8Digit = bytes32(leastSignificantDigit + utf8NumberOffset);

                // The top byte of ret has already been cleared to make room for the new digit.
                // Upshift by 31 bytes to put it in position, and OR it with ret to leave the other characters untouched.
                ret |= utf8Digit << (31 * bitsPerByte);

                // Divide v by the base to remove the digit that was just added.
                v /= base;
            }
        }
        return ret;
    }

    // This method takes two UTF-8 strings represented as bytes32 and outputs one as a prefixed by the other.
    // `input` is the UTF-8 that should have the prefix prepended.
    // `prefix` is the UTF-8 that should be prepended onto input.
    // `prefixLength` is number of UTF-8 characters represented by `prefix`.
    // Notes:
    // 1. If the resulting UTF-8 is larger than 32 characters, then only the first 32 characters will be represented
    //    by the bytes32 output.
    // 2. If `prefix` has more characters than `prefixLength`, the function will produce an invalid result.
    function _addPrefix(
        bytes32 input,
        bytes32 prefix,
        uint256 prefixLength
    ) internal pure returns (bytes32) {
        // Downshift `input` to open space at the "front" of the bytes32
        bytes32 shiftedInput = input >> (prefixLength * 8);
        return shiftedInput | prefix;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../Governor.sol";

// GovernorTest exposes internal methods in the Governor for testing.
contract GovernorTest is Governor {
    constructor(address _timerAddress) public Governor(address(0), 0, _timerAddress) {}

    function addPrefix(
        bytes32 input,
        bytes32 prefix,
        uint256 prefixLength
    ) external pure returns (bytes32) {
        return _addPrefix(input, prefix, prefixLength);
    }

    function uintToUtf8(uint256 v) external pure returns (bytes32 ret) {
        return _uintToUtf8(v);
    }

    function constructIdentifier(uint256 id) external pure returns (bytes32 identifier) {
        return _constructIdentifier(id);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../common/implementation/FixedPoint.sol";
import "../../common/interfaces/ExpandedIERC20.sol";
import "../../common/interfaces/IERC20Standard.sol";

import "../../oracle/interfaces/OracleInterface.sol";
import "../../oracle/interfaces/OptimisticOracleInterface.sol";
import "../../oracle/interfaces/IdentifierWhitelistInterface.sol";
import "../../oracle/implementation/Constants.sol";

import "../common/FeePayer.sol";
import "../common/financial-product-libraries/FinancialProductLibrary.sol";

/**
 * @title Financial contract with priceless position management.
 * @notice Handles positions for multiple sponsors in an optimistic (i.e., priceless) way without relying
 * on a price feed. On construction, deploys a new ERC20, managed by this contract, that is the synthetic token.
 */

contract PricelessPositionManager is FeePayer {
    using SafeMath for uint256;
    using FixedPoint for FixedPoint.Unsigned;
    using SafeERC20 for IERC20;
    using SafeERC20 for ExpandedIERC20;
    using Address for address;

    /****************************************
     *  PRICELESS POSITION DATA STRUCTURES  *
     ****************************************/

    // Stores the state of the PricelessPositionManager. Set on expiration, emergency shutdown, or settlement.
    enum ContractState { Open, ExpiredPriceRequested, ExpiredPriceReceived }
    ContractState public contractState;

    // Represents a single sponsor's position. All collateral is held by this contract.
    // This struct acts as bookkeeping for how much of that collateral is allocated to each sponsor.
    struct PositionData {
        FixedPoint.Unsigned tokensOutstanding;
        // Tracks pending withdrawal requests. A withdrawal request is pending if `withdrawalRequestPassTimestamp != 0`.
        uint256 withdrawalRequestPassTimestamp;
        FixedPoint.Unsigned withdrawalRequestAmount;
        // Raw collateral value. This value should never be accessed directly -- always use _getFeeAdjustedCollateral().
        // To add or remove collateral, use _addCollateral() and _removeCollateral().
        FixedPoint.Unsigned rawCollateral;
        // Tracks pending transfer position requests. A transfer position request is pending if `transferPositionRequestPassTimestamp != 0`.
        uint256 transferPositionRequestPassTimestamp;
    }

    // Maps sponsor addresses to their positions. Each sponsor can have only one position.
    mapping(address => PositionData) public positions;

    // Keep track of the total collateral and tokens across all positions to enable calculating the
    // global collateralization ratio without iterating over all positions.
    FixedPoint.Unsigned public totalTokensOutstanding;

    // Similar to the rawCollateral in PositionData, this value should not be used directly.
    // _getFeeAdjustedCollateral(), _addCollateral() and _removeCollateral() must be used to access and adjust.
    FixedPoint.Unsigned public rawTotalPositionCollateral;

    // Synthetic token created by this contract.
    ExpandedIERC20 public tokenCurrency;

    // Unique identifier for DVM price feed ticker.
    bytes32 public priceIdentifier;
    // Time that this contract expires. Should not change post-construction unless an emergency shutdown occurs.
    uint256 public expirationTimestamp;
    // Time that has to elapse for a withdrawal request to be considered passed, if no liquidations occur.
    // !!Note: The lower the withdrawal liveness value, the more risk incurred by the contract.
    //       Extremely low liveness values increase the chance that opportunistic invalid withdrawal requests
    //       expire without liquidation, thereby increasing the insolvency risk for the contract as a whole. An insolvent
    //       contract is extremely risky for any sponsor or synthetic token holder for the contract.
    uint256 public withdrawalLiveness;

    // Minimum number of tokens in a sponsor's position.
    FixedPoint.Unsigned public minSponsorTokens;

    // The expiry price pulled from the DVM.
    FixedPoint.Unsigned public expiryPrice;

    // Instance of FinancialProductLibrary to provide custom price and collateral requirement transformations to extend
    // the functionality of the EMP to support a wider range of financial products.
    FinancialProductLibrary public financialProductLibrary;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event RequestTransferPosition(address indexed oldSponsor);
    event RequestTransferPositionExecuted(address indexed oldSponsor, address indexed newSponsor);
    event RequestTransferPositionCanceled(address indexed oldSponsor);
    event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
    event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
    event RequestWithdrawal(address indexed sponsor, uint256 indexed collateralAmount);
    event RequestWithdrawalExecuted(address indexed sponsor, uint256 indexed collateralAmount);
    event RequestWithdrawalCanceled(address indexed sponsor, uint256 indexed collateralAmount);
    event PositionCreated(address indexed sponsor, uint256 indexed collateralAmount, uint256 indexed tokenAmount);
    event NewSponsor(address indexed sponsor);
    event EndedSponsorPosition(address indexed sponsor);
    event Repay(address indexed sponsor, uint256 indexed numTokensRepaid, uint256 indexed newTokenCount);
    event Redeem(address indexed sponsor, uint256 indexed collateralAmount, uint256 indexed tokenAmount);
    event ContractExpired(address indexed caller);
    event SettleExpiredPosition(
        address indexed caller,
        uint256 indexed collateralReturned,
        uint256 indexed tokensBurned
    );
    event EmergencyShutdown(address indexed caller, uint256 originalExpirationTimestamp, uint256 shutdownTimestamp);

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    modifier onlyPreExpiration() {
        _onlyPreExpiration();
        _;
    }

    modifier onlyPostExpiration() {
        _onlyPostExpiration();
        _;
    }

    modifier onlyCollateralizedPosition(address sponsor) {
        _onlyCollateralizedPosition(sponsor);
        _;
    }

    // Check that the current state of the pricelessPositionManager is Open.
    // This prevents multiple calls to `expire` and `EmergencyShutdown` post expiration.
    modifier onlyOpenState() {
        _onlyOpenState();
        _;
    }

    modifier noPendingWithdrawal(address sponsor) {
        _positionHasNoPendingWithdrawal(sponsor);
        _;
    }

    /**
     * @notice Construct the PricelessPositionManager
     * @dev Deployer of this contract should consider carefully which parties have ability to mint and burn
     * the synthetic tokens referenced by `_tokenAddress`. This contract's security assumes that no external accounts
     * can mint new tokens, which could be used to steal all of this contract's locked collateral.
     * We recommend to only use synthetic token contracts whose sole Owner role (the role capable of adding & removing roles)
     * is assigned to this contract, whose sole Minter role is assigned to this contract, and whose
     * total supply is 0 prior to construction of this contract.
     * @param _expirationTimestamp unix timestamp of when the contract will expire.
     * @param _withdrawalLiveness liveness delay, in seconds, for pending withdrawals.
     * @param _collateralAddress ERC20 token used as collateral for all positions.
     * @param _tokenAddress ERC20 token used as synthetic token.
     * @param _finderAddress UMA protocol Finder used to discover other protocol contracts.
     * @param _priceIdentifier registered in the DVM for the synthetic.
     * @param _minSponsorTokens minimum amount of collateral that must exist at any time in a position.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     * @param _financialProductLibraryAddress Contract providing contract state transformations.
     */
    constructor(
        uint256 _expirationTimestamp,
        uint256 _withdrawalLiveness,
        address _collateralAddress,
        address _tokenAddress,
        address _finderAddress,
        bytes32 _priceIdentifier,
        FixedPoint.Unsigned memory _minSponsorTokens,
        address _timerAddress,
        address _financialProductLibraryAddress
    ) public FeePayer(_collateralAddress, _finderAddress, _timerAddress) nonReentrant() {
        require(_expirationTimestamp > getCurrentTime());
        require(_getIdentifierWhitelist().isIdentifierSupported(_priceIdentifier));

        expirationTimestamp = _expirationTimestamp;
        withdrawalLiveness = _withdrawalLiveness;
        tokenCurrency = ExpandedIERC20(_tokenAddress);
        minSponsorTokens = _minSponsorTokens;
        priceIdentifier = _priceIdentifier;

        // Initialize the financialProductLibrary at the provided address.
        financialProductLibrary = FinancialProductLibrary(_financialProductLibraryAddress);
    }

    /****************************************
     *          POSITION FUNCTIONS          *
     ****************************************/

    /**
     * @notice Requests to transfer ownership of the caller's current position to a new sponsor address.
     * Once the request liveness is passed, the sponsor can execute the transfer and specify the new sponsor.
     * @dev The liveness length is the same as the withdrawal liveness.
     */
    function requestTransferPosition() public onlyPreExpiration() nonReentrant() {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(positionData.transferPositionRequestPassTimestamp == 0);

        // Make sure the proposed expiration of this request is not post-expiry.
        uint256 requestPassTime = getCurrentTime().add(withdrawalLiveness);
        require(requestPassTime < expirationTimestamp);

        // Update the position object for the user.
        positionData.transferPositionRequestPassTimestamp = requestPassTime;

        emit RequestTransferPosition(msg.sender);
    }

    /**
     * @notice After a passed transfer position request (i.e., by a call to `requestTransferPosition` and waiting
     * `withdrawalLiveness`), transfers ownership of the caller's current position to `newSponsorAddress`.
     * @dev Transferring positions can only occur if the recipient does not already have a position.
     * @param newSponsorAddress is the address to which the position will be transferred.
     */
    function transferPositionPassedRequest(address newSponsorAddress)
        public
        onlyPreExpiration()
        noPendingWithdrawal(msg.sender)
        nonReentrant()
    {
        require(
            _getFeeAdjustedCollateral(positions[newSponsorAddress].rawCollateral).isEqual(
                FixedPoint.fromUnscaledUint(0)
            )
        );
        PositionData storage positionData = _getPositionData(msg.sender);
        require(
            positionData.transferPositionRequestPassTimestamp != 0 &&
                positionData.transferPositionRequestPassTimestamp <= getCurrentTime()
        );

        // Reset transfer request.
        positionData.transferPositionRequestPassTimestamp = 0;

        positions[newSponsorAddress] = positionData;
        delete positions[msg.sender];

        emit RequestTransferPositionExecuted(msg.sender, newSponsorAddress);
        emit NewSponsor(newSponsorAddress);
        emit EndedSponsorPosition(msg.sender);
    }

    /**
     * @notice Cancels a pending transfer position request.
     */
    function cancelTransferPosition() external onlyPreExpiration() nonReentrant() {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(positionData.transferPositionRequestPassTimestamp != 0);

        emit RequestTransferPositionCanceled(msg.sender);

        // Reset withdrawal request.
        positionData.transferPositionRequestPassTimestamp = 0;
    }

    /**
     * @notice Transfers `collateralAmount` of `collateralCurrency` into the specified sponsor's position.
     * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
     * at least `collateralAmount` of `collateralCurrency`.
     * @param sponsor the sponsor to credit the deposit to.
     * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
     */
    function depositTo(address sponsor, FixedPoint.Unsigned memory collateralAmount)
        public
        onlyPreExpiration()
        noPendingWithdrawal(sponsor)
        fees()
        nonReentrant()
    {
        require(collateralAmount.isGreaterThan(0));
        PositionData storage positionData = _getPositionData(sponsor);

        // Increase the position and global collateral balance by collateral amount.
        _incrementCollateralBalances(positionData, collateralAmount);

        emit Deposit(sponsor, collateralAmount.rawValue);

        // Move collateral currency from sender to contract.
        collateralCurrency.safeTransferFrom(msg.sender, address(this), collateralAmount.rawValue);
    }

    /**
     * @notice Transfers `collateralAmount` of `collateralCurrency` into the caller's position.
     * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
     * at least `collateralAmount` of `collateralCurrency`.
     * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
     */
    function deposit(FixedPoint.Unsigned memory collateralAmount) public {
        // This is just a thin wrapper over depositTo that specified the sender as the sponsor.
        depositTo(msg.sender, collateralAmount);
    }

    /**
     * @notice Transfers `collateralAmount` of `collateralCurrency` from the sponsor's position to the sponsor.
     * @dev Reverts if the withdrawal puts this position's collateralization ratio below the global collateralization
     * ratio. In that case, use `requestWithdrawal`. Might not withdraw the full requested amount to account for precision loss.
     * @param collateralAmount is the amount of collateral to withdraw.
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function withdraw(FixedPoint.Unsigned memory collateralAmount)
        public
        onlyPreExpiration()
        noPendingWithdrawal(msg.sender)
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        require(collateralAmount.isGreaterThan(0));
        PositionData storage positionData = _getPositionData(msg.sender);

        // Decrement the sponsor's collateral and global collateral amounts. Check the GCR between decrement to ensure
        // position remains above the GCR within the withdrawal. If this is not the case the caller must submit a request.
        amountWithdrawn = _decrementCollateralBalancesCheckGCR(positionData, collateralAmount);

        emit Withdrawal(msg.sender, amountWithdrawn.rawValue);

        // Move collateral currency from contract to sender.
        // Note: that we move the amount of collateral that is decreased from rawCollateral (inclusive of fees)
        // instead of the user requested amount. This eliminates precision loss that could occur
        // where the user withdraws more collateral than rawCollateral is decremented by.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
    }

    /**
     * @notice Starts a withdrawal request that, if passed, allows the sponsor to withdraw` from their position.
     * @dev The request will be pending for `withdrawalLiveness`, during which the position can be liquidated.
     * @param collateralAmount the amount of collateral requested to withdraw
     */
    function requestWithdrawal(FixedPoint.Unsigned memory collateralAmount)
        public
        onlyPreExpiration()
        noPendingWithdrawal(msg.sender)
        nonReentrant()
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(
            collateralAmount.isGreaterThan(0) &&
                collateralAmount.isLessThanOrEqual(_getFeeAdjustedCollateral(positionData.rawCollateral))
        );

        // Make sure the proposed expiration of this request is not post-expiry.
        uint256 requestPassTime = getCurrentTime().add(withdrawalLiveness);
        require(requestPassTime < expirationTimestamp);

        // Update the position object for the user.
        positionData.withdrawalRequestPassTimestamp = requestPassTime;
        positionData.withdrawalRequestAmount = collateralAmount;

        emit RequestWithdrawal(msg.sender, collateralAmount.rawValue);
    }

    /**
     * @notice After a passed withdrawal request (i.e., by a call to `requestWithdrawal` and waiting
     * `withdrawalLiveness`), withdraws `positionData.withdrawalRequestAmount` of collateral currency.
     * @dev Might not withdraw the full requested amount in order to account for precision loss or if the full requested
     * amount exceeds the collateral in the position (due to paying fees).
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function withdrawPassedRequest()
        external
        onlyPreExpiration()
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(
            positionData.withdrawalRequestPassTimestamp != 0 &&
                positionData.withdrawalRequestPassTimestamp <= getCurrentTime()
        );

        // If withdrawal request amount is > position collateral, then withdraw the full collateral amount.
        // This situation is possible due to fees charged since the withdrawal was originally requested.
        FixedPoint.Unsigned memory amountToWithdraw = positionData.withdrawalRequestAmount;
        if (positionData.withdrawalRequestAmount.isGreaterThan(_getFeeAdjustedCollateral(positionData.rawCollateral))) {
            amountToWithdraw = _getFeeAdjustedCollateral(positionData.rawCollateral);
        }

        // Decrement the sponsor's collateral and global collateral amounts.
        amountWithdrawn = _decrementCollateralBalances(positionData, amountToWithdraw);

        // Reset withdrawal request by setting withdrawal amount and withdrawal timestamp to 0.
        _resetWithdrawalRequest(positionData);

        // Transfer approved withdrawal amount from the contract to the caller.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);

        emit RequestWithdrawalExecuted(msg.sender, amountWithdrawn.rawValue);
    }

    /**
     * @notice Cancels a pending withdrawal request.
     */
    function cancelWithdrawal() external nonReentrant() {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(positionData.withdrawalRequestPassTimestamp != 0);

        emit RequestWithdrawalCanceled(msg.sender, positionData.withdrawalRequestAmount.rawValue);

        // Reset withdrawal request by setting withdrawal amount and withdrawal timestamp to 0.
        _resetWithdrawalRequest(positionData);
    }

    /**
     * @notice Creates tokens by creating a new position or by augmenting an existing position. Pulls `collateralAmount` into the sponsor's position and mints `numTokens` of `tokenCurrency`.
     * @dev Reverts if minting these tokens would put the position's collateralization ratio below the
     * global collateralization ratio. This contract must be approved to spend at least `collateralAmount` of
     * `collateralCurrency`.
     * @dev This contract must have the Minter role for the `tokenCurrency`.
     * @param collateralAmount is the number of collateral tokens to collateralize the position with
     * @param numTokens is the number of tokens to mint from the position.
     */
    function create(FixedPoint.Unsigned memory collateralAmount, FixedPoint.Unsigned memory numTokens)
        public
        onlyPreExpiration()
        fees()
        nonReentrant()
    {
        PositionData storage positionData = positions[msg.sender];

        // Either the new create ratio or the resultant position CR must be above the current GCR.
        require(
            (_checkCollateralization(
                _getFeeAdjustedCollateral(positionData.rawCollateral).add(collateralAmount),
                positionData.tokensOutstanding.add(numTokens)
            ) || _checkCollateralization(collateralAmount, numTokens)),
            "Insufficient collateral"
        );

        require(positionData.withdrawalRequestPassTimestamp == 0, "Pending withdrawal");
        if (positionData.tokensOutstanding.isEqual(0)) {
            require(numTokens.isGreaterThanOrEqual(minSponsorTokens), "Below minimum sponsor position");
            emit NewSponsor(msg.sender);
        }

        // Increase the position and global collateral balance by collateral amount.
        _incrementCollateralBalances(positionData, collateralAmount);

        // Add the number of tokens created to the position's outstanding tokens.
        positionData.tokensOutstanding = positionData.tokensOutstanding.add(numTokens);

        totalTokensOutstanding = totalTokensOutstanding.add(numTokens);

        emit PositionCreated(msg.sender, collateralAmount.rawValue, numTokens.rawValue);

        // Transfer tokens into the contract from caller and mint corresponding synthetic tokens to the caller's address.
        collateralCurrency.safeTransferFrom(msg.sender, address(this), collateralAmount.rawValue);
        require(tokenCurrency.mint(msg.sender, numTokens.rawValue));
    }

    /**
     * @notice Burns `numTokens` of `tokenCurrency` to decrease sponsors position size, without sending back `collateralCurrency`.
     * This is done by a sponsor to increase position CR. Resulting size is bounded by minSponsorTokens.
     * @dev Can only be called by token sponsor. This contract must be approved to spend `numTokens` of `tokenCurrency`.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @param numTokens is the number of tokens to be burnt from the sponsor's debt position.
     */
    function repay(FixedPoint.Unsigned memory numTokens)
        public
        onlyPreExpiration()
        noPendingWithdrawal(msg.sender)
        fees()
        nonReentrant()
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(numTokens.isLessThanOrEqual(positionData.tokensOutstanding));

        // Decrease the sponsors position tokens size. Ensure it is above the min sponsor size.
        FixedPoint.Unsigned memory newTokenCount = positionData.tokensOutstanding.sub(numTokens);
        require(newTokenCount.isGreaterThanOrEqual(minSponsorTokens));
        positionData.tokensOutstanding = newTokenCount;

        // Update the totalTokensOutstanding after redemption.
        totalTokensOutstanding = totalTokensOutstanding.sub(numTokens);

        emit Repay(msg.sender, numTokens.rawValue, newTokenCount.rawValue);

        // Transfer the tokens back from the sponsor and burn them.
        tokenCurrency.safeTransferFrom(msg.sender, address(this), numTokens.rawValue);
        tokenCurrency.burn(numTokens.rawValue);
    }

    /**
     * @notice Burns `numTokens` of `tokenCurrency` and sends back the proportional amount of `collateralCurrency`.
     * @dev Can only be called by a token sponsor. Might not redeem the full proportional amount of collateral
     * in order to account for precision loss. This contract must be approved to spend at least `numTokens` of
     * `tokenCurrency`.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @param numTokens is the number of tokens to be burnt for a commensurate amount of collateral.
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function redeem(FixedPoint.Unsigned memory numTokens)
        public
        noPendingWithdrawal(msg.sender)
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(!numTokens.isGreaterThan(positionData.tokensOutstanding));

        FixedPoint.Unsigned memory fractionRedeemed = numTokens.div(positionData.tokensOutstanding);
        FixedPoint.Unsigned memory collateralRedeemed =
            fractionRedeemed.mul(_getFeeAdjustedCollateral(positionData.rawCollateral));

        // If redemption returns all tokens the sponsor has then we can delete their position. Else, downsize.
        if (positionData.tokensOutstanding.isEqual(numTokens)) {
            amountWithdrawn = _deleteSponsorPosition(msg.sender);
        } else {
            // Decrement the sponsor's collateral and global collateral amounts.
            amountWithdrawn = _decrementCollateralBalances(positionData, collateralRedeemed);

            // Decrease the sponsors position tokens size. Ensure it is above the min sponsor size.
            FixedPoint.Unsigned memory newTokenCount = positionData.tokensOutstanding.sub(numTokens);
            require(newTokenCount.isGreaterThanOrEqual(minSponsorTokens), "Below minimum sponsor position");
            positionData.tokensOutstanding = newTokenCount;

            // Update the totalTokensOutstanding after redemption.
            totalTokensOutstanding = totalTokensOutstanding.sub(numTokens);
        }

        emit Redeem(msg.sender, amountWithdrawn.rawValue, numTokens.rawValue);

        // Transfer collateral from contract to caller and burn callers synthetic tokens.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
        tokenCurrency.safeTransferFrom(msg.sender, address(this), numTokens.rawValue);
        tokenCurrency.burn(numTokens.rawValue);
    }

    /**
     * @notice After a contract has passed expiry all token holders can redeem their tokens for underlying at the
     * prevailing price defined by the DVM from the `expire` function.
     * @dev This burns all tokens from the caller of `tokenCurrency` and sends back the proportional amount of
     * `collateralCurrency`. Might not redeem the full proportional amount of collateral in order to account for
     * precision loss. This contract must be approved to spend `tokenCurrency` at least up to the caller's full balance.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function settleExpired()
        external
        onlyPostExpiration()
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        // If the contract state is open and onlyPostExpiration passed then `expire()` has not yet been called.
        require(contractState != ContractState.Open, "Unexpired position");

        // Get the current settlement price and store it. If it is not resolved will revert.
        if (contractState != ContractState.ExpiredPriceReceived) {
            expiryPrice = _getOraclePriceExpiration(expirationTimestamp);
            contractState = ContractState.ExpiredPriceReceived;
        }

        // Get caller's tokens balance and calculate amount of underlying entitled to them.
        FixedPoint.Unsigned memory tokensToRedeem = FixedPoint.Unsigned(tokenCurrency.balanceOf(msg.sender));
        FixedPoint.Unsigned memory totalRedeemableCollateral = tokensToRedeem.mul(expiryPrice);

        // If the caller is a sponsor with outstanding collateral they are also entitled to their excess collateral after their debt.
        PositionData storage positionData = positions[msg.sender];
        if (_getFeeAdjustedCollateral(positionData.rawCollateral).isGreaterThan(0)) {
            // Calculate the underlying entitled to a token sponsor. This is collateral - debt in underlying.
            FixedPoint.Unsigned memory tokenDebtValueInCollateral = positionData.tokensOutstanding.mul(expiryPrice);
            FixedPoint.Unsigned memory positionCollateral = _getFeeAdjustedCollateral(positionData.rawCollateral);

            // If the debt is greater than the remaining collateral, they cannot redeem anything.
            FixedPoint.Unsigned memory positionRedeemableCollateral =
                tokenDebtValueInCollateral.isLessThan(positionCollateral)
                    ? positionCollateral.sub(tokenDebtValueInCollateral)
                    : FixedPoint.Unsigned(0);

            // Add the number of redeemable tokens for the sponsor to their total redeemable collateral.
            totalRedeemableCollateral = totalRedeemableCollateral.add(positionRedeemableCollateral);

            // Reset the position state as all the value has been removed after settlement.
            delete positions[msg.sender];
            emit EndedSponsorPosition(msg.sender);
        }

        // Take the min of the remaining collateral and the collateral "owed". If the contract is undercapitalized,
        // the caller will get as much collateral as the contract can pay out.
        FixedPoint.Unsigned memory payout =
            FixedPoint.min(_getFeeAdjustedCollateral(rawTotalPositionCollateral), totalRedeemableCollateral);

        // Decrement total contract collateral and outstanding debt.
        amountWithdrawn = _removeCollateral(rawTotalPositionCollateral, payout);
        totalTokensOutstanding = totalTokensOutstanding.sub(tokensToRedeem);

        emit SettleExpiredPosition(msg.sender, amountWithdrawn.rawValue, tokensToRedeem.rawValue);

        // Transfer tokens & collateral and burn the redeemed tokens.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
        tokenCurrency.safeTransferFrom(msg.sender, address(this), tokensToRedeem.rawValue);
        tokenCurrency.burn(tokensToRedeem.rawValue);
    }

    /****************************************
     *        GLOBAL STATE FUNCTIONS        *
     ****************************************/

    /**
     * @notice Locks contract state in expired and requests oracle price.
     * @dev this function can only be called once the contract is expired and can't be re-called.
     */
    function expire() external onlyPostExpiration() onlyOpenState() fees() nonReentrant() {
        contractState = ContractState.ExpiredPriceRequested;

        // Final fees do not need to be paid when sending a request to the optimistic oracle.
        _requestOraclePriceExpiration(expirationTimestamp);

        emit ContractExpired(msg.sender);
    }

    /**
     * @notice Premature contract settlement under emergency circumstances.
     * @dev Only the governor can call this function as they are permissioned within the `FinancialContractAdmin`.
     * Upon emergency shutdown, the contract settlement time is set to the shutdown time. This enables withdrawal
     * to occur via the standard `settleExpired` function. Contract state is set to `ExpiredPriceRequested`
     * which prevents re-entry into this function or the `expire` function. No fees are paid when calling
     * `emergencyShutdown` as the governor who would call the function would also receive the fees.
     */
    function emergencyShutdown() external override onlyPreExpiration() onlyOpenState() nonReentrant() {
        require(msg.sender == _getFinancialContractsAdminAddress());

        contractState = ContractState.ExpiredPriceRequested;
        // Expiratory time now becomes the current time (emergency shutdown time).
        // Price requested at this time stamp. `settleExpired` can now withdraw at this timestamp.
        uint256 oldExpirationTimestamp = expirationTimestamp;
        expirationTimestamp = getCurrentTime();
        _requestOraclePriceExpiration(expirationTimestamp);

        emit EmergencyShutdown(msg.sender, oldExpirationTimestamp, expirationTimestamp);
    }

    /**
     * @notice Theoretically supposed to pay fees and move money between margin accounts to make sure they
     * reflect the NAV of the contract. However, this functionality doesn't apply to this contract.
     * @dev This is supposed to be implemented by any contract that inherits `AdministrateeInterface` and callable
     * only by the Governor contract. This method is therefore minimally implemented in this contract and does nothing.
     */
    function remargin() external override onlyPreExpiration() nonReentrant() {
        return;
    }

    /**
     * @notice Accessor method for a sponsor's collateral.
     * @dev This is necessary because the struct returned by the positions() method shows
     * rawCollateral, which isn't a user-readable value.
     * @dev This method accounts for pending regular fees that have not yet been withdrawn from this contract, for
     * example if the `lastPaymentTime != currentTime`.
     * @param sponsor address whose collateral amount is retrieved.
     * @return collateralAmount amount of collateral within a sponsors position.
     */
    function getCollateral(address sponsor) external view nonReentrantView() returns (FixedPoint.Unsigned memory) {
        // Note: do a direct access to avoid the validity check.
        return _getPendingRegularFeeAdjustedCollateral(_getFeeAdjustedCollateral(positions[sponsor].rawCollateral));
    }

    /**
     * @notice Accessor method for the total collateral stored within the PricelessPositionManager.
     * @return totalCollateral amount of all collateral within the Expiring Multi Party Contract.
     * @dev This method accounts for pending regular fees that have not yet been withdrawn from this contract, for
     * example if the `lastPaymentTime != currentTime`.
     */
    function totalPositionCollateral() external view nonReentrantView() returns (FixedPoint.Unsigned memory) {
        return _getPendingRegularFeeAdjustedCollateral(_getFeeAdjustedCollateral(rawTotalPositionCollateral));
    }

    /**
     * @notice Accessor method to compute a transformed price using the finanicalProductLibrary specified at contract
     * deployment. If no library was provided then no modification to the price is done.
     * @param price input price to be transformed.
     * @param requestTime timestamp the oraclePrice was requested at.
     * @return transformedPrice price with the transformation function applied to it.
     * @dev This method should never revert.
     */

    function transformPrice(FixedPoint.Unsigned memory price, uint256 requestTime)
        public
        view
        nonReentrantView()
        returns (FixedPoint.Unsigned memory)
    {
        return _transformPrice(price, requestTime);
    }

    /**
     * @notice Accessor method to compute a transformed price identifier using the finanicalProductLibrary specified
     * at contract deployment. If no library was provided then no modification to the identifier is done.
     * @param requestTime timestamp the identifier is to be used at.
     * @return transformedPrice price with the transformation function applied to it.
     * @dev This method should never revert.
     */
    function transformPriceIdentifier(uint256 requestTime) public view nonReentrantView() returns (bytes32) {
        return _transformPriceIdentifier(requestTime);
    }

    /****************************************
     *          INTERNAL FUNCTIONS          *
     ****************************************/

    // Reduces a sponsor's position and global counters by the specified parameters. Handles deleting the entire
    // position if the entire position is being removed. Does not make any external transfers.
    function _reduceSponsorPosition(
        address sponsor,
        FixedPoint.Unsigned memory tokensToRemove,
        FixedPoint.Unsigned memory collateralToRemove,
        FixedPoint.Unsigned memory withdrawalAmountToRemove
    ) internal {
        PositionData storage positionData = _getPositionData(sponsor);

        // If the entire position is being removed, delete it instead.
        if (
            tokensToRemove.isEqual(positionData.tokensOutstanding) &&
            _getFeeAdjustedCollateral(positionData.rawCollateral).isEqual(collateralToRemove)
        ) {
            _deleteSponsorPosition(sponsor);
            return;
        }

        // Decrement the sponsor's collateral and global collateral amounts.
        _decrementCollateralBalances(positionData, collateralToRemove);

        // Ensure that the sponsor will meet the min position size after the reduction.
        FixedPoint.Unsigned memory newTokenCount = positionData.tokensOutstanding.sub(tokensToRemove);
        require(newTokenCount.isGreaterThanOrEqual(minSponsorTokens), "Below minimum sponsor position");
        positionData.tokensOutstanding = newTokenCount;

        // Decrement the position's withdrawal amount.
        positionData.withdrawalRequestAmount = positionData.withdrawalRequestAmount.sub(withdrawalAmountToRemove);

        // Decrement the total outstanding tokens in the overall contract.
        totalTokensOutstanding = totalTokensOutstanding.sub(tokensToRemove);
    }

    // Deletes a sponsor's position and updates global counters. Does not make any external transfers.
    function _deleteSponsorPosition(address sponsor) internal returns (FixedPoint.Unsigned memory) {
        PositionData storage positionToLiquidate = _getPositionData(sponsor);

        FixedPoint.Unsigned memory startingGlobalCollateral = _getFeeAdjustedCollateral(rawTotalPositionCollateral);

        // Remove the collateral and outstanding from the overall total position.
        FixedPoint.Unsigned memory remainingRawCollateral = positionToLiquidate.rawCollateral;
        rawTotalPositionCollateral = rawTotalPositionCollateral.sub(remainingRawCollateral);
        totalTokensOutstanding = totalTokensOutstanding.sub(positionToLiquidate.tokensOutstanding);

        // Reset the sponsors position to have zero outstanding and collateral.
        delete positions[sponsor];

        emit EndedSponsorPosition(sponsor);

        // Return fee-adjusted amount of collateral deleted from position.
        return startingGlobalCollateral.sub(_getFeeAdjustedCollateral(rawTotalPositionCollateral));
    }

    function _pfc() internal view virtual override returns (FixedPoint.Unsigned memory) {
        return _getFeeAdjustedCollateral(rawTotalPositionCollateral);
    }

    function _getPositionData(address sponsor)
        internal
        view
        onlyCollateralizedPosition(sponsor)
        returns (PositionData storage)
    {
        return positions[sponsor];
    }

    function _getIdentifierWhitelist() internal view returns (IdentifierWhitelistInterface) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }

    function _getOracle() internal view returns (OracleInterface) {
        return OracleInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
    }

    function _getOptimisticOracle() internal view returns (OptimisticOracleInterface) {
        return OptimisticOracleInterface(finder.getImplementationAddress(OracleInterfaces.OptimisticOracle));
    }

    function _getFinancialContractsAdminAddress() internal view returns (address) {
        return finder.getImplementationAddress(OracleInterfaces.FinancialContractsAdmin);
    }

    // Requests a price for transformed `priceIdentifier` at `requestedTime` from the Oracle.
    function _requestOraclePriceExpiration(uint256 requestedTime) internal {
        OptimisticOracleInterface optimisticOracle = _getOptimisticOracle();

        // Increase token allowance to enable the optimistic oracle reward transfer.
        FixedPoint.Unsigned memory reward = _computeFinalFees();
        collateralCurrency.safeIncreaseAllowance(address(optimisticOracle), reward.rawValue);
        optimisticOracle.requestPrice(
            _transformPriceIdentifier(requestedTime),
            requestedTime,
            _getAncillaryData(),
            collateralCurrency,
            reward.rawValue // Reward is equal to the final fee
        );

        // Apply haircut to all sponsors by decrementing the cumlativeFeeMultiplier by the amount lost from the final fee.
        _adjustCumulativeFeeMultiplier(reward, _pfc());
    }

    // Fetches a resolved Oracle price from the Oracle. Reverts if the Oracle hasn't resolved for this request.
    function _getOraclePriceExpiration(uint256 requestedTime) internal returns (FixedPoint.Unsigned memory) {
        // Create an instance of the oracle and get the price. If the price is not resolved revert.
        OptimisticOracleInterface optimisticOracle = _getOptimisticOracle();
        require(
            optimisticOracle.hasPrice(
                address(this),
                _transformPriceIdentifier(requestedTime),
                requestedTime,
                _getAncillaryData()
            )
        );
        int256 optimisticOraclePrice =
            optimisticOracle.settleAndGetPrice(
                _transformPriceIdentifier(requestedTime),
                requestedTime,
                _getAncillaryData()
            );

        // For now we don't want to deal with negative prices in positions.
        if (optimisticOraclePrice < 0) {
            optimisticOraclePrice = 0;
        }
        return _transformPrice(FixedPoint.Unsigned(uint256(optimisticOraclePrice)), requestedTime);
    }

    // Requests a price for transformed `priceIdentifier` at `requestedTime` from the Oracle.
    function _requestOraclePriceLiquidation(uint256 requestedTime) internal {
        OracleInterface oracle = _getOracle();
        oracle.requestPrice(_transformPriceIdentifier(requestedTime), requestedTime);
    }

    // Fetches a resolved Oracle price from the Oracle. Reverts if the Oracle hasn't resolved for this request.
    function _getOraclePriceLiquidation(uint256 requestedTime) internal view returns (FixedPoint.Unsigned memory) {
        // Create an instance of the oracle and get the price. If the price is not resolved revert.
        OracleInterface oracle = _getOracle();
        require(oracle.hasPrice(_transformPriceIdentifier(requestedTime), requestedTime), "Unresolved oracle price");
        int256 oraclePrice = oracle.getPrice(_transformPriceIdentifier(requestedTime), requestedTime);

        // For now we don't want to deal with negative prices in positions.
        if (oraclePrice < 0) {
            oraclePrice = 0;
        }
        return _transformPrice(FixedPoint.Unsigned(uint256(oraclePrice)), requestedTime);
    }

    // Reset withdrawal request by setting the withdrawal request and withdrawal timestamp to 0.
    function _resetWithdrawalRequest(PositionData storage positionData) internal {
        positionData.withdrawalRequestAmount = FixedPoint.fromUnscaledUint(0);
        positionData.withdrawalRequestPassTimestamp = 0;
    }

    // Ensure individual and global consistency when increasing collateral balances. Returns the change to the position.
    function _incrementCollateralBalances(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _addCollateral(positionData.rawCollateral, collateralAmount);
        return _addCollateral(rawTotalPositionCollateral, collateralAmount);
    }

    // Ensure individual and global consistency when decrementing collateral balances. Returns the change to the
    // position. We elect to return the amount that the global collateral is decreased by, rather than the individual
    // position's collateral, because we need to maintain the invariant that the global collateral is always
    // <= the collateral owned by the contract to avoid reverts on withdrawals. The amount returned = amount withdrawn.
    function _decrementCollateralBalances(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _removeCollateral(positionData.rawCollateral, collateralAmount);
        return _removeCollateral(rawTotalPositionCollateral, collateralAmount);
    }

    // Ensure individual and global consistency when decrementing collateral balances. Returns the change to the position.
    // This function is similar to the _decrementCollateralBalances function except this function checks position GCR
    // between the decrements. This ensures that collateral removal will not leave the position undercollateralized.
    function _decrementCollateralBalancesCheckGCR(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _removeCollateral(positionData.rawCollateral, collateralAmount);
        require(_checkPositionCollateralization(positionData), "CR below GCR");
        return _removeCollateral(rawTotalPositionCollateral, collateralAmount);
    }

    // These internal functions are supposed to act identically to modifiers, but re-used modifiers
    // unnecessarily increase contract bytecode size.
    // source: https://blog.polymath.network/solidity-tips-and-tricks-to-save-gas-and-reduce-bytecode-size-c44580b218e6
    function _onlyOpenState() internal view {
        require(contractState == ContractState.Open, "Contract state is not OPEN");
    }

    function _onlyPreExpiration() internal view {
        require(getCurrentTime() < expirationTimestamp, "Only callable pre-expiry");
    }

    function _onlyPostExpiration() internal view {
        require(getCurrentTime() >= expirationTimestamp, "Only callable post-expiry");
    }

    function _onlyCollateralizedPosition(address sponsor) internal view {
        require(
            _getFeeAdjustedCollateral(positions[sponsor].rawCollateral).isGreaterThan(0),
            "Position has no collateral"
        );
    }

    // Note: This checks whether an already existing position has a pending withdrawal. This cannot be used on the
    // `create` method because it is possible that `create` is called on a new position (i.e. one without any collateral
    // or tokens outstanding) which would fail the `onlyCollateralizedPosition` modifier on `_getPositionData`.
    function _positionHasNoPendingWithdrawal(address sponsor) internal view {
        require(_getPositionData(sponsor).withdrawalRequestPassTimestamp == 0, "Pending withdrawal");
    }

    /****************************************
     *          PRIVATE FUNCTIONS          *
     ****************************************/

    function _checkPositionCollateralization(PositionData storage positionData) private view returns (bool) {
        return
            _checkCollateralization(
                _getFeeAdjustedCollateral(positionData.rawCollateral),
                positionData.tokensOutstanding
            );
    }

    // Checks whether the provided `collateral` and `numTokens` have a collateralization ratio above the global
    // collateralization ratio.
    function _checkCollateralization(FixedPoint.Unsigned memory collateral, FixedPoint.Unsigned memory numTokens)
        private
        view
        returns (bool)
    {
        FixedPoint.Unsigned memory global =
            _getCollateralizationRatio(_getFeeAdjustedCollateral(rawTotalPositionCollateral), totalTokensOutstanding);
        FixedPoint.Unsigned memory thisChange = _getCollateralizationRatio(collateral, numTokens);
        return !global.isGreaterThan(thisChange);
    }

    function _getCollateralizationRatio(FixedPoint.Unsigned memory collateral, FixedPoint.Unsigned memory numTokens)
        private
        pure
        returns (FixedPoint.Unsigned memory ratio)
    {
        if (!numTokens.isGreaterThan(0)) {
            return FixedPoint.fromUnscaledUint(0);
        } else {
            return collateral.div(numTokens);
        }
    }

    // IERC20Standard.decimals() will revert if the collateral contract has not implemented the decimals() method,
    // which is possible since the method is only an OPTIONAL method in the ERC20 standard:
    // https://eips.ethereum.org/EIPS/eip-20#methods.
    function _getSyntheticDecimals(address _collateralAddress) public view returns (uint8 decimals) {
        try IERC20Standard(_collateralAddress).decimals() returns (uint8 _decimals) {
            return _decimals;
        } catch {
            return 18;
        }
    }

    function _transformPrice(FixedPoint.Unsigned memory price, uint256 requestTime)
        internal
        view
        returns (FixedPoint.Unsigned memory)
    {
        if (!address(financialProductLibrary).isContract()) return price;
        try financialProductLibrary.transformPrice(price, requestTime) returns (
            FixedPoint.Unsigned memory transformedPrice
        ) {
            return transformedPrice;
        } catch {
            return price;
        }
    }

    function _transformPriceIdentifier(uint256 requestTime) internal view returns (bytes32) {
        if (!address(financialProductLibrary).isContract()) return priceIdentifier;
        try financialProductLibrary.transformPriceIdentifier(priceIdentifier, requestTime) returns (
            bytes32 transformedIdentifier
        ) {
            return transformedIdentifier;
        } catch {
            return priceIdentifier;
        }
    }

    function _getAncillaryData() internal view returns (bytes memory) {
        // Note: when ancillary data is passed to the optimistic oracle, it should be tagged with the token address
        // whose funding rate it's trying to get.
        return abi.encodePacked(address(tokenCurrency));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ERC20 interface that includes the decimals read only method.
 */
interface IERC20Standard is IERC20 {
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should be displayed to a user as `5,05`
     * (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei. This is the value
     * {ERC20} uses, unless {_setupDecimals} is called.
     *
     * NOTE: This information is only used for _display_ purposes: it in no way affects any of the arithmetic
     * of the contract, including {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../common/implementation/Lockable.sol";
import "../../common/implementation/FixedPoint.sol";
import "../../common/implementation/Testable.sol";

import "../../oracle/interfaces/StoreInterface.sol";
import "../../oracle/interfaces/FinderInterface.sol";
import "../../oracle/interfaces/AdministrateeInterface.sol";
import "../../oracle/implementation/Constants.sol";

/**
 * @title FeePayer contract.
 * @notice Provides fee payment functionality for the ExpiringMultiParty contract.
 * contract is abstract as each derived contract that inherits `FeePayer` must implement `pfc()`.
 */

abstract contract FeePayer is AdministrateeInterface, Testable, Lockable {
    using SafeMath for uint256;
    using FixedPoint for FixedPoint.Unsigned;
    using SafeERC20 for IERC20;

    /****************************************
     *      FEE PAYER DATA STRUCTURES       *
     ****************************************/

    // The collateral currency used to back the positions in this contract.
    IERC20 public collateralCurrency;

    // Finder contract used to look up addresses for UMA system contracts.
    FinderInterface public finder;

    // Tracks the last block time when the fees were paid.
    uint256 private lastPaymentTime;

    // Tracks the cumulative fees that have been paid by the contract for use by derived contracts.
    // The multiplier starts at 1, and is updated by computing cumulativeFeeMultiplier * (1 - effectiveFee).
    // Put another way, the cumulativeFeeMultiplier is (1 - effectiveFee1) * (1 - effectiveFee2) ...
    // For example:
    // The cumulativeFeeMultiplier should start at 1.
    // If a 1% fee is charged, the multiplier should update to .99.
    // If another 1% fee is charged, the multiplier should be 0.99^2 (0.9801).
    FixedPoint.Unsigned public cumulativeFeeMultiplier;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event RegularFeesPaid(uint256 indexed regularFee, uint256 indexed lateFee);
    event FinalFeesPaid(uint256 indexed amount);

    /****************************************
     *              MODIFIERS               *
     ****************************************/

    // modifier that calls payRegularFees().
    modifier fees virtual {
        // Note: the regular fee is applied on every fee-accruing transaction, where the total change is simply the
        // regular fee applied linearly since the last update. This implies that the compounding rate depends on the
        // frequency of update transactions that have this modifier, and it never reaches the ideal of continuous
        // compounding. This approximate-compounding pattern is common in the Ethereum ecosystem because of the
        // complexity of compounding data on-chain.
        payRegularFees();
        _;
    }

    /**
     * @notice Constructs the FeePayer contract. Called by child contracts.
     * @param _collateralAddress ERC20 token that is used as the underlying collateral for the synthetic.
     * @param _finderAddress UMA protocol Finder used to discover other protocol contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(
        address _collateralAddress,
        address _finderAddress,
        address _timerAddress
    ) public Testable(_timerAddress) {
        collateralCurrency = IERC20(_collateralAddress);
        finder = FinderInterface(_finderAddress);
        lastPaymentTime = getCurrentTime();
        cumulativeFeeMultiplier = FixedPoint.fromUnscaledUint(1);
    }

    /****************************************
     *        FEE PAYMENT FUNCTIONS         *
     ****************************************/

    /**
     * @notice Pays UMA DVM regular fees (as a % of the collateral pool) to the Store contract.
     * @dev These must be paid periodically for the life of the contract. If the contract has not paid its regular fee
     * in a week or more then a late penalty is applied which is sent to the caller. If the amount of
     * fees owed are greater than the pfc, then this will pay as much as possible from the available collateral.
     * An event is only fired if the fees charged are greater than 0.
     * @return totalPaid Amount of collateral that the contract paid (sum of the amount paid to the Store and caller).
     * This returns 0 and exit early if there is no pfc, fees were already paid during the current block, or the fee rate is 0.
     */
    function payRegularFees() public nonReentrant() returns (FixedPoint.Unsigned memory) {
        uint256 time = getCurrentTime();
        FixedPoint.Unsigned memory collateralPool = _pfc();

        // Fetch the regular fees, late penalty and the max possible to pay given the current collateral within the contract.
        (
            FixedPoint.Unsigned memory regularFee,
            FixedPoint.Unsigned memory latePenalty,
            FixedPoint.Unsigned memory totalPaid
        ) = getOutstandingRegularFees(time);
        lastPaymentTime = time;

        // If there are no fees to pay then exit early.
        if (totalPaid.isEqual(0)) {
            return totalPaid;
        }

        emit RegularFeesPaid(regularFee.rawValue, latePenalty.rawValue);

        _adjustCumulativeFeeMultiplier(totalPaid, collateralPool);

        if (regularFee.isGreaterThan(0)) {
            StoreInterface store = _getStore();
            collateralCurrency.safeIncreaseAllowance(address(store), regularFee.rawValue);
            store.payOracleFeesErc20(address(collateralCurrency), regularFee);
        }

        if (latePenalty.isGreaterThan(0)) {
            collateralCurrency.safeTransfer(msg.sender, latePenalty.rawValue);
        }
        return totalPaid;
    }

    /**
     * @notice Fetch any regular fees that the contract has pending but has not yet paid. If the fees to be paid are more
     * than the total collateral within the contract then the totalPaid returned is full contract collateral amount.
     * @dev This returns 0 and exit early if there is no pfc, fees were already paid during the current block, or the fee rate is 0.
     * @return regularFee outstanding unpaid regular fee.
     * @return latePenalty outstanding unpaid late fee for being late in previous fee payments.
     * @return totalPaid Amount of collateral that the contract paid (sum of the amount paid to the Store and caller).
     */
    function getOutstandingRegularFees(uint256 time)
        public
        view
        returns (
            FixedPoint.Unsigned memory regularFee,
            FixedPoint.Unsigned memory latePenalty,
            FixedPoint.Unsigned memory totalPaid
        )
    {
        StoreInterface store = _getStore();
        FixedPoint.Unsigned memory collateralPool = _pfc();

        // Exit early if there is no collateral or if fees were already paid during this block.
        if (collateralPool.isEqual(0) || lastPaymentTime == time) {
            return (regularFee, latePenalty, totalPaid);
        }

        (regularFee, latePenalty) = store.computeRegularFee(lastPaymentTime, time, collateralPool);

        totalPaid = regularFee.add(latePenalty);
        if (totalPaid.isEqual(0)) {
            return (regularFee, latePenalty, totalPaid);
        }
        // If the effective fees paid as a % of the pfc is > 100%, then we need to reduce it and make the contract pay
        // as much of the fee that it can (up to 100% of its pfc). We'll reduce the late penalty first and then the
        // regular fee, which has the effect of paying the store first, followed by the caller if there is any fee remaining.
        if (totalPaid.isGreaterThan(collateralPool)) {
            FixedPoint.Unsigned memory deficit = totalPaid.sub(collateralPool);
            FixedPoint.Unsigned memory latePenaltyReduction = FixedPoint.min(latePenalty, deficit);
            latePenalty = latePenalty.sub(latePenaltyReduction);
            deficit = deficit.sub(latePenaltyReduction);
            regularFee = regularFee.sub(FixedPoint.min(regularFee, deficit));
            totalPaid = collateralPool;
        }
    }

    /**
     * @notice Gets the current profit from corruption for this contract in terms of the collateral currency.
     * @dev This is equivalent to the collateral pool available from which to pay fees. Therefore, derived contracts are
     * expected to implement this so that pay-fee methods can correctly compute the owed fees as a % of PfC.
     * @return pfc value for equal to the current profit from corruption denominated in collateral currency.
     */
    function pfc() external view override nonReentrantView() returns (FixedPoint.Unsigned memory) {
        return _pfc();
    }

    /**
     * @notice Removes excess collateral balance not counted in the PfC by distributing it out pro-rata to all sponsors.
     * @dev Multiplying the `cumulativeFeeMultiplier` by the ratio of non-PfC-collateral :: PfC-collateral effectively
     * pays all sponsors a pro-rata portion of the excess collateral.
     * @dev This will revert if PfC is 0 and this contract's collateral balance > 0.
     */
    function gulp() external nonReentrant() {
        _gulp();
    }

    /****************************************
     *         INTERNAL FUNCTIONS           *
     ****************************************/

    // Pays UMA Oracle final fees of `amount` in `collateralCurrency` to the Store contract. Final fee is a flat fee
    // charged for each price request. If payer is the contract, adjusts internal bookkeeping variables. If payer is not
    // the contract, pulls in `amount` of collateral currency.
    function _payFinalFees(address payer, FixedPoint.Unsigned memory amount) internal {
        if (amount.isEqual(0)) {
            return;
        }

        if (payer != address(this)) {
            // If the payer is not the contract pull the collateral from the payer.
            collateralCurrency.safeTransferFrom(payer, address(this), amount.rawValue);
        } else {
            // If the payer is the contract, adjust the cumulativeFeeMultiplier to compensate.
            FixedPoint.Unsigned memory collateralPool = _pfc();

            // The final fee must be < available collateral or the fee will be larger than 100%.
            // Note: revert reason removed to save bytecode.
            require(collateralPool.isGreaterThan(amount));

            _adjustCumulativeFeeMultiplier(amount, collateralPool);
        }

        emit FinalFeesPaid(amount.rawValue);

        StoreInterface store = _getStore();
        collateralCurrency.safeIncreaseAllowance(address(store), amount.rawValue);
        store.payOracleFeesErc20(address(collateralCurrency), amount);
    }

    function _gulp() internal {
        FixedPoint.Unsigned memory currentPfc = _pfc();
        FixedPoint.Unsigned memory currentBalance = FixedPoint.Unsigned(collateralCurrency.balanceOf(address(this)));
        if (currentPfc.isLessThan(currentBalance)) {
            cumulativeFeeMultiplier = cumulativeFeeMultiplier.mul(currentBalance.div(currentPfc));
        }
    }

    function _pfc() internal view virtual returns (FixedPoint.Unsigned memory);

    function _getStore() internal view returns (StoreInterface) {
        return StoreInterface(finder.getImplementationAddress(OracleInterfaces.Store));
    }

    function _computeFinalFees() internal view returns (FixedPoint.Unsigned memory finalFees) {
        StoreInterface store = _getStore();
        return store.computeFinalFee(address(collateralCurrency));
    }

    // Returns the user's collateral minus any fees that have been subtracted since it was originally
    // deposited into the contract. Note: if the contract has paid fees since it was deployed, the raw
    // value should be larger than the returned value.
    function _getFeeAdjustedCollateral(FixedPoint.Unsigned memory rawCollateral)
        internal
        view
        returns (FixedPoint.Unsigned memory collateral)
    {
        return rawCollateral.mul(cumulativeFeeMultiplier);
    }

    // Returns the user's collateral minus any pending fees that have yet to be subtracted.
    function _getPendingRegularFeeAdjustedCollateral(FixedPoint.Unsigned memory rawCollateral)
        internal
        view
        returns (FixedPoint.Unsigned memory)
    {
        (, , FixedPoint.Unsigned memory currentTotalOutstandingRegularFees) =
            getOutstandingRegularFees(getCurrentTime());
        if (currentTotalOutstandingRegularFees.isEqual(FixedPoint.fromUnscaledUint(0))) return rawCollateral;

        // Calculate the total outstanding regular fee as a fraction of the total contract PFC.
        FixedPoint.Unsigned memory effectiveOutstandingFee = currentTotalOutstandingRegularFees.divCeil(_pfc());

        // Scale as rawCollateral* (1 - effectiveOutstandingFee) to apply the pro-rata amount to the regular fee.
        return rawCollateral.mul(FixedPoint.fromUnscaledUint(1).sub(effectiveOutstandingFee));
    }

    // Converts a user-readable collateral value into a raw value that accounts for already-assessed fees. If any fees
    // have been taken from this contract in the past, then the raw value will be larger than the user-readable value.
    function _convertToRawCollateral(FixedPoint.Unsigned memory collateral)
        internal
        view
        returns (FixedPoint.Unsigned memory rawCollateral)
    {
        return collateral.div(cumulativeFeeMultiplier);
    }

    // Decrease rawCollateral by a fee-adjusted collateralToRemove amount. Fee adjustment scales up collateralToRemove
    // by dividing it by cumulativeFeeMultiplier. There is potential for this quotient to be floored, therefore
    // rawCollateral is decreased by less than expected. Because this method is usually called in conjunction with an
    // actual removal of collateral from this contract, return the fee-adjusted amount that the rawCollateral is
    // decreased by so that the caller can minimize error between collateral removed and rawCollateral debited.
    function _removeCollateral(FixedPoint.Unsigned storage rawCollateral, FixedPoint.Unsigned memory collateralToRemove)
        internal
        returns (FixedPoint.Unsigned memory removedCollateral)
    {
        FixedPoint.Unsigned memory initialBalance = _getFeeAdjustedCollateral(rawCollateral);
        FixedPoint.Unsigned memory adjustedCollateral = _convertToRawCollateral(collateralToRemove);
        rawCollateral.rawValue = rawCollateral.sub(adjustedCollateral).rawValue;
        removedCollateral = initialBalance.sub(_getFeeAdjustedCollateral(rawCollateral));
    }

    // Increase rawCollateral by a fee-adjusted collateralToAdd amount. Fee adjustment scales up collateralToAdd
    // by dividing it by cumulativeFeeMultiplier. There is potential for this quotient to be floored, therefore
    // rawCollateral is increased by less than expected. Because this method is usually called in conjunction with an
    // actual addition of collateral to this contract, return the fee-adjusted amount that the rawCollateral is
    // increased by so that the caller can minimize error between collateral added and rawCollateral credited.
    // NOTE: This return value exists only for the sake of symmetry with _removeCollateral. We don't actually use it
    // because we are OK if more collateral is stored in the contract than is represented by rawTotalPositionCollateral.
    function _addCollateral(FixedPoint.Unsigned storage rawCollateral, FixedPoint.Unsigned memory collateralToAdd)
        internal
        returns (FixedPoint.Unsigned memory addedCollateral)
    {
        FixedPoint.Unsigned memory initialBalance = _getFeeAdjustedCollateral(rawCollateral);
        FixedPoint.Unsigned memory adjustedCollateral = _convertToRawCollateral(collateralToAdd);
        rawCollateral.rawValue = rawCollateral.add(adjustedCollateral).rawValue;
        addedCollateral = _getFeeAdjustedCollateral(rawCollateral).sub(initialBalance);
    }

    // Scale the cumulativeFeeMultiplier by the ratio of fees paid to the current available collateral.
    function _adjustCumulativeFeeMultiplier(FixedPoint.Unsigned memory amount, FixedPoint.Unsigned memory currentPfc)
        internal
    {
        FixedPoint.Unsigned memory effectiveFee = amount.divCeil(currentPfc);
        cumulativeFeeMultiplier = cumulativeFeeMultiplier.mul(FixedPoint.fromUnscaledUint(1).sub(effectiveFee));
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "../../../common/implementation/FixedPoint.sol";

interface ExpiringContractInterface {
    function expirationTimestamp() external view returns (uint256);
}

/**
 * @title Financial product library contract
 * @notice Provides price and collateral requirement transformation interfaces that can be overridden by custom
 * Financial product library implementations.
 */
abstract contract FinancialProductLibrary {
    using FixedPoint for FixedPoint.Unsigned;

    /**
     * @notice Transforms a given oracle price using the financial product libraries transformation logic.
     * @param oraclePrice input price returned by the DVM to be transformed.
     * @param requestTime timestamp the oraclePrice was requested at.
     * @return transformedOraclePrice input oraclePrice with the transformation function applied.
     */
    function transformPrice(FixedPoint.Unsigned memory oraclePrice, uint256 requestTime)
        public
        view
        virtual
        returns (FixedPoint.Unsigned memory)
    {
        return oraclePrice;
    }

    /**
     * @notice Transforms a given collateral requirement using the financial product libraries transformation logic.
     * @param oraclePrice input price returned by DVM used to transform the collateral requirement.
     * @param collateralRequirement input collateral requirement to be transformed.
     * @return transformedCollateralRequirement input collateral requirement with the transformation function applied.
     */
    function transformCollateralRequirement(
        FixedPoint.Unsigned memory oraclePrice,
        FixedPoint.Unsigned memory collateralRequirement
    ) public view virtual returns (FixedPoint.Unsigned memory) {
        return collateralRequirement;
    }

    /**
     * @notice Transforms a given price identifier using the financial product libraries transformation logic.
     * @param priceIdentifier input price identifier defined for the financial contract.
     * @param requestTime timestamp the identifier is to be used at. EG the time that a price request would be sent using this identifier.
     * @return transformedPriceIdentifier input price identifier with the transformation function applied.
     */
    function transformPriceIdentifier(bytes32 priceIdentifier, uint256 requestTime)
        public
        view
        virtual
        returns (bytes32)
    {
        return priceIdentifier;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/implementation/FixedPoint.sol";

/**
 * @title Interface that all financial contracts expose to the admin.
 */
interface AdministrateeInterface {
    /**
     * @notice Initiates the shutdown process, in case of an emergency.
     */
    function emergencyShutdown() external;

    /**
     * @notice A core contract method called independently or as a part of other financial contract transactions.
     * @dev It pays fees and moves money between margin accounts to make sure they reflect the NAV of the contract.
     */
    function remargin() external;

    /**
     * @notice Gets the current profit from corruption for this contract in terms of the collateral currency.
     * @dev This is equivalent to the collateral pool available from which to pay fees. Therefore, derived contracts are
     * expected to implement this so that pay-fee methods can correctly compute the owed fees as a % of PfC.
     * @return pfc value for equal to the current profit from corruption denominated in collateral currency.
     */
    function pfc() external view returns (FixedPoint.Unsigned memory);
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "../common/financial-product-libraries/FinancialProductLibrary.sol";

// Implements a simple FinancialProductLibrary to test price and collateral requirement transoformations.
contract FinancialProductLibraryTest is FinancialProductLibrary {
    FixedPoint.Unsigned public priceTransformationScalar;
    FixedPoint.Unsigned public collateralRequirementTransformationScalar;
    bytes32 public transformedPriceIdentifier;
    bool public shouldRevert;

    constructor(
        FixedPoint.Unsigned memory _priceTransformationScalar,
        FixedPoint.Unsigned memory _collateralRequirementTransformationScalar,
        bytes32 _transformedPriceIdentifier
    ) public {
        priceTransformationScalar = _priceTransformationScalar;
        collateralRequirementTransformationScalar = _collateralRequirementTransformationScalar;
        transformedPriceIdentifier = _transformedPriceIdentifier;
    }

    // Set the mocked methods to revert to test failed library computation.
    function setShouldRevert(bool _shouldRevert) public {
        shouldRevert = _shouldRevert;
    }

    // Create a simple price transformation function that scales the input price by the scalar for testing.
    function transformPrice(FixedPoint.Unsigned memory oraclePrice, uint256 requestTime)
        public
        view
        override
        returns (FixedPoint.Unsigned memory)
    {
        require(!shouldRevert, "set to always reverts");
        return oraclePrice.mul(priceTransformationScalar);
    }

    // Create a simple collateral requirement transformation that doubles the input collateralRequirement.
    function transformCollateralRequirement(
        FixedPoint.Unsigned memory price,
        FixedPoint.Unsigned memory collateralRequirement
    ) public view override returns (FixedPoint.Unsigned memory) {
        require(!shouldRevert, "set to always reverts");
        return collateralRequirement.mul(collateralRequirementTransformationScalar);
    }

    // Create a simple transformPriceIdentifier function that returns the transformed price identifier.
    function transformPriceIdentifier(bytes32 priceIdentifier, uint256 requestTime)
        public
        view
        override
        returns (bytes32)
    {
        require(!shouldRevert, "set to always reverts");
        return transformedPriceIdentifier;
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/implementation/Testable.sol";
import "../../common/implementation/FixedPoint.sol";
import "../common/financial-product-libraries/FinancialProductLibrary.sol";

contract ExpiringMultiPartyMock is Testable {
    using FixedPoint for FixedPoint.Unsigned;

    FinancialProductLibrary public financialProductLibrary;
    uint256 public expirationTimestamp;
    FixedPoint.Unsigned public collateralRequirement;
    bytes32 public priceIdentifier;

    constructor(
        address _financialProductLibraryAddress,
        uint256 _expirationTimestamp,
        FixedPoint.Unsigned memory _collateralRequirement,
        bytes32 _priceIdentifier,
        address _timerAddress
    ) public Testable(_timerAddress) {
        expirationTimestamp = _expirationTimestamp;
        collateralRequirement = _collateralRequirement;
        financialProductLibrary = FinancialProductLibrary(_financialProductLibraryAddress);
        priceIdentifier = _priceIdentifier;
    }

    function transformPrice(FixedPoint.Unsigned memory price, uint256 requestTime)
        public
        view
        returns (FixedPoint.Unsigned memory)
    {
        if (address(financialProductLibrary) == address(0)) return price;
        try financialProductLibrary.transformPrice(price, requestTime) returns (
            FixedPoint.Unsigned memory transformedPrice
        ) {
            return transformedPrice;
        } catch {
            return price;
        }
    }

    function transformCollateralRequirement(FixedPoint.Unsigned memory price)
        public
        view
        returns (FixedPoint.Unsigned memory)
    {
        if (address(financialProductLibrary) == address(0)) return collateralRequirement;
        try financialProductLibrary.transformCollateralRequirement(price, collateralRequirement) returns (
            FixedPoint.Unsigned memory transformedCollateralRequirement
        ) {
            return transformedCollateralRequirement;
        } catch {
            return collateralRequirement;
        }
    }

    function transformPriceIdentifier(uint256 requestTime) public view returns (bytes32) {
        if (address(financialProductLibrary) == address(0)) return priceIdentifier;
        try financialProductLibrary.transformPriceIdentifier(priceIdentifier, requestTime) returns (
            bytes32 transformedIdentifier
        ) {
            return transformedIdentifier;
        } catch {
            return priceIdentifier;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;
import "../../common/implementation/FixedPoint.sol";
import "../../common/implementation/Testable.sol";
import "../interfaces/OracleAncillaryInterface.sol";
import "../interfaces/VotingAncillaryInterface.sol";

// A mock oracle used for testing. Exports the voting & oracle interfaces and events that contain ancillary data.
abstract contract VotingAncillaryInterfaceTesting is OracleAncillaryInterface, VotingAncillaryInterface, Testable {
    using FixedPoint for FixedPoint.Unsigned;

    // Events, data structures and functions not exported in the base interfaces, used for testing.
    event VoteCommitted(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData
    );

    event EncryptedVote(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        bytes encryptedVote
    );

    event VoteRevealed(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        int256 price,
        bytes ancillaryData,
        uint256 numTokens
    );

    event RewardsRetrieved(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        uint256 numTokens
    );

    event PriceRequestAdded(uint256 indexed roundId, bytes32 indexed identifier, uint256 time);

    event PriceResolved(
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        int256 price,
        bytes ancillaryData
    );

    struct Round {
        uint256 snapshotId; // Voting token snapshot ID for this round.  0 if no snapshot has been taken.
        FixedPoint.Unsigned inflationRate; // Inflation rate set for this round.
        FixedPoint.Unsigned gatPercentage; // Gat rate set for this round.
        uint256 rewardsExpirationTime; // Time that rewards for this round can be claimed until.
    }

    // Represents the status a price request has.
    enum RequestStatus {
        NotRequested, // Was never requested.
        Active, // Is being voted on in the current round.
        Resolved, // Was resolved in a previous round.
        Future // Is scheduled to be voted on in a future round.
    }

    // Only used as a return value in view methods -- never stored in the contract.
    struct RequestState {
        RequestStatus status;
        uint256 lastVotingRound;
    }

    function rounds(uint256 roundId) public view virtual returns (Round memory);

    function getPriceRequestStatuses(VotingAncillaryInterface.PendingRequestAncillary[] memory requests)
        public
        view
        virtual
        returns (RequestState[] memory);

    function getPendingPriceRequestsArray() external view virtual returns (bytes32[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/implementation/MultiRole.sol";
import "../../common/implementation/Withdrawable.sol";
import "../interfaces/VotingAncillaryInterface.sol";
import "../interfaces/FinderInterface.sol";
import "./Constants.sol";

/**
 * @title Proxy to allow voting from another address.
 * @dev Allows a UMA token holder to designate another address to vote on their behalf.
 * Each voter must deploy their own instance of this contract.
 */
contract DesignatedVoting is Withdrawable {
    /****************************************
     *    INTERNAL VARIABLES AND STORAGE    *
     ****************************************/

    enum Roles {
        Owner, // Can set the Voter role. Is also permanently permissioned as the minter role.
        Voter // Can vote through this contract.
    }

    // Reference to the UMA Finder contract, allowing Voting upgrades to be performed
    // without requiring any calls to this contract.
    FinderInterface private finder;

    /**
     * @notice Construct the DesignatedVoting contract.
     * @param finderAddress keeps track of all contracts within the system based on their interfaceName.
     * @param ownerAddress address of the owner of the DesignatedVoting contract.
     * @param voterAddress address to which the owner has delegated their voting power.
     */
    constructor(
        address finderAddress,
        address ownerAddress,
        address voterAddress
    ) public {
        _createExclusiveRole(uint256(Roles.Owner), uint256(Roles.Owner), ownerAddress);
        _createExclusiveRole(uint256(Roles.Voter), uint256(Roles.Owner), voterAddress);
        _setWithdrawRole(uint256(Roles.Owner));

        finder = FinderInterface(finderAddress);
    }

    /****************************************
     *   VOTING AND REWARD FUNCTIONALITY    *
     ****************************************/

    /**
     * @notice Forwards a commit to Voting.
     * @param identifier uniquely identifies the feed for this vote. EG BTC/USD price pair.
     * @param time specifies the unix timestamp of the price being voted on.
     * @param hash the keccak256 hash of the price you want to vote for and a random integer salt value.
     */
    function commitVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash
    ) external onlyRoleHolder(uint256(Roles.Voter)) {
        _getVotingAddress().commitVote(identifier, time, ancillaryData, hash);
    }

    /**
     * @notice Forwards a batch commit to Voting.
     * @param commits struct to encapsulate an `identifier`, `time`, `hash` and optional `encryptedVote`.
     */
    function batchCommit(VotingAncillaryInterface.CommitmentAncillary[] calldata commits)
        external
        onlyRoleHolder(uint256(Roles.Voter))
    {
        _getVotingAddress().batchCommit(commits);
    }

    /**
     * @notice Forwards a reveal to Voting.
     * @param identifier voted on in the commit phase. EG BTC/USD price pair.
     * @param time specifies the unix timestamp of the price being voted on.
     * @param price used along with the `salt` to produce the `hash` during the commit phase.
     * @param salt used along with the `price` to produce the `hash` during the commit phase.
     */
    function revealVote(
        bytes32 identifier,
        uint256 time,
        int256 price,
        bytes memory ancillaryData,
        int256 salt
    ) external onlyRoleHolder(uint256(Roles.Voter)) {
        _getVotingAddress().revealVote(identifier, time, price, ancillaryData, salt);
    }

    /**
     * @notice Forwards a batch reveal to Voting.
     * @param reveals is an array of the Reveal struct which contains an identifier, time, price and salt.
     */
    function batchReveal(VotingAncillaryInterface.RevealAncillary[] calldata reveals)
        external
        onlyRoleHolder(uint256(Roles.Voter))
    {
        _getVotingAddress().batchReveal(reveals);
    }

    /**
     * @notice Forwards a reward retrieval to Voting.
     * @dev Rewards are added to the tokens already held by this contract.
     * @param roundId defines the round from which voting rewards will be retrieved from.
     * @param toRetrieve an array of PendingRequests which rewards are retrieved from.
     * @return amount of rewards that the user should receive.
     */
    function retrieveRewards(uint256 roundId, VotingAncillaryInterface.PendingRequestAncillary[] memory toRetrieve)
        public
        onlyRoleHolder(uint256(Roles.Voter))
        returns (FixedPoint.Unsigned memory)
    {
        return _getVotingAddress().retrieveRewards(address(this), roundId, toRetrieve);
    }

    function _getVotingAddress() private view returns (VotingAncillaryInterface) {
        return VotingAncillaryInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/implementation/Withdrawable.sol";
import "./DesignatedVoting.sol";

/**
 * @title Factory to deploy new instances of DesignatedVoting and look up previously deployed instances.
 * @dev Allows off-chain infrastructure to look up a hot wallet's deployed DesignatedVoting contract.
 */
contract DesignatedVotingFactory is Withdrawable {
    /****************************************
     *    INTERNAL VARIABLES AND STORAGE    *
     ****************************************/

    enum Roles {
        Withdrawer // Can withdraw any ETH or ERC20 sent accidentally to this contract.
    }

    address private finder;
    mapping(address => DesignatedVoting) public designatedVotingContracts;

    /**
     * @notice Construct the DesignatedVotingFactory contract.
     * @param finderAddress keeps track of all contracts within the system based on their interfaceName.
     */
    constructor(address finderAddress) public {
        finder = finderAddress;

        _createWithdrawRole(uint256(Roles.Withdrawer), uint256(Roles.Withdrawer), msg.sender);
    }

    /**
     * @notice Deploys a new `DesignatedVoting` contract.
     * @param ownerAddress defines who will own the deployed instance of the designatedVoting contract.
     * @return designatedVoting a new DesignatedVoting contract.
     */
    function newDesignatedVoting(address ownerAddress) external returns (DesignatedVoting) {
        require(address(designatedVotingContracts[msg.sender]) == address(0), "Duplicate hot key not permitted");

        DesignatedVoting designatedVoting = new DesignatedVoting(finder, ownerAddress, msg.sender);
        designatedVotingContracts[msg.sender] = designatedVoting;
        return designatedVoting;
    }

    /**
     * @notice Associates a `DesignatedVoting` instance with `msg.sender`.
     * @param designatedVotingAddress address to designate voting to.
     * @dev This is generally only used if the owner of a `DesignatedVoting` contract changes their `voter`
     * address and wants that reflected here.
     */
    function setDesignatedVoting(address designatedVotingAddress) external {
        require(address(designatedVotingContracts[msg.sender]) == address(0), "Duplicate hot key not permitted");
        designatedVotingContracts[msg.sender] = DesignatedVoting(designatedVotingAddress);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../implementation/Withdrawable.sol";

// WithdrawableTest is derived from the abstract contract Withdrawable for testing purposes.
contract WithdrawableTest is Withdrawable {
    enum Roles { Governance, Withdraw }

    // solhint-disable-next-line no-empty-blocks
    constructor() public {
        _createExclusiveRole(uint256(Roles.Governance), uint256(Roles.Governance), msg.sender);
        _createWithdrawRole(uint256(Roles.Withdraw), uint256(Roles.Governance), msg.sender);
    }

    function pay() external payable {
        require(msg.value > 0);
    }

    function setInternalWithdrawRole(uint256 setRoleId) public {
        _setWithdrawRole(setRoleId);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title An implementation of ERC20 with the same interface as the Compound project's testnet tokens (mainly DAI)
 * @dev This contract can be deployed or the interface can be used to communicate with Compound's ERC20 tokens.  Note:
 * this token should never be used to store real value since it allows permissionless minting.
 */
contract TestnetERC20 is ERC20 {
    /**
     * @notice Constructs the TestnetERC20.
     * @param _name The name which describes the new token.
     * @param _symbol The ticker abbreviation of the name. Ideally < 5 chars.
     * @param _decimals The number of decimals to define token precision.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
    }

    // Sample token information.

    /**
     * @notice Mints value tokens to the owner address.
     * @param ownerAddress the address to mint to.
     * @param value the amount of tokens to mint.
     */
    function allocateTo(address ownerAddress, uint256 value) external {
        _mint(ownerAddress, value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../interfaces/IdentifierWhitelistInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Stores a whitelist of supported identifiers that the oracle can provide prices for.
 */
contract IdentifierWhitelist is IdentifierWhitelistInterface, Ownable {
    /****************************************
     *     INTERNAL VARIABLES AND STORAGE   *
     ****************************************/

    mapping(bytes32 => bool) private supportedIdentifiers;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event SupportedIdentifierAdded(bytes32 indexed identifier);
    event SupportedIdentifierRemoved(bytes32 indexed identifier);

    /****************************************
     *    ADMIN STATE MODIFYING FUNCTIONS   *
     ****************************************/

    /**
     * @notice Adds the provided identifier as a supported identifier.
     * @dev Price requests using this identifier will succeed after this call.
     * @param identifier unique UTF-8 representation for the feed being added. Eg: BTC/USD.
     */
    function addSupportedIdentifier(bytes32 identifier) external override onlyOwner {
        if (!supportedIdentifiers[identifier]) {
            supportedIdentifiers[identifier] = true;
            emit SupportedIdentifierAdded(identifier);
        }
    }

    /**
     * @notice Removes the identifier from the whitelist.
     * @dev Price requests using this identifier will no longer succeed after this call.
     * @param identifier unique UTF-8 representation for the feed being removed. Eg: BTC/USD.
     */
    function removeSupportedIdentifier(bytes32 identifier) external override onlyOwner {
        if (supportedIdentifiers[identifier]) {
            supportedIdentifiers[identifier] = false;
            emit SupportedIdentifierRemoved(identifier);
        }
    }

    /****************************************
     *     WHITELIST GETTERS FUNCTIONS      *
     ****************************************/

    /**
     * @notice Checks whether an identifier is on the whitelist.
     * @param identifier unique UTF-8 representation for the feed being queried. Eg: BTC/USD.
     * @return bool if the identifier is supported (or not).
     */
    function isIdentifierSupported(bytes32 identifier) external view override returns (bool) {
        return supportedIdentifiers[identifier];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../interfaces/AdministrateeInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Admin for financial contracts in the UMA system.
 * @dev Allows appropriately permissioned admin roles to interact with financial contracts.
 */
contract FinancialContractsAdmin is Ownable {
    /**
     * @notice Calls emergency shutdown on the provided financial contract.
     * @param financialContract address of the FinancialContract to be shut down.
     */
    function callEmergencyShutdown(address financialContract) external onlyOwner {
        AdministrateeInterface administratee = AdministrateeInterface(financialContract);
        administratee.emergencyShutdown();
    }

    /**
     * @notice Calls remargin on the provided financial contract.
     * @param financialContract address of the FinancialContract to be remargined.
     */
    function callRemargin(address financialContract) external onlyOwner {
        AdministrateeInterface administratee = AdministrateeInterface(financialContract);
        administratee.remargin();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../interfaces/AdministrateeInterface.sol";

// A mock implementation of AdministrateeInterface, taking the place of a financial contract.
contract MockAdministratee is AdministrateeInterface {
    uint256 public timesRemargined;
    uint256 public timesEmergencyShutdown;

    function remargin() external override {
        timesRemargined++;
    }

    function emergencyShutdown() external override {
        timesEmergencyShutdown++;
    }

    function pfc() external view override returns (FixedPoint.Unsigned memory) {
        return FixedPoint.fromUnscaledUint(0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../common/FeePayer.sol";

import "../../common/implementation/FixedPoint.sol";

import "../../oracle/interfaces/IdentifierWhitelistInterface.sol";
import "../../oracle/interfaces/OracleInterface.sol";
import "../../oracle/implementation/ContractCreator.sol";

/**
 * @title Token Deposit Box
 * @notice This is a minimal example of a financial template that depends on price requests from the DVM.
 * This contract should be thought of as a "Deposit Box" into which the user deposits some ERC20 collateral.
 * The main feature of this box is that the user can withdraw their ERC20 corresponding to a desired USD amount.
 * When the user wants to make a withdrawal, a price request is enqueued with the UMA DVM.
 * For simplicty, the user is constrained to have one outstanding withdrawal request at any given time.
 * Regular fees are charged on the collateral in the deposit box throughout the lifetime of the deposit box,
 * and final fees are charged on each price request.
 *
 * This example is intended to accompany a technical tutorial for how to integrate the DVM into a project.
 * The main feature this demo serves to showcase is how to build a financial product on-chain that "pulls" price
 * requests from the DVM on-demand, which is an implementation of the "priceless" oracle framework.
 *
 * The typical user flow would be:
 * - User sets up a deposit box for the (wETH - USD) price-identifier. The "collateral currency" in this deposit
 *   box is therefore wETH.
 *   The user can subsequently make withdrawal requests for USD-denominated amounts of wETH.
 * - User deposits 10 wETH into their deposit box.
 * - User later requests to withdraw $100 USD of wETH.
 * - DepositBox asks DVM for latest wETH/USD exchange rate.
 * - DVM resolves the exchange rate at: 1 wETH is worth 200 USD.
 * - DepositBox transfers 0.5 wETH to user.
 */
contract DepositBox is FeePayer, ContractCreator {
    using SafeMath for uint256;
    using FixedPoint for FixedPoint.Unsigned;
    using SafeERC20 for IERC20;

    // Represents a single caller's deposit box. All collateral is held by this contract.
    struct DepositBoxData {
        // Requested amount of collateral, denominated in quote asset of the price identifier.
        // Example: If the price identifier is wETH-USD, and the `withdrawalRequestAmount = 100`, then
        // this represents a withdrawal request for 100 USD worth of wETH.
        FixedPoint.Unsigned withdrawalRequestAmount;
        // Timestamp of the latest withdrawal request. A withdrawal request is pending if `requestPassTimestamp != 0`.
        uint256 requestPassTimestamp;
        // Raw collateral value. This value should never be accessed directly -- always use _getFeeAdjustedCollateral().
        // To add or remove collateral, use _addCollateral() and _removeCollateral().
        FixedPoint.Unsigned rawCollateral;
    }

    // Maps addresses to their deposit boxes. Each address can have only one position.
    mapping(address => DepositBoxData) private depositBoxes;

    // Unique identifier for DVM price feed ticker.
    bytes32 private priceIdentifier;

    // Similar to the rawCollateral in DepositBoxData, this value should not be used directly.
    // _getFeeAdjustedCollateral(), _addCollateral() and _removeCollateral() must be used to access and adjust.
    FixedPoint.Unsigned private rawTotalDepositBoxCollateral;

    // This blocks every public state-modifying method until it flips to true, via the `initialize()` method.
    bool private initialized;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event NewDepositBox(address indexed user);
    event EndedDepositBox(address indexed user);
    event Deposit(address indexed user, uint256 indexed collateralAmount);
    event RequestWithdrawal(address indexed user, uint256 indexed collateralAmount, uint256 requestPassTimestamp);
    event RequestWithdrawalExecuted(
        address indexed user,
        uint256 indexed collateralAmount,
        uint256 exchangeRate,
        uint256 requestPassTimestamp
    );
    event RequestWithdrawalCanceled(
        address indexed user,
        uint256 indexed collateralAmount,
        uint256 requestPassTimestamp
    );

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    modifier noPendingWithdrawal(address user) {
        _depositBoxHasNoPendingWithdrawal(user);
        _;
    }

    modifier isInitialized() {
        _isInitialized();
        _;
    }

    /****************************************
     *           PUBLIC FUNCTIONS           *
     ****************************************/

    /**
     * @notice Construct the DepositBox.
     * @param _collateralAddress ERC20 token to be deposited.
     * @param _finderAddress UMA protocol Finder used to discover other protocol contracts.
     * @param _priceIdentifier registered in the DVM, used to price the ERC20 deposited.
     * The price identifier consists of a "base" asset and a "quote" asset. The "base" asset corresponds to the collateral ERC20
     * currency deposited into this account, and it is denominated in the "quote" asset on withdrawals.
     * An example price identifier would be "ETH-USD" which will resolve and return the USD price of ETH.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(
        address _collateralAddress,
        address _finderAddress,
        bytes32 _priceIdentifier,
        address _timerAddress
    )
        public
        ContractCreator(_finderAddress)
        FeePayer(_collateralAddress, _finderAddress, _timerAddress)
        nonReentrant()
    {
        require(_getIdentifierWhitelist().isIdentifierSupported(_priceIdentifier), "Unsupported price identifier");

        priceIdentifier = _priceIdentifier;
    }

    /**
     * @notice This should be called after construction of the DepositBox and handles registration with the Registry, which is required
     * to make price requests in production environments.
     * @dev This contract must hold the `ContractCreator` role with the Registry in order to register itself as a financial-template with the DVM.
     * Note that `_registerContract` cannot be called from the constructor because this contract first needs to be given the `ContractCreator` role
     * in order to register with the `Registry`. But, its address is not known until after deployment.
     */
    function initialize() public nonReentrant() {
        initialized = true;
        _registerContract(new address[](0), address(this));
    }

    /**
     * @notice Transfers `collateralAmount` of `collateralCurrency` into caller's deposit box.
     * @dev This contract must be approved to spend at least `collateralAmount` of `collateralCurrency`.
     * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
     */
    function deposit(FixedPoint.Unsigned memory collateralAmount) public isInitialized() fees() nonReentrant() {
        require(collateralAmount.isGreaterThan(0), "Invalid collateral amount");
        DepositBoxData storage depositBoxData = depositBoxes[msg.sender];
        if (_getFeeAdjustedCollateral(depositBoxData.rawCollateral).isEqual(0)) {
            emit NewDepositBox(msg.sender);
        }

        // Increase the individual deposit box and global collateral balance by collateral amount.
        _incrementCollateralBalances(depositBoxData, collateralAmount);

        emit Deposit(msg.sender, collateralAmount.rawValue);

        // Move collateral currency from sender to contract.
        collateralCurrency.safeTransferFrom(msg.sender, address(this), collateralAmount.rawValue);
    }

    /**
     * @notice Starts a withdrawal request that allows the sponsor to withdraw `denominatedCollateralAmount`
     * from their position denominated in the quote asset of the price identifier, following a DVM price resolution.
     * @dev The request will be pending for the duration of the DVM vote and can be cancelled at any time.
     * Only one withdrawal request can exist for the user.
     * @param denominatedCollateralAmount the quote-asset denominated amount of collateral requested to withdraw.
     */
    function requestWithdrawal(FixedPoint.Unsigned memory denominatedCollateralAmount)
        public
        isInitialized()
        noPendingWithdrawal(msg.sender)
        nonReentrant()
    {
        DepositBoxData storage depositBoxData = depositBoxes[msg.sender];
        require(denominatedCollateralAmount.isGreaterThan(0), "Invalid collateral amount");

        // Update the position object for the user.
        depositBoxData.withdrawalRequestAmount = denominatedCollateralAmount;
        depositBoxData.requestPassTimestamp = getCurrentTime();

        emit RequestWithdrawal(msg.sender, denominatedCollateralAmount.rawValue, depositBoxData.requestPassTimestamp);

        // Every price request costs a fixed fee. Check that this user has enough deposited to cover the final fee.
        FixedPoint.Unsigned memory finalFee = _computeFinalFees();
        require(
            _getFeeAdjustedCollateral(depositBoxData.rawCollateral).isGreaterThanOrEqual(finalFee),
            "Cannot pay final fee"
        );
        _payFinalFees(address(this), finalFee);
        // A price request is sent for the current timestamp.
        _requestOraclePrice(depositBoxData.requestPassTimestamp);
    }

    /**
     * @notice After a passed withdrawal request (i.e., by a call to `requestWithdrawal` and subsequent DVM price resolution),
     * withdraws `depositBoxData.withdrawalRequestAmount` of collateral currency denominated in the quote asset.
     * @dev Might not withdraw the full requested amount in order to account for precision loss or if the full requested
     * amount exceeds the collateral in the position (due to paying fees).
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function executeWithdrawal()
        external
        isInitialized()
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        DepositBoxData storage depositBoxData = depositBoxes[msg.sender];
        require(
            depositBoxData.requestPassTimestamp != 0 && depositBoxData.requestPassTimestamp <= getCurrentTime(),
            "Invalid withdraw request"
        );

        // Get the resolved price or revert.
        FixedPoint.Unsigned memory exchangeRate = _getOraclePrice(depositBoxData.requestPassTimestamp);

        // Calculate denomated amount of collateral based on resolved exchange rate.
        // Example 1: User wants to withdraw $100 of ETH, exchange rate is $200/ETH, therefore user to receive 0.5 ETH.
        // Example 2: User wants to withdraw $250 of ETH, exchange rate is $200/ETH, therefore user to receive 1.25 ETH.
        FixedPoint.Unsigned memory denominatedAmountToWithdraw =
            depositBoxData.withdrawalRequestAmount.div(exchangeRate);

        // If withdrawal request amount is > collateral, then withdraw the full collateral amount and delete the deposit box data.
        if (denominatedAmountToWithdraw.isGreaterThan(_getFeeAdjustedCollateral(depositBoxData.rawCollateral))) {
            denominatedAmountToWithdraw = _getFeeAdjustedCollateral(depositBoxData.rawCollateral);

            // Reset the position state as all the value has been removed after settlement.
            emit EndedDepositBox(msg.sender);
        }

        // Decrease the individual deposit box and global collateral balance.
        amountWithdrawn = _decrementCollateralBalances(depositBoxData, denominatedAmountToWithdraw);

        emit RequestWithdrawalExecuted(
            msg.sender,
            amountWithdrawn.rawValue,
            exchangeRate.rawValue,
            depositBoxData.requestPassTimestamp
        );

        // Reset withdrawal request by setting withdrawal request timestamp to 0.
        _resetWithdrawalRequest(depositBoxData);

        // Transfer approved withdrawal amount from the contract to the caller.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
    }

    /**
     * @notice Cancels a pending withdrawal request.
     */
    function cancelWithdrawal() external isInitialized() nonReentrant() {
        DepositBoxData storage depositBoxData = depositBoxes[msg.sender];
        require(depositBoxData.requestPassTimestamp != 0, "No pending withdrawal");

        emit RequestWithdrawalCanceled(
            msg.sender,
            depositBoxData.withdrawalRequestAmount.rawValue,
            depositBoxData.requestPassTimestamp
        );

        // Reset withdrawal request by setting withdrawal request timestamp to 0.
        _resetWithdrawalRequest(depositBoxData);
    }

    /**
     * @notice `emergencyShutdown` and `remargin` are required to be implemented by all financial contracts and exposed to the DVM, but
     * because this is a minimal demo they will simply exit silently.
     */
    function emergencyShutdown() external override isInitialized() nonReentrant() {
        return;
    }

    /**
     * @notice Same comment as `emergencyShutdown`. For the sake of simplicity, this will simply exit silently.
     */
    function remargin() external override isInitialized() nonReentrant() {
        return;
    }

    /**
     * @notice Accessor method for a user's collateral.
     * @dev This is necessary because the struct returned by the depositBoxes() method shows
     * rawCollateral, which isn't a user-readable value.
     * @param user address whose collateral amount is retrieved.
     * @return the fee-adjusted collateral amount in the deposit box (i.e. available for withdrawal).
     */
    function getCollateral(address user) external view nonReentrantView() returns (FixedPoint.Unsigned memory) {
        return _getFeeAdjustedCollateral(depositBoxes[user].rawCollateral);
    }

    /**
     * @notice Accessor method for the total collateral stored within the entire contract.
     * @return the total fee-adjusted collateral amount in the contract (i.e. across all users).
     */
    function totalDepositBoxCollateral() external view nonReentrantView() returns (FixedPoint.Unsigned memory) {
        return _getFeeAdjustedCollateral(rawTotalDepositBoxCollateral);
    }

    /****************************************
     *          INTERNAL FUNCTIONS          *
     ****************************************/

    // Requests a price for `priceIdentifier` at `requestedTime` from the Oracle.
    function _requestOraclePrice(uint256 requestedTime) internal {
        OracleInterface oracle = _getOracle();
        oracle.requestPrice(priceIdentifier, requestedTime);
    }

    // Ensure individual and global consistency when increasing collateral balances. Returns the change to the position.
    function _incrementCollateralBalances(
        DepositBoxData storage depositBoxData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _addCollateral(depositBoxData.rawCollateral, collateralAmount);
        return _addCollateral(rawTotalDepositBoxCollateral, collateralAmount);
    }

    // Ensure individual and global consistency when decrementing collateral balances. Returns the change to the
    // position. We elect to return the amount that the global collateral is decreased by, rather than the individual
    // position's collateral, because we need to maintain the invariant that the global collateral is always
    // <= the collateral owned by the contract to avoid reverts on withdrawals. The amount returned = amount withdrawn.
    function _decrementCollateralBalances(
        DepositBoxData storage depositBoxData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _removeCollateral(depositBoxData.rawCollateral, collateralAmount);
        return _removeCollateral(rawTotalDepositBoxCollateral, collateralAmount);
    }

    function _resetWithdrawalRequest(DepositBoxData storage depositBoxData) internal {
        depositBoxData.withdrawalRequestAmount = FixedPoint.fromUnscaledUint(0);
        depositBoxData.requestPassTimestamp = 0;
    }

    function _depositBoxHasNoPendingWithdrawal(address user) internal view {
        require(depositBoxes[user].requestPassTimestamp == 0, "Pending withdrawal");
    }

    function _isInitialized() internal view {
        require(initialized, "Uninitialized contract");
    }

    function _getIdentifierWhitelist() internal view returns (IdentifierWhitelistInterface) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }

    function _getOracle() internal view returns (OracleInterface) {
        return OracleInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
    }

    // Fetches a resolved Oracle price from the Oracle. Reverts if the Oracle hasn't resolved for this request.
    function _getOraclePrice(uint256 requestedTime) internal view returns (FixedPoint.Unsigned memory) {
        OracleInterface oracle = _getOracle();
        require(oracle.hasPrice(priceIdentifier, requestedTime), "Unresolved oracle price");
        int256 oraclePrice = oracle.getPrice(priceIdentifier, requestedTime);

        // For simplicity we don't want to deal with negative prices.
        if (oraclePrice < 0) {
            oraclePrice = 0;
        }
        return FixedPoint.Unsigned(uint256(oraclePrice));
    }

    // `_pfc()` is inherited from FeePayer and must be implemented to return the available pool of collateral from
    // which fees can be charged. For this contract, the available fee pool is simply all of the collateral locked up in the
    // contract.
    function _pfc() internal view virtual override returns (FixedPoint.Unsigned memory) {
        return _getFeeAdjustedCollateral(rawTotalDepositBoxCollateral);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../interfaces/FinderInterface.sol";
import "../../common/implementation/AddressWhitelist.sol";
import "./Registry.sol";
import "./Constants.sol";

/**
 * @title Base contract for all financial contract creators
 */
abstract contract ContractCreator {
    address internal finderAddress;

    constructor(address _finderAddress) public {
        finderAddress = _finderAddress;
    }

    function _requireWhitelistedCollateral(address collateralAddress) internal view {
        FinderInterface finder = FinderInterface(finderAddress);
        AddressWhitelist collateralWhitelist =
            AddressWhitelist(finder.getImplementationAddress(OracleInterfaces.CollateralWhitelist));
        require(collateralWhitelist.isOnWhitelist(collateralAddress), "Collateral not whitelisted");
    }

    function _registerContract(address[] memory parties, address contractToRegister) internal {
        FinderInterface finder = FinderInterface(finderAddress);
        Registry registry = Registry(finder.getImplementationAddress(OracleInterfaces.Registry));
        registry.registerContract(parties, contractToRegister);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/interfaces/ExpandedIERC20.sol";
import "../../common/interfaces/IERC20Standard.sol";
import "../../oracle/implementation/ContractCreator.sol";
import "../../common/implementation/Testable.sol";
import "../../common/implementation/AddressWhitelist.sol";
import "../../common/implementation/Lockable.sol";
import "../common/TokenFactory.sol";
import "../common/SyntheticToken.sol";
import "./PerpetualLib.sol";
import "./ConfigStore.sol";

/**
 * @title Perpetual Contract creator.
 * @notice Factory contract to create and register new instances of perpetual contracts.
 * Responsible for constraining the parameters used to construct a new perpetual. This creator contains a number of constraints
 * that are applied to newly created contract. These constraints can evolve over time and are
 * initially constrained to conservative values in this first iteration. Technically there is nothing in the
 * Perpetual contract requiring these constraints. However, because `createPerpetual()` is intended
 * to be the only way to create valid financial contracts that are registered with the DVM (via _registerContract),
  we can enforce deployment configurations here.
 */
contract PerpetualCreator is ContractCreator, Testable, Lockable {
    using FixedPoint for FixedPoint.Unsigned;

    /****************************************
     *     PERP CREATOR DATA STRUCTURES      *
     ****************************************/

    // Immutable params for perpetual contract.
    struct Params {
        address collateralAddress;
        bytes32 priceFeedIdentifier;
        bytes32 fundingRateIdentifier;
        string syntheticName;
        string syntheticSymbol;
        FixedPoint.Unsigned collateralRequirement;
        FixedPoint.Unsigned disputeBondPercentage;
        FixedPoint.Unsigned sponsorDisputeRewardPercentage;
        FixedPoint.Unsigned disputerDisputeRewardPercentage;
        FixedPoint.Unsigned minSponsorTokens;
        FixedPoint.Unsigned tokenScaling;
        uint256 withdrawalLiveness;
        uint256 liquidationLiveness;
    }
    // Address of TokenFactory used to create a new synthetic token.
    address public tokenFactoryAddress;

    event CreatedPerpetual(address indexed perpetualAddress, address indexed deployerAddress);
    event CreatedConfigStore(address indexed configStoreAddress, address indexed ownerAddress);

    /**
     * @notice Constructs the Perpetual contract.
     * @param _finderAddress UMA protocol Finder used to discover other protocol contracts.
     * @param _tokenFactoryAddress ERC20 token factory used to deploy synthetic token instances.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     */
    constructor(
        address _finderAddress,
        address _tokenFactoryAddress,
        address _timerAddress
    ) public ContractCreator(_finderAddress) Testable(_timerAddress) nonReentrant() {
        tokenFactoryAddress = _tokenFactoryAddress;
    }

    /**
     * @notice Creates an instance of perpetual and registers it within the registry.
     * @param params is a `ConstructorParams` object from Perpetual.
     * @return address of the deployed contract.
     */
    function createPerpetual(Params memory params, ConfigStore.ConfigSettings memory configSettings)
        public
        nonReentrant()
        returns (address)
    {
        require(bytes(params.syntheticName).length != 0, "Missing synthetic name");
        require(bytes(params.syntheticSymbol).length != 0, "Missing synthetic symbol");

        // Create new config settings store for this contract and reset ownership to the deployer.
        ConfigStore configStore = new ConfigStore(configSettings, timerAddress);
        configStore.transferOwnership(msg.sender);
        emit CreatedConfigStore(address(configStore), configStore.owner());

        // Create a new synthetic token using the params.
        TokenFactory tf = TokenFactory(tokenFactoryAddress);

        // If the collateral token does not have a `decimals()` method,
        // then a default precision of 18 will be applied to the newly created synthetic token.
        uint8 syntheticDecimals = _getSyntheticDecimals(params.collateralAddress);
        ExpandedIERC20 tokenCurrency = tf.createToken(params.syntheticName, params.syntheticSymbol, syntheticDecimals);
        address derivative = PerpetualLib.deploy(_convertParams(params, tokenCurrency, address(configStore)));

        // Give permissions to new derivative contract and then hand over ownership.
        tokenCurrency.addMinter(derivative);
        tokenCurrency.addBurner(derivative);
        tokenCurrency.resetOwner(derivative);

        _registerContract(new address[](0), derivative);

        emit CreatedPerpetual(derivative, msg.sender);

        return derivative;
    }

    /****************************************
     *          PRIVATE FUNCTIONS           *
     ****************************************/

    // Converts createPerpetual params to Perpetual constructor params.
    function _convertParams(
        Params memory params,
        ExpandedIERC20 newTokenCurrency,
        address configStore
    ) private view returns (Perpetual.ConstructorParams memory constructorParams) {
        // Known from creator deployment.
        constructorParams.finderAddress = finderAddress;
        constructorParams.timerAddress = timerAddress;

        // Enforce configuration constraints.
        require(params.withdrawalLiveness != 0, "Withdrawal liveness cannot be 0");
        require(params.liquidationLiveness != 0, "Liquidation liveness cannot be 0");
        _requireWhitelistedCollateral(params.collateralAddress);

        // We don't want perpetual deployers to be able to intentionally or unintentionally set
        // liveness periods that could induce arithmetic overflow, but we also don't want
        // to be opinionated about what livenesses are "correct", so we will somewhat
        // arbitrarily set the liveness upper bound to 100 years (5200 weeks). In practice, liveness
        // periods even greater than a few days would make the perpetual unusable for most users.
        require(params.withdrawalLiveness < 5200 weeks, "Withdrawal liveness too large");
        require(params.liquidationLiveness < 5200 weeks, "Liquidation liveness too large");

        // To avoid precision loss or overflows, prevent the token scaling from being too large or too small.
        FixedPoint.Unsigned memory minScaling = FixedPoint.Unsigned(1e8); // 1e-10
        FixedPoint.Unsigned memory maxScaling = FixedPoint.Unsigned(1e28); // 1e10
        require(
            params.tokenScaling.isGreaterThan(minScaling) && params.tokenScaling.isLessThan(maxScaling),
            "Invalid tokenScaling"
        );

        // Input from function call.
        constructorParams.configStoreAddress = configStore;
        constructorParams.tokenAddress = address(newTokenCurrency);
        constructorParams.collateralAddress = params.collateralAddress;
        constructorParams.priceFeedIdentifier = params.priceFeedIdentifier;
        constructorParams.fundingRateIdentifier = params.fundingRateIdentifier;
        constructorParams.collateralRequirement = params.collateralRequirement;
        constructorParams.disputeBondPercentage = params.disputeBondPercentage;
        constructorParams.sponsorDisputeRewardPercentage = params.sponsorDisputeRewardPercentage;
        constructorParams.disputerDisputeRewardPercentage = params.disputerDisputeRewardPercentage;
        constructorParams.minSponsorTokens = params.minSponsorTokens;
        constructorParams.withdrawalLiveness = params.withdrawalLiveness;
        constructorParams.liquidationLiveness = params.liquidationLiveness;
        constructorParams.tokenScaling = params.tokenScaling;
    }

    // IERC20Standard.decimals() will revert if the collateral contract has not implemented the decimals() method,
    // which is possible since the method is only an OPTIONAL method in the ERC20 standard:
    // https://eips.ethereum.org/EIPS/eip-20#methods.
    function _getSyntheticDecimals(address _collateralAddress) public view returns (uint8 decimals) {
        try IERC20Standard(_collateralAddress).decimals() returns (uint8 _decimals) {
            return _decimals;
        } catch {
            return 18;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./SyntheticToken.sol";
import "../../common/interfaces/ExpandedIERC20.sol";
import "../../common/implementation/Lockable.sol";

/**
 * @title Factory for creating new mintable and burnable tokens.
 */

contract TokenFactory is Lockable {
    /**
     * @notice Create a new token and return it to the caller.
     * @dev The caller will become the only minter and burner and the new owner capable of assigning the roles.
     * @param tokenName used to describe the new token.
     * @param tokenSymbol short ticker abbreviation of the name. Ideally < 5 chars.
     * @param tokenDecimals used to define the precision used in the token's numerical representation.
     * @return newToken an instance of the newly created token interface.
     */
    function createToken(
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals
    ) external nonReentrant() returns (ExpandedIERC20 newToken) {
        SyntheticToken mintableToken = new SyntheticToken(tokenName, tokenSymbol, tokenDecimals);
        mintableToken.addMinter(msg.sender);
        mintableToken.addBurner(msg.sender);
        mintableToken.resetOwner(msg.sender);
        newToken = ExpandedIERC20(address(mintableToken));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
import "../../common/implementation/ExpandedERC20.sol";
import "../../common/implementation/Lockable.sol";

/**
 * @title Burnable and mintable ERC20.
 * @dev The contract deployer will initially be the only minter, burner and owner capable of adding new roles.
 */

contract SyntheticToken is ExpandedERC20, Lockable {
    /**
     * @notice Constructs the SyntheticToken.
     * @param tokenName The name which describes the new token.
     * @param tokenSymbol The ticker abbreviation of the name. Ideally < 5 chars.
     * @param tokenDecimals The number of decimals to define token precision.
     */
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) public ExpandedERC20(tokenName, tokenSymbol, tokenDecimals) nonReentrant() {}

    /**
     * @notice Add Minter role to account.
     * @dev The caller must have the Owner role.
     * @param account The address to which the Minter role is added.
     */
    function addMinter(address account) external override nonReentrant() {
        addMember(uint256(Roles.Minter), account);
    }

    /**
     * @notice Remove Minter role from account.
     * @dev The caller must have the Owner role.
     * @param account The address from which the Minter role is removed.
     */
    function removeMinter(address account) external nonReentrant() {
        removeMember(uint256(Roles.Minter), account);
    }

    /**
     * @notice Add Burner role to account.
     * @dev The caller must have the Owner role.
     * @param account The address to which the Burner role is added.
     */
    function addBurner(address account) external override nonReentrant() {
        addMember(uint256(Roles.Burner), account);
    }

    /**
     * @notice Removes Burner role from account.
     * @dev The caller must have the Owner role.
     * @param account The address from which the Burner role is removed.
     */
    function removeBurner(address account) external nonReentrant() {
        removeMember(uint256(Roles.Burner), account);
    }

    /**
     * @notice Reset Owner role to account.
     * @dev The caller must have the Owner role.
     * @param account The new holder of the Owner role.
     */
    function resetOwner(address account) external override nonReentrant() {
        resetMember(uint256(Roles.Owner), account);
    }

    /**
     * @notice Checks if a given account holds the Minter role.
     * @param account The address which is checked for the Minter role.
     * @return bool True if the provided account is a Minter.
     */
    function isMinter(address account) public view nonReentrantView() returns (bool) {
        return holdsRole(uint256(Roles.Minter), account);
    }

    /**
     * @notice Checks if a given account holds the Burner role.
     * @param account The address which is checked for the Burner role.
     * @return bool True if the provided account is a Burner.
     */
    function isBurner(address account) public view nonReentrantView() returns (bool) {
        return holdsRole(uint256(Roles.Burner), account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Perpetual.sol";

/**
 * @title Provides convenient Perpetual Multi Party contract utilities.
 * @dev Using this library to deploy Perpetuals allows calling contracts to avoid importing the full bytecode.
 */
library PerpetualLib {
    /**
     * @notice Returns address of new Perpetual deployed with given `params` configuration.
     * @dev Caller will need to register new Perpetual with the Registry to begin requesting prices. Caller is also
     * responsible for enforcing constraints on `params`.
     * @param params is a `ConstructorParams` object from Perpetual.
     * @return address of the deployed Perpetual contract
     */
    function deploy(Perpetual.ConstructorParams memory params) public returns (address) {
        Perpetual derivative = new Perpetual(params);
        return address(derivative);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ConfigStoreInterface.sol";
import "../../common/implementation/Testable.sol";
import "../../common/implementation/Lockable.sol";
import "../../common/implementation/FixedPoint.sol";

/**
 * @notice ConfigStore stores configuration settings for a perpetual contract and provides an interface for it
 * to query settings such as reward rates, proposal bond sizes, etc. The configuration settings can be upgraded
 * by a privileged account and the upgraded changes are timelocked.
 */
contract ConfigStore is ConfigStoreInterface, Testable, Lockable, Ownable {
    using SafeMath for uint256;
    using FixedPoint for FixedPoint.Unsigned;

    /****************************************
     *        STORE DATA STRUCTURES         *
     ****************************************/

    // Make currentConfig private to force user to call getCurrentConfig, which returns the pendingConfig
    // if its liveness has expired.
    ConfigStoreInterface.ConfigSettings private currentConfig;

    // Beginning on `pendingPassedTimestamp`, the `pendingConfig` can be published as the current config.
    ConfigStoreInterface.ConfigSettings public pendingConfig;
    uint256 public pendingPassedTimestamp;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event ProposedNewConfigSettings(
        address indexed proposer,
        uint256 rewardRatePerSecond,
        uint256 proposerBondPercentage,
        uint256 timelockLiveness,
        int256 maxFundingRate,
        int256 minFundingRate,
        uint256 proposalTimePastLimit,
        uint256 proposalPassedTimestamp
    );
    event ChangedConfigSettings(
        uint256 rewardRatePerSecond,
        uint256 proposerBondPercentage,
        uint256 timelockLiveness,
        int256 maxFundingRate,
        int256 minFundingRate,
        uint256 proposalTimePastLimit
    );

    /****************************************
     *                MODIFIERS             *
     ****************************************/

    // Update config settings if possible.
    modifier updateConfig() {
        _updateConfig();
        _;
    }

    /**
     * @notice Construct the Config Store. An initial configuration is provided and set on construction.
     * @param _initialConfig Configuration settings to initialize `currentConfig` with.
     * @param _timerAddress Address of testable Timer contract.
     */
    constructor(ConfigSettings memory _initialConfig, address _timerAddress) public Testable(_timerAddress) {
        _validateConfig(_initialConfig);
        currentConfig = _initialConfig;
    }

    /**
     * @notice Returns current config or pending config if pending liveness has expired.
     * @return ConfigSettings config settings that calling financial contract should view as "live".
     */
    function updateAndGetCurrentConfig()
        external
        override
        updateConfig()
        nonReentrant()
        returns (ConfigStoreInterface.ConfigSettings memory)
    {
        return currentConfig;
    }

    /**
     * @notice Propose new configuration settings. New settings go into effect after a liveness period passes.
     * @param newConfig Configuration settings to publish after `currentConfig.timelockLiveness` passes from now.
     * @dev Callable only by owner. Calling this while there is already a pending proposal will overwrite the pending proposal.
     */
    function proposeNewConfig(ConfigSettings memory newConfig) external onlyOwner() nonReentrant() updateConfig() {
        _validateConfig(newConfig);

        // Warning: This overwrites a pending proposal!
        pendingConfig = newConfig;

        // Use current config's liveness period to timelock this proposal.
        pendingPassedTimestamp = getCurrentTime().add(currentConfig.timelockLiveness);

        emit ProposedNewConfigSettings(
            msg.sender,
            newConfig.rewardRatePerSecond.rawValue,
            newConfig.proposerBondPercentage.rawValue,
            newConfig.timelockLiveness,
            newConfig.maxFundingRate.rawValue,
            newConfig.minFundingRate.rawValue,
            newConfig.proposalTimePastLimit,
            pendingPassedTimestamp
        );
    }

    /**
     * @notice Publish any pending configuration settings if there is a pending proposal that has passed liveness.
     */
    function publishPendingConfig() external nonReentrant() updateConfig() {}

    /****************************************
     *         INTERNAL FUNCTIONS           *
     ****************************************/

    // Check if pending proposal can overwrite the current config.
    function _updateConfig() internal {
        // If liveness has passed, publish proposed configuration settings.
        if (_pendingProposalPassed()) {
            currentConfig = pendingConfig;

            _deletePendingConfig();

            emit ChangedConfigSettings(
                currentConfig.rewardRatePerSecond.rawValue,
                currentConfig.proposerBondPercentage.rawValue,
                currentConfig.timelockLiveness,
                currentConfig.maxFundingRate.rawValue,
                currentConfig.minFundingRate.rawValue,
                currentConfig.proposalTimePastLimit
            );
        }
    }

    function _deletePendingConfig() internal {
        delete pendingConfig;
        pendingPassedTimestamp = 0;
    }

    function _pendingProposalPassed() internal view returns (bool) {
        return (pendingPassedTimestamp != 0 && pendingPassedTimestamp <= getCurrentTime());
    }

    // Use this method to constrain values with which you can set ConfigSettings.
    function _validateConfig(ConfigStoreInterface.ConfigSettings memory config) internal pure {
        // We don't set limits on proposal timestamps because there are already natural limits:
        // - Future: price requests to the OptimisticOracle must be in the past---we can't add further constraints.
        // - Past: proposal times must always be after the last update time, and  a reasonable past limit would be 30
        //   mins, meaning that no proposal timestamp can be more than 30 minutes behind the current time.

        // Make sure timelockLiveness is not too long, otherwise contract might not be able to fix itself
        // before a vulnerability drains its collateral.
        require(config.timelockLiveness <= 7 days && config.timelockLiveness >= 1 days, "Invalid timelockLiveness");

        // The reward rate should be modified as needed to incentivize honest proposers appropriately.
        // Additionally, the rate should be less than 100% a year => 100% / 360 days / 24 hours / 60 mins / 60 secs
        // = 0.0000033
        FixedPoint.Unsigned memory maxRewardRatePerSecond = FixedPoint.fromUnscaledUint(33).div(1e7);
        require(config.rewardRatePerSecond.isLessThan(maxRewardRatePerSecond), "Invalid rewardRatePerSecond");

        // We don't set a limit on the proposer bond because it is a defense against dishonest proposers. If a proposer
        // were to successfully propose a very high or low funding rate, then their PfC would be very high. The proposer
        // could theoretically keep their "evil" funding rate alive indefinitely by continuously disputing honest
        // proposers, so we would want to be able to set the proposal bond (equal to the dispute bond) higher than their
        // PfC for each proposal liveness window. The downside of not limiting this is that the config store owner
        // can set it arbitrarily high and preclude a new funding rate from ever coming in. We suggest setting the
        // proposal bond based on the configuration's funding rate range like in this discussion:
        // https://github.com/UMAprotocol/protocol/issues/2039#issuecomment-719734383

        // We also don't set a limit on the funding rate max/min because we might need to allow very high magnitude
        // funding rates in extraordinarily volatile market situations. Note, that even though we do not bound
        // the max/min, we still recommend that the deployer of this contract set the funding rate max/min values
        // to bound the PfC of a dishonest proposer. A reasonable range might be the equivalent of [+200%/year, -200%/year].
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./PerpetualLiquidatable.sol";

/**
 * @title Perpetual Multiparty Contract.
 * @notice Convenient wrapper for Liquidatable.
 */
contract Perpetual is PerpetualLiquidatable {
    /**
     * @notice Constructs the Perpetual contract.
     * @param params struct to define input parameters for construction of Liquidatable. Some params
     * are fed directly into the PositionManager's constructor within the inheritance tree.
     */
    constructor(ConstructorParams memory params)
        public
        PerpetualLiquidatable(params)
    // Note: since there is no logic here, there is no need to add a re-entrancy guard.
    {

    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./PerpetualPositionManager.sol";

import "../../common/implementation/FixedPoint.sol";

/**
 * @title PerpetualLiquidatable
 * @notice Adds logic to a position-managing contract that enables callers to liquidate an undercollateralized position.
 * @dev The liquidation has a liveness period before expiring successfully, during which someone can "dispute" the
 * liquidation, which sends a price request to the relevant Oracle to settle the final collateralization ratio based on
 * a DVM price. The contract enforces dispute rewards in order to incentivize disputers to correctly dispute false
 * liquidations and compensate position sponsors who had their position incorrectly liquidated. Importantly, a
 * prospective disputer must deposit a dispute bond that they can lose in the case of an unsuccessful dispute.
 * NOTE: this contract does _not_ work with ERC777 collateral currencies or any others that call into the receiver on
 * transfer(). Using an ERC777 token would allow a user to maliciously grief other participants (while also losing
 * money themselves).
 */
contract PerpetualLiquidatable is PerpetualPositionManager {
    using FixedPoint for FixedPoint.Unsigned;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /****************************************
     *     LIQUIDATION DATA STRUCTURES      *
     ****************************************/

    // Because of the check in withdrawable(), the order of these enum values should not change.
    enum Status { Uninitialized, NotDisputed, Disputed, DisputeSucceeded, DisputeFailed }

    struct LiquidationData {
        // Following variables set upon creation of liquidation:
        address sponsor; // Address of the liquidated position's sponsor
        address liquidator; // Address who created this liquidation
        Status state; // Liquidated (and expired or not), Pending a Dispute, or Dispute has resolved
        uint256 liquidationTime; // Time when liquidation is initiated, needed to get price from Oracle
        // Following variables determined by the position that is being liquidated:
        FixedPoint.Unsigned tokensOutstanding; // Synthetic tokens required to be burned by liquidator to initiate dispute
        FixedPoint.Unsigned lockedCollateral; // Collateral locked by contract and released upon expiry or post-dispute
        // Amount of collateral being liquidated, which could be different from
        // lockedCollateral if there were pending withdrawals at the time of liquidation
        FixedPoint.Unsigned liquidatedCollateral;
        // Unit value (starts at 1) that is used to track the fees per unit of collateral over the course of the liquidation.
        FixedPoint.Unsigned rawUnitCollateral;
        // Following variable set upon initiation of a dispute:
        address disputer; // Person who is disputing a liquidation
        // Following variable set upon a resolution of a dispute:
        FixedPoint.Unsigned settlementPrice; // Final price as determined by an Oracle following a dispute
        FixedPoint.Unsigned finalFee;
    }

    // Define the contract's constructor parameters as a struct to enable more variables to be specified.
    // This is required to enable more params, over and above Solidity's limits.
    struct ConstructorParams {
        // Params for PerpetualPositionManager only.
        uint256 withdrawalLiveness;
        address configStoreAddress;
        address collateralAddress;
        address tokenAddress;
        address finderAddress;
        address timerAddress;
        bytes32 priceFeedIdentifier;
        bytes32 fundingRateIdentifier;
        FixedPoint.Unsigned minSponsorTokens;
        FixedPoint.Unsigned tokenScaling;
        // Params specifically for PerpetualLiquidatable.
        uint256 liquidationLiveness;
        FixedPoint.Unsigned collateralRequirement;
        FixedPoint.Unsigned disputeBondPercentage;
        FixedPoint.Unsigned sponsorDisputeRewardPercentage;
        FixedPoint.Unsigned disputerDisputeRewardPercentage;
    }

    // This struct is used in the `withdrawLiquidation` method that disperses liquidation and dispute rewards.
    // `payToX` stores the total collateral to withdraw from the contract to pay X. This value might differ
    // from `paidToX` due to precision loss between accounting for the `rawCollateral` versus the
    // fee-adjusted collateral. These variables are stored within a struct to avoid the stack too deep error.
    struct RewardsData {
        FixedPoint.Unsigned payToSponsor;
        FixedPoint.Unsigned payToLiquidator;
        FixedPoint.Unsigned payToDisputer;
        FixedPoint.Unsigned paidToSponsor;
        FixedPoint.Unsigned paidToLiquidator;
        FixedPoint.Unsigned paidToDisputer;
    }

    // Liquidations are unique by ID per sponsor
    mapping(address => LiquidationData[]) public liquidations;

    // Total collateral in liquidation.
    FixedPoint.Unsigned public rawLiquidationCollateral;

    // Immutable contract parameters:
    // Amount of time for pending liquidation before expiry.
    // !!Note: The lower the liquidation liveness value, the more risk incurred by sponsors.
    //       Extremely low liveness values increase the chance that opportunistic invalid liquidations
    //       expire without dispute, thereby decreasing the usability for sponsors and increasing the risk
    //       for the contract as a whole. An insolvent contract is extremely risky for any sponsor or synthetic
    //       token holder for the contract.
    uint256 public liquidationLiveness;
    // Required collateral:TRV ratio for a position to be considered sufficiently collateralized.
    FixedPoint.Unsigned public collateralRequirement;
    // Percent of a Liquidation/Position's lockedCollateral to be deposited by a potential disputer
    // Represented as a multiplier, for example 1.5e18 = "150%" and 0.05e18 = "5%"
    FixedPoint.Unsigned public disputeBondPercentage;
    // Percent of oraclePrice paid to sponsor in the Disputed state (i.e. following a successful dispute)
    // Represented as a multiplier, see above.
    FixedPoint.Unsigned public sponsorDisputeRewardPercentage;
    // Percent of oraclePrice paid to disputer in the Disputed state (i.e. following a successful dispute)
    // Represented as a multiplier, see above.
    FixedPoint.Unsigned public disputerDisputeRewardPercentage;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event LiquidationCreated(
        address indexed sponsor,
        address indexed liquidator,
        uint256 indexed liquidationId,
        uint256 tokensOutstanding,
        uint256 lockedCollateral,
        uint256 liquidatedCollateral,
        uint256 liquidationTime
    );
    event LiquidationDisputed(
        address indexed sponsor,
        address indexed liquidator,
        address indexed disputer,
        uint256 liquidationId,
        uint256 disputeBondAmount
    );
    event DisputeSettled(
        address indexed caller,
        address indexed sponsor,
        address indexed liquidator,
        address disputer,
        uint256 liquidationId,
        bool disputeSucceeded
    );
    event LiquidationWithdrawn(
        address indexed caller,
        uint256 paidToLiquidator,
        uint256 paidToDisputer,
        uint256 paidToSponsor,
        Status indexed liquidationStatus,
        uint256 settlementPrice
    );

    /****************************************
     *              MODIFIERS               *
     ****************************************/

    modifier disputable(uint256 liquidationId, address sponsor) {
        _disputable(liquidationId, sponsor);
        _;
    }

    modifier withdrawable(uint256 liquidationId, address sponsor) {
        _withdrawable(liquidationId, sponsor);
        _;
    }

    /**
     * @notice Constructs the liquidatable contract.
     * @param params struct to define input parameters for construction of Liquidatable. Some params
     * are fed directly into the PositionManager's constructor within the inheritance tree.
     */
    constructor(ConstructorParams memory params)
        public
        PerpetualPositionManager(
            params.withdrawalLiveness,
            params.collateralAddress,
            params.tokenAddress,
            params.finderAddress,
            params.priceFeedIdentifier,
            params.fundingRateIdentifier,
            params.minSponsorTokens,
            params.configStoreAddress,
            params.tokenScaling,
            params.timerAddress
        )
    {
        require(params.collateralRequirement.isGreaterThan(1));
        require(params.sponsorDisputeRewardPercentage.add(params.disputerDisputeRewardPercentage).isLessThan(1));

        // Set liquidatable specific variables.
        liquidationLiveness = params.liquidationLiveness;
        collateralRequirement = params.collateralRequirement;
        disputeBondPercentage = params.disputeBondPercentage;
        sponsorDisputeRewardPercentage = params.sponsorDisputeRewardPercentage;
        disputerDisputeRewardPercentage = params.disputerDisputeRewardPercentage;
    }

    /****************************************
     *        LIQUIDATION FUNCTIONS         *
     ****************************************/

    /**
     * @notice Liquidates the sponsor's position if the caller has enough
     * synthetic tokens to retire the position's outstanding tokens. Liquidations above
     * a minimum size also reset an ongoing "slow withdrawal"'s liveness.
     * @dev This method generates an ID that will uniquely identify liquidation for the sponsor. This contract must be
     * approved to spend at least `tokensLiquidated` of `tokenCurrency` and at least `finalFeeBond` of `collateralCurrency`.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @param sponsor address of the sponsor to liquidate.
     * @param minCollateralPerToken abort the liquidation if the position's collateral per token is below this value.
     * @param maxCollateralPerToken abort the liquidation if the position's collateral per token exceeds this value.
     * @param maxTokensToLiquidate max number of tokens to liquidate.
     * @param deadline abort the liquidation if the transaction is mined after this timestamp.
     * @return liquidationId ID of the newly created liquidation.
     * @return tokensLiquidated amount of synthetic tokens removed and liquidated from the `sponsor`'s position.
     * @return finalFeeBond amount of collateral to be posted by liquidator and returned if not disputed successfully.
     */
    function createLiquidation(
        address sponsor,
        FixedPoint.Unsigned calldata minCollateralPerToken,
        FixedPoint.Unsigned calldata maxCollateralPerToken,
        FixedPoint.Unsigned calldata maxTokensToLiquidate,
        uint256 deadline
    )
        external
        notEmergencyShutdown()
        fees()
        nonReentrant()
        returns (
            uint256 liquidationId,
            FixedPoint.Unsigned memory tokensLiquidated,
            FixedPoint.Unsigned memory finalFeeBond
        )
    {
        // Check that this transaction was mined pre-deadline.
        require(getCurrentTime() <= deadline, "Mined after deadline");

        // Retrieve Position data for sponsor
        PositionData storage positionToLiquidate = _getPositionData(sponsor);

        tokensLiquidated = FixedPoint.min(maxTokensToLiquidate, positionToLiquidate.tokensOutstanding);
        require(tokensLiquidated.isGreaterThan(0));

        // Starting values for the Position being liquidated. If withdrawal request amount is > position's collateral,
        // then set this to 0, otherwise set it to (startCollateral - withdrawal request amount).
        FixedPoint.Unsigned memory startCollateral = _getFeeAdjustedCollateral(positionToLiquidate.rawCollateral);
        FixedPoint.Unsigned memory startCollateralNetOfWithdrawal = FixedPoint.fromUnscaledUint(0);
        if (positionToLiquidate.withdrawalRequestAmount.isLessThanOrEqual(startCollateral)) {
            startCollateralNetOfWithdrawal = startCollateral.sub(positionToLiquidate.withdrawalRequestAmount);
        }

        // Scoping to get rid of a stack too deep error.
        {
            FixedPoint.Unsigned memory startTokens = positionToLiquidate.tokensOutstanding;

            // The Position's collateralization ratio must be between [minCollateralPerToken, maxCollateralPerToken].
            require(
                maxCollateralPerToken.mul(startTokens).isGreaterThanOrEqual(startCollateralNetOfWithdrawal),
                "CR is more than max liq. price"
            );
            // minCollateralPerToken >= startCollateralNetOfWithdrawal / startTokens.
            require(
                minCollateralPerToken.mul(startTokens).isLessThanOrEqual(startCollateralNetOfWithdrawal),
                "CR is less than min liq. price"
            );
        }

        // Compute final fee at time of liquidation.
        finalFeeBond = _computeFinalFees();

        // These will be populated within the scope below.
        FixedPoint.Unsigned memory lockedCollateral;
        FixedPoint.Unsigned memory liquidatedCollateral;

        // Scoping to get rid of a stack too deep error. The amount of tokens to remove from the position
        // are not funding-rate adjusted because the multiplier only affects their redemption value, not their
        // notional.
        {
            FixedPoint.Unsigned memory ratio = tokensLiquidated.div(positionToLiquidate.tokensOutstanding);

            // The actual amount of collateral that gets moved to the liquidation.
            lockedCollateral = startCollateral.mul(ratio);

            // For purposes of disputes, it's actually this liquidatedCollateral value that's used. This value is net of
            // withdrawal requests.
            liquidatedCollateral = startCollateralNetOfWithdrawal.mul(ratio);

            // Part of the withdrawal request is also removed. Ideally:
            // liquidatedCollateral + withdrawalAmountToRemove = lockedCollateral.
            FixedPoint.Unsigned memory withdrawalAmountToRemove =
                positionToLiquidate.withdrawalRequestAmount.mul(ratio);
            _reduceSponsorPosition(sponsor, tokensLiquidated, lockedCollateral, withdrawalAmountToRemove);
        }

        // Add to the global liquidation collateral count.
        _addCollateral(rawLiquidationCollateral, lockedCollateral.add(finalFeeBond));

        // Construct liquidation object.
        // Note: All dispute-related values are zeroed out until a dispute occurs. liquidationId is the index of the new
        // LiquidationData that is pushed into the array, which is equal to the current length of the array pre-push.
        liquidationId = liquidations[sponsor].length;
        liquidations[sponsor].push(
            LiquidationData({
                sponsor: sponsor,
                liquidator: msg.sender,
                state: Status.NotDisputed,
                liquidationTime: getCurrentTime(),
                tokensOutstanding: _getFundingRateAppliedTokenDebt(tokensLiquidated),
                lockedCollateral: lockedCollateral,
                liquidatedCollateral: liquidatedCollateral,
                rawUnitCollateral: _convertToRawCollateral(FixedPoint.fromUnscaledUint(1)),
                disputer: address(0),
                settlementPrice: FixedPoint.fromUnscaledUint(0),
                finalFee: finalFeeBond
            })
        );

        // If this liquidation is a subsequent liquidation on the position, and the liquidation size is larger than
        // some "griefing threshold", then re-set the liveness. This enables a liquidation against a withdraw request to be
        // "dragged out" if the position is very large and liquidators need time to gather funds. The griefing threshold
        // is enforced so that liquidations for trivially small # of tokens cannot drag out an honest sponsor's slow withdrawal.

        // We arbitrarily set the "griefing threshold" to `minSponsorTokens` because it is the only parameter
        // denominated in token currency units and we can avoid adding another parameter.
        FixedPoint.Unsigned memory griefingThreshold = minSponsorTokens;
        if (
            positionToLiquidate.withdrawalRequestPassTimestamp > 0 && // The position is undergoing a slow withdrawal.
            positionToLiquidate.withdrawalRequestPassTimestamp > getCurrentTime() && // The slow withdrawal has not yet expired.
            tokensLiquidated.isGreaterThanOrEqual(griefingThreshold) // The liquidated token count is above a "griefing threshold".
        ) {
            positionToLiquidate.withdrawalRequestPassTimestamp = getCurrentTime().add(withdrawalLiveness);
        }

        emit LiquidationCreated(
            sponsor,
            msg.sender,
            liquidationId,
            _getFundingRateAppliedTokenDebt(tokensLiquidated).rawValue,
            lockedCollateral.rawValue,
            liquidatedCollateral.rawValue,
            getCurrentTime()
        );

        // Destroy tokens
        tokenCurrency.safeTransferFrom(msg.sender, address(this), tokensLiquidated.rawValue);
        tokenCurrency.burn(tokensLiquidated.rawValue);

        // Pull final fee from liquidator.
        collateralCurrency.safeTransferFrom(msg.sender, address(this), finalFeeBond.rawValue);
    }

    /**
     * @notice Disputes a liquidation, if the caller has enough collateral to post a dispute bond and pay a fixed final
     * fee charged on each price request.
     * @dev Can only dispute a liquidation before the liquidation expires and if there are no other pending disputes.
     * This contract must be approved to spend at least the dispute bond amount of `collateralCurrency`. This dispute
     * bond amount is calculated from `disputeBondPercentage` times the collateral in the liquidation.
     * @param liquidationId of the disputed liquidation.
     * @param sponsor the address of the sponsor whose liquidation is being disputed.
     * @return totalPaid amount of collateral charged to disputer (i.e. final fee bond + dispute bond).
     */
    function dispute(uint256 liquidationId, address sponsor)
        external
        disputable(liquidationId, sponsor)
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory totalPaid)
    {
        LiquidationData storage disputedLiquidation = _getLiquidationData(sponsor, liquidationId);

        // Multiply by the unit collateral so the dispute bond is a percentage of the locked collateral after fees.
        FixedPoint.Unsigned memory disputeBondAmount =
            disputedLiquidation.lockedCollateral.mul(disputeBondPercentage).mul(
                _getFeeAdjustedCollateral(disputedLiquidation.rawUnitCollateral)
            );
        _addCollateral(rawLiquidationCollateral, disputeBondAmount);

        // Request a price from DVM. Liquidation is pending dispute until DVM returns a price.
        disputedLiquidation.state = Status.Disputed;
        disputedLiquidation.disputer = msg.sender;

        // Enqueue a request with the DVM.
        _requestOraclePrice(disputedLiquidation.liquidationTime);

        emit LiquidationDisputed(
            sponsor,
            disputedLiquidation.liquidator,
            msg.sender,
            liquidationId,
            disputeBondAmount.rawValue
        );
        totalPaid = disputeBondAmount.add(disputedLiquidation.finalFee);

        // Pay the final fee for requesting price from the DVM.
        _payFinalFees(msg.sender, disputedLiquidation.finalFee);

        // Transfer the dispute bond amount from the caller to this contract.
        collateralCurrency.safeTransferFrom(msg.sender, address(this), disputeBondAmount.rawValue);
    }

    /**
     * @notice After a dispute has settled or after a non-disputed liquidation has expired,
     * anyone can call this method to disperse payments to the sponsor, liquidator, and disputer.
     * @dev If the dispute SUCCEEDED: the sponsor, liquidator, and disputer are eligible for payment.
     * If the dispute FAILED: only the liquidator receives payment. This method deletes the liquidation data.
     * This method will revert if rewards have already been dispersed.
     * @param liquidationId uniquely identifies the sponsor's liquidation.
     * @param sponsor address of the sponsor associated with the liquidation.
     * @return data about rewards paid out.
     */
    function withdrawLiquidation(uint256 liquidationId, address sponsor)
        public
        withdrawable(liquidationId, sponsor)
        fees()
        nonReentrant()
        returns (RewardsData memory)
    {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);

        // Settles the liquidation if necessary. This call will revert if the price has not resolved yet.
        _settle(liquidationId, sponsor);

        // Calculate rewards as a function of the TRV.
        // Note1: all payouts are scaled by the unit collateral value so all payouts are charged the fees pro rata.
        // Note2: the tokenRedemptionValue uses the tokensOutstanding which was calculated using the funding rate at
        // liquidation time from _getFundingRateAppliedTokenDebt. Therefore the TRV considers the full debt value at that time.
        FixedPoint.Unsigned memory feeAttenuation = _getFeeAdjustedCollateral(liquidation.rawUnitCollateral);
        FixedPoint.Unsigned memory settlementPrice = liquidation.settlementPrice;
        FixedPoint.Unsigned memory tokenRedemptionValue =
            liquidation.tokensOutstanding.mul(settlementPrice).mul(feeAttenuation);
        FixedPoint.Unsigned memory collateral = liquidation.lockedCollateral.mul(feeAttenuation);
        FixedPoint.Unsigned memory disputerDisputeReward = disputerDisputeRewardPercentage.mul(tokenRedemptionValue);
        FixedPoint.Unsigned memory sponsorDisputeReward = sponsorDisputeRewardPercentage.mul(tokenRedemptionValue);
        FixedPoint.Unsigned memory disputeBondAmount = collateral.mul(disputeBondPercentage);
        FixedPoint.Unsigned memory finalFee = liquidation.finalFee.mul(feeAttenuation);

        // There are three main outcome states: either the dispute succeeded, failed or was not updated.
        // Based on the state, different parties of a liquidation receive different amounts.
        // After assigning rewards based on the liquidation status, decrease the total collateral held in this contract
        // by the amount to pay each party. The actual amounts withdrawn might differ if _removeCollateral causes
        // precision loss.
        RewardsData memory rewards;
        if (liquidation.state == Status.DisputeSucceeded) {
            // If the dispute is successful then all three users should receive rewards:

            // Pay DISPUTER: disputer reward + dispute bond + returned final fee
            rewards.payToDisputer = disputerDisputeReward.add(disputeBondAmount).add(finalFee);

            // Pay SPONSOR: remaining collateral (collateral - TRV) + sponsor reward
            rewards.payToSponsor = sponsorDisputeReward.add(collateral.sub(tokenRedemptionValue));

            // Pay LIQUIDATOR: TRV - dispute reward - sponsor reward
            // If TRV > Collateral, then subtract rewards from collateral
            // NOTE: This should never be below zero since we prevent (sponsorDisputePercentage+disputerDisputePercentage) >= 0 in
            // the constructor when these params are set.
            rewards.payToLiquidator = tokenRedemptionValue.sub(sponsorDisputeReward).sub(disputerDisputeReward);

            // Transfer rewards and debit collateral
            rewards.paidToLiquidator = _removeCollateral(rawLiquidationCollateral, rewards.payToLiquidator);
            rewards.paidToSponsor = _removeCollateral(rawLiquidationCollateral, rewards.payToSponsor);
            rewards.paidToDisputer = _removeCollateral(rawLiquidationCollateral, rewards.payToDisputer);

            collateralCurrency.safeTransfer(liquidation.disputer, rewards.paidToDisputer.rawValue);
            collateralCurrency.safeTransfer(liquidation.liquidator, rewards.paidToLiquidator.rawValue);
            collateralCurrency.safeTransfer(liquidation.sponsor, rewards.paidToSponsor.rawValue);

            // In the case of a failed dispute only the liquidator can withdraw.
        } else if (liquidation.state == Status.DisputeFailed) {
            // Pay LIQUIDATOR: collateral + dispute bond + returned final fee
            rewards.payToLiquidator = collateral.add(disputeBondAmount).add(finalFee);

            // Transfer rewards and debit collateral
            rewards.paidToLiquidator = _removeCollateral(rawLiquidationCollateral, rewards.payToLiquidator);

            collateralCurrency.safeTransfer(liquidation.liquidator, rewards.paidToLiquidator.rawValue);

            // If the state is pre-dispute but time has passed liveness then there was no dispute. We represent this
            // state as a dispute failed and the liquidator can withdraw.
        } else if (liquidation.state == Status.NotDisputed) {
            // Pay LIQUIDATOR: collateral + returned final fee
            rewards.payToLiquidator = collateral.add(finalFee);

            // Transfer rewards and debit collateral
            rewards.paidToLiquidator = _removeCollateral(rawLiquidationCollateral, rewards.payToLiquidator);

            collateralCurrency.safeTransfer(liquidation.liquidator, rewards.paidToLiquidator.rawValue);
        }

        emit LiquidationWithdrawn(
            msg.sender,
            rewards.paidToLiquidator.rawValue,
            rewards.paidToDisputer.rawValue,
            rewards.paidToSponsor.rawValue,
            liquidation.state,
            settlementPrice.rawValue
        );

        // Free up space after collateral is withdrawn by removing the liquidation object from the array.
        delete liquidations[sponsor][liquidationId];

        return rewards;
    }

    /**
     * @notice Gets all liquidation information for a given sponsor address.
     * @param sponsor address of the position sponsor.
     * @return liquidationData array of all liquidation information for the given sponsor address.
     */
    function getLiquidations(address sponsor)
        external
        view
        nonReentrantView()
        returns (LiquidationData[] memory liquidationData)
    {
        return liquidations[sponsor];
    }

    /****************************************
     *          INTERNAL FUNCTIONS          *
     ****************************************/

    // This settles a liquidation if it is in the Disputed state. If not, it will immediately return.
    // If the liquidation is in the Disputed state, but a price is not available, this will revert.
    function _settle(uint256 liquidationId, address sponsor) internal {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);

        // Settlement only happens when state == Disputed and will only happen once per liquidation.
        // If this liquidation is not ready to be settled, this method should return immediately.
        if (liquidation.state != Status.Disputed) {
            return;
        }

        // Get the returned price from the oracle. If this has not yet resolved will revert.
        liquidation.settlementPrice = _getOraclePrice(liquidation.liquidationTime);

        // Find the value of the tokens in the underlying collateral.
        FixedPoint.Unsigned memory tokenRedemptionValue =
            liquidation.tokensOutstanding.mul(liquidation.settlementPrice);

        // The required collateral is the value of the tokens in underlying * required collateral ratio.
        FixedPoint.Unsigned memory requiredCollateral = tokenRedemptionValue.mul(collateralRequirement);

        // If the position has more than the required collateral it is solvent and the dispute is valid (liquidation is invalid)
        // Note that this check uses the liquidatedCollateral not the lockedCollateral as this considers withdrawals.
        bool disputeSucceeded = liquidation.liquidatedCollateral.isGreaterThanOrEqual(requiredCollateral);
        liquidation.state = disputeSucceeded ? Status.DisputeSucceeded : Status.DisputeFailed;

        emit DisputeSettled(
            msg.sender,
            sponsor,
            liquidation.liquidator,
            liquidation.disputer,
            liquidationId,
            disputeSucceeded
        );
    }

    function _pfc() internal view override returns (FixedPoint.Unsigned memory) {
        return super._pfc().add(_getFeeAdjustedCollateral(rawLiquidationCollateral));
    }

    function _getLiquidationData(address sponsor, uint256 liquidationId)
        internal
        view
        returns (LiquidationData storage liquidation)
    {
        LiquidationData[] storage liquidationArray = liquidations[sponsor];

        // Revert if the caller is attempting to access an invalid liquidation
        // (one that has never been created or one has never been initialized).
        require(
            liquidationId < liquidationArray.length && liquidationArray[liquidationId].state != Status.Uninitialized
        );
        return liquidationArray[liquidationId];
    }

    function _getLiquidationExpiry(LiquidationData storage liquidation) internal view returns (uint256) {
        return liquidation.liquidationTime.add(liquidationLiveness);
    }

    // These internal functions are supposed to act identically to modifiers, but re-used modifiers
    // unnecessarily increase contract bytecode size.
    // source: https://blog.polymath.network/solidity-tips-and-tricks-to-save-gas-and-reduce-bytecode-size-c44580b218e6
    function _disputable(uint256 liquidationId, address sponsor) internal view {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);
        require(
            (getCurrentTime() < _getLiquidationExpiry(liquidation)) && (liquidation.state == Status.NotDisputed),
            "Liquidation not disputable"
        );
    }

    function _withdrawable(uint256 liquidationId, address sponsor) internal view {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);
        Status state = liquidation.state;

        // Must be disputed or the liquidation has passed expiry.
        require(
            (state > Status.NotDisputed) ||
                ((_getLiquidationExpiry(liquidation) <= getCurrentTime()) && (state == Status.NotDisputed))
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../common/implementation/FixedPoint.sol";
import "../../common/interfaces/ExpandedIERC20.sol";

import "../../oracle/interfaces/OracleInterface.sol";
import "../../oracle/interfaces/IdentifierWhitelistInterface.sol";
import "../../oracle/implementation/Constants.sol";

import "../common/FundingRateApplier.sol";

/**
 * @title Financial contract with priceless position management.
 * @notice Handles positions for multiple sponsors in an optimistic (i.e., priceless) way without relying
 * on a price feed. On construction, deploys a new ERC20, managed by this contract, that is the synthetic token.
 */

contract PerpetualPositionManager is FundingRateApplier {
    using SafeMath for uint256;
    using FixedPoint for FixedPoint.Unsigned;
    using SafeERC20 for IERC20;
    using SafeERC20 for ExpandedIERC20;

    /****************************************
     *  PRICELESS POSITION DATA STRUCTURES  *
     ****************************************/

    // Represents a single sponsor's position. All collateral is held by this contract.
    // This struct acts as bookkeeping for how much of that collateral is allocated to each sponsor.
    struct PositionData {
        FixedPoint.Unsigned tokensOutstanding;
        // Tracks pending withdrawal requests. A withdrawal request is pending if `withdrawalRequestPassTimestamp != 0`.
        uint256 withdrawalRequestPassTimestamp;
        FixedPoint.Unsigned withdrawalRequestAmount;
        // Raw collateral value. This value should never be accessed directly -- always use _getFeeAdjustedCollateral().
        // To add or remove collateral, use _addCollateral() and _removeCollateral().
        FixedPoint.Unsigned rawCollateral;
    }

    // Maps sponsor addresses to their positions. Each sponsor can have only one position.
    mapping(address => PositionData) public positions;

    // Keep track of the total collateral and tokens across all positions to enable calculating the
    // global collateralization ratio without iterating over all positions.
    FixedPoint.Unsigned public totalTokensOutstanding;

    // Similar to the rawCollateral in PositionData, this value should not be used directly.
    // _getFeeAdjustedCollateral(), _addCollateral() and _removeCollateral() must be used to access and adjust.
    FixedPoint.Unsigned public rawTotalPositionCollateral;

    // Synthetic token created by this contract.
    ExpandedIERC20 public tokenCurrency;

    // Unique identifier for DVM price feed ticker.
    bytes32 public priceIdentifier;

    // Time that has to elapse for a withdrawal request to be considered passed, if no liquidations occur.
    // !!Note: The lower the withdrawal liveness value, the more risk incurred by the contract.
    //       Extremely low liveness values increase the chance that opportunistic invalid withdrawal requests
    //       expire without liquidation, thereby increasing the insolvency risk for the contract as a whole. An insolvent
    //       contract is extremely risky for any sponsor or synthetic token holder for the contract.
    uint256 public withdrawalLiveness;

    // Minimum number of tokens in a sponsor's position.
    FixedPoint.Unsigned public minSponsorTokens;

    // Expiry price pulled from the DVM in the case of an emergency shutdown.
    FixedPoint.Unsigned public emergencyShutdownPrice;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
    event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
    event RequestWithdrawal(address indexed sponsor, uint256 indexed collateralAmount);
    event RequestWithdrawalExecuted(address indexed sponsor, uint256 indexed collateralAmount);
    event RequestWithdrawalCanceled(address indexed sponsor, uint256 indexed collateralAmount);
    event PositionCreated(address indexed sponsor, uint256 indexed collateralAmount, uint256 indexed tokenAmount);
    event NewSponsor(address indexed sponsor);
    event EndedSponsorPosition(address indexed sponsor);
    event Redeem(address indexed sponsor, uint256 indexed collateralAmount, uint256 indexed tokenAmount);
    event Repay(address indexed sponsor, uint256 indexed numTokensRepaid, uint256 indexed newTokenCount);
    event EmergencyShutdown(address indexed caller, uint256 shutdownTimestamp);
    event SettleEmergencyShutdown(
        address indexed caller,
        uint256 indexed collateralReturned,
        uint256 indexed tokensBurned
    );

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    modifier onlyCollateralizedPosition(address sponsor) {
        _onlyCollateralizedPosition(sponsor);
        _;
    }

    modifier noPendingWithdrawal(address sponsor) {
        _positionHasNoPendingWithdrawal(sponsor);
        _;
    }

    /**
     * @notice Construct the PerpetualPositionManager.
     * @dev Deployer of this contract should consider carefully which parties have ability to mint and burn
     * the synthetic tokens referenced by `_tokenAddress`. This contract's security assumes that no external accounts
     * can mint new tokens, which could be used to steal all of this contract's locked collateral.
     * We recommend to only use synthetic token contracts whose sole Owner role (the role capable of adding & removing roles)
     * is assigned to this contract, whose sole Minter role is assigned to this contract, and whose
     * total supply is 0 prior to construction of this contract.
     * @param _withdrawalLiveness liveness delay, in seconds, for pending withdrawals.
     * @param _collateralAddress ERC20 token used as collateral for all positions.
     * @param _tokenAddress ERC20 token used as synthetic token.
     * @param _finderAddress UMA protocol Finder used to discover other protocol contracts.
     * @param _priceIdentifier registered in the DVM for the synthetic.
     * @param _fundingRateIdentifier Unique identifier for DVM price feed ticker for child financial contract.
     * @param _minSponsorTokens minimum amount of collateral that must exist at any time in a position.
     * @param _tokenScaling initial scaling to apply to the token value (i.e. scales the tracking index).
     * @param _timerAddress Contract that stores the current time in a testing environment. Set to 0x0 for production.
     */
    constructor(
        uint256 _withdrawalLiveness,
        address _collateralAddress,
        address _tokenAddress,
        address _finderAddress,
        bytes32 _priceIdentifier,
        bytes32 _fundingRateIdentifier,
        FixedPoint.Unsigned memory _minSponsorTokens,
        address _configStoreAddress,
        FixedPoint.Unsigned memory _tokenScaling,
        address _timerAddress
    )
        public
        FundingRateApplier(
            _fundingRateIdentifier,
            _collateralAddress,
            _finderAddress,
            _configStoreAddress,
            _tokenScaling,
            _timerAddress
        )
    {
        require(_getIdentifierWhitelist().isIdentifierSupported(_priceIdentifier));

        withdrawalLiveness = _withdrawalLiveness;
        tokenCurrency = ExpandedIERC20(_tokenAddress);
        minSponsorTokens = _minSponsorTokens;
        priceIdentifier = _priceIdentifier;
    }

    /****************************************
     *          POSITION FUNCTIONS          *
     ****************************************/

    /**
     * @notice Transfers `collateralAmount` of `collateralCurrency` into the specified sponsor's position.
     * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
     * at least `collateralAmount` of `collateralCurrency`.
     * @param sponsor the sponsor to credit the deposit to.
     * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
     */
    function depositTo(address sponsor, FixedPoint.Unsigned memory collateralAmount)
        public
        notEmergencyShutdown()
        noPendingWithdrawal(sponsor)
        fees()
        nonReentrant()
    {
        require(collateralAmount.isGreaterThan(0));
        PositionData storage positionData = _getPositionData(sponsor);

        // Increase the position and global collateral balance by collateral amount.
        _incrementCollateralBalances(positionData, collateralAmount);

        emit Deposit(sponsor, collateralAmount.rawValue);

        // Move collateral currency from sender to contract.
        collateralCurrency.safeTransferFrom(msg.sender, address(this), collateralAmount.rawValue);
    }

    /**
     * @notice Transfers `collateralAmount` of `collateralCurrency` into the caller's position.
     * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
     * at least `collateralAmount` of `collateralCurrency`.
     * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
     */
    function deposit(FixedPoint.Unsigned memory collateralAmount) public {
        // This is just a thin wrapper over depositTo that specified the sender as the sponsor.
        depositTo(msg.sender, collateralAmount);
    }

    /**
     * @notice Transfers `collateralAmount` of `collateralCurrency` from the sponsor's position to the sponsor.
     * @dev Reverts if the withdrawal puts this position's collateralization ratio below the global collateralization
     * ratio. In that case, use `requestWithdrawal`. Might not withdraw the full requested amount to account for precision loss.
     * @param collateralAmount is the amount of collateral to withdraw.
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function withdraw(FixedPoint.Unsigned memory collateralAmount)
        public
        notEmergencyShutdown()
        noPendingWithdrawal(msg.sender)
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        require(collateralAmount.isGreaterThan(0));
        PositionData storage positionData = _getPositionData(msg.sender);

        // Decrement the sponsor's collateral and global collateral amounts. Check the GCR between decrement to ensure
        // position remains above the GCR within the withdrawal. If this is not the case the caller must submit a request.
        amountWithdrawn = _decrementCollateralBalancesCheckGCR(positionData, collateralAmount);

        emit Withdrawal(msg.sender, amountWithdrawn.rawValue);

        // Move collateral currency from contract to sender.
        // Note: that we move the amount of collateral that is decreased from rawCollateral (inclusive of fees)
        // instead of the user requested amount. This eliminates precision loss that could occur
        // where the user withdraws more collateral than rawCollateral is decremented by.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
    }

    /**
     * @notice Starts a withdrawal request that, if passed, allows the sponsor to withdraw from their position.
     * @dev The request will be pending for `withdrawalLiveness`, during which the position can be liquidated.
     * @param collateralAmount the amount of collateral requested to withdraw
     */
    function requestWithdrawal(FixedPoint.Unsigned memory collateralAmount)
        public
        notEmergencyShutdown()
        noPendingWithdrawal(msg.sender)
        nonReentrant()
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(
            collateralAmount.isGreaterThan(0) &&
                collateralAmount.isLessThanOrEqual(_getFeeAdjustedCollateral(positionData.rawCollateral))
        );

        // Update the position object for the user.
        positionData.withdrawalRequestPassTimestamp = getCurrentTime().add(withdrawalLiveness);
        positionData.withdrawalRequestAmount = collateralAmount;

        emit RequestWithdrawal(msg.sender, collateralAmount.rawValue);
    }

    /**
     * @notice After a passed withdrawal request (i.e., by a call to `requestWithdrawal` and waiting
     * `withdrawalLiveness`), withdraws `positionData.withdrawalRequestAmount` of collateral currency.
     * @dev Might not withdraw the full requested amount in order to account for precision loss or if the full requested
     * amount exceeds the collateral in the position (due to paying fees).
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function withdrawPassedRequest()
        external
        notEmergencyShutdown()
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(
            positionData.withdrawalRequestPassTimestamp != 0 &&
                positionData.withdrawalRequestPassTimestamp <= getCurrentTime()
        );

        // If withdrawal request amount is > position collateral, then withdraw the full collateral amount.
        // This situation is possible due to fees charged since the withdrawal was originally requested.
        FixedPoint.Unsigned memory amountToWithdraw = positionData.withdrawalRequestAmount;
        if (positionData.withdrawalRequestAmount.isGreaterThan(_getFeeAdjustedCollateral(positionData.rawCollateral))) {
            amountToWithdraw = _getFeeAdjustedCollateral(positionData.rawCollateral);
        }

        // Decrement the sponsor's collateral and global collateral amounts.
        amountWithdrawn = _decrementCollateralBalances(positionData, amountToWithdraw);

        // Reset withdrawal request by setting withdrawal amount and withdrawal timestamp to 0.
        _resetWithdrawalRequest(positionData);

        // Transfer approved withdrawal amount from the contract to the caller.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);

        emit RequestWithdrawalExecuted(msg.sender, amountWithdrawn.rawValue);
    }

    /**
     * @notice Cancels a pending withdrawal request.
     */
    function cancelWithdrawal() external notEmergencyShutdown() nonReentrant() {
        PositionData storage positionData = _getPositionData(msg.sender);
        // No pending withdrawal require message removed to save bytecode.
        require(positionData.withdrawalRequestPassTimestamp != 0);

        emit RequestWithdrawalCanceled(msg.sender, positionData.withdrawalRequestAmount.rawValue);

        // Reset withdrawal request by setting withdrawal amount and withdrawal timestamp to 0.
        _resetWithdrawalRequest(positionData);
    }

    /**
     * @notice Creates tokens by creating a new position or by augmenting an existing position. Pulls `collateralAmount
     * ` into the sponsor's position and mints `numTokens` of `tokenCurrency`.
     * @dev This contract must have the Minter role for the `tokenCurrency`.
     * @dev Reverts if minting these tokens would put the position's collateralization ratio below the
     * global collateralization ratio. This contract must be approved to spend at least `collateralAmount` of
     * `collateralCurrency`.
     * @param collateralAmount is the number of collateral tokens to collateralize the position with
     * @param numTokens is the number of tokens to mint from the position.
     */
    function create(FixedPoint.Unsigned memory collateralAmount, FixedPoint.Unsigned memory numTokens)
        public
        notEmergencyShutdown()
        fees()
        nonReentrant()
    {
        PositionData storage positionData = positions[msg.sender];

        // Either the new create ratio or the resultant position CR must be above the current GCR.
        require(
            (_checkCollateralization(
                _getFeeAdjustedCollateral(positionData.rawCollateral).add(collateralAmount),
                positionData.tokensOutstanding.add(numTokens)
            ) || _checkCollateralization(collateralAmount, numTokens)),
            "Insufficient collateral"
        );

        require(positionData.withdrawalRequestPassTimestamp == 0);
        if (positionData.tokensOutstanding.isEqual(0)) {
            require(numTokens.isGreaterThanOrEqual(minSponsorTokens));
            emit NewSponsor(msg.sender);
        }

        // Increase the position and global collateral balance by collateral amount.
        _incrementCollateralBalances(positionData, collateralAmount);

        // Add the number of tokens created to the position's outstanding tokens.
        positionData.tokensOutstanding = positionData.tokensOutstanding.add(numTokens);

        totalTokensOutstanding = totalTokensOutstanding.add(numTokens);

        emit PositionCreated(msg.sender, collateralAmount.rawValue, numTokens.rawValue);

        // Transfer tokens into the contract from caller and mint corresponding synthetic tokens to the caller's address.
        collateralCurrency.safeTransferFrom(msg.sender, address(this), collateralAmount.rawValue);

        // Note: revert reason removed to save bytecode.
        require(tokenCurrency.mint(msg.sender, numTokens.rawValue));
    }

    /**
     * @notice Burns `numTokens` of `tokenCurrency` and sends back the proportional amount of `collateralCurrency`.
     * @dev Can only be called by a token sponsor. Might not redeem the full proportional amount of collateral
     * in order to account for precision loss. This contract must be approved to spend at least `numTokens` of
     * `tokenCurrency`.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @param numTokens is the number of tokens to be burnt for a commensurate amount of collateral.
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function redeem(FixedPoint.Unsigned memory numTokens)
        public
        notEmergencyShutdown()
        noPendingWithdrawal(msg.sender)
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(numTokens.isLessThanOrEqual(positionData.tokensOutstanding));

        FixedPoint.Unsigned memory fractionRedeemed = numTokens.div(positionData.tokensOutstanding);
        FixedPoint.Unsigned memory collateralRedeemed =
            fractionRedeemed.mul(_getFeeAdjustedCollateral(positionData.rawCollateral));

        // If redemption returns all tokens the sponsor has then we can delete their position. Else, downsize.
        if (positionData.tokensOutstanding.isEqual(numTokens)) {
            amountWithdrawn = _deleteSponsorPosition(msg.sender);
        } else {
            // Decrement the sponsor's collateral and global collateral amounts.
            amountWithdrawn = _decrementCollateralBalances(positionData, collateralRedeemed);

            // Decrease the sponsors position tokens size. Ensure it is above the min sponsor size.
            FixedPoint.Unsigned memory newTokenCount = positionData.tokensOutstanding.sub(numTokens);
            require(newTokenCount.isGreaterThanOrEqual(minSponsorTokens));
            positionData.tokensOutstanding = newTokenCount;

            // Update the totalTokensOutstanding after redemption.
            totalTokensOutstanding = totalTokensOutstanding.sub(numTokens);
        }

        emit Redeem(msg.sender, amountWithdrawn.rawValue, numTokens.rawValue);

        // Transfer collateral from contract to caller and burn callers synthetic tokens.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
        tokenCurrency.safeTransferFrom(msg.sender, address(this), numTokens.rawValue);
        tokenCurrency.burn(numTokens.rawValue);
    }

    /**
     * @notice Burns `numTokens` of `tokenCurrency` to decrease sponsors position size, without sending back `collateralCurrency`.
     * This is done by a sponsor to increase position CR. Resulting size is bounded by minSponsorTokens.
     * @dev Can only be called by token sponsor. This contract must be approved to spend `numTokens` of `tokenCurrency`.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @param numTokens is the number of tokens to be burnt from the sponsor's debt position.
     */
    function repay(FixedPoint.Unsigned memory numTokens)
        public
        notEmergencyShutdown()
        noPendingWithdrawal(msg.sender)
        fees()
        nonReentrant()
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(numTokens.isLessThanOrEqual(positionData.tokensOutstanding));

        // Decrease the sponsors position tokens size. Ensure it is above the min sponsor size.
        FixedPoint.Unsigned memory newTokenCount = positionData.tokensOutstanding.sub(numTokens);
        require(newTokenCount.isGreaterThanOrEqual(minSponsorTokens));
        positionData.tokensOutstanding = newTokenCount;

        // Update the totalTokensOutstanding after redemption.
        totalTokensOutstanding = totalTokensOutstanding.sub(numTokens);

        emit Repay(msg.sender, numTokens.rawValue, newTokenCount.rawValue);

        // Transfer the tokens back from the sponsor and burn them.
        tokenCurrency.safeTransferFrom(msg.sender, address(this), numTokens.rawValue);
        tokenCurrency.burn(numTokens.rawValue);
    }

    /**
     * @notice If the contract is emergency shutdown then all token holders and sponsors can redeem their tokens or
     * remaining collateral for underlying at the prevailing price defined by a DVM vote.
     * @dev This burns all tokens from the caller of `tokenCurrency` and sends back the resolved settlement value of
     * `collateralCurrency`. Might not redeem the full proportional amount of collateral in order to account for
     * precision loss. This contract must be approved to spend `tokenCurrency` at least up to the caller's full balance.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @dev Note that this function does not call the updateFundingRate modifier to update the funding rate as this
     * function is only called after an emergency shutdown & there should be no funding rate updates after the shutdown.
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function settleEmergencyShutdown()
        external
        isEmergencyShutdown()
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        // Set the emergency shutdown price as resolved from the DVM. If DVM has not resolved will revert.
        if (emergencyShutdownPrice.isEqual(FixedPoint.fromUnscaledUint(0))) {
            emergencyShutdownPrice = _getOracleEmergencyShutdownPrice();
        }

        // Get caller's tokens balance and calculate amount of underlying entitled to them.
        FixedPoint.Unsigned memory tokensToRedeem = FixedPoint.Unsigned(tokenCurrency.balanceOf(msg.sender));
        FixedPoint.Unsigned memory totalRedeemableCollateral =
            _getFundingRateAppliedTokenDebt(tokensToRedeem).mul(emergencyShutdownPrice);

        // If the caller is a sponsor with outstanding collateral they are also entitled to their excess collateral after their debt.
        PositionData storage positionData = positions[msg.sender];
        if (_getFeeAdjustedCollateral(positionData.rawCollateral).isGreaterThan(0)) {
            // Calculate the underlying entitled to a token sponsor. This is collateral - debt in underlying with
            // the funding rate applied to the outstanding token debt.

            FixedPoint.Unsigned memory tokenDebtValueInCollateral =
                _getFundingRateAppliedTokenDebt(positionData.tokensOutstanding).mul(emergencyShutdownPrice);
            FixedPoint.Unsigned memory positionCollateral = _getFeeAdjustedCollateral(positionData.rawCollateral);

            // If the debt is greater than the remaining collateral, they cannot redeem anything.
            FixedPoint.Unsigned memory positionRedeemableCollateral =
                tokenDebtValueInCollateral.isLessThan(positionCollateral)
                    ? positionCollateral.sub(tokenDebtValueInCollateral)
                    : FixedPoint.Unsigned(0);

            // Add the number of redeemable tokens for the sponsor to their total redeemable collateral.
            totalRedeemableCollateral = totalRedeemableCollateral.add(positionRedeemableCollateral);

            // Reset the position state as all the value has been removed after settlement.
            delete positions[msg.sender];
            emit EndedSponsorPosition(msg.sender);
        }

        // Take the min of the remaining collateral and the collateral "owed". If the contract is undercapitalized,
        // the caller will get as much collateral as the contract can pay out.
        FixedPoint.Unsigned memory payout =
            FixedPoint.min(_getFeeAdjustedCollateral(rawTotalPositionCollateral), totalRedeemableCollateral);

        // Decrement total contract collateral and outstanding debt.
        amountWithdrawn = _removeCollateral(rawTotalPositionCollateral, payout);
        totalTokensOutstanding = totalTokensOutstanding.sub(tokensToRedeem);

        emit SettleEmergencyShutdown(msg.sender, amountWithdrawn.rawValue, tokensToRedeem.rawValue);

        // Transfer tokens & collateral and burn the redeemed tokens.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
        tokenCurrency.safeTransferFrom(msg.sender, address(this), tokensToRedeem.rawValue);
        tokenCurrency.burn(tokensToRedeem.rawValue);
    }

    /****************************************
     *        GLOBAL STATE FUNCTIONS        *
     ****************************************/

    /**
     * @notice Premature contract settlement under emergency circumstances.
     * @dev Only the governor can call this function as they are permissioned within the `FinancialContractAdmin`.
     * Upon emergency shutdown, the contract settlement time is set to the shutdown time. This enables withdrawal
     * to occur via the `settleEmergencyShutdown` function.
     */
    function emergencyShutdown() external override notEmergencyShutdown() fees() nonReentrant() {
        // Note: revert reason removed to save bytecode.
        require(msg.sender == _getFinancialContractsAdminAddress());

        emergencyShutdownTimestamp = getCurrentTime();
        _requestOraclePrice(emergencyShutdownTimestamp);

        emit EmergencyShutdown(msg.sender, emergencyShutdownTimestamp);
    }

    /**
     * @notice Theoretically supposed to pay fees and move money between margin accounts to make sure they
     * reflect the NAV of the contract. However, this functionality doesn't apply to this contract.
     * @dev This is supposed to be implemented by any contract that inherits `AdministrateeInterface` and callable
     * only by the Governor contract. This method is therefore minimally implemented in this contract and does nothing.
     */
    function remargin() external override {
        return;
    }

    /**
     * @notice Accessor method for a sponsor's collateral.
     * @dev This is necessary because the struct returned by the positions() method shows
     * rawCollateral, which isn't a user-readable value.
     * @dev This method accounts for pending regular fees that have not yet been withdrawn from this contract, for
     * example if the `lastPaymentTime != currentTime`.
     * @param sponsor address whose collateral amount is retrieved.
     * @return collateralAmount amount of collateral within a sponsors position.
     */
    function getCollateral(address sponsor)
        external
        view
        nonReentrantView()
        returns (FixedPoint.Unsigned memory collateralAmount)
    {
        // Note: do a direct access to avoid the validity check.
        return _getPendingRegularFeeAdjustedCollateral(_getFeeAdjustedCollateral(positions[sponsor].rawCollateral));
    }

    /**
     * @notice Accessor method for the total collateral stored within the PerpetualPositionManager.
     * @return totalCollateral amount of all collateral within the position manager.
     */
    function totalPositionCollateral()
        external
        view
        nonReentrantView()
        returns (FixedPoint.Unsigned memory totalCollateral)
    {
        return _getPendingRegularFeeAdjustedCollateral(_getFeeAdjustedCollateral(rawTotalPositionCollateral));
    }

    function getFundingRateAppliedTokenDebt(FixedPoint.Unsigned memory rawTokenDebt)
        external
        view
        nonReentrantView()
        returns (FixedPoint.Unsigned memory totalCollateral)
    {
        return _getFundingRateAppliedTokenDebt(rawTokenDebt);
    }

    /****************************************
     *          INTERNAL FUNCTIONS          *
     ****************************************/

    // Reduces a sponsor's position and global counters by the specified parameters. Handles deleting the entire
    // position if the entire position is being removed. Does not make any external transfers.
    function _reduceSponsorPosition(
        address sponsor,
        FixedPoint.Unsigned memory tokensToRemove,
        FixedPoint.Unsigned memory collateralToRemove,
        FixedPoint.Unsigned memory withdrawalAmountToRemove
    ) internal {
        PositionData storage positionData = _getPositionData(sponsor);

        // If the entire position is being removed, delete it instead.
        if (
            tokensToRemove.isEqual(positionData.tokensOutstanding) &&
            _getFeeAdjustedCollateral(positionData.rawCollateral).isEqual(collateralToRemove)
        ) {
            _deleteSponsorPosition(sponsor);
            return;
        }

        // Decrement the sponsor's collateral and global collateral amounts.
        _decrementCollateralBalances(positionData, collateralToRemove);

        // Ensure that the sponsor will meet the min position size after the reduction.
        positionData.tokensOutstanding = positionData.tokensOutstanding.sub(tokensToRemove);
        require(positionData.tokensOutstanding.isGreaterThanOrEqual(minSponsorTokens));

        // Decrement the position's withdrawal amount.
        positionData.withdrawalRequestAmount = positionData.withdrawalRequestAmount.sub(withdrawalAmountToRemove);

        // Decrement the total outstanding tokens in the overall contract.
        totalTokensOutstanding = totalTokensOutstanding.sub(tokensToRemove);
    }

    // Deletes a sponsor's position and updates global counters. Does not make any external transfers.
    function _deleteSponsorPosition(address sponsor) internal returns (FixedPoint.Unsigned memory) {
        PositionData storage positionToLiquidate = _getPositionData(sponsor);

        FixedPoint.Unsigned memory startingGlobalCollateral = _getFeeAdjustedCollateral(rawTotalPositionCollateral);

        // Remove the collateral and outstanding from the overall total position.
        rawTotalPositionCollateral = rawTotalPositionCollateral.sub(positionToLiquidate.rawCollateral);
        totalTokensOutstanding = totalTokensOutstanding.sub(positionToLiquidate.tokensOutstanding);

        // Reset the sponsors position to have zero outstanding and collateral.
        delete positions[sponsor];

        emit EndedSponsorPosition(sponsor);

        // Return fee-adjusted amount of collateral deleted from position.
        return startingGlobalCollateral.sub(_getFeeAdjustedCollateral(rawTotalPositionCollateral));
    }

    function _pfc() internal view virtual override returns (FixedPoint.Unsigned memory) {
        return _getFeeAdjustedCollateral(rawTotalPositionCollateral);
    }

    function _getPositionData(address sponsor)
        internal
        view
        onlyCollateralizedPosition(sponsor)
        returns (PositionData storage)
    {
        return positions[sponsor];
    }

    function _getIdentifierWhitelist() internal view returns (IdentifierWhitelistInterface) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }

    function _getOracle() internal view returns (OracleInterface) {
        return OracleInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
    }

    function _getFinancialContractsAdminAddress() internal view returns (address) {
        return finder.getImplementationAddress(OracleInterfaces.FinancialContractsAdmin);
    }

    // Requests a price for `priceIdentifier` at `requestedTime` from the Oracle.
    function _requestOraclePrice(uint256 requestedTime) internal {
        _getOracle().requestPrice(priceIdentifier, requestedTime);
    }

    // Fetches a resolved Oracle price from the Oracle. Reverts if the Oracle hasn't resolved for this request.
    function _getOraclePrice(uint256 requestedTime) internal view returns (FixedPoint.Unsigned memory price) {
        // Create an instance of the oracle and get the price. If the price is not resolved revert.
        int256 oraclePrice = _getOracle().getPrice(priceIdentifier, requestedTime);

        // For now we don't want to deal with negative prices in positions.
        if (oraclePrice < 0) {
            oraclePrice = 0;
        }
        return FixedPoint.Unsigned(uint256(oraclePrice));
    }

    // Fetches a resolved Oracle price from the Oracle. Reverts if the Oracle hasn't resolved for this request.
    function _getOracleEmergencyShutdownPrice() internal view returns (FixedPoint.Unsigned memory) {
        return _getOraclePrice(emergencyShutdownTimestamp);
    }

    // Reset withdrawal request by setting the withdrawal request and withdrawal timestamp to 0.
    function _resetWithdrawalRequest(PositionData storage positionData) internal {
        positionData.withdrawalRequestAmount = FixedPoint.fromUnscaledUint(0);
        positionData.withdrawalRequestPassTimestamp = 0;
    }

    // Ensure individual and global consistency when increasing collateral balances. Returns the change to the position.
    function _incrementCollateralBalances(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _addCollateral(positionData.rawCollateral, collateralAmount);
        return _addCollateral(rawTotalPositionCollateral, collateralAmount);
    }

    // Ensure individual and global consistency when decrementing collateral balances. Returns the change to the
    // position. We elect to return the amount that the global collateral is decreased by, rather than the individual
    // position's collateral, because we need to maintain the invariant that the global collateral is always
    // <= the collateral owned by the contract to avoid reverts on withdrawals. The amount returned = amount withdrawn.
    function _decrementCollateralBalances(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _removeCollateral(positionData.rawCollateral, collateralAmount);
        return _removeCollateral(rawTotalPositionCollateral, collateralAmount);
    }

    // Ensure individual and global consistency when decrementing collateral balances. Returns the change to the position.
    // This function is similar to the _decrementCollateralBalances function except this function checks position GCR
    // between the decrements. This ensures that collateral removal will not leave the position undercollateralized.
    function _decrementCollateralBalancesCheckGCR(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _removeCollateral(positionData.rawCollateral, collateralAmount);
        require(_checkPositionCollateralization(positionData), "CR below GCR");
        return _removeCollateral(rawTotalPositionCollateral, collateralAmount);
    }

    // These internal functions are supposed to act identically to modifiers, but re-used modifiers
    // unnecessarily increase contract bytecode size.
    // source: https://blog.polymath.network/solidity-tips-and-tricks-to-save-gas-and-reduce-bytecode-size-c44580b218e6
    function _onlyCollateralizedPosition(address sponsor) internal view {
        require(_getFeeAdjustedCollateral(positions[sponsor].rawCollateral).isGreaterThan(0));
    }

    // Note: This checks whether an already existing position has a pending withdrawal. This cannot be used on the
    // `create` method because it is possible that `create` is called on a new position (i.e. one without any collateral
    // or tokens outstanding) which would fail the `onlyCollateralizedPosition` modifier on `_getPositionData`.
    function _positionHasNoPendingWithdrawal(address sponsor) internal view {
        require(_getPositionData(sponsor).withdrawalRequestPassTimestamp == 0);
    }

    /****************************************
     *          PRIVATE FUNCTIONS          *
     ****************************************/

    function _checkPositionCollateralization(PositionData storage positionData) private view returns (bool) {
        return
            _checkCollateralization(
                _getFeeAdjustedCollateral(positionData.rawCollateral),
                positionData.tokensOutstanding
            );
    }

    // Checks whether the provided `collateral` and `numTokens` have a collateralization ratio above the global
    // collateralization ratio.
    function _checkCollateralization(FixedPoint.Unsigned memory collateral, FixedPoint.Unsigned memory numTokens)
        private
        view
        returns (bool)
    {
        FixedPoint.Unsigned memory global =
            _getCollateralizationRatio(_getFeeAdjustedCollateral(rawTotalPositionCollateral), totalTokensOutstanding);
        FixedPoint.Unsigned memory thisChange = _getCollateralizationRatio(collateral, numTokens);
        return !global.isGreaterThan(thisChange);
    }

    function _getCollateralizationRatio(FixedPoint.Unsigned memory collateral, FixedPoint.Unsigned memory numTokens)
        private
        pure
        returns (FixedPoint.Unsigned memory ratio)
    {
        return numTokens.isLessThanOrEqual(0) ? FixedPoint.fromUnscaledUint(0) : collateral.div(numTokens);
    }

    function _getTokenAddress() internal view override returns (address) {
        return address(tokenCurrency);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../common/implementation/Lockable.sol";
import "../../common/implementation/FixedPoint.sol";
import "../../common/implementation/Testable.sol";

import "../../oracle/implementation/Constants.sol";
import "../../oracle/interfaces/OptimisticOracleInterface.sol";
import "../perpetual-multiparty/ConfigStoreInterface.sol";

import "./EmergencyShutdownable.sol";
import "./FeePayer.sol";

/**
 * @title FundingRateApplier contract.
 * @notice Provides funding rate payment functionality for the Perpetual contract.
 */

abstract contract FundingRateApplier is EmergencyShutdownable, FeePayer {
    using FixedPoint for FixedPoint.Unsigned;
    using FixedPoint for FixedPoint.Signed;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /****************************************
     * FUNDING RATE APPLIER DATA STRUCTURES *
     ****************************************/

    struct FundingRate {
        // Current funding rate value.
        FixedPoint.Signed rate;
        // Identifier to retrieve the funding rate.
        bytes32 identifier;
        // Tracks the cumulative funding payments that have been paid to the sponsors.
        // The multiplier starts at 1, and is updated by computing cumulativeFundingRateMultiplier * (1 + effectivePayment).
        // Put another way, the cumulativeFeeMultiplier is (1 + effectivePayment1) * (1 + effectivePayment2) ...
        // For example:
        // The cumulativeFundingRateMultiplier should start at 1.
        // If a 1% funding payment is paid to sponsors, the multiplier should update to 1.01.
        // If another 1% fee is charged, the multiplier should be 1.01^2 (1.0201).
        FixedPoint.Unsigned cumulativeMultiplier;
        // Most recent time that the funding rate was updated.
        uint256 updateTime;
        // Most recent time that the funding rate was applied and changed the cumulative multiplier.
        uint256 applicationTime;
        // The time for the active (if it exists) funding rate proposal. 0 otherwise.
        uint256 proposalTime;
    }

    FundingRate public fundingRate;

    // Remote config store managed an owner.
    ConfigStoreInterface public configStore;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event FundingRateUpdated(int256 newFundingRate, uint256 indexed updateTime, uint256 reward);

    /****************************************
     *              MODIFIERS               *
     ****************************************/

    // This is overridden to both pay fees (which is done by applyFundingRate()) and apply the funding rate.
    modifier fees override {
        // Note: the funding rate is applied on every fee-accruing transaction, where the total change is simply the
        // rate applied linearly since the last update. This implies that the compounding rate depends on the frequency
        // of update transactions that have this modifier, and it never reaches the ideal of continuous compounding.
        // This approximate-compounding pattern is common in the Ethereum ecosystem because of the complexity of
        // compounding data on-chain.
        applyFundingRate();
        _;
    }

    // Note: this modifier is intended to be used if the caller intends to _only_ pay regular fees.
    modifier paysRegularFees {
        payRegularFees();
        _;
    }

    /**
     * @notice Constructs the FundingRateApplier contract. Called by child contracts.
     * @param _fundingRateIdentifier identifier that tracks the funding rate of this contract.
     * @param _collateralAddress address of the collateral token.
     * @param _finderAddress Finder used to discover financial-product-related contracts.
     * @param _configStoreAddress address of the remote configuration store managed by an external owner.
     * @param _tokenScaling initial scaling to apply to the token value (i.e. scales the tracking index).
     * @param _timerAddress address of the timer contract in test envs, otherwise 0x0.
     */
    constructor(
        bytes32 _fundingRateIdentifier,
        address _collateralAddress,
        address _finderAddress,
        address _configStoreAddress,
        FixedPoint.Unsigned memory _tokenScaling,
        address _timerAddress
    ) public FeePayer(_collateralAddress, _finderAddress, _timerAddress) EmergencyShutdownable() {
        uint256 currentTime = getCurrentTime();
        fundingRate.updateTime = currentTime;
        fundingRate.applicationTime = currentTime;

        // Seed the cumulative multiplier with the token scaling, from which it will be scaled as funding rates are
        // applied over time.
        fundingRate.cumulativeMultiplier = _tokenScaling;

        fundingRate.identifier = _fundingRateIdentifier;
        configStore = ConfigStoreInterface(_configStoreAddress);
    }

    /**
     * @notice This method takes 3 distinct actions:
     * 1. Pays out regular fees.
     * 2. If possible, resolves the outstanding funding rate proposal, pulling the result in and paying out the rewards.
     * 3. Applies the prevailing funding rate over the most recent period.
     */
    function applyFundingRate() public paysRegularFees() nonReentrant() {
        _applyEffectiveFundingRate();
    }

    /**
     * @notice Proposes a new funding rate. Proposer receives a reward if correct.
     * @param rate funding rate being proposed.
     * @param timestamp time at which the funding rate was computed.
     */
    function proposeFundingRate(FixedPoint.Signed memory rate, uint256 timestamp)
        external
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory totalBond)
    {
        require(fundingRate.proposalTime == 0, "Proposal in progress");
        _validateFundingRate(rate);

        // Timestamp must be after the last funding rate update time, within the last 30 minutes.
        uint256 currentTime = getCurrentTime();
        uint256 updateTime = fundingRate.updateTime;
        require(
            timestamp > updateTime && timestamp >= currentTime.sub(_getConfig().proposalTimePastLimit),
            "Invalid proposal time"
        );

        // Set the proposal time in order to allow this contract to track this request.
        fundingRate.proposalTime = timestamp;

        OptimisticOracleInterface optimisticOracle = _getOptimisticOracle();

        // Set up optimistic oracle.
        bytes32 identifier = fundingRate.identifier;
        bytes memory ancillaryData = _getAncillaryData();
        // Note: requestPrice will revert if `timestamp` is less than the current block timestamp.
        optimisticOracle.requestPrice(identifier, timestamp, ancillaryData, collateralCurrency, 0);
        totalBond = FixedPoint.Unsigned(
            optimisticOracle.setBond(
                identifier,
                timestamp,
                ancillaryData,
                _pfc().mul(_getConfig().proposerBondPercentage).rawValue
            )
        );

        // Pull bond from caller and send to optimistic oracle.
        if (totalBond.isGreaterThan(0)) {
            collateralCurrency.safeTransferFrom(msg.sender, address(this), totalBond.rawValue);
            collateralCurrency.safeIncreaseAllowance(address(optimisticOracle), totalBond.rawValue);
        }

        optimisticOracle.proposePriceFor(
            msg.sender,
            address(this),
            identifier,
            timestamp,
            ancillaryData,
            rate.rawValue
        );
    }

    // Returns a token amount scaled by the current funding rate multiplier.
    // Note: if the contract has paid fees since it was deployed, the raw value should be larger than the returned value.
    function _getFundingRateAppliedTokenDebt(FixedPoint.Unsigned memory rawTokenDebt)
        internal
        view
        returns (FixedPoint.Unsigned memory tokenDebt)
    {
        return rawTokenDebt.mul(fundingRate.cumulativeMultiplier);
    }

    function _getOptimisticOracle() internal view returns (OptimisticOracleInterface) {
        return OptimisticOracleInterface(finder.getImplementationAddress(OracleInterfaces.OptimisticOracle));
    }

    function _getConfig() internal returns (ConfigStoreInterface.ConfigSettings memory) {
        return configStore.updateAndGetCurrentConfig();
    }

    function _updateFundingRate() internal {
        uint256 proposalTime = fundingRate.proposalTime;
        // If there is no pending proposal then do nothing. Otherwise check to see if we can update the funding rate.
        if (proposalTime != 0) {
            // Attempt to update the funding rate.
            OptimisticOracleInterface optimisticOracle = _getOptimisticOracle();
            bytes32 identifier = fundingRate.identifier;
            bytes memory ancillaryData = _getAncillaryData();

            // Try to get the price from the optimistic oracle. This call will revert if the request has not resolved
            // yet. If the request has not resolved yet, then we need to do additional checks to see if we should
            // "forget" the pending proposal and allow new proposals to update the funding rate.
            try optimisticOracle.settleAndGetPrice(identifier, proposalTime, ancillaryData) returns (int256 price) {
                // If successful, determine if the funding rate state needs to be updated.
                // If the request is more recent than the last update then we should update it.
                uint256 lastUpdateTime = fundingRate.updateTime;
                if (proposalTime >= lastUpdateTime) {
                    // Update funding rates
                    fundingRate.rate = FixedPoint.Signed(price);
                    fundingRate.updateTime = proposalTime;

                    // If there was no dispute, send a reward.
                    FixedPoint.Unsigned memory reward = FixedPoint.fromUnscaledUint(0);
                    OptimisticOracleInterface.Request memory request =
                        optimisticOracle.getRequest(address(this), identifier, proposalTime, ancillaryData);
                    if (request.disputer == address(0)) {
                        reward = _pfc().mul(_getConfig().rewardRatePerSecond).mul(proposalTime.sub(lastUpdateTime));
                        if (reward.isGreaterThan(0)) {
                            _adjustCumulativeFeeMultiplier(reward, _pfc());
                            collateralCurrency.safeTransfer(request.proposer, reward.rawValue);
                        }
                    }

                    // This event will only be emitted after the fundingRate struct's "updateTime" has been set
                    // to the latest proposal's proposalTime, indicating that the proposal has been published.
                    // So, it suffices to just emit fundingRate.updateTime here.
                    emit FundingRateUpdated(fundingRate.rate.rawValue, fundingRate.updateTime, reward.rawValue);
                }

                // Set proposal time to 0 since this proposal has now been resolved.
                fundingRate.proposalTime = 0;
            } catch {
                // Stop tracking and allow other proposals to come in if:
                // - The requester address is empty, indicating that the Oracle does not know about this funding rate
                //   request. This is possible if the Oracle is replaced while the price request is still pending.
                // - The request has been disputed.
                OptimisticOracleInterface.Request memory request =
                    optimisticOracle.getRequest(address(this), identifier, proposalTime, ancillaryData);
                if (request.disputer != address(0) || request.proposer == address(0)) {
                    fundingRate.proposalTime = 0;
                }
            }
        }
    }

    // Constraining the range of funding rates limits the PfC for any dishonest proposer and enhances the
    // perpetual's security. For example, let's examine the case where the max and min funding rates
    // are equivalent to +/- 500%/year. This 1000% funding rate range allows a 8.6% profit from corruption for a
    // proposer who can deter honest proposers for 74 hours:
    // 1000%/year / 360 days / 24 hours * 74 hours max attack time = ~ 8.6%.
    // How would attack work? Imagine that the market is very volatile currently and that the "true" funding
    // rate for the next 74 hours is -500%, but a dishonest proposer successfully proposes a rate of +500%
    // (after a two hour liveness) and disputes honest proposers for the next 72 hours. This results in a funding
    // rate error of 1000% for 74 hours, until the DVM can set the funding rate back to its correct value.
    function _validateFundingRate(FixedPoint.Signed memory rate) internal {
        require(
            rate.isLessThanOrEqual(_getConfig().maxFundingRate) &&
                rate.isGreaterThanOrEqual(_getConfig().minFundingRate)
        );
    }

    // Fetches a funding rate from the Store, determines the period over which to compute an effective fee,
    // and multiplies the current multiplier by the effective fee.
    // A funding rate < 1 will reduce the multiplier, and a funding rate of > 1 will increase the multiplier.
    // Note: 1 is set as the neutral rate because there are no negative numbers in FixedPoint, so we decide to treat
    // values < 1 as "negative".
    function _applyEffectiveFundingRate() internal {
        // If contract is emergency shutdown, then the funding rate multiplier should no longer change.
        if (emergencyShutdownTimestamp != 0) {
            return;
        }

        uint256 currentTime = getCurrentTime();
        uint256 paymentPeriod = currentTime.sub(fundingRate.applicationTime);

        _updateFundingRate(); // Update the funding rate if there is a resolved proposal.
        fundingRate.cumulativeMultiplier = _calculateEffectiveFundingRate(
            paymentPeriod,
            fundingRate.rate,
            fundingRate.cumulativeMultiplier
        );

        fundingRate.applicationTime = currentTime;
    }

    function _calculateEffectiveFundingRate(
        uint256 paymentPeriodSeconds,
        FixedPoint.Signed memory fundingRatePerSecond,
        FixedPoint.Unsigned memory currentCumulativeFundingRateMultiplier
    ) internal pure returns (FixedPoint.Unsigned memory newCumulativeFundingRateMultiplier) {
        // Note: this method uses named return variables to save a little bytecode.

        // The overall formula that this function is performing:
        //   newCumulativeFundingRateMultiplier =
        //   (1 + (fundingRatePerSecond * paymentPeriodSeconds)) * currentCumulativeFundingRateMultiplier.
        FixedPoint.Signed memory ONE = FixedPoint.fromUnscaledInt(1);

        // Multiply the per-second rate over the number of seconds that have elapsed to get the period rate.
        FixedPoint.Signed memory periodRate = fundingRatePerSecond.mul(SafeCast.toInt256(paymentPeriodSeconds));

        // Add one to create the multiplier to scale the existing fee multiplier.
        FixedPoint.Signed memory signedPeriodMultiplier = ONE.add(periodRate);

        // Max with 0 to ensure the multiplier isn't negative, then cast to an Unsigned.
        FixedPoint.Unsigned memory unsignedPeriodMultiplier =
            FixedPoint.fromSigned(FixedPoint.max(signedPeriodMultiplier, FixedPoint.fromUnscaledInt(0)));

        // Multiply the existing cumulative funding rate multiplier by the computed period multiplier to get the new
        // cumulative funding rate multiplier.
        newCumulativeFundingRateMultiplier = currentCumulativeFundingRateMultiplier.mul(unsignedPeriodMultiplier);
    }

    function _getAncillaryData() internal view returns (bytes memory) {
        // Note: when ancillary data is passed to the optimistic oracle, it should be tagged with the token address
        // whose funding rate it's trying to get.
        return abi.encodePacked(_getTokenAddress());
    }

    function _getTokenAddress() internal view virtual returns (address);
}

pragma solidity ^0.6.0;


/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/implementation/FixedPoint.sol";

interface ConfigStoreInterface {
    // All of the configuration settings available for querying by a perpetual.
    struct ConfigSettings {
        // Liveness period (in seconds) for an update to currentConfig to become official.
        uint256 timelockLiveness;
        // Reward rate paid to successful proposers. Percentage of 1 E.g., .1 is 10%.
        FixedPoint.Unsigned rewardRatePerSecond;
        // Bond % (of given contract's PfC) that must be staked by proposers. Percentage of 1, e.g. 0.0005 is 0.05%.
        FixedPoint.Unsigned proposerBondPercentage;
        // Maximum funding rate % per second that can be proposed.
        FixedPoint.Signed maxFundingRate;
        // Minimum funding rate % per second that can be proposed.
        FixedPoint.Signed minFundingRate;
        // Funding rate proposal timestamp cannot be more than this amount of seconds in the past from the latest
        // update time.
        uint256 proposalTimePastLimit;
    }

    function updateAndGetCurrentConfig() external returns (ConfigSettings memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title EmergencyShutdownable contract.
 * @notice Any contract that inherits this contract will have an emergency shutdown timestamp state variable.
 * This contract provides modifiers that can be used by children contracts to determine if the contract is
 * in the shutdown state. The child contract is expected to implement the logic that happens
 * once a shutdown occurs.
 */

abstract contract EmergencyShutdownable {
    using SafeMath for uint256;

    /****************************************
     * EMERGENCY SHUTDOWN DATA STRUCTURES *
     ****************************************/

    // Timestamp used in case of emergency shutdown. 0 if no shutdown has been triggered.
    uint256 public emergencyShutdownTimestamp;

    /****************************************
     *              MODIFIERS               *
     ****************************************/

    modifier notEmergencyShutdown() {
        _notEmergencyShutdown();
        _;
    }

    modifier isEmergencyShutdown() {
        _isEmergencyShutdown();
        _;
    }

    /****************************************
     *          EXTERNAL FUNCTIONS          *
     ****************************************/

    constructor() public {
        emergencyShutdownTimestamp = 0;
    }

    /****************************************
     *          INTERNAL FUNCTIONS          *
     ****************************************/

    function _notEmergencyShutdown() internal view {
        // Note: removed require string to save bytecode.
        require(emergencyShutdownTimestamp == 0);
    }

    function _isEmergencyShutdown() internal view {
        // Note: removed require string to save bytecode.
        require(emergencyShutdownTimestamp != 0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/interfaces/ExpandedIERC20.sol";
import "../../common/interfaces/IERC20Standard.sol";
import "../../oracle/implementation/ContractCreator.sol";
import "../../common/implementation/Testable.sol";
import "../../common/implementation/AddressWhitelist.sol";
import "../../common/implementation/Lockable.sol";
import "../common/TokenFactory.sol";
import "../common/SyntheticToken.sol";
import "./ExpiringMultiPartyLib.sol";

/**
 * @title Expiring Multi Party Contract creator.
 * @notice Factory contract to create and register new instances of expiring multiparty contracts.
 * Responsible for constraining the parameters used to construct a new EMP. This creator contains a number of constraints
 * that are applied to newly created expiring multi party contract. These constraints can evolve over time and are
 * initially constrained to conservative values in this first iteration. Technically there is nothing in the
 * ExpiringMultiParty contract requiring these constraints. However, because `createExpiringMultiParty()` is intended
 * to be the only way to create valid financial contracts that are registered with the DVM (via _registerContract),
  we can enforce deployment configurations here.
 */
contract ExpiringMultiPartyCreator is ContractCreator, Testable, Lockable {
    using FixedPoint for FixedPoint.Unsigned;

    /****************************************
     *     EMP CREATOR DATA STRUCTURES      *
     ****************************************/

    struct Params {
        uint256 expirationTimestamp;
        address collateralAddress;
        bytes32 priceFeedIdentifier;
        string syntheticName;
        string syntheticSymbol;
        FixedPoint.Unsigned collateralRequirement;
        FixedPoint.Unsigned disputeBondPercentage;
        FixedPoint.Unsigned sponsorDisputeRewardPercentage;
        FixedPoint.Unsigned disputerDisputeRewardPercentage;
        FixedPoint.Unsigned minSponsorTokens;
        uint256 withdrawalLiveness;
        uint256 liquidationLiveness;
        address financialProductLibraryAddress;
    }
    // Address of TokenFactory used to create a new synthetic token.
    address public tokenFactoryAddress;

    event CreatedExpiringMultiParty(address indexed expiringMultiPartyAddress, address indexed deployerAddress);

    /**
     * @notice Constructs the ExpiringMultiPartyCreator contract.
     * @param _finderAddress UMA protocol Finder used to discover other protocol contracts.
     * @param _tokenFactoryAddress ERC20 token factory used to deploy synthetic token instances.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     */
    constructor(
        address _finderAddress,
        address _tokenFactoryAddress,
        address _timerAddress
    ) public ContractCreator(_finderAddress) Testable(_timerAddress) nonReentrant() {
        tokenFactoryAddress = _tokenFactoryAddress;
    }

    /**
     * @notice Creates an instance of expiring multi party and registers it within the registry.
     * @param params is a `ConstructorParams` object from ExpiringMultiParty.
     * @return address of the deployed ExpiringMultiParty contract.
     */
    function createExpiringMultiParty(Params memory params) public nonReentrant() returns (address) {
        // Create a new synthetic token using the params.
        require(bytes(params.syntheticName).length != 0, "Missing synthetic name");
        require(bytes(params.syntheticSymbol).length != 0, "Missing synthetic symbol");
        TokenFactory tf = TokenFactory(tokenFactoryAddress);

        // If the collateral token does not have a `decimals()` method, then a default precision of 18 will be
        // applied to the newly created synthetic token.
        uint8 syntheticDecimals = _getSyntheticDecimals(params.collateralAddress);
        ExpandedIERC20 tokenCurrency = tf.createToken(params.syntheticName, params.syntheticSymbol, syntheticDecimals);
        address derivative = ExpiringMultiPartyLib.deploy(_convertParams(params, tokenCurrency));

        // Give permissions to new derivative contract and then hand over ownership.
        tokenCurrency.addMinter(derivative);
        tokenCurrency.addBurner(derivative);
        tokenCurrency.resetOwner(derivative);

        _registerContract(new address[](0), derivative);

        emit CreatedExpiringMultiParty(derivative, msg.sender);

        return derivative;
    }

    /****************************************
     *          PRIVATE FUNCTIONS           *
     ****************************************/

    // Converts createExpiringMultiParty params to ExpiringMultiParty constructor params.
    function _convertParams(Params memory params, ExpandedIERC20 newTokenCurrency)
        private
        view
        returns (ExpiringMultiParty.ConstructorParams memory constructorParams)
    {
        // Known from creator deployment.
        constructorParams.finderAddress = finderAddress;
        constructorParams.timerAddress = timerAddress;

        // Enforce configuration constraints.
        require(params.withdrawalLiveness != 0, "Withdrawal liveness cannot be 0");
        require(params.liquidationLiveness != 0, "Liquidation liveness cannot be 0");
        require(params.expirationTimestamp > now, "Invalid expiration time");
        _requireWhitelistedCollateral(params.collateralAddress);

        // We don't want EMP deployers to be able to intentionally or unintentionally set
        // liveness periods that could induce arithmetic overflow, but we also don't want
        // to be opinionated about what livenesses are "correct", so we will somewhat
        // arbitrarily set the liveness upper bound to 100 years (5200 weeks). In practice, liveness
        // periods even greater than a few days would make the EMP unusable for most users.
        require(params.withdrawalLiveness < 5200 weeks, "Withdrawal liveness too large");
        require(params.liquidationLiveness < 5200 weeks, "Liquidation liveness too large");

        // Input from function call.
        constructorParams.tokenAddress = address(newTokenCurrency);
        constructorParams.expirationTimestamp = params.expirationTimestamp;
        constructorParams.collateralAddress = params.collateralAddress;
        constructorParams.priceFeedIdentifier = params.priceFeedIdentifier;
        constructorParams.collateralRequirement = params.collateralRequirement;
        constructorParams.disputeBondPercentage = params.disputeBondPercentage;
        constructorParams.sponsorDisputeRewardPercentage = params.sponsorDisputeRewardPercentage;
        constructorParams.disputerDisputeRewardPercentage = params.disputerDisputeRewardPercentage;
        constructorParams.minSponsorTokens = params.minSponsorTokens;
        constructorParams.withdrawalLiveness = params.withdrawalLiveness;
        constructorParams.liquidationLiveness = params.liquidationLiveness;
        constructorParams.financialProductLibraryAddress = params.financialProductLibraryAddress;
    }

    // IERC20Standard.decimals() will revert if the collateral contract has not implemented the decimals() method,
    // which is possible since the method is only an OPTIONAL method in the ERC20 standard:
    // https://eips.ethereum.org/EIPS/eip-20#methods.
    function _getSyntheticDecimals(address _collateralAddress) public view returns (uint8 decimals) {
        try IERC20Standard(_collateralAddress).decimals() returns (uint8 _decimals) {
            return _decimals;
        } catch {
            return 18;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ExpiringMultiParty.sol";

/**
 * @title Provides convenient Expiring Multi Party contract utilities.
 * @dev Using this library to deploy EMP's allows calling contracts to avoid importing the full EMP bytecode.
 */
library ExpiringMultiPartyLib {
    /**
     * @notice Returns address of new EMP deployed with given `params` configuration.
     * @dev Caller will need to register new EMP with the Registry to begin requesting prices. Caller is also
     * responsible for enforcing constraints on `params`.
     * @param params is a `ConstructorParams` object from ExpiringMultiParty.
     * @return address of the deployed ExpiringMultiParty contract
     */
    function deploy(ExpiringMultiParty.ConstructorParams memory params) public returns (address) {
        ExpiringMultiParty derivative = new ExpiringMultiParty(params);
        return address(derivative);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Liquidatable.sol";

/**
 * @title Expiring Multi Party.
 * @notice Convenient wrapper for Liquidatable.
 */
contract ExpiringMultiParty is Liquidatable {
    /**
     * @notice Constructs the ExpiringMultiParty contract.
     * @param params struct to define input parameters for construction of Liquidatable. Some params
     * are fed directly into the PricelessPositionManager's constructor within the inheritance tree.
     */
    constructor(ConstructorParams memory params)
        public
        Liquidatable(params)
    // Note: since there is no logic here, there is no need to add a re-entrancy guard.
    {

    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./PricelessPositionManager.sol";

import "../../common/implementation/FixedPoint.sol";

/**
 * @title Liquidatable
 * @notice Adds logic to a position-managing contract that enables callers to liquidate an undercollateralized position.
 * @dev The liquidation has a liveness period before expiring successfully, during which someone can "dispute" the
 * liquidation, which sends a price request to the relevant Oracle to settle the final collateralization ratio based on
 * a DVM price. The contract enforces dispute rewards in order to incentivize disputers to correctly dispute false
 * liquidations and compensate position sponsors who had their position incorrectly liquidated. Importantly, a
 * prospective disputer must deposit a dispute bond that they can lose in the case of an unsuccessful dispute.
 * NOTE: this contract does _not_ work with ERC777 collateral currencies or any others that call into the receiver on
 * transfer(). Using an ERC777 token would allow a user to maliciously grief other participants (while also losing
 * money themselves).
 */
contract Liquidatable is PricelessPositionManager {
    using FixedPoint for FixedPoint.Unsigned;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    /****************************************
     *     LIQUIDATION DATA STRUCTURES      *
     ****************************************/

    // Because of the check in withdrawable(), the order of these enum values should not change.
    enum Status { Uninitialized, NotDisputed, Disputed, DisputeSucceeded, DisputeFailed }

    struct LiquidationData {
        // Following variables set upon creation of liquidation:
        address sponsor; // Address of the liquidated position's sponsor
        address liquidator; // Address who created this liquidation
        Status state; // Liquidated (and expired or not), Pending a Dispute, or Dispute has resolved
        uint256 liquidationTime; // Time when liquidation is initiated, needed to get price from Oracle
        // Following variables determined by the position that is being liquidated:
        FixedPoint.Unsigned tokensOutstanding; // Synthetic tokens required to be burned by liquidator to initiate dispute
        FixedPoint.Unsigned lockedCollateral; // Collateral locked by contract and released upon expiry or post-dispute
        // Amount of collateral being liquidated, which could be different from
        // lockedCollateral if there were pending withdrawals at the time of liquidation
        FixedPoint.Unsigned liquidatedCollateral;
        // Unit value (starts at 1) that is used to track the fees per unit of collateral over the course of the liquidation.
        FixedPoint.Unsigned rawUnitCollateral;
        // Following variable set upon initiation of a dispute:
        address disputer; // Person who is disputing a liquidation
        // Following variable set upon a resolution of a dispute:
        FixedPoint.Unsigned settlementPrice; // Final price as determined by an Oracle following a dispute
        FixedPoint.Unsigned finalFee;
    }

    // Define the contract's constructor parameters as a struct to enable more variables to be specified.
    // This is required to enable more params, over and above Solidity's limits.
    struct ConstructorParams {
        // Params for PricelessPositionManager only.
        uint256 expirationTimestamp;
        uint256 withdrawalLiveness;
        address collateralAddress;
        address tokenAddress;
        address finderAddress;
        address timerAddress;
        address financialProductLibraryAddress;
        bytes32 priceFeedIdentifier;
        FixedPoint.Unsigned minSponsorTokens;
        // Params specifically for Liquidatable.
        uint256 liquidationLiveness;
        FixedPoint.Unsigned collateralRequirement;
        FixedPoint.Unsigned disputeBondPercentage;
        FixedPoint.Unsigned sponsorDisputeRewardPercentage;
        FixedPoint.Unsigned disputerDisputeRewardPercentage;
    }

    // This struct is used in the `withdrawLiquidation` method that disperses liquidation and dispute rewards.
    // `payToX` stores the total collateral to withdraw from the contract to pay X. This value might differ
    // from `paidToX` due to precision loss between accounting for the `rawCollateral` versus the
    // fee-adjusted collateral. These variables are stored within a struct to avoid the stack too deep error.
    struct RewardsData {
        FixedPoint.Unsigned payToSponsor;
        FixedPoint.Unsigned payToLiquidator;
        FixedPoint.Unsigned payToDisputer;
        FixedPoint.Unsigned paidToSponsor;
        FixedPoint.Unsigned paidToLiquidator;
        FixedPoint.Unsigned paidToDisputer;
    }

    // Liquidations are unique by ID per sponsor
    mapping(address => LiquidationData[]) public liquidations;

    // Total collateral in liquidation.
    FixedPoint.Unsigned public rawLiquidationCollateral;

    // Immutable contract parameters:
    // Amount of time for pending liquidation before expiry.
    // !!Note: The lower the liquidation liveness value, the more risk incurred by sponsors.
    //       Extremely low liveness values increase the chance that opportunistic invalid liquidations
    //       expire without dispute, thereby decreasing the usability for sponsors and increasing the risk
    //       for the contract as a whole. An insolvent contract is extremely risky for any sponsor or synthetic
    //       token holder for the contract.
    uint256 public liquidationLiveness;
    // Required collateral:TRV ratio for a position to be considered sufficiently collateralized.
    FixedPoint.Unsigned public collateralRequirement;
    // Percent of a Liquidation/Position's lockedCollateral to be deposited by a potential disputer
    // Represented as a multiplier, for example 1.5e18 = "150%" and 0.05e18 = "5%"
    FixedPoint.Unsigned public disputeBondPercentage;
    // Percent of oraclePrice paid to sponsor in the Disputed state (i.e. following a successful dispute)
    // Represented as a multiplier, see above.
    FixedPoint.Unsigned public sponsorDisputeRewardPercentage;
    // Percent of oraclePrice paid to disputer in the Disputed state (i.e. following a successful dispute)
    // Represented as a multiplier, see above.
    FixedPoint.Unsigned public disputerDisputeRewardPercentage;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event LiquidationCreated(
        address indexed sponsor,
        address indexed liquidator,
        uint256 indexed liquidationId,
        uint256 tokensOutstanding,
        uint256 lockedCollateral,
        uint256 liquidatedCollateral,
        uint256 liquidationTime
    );
    event LiquidationDisputed(
        address indexed sponsor,
        address indexed liquidator,
        address indexed disputer,
        uint256 liquidationId,
        uint256 disputeBondAmount
    );
    event DisputeSettled(
        address indexed caller,
        address indexed sponsor,
        address indexed liquidator,
        address disputer,
        uint256 liquidationId,
        bool disputeSucceeded
    );
    event LiquidationWithdrawn(
        address indexed caller,
        uint256 paidToLiquidator,
        uint256 paidToDisputer,
        uint256 paidToSponsor,
        Status indexed liquidationStatus,
        uint256 settlementPrice
    );

    /****************************************
     *              MODIFIERS               *
     ****************************************/

    modifier disputable(uint256 liquidationId, address sponsor) {
        _disputable(liquidationId, sponsor);
        _;
    }

    modifier withdrawable(uint256 liquidationId, address sponsor) {
        _withdrawable(liquidationId, sponsor);
        _;
    }

    /**
     * @notice Constructs the liquidatable contract.
     * @param params struct to define input parameters for construction of Liquidatable. Some params
     * are fed directly into the PricelessPositionManager's constructor within the inheritance tree.
     */
    constructor(ConstructorParams memory params)
        public
        PricelessPositionManager(
            params.expirationTimestamp,
            params.withdrawalLiveness,
            params.collateralAddress,
            params.tokenAddress,
            params.finderAddress,
            params.priceFeedIdentifier,
            params.minSponsorTokens,
            params.timerAddress,
            params.financialProductLibraryAddress
        )
        nonReentrant()
    {
        require(params.collateralRequirement.isGreaterThan(1));
        require(params.sponsorDisputeRewardPercentage.add(params.disputerDisputeRewardPercentage).isLessThan(1));

        // Set liquidatable specific variables.
        liquidationLiveness = params.liquidationLiveness;
        collateralRequirement = params.collateralRequirement;
        disputeBondPercentage = params.disputeBondPercentage;
        sponsorDisputeRewardPercentage = params.sponsorDisputeRewardPercentage;
        disputerDisputeRewardPercentage = params.disputerDisputeRewardPercentage;
    }

    /****************************************
     *        LIQUIDATION FUNCTIONS         *
     ****************************************/

    /**
     * @notice Liquidates the sponsor's position if the caller has enough
     * synthetic tokens to retire the position's outstanding tokens. Liquidations above
     * a minimum size also reset an ongoing "slow withdrawal"'s liveness.
     * @dev This method generates an ID that will uniquely identify liquidation for the sponsor. This contract must be
     * approved to spend at least `tokensLiquidated` of `tokenCurrency` and at least `finalFeeBond` of `collateralCurrency`.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @param sponsor address of the sponsor to liquidate.
     * @param minCollateralPerToken abort the liquidation if the position's collateral per token is below this value.
     * @param maxCollateralPerToken abort the liquidation if the position's collateral per token exceeds this value.
     * @param maxTokensToLiquidate max number of tokens to liquidate.
     * @param deadline abort the liquidation if the transaction is mined after this timestamp.
     * @return liquidationId ID of the newly created liquidation.
     * @return tokensLiquidated amount of synthetic tokens removed and liquidated from the `sponsor`'s position.
     * @return finalFeeBond amount of collateral to be posted by liquidator and returned if not disputed successfully.
     */
    function createLiquidation(
        address sponsor,
        FixedPoint.Unsigned calldata minCollateralPerToken,
        FixedPoint.Unsigned calldata maxCollateralPerToken,
        FixedPoint.Unsigned calldata maxTokensToLiquidate,
        uint256 deadline
    )
        external
        fees()
        onlyPreExpiration()
        nonReentrant()
        returns (
            uint256 liquidationId,
            FixedPoint.Unsigned memory tokensLiquidated,
            FixedPoint.Unsigned memory finalFeeBond
        )
    {
        // Check that this transaction was mined pre-deadline.
        require(getCurrentTime() <= deadline, "Mined after deadline");

        // Retrieve Position data for sponsor
        PositionData storage positionToLiquidate = _getPositionData(sponsor);

        tokensLiquidated = FixedPoint.min(maxTokensToLiquidate, positionToLiquidate.tokensOutstanding);
        require(tokensLiquidated.isGreaterThan(0));

        // Starting values for the Position being liquidated. If withdrawal request amount is > position's collateral,
        // then set this to 0, otherwise set it to (startCollateral - withdrawal request amount).
        FixedPoint.Unsigned memory startCollateral = _getFeeAdjustedCollateral(positionToLiquidate.rawCollateral);
        FixedPoint.Unsigned memory startCollateralNetOfWithdrawal = FixedPoint.fromUnscaledUint(0);
        if (positionToLiquidate.withdrawalRequestAmount.isLessThanOrEqual(startCollateral)) {
            startCollateralNetOfWithdrawal = startCollateral.sub(positionToLiquidate.withdrawalRequestAmount);
        }

        // Scoping to get rid of a stack too deep error.
        {
            FixedPoint.Unsigned memory startTokens = positionToLiquidate.tokensOutstanding;

            // The Position's collateralization ratio must be between [minCollateralPerToken, maxCollateralPerToken].
            // maxCollateralPerToken >= startCollateralNetOfWithdrawal / startTokens.
            require(
                maxCollateralPerToken.mul(startTokens).isGreaterThanOrEqual(startCollateralNetOfWithdrawal),
                "CR is more than max liq. price"
            );
            // minCollateralPerToken >= startCollateralNetOfWithdrawal / startTokens.
            require(
                minCollateralPerToken.mul(startTokens).isLessThanOrEqual(startCollateralNetOfWithdrawal),
                "CR is less than min liq. price"
            );
        }

        // Compute final fee at time of liquidation.
        finalFeeBond = _computeFinalFees();

        // These will be populated within the scope below.
        FixedPoint.Unsigned memory lockedCollateral;
        FixedPoint.Unsigned memory liquidatedCollateral;

        // Scoping to get rid of a stack too deep error.
        {
            FixedPoint.Unsigned memory ratio = tokensLiquidated.div(positionToLiquidate.tokensOutstanding);

            // The actual amount of collateral that gets moved to the liquidation.
            lockedCollateral = startCollateral.mul(ratio);

            // For purposes of disputes, it's actually this liquidatedCollateral value that's used. This value is net of
            // withdrawal requests.
            liquidatedCollateral = startCollateralNetOfWithdrawal.mul(ratio);

            // Part of the withdrawal request is also removed. Ideally:
            // liquidatedCollateral + withdrawalAmountToRemove = lockedCollateral.
            FixedPoint.Unsigned memory withdrawalAmountToRemove =
                positionToLiquidate.withdrawalRequestAmount.mul(ratio);
            _reduceSponsorPosition(sponsor, tokensLiquidated, lockedCollateral, withdrawalAmountToRemove);
        }

        // Add to the global liquidation collateral count.
        _addCollateral(rawLiquidationCollateral, lockedCollateral.add(finalFeeBond));

        // Construct liquidation object.
        // Note: All dispute-related values are zeroed out until a dispute occurs. liquidationId is the index of the new
        // LiquidationData that is pushed into the array, which is equal to the current length of the array pre-push.
        liquidationId = liquidations[sponsor].length;
        liquidations[sponsor].push(
            LiquidationData({
                sponsor: sponsor,
                liquidator: msg.sender,
                state: Status.NotDisputed,
                liquidationTime: getCurrentTime(),
                tokensOutstanding: tokensLiquidated,
                lockedCollateral: lockedCollateral,
                liquidatedCollateral: liquidatedCollateral,
                rawUnitCollateral: _convertToRawCollateral(FixedPoint.fromUnscaledUint(1)),
                disputer: address(0),
                settlementPrice: FixedPoint.fromUnscaledUint(0),
                finalFee: finalFeeBond
            })
        );

        // If this liquidation is a subsequent liquidation on the position, and the liquidation size is larger than
        // some "griefing threshold", then re-set the liveness. This enables a liquidation against a withdraw request to be
        // "dragged out" if the position is very large and liquidators need time to gather funds. The griefing threshold
        // is enforced so that liquidations for trivially small # of tokens cannot drag out an honest sponsor's slow withdrawal.

        // We arbitrarily set the "griefing threshold" to `minSponsorTokens` because it is the only parameter
        // denominated in token currency units and we can avoid adding another parameter.
        FixedPoint.Unsigned memory griefingThreshold = minSponsorTokens;
        if (
            positionToLiquidate.withdrawalRequestPassTimestamp > 0 && // The position is undergoing a slow withdrawal.
            positionToLiquidate.withdrawalRequestPassTimestamp > getCurrentTime() && // The slow withdrawal has not yet expired.
            tokensLiquidated.isGreaterThanOrEqual(griefingThreshold) // The liquidated token count is above a "griefing threshold".
        ) {
            positionToLiquidate.withdrawalRequestPassTimestamp = getCurrentTime().add(withdrawalLiveness);
        }

        emit LiquidationCreated(
            sponsor,
            msg.sender,
            liquidationId,
            tokensLiquidated.rawValue,
            lockedCollateral.rawValue,
            liquidatedCollateral.rawValue,
            getCurrentTime()
        );

        // Destroy tokens
        tokenCurrency.safeTransferFrom(msg.sender, address(this), tokensLiquidated.rawValue);
        tokenCurrency.burn(tokensLiquidated.rawValue);

        // Pull final fee from liquidator.
        collateralCurrency.safeTransferFrom(msg.sender, address(this), finalFeeBond.rawValue);
    }

    /**
     * @notice Disputes a liquidation, if the caller has enough collateral to post a dispute bond
     * and pay a fixed final fee charged on each price request.
     * @dev Can only dispute a liquidation before the liquidation expires and if there are no other pending disputes.
     * This contract must be approved to spend at least the dispute bond amount of `collateralCurrency`. This dispute
     * bond amount is calculated from `disputeBondPercentage` times the collateral in the liquidation.
     * @param liquidationId of the disputed liquidation.
     * @param sponsor the address of the sponsor whose liquidation is being disputed.
     * @return totalPaid amount of collateral charged to disputer (i.e. final fee bond + dispute bond).
     */
    function dispute(uint256 liquidationId, address sponsor)
        external
        disputable(liquidationId, sponsor)
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory totalPaid)
    {
        LiquidationData storage disputedLiquidation = _getLiquidationData(sponsor, liquidationId);

        // Multiply by the unit collateral so the dispute bond is a percentage of the locked collateral after fees.
        FixedPoint.Unsigned memory disputeBondAmount =
            disputedLiquidation.lockedCollateral.mul(disputeBondPercentage).mul(
                _getFeeAdjustedCollateral(disputedLiquidation.rawUnitCollateral)
            );
        _addCollateral(rawLiquidationCollateral, disputeBondAmount);

        // Request a price from DVM. Liquidation is pending dispute until DVM returns a price.
        disputedLiquidation.state = Status.Disputed;
        disputedLiquidation.disputer = msg.sender;

        // Enqueue a request with the DVM.
        _requestOraclePriceLiquidation(disputedLiquidation.liquidationTime);

        emit LiquidationDisputed(
            sponsor,
            disputedLiquidation.liquidator,
            msg.sender,
            liquidationId,
            disputeBondAmount.rawValue
        );
        totalPaid = disputeBondAmount.add(disputedLiquidation.finalFee);

        // Pay the final fee for requesting price from the DVM.
        _payFinalFees(msg.sender, disputedLiquidation.finalFee);

        // Transfer the dispute bond amount from the caller to this contract.
        collateralCurrency.safeTransferFrom(msg.sender, address(this), disputeBondAmount.rawValue);
    }

    /**
     * @notice After a dispute has settled or after a non-disputed liquidation has expired,
     * anyone can call this method to disperse payments to the sponsor, liquidator, and disdputer.
     * @dev If the dispute SUCCEEDED: the sponsor, liquidator, and disputer are eligible for payment.
     * If the dispute FAILED: only the liquidator can receive payment.
     * This method will revert if rewards have already been dispersed.
     * @param liquidationId uniquely identifies the sponsor's liquidation.
     * @param sponsor address of the sponsor associated with the liquidation.
     * @return data about rewards paid out.
     */
    function withdrawLiquidation(uint256 liquidationId, address sponsor)
        public
        withdrawable(liquidationId, sponsor)
        fees()
        nonReentrant()
        returns (RewardsData memory)
    {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);

        // Settles the liquidation if necessary. This call will revert if the price has not resolved yet.
        _settle(liquidationId, sponsor);

        // Calculate rewards as a function of the TRV.
        // Note: all payouts are scaled by the unit collateral value so all payouts are charged the fees pro rata.
        FixedPoint.Unsigned memory feeAttenuation = _getFeeAdjustedCollateral(liquidation.rawUnitCollateral);
        FixedPoint.Unsigned memory settlementPrice = liquidation.settlementPrice;
        FixedPoint.Unsigned memory tokenRedemptionValue =
            liquidation.tokensOutstanding.mul(settlementPrice).mul(feeAttenuation);
        FixedPoint.Unsigned memory collateral = liquidation.lockedCollateral.mul(feeAttenuation);
        FixedPoint.Unsigned memory disputerDisputeReward = disputerDisputeRewardPercentage.mul(tokenRedemptionValue);
        FixedPoint.Unsigned memory sponsorDisputeReward = sponsorDisputeRewardPercentage.mul(tokenRedemptionValue);
        FixedPoint.Unsigned memory disputeBondAmount = collateral.mul(disputeBondPercentage);
        FixedPoint.Unsigned memory finalFee = liquidation.finalFee.mul(feeAttenuation);

        // There are three main outcome states: either the dispute succeeded, failed or was not updated.
        // Based on the state, different parties of a liquidation receive different amounts.
        // After assigning rewards based on the liquidation status, decrease the total collateral held in this contract
        // by the amount to pay each party. The actual amounts withdrawn might differ if _removeCollateral causes
        // precision loss.
        RewardsData memory rewards;
        if (liquidation.state == Status.DisputeSucceeded) {
            // If the dispute is successful then all three users should receive rewards:

            // Pay DISPUTER: disputer reward + dispute bond + returned final fee
            rewards.payToDisputer = disputerDisputeReward.add(disputeBondAmount).add(finalFee);

            // Pay SPONSOR: remaining collateral (collateral - TRV) + sponsor reward
            rewards.payToSponsor = sponsorDisputeReward.add(collateral.sub(tokenRedemptionValue));

            // Pay LIQUIDATOR: TRV - dispute reward - sponsor reward
            // If TRV > Collateral, then subtract rewards from collateral
            // NOTE: This should never be below zero since we prevent (sponsorDisputePct+disputerDisputePct) >= 0 in
            // the constructor when these params are set.
            rewards.payToLiquidator = tokenRedemptionValue.sub(sponsorDisputeReward).sub(disputerDisputeReward);

            // Transfer rewards and debit collateral
            rewards.paidToLiquidator = _removeCollateral(rawLiquidationCollateral, rewards.payToLiquidator);
            rewards.paidToSponsor = _removeCollateral(rawLiquidationCollateral, rewards.payToSponsor);
            rewards.paidToDisputer = _removeCollateral(rawLiquidationCollateral, rewards.payToDisputer);

            collateralCurrency.safeTransfer(liquidation.disputer, rewards.paidToDisputer.rawValue);
            collateralCurrency.safeTransfer(liquidation.liquidator, rewards.paidToLiquidator.rawValue);
            collateralCurrency.safeTransfer(liquidation.sponsor, rewards.paidToSponsor.rawValue);

            // In the case of a failed dispute only the liquidator can withdraw.
        } else if (liquidation.state == Status.DisputeFailed) {
            // Pay LIQUIDATOR: collateral + dispute bond + returned final fee
            rewards.payToLiquidator = collateral.add(disputeBondAmount).add(finalFee);

            // Transfer rewards and debit collateral
            rewards.paidToLiquidator = _removeCollateral(rawLiquidationCollateral, rewards.payToLiquidator);

            collateralCurrency.safeTransfer(liquidation.liquidator, rewards.paidToLiquidator.rawValue);

            // If the state is pre-dispute but time has passed liveness then there was no dispute. We represent this
            // state as a dispute failed and the liquidator can withdraw.
        } else if (liquidation.state == Status.NotDisputed) {
            // Pay LIQUIDATOR: collateral + returned final fee
            rewards.payToLiquidator = collateral.add(finalFee);

            // Transfer rewards and debit collateral
            rewards.paidToLiquidator = _removeCollateral(rawLiquidationCollateral, rewards.payToLiquidator);

            collateralCurrency.safeTransfer(liquidation.liquidator, rewards.paidToLiquidator.rawValue);
        }

        emit LiquidationWithdrawn(
            msg.sender,
            rewards.paidToLiquidator.rawValue,
            rewards.paidToDisputer.rawValue,
            rewards.paidToSponsor.rawValue,
            liquidation.state,
            settlementPrice.rawValue
        );

        // Free up space after collateral is withdrawn by removing the liquidation object from the array.
        delete liquidations[sponsor][liquidationId];

        return rewards;
    }

    /**
     * @notice Gets all liquidation information for a given sponsor address.
     * @param sponsor address of the position sponsor.
     * @return liquidationData array of all liquidation information for the given sponsor address.
     */
    function getLiquidations(address sponsor)
        external
        view
        nonReentrantView()
        returns (LiquidationData[] memory liquidationData)
    {
        return liquidations[sponsor];
    }

    /**
     * @notice Accessor method to calculate a transformed collateral requirement using the finanical product library
      specified during contract deployment. If no library was provided then no modification to the collateral requirement is done.
     * @param price input price used as an input to transform the collateral requirement.
     * @return transformedCollateralRequirement collateral requirement with transformation applied to it.
     * @dev This method should never revert.
     */
    function transformCollateralRequirement(FixedPoint.Unsigned memory price)
        public
        view
        nonReentrantView()
        returns (FixedPoint.Unsigned memory)
    {
        return _transformCollateralRequirement(price);
    }

    /****************************************
     *          INTERNAL FUNCTIONS          *
     ****************************************/

    // This settles a liquidation if it is in the Disputed state. If not, it will immediately return.
    // If the liquidation is in the Disputed state, but a price is not available, this will revert.
    function _settle(uint256 liquidationId, address sponsor) internal {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);

        // Settlement only happens when state == Disputed and will only happen once per liquidation.
        // If this liquidation is not ready to be settled, this method should return immediately.
        if (liquidation.state != Status.Disputed) {
            return;
        }

        // Get the returned price from the oracle. If this has not yet resolved will revert.
        liquidation.settlementPrice = _getOraclePriceLiquidation(liquidation.liquidationTime);

        // Find the value of the tokens in the underlying collateral.
        FixedPoint.Unsigned memory tokenRedemptionValue =
            liquidation.tokensOutstanding.mul(liquidation.settlementPrice);

        // The required collateral is the value of the tokens in underlying * required collateral ratio. The Transform
        // Collateral requirement method applies a from the financial Product library to change the scaled the collateral
        // requirement based on the settlement price. If no library was specified when deploying the emp then this makes no change.
        FixedPoint.Unsigned memory requiredCollateral =
            tokenRedemptionValue.mul(_transformCollateralRequirement(liquidation.settlementPrice));

        // If the position has more than the required collateral it is solvent and the dispute is valid(liquidation is invalid)
        // Note that this check uses the liquidatedCollateral not the lockedCollateral as this considers withdrawals.
        bool disputeSucceeded = liquidation.liquidatedCollateral.isGreaterThanOrEqual(requiredCollateral);
        liquidation.state = disputeSucceeded ? Status.DisputeSucceeded : Status.DisputeFailed;

        emit DisputeSettled(
            msg.sender,
            sponsor,
            liquidation.liquidator,
            liquidation.disputer,
            liquidationId,
            disputeSucceeded
        );
    }

    function _pfc() internal view override returns (FixedPoint.Unsigned memory) {
        return super._pfc().add(_getFeeAdjustedCollateral(rawLiquidationCollateral));
    }

    function _getLiquidationData(address sponsor, uint256 liquidationId)
        internal
        view
        returns (LiquidationData storage liquidation)
    {
        LiquidationData[] storage liquidationArray = liquidations[sponsor];

        // Revert if the caller is attempting to access an invalid liquidation
        // (one that has never been created or one has never been initialized).
        require(
            liquidationId < liquidationArray.length && liquidationArray[liquidationId].state != Status.Uninitialized,
            "Invalid liquidation ID"
        );
        return liquidationArray[liquidationId];
    }

    function _getLiquidationExpiry(LiquidationData storage liquidation) internal view returns (uint256) {
        return liquidation.liquidationTime.add(liquidationLiveness);
    }

    // These internal functions are supposed to act identically to modifiers, but re-used modifiers
    // unnecessarily increase contract bytecode size.
    // source: https://blog.polymath.network/solidity-tips-and-tricks-to-save-gas-and-reduce-bytecode-size-c44580b218e6
    function _disputable(uint256 liquidationId, address sponsor) internal view {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);
        require(
            (getCurrentTime() < _getLiquidationExpiry(liquidation)) && (liquidation.state == Status.NotDisputed),
            "Liquidation not disputable"
        );
    }

    function _withdrawable(uint256 liquidationId, address sponsor) internal view {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);
        Status state = liquidation.state;

        // Must be disputed or the liquidation has passed expiry.
        require(
            (state > Status.NotDisputed) ||
                ((_getLiquidationExpiry(liquidation) <= getCurrentTime()) && (state == Status.NotDisputed)),
            "Liquidation not withdrawable"
        );
    }

    function _transformCollateralRequirement(FixedPoint.Unsigned memory price)
        internal
        view
        returns (FixedPoint.Unsigned memory)
    {
        if (!address(financialProductLibrary).isContract()) return collateralRequirement;
        try financialProductLibrary.transformCollateralRequirement(price, collateralRequirement) returns (
            FixedPoint.Unsigned memory transformedCollateralRequirement
        ) {
            return transformedCollateralRequirement;
        } catch {
            return collateralRequirement;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../common/FundingRateApplier.sol";
import "../../common/implementation/FixedPoint.sol";

// Implements FundingRateApplier internal methods to enable unit testing.
contract FundingRateApplierTest is FundingRateApplier {
    constructor(
        bytes32 _fundingRateIdentifier,
        address _collateralAddress,
        address _finderAddress,
        address _configStoreAddress,
        FixedPoint.Unsigned memory _tokenScaling,
        address _timerAddress
    )
        public
        FundingRateApplier(
            _fundingRateIdentifier,
            _collateralAddress,
            _finderAddress,
            _configStoreAddress,
            _tokenScaling,
            _timerAddress
        )
    {}

    function calculateEffectiveFundingRate(
        uint256 paymentPeriodSeconds,
        FixedPoint.Signed memory fundingRatePerSecond,
        FixedPoint.Unsigned memory currentCumulativeFundingRateMultiplier
    ) public pure returns (FixedPoint.Unsigned memory) {
        return
            _calculateEffectiveFundingRate(
                paymentPeriodSeconds,
                fundingRatePerSecond,
                currentCumulativeFundingRateMultiplier
            );
    }

    // Required overrides.
    function _pfc() internal view virtual override returns (FixedPoint.Unsigned memory currentPfc) {
        return FixedPoint.Unsigned(collateralCurrency.balanceOf(address(this)));
    }

    function emergencyShutdown() external override {}

    function remargin() external override {}

    function _getTokenAddress() internal view override returns (address) {
        return address(collateralCurrency);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../../common/implementation/FixedPoint.sol";
import "../../common/interfaces/ExpandedIERC20.sol";
import "./VotingToken.sol";

/**
 * @title Migration contract for VotingTokens.
 * @dev Handles migrating token holders from one token to the next.
 */
contract TokenMigrator {
    using FixedPoint for FixedPoint.Unsigned;

    /****************************************
     *    INTERNAL VARIABLES AND STORAGE    *
     ****************************************/

    VotingToken public oldToken;
    ExpandedIERC20 public newToken;

    uint256 public snapshotId;
    FixedPoint.Unsigned public rate;

    mapping(address => bool) public hasMigrated;

    /**
     * @notice Construct the TokenMigrator contract.
     * @dev This function triggers the snapshot upon which all migrations will be based.
     * @param _rate the number of old tokens it takes to generate one new token.
     * @param _oldToken address of the token being migrated from.
     * @param _newToken address of the token being migrated to.
     */
    constructor(
        FixedPoint.Unsigned memory _rate,
        address _oldToken,
        address _newToken
    ) public {
        // Prevents division by 0 in migrateTokens().
        // Also it doesn’t make sense to have “0 old tokens equate to 1 new token”.
        require(_rate.isGreaterThan(0), "Rate can't be 0");
        rate = _rate;
        newToken = ExpandedIERC20(_newToken);
        oldToken = VotingToken(_oldToken);
        snapshotId = oldToken.snapshot();
    }

    /**
     * @notice Migrates the tokenHolder's old tokens to new tokens.
     * @dev This function can only be called once per `tokenHolder`. Anyone can call this method
     * on behalf of any other token holder since there is no disadvantage to receiving the tokens earlier.
     * @param tokenHolder address of the token holder to migrate.
     */
    function migrateTokens(address tokenHolder) external {
        require(!hasMigrated[tokenHolder], "Already migrated tokens");
        hasMigrated[tokenHolder] = true;

        FixedPoint.Unsigned memory oldBalance = FixedPoint.Unsigned(oldToken.balanceOfAt(tokenHolder, snapshotId));

        if (!oldBalance.isGreaterThan(0)) {
            return;
        }

        FixedPoint.Unsigned memory newBalance = oldBalance.div(rate);
        require(newToken.mint(tokenHolder, newBalance.rawValue), "Mint failed");
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "./FinancialProductLibrary.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../../common/implementation/Lockable.sol";

/**
 * @title Structured Note Financial Product Library
 * @notice Adds custom price transformation logic to modify the behavior of the expiring multi party contract.  The
 * contract holds say 1 WETH in collateral and pays out that 1 WETH if, at expiry, ETHUSD is below a set strike. If
 * ETHUSD is above that strike, the contract pays out a given dollar amount of ETH.
 * Example: expiry is DEC 31. Strike is $400. Each token is backed by 1 WETH
 * If ETHUSD < $400 at expiry, token is redeemed for 1 ETH.
 * If ETHUSD >= $400 at expiry, token is redeemed for $400 worth of ETH, as determined by the DVM.
 */
contract StructuredNoteFinancialProductLibrary is FinancialProductLibrary, Ownable, Lockable {
    mapping(address => FixedPoint.Unsigned) financialProductStrikes;

    /**
     * @notice Enables the deployer of the library to set the strike price for an associated financial product.
     * @param financialProduct address of the financial product.
     * @param strikePrice the strike price for the structured note to be applied to the financial product.
     * @dev Note: a) Only the owner (deployer) of this library can set new strike prices b) A strike price cannot be 0.
     * c) A strike price can only be set once to prevent the deployer from changing the strike after the fact.
     * d)  financialProduct must exposes an expirationTimestamp method.
     */
    function setFinancialProductStrike(address financialProduct, FixedPoint.Unsigned memory strikePrice)
        public
        onlyOwner
        nonReentrant()
    {
        require(strikePrice.isGreaterThan(0), "Cant set 0 strike");
        require(financialProductStrikes[financialProduct].isEqual(0), "Strike already set");
        require(ExpiringContractInterface(financialProduct).expirationTimestamp() != 0, "Invalid EMP contract");
        financialProductStrikes[financialProduct] = strikePrice;
    }

    /**
     * @notice Returns the strike price associated with a given financial product address.
     * @param financialProduct address of the financial product.
     * @return strikePrice for the associated financial product.
     */
    function getStrikeForFinancialProduct(address financialProduct)
        public
        view
        nonReentrantView()
        returns (FixedPoint.Unsigned memory)
    {
        return financialProductStrikes[financialProduct];
    }

    /**
     * @notice Returns a transformed price by applying the structured note payout structure.
     * @param oraclePrice price from the oracle to be transformed.
     * @param requestTime timestamp the oraclePrice was requested at.
     * @return transformedPrice the input oracle price with the price transformation logic applied to it.
     */
    function transformPrice(FixedPoint.Unsigned memory oraclePrice, uint256 requestTime)
        public
        view
        override
        nonReentrantView()
        returns (FixedPoint.Unsigned memory)
    {
        FixedPoint.Unsigned memory strike = financialProductStrikes[msg.sender];
        require(strike.isGreaterThan(0), "Caller has no strike");
        // If price request is made before expiry, return 1. Thus we can keep the contract 100% collateralized with
        // each token backed 1:1 by collateral currency.
        if (requestTime < ExpiringContractInterface(msg.sender).expirationTimestamp()) {
            return FixedPoint.fromUnscaledUint(1);
        }
        if (oraclePrice.isLessThan(strike)) {
            return FixedPoint.fromUnscaledUint(1);
        } else {
            // Token expires to be worth strike $ worth of collateral.
            // eg if ETHUSD is $500 and strike is $400, token is redeemable for 400/500 = 0.8 WETH.
            return strike.div(oraclePrice);
        }
    }

    /**
     * @notice Returns a transformed collateral requirement by applying the structured note payout structure. If the price
     * of the structured note is greater than the strike then the collateral requirement scales down accordingly.
     * @param oraclePrice price from the oracle to transform the collateral requirement.
     * @param collateralRequirement financial products collateral requirement to be scaled according to price and strike.
     * @return transformedCollateralRequirement the input collateral requirement with the transformation logic applied to it.
     */
    function transformCollateralRequirement(
        FixedPoint.Unsigned memory oraclePrice,
        FixedPoint.Unsigned memory collateralRequirement
    ) public view override nonReentrantView() returns (FixedPoint.Unsigned memory) {
        FixedPoint.Unsigned memory strike = financialProductStrikes[msg.sender];
        require(strike.isGreaterThan(0), "Caller has no strike");
        // If the price is less than the strike than the original collateral requirement is used.
        if (oraclePrice.isLessThan(strike)) {
            return collateralRequirement;
        } else {
            // If the price is more than the strike then the collateral requirement is scaled by the strike. For example
            // a strike of $400 and a CR of 1.2 would yield:
            // ETHUSD = $350, payout is 1 WETH. CR is multiplied by 1. resulting CR = 1.2
            // ETHUSD = $400, payout is 1 WETH. CR is multiplied by 1. resulting CR = 1.2
            // ETHUSD = $425, payout is 0.941 WETH (worth $400). CR is multiplied by 0.941. resulting CR = 1.1292
            // ETHUSD = $500, payout is 0.8 WETH (worth $400). CR multiplied by 0.8. resulting CR = 0.96
            return collateralRequirement.mul(strike.div(oraclePrice));
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "./FinancialProductLibrary.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../../common/implementation/Lockable.sol";

/**
 * @title Pre-Expiration Identifier Transformation Financial Product Library
 * @notice Adds custom identifier transformation to enable a financial contract to use two different identifiers, depending
 * on when a price request is made. If the request is made before expiration then a transformation is made to the identifier
 * & if it is at or after expiration then the original identifier is returned. This library enables self referential
 * TWAP identifier to be used on synthetics pre-expiration, in conjunction with a separate identifier at expiration.
 */
contract PreExpirationIdentifierTransformationFinancialProductLibrary is FinancialProductLibrary, Ownable, Lockable {
    mapping(address => bytes32) financialProductTransformedIdentifiers;

    /**
     * @notice Enables the deployer of the library to set the transformed identifier for an associated financial product.
     * @param financialProduct address of the financial product.
     * @param transformedIdentifier the identifier for the financial product to be used if the contract is post expiration.
     * @dev Note: a) Only the owner (deployer) of this library can set identifier transformations b) The identifier can't
     * be set to blank. c) A transformed price can only be set once to prevent the deployer from changing it after the fact.
     * d)  financialProduct must expose an expirationTimestamp method.
     */
    function setFinancialProductTransformedIdentifier(address financialProduct, bytes32 transformedIdentifier)
        public
        onlyOwner
        nonReentrant()
    {
        require(transformedIdentifier != "", "Cant set to empty transformation");
        require(financialProductTransformedIdentifiers[financialProduct] == "", "Transformation already set");
        require(ExpiringContractInterface(financialProduct).expirationTimestamp() != 0, "Invalid EMP contract");
        financialProductTransformedIdentifiers[financialProduct] = transformedIdentifier;
    }

    /**
     * @notice Returns the transformed identifier associated with a given financial product address.
     * @param financialProduct address of the financial product.
     * @return transformed identifier for the associated financial product.
     */
    function getTransformedIdentifierForFinancialProduct(address financialProduct)
        public
        view
        nonReentrantView()
        returns (bytes32)
    {
        return financialProductTransformedIdentifiers[financialProduct];
    }

    /**
     * @notice Returns a transformed price identifier if the contract is pre-expiration and no transformation if post.
     * @param identifier input price identifier to be transformed.
     * @param requestTime timestamp the identifier is to be used at.
     * @return transformedPriceIdentifier the input price identifier with the transformation logic applied to it.
     */
    function transformPriceIdentifier(bytes32 identifier, uint256 requestTime)
        public
        view
        override
        nonReentrantView()
        returns (bytes32)
    {
        require(financialProductTransformedIdentifiers[msg.sender] != "", "Caller has no transformation");
        // If the request time is before contract expiration then return the transformed identifier. Else, return the
        // original price identifier.
        if (requestTime < ExpiringContractInterface(msg.sender).expirationTimestamp()) {
            return financialProductTransformedIdentifiers[msg.sender];
        } else {
            return identifier;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../implementation/Lockable.sol";
import "./ReentrancyAttack.sol";

// Tests reentrancy guards defined in Lockable.sol.
// Extends https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/mocks/ReentrancyMock.sol.
contract ReentrancyMock is Lockable {
    uint256 public counter;

    constructor() public {
        counter = 0;
    }

    function callback() external nonReentrant {
        _count();
    }

    function countAndSend(ReentrancyAttack attacker) external nonReentrant {
        _count();
        bytes4 func = bytes4(keccak256("callback()"));
        attacker.callSender(func);
    }

    function countAndCall(ReentrancyAttack attacker) external nonReentrant {
        _count();
        bytes4 func = bytes4(keccak256("getCount()"));
        attacker.callSender(func);
    }

    function countLocalRecursive(uint256 n) public nonReentrant {
        if (n > 0) {
            _count();
            countLocalRecursive(n - 1);
        }
    }

    function countThisRecursive(uint256 n) public nonReentrant {
        if (n > 0) {
            _count();
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = address(this).call(abi.encodeWithSignature("countThisRecursive(uint256)", n - 1));
            require(success, "ReentrancyMock: failed call");
        }
    }

    function countLocalCall() public nonReentrant {
        getCount();
    }

    function countThisCall() public nonReentrant {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = address(this).call(abi.encodeWithSignature("getCount()"));
        require(success, "ReentrancyMock: failed call");
    }

    function getCount() public view nonReentrantView returns (uint256) {
        return counter;
    }

    function _count() private {
        counter += 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

// Tests reentrancy guards defined in Lockable.sol.
// Copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/mocks/ReentrancyAttack.sol.
contract ReentrancyAttack {
    function callSender(bytes4 data) public {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = msg.sender.call(abi.encodeWithSelector(data));
        require(success, "ReentrancyAttack: failed call");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../../interfaces/VotingInterface.sol";
import "../VoteTiming.sol";

// Wraps the library VoteTiming for testing purposes.
contract VoteTimingTest {
    using VoteTiming for VoteTiming.Data;

    VoteTiming.Data public voteTiming;

    constructor(uint256 phaseLength) public {
        wrapInit(phaseLength);
    }

    function wrapComputeCurrentRoundId(uint256 currentTime) external view returns (uint256) {
        return voteTiming.computeCurrentRoundId(currentTime);
    }

    function wrapComputeCurrentPhase(uint256 currentTime) external view returns (VotingAncillaryInterface.Phase) {
        return voteTiming.computeCurrentPhase(currentTime);
    }

    function wrapInit(uint256 phaseLength) public {
        voteTiming.init(phaseLength);
    }
}

/*
  MultiRoleTest contract.
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../implementation/MultiRole.sol";

// The purpose of this contract is to make the MultiRole creation methods externally callable for testing purposes.
contract MultiRoleTest is MultiRole {
    function createSharedRole(
        uint256 roleId,
        uint256 managingRoleId,
        address[] calldata initialMembers
    ) external {
        _createSharedRole(roleId, managingRoleId, initialMembers);
    }

    function createExclusiveRole(
        uint256 roleId,
        uint256 managingRoleId,
        address initialMember
    ) external {
        _createExclusiveRole(roleId, managingRoleId, initialMember);
    }

    // solhint-disable-next-line no-empty-blocks
    function revertIfNotHoldingRole(uint256 roleId) external view onlyRoleHolder(roleId) {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../implementation/Testable.sol";

// TestableTest is derived from the abstract contract Testable for testing purposes.
contract TestableTest is Testable {
    // solhint-disable-next-line no-empty-blocks
    constructor(address _timerAddress) public Testable(_timerAddress) {}

    function getTestableTimeAndBlockTime() external view returns (uint256 testableTime, uint256 blockTime) {
        // solhint-disable-next-line not-rely-on-time
        return (getCurrentTime(), now);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../ResultComputation.sol";
import "../../../common/implementation/FixedPoint.sol";

// Wraps the library ResultComputation for testing purposes.
contract ResultComputationTest {
    using ResultComputation for ResultComputation.Data;

    ResultComputation.Data public data;

    function wrapAddVote(int256 votePrice, uint256 numberTokens) external {
        data.addVote(votePrice, FixedPoint.Unsigned(numberTokens));
    }

    function wrapGetResolvedPrice(uint256 minVoteThreshold) external view returns (bool isResolved, int256 price) {
        return data.getResolvedPrice(FixedPoint.Unsigned(minVoteThreshold));
    }

    function wrapWasVoteCorrect(bytes32 revealHash) external view returns (bool) {
        return data.wasVoteCorrect(revealHash);
    }

    function wrapGetTotalCorrectlyVotedTokens() external view returns (uint256) {
        return data.getTotalCorrectlyVotedTokens().rawValue;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../Voting.sol";
import "../../../common/implementation/FixedPoint.sol";

// Test contract used to access internal variables in the Voting contract.
contract VotingTest is Voting {
    constructor(
        uint256 _phaseLength,
        FixedPoint.Unsigned memory _gatPercentage,
        FixedPoint.Unsigned memory _inflationRate,
        uint256 _rewardsExpirationTimeout,
        address _votingToken,
        address _finder,
        address _timerAddress
    )
        public
        Voting(
            _phaseLength,
            _gatPercentage,
            _inflationRate,
            _rewardsExpirationTimeout,
            _votingToken,
            _finder,
            _timerAddress
        )
    {}

    function getPendingPriceRequestsArray() external view returns (bytes32[] memory) {
        return pendingPriceRequests;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../implementation/FixedPoint.sol";

// Wraps the FixedPoint library for testing purposes.
contract UnsignedFixedPointTest {
    using FixedPoint for FixedPoint.Unsigned;
    using FixedPoint for uint256;
    using SafeMath for uint256;

    function wrapFromUnscaledUint(uint256 a) external pure returns (uint256) {
        return FixedPoint.fromUnscaledUint(a).rawValue;
    }

    function wrapIsEqual(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isEqual(FixedPoint.Unsigned(b));
    }

    function wrapMixedIsEqual(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isEqual(b);
    }

    function wrapIsGreaterThan(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isGreaterThan(FixedPoint.Unsigned(b));
    }

    function wrapIsGreaterThanOrEqual(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isGreaterThanOrEqual(FixedPoint.Unsigned(b));
    }

    function wrapMixedIsGreaterThan(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isGreaterThan(b);
    }

    function wrapMixedIsGreaterThanOrEqual(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isGreaterThanOrEqual(b);
    }

    function wrapMixedIsGreaterThanOpposite(uint256 a, uint256 b) external pure returns (bool) {
        return a.isGreaterThan(FixedPoint.Unsigned(b));
    }

    function wrapMixedIsGreaterThanOrEqualOpposite(uint256 a, uint256 b) external pure returns (bool) {
        return a.isGreaterThanOrEqual(FixedPoint.Unsigned(b));
    }

    function wrapIsLessThan(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isLessThan(FixedPoint.Unsigned(b));
    }

    function wrapIsLessThanOrEqual(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isLessThanOrEqual(FixedPoint.Unsigned(b));
    }

    function wrapMixedIsLessThan(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isLessThan(b);
    }

    function wrapMixedIsLessThanOrEqual(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isLessThanOrEqual(b);
    }

    function wrapMixedIsLessThanOpposite(uint256 a, uint256 b) external pure returns (bool) {
        return a.isLessThan(FixedPoint.Unsigned(b));
    }

    function wrapMixedIsLessThanOrEqualOpposite(uint256 a, uint256 b) external pure returns (bool) {
        return a.isLessThanOrEqual(FixedPoint.Unsigned(b));
    }

    function wrapMin(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).min(FixedPoint.Unsigned(b)).rawValue;
    }

    function wrapMax(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).max(FixedPoint.Unsigned(b)).rawValue;
    }

    function wrapAdd(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).add(FixedPoint.Unsigned(b)).rawValue;
    }

    // The first uint256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedAdd(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).add(b).rawValue;
    }

    function wrapSub(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).sub(FixedPoint.Unsigned(b)).rawValue;
    }

    // The first uint256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedSub(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).sub(b).rawValue;
    }

    // The second uint256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedSubOpposite(uint256 a, uint256 b) external pure returns (uint256) {
        return a.sub(FixedPoint.Unsigned(b)).rawValue;
    }

    function wrapMul(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).mul(FixedPoint.Unsigned(b)).rawValue;
    }

    function wrapMulCeil(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).mulCeil(FixedPoint.Unsigned(b)).rawValue;
    }

    // The first uint256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedMul(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).mul(b).rawValue;
    }

    function wrapMixedMulCeil(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).mulCeil(b).rawValue;
    }

    function wrapDiv(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).div(FixedPoint.Unsigned(b)).rawValue;
    }

    function wrapDivCeil(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).divCeil(FixedPoint.Unsigned(b)).rawValue;
    }

    // The first uint256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedDiv(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).div(b).rawValue;
    }

    function wrapMixedDivCeil(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).divCeil(b).rawValue;
    }

    // The second uint256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedDivOpposite(uint256 a, uint256 b) external pure returns (uint256) {
        return a.div(FixedPoint.Unsigned(b)).rawValue;
    }

    // The first uint256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapPow(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).pow(b).rawValue;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../implementation/FixedPoint.sol";

// Wraps the FixedPoint library for testing purposes.
contract SignedFixedPointTest {
    using FixedPoint for FixedPoint.Signed;
    using FixedPoint for int256;
    using SafeMath for int256;

    function wrapFromSigned(int256 a) external pure returns (uint256) {
        return FixedPoint.fromSigned(FixedPoint.Signed(a)).rawValue;
    }

    function wrapFromUnsigned(uint256 a) external pure returns (int256) {
        return FixedPoint.fromUnsigned(FixedPoint.Unsigned(a)).rawValue;
    }

    function wrapFromUnscaledInt(int256 a) external pure returns (int256) {
        return FixedPoint.fromUnscaledInt(a).rawValue;
    }

    function wrapIsEqual(int256 a, int256 b) external pure returns (bool) {
        return FixedPoint.Signed(a).isEqual(FixedPoint.Signed(b));
    }

    function wrapMixedIsEqual(int256 a, int256 b) external pure returns (bool) {
        return FixedPoint.Signed(a).isEqual(b);
    }

    function wrapIsGreaterThan(int256 a, int256 b) external pure returns (bool) {
        return FixedPoint.Signed(a).isGreaterThan(FixedPoint.Signed(b));
    }

    function wrapIsGreaterThanOrEqual(int256 a, int256 b) external pure returns (bool) {
        return FixedPoint.Signed(a).isGreaterThanOrEqual(FixedPoint.Signed(b));
    }

    function wrapMixedIsGreaterThan(int256 a, int256 b) external pure returns (bool) {
        return FixedPoint.Signed(a).isGreaterThan(b);
    }

    function wrapMixedIsGreaterThanOrEqual(int256 a, int256 b) external pure returns (bool) {
        return FixedPoint.Signed(a).isGreaterThanOrEqual(b);
    }

    function wrapMixedIsGreaterThanOpposite(int256 a, int256 b) external pure returns (bool) {
        return a.isGreaterThan(FixedPoint.Signed(b));
    }

    function wrapMixedIsGreaterThanOrEqualOpposite(int256 a, int256 b) external pure returns (bool) {
        return a.isGreaterThanOrEqual(FixedPoint.Signed(b));
    }

    function wrapIsLessThan(int256 a, int256 b) external pure returns (bool) {
        return FixedPoint.Signed(a).isLessThan(FixedPoint.Signed(b));
    }

    function wrapIsLessThanOrEqual(int256 a, int256 b) external pure returns (bool) {
        return FixedPoint.Signed(a).isLessThanOrEqual(FixedPoint.Signed(b));
    }

    function wrapMixedIsLessThan(int256 a, int256 b) external pure returns (bool) {
        return FixedPoint.Signed(a).isLessThan(b);
    }

    function wrapMixedIsLessThanOrEqual(int256 a, int256 b) external pure returns (bool) {
        return FixedPoint.Signed(a).isLessThanOrEqual(b);
    }

    function wrapMixedIsLessThanOpposite(int256 a, int256 b) external pure returns (bool) {
        return a.isLessThan(FixedPoint.Signed(b));
    }

    function wrapMixedIsLessThanOrEqualOpposite(int256 a, int256 b) external pure returns (bool) {
        return a.isLessThanOrEqual(FixedPoint.Signed(b));
    }

    function wrapMin(int256 a, int256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).min(FixedPoint.Signed(b)).rawValue;
    }

    function wrapMax(int256 a, int256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).max(FixedPoint.Signed(b)).rawValue;
    }

    function wrapAdd(int256 a, int256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).add(FixedPoint.Signed(b)).rawValue;
    }

    // The first int256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedAdd(int256 a, int256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).add(b).rawValue;
    }

    function wrapSub(int256 a, int256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).sub(FixedPoint.Signed(b)).rawValue;
    }

    // The first int256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedSub(int256 a, int256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).sub(b).rawValue;
    }

    // The second int256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedSubOpposite(int256 a, int256 b) external pure returns (int256) {
        return a.sub(FixedPoint.Signed(b)).rawValue;
    }

    function wrapMul(int256 a, int256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).mul(FixedPoint.Signed(b)).rawValue;
    }

    function wrapMulAwayFromZero(int256 a, int256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).mulAwayFromZero(FixedPoint.Signed(b)).rawValue;
    }

    // The first int256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedMul(int256 a, int256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).mul(b).rawValue;
    }

    function wrapMixedMulAwayFromZero(int256 a, int256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).mulAwayFromZero(b).rawValue;
    }

    function wrapDiv(int256 a, int256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).div(FixedPoint.Signed(b)).rawValue;
    }

    function wrapDivAwayFromZero(int256 a, int256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).divAwayFromZero(FixedPoint.Signed(b)).rawValue;
    }

    // The first int256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedDiv(int256 a, int256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).div(b).rawValue;
    }

    function wrapMixedDivAwayFromZero(int256 a, int256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).divAwayFromZero(b).rawValue;
    }

    // The second int256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedDivOpposite(int256 a, int256 b) external pure returns (int256) {
        return a.div(FixedPoint.Signed(b)).rawValue;
    }

    // The first int256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapPow(int256 a, uint256 b) external pure returns (int256) {
        return FixedPoint.Signed(a).pow(b).rawValue;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../interfaces/OneSplit.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title OneSplit Mock that allows manual price injection.
 */
contract OneSplitMock is OneSplit {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(bytes32 => uint256) prices;

    receive() external payable {}

    // Sets price of 1 FROM = <PRICE> TO
    function setPrice(
        address from,
        address to,
        uint256 price
    ) external {
        prices[keccak256(abi.encodePacked(from, to))] = price;
    }

    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    ) public view override returns (uint256 returnAmount, uint256[] memory distribution) {
        returnAmount = prices[keccak256(abi.encodePacked(fromToken, destToken))] * amount;

        return (returnAmount, distribution);
    }

    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    ) public payable override returns (uint256 returnAmount) {
        uint256 amountReturn = prices[keccak256(abi.encodePacked(fromToken, destToken))] * amount;

        require(amountReturn >= minReturn, "Min Amount not reached");

        if (destToken == ETH_ADDRESS) {
            msg.sender.transfer(amountReturn);
        } else {
            require(IERC20(destToken).transfer(msg.sender, amountReturn), "erc20-send-failed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

abstract contract OneSplit {
    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    ) public view virtual returns (uint256 returnAmount, uint256[] memory distribution);

    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    ) public payable virtual returns (uint256 returnAmount);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Implements only the required ERC20 methods. This contract is used
 * test how contracts handle ERC20 contracts that have not implemented `decimals()`
 * @dev Mostly copied from Consensys EIP-20 implementation:
 * https://github.com/ConsenSys/Tokens/blob/fdf687c69d998266a95f15216b1955a4965a0a6d/contracts/eip20/EIP20.sol
 */
contract BasicERC20 is IERC20 {
    uint256 private constant MAX_UINT256 = 2**256 - 1;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    uint256 private _totalSupply;

    constructor(uint256 _initialAmount) public {
        balances[msg.sender] = _initialAmount;
        _totalSupply = _initialAmount;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}