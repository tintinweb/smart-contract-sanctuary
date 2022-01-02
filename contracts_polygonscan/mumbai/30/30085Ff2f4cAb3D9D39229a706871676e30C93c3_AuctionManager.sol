// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IDaoManager.sol";

import "./libraries/Config.sol";
import "./libraries/Fixed.sol";
import "./libraries/Formula.sol";

import "./MirrorPool.sol";
import "./TreasuryManager.sol";

/// @title AuctionManager manage auction and token, cash flow
/// @notice It connect to different components to transfer token, cash. User interact directly with AuctionManager to bid the token sales
contract AuctionManager {
    using FixedMath for Fixed;

    IERC20          public immutable cash; // Should be ERC20
    IERC20          public immutable token; // Should be ERC20
    TreasuryManager public immutable treasury;

    IDaoManager public dao;

    /// @title  AuctionData hold the balance sheet for the auction of one day (round)
    /// @notice Basically it holds total bid cash amount, total token amount ( if auction has succeed), and track bid amount for each users
    /// @dev    totalToken equal to zero is equivalent to the failure of the auction
    struct AuctionData {
        uint256 totalCash;
        uint256 totalToken;
        mapping(address => uint256) accumulatedDeposits;
    }

    /// @notice This struct contains personal data of a depositor who has participated in any auctions
    struct Depositor {
        /**
         *  @notice The index of auction data block corresponding to the last time the depositor deposited but its
         *          tokens haven't been updated to the accumulated token amount of the depositor
         *  @dev    If all tokens belongs to the depositor are updated then the value of lastDeposit will be 0.
         */
        uint256 lastDeposit;

        /**
         *  @notice The total accumulated token amount that the depositor possessed from succeeded auctions they joined
         *  @dev    This value maybe lack of the amount from the last deposited auction, should be corrected in each
         *          transactions.
         */
        uint256 token;
    }

    /// @dev Id of auction data block
    uint256 public currentDataBlockId = 1;

    uint256 public floorDeposit = Constant.AUCTION_DEFAULT_FLOOR_DEPOSIT;
    uint256 public capDeposit = Constant.AUCTION_DEFAULT_CAP_DEPOSIT;

    mapping(uint256 => mapping(address => uint256)) public separatedDeposits;

    mapping(uint256 => uint256) public idMapping;
    mapping(uint256 => AuctionData) public dataBlocks;

    mapping(address => Depositor) public depositors;

    event DaoManagerRegistration(address indexed account);
    event CashDeposit(address indexed account, uint256 auctionId, uint256 amount);
    event TokenWithdrawal(address indexed account, uint256 amount);
    event CashWithdrawal(address indexed account, uint256 amount);
    event AuctionIdIncrement(uint256 auctionId, uint256 floorDeposit, uint256 capDeposit);

    /// @notice AuctionManager constructs on top of CASH token and TreasuryManager
    /// @param  _cash     Address of deployed CASH token
    /// @param  _treasury Address of deployed TreasuryManager
    constructor(IERC20 _cash, TreasuryManager _treasury) public {
        cash = _cash;
        treasury = _treasury;
        token = _treasury.token();
        treasury.registerAuctionManager();

        floorDeposit = 1;
        capDeposit = Constant.AUCTION_DEFAULT_CAP_DEPOSIT;
    }

    modifier permittedTo(address _account) {
        require(msg.sender == _account, "Unauthorized.");
        _;
    }

    function currentTotalDeposit() public view returns (uint256) {
        return dataBlocks[currentDataBlockId].totalCash;
    }

    /// @notice Register DaoManager to allow it order methods of this contract
    /// @dev    Register can only be called once
    function registerDaoManager() external {
        require(address(dao) == address(0), "DaoManager has been registered");
        dao = IDaoManager(msg.sender);
        emit DaoManagerRegistration(address(dao));
    }

    /**
     *  @notice The token a depositor possessed from a specific auction
     *  @param  _dataBlockId    Index of the data block corresponding to a succeeded auction
     *  @param  _account        Address of the depositor
     */
    function tokenOfAuction(uint256 _dataBlockId, address _account) internal view returns (uint256) {
        require(0 < _dataBlockId && _dataBlockId < currentDataBlockId, "Invalid data block index");
        AuctionData storage dataBlock = dataBlocks[_dataBlockId];
        uint256 cashAmount = dataBlock.accumulatedDeposits[_account];
        /// @dev    tokenAmount = auctionTotalToken * depositedCash / auctionTotalCash
        uint256 tokenAmount = Formula.portion(cashAmount, dataBlock.totalCash, dataBlock.totalToken);
        return tokenAmount;
    }

    /**
     *  @notice Update the token from the last deposited auction to the accumulated token amount of the depositor
     *  @dev    _isDepositing   The method is called during depositing or not
     */
    function updateLastDeposit(bool _isDepositing) internal {
        Depositor storage depositor = depositors[msg.sender];
        uint256 dataBlockId = depositor.lastDeposit;
        // If the method is called during depositing, lastDeposit should be assigned currentDataBlockId.
        // Or else, it should be cleared by assigning 0.
        depositor.lastDeposit = _isDepositing ? currentDataBlockId : 0;
        // Only update if the last depositing auction is before the current one.
        if (dataBlockId == currentDataBlockId || dataBlockId == 0) return;
        depositor.token += tokenOfAuction(dataBlockId, msg.sender);
    }

    /**
     *  @notice The token amount that the depositor possessed from succeeded auctions they joined
     *  @dev    In order to stay as a view, this method only calculate the correct token amount without update it.
     *  @param  _account        Address of the depositor
     */
    function withdrawableTokenAmount(address _account) external view returns (uint256) {
        Depositor storage depositor = depositors[_account];
        uint256 dataBlockId = depositor.lastDeposit;
        if (dataBlockId == currentDataBlockId || dataBlockId == 0) {
            return depositor.token;
        } else {
            // Only add the token from the last depositing auction if it is before the current one.
            return depositor.token + tokenOfAuction(dataBlockId, _account);
        }
    }

    /// @notice User deposit cash to bid the current auction
    /// @param _amount cash amount that user deposit to the auction
    /// @dev User have to call approve with enough amount before calling this deposit method
    function deposit(uint256 _amount) external {
        require(!dao.isBlockedForMigration(), "Migrated");
        require(!dao.emissionTerminated(), "Emission Terminated");

        require(_amount <= maxBiddableAmount(), "Deposit amount exceeds cap deposit");
        updateLastDeposit(true);

        // Transfer CASH from user to this contract balance
        cash.transferFrom(msg.sender, address(this), _amount);

        // Track user's cash in current auction balance sheet
        AuctionData storage data = dataBlocks[currentDataBlockId];
        data.accumulatedDeposits[msg.sender] += _amount;
        data.totalCash += _amount;
        separatedDeposits[dao.day()][msg.sender] += _amount;

        emit CashDeposit(msg.sender, dao.day(), _amount);
    }

    /// @notice isSuccess return the SUCCESS/FAILED of a specified auctionId in the pass
    /// @param _auctionId is the Id of the auction that users has deposit fund
    /// @dev    This method can be called by anyone
    function isSuccessful(uint256 _auctionId) public view returns (bool) {
        require(_auctionId < dao.day(), "The requested auction has not ended");
        return idMapping[_auctionId] > 0;
    }

    /// @notice Transfer all tokens of the depositor possessed to the personal address
    function withdrawToken() external {
        updateLastDeposit(false);
        uint256 tokenAmount = depositors[msg.sender].token;
        depositors[msg.sender].token = 0;
        token.transfer(msg.sender, tokenAmount);
        emit TokenWithdrawal(msg.sender, tokenAmount);
    }

    /**
     *  @notice Take back an amount of deposit forwarded from previous failed auctions
     *  @dev    _amount         Amount of cash wished to be taken back
     */
    function withdrawCash(uint256 _amount) external {
        require(
            _amount <= withdrawableCashAmount(msg.sender),
            "Can only withdraw no more than the deposit left from previous fail auctions"
        );
        cash.transfer(msg.sender, _amount);

        AuctionData storage dataBlock = dataBlocks[currentDataBlockId];
        /* solhint-disable */
        unchecked {
            dataBlock.accumulatedDeposits[msg.sender] -= _amount;
            dataBlock.totalCash -= _amount;
        }
        /* solhint-enable */
        emit CashWithdrawal(msg.sender, _amount);
    }

    /// @notice status return the SUCCESS/FAILED status of the current auction
    /// @dev    MAKE SURE this function should never throw error, i.e it should always return true or false
    ///         IF not the DaoManager can be attacked
    function status() external permittedTo(address(dao)) view returns (bool) {
        return (dataBlocks[currentDataBlockId].totalCash >= floorDeposit);
    }

    /// @notice fetchToken fetch tokens being minted and approved by DaoManager and conclude the auction
    /// @dev    This method is only callable by DaoManager
    /// @param  _amount amount of 420D tokens to be pulled
    function fetchToken(uint256 _amount) external permittedTo(address(dao)) {
        // Fetch the tokens minted and approved by DaoManager, register the token balance sheet
        token.transferFrom(address(dao), address(this), _amount);
        dataBlocks[currentDataBlockId].totalToken = _amount;

        // approve the cash of the auction to treasury and order treasury to fetch it
        uint256 cashAmount = dataBlocks[currentDataBlockId].totalCash;
        cash.approve(address(treasury), cashAmount);
        treasury.fetchCash(cashAmount);

        idMapping[dao.day()] = currentDataBlockId;
        currentDataBlockId++;
    }

    /// @notice Update the information of cap and floor price for the current opening auction
    /// @dev    This method is only callable by DaoManager
    function updateAuctionInfo(
        uint256 _incomingAuctionEmission,
        uint256 _incomingStakingReward
    ) external permittedTo(address(dao)) {

        uint256 totalAsset = treasury.totalAsset();
        uint256 totalSupply = token.totalSupply();

        if (totalAsset == 0 || totalSupply == 0) {
            floorDeposit = Constant.AUCTION_DEFAULT_FLOOR_DEPOSIT;
            capDeposit = Constant.AUCTION_DEFAULT_CAP_DEPOSIT;
        } else {
            Fixed memory tokenIntrinsicPrice = Formula.tokenIntrinsicPrice(
                totalAsset,
                totalSupply,
                _incomingStakingReward
            );

            uint256 treasuryPercentage = Constant.TREASURY_PERCENTAGE_INSURANCE + Constant.TREASURY_PERCENTAGE_ASSET;

            floorDeposit = Formula.floorDeposit(
                tokenIntrinsicPrice,
                _incomingAuctionEmission,
                treasuryPercentage
            );

            capDeposit = Formula.capDeposit(
                tokenIntrinsicPrice,
                _incomingAuctionEmission,
                totalAsset,
                treasuryPercentage
            );
        }

        emit AuctionIdIncrement(dao.day(), floorDeposit, capDeposit);
    }

    /// @notice maxBiddableAmount deposit amount that user can deposit for bidding auction
    /// @dev    MAKE SURE this function should never throw error, i.e it should always return exact result
    ///         IF not the AuctionManager can be attacked
    function maxBiddableAmount() public view returns (uint256) {
        return capDeposit - dataBlocks[currentDataBlockId].totalCash;
    }

    /// @notice withdrawCashAmount amount of cash that user can withdraw from failed auction
    /// @param  _account address of the person who want withdraw cash
    /// @dev    MAKE SURE this function should never throw error, i.e it should always return exact result
    ///         IF not the AuctionManager can be attacked
    function withdrawableCashAmount(address _account) public view returns (uint256) {
        AuctionData storage dataBlock = dataBlocks[currentDataBlockId];
        return dataBlock.accumulatedDeposits[_account] - separatedDeposits[dao.day()][_account];
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
pragma solidity 0.8.9;

/**
 * @dev Interface of the DaoManager that will be commonly used by other smart contracts.
 *
 *      This interface help to get DAO's global information
 *        - admin of the entire DAO
 *        - current auction day
 *        - state of token's emission
 *        - migration status
 *
 *      When the token's total supply reach its maxium, the DAO should be in the state of
 *      terminating token emission. This is implemented through function emissionTerminated.
 *      When this happens, users can not deposit to the auction or to staking pool anymore
 *      because there will be no interest for them, as there are no new tokens to be minted
 *
 *      When the system wants to upgrate, there are two steps
 *        - First admin move the DAO to the preparation state, where it notifies the entire
 *          community this will be the last day running on this old system. At this state,
 *          the isGoingToMigrate() return true
 *        - After the first state has been set, when DAO move to the next day, that will be
 *          the last, and everything will be frozen on the old system. If users want to do
 *          anything, that will be done through the newly deployed system
 */
interface IDaoManager {
    /**
     * @dev Get DAO's admin address
     */
    function admin() external view returns (address);

    /**
     * @dev Get current auction day
     */
    function day() external view returns (uint256);

    /**
     * @dev Get token's emission status
     */
    function emissionTerminated() external view returns (bool);

    /**
     * @dev Dao is about to migrate. This state determine the last day just before being blocked for the migration
     */
    function isGoingToMigrate() external view returns (bool);

    /**
     * @dev Dao is blocked for migration
     */
    function isBlockedForMigration() external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title Constant library provides most of constants used in smart contracts among project
library Constant {
    uint8   internal constant TOKEN_DECIMALS = 18;
    uint256 internal constant TOKEN_SCALE    = 10**TOKEN_DECIMALS;
    uint256 internal constant TOKEN_MAX_SUPPLY_THRESHOLD = 420000000 * TOKEN_SCALE; // Max supply ~ 420 M
    uint8   internal constant EPSILON = 10;

    /// @notice In the Treasury, the tokens are split by percentages:
    ///     Asset Fund:     50%
    ///     Insurance Fund: 30%
    ///     Operation Fund: 20%
    uint256 internal constant TREASURY_PERCENTAGE_ASSET     = 50;
    uint256 internal constant TREASURY_PERCENTAGE_INSURANCE = 30;

    /// @notice In the Treasury, claiming is locked up to a certain timestamp
    ///     Max lock:     6 months
    uint256 internal constant TREASURY_MAX_LOCK = 15552000;

    /// @notice In the Mirror Pool, the tokens are split by percentages:
    ///     Development & Marketing: 30%
    ///     Early Supporters:        10%
    ///     Reservation:             60%
    uint256 internal constant MIRROR_PERCENTAGE_EARLY_SUPPORTERS = 10;
    uint256 internal constant MIRROR_PERCENTAGE_RESERVATION      = 60;

    /// TODO: write description
    uint256 internal constant STAKING_FEE_CONVERGENCE_DAY = 787;
    uint256 internal constant STAKING_FEE_BASE_PERCENTAGE = 42;

    uint256 internal constant AUCTION_DEFAULT_FLOOR_DEPOSIT = 1;
    uint256 internal constant AUCTION_FLOOR_DEPOSIT_COEFFICIENT = 200;

    uint256 internal constant AUCTION_DEFAULT_CAP_DEPOSIT = 4200000 * TOKEN_SCALE;
    uint256 internal constant AUCTION_CAP_DEPOSIT_COEFFICIENT_1 = 284;
    uint256 internal constant AUCTION_CAP_DEPOSIT_COEFFICIENT_2 = 42;
}

/// TODO: write description
library DoubleHalving {
    uint256 internal constant PHASE_1 =  420;
    uint256 internal constant PHASE_2 =  630;
    uint256 internal constant PHASE_3 =  735;
    uint256 internal constant PHASE_4 =  787;

    uint256 internal constant AUCTION_EMISSION_1 = 100000;
    uint256 internal constant AUCTION_EMISSION_2 =  50000;
    uint256 internal constant AUCTION_EMISSION_3 =  25000;
    uint256 internal constant AUCTION_EMISSION_4 =  12500;
    uint256 internal constant AUCTION_EMISSION_5 =  12500;

    uint256 internal constant STAKING_REWARD_1 = 220000;
    uint256 internal constant STAKING_REWARD_2 = 110000;
    uint256 internal constant STAKING_REWARD_3 =  55000;
    uint256 internal constant STAKING_REWARD_4 =  27000;
    uint256 internal constant STAKING_REWARD_5 =  27000;

    function tokenInflation(uint256 _day) internal pure returns (uint256, uint256) {
        if (_day <= PHASE_1) return (AUCTION_EMISSION_1, STAKING_REWARD_1);
        if (_day <= PHASE_2) return (AUCTION_EMISSION_2, STAKING_REWARD_2);
        if (_day <= PHASE_3) return (AUCTION_EMISSION_3, STAKING_REWARD_3);
        if (_day <= PHASE_4) return (AUCTION_EMISSION_4, STAKING_REWARD_4);
        return (AUCTION_EMISSION_5, STAKING_REWARD_5);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./MulDiv.sol";

/* solhint-disable */
struct Fixed {
    uint256 value;
}
/* solhint-enable */

library FixedMath {

    uint256 private constant Q = 0x100000000000000000000000000000000;

    function one() internal pure returns (Fixed memory) {
        return Fixed(Q);
    }

    function compare(Fixed memory _x, Fixed memory _y) internal pure returns (int256) {
        if (_x.value < _y.value) return -1;
        if (_x.value > _y.value) return 1;
        return 0;
    }

    function intToFixed(uint256 _x) internal pure returns (Fixed memory) {
        return Fixed(_x * Q);
    }

    function fixedToInt(Fixed memory _x) internal pure returns (uint256) {
        return _x.value / Q;
    }

    function add(Fixed memory _a, Fixed memory _b) internal pure returns (Fixed memory) {
        return Fixed(_a.value + _b.value);
    }

    function subtract(Fixed memory _a, Fixed memory _b) internal pure returns (Fixed memory) {
        return Fixed(_a.value - _b.value);
    }

    function multiply(Fixed memory _a, Fixed memory _b) internal pure returns (Fixed memory) {
        return Fixed(MulDiv.mulDiv(_a.value, _b.value, Q));
    }

    function multiply(Fixed memory _a, uint256 _b) internal pure returns (Fixed memory) {
        return Fixed(_a.value * _b);
    }

    function multiply(uint256 _a, Fixed memory _b) internal pure returns (Fixed memory) {
        return Fixed(_a * _b.value);
    }

    function multiplyTruncating(Fixed memory _a, uint256 _b) internal pure returns (uint256) {
        return MulDiv.mulDiv(_a.value, _b, Q);
    }

    function multiplyTruncating(uint256 _a, Fixed memory _b) internal pure returns (uint256) {
        return MulDiv.mulDiv(_a, _b.value, Q);
    }

    function divide(Fixed memory _a, Fixed memory _b) internal pure returns (Fixed memory) {
        require(_b.value != 0, "Division by zero");
        return Fixed(MulDiv.mulDiv(_a.value, Q, _b.value));
    }

    function divide(uint256 _a, uint256 _b) internal pure returns (Fixed memory) {
        require(_b != 0, "Division by zero");
        return Fixed(MulDiv.mulDiv(_a, Q, _b));
    }

    function divide(Fixed memory _a, uint256 _b) internal pure returns (Fixed memory) {
        require(_b != 0, "Division by zero");
        return Fixed(_a.value / _b);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Config.sol";
import "./Fixed.sol";

/**
 *  @title  Formula
 *
 *  @author 420 DAO Team
 *
 *  @notice Each function of this library is the implementation of a featured mathematical formula used in the system.
 *
 */
library Formula {
    using FixedMath for Fixed;
    using FixedMath for uint256;

    /**
     *  @notice Calculate the truncated value of a certain portion of an integer amount
     *          Formula:    truncate(x / y * a)
     *          Type:       int
     *          Usage:      AuctionManager, MirrorPool, TreasuryManager
     *
     *  @dev    The proportion (x / y) must be less than or equal to 1.
     *
     *          Name        Symbol  Type    Meaning
     *  @param  _x          x       int     Numerator of the proportion
     *  @param  _y          y       int     Denominator of the proportion
     *  @param  _a          a       int     Whole amount
     *
     */
    function portion(uint256 _x, uint256 _y, uint256 _a) internal pure returns (uint256 res) {
        require(_x <= _y, "The proportion must be less than or equal to 1.");
        Fixed memory proportion = _x.divide(_y);
        res = _a.multiplyTruncating(proportion);
    }

    /**
     *  @notice Calculate the staking fee rate of a certain day before the fee converges and becomes unchangeable
     *          Formula:    (1 - i / 787) * 42%
     *          Type:       dec
     *          Usage:      StakingPool
     *
     *  @dev    The day (i) must be less than or equal to the convergent day.
     *
     *          Name    Symbol  Type    Meaning
     *  @param  _day    i       int     integer Day to calculate fee
     *
     */
    function earlyFeeRate(uint256 _day) internal pure returns (Fixed memory res) {
        require(
            _day <= Constant.STAKING_FEE_CONVERGENCE_DAY,
            "The day is greater than the convergent day."
        );
        res = FixedMath.one()
            .subtract(_day.divide(Constant.STAKING_FEE_CONVERGENCE_DAY))
            .multiply(Constant.STAKING_FEE_BASE_PERCENTAGE)
            .divide(100);
    }

    /**
     *  @notice Calculate the accumulated interest rate in the staking pool when an amount of staking reward is emitted.
     *          Formula:    P * (1 + r / a)
     *          Type:       dec
     *          Usage:      StakingPool
     *
     *          Name                    Symbol  Type    Meaning
     *  @param  _productOfInterestRate  P       dec     Accumulated interest rate in the staking pool
     *  @param  _reward                 r       int     Staking reward
     *  @param  _totalCapital           a       int     Total staked capital
     *
     */
    function newProductOfInterestRate(
        Fixed memory _productOfInterestRate,
        uint256 _reward,
        uint256 _totalCapital
    ) internal pure returns (Fixed memory res) {
        Fixed memory interestRate = FixedMath.one().add(_reward.divide(_totalCapital));
        res = _productOfInterestRate.multiply(interestRate);
    }

    /**
     *  @notice Calculate the unit price of the token after the auction failed.
     *          Formula:    A / (Q + r)
     *          Type:       dec
     *          Usage:      StakingPool
     *
     *          Name            Symbol  Type    Meaning
     *  @param  _totalAsset     A       int     Total value of the asset fund and the insurance fund in the treasury
     *  @param  _totalSupply    Q       int     Total circulating supply of the token
     *  @param  _stakingReward  r       int     Total staked capital
     *
     */
    function tokenIntrinsicPrice(
        uint256 _totalAsset,
        uint256 _totalSupply,
        uint256 _stakingReward
    ) internal pure returns (Fixed memory res) {
        res = _totalAsset.divide(_totalSupply + _stakingReward);
    }

    /**
     *  @notice Calculate the floor value that the total deposit in the auction must surpass in order for the auction
     *          to succeed.
     *          Formula:    max(1, 2 * v * e / X%)
     *          Type:       int
     *          Usage:      StakingPool
     *
     *  @dev    Constant: AUCTION_DEFAULT_FLOOR_DEPOSIT     = 1
     *  @dev    Constant: AUCTION_FLOOR_DEPOSIT_COEFFICIENT = 200
     *
     *          Name                    Symbol  Type    Meaning
     *  @param  _tokenIntrinsicPrice    v       dec     Unit price of the token after the auction failed
     *  @param  _tokenEmission          e       int     Amount of token will be emitted in the auction
     *  @param  _treasuryPercentage     X       int     Sum of the percentages of the asset fund and the insurance fund
     *                                                  in the treasury
     *
     */
    function floorDeposit(
        Fixed memory _tokenIntrinsicPrice,
        uint256 _tokenEmission,
        uint256 _treasuryPercentage
    ) internal pure returns (uint256 res) {
        // 200 * tokenIntrinsicPrice * tokenEmission
        Fixed memory numerator =
            Constant.AUCTION_FLOOR_DEPOSIT_COEFFICIENT.multiply(_tokenIntrinsicPrice.multiply(_tokenEmission));

        // 2 * tokenIntrinsicPrice * tokenEmission / treasuryPercentage%
        res = numerator.divide(_treasuryPercentage).fixedToInt();

        if (res == 0) res = Constant.AUCTION_DEFAULT_FLOOR_DEPOSIT;
    }

    /**
     *  @notice Calculate the ceiling value that the total deposit in the auction cannot exceed.
     *          Formula:    max(42E22, truncate((284% * v * e + 42% * A) / X%))
     *          Type:       int
     *          Usage:      StakingPool
     *
     *  @dev    Constant: AUCTION_DEFAULT_CAP_DEPOSIT       = 42E22
     *  @dev    Constant: AUCTION_CAP_DEPOSIT_COEFFICIENT_1 = 284
     *  @dev    Constant: AUCTION_CAP_DEPOSIT_COEFFICIENT_2 = 42
     *
     *          Name                    Symbol  Type    Meaning
     *  @param  _tokenIntrinsicPrice    v       dec     Unit price of the token after the auction failed
     *  @param  _tokenEmission          e       int     Amount of token will be emitted in the auction
     *  @param  _totalAsset             A       int     Total value of the asset fund and the insurance fund in the
     *                                                  treasury
     *  @param  _treasuryPercentage     X       int     Sum of the percentages of the asset fund and the insurance fund
     *                                                  in the treasury
     *
     */
    function capDeposit(
        Fixed memory _tokenIntrinsicPrice,
        uint256 _tokenEmission,
        uint256 _totalAsset,
        uint256 _treasuryPercentage
    ) internal pure returns (uint256 res) {
        // 284 * tokenIntrinsicPrice * tokenEmission + 42 * totalAsset
        Fixed memory numerator = FixedMath.add(
            Constant.AUCTION_CAP_DEPOSIT_COEFFICIENT_1.multiply(_tokenIntrinsicPrice.multiply(_tokenEmission)),
            Constant.AUCTION_CAP_DEPOSIT_COEFFICIENT_2.multiply(_totalAsset.intToFixed())
        );

        // (284% * tokenIntrinsicPrice * tokenEmission + 42% * totalAsset) / treasuryPercentage%
        res = numerator.divide(_treasuryPercentage).fixedToInt();

        if (res < Constant.AUCTION_DEFAULT_CAP_DEPOSIT) res = Constant.AUCTION_DEFAULT_CAP_DEPOSIT;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IDaoManager.sol";

import "./libraries/Formula.sol";
import "./libraries/Config.sol";

import "./Token420.sol";

/// @title  MirrorPool manage reserve tokens flow input and split the pie
/// @notice Tokens minted by auction then fetched to this pool and split to appropriated parts using predefined percentages
contract MirrorPool {
    uint256 public devMktShare;      // Development & Marketing Share
    uint256 public earlySupShare;    // Early Supporters Share
    uint256 public rsvShare;         // Reservation Share

    address public devMktShareOwner;
    address public earlySupShareOwner;
    address public rsvShareOwner;

    Token420 public immutable token;
    IDaoManager public dao;

    event DaoManagerRegistration(address indexed account);

    event DevMktShareOwnerAssignment(address indexed account);
    event DevMktShareWithdrawal(uint256 amount);
    event DevMktShareRefund(uint256 amount);

    event EarlySupShareOwnerAssignment(address indexed account);
    event EarlySupShareWithdrawal(uint256 amount);
    event EarlySupShareRefund(uint256 amount);

    event RsvShareOwnerAssignment(address indexed account);
    event RsvShareWithdrawal(uint256 amount);
    event RsvShareRefund(uint256 amount);

    event UpgradeMirrorPool(address indexed oldAddr, address indexed newAddr, uint256 indexed amount);

    /// @notice MirrorPool constructs on top of Token420
    constructor(Token420 _token) public {
        devMktShareOwner = msg.sender;
        earlySupShareOwner = msg.sender;
        rsvShareOwner = msg.sender;
        token = _token;
    }

    modifier permittedTo(address _account) {
        require(msg.sender == _account, "Unauthorized.");
        _;
    }

    /// @notice Register DaoManager to allow  manage auctions
    /// @dev    Register can only be called once
    function registerDaoManager() external {
        require(address(dao) == address(0), "DaoManager has been registered");
        dao = IDaoManager(msg.sender);
        emit DaoManagerRegistration(address(dao));
    }

    /// @dev Transfer all tokens to the new upgraded mirror pool
    function upgradeTo(address newMirrorPoolAddr) external permittedTo(dao.admin()) {
        require(newMirrorPoolAddr != address(0), "Prohibited null address");

        address oldMirrorPoolAddr = address(this);
        uint256 totalBalance = token.balanceOf(oldMirrorPoolAddr);
        token.transfer(newMirrorPoolAddr, totalBalance);
        emit UpgradeMirrorPool(oldMirrorPoolAddr, newMirrorPoolAddr, totalBalance);
    }

    function assignDevMktShareOwner(address _account) external permittedTo(dao.admin()) {
        require(_account != address(0), "Zero-address is forbidden.");
        devMktShareOwner = _account;
        emit DevMktShareOwnerAssignment(_account);
    }

    function withdrawDevMktShare(uint256 _amount) external permittedTo(devMktShareOwner) {
        require(_amount <= devMktShare, "Invalid amount.");
        devMktShare -= _amount;
        token.transfer(devMktShareOwner, _amount);
        emit DevMktShareWithdrawal(_amount);
    }

    function refundDevMktShare(uint256 _amount) external permittedTo(devMktShareOwner) {
        devMktShare += _amount;
        token.transferFrom(devMktShareOwner, address(this), _amount);
        emit DevMktShareRefund(_amount);
    }

    function assignEarlySupShareOwner(address _account) external permittedTo(dao.admin()) {
        require(_account != address(0), "Zero-address is forbidden.");
        earlySupShareOwner = _account;
        emit EarlySupShareOwnerAssignment(_account);
    }

    function withdrawEarlySupShare(uint256 _amount) external permittedTo(earlySupShareOwner) {
        require(_amount <= earlySupShare, "Invalid amount.");
        earlySupShare -= _amount;
        token.transfer(earlySupShareOwner, _amount);
        emit EarlySupShareWithdrawal(_amount);
    }

    function refundEarlySupShare(uint256 _amount) external permittedTo(earlySupShareOwner) {
        earlySupShare += _amount;
        token.transferFrom(earlySupShareOwner, address(this), _amount);
        emit EarlySupShareRefund(_amount);
    }

    function assignRsvShareOwner(address _account) external permittedTo(dao.admin()) {
        require(_account != address(0), "Zero-address is forbidden.");
        rsvShareOwner = _account;
        emit RsvShareOwnerAssignment(_account);
    }

    function withdrawRsvShare(uint256 _amount) external permittedTo(rsvShareOwner) {
        require(_amount <= rsvShare, "Invalid amount.");
        rsvShare -= _amount;
        token.transfer(rsvShareOwner, _amount);
        emit RsvShareWithdrawal(_amount);
    }

    function refundRsvShare(uint256 _amount) external permittedTo(rsvShareOwner) {
        rsvShare += _amount;
        token.transferFrom(rsvShareOwner, address(this), _amount);
        emit RsvShareRefund(_amount);
    }

    /// @notice fetchToken fetch tokens being minted and approved by DaoManager and split the pies
    /// @dev    fetchToken is callable only by DaoManager
    /// @param  _amount amount of 420D tokens to be fetched
    function fetchToken(uint256 _amount) external permittedTo(address(dao)) {
        token.transferFrom(address(dao), address(this), _amount);
        _split(_amount);
    }

    /// @notice _split splits the fetched token amount accordingly to the defined percentages
    /// @param  _amount amount of 420D tokens to be split
    function _split(uint256 _amount) private {
        uint256 earlySupAmount = Formula.portion(Constant.MIRROR_PERCENTAGE_EARLY_SUPPORTERS, 100, _amount);
        uint256 rsvAmount      = Formula.portion(Constant.MIRROR_PERCENTAGE_RESERVATION, 100, _amount);
        require(_amount >= earlySupAmount + rsvAmount, "Calculation error");
        uint256 devMktAmount   = _amount - (earlySupAmount + rsvAmount); // dust go to Development & Marketing Share

        earlySupShare += earlySupAmount;
        devMktShare += devMktAmount;
        rsvShare += rsvAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libraries/Formula.sol";
import "./libraries/Config.sol";

import "./DaoManager.sol";

/// @title  TreasuryManager manage CASH flow and hold CASH reserve to back tokens value
/// @notice Users can claim token to get CASH back in the worst case token economy
contract TreasuryManager {
    uint256 public assetFund;
    uint256 public insuranceFund;
    uint256 public operationFund;

    address public assetFundOwner;
    address public insuranceFundOwner;
    address public operationFundOwner;

    uint256 public lockUntil;

    IERC20 public immutable cash;
    IERC20 public immutable token;

    DaoManager public dao;

    address public auction;

    event DaoManagerRegistration(address indexed account);
    event AuctionManagerRegistration(address indexed account);

    event AssetFundOwnerAssignment(address indexed account);
    event AssetFundWithdrawal(uint256 amount);
    event AssetFundRefund(uint256 amount);

    event InsuranceFundOwnerAssignment(address indexed account);
    event InsuranceFundWithdrawal(uint256 amount);
    event InsuranceFundRefund(uint256 amount);

    event OperationFundOwnerAssignment(address indexed account);
    event OperationFundWithdrawal(uint256 amount);
    event OperationFundRefund(uint256 amount);

    event LockUpto(address indexed account, uint256 oldLockUntil, uint256 newLockUntil);
    event BuyBackAndBurn(address indexed user, uint256 amountToken, uint256 amountCash);

    event UpgradeTreasuryManager(address indexed oldAddr, address indexed newAddr, uint256 indexed amount);

    /// @notice TreasuryManager constructs on top of Token420 and ERC20 cash token
    /// @dev    At deployment time, it call token to register it as dao manager.
    /// @param  _cash Address of deployed CASH token
    /// @param  _token Address of deployed Token420
    constructor(
        IERC20 _cash,
        IERC20 _token
    ) public {
        cash = _cash;
        token = _token;
        assetFundOwner = msg.sender;
        insuranceFundOwner = msg.sender;
        operationFundOwner = msg.sender;
    }

    modifier permittedTo(address _account) {
        require(msg.sender == _account, "Unauthorized.");
        _;
    }

    /// @notice Register DaoManager to interact with
    /// @dev    Register can only be called once and to be called inside DaoManager constructor
    function registerDaoManager() external {
        require(address(dao) == address(0), "DaoManager has been registered");
        dao = DaoManager(msg.sender);
        emit DaoManagerRegistration(address(dao));
    }

    /// @notice Register AuctionManager address to allow only order from coming from it
    /// @dev    Register can only be called once and to be called inside AuctionManager constructor
    function registerAuctionManager() external {
        require(auction == address(0), "AuctionManager has been registered");
        auction = msg.sender;
        emit AuctionManagerRegistration(auction);
    }

    /// @dev Transfer all treasury to the new upgraded treasury
    function upgradeTo(address newTreasuryManagerAddr) external permittedTo(dao.admin()) {
        require(newTreasuryManagerAddr != address(0), "Prohibited null address");

        address oldTreasuryManagerAddr = address(this);
        uint256 totalTreasuryCash = cash.balanceOf(oldTreasuryManagerAddr);
        cash.transfer(newTreasuryManagerAddr, totalTreasuryCash);
        emit UpgradeTreasuryManager(oldTreasuryManagerAddr, newTreasuryManagerAddr, totalTreasuryCash);
    }

    function assignAssetFundOwner(address _account) external permittedTo(dao.admin()) {
        require(_account != address(0), "Zero-address is forbidden.");
        assetFundOwner = _account;
        emit AssetFundOwnerAssignment(_account);
    }

    function withdrawAssetFund(uint256 _amount) external permittedTo(assetFundOwner) {
        require(_amount <= assetFund, "Invalid amount.");
        assetFund -= _amount;
        cash.transfer(assetFundOwner, _amount);
        emit AssetFundWithdrawal(_amount);
    }

    function refundAssetFund(uint256 _amount) external permittedTo(assetFundOwner) {
        assetFund += _amount;
        cash.transferFrom(assetFundOwner, address(this), _amount);
        emit AssetFundRefund(_amount);
    }

    function assignInsuranceFundOwner(address _account) external permittedTo(dao.admin()) {
        require(_account != address(0), "Zero-address is forbidden.");
        insuranceFundOwner = _account;
        emit InsuranceFundOwnerAssignment(_account);
    }

    function withdrawInsuranceFund(uint256 _amount) external permittedTo(insuranceFundOwner) {
        require(_amount <= insuranceFund, "Invalid amount.");
        insuranceFund -= _amount;
        cash.transfer(insuranceFundOwner, _amount);
        emit InsuranceFundWithdrawal(_amount);
    }

    function refundInsuranceFund(uint256 _amount) external permittedTo(insuranceFundOwner) {
        insuranceFund += _amount;
        cash.transferFrom(insuranceFundOwner, address(this), _amount);
        emit InsuranceFundRefund(_amount);
    }

    function assignOperationFundOwner(address _account) external permittedTo(dao.admin()) {
        require(_account != address(0), "Zero-address is forbidden.");
        operationFundOwner = _account;
        emit OperationFundOwnerAssignment(_account);
    }

    function withdrawOperationFund(uint256 _amount) external permittedTo(operationFundOwner) {
        require(_amount <= operationFund, "Invalid amount.");
        operationFund -= _amount;
        cash.transfer(operationFundOwner, _amount);
        emit OperationFundWithdrawal(_amount);
    }

    function refundOperationFund(uint256 _amount) external permittedTo(operationFundOwner) {
        operationFund += _amount;
        cash.transferFrom(operationFundOwner, address(this), _amount);
        emit OperationFundRefund(_amount);
    }

    /// @notice lockUpto to allow to lock claim cash back up to a certain timestamp
    /// @dev    lockUpto is callable only by Dao Manager admin
    /// @param  _t certain lock timestamp
    function lockUpto(uint256 _t) external permittedTo(dao.admin()) {
        uint256 currentTime = block.timestamp; // solhint-disable-line not-rely-on-time
        require(
            _t > currentTime && _t > lockUntil && (_t - currentTime) <= Constant.TREASURY_MAX_LOCK,
            "Invalid lock time"
        );

        uint256 oldLockUntil = lockUntil;
        lockUntil = _t;
        emit LockUpto(msg.sender, oldLockUntil, _t);
    }

    /// @notice fetchCash fetch cashes being approved by AuctionManager and split the pies
    /// @dev    fetchCash is callable only by AuctionManager
    /// @param  _amount amount of CASH to be fetched
    function fetchCash(uint256 _amount) external permittedTo(auction) {
        cash.transferFrom(auction, address(this), _amount);
        _split(_amount);
    }

    /// @notice User can claim cash back to the Treasury. Cash will be send to user and the tokens will be burned
    ///         User have to approve the amountToken to the Treasury before being able to call this method
    /// @param _tokenAmount cash amount that user is willing to burn in exchange of cash back
    /// @dev The token burning doesn't require users to approve allowance before. Though we force this mechanism
    ///      to avoid users accidentally request to claim/burn his tokens.
    function buyBackAndBurn(uint256 _tokenAmount) external {
        require(block.timestamp > lockUntil, "buyBackAndBurn is locked"); // solhint-disable-line not-rely-on-time

        uint256 totalToken = token.totalSupply();
        require(_tokenAmount <= totalToken, "Excessive amount of tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _tokenAmount, "Not enough allowance");

        uint256 totalCash = assetFund + insuranceFund;

        uint256 cashAmount = Formula.portion(_tokenAmount, totalToken, totalCash);
        uint256 insuranceCashAmount = Formula.portion(
            insuranceFund,
            totalCash,
            cashAmount
        );

        uint256 assetCashAmount = Formula.portion(
            assetFund,
            totalCash,
            cashAmount
        );

        require(insuranceCashAmount <= insuranceFund, "Error withdrawal parts Insurance Fund");
        require(assetCashAmount <= assetFund, "Error withdrawal parts Asset Fund");

        dao.burn(msg.sender, _tokenAmount);
        cash.transfer(msg.sender, cashAmount);
        insuranceFund -= insuranceCashAmount;
        assetFund -= assetCashAmount;

        emit BuyBackAndBurn(msg.sender, _tokenAmount, cashAmount);
    }

    /// @notice _split splits the fetched cash amount accordingly to the defined percentages
    /// @param  _amount amount of CASH tokens to be split
    function _split(uint256 _amount) private {
        uint256 assetAmount     = Formula.portion(Constant.TREASURY_PERCENTAGE_ASSET, 100, _amount);
        uint256 insuranceAmount = Formula.portion(Constant.TREASURY_PERCENTAGE_INSURANCE, 100, _amount);
        require(_amount >= insuranceAmount + assetAmount, "Calculation error");
        uint256 operationAmount = _amount - (insuranceAmount + assetAmount); // dust go to Operation Fund

        assetFund += assetAmount;
        insuranceFund += insuranceAmount;
        operationFund += operationAmount;
    }

    function totalAsset() external view returns (uint256) {
        return assetFund + insuranceFund;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library MulDiv {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
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
        unchecked {
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
            uint256 twos = (~denominator + 1) & denominator;
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
            // correct result modulo 2**256. Since the preconditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
        }
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IDaoManager.sol";
import "./libraries/Config.sol";

/// @title  Token 420 conforms to ERC20
/// @notice Token 420 is fully conformed to ERC20 standard. It has extra mint and burn features.
/// @dev    These capabilities are delegated to DaoManager, i.e only DaoManager can call mint and burn
contract Token420 is ERC20 {
    IDaoManager public dao;

    event DaoManagerRegistration(address indexed account);
    event DaoManagerMigration(address indexed account);
    event Mint(address indexed account, uint256 indexed amount);
    event Burn(address indexed account, uint256 indexed amount);

    /* solhint-disable-next-line no-empty-blocks */
    constructor() public ERC20("Token 420", "420") {}

    function decimals() public pure override returns (uint8) {
        return Constant.TOKEN_DECIMALS;
    }

    /// @notice Register DaoManager to delegate minting and burning permission
    /// @dev    Register can only be called once
    function registerDaoManager() external {
        require(address(dao) == address(0), "DAO Manager has been registered");
        dao = IDaoManager(msg.sender);
        emit DaoManagerRegistration(address(dao));
    }

    /// @notice Migrate the DAO Manager to the new version
    /// @dev    Migration can only called by DAO's admin
    function upgrateDaoManager(address newDao) external {
        require(msg.sender == dao.admin(), "Only admin can upgrade");
        require(dao.isBlockedForMigration(), "DAO is not at migration state");
        dao = IDaoManager(newDao);
        emit DaoManagerMigration(address(dao));
    }

    /// @notice Delegate minting permission to DaoManager
    /// @param  _account account that receive token newly minted
    /// @param  _amount  amount of the tokens to be minted
    function mint(address _account, uint256 _amount) external {
        require(msg.sender == address(dao), "Only DAO Manager can mint tokens");
        _mint(_account, _amount);
        emit Mint(_account, _amount);
    }

    /// @notice Delegate burning permission to DaoManager
    /// @param _account account that burn token
    /// @param _amount  amount of the tokens to be burned
    function burn(address _account, uint256 _amount) external {
        require(msg.sender == address(dao), "Only DAO Manager can burn tokens");
        _burn(_account, _amount);
        emit Burn(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IDaoManager.sol";

import "./libraries/Config.sol";

import "./AuctionManager.sol";
import "./MirrorPool.sol";
import "./StakingPool.sol";
import "./Token420.sol";
import "./TreasuryManager.sol";

/// @title  DaoManager coordinates token management (mint/burn) and other components of the DAO
/// @notice DaoManager have permission to mint and burn 420D tokens. It can trigger the end of auction day by admin
/// @dev    mint order is only permitted by StakingPool
/// @dev    burn order is only permitted by TreasuryManager
/// @dev    trigger nextAuction is only permitted by admin
contract DaoManager is IDaoManager {
    address public immutable admin;
    address public immutable treasury;

    Token420        public immutable token;

    AuctionManager  public immutable auction;
    MirrorPool      public immutable pmirror;
    StakingPool     public immutable pstaking;

    uint256 public day = 1;
    uint256 public lastTriggerNextAuction;
    bool public emissionTerminated;           /// Stop token's emission when it reached total supply
    uint256 public migrationStatus;           /// 0 non, 1 prepare to migrate, 2 migrated
    uint256 public immutable auctionDuration;

    /// @notice DaoManager constructs on top of Token420
    /// @dev    At deployment time, it call token to register it as dao manager.
    constructor(
        Token420 _token,
        MirrorPool _pmirror,
        AuctionManager _auction,
        StakingPool _pstaking,
        uint256 _auctionDuration
    ) public {
        admin = msg.sender;
        token = _token;
        pmirror = _pmirror;
        auction = _auction;
        pstaking = _pstaking;

        pmirror.registerDaoManager();
        auction.registerDaoManager();
        token.registerDaoManager();
        pstaking.registerDaoManager();

        treasury = address(auction.treasury());
        auction.treasury().registerDaoManager();

        auctionDuration = _auctionDuration;
    }

    /// @dev Dao is about to migrate. This state determine the last day just before the migration
    function isGoingToMigrate() external view virtual override returns (bool) {
        return (migrationStatus > 0);
    }

    /// @dev Dao is migrated. This state determine DAO is migrated to the newer version
    function isBlockedForMigration() external view virtual override returns (bool) {
        return (migrationStatus > 1);
    }

    modifier permittedTo(address _account) {
        require(msg.sender == _account, "Unauthorized.");
        _;
    }

    /// @notice Order Token420 to burn 420Ds token from specified account
    /// @dev    Only Treasury can order burning operation.
    /// @param  _account account that burn token
    /// @param  _amount  amount of the tokens to be burned
    function burn(address _account, uint256 _amount) external permittedTo(treasury) {
        token.burn(_account, _amount);
    }

    function inflationOf(uint256 _day) public pure returns (uint256, uint256) {
        (uint256 a, uint256 b) = DoubleHalving.tokenInflation(_day);
        a *= Constant.TOKEN_SCALE;
        b *= Constant.TOKEN_SCALE;
        return (a, b);
    }

    function todayInflation() public view returns (uint256, uint256) {
        return inflationOf(day);
    }

    /// @notice Set the entire DAO to the freezing state for migraion purpose
    /// @dev    Only admin can call this method
    function freezeForMigration() external permittedTo(admin) {
        migrationStatus = 1;
    }

    /// @notice Order AuctionManager to close current auction and open new auction
    /// @dev    If the current auction is SUCCESS, then mint 420D tokens to MirrorPool and AuctionManager
    ///         Then order them to rebalance the pies
    ///         Note :
    ///           It can be useful to have a method to change admin, callable by this admin only
    function nextAuction() external permittedTo(admin) {
        require(!emissionTerminated, "Emission Terminated");
        require(!this.isBlockedForMigration(), "Migrated");

        uint256 currentTimestamp = block.timestamp; // solhint-disable-line not-rely-on-time
        require(currentTimestamp - lastTriggerNextAuction >= auctionDuration, "Invalid trigger nextAuction");

        (uint256 auctionEmission, uint256 stakingReward) = todayInflation();

        if (auction.status()) {
            token.mint(address(this), (auctionEmission*2));

            token.approve(address(auction), auctionEmission);
            auction.fetchToken(auctionEmission);

            token.approve(address(pmirror), auctionEmission);
            pmirror.fetchToken(auctionEmission);
        }

        if (pstaking.isStakingTooSmall()) {
            token.burn(address(pstaking), pstaking.chargedFee());
            pstaking.clearChargedFee();
        } else {
            token.mint(address(this), stakingReward);
            token.approve(address(pstaking), stakingReward);
            pstaking.fetchReward(stakingReward);
        }

        day++;
        if (token.totalSupply() >= Constant.TOKEN_MAX_SUPPLY_THRESHOLD) {
            emissionTerminated = true;
        } else {
            (auctionEmission, stakingReward) = inflationOf(day);
            auction.updateAuctionInfo(auctionEmission, stakingReward);
            pstaking.updateFeeRate();
        }

        lastTriggerNextAuction = currentTimestamp;

        if (this.isGoingToMigrate()) {
            migrationStatus = 2;
            emissionTerminated = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IDaoManager.sol";
import "./interfaces/IStaking.sol";

import "./libraries/Config.sol";
import "./libraries/Fixed.sol";
import "./libraries/Formula.sol";

import "./TokenS420.sol";

/// @title  StakingPool ensure interest rate for stakers
/// @notice It connect to DaoManager to order token mint interest coupon when staker withdraw
contract StakingPool is IStaking {
    using FixedMath for Fixed;
    using FixedMath for uint256;

    IDaoManager public dao;

    IERC20  public immutable token;
    TokenS420 public immutable stakingToken;

    /// @dev Unstake fee rate for the current day
    Fixed public feeRate;

    /// @dev Accumulated fee charged by all unstake from previous day
    ///      It will be cleared when the auction pass to the next day, or
    ///      if next day, the staking pool is nearly empty
    uint256 public chargedFee;

    /// @dev Global compound interest rate, update on a daily basis
    Fixed public productOfInterestRate = FixedMath.one();

    event DaoManagerRegistration(address indexed account);
    event UpgradeStakingPool(address indexed oldAddr, address indexed newAddr, uint256 indexed amount);
    event Stake(address indexed account, uint256 indexed amount);
    event Unstake(address indexed account, uint256 indexed amount);
    event Inflation(uint256 indexed reward);

    /// @notice StakingPool constructs on top of DaoManager
    /// @dev    At deployment time, it set epsilon for considering empty staking pool
    /// @param  _token Address of deployed Token420
    constructor(IERC20 _token, TokenS420 _stakingToken) public {
        token = _token;

        stakingToken = _stakingToken;
        stakingToken.registerStakingPool();
        feeRate = Formula.earlyFeeRate(1);
    }

    modifier permittedTo(address _account) {
        require(msg.sender == _account, "Unauthorized.");
        _;
    }

    /// @dev Getter for feeRate (the implicit  generator does not goes well with custom struct data)
    function getFeeRate() external view  returns (Fixed memory) {
        return feeRate;
    }
    /// @dev Getter for productOfInterestRate (the implicit  generator does not goes well with custom struct data)
    function getProductOfInterestRate() external view  returns (Fixed memory) {
        return productOfInterestRate;
    }

    /// @dev Convert the amount of token to the discount factor
    function token2Stake(uint256 sAmount) external view virtual override returns (Fixed memory) {
        return sAmount.intToFixed().divide(productOfInterestRate);
    }

    /// @dev Convert the discount factor to the amount of token
    function stake2Token(Fixed memory dfactor) external view virtual override returns (uint256) {
        return dfactor.multiply(productOfInterestRate).fixedToInt();
    }

    /// @dev Transfer all locking 420 token to the new stake
    function upgradeTo(IStaking newStakingPool) external permittedTo(dao.admin()) {
        address newStakingPoolAddr = address(newStakingPool);
        require(newStakingPoolAddr != address(0), "Prohibited null address");

        address oldStakingPoolAddr = address(this);
        uint256 totalStakingPool = token.balanceOf(oldStakingPoolAddr);
        token.transfer(newStakingPoolAddr, totalStakingPool);
        emit UpgradeStakingPool(oldStakingPoolAddr, newStakingPoolAddr, totalStakingPool);
    }

    /// @notice Get dao address
    function daoAddress() external view virtual override returns (address) {
        return address(dao);
    }

    /// @notice Register DaoManager to allow it order methods of this contract
    /// @dev    Register can only be called once
    function registerDaoManager() external {
        require(address(dao) == address(0), "DaoManager has been registered");
        dao = IDaoManager(msg.sender);
        emit DaoManagerRegistration(address(dao));
    }

    /// @notice Update fee rate given the current day counter
    /// @dev    Only Dao Manager can order Staking Pool to update fee, depending to the
    ///         auction day increment
    function updateFeeRate() external permittedTo(address(dao)) {
        if (dao.day() <= Constant.STAKING_FEE_CONVERGENCE_DAY) {
            feeRate = Formula.earlyFeeRate(dao.day());
        }
    }

    /// @notice isStakingEmpty return the TRUE/FALSE on whether a staking exists
    /// @dev    This method can be called by anyone. If the total amount in staking pool is less than a certain amount,
    ///         it is considered as 'dust', and staking pool is considered as empty
    function isStakingTooSmall() public view returns (bool) {
        // As long there are token staked to the pool, it is TRUE
        // TODO: Correct epsilon should match with decimals(), i.e: 10^10 which bounds epsilon ERROR to 10^(-8)
        return (stakingToken.totalSupply() < Constant.EPSILON);
    }

    function clearChargedFee() external permittedTo(address(dao)) {
        chargedFee = 0;
    }

    /// @notice Fetch reward and update latest interest and total staking amount everyday
    /// @param _reward Amount of inflated tokens distributes to staking pool on the daily basis
    /// @dev This method can be called by only DaoManager
    function fetchReward(uint256 _reward) external permittedTo(address(dao)) {
        uint256 totalStake = token.balanceOf(address(this));
        uint256 rewardAndFee = _reward + chargedFee;
        require(totalStake > chargedFee, "Dao Manager only");
        productOfInterestRate = Formula.newProductOfInterestRate(productOfInterestRate, rewardAndFee, (totalStake - chargedFee));
        chargedFee = 0;

        token.transferFrom(address(dao), address(this), _reward);
        emit Inflation(rewardAndFee);
    }

    /// @notice User can stake their token to staking pool and receive reward
    /// @param _amount token amount that user is willing to stake to Staking Pool
    function stake(uint256 _amount) external {
        require(!dao.isBlockedForMigration(), "Migrated");
        require(!dao.emissionTerminated(), "Emission Terminated");

        Fixed memory dFactor = this.token2Stake(_amount);
        stakingToken.mintDiscountFactor(msg.sender, dFactor);

        // Transfer token to Staking pool
        token.transferFrom(msg.sender, address(this), _amount);
        emit Stake(msg.sender, _amount);
    }

    /// @notice User can withdraw fully or partially their stake ( capital + interest )
    /// @param _amount Token amount that user want to withdraw
    function unstake(uint256 _amount) external {
        require(!dao.isBlockedForMigration(), "Migrated");
        require(_amount <= stakingToken.balanceOf(msg.sender), "exceeds unstake amount");

        uint256 fee = feeRate.multiplyTruncating(_amount);

        chargedFee += fee;

        Fixed memory dFactor = this.token2Stake(_amount);
        stakingToken.burnDiscountFactor(msg.sender, dFactor);

        token.transfer(msg.sender, _amount - fee);
        emit Unstake(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../libraries/Fixed.sol";

/**
 * @dev Interface of the Staking Pool.
 *      This interface help to implement dynamic grow of a stake token
 *      When user stake their tokens in a staking pool, we return them stake token as a receipt
 *      The amount of stake token is calculated based on some internal storage of the stake,
 *      which make the amount of token grow dynamically.
 *      The internal storage for the stake is a Fixed number
 *
 *      The implementation has to provide functions
 *        - convert the amount of token to the internal stake amount
 *        - convert the internal stake amount to the amount of token
 *        - transfer locking stake token 420 to the new staking pool
 *        - Dao's admin getter
 */
interface IStaking {
    /**
     * @dev Convert the amount of token to the internal stake amount
     */
    function token2Stake(uint256 t) external view returns (Fixed memory);

    /**
     * @dev Convert the internal stake amount to the amount of token
     */
    function stake2Token(Fixed memory s) external view returns (uint256);

    /**
     * @dev Transfer all locking 420 token to the new stake
     */
    function upgradeTo(IStaking newStakingPool) external;

    /**
     * @dev Get dao address
     */
    function daoAddress() external view returns (address);
}

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./interfaces/IStaking.sol";
import "./interfaces/IDaoManager.sol";

import "./libraries/Config.sol";
import "./libraries/Fixed.sol";
import "./libraries/Formula.sol";

/// @title  Token s420 conforms to ERC20
/// @notice Token Stake s420 is fully conformed to ERC20 standard. It has extra mint and burn features.
/// @dev    These capabilities are delegated to StakingPool, i.e only StakingPool can call mint and burn
///         s420 has an internal 'amount' which is the storage of user's discount factor
///         The discount factor is dynamically convertible to token amount, using StakingPool utility
contract TokenS420 is ERC20 {

    /// @notice Interface of staking pool. The Staking pool provide method
    ///         to convert between token amount and discount factor
    IStaking public istaking;

    /// @notice Internal storage of user's discount factors
    mapping(address => Fixed) public _internalBalances;

    /// @notice Total minted discount factor
    Fixed public totalDFactor;

    event StakingPoolRegistration(address indexed account);
    event StakingPoolMigration(address indexed account);
    event MintDFactor(address indexed account, uint256 v);
    event BurnDFactor(address indexed account, uint256 v);

    /* solhint-disable-next-line no-empty-blocks */
    constructor() public ERC20("Stake s420", "s420") {}

    function registerStakingPool() external {
        require(address(istaking) == address(0), "Staking Pool has been registered");
        istaking = IStaking(msg.sender);
        emit StakingPoolRegistration(address(istaking));
    }

    /// @notice Migrate the StakingPool to the new version
    /// @dev    Migration can only called by DAO's admin
    function upgradeStakingPool(address newStakingPool) external {
        IDaoManager dao = IDaoManager(istaking.daoAddress());
        require(msg.sender == dao.admin(), "Only admin can migrate");
        require(dao.isBlockedForMigration(), "DAO is not at migration state");
        istaking = IStaking(newStakingPool);
        emit StakingPoolMigration(address(istaking));
    }

    function decimals() public pure override returns (uint8) {
        return Constant.TOKEN_DECIMALS;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return istaking.stake2Token(totalDFactor);
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return istaking.stake2Token(_internalBalances[_account]);
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        Fixed memory dfactor = istaking.token2Stake(_amount);
        _transfer(msg.sender, _recipient, dfactor);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(_sender, _recipient);
        require(currentAllowance >= _amount, "exceeds allowance");

        /* solhint-disable */
        unchecked {
            _approve(_sender, msg.sender, currentAllowance - _amount);
        }
        /* solhint-enable */

        Fixed memory dfactor = istaking.token2Stake(_amount);
        _transfer(_sender, _recipient, dfactor);

        return true;
    }

    function _transfer(
        address _sender,
        address _recipient,
        Fixed memory _dFactor
    ) internal {
        require(_sender != address(0), "sender null address");
        require(_recipient != address(0), "recipient null address");

        Fixed memory senderDiscountFactor = _internalBalances[_sender];
        require(
            FixedMath.compare(senderDiscountFactor, _dFactor) > -1,
            "exceeds balance"
        );

        _internalBalances[_sender] = FixedMath.subtract(_internalBalances[_sender], _dFactor);
        _internalBalances[_recipient] = FixedMath.add(_internalBalances[_recipient], _dFactor);

        emit Transfer(_sender, _recipient, _dFactor.value);
    }

    function mintDiscountFactor(address _account, Fixed memory _dFactor) public {
        require(msg.sender == address(istaking), "Only Staking Pool");
        require(_account != address(0), "prohibited null account");

        _internalBalances[_account] = FixedMath.add(_internalBalances[_account], _dFactor);
        totalDFactor = FixedMath.add(totalDFactor, _dFactor);

        emit MintDFactor(_account, _dFactor.value);
    }

    function burnDiscountFactor(address _account, Fixed memory _dFactor) public {
        require(msg.sender == address(istaking), "Only Staking Pool");
        require(_account != address(0), "prohibited null account");

        require(
            FixedMath.compare(totalDFactor, _dFactor) > -1,
            "exceeds total discount factor"
        );

        Fixed memory accountDiscountFactor = _internalBalances[_account];
        require(
            FixedMath.compare(accountDiscountFactor, _dFactor) > -1,
            "exceeds balance"
        );

        _internalBalances[_account] = FixedMath.subtract(_internalBalances[_account], _dFactor);
        totalDFactor = FixedMath.subtract(totalDFactor, _dFactor);

        emit BurnDFactor(_account, _dFactor.value);
    }
}