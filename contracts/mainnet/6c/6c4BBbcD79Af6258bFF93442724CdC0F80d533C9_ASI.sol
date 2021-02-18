// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract ASI is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _mock;
    mapping(address => uint256) private _scores;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private constant _totalSupply = 10 * 10**6 * 10**18;
    uint256 private constant _antiBotsPeriod = 45;

    uint256 private _totalFees;
    uint256 private _totalScores;
    uint256 private _rate;

    mapping(address => bool) private _exchanges;
    mapping(address => uint256) private _lastTransactionPerUser;

    string private _name = 'asi.finance';
    string private _symbol = 'ASI';
    uint8 private _decimals = 18;

    constructor() public {
        _balances[_msgSender()] = _totalSupply;
        _exchanges[_msgSender()] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // ERC20 STRUCTURE

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_exchanges[account]) return _balances[account];

        return _calculateBalance(account);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance'));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero'));
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

        if (_exchanges[sender] && !_exchanges[recipient]) {
            _transferFromExchangeToUser(sender, recipient, amount);
        }
        else if (!_exchanges[sender] && _exchanges[recipient]) {
            _transferFromUserToExchange(sender, recipient, amount);
        }
        else if (!_exchanges[sender] && !_exchanges[recipient]) {
            _transferFromUserToUser(sender, recipient, amount);
        }
        else if (_exchanges[sender] && _exchanges[recipient]) {
            _transferFromExchangeToExchange(sender, recipient, amount);
        } else {
            _transferFromUserToUser(sender, recipient, amount);
        }
    }

    // SETTERS

    function _transferFromExchangeToUser(
        address exchange,
        address user,
        uint256 amount
    ) private {
        require(_calculateBalance(exchange) >= amount, 'ERC20: transfer amount exceeds balance');

        (uint256 fees,, uint256 scoreRate, uint256 amountSubFees) = _getWorth(_calculateBalance(user).add(amount), user, amount, true);

        _balances[exchange] = _calculateBalance(exchange).sub(amount);
        _balances[user] = _calculateBalance(user).add(amountSubFees);

        _reScore(user, scoreRate);
        _reRate(fees);
        _lastTransactionPerUser[user] = block.number;

        emit Transfer(exchange, user, amount);
    }

    function _transferFromUserToExchange(
        address user,
        address exchange,
        uint256 amount
    ) private {
        require(_calculateBalance(user) >= amount, 'ERC20: transfer amount exceeds balance');

        (uint256 fees,, uint256 scoreRate, uint256 amountSubFees) = _getWorth(_calculateBalance(user), user, amount, true);

        _balances[exchange] = _calculateBalance(exchange).add(amountSubFees);
        _balances[user] = _calculateBalance(user).sub(amount);

        _reScore(user, scoreRate);
        _reRate(fees);
        _lastTransactionPerUser[user] = block.number;

        emit Transfer(user, exchange, amount);
    }

    function _transferFromUserToUser(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(_calculateBalance(sender) >= amount, 'ERC20: transfer amount exceeds balance');

        (uint256 fees,, uint256 senderScoreRate, uint256 amountSubFees) = _getWorth(_calculateBalance(sender), sender, amount, true);
        (,, uint256 recipientScoreRate,) = _getWorth(_calculateBalance(recipient).add(amount), recipient, amount, false);

        _balances[recipient] = _calculateBalance(recipient).add(amountSubFees);
        _balances[sender] = _calculateBalance(sender).sub(amount);

        _reScore(sender, senderScoreRate);
        _reScore(recipient, recipientScoreRate);
        _reRate(fees);
        _lastTransactionPerUser[sender] = block.number;

        emit Transfer(sender, recipient, amount);
    }

    function _transferFromExchangeToExchange(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(_calculateBalance(sender) >= amount, 'ERC20: transfer amount exceeds balance');

        _balances[sender] = _calculateBalance(sender).sub(amount);
        _balances[recipient] = _calculateBalance(recipient).add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _reScore(address account, uint256 score) private {
        _totalScores = _totalScores.sub(_scores[account]);
        _scores[account] = _balances[account].mul(score);
        _mock[account] = _scores[account].mul(_rate).div(1e18);
        _totalScores = _totalScores.add(_scores[account]);
    }

    function _reRate(uint256 fees) private {
        _totalFees = _totalFees.add(fees);
        if(_totalScores > 0)
            _rate = _rate.add(fees.mul(1e18).div(_totalScores));
    }

    function setExchange(address account) public onlyOwner() {
        require(!_exchanges[account], 'Account is already exchange');

        _balances[account] = _calculateBalance(account);
        _totalScores = _totalScores.sub(_scores[account]);
        _scores[account] = 0;
        _exchanges[account] = true;
    }

    function removeExchange(address account) public onlyOwner() {
        require(_exchanges[account], 'Account not exchange');

        (,, uint256 scoreRate,) = _getWorth(_calculateBalance(account), account, _calculateBalance(account), false);
        _balances[account] = _calculateBalance(account);
        if (scoreRate > 0) _reScore(account, scoreRate);
        _exchanges[account] = false;
    }

    // PUBLIC GETTERS

    function getScore(address account) public view returns (uint256) {
        return _scores[account];
    }

    function getTotalScores() public view returns (uint256) {
        return _totalScores;
    }

    function getTotalFees() public view returns (uint256) {
        return _totalFees;
    }

    function isExchange(address account) public view returns (bool) {
        return _exchanges[account];
    }

    function getTradingFees(address account) public view returns (uint256) {
        (, uint256 feesRate,,) = _getWorth(_calculateBalance(account), account, 0, true);
        return feesRate;
    }

    function getLastTransactionPerUser(address account) public view returns (uint256) {
        return _lastTransactionPerUser[account];
    }

    // PRIVATE GETTERS

    function _getWorth(
        uint256 balance,
        address account,
        uint256 amount,
        bool antiBots
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 fees;
        uint256 feesRate;
        uint256 scoreRate;

        uint256 _startCategory = 500 * 10**18;

        if (balance < _startCategory) {
            feesRate = 120;
            fees = amount.mul(feesRate).div(10000);
            scoreRate = 10;
        } else if (balance >= _startCategory && balance < _startCategory.mul(10)) {
            feesRate = 110;
            fees = amount.mul(feesRate).div(10000);
            scoreRate = 100;
        } else if (balance >= _startCategory.mul(10) && balance < _startCategory.mul(50)) {
            feesRate = 100;
            fees = amount.mul(feesRate).div(10000);
            scoreRate = 110;
        } else if (balance >= _startCategory.mul(50) && balance < _startCategory.mul(100)) {
            feesRate = 90;
            fees = amount.mul(feesRate).div(10000);
            scoreRate = 120;
        } else if (balance >= _startCategory.mul(100) && balance < _startCategory.mul(200)) {
            feesRate = 75;
            fees = amount.mul(feesRate).div(10000);
            scoreRate = 130;
        } else if (balance >= _startCategory.mul(200)) {
            feesRate = 50;
            fees = amount.mul(feesRate).div(10000);
            scoreRate = 140;
        } else {
            feesRate = 100;
            fees = amount.mul(feesRate).div(10000);
            scoreRate = 0;
        }

        if (antiBots == true && block.number < _lastTransactionPerUser[account].add(_antiBotsPeriod)) {
            feesRate = 500;
            fees = amount.mul(feesRate).div(10000);
        }
        uint256 amountSubFees = amount.sub(fees);

        return (fees, feesRate, scoreRate, amountSubFees);
    }

    function _calculateFeesForUser(address account) private view returns (uint256) {
        return _scores[account] > 0 ? _scores[account].mul(_rate).div(1e18).sub(_mock[account]) : 0;
    }

    function _calculateBalance(address account) private view returns (uint256) {
        return _calculateFeesForUser(account) > 0 ? _calculateFeesForUser(account).add(_balances[account]) : _balances[account];
    }
}

// SPDX-License-Identifier: MIT

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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