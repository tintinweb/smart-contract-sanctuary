/**
 *Submitted for verification at Etherscan.io on 2021-05-20
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


// Dependency file: contracts/trusttoken/interface/IBurnableERC20.sol

// pragma solidity 0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBurnableERC20 is IERC20 {
    function burn(uint256 amount) external;
}


// Dependency file: contracts/governance/interface/IVoteToken.sol

// pragma solidity ^0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVoteToken {
    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getCurrentVotes(address account) external view returns (uint96);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
}

interface IVoteTokenWithERC20 is IVoteToken, IERC20 {}


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


// Dependency file: contracts/common/Initializable.sol

// Copied from https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/v3.0.0/contracts/Initializable.sol
// Added public isInitialized() view of private initialized bool.

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

    /**
     * @dev Return true if and only if the contract has been initialized
     * @return whether the contract has been initialized
     */
    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}


// Dependency file: contracts/common/UpgradeableOwnable.sol

// pragma solidity 0.6.10;

// import {Context} from "@openzeppelin/contracts/GSN/Context.sol";

// import {Initializable} from "contracts/common/Initializable.sol";

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


// Dependency file: contracts/truefi/interface/IArbitraryDistributor.sol

// pragma solidity 0.6.10;

interface IArbitraryDistributor {
    function amount() external returns (uint256);

    function remaining() external returns (uint256);

    function beneficiary() external returns (address);

    function distribute(uint256 _amount) external;

    function empty() external;
}


// Dependency file: contracts/truefi/interface/ILoanFactory.sol

// pragma solidity 0.6.10;

interface ILoanFactory {
    function createLoanToken(
        uint256 _amount,
        uint256 _term,
        uint256 _apy
    ) external;

    function isLoanToken(address) external view returns (bool);
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

    function settle() external;

    function enterDefault() external;

    function liquidate() external;

    function redeem(uint256 _amount) external;

    function repay(address _sender, uint256 _amount) external;

    function repayInFull(address _sender) external;

    function reclaim() external;

    function allowTransfer(address account, bool _status) external;

    function repaid() external view returns (uint256);

    function isRepaid() external view returns (bool);

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


// Dependency file: contracts/truefi/interface/ITrueRatingAgencyV2.sol

// pragma solidity 0.6.10;

interface ITrueRatingAgencyV2 {
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

    function resetCastRatings(address id) external;

    function yes(address id) external;

    function no(address id) external;

    function claim(address id, address voter) external;
}


// Root file: contracts/truefi/TrueRatingAgencyV2.sol

pragma solidity 0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

// import {IBurnableERC20} from "contracts/trusttoken/interface/IBurnableERC20.sol";
// import {IVoteTokenWithERC20} from "contracts/governance/interface/IVoteToken.sol";

// import {Ownable} from "contracts/common/UpgradeableOwnable.sol";
// import {IArbitraryDistributor} from "contracts/truefi/interface/IArbitraryDistributor.sol";
// import {ILoanFactory} from "contracts/truefi/interface/ILoanFactory.sol";
// import {ILoanToken} from "contracts/truefi/interface/ILoanToken.sol";
// import {ITrueFiPool} from "contracts/truefi/interface/ITrueFiPool.sol";
// import {ITrueRatingAgencyV2} from "contracts/truefi/interface/ITrueRatingAgencyV2.sol";

/**
 * @title TrueRatingAgencyV2
 * @dev Credit prediction market for LoanTokens
 *
 * TrueFi uses use a prediction market to signal how risky a loan is.
 * The Credit Prediction Market estimates the likelihood of a loan defaulting.
 * Any stkTRU holder can rate YES or NO and stake TRU as collateral on their rate.
 * Voting weight is equal to delegated governance power (see VoteToken.sol)
 * If a loan is funded, TRU is rewarded as incentive for participation
 * Rating stkTRU in the prediction market allows raters to earn and claim TRU
 * incentive when the loan is approved
 *
 * Voting Lifecycle:
 * - Borrowers can apply for loans at any time by deploying a LoanToken
 * - LoanTokens are registered with the prediction market contract
 * - Once registered, stkTRU holders can rate at any time
 *
 * States:
 * Void:        Rated loan is invalid
 * Pending:     Waiting to be funded
 * Retracted:   Rating has been cancelled
 * Running:     Rated loan has been funded
 * Settled:     Rated loan has been paid back in full
 * Defaulted:   Rated loan has not been paid back in full
 * Liquidated:  Rated loan has defaulted and stakers have been liquidated
 */
contract TrueRatingAgencyV2 is ITrueRatingAgencyV2, Ownable {
    using SafeMath for uint256;

    enum LoanStatus {Void, Pending, Retracted, Running, Settled, Defaulted, Liquidated}

    struct Loan {
        address creator;
        uint256 timestamp;
        uint256 blockNumber;
        mapping(bool => uint256) prediction;
        mapping(address => mapping(bool => uint256)) ratings;
        mapping(address => uint256) claimed;
        uint256 reward;
    }

    // TRU is 1e8 decimals
    uint256 private constant TOKEN_PRECISION_DIFFERENCE = 10**10;

    // ================ WARNING ==================
    // ===== THIS CONTRACT IS INITIALIZABLE ======
    // === STORAGE VARIABLES ARE DECLARED BELOW ==
    // REMOVAL OR REORDER OF VARIABLES WILL RESULT
    // ========= IN STORAGE CORRUPTION ===========

    mapping(address => bool) public allowedSubmitters;
    mapping(address => Loan) public loans;

    IBurnableERC20 public TRU;
    IVoteTokenWithERC20 public stkTRU;
    IArbitraryDistributor public distributor;
    ILoanFactory public factory;

    /**
     * @dev % multiplied by 100. e.g. 10.5% = 1050
     */
    uint256 public ratersRewardFactor;

    // reward multiplier for raters
    uint256 public rewardMultiplier;

    // are submissions paused?
    bool public submissionPauseStatus;

    mapping(address => bool) public canChangeAllowance;

    // ======= STORAGE DECLARATION END ============

    event CanChangeAllowanceChanged(address indexed who, bool status);
    event Allowed(address indexed who, bool status);
    event RatersRewardFactorChanged(uint256 ratersRewardFactor);
    event LoanSubmitted(address id);
    event LoanRetracted(address id);
    event Rated(address loanToken, address rater, bool choice, uint256 stake);
    event Withdrawn(address loanToken, address rater, uint256 stake, uint256 received, uint256 burned);
    event RewardMultiplierChanged(uint256 newRewardMultiplier);
    event Claimed(address loanToken, address rater, uint256 claimedReward);
    event SubmissionPauseStatusChanged(bool status);
    event LoanFactoryChanged(address newLoanFactory);

    /**
     * @dev Only whitelisted borrowers can submit for credit ratings
     */
    modifier onlyAllowedSubmitters() {
        require(allowedSubmitters[msg.sender], "TrueRatingAgencyV2: Sender is not allowed to submit");
        _;
    }

    /**
     * @dev Only loan submitter can perform certain actions
     */
    modifier onlyCreator(address id) {
        require(loans[id].creator == msg.sender, "TrueRatingAgencyV2: Not sender's loan");
        _;
    }

    /**
     * @dev Cannot submit the same loan multiple times
     */
    modifier onlyNotExistingLoans(address id) {
        require(status(id) == LoanStatus.Void, "TrueRatingAgencyV2: Loan was already created");
        _;
    }

    /**
     * @dev Only loans in Pending state
     */
    modifier onlyPendingLoans(address id) {
        require(status(id) == LoanStatus.Pending, "TrueRatingAgencyV2: Loan is not currently pending");
        _;
    }

    /**
     * @dev Only loans that have been funded
     */
    modifier onlyFundedLoans(address id) {
        require(status(id) >= LoanStatus.Running, "TrueRatingAgencyV2: Loan was not funded");
        _;
    }

    /**
     * @dev Initialize Rating Agency
     * Distributor contract decides how much TRU is rewarded to stakers
     * @param _TRU TRU contract
     * @param _distributor Distributor contract
     * @param _factory Factory contract for deploying tokens
     */
    function initialize(
        IBurnableERC20 _TRU,
        IVoteTokenWithERC20 _stkTRU,
        IArbitraryDistributor _distributor,
        ILoanFactory _factory
    ) public initializer {
        require(address(this) == _distributor.beneficiary(), "TrueRatingAgencyV2: Invalid distributor beneficiary");
        Ownable.initialize();

        TRU = _TRU;
        stkTRU = _stkTRU;
        distributor = _distributor;
        factory = _factory;

        ratersRewardFactor = 10000;
    }

    /**
     * @dev Set new loan factory.
     * @param _factory New LoanFactory contract address
     */
    function setLoanFactory(ILoanFactory _factory) external onlyOwner {
        factory = _factory;
        emit LoanFactoryChanged(address(_factory));
    }

    /**
     * @dev Set rater reward factor.
     * Reward factor decides what percentage of rewarded TRU is goes to raters
     */
    function setRatersRewardFactor(uint256 newRatersRewardFactor) external onlyOwner {
        require(newRatersRewardFactor <= 10000, "TrueRatingAgencyV2: Raters reward factor cannot be greater than 100%");
        ratersRewardFactor = newRatersRewardFactor;
        emit RatersRewardFactorChanged(newRatersRewardFactor);
    }

    /**
     * @dev Set reward multiplier.
     * Reward multiplier increases reward for TRU stakers
     */
    function setRewardMultiplier(uint256 newRewardMultiplier) external onlyOwner {
        rewardMultiplier = newRewardMultiplier;
        emit RewardMultiplierChanged(newRewardMultiplier);
    }

    /**
     * @dev Get number of NO ratings for a specific account and loan
     * @param id Loan ID
     * @param rater Rater account
     */
    function getNoRate(address id, address rater) public view returns (uint256) {
        return loans[id].ratings[rater][false];
    }

    /**
     * @dev Get number of YES ratings for a specific account and loan
     * @param id Loan ID
     * @param rater Rater account
     */
    function getYesRate(address id, address rater) public view returns (uint256) {
        return loans[id].ratings[rater][true];
    }

    /**
     * @dev Get total NO ratings for a specific loan
     * @param id Loan ID
     */
    function getTotalNoRatings(address id) public view returns (uint256) {
        return loans[id].prediction[false];
    }

    /**
     * @dev Get total YES ratings for a specific loan
     * @param id Loan ID
     */
    function getTotalYesRatings(address id) public view returns (uint256) {
        return loans[id].prediction[true];
    }

    /**
     * @dev Get timestamp at which voting started for a specific loan
     * @param id Loan ID
     */
    function getVotingStart(address id) public view returns (uint256) {
        return loans[id].timestamp;
    }

    /**
     * @dev Get current results for a specific loan
     * @param id Loan ID
     * @return (start_time, total_no, total_yes)
     */
    function getResults(address id)
        external
        override
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (getVotingStart(id), getTotalNoRatings(id), getTotalYesRatings(id));
    }

    /**
     * @dev Allows addresses to whitelist borrowers
     */
    function allowChangingAllowances(address who, bool status) external onlyOwner {
        canChangeAllowance[who] = status;
        emit CanChangeAllowanceChanged(who, status);
    }

    /**
     * @dev Whitelist borrowers to submit loans for rating
     * @param who Account to whitelist
     * @param status Flag to whitelist accounts
     */
    function allow(address who, bool status) external {
        require(canChangeAllowance[msg.sender], "TrueFiPool: Cannot change allowances");
        allowedSubmitters[who] = status;
        emit Allowed(who, status);
    }

    /**
     * @dev Pause submitting loans for rating
     * @param status Flag of the status
     */
    function pauseSubmissions(bool status) public onlyOwner {
        submissionPauseStatus = status;
        emit SubmissionPauseStatusChanged(status);
    }

    /**
     * @dev Submit a loan for rating
     * Cannot submit the same loan twice
     * @param id Loan ID
     */
    function submit(address id) external override onlyAllowedSubmitters onlyNotExistingLoans(id) {
        require(!submissionPauseStatus, "TrueRatingAgencyV2: New submissions are paused");
        require(ILoanToken(id).borrower() == msg.sender, "TrueRatingAgencyV2: Sender is not borrower");
        require(factory.isLoanToken(id), "TrueRatingAgencyV2: Only LoanTokens created via LoanFactory are supported");
        loans[id] = Loan({creator: msg.sender, timestamp: block.timestamp, blockNumber: block.number, reward: 0});
        emit LoanSubmitted(id);
    }

    /**
     * @dev Remove Loan from rating agency
     * Can only be retracted by loan creator
     * @param id Loan ID
     */
    function retract(address id) external override onlyPendingLoans(id) onlyCreator(id) {
        loans[id].creator = address(0);
        loans[id].prediction[true] = 0;
        loans[id].prediction[false] = 0;

        emit LoanRetracted(id);
    }

    /**
     * @dev Rate on a loan by staking TRU
     * @param id Loan ID
     * @param choice Rater choice. false = NO, true = YES
     */
    function rate(address id, bool choice) internal {
        uint256 stake = stkTRU.getPriorVotes(msg.sender, loans[id].blockNumber);
        require(stake > 0, "TrueRatingAgencyV2: Cannot rate with empty balance");

        resetCastRatings(id);

        loans[id].prediction[choice] = loans[id].prediction[choice].add(stake);
        loans[id].ratings[msg.sender][choice] = loans[id].ratings[msg.sender][choice].add(stake);

        emit Rated(id, msg.sender, choice, stake);
    }

    /**
     * @dev Internal function to help reset ratings
     * @param id Loan ID
     * @param choice Boolean representing choice
     */
    function _resetCastRatings(address id, bool choice) internal {
        loans[id].prediction[choice] = loans[id].prediction[choice].sub(loans[id].ratings[msg.sender][choice]);
        loans[id].ratings[msg.sender][choice] = 0;
    }

    /**
     * @dev Cancel ratings of msg.sender
     * @param id ID to cancel ratings for
     */
    function resetCastRatings(address id) public override onlyPendingLoans(id) {
        if (getYesRate(id, msg.sender) > 0) {
            _resetCastRatings(id, true);
        } else if (getNoRate(id, msg.sender) > 0) {
            _resetCastRatings(id, false);
        }
    }

    /**
     * @dev Rate YES on a loan by staking TRU
     * @param id Loan ID
     */
    function yes(address id) external override onlyPendingLoans(id) {
        rate(id, true);
    }

    /**
     * @dev Rate NO on a loan by staking TRU
     * @param id Loan ID
     */
    function no(address id) external override onlyPendingLoans(id) {
        rate(id, false);
    }

    /**
     * @dev Internal view to convert values to 8 decimals precision
     * @param input Value to convert to TRU precision
     * @return output TRU amount
     */
    function toTRU(uint256 input) internal pure returns (uint256 output) {
        output = input.div(TOKEN_PRECISION_DIFFERENCE);
    }

    /**
     * @dev Update total TRU reward for a Loan
     * Reward is divided proportionally based on # TRU staked
     * chi = (TRU remaining in distributor) / (Total TRU allocated for distribution)
     * interest = (loan APY * term * principal)
     * R = Total Reward = (interest * chi * rewardFactor)
     * @param id Loan ID
     */
    modifier calculateTotalReward(address id) {
        if (loans[id].reward == 0) {
            uint256 interest = ILoanToken(id).profit();

            // calculate reward
            // prettier-ignore
            uint256 totalReward = toTRU(
                interest
                    .mul(distributor.remaining())
                    .mul(rewardMultiplier)
                    .div(distributor.amount())
            );

            uint256 ratersReward = totalReward.mul(ratersRewardFactor).div(10000);
            loans[id].reward = ratersReward;
            if (totalReward > 0) {
                distributor.distribute(totalReward);
                TRU.transfer(address(stkTRU), totalReward.sub(ratersReward));
            }
        }
        _;
    }

    /**
     * @dev Claim TRU rewards for raters
     * - Only can claim TRU rewards for funded loans
     * - Claimed automatically when a user withdraws stake
     *
     * chi = (TRU remaining in distributor) / (Total TRU allocated for distribution)
     * interest = (loan APY * term * principal)
     * R = Total Reward = (interest * chi)
     * R is distributed to raters based on their proportion of ratings/total_ratings
     *
     * Claimable reward = R x (current time / total time)
     *      * (account TRU staked / total TRU staked) - (amount claimed)
     *
     * @param id Loan ID
     * @param rater Rater account
     */
    function claim(address id, address rater) external override onlyFundedLoans(id) calculateTotalReward(id) {
        uint256 claimableRewards = claimable(id, rater);

        if (claimableRewards > 0) {
            // track amount of claimed tokens
            loans[id].claimed[rater] = loans[id].claimed[rater].add(claimableRewards);
            // transfer tokens
            require(TRU.transfer(rater, claimableRewards));
            emit Claimed(id, rater, claimableRewards);
        }
    }

    /**
     * @dev Get amount claimed for loan ID and rater address
     * @param id Loan ID
     * @param rater Rater address
     * @return Amount claimed for id and address
     */
    function claimed(address id, address rater) external view returns (uint256) {
        return loans[id].claimed[rater];
    }

    /**
     * @dev Get amount claimable for loan ID and rater address
     * @param id Loan ID
     * @param rater Rater address
     * @return Amount claimable for id and address
     */
    function claimable(address id, address rater) public view returns (uint256) {
        if (status(id) < LoanStatus.Running) {
            return 0;
        }

        // calculate how many tokens user can claim
        // claimable = stakedByRater / totalStaked
        uint256 stakedByRater = loans[id].ratings[rater][false].add(loans[id].ratings[rater][true]);
        uint256 totalStaked = loans[id].prediction[false].add(loans[id].prediction[true]);

        // calculate claimable rewards at current time
        uint256 totalClaimable = loans[id].reward.mul(stakedByRater).div(totalStaked);

        return totalClaimable.sub(loans[id].claimed[rater]);
    }

    /**
     * @dev Get status for a specific loan
     * We rely on correct implementation of LoanToken
     * @param id Loan ID
     * @return Status of loan
     */
    function status(address id) public view returns (LoanStatus) {
        Loan storage loan = loans[id];
        // Void loan doesn't exist because timestamp is zero
        if (loan.creator == address(0) && loan.timestamp == 0) {
            return LoanStatus.Void;
        }
        // Retracted loan was cancelled by borrower
        if (loan.creator == address(0) && loan.timestamp != 0) {
            return LoanStatus.Retracted;
        }
        // get internal status
        ILoanToken.Status loanInternalStatus = ILoanToken(id).status();

        // Running is Funded || Withdrawn
        if (loanInternalStatus == ILoanToken.Status.Funded || loanInternalStatus == ILoanToken.Status.Withdrawn) {
            return LoanStatus.Running;
        }
        // Settled has been paid back in full and past term
        if (loanInternalStatus == ILoanToken.Status.Settled) {
            return LoanStatus.Settled;
        }
        // Defaulted has not been paid back in full and past term
        if (loanInternalStatus == ILoanToken.Status.Defaulted) {
            return LoanStatus.Defaulted;
        }
        // Liquidated is same as defaulted and stakers have been liquidated
        if (loanInternalStatus == ILoanToken.Status.Liquidated) {
            return LoanStatus.Liquidated;
        }
        // otherwise return Pending
        return LoanStatus.Pending;
    }
}