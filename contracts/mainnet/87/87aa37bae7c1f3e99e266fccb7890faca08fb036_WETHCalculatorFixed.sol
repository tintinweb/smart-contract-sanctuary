// File: @openzeppelin/contracts/GSN/Context.sol



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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



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

// File: @openzeppelin/contracts/math/SafeMath.sol



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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/SodaMaster.sol



/*

Here we have a list of constants. In order to get access to an address
managed by SodaMaster, the calling contract should copy and define
some of these constants and use them as keys.

Keys themselves are immutable. Addresses can be immutable or mutable.

a) Vault addresses are immutable once set, and the list may grow:

K_VAULT_WETH = 0;
K_VAULT_USDT_ETH_SUSHI_LP = 1;
K_VAULT_SOETH_ETH_UNI_V2_LP = 2;
K_VAULT_SODA_ETH_UNI_V2_LP = 3;
K_VAULT_GT = 4;
K_VAULT_GT_ETH_UNI_V2_LP = 5;


b) SodaMade token addresses are immutable once set, and the list may grow:

K_MADE_SOETH = 0;


c) Strategy addresses are mutable:

K_STRATEGY_CREATE_SODA = 0;
K_STRATEGY_EAT_SUSHI = 1;
K_STRATEGY_SHARE_REVENUE = 2;


d) Calculator addresses are mutable:

K_CALCULATOR_WETH = 0;

Solidity doesn't allow me to define global constants, so please
always make sure the key name and key value are copied as the same
in different contracts.

*/


// SodaMaster manages the addresses all the other contracts of the system.
// This contract is owned by Timelock.
contract SodaMaster is Ownable {

    address public pool;
    address public bank;
    address public revenue;
    address public dev;

    address public soda;
    address public wETH;
    address public usdt;

    address public uniswapV2Factory;

    mapping(address => bool) public isVault;
    mapping(uint256 => address) public vaultByKey;

    mapping(address => bool) public isSodaMade;
    mapping(uint256 => address) public sodaMadeByKey;

    mapping(address => bool) public isStrategy;
    mapping(uint256 => address) public strategyByKey;

    mapping(address => bool) public isCalculator;
    mapping(uint256 => address) public calculatorByKey;

    // Immutable once set.
    function setPool(address _pool) external onlyOwner {
        require(pool == address(0));
        pool = _pool;
    }

    // Immutable once set.
    // Bank owns all the SodaMade tokens.
    function setBank(address _bank) external onlyOwner {
        require(bank == address(0));
        bank = _bank;
    }

    // Mutable in case we want to upgrade this module.
    function setRevenue(address _revenue) external onlyOwner {
        revenue = _revenue;
    }

    // Mutable in case we want to upgrade this module.
    function setDev(address _dev) external onlyOwner {
        dev = _dev;
    }

    // Mutable, in case Uniswap has changed or we want to switch to sushi.
    // The core systems, Pool and Bank, don't rely on Uniswap, so there is no risk.
    function setUniswapV2Factory(address _uniswapV2Factory) external onlyOwner {
        uniswapV2Factory = _uniswapV2Factory;
    }

    // Immutable once set.
    function setWETH(address _wETH) external onlyOwner {
       require(wETH == address(0));
       wETH = _wETH;
    }

    // Immutable once set. Hopefully Tether is reliable.
    // Even if it fails, not a big deal, we only used USDT to estimate APY.
    function setUSDT(address _usdt) external onlyOwner {
        require(usdt == address(0));
        usdt = _usdt;
    }
 
    // Immutable once set.
    function setSoda(address _soda) external onlyOwner {
        require(soda == address(0));
        soda = _soda;
    }

    // Immutable once added, and you can always add more.
    function addVault(uint256 _key, address _vault) external onlyOwner {
        require(vaultByKey[_key] == address(0), "vault: key is taken");

        isVault[_vault] = true;
        vaultByKey[_key] = _vault;
    }

    // Immutable once added, and you can always add more.
    function addSodaMade(uint256 _key, address _sodaMade) external onlyOwner {
        require(sodaMadeByKey[_key] == address(0), "sodaMade: key is taken");

        isSodaMade[_sodaMade] = true;
        sodaMadeByKey[_key] = _sodaMade;
    }

    // Mutable and removable.
    function addStrategy(uint256 _key, address _strategy) external onlyOwner {
        isStrategy[_strategy] = true;
        strategyByKey[_key] = _strategy;
    }

    function removeStrategy(uint256 _key) external onlyOwner {
        isStrategy[strategyByKey[_key]] = false;
        delete strategyByKey[_key];
    }

    // Mutable and removable.
    function addCalculator(uint256 _key, address _calculator) external onlyOwner {
        isCalculator[_calculator] = true;
        calculatorByKey[_key] = _calculator;
    }

    function removeCalculator(uint256 _key) external onlyOwner {
        isCalculator[calculatorByKey[_key]] = false;
        delete calculatorByKey[_key];
    }
}

// File: contracts/calculators/ICalculator.sol


// `TOKEN` can be any ERC20 token. The first one is WETH.
abstract contract ICalculator {

    function rate() external view virtual returns(uint256);
    function minimumLTV() external view virtual returns(uint256);
    function maximumLTV() external view virtual returns(uint256);

    // Get next loan Id.
    function getNextLoanId() external view virtual returns(uint256);

    // Get loan creator address.
    function getLoanCreator(uint256 _loanId) external view virtual returns (address);

    // Get the locked `TOKEN` amount by the loan.
    function getLoanLockedAmount(uint256 _loanId) external view virtual returns (uint256);

    // Get the time by the loan.
    function getLoanTime(uint256 _loanId) external view virtual returns (uint256);

    // Get the rate by the loan.
    function getLoanRate(uint256 _loanId) external view virtual returns (uint256);

    // Get the minimumLTV by the loan.
    function getLoanMinimumLTV(uint256 _loanId) external view virtual returns (uint256);

    // Get the maximumLTV by the loan.
    function getLoanMaximumLTV(uint256 _loanId) external view virtual returns (uint256);

    // Get the SoMade amount of the loan principal.
    function getLoanPrincipal(uint256 _loanId) external view virtual returns (uint256);

    // Get the SoMade amount of the loan interest.
    function getLoanInterest(uint256 _loanId) external view virtual returns (uint256);

    // Get the SoMade amount that the user needs to pay back in full.
    function getLoanTotal(uint256 _loanId) external view virtual returns (uint256);

    // Get the extra fee for collection in SoMade.
    function getLoanExtra(uint256 _loanId) external view virtual returns (uint256);

    // Lend SoMade to create a new loan.
    //
    // Only SodaPool can call this contract, and SodaPool should make sure the
    // user has enough `TOKEN` deposited.
    function borrow(address _who, uint256 _amount) external virtual;

    // Pay back to a loan fully.
    //
    // Only SodaPool can call this contract.
    function payBackInFull(uint256 _loanId) external virtual;

    // Collect debt if someone defaults.
    //
    // Only SodaPool can call this contract, and SodaPool should send `TOKEN` to
    // the debt collector.
    function collectDebt(uint256 _loanId) external virtual;
}

// File: contracts/calculators/WETHCalculator.sol






// This calculator fitures out lending SoETH by depositing WETH.
// All the money are still managed by the pool, but the calculator tells him
// what to do.
// This contract is owned by Timelock.
contract WETHCalculator is Ownable, ICalculator {
    using SafeMath for uint256;

    uint256 constant RATE_BASE = 1e6;
    uint256 constant LTV_BASE = 100;

    SodaMaster public sodaMaster;

    uint256 public override rate;  // Daily interest rate, a number between 0 and 10000.
    uint256 public override minimumLTV;  // Minimum Loan-to-value ratio, a number between 10 and 90.
    uint256 public override maximumLTV;  // Maximum Loan-to-value ratio, a number between 15 and 95.

    // We will start with rate = 500, which means 0.05% daily interest.
    // We will initially set _minimumLTV as 90, and maximumLTV as 95.
    // It should work perfectly, however, we may change it based on governance.
    // The maximum daily interest is 1%, and maximumLTV - _minimumLTV >= 5.
    // As a result, user has at least 5 days to do something.

    // Info of each loan.
    struct LoanInfo {
        address who;  // The user that creats the loan.
        uint256 amount;  // How many SoETH tokens the user has lended.
        uint256 lockedAmount;  // How many WETH tokens the user has locked.
        uint256 time;  // When the loan is created or updated.
        uint256 rate;  // At what daily interest rate the user lended.
        uint256 minimumLTV;  // At what minimum loan-to-deposit ratio the user lended.
        uint256 maximumLTV;  // At what maximum loan-to-deposit ratio the user lended.
    }

    mapping (uint256 => LoanInfo) public loanInfo;  // loanId => LoanInfo
    uint256 private nextLoanId;

    constructor(SodaMaster _sodaMaster) public {
        sodaMaster = _sodaMaster;
    }

    // Change the bank's interest rate and LTVs.
    // Can only be called by the owner.
    // The change should only affect loans made after it.
    function changeRateAndLTV(uint256 _rate, uint256 _minimumLTV, uint256 _maximumLTV) public onlyOwner {
        require(_rate <= RATE_BASE, "_rate <= RATE_BASE");
        require(_minimumLTV + 5 <= _maximumLTV, "+ 5 <= _maximumLTV");
        require(_minimumLTV >= 10, ">= 10");
        require(_maximumLTV <= 95, "<= 95");

        rate = _rate;
        minimumLTV = _minimumLTV;
        maximumLTV = _maximumLTV;
    }

    /**
     * @dev See {ICalculator-getNextLoanId}.
     */
    function getNextLoanId() external view override returns(uint256) {
        return nextLoanId;
    }

    /**
     * @dev See {ICalculator-getLoanCreator}.
     */
    function getLoanCreator(uint256 _loanId) external view override returns (address) {
        return loanInfo[_loanId].who;
    }

    /**
     * @dev See {ICalculator-getLoanPrincipal}.
     */
    function getLoanPrincipal(uint256 _loanId) public view override returns (uint256) {
        return loanInfo[_loanId].amount;
    }

    /**
     * @dev See {ICalculator-getLoanPrincipal}.
     */
    function getLoanInterest(uint256 _loanId) public view override returns (uint256) {
        uint256 principal = loanInfo[_loanId].amount;
        uint256 durationByDays = now.sub(loanInfo[_loanId].time) / (1 days) + 1;

        uint256 interest = loanInfo[_loanId].amount.mul(loanInfo[_loanId].rate).div(RATE_BASE).mul(durationByDays);
        uint256 lockedAmount = loanInfo[_loanId].lockedAmount;
        uint256 maximumAmount = lockedAmount.mul(loanInfo[_loanId].maximumLTV).div(LTV_BASE);

        // Interest has a cap. After that collector will collect.
        if (principal + interest <= maximumAmount) {
            return interest;
        } else {
            return maximumAmount - principal;
        }
    }

    /**
     * @dev See {ICalculator-getLoanTotal}.
     */
    function getLoanTotal(uint256 _loanId) public view override returns (uint256) {
        return getLoanPrincipal(_loanId) + getLoanInterest(_loanId);
    }

    /**
     * @dev See {ICalculator-getLoanExtra}.
     */
    function getLoanExtra(uint256 _loanId) external view override returns (uint256) {
        uint256 lockedAmount = loanInfo[_loanId].lockedAmount;
        uint256 maximumAmount = lockedAmount.mul(loanInfo[_loanId].maximumLTV).div(LTV_BASE);
        require(lockedAmount >= maximumAmount, "getLoanExtra: >=");
        return (lockedAmount - maximumAmount) / 2;
    }

    /**
     * @dev See {ICalculator-getLoanLockedAmount}.
     */
    function getLoanLockedAmount(uint256 _loanId) external view override returns (uint256) {
        return loanInfo[_loanId].lockedAmount;
    }

    /**
     * @dev See {ICalculator-getLoanTime}.
     */
    function getLoanTime(uint256 _loanId) external view override returns (uint256) {
        return loanInfo[_loanId].time;
    }

    /**
     * @dev See {ICalculator-getLoanRate}.
     */
    function getLoanRate(uint256 _loanId) external view override returns (uint256) {
        return loanInfo[_loanId].rate;
    }

    /**
     * @dev See {ICalculator-getLoanMinimumLTV}.
     */
    function getLoanMinimumLTV(uint256 _loanId) external view override returns (uint256) {
        return loanInfo[_loanId].minimumLTV;
    }

    /**
     * @dev See {ICalculator-getLoanMaximumLTV}.
     */
    function getLoanMaximumLTV(uint256 _loanId) external view override returns (uint256) {
        return loanInfo[_loanId].maximumLTV;
    }

    /**
     * @dev See {ICalculator-borrow}.
     */
    function borrow(address _who, uint256 _amount) external override {
        require(msg.sender == sodaMaster.bank(), "sender not bank");

        uint256 lockedAmount = _amount.mul(LTV_BASE).div(minimumLTV);
        require(lockedAmount >= 1, "lock at least 1 WETH");

        loanInfo[nextLoanId].who = _who;
        loanInfo[nextLoanId].amount = _amount;
        loanInfo[nextLoanId].lockedAmount = lockedAmount;
        loanInfo[nextLoanId].time = now;
        loanInfo[nextLoanId].rate = rate;
        loanInfo[nextLoanId].minimumLTV = minimumLTV;
        loanInfo[nextLoanId].maximumLTV = maximumLTV;
        ++nextLoanId;
    }

    /**
     * @dev See {ICalculator-payBackInFull}.
     */
    function payBackInFull(uint256 _loanId) external override {
        require(msg.sender == sodaMaster.bank(), "sender not bank");

        loanInfo[_loanId].amount = 0;
        loanInfo[_loanId].lockedAmount = 0;

        loanInfo[_loanId].time = now;
    }

    /**
     * @dev See {ICalculator-collectDebt}.
     */
    function collectDebt(uint256 _loanId) external override {
        require(msg.sender == sodaMaster.bank(), "sender not bank");

        uint256 loanTotal = getLoanTotal(_loanId);
        uint256 maximumLoan = loanInfo[_loanId].amount.mul(loanInfo[_loanId].maximumLTV).div(LTV_BASE);

        // You can collect only if the user defaults.
        require(loanTotal >= maximumLoan, "collectDebt: >=");

        // Now the debt is clear. SodaPool, please do the rest.
        loanInfo[_loanId].amount = 0;
        loanInfo[_loanId].lockedAmount = 0;
        loanInfo[_loanId].time = now;
    }
}

// File: contracts/calculators/WETHCalculatorFixed.sol







// This calculator fitures out lending SoETH by depositing WETH.
// All the money are still managed by the pool, but the calculator tells him
// what to do.
// This contract is owned by Timelock.
contract WETHCalculatorFixed is Ownable, ICalculator {
    using SafeMath for uint256;

    uint256 constant RATE_BASE = 1e6;
    uint256 constant LTV_BASE = 100;

    SodaMaster public sodaMaster;

    uint256 public override rate;  // Daily interest rate, a number between 0 and 10000.
    uint256 public override minimumLTV;  // Minimum Loan-to-value ratio, a number between 10 and 90.
    uint256 public override maximumLTV;  // Maximum Loan-to-value ratio, a number between 15 and 95.

    // We will start with rate = 500, which means 0.05% daily interest.
    // We will initially set _minimumLTV as 90, and maximumLTV as 95.
    // It should work perfectly, however, we may change it based on governance.
    // The maximum daily interest is 1%, and maximumLTV - _minimumLTV >= 5.
    // As a result, user has at least 5 days to do something.

    // Info of each loan.
    struct LoanInfo {
        address who;  // The user that creats the loan.
        uint256 amount;  // How many SoETH tokens the user has lended.
        uint256 lockedAmount;  // How many WETH tokens the user has locked.
        uint256 time;  // When the loan is created or updated.
        uint256 rate;  // At what daily interest rate the user lended.
        uint256 minimumLTV;  // At what minimum loan-to-deposit ratio the user lended.
        uint256 maximumLTV;  // At what maximum loan-to-deposit ratio the user lended.
        bool filledByOld;
    }

    mapping (uint256 => LoanInfo) private loanInfoFixed;  // loanId => LoanInfo
    uint256 private nextLoanId;

    WETHCalculator public oldCalculator;

    uint256 constant LOAN_ID_START = 1e18;

    constructor(SodaMaster _sodaMaster, WETHCalculator _oldCalculator) public {
        sodaMaster = _sodaMaster;
        oldCalculator = _oldCalculator;

        // Start loanId from a large enough number.
        nextLoanId = LOAN_ID_START;
    }

    function loanInfo(uint256 _loanId) public returns (address, uint256, uint256, uint256, uint256, uint256, uint256) {
      if (_loanId < LOAN_ID_START && !loanInfoFixed[_loanId].filledByOld) {
        return oldCalculator.loanInfo(_loanId);
      } else {
        address who = loanInfoFixed[nextLoanId].who;
        uint256 amount = loanInfoFixed[nextLoanId].amount;
        uint256 lockedAmount = loanInfoFixed[nextLoanId].lockedAmount;
        uint256 time = loanInfoFixed[nextLoanId].time;
        uint256 rate = loanInfoFixed[nextLoanId].rate;
        uint256 minimumLTV = loanInfoFixed[nextLoanId].minimumLTV;
        uint256 maximumLTV = loanInfoFixed[nextLoanId].maximumLTV;
        return (who, amount, lockedAmount, time, rate, minimumLTV, maximumLTV);
      }
    }

    // Change the bank's interest rate and LTVs.
    // Can only be called by the owner.
    // The change should only affect loans made after it.
    function changeRateAndLTV(uint256 _rate, uint256 _minimumLTV, uint256 _maximumLTV) public onlyOwner {
        require(_rate <= RATE_BASE, "_rate <= RATE_BASE");
        require(_minimumLTV + 5 <= _maximumLTV, "+ 5 <= _maximumLTV");
        require(_minimumLTV >= 10, ">= 10");
        require(_maximumLTV <= 95, "<= 95");

        rate = _rate;
        minimumLTV = _minimumLTV;
        maximumLTV = _maximumLTV;
    }

    /**
     * @dev See {ICalculator-getNextLoanId}.
     */
    function getNextLoanId() external view override returns(uint256) {
        return nextLoanId;
    }

    /**
     * @dev See {ICalculator-getLoanCreator}.
     */
    function getLoanCreator(uint256 _loanId) external view override returns (address) {
        if (_loanId < LOAN_ID_START  && !loanInfoFixed[_loanId].filledByOld) {
            return oldCalculator.getLoanCreator(_loanId);
        }

        return loanInfoFixed[_loanId].who;
    }

    /**
     * @dev See {ICalculator-getLoanPrincipal}.
     */
    function getLoanPrincipal(uint256 _loanId) public view override returns (uint256) {
        if (_loanId < LOAN_ID_START && !loanInfoFixed[_loanId].filledByOld) {
            return oldCalculator.getLoanPrincipal(_loanId);
        }

        return loanInfoFixed[_loanId].amount;
    }

    /**
     * @dev See {ICalculator-getLoanPrincipal}.
     */
    function getLoanInterest(uint256 _loanId) public view override returns (uint256) {
        if (_loanId < LOAN_ID_START && !loanInfoFixed[_loanId].filledByOld) {
            return oldCalculator.getLoanInterest(_loanId);
        }

        uint256 principal = loanInfoFixed[_loanId].amount;
        uint256 durationByDays = now.sub(loanInfoFixed[_loanId].time) / (1 days) + 1;

        uint256 interest = loanInfoFixed[_loanId].amount.mul(loanInfoFixed[_loanId].rate).div(RATE_BASE).mul(durationByDays);
        uint256 lockedAmount = loanInfoFixed[_loanId].lockedAmount;
        uint256 maximumAmount = lockedAmount.mul(loanInfoFixed[_loanId].maximumLTV).div(LTV_BASE);

        // Interest has a cap. After that collector will collect.
        if (principal + interest <= maximumAmount) {
            return interest;
        } else {
            return maximumAmount - principal;
        }
    }

    /**
     * @dev See {ICalculator-getLoanTotal}.
     */
    function getLoanTotal(uint256 _loanId) public view override returns (uint256) {
        if (_loanId < LOAN_ID_START && !loanInfoFixed[_loanId].filledByOld) {
            return oldCalculator.getLoanTotal(_loanId);
        }

        return getLoanPrincipal(_loanId) + getLoanInterest(_loanId);
    }

    /**
     * @dev See {ICalculator-getLoanExtra}.
     */
    function getLoanExtra(uint256 _loanId) external view override returns (uint256) {
        if (_loanId < LOAN_ID_START && !loanInfoFixed[_loanId].filledByOld) {
            return oldCalculator.getLoanExtra(_loanId);
        }

        uint256 lockedAmount = loanInfoFixed[_loanId].lockedAmount;
        uint256 maximumAmount = lockedAmount.mul(loanInfoFixed[_loanId].maximumLTV).div(LTV_BASE);
        require(lockedAmount >= maximumAmount, "getLoanExtra: >=");
        return (lockedAmount - maximumAmount) / 2;
    }

    /**
     * @dev See {ICalculator-getLoanLockedAmount}.
     */
    function getLoanLockedAmount(uint256 _loanId) external view override returns (uint256) {
        if (_loanId < LOAN_ID_START && !loanInfoFixed[_loanId].filledByOld) {
            return oldCalculator.getLoanLockedAmount(_loanId);
        }

        return loanInfoFixed[_loanId].lockedAmount;
    }

    /**
     * @dev See {ICalculator-getLoanTime}.
     */
    function getLoanTime(uint256 _loanId) external view override returns (uint256) {
        if (_loanId < LOAN_ID_START && !loanInfoFixed[_loanId].filledByOld) {
            return oldCalculator.getLoanTime(_loanId);
        }

        return loanInfoFixed[_loanId].time;
    }

    /**
     * @dev See {ICalculator-getLoanRate}.
     */
    function getLoanRate(uint256 _loanId) external view override returns (uint256) {
        if (_loanId < LOAN_ID_START && !loanInfoFixed[_loanId].filledByOld) {
            return oldCalculator.getLoanRate(_loanId);
        }

        return loanInfoFixed[_loanId].rate;
    }

    /**
     * @dev See {ICalculator-getLoanMinimumLTV}.
     */
    function getLoanMinimumLTV(uint256 _loanId) external view override returns (uint256) {
        if (_loanId < LOAN_ID_START && !loanInfoFixed[_loanId].filledByOld) {
            return oldCalculator.getLoanMinimumLTV(_loanId);
        }

        return loanInfoFixed[_loanId].minimumLTV;
    }

    /**
     * @dev See {ICalculator-getLoanMaximumLTV}.
     */
    function getLoanMaximumLTV(uint256 _loanId) external view override returns (uint256) {
        if (_loanId < LOAN_ID_START && !loanInfoFixed[_loanId].filledByOld) {
            return oldCalculator.getLoanMaximumLTV(_loanId);
        }

        return loanInfoFixed[_loanId].maximumLTV;
    }

    /**
     * @dev See {ICalculator-borrow}.
     */
    function borrow(address _who, uint256 _amount) external override {
        require(msg.sender == sodaMaster.bank(), "sender not bank");

        uint256 lockedAmount = _amount.mul(LTV_BASE).div(minimumLTV);
        require(lockedAmount >= 1, "lock at least 1 WETH");

        loanInfoFixed[nextLoanId].who = _who;
        loanInfoFixed[nextLoanId].amount = _amount;
        loanInfoFixed[nextLoanId].lockedAmount = lockedAmount;
        loanInfoFixed[nextLoanId].time = now;
        loanInfoFixed[nextLoanId].rate = rate;
        loanInfoFixed[nextLoanId].minimumLTV = minimumLTV;
        loanInfoFixed[nextLoanId].maximumLTV = maximumLTV;
        ++nextLoanId;
    }

    /**
     * @dev See {ICalculator-payBackInFull}.
     */
    function payBackInFull(uint256 _loanId) external override {
        require(msg.sender == sodaMaster.bank(), "sender not bank");

        if (_loanId < LOAN_ID_START && !loanInfoFixed[_loanId].filledByOld) {
            address who;  // The user that creats the loan.
            uint256 amount;  // How many SoETH tokens the user has lended.
            uint256 lockedAmount;  // How many WETH tokens the user has locked.
            uint256 time;  // When the loan is created or updated.
            uint256 rate;  // At what daily interest rate the user lended.
            uint256 minimumLTV;  // At what minimum loan-to-deposit ratio the user lended.
            uint256 maximumLTV;

            (who, amount, lockedAmount, time, rate, minimumLTV, maximumLTV) = oldCalculator.loanInfo(_loanId);

            loanInfoFixed[_loanId].who = who;
            // loanInfoFixed[_loanId].amount = amount;
            // loanInfoFixed[_loanId].lockedAmount = lockedAmount;
            // loanInfoFixed[_loanId].time = time;
            loanInfoFixed[_loanId].rate = rate;
            loanInfoFixed[_loanId].minimumLTV = minimumLTV;
            loanInfoFixed[_loanId].maximumLTV = maximumLTV;
            loanInfoFixed[_loanId].filledByOld = true;
        }

        loanInfoFixed[_loanId].amount = 0;
        loanInfoFixed[_loanId].lockedAmount = 0;

        loanInfoFixed[_loanId].time = now;
    }

    /**
     * @dev See {ICalculator-collectDebt}.
     */
    function collectDebt(uint256 _loanId) external override {
        require(msg.sender == sodaMaster.bank(), "sender not bank");

        if (_loanId < LOAN_ID_START && !loanInfoFixed[_loanId].filledByOld) {
            address who;  // The user that creats the loan.
            uint256 amount;  // How many SoETH tokens the user has lended.
            uint256 lockedAmount;  // How many WETH tokens the user has locked.
            uint256 time;  // When the loan is created or updated.
            uint256 rate;  // At what daily interest rate the user lended.
            uint256 minimumLTV;  // At what minimum loan-to-deposit ratio the user lended.
            uint256 maximumLTV;

            (who, amount, lockedAmount, time, rate, minimumLTV, maximumLTV) = oldCalculator.loanInfo(_loanId);

            loanInfoFixed[_loanId].who = who;
            loanInfoFixed[_loanId].amount = amount;
            loanInfoFixed[_loanId].lockedAmount = lockedAmount;
            loanInfoFixed[_loanId].time = time;
            loanInfoFixed[_loanId].rate = rate;
            loanInfoFixed[_loanId].minimumLTV = minimumLTV;
            loanInfoFixed[_loanId].maximumLTV = maximumLTV;
            loanInfoFixed[_loanId].filledByOld = true;
        }

        uint256 loanTotal = getLoanTotal(_loanId);
        uint256 maximumLoan = loanInfoFixed[_loanId].lockedAmount.mul(loanInfoFixed[_loanId].maximumLTV).div(LTV_BASE);

        // You can collect only if the user defaults.
        require(loanTotal >= maximumLoan, "collectDebt: >=");

        // Now the debt is clear. SodaPool, please do the rest.
        loanInfoFixed[_loanId].amount = 0;
        loanInfoFixed[_loanId].lockedAmount = 0;
        loanInfoFixed[_loanId].time = now;
    }
}