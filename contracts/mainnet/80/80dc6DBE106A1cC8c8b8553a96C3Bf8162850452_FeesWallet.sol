// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";

import "./IMigratableFeesWallet.sol";
import "./IFeesWallet.sol";
import "./ManagedContract.sol";

/// @title Fees Wallet contract interface, manages the fee buckets
contract FeesWallet is IFeesWallet, ManagedContract {
    using SafeMath for uint256;

    uint256 constant BUCKET_TIME_PERIOD = 30 days;
    uint constant MAX_FEE_BUCKET_ITERATIONS = 24;

    IERC20 public token;
    mapping(uint256 => uint256) public buckets;
    uint256 public lastCollectedAt;

    constructor(IContractRegistry _contractRegistry, address _registryAdmin, IERC20 _token) ManagedContract(_contractRegistry, _registryAdmin) public {
        token = _token;
        lastCollectedAt = now;
    }

    modifier onlyRewardsContract() {
        require(msg.sender == rewardsContract, "caller is not the rewards contract");

        _;
    }

    /*
     *   External methods
     */

    /// @dev collect fees from the buckets since the last call and transfers the amount back.
    /// Called by: only Rewards contract.
    function collectFees() external override onlyRewardsContract returns (uint256 collectedFees)  {
        (uint256 _collectedFees, uint[] memory bucketsWithdrawn, uint[] memory amountsWithdrawn, uint[] memory newTotals) = _getOutstandingFees();

        for (uint i = 0; i < bucketsWithdrawn.length; i++) {
            buckets[bucketsWithdrawn[i]] = newTotals[i];
            emit FeesWithdrawnFromBucket(bucketsWithdrawn[i], amountsWithdrawn[i], newTotals[i]);
        }

        lastCollectedAt = block.timestamp;

        require(token.transfer(msg.sender, _collectedFees), "FeesWallet::failed to transfer collected fees to rewards"); // TODO in that case, transfer the remaining balance?
        return _collectedFees;
    }

    function getOutstandingFees() external override view returns (uint256 outstandingFees)  {
        (outstandingFees,,,) = _getOutstandingFees();
    }

    /// @dev Called by: subscriptions contract.
    /// Top-ups the fee pool with the given amount at the given rate (typically called by the subscriptions contract).
    function fillFeeBuckets(uint256 amount, uint256 monthlyRate, uint256 fromTimestamp) external override onlyWhenActive {
        uint256 bucket = _bucketTime(fromTimestamp);
        require(bucket >= _bucketTime(block.timestamp), "FeeWallet::cannot fill bucket from the past");

        uint256 _amount = amount;

        // add the partial amount to the first bucket
        uint256 bucketAmount = Math.min(amount, monthlyRate.mul(BUCKET_TIME_PERIOD - fromTimestamp % BUCKET_TIME_PERIOD).div(BUCKET_TIME_PERIOD));
        fillFeeBucket(bucket, bucketAmount);
        _amount = _amount.sub(bucketAmount);

        // following buckets are added with the monthly rate
        while (_amount > 0) {
            bucket = bucket.add(BUCKET_TIME_PERIOD);
            bucketAmount = Math.min(monthlyRate, _amount);
            fillFeeBucket(bucket, bucketAmount);

            _amount = _amount.sub(bucketAmount);
        }

        require(token.transferFrom(msg.sender, address(this), amount), "failed to transfer fees into fee wallet");
    }

    /*
     * Governance functions
     */

    /// @dev migrates the fees of bucket starting at startTimestamp.
    /// bucketStartTime must be a bucket's start time.
    /// Calls acceptBucketMigration in the destination contract.
    function migrateBucket(IMigratableFeesWallet destination, uint256 bucketStartTime) external override onlyMigrationManager {
        require(_bucketTime(bucketStartTime) == bucketStartTime,  "bucketStartTime must be the  start time of a bucket");

        uint bucketAmount = buckets[bucketStartTime];
        if (bucketAmount == 0) return;

        buckets[bucketStartTime] = 0;
        emit FeesWithdrawnFromBucket(bucketStartTime, bucketAmount, 0);

        token.approve(address(destination), bucketAmount);
        destination.acceptBucketMigration(bucketStartTime, bucketAmount);
    }

    /// @dev Called by the old FeesWallet contract.
    /// Part of the IMigratableFeesWallet interface.
    function acceptBucketMigration(uint256 bucketStartTime, uint256 amount) external override {
        require(_bucketTime(bucketStartTime) == bucketStartTime,  "bucketStartTime must be the  start time of a bucket");
        fillFeeBucket(bucketStartTime, amount);
        require(token.transferFrom(msg.sender, address(this), amount), "failed to transfer fees into fee wallet on bucket migration");
    }

    /// @dev an emergency withdrawal enables withdrawal of all funds to an escrow account. To be use in emergencies only.
    function emergencyWithdraw() external override onlyMigrationManager {
        emit EmergencyWithdrawal(msg.sender);
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "IFeesWallet::emergencyWithdraw - transfer failed (fee token)");
    }

    /*
    * Private methods
    */

    function fillFeeBucket(uint256 bucketId, uint256 amount) private {
        uint256 bucketTotal = buckets[bucketId].add(amount);
        buckets[bucketId] = bucketTotal;
        emit FeesAddedToBucket(bucketId, amount, bucketTotal);
    }

    function _getOutstandingFees() private view returns (uint256 outstandingFees, uint[] memory bucketsWithdrawn, uint[] memory withdrawnAmounts, uint[] memory newTotals)  {
        // TODO we often do integer division for rate related calculation, which floors the result. Do we need to address this?
        // TODO for an empty committee or a committee with 0 total stake the divided amounts will be locked in the contract FOREVER

        // Fee pool
        uint _lastCollectedAt = lastCollectedAt;
        uint nUpdatedBuckets = _bucketTime(block.timestamp).sub(_bucketTime(_lastCollectedAt)).div(BUCKET_TIME_PERIOD).add(1);
        bucketsWithdrawn = new uint[](nUpdatedBuckets);
        withdrawnAmounts = new uint[](nUpdatedBuckets);
        newTotals = new uint[](nUpdatedBuckets);
        uint bucketsPayed = 0;
        while (bucketsPayed < MAX_FEE_BUCKET_ITERATIONS && _lastCollectedAt < block.timestamp) {
            uint256 bucketStart = _bucketTime(_lastCollectedAt);
            uint256 bucketEnd = bucketStart.add(BUCKET_TIME_PERIOD);
            uint256 payUntil = Math.min(bucketEnd, block.timestamp);
            uint256 bucketDuration = payUntil.sub(_lastCollectedAt);
            uint256 remainingBucketTime = bucketEnd.sub(_lastCollectedAt);

            uint256 bucketTotal = buckets[bucketStart];
            uint256 amount = bucketTotal * bucketDuration / remainingBucketTime;
            outstandingFees += amount;
            bucketTotal = bucketTotal.sub(amount);

            bucketsWithdrawn[bucketsPayed] = bucketStart;
            withdrawnAmounts[bucketsPayed] = amount;
            newTotals[bucketsPayed] = bucketTotal;

            _lastCollectedAt = payUntil;
            bucketsPayed++;
        }
    }

    function _bucketTime(uint256 time) private pure returns (uint256) {
        return time - time % BUCKET_TIME_PERIOD;
    }

    /*
     * Contracts topology / registry interface
     */

    address rewardsContract;
    function refreshContracts() external override {
        rewardsContract = getFeesAndBootstrapRewardsContract();
    }
}
