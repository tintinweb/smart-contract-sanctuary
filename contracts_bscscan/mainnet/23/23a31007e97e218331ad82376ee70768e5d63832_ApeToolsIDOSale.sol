/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/GSN/Context.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/access/Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/utils/Address.sol

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/math/SafeMath.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC20/IERC20.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/token/ERC20/SafeERC20.sol

pragma solidity >=0.6.0 <0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/aaa.sol

//SPDX-License-Identifier: Unlicense
pragma solidity =0.7.3;





contract ApeToolsIDOSale is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address busdAddress = 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47;



    uint256 public salePrice;
    uint256 public cap;
    address public token;
    uint256 public tokensSold;
    uint256 public tokenSaleDuration;
    uint256 public startTime;
    uint256 public tokenListingTime;

    bool public released = false;
    address payable public wallet;

    bool public initialized = false;
    bool public personalAllocation = true;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _purchasedTokens;
    mapping(address => uint256) private _allocations;

    uint256 public maxBuyAmount;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
    */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokensWithdrawn(address indexed withdrawer, uint256 amount);
    event StartChanged(uint256 newStartDate);
    event SetListingTime(uint256 listingTime);
    event TokenSaleDurationChanged(uint256 newDuration);
    event TokenReleased(bool _released);
    event DepositBUSD(string tokenName, address indexed beneficiary, uint256 amount);

    modifier ongoingSale() {
        require(block.timestamp >= startTime && block.timestamp <= tokenSaleEndTime() && initialized,
            "Sale: not selling now");
        _;
    }

    modifier allowedUser(address beneficiary) {
        if (personalAllocation){
            require(_allocations[beneficiary] != 0 && maxBuyAmount > 0, "Sale: You are not allowed to buy tokens");
        } else {
            require(maxBuyAmount > 0, "Sale: maxBuyAmount should be defined if personal allocation is off");
        }
        _;
    }

    modifier afterRelease() {
        require(released || (block.timestamp >= tokenListingTime && tokenListingTime != 0), "Sale: not released yet");
        _;
    }

    /**
    * @notice Create token sale contracts with initial params. After creation init functions must be called
    * @param _token Address of token to sale
    * @param _salePrice BUSD per token, multiplied by 1e6
    * @param _startTime Token sale start time in unix seconds
    * @param _cap Amount of tokens to sell, multiplied by 1e18(decimals ether)
    * @param _tokenSaleDuration token sale duration
    */
    constructor(address _token, uint256 _salePrice, uint256 _startTime, uint256 _cap, uint256 _tokenSaleDuration, address _busdAddress) {
        require(_startTime > block.timestamp, "Sale: invalid start time");
        require(_token != address(0), "Sale: zero token address");
        require(_salePrice > 0, "Sale: price must not be zero");
        require(_cap > 0, "Sale: cap not be zero");
        require(_tokenSaleDuration > 0, "Sale: duration not be zero");

        token = _token;
        cap = _cap;
        salePrice = _salePrice;
        startTime = _startTime;
        tokenSaleDuration = _tokenSaleDuration;
        wallet = msg.sender;
        maxBuyAmount = calculatePurchaseAmount(50 ether);
        busdAddress = _busdAddress;
    }

    function init() public {
        require(!initialized, "Sale: already initialized");
        IERC20(token).safeTransferFrom(msg.sender, address(this), cap);
        initialized = true;
    }

    /**
    * @notice Token sale end time in unix seconds
    */
    function tokenSaleEndTime() public view returns (uint256) {
        return startTime + tokenSaleDuration;
    }

    /**
    * @notice Buy tokens
    * @param beneficiary Address of account token can be withdrawn to after sale
    * @param busdAmountWei Amount in BUSD multiplied by 1e18
    */
    function buyTokens(address beneficiary, uint256 busdAmountWei) public ongoingSale allowedUser(beneficiary) returns (bool){
        require(beneficiary != address(0), "Sale: to the zero address");
        uint256 amount = calculatePurchaseAmount(busdAmountWei);
        require(amount != 0, "Sale: amount is 0");
        require(amount.add(tokensSold) <= cap, "Sale: cap reached");
        if (personalAllocation) {
            require(_allocations[beneficiary] >= amount, "Sale: amount exceeds available personal allocation");
            require(_purchasedTokens[beneficiary] < _allocations[beneficiary], "You bought full allowed alocation");
        } else {
            require(maxBuyAmount >= amount, "Sale: amount exceeds max allocation");
            require(_purchasedTokens[beneficiary] < maxBuyAmount, "You bought full allowed alocation");
        }
        require(IERC20(busdAddress).balanceOf(msg.sender) >= busdAmountWei, "Sale: Not enough funds");
        tokensSold = tokensSold.add(amount);
        _balances[beneficiary] = _balances[beneficiary].add(amount);

        if (personalAllocation) {
            _allocations[beneficiary] = _allocations[beneficiary].sub(amount);
        }
        _purchasedTokens[beneficiary] = _purchasedTokens[beneficiary].add(amount);
        emit TokensPurchased(msg.sender, beneficiary, busdAmountWei, amount);

        IERC20(busdAddress).transferFrom(msg.sender, address(this), busdAmountWei);
        emit DepositBUSD("BUSD", msg.sender, busdAmountWei);
        return true;
    }

    /**
    * @notice Calculates amount of tokens to be bought for given bnb
    * @param purchaseAmountWei amount in wei
    * @return amount of tokens that can be bought for given purchaseAmountInWei
    */
    function calculatePurchaseAmount(uint purchaseAmountWei) public view returns(uint256) {
        return purchaseAmountWei.mul(1e6).div(salePrice);
    }

    /**
    * @notice Amount of tokens that can be withdrawn (locked and unlocked)
    * @param account Address of account to query balance
    * @return the balance of purchased tokens of an account.
    */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
    * @return the amount of purchased tokens of an account.
    */
    function tokensPurchased(address account) public view returns (uint256) {
        return _purchasedTokens[account];
    }

    /**
    * @notice Withdraw bought tokens
    */
    function withdrawTokens() public afterRelease {
        uint amount = _balances[msg.sender];
        require(amount <= withdrawableBalance(msg.sender), "Sale: locked");
        require(amount != 0, "Sale: Your balance is 0");
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        IERC20(token).safeTransfer(msg.sender, amount);
        emit TokensWithdrawn(msg.sender, amount);
    }

    /**
    * @notice amount of tokens available to withdraw at current time
    * @param user Address of account
    */
    function withdrawableBalance(address user) public view returns (uint256) {
        uint256 availableBalance = _balances[user];
        if ((block.timestamp >= tokenListingTime && tokenListingTime != 0) || released == true) {
            return availableBalance;
        } else {
            return 0;
        }
    }

    function changeSaleStart(uint256 _startTime) public onlyOwner {
        require(block.timestamp < startTime, "Sale: started");
        startTime = _startTime;
        emit StartChanged(startTime);
    }

    function setListingTime(uint256 _listingTime) public onlyOwner {
        require(block.timestamp <= _listingTime, "Sale: listing time should be greather than current time");
        tokenListingTime = _listingTime;
        emit SetListingTime(tokenListingTime);

    }

    function changeSaleDuration(uint256 _saleDuration) public onlyOwner {
        require(block.timestamp <= tokenSaleEndTime(), "Sale: ended");
        tokenSaleDuration = _saleDuration;
        emit TokenSaleDurationChanged(_saleDuration);
    }

    function release() public onlyOwner {
        require(block.timestamp >= tokenSaleEndTime(), "Sale: not ended");
        released = true;
        emit TokenReleased(released);
    }

    function withdrawBusd() external onlyOwner {
        withdrawBusdPartially(IERC20(busdAddress).balanceOf(address(this)));
    }

    function withdrawNotSoldTokens() external onlyOwner {
        require(block.timestamp >= tokenSaleEndTime(), "Sale: only after sale");
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(wallet, balance.sub(tokensSold));
    }

    function getBusdBalance() public view onlyOwner returns(uint256){
        return IERC20(busdAddress).balanceOf(address(this));
    }

    /**
     * Withdraw BUSD from the sale contract after sale is ended
     * param busdAmountWei amount to withdraw in wei
     */
    function withdrawBusdPartially(uint256 busdAmountWei) public onlyOwner {
        require(IERC20(busdAddress).balanceOf(address(this)) >= busdAmountWei, "Not enough funds");
        IERC20(busdAddress).approve(address(this), busdAmountWei);
        IERC20(busdAddress).transferFrom(address(this), wallet, busdAmountWei);
    }

    function changeWallet(address _to) public onlyOwner {
        require(_to != address(0), "change wallet: to the zero address");
        wallet = payable(_to);
    }

    function setMaxBuyAmountToken(uint256 _tokenAmountWei) public onlyOwner {
        require(_tokenAmountWei <= cap && _tokenAmountWei > 0, "Sale: maxBuyAmount must not exceed the cap and must be greater than zero");
        maxBuyAmount = _tokenAmountWei;
    }

    function setMaxBuyAmountBUSD(uint _busdAmountWei) public onlyOwner {
        uint256 _tokenAmount = calculatePurchaseAmount(_busdAmountWei);
        require(_tokenAmount <= cap && _tokenAmount > 0, "Sale: maxBuyAmount must not exceed the cap and must be greater than zero");
        maxBuyAmount = _tokenAmount;
    }

    /**
    * @notice Update _allocations for addresses with new amounts
    */
    function updateAllocations(address[] calldata addresses, uint256[] calldata amounts) public onlyOwner {

        for(uint256 i = 0; i < addresses.length; i++) {
            uint256 amount = amounts[i];
            address investor = addresses[i];
            _allocations[investor] = amount;
        }
    }

    /**
    * @notice Reset _allocations for addresses to 0
    */
    function resetAllocations(address[] calldata addresses) public onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            delete _allocations[addresses[i]];
        }
    }

    /**
    * @notice enables/disables personal allocation checking for buyTokens
    */
    function enablePersonalAllocation(bool _bool) public onlyOwner {
        personalAllocation = _bool;
    }

    /**
    * @notice Get allocation for address
    */
    function allocationOf(address investor) public view returns (uint256) {
        if (personalAllocation) {
            return _allocations[investor];
        } else {
            require(maxBuyAmount > 0, "Allocation: maxBuyAmount should be defined if personal allocation is off");
            return maxBuyAmount;
        }
        
    }
}