/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

pragma solidity 0.5.14;

contract Constant {
    enum ActionType { DepositAction, WithdrawAction, BorrowAction, RepayAction }
    address public constant ETH_ADDR = 0x000000000000000000000000000000000000000E;
    uint256 public constant INT_UNIT = 10 ** uint256(18);
    uint256 public constant ACCURACY = 10 ** 18;
    // Polygon mainnet blocks per year
    uint256 public constant BLOCKS_PER_YEAR = 2102400;
}

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


// This is for per user
library AccountTokenLib {
    using SafeMath for uint256;
    struct TokenInfo {
        // Deposit info
        uint256 depositPrincipal;   // total deposit principal of ther user
        uint256 depositInterest;    // total deposit interest of the user
        uint256 lastDepositBlock;   // the block number of user's last deposit
        // Borrow info
        uint256 borrowPrincipal;    // total borrow principal of ther user
        uint256 borrowInterest;     // total borrow interest of ther user
        uint256 lastBorrowBlock;    // the block number of user's last borrow
    }

    uint256 constant BASE = 10**18;

    // returns the principal
    function getDepositPrincipal(TokenInfo storage self) public view returns(uint256) {
        return self.depositPrincipal;
    }

    function getBorrowPrincipal(TokenInfo storage self) public view returns(uint256) {
        return self.borrowPrincipal;
    }

    function getDepositBalance(TokenInfo storage self, uint accruedRate) public view returns(uint256) {
        return self.depositPrincipal.add(calculateDepositInterest(self, accruedRate));
    }

    function getBorrowBalance(TokenInfo storage self, uint accruedRate) public view returns(uint256) {
        return self.borrowPrincipal.add(calculateBorrowInterest(self, accruedRate));
    }

    function getLastDepositBlock(TokenInfo storage self) public view returns(uint256) {
        return self.lastDepositBlock;
    }

    function getLastBorrowBlock(TokenInfo storage self) public view returns(uint256) {
        return self.lastBorrowBlock;
    }

    function getDepositInterest(TokenInfo storage self) public view returns(uint256) {
        return self.depositInterest;
    }

    function getBorrowInterest(TokenInfo storage self) public view returns(uint256) {
        return self.borrowInterest;
    }

    function borrow(TokenInfo storage self, uint256 amount, uint256 accruedRate, uint256 _block) public {
        newBorrowCheckpoint(self, accruedRate, _block);
        self.borrowPrincipal = self.borrowPrincipal.add(amount);
    }

    /**
     * Update token info for withdraw. The interest will be withdrawn with higher priority.
     */
    function withdraw(TokenInfo storage self, uint256 amount, uint256 accruedRate, uint256 _block) public {
        newDepositCheckpoint(self, accruedRate, _block);
        if (self.depositInterest >= amount) {
            self.depositInterest = self.depositInterest.sub(amount);
        } else if (self.depositPrincipal.add(self.depositInterest) >= amount) {
            self.depositPrincipal = self.depositPrincipal.sub(amount.sub(self.depositInterest));
            self.depositInterest = 0;
        } else {
            self.depositPrincipal = 0;
            self.depositInterest = 0;
        }
    }

    /**
     * Update token info for deposit
     */
    function deposit(TokenInfo storage self, uint256 amount, uint accruedRate, uint256 _block) public {
        newDepositCheckpoint(self, accruedRate, _block);
        self.depositPrincipal = self.depositPrincipal.add(amount);
    }

    function repay(TokenInfo storage self, uint256 amount, uint accruedRate, uint256 _block) public {
        // updated rate (new index rate), applying the rate from startBlock(checkpoint) to currBlock
        newBorrowCheckpoint(self, accruedRate, _block);
        // user owes money, then he tries to repays
        if (self.borrowInterest > amount) {
            self.borrowInterest = self.borrowInterest.sub(amount);
        } else if (self.borrowPrincipal.add(self.borrowInterest) > amount) {
            self.borrowPrincipal = self.borrowPrincipal.sub(amount.sub(self.borrowInterest));
            self.borrowInterest = 0;
        } else {
            self.borrowPrincipal = 0;
            self.borrowInterest = 0;
        }
    }

    function newDepositCheckpoint(TokenInfo storage self, uint accruedRate, uint256 _block) public {
        self.depositInterest = calculateDepositInterest(self, accruedRate);
        self.lastDepositBlock = _block;
    }

    function newBorrowCheckpoint(TokenInfo storage self, uint accruedRate, uint256 _block) public {
        self.borrowInterest = calculateBorrowInterest(self, accruedRate);
        self.lastBorrowBlock = _block;
    }

    // Calculating interest according to the new rate
    // calculated starting from last deposit checkpoint
    function calculateDepositInterest(TokenInfo storage self, uint accruedRate) public view returns(uint256) {
        return self.depositPrincipal.add(self.depositInterest).mul(accruedRate).sub(self.depositPrincipal.mul(BASE)).div(BASE);
    }

    function calculateBorrowInterest(TokenInfo storage self, uint accruedRate) public view returns(uint256) {
        uint256 _balance = self.borrowPrincipal;
        if(accruedRate == 0 || _balance == 0 || BASE >= accruedRate) {
            return self.borrowInterest;
        } else {
            return _balance.add(self.borrowInterest).mul(accruedRate).sub(_balance.mul(BASE)).div(BASE);
        }
    }
}


/**
 * @notice Bitmap library to set or unset bits on bitmap value
 */
library BitmapLib {

    /**
     * @dev Sets the given bit in the bitmap value
     * @param _bitmap Bitmap value to update the bit in
     * @param _index Index range from 0 to 127
     * @return Returns the updated bitmap value
     */
    function setBit(uint128 _bitmap, uint8 _index) internal pure returns (uint128) {
        // Suppose `_bitmap` is in bit value:
        // 0001 0100 = represents third(_index == 2) and fifth(_index == 4) bit is set

        // Bit not set, hence, set the bit
        if( ! isBitSet(_bitmap, _index)) {
            // Suppose `_index` is = 3 = 4th bit
            // mask = 0000 1000 = Left shift to create mask to find 4rd bit status
            uint128 mask = uint128(1) << _index;

            // Setting the corrospending bit in _bitmap
            // Performing OR (|) operation
            // 0001 0100 (_bitmap)
            // 0000 1000 (mask)
            // -------------------
            // 0001 1100 (result)
            return _bitmap | mask;
        }

        // Bit already set, just return without any change
        return _bitmap;
    }

    /**
     * @dev Unsets the bit in given bitmap
     * @param _bitmap Bitmap value to update the bit in
     * @param _index Index range from 0 to 127
     * @return Returns the updated bitmap value
     */
    function unsetBit(uint128 _bitmap, uint8 _index) internal pure returns (uint128) {
        // Suppose `_bitmap` is in bit value:
        // 0001 0100 = represents third(_index == 2) and fifth(_index == 4) bit is set

        // Bit is set, hence, unset the bit
        if(isBitSet(_bitmap, _index)) {
            // Suppose `_index` is = 2 = 3th bit
            // mask = 0000 0100 = Left shift to create mask to find 3rd bit status
            uint128 mask = uint128(1) << _index;

            // Performing Bitwise NOT(~) operation
            // 1111 1011 (mask)
            mask = ~mask;

            // Unsetting the corrospending bit in _bitmap
            // Performing AND (&) operation
            // 0001 0100 (_bitmap)
            // 1111 1011 (mask)
            // -------------------
            // 0001 0000 (result)
            return _bitmap & mask;
        }

        // Bit not set, just return without any change
        return _bitmap;
    }

    /**
     * @dev Returns true if the corrosponding bit set in the bitmap
     * @param _bitmap Bitmap value to check
     * @param _index Index to check. Index range from 0 to 127
     * @return Returns true if bit is set, false otherwise
     */
    function isBitSet(uint128 _bitmap, uint8 _index) internal pure returns (bool) {
        require(_index < 128, "Index out of range for bit operation");
        // Suppose `_bitmap` is in bit value:
        // 0001 0100 = represents third(_index == 2) and fifth(_index == 4) bit is set

        // Suppose `_index` is = 2 = 3th bit
        // 0000 0100 = Left shift to create mask to find 3rd bit status
        uint128 mask = uint128(1) << _index;

        // Example: When bit is set:
        // Performing AND (&) operation
        // 0001 0100 (_bitmap)
        // 0000 0100 (mask)
        // -------------------------
        // 0000 0100 (bitSet > 0)

        // Example: When bit is not set:
        // Performing AND (&) operation
        // 0001 0100 (_bitmap)
        // 0000 1000 (mask)
        // -------------------------
        // 0000 0000 (bitSet == 0)

        uint128 bitSet = _bitmap & mask;
        // Bit is set when greater than zero, else not set
        return bitSet > 0;
    }
}
interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Utils{

    function _isETH(address globalConfig, address _token) public view returns (bool) {
        return GlobalConfig(globalConfig).constants().ETH_ADDR() == _token;
    }

    function getDivisor(address globalConfig, address _token) public view returns (uint256) {
        if(_isETH(globalConfig, _token)) return GlobalConfig(globalConfig).constants().INT_UNIT();
        return 10 ** uint256(GlobalConfig(globalConfig).tokenInfoRegistry().getTokenDecimals(_token));
    }

}
library SavingLib {
    using SafeERC20 for IERC20;

    /**
     * Receive the amount of token from msg.sender
     * @param _amount amount of token
     * @param _token token address
     */
    function receive(GlobalConfig globalConfig, uint256 _amount, address _token) public {
        if (Utils._isETH(address(globalConfig), _token)) {
            require(msg.value == _amount, "The amount is not sent from address.");
        } else {
            //When only tokens received, msg.value must be 0
            require(msg.value == 0, "msg.value must be 0 when receiving tokens");
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    /**
     * Send the amount of token to an address
     * @param _amount amount of token
     * @param _token token address
     */
    function send(GlobalConfig globalConfig, uint256 _amount, address _token) public {
        if (Utils._isETH(address(globalConfig), _token)) {
            msg.sender.transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
    }

}
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
 * @dev Token Info Registry to manage Token information
 *      The Owner of the contract allowed to update the information
 */
contract TokenRegistry is Ownable, Constant {

    using SafeMath for uint256;

    /**
     * @dev TokenInfo struct stores Token Information, this includes:
     *      ERC20 Token address, Compound Token address, ChainLink Aggregator address etc.
     * @notice This struct will consume 5 storage locations
     */
    struct TokenInfo {
        // Token index, can store upto 255
        uint8 index;
        // ERC20 Token decimal
        uint8 decimals;
        // If token is enabled / disabled
        bool enabled;
        // Is ERC20 token charge transfer fee?
        bool isTransferFeeEnabled;
        // Is Token supported on Compound
        bool isSupportedOnCompound;
        // cToken address on Compound
        address cToken;
        // Chain Link Aggregator address for TOKEN/ETH pair
        address chainLinkOracle;
        // Borrow LTV, by default 60%
        uint256 borrowLTV;
    }

    event TokenAdded(address indexed token);
    event TokenUpdated(address indexed token);

    uint256 public constant MAX_TOKENS = 128;
    uint256 public constant SCALE = 100;

    // TokenAddress to TokenInfo mapping
    mapping (address => TokenInfo) public tokenInfo;

    // TokenAddress array
    address[] public tokens;
    GlobalConfig public globalConfig;

    /**
     */
    modifier whenTokenExists(address _token) {
        require(isTokenExist(_token), "Token not exists");
        _;
    }

    /**
     *  initializes the symbols structure
     */
    function initialize(GlobalConfig _globalConfig) public onlyOwner{
        globalConfig = _globalConfig;
    }

    /**
     * @dev Add a new token to registry
     * @param _token ERC20 Token address
     * @param _decimals Token's decimals
     * @param _isTransferFeeEnabled Is token changes transfer fee
     * @param _isSupportedOnCompound Is token supported on Compound
     * @param _cToken cToken contract address
     * @param _chainLinkOracle Chain Link Aggregator address to get TOKEN/ETH rate
     */
    function addToken(
        address _token,
        uint8 _decimals,
        bool _isTransferFeeEnabled,
        bool _isSupportedOnCompound,
        address _cToken,
        address _chainLinkOracle
    )
        public
        onlyOwner
    {
        require(_token != address(0), "Token address is zero");
        require(!isTokenExist(_token), "Token already exist");
        require(_chainLinkOracle != address(0), "ChainLinkAggregator address is zero");
        require(tokens.length < MAX_TOKENS, "Max token limit reached");

        TokenInfo storage storageTokenInfo = tokenInfo[_token];
        storageTokenInfo.index = uint8(tokens.length);
        storageTokenInfo.decimals = _decimals;
        storageTokenInfo.enabled = true;
        storageTokenInfo.isTransferFeeEnabled = _isTransferFeeEnabled;
        storageTokenInfo.isSupportedOnCompound = _isSupportedOnCompound;
        storageTokenInfo.cToken = _cToken;
        storageTokenInfo.chainLinkOracle = _chainLinkOracle;
        // Default values
        storageTokenInfo.borrowLTV = 60; //6e7; // 60%

        tokens.push(_token);
        emit TokenAdded(_token);
    }

    function updateBorrowLTV(
        address _token,
        uint256 _borrowLTV
    )
        external
        onlyOwner
        whenTokenExists(_token)
    {
        if (tokenInfo[_token].borrowLTV == _borrowLTV)
            return;

        // require(_borrowLTV != 0, "Borrow LTV is zero");
        require(_borrowLTV < SCALE, "Borrow LTV must be less than Scale");
        // require(liquidationThreshold > _borrowLTV, "Liquidation threshold must be greater than Borrow LTV");

        tokenInfo[_token].borrowLTV = _borrowLTV;
        emit TokenUpdated(_token);
    }

    /**
     */
    function updateTokenTransferFeeFlag(
        address _token,
        bool _isTransfeFeeEnabled
    )
        external
        onlyOwner
        whenTokenExists(_token)
    {
        if (tokenInfo[_token].isTransferFeeEnabled == _isTransfeFeeEnabled)
            return;

        tokenInfo[_token].isTransferFeeEnabled = _isTransfeFeeEnabled;
        emit TokenUpdated(_token);
    }

    /**
     */
    function updateTokenSupportedOnCompoundFlag(
        address _token,
        bool _isSupportedOnCompound
    )
        external
        onlyOwner
        whenTokenExists(_token)
    {
        if (tokenInfo[_token].isSupportedOnCompound == _isSupportedOnCompound)
            return;

        tokenInfo[_token].isSupportedOnCompound = _isSupportedOnCompound;
        emit TokenUpdated(_token);
    }

    /**
     */
    function updateCToken(
        address _token,
        address _cToken
    )
        external
        onlyOwner
        whenTokenExists(_token)
    {
        if (tokenInfo[_token].cToken == _cToken)
            return;

        tokenInfo[_token].cToken = _cToken;
        emit TokenUpdated(_token);
    }

    /**
     */
    function updateChainLinkAggregator(
        address _token,
        address _chainLinkOracle
    )
        external
        onlyOwner
        whenTokenExists(_token)
    {
        if (tokenInfo[_token].chainLinkOracle == _chainLinkOracle)
            return;

        tokenInfo[_token].chainLinkOracle = _chainLinkOracle;
        emit TokenUpdated(_token);
    }


    function enableToken(address _token) external onlyOwner whenTokenExists(_token) {
        require(!tokenInfo[_token].enabled, "Token already enabled");

        tokenInfo[_token].enabled = true;

        emit TokenUpdated(_token);
    }

    function disableToken(address _token) external onlyOwner whenTokenExists(_token) {
        require(tokenInfo[_token].enabled, "Token already disabled");

        tokenInfo[_token].enabled = false;

        emit TokenUpdated(_token);
    }

    // =====================
    //      GETTERS
    // =====================

    /**
     * @dev Is token address is registered
     * @param _token token address
     * @return Returns `true` when token registered, otherwise `false`
     */
    function isTokenExist(address _token) public view returns (bool isExist) {
        isExist = tokenInfo[_token].chainLinkOracle != address(0);
    }

    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    function getTokenIndex(address _token) external view returns (uint8) {
        return tokenInfo[_token].index;
    }

    function isTokenEnabled(address _token) external view returns (bool) {
        return tokenInfo[_token].enabled;
    }

    /**
     */
    function getCTokens() external view returns (address[] memory cTokens) {
        uint256 len = tokens.length;
        cTokens = new address[](len);
        for(uint256 i = 0; i < len; i++) {
            cTokens[i] = tokenInfo[tokens[i]].cToken;
        }
    }

    function getTokenDecimals(address _token) public view returns (uint8) {
        return tokenInfo[_token].decimals;
    }

    function isTransferFeeEnabled(address _token) external view returns (bool) {
        return tokenInfo[_token].isTransferFeeEnabled;
    }

    function isSupportedOnCompound(address _token) external view returns (bool) {
        return tokenInfo[_token].isSupportedOnCompound;
    }

    /**
     */
    function getCToken(address _token) external view returns (address) {
        return tokenInfo[_token].cToken;
    }

    function getChainLinkAggregator(address _token) external view returns (address) {
        return tokenInfo[_token].chainLinkOracle;
    }

    function getBorrowLTV(address _token) external view returns (uint256) {
        return tokenInfo[_token].borrowLTV;
    }

    function getCoinLength() public view returns (uint256 length) {
        return tokens.length;
    }

    function addressFromIndex(uint index) public view returns(address) {
        require(index < tokens.length, "coinIndex must be smaller than the coins length.");
        return tokens[index];
    }

    function priceFromIndex(uint index) public view returns(uint256) {
        require(index < tokens.length, "coinIndex must be smaller than the coins length.");
        address tokenAddress = tokens[index];
        // Temp fix
        if(Utils._isETH(address(globalConfig), tokenAddress)) {
            return 1e18;
        }
        return uint256(AggregatorInterface(tokenInfo[tokenAddress].chainLinkOracle).latestAnswer());
    }

    function priceFromAddress(address tokenAddress) public view returns(uint256) {
        if(Utils._isETH(address(globalConfig), tokenAddress)) {
            return 1e18;
        }
        return uint256(AggregatorInterface(tokenInfo[tokenAddress].chainLinkOracle).latestAnswer());
    }

     function _priceFromAddress(address _token) internal view returns (uint) {
        return 
            _token != ETH_ADDR 
            ? uint256(AggregatorInterface(tokenInfo[_token].chainLinkOracle).latestAnswer())
            : INT_UNIT;
    }

    function _tokenDivisor(address _token) internal view returns (uint) {
        return _token != ETH_ADDR ? 10**uint256(tokenInfo[_token].decimals) : INT_UNIT;
    }

    function getTokenInfoFromIndex(uint index)
        external
        view
        whenTokenExists(addressFromIndex(index))
        returns (
            address,
            uint256,
            uint256,
            uint256
        )
    {
        address token = tokens[index];
        return (
            token,
            _tokenDivisor(token),
            _priceFromAddress(token),
            tokenInfo[token].borrowLTV
        );
    }

    function getTokenInfoFromAddress(address _token)
        external
        view
        whenTokenExists(_token)
        returns (
            uint8,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            tokenInfo[_token].index,
            _tokenDivisor(_token),
            _priceFromAddress(_token),
            tokenInfo[_token].borrowLTV
        );
    }

    // function _isETH(address _token) public view returns (bool) {
    //     return globalConfig.constants().ETH_ADDR() == _token;
    // }

    // function getDivisor(address _token) public view returns (uint256) {
    //     if(_isETH(_token)) return INT_UNIT;
    //     return 10 ** uint256(getTokenDecimals(_token));
    // }

    mapping(address => uint) public depositeMiningSpeeds;
    mapping(address => uint) public borrowMiningSpeeds;

    function updateMiningSpeed(address _token, uint _depositeMiningSpeed, uint _borrowMiningSpeed) public onlyOwner{
        if(_depositeMiningSpeed != depositeMiningSpeeds[_token]) {
            depositeMiningSpeeds[_token] = _depositeMiningSpeed;
        }
        
        if(_borrowMiningSpeed != borrowMiningSpeeds[_token]) {
            borrowMiningSpeeds[_token] = _borrowMiningSpeed;
        }

        emit TokenUpdated(_token);
    }
}

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

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract InitializablePausable {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);
    
    address private globalConfig;
    bool private _paused;

    function _initialize(address _globalConfig) internal {
        globalConfig = _globalConfig;
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(GlobalConfig(globalConfig).owner());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(GlobalConfig(globalConfig).owner());
    }

    modifier onlyPauser() {
        require(msg.sender == GlobalConfig(globalConfig).owner(), "PauserRole: caller does not have the Pauser role");
        _;
    }
}


/**
 * @notice Code copied from OpenZeppelin, to make it an upgradable contract
 */
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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract InitializableReentrancyGuard {
    bool private _notEntered;

    function _initialize() internal {
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
}


contract SavingAccount is Initializable, InitializableReentrancyGuard, Constant, InitializablePausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    GlobalConfig public globalConfig;

    address public constant FIN_ADDR = 0x576c990A8a3E7217122e9973b2230A3be9678E94;
    address public constant COMP_ADDR = address(0);

    event Transfer(address indexed token, address from, address to, uint256 amount);
    event Borrow(address indexed token, address from, uint256 amount);
    event Repay(address indexed token, address from, uint256 amount);
    event Deposit(address indexed token, address from, uint256 amount);
    event Withdraw(address indexed token, address from, uint256 amount);
    event WithdrawAll(address indexed token, address from, uint256 amount);
    event Liquidate(address liquidator, address borrower, address borrowedToken, uint256 repayAmount, address collateralToken, uint256 payAmount);
    event Claim(address from, uint256 amount);
    event WithdrawCOMP(address beneficiary, uint256 amount);

    modifier onlySupportedToken(address _token) {
        if(_token != ETH_ADDR) {
            require(globalConfig.tokenInfoRegistry().isTokenExist(_token), "Unsupported token");
        }
        _;
    }

    modifier onlyEnabledToken(address _token) {
        require(globalConfig.tokenInfoRegistry().isTokenEnabled(_token), "The token is not enabled");
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == address(globalConfig.bank()),
            "Only authorized to call from DeFiner internal contracts.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == GlobalConfig(globalConfig).owner(), "Only owner");
        _;
    }

    /**
     * Initialize function to be called by the Deployer for the first time
     * @param _tokenAddresses list of token addresses
     * @param _cTokenAddresses list of corresponding cToken addresses
     * @param _globalConfig global configuration contract
     */
    function initialize(
        address[] memory _tokenAddresses,
        address[] memory _cTokenAddresses,
        GlobalConfig _globalConfig
    )
        public
        initializer
    {
        // Initialize InitializableReentrancyGuard
        super._initialize();
        super._initialize(address(_globalConfig));

        globalConfig = _globalConfig;

        require(_tokenAddresses.length == _cTokenAddresses.length, "Token and cToken length don't match.");
        uint tokenNum = _tokenAddresses.length;
        for(uint i = 0;i < tokenNum;i++) {
            if(_cTokenAddresses[i] != address(0x0) && _tokenAddresses[i] != ETH_ADDR) {
                approveAll(_tokenAddresses[i]);
            }
        }
    }

    /**
     * Approve transfer of all available tokens
     * @param _token token address
     */
    function approveAll(address _token) public {
        address cToken = globalConfig.tokenInfoRegistry().getCToken(_token);
        require(cToken != address(0x0), "cToken address is zero");
        IERC20(_token).safeApprove(cToken, 0);
        IERC20(_token).safeApprove(cToken, uint256(-1));
    }

    /**
     * Get current block number
     * @return the current block number
     */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    /**
     * Transfer the token between users inside DeFiner
     * @param _to the address that the token be transfered to
     * @param _token token address
     * @param _amount amout of tokens transfer
     */
    function transfer(address _to, address _token, uint _amount) external onlySupportedToken(_token) onlyEnabledToken(_token) whenNotPaused nonReentrant {

        globalConfig.bank().newRateIndexCheckpoint(_token);
        uint256 amount = globalConfig.accounts().withdraw(msg.sender, _token, _amount);
        globalConfig.accounts().deposit(_to, _token, amount);

        emit Transfer(_token, msg.sender, _to, amount);
    }

    /**
     * Borrow the amount of token from the saving pool.
     * @param _token token address
     * @param _amount amout of tokens to borrow
     */
    function borrow(address _token, uint256 _amount) external onlySupportedToken(_token) onlyEnabledToken(_token) whenNotPaused nonReentrant {

        require(_amount != 0, "Borrow zero amount of token is not allowed.");

        globalConfig.bank().borrow(msg.sender, _token, _amount);

        // Transfer the token on Ethereum
        SavingLib.send(globalConfig, _amount, _token);

        emit Borrow(_token, msg.sender, _amount);
    }

    /**
     * Repay the amount of token back to the saving pool.
     * @param _token token address
     * @param _amount amout of tokens to borrow
     * @dev If the repay amount is larger than the borrowed balance, the extra will be returned.
     */
    function repay(address _token, uint256 _amount) public payable onlySupportedToken(_token) nonReentrant {
        require(_amount != 0, "Amount is zero");
        SavingLib.receive(globalConfig, _amount, _token);

        // Add a new checkpoint on the index curve.
        uint256 amount = globalConfig.bank().repay(msg.sender, _token, _amount);

        // Send the remain money back
        if(amount < _amount) {
            SavingLib.send(globalConfig, _amount.sub(amount), _token);
        }

        emit Repay(_token, msg.sender, amount);
    }

    /**
     * Deposit the amount of token to the saving pool.
     * @param _token the address of the deposited token
     * @param _amount the mount of the deposited token
     */
    function deposit(address _token, uint256 _amount) public payable onlySupportedToken(_token) onlyEnabledToken(_token) nonReentrant {
        require(_amount != 0, "Amount is zero");
        SavingLib.receive(globalConfig, _amount, _token);
        globalConfig.bank().deposit(msg.sender, _token, _amount);

        emit Deposit(_token, msg.sender, _amount);
    }

    /**
     * Withdraw a token from an address
     * @param _token token address
     * @param _amount amount to be withdrawn
     */
    function withdraw(address _token, uint256 _amount) external onlySupportedToken(_token) whenNotPaused nonReentrant {
        require(_amount != 0, "Amount is zero");
        uint256 amount = globalConfig.bank().withdraw(msg.sender, _token, _amount);
        SavingLib.send(globalConfig, amount, _token);

        emit Withdraw(_token, msg.sender, amount);
    }

    /**
     * Withdraw all tokens from the saving pool.
     * @param _token the address of the withdrawn token
     */
    function withdrawAll(address _token) external onlySupportedToken(_token) whenNotPaused nonReentrant {

        // Sanity check
        require(globalConfig.accounts().getDepositPrincipal(msg.sender, _token) > 0, "Token depositPrincipal must be greater than 0");

        // Add a new checkpoint on the index curve.
        globalConfig.bank().newRateIndexCheckpoint(_token);

        // Get the total amount of token for the account
        uint amount = globalConfig.accounts().getDepositBalanceCurrent(_token, msg.sender);

        uint256 actualAmount = globalConfig.bank().withdraw(msg.sender, _token, amount);
        if(actualAmount != 0) {
            SavingLib.send(globalConfig, actualAmount, _token);
        }
        emit WithdrawAll(_token, msg.sender, actualAmount);
    }

    function liquidate(address _borrower, address _borrowedToken, address _collateralToken) public onlySupportedToken(_borrowedToken) onlySupportedToken(_collateralToken) whenNotPaused nonReentrant {
        (uint256 repayAmount, uint256 payAmount) = globalConfig.accounts().liquidate(msg.sender, _borrower, _borrowedToken, _collateralToken);

        emit Liquidate(msg.sender, _borrower, _borrowedToken, repayAmount, _collateralToken, payAmount);
    }

    /**
     * Withdraw token from Compound
     * @param _token token address
     * @param _amount amount of token
     */
    function fromCompound(address _token, uint _amount) external onlyAuthorized {
        require(ICToken(globalConfig.tokenInfoRegistry().getCToken(_token)).redeemUnderlying(_amount) == 0, "redeemUnderlying failed");
    }

    function toCompound(address _token, uint _amount) external onlyAuthorized {
        address cToken = globalConfig.tokenInfoRegistry().getCToken(_token);
        if (Utils._isETH(address(globalConfig), _token)) {
            ICETH(cToken).mint.value(_amount)();
        } else {
            // uint256 success = ICToken(cToken).mint(_amount);
            require(ICToken(cToken).mint(_amount) == 0, "mint failed");
        }
    }

    function() external payable{}

    /**
     * An account claim all mined FIN token
     */
    function claim() public nonReentrant returns (uint256) {
        uint256 finAmount = globalConfig.accounts().claim(msg.sender);
        IERC20(FIN_ADDR).safeTransfer(msg.sender, finAmount);
        emit Claim(msg.sender, finAmount);
        return finAmount;
    }

    function claimForToken(address _token) public nonReentrant returns (uint256) {
        uint256 finAmount = globalConfig.accounts().claimForToken(msg.sender, _token);
        if(finAmount > 0) IERC20(FIN_ADDR).safeTransfer(msg.sender, finAmount);
        emit Claim(msg.sender, finAmount);
        return finAmount;
    }

    /**
     * Withdraw COMP token to beneficiary
     */
    /*
    function withdrawCOMP(address _beneficiary) external onlyOwner {
        uint256 compBalance = IERC20(COMP_ADDR).balanceOf(address(this));
        IERC20(COMP_ADDR).safeTransfer(_beneficiary, compBalance);

        emit WithdrawCOMP(_beneficiary, compBalance);
    }
    */

    function version() public pure returns(string memory) {
        return "v1.2.0";
    }
}


interface IGlobalConfig {
    function savingAccount() external view returns (address);
    function tokenInfoRegistry() external view returns (TokenRegistry);
    function bank() external view returns (Bank);
    function deFinerCommunityFund() external view returns (address);
    function deFinerRate() external view returns (uint256);
    function liquidationThreshold() external view returns (uint256);
    function liquidationDiscountRatio() external view returns (uint256);
}

contract Accounts is Constant, Initializable{
    using AccountTokenLib for AccountTokenLib.TokenInfo;
    using BitmapLib for uint128;
    using SafeMath for uint256;
    using Math for uint256;

    mapping(address => Account) public accounts;
    IGlobalConfig globalConfig;
    mapping(address => uint256) public FINAmount;

    modifier onlyAuthorized() {
        _isAuthorized();
        _;
    }

    struct Account {
        // Note, it's best practice to use functions minusAmount, addAmount, totalAmount
        // to operate tokenInfos instead of changing it directly.
        mapping(address => AccountTokenLib.TokenInfo) tokenInfos;
        uint128 depositBitmap;
        uint128 borrowBitmap;
        uint128 collateralBitmap;
        bool isCollInit;
    }

    event CollateralFlagChanged(address indexed _account, uint8 _index, bool _enabled);

    function _isAuthorized() internal view {
        require(
            msg.sender == address(globalConfig.savingAccount()) || msg.sender == address(globalConfig.bank()),
            "not authorized"
        );
    }

    /**
     * Initialize the Accounts
     * @param _globalConfig the global configuration contract
     */
    function initialize(
        IGlobalConfig _globalConfig
    ) public initializer {
        globalConfig = _globalConfig;
    }

    /**
     * @dev Initialize the Collateral flag Bitmap for given account
     * @notice This function is required for the contract upgrade, as previous users didn't
     *         have this collateral feature. So need to init the collateralBitmap for each user.
     * @param _account User account address
    */
    function initCollateralFlag(address _account) public {
        Account storage account = accounts[_account];

        // For all users by default `isCollInit` will be `false`
        if(account.isCollInit == false) {
            // Two conditions:
            // 1) An account has some position previous to this upgrade
            //    THEN: copy `depositBitmap` to `collateralBitmap`
            // 2) A new account is setup after this upgrade
            //    THEN: `depositBitmap` will be zero for that user, so don't copy

            // all deposited tokens be treated as collateral
            if(account.depositBitmap > 0) account.collateralBitmap = account.depositBitmap;
            account.isCollInit = true;
        }

        // when isCollInit == true, function will just return after if condition check
    }

    /**
     * @dev Enable/Disable collateral for a given token
     * @param _tokenIndex Index of the token
     * @param _enable `true` to enable the collateral, `false` to disable
     */
    function setCollateral(uint8 _tokenIndex, bool _enable) public {
        address accountAddr = msg.sender;
        initCollateralFlag(accountAddr);
        Account storage account = accounts[accountAddr];

        if(_enable) {
            account.collateralBitmap = account.collateralBitmap.setBit(_tokenIndex);
            // when set new collateral, no need to evaluate borrow power
        } else {
            account.collateralBitmap = account.collateralBitmap.unsetBit(_tokenIndex);
            // when unset collateral, evaluate borrow power, only when user borrowed already
            if(account.borrowBitmap > 0) {
                require(getBorrowETH(accountAddr) <= getBorrowPower(accountAddr), "Insufficient collateral");
            }
        }

        emit CollateralFlagChanged(msg.sender, _tokenIndex, _enable);
    }

    function setCollateral(uint8[] calldata _tokenIndexArr, bool[] calldata _enableArr) external {
        require(_tokenIndexArr.length == _enableArr.length, "array length does not match");
        for(uint i = 0; i < _tokenIndexArr.length; i++) {
            setCollateral(_tokenIndexArr[i], _enableArr[i]);
        }
    }

    function getCollateralStatus(address _account)
        external
        view
        returns (address[] memory tokens, bool[] memory status)
    {
        Account memory account = accounts[_account];
        TokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        tokens = tokenRegistry.getTokens();
        uint256 tokensCount = tokens.length;
        status = new bool[](tokensCount);
        uint128 collBitmap = account.collateralBitmap;
        for(uint i = 0; i < tokensCount; i++) {
            // Example: 0001 << 1 => 0010 (mask for 2nd position)
            uint128 mask = uint128(1) << uint128(i);
            bool isEnabled = (collBitmap & mask) > 0;
            if(isEnabled) status[i] = true;
        }
    }

    /**
     * Check if the user has deposit for any tokens
     * @param _account address of the user
     * @return true if the user has positive deposit balance
     */
    function isUserHasAnyDeposits(address _account) public view returns (bool) {
        Account storage account = accounts[_account];
        return account.depositBitmap > 0;
    }

    /**
     * Check if the user has deposit for a token
     * @param _account address of the user
     * @param _index index of the token
     * @return true if the user has positive deposit balance for the token
     */
    function isUserHasDeposits(address _account, uint8 _index) public view returns (bool) {
        Account storage account = accounts[_account];
        return account.depositBitmap.isBitSet(_index);
    }

    /**
     * Check if the user has borrowed a token
     * @param _account address of the user
     * @param _index index of the token
     * @return true if the user has borrowed the token
     */
    function isUserHasBorrows(address _account, uint8 _index) public view returns (bool) {
        Account storage account = accounts[_account];
        return account.borrowBitmap.isBitSet(_index);
    }

    /**
     * Check if the user has collateral flag set
     * @param _account address of the user
     * @param _index index of the token
     * @return true if the user has collateral flag set for the given index
     */
    function isUserHasCollateral(address _account, uint8 _index) public view returns(bool) {
        Account storage account = accounts[_account];
        return account.collateralBitmap.isBitSet(_index);
    }

    /**
     * Set the deposit bitmap for a token.
     * @param _account address of the user
     * @param _index index of the token
     */
    function setInDepositBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.depositBitmap = account.depositBitmap.setBit(_index);
    }

    /**
     * Unset the deposit bitmap for a token
     * @param _account address of the user
     * @param _index index of the token
     */
    function unsetFromDepositBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.depositBitmap = account.depositBitmap.unsetBit(_index);
    }

    /**
     * Set the borrow bitmap for a token.
     * @param _account address of the user
     * @param _index index of the token
     */
    function setInBorrowBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.borrowBitmap = account.borrowBitmap.setBit(_index);
    }

    /**
     * Unset the borrow bitmap for a token
     * @param _account address of the user
     * @param _index index of the token
     */
    function unsetFromBorrowBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.borrowBitmap = account.borrowBitmap.unsetBit(_index);
    }

    function getDepositPrincipal(address _accountAddr, address _token) public view returns(uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getDepositPrincipal();
    }

    function getBorrowPrincipal(address _accountAddr, address _token) public view returns(uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getBorrowPrincipal();
    }

    function getLastDepositBlock(address _accountAddr, address _token) public view returns(uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getLastDepositBlock();
    }

    function getLastBorrowBlock(address _accountAddr, address _token) public view returns(uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getLastBorrowBlock();
    }

    /**
     * Get deposit interest of an account for a specific token
     * @param _account account address
     * @param _token token address
     * @dev The deposit interest may not have been updated in AccountTokenLib, so we need to explicited calcuate it.
     */
    function getDepositInterest(address _account, address _token) public view returns(uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_account].tokenInfos[_token];
        // If the account has never deposited the token, return 0.
        uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
        if (lastDepositBlock == 0)
            return 0;
        else {
            // As the last deposit block exists, the block is also a check point on index curve.
            uint256 accruedRate = globalConfig.bank().getDepositAccruedRate(_token, lastDepositBlock);
            return tokenInfo.calculateDepositInterest(accruedRate);
        }
    }

    function getBorrowInterest(address _accountAddr, address _token) public view returns(uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        // If the account has never borrowed the token, return 0
        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
        if (lastBorrowBlock == 0)
            return 0;
        else {
            // As the last borrow block exists, the block is also a check point on index curve.
            uint256 accruedRate = globalConfig.bank().getBorrowAccruedRate(_token, lastBorrowBlock);
            return tokenInfo.calculateBorrowInterest(accruedRate);
        }
    }

    function borrow(address _accountAddr, address _token, uint256 _amount) external onlyAuthorized {
        initCollateralFlag(_accountAddr);
        require(_amount != 0, "borrow amount is 0");
        require(isUserHasAnyDeposits(_accountAddr), "no user deposits");
        (uint8 tokenIndex, uint256 tokenDivisor, uint256 tokenPrice,) = globalConfig.tokenInfoRegistry().getTokenInfoFromAddress(_token);
        require(
            getBorrowETH(_accountAddr).add(_amount.mul(tokenPrice).div(tokenDivisor)) <=
            getBorrowPower(_accountAddr), "Insufficient collateral when borrow"
        );

        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        uint256 blockNumber = getBlockNumber();
        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();

        if(lastBorrowBlock == 0)
            tokenInfo.borrow(_amount, INT_UNIT, blockNumber);
        else {
            calculateBorrowFIN(lastBorrowBlock, _token, _accountAddr, blockNumber);
            uint256 accruedRate = globalConfig.bank().getBorrowAccruedRate(_token, lastBorrowBlock);
            // Update the token principla and interest
            tokenInfo.borrow(_amount, accruedRate, blockNumber);
        }

        // Since we have checked that borrow amount is larget than zero. We can set the borrow
        // map directly without checking the borrow balance.
        setInBorrowBitmap(_accountAddr, tokenIndex);
    }

    /**
     * Update token info for withdraw. The interest will be withdrawn with higher priority.
     */
    function withdraw(address _accountAddr, address _token, uint256 _amount) public onlyAuthorized returns (uint256) {
        initCollateralFlag(_accountAddr);
        (, uint256 tokenDivisor, uint256 tokenPrice, uint256 borrowLTV) = globalConfig.tokenInfoRegistry().getTokenInfoFromAddress(_token);

        // if user borrowed before then only check for under liquidation
        Account memory account = accounts[_accountAddr];
        if(account.borrowBitmap > 0) {
            uint256 withdrawETH = _amount.mul(tokenPrice).mul(borrowLTV).div(tokenDivisor).div(100);
            require(getBorrowETH(_accountAddr) <= getBorrowPower(_accountAddr).sub(withdrawETH), "Insufficient collateral");
        }

        (uint256 amountAfterCommission, ) = _withdraw(_accountAddr, _token, _amount, true);

        return amountAfterCommission;
    }

    /**
     * This function is called in liquidation function. There two difference between this function and
     * the Account.withdraw function: 1) It doesn't check the user's borrow power, because the user
     * is already borrowed more than it's borrowing power. 2) It doesn't take commissions.
     */
    function withdraw_liquidate(address _accountAddr, address _token, uint256 _amount) internal {
        _withdraw(_accountAddr, _token, _amount, false);
    }

    function _withdraw(address _accountAddr, address _token, uint256 _amount, bool _isCommission) internal returns (uint256, uint256) {
        uint256 calcAmount = _amount;
        // Check if withdraw amount is less than user's balance
        require(calcAmount <= getDepositBalanceCurrent(_token, _accountAddr), "Insufficient balance");

        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        uint256 lastBlock = tokenInfo.getLastDepositBlock();
        uint256 blockNumber = getBlockNumber();
        calculateDepositFIN(lastBlock, _token, _accountAddr, blockNumber);

        uint256 principalBeforeWithdraw = tokenInfo.getDepositPrincipal();

        if (lastBlock == 0)
            tokenInfo.withdraw(calcAmount, INT_UNIT, blockNumber);
        else {
            // As the last deposit block exists, the block is also a check point on index curve.
            uint256 accruedRate = globalConfig.bank().getDepositAccruedRate(_token, lastBlock);
            tokenInfo.withdraw(calcAmount, accruedRate, blockNumber);
        }

        uint256 principalAfterWithdraw = tokenInfo.getDepositPrincipal();
        if(principalAfterWithdraw == 0) {
            uint8 tokenIndex = globalConfig.tokenInfoRegistry().getTokenIndex(_token);
            unsetFromDepositBitmap(_accountAddr, tokenIndex);
        }

        uint256 commission = 0;
        if (_isCommission && _accountAddr != globalConfig.deFinerCommunityFund()) {
            // DeFiner takes 10% commission on the interest a user earn
            commission = calcAmount.sub(principalBeforeWithdraw.sub(principalAfterWithdraw)).mul(globalConfig.deFinerRate()).div(100);
            deposit(globalConfig.deFinerCommunityFund(), _token, commission);
            calcAmount = calcAmount.sub(commission);
        }

        return (calcAmount, commission);
    }

    /**
     * Update token info for deposit
     */
    function deposit(address _accountAddr, address _token, uint256 _amount) public onlyAuthorized {
        initCollateralFlag(_accountAddr);
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        if(tokenInfo.getDepositPrincipal() == 0) {
            uint8 tokenIndex = globalConfig.tokenInfoRegistry().getTokenIndex(_token);
            setInDepositBitmap(_accountAddr, tokenIndex);
        }

        uint256 blockNumber = getBlockNumber();
        uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
        if(lastDepositBlock == 0)
            tokenInfo.deposit(_amount, INT_UNIT, blockNumber);
        else {
            calculateDepositFIN(lastDepositBlock, _token, _accountAddr, blockNumber);
            uint256 accruedRate = globalConfig.bank().getDepositAccruedRate(_token, lastDepositBlock);
            tokenInfo.deposit(_amount, accruedRate, blockNumber);
        }
    }

    function repay(address _accountAddr, address _token, uint256 _amount) public onlyAuthorized returns(uint256){
        initCollateralFlag(_accountAddr);
        // Update tokenInfo
        uint256 amountOwedWithInterest = getBorrowBalanceCurrent(_token, _accountAddr);
        uint256 amount = _amount > amountOwedWithInterest ? amountOwedWithInterest : _amount;
        uint256 remain = _amount > amountOwedWithInterest ? _amount.sub(amountOwedWithInterest) : 0;
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        // Sanity check
        uint256 borrowPrincipal = tokenInfo.getBorrowPrincipal();
        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
        require(borrowPrincipal > 0, "BorrowPrincipal not gt 0");
        if(lastBorrowBlock == 0)
            tokenInfo.repay(amount, INT_UNIT, getBlockNumber());
        else {
            calculateBorrowFIN(lastBorrowBlock, _token, _accountAddr, getBlockNumber());
            uint256 accruedRate = globalConfig.bank().getBorrowAccruedRate(_token, lastBorrowBlock);
            tokenInfo.repay(amount, accruedRate, getBlockNumber());
        }

        if(borrowPrincipal == 0) {
            uint8 tokenIndex = globalConfig.tokenInfoRegistry().getTokenIndex(_token);
            unsetFromBorrowBitmap(_accountAddr, tokenIndex);
        }
        return remain;
    }

    function getDepositBalanceCurrent(
        address _token,
        address _accountAddr
    ) public view returns (uint256 depositBalance) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        Bank bank = globalConfig.bank();
        uint256 accruedRate;
        uint256 depositRateIndex = bank.depositeRateIndex(_token, tokenInfo.getLastDepositBlock());
        if(tokenInfo.getDepositPrincipal() == 0) {
            return 0;
        } else {
            if(depositRateIndex == 0) {
                accruedRate = INT_UNIT;
            } else {
                accruedRate = bank.depositeRateIndexNow(_token)
                .mul(INT_UNIT)
                .div(depositRateIndex);
            }
            return tokenInfo.getDepositBalance(accruedRate);
        }
    }

    /**
     * Get current borrow balance of a token
     * @param _token token address
     * @dev This is an estimation. Add a new checkpoint first, if you want to derive the exact balance.
     */
    function getBorrowBalanceCurrent(
        address _token,
        address _accountAddr
    ) public view returns (uint256 borrowBalance) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        Bank bank = globalConfig.bank();
        uint256 accruedRate;
        uint256 borrowRateIndex = bank.borrowRateIndex(_token, tokenInfo.getLastBorrowBlock());
        if(tokenInfo.getBorrowPrincipal() == 0) {
            return 0;
        } else {
            if(borrowRateIndex == 0) {
                accruedRate = INT_UNIT;
            } else {
                accruedRate = bank.borrowRateIndexNow(_token)
                .mul(INT_UNIT)
                .div(borrowRateIndex);
            }
            return tokenInfo.getBorrowBalance(accruedRate);
        }
    }

    /**
     * Calculate an account's borrow power based on token's LTV
     */
     /*
    function getBorrowPower(address _borrower) public view returns (uint256 power) {
        TokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        uint256 tokenNum = tokenRegistry.getCoinLength();
        for(uint256 i = 0; i < tokenNum; i++) {
            if (isUserHasDeposits(_borrower, uint8(i))) {
                (address token, uint256 divisor, uint256 price, uint256 borrowLTV) = tokenRegistry.getTokenInfoFromIndex(i);

                uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _borrower);
                power = power.add(depositBalanceCurrent.mul(price).mul(borrowLTV).div(100).div(divisor));
            }
        }
        return power;
    }
    */

    function getBorrowPower(address _borrower) public view returns (uint256 power) {
        Account storage account = accounts[_borrower];

        // if a user have deposits in some tokens and collateral enabled for some
        // then we need to iterate over his deposits for which collateral is also enabled.
        // Hence, we can derive this information by perorming AND bitmap operation
        // hasCollnDepositBitmap = collateralEnabled & hasDeposit
        // Example:
        // collateralBitmap         = 0101
        // depositBitmap            = 0110
        // ================================== OP AND
        // hasCollnDepositBitmap    = 0100 (user can only use his 3rd token as borrow power)
        uint128 hasCollnDepositBitmap = account.collateralBitmap & account.depositBitmap;

        // When no-collateral enabled and no-deposits just return '0' power
        if(hasCollnDepositBitmap == 0) return power;

        TokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();

        // This loop has max "O(n)" complexity where "n = TokensLength", but the loop
        // calculates borrow power only for the `hasCollnDepositBitmap` bit, hence the loop
        // iterates only till the highest bit set. Example 00000100, the loop will iterate
        // only for 4 times, and only 1 time to calculate borrow the power.
        // NOTE: When transaction gas-cost goes above the block gas limit, a user can
        //      disable some of his collaterals so that he can perform the borrow.
        //      Earlier loop implementation was iterating over all tokens, hence the platform
        //      were not able to add new tokens
        for(uint i = 0; i < 128; i++) {
            // if hasCollnDepositBitmap = 0000 then break the loop
            if(hasCollnDepositBitmap > 0) {
                // hasCollnDepositBitmap = 0100
                // mask                  = 0001
                // =============================== OP AND
                // result                = 0000
                bool isEnabled = (hasCollnDepositBitmap & uint128(1)) > 0;
                // Is i(th) token enabled?
                if(isEnabled) {
                    // continue calculating borrow power for i(th) token
                    (address token, uint256 divisor, uint256 price, uint256 borrowLTV) = tokenRegistry.getTokenInfoFromIndex(i);

                    // avoid some gas consumption when borrowLTV == 0
                    if(borrowLTV != 0) {
                        uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _borrower);
                        power = power.add(depositBalanceCurrent.mul(price).mul(borrowLTV).div(100).div(divisor));
                    }
                }

                // right shift by 1
                // hasCollnDepositBitmap = 0100
                // BITWISE RIGHTSHIFT 1 on hasCollnDepositBitmap = 0010
                hasCollnDepositBitmap = hasCollnDepositBitmap >> 1;
                // continue loop and repeat the steps until `hasCollnDepositBitmap == 0`
            } else {
                break;
            }
        }

        return power;
    }

    function getCollateralETH(address _account) public view returns (uint256 collETH) {
        TokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        Account memory account = accounts[_account];
        uint128 hasDeposits = account.depositBitmap;
        for(uint8 i = 0; i < 128; i++) {
            if(hasDeposits > 0) {
                bool isEnabled = (hasDeposits & uint128(1)) > 0;
                if(isEnabled) {
                    (address token,
                    uint256 divisor,
                    uint256 price,
                    uint256 borrowLTV) = tokenRegistry.getTokenInfoFromIndex(i);
                    if(borrowLTV != 0) {
                        uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _account);
                        collETH = collETH.add(depositBalanceCurrent.mul(price).div(divisor));
                    }
                }
                hasDeposits = hasDeposits >> 1;
            } else {
                break;
            }
        }

        return collETH;
    }

    /**
     * Get current deposit balance of a token
     * @dev This is an estimation. Add a new checkpoint first, if you want to derive the exact balance.
     */
    function getDepositETH(
        address _accountAddr
    ) public view returns (uint256 depositETH) {
        TokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        Account memory account = accounts[_accountAddr];
        uint128 hasDeposits = account.depositBitmap;
        for(uint8 i = 0; i < 128; i++) {
            if(hasDeposits > 0) {
                bool isEnabled = (hasDeposits & uint128(1)) > 0;
                if(isEnabled) {
                    (address token, uint256 divisor, uint256 price, ) = tokenRegistry.getTokenInfoFromIndex(i);

                    uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _accountAddr);
                    depositETH = depositETH.add(depositBalanceCurrent.mul(price).div(divisor));
                }
                hasDeposits = hasDeposits >> 1;
            } else {
                break;
            }
        }

        return depositETH;
    }
    /**
     * Get borrowed balance of a token in the uint256 of Wei
     */
    function getBorrowETH(
        address _accountAddr
    ) public view returns (uint256 borrowETH) {
        TokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        Account memory account = accounts[_accountAddr];
        uint128 hasBorrows = account.borrowBitmap;
        for(uint8 i = 0; i < 128; i++) {
            if(hasBorrows > 0) {
                bool isEnabled = (hasBorrows & uint128(1)) > 0;
                if(isEnabled) {
                    (address token, uint256 divisor, uint256 price, ) = tokenRegistry.getTokenInfoFromIndex(i);

                    uint256 borrowBalanceCurrent = getBorrowBalanceCurrent(token, _accountAddr);
                    borrowETH = borrowETH.add(borrowBalanceCurrent.mul(price).div(divisor));
                }
                hasBorrows = hasBorrows >> 1;
            } else {
                break;
            }
        }

        return borrowETH;
    }

    /**
     * Check if the account is liquidatable
     * @param _borrower borrower's account
     * @return true if the account is liquidatable
     */
    function isAccountLiquidatable(address _borrower) public returns (bool) {
        TokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        Bank bank = globalConfig.bank();

        // Add new rate check points for all the collateral tokens from borrower in order to
        // have accurate calculation of liquidation oppotunites.
        Account memory account = accounts[_borrower];
        uint128 hasBorrowsOrDeposits = account.borrowBitmap | account.depositBitmap;
        for(uint8 i = 0; i < 128; i++) {
            if(hasBorrowsOrDeposits > 0) {
                bool isEnabled = (hasBorrowsOrDeposits & uint128(1)) > 0;
                if(isEnabled) {
                    address token = tokenRegistry.addressFromIndex(i);
                    bank.newRateIndexCheckpoint(token);
                }
                hasBorrowsOrDeposits = hasBorrowsOrDeposits >> 1;
            } else {
                break;
            }
        }

        uint256 liquidationThreshold = globalConfig.liquidationThreshold();

        uint256 totalBorrow = getBorrowETH(_borrower);
        uint256 totalCollateral = getCollateralETH(_borrower);

        // It is required that LTV is larger than LIQUIDATE_THREADHOLD for liquidation
        // return totalBorrow.mul(100) > totalCollateral.mul(liquidationThreshold);
        return totalBorrow.mul(100) > totalCollateral.mul(liquidationThreshold);
    }

    struct LiquidationVars {
        uint256 borrowerCollateralValue;
        uint256 targetTokenBalance;
        uint256 targetTokenBalanceBorrowed;
        uint256 targetTokenPrice;
        uint256 liquidationDiscountRatio;
        uint256 totalBorrow;
        uint256 borrowPower;
        uint256 liquidateTokenBalance;
        uint256 liquidateTokenPrice;
        uint256 limitRepaymentValue;
        uint256 borrowTokenLTV;
        uint256 repayAmount;
        uint256 payAmount;
    }

    function liquidate(
        address _liquidator,
        address _borrower,
        address _borrowedToken,
        address _collateralToken
    )
        external
        onlyAuthorized
        returns (
            uint256,
            uint256
        )
    {
        initCollateralFlag(_liquidator);
        initCollateralFlag(_borrower);
        require(isAccountLiquidatable(_borrower), "borrower is not liquidatable");

        // It is required that the liquidator doesn't exceed it's borrow power.
        // if liquidator has any borrows, then only check for borrowPower condition
        Account memory liquidateAcc = accounts[_liquidator];
        if(liquidateAcc.borrowBitmap > 0) {
            require(
                getBorrowETH(_liquidator) < getBorrowPower(_liquidator),
                "No extra funds used for liquidation"
            );
        }

        LiquidationVars memory vars;

        TokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();

        // _borrowedToken balance of the liquidator (deposit balance)
        vars.targetTokenBalance = getDepositBalanceCurrent(_borrowedToken, _liquidator);
        require(vars.targetTokenBalance > 0, "amount must be > 0");

        // _borrowedToken balance of the borrower (borrow balance)
        vars.targetTokenBalanceBorrowed = getBorrowBalanceCurrent(_borrowedToken, _borrower);
        require(vars.targetTokenBalanceBorrowed > 0, "borrower not own any debt token");

        // _borrowedToken available for liquidation
        uint256 borrowedTokenAmountForLiquidation = vars.targetTokenBalance.min(vars.targetTokenBalanceBorrowed);

        // _collateralToken balance of the borrower (deposit balance)
        vars.liquidateTokenBalance = getDepositBalanceCurrent(_collateralToken, _borrower);

        uint256 targetTokenDivisor;
        (
            ,
            targetTokenDivisor,
            vars.targetTokenPrice,
            vars.borrowTokenLTV
        ) = tokenRegistry.getTokenInfoFromAddress(_borrowedToken);

        uint256 liquidateTokendivisor;
        uint256 collateralLTV;
        (
            ,
            liquidateTokendivisor,
            vars.liquidateTokenPrice,
            collateralLTV
        ) = tokenRegistry.getTokenInfoFromAddress(_collateralToken);

        // _collateralToken to purchase so that borrower's balance matches its borrow power
        vars.totalBorrow = getBorrowETH(_borrower);
        vars.borrowPower = getBorrowPower(_borrower);
        vars.liquidationDiscountRatio = globalConfig.liquidationDiscountRatio();
        vars.limitRepaymentValue = vars.totalBorrow.sub(vars.borrowPower)
            .mul(100)
            .div(vars.liquidationDiscountRatio.sub(collateralLTV));

        uint256 collateralTokenValueForLiquidation = vars.limitRepaymentValue.min(
            vars.liquidateTokenBalance
            .mul(vars.liquidateTokenPrice)
            .div(liquidateTokendivisor)
        );

        uint256 liquidationValue = collateralTokenValueForLiquidation.min(
            borrowedTokenAmountForLiquidation
            .mul(vars.targetTokenPrice)
            .mul(100)
            .div(targetTokenDivisor)
            .div(vars.liquidationDiscountRatio)
        );

        vars.repayAmount = liquidationValue.mul(vars.liquidationDiscountRatio)
            .mul(targetTokenDivisor)
            .div(100)
            .div(vars.targetTokenPrice);
        vars.payAmount = vars.repayAmount.mul(liquidateTokendivisor)
            .mul(100)
            .mul(vars.targetTokenPrice);
        vars.payAmount = vars.payAmount.div(targetTokenDivisor)
            .div(vars.liquidationDiscountRatio)
            .div(vars.liquidateTokenPrice);

        deposit(_liquidator, _collateralToken, vars.payAmount);
        withdraw_liquidate(_liquidator, _borrowedToken, vars.repayAmount);
        withdraw_liquidate(_borrower, _collateralToken, vars.payAmount);
        repay(_borrower, _borrowedToken, vars.repayAmount);

        return (vars.repayAmount, vars.payAmount);
    }


    /**
     * Get current block number
     * @return the current block number
     */
    function getBlockNumber() private view returns (uint256) {
        return block.number;
    }

    /**
     * An account claim all mined FIN token.
     * @dev If the FIN mining index point doesn't exist, we have to calculate the FIN amount
     * accurately. So the user can withdraw all available FIN tokens.
     */
    function claim(address _account) public onlyAuthorized returns(uint256){
        TokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        Bank bank = globalConfig.bank();

        uint256 currentBlock = getBlockNumber();

        Account memory account = accounts[_account];
        uint128 depositBitmap = account.depositBitmap;
        uint128 borrowBitmap = account.borrowBitmap;
        uint128 hasDepositOrBorrow = depositBitmap | borrowBitmap;

        for(uint8 i = 0; i < 128; i++) {
            if(hasDepositOrBorrow > 0) {
                if((hasDepositOrBorrow & uint128(1)) > 0) {
                    address token = tokenRegistry.addressFromIndex(i);
                    AccountTokenLib.TokenInfo storage tokenInfo = accounts[_account].tokenInfos[token];
                    bank.updateMining(token);
                    if (depositBitmap.isBitSet(i)) {
                        bank.updateDepositFINIndex(token);
                        uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
                        calculateDepositFIN(lastDepositBlock, token, _account, currentBlock);
                        tokenInfo.deposit(0, bank.getDepositAccruedRate(token, lastDepositBlock), currentBlock);
                    }

                    if (borrowBitmap.isBitSet(i)) {
                        bank.updateBorrowFINIndex(token);
                        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
                        calculateBorrowFIN(lastBorrowBlock, token, _account, currentBlock);
                        tokenInfo.borrow(0, bank.getBorrowAccruedRate(token, lastBorrowBlock), currentBlock);
                    }
                }
                hasDepositOrBorrow = hasDepositOrBorrow >> 1;
            } else {
                break;
            }
        }

        uint256 _FINAmount = FINAmount[_account];
        FINAmount[_account] = 0;
        return _FINAmount;
    }

    function claimForToken(address _account, address _token) public onlyAuthorized returns(uint256) {
        Account memory account = accounts[_account];
        uint8 index = globalConfig.tokenInfoRegistry().getTokenIndex(_token);
        bool isDeposit = account.depositBitmap.isBitSet(index);
        bool isBorrow = account.borrowBitmap.isBitSet(index);
        if(! (isDeposit || isBorrow)) return 0;

        Bank bank = globalConfig.bank();
        uint256 currentBlock = getBlockNumber();

        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_account].tokenInfos[_token];
        bank.updateMining(_token);

        if (isDeposit) {
            bank.updateDepositFINIndex(_token);
            uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
            calculateDepositFIN(lastDepositBlock, _token, _account, currentBlock);
            tokenInfo.deposit(0, bank.getDepositAccruedRate(_token, lastDepositBlock), currentBlock);
        }
        if (isBorrow) {
            bank.updateBorrowFINIndex(_token);
            uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
            calculateBorrowFIN(lastBorrowBlock, _token, _account, currentBlock);
            tokenInfo.borrow(0, bank.getBorrowAccruedRate(_token, lastBorrowBlock), currentBlock);
        }

        uint256 _FINAmount = FINAmount[_account];
        FINAmount[_account] = 0;
        return _FINAmount;
    }

    /**
     * Accumulate the amount FIN mined by depositing between _lastBlock and _currentBlock
     */
    function calculateDepositFIN(uint256 _lastBlock, address _token, address _accountAddr, uint256 _currentBlock) internal {
        Bank bank = globalConfig.bank();

        uint256 indexDifference = bank.depositFINRateIndex(_token, _currentBlock)
            .sub(bank.depositFINRateIndex(_token, _lastBlock));
        uint256 getFIN = getDepositBalanceCurrent(_token, _accountAddr)
            .mul(indexDifference)
            .div(bank.depositeRateIndex(_token, _currentBlock));
        FINAmount[_accountAddr] = FINAmount[_accountAddr].add(getFIN);
    }

    /**
     * Accumulate the amount FIN mined by borrowing between _lastBlock and _currentBlock
     */
    function calculateBorrowFIN(uint256 _lastBlock, address _token, address _accountAddr, uint256 _currentBlock) internal {
        Bank bank = globalConfig.bank();

        uint256 indexDifference = bank.borrowFINRateIndex(_token, _currentBlock)
            .sub(bank.borrowFINRateIndex(_token, _lastBlock));
        uint256 getFIN = getBorrowBalanceCurrent(_token, _accountAddr)
            .mul(indexDifference)
            .div(bank.borrowRateIndex(_token, _currentBlock));
        FINAmount[_accountAddr] = FINAmount[_accountAddr].add(getFIN);
    }

    function version() public pure returns(string memory) {
        return "v1.2.0";
    }
}



contract GlobalConfig is Ownable {
    using SafeMath for uint256;

    uint256 public communityFundRatio = 20;
    uint256 public minReserveRatio = 10;
    uint256 public maxReserveRatio = 20;
    uint256 public liquidationThreshold = 85;
    uint256 public liquidationDiscountRatio = 95;
    uint256 public compoundSupplyRateWeights = 1;
    uint256 public compoundBorrowRateWeights = 9;
    uint256 public rateCurveSlope = 0;
    uint256 public rateCurveConstant = 4 * 10 ** 16;
    uint256 public deFinerRate = 25;
    address payable public deFinerCommunityFund = 0xC0fd76eDcb8893a83c293ed06a362b1c18a584C7;

    Bank public bank;                               // the Bank contract
    SavingAccount public savingAccount;             // the SavingAccount contract
    TokenRegistry public tokenInfoRegistry;     // the TokenRegistry contract
    Accounts public accounts;                       // the Accounts contract
    Constant public constants;                      // the constants contract

    event CommunityFundRatioUpdated(uint256 indexed communityFundRatio);
    event MinReserveRatioUpdated(uint256 indexed minReserveRatio);
    event MaxReserveRatioUpdated(uint256 indexed maxReserveRatio);
    event LiquidationThresholdUpdated(uint256 indexed liquidationThreshold);
    event LiquidationDiscountRatioUpdated(uint256 indexed liquidationDiscountRatio);
    event CompoundSupplyRateWeightsUpdated(uint256 indexed compoundSupplyRateWeights);
    event CompoundBorrowRateWeightsUpdated(uint256 indexed compoundBorrowRateWeights);
    event rateCurveSlopeUpdated(uint256 indexed rateCurveSlope);
    event rateCurveConstantUpdated(uint256 indexed rateCurveConstant);
    event ConstantUpdated(address indexed constants);
    event BankUpdated(address indexed bank);
    event SavingAccountUpdated(address indexed savingAccount);
    event TokenInfoRegistryUpdated(address indexed tokenInfoRegistry);
    event AccountsUpdated(address indexed accounts);
    event DeFinerCommunityFundUpdated(address indexed deFinerCommunityFund);
    event DeFinerRateUpdated(uint256 indexed deFinerRate);
    event ChainLinkUpdated(address indexed chainLink);


    function initialize(
        Bank _bank,
        SavingAccount _savingAccount,
        TokenRegistry _tokenInfoRegistry,
        Accounts _accounts,
        Constant _constants
    ) public onlyOwner {
        bank = _bank;
        savingAccount = _savingAccount;
        tokenInfoRegistry = _tokenInfoRegistry;
        accounts = _accounts;
        constants = _constants;
    }

    /**
     * Update the community fund (commision fee) ratio.
     * @param _communityFundRatio the new ratio
     */
    function updateCommunityFundRatio(uint256 _communityFundRatio) external onlyOwner {
        if (_communityFundRatio == communityFundRatio)
            return;

        require(_communityFundRatio > 0 && _communityFundRatio < 100,
            "Invalid community fund ratio.");
        communityFundRatio = _communityFundRatio;

        emit CommunityFundRatioUpdated(_communityFundRatio);
    }

    /**
     * Update the minimum reservation reatio
     * @param _minReserveRatio the new value of the minimum reservation ratio
     */
    function updateMinReserveRatio(uint256 _minReserveRatio) external onlyOwner {
        if (_minReserveRatio == minReserveRatio)
            return;

        require(_minReserveRatio > 0 && _minReserveRatio < maxReserveRatio,
            "Invalid min reserve ratio.");
        minReserveRatio = _minReserveRatio;

        emit MinReserveRatioUpdated(_minReserveRatio);
    }

    /**
     * Update the maximum reservation reatio
     * @param _maxReserveRatio the new value of the maximum reservation ratio
     */
    function updateMaxReserveRatio(uint256 _maxReserveRatio) external onlyOwner {
        if (_maxReserveRatio == maxReserveRatio)
            return;

        require(_maxReserveRatio > minReserveRatio && _maxReserveRatio < 100,
            "Invalid max reserve ratio.");
        maxReserveRatio = _maxReserveRatio;

        emit MaxReserveRatioUpdated(_maxReserveRatio);
    }

    /**
     * Update the liquidation threshold, i.e. the LTV that will trigger the liquidation.
     * @param _liquidationThreshold the new threshhold value
     */
    function updateLiquidationThreshold(uint256 _liquidationThreshold) external onlyOwner {
        if (_liquidationThreshold == liquidationThreshold)
            return;

        require(_liquidationThreshold > 0 && _liquidationThreshold < liquidationDiscountRatio,
            "Invalid liquidation threshold.");
        liquidationThreshold = _liquidationThreshold;

        emit LiquidationThresholdUpdated(_liquidationThreshold);
    }

    /**
     * Update the liquidation discount
     * @param _liquidationDiscountRatio the new liquidation discount
     */
    function updateLiquidationDiscountRatio(uint256 _liquidationDiscountRatio) external onlyOwner {
        if (_liquidationDiscountRatio == liquidationDiscountRatio)
            return;

        require(_liquidationDiscountRatio > liquidationThreshold && _liquidationDiscountRatio < 100,
            "Invalid liquidation discount ratio.");
        liquidationDiscountRatio = _liquidationDiscountRatio;

        emit LiquidationDiscountRatioUpdated(_liquidationDiscountRatio);
    }

    /**
     * Medium value of the reservation ratio, which is the value that the pool try to maintain.
     */
    function midReserveRatio() public view returns(uint256){
        return minReserveRatio.add(maxReserveRatio).div(2);
    }

    function updateCompoundSupplyRateWeights(uint256 _compoundSupplyRateWeights) external onlyOwner{
        compoundSupplyRateWeights = _compoundSupplyRateWeights;

        emit CompoundSupplyRateWeightsUpdated(_compoundSupplyRateWeights);
    }

    function updateCompoundBorrowRateWeights(uint256 _compoundBorrowRateWeights) external onlyOwner{
        compoundBorrowRateWeights = _compoundBorrowRateWeights;

        emit CompoundBorrowRateWeightsUpdated(_compoundBorrowRateWeights);
    }

    function updaterateCurveSlope(uint256 _rateCurveSlope) external onlyOwner{
        rateCurveSlope = _rateCurveSlope;

        emit rateCurveSlopeUpdated(_rateCurveSlope);
    }

    function updaterateCurveConstant(uint256 _rateCurveConstant) external onlyOwner{
        rateCurveConstant = _rateCurveConstant;

        emit rateCurveConstantUpdated(_rateCurveConstant);
    }

    function updateBank(Bank _bank) external onlyOwner{
        bank = _bank;

        emit BankUpdated(address(_bank));
    }

    function updateSavingAccount(SavingAccount _savingAccount) external onlyOwner{
        savingAccount = _savingAccount;

        emit SavingAccountUpdated(address(_savingAccount));
    }

    function updateTokenInfoRegistry(TokenRegistry _tokenInfoRegistry) external onlyOwner{
        tokenInfoRegistry = _tokenInfoRegistry;

        emit TokenInfoRegistryUpdated(address(_tokenInfoRegistry));
    }

    function updateAccounts(Accounts _accounts) external onlyOwner{
        accounts = _accounts;

        emit AccountsUpdated(address(_accounts));
    }

    function updateConstant(Constant _constants) external onlyOwner{
        constants = _constants;

        emit ConstantUpdated(address(_constants));
    }

    function updatedeFinerCommunityFund(address payable _deFinerCommunityFund) external onlyOwner{
        deFinerCommunityFund = _deFinerCommunityFund;

        emit DeFinerCommunityFundUpdated(_deFinerCommunityFund);
    }

    function updatedeFinerRate(uint256 _deFinerRate) external onlyOwner{
        require(_deFinerRate <= 100,"_deFinerRate cannot exceed 100");
        deFinerRate = _deFinerRate;

        emit DeFinerRateUpdated(_deFinerRate);
    }

}
interface ICToken {
    function supplyRatePerBlock() external view returns (uint);
    function borrowRatePerBlock() external view returns (uint);
    function mint(uint mintAmount) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function redeem(uint redeemAmount) external returns (uint);
    function exchangeRateStore() external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function balanceOf(address owner) external view returns (uint256);
    function balanceOfUnderlying(address owner) external returns (uint);
}

interface ICETH{
    function mint() external payable;
}

interface IController {
    function fastForward(uint blocks) external returns (uint);
    function getBlockNumber() external view returns (uint);
}



contract Bank is Constant, Initializable{
    using SafeMath for uint256;

    mapping(address => uint256) public totalLoans;     // amount of lended tokens
    mapping(address => uint256) public totalReserve;   // amount of tokens in reservation
    mapping(address => uint256) public totalCompound;  // amount of tokens in compound
    // Token => block-num => rate
    mapping(address => mapping(uint => uint)) public depositeRateIndex; // the index curve of deposit rate
    // Token => block-num => rate
    mapping(address => mapping(uint => uint)) public borrowRateIndex;   // the index curve of borrow rate
    // token address => block number
    mapping(address => uint) public lastCheckpoint;            // last checkpoint on the index curve
    // cToken address => rate
    mapping(address => uint) public lastCTokenExchangeRate;    // last compound cToken exchange rate
    mapping(address => ThirdPartyPool) compoundPool;    // the compound pool

    GlobalConfig globalConfig;            // global configuration contract address

    mapping(address => mapping(uint => uint)) public depositFINRateIndex;
    mapping(address => mapping(uint => uint)) public borrowFINRateIndex;
    mapping(address => uint) public lastDepositFINRateCheckpoint;
    mapping(address => uint) public lastBorrowFINRateCheckpoint;

    modifier onlyAuthorized() {
        require(msg.sender == address(globalConfig.savingAccount()) || msg.sender == address(globalConfig.accounts()),
            "Only authorized to call from DeFiner internal contracts.");
        _;
    }

    struct ThirdPartyPool {
        bool supported;             // if the token is supported by the third party platforms such as Compound
        uint capitalRatio;          // the ratio of the capital in third party to the total asset
        uint depositRatePerBlock;   // the deposit rate of the token in third party
        uint borrowRatePerBlock;    // the borrow rate of the token in third party
    }

    event UpdateIndex(address indexed token, uint256 depositeRateIndex, uint256 borrowRateIndex);
    event UpdateDepositFINIndex(address indexed _token, uint256 depositFINRateIndex);
    event UpdateBorrowFINIndex(address indexed _token, uint256 borrowFINRateIndex);

    /**
     * Initialize the Bank
     * @param _globalConfig the global configuration contract
     */
    function initialize(
        GlobalConfig _globalConfig
    ) public initializer {
        globalConfig = _globalConfig;
    }

    /**
     * Total amount of the token in Saving account
     * @param _token token address
     */
    function getTotalDepositStore(address _token) public view returns(uint) {
        address cToken = globalConfig.tokenInfoRegistry().getCToken(_token);
        // totalLoans[_token] = U   totalReserve[_token] = R
        return totalCompound[cToken].add(totalLoans[_token]).add(totalReserve[_token]); // return totalAmount = C + U + R
    }

    /**
     * Update total amount of token in Compound as the cToken price changed
     * @param _token token address
     */
    function updateTotalCompound(address _token) internal {
        address cToken = globalConfig.tokenInfoRegistry().getCToken(_token);
        if(cToken != address(0)) {
            totalCompound[cToken] = ICToken(cToken).balanceOfUnderlying(address(globalConfig.savingAccount()));
        }
    }

    /**
     * Update the total reservation. Before run this function, make sure that totalCompound has been updated
     * by calling updateTotalCompound. Otherwise, totalCompound may not equal to the exact amount of the
     * token in Compound.
     * @param _token token address
     * @param _action indicate if user's operation is deposit or withdraw, and borrow or repay.
     * @return the actuall amount deposit/withdraw from the saving pool
     */
    function updateTotalReserve(address _token, uint _amount, ActionType _action) internal returns(uint256 compoundAmount){
        address cToken = globalConfig.tokenInfoRegistry().getCToken(_token);
        uint totalAmount = getTotalDepositStore(_token);
        if (_action == ActionType.DepositAction || _action == ActionType.RepayAction) {
            // Total amount of token after deposit or repay
            if (_action == ActionType.DepositAction)
                totalAmount = totalAmount.add(_amount);
            else
                totalLoans[_token] = totalLoans[_token].sub(_amount);

            // Expected total amount of token in reservation after deposit or repay
            uint totalReserveBeforeAdjust = totalReserve[_token].add(_amount);

            if (cToken != address(0) &&
            totalReserveBeforeAdjust > totalAmount.mul(globalConfig.maxReserveRatio()).div(100)) {
                uint toCompoundAmount = totalReserveBeforeAdjust.sub(totalAmount.mul(globalConfig.midReserveRatio()).div(100));
                //toCompound(_token, toCompoundAmount);
                compoundAmount = toCompoundAmount;
                totalCompound[cToken] = totalCompound[cToken].add(toCompoundAmount);
                totalReserve[_token] = totalReserve[_token].add(_amount).sub(toCompoundAmount);
            }
            else {
                totalReserve[_token] = totalReserve[_token].add(_amount);
            }
        } else {
            // The lack of liquidity exception happens when the pool doesn't have enough tokens for borrow/withdraw
            // It happens when part of the token has lended to the other accounts.
            // However in case of withdrawAll, even if the token has no loan, this requirment may still false because
            // of the precision loss in the rate calcuation. So we put a logic here to deal with this case: in case
            // of withdrawAll and there is no loans for the token, we just adjust the balance in bank contract to the
            // to the balance of that individual account.
            if(_action == ActionType.WithdrawAction) {
                if(totalLoans[_token] != 0)
                    require(getPoolAmount(_token) >= _amount, "Lack of liquidity when withdraw.");
                else if (getPoolAmount(_token) < _amount)
                    totalReserve[_token] = _amount.sub(totalCompound[cToken]);
                totalAmount = getTotalDepositStore(_token);
            }
            else
                require(getPoolAmount(_token) >= _amount, "Lack of liquidity when borrow.");

            // Total amount of token after withdraw or borrow
            if (_action == ActionType.WithdrawAction)
                totalAmount = totalAmount.sub(_amount);
            else
                totalLoans[_token] = totalLoans[_token].add(_amount);

            // Expected total amount of token in reservation after deposit or repay
            uint totalReserveBeforeAdjust = totalReserve[_token] > _amount ? totalReserve[_token].sub(_amount) : 0;

            // Trigger fromCompound if the new reservation ratio is less than 10%
            if(cToken != address(0) &&
            (totalAmount == 0 || totalReserveBeforeAdjust < totalAmount.mul(globalConfig.minReserveRatio()).div(100))) {

                uint totalAvailable = totalReserve[_token].add(totalCompound[cToken]).sub(_amount);
                if (totalAvailable < totalAmount.mul(globalConfig.midReserveRatio()).div(100)){
                    // Withdraw all the tokens from Compound
                    compoundAmount = totalCompound[cToken];
                    totalCompound[cToken] = 0;
                    totalReserve[_token] = totalAvailable;
                } else {
                    // Withdraw partial tokens from Compound
                    uint totalInCompound = totalAvailable.sub(totalAmount.mul(globalConfig.midReserveRatio()).div(100));
                    compoundAmount = totalCompound[cToken].sub(totalInCompound);
                    totalCompound[cToken] = totalInCompound;
                    totalReserve[_token] = totalAvailable.sub(totalInCompound);
                }
            }
            else {
                totalReserve[_token] = totalReserve[_token].sub(_amount);
            }
        }
        return compoundAmount;
    }

     function update(address _token, uint _amount, ActionType _action) public onlyAuthorized returns(uint256 compoundAmount) {
        updateTotalCompound(_token);
        // updateTotalLoan(_token);
        compoundAmount = updateTotalReserve(_token, _amount, _action);
        return compoundAmount;
    }

    /**
     * The function is called in Bank.deposit(), Bank.withdraw() and Accounts.claim() functions.
     * The function should be called AFTER the newRateIndexCheckpoint function so that the account balances are
     * accurate, and BEFORE the account balance acutally updated due to deposit/withdraw activities.
     */
    function updateDepositFINIndex(address _token) public onlyAuthorized{
        uint currentBlock = getBlockNumber();
        uint deltaBlock;
        // If it is the first deposit FIN rate checkpoint, set the deltaBlock value be 0 so that the first
        // point on depositFINRateIndex is zero.
        deltaBlock = lastDepositFINRateCheckpoint[_token] == 0 ? 0 : currentBlock.sub(lastDepositFINRateCheckpoint[_token]);
        // If the totalDeposit of the token is zero, no FIN token should be mined and the FINRateIndex is unchanged.
        depositFINRateIndex[_token][currentBlock] = depositFINRateIndex[_token][lastDepositFINRateCheckpoint[_token]].add(
            getTotalDepositStore(_token) == 0 ? 0 : depositeRateIndex[_token][lastCheckpoint[_token]]
                .mul(deltaBlock)
                .mul(globalConfig.tokenInfoRegistry().depositeMiningSpeeds(_token))
                .div(getTotalDepositStore(_token)));
        lastDepositFINRateCheckpoint[_token] = currentBlock;

        emit UpdateDepositFINIndex(_token, depositFINRateIndex[_token][currentBlock]);
    }

    function updateBorrowFINIndex(address _token) public onlyAuthorized{
        uint currentBlock = getBlockNumber();
        uint deltaBlock;
        // If it is the first borrow FIN rate checkpoint, set the deltaBlock value be 0 so that the first
        // point on borrowFINRateIndex is zero.
        deltaBlock = lastBorrowFINRateCheckpoint[_token] == 0 ? 0 : currentBlock.sub(lastBorrowFINRateCheckpoint[_token]);
        // If the totalBorrow of the token is zero, no FIN token should be mined and the FINRateIndex is unchanged.
        borrowFINRateIndex[_token][currentBlock] = borrowFINRateIndex[_token][lastBorrowFINRateCheckpoint[_token]].add(
            totalLoans[_token] == 0 ? 0 : borrowRateIndex[_token][lastCheckpoint[_token]]
                    .mul(deltaBlock)
                    .mul(globalConfig.tokenInfoRegistry().borrowMiningSpeeds(_token))
                    .div(totalLoans[_token]));
        lastBorrowFINRateCheckpoint[_token] = currentBlock;

        emit UpdateBorrowFINIndex(_token, borrowFINRateIndex[_token][currentBlock]);
    }

    function updateMining(address _token) public onlyAuthorized{
        newRateIndexCheckpoint(_token);
        updateTotalCompound(_token);
    }

    /**
     * Get the borrowing interest rate.
     * @param _token token address
     * @return the borrow rate for the current block
     */
    function getBorrowRatePerBlock(address _token) public view returns(uint) {
        uint256 capitalUtilizationRatio = getCapitalUtilizationRatio(_token);
        // rateCurveConstant = <'3 * (10)^16'_rateCurveConstant_configurable>
        uint256 rateCurveConstant = globalConfig.rateCurveConstant();
        // compoundSupply = Compound Supply Rate * <'0.4'_supplyRateWeights_configurable>
        uint256 compoundSupply = compoundPool[_token].depositRatePerBlock.mul(globalConfig.compoundSupplyRateWeights());
        // compoundBorrow = Compound Borrow Rate * <'0.6'_borrowRateWeights_configurable>
        uint256 compoundBorrow = compoundPool[_token].borrowRatePerBlock.mul(globalConfig.compoundBorrowRateWeights());
        // nonUtilizedCapRatio = (1 - U) // Non utilized capital ratio
        uint256 nonUtilizedCapRatio = INT_UNIT.sub(capitalUtilizationRatio);

        bool isSupportedOnCompound = globalConfig.tokenInfoRegistry().isSupportedOnCompound(_token);
        if(isSupportedOnCompound) {
            uint256 compoundSupplyPlusBorrow = compoundSupply.add(compoundBorrow).div(10);
            uint256 rateConstant;
            // if the token is supported in third party (like Compound), check if U = 1
            if(capitalUtilizationRatio > ((10**18) - (10**15))) { // > 0.999
                // if U = 1, borrowing rate = compoundSupply + compoundBorrow + ((rateCurveConstant * 100) / BLOCKS_PER_YEAR)
                rateConstant = rateCurveConstant.mul(1000).div(BLOCKS_PER_YEAR);
                return compoundSupplyPlusBorrow.add(rateConstant);
            } else {
                // if U != 1, borrowing rate = compoundSupply + compoundBorrow + ((rateCurveConstant / (1 - U)) / BLOCKS_PER_YEAR)
                rateConstant = rateCurveConstant.mul(10**18).div(nonUtilizedCapRatio).div(BLOCKS_PER_YEAR);
                return compoundSupplyPlusBorrow.add(rateConstant);
            }
        } else {
            // If the token is NOT supported by the third party, check if U = 1
            if(capitalUtilizationRatio > ((10**18) - (10**15))) { // > 0.999
                // if U = 1, borrowing rate = rateCurveConstant * 100
                return rateCurveConstant.mul(1000).div(BLOCKS_PER_YEAR);
            } else {
                // if 0 < U < 1, borrowing rate = 3% / (1 - U)
                return rateCurveConstant.mul(10**18).div(nonUtilizedCapRatio).div(BLOCKS_PER_YEAR);
            }
        }
    }

    /**
    * Get Deposit Rate.  Deposit APR = (Borrow APR * Utilization Rate (U) +  Compound Supply Rate *
    * Capital Compound Ratio (C) )* (1- DeFiner Community Fund Ratio (D)). The scaling is 10 ** 18
    * @param _token token address
    * @return deposite rate of blocks before the current block
    */
    function getDepositRatePerBlock(address _token) public view returns(uint) {
        uint256 borrowRatePerBlock = getBorrowRatePerBlock(_token);
        uint256 capitalUtilRatio = getCapitalUtilizationRatio(_token);
        if(!globalConfig.tokenInfoRegistry().isSupportedOnCompound(_token))
            return borrowRatePerBlock.mul(capitalUtilRatio).div(INT_UNIT);

        return borrowRatePerBlock.mul(capitalUtilRatio).add(compoundPool[_token].depositRatePerBlock
            .mul(compoundPool[_token].capitalRatio)).div(INT_UNIT);
    }

    /**
     * Get capital utilization. Capital Utilization Rate (U )= total loan outstanding / Total market deposit
     * @param _token token address
     * @return Capital utilization ratio `U`.
     *  Valid range: 0 ≤ U ≤ 10^18
     */
    function getCapitalUtilizationRatio(address _token) public view returns(uint) {
        uint256 totalDepositsNow = getTotalDepositStore(_token);
        if(totalDepositsNow == 0) {
            return 0;
        } else {
            return totalLoans[_token].mul(INT_UNIT).div(totalDepositsNow);
        }
    }

    /**
     * Ratio of the capital in Compound
     * @param _token token address
     */
    function getCapitalCompoundRatio(address _token) public view returns(uint) {
        address cToken = globalConfig.tokenInfoRegistry().getCToken(_token);
        if(totalCompound[cToken] == 0 ) {
            return 0;
        } else {
            return uint(totalCompound[cToken].mul(INT_UNIT).div(getTotalDepositStore(_token)));
        }
    }

    /**
     * It's a utility function. Get the cummulative deposit rate in a block interval ending in current block
     * @param _token token address
     * @param _depositRateRecordStart the start block of the interval
     * @dev This function should always be called after current block is set as a new rateIndex point.
     */
    function getDepositAccruedRate(address _token, uint _depositRateRecordStart) external view returns (uint256) {
        uint256 depositRate = depositeRateIndex[_token][_depositRateRecordStart];
        require(depositRate != 0, "_depositRateRecordStart is not a check point on index curve.");
        return depositeRateIndexNow(_token).mul(INT_UNIT).div(depositRate);
    }

    /**
     * Get the cummulative borrow rate in a block interval ending in current block
     * @param _token token address
     * @param _borrowRateRecordStart the start block of the interval
     * @dev This function should always be called after current block is set as a new rateIndex point.
     */
    function getBorrowAccruedRate(address _token, uint _borrowRateRecordStart) external view returns (uint256) {
        uint256 borrowRate = borrowRateIndex[_token][_borrowRateRecordStart];
        require(borrowRate != 0, "_borrowRateRecordStart is not a check point on index curve.");
        return borrowRateIndexNow(_token).mul(INT_UNIT).div(borrowRate);
    }

    /**
     * Set a new rate index checkpoint.
     * @param _token token address
     * @dev The rate set at the checkpoint is the rate from the last checkpoint to this checkpoint
     */
    function newRateIndexCheckpoint(address _token) public onlyAuthorized {

        // return if the rate check point already exists
        uint blockNumber = getBlockNumber();
        if (blockNumber == lastCheckpoint[_token])
            return;

        uint256 UNIT = INT_UNIT;
        address cToken = globalConfig.tokenInfoRegistry().getCToken(_token);

        // If it is the first check point, initialize the rate index
        uint256 previousCheckpoint = lastCheckpoint[_token];
        if (lastCheckpoint[_token] == 0) {
            if(cToken == address(0)) {
                compoundPool[_token].supported = false;
                borrowRateIndex[_token][blockNumber] = UNIT;
                depositeRateIndex[_token][blockNumber] = UNIT;
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
            }
            else {
                compoundPool[_token].supported = true;
                uint cTokenExchangeRate = ICToken(cToken).exchangeRateCurrent();
                // Get the curretn cToken exchange rate in Compound, which is need to calculate DeFiner's rate
                compoundPool[_token].capitalRatio = getCapitalCompoundRatio(_token);
                compoundPool[_token].borrowRatePerBlock = ICToken(cToken).borrowRatePerBlock();  // initial value
                compoundPool[_token].depositRatePerBlock = ICToken(cToken).supplyRatePerBlock(); // initial value
                borrowRateIndex[_token][blockNumber] = UNIT;
                depositeRateIndex[_token][blockNumber] = UNIT;
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
                lastCTokenExchangeRate[cToken] = cTokenExchangeRate;
            }

        } else {
            if(cToken == address(0)) {
                compoundPool[_token].supported = false;
                borrowRateIndex[_token][blockNumber] = borrowRateIndexNow(_token);
                depositeRateIndex[_token][blockNumber] = depositeRateIndexNow(_token);
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
            } else {
                compoundPool[_token].supported = true;
                uint cTokenExchangeRate = ICToken(cToken).exchangeRateCurrent();
                // Get the curretn cToken exchange rate in Compound, which is need to calculate DeFiner's rate
                compoundPool[_token].capitalRatio = getCapitalCompoundRatio(_token);
                compoundPool[_token].borrowRatePerBlock = ICToken(cToken).borrowRatePerBlock();
                compoundPool[_token].depositRatePerBlock = cTokenExchangeRate.mul(UNIT).div(lastCTokenExchangeRate[cToken])
                    .sub(UNIT).div(blockNumber.sub(lastCheckpoint[_token]));
                borrowRateIndex[_token][blockNumber] = borrowRateIndexNow(_token);
                depositeRateIndex[_token][blockNumber] = depositeRateIndexNow(_token);
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
                lastCTokenExchangeRate[cToken] = cTokenExchangeRate;
            }
        }

        // Update the total loan
        if(borrowRateIndex[_token][blockNumber] != UNIT) {
            totalLoans[_token] = totalLoans[_token].mul(borrowRateIndex[_token][blockNumber])
                .div(borrowRateIndex[_token][previousCheckpoint]);
        }

        emit UpdateIndex(_token, depositeRateIndex[_token][getBlockNumber()], borrowRateIndex[_token][getBlockNumber()]);
    }

    /**
     * Calculate a token deposite rate of current block
     * @param _token token address
     * @dev This is an looking forward estimation from last checkpoint and not the exactly rate that the user will pay or earn.
     */
    function depositeRateIndexNow(address _token) public view returns(uint) {
        uint256 lcp = lastCheckpoint[_token];
        // If this is the first checkpoint, set the index be 1.
        if(lcp == 0)
            return INT_UNIT;

        uint256 lastDepositeRateIndex = depositeRateIndex[_token][lcp];
        uint256 depositRatePerBlock = getDepositRatePerBlock(_token);
        // newIndex = oldIndex*(1+r*delta_block). If delta_block = 0, i.e. the last checkpoint is current block, index doesn't change.
        return lastDepositeRateIndex.mul(getBlockNumber().sub(lcp).mul(depositRatePerBlock).add(INT_UNIT)).div(INT_UNIT);
    }

    /**
     * Calculate a token borrow rate of current block
     * @param _token token address
     */
    function borrowRateIndexNow(address _token) public view returns(uint) {
        uint256 lcp = lastCheckpoint[_token];
        // If this is the first checkpoint, set the index be 1.
        if(lcp == 0)
            return INT_UNIT;
        uint256 lastBorrowRateIndex = borrowRateIndex[_token][lcp];
        uint256 borrowRatePerBlock = getBorrowRatePerBlock(_token);
        return lastBorrowRateIndex.mul(getBlockNumber().sub(lcp).mul(borrowRatePerBlock).add(INT_UNIT)).div(INT_UNIT);
    }

    /**
	 * Get the state of the given token
     * @param _token token address
	 */
    function getTokenState(address _token) public view returns (uint256 deposits, uint256 loans, uint256 reserveBalance, uint256 remainingAssets){
        return (
        getTotalDepositStore(_token),
        totalLoans[_token],
        totalReserve[_token],
        totalReserve[_token].add(totalCompound[globalConfig.tokenInfoRegistry().getCToken(_token)])
        );
    }

    function getPoolAmount(address _token) public view returns(uint) {
        return totalReserve[_token].add(totalCompound[globalConfig.tokenInfoRegistry().getCToken(_token)]);
    }

    function deposit(address _to, address _token, uint256 _amount) external onlyAuthorized {

        require(_amount != 0, "Amount is zero");

        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateDepositFINIndex(_token);

        // Update tokenInfo. Add the _amount to principal, and update the last deposit block in tokenInfo
        globalConfig.accounts().deposit(_to, _token, _amount);

        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint compoundAmount = update(_token, _amount, ActionType.DepositAction);

        if(compoundAmount > 0) {
            globalConfig.savingAccount().toCompound(_token, compoundAmount);
        }
    }

    function borrow(address _from, address _token, uint256 _amount) external onlyAuthorized {

        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateBorrowFINIndex(_token);

        // Update tokenInfo for the user
        globalConfig.accounts().borrow(_from, _token, _amount);

        // Update pool balance
        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint compoundAmount = update(_token, _amount, ActionType.BorrowAction);

        if(compoundAmount > 0) {
            globalConfig.savingAccount().fromCompound(_token, compoundAmount);
        }
    }

    function repay(address _to, address _token, uint256 _amount) external onlyAuthorized returns(uint) {

        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateBorrowFINIndex(_token);

        // Sanity check
        require(globalConfig.accounts().getBorrowPrincipal(_to, _token) > 0,
            "Token BorrowPrincipal must be greater than 0. To deposit balance, please use deposit button."
        );

        // Update tokenInfo
        uint256 remain = globalConfig.accounts().repay(_to, _token, _amount);

        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint compoundAmount = update(_token, _amount.sub(remain), ActionType.RepayAction);
        if(compoundAmount > 0) {
           globalConfig.savingAccount().toCompound(_token, compoundAmount);
        }

        // Return actual amount repaid
        return _amount.sub(remain);
    }

    /**
     * Withdraw a token from an address
     * @param _from address to be withdrawn from
     * @param _token token address
     * @param _amount amount to be withdrawn
     * @return The actually amount withdrawed, which will be the amount requested minus the commission fee.
     */
    function withdraw(address _from, address _token, uint256 _amount) external onlyAuthorized returns(uint) {

        require(_amount != 0, "Amount is zero");

        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateDepositFINIndex(_token);

        // Withdraw from the account
        uint amount = globalConfig.accounts().withdraw(_from, _token, _amount);

        // Update pool balance
        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint compoundAmount = update(_token, amount, ActionType.WithdrawAction);

        // Check if there are enough tokens in the pool.
        if(compoundAmount > 0) {
            globalConfig.savingAccount().fromCompound(_token, compoundAmount);
        }

        return amount;
    }

    /**
     * Get current block number
     * @return the current block number
     */
    function getBlockNumber() private view returns (uint) {
        return block.number;
    }

    function version() public pure returns(string memory) {
        return "v1.2.0";
    }

}