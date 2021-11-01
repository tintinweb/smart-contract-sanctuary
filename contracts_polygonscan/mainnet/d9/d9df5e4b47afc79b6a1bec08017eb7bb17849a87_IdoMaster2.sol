/**
 *Submitted for verification at polygonscan.com on 2021-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
        assembly {
            codehash := extcodehash(account)
        }
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeERC20: decreased allowance below zero'
        );
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

        bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
        }
    }
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
    constructor() {}

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
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
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
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
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address payable) {
        return payable(_owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface PriceFeedRouter {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract IdoMaster2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
      uint256 tokenAmount;
      uint256 contributed;
      uint256 referralBonus;
      bool whitelisted;
      bool participated;
      address referrer;
    }

    struct IdoInfo {
        bool hasWhitelist;
        bool claimStarted;
        bool refundInitiated;
        uint256 referralPercent;
        uint256 supply; // total token for sale
        uint256 min; // min contribution
        uint256 max; // maximum contribution
        uint256 rate; // tokens per bnb
        uint256 allocated; // total token sold
        uint256 weiRaised;
        uint256 startBlock;
        uint256 endBlock;
    }

    // Info of each ido.

    IERC20[] public idos;
    mapping (IERC20 => IdoInfo) public idoInfo;
    
    // Info of each user that participates in sale.
    mapping (IERC20 => mapping (address => UserInfo)) public userInfo;
    
    event Deposit(address indexed user, IERC20 indexed token, uint256 amount);
    event Claim(address indexed user, IERC20 indexed token, uint256 amount);
    event Refund(address indexed user, IERC20 indexed token, uint256 amount);
    event Withdraw(address indexed owner, IERC20 indexed token, uint256 amount);

    constructor() {}

    receive() external payable {
        revert();
    }

    function idoLength() external view returns (uint256) {
        return idos.length;
    }

    function add(IERC20 _address, uint256 _supply, uint256 _rate, uint256 _min, uint256 _max, uint256 _startBlock, uint256 _endBlock, uint256 _referralPercent, bool _hasWhitelist) public onlyOwner {
        require(!inIdo(_address), "Token already in Ido");

        idoInfo[_address] = IdoInfo({
            hasWhitelist: _hasWhitelist,
            referralPercent: _referralPercent,
            supply: _supply,
            rate: _rate,
            min: _min,
            max: _max,
            startBlock: _startBlock,
            endBlock: _endBlock,
            weiRaised: 0,
            allocated: 0,
            claimStarted: false,
            refundInitiated: false
        });

        idos.push(_address);
    }

    function inIdo(IERC20 _token) public view returns(bool status) {
        for (uint i = 0; i < idos.length; i++) {

            if (idos[i] == _token) {
                status = true;
                break;
            }
        }
    }

    function isActive(IERC20 _token) public view returns(bool status) {
        IdoInfo memory ido = idoInfo[_token];

        if (block.number >= ido.startBlock && block.number < ido.endBlock) {
            status = true;
        }
    }

    function setStartBlock(IERC20 _token, uint256 _startBlock) external onlyOwner {
        idoInfo[_token].startBlock = _startBlock;
    }

    function setEndBlock(IERC20 _token, uint256 _endBlock) external onlyOwner {
        idoInfo[_token].endBlock = _endBlock;
    }

    function setRate(IERC20 _token, uint256 _rate) external onlyOwner {
        idoInfo[_token].rate = _rate;
    }

    function setMin(IERC20 _token, uint256 _min) external onlyOwner {
        idoInfo[_token].min = _min;
    }

    function setMax(IERC20 _token, uint256 _max) external onlyOwner {
        idoInfo[_token].max = _max;
    }

    function setSupply(IERC20 _token, uint256 _supply) external onlyOwner {
        idoInfo[_token].supply = _supply;
    }
    
    function setReferralPercent(IERC20 _token, uint256 _referralPercent) external onlyOwner {
        idoInfo[_token].referralPercent = _referralPercent;
    }
    
    function setWhitelist(IERC20 _token, bool _hasWhitelist) external onlyOwner {
        idoInfo[_token].hasWhitelist = _hasWhitelist;
    }
    
    function startRefund(IERC20 _token) external onlyOwner {
        require(!idoInfo[_token].claimStarted, "Claim started!");
        idoInfo[_token].refundInitiated = true;
    }
    
    function stopRefund(IERC20 _token) external onlyOwner {
        idoInfo[_token].refundInitiated = false;
    }
    
    function startClaim(IERC20 _token) external onlyOwner {
        require(!idoInfo[_token].refundInitiated, "Refunding!");
        idoInfo[_token].claimStarted = true;
    }
    
    function stopClaim(IERC20 _token) external onlyOwner {
        idoInfo[_token].claimStarted = false;
    }

    function takeWei(IERC20 _token, uint256 _amount) external onlyOwner {
        IdoInfo storage ido = idoInfo[_token];

        require(ido.claimStarted, "Claim not started");
        require(!ido.refundInitiated, "Refunding");
        require(_amount <= ido.weiRaised, "Bad amount");

        emit Withdraw(owner(), _token, _amount);
        ido.weiRaised = ido.weiRaised.sub(_amount);
        owner().transfer(_amount);
    }
    
    function takeDustWei() external onlyOwner {
        bool hasPendingIdoFund = false;
        
        for (uint i = 0; i < idos.length; i++) {

            if (idoInfo[idos[i]].weiRaised > 0) {
                hasPendingIdoFund = true;
                break;
            }
        }
        
        require(!hasPendingIdoFund, "Ido funds!");
        owner().transfer(address(this).balance);
    }
    
    function withdrawToken(IERC20 _token, uint256 _amount) public onlyOwner {
        require(_token.balanceOf(address(this)) >= _amount, "Not enough balance");
        _token.safeTransfer(owner(), _amount);
    }

    function whitelistMe(IERC20 _token) external {
        require(!isActive(_token), "Active");
        userInfo[_token][_msgSender()].whitelisted = true;
    }
    
    function giveReferralBonus(IERC20 _token, address _referrer, uint256 _purchased, uint256 _percent) internal {
        uint256 bonus = _percent.mul(_purchased).div(100);
        userInfo[_token][_referrer].referralBonus = userInfo[_token][_referrer].referralBonus.add(bonus);
    }
    
    function deposit(IERC20 _token, address _referrer) public payable {
        IdoInfo storage ido = idoInfo[_token];
        UserInfo storage user = userInfo[_token][_msgSender()];

        uint256 amount = msg.value;
        bool whitelistPassed = ido.hasWhitelist ? user.whitelisted : !ido.hasWhitelist;
        
        require(_msgSender() == owner() || whitelistPassed, "Not whitelisted");
        require(isActive(_token), "Inactive");
        require(!ido.claimStarted, "Claim started");
        require(!ido.refundInitiated, "Refunding");
        require(amount >= ido.min, "Less than minimum purchase");
        require(user.contributed.add(amount) <= ido.max, "Cummulative more than maximum purchase");

        uint256 tokenAmount = amount.mul(ido.rate).div(1 ether);

        require(ido.allocated.add(tokenAmount) <= ido.supply, "Filled");
        
        address referrer = _referrer == _msgSender() ? address(0) : _referrer;
        
        user.contributed = user.contributed.add(amount);
        user.tokenAmount = user.tokenAmount.add(tokenAmount);
        user.referrer = referrer;
        user.participated = true;
        
        ido.weiRaised = ido.weiRaised.add(amount);
        ido.allocated = ido.allocated.add(tokenAmount);
        
        emit Deposit(_msgSender(), _token, amount);
        
        if (referrer != address(0)) giveReferralBonus(_token, referrer, tokenAmount, ido.referralPercent);
        
    }

    function claim(IERC20 _token) external {
        IdoInfo storage ido = idoInfo[_token];
        UserInfo storage user = userInfo[_token][_msgSender()];

        require(!ido.refundInitiated, "Refunding");
        require(ido.claimStarted, "Claim not started");
        uint256 tokenToBeSent = user.tokenAmount;
        
        user.contributed = 0;
        user.tokenAmount = 0;
        
        emit Claim(_msgSender(), _token, tokenToBeSent);
        _token.safeTransfer(_msgSender(), tokenToBeSent);
    }
    
    function claimReferralBonus(IERC20 _token) external {
        IdoInfo storage ido = idoInfo[_token];
        UserInfo storage user = userInfo[_token][_msgSender()];
        
        require(user.participated, "Not a participant");
        require(!ido.refundInitiated, "Refunding");
        require(ido.claimStarted, "Claim not started");
        
        uint256 tokenToBeSent = user.referralBonus;
        user.referralBonus = 0;
        
        emit Claim(_msgSender(), _token, tokenToBeSent);
        _token.safeTransfer(_msgSender(), tokenToBeSent);
        
    }

    function refund(IERC20 _token) external {
        IdoInfo storage ido = idoInfo[_token];
        UserInfo storage user = userInfo[_token][_msgSender()];

        require(!ido.claimStarted, "Claim started");
        require(ido.refundInitiated, "Not refunding");
        
        uint256 weiToBeSent = user.contributed;
        uint256 tokenAllocated = user.tokenAmount;
        
        user.contributed = 0;
        user.tokenAmount = 0;
        
        ido.weiRaised = ido.weiRaised.sub(weiToBeSent);
        ido.allocated = ido.allocated.sub(tokenAllocated);

        emit Refund(_msgSender(), _token, weiToBeSent);
        _msgSender().transfer(weiToBeSent);
    }
}