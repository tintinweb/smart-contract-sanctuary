/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.9;

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
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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


contract Ownable is Context {
    
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract WindSwap is Context, IBEP20, Ownable {

    struct Transaction {
        bool enabled;
        address destination;
        bytes data;
    }

    Transaction[] public transactions;
    using SafeMath for uint256;
    using Address for address;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;
    mapping (address => uint256) private _bOwned;
    mapping (address => uint256) private _qOwned;
    address[] private _excluded;
    
    string  private constant _NAME = 'WindSwap';
    string  private constant _SYMBOL = 'WINDY';
    uint8   private constant _DECIMALS = 8;
    uint256 private constant _MAX = ~uint256(0);
    uint256 private constant _CORRECTDECIMALS = 10 ** uint256(_DECIMALS);
    uint256 private constant _GRANULARITY = 100;
    uint256 private _qTotal = 25000000 * _CORRECTDECIMALS;
    uint256 private _bTotal = (_MAX - (_MAX % _qTotal));
    uint256 private _qLevyTotal;
    uint256 private _qBurnTotal;
    uint256 private _WindSwapRotations = 0;
    uint256 private _qTradeRotations = 0;
    uint256 private _qBurnRotations = 0;
    uint256 private transferredWindSwap = 0;
    uint256 private countOfWindSwap = 0;
    uint256 private burn_factor = 0;
    uint256 private levy_factor = 0;
    uint256 private constant _MAX_RT_SIZE = 25000000 * _CORRECTDECIMALS;
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1  
    uint256 private _gonsPerFragment;
    
    mapping(address => uint256) private _gonBalances;

    constructor () public {
        _bOwned[_msgSender()] = _bTotal;
        emit Transfer(address(0), _msgSender(), _qTotal);
    }

    event TransactionFailed(address indexed destination, uint index, bytes data);

    function name() public view returns (string memory) {
        return _NAME;
    }

    function symbol() public view returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public view returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _qTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _qOwned[account];
        return tokenFromReflection(_bOwned[account]);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalLevies() public view returns (uint256) {
        return _qLevyTotal;
    }
    
    function totalBurn() public view returns (uint256) {
        return _qBurnTotal;
    }

    function deliver(uint256 qAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 bAmount,,,,,) = _getValues(qAmount);
        _bOwned[sender] = _bOwned[sender].sub(bAmount);
        _bTotal = _bTotal.sub(bAmount);
        _qLevyTotal = _qLevyTotal.add(qAmount);
    }

    function reflectionFromToken(uint256 qAmount, bool deductTransfebLevy) public view returns(uint256) {
        require(qAmount <= _qTotal, "Amount has to be lower than supply");
        if (!deductTransfebLevy) {
            (uint256 bAmount,,,,,) = _getValues(qAmount);
            return bAmount;
        } else {
            (,uint256 bTransferAmount,,,,) = _getValues(qAmount);
            return bTransferAmount;
        }
    }

    function tokenFromReflection(uint256 bAmount) public view returns(uint256) {
        require(bAmount <= _bTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return bAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_bOwned[account] > 0) {
            _qOwned[account] = tokenFromReflection(_bOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _qOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
    
        if(sender != owner() && recipient != owner())
            require(amount <= _MAX_RT_SIZE, "Transfer amount exceeds the maxRTAmount.");

        if(burn_factor >= 250){
        
        _qTradeRotations = _qTradeRotations.add(amount);

            if(_qTradeRotations >= (0 * _CORRECTDECIMALS) && _qTradeRotations <= (499999*_CORRECTDECIMALS)){
                _startBurnLevy(250);
            }   else if(_qTradeRotations >= (500000 * _CORRECTDECIMALS) && _qTradeRotations <= (1000000 * _CORRECTDECIMALS)){
                _startBurnLevy(350);
            }   else if(_qTradeRotations >= (1000000 * _CORRECTDECIMALS) && _qTradeRotations <= (1500000 * _CORRECTDECIMALS)){
                _startBurnLevy(450);
            }   else if(_qTradeRotations >= (1500000 * _CORRECTDECIMALS) && _qTradeRotations <= (2000000 * _CORRECTDECIMALS)){
                _startBurnLevy(550);
            } else if(_qTradeRotations >= (2000000 * _CORRECTDECIMALS) && _qTradeRotations <= (2500000 * _CORRECTDECIMALS)){
                _startBurnLevy(650);
            }
            
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 qAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 bAmount, uint256 bTransferAmount, uint256 bLevy, uint256 qTransferAmount, uint256 qLevy, uint256 qBurn) = _getValues(qAmount);
        uint256 rBurn =  qBurn.mul(currentRate);
        _bOwned[sender] = _bOwned[sender].sub(bAmount);
        _bOwned[recipient] = _bOwned[recipient].add(bTransferAmount);       
        _burnFloat(bLevy, rBurn, qLevy, qBurn);
        emit Transfer(sender, recipient, qTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 qAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 bAmount, uint256 bTransferAmount, uint256 bLevy, uint256 qTransferAmount, uint256 qLevy, uint256 qBurn) = _getValues(qAmount);
        uint256 rBurn =  qBurn.mul(currentRate);
        _bOwned[sender] = _bOwned[sender].sub(bAmount);
        _qOwned[recipient] = _qOwned[recipient].add(qTransferAmount);
        _bOwned[recipient] = _bOwned[recipient].add(bTransferAmount);           
        _burnFloat(bLevy, rBurn, qLevy, qBurn);
        emit Transfer(sender, recipient, qTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 qAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 bAmount, uint256 bTransferAmount, uint256 bLevy, uint256 qTransferAmount, uint256 qLevy, uint256 qBurn) = _getValues(qAmount);
        uint256 rBurn =  qBurn.mul(currentRate);
        _qOwned[sender] = _qOwned[sender].sub(qAmount);
        _bOwned[sender] = _bOwned[sender].sub(bAmount);
        _bOwned[recipient] = _bOwned[recipient].add(bTransferAmount);   
        _burnFloat(bLevy, rBurn, qLevy, qBurn);
        emit Transfer(sender, recipient, qTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 qAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 bAmount, uint256 bTransferAmount, uint256 bLevy, uint256 qTransferAmount, uint256 qLevy, uint256 qBurn) = _getValues(qAmount);
        uint256 rBurn =  qBurn.mul(currentRate);
        _qOwned[sender] = _qOwned[sender].sub(qAmount);
        _bOwned[sender] = _bOwned[sender].sub(bAmount);
        _qOwned[recipient] = _qOwned[recipient].add(qTransferAmount);
        _bOwned[recipient] = _bOwned[recipient].add(bTransferAmount);        
        _burnFloat(bLevy, rBurn, qLevy, qBurn);
        emit Transfer(sender, recipient, qTransferAmount);
    }

    function _burnFloat(uint256 bLevy, uint256 rBurn, uint256 qLevy, uint256 qBurn) private {
        _bTotal = _bTotal.sub(bLevy).sub(rBurn);
        _qLevyTotal = _qLevyTotal.add(qLevy);
        _qBurnTotal = _qBurnTotal.add(qBurn);
        _qBurnRotations = _qBurnRotations.add(qBurn);
        _qTotal = _qTotal.sub(qBurn);

        if(_qBurnRotations >= (112500 * _CORRECTDECIMALS)){
                uint256 _qRebase = 28125 * _CORRECTDECIMALS;
                _qBurnRotations = _qBurnRotations.sub((112500 * _CORRECTDECIMALS));
                _qTradeRotations = 0;
                _startBurnLevy(250);
                _rebase(_qRebase);
            } 
    }

    function _getValues(uint256 qAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 qTransferAmount, uint256 qLevy, uint256 qBurn) = _getQValues(qAmount, levy_factor, burn_factor);
        uint256 currentRate =  _getRate();
        (uint256 bAmount, uint256 bTransferAmount, uint256 bLevy) = _getBValues(qAmount, qLevy, qBurn, currentRate);
        return (bAmount, bTransferAmount, bLevy, qTransferAmount, qLevy, qBurn);
    }

    function _getQValues(uint256 qAmount, uint256 taxLevy, uint256 burnLevy) private pure returns (uint256, uint256, uint256) {
        uint256 qLevy = ((qAmount.mul(taxLevy)).div(_GRANULARITY)).div(100);
        uint256 qBurn = ((qAmount.mul(burnLevy)).div(_GRANULARITY)).div(100);
        uint256 qTransferAmount = qAmount.sub(qLevy).sub(qBurn);
        return (qTransferAmount, qLevy, qBurn);
    }

    function _getBValues(uint256 qAmount, uint256 qLevy, uint256 qBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 bAmount = qAmount.mul(currentRate);
        uint256 bLevy = qLevy.mul(currentRate);
        uint256 rBurn = qBurn.mul(currentRate);
        uint256 bTransferAmount = bAmount.sub(bLevy).sub(rBurn);
        return (bAmount, bTransferAmount, bLevy);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 qSupply) = _getCurrentSupply();
        return rSupply.div(qSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _bTotal;
        uint256 qSupply = _qTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_bOwned[_excluded[i]] > rSupply || _qOwned[_excluded[i]] > qSupply) return (_bTotal, _qTotal);
            rSupply = rSupply.sub(_bOwned[_excluded[i]]);
            qSupply = qSupply.sub(_qOwned[_excluded[i]]);
        }
        if (rSupply < _bTotal.div(_qTotal)) return (_bTotal, _qTotal);
        return (rSupply, qSupply);
    }
    

    function _startBurnLevy(uint256 burnLevy) private {
        require(burnLevy >= 0 && burnLevy <= 650, "0-6.5%");
        burn_factor = burnLevy;
    }
    
    function setLevy(uint256 burnLevy) external onlyOwner() {
        require(burnLevy >= 0 && burnLevy <= 650, "0-6.5%");
        burn_factor = burnLevy;
    }

    function _getBurnLevy() public view returns(uint256)  {
        return burn_factor;
    }

    function _getMaxRTAmount() private view returns(uint256) {
        return _MAX_RT_SIZE;
    }

    function _getRotations() public view returns(uint256) {
        return _WindSwapRotations;
    }

    function _getBurnRotations() public view returns(uint256) {
        return _qBurnRotations;
    }

    function _getTradedRotations() public view returns(uint256) {
        return _qTradeRotations;
    }
    
    function _rebase(uint256 supplyDelta) internal {
        _WindSwapRotations = _WindSwapRotations.add(1);
        _qTotal = _qTotal.add(supplyDelta);

        if(_WindSwapRotations > 192 || _qTotal <= 8800000 * _CORRECTDECIMALS){
            _startEndProcedure();
        }
    }

    function _startEndProcedure() internal {
        _startBurnLevy(0);
    }   
}