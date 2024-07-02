// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "Initializable.sol";
import "IERC20.sol";

import "WithdrawalQueue.sol";
import "ILido.sol";

contract Withdrawal is Initializable {
    using WithdrawalQueue for WithdrawalQueue.Queue;

    // Element removed from queue
    event ElementRemoved(uint256 elementId);

    // Element added to queue
    event ElementAdded(uint256 elementId);

    // New redeem request added
    event RedeemRequestAdded(address indexed user, uint256 shares, uint256 batchId);

    // xcKSM claimed by user
    event Claimed(address indexed user, uint256 claimedAmount);

    // Losses ditributed to contract
    event LossesDistributed(uint256 losses);

    // stKSM smart contract
    ILido public stKSM;

    // xcKSM precompile
    IERC20 public xcKSM;

    // withdrawal queue
    WithdrawalQueue.Queue public queue;

    // batch id => price for pool shares to xcKSM 
    // to retrive xcKSM amount for user: user_pool_shares * batchSharePrice[batch_id]
    mapping(uint256 => uint256) public batchSharePrice;

    struct Request {
        uint256 share;
        uint256 batchId;
    }

    // user's withdrawal requests (unclaimed)
    mapping(address => Request[]) public userRequests;

    // total virtual xcKSM amount on contract
    uint256 public totalVirtualXcKSMAmount;

    // total amount of xcKSM pool shares
    uint256 public totalXcKSMPoolShares;

    // stKSM(xcKSM) virtual amount for batch
    uint256 public batchVirtualXcKSMAmount;

    // Last Id of queue element which can be claimed
    uint256 public claimableId;

    // Balance for claiming
    uint256 public pendingForClaiming;

    // max amount of requests in parallel
    uint16 internal constant MAX_REQUESTS = 20;


    modifier onlyLido() {
        require(msg.sender == address(stKSM), "WITHDRAWAL: CALLER_NOT_LIDO");
        _;
    }

    /**
    * @notice Initialize redeemPool contract.
    * @param _cap - cap for queue
    * @param _xcKSM - xcKSM precompile address
    */
    function initialize(
        uint256 _cap,
        address _xcKSM
    ) external initializer {
        require(_cap > 0, "WITHDRAWAL: INCORRECT_CAP");
        require(_xcKSM != address(0), "WITHDRAWAL: INCORRECT_XCKSM_ADDRESS");
        queue.init(_cap);
        xcKSM = IERC20(_xcKSM);
    }

    /**
    * @notice Set stKSM contract address, allowed to only once
    * @param _stKSM stKSM contract address
    */
    function setStKSM(address _stKSM) external {
        require(address(stKSM) == address(0), "WITHDRAWAL: STKSM_ALREADY_DEFINED");
        require(_stKSM != address(0), "WITHDRAWAL: INCORRECT_STKSM_ADDRESS");

        stKSM = ILido(_stKSM);
    }

    /**
    * @notice Burn pool shares from first element of queue and move index for allow claiming. After that add new batch
    */
    function newEra() external onlyLido {
        uint256 newXcKSMAmount = xcKSM.balanceOf(address(this)) - pendingForClaiming;

        if ((newXcKSMAmount > 0) && (queue.size > 0)) {
            (WithdrawalQueue.Batch memory topBatch, uint256 topId) = queue.top();
            // batchSharePrice = pool_xcKSM_balance / pool_shares
            // when user try to claim: user_KSM = user_pool_share * batchSharePrice
            uint256 sharePriceForBatch = getBatchSharePrice(topBatch);
            uint256 xcKSMForBatch = topBatch.batchTotalShares * sharePriceForBatch / 10**12;
            if (newXcKSMAmount >= xcKSMForBatch) {
                batchSharePrice[topId] = sharePriceForBatch;

                totalXcKSMPoolShares -= topBatch.batchXcKSMShares;
                totalVirtualXcKSMAmount -= xcKSMForBatch;
                // NOTE: In case when losses occur due to rounding it is possible to 
                // totalVirtualXcKSMAmount > 0 and totalXcKSMPoolShares = 0
                if (totalXcKSMPoolShares == 0) {
                    totalVirtualXcKSMAmount = 0;
                }

                claimableId = topId;
                pendingForClaiming += xcKSMForBatch;

                queue.pop();

                emit ElementRemoved(topId);
            }
        }

        if ((batchVirtualXcKSMAmount > 0) && (queue.size < queue.cap)) {
            uint256 batchKSMPoolShares = getKSMPoolShares(batchVirtualXcKSMAmount);

            // NOTE: batch total shares = batch xcKSM amount, because 1 share = 1 xcKSM
            WithdrawalQueue.Batch memory newBatch = WithdrawalQueue.Batch(batchVirtualXcKSMAmount, batchKSMPoolShares);
            uint256 newId = queue.push(newBatch);

            totalVirtualXcKSMAmount += batchVirtualXcKSMAmount;
            totalXcKSMPoolShares += batchKSMPoolShares;

            batchVirtualXcKSMAmount = 0;

            emit ElementAdded(newId);
        }
    }

    /**
    * @notice Returns total virtual xcKSM balance of contract for which losses can be applied
    */
    function totalBalanceForLosses() external view returns (uint256) {
        return totalVirtualXcKSMAmount + batchVirtualXcKSMAmount;
    }

    /**
    * @notice function returns xcKSM amount that should be available for claiming after batch remove
    * @param _batchShift batch shift from first element
    */
    function getxcKSMBalanceForBatch(uint256 _batchShift) external view returns (uint256) {
        (WithdrawalQueue.Batch memory specificBatch, ) = queue.element(_batchShift);
        // batchSharePrice = pool_xcKSM_balance / pool_shares
        // when user try to claim: user_KSM = user_pool_share * batchSharePrice
        uint256 sharePriceForBatch = getBatchSharePrice(specificBatch);
        uint256 xcKSMForBatch = specificBatch.batchTotalShares * sharePriceForBatch / 10**12;
        return xcKSMForBatch;
    }

    /**
    * @notice function returns specific batch from queue
    * @param _batchShift batch shift from first element
    */
    function getQueueBatch(uint256 _batchShift) external view returns (WithdrawalQueue.Batch memory) {
        (WithdrawalQueue.Batch memory specificBatch, ) = queue.element(_batchShift);
        return specificBatch;
    }

    /**
    * @notice 1. Mint equal amount of pool shares for user 
    * @notice 2. Adjust current amount of virtual xcKSM on Withdrawal contract
    * @notice 3. Burn shares on LIDO side
    * @param _from user address for minting
    * @param _amount amount of stKSM which user wants to redeem
    */
    function redeem(address _from, uint256 _amount) external onlyLido {
        // NOTE: user share in batch = user stKSM balance in specific batch
        require(userRequests[_from].length < MAX_REQUESTS, "WITHDRAWAL: REQUEST_CAP_EXCEEDED");
        batchVirtualXcKSMAmount += _amount;

        Request memory req = Request(_amount, queue.nextId());
        userRequests[_from].push(req);

        emit RedeemRequestAdded(_from, req.share, req.batchId);
    }

    /**
    * @notice Returns available for claiming xcKSM amount for user
    * @param _holder user address for claiming
    */
    function claim(address _holder) external onlyLido returns (uint256) {
        // go through claims and check if unlocked than just transfer xcKSMs
        uint256 readyToClaim = 0;
        uint256 readyToClaimCount = 0;
        Request[] storage requests = userRequests[_holder];

        for (uint256 i = 0; i < requests.length; ++i) {
            if (requests[i].batchId <= claimableId) {
                readyToClaim += requests[i].share * batchSharePrice[requests[i].batchId] / 10**12;
                readyToClaimCount += 1;
            }
            else {
                requests[i - readyToClaimCount] = requests[i];
            }
        }

        // remove claimed items
        for (uint256 i = 0; i < readyToClaimCount; ++i) { requests.pop(); }

        require(readyToClaim <= xcKSM.balanceOf(address(this)), "WITHDRAWAL: CLAIM_EXCEEDS_BALANCE");
        xcKSM.transfer(_holder, readyToClaim);
        pendingForClaiming -= readyToClaim;

        emit Claimed(_holder, readyToClaim);

        return readyToClaim;
    }

    /**
    * @notice Apply losses to current stKSM shares on this contract
    * @param _losses user address for claiming
    */
    function ditributeLosses(uint256 _losses) external onlyLido {
        totalVirtualXcKSMAmount -= _losses;
        emit LossesDistributed(_losses);
    }

    /**
    * @notice Check available for claim xcKSM balance for user
    * @param _holder user address
    */
    function getRedeemStatus(address _holder) external view returns(uint256 _waiting, uint256 _available) {
        Request[] storage requests = userRequests[_holder];

        for (uint256 i = 0; i < requests.length; ++i) {
            if (requests[i].batchId <= claimableId) {
                _available += requests[i].share * batchSharePrice[requests[i].batchId] / 10**12;
            }
            else {
                _waiting += requests[i].share * getBatchSharePrice(queue.findBatch(requests[i].batchId)) / 10**12;
            }
        }
        return (_waiting, _available);
    }

    /**
    * @notice Calculate share price to KSM for specific batch
    * @param _batch batch
    */
    function getBatchSharePrice(WithdrawalQueue.Batch memory _batch) internal view returns (uint256) {
        uint256 batchKSMPrice;
        if (totalXcKSMPoolShares > 0) {
            // user_xcKSM = user_batch_share * batch_share_price
            // batch_share_price = (1 / batch_total_shares) * batch_pool_shares * (total_xcKSM / total_pool_shares)
            if (_batch.batchTotalShares > 0) {
                batchKSMPrice = (10**12 * _batch.batchXcKSMShares * totalVirtualXcKSMAmount) / 
                                (_batch.batchTotalShares * totalXcKSMPoolShares);
            }
            else {
                // NOTE: This means that batch not added to queue currently
                if (batchVirtualXcKSMAmount > 0) {
                    batchKSMPrice = (10**12 * getKSMPoolShares(batchVirtualXcKSMAmount) * totalVirtualXcKSMAmount) / 
                                    (batchVirtualXcKSMAmount * totalXcKSMPoolShares);
                }
            }
        }
        else {
            // NOTE: This means that we have only one batch that no in the pool (batch share price == 10**12)
            if (batchVirtualXcKSMAmount > 0) {
                batchKSMPrice = 10**12;
            }
        }
        return batchKSMPrice;
    }

    /**
    * @notice Calculate shares amount in KSM pool for specific xcKSM amount
    * @param _amount amount of xcKSM tokens
    */
    function getKSMPoolShares(uint256 _amount) internal view returns (uint256) {
        if (totalVirtualXcKSMAmount > 0) {
            return _amount * totalXcKSMPoolShares / totalVirtualXcKSMAmount;
        }
        return _amount;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

library WithdrawalQueue {
    struct Batch {
        uint256 batchTotalShares; // Total shares amount for batch
        uint256 batchXcKSMShares; // Batch xcKSM shares in xcKSM pool
    }

    struct Queue {
        Batch[] items;
        uint256[] ids;

        uint256 first;
        uint256 size;
        uint256 cap;
        uint256 id;
    }

    /**
    * @notice Queue initialization
    * @param queue queue for initializing
    * @param cap max amount of elements in the queue
    */
    function init(Queue storage queue, uint256 cap) internal {
        for (uint256 i = 0; i < cap; ++i) {
            queue.items.push(Batch(0, 0));
        }
        queue.ids = new uint256[](cap);
        queue.first = 0;
        queue.size = 0;
        queue.size = 0;
        queue.cap = cap;
    }

    /**
    * @notice Add element to the end of queue
    * @param queue current queue
    * @param elem element for adding
    */
    function push(Queue storage queue, Batch memory elem) internal returns (uint256 _id) {
        require(queue.size < queue.cap, "WithdrawalQueue: capacity exceeded");
        uint256 lastIndex = (queue.first + queue.size) % queue.cap;
        queue.items[lastIndex] = elem;
        queue.id++;
        queue.ids[lastIndex] = queue.id;
        queue.size++;
        return queue.id;
    }

    /**
    * @notice Remove element from top of the queue
    * @param queue current queue
    */
    function pop(Queue storage queue) internal returns (Batch memory _item, uint256 _id) {
        require(queue.size > 0, "WithdrawalQueue: queue is empty");
        _item = queue.items[queue.first];
        _id = queue.ids[queue.first];
        queue.first = (queue.first + 1) % queue.cap;
        queue.size--;
    }

    /**
    * @notice Return batch for specific index
    * @param queue current queue
    * @param index index of batch
    */
    function findBatch(Queue storage queue, uint256 index) internal view returns (Batch memory _item) {
        uint256 startIndex = queue.ids[queue.first];
        if (index >= startIndex) {
            if ((index - startIndex) < queue.size) {
                return queue.items[(queue.first + (index - startIndex)) % queue.cap];
            }
        }
        return Batch(0, 0);
    }

    /**
    * @notice Return first element of the queue
    * @param queue current queue
    */
    function top(Queue storage queue) internal view returns (Batch memory _item, uint256 _id) {
        require(queue.size > 0, "WithdrawalQueue: queue is empty");
        _item = queue.items[queue.first];
        _id = queue.ids[queue.first];
    }

    /**
    * @notice Return specific element of the queue
    * @param queue current queue
    * @param shift element shift from top id
    */
    function element(Queue storage queue, uint256 shift) internal view returns (Batch memory _item, uint256 _id) {
        require(queue.size > 0, "WithdrawalQueue: queue is empty");
        require(shift < queue.size, "WithdrawalQueue: index outside queue");
        uint256 index = (queue.first + shift) % queue.cap;
        _item = queue.items[index];
        _id = queue.ids[index];
    }

    /**
    * @notice Return last element of the queue
    * @param queue current queue
    */
    function last(Queue storage queue) internal view returns (Batch memory _item, uint256 _id) {
        require(queue.size > 0, "WithdrawalQueue: queue is empty");
        uint256 lastIndex = (queue.first + queue.size - 1) % queue.cap;
        _item = queue.items[lastIndex];
        _id = queue.ids[lastIndex];
    }

    /**
    * @notice Return last element id + 1
    * @param queue current queue
    */
    function nextId(Queue storage queue) internal view returns (uint256 _id) {
        _id = queue.id + 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Types.sol";

interface ILido {
    function MAX_ALLOWABLE_DIFFERENCE() external view returns(uint128);

    function deposit(uint256 amount) external returns (uint256);

    function distributeRewards(uint256 totalRewards, uint256 ledgerBalance) external;

    function distributeLosses(uint256 totalLosses, uint256 ledgerBalance) external;

    function getStashAccounts() external view returns (bytes32[] memory);

    function getLedgerAddresses() external view returns (address[] memory);

    function ledgerStake(address ledger) external view returns (uint256);

    function transferFromLedger(uint256 amount, uint256 excess) external;

    function transferFromLedger(uint256 amount) external;

    function transferToLedger(uint256 amount) external;

    function flushStakes() external;

    function findLedger(bytes32 stash) external view returns (address);

    function AUTH_MANAGER() external returns(address);

    function ORACLE_MASTER() external view returns (address);

    function getPooledKSMByShares(uint256 sharesAmount) external view returns (uint256);

    function getSharesByPooledKSM(uint256 amount) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Types {
    struct Fee{
        uint16 total;
        uint16 operators;
        uint16 developers;
        uint16 treasury;
    }

    struct Stash {
        bytes32 stashAccount;
        uint64  eraId;
    }

    enum LedgerStatus {
        // bonded but not participate in staking
        Idle,
        // participate as nominator
        Nominator,
        // participate as validator
        Validator,
        // not bonded not participate in staking
        None
    }

    struct UnlockingChunk {
        uint128 balance;
        uint64 era;
    }

    struct OracleData {
        bytes32 stashAccount;
        bytes32 controllerAccount;
        LedgerStatus stakeStatus;
        // active part of stash balance
        uint128 activeBalance;
        // locked for stake stash balance.
        uint128 totalBalance;
        // totalBalance = activeBalance + sum(unlocked.balance)
        UnlockingChunk[] unlocking;
        uint32[] claimedRewards;
        // stash account balance. It includes locked (totalBalance) balance assigned
        // to a controller.
        uint128 stashBalance;
        // slashing spans for ledger
        uint32 slashingSpans;
    }

    struct RelaySpec {
        uint16 maxValidatorsPerLedger;
        uint128 minNominatorBalance;
        uint128 ledgerMinimumActiveBalance;
        uint256 maxUnlockingChunks;
    }
}