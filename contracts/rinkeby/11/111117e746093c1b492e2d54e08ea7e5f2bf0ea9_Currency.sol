/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// File: contracts/InvitersReward.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;


contract InvitersReward {
    
    using SafeMath for uint256;
    
    
    ICommunity community;
    uint256 inviterCommission;
    
    uint256 multiplier;
    
    event RewardAdded(address to, uint256 amount);
    event RewardExceed(address to);
    
    /**
     * @param _community address community
     * @param _inviterCommission commission mul by 1e6
     * 
     */
    function __InvitersReward_init(
        ICommunity _community, 
        uint256 _inviterCommission
    ) 
        
        public 
    {
        require(_inviterCommission < 100e6, "can not be more or equal 100%");
        community = _community;
        inviterCommission = _inviterCommission;
        
        multiplier = 1e6;
    }

    function invitersRewardProceed(
        address recipient,
        uint256 reserveTokenAmount
    )
        internal
        returns(uint256 left)
    {
        left = reserveTokenAmount;
        if (address(community) == address(0) || inviterCommission == uint256(0) ) {
        } else {
            
            address invitedAddress = ICommunity(community).whoInvited(recipient);
            if (invitedAddress != address(0)) {
                
                uint256 surplus = reserveTokenAmount.mul(inviterCommission).div(multiplier);    
                
                if (surplus == 0) {
                    emit RewardExceed(invitedAddress);
                } else {
                    invitersRewardTransfer(invitedAddress, surplus);
                    emit RewardAdded(invitedAddress, surplus);
                }
                
                left = reserveTokenAmount.sub(surplus);
                
            }
        }
        
    }
    
    function invitersRewardTransfer(
        address recipient,
        uint256 amount2send
    ) 
        internal 
        virtual 
    {
        // implemented in child
    }
    
}
    
// File: contracts/interfaces/ICommunity.sol


pragma solidity >=0.6.0 <0.7.0;


interface ICommunity {
    function memberCount(string calldata role) external view returns(uint256);
    function getRoles(address member)external view returns(string[] memory);
    function getMember(string calldata role) external view returns(address[] memory);
    
    function isInvited(address sender, address recipient) external view returns(bool) ;
    function whoInvited(address recipient) external view returns(address);

}
// File: contracts/IPricesContract.sol

pragma solidity >=0.6.0 <0.7.0;


interface IPricesContract {
    function recordByVendor(address vendor, uint256 price) external returns(bool);
    
}
// File: contracts/Claimed.sol

pragma solidity >=0.6.0 <0.7.0;


/**
 * Realization a restriction limits for user transfer
 * 
 */
contract Claimed {
    using SafeMath for uint256;
    
    // user allowance
    struct ClaimStruct {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool gradual;
    }

    mapping (address => ClaimStruct[]) internal _claimed;
    
    /**
     * @param recipient recipient's address
     * @param amount token amount
     * @param endTime timestamp in which limit expire
     * @param gradual if true then limit is gradually decreasing
     */
    function addClaimLimit(address recipient, uint256 amount, uint256 endTime, bool gradual) internal {
        require(now <= endTime, "endTime need to be more than current timestamp");
        
        ClaimStruct memory newClaim = ClaimStruct({
            amount: amount, 
            startTime: now, 
            endTime: endTime, 
            gradual: gradual
        });

        //uint256 claimCount = _claimed[recipient].length;
        _claimed[recipient].push(newClaim);
    }
    
    /**
     * Calculate minimum amount of tokens need to be left at recipient's account
     * @dev method additionally cleaned _claimed if endTime was expired
     * @param recipient recipient's address
     * @return minimum amount of tokens need to be left at recipient's account
     */
    function getAmountLockUp(address recipient) internal returns (uint256 minimum)  {
        
        minimum = 0;
        
        uint256 claimCount = _claimed[recipient].length;
        uint256 tmpIndex;
        uint256 tmpPerSecond;
        for (uint256 i = 0; i < claimCount; i++) {
            
            // loop by expired and delete them from array by exchanging from last element to current
            while (now > _claimed[recipient][i].endTime && claimCount > 0) {
                tmpIndex = _claimed[recipient].length - 1;
                
                if (i != tmpIndex) {
                    _claimed[recipient][i] = _claimed[recipient][tmpIndex];
                }

                _claimed[recipient].pop();
                
                // decrease claimCount
                claimCount--;
                if (i == tmpIndex) {
                    break;
                }
            }
            
            if (claimCount == 0) {
                break;
            }
            
            minimum = minimum.add(_claimed[recipient][i].amount);
            
            // if gradual then minimum decreasing until reached endTime
            if (_claimed[recipient][i].gradual == true) {
                // calculate how much amount descreasing per second
                tmpPerSecond = (_claimed[recipient][i].amount).div(_claimed[recipient][i].endTime.sub(_claimed[recipient][i].startTime));
                // and now sub
                minimum = minimum.sub((now.sub(_claimed[recipient][i].startTime)).mul(tmpPerSecond));
            }
        }
    }
    
    /** Do the same as getAmountLockUp but without gas spent (without cleanup expired claim)
     * @param recipient recipient's address
     */
    function amountLockUp(address recipient) public view returns (uint256 minimum)  {
        minimum = 0;
        uint256 tmpPerSecond;
        uint256 claimCount = _claimed[recipient].length;
        for (uint256 i = 0; i < claimCount; i++) {

            if (now < _claimed[recipient][i].endTime) {
                minimum = minimum.add(_claimed[recipient][i].amount);
                
                // if gradual then minimum decreasing until reached endTime
                if (_claimed[recipient][i].gradual == true) {
                    // calculate how much amount descreasing per second
                    tmpPerSecond = (_claimed[recipient][i].amount).div(_claimed[recipient][i].endTime.sub(_claimed[recipient][i].startTime));
                    // and now sub
                    minimum = minimum.sub((now.sub(_claimed[recipient][i].startTime)).mul(tmpPerSecond));
                }
            }
        }
    }
    
}

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

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
// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.6.0;


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

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.6.0;


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

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

pragma solidity ^0.6.0;


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

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
}

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

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




// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.6.0;






/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;
        _decimals = 18;

    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    uint256[44] private __gap;
}

// File: contracts/CurrencyBase.sol


pragma solidity >=0.6.0 <0.7.0;









contract CurrencyBase is ERC20UpgradeSafe, OwnableUpgradeSafe, Claimed, ReentrancyGuardUpgradeSafe, InvitersReward {
    using SafeMath for uint256;
    using Address for address;
    
    // Fraction part. means 1e18
    uint256 constant internal DECIMALS = 10**18;
    
    uint256 internal _sellExchangeRate;
    uint256 internal _buyExchangeRate;
    
    uint256 public maxGasPrice;
    
    uint256 startTime;
    
    uint256 internal claimMorePerSeconds = 10 * DECIMALS;

    // initial amount that can be claimed by contract without transactions failing
    uint256 internal claimInitialMax = 1000000 * DECIMALS;
    
    // amount that can be claimed one-time by contract without transactions failing
    uint256 internal tokensClaimOneTimeLimit = 1000000 * DECIMALS;
    
    // consider total token2 balance held at start of block when sending, 
    // claim fails if we would have new token1outstanding * exchangeRate > token2balance * (100 - this number) / 100
    uint256 internal claimReserveMinPercent = 20;
    
    // consider total token2 balance held at start of block when sending, 
    // claim fails if token1beingSent * exchangeRate > token2balance * this number / 100
    uint256 internal claimTransactionMaxPercent = 2;
    
    // deficit = token1outstanding * exchangeRate - token2balance . 
    // claim fails if claimDeficitMax exceeds this number.
    uint256 internal claimDeficitMax = 1000000 * DECIMALS;
    
    // claim discount
    uint256 internal claimReserveExchangeRate = 99e4;
    
    // total claimed
    uint256 claimTotal;
    
    // default variable for claim permissions
    uint256 internal claimLockupPeriod = 100; // seconds
    bool internal claimGradual = true;
    
    uint256 private tokensForClaimingCount;
    address[] private tokensForClaiming;
    mapping (address => bool) private tokensForClaimingMap;
    
    IPricesContract pricesAddress;
    
    
    ICommunity private communityAddress;
    string private communityRole;
    
    
    event StatAdded(address indexed recipient, uint256 amount);
    
    modifier onlyPassTransferLimit(uint256 amount) {
        
         require(
            getAmountLockUp(_msgSender()).add(amount) <= balanceOf(_msgSender()), 
            'TransferLimit: There are no allowance tokens to transfer'
        );
        _;
    }


    modifier canReceiveTokens() {
        bool s = false;
        string[] memory roles = ICommunity(communityAddress).getRoles(msg.sender);
        for (uint256 i=0; i< roles.length; i++) {
            
            if (keccak256(abi.encodePacked(communityRole)) == keccak256(abi.encodePacked(roles[i]))) {
                s = true;
            }
        }
        
        require(s == true, "Sender is not in whitelist");
        
        _;
    }
    
    event claimingTokenAdded(address token);
    
    /**
     * @param name Token name
     * @param symbol Token symbol
     * @param pricesContractAddress address of PricesContract
     * @param community address of CommunityContract
     * @param roleName whitelist role name
     */
    function init(
        string memory name, 
        string memory symbol,
        IPricesContract pricesContractAddress,
        ICommunity community,
        uint256 inviterCommission,
        string memory roleName
    ) 
        public 
        initializer 
    {
        
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC20_init(name, symbol);
		__InvitersReward_init(community, inviterCommission);
		
        startTime = now;
        pricesAddress = pricesContractAddress;
        
        communityAddress = community;
        communityRole = roleName;
    
        claimTotal = 0;
        maxGasPrice = 1 * DECIMALS;
        tokensForClaimingCount = 0;
        
        _sellExchangeRate = 99e4; // 99% * 1e6
        _buyExchangeRate = 100e4; // 100% *1e6
        
        claimMorePerSeconds = 10 * DECIMALS;
        claimInitialMax = 1000000 * DECIMALS;
        tokensClaimOneTimeLimit = 1000000 * DECIMALS;
        claimReserveMinPercent = 20;
        claimTransactionMaxPercent = 2;
        claimDeficitMax = 1000000 * DECIMALS;
        claimReserveExchangeRate = 99e4;
        claimLockupPeriod = 100;
        claimGradual = true;
    
        
    }
    
    modifier validGasPrice() {
        require(tx.gasprice <= maxGasPrice, "Transaction gas price cannot exceed maximum gas price.");
        _;
    } 
    
    // 
    /**
     * Recieved ether and transfer token to sender
     */
    receive() external payable virtual validGasPrice {
        _receivedETH(msg.value);
    }
    
    /**
     * Setting maximum Gas Price
     * @param gasPrice maximum Gas Price(in wei) used for transaction
     */
    function setMaxGasPrice(uint256 gasPrice) public onlyOwner {
        maxGasPrice = gasPrice;
    }
    
    function claimingTokenAdd(address tokenForClaiming) public onlyOwner {
        require(tokenForClaiming.isContract(), 'tokenForClaiming must be a contract address');
        if (tokensForClaimingMap[tokenForClaiming]) {
            // already exist
        } else {
            tokensForClaiming.push(tokenForClaiming);
            tokensForClaimingCount = tokensForClaimingCount.add(1);
            tokensForClaimingMap[tokenForClaiming] = true;
            emit claimingTokenAdded(tokenForClaiming);
        }
    }
    
    /**
     * @return list list of tokens added for claiming
     */
    function claimingTokensView() public view returns (address[] memory list) {
        list = tokensForClaiming;
    }
    
    
    function claimingTokensWithdraw() public onlyOwner nonReentrant() {
        
        for (uint256 i = 0; i < tokensForClaimingCount; i++) {
            uint256 amount = IERC20(tokensForClaiming[i]).balanceOf(address(this));
            if (amount > 0) {
                // try to get
                bool success = IERC20(tokensForClaiming[i]).transferFrom(address(this), owner(), amount);
                require(success == true, 'Transfer tokens were failed'); 
            }
        }

    }
    
    /**
     * @dev getting own tokens instead claimed tokens
     */
    function claim() validGasPrice public nonReentrant() {
        
        require(tokensForClaimingCount > 0, 'There are no allowed tokens for claiming');
        
        bool hasAllowedAmount = false;
        
        for (uint256 i = 0; i < tokensForClaimingCount; i++) {
        
            uint256 allowedAmount = IERC20(tokensForClaiming[i]).allowance(_msgSender(), address(this));
            
            if (allowedAmount > 0) {
            
                hasAllowedAmount = true;
                
                // own token with rate 1to1
                uint256 amount = allowedAmount;
                
                claimTotal = claimTotal.add(amount);
                
                if (claimTotal <= claimInitialMax) {
                    //allow claim without check any restrictions;
                } else {
                    require(
                        (claimTotal < claimInitialMax.add(((now).sub(startTime)).mul(claimMorePerSeconds))), 
                        'This many tokens are not available to be claimed yet' 
                    );
                    require(
                        claimTotal.mul(claimReserveExchangeRate).div(1e6) <= _overallBalance2().mul(100-claimReserveMinPercent).div(100), 
                        'Amount exceeds available reserve limit' 
                    );
                    require(
                        amount.mul(claimReserveExchangeRate).div(1e6) <= _overallBalance2().mul(claimTransactionMaxPercent).div(100),
                        'Amount exceeds transaction max percent' 
                    );
                    
                    require(
                        ((claimTotal).mul(claimReserveExchangeRate).div(1e6)).sub(_overallBalance2()) <= claimDeficitMax,
                        'Amount exceeds deficit max'
                    );
            
                }
               
                require(tokensClaimOneTimeLimit >= amount, 'Too many tokens to claim in one transaction');
                
                
                // try to get
                bool success = IERC20(tokensForClaiming[i]).transferFrom(_msgSender(), address(this), allowedAmount);
                require(success == true, 'Transfer tokens were failed'); 
                
                // claim own tokens
                _mint(_msgSender(), amount);
                
                //
                addClaimLimit(_msgSender(), amount, now.add(claimLockupPeriod), claimGradual);
            }
        }
        require(hasAllowedAmount == true, 'Amount exceeds allowed balance');
    }
    
    /**
     * Overrode {ERC20-transfer} method.
     * There are added some features:
     * 1. added validation of restriction limit to transfer
     * 2. if recipient is self contract than we will 
     *      get tokens, burn it and transfer eth to sender (if whitelisted)
     *      In all over cases its simple ERC20 Transfer
     * 3. in any cases we will try to send stat to pricesContract. if true stats was accepted
     * @param recipient recipient
     * @param amount amount
     * @return success
     */
    function transfer(address recipient, uint256 amount) public onlyPassTransferLimit(amount) nonReentrant() virtual override returns (bool) {
      
        _transfer(_msgSender(), recipient, amount);
        
        if (recipient == address(this)) {
            _receivedToken(amount);
            _burn(address(this), amount);
        }
        
        // try to send stats to pricesContract
        bool ret = IPricesContract(pricesAddress).recordByVendor(recipient, amount);
        if (ret == true) {
            emit StatAdded(recipient, amount);
        }
        
        
        return true;
    }
    
    function _overallBalance2() internal virtual returns(uint256) {
        // need to be implement in child
        return 0;
    }
    
    /**
     * @dev private method. getting Tokens and send back eth(token2)
     * Available only to recipient in whitelist
     * @param tokensAmount tokens amount
     */
    function _receivedToken(uint256 tokensAmount) internal canReceiveTokens {
        
        uint256 balanceToken2 = _overallBalance2();
        uint256 amount2send = tokensAmount.mul(sellExchangeRate()).div(1e6); // "sell exchange" interpretation with rate discount
        require ((amount2send <= balanceToken2 && balanceToken2>0), 'Amount exceeds available balance.');
        
        _receivedTokenAfter(_msgSender(), amount2send);
        
    }
    
    function _receivedTokenAfter(address to, uint256 amount2send) internal virtual {
        // need to be implement in child
    }  
    
    
    /**
     * @dev private method. getting ETH and send back minted tokens
     * @param ethAmount ether amount
     */
    function _receivedETH(uint256 ethAmount) internal virtual {
        // need to be implement in child
    }  
    
    function sellExchangeRate() internal virtual returns(uint256) {
        // need to be implement in child
        return uint256(1e6);
    }
    function buyExchangeRate() internal virtual returns(uint256) {
        // need to be implement in child
        return uint256(1e6);
    }  
    function _mintedOwnTokens(uint256 amount) internal {
        
        _mint(_msgSender(), amount);
    } 
    
   function invitersRewardTransfer(
        address recipient,
        uint256 amount2send
    ) 
        internal
        override 
    {
       
        _receivedTokenAfter(recipient,amount2send);
    }
    
}




// File: contracts/Currency.sol


pragma solidity >=0.6.0 <0.7.0;




contract Currency is CurrencyBase {
    using Address for address;
    
    address private token2;
    
    /**
     * @param name Token name
     * @param symbol Token symbol
     * @param pricesContractAddress address of PricesContract
     * @param community address of CommunityContract
     * @param roleName whitelist role name
     */
    function init(
        string memory name, 
        string memory symbol,
        address secondary_token,
        IPricesContract pricesContractAddress,
        ICommunity community,
        uint256 inviterCommission,
        string memory roleName
    ) 
        public 
        initializer 
    {
        super.init( name, symbol, pricesContractAddress, community, inviterCommission, roleName);
        require(secondary_token.isContract(), 'secondary_token must be a contract address');
        token2 = secondary_token;
    }
    
    // 
    /**
     * Recieved ether 
     */
    receive() external payable override validGasPrice {
        require (true == true, "This method is not supported"); 
    }

    /**
     * @dev getting token2 and mint instead own tokens
     * proceeded if user set allowance in secondary_token contract
     * @param isDonate if set true, contract will not send tokens
     */
    function receiveERC20Token2(bool isDonate) validGasPrice public nonReentrant() {
        uint256 _allowedAmount = IERC20(token2).allowance(_msgSender(), address(this));
        
        require(_allowedAmount > 0, 'Amount exceeds allowed balance');
        
        // try to get
        bool success = IERC20(token2).transferFrom(_msgSender(), address(this), _allowedAmount);
        require(success == true, 'Transfer tokens were failed'); 
        if (!isDonate) {
            _receivedToken2(_allowedAmount);
        }
    }
    /**
     * @dev internal overrided method. token2 will be transfer to sender
     * @param amount2send amount of tokens
     */
    function _receivedTokenAfter(address to, uint256 amount2send) internal virtual override {
        bool success = IERC20(token2).transfer(to,amount2send);
        require(success == true, 'Transfer tokens were failed');    
    }
    
    /**
     * @dev overall tokens(token2) balance of this contract
     */
    function _overallBalance2() internal virtual override returns(uint256) {
        return IERC20(token2).balanceOf(address(this));
    }
    
    /**
     * @dev overall tokens(token2) balance of this contract
     */
    function _receivedToken2(uint256 token2Amount) private {
        uint256 token2AmountLeft = invitersRewardProceed(
            _msgSender(),
            token2Amount
        );
        
        
        uint256 nativeTokensAmount = token2AmountLeft.mul(buyExchangeRate()).div(1e6);
        _mintedOwnTokens(nativeTokensAmount);
    }  
    
    /**
     * @dev sell exchange rate
     * @return rate multiplied at 1e6
     */
    function sellExchangeRate() internal virtual override returns(uint256) {
        return _sellExchangeRate;
    }
    
    /**
     * @dev buy exchange rate
     * @return rate multiplied at 1e6
     */
    function buyExchangeRate() internal virtual  override returns(uint256) {
        return _buyExchangeRate;
    }  
    
}