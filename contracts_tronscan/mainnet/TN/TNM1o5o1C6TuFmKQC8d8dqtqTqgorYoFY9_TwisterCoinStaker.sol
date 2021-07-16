//SourceUnit: Context.sol

pragma solidity ^0.6.0;
import "Initializable.sol";

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


//SourceUnit: IERC20.sol

pragma solidity ^0.6.0;

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


//SourceUnit: Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


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


//SourceUnit: Math.sol

pragma solidity ^0.6.0;

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


//SourceUnit: Ownable.sol

pragma solidity ^0.6.0;

import "Context.sol";
import "Initializable.sol";
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


//SourceUnit: ReentrancyGuard.sol

pragma solidity ^0.6.0;
import "Initializable.sol";

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


//SourceUnit: SafeMath.sol

pragma solidity ^0.6.0;

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


//SourceUnit: TwisterCoinStaker.sol

// contracts/TwisterCoinStaker.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "Initializable.sol";
import "SafeMath.sol";
import "Math.sol";
import "Ownable.sol";
import "IERC20.sol";
import "ReentrancyGuard.sol";


interface TwisterTokenDispenser {
    function allowedAgents(address addr) external view returns(bool);
    function twisterTokenClaim() external view returns(address);
}

interface TwisterTokenClaim {
    function calcClaimAmount(address token, uint256 amount) external view returns (uint256);
    function mixerFeePercentage(address token, uint256 amount) external view returns (uint256);
    function mixerFee(address token, uint256 amount) external view returns (uint256);
    function depositFee() external view returns (uint256);
    function withdrawFee() external view returns (uint256);
}

contract TwisterCoinStaker is Initializable, OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe {
    using SafeMath for uint256;

    event ReceivedDividend(
        address contractAddr,
        address token,
        uint256 dividend,
        uint256 investedCoins,
        uint256 timestamp
    );

    event WithdrawDividend(
        address player,
        address token,
        uint256 withdrawAmount,
        uint256 timestamp
    );

    event ReceivedStake(
        address staker,
        uint256 newCoins,
        uint256 totalInvestedCoins,
        uint256 timestamp
    );

    event RequestFund(
        address requester,
        address target,
        address token,
        uint256 amount,
        uint256 timestamp
    );

    event RemovedStake(
        address staker,
        uint256 removedCoins,
        uint256 totalInvestedCoins,
        uint256 timestamp
    );

    event WithdrawReward(
        address player,
        uint256 withdrawAmount,
        uint256 timestamap
    );

    struct Status {
        uint256 dividendPerCoin;
        uint256 totalDividend;
        uint256 dust;
    }

    struct StakerStatus {
        uint256 dividendMask;
        uint256 parkedDividend;
        uint256 withdrawnDividend;
    }

    struct RewardStatus {
        uint256 lastRewardBlock;
        uint256 rewardPerCoin;
        uint256 totalReward;
        uint256 rewardDust;
    }

    struct RewardStakerStatus {
        uint256 rewardMask;
        uint256 parkedReward;
        uint256 withdrawnReward;
    }

    uint256 public REWARDS_BLOCKS;              // total reward blocks
    uint256 public REWARDS_PER_BLOCK;           // reward per block

    address public TwisterToken;                            // twister token
    address public trxTRC20;                                // trxTRC20 address
    TwisterTokenDispenser public TokenDispenser;            // token dispenser address
    address payable public communityAddress;               // community address
    uint256 public communityPercentage;                     // community percentage (in 0.01%, e.g. 100 = 1%)
    mapping(address => uint256) public communityAmounts;    // community amounts
    uint256 public numberOfTokens;                          // number of allowed tokens
    mapping(uint256 => address) public tokens;              // allowed tokens
    uint256 public totalInvestedCoins;                      // total invested coins
    mapping(address => Status) public status;               // status
    mapping(address => uint256) public investedCoins;       // staker invested coins
    mapping(address => mapping(address => StakerStatus)) public stakerStatus;   // staker status
    uint256 public rewardStartBlock;
    RewardStatus public rewardStatus;
    mapping(address => RewardStakerStatus) public rewardStakerStatus;
    mapping(address => bool) public allowedTokens;          // reverse index of allowed tokens

    modifier onlyAgent {
        require(TokenDispenser.allowedAgents(msg.sender), "not allowed agent");
        _;
    }

    // TODO: check these addresses before deploy
    function initialize(address _twisterToken, address _tokenDispenser, address payable _community) public initializer {
        TwisterToken = _twisterToken;
        TokenDispenser = TwisterTokenDispenser(_tokenDispenser);
        trxTRC20 = address(0x414141414141414141414141414141414141414141);
        communityPercentage = 1000;
        communityAddress = _community;
        REWARDS_BLOCKS = 0;
        REWARDS_PER_BLOCK = 0;
        rewardStartBlock = block.number;
        ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();
        OwnableUpgradeSafe.__Ownable_init();
    }

    /// set allowed tokens
    function addTokens(address tokenAddr) public onlyOwner {
        require(!allowedTokens[tokenAddr], "token already added");

        tokens[numberOfTokens] = tokenAddr;
        allowedTokens[tokenAddr] = true;
        numberOfTokens++;
    }

    /// mixer fee percentage
    function mixerFeePercentage(address token, uint256 amount) public view returns (uint256) {
        TwisterTokenClaim twisterTokenClaim = TwisterTokenClaim(TokenDispenser.twisterTokenClaim());
        return twisterTokenClaim.mixerFeePercentage(token, amount);
    }

    /// mixer fee
    function mixerFee(address token, uint256 amount) public view returns (uint256) {
        TwisterTokenClaim twisterTokenClaim = TwisterTokenClaim(TokenDispenser.twisterTokenClaim());
        return twisterTokenClaim.mixerFee(token, amount);
    }

    /// deposit fee
    function depositFee() public view returns (uint256) {
        TwisterTokenClaim twisterTokenClaim = TwisterTokenClaim(TokenDispenser.twisterTokenClaim());
        return twisterTokenClaim.depositFee();
    }

    /// withdraw fee
    function withdrawFee() public view returns (uint256) {
        TwisterTokenClaim twisterTokenClaim = TwisterTokenClaim(TokenDispenser.twisterTokenClaim());
        return twisterTokenClaim.withdrawFee();
    }

    /// set community address
    function setCommunityAddress(address payable newAddr) public onlyOwner {
        communityAddress = newAddr;
    }

    /// pay community (anyone can call this function, but it always pays to community address)
    function withdrawCommunityAmount(address token) public nonReentrant {
        uint256 amount = communityAmounts[token];
        require(amount > 0, "no remaining community amount for this token");
        communityAmounts[token] = 0;
        if (amount > 0) {
            if (token == trxTRC20) {
                communityAddress.transfer(amount);
            }
            else {
                _safeErc20Transfer(token, communityAddress, amount);
            }
        }
    }

    /// accept dividend from agents
    function sendDividend(address token, uint256 amount) public payable onlyAgent nonReentrant {
        require(allowedTokens[token], "not allowed token");

        status[token].totalDividend = status[token].totalDividend.add(amount);

        emit ReceivedDividend(msg.sender, token, amount, totalInvestedCoins, now);

        if (totalInvestedCoins == 0) {
            // no invested coins, send the dividend to owner
            communityAmounts[token] = communityAmounts[token].add(amount);
        }
        else {
            uint256 communityPart = amount.mul(communityPercentage) / 10000;
            communityAmounts[token] = communityAmounts[token].add(communityPart);
            uint256 remainPart = amount.sub(communityPart);

            uint256 bigAmount = remainPart.mul(1000000000000000000000000000).add(status[token].dust);
            uint256 newDividendPerCoin = bigAmount / totalInvestedCoins;
            status[token].dividendPerCoin = status[token].dividendPerCoin.add(newDividendPerCoin);
            status[token].dust = bigAmount.sub(newDividendPerCoin.mul(totalInvestedCoins));
        }
    }


    /// request sending fund
    function requestFund(address token, address payable to, uint256 amount) public onlyAgent nonReentrant {
        if (token == trxTRC20) {
            to.transfer(amount);
            emit RequestFund(msg.sender, to, trxTRC20, amount, now);
        }
        else {
            _safeErc20Transfer(token, to, amount);
            emit RequestFund(msg.sender, to, token, amount, now);
        }
    }


    function _safeErc20Transfer(address _token, address _to, uint256 _amount) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0xa9059cbb /* transfer */, _to, _amount));
        require(success, "not enough tokens");

        // if contract returns some data lets make sure that is `true` according to standard
        if (data.length > 0) {
            require(data.length == 32, "data length should be either 0 or 32 bytes");
            success = abi.decode(data, (bool));
            require(success, "not enough tokens. Token returns false.");
        }
    }


    function _safeErc20TransferFrom(address _token, address _from, address _to, uint256 _amount) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd /* transferFrom */, _from, _to, _amount));
        require(success, "not enough allowed tokens");

        // if contract returns some data lets make sure that is `true` according to standard
        if (data.length > 0) {
            require(data.length == 32, "data length should be either 0 or 32 bytes");
            success = abi.decode(data, (bool));
            require(success, "not enough allowed tokens. Token returns false.");
        }
    }

    /// stake coins
    function stake(uint256 amount) public nonReentrant {
        require(amount > 0, "Need to stake more than 0");

        _safeErc20TransferFrom(TwisterToken, msg.sender, address(this), amount);

        // handle rewards
        uint256 rewards;
        uint256 currentBlock;
        (rewards, currentBlock) = additionalRewards();
        if (rewards > 0) {
            syncRewards(rewards, currentBlock);

            uint256 currentReward;
            uint256 currentDust;
            (currentReward, currentDust) = rewardWithDust(msg.sender);

            rewardStakerStatus[msg.sender].parkedReward = currentReward;
            rewardStatus.rewardDust = rewardStatus.rewardDust.add(currentDust);
        }

        uint256 i;
        for (i = 0; i < numberOfTokens; i++) {
            address token = tokens[i];

            // calculate current dividend
            uint256 currentDividend;
            uint256 currentDust;
            (currentDividend, currentDust) = dividendWithDust(msg.sender, token);

            stakerStatus[msg.sender][token].parkedDividend = currentDividend;
            status[token].dust = status[token].dust.add(currentDust);
        }

        investedCoins[msg.sender] = investedCoins[msg.sender].add(amount);

        rewardStakerStatus[msg.sender].rewardMask = investedCoins[msg.sender].mul(rewardStatus.rewardPerCoin);

        for (i = 0; i < numberOfTokens; i++) {
            address token = tokens[i];
            stakerStatus[msg.sender][token].dividendMask = investedCoins[msg.sender].mul(status[token].dividendPerCoin);
        }

        totalInvestedCoins = totalInvestedCoins.add(amount);

        emit ReceivedStake(msg.sender, amount, investedCoins[msg.sender], now);
    }

    /// unstake coins (use amount = 0 to unstake all)
    function unstake(uint256 amount) public nonReentrant {
        require(investedCoins[msg.sender] >= amount, "Insufficient fund to unstake");
        
        uint256 unstakeAmount = amount;
        if (unstakeAmount == 0) {
            unstakeAmount = investedCoins[msg.sender];
        }

        // handle rewards
        uint256 rewards;
        uint256 currentBlock;
        (rewards, currentBlock) = additionalRewards();
        if (rewards > 0) {
            syncRewards(rewards, currentBlock);

            uint256 currentReward;
            uint256 currentDust;
            (currentReward, currentDust) = rewardWithDust(msg.sender);

            rewardStakerStatus[msg.sender].parkedReward = currentReward;
            rewardStatus.rewardDust = rewardStatus.rewardDust.add(currentDust);            
        }        

        uint256 i;
        for (i = 0; i < numberOfTokens; i++) {
            address token = tokens[i];

            // calculate current dividend
            uint256 currentDividend;
            uint256 currentDust;
            (currentDividend, currentDust) = dividendWithDust(msg.sender, token);

            stakerStatus[msg.sender][token].parkedDividend = currentDividend;
            status[token].dust = status[token].dust.add(currentDust);
        }       

        investedCoins[msg.sender] = investedCoins[msg.sender].sub(unstakeAmount);

        rewardStakerStatus[msg.sender].rewardMask = investedCoins[msg.sender].mul(rewardStatus.rewardPerCoin);
        
        for (i = 0; i < numberOfTokens; i++) {
            address token = tokens[i];
            stakerStatus[msg.sender][token].dividendMask = investedCoins[msg.sender].mul(status[token].dividendPerCoin);
        }

        totalInvestedCoins = totalInvestedCoins.sub(unstakeAmount);

        _safeErc20Transfer(TwisterToken, msg.sender, unstakeAmount);

        emit RemovedStake(msg.sender, unstakeAmount, investedCoins[msg.sender], now);
    }


    /// withdraw dividends
    function withdraw(address payable stakerAddr, address token) public nonReentrant {
        // calculate current dividend
        uint256 currentDividend;
        uint256 currentDust;
        (currentDividend, currentDust) = dividendWithDust(stakerAddr, token);

        if (currentDividend > 0) {
            // clear parked dividend and update mask
            stakerStatus[stakerAddr][token].parkedDividend = 0;
            stakerStatus[stakerAddr][token].dividendMask = investedCoins[stakerAddr].mul(status[token].dividendPerCoin);
            status[token].dust = status[token].dust.add(currentDust);

            stakerStatus[stakerAddr][token].withdrawnDividend = stakerStatus[stakerAddr][token].withdrawnDividend.add(currentDividend);

            if (token == trxTRC20) {
                stakerAddr.transfer(currentDividend);
            }
            else {
                _safeErc20Transfer(token, stakerAddr, currentDividend);
            }

            emit WithdrawDividend(stakerAddr, token, currentDividend, now);
        }
    }

    /// withdraw dividends
    function withdraw(address payable token) public {
        withdraw(msg.sender, token);
    }


    /// withdraw all dividends
    function withdrawAll(address payable stakeAddr) public {
        uint256 i;
        for (i = 0; i < numberOfTokens; i++) {
            withdraw(stakeAddr, tokens[i]);
        }
    }

    /// withdraw all dividends
    function withdrawAll() public {
        withdrawAll(msg.sender);
    }

    /// claim rewards
    function claimRewards(address stakerAddr) public nonReentrant {
        // sync reward
        uint256 rewards;
        uint256 currentBlock;
        (rewards, currentBlock) = additionalRewards();
        if (rewards > 0) {
            syncRewards(rewards, currentBlock);
        }

        // calculate current reward
        uint256 currentReward;
        uint256 currentDust;
        (currentReward, currentDust) = rewardWithDust(stakerAddr);

        if (currentReward > 0) {
            // clear parked dividend and update mask
            rewardStakerStatus[stakerAddr].parkedReward = 0;
            rewardStakerStatus[stakerAddr].rewardMask = investedCoins[stakerAddr].mul(rewardStatus.rewardPerCoin);
            rewardStatus.rewardDust = rewardStatus.rewardDust.add(currentDust);

            rewardStakerStatus[stakerAddr].withdrawnReward = rewardStakerStatus[stakerAddr].withdrawnReward.add(currentReward);

            _safeErc20Transfer(TwisterToken, stakerAddr, currentReward);

            emit WithdrawReward(stakerAddr, currentReward, now);
        }
    }

    /// claim rewards
    function claimRewards() public {
        claimRewards(msg.sender);
    }


    /// @notice get current dividend for a staker
    function dividend(address stakerAddr, address token) public view returns (uint256) {
        uint256 stakerDividend = 0;

        // calculate with dividendPerCoin
        if (investedCoins[stakerAddr] > 0) {
            stakerDividend = stakerDividend.add(investedCoins[stakerAddr].mul(status[token].dividendPerCoin));
            stakerDividend = stakerDividend.sub(stakerStatus[stakerAddr][token].dividendMask) / 1000000000000000000000000000;
        }

        stakerDividend = stakerDividend.add(stakerStatus[stakerAddr][token].parkedDividend);

        return stakerDividend;
    }


    /// @dev get current dividend and dust for a staker
    /// @return dividend, dust
    function dividendWithDust(address stakerAddr, address token) internal view returns (uint256, uint256) {
        uint256 stakerDividend = 0;
        uint256 dust = 0;

        // calculate with dividendPerCoin
        if (investedCoins[stakerAddr] > 0) {
            stakerDividend = stakerDividend.add(investedCoins[stakerAddr].mul(status[token].dividendPerCoin));
            dust = stakerDividend.sub(stakerStatus[stakerAddr][token].dividendMask) % 1000000000000000000000000000;
            stakerDividend = stakerDividend.sub(stakerStatus[stakerAddr][token].dividendMask) / 1000000000000000000000000000;
        }

        stakerDividend = stakerDividend.add(stakerStatus[stakerAddr][token].parkedDividend);

        return (stakerDividend, dust);
    }

    /// @dev get current reward
    /// @return rewards
    function reward(address stakerAddr) public view returns (uint256) {
        uint256 stakerReward = 0;

        // calculate with dividendPerCoin
        if (investedCoins[stakerAddr] > 0) {
            uint256 rewards;
            uint256 currentBlock;
            (rewards, currentBlock) = additionalRewards();
            uint256 bigAmount = rewards.mul(1000000000000000000000000000).add(rewardStatus.rewardDust);
            uint256 rewardPerCoin = rewardStatus.rewardPerCoin.add(bigAmount / totalInvestedCoins);

            stakerReward = stakerReward.add(investedCoins[stakerAddr].mul(rewardPerCoin));
            stakerReward = stakerReward.sub(rewardStakerStatus[stakerAddr].rewardMask) / 1000000000000000000000000000;
        }

        stakerReward = stakerReward.add(rewardStakerStatus[stakerAddr].parkedReward);

        return stakerReward;
    }

    /// @dev get current reward and dust for a staker
    /// @return reward, dust
    function rewardWithDust(address stakerAddr) internal view returns (uint256, uint256) {
        uint256 stakerReward = 0;
        uint256 dust = 0;

        // calculate with dividendPerCoin
        if (investedCoins[stakerAddr] > 0) {
            stakerReward = stakerReward.add(investedCoins[stakerAddr].mul(rewardStatus.rewardPerCoin));
            dust = stakerReward.sub(rewardStakerStatus[stakerAddr].rewardMask) % 1000000000000000000000000000;
            stakerReward = stakerReward.sub(rewardStakerStatus[stakerAddr].rewardMask) / 1000000000000000000000000000;
        }

        stakerReward = stakerReward.add(rewardStakerStatus[stakerAddr].parkedReward);

        return (stakerReward, dust);
    }

    function additionalRewards() internal view returns (uint256, uint256) {
        // uint256 currentBlock = Math.min(block.number, rewardStartBlock.add(REWARDS_BLOCKS));
        // uint256 additionalRewardBlocks = currentBlock.sub(rewardStatus.lastRewardBlock);
        // return (additionalRewardBlocks.mul(REWARDS_PER_BLOCK), currentBlock);
        return (0, 0);
    }

    function syncRewards(uint256 amount, uint256 currentBlock) internal {
        rewardStatus.totalReward = rewardStatus.totalReward.add(amount);
        rewardStatus.lastRewardBlock = currentBlock;

        if (totalInvestedCoins == 0) {
            // no invested coins, send the dividend to owner
            communityAmounts[TwisterToken] = communityAmounts[TwisterToken].add(amount);
        }
        else {
            uint256 bigAmount = amount.mul(1000000000000000000000000000).add(rewardStatus.rewardDust);
            uint256 newRewardPerCoin = bigAmount / totalInvestedCoins;
            rewardStatus.rewardPerCoin = rewardStatus.rewardPerCoin.add(newRewardPerCoin);
            rewardStatus.rewardDust = bigAmount.sub(newRewardPerCoin.mul(totalInvestedCoins));
        }        
    }
}