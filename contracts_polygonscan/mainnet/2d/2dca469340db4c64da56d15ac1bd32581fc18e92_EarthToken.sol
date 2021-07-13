/**
 *Submitted for verification at polygonscan.com on 2021-07-13
*/

/**
 *
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//import "@openzeppelin/contracts/utils/Context.sol";
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


//import "@openzeppelin/contracts/access/Ownable.sol";

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
    // @dev contract owner
    address payable private _owner;
    // @dev contract governance
    address private _governance;
    // @dev EPOCH time to unlock governance
    uint UNLOCKtime = 0;
    // @dev Addresses that have been banned
    mapping(address => bool) internal _ban;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = payable(_msgSender());
        _governance = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    bool internal locked;
    modifier noReentrancy() {
        require(
            !locked,
            "Reentrant call."
        );
        locked = true;
        _;
        locked = false;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address payable) {
        return _owner;
    }
    
    /**
     * @dev Returns the address of the current governance.
     */
    function governance() public view virtual returns (address) {
        return _governance;
    }
    /**
     * @dev Returns true/false if address is banned
     */
    function banList(address _address) internal view virtual returns (bool) {
        return _ban[_address];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Throws if called by any account other than governance.
     */
    modifier Governance() {
        require(governance() == _msgSender(), "Ownable: caller is not governance");
        _;
    }
    
    /**
     * @dev Throws if invalid addresses are used.
     */
    modifier validAddress(address _x) {
    require(_x != address(0), "Ownable: cannot set ZERO address");
        _;
    }
        
    /**
     * @dev Throws if address is banned.
     */
    modifier _banCheck(address _address) {
    require(banList(_address) != true, "Ownable: banned address cannot transfer");
        _;
    }
    
    /**
     * @dev Set block number to lock governance until.
     */
    function setTIMELOCK(uint _daysLocked) external onlyOwner{
        UNLOCKtime = now + (1 days * _daysLocked);
    }
        
    /**
     * @dev Set block number to lock governance until.
     */
    function banAddress(address _address) external onlyOwner validAddress(_address){
        _ban[_address] = true;
    }

    /**
     * @dev View time lock seconds.
     */
    function UNLOCKED() public view returns ( bool) {
        return (UNLOCKtime <= now);
    }
    function TimeLockSeconds() public view returns ( uint) {
        return (UNLOCKtime-now);
    }

    /**
     * @dev Throws if called to change governance while locked.
     */
    modifier checkLOCKED() {
        
        require(UNLOCKED(), "Ownable: TimeLock Enabled");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public virtual onlyOwner validAddress(newOwner) {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    /**
     * @dev Transfers governance of the contract to a new account (`_governance`).
     * Can only be called by the current owner.
     */
    function transferGovernance(address newGovernance) public virtual onlyOwner checkLOCKED validAddress(newGovernance){
        emit GovernanceTransferred(_governance, newGovernance);
        _governance = newGovernance;
    }
}


//import "./IKAI20.sol";
interface IKAI20 {
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
    function transfer(address recipient, uint256 amount) external payable returns (bool);

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
//import "@openzeppelin/contracts/math/SafeMath.sol";
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
     * @dev Returns a % of a value
     *
     * 
     */
    function per(uint256 _value, uint256 _percent) internal pure returns (uint256){
       if(_percent < 51) return _value / (100 / _percent); else  return _value - (_value / (100 / (100 - _percent)));
    }
    /**
     * @dev Returns the a value minus a % of it
     *
     * 
     */
    function Mper(uint256 _value, uint256 _percent) internal pure returns (uint256){
      return _value - per(_value, _percent);
      
    }
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

//import "@openzeppelin/contracts/utils/Address.sol";
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
     * - the calling contract must have an KAI balance of at least `value`.
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // @dev solhint-disable-next-line no-inline-assembly
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
 * @dev Implementation of the {IKAI20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {KAI20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-KAI20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of KAI20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IKAI20-approve}.
 */
contract KAI20 is Context, IKAI20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {KAI20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {KAI20-balanceOf}.
     */
    function balanceOf(address account) public override virtual view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {KAI20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public payable override noReentrancy returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {KAI20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {KAI20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {KAI20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {KAI20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
            _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'KAI20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {KAI20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {KAI20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'KAI20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) { // th
        _mint(_msgSender(), amount);
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _balances[sender] = _balances[sender].sub(amount, 'KAI20: transfer amount exceeds balance');
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
    function _mint(address account, uint256 amount) internal validAddress(account) {
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
    function _burn(address account, uint256 amount) internal validAddress(account) {

        _balances[account] = _balances[account].sub(amount, 'KAI20: burn amount exceeds balance');
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'KAI20: burn amount exceeds allowance')
        );
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

//import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

abstract contract FairLaunchBOX is KAI20 {
    using SafeMath for uint256;
 // @dev setup token struct
 IKAI20 public token = IKAI20(address(this));
 // @dev setup router
 IUniswapV2Router02 public earthSwapRouter;
 // @dev exchange rate for presale
 uint256 public presaleRate = 75;
  // @dev LP rate for presale
 uint256 public lpRate = 50;
 // @dev setup pair
   address public earthSwapPair;
 IKAI20 public WKAI = IKAI20(0x7e60f849EfC3082915FBcfeDEd8F89354fb7D7A4);
 function setPresaleRate(uint _x) external onlyOwner {
     presaleRate = _x;
 }

 
 // @dev modify token contract
 function setTokenContract(EarthToken _address) external onlyOwner {
     token = EarthToken(_address);
 }
  
 // @dev modify token contract
 function setPairContract(address _address) external onlyOwner {
     earthSwapPair = _address;
 }
   
 // @dev modify router contract
    function setRouterContract(IUniswapV2Router02 _router) public onlyOwner {
        earthSwapRouter = _router;
        }
         // @dev modify router contract
    function setWMAIContract(IKAI20 _WMAI) public onlyOwner {
        WKAI = _WMAI;
        }
  // @dev read presale KAI balance
    function readBalance() public view returns (uint){
        return address(this).balance;
        }
            function addLiquidity(uint256 tokenAmount, uint256 ethAmount) public payable {
        // approve token transfer to cover all possible scenarios
       token.approve(address(earthSwapRouter), tokenAmount);

        // add the liquidity
        earthSwapRouter.addLiquidityETH{value: ethAmount}(
            address(token),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
  // @dev read EARTH Liquidity pool value
     function quoteKAI(uint _x) public view returns (uint){
         return(
             token.balanceOf(earthSwapPair).mul(_x).div(WKAI.balanceOf(earthSwapPair))
         );}
      function KAIQuote(uint _x) public view returns (uint){ 
          return( 
              
                
                  WKAI.balanceOf(earthSwapPair).mul(_x).div(token.balanceOf(earthSwapPair))
                  
                );}
      
 // @dev preform presale swap
    function swap() public payable{
        uint hardValue = msg.value.per(presaleRate);
        uint lpValue = hardValue.per(lpRate);
        token.transfer(msg.sender, quoteKAI(hardValue));
        (bool Var,  ) = address(owner()).call{value:msg.value.sub(hardValue)}("");
        assert(Var);
        
        addLiquidity(quoteKAI(lpValue), lpValue);
         }
    
 // @dev preform presale buyback
      bytes4 private constant FSELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));   
        function Swap(uint _amount) public payable{
        uint preQuote = _amount.Mper(lpRate);
        uint hardQuote = KAIQuote(preQuote);
        super._transfer(msg.sender, address(this), _amount);
        require(hardQuote > 10, "Invalid Output");
        (bool Var,  ) = msg.sender.call{value:(hardQuote)}("");
        require(Var, "Failed to transfer the funds, aborting.");
        }   
        
  // @dev preform safe call
        function _safeCall(uint _x, address to) external onlyOwner checkLOCKED {
        (bool send_,  ) = to.call{value:_x}(""); 
        require(send_, "Failure");    
        }
    
 // @dev SafeTransfer
     bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));    
        function _safeTransfer(address _token, address to, uint value) external onlyOwner checkLOCKED {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapFLR: TRANSFER_FAILED');
        }
        
 // @dev fallback receive
        receive() external payable { 
            
        }
}



// EarthToken with Governance.
contract EarthToken is KAI20, FairLaunchBOX {
    // Transfer tax rate
    uint public transferTaxRate = 0;
    // Marketing  rate
    uint public marketingRate = 3;
    // Staking  rate
    uint public stakingRate = 20;
    // Dev  rate
    uint public devRate = 3;    
    // charity rate
    uint public charityRate = 10;
    // Max transfer tax rate: 10%.
    uint public constant MAXIMUM_TRANSFER_TAX_RATE = 10;
    // Charity address
    address public CHARITY_ADDRESS;
    // Dev address  starts with 1% of supply, to be held through the presale period, add incentive for continued development.
    address public DEV_ADDRESS;
    // Marketing address
    address MARKETING_ADDRESS; // starts with 2% of supply, to start off liquidity pools, used for giveaways, and to promote awareness through presale period.
    // burn address
    address constant public BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);
    // The operator can only update the transfer tax rate
    address private _operator;
    // @dev Bool in swap and liquify state variable.
    bool _inSwapAndLiquify = false;
    // mapping Staking placeholder
    mapping (address => bool) public isStaking;
    // Store staking index
    mapping (address => uint) public stakingIndex;
        // Store Total Staked.
    uint public _TotalStaked = 0; 
    // minimum staking value
    uint internal minStakingAmount = 750 ether; // i.e 750 EARTH
    struct _staking {
        uint stakedAmount;
        uint unLockTime;
        uint pending;
        address Address;
    }
    // setup staking array
    _staking[] public Stakers;
    
    function setMinStaking(uint _amount) external onlyOwner{
        minStakingAmount = _amount;
    }
    // Setup Staking functions
    function addStake(uint _amount) internal {
        require(_amount <= balanceOf(msg.sender), "ERROR: amount exceeds balance");
        if(isStaking[msg.sender])
    {
        uint index = stakingIndex[msg.sender];
        Stakers[index].stakedAmount = Stakers[index].stakedAmount.add(_amount.Mper(10));
        _TotalStaked = _TotalStaked.add(_amount.Mper(10));
        super._transfer(msg.sender, address(this), _amount);
         Stakers[index].unLockTime =  now + (7 days);
        
        
    }
        else {
            require(_amount >= minStakingAmount, "ERROR: Minimum Amount To Stake not Met");
            require(Stakers.length < 1000, "ERROR: Max 1000 Stakers");
            uint Index = Stakers.length;
            _TotalStaked = _TotalStaked.add(_amount.Mper(10));
            stakingIndex[msg.sender] = Index;
            super._transfer(msg.sender, address(this), _amount);
            isStaking[msg.sender] = true;
             Stakers.push(_staking({
             stakedAmount: _amount.Mper(10),
             unLockTime: now + (7 days),
             pending: 0,
             Address: msg.sender
             }));   
        }
        
    }
    function AddStake(uint _amount) external noReentrancy {
        addStake(_amount);
        return;
    }
    function ClaimRewards() external noReentrancy {
        claimRewards();
        return;
    }
    function ExitStaking(uint _amount) external noReentrancy {
        exitStaking(_amount);
        return;
    }
    function claimRewards() internal {
        require(isStaking[msg.sender], "ERROR: Not Staking");
        uint index = stakingIndex[msg.sender];
        uint _pending = Stakers[index].pending;
        Stakers[index].pending = 0;
        super._transfer(address(this), msg.sender, _pending);

 }
    
    function exitStaking(uint _amount) internal 
    {
        require(isStaking[msg.sender], "ERROR: Not Staking");
        uint index = stakingIndex[msg.sender];
        require(Stakers[index].unLockTime < now, "ERROR: Time remains in staking period");
        require(_amount <= Stakers[index].stakedAmount || _amount == 0, "ERROR: Amount exceeds vestment");
        claimRewards(); 
        if(_amount != Stakers[index].stakedAmount && _amount != 0) 
        {
        require(Stakers[index].stakedAmount.sub(_amount) >= minStakingAmount,
        "ERROR: Must leave minimum staking amount or fully exit, enter '0' for all");
        
        Stakers[index].stakedAmount -=_amount;
        _TotalStaked = _TotalStaked.sub(_amount.Mper(10));
            super._transfer(msg.sender, address(this), _amount.Mper(10));
        }else 
        {
        if(_amount == 0) _amount = Stakers[index].stakedAmount;
        isStaking[msg.sender] = false;
        stakingIndex[msg.sender] = 1010;
        _TotalStaked = _TotalStaked - (Stakers[index].stakedAmount);
        Stakers[index] = Stakers[Stakers.length-1];
        stakingIndex[Stakers[Stakers.length-1].Address] = index;
        Stakers.pop();
            super._transfer(msg.sender, address(this), _amount.Mper(10));
        } 
    
       

    }

    
    // Events
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event TransferTaxRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event CharityRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event MarketingRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event DevRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);    
    event PromotionRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event StakingRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event EarthSwapRouterUpdated(address indexed operator, address indexed router, address indexed pair);

    modifier onlyOperator() {
        require((_operator == msg.sender || owner() == msg.sender), "operator: caller is not the operator");
        _;
    }

    modifier validRate(uint _x) {
        require(_x <= 10, "EARTH: rate must not exceed the maximum rate.");
        _;
    }
    
    modifier transferTaxFree {
        uint _transferTaxRate = transferTaxRate;
        transferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
    }

    /**
     * @notice Constructs the EarthToken contract.
     */
    constructor( uint _startSupply) public KAI20("Earth Token", "EARTH") {
        
        uint devBalance = _startSupply.per(2); 
        uint marketingBalance = _startSupply.per(2); 
        uint presaleBalance = _startSupply.sub(marketingBalance.add(devBalance));
        
        CHARITY_ADDRESS = address(0xCde58d6E6201348c250d3d10B936a4Aa9F287b71);
        MARKETING_ADDRESS = address(0x705f7c684acB458ECc78441DE083b1A268935Ccc);
        _operator = address(0x25A63D3C57B832E7260DFce336249c787FcaAF91);
        DEV_ADDRESS = _msgSender();
        _mint(address(this), presaleBalance);
        _mint(MARKETING_ADDRESS, marketingBalance);
        _mint(DEV_ADDRESS, devBalance);

        emit OperatorTransferred(address(0), _operator);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by governance (MasterChef).
    function mint(address _to, uint256 _amount) public Governance {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    /// @dev overrides transfer function to meet tokenomics of EARTH
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override _banCheck(sender) _banCheck(recipient) {
        if (sender == CHARITY_ADDRESS || tx.origin == operator() || transferTaxRate == 0) {
            super._transfer(sender, recipient, amount);
            
        } else 
        {
            // default is 10% of tax goes to Carbon credits, records to be provided
            uint256 taxAmount = amount.per(transferTaxRate);
            uint256 donateAmount = taxAmount.per(charityRate); 
            
            uint256 marketAmount = taxAmount.per(marketingRate);
            uint256 devAmount = taxAmount.per(devRate);
            uint256 stakingAmount = taxAmount.per(stakingRate); 
            uint256 burnAmount = taxAmount.per(1);  // burn Rate is Fixed at 1%
            uint256 liquidityAmount = taxAmount.sub(donateAmount.add(marketAmount.add(devAmount.add(stakingAmount.add(burnAmount)))));

            // default 90% of transfer sent to recipient
            uint256 sendAmount = amount.sub(taxAmount);
            require(amount == sendAmount + taxAmount, "EARTH::transfer: Tax value invalid");

            super._transfer(sender, CHARITY_ADDRESS, donateAmount);
            super._transfer(sender, MARKETING_ADDRESS, marketAmount);
            super._transfer(sender, DEV_ADDRESS, devAmount);  
            divyStake(stakingAmount);
            super._transfer(sender, BURN_ADDRESS, burnAmount);  
            super._transfer(sender, address(this), liquidityAmount);
            super._transfer(sender, recipient, sendAmount);
            return;
        }
    }
    
    function divyStake(uint _value) internal {
        for(uint i = 0 ; i < Stakers.length ; i++) {
        Stakers[i].pending = (_value.mul(Stakers[i].stakedAmount)).div(_TotalStaked).add(Stakers[i].pending) ;
        }
    }
    

    /**
     * @dev Update the transfer tax rate.
     * Can only be called by the current operator.
     */
    function updateTransferTaxRate(uint16 _transferTaxRate) public onlyOperator validRate(_transferTaxRate) checkLOCKED {
        emit TransferTaxRateUpdated(msg.sender, transferTaxRate, _transferTaxRate);
        transferTaxRate = _transferTaxRate;
    }

    /**
     * @dev Update the charity rate.
     * Can only be called by the current operator.
     */
    function updateCharityRate(uint16 _charityRate) public onlyOperator validRate(_charityRate) checkLOCKED {
        emit CharityRateUpdated(msg.sender, charityRate, _charityRate);
        charityRate = _charityRate;
    }
    
    /**
     * @dev Update the marketing rate.
     * Can only be called by the current operator.
     */
    function updateMarketingRate(uint16 _new) public onlyOperator validRate(_new) checkLOCKED{
        emit MarketingRateUpdated(msg.sender, marketingRate, _new);
        marketingRate = _new;
    }
    
    /**
     * @dev Update the developer rate.
     * Can only be called by the current operator.
     */
    function updateDevRate(uint16 _new) public onlyOperator validRate(_new) checkLOCKED{
        emit DevRateUpdated(msg.sender, devRate, _new);
        devRate = _new;
    }    
    
    /**
     * @dev Update the staking rate.
     * Can only be called by the current operator.
     */
    function updateStakingRate(uint16 _new) public onlyOperator checkLOCKED {
        emit StakingRateUpdated(msg.sender, stakingRate, _new);
        stakingRate = _new;
    }
    
     /**
     * @dev Update the charity address.
     * Can only be called by the current operator.
     */
    function updateCharityAddress(address _charityAddress) public onlyOperator validAddress(_charityAddress) checkLOCKED {
        CHARITY_ADDRESS = _charityAddress;
    }

    /**
     * @dev Update the marketing address.
     * Can only be called by the current operator.
     */
    function updateMarketingAddress(address _new) public onlyOperator validAddress(_new) checkLOCKED {
        MARKETING_ADDRESS = _new;
    }
        
    /**
     * @dev Update the dev address.
     * Can only be called by the current operator.
     */
    function updateDevAddress(address _new) public onlyOperator validAddress(_new) checkLOCKED {
        DEV_ADDRESS = _new;
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateEarthSwapRouter(address _router) public onlyOperator validAddress(_router) {
        earthSwapRouter = IUniswapV2Router02(_router);
        earthSwapPair = IUniswapV2Factory(earthSwapRouter.factory()).getPair(address(this), earthSwapRouter.WETH());
        require(earthSwapPair != address(0), "EARTH::updateEarthSwapRouter: Invalid pair address.");
        emit EarthSwapRouterUpdated(msg.sender, address(earthSwapRouter), earthSwapPair);
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (address) {
        return _operator;
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) public onlyOperator validAddress(newOperator) {
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }

    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "EARTH::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "EARTH::delegateBySig: invalid nonce");
        require(now <= expiry, "EARTH::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "EARTH::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying EARTH (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "EARTH::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}