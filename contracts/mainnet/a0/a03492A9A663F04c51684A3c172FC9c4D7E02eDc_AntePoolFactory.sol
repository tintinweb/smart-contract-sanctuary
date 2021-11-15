// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.7.0;

import "./AntePool.sol";
import "./interfaces/IAnteTest.sol";
import "./interfaces/IAntePoolFactory.sol";

/// @title Ante V0.5 Ante Pool Factory smart contract
/// @notice Contract that creates an AntePool wrapper for an AnteTest
contract AntePoolFactory is IAntePoolFactory {
    /// @inheritdoc IAntePoolFactory
    mapping(address => address) public override poolMap;
    /// @inheritdoc IAntePoolFactory
    address[] public override allPools;

    /// @inheritdoc IAntePoolFactory
    function createPool(address testAddr) external override returns (address testPool) {
        // Checks that a non-zero AnteTest address is passed in and that
        // an AntePool has not already been created for that AnteTest
        require(testAddr != address(0), "ANTE: Test address is 0");
        require(poolMap[testAddr] == address(0), "ANTE: Pool already created");

        IAnteTest anteTest = IAnteTest(testAddr);

        bytes memory bytecode = type(AntePool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(testAddr));

        assembly {
            testPool := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        poolMap[testAddr] = testPool;
        allPools.push(testPool);

        AntePool(testPool).initialize(anteTest);

        emit AntePoolCreated(testAddr, testPool);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IAnteTest.sol";
import "./libraries/IterableSet.sol";
import "./libraries/FullMath.sol";
import "./interfaces/IAntePool.sol";

/// @title Ante V0.5 Ante Pool smart contract
/// @notice Deploys an Ante Pool and connects with the Ante Test, manages pools and interactions with users
contract AntePool is IAntePool {
    using SafeMath for uint256;
    using FullMath for uint256;
    using Address for address;
    using IterableAddressSetUtils for IterableAddressSetUtils.IterableAddressSet;

    /// @notice Info related to a single user
    struct UserInfo {
        // How much ETH this user deposited.
        uint256 startAmount;
        // How much decay this side of the pool accrued between (0, this user's
        // entry block), stored as a multiplier expressed as an 18-decimal
        // mantissa. For example, if this side of the pool accrued a decay of
        // 20% during this time period, we'd store 1.2e18 (staking side) or
        // 0.8e18 (challenger side).
        uint256 startDecayMultiplier;
    }

    /// @notice Info related to one side of the pool
    struct PoolSideInfo {
        mapping(address => UserInfo) userInfo;
        // Number of users on this side of the pool.
        uint256 numUsers;
        // Amount staked across all users on this side of the pool, as of
        // `lastUpdateBlock`.`
        uint256 totalAmount;
        // How much decay this side of the pool accrued between (0,
        // lastUpdateBlock), stored as a multiplier expressed as an 18-decimal
        // mantissa. For example, if this side of the pool accrued a decay of
        // 20% during this time period, we'd store 1.2e18 (staking side) or
        // 0.8e18 (challenger side).
        uint256 decayMultiplier;
    }

    /// @notice Info related to eligible challengers
    struct ChallengerEligibilityInfo {
        // Used when test fails to determine which challengers should receive payout
        // i.e., those which haven't staked within 12 blocks prior to test failure
        mapping(address => uint256) lastStakedBlock;
        uint256 eligibleAmount;
    }

    /// @notice Info related to stakers who are currently withdrawing
    struct StakerWithdrawInfo {
        mapping(address => UserUnstakeInfo) userUnstakeInfo;
        uint256 totalAmount;
    }

    /// @notice Info related to a single withdrawing user
    struct UserUnstakeInfo {
        uint256 lastUnstakeTimestamp;
        uint256 amount;
    }

    /// @inheritdoc IAntePool
    IAnteTest public override anteTest;
    /// @inheritdoc IAntePool
    address public override factory;
    /// @inheritdoc IAntePool
    /// @dev pendingFailure set to true until pool is initialized to avoid
    /// people staking in uninitialized pools
    bool public override pendingFailure = true;
    /// @inheritdoc IAntePool
    uint256 public override numTimesVerified;
    /// @dev Percent of staked amount alloted for verifier bounty
    uint256 public constant VERIFIER_BOUNTY = 5;
    /// @inheritdoc IAntePool
    uint256 public override failedBlock;
    /// @inheritdoc IAntePool
    uint256 public override lastVerifiedBlock;
    /// @inheritdoc IAntePool
    address public override verifier;
    /// @inheritdoc IAntePool
    uint256 public override numPaidOut;
    /// @inheritdoc IAntePool
    uint256 public override totalPaidOut;

    /// @dev pool can only be initialized once
    bool internal _initialized = false;
    /// @dev Bounty amount, set when test fails
    uint256 internal _bounty;
    /// @dev Total staked value, after bounty is removed
    uint256 internal _remainingStake;

    /// @dev Amount of decay to charge each challengers ETH per block
    /// 100 gwei decay per block per ETH is ~20-25% decay per year
    uint256 public constant DECAY_RATE_PER_BLOCK = 100 gwei;

    /// @dev Number of blocks a challenger must be staking before they are
    /// eligible for paytout on test failure
    uint8 public constant CHALLENGER_BLOCK_DELAY = 12;

    /// @dev Minimum challenger stake is 0.01 ETH
    uint256 public constant MIN_CHALLENGER_STAKE = 1e16;

    /// @dev Time after initiating withdraw before staker can finally withdraw capital,
    /// starts when staker initiates the unstake action
    uint256 public constant UNSTAKE_DELAY = 24 hours;

    /// @dev convenience constant for 1 ether worth of wei
    uint256 private constant ONE = 1e18;

    /// @inheritdoc IAntePool
    PoolSideInfo public override stakingInfo;
    /// @inheritdoc IAntePool
    PoolSideInfo public override challengerInfo;
    /// @inheritdoc IAntePool
    ChallengerEligibilityInfo public override eligibilityInfo;
    /// @dev All addresses currently challenging the Ante Test
    IterableAddressSetUtils.IterableAddressSet private challengers;
    /// @inheritdoc IAntePool
    StakerWithdrawInfo public override withdrawInfo;

    /// @inheritdoc IAntePool
    uint256 public override lastUpdateBlock;

    /// @notice Modifier function to make sure test hasn't failed yet
    modifier testNotFailed() {
        _testNotFailed();
        _;
    }

    modifier notInitialized() {
        require(!_initialized, "ANTE: Pool already initialized");
        _;
    }

    /// @dev Ante Pools are deployed by Ante Pool Factory, and we store
    /// the address of the factory here
    constructor() {
        factory = msg.sender;
        stakingInfo.decayMultiplier = ONE;
        challengerInfo.decayMultiplier = ONE;
        lastUpdateBlock = block.number;
    }

    /// @inheritdoc IAntePool
    function initialize(IAnteTest _anteTest) external override notInitialized {
        require(msg.sender == factory, "ANTE: only factory can initialize AntePool");
        require(address(_anteTest).isContract(), "ANTE: AnteTest must be a smart contract");
        // Check that anteTest has checkTestPasses function and that it currently passes
        // place check here to minimize reentrancy risk - most external function calls are locked
        // while pendingFailure is true
        require(_anteTest.checkTestPasses(), "ANTE: AnteTest does not implement checkTestPasses or test fails");

        _initialized = true;
        pendingFailure = false;
        anteTest = _anteTest;
    }

    /*****************************************************
     * ================ USER INTERFACE ================= *
     *****************************************************/

    /// @inheritdoc IAntePool
    /// @dev Stake `msg.value` on the side given by `isChallenger`
    function stake(bool isChallenger) external payable override testNotFailed {
        uint256 amount = msg.value;
        require(amount > 0, "ANTE: Cannot stake zero");

        updateDecay();

        PoolSideInfo storage side;
        if (isChallenger) {
            require(amount >= MIN_CHALLENGER_STAKE, "ANTE: Challenger must stake more than 0.01 ETH");
            side = challengerInfo;

            // Record challenger info for future use
            // Challengers are not eligible for rewards if challenging within 12 block window of test failure
            challengers.insert(msg.sender);
            eligibilityInfo.lastStakedBlock[msg.sender] = block.number;
        } else {
            side = stakingInfo;
        }

        UserInfo storage user = side.userInfo[msg.sender];

        // Calculate how much the user already has staked, including the
        // effects of any previously accrued decay.
        //   prevAmount = startAmount * decayMultipiler / startDecayMultiplier
        //   newAmount = amount + prevAmount
        if (user.startAmount > 0) {
            user.startAmount = amount.add(_storedBalance(user, side));
        } else {
            user.startAmount = amount;
            side.numUsers = side.numUsers.add(1);
        }
        side.totalAmount = side.totalAmount.add(amount);

        // Reset the startDecayMultiplier for this user, since we've updated
        // the startAmount to include any already-accrued decay.
        user.startDecayMultiplier = side.decayMultiplier;

        emit Stake(msg.sender, amount, isChallenger);
    }

    /// @inheritdoc IAntePool
    /// @dev Unstake `amount` on the side given by `isChallenger`.
    function unstake(uint256 amount, bool isChallenger) external override testNotFailed {
        require(amount > 0, "ANTE: Cannot unstake 0.");

        updateDecay();

        PoolSideInfo storage side = isChallenger ? challengerInfo : stakingInfo;

        UserInfo storage user = side.userInfo[msg.sender];
        _unstake(amount, isChallenger, side, user);
    }

    /// @inheritdoc IAntePool
    function unstakeAll(bool isChallenger) external override testNotFailed {
        updateDecay();

        PoolSideInfo storage side = isChallenger ? challengerInfo : stakingInfo;

        UserInfo storage user = side.userInfo[msg.sender];

        uint256 amount = _storedBalance(user, side);
        require(amount > 0, "ANTE: Nothing to unstake");

        _unstake(amount, isChallenger, side, user);
    }

    /// @inheritdoc IAntePool
    function withdrawStake() external override testNotFailed {
        UserUnstakeInfo storage unstakeUser = withdrawInfo.userUnstakeInfo[msg.sender];

        require(
            unstakeUser.lastUnstakeTimestamp < block.timestamp - UNSTAKE_DELAY,
            "ANTE: must wait 24 hours to withdraw stake"
        );
        require(unstakeUser.amount > 0, "ANTE: Nothing to withdraw");

        uint256 amount = unstakeUser.amount;
        withdrawInfo.totalAmount = withdrawInfo.totalAmount.sub(amount);
        unstakeUser.amount = 0;

        _safeTransfer(msg.sender, amount);

        emit WithdrawStake(msg.sender, amount);
    }

    /// @inheritdoc IAntePool
    function cancelPendingWithdraw() external override testNotFailed {
        UserUnstakeInfo storage unstakeUser = withdrawInfo.userUnstakeInfo[msg.sender];

        require(unstakeUser.amount > 0, "ANTE: No pending withdraw balance");
        uint256 amount = unstakeUser.amount;
        unstakeUser.amount = 0;

        updateDecay();

        UserInfo storage user = stakingInfo.userInfo[msg.sender];
        if (user.startAmount > 0) {
            user.startAmount = amount.add(_storedBalance(user, stakingInfo));
        } else {
            user.startAmount = amount;
            stakingInfo.numUsers = stakingInfo.numUsers.add(1);
        }
        stakingInfo.totalAmount = stakingInfo.totalAmount.add(amount);
        user.startDecayMultiplier = stakingInfo.decayMultiplier;

        withdrawInfo.totalAmount = withdrawInfo.totalAmount.sub(amount);

        emit CancelWithdraw(msg.sender, amount);
    }

    /// @inheritdoc IAntePool
    function checkTest() external override testNotFailed {
        require(challengers.exists(msg.sender), "ANTE: Only challengers can checkTest");
        require(
            block.number.sub(eligibilityInfo.lastStakedBlock[msg.sender]) > CHALLENGER_BLOCK_DELAY,
            "ANTE: must wait 12 blocks after challenging to call checkTest"
        );

        numTimesVerified = numTimesVerified.add(1);
        lastVerifiedBlock = block.number;
        emit TestChecked(msg.sender);
        if (!_checkTestNoRevert()) {
            updateDecay();
            verifier = msg.sender;
            failedBlock = block.number;
            pendingFailure = true;

            _calculateChallengerEligibility();
            _bounty = getVerifierBounty();

            uint256 totalStake = stakingInfo.totalAmount.add(withdrawInfo.totalAmount);
            _remainingStake = totalStake.sub(_bounty);

            emit FailureOccurred(msg.sender);
        }
    }

    /// @inheritdoc IAntePool
    function claim() external override {
        require(pendingFailure, "ANTE: Test has not failed");

        UserInfo storage user = challengerInfo.userInfo[msg.sender];
        require(user.startAmount > 0, "ANTE: No Challenger Staking balance");

        uint256 amount = _calculateChallengerPayout(user, msg.sender);
        // Zero out the user so they can't claim again.
        user.startAmount = 0;

        numPaidOut = numPaidOut.add(1);
        totalPaidOut = totalPaidOut.add(amount);

        _safeTransfer(msg.sender, amount);
        emit ClaimPaid(msg.sender, amount);
    }

    /// @inheritdoc IAntePool
    function updateDecay() public override {
        (uint256 decayMultiplierThisUpdate, uint256 decayThisUpdate) = _computeDecay();

        lastUpdateBlock = block.number;

        if (decayThisUpdate == 0) return;

        uint256 totalStaked = stakingInfo.totalAmount;
        uint256 totalChallengerStaked = challengerInfo.totalAmount;

        // update totoal accrued decay amounts for challengers
        // decayMultiplier for challengers = decayMultiplier for challengers * decayMultiplierThisUpdate
        // totalChallengerStaked = totalChallengerStaked - decayThisUpdate
        challengerInfo.decayMultiplier = challengerInfo.decayMultiplier.mulDiv(decayMultiplierThisUpdate, ONE);
        challengerInfo.totalAmount = totalChallengerStaked.sub(decayThisUpdate);

        // Update the new accrued decay amounts for stakers.
        //   totalStaked_new = totalStaked_old + decayThisUpdate
        //   decayMultipilerThisUpdate = totalStaked_new / totalStaked_old
        //   decayMultiplier_staker = decayMultiplier_staker * decayMultiplierThisUpdate
        uint256 totalStakedNew = totalStaked.add(decayThisUpdate);

        stakingInfo.decayMultiplier = stakingInfo.decayMultiplier.mulDiv(totalStakedNew, totalStaked);
        stakingInfo.totalAmount = totalStakedNew;
    }

    /*****************************************************
     * ================ VIEW FUNCTIONS ================= *
     *****************************************************/

    /// @inheritdoc IAntePool
    function getTotalChallengerStaked() external view override returns (uint256) {
        return challengerInfo.totalAmount;
    }

    /// @inheritdoc IAntePool
    function getTotalStaked() external view override returns (uint256) {
        return stakingInfo.totalAmount;
    }

    /// @inheritdoc IAntePool
    function getTotalPendingWithdraw() external view override returns (uint256) {
        return withdrawInfo.totalAmount;
    }

    /// @inheritdoc IAntePool
    function getTotalChallengerEligibleBalance() external view override returns (uint256) {
        return eligibilityInfo.eligibleAmount;
    }

    /// @inheritdoc IAntePool
    function getChallengerPayout(address challenger) external view override returns (uint256) {
        UserInfo storage user = challengerInfo.userInfo[challenger];
        require(user.startAmount > 0, "ANTE: No Challenger Staking balance");

        // If called before test failure returns an estimate
        if (pendingFailure) {
            return _calculateChallengerPayout(user, challenger);
        } else {
            uint256 amount = _storedBalance(user, challengerInfo);
            uint256 bounty = getVerifierBounty();
            uint256 totalStake = stakingInfo.totalAmount.add(withdrawInfo.totalAmount);

            return amount.add(amount.mulDiv(totalStake.sub(bounty), challengerInfo.totalAmount));
        }
    }

    /// @inheritdoc IAntePool
    function getStoredBalance(address _user, bool isChallenger) external view override returns (uint256) {
        (uint256 decayMultiplierThisUpdate, uint256 decayThisUpdate) = _computeDecay();

        UserInfo storage user = isChallenger ? challengerInfo.userInfo[_user] : stakingInfo.userInfo[_user];

        if (user.startAmount == 0) return 0;

        require(user.startDecayMultiplier > 0, "ANTE: Invalid startDecayMultiplier");

        uint256 decayMultiplier;

        if (isChallenger) {
            decayMultiplier = challengerInfo.decayMultiplier.mul(decayMultiplierThisUpdate).div(1e18);
        } else {
            uint256 totalStaked = stakingInfo.totalAmount;
            uint256 totalStakedNew = totalStaked.add(decayThisUpdate);
            decayMultiplier = stakingInfo.decayMultiplier.mul(totalStakedNew).div(totalStaked);
        }

        return user.startAmount.mulDiv(decayMultiplier, user.startDecayMultiplier);
    }

    /// @inheritdoc IAntePool
    function getPendingWithdrawAmount(address _user) external view override returns (uint256) {
        return withdrawInfo.userUnstakeInfo[_user].amount;
    }

    /// @inheritdoc IAntePool
    function getPendingWithdrawAllowedTime(address _user) external view override returns (uint256) {
        UserUnstakeInfo storage user = withdrawInfo.userUnstakeInfo[_user];
        require(user.amount > 0, "ANTE: nothing to withdraw");

        return user.lastUnstakeTimestamp.add(UNSTAKE_DELAY);
    }

    /// @inheritdoc IAntePool
    function getCheckTestAllowedBlock(address _user) external view override returns (uint256) {
        return eligibilityInfo.lastStakedBlock[_user].add(CHALLENGER_BLOCK_DELAY);
    }

    /// @inheritdoc IAntePool
    function getUserStartAmount(address _user, bool isChallenger) external view override returns (uint256) {
        return isChallenger ? challengerInfo.userInfo[_user].startAmount : stakingInfo.userInfo[_user].startAmount;
    }

    /// @inheritdoc IAntePool
    function getVerifierBounty() public view override returns (uint256) {
        uint256 totalStake = stakingInfo.totalAmount.add(withdrawInfo.totalAmount);
        return totalStake.mul(VERIFIER_BOUNTY).div(100);
    }

    /*****************************************************
     * =============== INTERNAL HELPERS ================ *
     *****************************************************/

    /// @notice Internal function activating the unstaking action for staker or challengers
    /// @param amount Amount to be removed in wei
    /// @param isChallenger True if user is a challenger
    /// @param side Corresponding staker or challenger pool info
    /// @param user Info related to the user
    /// @dev If the user is a challenger the function the amount can be withdrawn
    /// immediately, if the user is a staker, the amount is moved to the withdraw
    /// info and then the 24 hour waiting period starts
    function _unstake(
        uint256 amount,
        bool isChallenger,
        PoolSideInfo storage side,
        UserInfo storage user
    ) internal {
        // Calculate how much the user has available to unstake, including the
        // effects of any previously accrued decay.
        //   prevAmount = startAmount * decayMultiplier / startDecayMultiplier
        uint256 prevAmount = _storedBalance(user, side);

        if (prevAmount == amount) {
            user.startAmount = 0;
            user.startDecayMultiplier = 0;
            side.numUsers = side.numUsers.sub(1);

            // Remove from set of existing challengers
            if (isChallenger) challengers.remove(msg.sender);
        } else {
            require(amount <= prevAmount, "ANTE: Withdraw request exceeds balance.");
            user.startAmount = prevAmount.sub(amount);
            // Reset the startDecayMultiplier for this user, since we've updated
            // the startAmount to include any already-accrued decay.
            user.startDecayMultiplier = side.decayMultiplier;
        }
        side.totalAmount = side.totalAmount.sub(amount);

        if (isChallenger) _safeTransfer(msg.sender, amount);
        else {
            // Just initiate the withdraw if staker
            UserUnstakeInfo storage unstakeUser = withdrawInfo.userUnstakeInfo[msg.sender];
            unstakeUser.lastUnstakeTimestamp = block.timestamp;
            unstakeUser.amount = unstakeUser.amount.add(amount);

            withdrawInfo.totalAmount = withdrawInfo.totalAmount.add(amount);
        }

        emit Unstake(msg.sender, amount, isChallenger);
    }

    /// @notice Computes the decay differences for staker and challenger pools
    /// @dev Function shared by getStoredBalance view function and internal
    /// decay computation
    /// @return decayMultiplierThisUpdate multiplier factor for this decay change
    /// @return decayThisUpdate amount of challenger value that's decayed in wei
    function _computeDecay() internal view returns (uint256 decayMultiplierThisUpdate, uint256 decayThisUpdate) {
        decayThisUpdate = 0;
        decayMultiplierThisUpdate = ONE;

        if (block.number <= lastUpdateBlock) {
            return (decayMultiplierThisUpdate, decayThisUpdate);
        }
        // Stop charging decay if the test already failed.
        if (pendingFailure) {
            return (decayMultiplierThisUpdate, decayThisUpdate);
        }
        // If we have no stakers or challengers, don't charge any decay.
        uint256 totalStaked = stakingInfo.totalAmount;
        uint256 totalChallengerStaked = challengerInfo.totalAmount;
        if (totalStaked == 0 || totalChallengerStaked == 0) {
            return (decayMultiplierThisUpdate, decayThisUpdate);
        }

        uint256 numBlocks = block.number.sub(lastUpdateBlock);

        // The rest of the function updates the new accrued decay amounts
        //   decayRateThisUpdate = DECAY_RATE_PER_BLOCK * numBlocks
        //   decayMultiplierThisUpdate = 1 - decayRateThisUpdate
        //   decayThisUpdate = totalChallengerStaked * decayRateThisUpdate
        uint256 decayRateThisUpdate = DECAY_RATE_PER_BLOCK.mul(numBlocks);

        // Failsafe to avoid underflow when calculating decayMultiplierThisUpdate
        if (decayRateThisUpdate >= ONE) {
            decayMultiplierThisUpdate = 0;
            decayThisUpdate = totalChallengerStaked;
        } else {
            decayMultiplierThisUpdate = ONE.sub(decayRateThisUpdate);
            decayThisUpdate = totalChallengerStaked.mulDiv(decayRateThisUpdate, ONE);
        }
    }

    /// @notice Calculates total amount of challenger capital eligible for payout.
    /// @dev Any challenger which stakes within 12 blocks prior to test failure
    /// will not get a payout but will be able to withdraw their capital
    /// (minus decay)
    function _calculateChallengerEligibility() internal {
        uint256 cutoffBlock = failedBlock.sub(CHALLENGER_BLOCK_DELAY);
        for (uint256 i = 0; i < challengers.addresses.length; i++) {
            address challenger = challengers.addresses[i];
            if (eligibilityInfo.lastStakedBlock[challenger] < cutoffBlock) {
                eligibilityInfo.eligibleAmount = eligibilityInfo.eligibleAmount.add(
                    _storedBalance(challengerInfo.userInfo[challenger], challengerInfo)
                );
            }
        }
    }

    /// @notice Checks the connected Ante Test, also returns false if checkTestPasses reverts
    /// @return passes bool if the Ante Test passed
    function _checkTestNoRevert() internal returns (bool) {
        try anteTest.checkTestPasses() returns (bool passes) {
            return passes;
        } catch {
            return false;
        }
    }

    /// @notice Calculates individual challenger payout
    /// @param user UserInfo for specified challenger
    /// @param challenger Address of challenger
    /// @dev This is only called after a test is failed, so it's calculated payouts
    /// are no longer estimates
    /// @return Payout amount for challenger in wei
    function _calculateChallengerPayout(UserInfo storage user, address challenger) internal view returns (uint256) {
        // Calculate this user's challenging balance.
        uint256 amount = _storedBalance(user, challengerInfo);
        // Calculate how much of the staking pool this user gets, and add that
        // to the user's challenging balance.
        if (eligibilityInfo.lastStakedBlock[challenger] < failedBlock.sub(CHALLENGER_BLOCK_DELAY)) {
            amount = amount.add(amount.mulDiv(_remainingStake, eligibilityInfo.eligibleAmount));
        }

        return challenger == verifier ? amount.add(_bounty) : amount;
    }

    /// @notice Get the stored balance held by user, including accrued decay
    /// @param user UserInfo of specified user
    /// @param side PoolSideInfo of where the user is located, either staker or challenger side
    /// @dev This includes accrued decay up to `lastUpdateBlock`
    /// @return Balance of the user in wei
    function _storedBalance(UserInfo storage user, PoolSideInfo storage side) internal view returns (uint256) {
        if (user.startAmount == 0) return 0;

        require(user.startDecayMultiplier > 0, "ANTE: Invalid startDecayMultiplier");
        return user.startAmount.mulDiv(side.decayMultiplier, user.startDecayMultiplier);
    }

    /// @notice Transfer function for moving funds
    /// @param to Address to transfer funds to
    /// @param amount Amount to be transferred in wei
    /// @dev Safe transfer function, just in case a rounding error causes the
    /// pool to not have enough ETH
    function _safeTransfer(address payable to, uint256 amount) internal {
        to.transfer(_min(amount, address(this).balance));
    }

    /// @notice Returns the minimum of 2 parameters
    /// @param a Value A
    /// @param b Value B
    /// @return Lower of a or b
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Checks if the test has not failed yet
    function _testNotFailed() internal {
        require(!pendingFailure, "ANTE: Test already failed.");
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.7.0;

/// @title The interface for the Ante V0.5 Ante Test
/// @notice The Ante V0.5 Ante Test wraps test logic for verifying fundamental invariants of a protocol
interface IAnteTest {
    /// @notice Returns the author of the Ante Test
    /// @dev This overrides the auto-generated getter for testAuthor as a public var
    /// @return The address of the test author
    function testAuthor() external view returns (address);

    /// @notice Returns the name of the protocol the Ante Test is testing
    /// @dev This overrides the auto-generated getter for protocolName as a public var
    /// @return The name of the protocol in string format
    function protocolName() external view returns (string memory);

    /// @notice Returns a single address in the testedContracts array
    /// @dev This overrides the auto-generated getter for testedContracts [] as a public var
    /// @param i The array index of the address to return
    /// @return The address of the i-th element in the list of tested contracts
    function testedContracts(uint256 i) external view returns (address);

    /// @notice Returns the name of the Ante Test
    /// @dev This overrides the auto-generated getter for testName as a public var
    /// @return The name of the Ante Test in string format
    function testName() external view returns (string memory);

    /// @notice Function containing test logic to inspect the protocol invariant
    /// @dev This should usually return True
    /// @return A single bool indicating if the Ante Test passes/fails
    function checkTestPasses() external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.7.0;

/// @title The interface for the Ante V0.5 Ante Pool Factory
/// @notice The Ante V0.5 Ante Pool Factory programmatically generates an AntePool for a given AnteTest
interface IAntePoolFactory {
    /// @notice Emitted when an AntePool is created from an AnteTest
    /// @param testAddr The address of the AnteTest used to create the AntePool
    /// @param testPool The address of the AntePool created by the factory
    event AntePoolCreated(address indexed testAddr, address testPool);

    /// @notice Creates an AntePool for an AnteTest and returns the AntePool address
    /// @param testAddr The address of the AnteTest to create an AntePool for
    /// @return testPool - The address of the generated AntePool
    function createPool(address testAddr) external returns (address testPool);

    /// @notice Returns a single address in the allPools array
    /// @param i The array index of the address to return
    /// @return The address of the i-th AntePool created by this factory
    function allPools(uint256 i) external view returns (address);

    /// @notice Returns the address of the AntePool corresponding to a given AnteTest
    /// @param testAddr address of the AnteTest to look up
    /// @return The address of the corresponding AntePool
    function poolMap(address testAddr) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.7.0;

/// @notice Key sets for addresses with enumeration and delete. Uses mappings for random
/// and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced.
/// @dev IterableAddressSets are unordered. Delete operations reorder keys. All operations have a
/// fixed gas cost at any scale, O(1).
/// Code inspired by https://github.com/rob-Hitchens/SetTypes/blob/master/contracts/AddressSet.sol
/// and updated to solidity 0.7.x
library IterableAddressSetUtils {
    /// @dev struct stores array of addresses and mapping of addresses to indices to allow O(1) CRUD operations
    struct IterableAddressSet {
        mapping(address => uint256) indices;
        address[] addresses;
    }

    /// @notice insert a key.
    /// @dev duplicate keys are not permitted but fails silently to avoid wasting gas on exist + insert calls
    /// @param self storage pointer to IterableAddressSet
    /// @param key value to insert.
    function insert(IterableAddressSet storage self, address key) internal {
        if (!exists(self, key)) {
            self.addresses.push(key);
            self.indices[key] = self.addresses.length - 1;
        }
    }

    /// @notice remove a key.
    /// @dev key to remove should exist but fails silently to avoid wasting gas on exist + remove calls
    /// @param self storage pointer to IterableAddressSet
    /// @param key value to remove.
    function remove(IterableAddressSet storage self, address key) internal {
        if (!exists(self, key)) {
            return;
        }

        uint256 last = self.addresses.length - 1;
        uint256 indexToReplace = self.indices[key];
        if (indexToReplace != last) {
            address keyToMove = self.addresses[last];
            self.indices[keyToMove] = indexToReplace;
            self.addresses[indexToReplace] = keyToMove;
        }

        delete self.indices[key];
        self.addresses.pop();
    }

    /// @notice check if a key is in IterableAddressSet
    /// @param self storage pointer to IterableAddressSet
    /// @param key value to check.
    /// @return bool true: is a member, false: not a member.
    function exists(IterableAddressSet storage self, address key) internal view returns (bool) {
        if (self.addresses.length == 0) return false;

        return self.addresses[self.indices[key]] == key;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

// taken with <3 from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/FullMath.sol
// under the MIT license
/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an
/// intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division
/// where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256
    /// or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.7.0;

import "./IAnteTest.sol";

/// @title The interface for Ante V0.5 Ante Pool
/// @notice The Ante Pool handles interactions with connected Ante Test
interface IAntePool {
    /// @notice Emitted when a user adds to the stake or challenge pool
    /// @param staker The address of user
    /// @param amount Amount being added in wei
    /// @param isChallenger Whether or not this is added to the challenger pool
    event Stake(address indexed staker, uint256 amount, bool indexed isChallenger);

    /// @notice Emitted when a user removes from the stake or challenge pool
    /// @param staker The address of user
    /// @param amount Amount being removed in wei
    /// @param isChallenger Whether or not this is removed from the challenger pool
    event Unstake(address indexed staker, uint256 amount, bool indexed isChallenger);

    /// @notice Emitted when the connected Ante Test's invariant gets verified
    /// @param checker The address of challenger who called the verification
    event TestChecked(address indexed checker);

    /// @notice Emitted when the connected Ante Test has failed test verification
    /// @param checker The address of challenger who called the verification
    event FailureOccurred(address indexed checker);

    /// @notice Emitted when a challenger claims their payout for a failed test
    /// @param claimer The address of challenger claiming their payout
    /// @param amount Amount being claimed in wei
    event ClaimPaid(address indexed claimer, uint256 amount);

    /// @notice Emitted when a staker has withdrawn their stake after the 24 hour wait period
    /// @param staker The address of the staker removing their stake
    /// @param amount Amount withdrawn in wei
    event WithdrawStake(address indexed staker, uint256 amount);

    /// @notice Emitted when a staker cancels their withdraw action before the 24 hour wait period
    /// @param staker The address of the staker cancelling their withdraw
    /// @param amount Amount cancelled in wei
    event CancelWithdraw(address indexed staker, uint256 amount);

    /// @notice Initializes Ante Pool with the connected Ante Test
    /// @param _anteTest The Ante Test that will be connected to the Ante Pool
    /// @dev This function requires that the Ante Test address is valid and that
    /// the invariant validation currently passes
    function initialize(IAnteTest _anteTest) external;

    /// @notice Cancels a withdraw action of a staker before the 24 hour wait period expires
    /// @dev This is called when a staker has initiated a withdraw stake action but
    /// then decides to cancel that withdraw before the 24 hour wait period is over
    function cancelPendingWithdraw() external;

    /// @notice Runs the verification of the invariant of the connected Ante Test
    /// @dev Can only be called by a challenger who has challenged the Ante Test
    function checkTest() external;

    /// @notice Claims the payout of a failed Ante Test
    /// @dev To prevent double claiming, the challenger balance is checked before
    /// claiming and that balance is zeroed out once the claim is done
    function claim() external;

    /// @notice Adds a users's stake or challenge to the staker or challenger pool
    /// @param isChallenger Flag for if this is a challenger
    function stake(bool isChallenger) external payable;

    /// @notice Removes a user's stake or challenge from the staker or challenger pool
    /// @param amount Amount being removed in wei
    /// @param isChallenger Flag for if this is a challenger
    function unstake(uint256 amount, bool isChallenger) external;

    /// @notice Removes all of a user's stake or challenge from the respective pool
    /// @param isChallenger Flag for if this is a challenger
    function unstakeAll(bool isChallenger) external;

    /// @notice Updates the decay multipliers and amounts for the total staked and challenged pools
    /// @dev This function is called in most other functions as well to keep the
    /// decay amounts and pools accurate
    function updateDecay() external;

    /// @notice Initiates the withdraw process for a staker, starting the 24 hour waiting period
    /// @dev During the 24 hour waiting period, the value is locked to prevent
    /// users from removing their stake when a challenger is going to verify test
    function withdrawStake() external;

    /// @notice Returns the Ante Test connected to this Ante Pool
    /// @return IAnteTest The Ante Test interface
    function anteTest() external view returns (IAnteTest);

    /// @notice Get the info for the challenger pool
    /// @return numUsers The total number of challengers in the challenger pool
    ///         totalAmount The total value locked in the challenger pool in wei
    ///         decayMultiplier The current multiplier for decay
    function challengerInfo()
        external
        view
        returns (
            uint256 numUsers,
            uint256 totalAmount,
            uint256 decayMultiplier
        );

    /// @notice Get the info for the staker pool
    /// @return numUsers The total number of stakers in the staker pool
    ///         totalAmount The total value locked in the staker pool in wei
    ///         decayMultiplier The current multiplier for decay
    function stakingInfo()
        external
        view
        returns (
            uint256 numUsers,
            uint256 totalAmount,
            uint256 decayMultiplier
        );

    /// @notice Get the total value eligible for payout
    /// @dev This is used so that challengers must have challenged for at least
    /// 12 blocks to receive payout, this is to mitigate other challengers
    /// from trying to stick in a challenge right before the verification
    /// @return eligibleAmount Total value eligible for payout in wei
    function eligibilityInfo() external view returns (uint256 eligibleAmount);

    /// @notice Returns the Ante Pool factory address that created this Ante Pool
    /// @return Address of Ante Pool factory
    function factory() external view returns (address);

    /// @notice Returns the block at which the connected Ante Test failed
    /// @dev This is only set when a verify test action is taken, so the test could
    /// have logically failed beforehand, but without having a user initiating
    /// the verify test action
    /// @return Block number where Ante Test failed
    function failedBlock() external view returns (uint256);

    /// @notice Returns the payout amount for a specific challenger
    /// @param challenger Address of challenger
    /// @dev If this is called before an Ante Test has failed, then it's return
    /// value is an estimate
    /// @return Amount that could be claimed by challenger in wei
    function getChallengerPayout(address challenger) external view returns (uint256);

    /// @notice Returns the timestamp for when the staker's 24 hour wait period is over
    /// @param _user Address of withdrawing staker
    /// @dev This is timestamp is 24 hours after the time when the staker initaited the
    /// withdraw process
    /// @return Timestamp for when the value is no longer locked and can be removed
    function getPendingWithdrawAllowedTime(address _user) external view returns (uint256);

    /// @notice Returns the amount a staker is attempting to withdraw
    /// @param _user Address of withdrawing staker
    /// @return Amount which is being withdrawn in wei
    function getPendingWithdrawAmount(address _user) external view returns (uint256);

    /// @notice Returns the stored balance of a user in their respective pool
    /// @param _user Address of user
    /// @param isChallenger Flag if user is a challenger
    /// @dev This function calculates decay and returns the stored value after the
    /// decay has been either added (staker) or subtracted (challenger)
    /// @return Balance that the user has currently in wei
    function getStoredBalance(address _user, bool isChallenger) external view returns (uint256);

    /// @notice Returns total value of eligible payout for challengers
    /// @return Amount eligible for payout in wei
    function getTotalChallengerEligibleBalance() external view returns (uint256);

    /// @notice Returns total value locked of all challengers
    /// @return Total amount challenged in wei
    function getTotalChallengerStaked() external view returns (uint256);

    /// @notice Returns total value of all stakers who are withdrawing their stake
    /// @return Total amount waiting for withdraw in wei
    function getTotalPendingWithdraw() external view returns (uint256);

    /// @notice Returns total value locked of all stakers
    /// @return Total amount staked in wei
    function getTotalStaked() external view returns (uint256);

    /// @notice Returns a user's starting amount added in their respective pool
    /// @param _user Address of user
    /// @param isChallenger Flag if user is a challenger
    /// @dev This value is updated as decay is caluclated or additional value
    /// added to respective side
    /// @return User's starting amount in wei
    function getUserStartAmount(address _user, bool isChallenger) external view returns (uint256);

    /// @notice Returns the verifier bounty amount
    /// @dev Currently this is 5% of the total staked amount
    /// @return Bounty amount rewarded to challenger who verifies test in wei
    function getVerifierBounty() external view returns (uint256);

    /// @notice Returns the cutoff block when challenger can call verify test
    /// @dev This is currently 12 blocks after a challenger has challenged the test
    /// @return Block number of when verify test can be called by challenger
    function getCheckTestAllowedBlock(address _user) external view returns (uint256);

    /// @notice Returns the most recent block number where decay was updated
    /// @dev This is generally updated on most actions that interact with the Ante
    /// Pool contract
    /// @return Block number of when contract was last updated
    function lastUpdateBlock() external view returns (uint256);

    /// @notice Returns the most recent block number where a challenger verified test
    /// @dev This is updated whenever the verify test is activated, whether or not
    /// the Ante Test fails
    /// @return Block number of last verification attempt
    function lastVerifiedBlock() external view returns (uint256);

    /// @notice Returns the number of challengers that have claimed their payout
    /// @return Number of challengers
    function numPaidOut() external view returns (uint256);

    /// @notice Returns the number of times that the Ante Test has been verified
    /// @return Number of verifications
    function numTimesVerified() external view returns (uint256);

    /// @notice Returns if the connected Ante Test has failed
    /// @return True if the connected Ante Test has failed, False if not
    function pendingFailure() external view returns (bool);

    /// @notice Returns the total value of payout to challengers that have been claimed
    /// @return Value of claimed payouts in wei
    function totalPaidOut() external view returns (uint256);

    /// @notice Returns the address of verifier who successfully activated verify test
    /// @dev This is the user who will receive the verifier bounty
    /// @return Address of verifier challenger
    function verifier() external view returns (address);

    /// @notice Returns the total value of stakers who are withdrawing
    /// @return totalAmount total amount pending to be withdrawn in wei
    function withdrawInfo() external view returns (uint256 totalAmount);
}

