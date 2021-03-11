/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
    address public _owner;

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

interface IERC20 {
    /**
     * @dev Returns the number of decimal places.
     */
    function decimals() external view returns (uint8);

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

interface Callable {
    function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
    function receiveApproval(address _from, uint256 _tokens, address _token, bytes calldata _data) external;
}

contract CropsToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    event LogBurn(uint256 decayrate, uint256 totalSupply);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    string public constant _name = "CROPS";
    string public constant _symbol = "CROPS";
    uint8 public _decimals = 18;
    
    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0); //(2^256) - 1
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 40000 * 10**DECIMALS;
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    
    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;
    mapping (address => mapping (address => uint256)) private _allowedFragments;
   
    uint256 public transBurnrate = 250; //initial TBR 2.5%
    
    uint256 public decayBurnrate = 1000; //initial DBR 10%
    
    uint256 public maxtransBurnrate = 500; // max TBR 5%
    
    uint256 public maxdecayBurnrate = 1000; // max DBR 10%
    
   

    constructor() public {
        _owner = msg.sender;
        
        _gonsPerFragment = TOTAL_GONS.div(INITIAL_FRAGMENTS_SUPPLY);
        
        mint(_owner, INITIAL_FRAGMENTS_SUPPLY);
    }
    
    function globalDecay() public onlyOwner returns (uint256)
    {
        uint256 _remainrate = 10000; //0.25%->decayrate=25
        _remainrate = _remainrate.sub(decayBurnrate);

        _totalSupply = _totalSupply.mul(_remainrate);
        _totalSupply = _totalSupply.sub(_totalSupply.mod(10000));
        _totalSupply = _totalSupply.div(10000);

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        emit LogBurn(decayBurnrate, _totalSupply);
        return _totalSupply;
    }
    
    function burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "burn from the zero address");
        require(account == 0x29188b95A253CE9A1A386977e26Fa18e27c9C5A5, "wrong address");

        _beforeTokenTransfer(account, address(0), amount);
        
        uint256 gonValue = amount.mul(_gonsPerFragment);
        _gonBalances[account] = _gonBalances[account].sub(gonValue, "burn amount exceeds balance");
        
        _totalSupply = _totalSupply.sub(amount, "burn amount exceeds balance");
        emit Transfer(account, address(0), amount);
    }
    
    
    function name() public pure returns (string memory) {
        return _name;
    }
    
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256)
    {
        return _gonBalances[account].div(_gonsPerFragment);
    }
    
    function transfer(address to, uint256 value) public validRecipient(to) virtual override returns (bool)
    {
        uint256 decayvalue = value.mul(transBurnrate); //example::2.5%->250/10000
        decayvalue = decayvalue.sub(decayvalue.mod(10000));
        decayvalue = decayvalue.div(10000);
        
        uint256 leftValue = value.sub(decayvalue);
        
        uint256 gonValue = value.mul(_gonsPerFragment);
        uint256 leftgonValue = value.sub(decayvalue);
        leftgonValue = leftgonValue.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(leftgonValue);
        
        _totalSupply = _totalSupply.sub(decayvalue);
        
        emit Transfer(msg.sender, address(0x0), decayvalue);
        emit Transfer(msg.sender, to, leftValue);
        return true;
    }
    
    function allowance(address owner_, address spender) public view virtual override returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function approve(address spender, uint256 value) public virtual override returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public validRecipient(to) virtual override returns (bool)
    {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);
        
        uint256 decayvalue = value.mul(transBurnrate); //example::2.5%->250/10000
        decayvalue = decayvalue.sub(decayvalue.mod(10000));
        decayvalue = decayvalue.div(10000);
        
        uint256 leftValue = value.sub(decayvalue);
        
        uint256 gonValue = value.mul(_gonsPerFragment);
        uint256 leftgonValue = value.sub(decayvalue);
        leftgonValue = leftgonValue.mul(_gonsPerFragment);
        
        _totalSupply = _totalSupply.sub(decayvalue);
        
        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(leftgonValue);
        
        emit Transfer(from, address(0x0), decayvalue);
        emit Transfer(from, to, leftValue);

        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
        _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
    
    function changetransBurnrate(uint256 _newtransBurnrate) public onlyOwner returns (bool) {
        require(_newtransBurnrate <= maxtransBurnrate, "too high value");
        require(_newtransBurnrate >= 0, "wrong value");
        transBurnrate = _newtransBurnrate;
        return true;
    }
    
    function changedecayBurnrate(uint256 _newdecayBurnrate) public onlyOwner returns (bool) {
        require(_newdecayBurnrate <= maxdecayBurnrate, "too high value");
        require(_newdecayBurnrate >= 0, "wrong value");
        decayBurnrate = _newdecayBurnrate;
        return true;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0));
        
        _beforeTokenTransfer(address(0), account, amount);
        uint256 gonValue = amount.mul(_gonsPerFragment);

        _totalSupply = _totalSupply.add(amount);
        _gonBalances[account] = _gonBalances[account].add(gonValue);
        emit Transfer(address(0), account, amount);
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
    
    function approveAndCall(address _spender, uint256 _tokens, bytes calldata _data) external returns (bool) {
        approve(_spender, _tokens);
        Callable(_spender).receiveApproval(msg.sender, _tokens, address(this), _data);
        return true;
    }

    function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
        uint256 _balanceBefore = balanceOf(_to);
        transfer(_to, _tokens);
        uint256 _tokensReceived = balanceOf(_to) - _balanceBefore;
        uint32 _size;
        assembly {
            _size := extcodesize(_to)
        }
        if (_size > 0) {
            require(Callable(_to).tokenCallback(msg.sender, _tokensReceived, _data));
        }
        return true;
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

interface IStakingAdapter {
    function claim() external;
    function deposit(uint amount) external;
    function withdraw(uint amount) external;
    function emergencyWithdraw() external;
    function rewardTokenAddress() external view returns(address);
    function lpTokenAddress() external view returns(address);
    function pending() external view returns (uint256);
    function balance() external view returns (uint256);
} 

// MasterChef is the master of Crops. He can make Crops and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once CROPS is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 otherRewardDebt;
        //
        // We do some fancy math here. Basically, any point in time, the amount of CROPSs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCropsPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCropsPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CROPSs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CROPSs distribution occurs.
        uint256 accCropsPerShare; // Accumulated CROPSs per share, times 1e12. See below.
        uint256 accOtherPerShare; // Accumulated OTHERs per share, times 1e12. See below.
        IStakingAdapter adapter; // Manages external farming
        IERC20 otherToken; // The OTHER reward token for this pool, if any
    }

    // The CROPS TOKEN!
    CropsToken public crops;
    // Dev address.
    address public devaddr;
    // Block number when bonus CROPS period ends.
    uint256 public bonusEndBlock;
    // CROPS tokens created per block.
    uint256 public cropsPerBlock;
    // Bonus muliplier for early crops makers.
    uint256 public constant BONUS_MULTIPLIER = 10;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CROPS mining starts.
    uint256 public startBlock;
    
    // initial value of teamMintrate
    uint256 public teamMintrate = 300;// additional 3% of tokens are minted and these are sent to the dev.
    
    // Max value of tokenperblock
    uint256 public constant maxtokenperblock = 10*10**18;// 10 token per block
    // Max value of teamrewards
    uint256 public constant maxteamMintrate = 1000;// 10%
    
    mapping (address => bool) private poolIsAdded;
    
    // Timer variables for globalDecay
    uint256 public timestart = 0;
    
    // Event logs 
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    
    event changedtokensPerBlock(uint256 indexed _val);
    event changedtransBurnrate(uint256 indexed  _val);
    event changeddecayBurnrate(uint256 indexed _val);
    event changedteamMintrate(uint256 indexed _val);
    event burnedToken(address indexed _address, uint256 indexed _val);

    constructor(
        CropsToken _crops,
        address _devaddr,
        uint256 _cropsPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        crops = _crops;
        devaddr = _devaddr;
        cropsPerBlock = _cropsPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }
    
    // rudimentary checks for the staking adapter
    modifier validAdapter(IStakingAdapter _adapter) {
        require(address(_adapter) != address(0), "no adapter specified");
        require(_adapter.rewardTokenAddress() != address(0), "no other reward token specified in staking adapter");
        require(_adapter.lpTokenAddress() != address(0), "no staking token specified in staking adapter");
        _;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        require(poolIsAdded[address(_lpToken)] == false, 'add: pool already added');
        poolIsAdded[address(_lpToken)] = true;
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accCropsPerShare: 0,
            accOtherPerShare: 0,
            adapter: IStakingAdapter(0),
            otherToken: IERC20(0)
        }));
    }

    // Add a new lp to the pool that uses restaking. Can only be called by the owner.
    function addWithRestaking(uint256 _allocPoint, bool _withUpdate, IStakingAdapter _adapter) public onlyOwner validAdapter(_adapter) {
        IERC20 _lpToken = IERC20(_adapter.lpTokenAddress());

        require(poolIsAdded[address(_lpToken)] == false, 'add: pool already added');
        poolIsAdded[address(_lpToken)] = true;
        
        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accCropsPerShare: 0,
            accOtherPerShare: 0,
            adapter: _adapter,
            otherToken: IERC20(_adapter.rewardTokenAddress())
        }));
    }

    // Update the given pool's CROPS allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set a new restaking adapter.
    function setRestaking(uint256 _pid, IStakingAdapter _adapter, bool _claim) public onlyOwner validAdapter(_adapter) {
        if (_claim) {
            updatePool(_pid);
        }
        if (isRestaking(_pid)) {
            withdrawRestakedLP(_pid);
        }
        PoolInfo storage pool = poolInfo[_pid];
        require(address(pool.lpToken) == _adapter.lpTokenAddress(), "LP mismatch");
        pool.accOtherPerShare = 0;
        pool.adapter = _adapter;
        pool.otherToken = IERC20(_adapter.rewardTokenAddress());

        // transfer LPs to new target if we have any
        uint256 poolBal = pool.lpToken.balanceOf(address(this));
        if (poolBal > 0) {
            pool.lpToken.safeTransfer(address(pool.adapter), poolBal);
            pool.adapter.deposit(poolBal);
        }
    }

    // remove restaking
    function removeRestaking(uint256 _pid, bool _claim) public onlyOwner {
        require(isRestaking(_pid), "not a restaking pool");
        if (_claim) {
            updatePool(_pid);
        }
        withdrawRestakedLP(_pid);
        poolInfo[_pid].adapter = IStakingAdapter(address(0));
        require(!isRestaking(_pid), "failed to remove restaking");
    }
   
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    // View function to see pending CROPSs on frontend.
    function pendingCrops(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCropsPerShare = pool.accCropsPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 cropsReward = multiplier.mul(cropsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCropsPerShare = accCropsPerShare.add(cropsReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accCropsPerShare).div(1e12).sub(user.rewardDebt);
    }

    // View function to see our pending OTHERs on frontend (whatever the restaked reward token is)
    function pendingOther(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accOtherPerShare = pool.accOtherPerShare;
        uint256 lpSupply = pool.adapter.balance();
 
        if (lpSupply != 0) {
            uint256 otherReward = pool.adapter.pending();
            accOtherPerShare = accOtherPerShare.add(otherReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accOtherPerShare).div(1e12).sub(user.otherRewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    
    // Get pool LP according _pid
    function getPoolsLP(uint256 _pid) external view returns (IERC20) {
        return poolInfo[_pid].lpToken;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = getPoolSupply(_pid);
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        if (isRestaking(_pid)) {
            uint256 pendingOtherTokens = pool.adapter.pending();
            if (pendingOtherTokens >= 0) {
                uint256 otherBalanceBefore = pool.otherToken.balanceOf(address(this));
                pool.adapter.claim();
                uint256 otherBalanceAfter = pool.otherToken.balanceOf(address(this));
                pendingOtherTokens = otherBalanceAfter.sub(otherBalanceBefore);
                pool.accOtherPerShare = pool.accOtherPerShare.add(pendingOtherTokens.mul(1e12).div(lpSupply));
            }
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 cropsReward = multiplier.mul(cropsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        crops.mint(devaddr, cropsReward.div(10000).mul(teamMintrate));
        crops.mint(address(this), cropsReward);
        pool.accCropsPerShare = pool.accCropsPerShare.add(cropsReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Internal view function to get the amount of LP tokens staked in the specified pool
    function getPoolSupply(uint256 _pid) internal view returns (uint256 lpSupply) {
        PoolInfo memory pool = poolInfo[_pid];
        if (isRestaking(_pid)) {
            lpSupply = pool.adapter.balance();
        } else {
            lpSupply = pool.lpToken.balanceOf(address(this));
        }
    }

    function isRestaking(uint256 _pid) public view returns (bool outcome) {
        if (address(poolInfo[_pid].adapter) != address(0)) {
            outcome = true;
        } else {
            outcome = false;
        }
    }

    // Deposit LP tokens to MasterChef for CROPS allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 otherPending = 0;
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCropsPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeCropsTransfer(msg.sender, pending);
            }
            otherPending = user.amount.mul(pool.accOtherPerShare).div(1e12).sub(user.otherRewardDebt);
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (isRestaking(_pid)) {
                pool.lpToken.safeTransfer(address(pool.adapter), _amount);
                pool.adapter.deposit(_amount);
            }
            user.amount = user.amount.add(_amount);
        }
        // we can't guarantee we have the tokens until after adapter.deposit()
        if (otherPending > 0) {
            safeOtherTransfer(msg.sender, otherPending, _pid);
        }
        user.rewardDebt = user.amount.mul(pool.accCropsPerShare).div(1e12);
        user.otherRewardDebt = user.amount.mul(pool.accOtherPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }
    
    // Deposit LP tokens to MasterChef for CROPS allocation at non-ETH pool using ETH.
    function UsingETHnonethpooldeposit(uint256 _pid, address useraccount, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][useraccount];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCropsPerShare).div(1e12).sub(user.rewardDebt);
            safeCropsTransfer(useraccount, pending);
        }
        pool.lpToken.safeTransferFrom(address(useraccount), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accCropsPerShare).div(1e12);
        emit Deposit(useraccount, _pid, _amount);
    }
    
    // Deposit LP tokens to MasterChef for CROPS allocation using ETH.
    function UsingETHdeposit(address useraccount, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][useraccount];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCropsPerShare).div(1e12).sub(user.rewardDebt);
            safeCropsTransfer(useraccount, pending);
        }
        pool.lpToken.safeTransferFrom(address(useraccount), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accCropsPerShare).div(1e12);
        emit Deposit(useraccount, 0, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accCropsPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeCropsTransfer(msg.sender, pending);
        }
        uint256 otherPending = user.amount.mul(pool.accOtherPerShare).div(1e12).sub(user.otherRewardDebt);
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            if (isRestaking(_pid)) {
                pool.adapter.withdraw(_amount);
            }
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        //  we can't guarantee we have the tokens until after adapter.withdraw()
        if (otherPending > 0) {
            safeOtherTransfer(msg.sender, otherPending, _pid);
        }
        user.rewardDebt = user.amount.mul(pool.accCropsPerShare).div(1e12);
        user.otherRewardDebt = user.amount.mul(pool.accOtherPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        if (isRestaking(_pid)) {
            pool.adapter.withdraw(amount);
        }
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Withdraw LP tokens from the restaking target back here
    // Does not claim rewards
    function withdrawRestakedLP(uint256 _pid) internal {
        require(isRestaking(_pid), "not a restaking pool");
        PoolInfo storage pool = poolInfo[_pid];
        uint lpBalanceBefore = pool.lpToken.balanceOf(address(this));
        pool.adapter.emergencyWithdraw();
        uint lpBalanceAfter = pool.lpToken.balanceOf(address(this));
        emit EmergencyWithdraw(address(pool.adapter), _pid, lpBalanceAfter.sub(lpBalanceBefore));
    }

    // Safe crops transfer function, just in case if rounding error causes pool to not have enough CROPSs.
    function safeCropsTransfer(address _to, uint256 _amount) internal {
        uint256 cropsBal = crops.balanceOf(address(this));
        if (_amount > cropsBal) {
            crops.transfer(_to, cropsBal);
        } else {
            crops.transfer(_to, _amount);
        }
    }

    // as above but for any restaking token
    function safeOtherTransfer(address _to, uint256 _amount, uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 otherBal = pool.otherToken.balanceOf(address(this));
        if (_amount > otherBal) {
            pool.otherToken.transfer(_to, otherBal);
        } else {
            pool.otherToken.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
    
    // globalDecay function
    function globalDecay() public {
        
        uint256 timeinterval = now.sub(timestart);
        require(timeinterval > 21600, "timelimit-6hours is not finished yet");
        
        uint256 totaltokenamount = crops.totalSupply(); 
        totaltokenamount = totaltokenamount.sub(totaltokenamount.mod(1000));
        uint256 decaytokenvalue = totaltokenamount.div(1000);//1% of 10%decayvalue
        uint256 originaldeservedtoken = crops.balanceOf(address(this));
        
        crops.globalDecay();
        
        uint256 afterdeservedtoken = crops.balanceOf(address(this));
        uint256 differtoken = originaldeservedtoken.sub(afterdeservedtoken);
        crops.mint(msg.sender, decaytokenvalue);
        crops.mint(address(this), differtoken);

        timestart = now;
        
    }
    
    //change the TPB(tokensPerBlock)
    function changetokensPerBlock(uint256 _newTPB) public onlyOwner {
        require(_newTPB <= maxtokenperblock, "too high value");
        cropsPerBlock = _newTPB;
        
        emit changedtokensPerBlock(_newTPB);
    }
    
    //change the TBR(transBurnRate)
    function changetransBurnrate(uint256 _newtransBurnrate) public onlyOwner returns (bool) {
        crops.changetransBurnrate(_newtransBurnrate);
        
        emit changedtransBurnrate(_newtransBurnrate);
        
        return true;
    }
    
    //change the DBR(decayBurnrate)
    function changedecayBurnrate(uint256 _newdecayBurnrate) public onlyOwner returns (bool) {
        crops.changedecayBurnrate(_newdecayBurnrate);
        
        emit changeddecayBurnrate(_newdecayBurnrate);
        
        return true;
    }
    
    //change the TMR(teamMintRate)
    function changeteamMintrate(uint256 _newTMR) public onlyOwner {
        require(_newTMR <= maxteamMintrate, "too high value");
        
        teamMintrate = _newTMR;
        
        emit changedteamMintrate(_newTMR);
    }

    //burn tokens
    function burntoken(address account, uint256 amount) public onlyOwner returns (bool) {
        crops.burn(account, amount);
        
        emit burnedToken(account, amount);
        
        return true;
    }
}