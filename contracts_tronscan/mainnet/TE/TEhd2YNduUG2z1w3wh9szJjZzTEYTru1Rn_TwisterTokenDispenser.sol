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


//SourceUnit: TwisterTokenDispenser.sol

// contracts/TwisterTokenDispenser.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;


import "Initializable.sol";
import "SafeMath.sol";
import "Math.sol";
import "Ownable.sol";
import "IERC20.sol";
import "ReentrancyGuard.sol";

interface TwisterTokenClaim {
    function calcClaimAmount(address token, uint256 amount) external view returns (uint256);
}

contract TwisterTokenDispenser is Initializable, OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe {
    using SafeMath for uint256;

    event Claimed(address, address, uint256, uint256, uint256);
    event Withdrawn(address, address, uint256, uint256);

    uint256 public EPOCH_BLOCKS;                // how many blocks for each small epoch
    uint256 public BIG_EPOCHS;                  // how many small epochs for each big epoch
    uint256 public TOTAL_BIG_EPOCHS;            // maximum number of big epochs
    uint256 public STARTING_DISPENSE_AMOUNT;    // starting dispense amount for each big epoch
    address public TwisterToken;                // twister token

    uint256 public genesisBlock;
    uint256 public lastClaimedEpoch;
    mapping(address => bool) public allowedAgents;
    mapping(uint256 => uint256) public amountForEpoch;
    mapping(uint256 => uint256) public claimersForEpoch;
    mapping(address => uint256) public lastEpochForClaimer;
    mapping(address => uint256) public lastAmountForClaimer;
    mapping(address => mapping(address => uint256)) public lastEpochForContractClaimer;
    mapping(address => uint256) public totalAmountForClaimer;
    TwisterTokenClaim public twisterTokenClaim;     // twister token claim

    // TODO: check these addresses before deploy
    function initialize(uint256 epochBlocks, uint256 bigEpochs, address _twisterToken) public initializer {
        EPOCH_BLOCKS = epochBlocks;
        BIG_EPOCHS = bigEpochs;
        TOTAL_BIG_EPOCHS = 19;
        STARTING_DISPENSE_AMOUNT = 7350000 * 10**18;
        TwisterToken = _twisterToken;
        ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();
        OwnableUpgradeSafe.__Ownable_init();
    }

    // enable
    function enable(uint256 blockNumber) public onlyOwner {
        require(genesisBlock == 0, "already enabled");
        if (blockNumber == 0) {
            genesisBlock = block.number;            
        }
        else {
            genesisBlock = blockNumber;
        }

        lastClaimedEpoch = 1;
        amountForEpoch[1] = baseDispenseAmountForEpoch(1);
    }

    // is enabled
    function isEnabled() public view returns (bool) {
        return genesisBlock != 0 && block.number >= genesisBlock;
    }

    // set allowed claimers
    function setAllowedAgent(address agentAddr, bool enableAgent) public onlyOwner {
        allowedAgents[agentAddr] = enableAgent;
    }

    // get allowed claimers
    function isAllowedAgent(address agentAddr) public view returns (bool) {
        return allowedAgents[agentAddr];
    }

    // set twister token claim
    function setTwisterTokenClaim(address _twisterTokenClaim) public onlyOwner {
        twisterTokenClaim = TwisterTokenClaim(_twisterTokenClaim);
    }

    // get current accumulated claim amount
    function calculateDispenseAmount(uint256 epoch) public view onlyEnabled returns (uint256) {
        uint256 lastClaimBigEpoch = Math.min((lastClaimedEpoch - 1) / BIG_EPOCHS + 1, TOTAL_BIG_EPOCHS);
        uint256 limitedEpoch = Math.min(epoch, TOTAL_BIG_EPOCHS * BIG_EPOCHS + 1);
        uint256 currentBigEpoch = Math.min((limitedEpoch - 1) / BIG_EPOCHS + 1, TOTAL_BIG_EPOCHS);

        if (lastClaimBigEpoch == currentBigEpoch) {
            // same big epoch
            return baseDispenseAmountForEpoch(currentBigEpoch).mul(limitedEpoch.sub(lastClaimedEpoch));
        }
        else {
            uint256 total = baseDispenseAmountForEpoch(lastClaimBigEpoch).mul(BIG_EPOCHS.mul(lastClaimBigEpoch).sub(lastClaimedEpoch));
            //if (lastClaimBigEpoch + 1 < currentBigEpoch) {
            //    total = total.add(baseDispenseAmountForEpoch(lastClaimBigEpoch).sub(baseDispenseAmountForEpoch(currentBigEpoch.sub(1))).mul(BIG_EPOCHS));
            //}
            // the loop version will produce a slightly different result due to round-off error compared to the one line version
            // (the loop version is the correct one)
            for (uint256 i = lastClaimBigEpoch + 1; i < currentBigEpoch; i++) {
                total = total.add(baseDispenseAmountForEpoch(i).mul(BIG_EPOCHS));
            }
            total = total.add(baseDispenseAmountForEpoch(currentBigEpoch).mul(limitedEpoch.sub(BIG_EPOCHS.mul(currentBigEpoch.sub(1)))));
            return total;
        }
    }

    // get current dispense amount
    function getCurrentDispenseAmount() public view onlyEnabled returns (uint256) {
        uint256 epoch = currentEpoch();
        return amountForEpoch[epoch].add(calculateDispenseAmount(epoch));
    }

    // get dispense amount for previous epochs
    function getDispenseAmount(uint256 epoch) public view onlyEnabled returns (uint256) {
        require(epoch <= currentEpoch(), "epoch is too large");
        if (epoch == currentEpoch()) {
            return getCurrentDispenseAmount();
        }
        else {
            return amountForEpoch[epoch];
        }
    }

    // is able to claim
    function isAbleToClaim(address targetAddr, address agentAddr) public view onlyEnabled returns (bool) {
        // agents are not able to claim
        if (isAllowedAgent(targetAddr)) {
            return false;
        }
        
        return true;
        // NOTE: removed restriction for claims within the same epoch
        //return lastEpochForContractClaimer[targetAddr][agentAddr] != currentEpoch();
    }

    // calculate claim amount
    // TODO: check these numbers before deploy
    function calcClaimAmount(address token, uint256 amount) public view returns (uint256) {
        return twisterTokenClaim.calcClaimAmount(token, amount);
    }

    // claim for address
    function claim(address targetAddr, address token, uint256 amount) public onlyEnabled nonReentrant onlyAgent(msg.sender) {
        uint256 claimAmount = calcClaimAmount(token, amount);
        if (claimAmount > 0) {
            uint256 epoch = currentEpoch();
            // NOTE: removed restriction for claims within the same epoch
            //require(lastEpochForContractClaimer[targetAddr][msg.sender] != epoch, "already claimed for current epoch");
            lastEpochForContractClaimer[targetAddr][msg.sender] = epoch;

            uint256 lastEpoch = lastEpochForClaimer[targetAddr];
            uint256 lastAmount = 0;
            if (lastEpoch != epoch) {
                lastEpochForClaimer[targetAddr] = epoch;
                lastAmount = lastAmountForClaimer[targetAddr];
                lastAmountForClaimer[targetAddr] = 0;
            }
            
            claimersForEpoch[epoch] = claimersForEpoch[epoch].add(claimAmount);
            lastAmountForClaimer[targetAddr] = lastAmountForClaimer[targetAddr].add(claimAmount);

            // calculate amount for current epoch
            if (lastClaimedEpoch != epoch) {
                amountForEpoch[epoch] = calculateDispenseAmount(epoch);
                lastClaimedEpoch = epoch;
            }

            if (lastEpoch != epoch && claimersForEpoch[lastEpoch] > 0) {
                totalAmountForClaimer[targetAddr] = totalAmountForClaimer[targetAddr].add(amountForEpoch[lastEpoch].mul(lastAmount) / claimersForEpoch[lastEpoch]);
            }

            emit Claimed(msg.sender, targetAddr, amount, claimAmount, block.timestamp);
        }
    }

    // amount availabe for claimant
    function amountForClaimant(address targetAddr) public view onlyEnabled returns (uint256) {
        uint256 epoch = currentEpoch();
        uint256 lastEpoch = lastEpochForClaimer[targetAddr];
        uint256 amount = totalAmountForClaimer[targetAddr];

        if (lastEpoch != epoch && claimersForEpoch[lastEpoch] > 0) {
            amount = amount.add(amountForEpoch[lastEpoch].mul(lastAmountForClaimer[targetAddr]) / claimersForEpoch[lastEpoch]);
        }

        return amount;
    }

    function amountForClaimant() public view returns(uint256) {
        return amountForClaimant(msg.sender);
    }

    // estimated pending amount for claimant
    function estimatedPendingAmountForClaimant(address targetAddr) public view onlyEnabled returns (uint256) {
        uint256 epoch = currentEpoch();
        uint256 lastEpoch = lastEpochForClaimer[targetAddr];
        
        if (epoch <= BIG_EPOCHS * TOTAL_BIG_EPOCHS && lastEpoch == epoch && claimersForEpoch[lastEpoch] > 0) {
            return amountForEpoch[epoch].mul(lastAmountForClaimer[targetAddr]) / claimersForEpoch[epoch];
        }
        else {
            return 0;
        }
    }

    function estimatedPendingAmountForClaimant() public view returns(uint256) {
        return estimatedPendingAmountForClaimant(msg.sender);
    }

    // withdraw
    function withdraw(address targetAddr) public onlyEnabled nonReentrant {
        uint256 amount = amountForClaimant(targetAddr);
        require(amount > 0, "amount is zero");

        if (lastEpochForClaimer[targetAddr] != currentEpoch()) {
            lastEpochForClaimer[targetAddr] = 0;
            lastAmountForClaimer[targetAddr] = 0;
        }

        totalAmountForClaimer[targetAddr] = 0;

        // send amount to targetAddr
        _safeErc20Transfer(TwisterToken, targetAddr, amount);

        emit Withdrawn(msg.sender, targetAddr, amount, block.timestamp);
    }

    function withdraw() public {
        withdraw(msg.sender);
    }

    modifier onlyEnabled {
        require(genesisBlock != 0 && block.number >= genesisBlock, "not enabled");
        _;
    }

    modifier onlyAgent(address addr) {
        require(allowedAgents[addr], "not allowed agent");
        _;
    }

    // find current epoch number
    // (starting from 1 to TOTAL_BIG_EPOCHS * BIG_EPOCHS + 1)
    function currentEpoch() public view onlyEnabled returns (uint256) {
        return Math.min((block.number.sub(genesisBlock) / EPOCH_BLOCKS).add(1), BIG_EPOCHS * TOTAL_BIG_EPOCHS + 1);
    }

    // find current big epoch number
    // (starting from 1 to TOTAL_BIG_EPOCHS + 1)
    function currentBigEpoch() public view onlyEnabled returns (uint256) {
        return (currentEpoch().sub(1) / BIG_EPOCHS).add(1);
    }

    // find current small epoch number
    // (starting from 1 to BIG_EPOCHS)
    function currentSmallEpoch() public view onlyEnabled returns (uint256) {
        return (currentEpoch().sub(1) % BIG_EPOCHS).add(1);
    }

    // find dispense amount for each small epoch
    function baseDispenseAmountForEpoch(uint256 bigEpoch) public view returns (uint256) {
        if (bigEpoch == 0 || bigEpoch >= TOTAL_BIG_EPOCHS + 1) {
            return 0;
        }
        else {
            return (STARTING_DISPENSE_AMOUNT >> bigEpoch.sub(1)) / BIG_EPOCHS;
        }
    }

    // find dispense amount for current small epoch
    function baseDispenseAmountForCurrentEpoch() public view onlyEnabled returns (uint256) {
        return baseDispenseAmountForEpoch(currentBigEpoch());
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
}