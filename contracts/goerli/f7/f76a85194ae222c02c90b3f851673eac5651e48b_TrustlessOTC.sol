/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: MIT
/**
 *Submitted for verification at Etherscan.io on 2019-06-08
*/

pragma solidity ^0.5.4;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract TrustlessOTC is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => uint256) public balanceTracker;
    mapping(address => uint256) public feeTracker;
    mapping(address => uint[]) public tradeTracker;

    event OfferCreated(uint indexed tradeID);
    event OfferCancelled(uint indexed tradeID);
    event OfferTaken(uint indexed tradeID);

    uint256 public feeBasisPoints;

    constructor (uint256 _feeBasisPoints) public {
      feeBasisPoints = _feeBasisPoints;
    }

    struct TradeOffer {
        address tokenFrom;
        address tokenTo;
        uint256 amountFrom;
        uint256 amountTo;
        address payable creator;
        address optionalTaker;
        bool active;
        bool completed;
        uint tradeID;
    }

    TradeOffer[] public offers;

    function initiateTrade(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountFrom,
        uint256 _amountTo,
        address _optionalTaker
        ) public payable returns (uint newTradeID) {
            if (_tokenFrom == address(0)) {
                require(msg.value == _amountFrom);
            } else {
                require(msg.value == 0);
                IERC20(_tokenFrom).safeTransferFrom(msg.sender, address(this), _amountFrom);
            }
            newTradeID = offers.length;
            offers.length++;
            TradeOffer storage o = offers[newTradeID];
            balanceTracker[_tokenFrom] = balanceTracker[_tokenFrom].add(_amountFrom);
            o.tokenFrom = _tokenFrom;
            o.tokenTo = _tokenTo;
            o.amountFrom = _amountFrom;
            o.amountTo = _amountTo;
            o.creator = msg.sender;
            o.optionalTaker = _optionalTaker;
            o.active = true;
            o.tradeID = newTradeID;
            tradeTracker[msg.sender].push(newTradeID);
            emit OfferCreated(newTradeID);
    }

    function cancelTrade(uint tradeID) public returns (bool) {
        TradeOffer storage o = offers[tradeID];
        require(msg.sender == o.creator);
        require(o.active == true);
        o.active = false;
        if (o.tokenFrom == address(0)) {
          msg.sender.transfer(o.amountFrom);
        } else {
          IERC20(o.tokenFrom).safeTransfer(o.creator, o.amountFrom);
        }
        balanceTracker[o.tokenFrom] -= o.amountFrom;
        emit OfferCancelled(tradeID);
        return true;
    }

    function take(uint tradeID) public payable returns (bool) {
        TradeOffer storage o = offers[tradeID];
        require(o.optionalTaker == msg.sender || o.optionalTaker == address(0));
        require(o.active == true);
        o.active = false;
        balanceTracker[o.tokenFrom] = balanceTracker[o.tokenFrom].sub(o.amountFrom);
        uint256 fee = o.amountFrom.mul(feeBasisPoints).div(10000);
        feeTracker[o.tokenFrom] = feeTracker[o.tokenFrom].add(fee);
        tradeTracker[msg.sender].push(tradeID);

        if (o.tokenFrom == address(0)) {
            msg.sender.transfer(o.amountFrom.sub(fee));
        } else {
          IERC20(o.tokenFrom).safeTransfer(msg.sender, o.amountFrom.sub(fee));
        }

        if (o.tokenTo == address(0)) {
            require(msg.value == o.amountTo);
            o.creator.transfer(msg.value);
        } else {
            require(msg.value == 0);
            IERC20(o.tokenTo).safeTransferFrom(msg.sender, o.creator, o.amountTo);
        }
        o.completed = true;
        emit OfferTaken(tradeID);
        return true;
    }

    function getOfferDetails(uint tradeID) external view returns (
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountFrom,
        uint256 _amountTo,
        address _creator,
        uint256 _fee,
        bool _active,
        bool _completed
    ) {
        TradeOffer storage o = offers[tradeID];
        _tokenFrom = o.tokenFrom;
        _tokenTo = o.tokenTo;
        _amountFrom = o.amountFrom;
        _amountTo = o.amountTo;
        _creator = o.creator;
        _fee = o.amountFrom.mul(feeBasisPoints).div(10000);
        _active = o.active;
        _completed = o.completed;
    }

    function getUserTrades(address user) external view returns (uint[] memory){
      return tradeTracker[user];
    }

    function reclaimToken(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        uint256 excess = balance.sub(balanceTracker[address(_token)]);
        require(excess > 0);
        if (address(_token) == address(0)) {
            msg.sender.transfer(excess);
        } else {
            _token.safeTransfer(owner(), excess);
        }
    }

    function claimFees(IERC20 _token) external onlyOwner {
        uint256 feesToClaim = feeTracker[address(_token)];
        feeTracker[address(_token)] = 0;
        require(feesToClaim > 0);
        if (address(_token) == address(0)) {
            msg.sender.transfer(feesToClaim);
        } else {
            _token.safeTransfer(owner(), feesToClaim);
        }
    }

}