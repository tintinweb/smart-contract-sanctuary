/**
 *Submitted for verification at polygonscan.com on 2021-08-05
*/

// SPDX-License-Identifier: MIT

//PolyDefy Website : https://polydefy.live
//PolyDefy Telegram : https://t.me/polydefy


pragma solidity 0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

contract PolyDefy is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    
    string  private constant _NAME = "PolyDefy";
    string  private constant _SYMBOL = "PFY";
    uint8   private constant _DECIMALS = 18;
   
    uint256 private constant _MAX = ~uint256(0);
    uint256 private constant _DECIMALFACTOR = 10 ** uint256(_DECIMALS);
    uint256 private constant _GRANULARITY = 100;
    
    uint256 private _tTotal = 1 * 10**5 * _DECIMALFACTOR;
    uint256 private _rTotal = (_MAX - (_MAX % _tTotal));
    
    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;
    
    uint256 private constant     _TAX_FEE = 150;
    uint256 private constant    _BURN_FEE = 200;
    uint256 private constant    _FARM_FEE = 400;
    uint256 private constant     _ILI_FEE = 200;    
    uint256 private constant     _DEV_FEE = 50;
    uint256 private constant _MAX_TX_SIZE = 100000 * _DECIMALFACTOR;
    
    address public WDev;
    address public WFarm;
    address public WPfyIli;
    address public WPfymaster;
    address public WFree;
    bool public TakeFee;
    
    event NewDeveloper(address);
    
    modifier onlyDev() {
        require(msg.sender == owner() || msg.sender == WDev , "Error: Require developer or Owner");
        _;
    }

    constructor (address _WPfyIli, address _WDev, address _WFarm, bool _takeFee)
        public {
        _rOwned[_msgSender()] = _rTotal;
        WPfyIli = _WPfyIli;
        WDev = _WDev;
        WFarm = _WFarm;
        TakeFee = _takeFee;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _NAME;
    }

    function symbol() public pure returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
    function setWPfyIli(address _WPfyIli)public onlyDev returns (bool){
        WPfyIli = _WPfyIli;
         return true;
    }

    function setWPfymaster(address _pfymaster)public onlyDev returns (bool){
        WPfymaster = _pfymaster;
         return true;
    }
    
    function setWFree(address _wfree)public onlyDev returns (bool){
        WFree = _wfree;
         return true;
    }
    
    function setDev(address _Wdev) external onlyDev {
        WDev = _Wdev ;
        emit NewDeveloper(_Wdev);
    }
    
    function setTakeFee(bool _takefee)public onlyDev returns (bool){
        TakeFee = _takefee;
         return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
    
    function burn(uint256 tAmount) public {
        
        address sender = _msgSender();
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(tAmount > 0, "Transfer amount must be greater than zero");

        uint256 currentRate =  _getRate();
        uint256 rAmount =  tAmount.mul(currentRate);
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tBurnTotal = _tBurnTotal.add(tAmount);
        _tTotal = _tTotal.sub(tAmount);
        
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
    //    require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(sender != owner() && recipient != owner())
            require(amount <= _MAX_TX_SIZE, "Transfer amount exceeds the maxTxAmount.");
        
        if(TakeFee){
        
        if (sender == WFarm || sender == WPfymaster || sender == WDev || sender == WPfyIli || sender == WFree) {
            _transferFromPfy(sender, recipient, amount);
        } else if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        } }
        else {
             _transferFromPfy(sender, recipient, amount);
        }
   }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        (, uint256 rFarm, uint256 rDev) = _getValues3(tAmount);
        _rOwned[WDev] = _rOwned[WDev].add(rDev);
        _rOwned[WFarm] = _rOwned[WFarm].add(rFarm);
        (uint256 rIli,) = _getIli(tAmount);
        _rOwned[WPfyIli] = _rOwned[WPfyIli].add(rIli);
        _reflectFee(rFee, rBurn, rDev, rFarm, rIli, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        (, uint256 rFarm, uint256 rDev) = _getValues3(tAmount);
        _rOwned[WDev] = _rOwned[WDev].add(rDev);
        _rOwned[WFarm] = _rOwned[WFarm].add(rFarm);
        (uint256 rIli,) = _getIli(tAmount);
        _rOwned[WPfyIli] = _rOwned[WPfyIli].add(rIli);
        _reflectFee(rFee, rBurn, rDev, rFarm, rIli, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        (, uint256 rFarm, uint256 rDev) = _getValues3(tAmount);
        _rOwned[WDev] = _rOwned[WDev].add(rDev);
        _rOwned[WFarm] = _rOwned[WFarm].add(rFarm);
        (uint256 rIli,) = _getIli(tAmount);
        _rOwned[WPfyIli] = _rOwned[WPfyIli].add(rIli);
        _reflectFee(rFee, rBurn, rDev, rFarm, rIli, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        (, uint256 rFarm, uint256 rDev) = _getValues3(tAmount);
        _rOwned[WDev] = _rOwned[WDev].add(rDev);
        _rOwned[WFarm] = _rOwned[WFarm].add(rFarm);
        (uint256 rIli,) = _getIli(tAmount);
        _rOwned[WPfyIli] = _rOwned[WPfyIli].add(rIli);
        _reflectFee(rFee, rBurn, rDev, rFarm, rIli, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferFromPfy(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        
//transferfromexcluded

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        } 
        
//transferToExcluded
        
        else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        } 
        
//transferStandard
        
        else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        }
        
//transferBothExcluded        
        
        else if (_isExcluded[sender] && _isExcluded[recipient]) {
            
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        } 
        
//transferStandard        
        
        else {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        } 

       emit Transfer(sender, recipient, tAmount);
    }

    function _reflectFee(uint256 rFee, uint256 rBurn, uint256 rDev, uint256 rFarm, uint256 rIli, uint256 tFee, uint256 tBurn) private {
        _rTotal = _rTotal.sub(rFee).add(rDev).add(rFarm).add(rIli).sub(rBurn);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
        _tTotal = _tTotal.sub(tBurn);
    }
    
    

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getTValues(tAmount, _BURN_FEE);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tBurn, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn);
    }

    function _getTValues(uint256 tAmount, uint256 burnFee) private view returns (uint256, uint256, uint256) {

        uint256 tBurn = ((tAmount.mul(burnFee)).div(_GRANULARITY)).div(100);
        (,,,uint256 tTax, uint256 tFarm, uint256 tDev) = _getValues2(tAmount);
        (, uint256 tIli) = _getIli(tAmount);
        uint256 tFee = tTax.add(tFarm).add(tDev).add(tIli);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn);
        return (tTransferAmount, tFee, tBurn);
    }

    function _getRValues(uint256 tAmount, uint256 tBurn, uint256 currentRate) private view returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        
        uint256 rBurn = tBurn.mul(currentRate);
        (uint256 rTax, uint256 rFarm, uint256 rDev, , , ) = _getValues2(tAmount);
        (uint256 rIli,) = _getIli(tAmount);
        uint256 rFee = rTax.add(rFarm).add(rDev).add(rIli);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getValues2(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tFarm, uint256 tDev, uint256 tTax) = _getTValues2(tAmount, _FARM_FEE, _DEV_FEE, _TAX_FEE);
        uint256 currentRate =  _getRate();
        (uint256 rFarm, uint256 rDev, uint256 rTax) = _getRValues2(tTax, tFarm, tDev, currentRate);
        return (rTax, rFarm, rDev, tTax, tFarm, tDev);
    }
    
    function _getValues3(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        ( uint256 rTax, uint256 rFarm, uint256 rDev,,,) = _getValues2(tAmount);
        return (rTax, rFarm, rDev);
    }

    function _getTValues2(uint256 tAmount, uint256 farmFee, uint256 devFee, uint256 taxFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFarm = ((tAmount.mul(farmFee)).div(_GRANULARITY)).div(100);
        uint256 tDev = ((tAmount.mul(devFee)).div(_GRANULARITY)).div(100);
        uint256 tTax = ((tAmount.mul(taxFee)).div(_GRANULARITY)).div(100);
        return (tFarm, tDev, tTax);
    }

    function _getRValues2(uint256 tTax, uint256 tFarm, uint256 tDev, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rFarm = tFarm.mul(currentRate);
        uint256 rDev = tDev.mul(currentRate);
        uint256 rTax = tTax.mul(currentRate);
        return (rFarm, rDev, rTax);
    }
    
    function _getIli(uint256 tAmount) private view returns (uint256, uint256) {
        (uint256 tIli) = _getTIli(tAmount, _ILI_FEE);
        uint256 currentRate =  _getRate();
        (uint256 rIli) = _getRIli(tIli, currentRate);
        return (rIli, tIli);
    }
    
    function _getTIli(uint256 tAmount, uint256 iliFee) private pure returns (uint256) {
        uint256 tIli = ((tAmount.mul(iliFee)).div(_GRANULARITY)).div(100);
        return (tIli);
    }

    function _getRIli(uint256 tIli, uint256 currentRate) private pure returns (uint256) {
        uint256 rIli = tIli.mul(currentRate);
        return (rIli);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    

    
}

// PfyMaster is the master of Pfy. Even he can not make PFY but he is a fair guy. :D
//
// Have fun reading it. Hopefully it's bug-free.

interface ImpermanentLossInsurance{
	//IMPERMANENT LOSS INSURANCE ABI
    function add(address _lpToken, IERC20 _token0, IERC20 _token1, bool _offerILI) external; 
    function set(uint256 _pid, address _lpToken, IERC20 _token0,IERC20 _token1, bool _offerILI) external;
    function getDepositValue(uint256 amount, uint256 _pid) external view returns (uint256 userDepValue);
    function pfyTransfer(address _to, uint256 _amount) external;
    function getPfyPrice() external view returns (uint256 pfyPrice);
}

contract PfyMaster is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
		uint256 depositTime;
		uint256 depVal;
        //
        // We do some fancy math here. Basically, any point in time, the amount of Pfy
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accpfyPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accpfyPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Pfy to distribute per block.
        uint256 lastRewardBlock; // Last block number that Pfy distribution occurs.
        uint256 accpfyPerShare; // Accumulated PFY per share, times 1e18. See below.
		IERC20 token0;
		IERC20 token1;
		bool impermanentLossInsurance;
    }

    // The PFY TOKEN!
    PolyDefy public pfy;
    // Dev address.
    address public devaddr;
	//ILI Contract
    ImpermanentLossInsurance public ili;
	//farmsender
    address public farmsender;
    // pfy tokens distributed per block.
    uint256 public pfyPerBlock;
    // Bonus muliplier for early pfy makers.
    uint256 public BONUS_MULTIPLIER = 1;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when pfy mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    
    modifier onlyDev() {
        require(msg.sender == owner() || msg.sender == devaddr , "Error: Require developer or Owner");
        _;
    }

    constructor(
        PolyDefy _pfy,
        address _devaddr
    ) public {
        pfy = _pfy;
        devaddr = _devaddr;
    }
	
	function setImpermanentLossInsurance(address _ili)public onlyDev returns (bool){
        ili = ImpermanentLossInsurance(_ili);
    }
    
    function setFarmsender(address _farmsender)public onlyDev returns (bool){
        farmsender = _farmsender;
         return true;
    }

	function getUserInfo(uint256 pid, address userAddr) 
		public 
		view 
		returns(uint256 deposit, uint256 rewardDebt, uint256 daysSinceDeposit, uint256 depVal)
	{
		UserInfo storage user = userInfo[pid][userAddr];
		return (user.amount, user.rewardDebt, _getDaysSinceDeposit(pid, userAddr), user.depVal);
	}
    
    function updateReward(uint256 reward) public {
       require(msg.sender == farmsender || msg.sender == owner(), "Only Farmsender or Dev can do this");
        pfyPerBlock = reward.div(24*60*24);
    }
    
    function setstartblock(uint256 sblock) public onlyOwner{
        startBlock = sblock;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyDev {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
		IERC20 _token0,
		IERC20 _token1,
		bool _offerILI,
        bool _withUpdate
    ) public onlyDev {
        if (_withUpdate) {
            massUpdatePools();
        }
		ili.add(address(_lpToken), _token0, _token1, _offerILI);
        
		uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accpfyPerShare: 0,
				token0: _token0,
				token1: _token1,
				impermanentLossInsurance: _offerILI
            })
        );
    }

    // Update the given pool's PFY allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        address _lpToken,
		IERC20 _token0,
		IERC20 _token1,
		bool _offerILI,
        bool _withUpdate
    ) public onlyDev {
        if (_withUpdate) {
            massUpdatePools();
        }
		ili.set(_pid, _lpToken, _token0, _token1, _offerILI);
		
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
		poolInfo[_pid].token0 =_token0;
		poolInfo[_pid].token1 = _token1;
        poolInfo[_pid].allocPoint = _allocPoint;
		poolInfo[_pid].impermanentLossInsurance = _offerILI;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending PFY on frontend.
    function pendingpfy(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accpfyPerShare = pool.accpfyPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 pfyReward =
                multiplier.mul(pfyPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accpfyPerShare = accpfyPerShare.add(
                pfyReward.mul(1e18).div(lpSupply)
            );
        }
        return user.amount.mul(accpfyPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 pfyReward =
            multiplier.mul(pfyPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
 
            pool.accpfyPerShare = pool.accpfyPerShare.add(
                pfyReward.mul(1e18).div(lpSupply)
            );
            pool.lastRewardBlock = block.number;
            return;
        
    }

    // Deposit LP tokens to PfyMaster for PFY allocation.
    function deposit(uint256 _pid, uint256 _amount) 
	public 
	{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
		
		uint256 xfAmt = _amount;
		if(xfAmt > pool.lpToken.balanceOf(msg.sender))
			xfAmt = pool.lpToken.balanceOf(msg.sender);
		
		//ILI
		uint256 extraPfy = 0;
		if(pool.impermanentLossInsurance)
			if(user.amount > 0)
				if(_getDaysSinceDeposit(_pid, msg.sender) >= 30)
					extraPfy = _checkForIL(_pid, user);
		
        if(user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accpfyPerShare).div(1e18).sub(user.rewardDebt);
			
			if (pending > 0)
				safepfyTransfer(msg.sender, pending);
			if(extraPfy > 0 && extraPfy > pending)
				ili.pfyTransfer(msg.sender, extraPfy.sub(pending));
			
        }
        if(xfAmt > 0) {
			pool.lpToken.safeTransferFrom(address(msg.sender), address(this), xfAmt);
            user.amount = user.amount.add(xfAmt);
        }
		
		user.depVal = ili.getDepositValue(user.amount, _pid);
		user.depositTime = block.timestamp;
        user.rewardDebt = user.amount.mul(pool.accpfyPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, xfAmt);
    }

    // Withdraw LP tokens from PfyMaster.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
		require(user.amount > 0, "Nothing deposited.");
		
		uint256 xfAmt = _amount;
		if(xfAmt > user.amount)
			xfAmt = user.amount;
		
		uint256 extraPfy = 0;
		if(pool.impermanentLossInsurance){
			if(_getDaysSinceDeposit(_pid, msg.sender) >= 30){
				extraPfy = _checkForIL(_pid, user);
			}
		}

        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accpfyPerShare).div(1e18).sub(
                user.rewardDebt
            );
			if (pending > 0)
				safepfyTransfer(msg.sender, pending);
			if(extraPfy > 0 && extraPfy > pending)
				ili.pfyTransfer(msg.sender, extraPfy.sub(pending));
			
        if(xfAmt > 0) {
            user.amount = user.amount.sub(xfAmt);
            pool.lpToken.safeTransfer(address(msg.sender), xfAmt);
        }
		
		user.depVal = ili.getDepositValue(user.amount, _pid);
		user.depositTime = block.timestamp;
        user.rewardDebt = user.amount.mul(pool.accpfyPerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, xfAmt);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe Pfy transfer function, just in case if rounding error causes pool to not have enough PFY.
    function safepfyTransfer(address _to, uint256 _amount) internal {
        pfy.transfer(_to, _amount);
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
		
	//Time Functions
    function getDaysSinceDeposit(uint256 pid, address userAddr)
        external
        view
        returns (uint256 daysSinceDeposit)
    {
        return _getDaysSinceDeposit(pid, userAddr);
    }
    function _getDaysSinceDeposit(uint256 _pid, address _userAddr)
        internal
        view
        returns (uint256)
    {
		UserInfo storage user = userInfo[_pid][_userAddr];
		
        if (block.timestamp < user.depositTime){	
             return 0;	
        }else{	
             return (block.timestamp.sub(user.depositTime)) / 1 days;	
        }
    }
	
    function checkForIL(uint256 pid, address userAddr)
        external
        view
        returns (uint256 extraPfy)
    {
		UserInfo storage user = userInfo[pid][userAddr];
		return _checkForIL(pid, user);
    }
    function _checkForIL(uint256 _pid, UserInfo storage user)
        internal
        view
        returns (uint256)
    {
		uint256 pfyPrice = ili.getPfyPrice();
		uint256 currentVal = ili.getDepositValue(user.amount, _pid);
		
		if(currentVal < user.depVal){
			uint256 difference = user.depVal.sub(currentVal);
			return difference.div(pfyPrice);
		}else return 0;
    }
}

contract PfyFarmsender is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The PFY TOKEN!
    PolyDefy public pfy;

    // Dev address.
    address public devaddr;
    
    //Wfarm wallet
    address public wfarm ;
    
    //Pfymaster wallet
   PfyMaster public pfymaster ;

 
    event Sendfarm();


    constructor(
        PolyDefy _pfy,
        address _devaddr,
        address _wfarm,
        PfyMaster _pfymaster

    ) public {
        pfy = _pfy;
        devaddr = _devaddr;
        wfarm = _wfarm;
        pfymaster = _pfymaster;
    }
    



    // Send tokens from Wfarm.
    function sendfarm() public {

        require(msg.sender == devaddr || msg.sender == owner() , "only dev");
        
        uint256 wfarmbal=pfy.balanceOf(wfarm);

        pfy.transferFrom(wfarm,address(pfymaster), wfarmbal);
        pfymaster.updateReward(wfarmbal);
        
        emit Sendfarm();
        
    }


    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr || msg.sender == owner() , "dev: wut?");
        devaddr = _devaddr;
    }
}