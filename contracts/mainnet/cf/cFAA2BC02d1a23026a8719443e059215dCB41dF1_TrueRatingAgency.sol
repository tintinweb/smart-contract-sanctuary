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


// Dependency file: contracts/trusttoken/interface/IBurnableERC20.sol

// pragma solidity 0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBurnableERC20 is IERC20 {
    function burn(uint256 amount) external;
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


// Root file: contracts/truefi/TrueRatingAgency.sol

pragma solidity 0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

// import {IBurnableERC20} from "contracts/trusttoken/interface/IBurnableERC20.sol";

// import {Ownable} from "contracts/truefi/common/UpgradeableOwnable.sol";
// import {IArbitraryDistributor} from "contracts/truefi/interface/IArbitraryDistributor.sol";
// import {ILoanFactory} from "contracts/truefi/interface/ILoanFactory.sol";
// import {ILoanToken} from "contracts/truefi/interface/ILoanToken.sol";
// import {ITrueFiPool} from "contracts/truefi/interface/ITrueFiPool.sol";
// import {ITrueRatingAgency} from "contracts/truefi/interface/ITrueRatingAgency.sol";

/**
 * @title TrueRatingAgency
 * @dev Credit prediction market for LoanTokens
 *
 * TrueFi uses use a prediction market to signal how risky a loan is.
 * The Credit Prediction Market estimates the likelihood of a loan defaulting.
 * Any TRU holder can vote YES or NO and stake TRU as collateral on their vote.
 * If a loan is funded, TRU is locked into the market until expiry.
 * Locking TRU into the prediction market allows voters to earn and claim
 * incentive TRU throughout the course of the loan. After the loan's term,
 * if the voter is correct, they earn a TRU reward plus a portion of the
 * losing side's vote. A portion of the losing side's TRU is burned.
 *
 * Voting Lifecycle:
 * - Borrowers can apply for loans at any time by deploying a LoanToken
 * - LoanTokens are registered with the prediction market contract
 * - Once registered, TRU holders can vote at any time
 * - If a loan is funded, TRU is locked for the term of the loan
 * - At the end of the term, payouts are determined based on the loan outcome
 *
 * States:
 * Void:        Rated loan is invalid
 * Pending:     Waiting to be funded
 * Retracted:   Rating has been cancelled
 * Running:     Rated loan has been funded
 * Settled:     Rated loan has been paid back in full
 * Defaulted:   Rated loan has not been paid back in full
 */
contract TrueRatingAgency is ITrueRatingAgency, Ownable {
    using SafeMath for uint256;

    enum LoanStatus {Void, Pending, Retracted, Running, Settled, Defaulted}

    struct Loan {
        address creator;
        uint256 timestamp;
        mapping(bool => uint256) prediction;
        mapping(address => mapping(bool => uint256)) votes;
        mapping(address => uint256) claimed;
        uint256 reward;
    }

    uint256 private constant TOKEN_PRECISION_DIFFERENCE = 10**10;

    // ================ WARNING ==================
    // ===== THIS CONTRACT IS INITIALIZABLE ======
    // === STORAGE VARIABLES ARE DECLARED BELOW ==
    // REMOVAL OR REORDER OF VARIABLES WILL RESULT
    // ========= IN STORAGE CORRUPTION ===========

    mapping(address => bool) public allowedSubmitters;
    mapping(address => Loan) public loans;

    IBurnableERC20 public trustToken;
    IArbitraryDistributor public distributor;
    ILoanFactory public factory;

    /**
     * @dev % multiplied by 100. e.g. 10.5% = 1050
     */
    uint256 public lossFactor;
    uint256 public burnFactor;

    // reward multiplier for voters
    uint256 public rewardMultiplier;

    bool public submissionPauseStatus;

    // ======= STORAGE DECLARATION END ============

    event Allowed(address indexed who, bool status);
    event LossFactorChanged(uint256 lossFactor);
    event BurnFactorChanged(uint256 burnFactor);
    event LoanSubmitted(address id);
    event LoanRetracted(address id);
    event Voted(address loanToken, address voter, bool choice, uint256 stake);
    event Withdrawn(address loanToken, address voter, uint256 stake, uint256 received, uint256 burned);
    event RewardMultiplierChanged(uint256 newRewardMultiplier);
    event Claimed(address loanToken, address voter, uint256 claimedReward);
    event SubmissionPauseStatusChanged(bool status);

    /**
     * @dev Only whitelisted borrowers can submit for credit ratings
     */
    modifier onlyAllowedSubmitters() {
        require(allowedSubmitters[msg.sender], "TrueRatingAgency: Sender is not allowed to submit");
        _;
    }

    /**
     * @dev Only loan submitter can perform certain actions
     */
    modifier onlyCreator(address id) {
        require(loans[id].creator == msg.sender, "TrueRatingAgency: Not sender's loan");
        _;
    }

    /**
     * @dev Cannot submit the same loan multiple times
     */
    modifier onlyNotExistingLoans(address id) {
        require(status(id) == LoanStatus.Void, "TrueRatingAgency: Loan was already created");
        _;
    }

    /**
     * @dev Only loans in Pending state
     */
    modifier onlyPendingLoans(address id) {
        require(status(id) == LoanStatus.Pending, "TrueRatingAgency: Loan is not currently pending");
        _;
    }

    /**
     * @dev Only loans in Running state
     */
    modifier onlyNotRunningLoans(address id) {
        require(status(id) != LoanStatus.Running, "TrueRatingAgency: Loan is currently running");
        _;
    }

    /**
     * @dev Only loans that have been funded
     */
    modifier onlyFundedLoans(address id) {
        require(status(id) >= LoanStatus.Running, "TrueRatingAgency: Loan was not funded");
        _;
    }

    /**
     * @dev Initalize Rating Agenct
     * Distributor contract decides how much TRU is rewarded to stakers
     * @param _trustToken TRU contract
     * @param _distributor Distributor contract
     * @param _factory Factory contract for deploying tokens
     */
    function initialize(
        IBurnableERC20 _trustToken,
        IArbitraryDistributor _distributor,
        ILoanFactory _factory
    ) public initializer {
        require(address(this) == _distributor.beneficiary(), "TrueRatingAgency: Invalid distributor beneficiary");
        Ownable.initialize();

        trustToken = _trustToken;
        distributor = _distributor;
        factory = _factory;

        lossFactor = 2500;
        burnFactor = 2500;
    }

    /**
     * @dev Set loss factor.
     * Loss factor decides what percentage of TRU is lost for incorrect votes
     * @param newLossFactor New loss factor
     */
    function setLossFactor(uint256 newLossFactor) external onlyOwner {
        require(newLossFactor <= 10000, "TrueRatingAgency: Loss factor cannot be greater than 100%");
        lossFactor = newLossFactor;
        emit LossFactorChanged(newLossFactor);
    }

    /**
     * @dev Set burn factor.
     * Burn factor decides what percentage of lost TRU is burned
     */
    function setBurnFactor(uint256 newBurnFactor) external onlyOwner {
        require(newBurnFactor <= 10000, "TrueRatingAgency: Burn factor cannot be greater than 100%");
        burnFactor = newBurnFactor;
        emit BurnFactorChanged(newBurnFactor);
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
     * @dev Get number of NO votes for a specific account and loan
     * @param id Loan ID
     * @param voter Voter account
     */
    function getNoVote(address id, address voter) public view returns (uint256) {
        return loans[id].votes[voter][false];
    }

    /**
     * @dev Get number of YES votes for a specific account and loan
     * @param id Loan ID
     * @param voter Voter account
     */
    function getYesVote(address id, address voter) public view returns (uint256) {
        return loans[id].votes[voter][true];
    }

    /**
     * @dev Get total NO votes for a specific loan
     * @param id Loan ID
     */
    function getTotalNoVotes(address id) public view returns (uint256) {
        return loans[id].prediction[false];
    }

    /**
     * @dev Get total YES votes for a specific loan
     * @param id Loan ID
     */
    function getTotalYesVotes(address id) public view returns (uint256) {
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
        return (getVotingStart(id), getTotalNoVotes(id), getTotalYesVotes(id));
    }

    /**
     * @dev Whitelist borrowers to submit loans for rating
     * @param who Account to whitelist
     * @param status Flag to whitelist accounts
     */
    function allow(address who, bool status) external onlyOwner {
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
        require(!submissionPauseStatus, "TrueRatingAgency: New submissions are paused");
        require(ILoanToken(id).borrower() == msg.sender, "TrueRatingAgency: Sender is not borrower");
        require(factory.isLoanToken(id), "TrueRatingAgency: Only LoanTokens created via LoanFactory are supported");
        loans[id] = Loan({creator: msg.sender, timestamp: block.timestamp, reward: 0});
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
     * @dev Vote on a loan by staking TRU
     * @param id Loan ID
     * @param stake Amount of TRU to stake
     * @param choice Voter choice. false = NO, true = YES
     */
    function vote(
        address id,
        uint256 stake,
        bool choice
    ) internal {
        require(loans[id].votes[msg.sender][!choice] == 0, "TrueRatingAgency: Cannot vote both yes and no");

        loans[id].prediction[choice] = loans[id].prediction[choice].add(stake);
        loans[id].votes[msg.sender][choice] = loans[id].votes[msg.sender][choice].add(stake);

        require(trustToken.transferFrom(msg.sender, address(this), stake));
        emit Voted(id, msg.sender, choice, stake);
    }

    /**
     * @dev Vote YES on a loan by staking TRU
     * @param id Loan ID
     * @param stake Amount of TRU to stake
     */
    function yes(address id, uint256 stake) external override onlyPendingLoans(id) {
        vote(id, stake, true);
    }

    /**
     * @dev Vote NO on a loan by staking TRU
     * @param id Loan ID
     * @param stake Amount of TRU to stake
     */
    function no(address id, uint256 stake) external override onlyPendingLoans(id) {
        vote(id, stake, false);
    }

    // prettier-ignore
    /**
     * @dev Withdraw stake on a loan and remove votes.
     * Unstaking only allowed for loans that are not Running
     * @param id Loan ID
     * @param stake Amount of TRU to unstake
     */
    function withdraw(address id, uint256 stake) external override onlyNotRunningLoans(id) {
        bool choice = loans[id].votes[msg.sender][true] > 0;
        LoanStatus loanStatus = status(id);

        require(loans[id].votes[msg.sender][choice] >= stake,
            "TrueRatingAgency: Cannot withdraw more than was staked");

        uint256 amountToTransfer = stake;
        uint256 burned = 0;
        if (loanStatus > LoanStatus.Running) {
            // claim TRU reward
            claim(id, msg.sender);
            // check if prediction correct
            bool correct = wasPredictionCorrect(id, choice);
            if (correct) {
                // if correct, take some from incorrect side's stake
                // amount taken from incorrect side but not burned
                amountToTransfer = amountToTransfer.add(
                    bounty(id, !choice).mul(stake).div(loans[id].prediction[choice]));
            } else {
                // if incorrect, calculate loss & burn stake
                // stake - (stake * lossFactor)
                uint256 lostAmount = amountToTransfer.mul(lossFactor).div(10000);
                amountToTransfer = amountToTransfer.sub(lostAmount);
                burned = lostAmount.mul(burnFactor).div(10000);
                trustToken.burn(burned);
            }
        }

        // if loan still pending, update total votes
        if (loanStatus == LoanStatus.Pending) {
            loans[id].prediction[choice] = loans[id].prediction[choice].sub(stake);
        }

        // update account votes
        loans[id].votes[msg.sender][choice] = loans[id].votes[msg.sender][choice].sub(stake);

        // transfer tokens to sender and emit event
        require(trustToken.transfer(msg.sender, amountToTransfer));
        emit Withdrawn(id, msg.sender, stake, amountToTransfer, burned);
    }

    /**
     * @dev Total amount of funds given to correct voters
     * @param id Loan ID
     * @param incorrectChoice Vote which was incorrect
     * @return TRU amount given to correct voters
     */
    function bounty(address id, bool incorrectChoice) public view returns (uint256) {
        // reward = (incorrect_tokens_staked) * (loss_factor) * (1 - burn_factor)
        // prettier-ignore
        return loans[id].prediction[incorrectChoice].mul(
            lossFactor).mul(uint256(10000).sub(burnFactor)).div(10000**2);
    }

    /**
     * @dev Internal view to convert values to 8 decimals precision
     * @param input Value to convert to TRU precision
     * @return output TRU amount
     */
    function toTrustToken(uint256 input) internal pure returns (uint256 output) {
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
            uint256 reward = toTrustToken(
                interest
                    .mul(distributor.remaining())
                    .mul(rewardMultiplier)
                    .div(distributor.amount())
            );

            loans[id].reward = reward;
            if (loans[id].reward > 0) {
                distributor.distribute(reward);
            }
        }
        _;
    }

    /**
     * @dev Claim TRU rewards for voters
     * - Only can claim TRU rewards for funded loans
     * - Voters can claim a portion of their total rewards over time
     * - Claimed automatically when a user withdraws stake
     *
     * chi = (TRU remaining in distributor) / (Total TRU allocated for distribution)
     * interest = (loan APY * term * principal)
     * R = Total Reward = (interest * chi)
     * R is distributed to voters based on their proportion of votes/total_votes
     *
     * Claimable reward = R x (current time / total time)
     *      * (account TRU staked / total TRU staked) - (amount claimed)
     *
     * @param id Loan ID
     * @param voter Voter account
     */
    function claim(address id, address voter) public override onlyFundedLoans(id) calculateTotalReward(id) {
        uint256 claimableRewards = claimable(id, voter);

        if (claimableRewards > 0) {
            // track amount of claimed tokens
            loans[id].claimed[voter] = loans[id].claimed[voter].add(claimableRewards);
            // transfer tokens
            require(trustToken.transfer(voter, claimableRewards));
            emit Claimed(id, voter, claimableRewards);
        }
    }

    function claimed(address id, address voter) external view returns (uint256) {
        return loans[id].claimed[voter];
    }

    function claimable(address id, address voter) public view returns (uint256) {
        if (status(id) < LoanStatus.Running) {
            return 0;
        }

        uint256 totalTime = ILoanToken(id).term();
        uint256 passedTime = block.timestamp.sub(ILoanToken(id).start());

        // check time of loan
        if (passedTime > totalTime) {
            passedTime = totalTime;
        }
        // calculate how many tokens user can claim
        // claimable = stakedByVoter / totalStaked
        uint256 stakedByVoter = loans[id].votes[voter][false].add(loans[id].votes[voter][true]);
        uint256 totalStaked = loans[id].prediction[false].add(loans[id].prediction[true]);

        // calculate claimable rewards at current time
        uint256 helper = loans[id].reward.mul(passedTime).mul(stakedByVoter);
        uint256 totalClaimable = helper.div(totalTime).div(totalStaked);
        if (totalClaimable < loans[id].claimed[voter]) {
            // This happens only in one case: voter withdrew part of stake after loan has ended and claimed all possible rewards
            return 0;
        }
        return totalClaimable.sub(loans[id].claimed[voter]);
    }

    /**
     * @dev Check if a prediction was correct for a specific loan and vote
     * @param id Loan ID
     * @param choice Outcome prediction
     */
    function wasPredictionCorrect(address id, bool choice) internal view returns (bool) {
        if (status(id) == LoanStatus.Settled && choice) {
            return true;
        }
        if (status(id) == LoanStatus.Defaulted && !choice) {
            return true;
        }
        return false;
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
        // otherwise return Pending
        return LoanStatus.Pending;
    }
}