/**
 *Submitted for verification at snowtrace.io on 2021-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;


// File: contracts/Interfaces/ISortedTroves.sol


// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {

    // --- Events ---
    
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---
    
    function setParams(uint256 _size, address _TroveManagerAddress, address _borrowerOperationsAddress) external;

    function insert(address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
}

// File: contracts/Interfaces/IPriceFeed.sol





interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);
   
    // --- Function ---
    function fetchPrice() external returns (uint);
}

// File: contracts/Interfaces/ILiquityBase.sol







interface ILiquityBase {
    function priceFeed() external view returns (IPriceFeed);
}

// File: contracts/Interfaces/IPool.sol





// Common interface for the Pools.
interface IPool {
    
    // --- Events ---
    
    event CollTokenAddressChanged(address _newCollTokenAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event CollSurplusPoolAddressChanged(address _newCollSurplusPoolAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    
    event EtherSent(address _to, uint _amount);

    // --- Functions ---
    
    function getETH() external view returns (uint);
    function increaseColl(uint256 _amount) external;
}

// File: contracts/Interfaces/IStabilityPool.sol






/*
 * The Stability Pool holds LUSD tokens deposited by Stability Pool depositors.
 *
 * When a trove is liquidated, then depending on system conditions, some of its LUSD debt gets offset with
 * LUSD in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of LUSD tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a LUSD loss, in proportion to their deposit as a share of total deposits.
 * They also receive an ETH gain, as the ETH collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total LUSD in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ETH gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 * --- LQTY ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An LQTY issuance event occurs at every deposit operation, and every liquidation.
 *
 * Each deposit is tagged with the address of the front end through which it was made.
 *
 * All deposits earn a share of the issued LQTY in proportion to the deposit as a share of total deposits. The LQTY earned
 * by a given deposit, is split between the depositor and the front end through which the deposit was made, based on the front end's kickbackRate.
 *
 * Please see the system Readme for an overview:
 * https://github.com/liquity/dev/blob/main/README.md#lqty-issuance-to-stability-providers
 */
interface IStabilityPool is IPool {

    // --- Events ---
    
    event StabilityPoolETHBalanceUpdated(uint _newBalance);
    event StabilityPoolLUSDBalanceUpdated(uint _newBalance);

    event CollTokenAddressChanged(address _newCollTokenAddress);
    event LUSDTokenAddressChanged(address _newLUSDTokenAddress);
    event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event FrontEndRegistered(address indexed _frontEnd, uint _kickbackRate);
    event FrontEndTagSet(address indexed _depositor, address indexed _frontEnd);

    event DepositSnapshotUpdated(address indexed _depositor, uint _P, uint _S, uint _G);
    event FrontEndSnapshotUpdated(address indexed _frontEnd, uint _P, uint _G);
    event UserDepositChanged(address indexed _depositor, uint _newDeposit);
    event FrontEndStakeChanged(address indexed _frontEnd, uint _newFrontEndStake, address _depositor);

    event ETHGainWithdrawn(address indexed _depositor, uint _ETH, uint _LUSDLoss);
    event LQTYPaidToDepositor(address indexed _depositor, uint _LQTY);
    event LQTYPaidToFrontEnd(address indexed _frontEnd, uint _LQTY);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Liquity contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _collTokenAddress,
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _lusdTokenAddress,
        address _sortedTrovesAddress,
        address _priceFeedAddress,
        address _communityIssuanceAddress
    ) external;

    /*
     * Initial checks:
     * - Frontend is registered or zero address
     * - Sender is not a registered frontend
     * - _amount is not zero
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint _amount, address _frontEndTag) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint _amount) external;

    /*
     * Initial checks:
     * - User has a non zero deposit
     * - User has an open trove
     * - User has some ETH gain
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Sends all depositor's LQTY gain to  depositor
     * - Sends all tagged front end's LQTY gain to the tagged front end
     * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
     * - Leaves their compounded deposit in the Stability Pool
     * - Updates snapshots for deposit and tagged front end stake
     */
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;

    /*
     * Initial checks:
     * - Frontend (sender) not already registered
     * - User (sender) has no deposit
     * - _kickbackRate is in the range [0, 100%]
     * ---
     * Front end makes a one-time selection of kickback rate upon registering
     */
    function registerFrontEnd(uint _kickbackRate) external;

    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the LUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint _debt, uint _coll) external;

    /*
     * Returns LUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalLUSDDeposits() external view returns (uint);

    /*
     * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
     */
    function getDepositorETHGain(address _depositor) external view returns (uint);

    /*
     * Calculate the LQTY gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorLQTYGain(address _depositor) external view returns (uint);

    /*
     * Return the LQTY gain earned by the front end.
     */
    function getFrontEndLQTYGain(address _frontEnd) external view returns (uint);

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint);

    /*
     * Return the front end's compounded stake.
     *
     * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
     */
    function getCompoundedFrontEndStake(address _frontEnd) external view returns (uint);


    /*
     * Fallback function
     * Only callable by Active Pool, it just accounts for ETH received
     * receive() external payable;
     */
}

// File: contracts/Dependencies/IERC20.sol





/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

// File: contracts/Dependencies/IERC2612.sol





/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 * 
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}

// File: contracts/Interfaces/IUSDToken.sol







interface IUSDToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event TroveManagerAddressChanged(address _troveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

    event LUSDTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// File: contracts/Interfaces/IToken.sol







interface IToken is IERC20, IERC2612 { 

    // --- Functions ---
    
    function sendToTokenStaking(address _sender, uint256 _amount) external;

    function getDeploymentStartTime() external view returns (uint256);
}

// File: contracts/Interfaces/ITokenStaking.sol





interface ITokenStaking {

    // --- Events --
    
    event StakeTokenAddress(address stakeTokenAddress);
    
    event NewAssetTokenAddress(
        address trovemanager, address borrowerOperation, 
        address activePool, address redeemingFeeToken, address borrowingFeeToken
    );

    event StakeChanged(address indexed staker, uint newStake);
    event StakingGainsWithdrawn(address indexed staker, address indexed feeToken, uint gain);
    event totalTokenStakedUpdated(uint totalTokenStaked);
    event EtherSent(address account, uint amount);

    event TokenFeeUpdated(address indexed feeToken, uint fee, uint feePerTokenStaked);
    event StakerSnapshotsUpdated(address staker, address token, uint feePerTokenStaked);

    // --- Functions ---

    function setAddresses(address _stakeToken)  external ;

    function addNewAsset(
        address _borrowingFeeToken,
        address _redeemingFeeToken, 
        address _troveManager,
        address _borrowerOperation,
        address _activaPool
    ) external;

    function stake(uint _amount) external;

    function unstake(uint _amount) external ;

    function increaseBorrowingFee(uint _fee) external; 

    function increaseRedeemingFee(uint _fee) external;  

    function increaseTransferFee(uint _fee) external;  

    function getPendingGain(address _token, address _user) external view returns (uint);
}

// File: contracts/Interfaces/ITroveManager.sol











// Common interface for the Trove Manager.
interface ITroveManager is ILiquityBase {

    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event CollAddressChanged(address _newCollTokenAddress);
    event LUSDTokenAddressChanged(address _newLUSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event LQTYTokenAddressChanged(address _lqtyTokenAddress);
    event LQTYStakingAddressChanged(address _lqtyStakingAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _LUSDGasCompensation);
    event Redemption(uint _attemptedLUSDAmount, uint _actualLUSDAmount, uint _tokenSent, uint _tokenFee);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_TOKEN, uint _L_LUSDDebt);
    event TroveSnapshotsUpdated(uint _L_TOKEN, uint _L_LUSDDebt);
    event TroveIndexUpdated(address _borrower, uint _newIndex);

    // --- Functions ---
    
    function setAddresses(
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _lusdTokenAddress,
        address _sortedTrovesAddress,
        address _lqtyTokenAddress,
        address _lqtyStakingAddress
    ) external;

    function stabilityPool() external view returns (IStabilityPool);
    function lusdToken() external view returns (IUSDToken);
    function lqtyToken() external view returns (IToken);
    function lqtyStaking() external view returns (ITokenStaking);

    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);
    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function liquidate(address _borrower) external;

    function liquidateTroves(uint _n) external;

    function batchLiquidateTroves(address[] calldata _troveArray) external;

    function redeemCollateral(
        uint _LUSDAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFee
    ) external;

    function getPendingETHReward(address _borrower) external view returns (uint);

    function updateStakeAndTotalStakes(address _borrower) external returns (uint);

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower) external returns (uint index);

    function applyPendingRewards(address _borrower) external;

    // function getPendingTokenReward(address _borrower) external view returns (uint);

    function getPendingLUSDDebtReward(address _borrower) external view returns (uint);

     function hasPendingRewards(address _borrower) external view returns (bool);

    function getEntireDebtAndColl(address _borrower) external view returns (
        uint debt,
        uint coll,
        uint pendingLUSDDebtReward,
        uint pendingTokenReward
    );

    function closeTrove(address _borrower) external;

    function removeStake(address _borrower) external;

    function getRedemptionRate() external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _tokenDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint LUSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _LUSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getTroveStatus(address _borrower) external view returns (uint);

    function getTroveStake(address _borrower) external view returns (uint);

    function getTroveDebt(address _borrower) external view returns (uint);

    function getTroveColl(address _borrower) external view returns (uint);

    function setTroveStatus(address _borrower, uint num) external;

    function increaseTroveColl(address _borrower, uint _collIncrease) external returns (uint);

    function decreaseTroveColl(address _borrower, uint _collDecrease) external returns (uint);

    function increaseTroveDebt(address _borrower, uint _debtIncrease) external returns (uint);

    function decreaseTroveDebt(address _borrower, uint _collDecrease) external returns (uint);

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);
}

// File: contracts/Interfaces/IBorrowerOperations.sol





// Common interface for the Trove Manager.
interface IBorrowerOperations {

    // --- Events ---

    event CollTokenAddressChanged(address _newCollTokenAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event LUSDTokenAddressChanged(address _lusdTokenAddress);
    event LQTYStakingAddressChanged(address _lqtyStakingAddress);

    event TroveCreated(address indexed _borrower, uint arrayIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event LUSDBorrowingFeePaid(address indexed _borrower, uint _LUSDFee);

    // --- Functions ---

    function setAddresses(
        address _collTokenAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _sortedTrovesAddress,
        address _lusdTokenAddress,
        address _lqtyStakingAddress
    ) external;

    function openTrove(uint _collAmount, uint _maxFee, uint _LUSDAmount, address _upperHint, address _lowerHint) external payable;

    function addColl(uint _collAmount, address _upperHint, address _lowerHint) external payable;

    function moveETHGainToTrove(uint _collAmount, address _user, address _upperHint, address _lowerHint) external payable;

    function withdrawColl(uint _amount, address _upperHint, address _lowerHint) external;

    function withdrawLUSD(uint _maxFee, uint _amount, address _upperHint, address _lowerHint) external;

    function repayLUSD(uint _amount, address _upperHint, address _lowerHint) external;

    function closeTrove() external;

    function adjustTrove(uint _collAmount, uint _maxFee, uint _collWithdrawal, uint _debtChange, bool isDebtIncrease, address _upperHint, address _lowerHint) external payable;

    function claimCollateral() external;

    function getCompositeDebt(uint _debt) external pure returns (uint);
}

// File: contracts/Dependencies/SafeMath.sol





/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/Dependencies/upgradeable/AddressUpgradeable.sol





/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// File: contracts/Dependencies/upgradeable/Initializable.sol



// solhint-disable-next-line compiler-version



/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool public initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: contracts/protocol/SortedTroves.sol










/*
* A sorted doubly linked list with nodes sorted in descending order.
*
* Nodes map to active Troves in the system - the ID property is the address of a Trove owner.
* Nodes are ordered according to their current nominal individual collateral ratio (NICR),
* which is like the ICR but without the price, i.e., just collateral / debt.
*
* The list optionally accepts insert position hints.
*
* NICRs are computed dynamically at runtime, and not stored on the Node. This is because NICRs of active Troves
* change dynamically as liquidation events occur.
*
* The list relies on the fact that liquidation events preserve ordering: a liquidation decreases the NICRs of all active Troves,
* but maintains their order. A node inserted based on current NICR will maintain the correct position,
* relative to it's peers, as rewards accumulate, as long as it's raw collateral and debt have not changed.
* Thus, Nodes remain sorted by current NICR.
*
* Nodes need only be re-inserted upon a Trove operation - when the owner adds or removes collateral or debt
* to their position.
*
* The list is a modification of the following audited SortedDoublyLinkedList:
* https://github.com/livepeer/protocol/blob/master/contracts/libraries/SortedDoublyLL.sol
*
*
* Changes made in the Liquity implementation:
*
* - Keys have been removed from nodes
*
* - Ordering checks for insertion are performed by comparing an NICR argument to the current NICR, calculated at runtime.
*   The list relies on the property that ordering by ICR is maintained as the ETH:USD price varies.
*
* - Public functions with parameters have been made internal to save gas, and given an external wrapper function for external access
*/
contract SortedTroves is ISortedTroves, Initializable{
    using SafeMath for uint256;

    string constant public NAME = "SortedTroves";

    address public borrowerOperationsAddress;

    ITroveManager public troveManager;

    // Information for a node in the list
    struct Node {
        bool exists;
        address nextId;                  // Id of next node (smaller NICR) in the list
        address prevId;                  // Id of previous node (larger NICR) in the list
    }

    // Information for the list
    struct Data {
        address head;                        // Head of the list. Also the node in the list with the largest NICR
        address tail;                        // Tail of the list. Also the node in the list with the smallest NICR
        uint256 maxSize;                     // Maximum size of the list
        uint256 size;                        // Current size of the list
        mapping (address => Node) nodes;     // Track the corresponding ids for each node in the list
    }

    Data public data;

    // --- Dependency setters ---

    function setParams(uint256 _size, address _troveManagerAddress, address _borrowerOperationsAddress) external override initializer {
        require(_size > 0, "SortedTroves: Size can’t be zero");

        data.maxSize = _size;

        troveManager = ITroveManager(_troveManagerAddress);
        borrowerOperationsAddress = _borrowerOperationsAddress;

        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);

    }

    /*
     * @dev Add a node to the list
     * @param _id Node's id
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */

    function insert(address _id, uint256 _NICR, address _prevId, address _nextId) external override {
        ITroveManager troveManagerCached = troveManager;

        _requireCallerIsBOorTroveM(troveManagerCached);
        _insert(troveManagerCached, _id, _NICR, _prevId, _nextId);
    }

    function _insert(ITroveManager _troveManager, address _id, uint256 _NICR, address _prevId, address _nextId) internal {
        // List must not be full
        require(!isFull(), "SortedTroves: List is full");
        // List must not already contain node
        require(!contains(_id), "SortedTroves: List already contains the node");
        // Node id must not be null
        require(_id != address(0), "SortedTroves: Id cannot be zero");
        // NICR must be non-zero
        require(_NICR > 0, "SortedTroves: NICR must be positive");

        address prevId = _prevId;
        address nextId = _nextId;

        if (!_validInsertPosition(_troveManager, _NICR, prevId, nextId)) {
            // Sender's hint was not a valid insert position
            // Use sender's hint to find a valid insert position
            (prevId, nextId) = _findInsertPosition(_troveManager, _NICR, prevId, nextId);
        }

        data.nodes[_id].exists = true;

        if (prevId == address(0) && nextId == address(0)) {
            // Insert as head and tail
            data.head = _id;
            data.tail = _id;
        } else if (prevId == address(0)) {
            // Insert before `prevId` as the head
            data.nodes[_id].nextId = data.head;
            data.nodes[data.head].prevId = _id;
            data.head = _id;
        } else if (nextId == address(0)) {
            // Insert after `nextId` as the tail
            data.nodes[_id].prevId = data.tail;
            data.nodes[data.tail].nextId = _id;
            data.tail = _id;
        } else {
            // Insert at insert position between `prevId` and `nextId`
            data.nodes[_id].nextId = nextId;
            data.nodes[_id].prevId = prevId;
            data.nodes[prevId].nextId = _id;
            data.nodes[nextId].prevId = _id;
        }

        data.size = data.size.add(1);
        emit NodeAdded(_id, _NICR);
    }

    function remove(address _id) external override {
        _requireCallerIsTroveManager();
        _remove(_id);
    }

    /*
     * @dev Remove a node from the list
     * @param _id Node's id
     */
    function _remove(address _id) internal {
        // List must contain the node
        require(contains(_id), "SortedTroves: List does not contain the id");

        if (data.size > 1) {
            // List contains more than a single node
            if (_id == data.head) {
                // The removed node is the head
                // Set head to next node
                data.head = data.nodes[_id].nextId;
                // Set prev pointer of new head to null
                data.nodes[data.head].prevId = address(0);
            } else if (_id == data.tail) {
                // The removed node is the tail
                // Set tail to previous node
                data.tail = data.nodes[_id].prevId;
                // Set next pointer of new tail to null
                data.nodes[data.tail].nextId = address(0);
            } else {
                // The removed node is neither the head nor the tail
                // Set next pointer of previous node to the next node
                data.nodes[data.nodes[_id].prevId].nextId = data.nodes[_id].nextId;
                // Set prev pointer of next node to the previous node
                data.nodes[data.nodes[_id].nextId].prevId = data.nodes[_id].prevId;
            }
        } else {
            // List contains a single node
            // Set the head and tail to null
            data.head = address(0);
            data.tail = address(0);
        }

        delete data.nodes[_id];
        data.size = data.size.sub(1);
        NodeRemoved(_id);
    }

    /*
     * @dev Re-insert the node at a new position, based on its new NICR
     * @param _id Node's id
     * @param _newNICR Node's new NICR
     * @param _prevId Id of previous node for the new insert position
     * @param _nextId Id of next node for the new insert position
     */
    function reInsert(address _id, uint256 _newNICR, address _prevId, address _nextId) external override {
        ITroveManager troveManagerCached = troveManager;

        _requireCallerIsBOorTroveM(troveManagerCached);
        // List must contain the node
        require(contains(_id), "SortedTroves: List does not contain the id");
        // NICR must be non-zero
        require(_newNICR > 0, "SortedTroves: NICR must be positive");

        // Remove node from the list
        _remove(_id);

        _insert(troveManagerCached, _id, _newNICR, _prevId, _nextId);
    }

    /*
     * @dev Checks if the list contains a node
     */
    function contains(address _id) public view override returns (bool) {
        return data.nodes[_id].exists;
    }

    /*
     * @dev Checks if the list is full
     */
    function isFull() public view override returns (bool) {
        return data.size == data.maxSize;
    }

    /*
     * @dev Checks if the list is empty
     */
    function isEmpty() public view override returns (bool) {
        return data.size == 0;
    }

    /*
     * @dev Returns the current size of the list
     */
    function getSize() external view override returns (uint256) {
        return data.size;
    }

    /*
     * @dev Returns the maximum size of the list
     */
    function getMaxSize() external view override returns (uint256) {
        return data.maxSize;
    }

    /*
     * @dev Returns the first node in the list (node with the largest NICR)
     */
    function getFirst() external view override returns (address) {
        return data.head;
    }

    /*
     * @dev Returns the last node in the list (node with the smallest NICR)
     */
    function getLast() external view override returns (address) {
        return data.tail;
    }

    /*
     * @dev Returns the next node (with a smaller NICR) in the list for a given node
     * @param _id Node's id
     */
    function getNext(address _id) external view override returns (address) {
        return data.nodes[_id].nextId;
    }

    /*
     * @dev Returns the previous node (with a larger NICR) in the list for a given node
     * @param _id Node's id
     */
    function getPrev(address _id) external view override returns (address) {
        return data.nodes[_id].prevId;
    }

    /*
     * @dev Check if a pair of nodes is a valid insertion point for a new node with the given NICR
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function validInsertPosition(uint256 _NICR, address _prevId, address _nextId) external view override returns (bool) {
        return _validInsertPosition(troveManager, _NICR, _prevId, _nextId);
    }

    function _validInsertPosition(ITroveManager _troveManager, uint256 _NICR, address _prevId, address _nextId) internal view returns (bool) {
        if (_prevId == address(0) && _nextId == address(0)) {
            // `(null, null)` is a valid insert position if the list is empty
            return isEmpty();
        } else if (_prevId == address(0)) {
            // `(null, _nextId)` is a valid insert position if `_nextId` is the head of the list
            return data.head == _nextId && _NICR >= _troveManager.getNominalICR(_nextId);
        } else if (_nextId == address(0)) {
            // `(_prevId, null)` is a valid insert position if `_prevId` is the tail of the list
            return data.tail == _prevId && _NICR <= _troveManager.getNominalICR(_prevId);
        } else {
            // `(_prevId, _nextId)` is a valid insert position if they are adjacent nodes and `_NICR` falls between the two nodes' NICRs
            return data.nodes[_prevId].nextId == _nextId &&
                   _troveManager.getNominalICR(_prevId) >= _NICR &&
                   _NICR >= _troveManager.getNominalICR(_nextId);
        }
    }

    /*
     * @dev Descend the list (larger NICRs to smaller NICRs) to find a valid insert position
     * @param _troveManager TroveManager contract, passed in as param to save SLOAD’s
     * @param _NICR Node's NICR
     * @param _startId Id of node to start descending the list from
     */
    function _descendList(ITroveManager _troveManager, uint256 _NICR, address _startId) internal view returns (address, address) {
        // If `_startId` is the head, check if the insert position is before the head
        if (data.head == _startId && _NICR >= _troveManager.getNominalICR(_startId)) {
            return (address(0), _startId);
        }

        address prevId = _startId;
        address nextId = data.nodes[prevId].nextId;

        // Descend the list until we reach the end or until we find a valid insert position
        while (prevId != address(0) && !_validInsertPosition(_troveManager, _NICR, prevId, nextId)) {
            prevId = data.nodes[prevId].nextId;
            nextId = data.nodes[prevId].nextId;
        }

        return (prevId, nextId);
    }

    /*
     * @dev Ascend the list (smaller NICRs to larger NICRs) to find a valid insert position
     * @param _troveManager TroveManager contract, passed in as param to save SLOAD’s
     * @param _NICR Node's NICR
     * @param _startId Id of node to start ascending the list from
     */
    function _ascendList(ITroveManager _troveManager, uint256 _NICR, address _startId) internal view returns (address, address) {
        // If `_startId` is the tail, check if the insert position is after the tail
        if (data.tail == _startId && _NICR <= _troveManager.getNominalICR(_startId)) {
            return (_startId, address(0));
        }

        address nextId = _startId;
        address prevId = data.nodes[nextId].prevId;

        // Ascend the list until we reach the end or until we find a valid insertion point
        while (nextId != address(0) && !_validInsertPosition(_troveManager, _NICR, prevId, nextId)) {
            nextId = data.nodes[nextId].prevId;
            prevId = data.nodes[nextId].prevId;
        }

        return (prevId, nextId);
    }

    /*
     * @dev Find the insert position for a new node with the given NICR
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function findInsertPosition(uint256 _NICR, address _prevId, address _nextId) external view override returns (address, address) {
        return _findInsertPosition(troveManager, _NICR, _prevId, _nextId);
    }

    function _findInsertPosition(ITroveManager _troveManager, uint256 _NICR, address _prevId, address _nextId) internal view returns (address, address) {
        address prevId = _prevId;
        address nextId = _nextId;

        if (prevId != address(0)) {
            if (!contains(prevId) || _NICR > _troveManager.getNominalICR(prevId)) {
                // `prevId` does not exist anymore or now has a smaller NICR than the given NICR
                prevId = address(0);
            }
        }

        if (nextId != address(0)) {
            if (!contains(nextId) || _NICR < _troveManager.getNominalICR(nextId)) {
                // `nextId` does not exist anymore or now has a larger NICR than the given NICR
                nextId = address(0);
            }
        }

        if (prevId == address(0) && nextId == address(0)) {
            // No hint - descend list starting from head
            return _descendList(_troveManager, _NICR, data.head);
        } else if (prevId == address(0)) {
            // No `prevId` for hint - ascend list starting from `nextId`
            return _ascendList(_troveManager, _NICR, nextId);
        } else if (nextId == address(0)) {
            // No `nextId` for hint - descend list starting from `prevId`
            return _descendList(_troveManager, _NICR, prevId);
        } else {
            // Descend list starting from `prevId`
            return _descendList(_troveManager, _NICR, prevId);
        }
    }

    // --- 'require' functions ---

    function _requireCallerIsTroveManager() internal view {
        require(msg.sender == address(troveManager), "SortedTroves: Caller is not the TroveManager");
    }

    function _requireCallerIsBOorTroveM(ITroveManager _troveManager) internal view {
        require(msg.sender == borrowerOperationsAddress || msg.sender == address(_troveManager),
                "SortedTroves: Caller is neither BO nor TroveM");
    }
}