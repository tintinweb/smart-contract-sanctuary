// Dependency file: @openzeppelin/contracts-ethereum-package/contracts/math/Math.sol

// pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// Dependency file: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

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


// Dependency file: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

// pragma solidity >=0.4.24 <0.7.0;


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
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


// Dependency file: @openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol

// pragma solidity ^0.6.0;
// import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

    }


    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}


// Dependency file: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

// pragma solidity ^0.6.0;
// import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

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


// Dependency file: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

// pragma solidity ^0.6.0;

// import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
// import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
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

    uint256[49] private __gap;
}


// Dependency file: contracts/BannedContractList.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

// import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

/*
    Approve and Ban Contracts to interact with pools.
    (All contracts are approved by default, unless banned)
*/
contract BannedContractList is Initializable, OwnableUpgradeSafe {
    mapping(address => bool) banned;

    function initialize() public initializer {
        __Ownable_init();
    }

    function isApproved(address toCheck) external view returns (bool) {
        return !banned[toCheck];
    }

    function isBanned(address toCheck) external view returns (bool) {
        return banned[toCheck];
    }

    function approveContract(address toApprove) external onlyOwner {
        banned[toApprove] = false;
    }

    function banContract(address toBan) external onlyOwner {
        banned[toBan] = true;
    }
}


// Dependency file: contracts/Defensible.sol


// pragma solidity ^0.6.0;

// import "contracts/BannedContractList.sol";

/*
    Prevent smart contracts from calling functions unless approved by the specified whitelist.
*/
contract Defensible {
 // Only smart contracts will be affected by this modifier
  modifier defend(BannedContractList bannedContractList) {
    require(
      (msg.sender == tx.origin) || bannedContractList.isApproved(msg.sender),
      "This smart contract has not been approved"
    );
    _;
  }
}


// Dependency file: contracts/interfaces/IMiniMe.sol


// pragma solidity ^0.6.0;

interface IMiniMe {
    /* ========== STANDARD ERC20 ========== */
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /* ========== MINIME EXTENSIONS ========== */

    function balanceOfAt(address account, uint256 blockNumber) external view returns (uint256);
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256);
}


// Dependency file: contracts/interfaces/ISporeToken.sol


// pragma solidity ^0.6.0;

interface ISporeToken {
    /* ========== STANDARD ERC20 ========== */
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /* ========== EXTENSIONS ========== */

    function burn(uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function addInitialLiquidityTransferRights(address account) external;

    function enableTransfers() external;

    function addMinter(address account) external;

    function removeMinter(address account) external;
}


// Dependency file: contracts/interfaces/IRateVoteable.sol


// pragma solidity ^0.6.0;

interface IRateVoteable {
    function changeRate(uint256 percentage) external;
}


// Root file: contracts/RateVote.sol


pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
// import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";

// import "contracts/Defensible.sol";
// import "contracts/interfaces/IMiniMe.sol";
// import "contracts/interfaces/ISporeToken.sol";
// import "contracts/interfaces/IRateVoteable.sol";
// import "contracts/BannedContractList.sol";

/*
    Can be paused by the owner
    The mushroomFactory must be set by the owner before mushrooms can be harvested (optionally), and can be modified to use new mushroom spawning logic
*/
contract RateVote is ReentrancyGuardUpgradeSafe, Defensible {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    uint256 public constant MAX_PERCENTAGE = 100;
    uint256 public votingEnabledTime;

    mapping(address => uint256) lastVoted;

    struct VoteEpoch {
        uint256 startTime;
        uint256 activeEpoch;
        uint256 increaseVoteWeight;
        uint256 decreaseVoteWeight;
    }

    VoteEpoch public voteEpoch;
    uint256 public voteDuration;

    IMiniMe public enokiToken;
    IRateVoteable public pool;
    BannedContractList public bannedContractList;

    // In percentage: mul(X).div(100)
    uint256 public decreaseRateMultiplier;
    uint256 public increaseRateMultiplier;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _pool,
        address _enokiToken,
        uint256 _voteDuration,
        uint256 _votingEnabledTime,
        address _bannedContractList
    ) public virtual initializer {
        __ReentrancyGuard_init();

        pool = IRateVoteable(_pool);

        decreaseRateMultiplier = 50;
        increaseRateMultiplier = 150;

        votingEnabledTime = _votingEnabledTime;

        voteDuration = _voteDuration;

        enokiToken = IMiniMe(_enokiToken);

        voteEpoch = VoteEpoch({
            startTime: votingEnabledTime, 
            activeEpoch: 0, 
            increaseVoteWeight: 0, 
            decreaseVoteWeight: 0
        });

        bannedContractList = BannedContractList(_bannedContractList);
    }

    /*
        Votes with a given nonce invalidate other votes with the same nonce
        This ensures only one rate vote can pass for a given time period
    */

    function getVoteEpoch() external view returns (VoteEpoch memory) {
        return voteEpoch;
    }

    /* === Actions === */

    /// @notice Any user can vote once in a given voting epoch, with their balance at the start of the epoch
    function vote(uint256 voteId) external nonReentrant defend(bannedContractList) {
        require(now > votingEnabledTime, "Too early");
        require(now <= voteEpoch.startTime.add(voteDuration), "Vote has ended");
        require(lastVoted[msg.sender] < voteEpoch.activeEpoch, "Already voted");

        uint256 userWeight = enokiToken.balanceOfAt(msg.sender, voteEpoch.startTime);

        if (voteId == 0) {
            // Decrease rate
            voteEpoch.decreaseVoteWeight = voteEpoch.decreaseVoteWeight.add(userWeight);
        } else if (voteId == 1) {
            // Increase rate
            voteEpoch.increaseVoteWeight = voteEpoch.increaseVoteWeight.add(userWeight);
        } else {
            revert("Invalid voteId");
        }

        lastVoted[msg.sender] = voteEpoch.activeEpoch;

        emit Vote(msg.sender, voteEpoch.activeEpoch, userWeight, voteId);
    }

    /// @notice Once a vote has exceeded the duration, it can be resolved, implementing the decision and starting the next vote    
    function resolveVote() external nonReentrant defend(bannedContractList) {
        require(now >= voteEpoch.startTime.add(voteDuration), "Vote still active");
        uint256 decision = 0;

        if (voteEpoch.decreaseVoteWeight > voteEpoch.increaseVoteWeight) {
            // Decrease wins
            pool.changeRate(decreaseRateMultiplier);
        } else if (voteEpoch.increaseVoteWeight > voteEpoch.decreaseVoteWeight) {
            // Increase wins
            pool.changeRate(increaseRateMultiplier);
            decision = 1;
        } else {
            //else Tie, no rate change
            decision = 2;
        }

        emit VoteResolved(voteEpoch.activeEpoch, decision);

        voteEpoch.activeEpoch = voteEpoch.activeEpoch.add(1);
        voteEpoch.decreaseVoteWeight = 0;
        voteEpoch.increaseVoteWeight = 0;
        voteEpoch.startTime = now;

        emit VoteStarted(voteEpoch.activeEpoch, voteEpoch.startTime, voteEpoch.startTime.add(voteDuration));
    }

    /* ===Events=== */

    event Vote(address indexed user, uint256 indexed epoch, uint256 weight, uint256 indexed vote);
    event VoteResolved(uint256 indexed epoch, uint256 indexed decision);
    event VoteStarted(uint256 indexed epoch, uint256 startTime, uint256 endTime);
}