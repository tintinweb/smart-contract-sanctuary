/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

/*
    .'''''''''''..     ..''''''''''''''''..       ..'''''''''''''''..
    .;;;;;;;;;;;'.   .';;;;;;;;;;;;;;;;;;,.     .,;;;;;;;;;;;;;;;;;,.
    .;;;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;,.    .,;;;;;;;;;;;;;;;;;;,.
    .;;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;;,.   .;;;;;;;;;;;;;;;;;;;;,.
    ';;;;;;;;'.  .';;;;;;;;;;;;;;;;;;;;;;,. .';;;;;;;;;;;;;;;;;;;;;,.
    ';;;;;,..   .';;;;;;;;;;;;;;;;;;;;;;;,..';;;;;;;;;;;;;;;;;;;;;;,.
    ......     .';;;;;;;;;;;;;,'''''''''''.,;;;;;;;;;;;;;,'''''''''..
              .,;;;;;;;;;;;;;.           .,;;;;;;;;;;;;;.
             .,;;;;;;;;;;;;,.           .,;;;;;;;;;;;;,.
            .,;;;;;;;;;;;;,.           .,;;;;;;;;;;;;,.
           .,;;;;;;;;;;;;,.           .;;;;;;;;;;;;;,.     .....
          .;;;;;;;;;;;;;'.         ..';;;;;;;;;;;;;'.    .',;;;;,'.
        .';;;;;;;;;;;;;'.         .';;;;;;;;;;;;;;'.   .';;;;;;;;;;.
       .';;;;;;;;;;;;;'.         .';;;;;;;;;;;;;;'.    .;;;;;;;;;;;,.
      .,;;;;;;;;;;;;;'...........,;;;;;;;;;;;;;;.      .;;;;;;;;;;;,.
     .,;;;;;;;;;;;;,..,;;;;;;;;;;;;;;;;;;;;;;;,.       ..;;;;;;;;;,.
    .,;;;;;;;;;;;;,. .,;;;;;;;;;;;;;;;;;;;;;;,.          .',;;;,,..
   .,;;;;;;;;;;;;,.  .,;;;;;;;;;;;;;;;;;;;;;,.              ....
    ..',;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;;,.
       ..',;;;;'.    .,;;;;;;;;;;;;;;;;;;;'.
          ...'..     .';;;;;;;;;;;;;;,,,'.
                       ...............
*/

// https://github.com/trusttoken/smart-contracts
// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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


// Dependency file: @openzeppelin/contracts/math/SafeMath.sol


// pragma solidity ^0.6.0;

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


// Dependency file: @openzeppelin/contracts/GSN/Context.sol


// pragma solidity ^0.6.0;

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


// Dependency file: contracts/truefi/common/Initializable.sol

// Copied from https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/v3.0.0/contracts/Initializable.sol

// pragma solidity 0.6.10;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}


// Dependency file: contracts/truefi/common/UpgradeableOwnable.sol

// pragma solidity 0.6.10;

// import {Context} from "@openzeppelin/contracts/GSN/Context.sol";

// import {Initializable} from "contracts/truefi/common/Initializable.sol";

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
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() internal initializer {
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


// Dependency file: contracts/truefi/interface/ILoanToken.sol

// pragma solidity 0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILoanToken is IERC20 {
    enum Status {Awaiting, Funded, Withdrawn, Settled, Defaulted, Liquidated}

    function borrower() external view returns (address);

    function amount() external view returns (uint256);

    function term() external view returns (uint256);

    function apy() external view returns (uint256);

    function start() external view returns (uint256);

    function lender() external view returns (address);

    function debt() external view returns (uint256);

    function profit() external view returns (uint256);

    function status() external view returns (Status);

    function borrowerFee() external view returns (uint256);

    function receivedAmount() external view returns (uint256);

    function isLoanToken() external pure returns (bool);

    function getParameters()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function fund() external;

    function withdraw(address _beneficiary) external;

    function close() external;

    function liquidate() external;

    function redeem(uint256 _amount) external;

    function repay(address _sender, uint256 _amount) external;

    function reclaim() external;

    function allowTransfer(address account, bool _status) external;

    function repaid() external view returns (uint256);

    function balance() external view returns (uint256);

    function value(uint256 _balance) external view returns (uint256);

    function currencyToken() external view returns (IERC20);

    function version() external pure returns (uint8);
}


// Dependency file: contracts/truefi/interface/ITrueFiPool.sol

// pragma solidity 0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * TruePool is an ERC20 which represents a share of a pool
 *
 * This contract can be used to wrap opportunities to be compatible
 * with TrueFi and allow users to directly opt-in through the TUSD contract
 *
 * Each TruePool is also a staking opportunity for TRU
 */
interface ITrueFiPool is IERC20 {
    /// @dev pool token (TUSD)
    function currencyToken() external view returns (IERC20);

    /// @dev stake token (TRU)
    function stakeToken() external view returns (IERC20);

    /**
     * @dev join pool
     * 1. Transfer TUSD from sender
     * 2. Mint pool tokens based on value to sender
     */
    function join(uint256 amount) external;

    /**
     * @dev exit pool
     * 1. Transfer pool tokens from sender
     * 2. Burn pool tokens
     * 3. Transfer value of pool tokens in TUSD to sender
     */
    function exit(uint256 amount) external;

    /**
     * @dev borrow from pool
     * 1. Transfer TUSD to sender
     * 2. Only lending pool should be allowed to call this
     */
    function borrow(uint256 amount, uint256 fee) external;

    /**
     * @dev join pool
     * 1. Transfer TUSD from sender
     * 2. Only lending pool should be allowed to call this
     */
    function repay(uint256 amount) external;
}


// Dependency file: contracts/truefi/interface/ITrueLender.sol

// pragma solidity 0.6.10;

interface ITrueLender {
    function value() external view returns (uint256);

    function distribute(
        address recipient,
        uint256 numerator,
        uint256 denominator
    ) external;
}


// Dependency file: contracts/truefi/interface/ITrueRatingAgency.sol

// pragma solidity 0.6.10;

interface ITrueRatingAgency {
    function getResults(address id)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function submit(address id) external;

    function retract(address id) external;

    function yes(address id, uint256 stake) external;

    function no(address id, uint256 stake) external;

    function withdraw(address id, uint256 stake) external;

    function claim(address id, address voter) external;
}


// Dependency file: contracts/truefi/interface/IStakingPool.sol

// pragma solidity 0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingPool is IERC20 {
    function stakeSupply() external view returns (uint256);

    function withdraw(uint256 amount) external;

    function payFee(uint256 amount, uint256 endTime) external;
}


// Root file: contracts/truefi/TrueLender.sol

pragma solidity 0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

// import {Ownable} from "contracts/truefi/common/UpgradeableOwnable.sol";
// import {ILoanToken} from "contracts/truefi/interface/ILoanToken.sol";
// import {ITrueFiPool} from "contracts/truefi/interface/ITrueFiPool.sol";
// import {ITrueLender} from "contracts/truefi/interface/ITrueLender.sol";
// import {ITrueRatingAgency} from "contracts/truefi/interface/ITrueRatingAgency.sol";
// import {IStakingPool} from "contracts/truefi/interface/IStakingPool.sol";

/**
 * @title TrueLender v1.0
 * @dev TrueFi Lending Strategy
 * This contract implements the lending strategy for the TrueFi pool
 * The strategy takes into account several parameters and consumes
 * information from the prediction market in order to approve loans
 *
 * This strategy is conservative to avoid defaults.
 * See: https://github.com/trusttoken/truefi-spec
 *
 * 1. Only approve loans which have the following inherent properties:
 * - minAPY <= loanAPY <= maxAPY
 * - minSize <= loanSize <= maxSize
 * - minTerm <= loanTerm <= maxTerm
 *
 * 2. Only approve loans which have been rated in the prediction market under the conditions:
 * - timeInMarket >= votingPeriod
 * - stakedTRU > (participationFactor * loanSize)
 * - 1 < ( interest * P(loan_repaid) - (loanSize * riskAversion * P(loan_defaults))
 *
 * Once a loan meets these requirements, fund() can be called to transfer
 * funds from the pool to the LoanToken contract
 */
contract TrueLender is ITrueLender, Ownable {
    using SafeMath for uint256;

    // ================ WARNING ==================
    // ===== THIS CONTRACT IS INITIALIZABLE ======
    // === STORAGE VARIABLES ARE DECLARED BELOW ==
    // REMOVAL OR REORDER OF VARIABLES WILL RESULT
    // ========= IN STORAGE CORRUPTION ===========

    mapping(address => bool) public allowedBorrowers;
    ILoanToken[] _loans;

    ITrueFiPool public pool;
    IERC20 public currencyToken;
    ITrueRatingAgency public ratingAgency;

    uint256 private constant TOKEN_PRECISION_DIFFERENCE = 10**10;

    // ===== Pool parameters =====

    // bound on APY
    uint256 public minApy;
    uint256 public maxApy;

    // How many votes in predction market
    uint256 public participationFactor;

    // How much worse is it to lose $1 TUSD than it is to gain $1 TUSD
    uint256 public riskAversion;

    // bound on min & max loan sizes
    uint256 public minSize;
    uint256 public maxSize;

    // bound on min & max loan terms
    uint256 public minTerm;
    uint256 public maxTerm;

    // minimum prediction market voting period
    uint256 public votingPeriod;

    // maximum amount of loans lender can handle at once
    uint256 public maxLoans;

    // implemented as an ERC20, will change after implementing stkPool
    IStakingPool public stakingPool;

    // ======= STORAGE DECLARATION END ============

    /**
     * @dev Emitted when a borrower's whitelist status changes
     * @param who Address for which whitelist status has changed
     * @param status New whitelist status
     */
    event Allowed(address indexed who, bool status);

    /**
     * @dev Emitted when APY bounds have changed
     * @param minApy New minimum APY
     * @param maxApy New maximum APY
     */
    event ApyLimitsChanged(uint256 minApy, uint256 maxApy);

    /**
     * @dev Emitted when participation factor changed
     * @param participationFactor New participation factor
     */
    event ParticipationFactorChanged(uint256 participationFactor);

    /**
     * @dev Emitted when risk aversion changed
     * @param riskAversion New risk aversion factor
     */
    event RiskAversionChanged(uint256 riskAversion);

    /**
     * @dev Emitted when the minimum voting period is changed
     * @param votingPeriod New voting period
     */
    event VotingPeriodChanged(uint256 votingPeriod);

    /**
     * @dev Emitted when the loan size bounds are changed
     * @param minSize New minimum loan size
     * @param maxSize New maximum loan size
     */
    event SizeLimitsChanged(uint256 minSize, uint256 maxSize);

    /**
     * @dev Emitted when loan term bounds are changed
     * @param minTerm New minimum loan term
     * @param maxTerm New minimum loan term
     */
    event TermLimitsChanged(uint256 minTerm, uint256 maxTerm);

    /**
     * @dev Emitted when loans limit is changed
     * @param maxLoans new maximum amount of loans
     */
    event LoansLimitChanged(uint256 maxLoans);

    /**
     * @dev Emitted when stakingPool address is changed
     * @param pool new stakingPool address
     */
    event StakingPoolChanged(IStakingPool pool);

    /**
     * @dev Emitted when a loan is funded
     * @param loanToken LoanToken contract which was funded
     * @param amount Amount funded
     */
    event Funded(address indexed loanToken, uint256 amount);

    /**
     * @dev Emitted when funds are reclaimed from the LoanToken contract
     * @param loanToken LoanToken from which funds were reclaimed
     * @param amount Amount repaid
     */
    event Reclaimed(address indexed loanToken, uint256 amount);

    /**
     * @dev Emitted when rating agency contract is changed
     * @param newRatingAgency Address of new rating agency
     */
    event RatingAgencyChanged(address newRatingAgency);

    /**
     * @dev Modifier for only lending pool
     */
    modifier onlyPool() {
        require(msg.sender == address(pool), "TrueLender: Sender is not a pool");
        _;
    }

    /**
     * @dev Initalize the contract with parameters
     * @param _pool Lending pool address
     * @param _ratingAgency Prediction market address
     */
    function initialize(
        ITrueFiPool _pool,
        ITrueRatingAgency _ratingAgency,
        IStakingPool _stakingPool
    ) public initializer {
        Ownable.initialize();

        pool = _pool;
        currencyToken = _pool.currencyToken();
        currencyToken.approve(address(_pool), uint256(-1));
        ratingAgency = _ratingAgency;
        stakingPool = _stakingPool;

        minApy = 1000;
        maxApy = 3000;
        participationFactor = 10000;
        riskAversion = 15000;
        minSize = 1000000 ether;
        maxSize = 10000000 ether;
        minTerm = 182 days;
        maxTerm = 3650 days;
        votingPeriod = 7 days;

        maxLoans = 100;
    }

    /**
     * @dev set stake pool address
     * @param newPool stake pool address to be set
     */
    function setStakingPool(IStakingPool newPool) public onlyOwner {
        stakingPool = newPool;
        emit StakingPoolChanged(newPool);
    }

    /**
     * @dev Set new bounds on loan size. Only owner can change parameters.
     * @param min New minimum loan size
     * @param max New maximum loan size
     */
    function setSizeLimits(uint256 min, uint256 max) external onlyOwner {
        require(min > 0, "TrueLender: Minimal loan size cannot be 0");
        require(max >= min, "TrueLender: Maximal loan size is smaller than minimal");
        minSize = min;
        maxSize = max;
        emit SizeLimitsChanged(min, max);
    }

    /**
     * @dev Set new bounds on loan term length. Only owner can change parameters.
     * @param min New minimum loan term
     * @param max New maximum loan term
     */
    function setTermLimits(uint256 min, uint256 max) external onlyOwner {
        require(max >= min, "TrueLender: Maximal loan term is smaller than minimal");
        minTerm = min;
        maxTerm = max;
        emit TermLimitsChanged(min, max);
    }

    /**
     * @dev Set new bounds on loan APY. Only owner can change parameters.
     * @param newMinApy New minimum loan APY
     * @param newMaxApy New maximum loan APY
     */
    function setApyLimits(uint256 newMinApy, uint256 newMaxApy) external onlyOwner {
        require(newMaxApy >= newMinApy, "TrueLender: Maximal APY is smaller than minimal");
        minApy = newMinApy;
        maxApy = newMaxApy;
        emit ApyLimitsChanged(newMinApy, newMaxApy);
    }

    /**
     * @dev Set new minimum voting period in credit rating market.
     * Only owner can change parameters
     * @param newVotingPeriod new minimum voting period
     */
    function setVotingPeriod(uint256 newVotingPeriod) external onlyOwner {
        votingPeriod = newVotingPeriod;
        emit VotingPeriodChanged(newVotingPeriod);
    }

    /**
     * @dev Set new participation factor. Only owner can change parameters.
     * @param newParticipationFactor New participation factor.
     */
    function setParticipationFactor(uint256 newParticipationFactor) external onlyOwner {
        participationFactor = newParticipationFactor;
        emit ParticipationFactorChanged(newParticipationFactor);
    }

    /**
     * @dev Set new risk aversion factor. Only owner can change parameters.
     * @param newRiskAversion New risk aversion factor
     */
    function setRiskAversion(uint256 newRiskAversion) external onlyOwner {
        riskAversion = newRiskAversion;
        emit RiskAversionChanged(newRiskAversion);
    }

    /**
     * @dev Set new loans limit. Only owner can change parameters.
     * @param newLoansLimit New loans limit
     */
    function setLoansLimit(uint256 newLoansLimit) external onlyOwner {
        maxLoans = newLoansLimit;
        emit LoansLimitChanged(maxLoans);
    }

    /**
     * @dev Set new rating agency. Only owner can change parameters.
     * @param newRatingAgency New rating agency.
     */
    function setRatingAgency(ITrueRatingAgency newRatingAgency) external onlyOwner {
        ratingAgency = newRatingAgency;
        emit RatingAgencyChanged(address(newRatingAgency));
    }

    /**
     * @dev Get currently funded loans
     * @return result Array of loans currently funded
     */
    function loans() public view returns (ILoanToken[] memory result) {
        result = _loans;
    }

    /**
     * @dev Fund a loan which meets the strategy requirements
     * @param loanToken LoanToken to fund
     */
    function fund(ILoanToken loanToken) external {
        require(loanToken.borrower() == msg.sender, "TrueLender: Sender is not borrower");
        require(loanToken.isLoanToken(), "TrueLender: Only LoanTokens can be funded");
        require(loanToken.currencyToken() == currencyToken, "TrueLender: Only the same currency LoanTokens can be funded");
        require(_loans.length < maxLoans, "TrueLender: Loans number has reached the limit");

        (uint256 amount, uint256 apy, uint256 term) = loanToken.getParameters();
        uint256 receivedAmount = loanToken.receivedAmount();
        (uint256 start, uint256 no, uint256 yes) = ratingAgency.getResults(address(loanToken));

        require(loanSizeWithinBounds(amount), "TrueLender: Loan size is out of bounds");
        require(loanTermWithinBounds(term), "TrueLender: Loan term is out of bounds");
        require(loanIsAttractiveEnough(apy), "TrueLender: APY is out of bounds");
        require(votingLastedLongEnough(start), "TrueLender: Voting time is below minimum");
        require(votesThresholdReached(amount, yes), "TrueLender: Not enough votes given for the loan");
        require(loanIsCredible(apy, term, yes, no), "TrueLender: Loan risk is too high");

        _loans.push(loanToken);
        pool.borrow(amount, amount.sub(receivedAmount));
        currencyToken.approve(address(loanToken), receivedAmount);
        loanToken.fund();

        pool.approve(address(stakingPool), pool.balanceOf(address(this)));
        stakingPool.payFee(pool.balanceOf(address(this)), block.timestamp.add(term));

        emit Funded(address(loanToken), receivedAmount);
    }

    /**
     * @dev Temporary fix for old LoanTokens with incorrect value calculation
     * @param loan Loan to calculate value for
     * @return value of a given loan
     */
    function loanValue(ILoanToken loan) public view returns (uint256) {
        uint256 _balance = loan.balanceOf(address(this));
        if (_balance == 0) {
            return 0;
        }

        uint256 passed = block.timestamp.sub(loan.start());
        if (passed > loan.term()) {
            passed = loan.term();
        }

        uint256 helper = loan.amount().mul(loan.apy()).mul(passed).mul(_balance);
        // assume year is 365 days
        uint256 interest = helper.div(365 days).div(10000).div(loan.debt());

        return loan.amount().mul(_balance).div(loan.debt()).add(interest);
    }

    /**
     * @dev Loop through loan tokens and calculate theoretical value of all loans
     * There should never be too many loans in the pool to run out of gas
     * @return Theoretical value of all the loans funded by this strategy
     */
    function value() external override view returns (uint256) {
        uint256 totalValue;
        for (uint256 index = 0; index < _loans.length; index++) {
            totalValue = totalValue.add(loanValue(_loans[index]));
        }
        return totalValue;
    }

    /**
     * @dev For settled loans, redeem LoanTokens for underlying funds
     * @param loanToken Loan to reclaim capital from (must be previously funded)
     */
    function reclaim(ILoanToken loanToken) external {
        require(loanToken.isLoanToken(), "TrueLender: Only LoanTokens can be used to reclaimed");

        ILoanToken.Status status = loanToken.status();
        require(status >= ILoanToken.Status.Settled, "TrueLender: LoanToken is not closed yet");

        if (status != ILoanToken.Status.Settled) {
            require(msg.sender == owner(), "TrueLender: Only owner can reclaim from defaulted loan");
        }

        // call redeem function on LoanToken
        uint256 balanceBefore = currencyToken.balanceOf(address(this));
        loanToken.redeem(loanToken.balanceOf(address(this)));
        uint256 balanceAfter = currencyToken.balanceOf(address(this));

        // gets reclaimed amount and pays back to pool
        uint256 fundsReclaimed = balanceAfter.sub(balanceBefore);
        pool.repay(fundsReclaimed);

        // remove loan from loan array
        for (uint256 index = 0; index < _loans.length; index++) {
            if (_loans[index] == loanToken) {
                _loans[index] = _loans[_loans.length - 1];
                _loans.pop();

                emit Reclaimed(address(loanToken), fundsReclaimed);
                return;
            }
        }
        // If we reach this, it means loanToken was not present in _loans array
        // This prevents invalid loans from being reclaimed
        revert("TrueLender: This loan has not been funded by the lender");
    }

    /**
     * @dev Withdraw a basket of tokens held by the pool
     * When exiting the pool, the pool contract calls this function
     * to withdraw a fraction of all the loans held by the pool
     * Loop through recipient's share of LoanTokens and calculate versus total per loan.
     * There should never be too many loans in the pool to run out of gas
     *
     * @param recipient Recipient of basket
     * @param numerator Numerator of fraction to withdraw
     * @param denominator Denominator of fraction to withdraw
     */
    function distribute(
        address recipient,
        uint256 numerator,
        uint256 denominator
    ) external override onlyPool {
        for (uint256 index = 0; index < _loans.length; index++) {
            _loans[index].transfer(recipient, numerator.mul(_loans[index].balanceOf(address(this))).div(denominator));
        }
    }

    /**
     * @dev Check if a loan is within APY bounds
     * @param apy APY of loan
     * @return Whether a loan is within APY bounds
     */
    function loanIsAttractiveEnough(uint256 apy) public view returns (bool) {
        return apy >= minApy && apy <= maxApy;
    }

    /**
     * @dev Check if a loan has been in the credit market long enough
     * @param start Timestamp at which rating began
     * @return Whether a loan has been rated for long enough
     */
    function votingLastedLongEnough(uint256 start) public view returns (bool) {
        return start.add(votingPeriod) <= block.timestamp;
    }

    /**
     * @dev Check if a loan is within size bounds
     * @param amount Size of loan
     * @return Whether a loan is within size bounds
     */
    function loanSizeWithinBounds(uint256 amount) public view returns (bool) {
        return amount >= minSize && amount <= maxSize;
    }

    /**
     * @dev Check if loan term is within term bounds
     * @param term Term of loan
     * @return Whether loan term is within term bounds
     */
    function loanTermWithinBounds(uint256 term) public view returns (bool) {
        return term >= minTerm && term <= maxTerm;
    }

    /**
     * @dev Check if a loan is within APY bounds
     * Minimum absolute value of yes votes, rather than ratio of yes to no
     * @param amount Size of loan
     * @param yesVotes Number of yes votes
     * @return Whether a loan has reached the required voting threshold
     */
    function votesThresholdReached(uint256 amount, uint256 yesVotes) public view returns (bool) {
        return amount.mul(participationFactor) <= yesVotes.mul(10000).mul(TOKEN_PRECISION_DIFFERENCE);
    }

    /**
     * @dev Use APY and term of loan to check expected value of a loan
     * Expected value = profit - (default_loss * (no / yes))
     * e.g. riskAversion = 10,000 => expected value of 1
     * @param apy APY of loan
     * @param term Term length of loan
     * @param yesVotes Number of YES votes in credit market
     * @param noVotes Number of NO votes in credit market
     */
    function loanIsCredible(
        uint256 apy,
        uint256 term,
        uint256 yesVotes,
        uint256 noVotes
    ) public view returns (bool) {
        return apy.mul(term).mul(yesVotes).div(365 days) >= noVotes.mul(riskAversion);
    }
}