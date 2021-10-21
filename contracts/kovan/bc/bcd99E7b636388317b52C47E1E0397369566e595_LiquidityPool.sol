// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IComptroller.sol";
import "./interfaces/ILPT.sol";
import "./BlockLock.sol";

/// @title Liquidity Pool
/// @notice The most important contract. Almost all the protocol is coded here
/// @dev Upgradeable Smart Contract
contract LiquidityPool is Initializable, OwnableUpgradeable, BlockLock, PausableUpgradeable, ILiquidityPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Borrow {
        uint256 amount;
        uint256 interestIndex;
        uint256 borrowedAtBlock;
    }

    address private stableCoin;
    address private liquidityPoolToken;
    uint256 private accrualBlock;
    uint256 private borrowIndex;
    uint256 private optimalUtilizationRate;
    uint256 private baseBorrowRate;
    uint256 private slope1;
    uint256 private slope2;
    uint256 private reserveFactor;
    uint256 private xtkFeeFactor;
    uint256 private lptBaseValue;
    uint256 private minimumLoanValue;
    uint256 private liquidityPenaltyFactor;

    /// @dev Comptroller's address
    address public comptroller;
    /// @dev Current total borrows owed to this Liquidity Pool
    uint256 public totalBorrows;
    /// @dev Current reserves
    uint256 public reserves;
    /// @dev Current protocol earnings
    uint256 public xtkEarns;

    mapping(address => Borrow) borrows;

    uint256 private constant RATIOS = 1e16;
    uint256 private constant FACTOR = 1e18;
    uint256 private constant BLOCKS_PER_YEAR = 2628000;

    event UpdateLiquidityPoolToken(address indexed liquidityPoolToken);
    event UpdateComptroller(address indexed comptroller);
    event UpdateInterestModelParameters(
        uint256 optimalUtilizationRate,
        uint256 baseBorrowRate,
        uint256 slope1,
        uint256 slope2
    );
    event UpdateXtkFeeFactor(uint256 xtkFeeFactor);
    event UpdateReserveFeeFactor(uint256 reserveFactor);
    event UpdateLPTBaseValue(uint256 lptBaseValue);
    event UpdateMiniumLoanValue(uint256 minimumLoanValue);
    event UpdateLiquidationPenaltyFactor(uint256 liquidityPenaltyFactor);
    event WithdrawFee(address indexed recipient, uint256 xtkEarns);
    event BorrowEvent(address indexed borrower, uint256 borrowAmount, uint256 debtAmount);
    event RepayEvent(address indexed borrower, uint256 repayAmount, uint256 debtAmount);
    event LiquidateEvent(address indexed borrower, address indexed liquidator, uint256 amount, address[] markets);

    /// @notice Upgradeable smart contract constructor
    /// @dev Initializes this Liquidity Pool
    function initialize(address _stableCoin) external initializer {
        require(_stableCoin != address(0));
        __Ownable_init();
        __Pausable_init_unchained();

        stableCoin = _stableCoin;
        borrowIndex = FACTOR;
    }

    /// @notice USDC owned by this Liquidity Pool
    /// @return (uint256) How much USDC the Liquidity Pool owns
    function currentLiquidity() public view returns (uint256) {
        return IERC20(stableCoin).balanceOf(address(this));
    }

    /// @notice Tells how much the protocol is being used
    /// @return (uint256) Utilization Rate value multiplied by FACTOR(1e18)
    function utilizationRate() public view returns (uint256) {
        if (totalBorrows == 0) return 0;
        return totalBorrows.mul(FACTOR).div(totalBorrows.add(currentLiquidity()).sub(reserves).sub(xtkEarns));
    }

    /// @notice Tells the current borrow rate
    /// @dev If the utilization rate is less or equal than the optimal utilization rate, a model using the slope 1 is used.
    /// @dev Otherwise the model uses the slope 2. This slope 2 is moved to the origin in order to avoid problems by the uint type
    /// @return (uint256) Borrow rate value multiplied by FACTOR
    function borrowRate() public view returns (uint256) {
        uint256 uRate = utilizationRate();
        if (uRate <= optimalUtilizationRate) return slope1.mul(uRate).div(FACTOR).add(baseBorrowRate);
        return
            baseBorrowRate.add(
                slope1.mul(optimalUtilizationRate).add(slope2.mul(uRate.sub(optimalUtilizationRate))).div(FACTOR)
            );
    }

    /// @notice Tells the current borrow rate per block
    /// @dev The borrow rateis divided by an estimated amount of blocks per year to help computing indexes
    /// @return (uint256) Borrow rate per block value multiplied by FACTOR
    function borrowRatePerBlock() public view returns (uint256) {
        return borrowRate().div(BLOCKS_PER_YEAR);
    }

    /// @notice Anyone can know how much a borrower owes to the Liquidity Pool
    /// @dev The value is updated via the ratio between the current borrow index and the borrower's borrow index
    /// @param _borrower (address) Borrower's address
    /// @return (uint256) How much a Borrower owes to the Liquidity Pool in USDC terms
    function updatedBorrowBy(address _borrower) public view override returns (uint256) {
        Borrow storage borrowerBorrow = borrows[_borrower];
        uint256 borrowAmount = borrowerBorrow.amount;

        if (borrowAmount == 0) return 0;
        (uint256 newBorrowIndex, ) = calculateBorrowInformationAtBlock(block.number);

        return borrowAmount.mul(newBorrowIndex).div(borrowerBorrow.interestIndex);
    }

    /// @notice Accrues the protocol interests
    /// @dev This function updates the borrow index and the total borrows values
    function accrueInterest() private {
        reserves = calculateReservesInformation(block.number);
        xtkEarns = calculateXtkEarnings(block.number);
        (borrowIndex, totalBorrows) = calculateBorrowInformationAtBlock(block.number);
        accrualBlock = block.number;
    }

    /// @notice Calculates updated borrow information at a given block
    /// @dev Computes the borrow index and total borrows depending on how many blocks have passed since latest interaction
    /// @param _block (uint256) Block to look against
    /// @return newBorrowIndex (uint256) Updated borrow index
    /// @return newTotalBorrow (uint256) Updated total borrows
    function calculateBorrowInformationAtBlock(uint256 _block)
        private
        view
        returns (uint256 newBorrowIndex, uint256 newTotalBorrow)
    {
        if (_block <= accrualBlock) return (borrowIndex, totalBorrows);
        if (totalBorrows == 0) return (borrowIndex, totalBorrows);

        uint256 deltaBlock = _block.sub(accrualBlock);
        uint256 interestFactor = borrowRatePerBlock().mul(deltaBlock).add(FACTOR);

        newBorrowIndex = borrowIndex.mul(interestFactor).div(FACTOR);
        newTotalBorrow = totalBorrows.mul(interestFactor).div(FACTOR);
    }

    /// @notice Calculates updated reserves information at a given block
    /// @dev Computes the accrued reserves value
    /// @param _block (uint256) Block to look against
    /// @return newReserves (uint256) Updated reserves value
    function calculateReservesInformation(uint256 _block) private view returns (uint256 newReserves) {
        if (_block <= accrualBlock) return reserves;

        uint256 deltaBlock = _block.sub(accrualBlock);
        uint256 reservesInterest = borrowRatePerBlock()
            .mul(deltaBlock)
            .mul(reserveFactor)
            .div(FACTOR)
            .mul(totalBorrows)
            .div(FACTOR);
        newReserves = reserves.add(reservesInterest);
    }

    /// @notice Calculates updated protocol earning information at a given block
    /// @dev Computes the accrued protocol earning value
    /// @param _block (uint256) Block to look against
    /// @return newXtkEarnings (uint256) Updated protocol earning value
    function calculateXtkEarnings(uint256 _block) private view returns (uint256 newXtkEarnings) {
        uint256 deltaBlock = _block.sub(accrualBlock);
        uint256 xtkInterest = borrowRatePerBlock().mul(deltaBlock).mul(xtkFeeFactor).div(FACTOR).mul(totalBorrows).div(
            FACTOR
        );
        newXtkEarnings = newXtkEarnings.add(xtkInterest);
    }

    /// @notice Lenders can supply as much USDC as they want into the Liquidity Pool
    /// @dev This will mint LPT upon updated LPT value
    /// @param _amount (uint256) Amount of USDC to be supplied into the Liquidity Pool
    function supply(uint256 _amount) external notLocked(msg.sender) whenNotPaused {
        require(liquidityPoolToken != address(0), "LPT token has not set yet");
        lock(msg.sender);
        accrueInterest();
        uint256 currentLptPrice = getLPTValue();
        IERC20(stableCoin).safeTransferFrom(msg.sender, address(this), _amount);
        ILPT(liquidityPoolToken).mint(msg.sender, _amount.mul(currentLptPrice).div(FACTOR));
    }

    /// @notice Lenders can exchange their LPT for USDC upon interes earned by the protocol
    /// @dev This will burn LPT in exchange for USDC
    /// @param _lptAmount (uint256) Amount of LPT to be burned
    function withdraw(uint256 _lptAmount) external notLocked(msg.sender) whenNotPaused {
        lock(msg.sender);
        accrueInterest();
        uint256 currentLptPrice = getLPTValue();
        uint256 currentCash = currentLiquidity();
        uint256 usdcAmount = _lptAmount.mul(FACTOR).div(currentLptPrice);
        uint256 finalAmount = usdcAmount;
        uint256 finalLPTAmount = _lptAmount;
        if (currentCash < usdcAmount) {
            finalAmount = currentCash;
            // rounding to the protocol
            finalLPTAmount = (finalAmount.mul(currentLptPrice).sub(1)).div(FACTOR).add(1);
        }
        ILPT(liquidityPoolToken).burnFrom(msg.sender, finalLPTAmount);
        IERC20(stableCoin).safeTransfer(msg.sender, finalAmount);
    }

    /// @notice Borrowers can borrow USDC having their collaterals as guarantee
    /// @dev Borrowers can only borrow the minimum loan value or more in order to avoid gas fee costs that are not worthy to pay for
    /// @dev Borrowers can only borrow the specified amount if they have enough collateral. Despite they can borrow 100% of that,
    /// @dev it is recommended to borrow up to 80% of that value
    /// @param _amount (uint256) Borrow amount
    function borrow(uint256 _amount) external notLocked(msg.sender) whenNotPaused {
        lock(msg.sender);
        accrueInterest();

        Borrow storage borrowerBorrow = borrows[msg.sender];
        uint256 updatedBorrowAmount = updatedBorrowBy(msg.sender);

        require(
            IComptroller(comptroller).borrowingCapacity(msg.sender).sub(updatedBorrowAmount) >= _amount,
            "You have not enough collateral to borrow this amount"
        );
        updatedBorrowAmount = updatedBorrowAmount.add(_amount);
        require(updatedBorrowAmount >= minimumLoanValue, "You must borrow the minimum loan value or more");

        borrowerBorrow.amount = updatedBorrowAmount;
        borrowerBorrow.interestIndex = borrowIndex;
        borrowerBorrow.borrowedAtBlock = block.number;
        totalBorrows = totalBorrows.add(_amount);

        IERC20(stableCoin).safeTransfer(msg.sender, _amount);

        emit BorrowEvent(msg.sender, _amount, updatedBorrowAmount);
    }

    /// @notice Borrowers can pay a portion of their debt
    /// @dev The borrower has to have a borrow active amount
    /// @dev If the borrower pays more than he owes, the payment is done by the whole debt and not all of the amount is used
    /// @param _amount (uint256) Borrow amount
    function repay(uint256 _amount) public notLocked(msg.sender) whenNotPaused {
        lock(msg.sender);
        accrueInterest();

        Borrow storage borrowerBorrow = borrows[msg.sender];

        uint256 updatedBorrowAmount = updatedBorrowBy(msg.sender);
        borrowerBorrow.interestIndex = borrowIndex;

        require(updatedBorrowAmount > 0, "You have no borrows to be repaid");

        if (_amount > updatedBorrowAmount) _amount = updatedBorrowAmount;

        updatedBorrowAmount = updatedBorrowAmount.sub(_amount);
        require(
            updatedBorrowAmount == 0 || updatedBorrowAmount >= minimumLoanValue,
            "You must borrow the minimum loan value or more"
        );

        borrowerBorrow.amount = updatedBorrowAmount;
        totalBorrows = totalBorrows.sub(_amount);

        IERC20(stableCoin).safeTransferFrom(msg.sender, address(this), _amount);

        emit RepayEvent(msg.sender, _amount, updatedBorrowAmount);
    }

    /// @notice Borrowers can pay all of their debt
    /// @dev The borrower can not pay in the same block that they borrowedfrom. This is to avoid attacks of other smart contracts
    /// @dev The borrower has to have a borrow active amount
    function payAll() external {
        repay(uint256(-1));
    }

    /// @notice Liquidator can liquidate a portion of a loan on behalf of a borrower
    /// @dev The protocol decides first the more stable markets, then the more volatile ones to reward the liquidator
    /// @param _borrower (address) Borrower's address
    /// @param _amount (address) Borrower's address
    function liquidate(address _borrower, uint256 _amount) external whenNotPaused {
        address[] memory emptyMarkets = new address[](0);
        liquidateInternal(_borrower, _amount, emptyMarkets);

        emit LiquidateEvent(_borrower, msg.sender, _amount, emptyMarkets);
    }

    /// @notice Liquidator can liquidate a portion of a loan on behalf of a borrower
    /// @dev The liquidator decides the order of markets they want to get collaterals from
    /// @param _borrower (address) Borrower's address
    /// @param _amount (address) Borrow amount
    /// @param _markets (address) Peferred markets addresses
    function liquidateWithPreference(
        address _borrower,
        uint256 _amount,
        address[] memory _markets
    ) external whenNotPaused {
        liquidateInternal(_borrower, _amount, _markets);

        emit LiquidateEvent(_borrower, msg.sender, _amount, _markets);
    }

    /// @notice Internal liquidate function
    /// @dev This is the one performing the liquidation logic
    /// @param _borrower (address) Borrower's address
    /// @param _amount (uint256) Amount to be liquidated
    /// @param _markets (address[] memory) Preferred markets if applies
    function liquidateInternal(
        address _borrower,
        uint256 _amount,
        address[] memory _markets
    ) private {
        accrueInterest();
        require(_borrower != msg.sender, "You are not allowed to liquidate your own debt");

        Borrow storage borrowerBorrow = borrows[_borrower];
        require(borrowerBorrow.amount > 0, "You have no borrows to be repaid");

        uint256 updatedBorrowAmount = updatedBorrowBy(_borrower);
        borrowerBorrow.interestIndex = borrowIndex;

        require(
            IComptroller(comptroller).getHealthRatio(_borrower) < 100,
            "You can not liquidate this loan because it has a good health factor"
        );

        if (_amount > updatedBorrowAmount) _amount = updatedBorrowAmount;

        borrowerBorrow.amount = updatedBorrowAmount.sub(_amount);
        totalBorrows = totalBorrows.sub(_amount);

        IERC20(stableCoin).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 amount = _amount.mul(FACTOR).div(uint256(1e18).sub(liquidityPenaltyFactor));

        if (_markets.length == 0) IComptroller(comptroller).sendCollateralToLiquidator(msg.sender, _borrower, amount);
        else
            IComptroller(comptroller).sendCollateralToLiquidatorWithPreference(msg.sender, _borrower, amount, _markets);
    }

    /// @notice Only owners can withdraw protocol earnings
    /// @param _recipient (address) Owners specify where to send the earnings
    function withdrawFees(address _recipient) external onlyOwner {
        require(_recipient != address(0));
        uint256 feeAmount = xtkEarns;
        xtkEarns = 0;
        IERC20(stableCoin).safeTransfer(_recipient, feeAmount);
        emit WithdrawFee(_recipient, feeAmount);
    }

    /// @notice Owners can determine the LPT address
    /// @param _liquidityPoolToken (address) LPT address
    function setLiquidityPoolToken(address _liquidityPoolToken) external onlyOwner {
        require(_liquidityPoolToken != address(0));
        liquidityPoolToken = _liquidityPoolToken;
        emit UpdateLiquidityPoolToken(_liquidityPoolToken);
    }

    /// @notice Owners can determine the Comptroller address
    /// @param _comptroller (address) Comptroller address
    function setComptroller(address _comptroller) external onlyOwner {
        comptroller = _comptroller;
        emit UpdateComptroller(_comptroller);
    }

    /// @notice Owners can determine the interes model variables
    /// @dev This parameters must be entered as percentages. Ex 35 is meant to be understood as 35%
    /// @param _optimalUtilizationRate (uint256) Optimal utilization rate
    /// @param _baseBorrowRate (uint256) Base borrow rate
    /// @param _slope1 (uint256) Slope 1
    /// @param _slope2 (uint256) Slope 2
    function setInterestModelParameters(
        uint256 _optimalUtilizationRate,
        uint256 _baseBorrowRate,
        uint256 _slope1,
        uint256 _slope2
    ) external onlyOwner {
        accrueInterest();

        optimalUtilizationRate = _optimalUtilizationRate.mul(RATIOS);
        baseBorrowRate = _baseBorrowRate.mul(RATIOS);
        slope1 = _slope1.mul(RATIOS);
        slope2 = _slope2.mul(RATIOS);

        emit UpdateInterestModelParameters(_optimalUtilizationRate, _baseBorrowRate, _slope1, _slope2);
    }

    /// @notice Owners can determine the reserve factor value
    /// @dev This parameter must be entered as percentage. Ex 35 is meant to be understood as 35%
    /// @param _reserveFactor (uint256) Reserve factor
    function setReserveFactor(uint256 _reserveFactor) external onlyOwner {
        accrueInterest();
        reserveFactor = _reserveFactor.mul(RATIOS);
        emit UpdateReserveFeeFactor(_reserveFactor);
    }

    /// @notice Owners can determine the protocol earning factor value
    /// @dev This parameter must be entered as percentage. Ex 35 is meant to be understood as 35%
    /// @param _xtkFeeFactor (uint256) Protocol earning factor
    function setXtkFeeFactor(uint256 _xtkFeeFactor) external onlyOwner {
        accrueInterest();
        xtkFeeFactor = _xtkFeeFactor.mul(RATIOS);
        emit UpdateXtkFeeFactor(_xtkFeeFactor);
    }

    /// @notice Owners can determine the protocol earning factor value
    /// @param _lptBaseValue (uint256) Liquidity Pool Token Base Value
    function setLPTBaseValue(uint256 _lptBaseValue) external onlyOwner {
        lptBaseValue = _lptBaseValue;
        emit UpdateLPTBaseValue(_lptBaseValue);
    }

    /// @notice Owners can determine the minimum loan value
    /// @param _minimumLoanValue (uint256) Minimum loan value
    function setMinimumLoanValue(uint256 _minimumLoanValue) external onlyOwner {
        minimumLoanValue = _minimumLoanValue;
        emit UpdateMiniumLoanValue(_minimumLoanValue);
    }

    /// @notice Owners can determine the liquidation penalty factor value
    /// @dev This parameter must be entered as percentage. Ex 35 is meant to be understood as 35%
    /// @param _liquidityPenaltyFactor (uint256) Liquidation penalty factor
    function setLiquidationPenaltyFactor(uint256 _liquidityPenaltyFactor) external onlyOwner {
        liquidityPenaltyFactor = _liquidityPenaltyFactor.mul(RATIOS);
        emit UpdateMiniumLoanValue(_liquidityPenaltyFactor);
    }

    /// @notice Owner function: pause all user actions
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Owner function: unpause
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Optmial utilization rate
    /// @dev This parameter must be understood as a percentage. Ex 35 is meant to be understood as 35%
    /// @return (uint256) Optimal utilization rate
    function getOptimalUtilizationRate() external view returns (uint256) {
        return optimalUtilizationRate.div(RATIOS);
    }

    /// @notice Base borrow rate
    /// @dev This parameter must be understood as a percentage. Ex 35 is meant to be understood as 35%
    /// @return (uint256) Base borrow rate
    function getBaseBorrowRate() external view returns (uint256) {
        return baseBorrowRate.div(RATIOS);
    }

    /// @notice Slope 1
    /// @dev This parameter must be understood as a percentage. Ex 35 is meant to be understood as 35%
    /// @return (uint256) Slope 1
    function getSlope1() external view returns (uint256) {
        return slope1.div(RATIOS);
    }

    /// @notice Slope 2
    /// @dev This parameter must be understood as a percentage. Ex 35 is meant to be understood as 35%
    /// @return (uint256) Slope 2
    function getSlope2() external view returns (uint256) {
        return slope2.div(RATIOS);
    }

    /// @notice Reserve factor
    /// @dev This parameter must be understood as a percentage. Ex 35 is meant to be understood as 35%
    /// @return (uint256) Reserve factor
    function getReserveFactor() external view returns (uint256) {
        return reserveFactor.div(RATIOS);
    }

    /// @notice Protocol earnings factor
    /// @dev This parameter must be understood as a percentage. Ex 35 is meant to be understood as 35%
    /// @return (uint256) Protocol earnings factor
    function getXtkFeeFactor() external view returns (uint256) {
        return xtkFeeFactor.div(RATIOS);
    }

    /// @notice LPT Base Value
    /// @return (uint256) LPT Base Value
    function getLPTBaseValue() external view returns (uint256) {
        return lptBaseValue;
    }

    /// @notice Gets the updated value of the liquidity pool token based on activity
    /// @return (uint256) Current LPT value
    function getLPTValue() public view returns (uint256) {
        uint256 totalSupplyLiquidityPool = IERC20(liquidityPoolToken).totalSupply();
        if (totalSupplyLiquidityPool == 0) return lptBaseValue;
        return
            totalSupplyLiquidityPool.mul(FACTOR).div(currentLiquidity().add(totalBorrows).sub(reserves).sub(xtkEarns));
    }

    /// @notice Minimum Loan Value
    /// @return (uint256) Minimum Loan Value
    function getMinimumLoanValue() external view returns (uint256) {
        return minimumLoanValue;
    }

    /// @notice Liquidation Penalty factor
    /// @dev This parameter must be understood as a percentage. Ex 35 is meant to be understood as 35%
    /// @return (uint256) Liquidation Penalty factor
    function getLiquidationPenaltyFactor() external view returns (uint256) {
        return liquidityPenaltyFactor.div(RATIOS);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

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
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

interface ILiquidityPool {
    function updatedBorrowBy(address _borrower) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

interface IComptroller {
    function addMarket(address _market) external;

    function setLiquidityPool(address _liquidityPool) external;

    function borrowingCapacity(address _borrower) external view returns (uint256 capacity);

    function addBorrowerMarket(address _borrower, address _market) external;

    function removeBorrowerMarket(address _borrower, address _market) external;

    function getHealthRatio(address _borrower) external view returns (uint256);

    function sendCollateralToLiquidator(
        address _liquidator,
        address _borrower,
        uint256 _amount
    ) external;

    function sendCollateralToLiquidatorWithPreference(
        address _liquidator,
        address _borrower,
        uint256 _amount,
        address[] memory _markets
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

interface ILPT {
    function mint(address _recipient, uint256 _amount) external returns (bool);

    function burnFrom(address _sender, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.3;

/**
 Contract which implements locking of functions via a notLocked modifier
 Functions are locked per address. 
 */
contract BlockLock {
    // how many blocks are the functions locked for
    uint256 private constant BLOCK_LOCK_COUNT = 16;
    // last block for which this address is timelocked
    mapping(address => uint256) public lastLockedBlock;

    function lock(address _address) internal {
        lastLockedBlock[_address] = block.number + BLOCK_LOCK_COUNT;
    }

    modifier notLocked(address lockedAddress) {
        require(lastLockedBlock[lockedAddress] <= block.number);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
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