pragma solidity ^0.7.6;

import "./PriceOracle.sol";

abstract contract ControllerInterface {
    /// @notice Indicator that this is a Controller contract (for inspection)
    bool public constant isController = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata pTokens) external virtual returns (uint[] memory);
    function exitMarket(address pToken) external virtual returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address pToken, address minter, uint mintAmount) external virtual returns (uint);
    function redeemAllowed(address pToken, address redeemer, uint redeemTokens) external virtual returns (uint);
    function redeemVerify(address pToken, address redeemer, uint redeemAmount, uint redeemTokens) external virtual;
    function borrowAllowed(address pToken, address borrower, uint borrowAmount) external virtual returns (uint);

    function repayBorrowAllowed(
        address pToken,
        address payer,
        address borrower,
        uint repayAmount) external virtual returns (uint);

    function liquidateBorrowAllowed(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external virtual returns (uint);

    function seizeAllowed(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external virtual returns (uint);

    function transferAllowed(address pToken, address src, address dst, uint transferTokens) external virtual returns (uint);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address pTokenBorrowed,
        address pTokenCollateral,
        uint repayAmount) external view virtual returns (uint, uint);

    function getOracle() external view virtual returns (PriceOracle);
}

pragma solidity ^0.7.6;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity ^0.7.6;

/**
  * @title DeFiPie's InterestRateModel Interface
  * @author DeFiPie
  */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view virtual returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view virtual returns (uint);

}

pragma solidity ^0.7.6;

import "./ControllerInterface.sol";
import "./InterestRateModel.sol";
import "./ProxyWithRegistry.sol";

contract PTokenStorage is ProxyWithRegistryStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @dev Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @dev Maximum fraction of interest that can be set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Contract which oversees inter-pToken operations
     */
    ControllerInterface public controller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @dev Initial exchange rate used when minting the first PTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @dev Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    /**
     * @dev Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @dev Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;
}

abstract contract PTokenInterface is PTokenStorage {
    /**
     * @notice Indicator that this is a PToken contract (for inspection)
     */
    bool public constant isPToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows, uint totalReserves);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address pTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when controller is changed
     */
    event NewController(ControllerInterface oldController, ControllerInterface newController);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /*** User Interface ***/

    function transfer(address dst, uint amount) external virtual returns (bool);
    function transferFrom(address src, address dst, uint amount) external virtual returns (bool);
    function approve(address spender, uint amount) external virtual returns (bool);
    function allowance(address owner, address spender) external view virtual returns (uint);
    function balanceOf(address owner) external view virtual returns (uint);
    function balanceOfUnderlying(address owner) external virtual returns (uint);
    function getAccountSnapshot(address account) external view virtual returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view virtual returns (uint);
    function supplyRatePerBlock() external view virtual returns (uint);
    function totalBorrowsCurrent() external virtual returns (uint);
    function borrowBalanceCurrent(address account) external virtual returns (uint);
    function borrowBalanceStored(address account) public view virtual returns (uint);
    function exchangeRateCurrent() public virtual returns (uint);
    function exchangeRateStored() public view virtual returns (uint);
    function getCash() external view virtual returns (uint);
    function accrueInterest() public virtual returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external virtual returns (uint);

    /*** Admin Functions ***/

    function _setController(ControllerInterface newController) public virtual returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external virtual returns (uint);
    function _reduceReserves(uint reduceAmount) external virtual returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) public virtual returns (uint);
}

contract PErc20Storage {
    /**
     * @notice Underlying asset for this PToken
     */
    address public underlying;
}

abstract contract PErc20Interface is PErc20Storage {

    /*** User Interface ***/

    function mint(uint mintAmount) external virtual returns (uint);
    function redeem(uint redeemTokens) external virtual returns (uint);
    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);
    function borrow(uint borrowAmount) external virtual returns (uint);
    function repayBorrow(uint repayAmount) external virtual returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external virtual returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, PTokenInterface pTokenCollateral) external virtual returns (uint);

    /*** Admin Functions ***/

    function _addReserves(uint addAmount) external virtual returns (uint);
}

contract PPIEStorage {
    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;
}

abstract contract PPIEInterface is PPIEStorage {
    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    function delegate(address delegatee) external virtual;
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external virtual;
    function getCurrentVotes(address account) external view virtual returns (uint96);
    function getPriorVotes(address account, uint blockNumber) external view virtual returns (uint96);
}

pragma solidity ^0.7.6;

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    event PriceUpdated(address asset, uint price);

    /**
      * @notice Get the underlying price of a pToken asset
      * @param pToken The pToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address pToken) external view virtual returns (uint);

    function updateUnderlyingPrice(address pToken) external virtual returns (uint);
}

pragma solidity ^0.7.6;

import "./RegistryInterface.sol";

contract ProxyWithRegistryStorage {

    /**
     * @notice Address of the registry contract
     */
    address public registry;
}

abstract contract ProxyWithRegistryInterface is ProxyWithRegistryStorage {
    function _setRegistry(address _registry) internal virtual;
    function _pTokenImplementation() internal view virtual returns (address);
}

contract ProxyWithRegistry is ProxyWithRegistryInterface {
    /**
     *  Returns actual address of the implementation contract from current registry
     *  @return registry Address of the registry
     */
    function _pTokenImplementation() internal view override returns (address) {
        return RegistryInterface(registry).pTokenImplementation();
    }

    function _setRegistry(address _registry) internal override {
        registry = _registry;
    }
}

contract ImplementationStorage {

    address public implementation;

    function _setImplementation(address implementation_) internal {
        implementation = implementation_;
    }
}

pragma solidity ^0.7.6;

interface RegistryInterface {

    /**
     *  Returns admin address for cToken contracts
     *  @return admin address
     */
    function admin() external view returns (address payable);

    /**
     *  Returns address of actual PToken implementation contract
     *  @return Address of contract
     */
    function pTokenImplementation() external view returns (address);

    function addPToken(address underlying, address pToken) external returns(uint);
    function addPETH(address pETH_) external returns(uint);
    function addPPIE(address pPIE_) external returns(uint);
}

pragma solidity ^0.7.6;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
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
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
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
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
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

pragma solidity ^0.7.6;

import "../../contracts/SafeMath.sol";

interface ERC20Base {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

abstract contract ERC20 is ERC20Base {
    function transfer(address to, uint256 value) external virtual returns (bool);
    function transferFrom(address from, address to, uint256 value) external virtual returns (bool);
}

abstract contract ERC20NS is ERC20Base {
    function transfer(address to, uint256 value) external virtual;
    function transferFrom(address from, address to, uint256 value) external virtual;
}

/**
 * @title Standard ERC20 token
 * @dev Implementation of the basic standard token.
 *  See https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is ERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply_;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) internal balances;

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) {
        totalSupply_ = _initialAmount;
        balances[msg.sender] = _initialAmount;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
    }

    function transfer(address dst, uint256 amount) external virtual override returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(amount, "Insufficient balance");
        balances[dst] = balances[dst].add(amount, "Balance overflow");
        emit Transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amount) external virtual override returns (bool) {
        allowed[src][msg.sender] = allowed[src][msg.sender].sub(amount, "Insufficient allowance");
        balances[src] = balances[src].sub(amount, "Insufficient balance");
        balances[dst] = balances[dst].add(amount, "Balance overflow");
        emit Transfer(src, dst, amount);
        return true;
    }

    function approve(address _spender, uint256 amount) external override returns (bool) {
        allowed[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        override
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
    }

    function totalSupply() external view override returns (uint256) {
        return totalSupply_;
    }
}

/**
 * @title Non-Standard ERC20 token
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
contract NonStandardToken is ERC20NS {
    using SafeMath for uint256;

    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public totalSupply_;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) internal balances;

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) {
        totalSupply_ = _initialAmount;
        balances[msg.sender] = _initialAmount;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
    }

    function transfer(address dst, uint256 amount) external override {
        balances[msg.sender] = balances[msg.sender].sub(amount, "Insufficient balance");
        balances[dst] = balances[dst].add(amount, "Balance overflow");
        emit Transfer(msg.sender, dst, amount);
    }

    function transferFrom(address src, address dst, uint256 amount) external override {
        allowed[src][msg.sender] = allowed[src][msg.sender].sub(amount, "Insufficient allowance");
        balances[src] = balances[src].sub(amount, "Insufficient balance");
        balances[dst] = balances[dst].add(amount, "Balance overflow");
        emit Transfer(src, dst, amount);
    }

    function approve(address _spender, uint256 amount) external override returns (bool) {
        allowed[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        override
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
    }

    function totalSupply() external view override returns (uint256) {
        return totalSupply_;
    }

}

contract ERC20Harness is StandardToken {
    using SafeMath for uint256;
    // To support testing, we can specify addresses for which transferFrom should fail and return false
    mapping (address => bool) public failTransferFromAddresses;

    // To support testing, we allow the contract to always fail `transfer`.
    mapping (address => bool) public failTransferToAddresses;

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol)
        StandardToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {}

    function harnessSetFailTransferFromAddress(address src, bool _fail) public {
        failTransferFromAddresses[src] = _fail;
    }

    function harnessSetFailTransferToAddress(address dst, bool _fail) public {
        failTransferToAddresses[dst] = _fail;
    }

    function harnessSetBalance(address _account, uint _amount) public {
        balances[_account] = _amount;
    }

    function transfer(address dst, uint256 amount) external override returns (bool success) {
        // Added for testing purposes
        if (failTransferToAddresses[dst]) {
            return false;
        }
        balances[msg.sender] = balances[msg.sender].sub(amount, "Insufficient balance");
        balances[dst] = balances[dst].add(amount, "Balance overflow");
        emit Transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amount) external override returns (bool success) {
        // Added for testing purposes
        if (failTransferFromAddresses[src]) {
            return false;
        }
        allowed[src][msg.sender] = allowed[src][msg.sender].sub(amount, "Insufficient allowance");
        balances[src] = balances[src].sub(amount, "Insufficient balance");
        balances[dst] = balances[dst].add(amount, "Balance overflow");
        emit Transfer(src, dst, amount);
        return true;
    }
}

pragma solidity ^0.7.6;

import "../../contracts/SafeMath.sol";
import "../../contracts/PTokenInterfaces.sol";
import "../../contracts/EIP20Interface.sol";
import "./FaucetToken.sol";
import "../../contracts/ProxyWithRegistry.sol";

/**
  * @title The DeFiPie Evil Test Token
  * @author DeFiPie
  * @notice A simple test token that fails certain operations
  */
contract EvilXToken is ImplementationStorage {
    using SafeMath for uint;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    bool public fail;
    uint public count;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply_;

    PErc20Interface public pToken;
    uint public borrowAmount;
    ControllerInterface public controller;
    PErc20Interface public pTokenBorrow;
    PErc20Interface public pTokenMint;

    constructor() {}

    function initialize(uint256 _initialAmount, string memory _tokenName, string memory _tokenSymbol, uint8 _decimalUnits) public {
        totalSupply_ = _initialAmount;
        balances[msg.sender] = _initialAmount;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
    }

    function enterMarkets(address[] memory pTokens) public returns (uint[] memory) {
        return controller.enterMarkets(pTokens);
    }

    function setController(address controller_) public {
        controller = ControllerInterface(controller_);
    }

    function totalSupply() public view returns (uint) {
        return totalSupply_;
    }

    function balanceOf(address user) public view returns (uint) {
        return balances[user];
    }

    function allocateTo(address _owner, uint256 value) public {
        balances[_owner] += value;
        totalSupply_ += value;
        emit Transfer(address(this), _owner, value);
    }

    function setFail(bool fail_) public {
        fail = fail_;
    }

    function setPToken(address pToken_) public {
        pToken = PErc20Interface(pToken_);
    }

    function setPTokenBorrow(address pToken_) public {
        pTokenBorrow = PErc20Interface(pToken_);
    }

    function setPTokenMint(address pToken_) public {
        pTokenMint = PErc20Interface(pToken_);
    }

    function setBorrowAmount(uint borrowAmount_) public {
        borrowAmount = borrowAmount_;
    }

    function setCount(uint count_) public {
        count = count_;
    }

    function setAllowance(address owner, address spender, uint amount) public {
        allowed[owner][spender] = amount;
    }

    function transfer(address to, uint value) external returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        if (fail) {
            for (uint i = 0; i < count; i++) {
                pTokenBorrow.borrow(borrowAmount);
            }
        }

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][to] = allowed[from][to].sub(value);

        if (fail) {
            for (uint i = 0; i < count; i++) {
                pTokenBorrow.borrow(borrowAmount);
            }
        }

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) external returns (bool) {
        allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function approveToken(address token, address spender, uint value) external returns (bool) {
        return EIP20Interface(token).approve(spender, value);
    }

    function allowance(address owner, address spender) external view returns (uint) {
        return allowed[owner][spender];
    }

    function mint(uint mintAmount) external virtual returns (uint) {
        return pTokenMint.mint(mintAmount);
    }

    function redeem(uint redeemTokens) external returns (uint) {
        return pToken.redeem(redeemTokens);
    }

    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        return pToken.redeemUnderlying(redeemAmount);
    }

    function borrow(uint borrowAmount_) external returns (uint) {
        return pToken.borrow(borrowAmount_);
    }

    function repayBorrow(uint repayAmount) external returns (uint) {
        return pToken.repayBorrow(repayAmount);
    }

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint) {
        return pToken.repayBorrowBehalf(borrower, repayAmount);
    }

    function liquidateBorrow(address borrower, uint repayAmount, address pTokenCollateral) external returns (uint) {
        return pToken.liquidateBorrow(borrower, repayAmount, PTokenInterface(pTokenCollateral));
    }

}

contract EvilXTokenV2 is FaucetToken {
    using SafeMath for uint256;

    bool public fail;
    uint public count;

    PErc20Interface public pToken;
    uint public borrowAmount;

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol)
        FaucetToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {
    }

    function setBorrowAmount(uint borrowAmount_) public {
        borrowAmount = borrowAmount_;
    }

    function setCount(uint count_) public {
        count = count_;
    }

    function setFail(bool fail_) public {
        fail = fail_;
    }

    function setAllowance(address owner, address spender, uint amount) public {
        allowed[owner][spender] = amount;
    }

    function mint(uint mintAmount) external virtual returns (uint) {
        return pToken.mint(mintAmount);
    }

    function redeem(uint redeemTokens) external returns (uint) {
        return pToken.redeem(redeemTokens);
    }

    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        return pToken.redeemUnderlying(redeemAmount);
    }

    function borrow(uint borrowAmount_) external returns (uint) {
        return pToken.borrow(borrowAmount_);
    }

    function repayBorrow(uint repayAmount) external returns (uint) {
        return pToken.repayBorrow(repayAmount);
    }

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint) {
        return pToken.repayBorrowBehalf(borrower, repayAmount);
    }

    function liquidateBorrow(address borrower, uint repayAmount, address pTokenCollateral) external returns (uint) {
        return pToken.liquidateBorrow(borrower, repayAmount, PTokenInterface(pTokenCollateral));
    }

    function transfer(address dst, uint amount) external override returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(amount, "Insufficient balance");
        balances[dst] = balances[dst].add(amount, "Balance overflow");

        if (fail) {
            for (uint i = 0; i < count; i++) {
                pToken.borrow(borrowAmount);
            }
        }

        emit Transfer(msg.sender, dst, amount);

        return true;
    }
}

pragma solidity ^0.7.6;

import "./ERC20.sol";

/**
 * @title The DeFiPie Faucet Test Token
 * @author DeFiPie
 * @notice A simple test token that lets anyone get more of it.
 */
contract FaucetToken is StandardToken {
    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol)
        StandardToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {
    }

    function allocateTo(address _owner, uint256 value) public {
        balances[_owner] += value;
        totalSupply_ += value;
        emit Transfer(address(this), _owner, value);
    }
}

/**
 * @title The DeFiPie Faucet Test Token (non-standard)
 * @author DeFiPie
 * @notice A simple test token that lets anyone get more of it.
 */
contract FaucetNonStandardToken is NonStandardToken {
    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol)
        NonStandardToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {
    }

    function allocateTo(address _owner, uint256 value) public {
        balances[_owner] += value;
        totalSupply_ += value;
        emit Transfer(address(this), _owner, value);
    }
}

/**
 * @title The DeFiPie Faucet Re-Entrant Test Token
 * @author DeFiPie
 * @notice A test token that is malicious and tries to re-enter callers
 */
contract FaucetTokenReEntrantHarness {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 totalSupply__;
    mapping (address => mapping (address => uint256)) allowance_;
    mapping (address => uint256) balanceOf_;

    bytes public reEntryCallData;
    string public reEntryFun;

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol, bytes memory _reEntryCallData, string memory _reEntryFun) {
        totalSupply__ = _initialAmount;
        balanceOf_[msg.sender] = _initialAmount;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
        reEntryCallData = _reEntryCallData;
        reEntryFun = _reEntryFun;
    }

    modifier reEnter(string memory funName) {
        string memory _reEntryFun = reEntryFun;
        if (compareStrings(_reEntryFun, funName)) {
            reEntryFun = ""; // Clear re-entry fun
            (bool success, bytes memory returndata) = msg.sender.call(reEntryCallData);
            assembly {
                if eq(success, 0) {
                    revert(add(returndata, 0x20), returndatasize())
                }
            }
        }

        _;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b)));
    }

    function allocateTo(address _owner, uint256 value) public {
        balanceOf_[_owner] += value;
        totalSupply__ += value;
        emit Transfer(address(this), _owner, value);
    }

    function totalSupply() public reEnter("totalSupply") returns (uint256) {
        return totalSupply__;
    }

    function allowance(address owner, address spender) public reEnter("allowance") returns (uint256 remaining) {
        return allowance_[owner][spender];
    }

    function approve(address spender, uint256 amount) public reEnter("approve") returns (bool success) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address owner) public reEnter("balanceOf") returns (uint256 balance) {
        return balanceOf_[owner];
    }

    function transfer(address dst, uint256 amount) public reEnter("transfer") returns (bool success) {
        _transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amount) public reEnter("transferFrom") returns (bool success) {
        _transfer(src, dst, amount);
        _approve(src, msg.sender, allowance_[src][msg.sender].sub(amount));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(spender != address(0));
        require(owner != address(0));
        allowance_[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address src, address dst, uint256 amount) internal {
        require(dst != address(0));
        balanceOf_[src] = balanceOf_[src].sub(amount);
        balanceOf_[dst] = balanceOf_[dst].add(amount);
        emit Transfer(src, dst, amount);
    }
}

