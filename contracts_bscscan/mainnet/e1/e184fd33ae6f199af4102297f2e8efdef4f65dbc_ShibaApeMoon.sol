/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

pragma solidity ^0.8.5;
// SPDX-License-Identifier: MIT
// Developed by: jawadklair

interface IBEP20 {

    /**  
     * @dev Returns the total tokens supply  
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
 
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data; // msg.data is used to handle array, bytes, string 
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
     * increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Koda Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Koda Address: unable to send value, recipient may have reverted");
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
      return functionCall(target, data, "Koda Address: low-level call failed");
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
     * - the calling contract must have an BNB balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Koda Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Koda Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Koda Address: call to non-contract");

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
abstract contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
contract LockOwnable is Ownable {
    address private _previousOwner;
    uint256 private _lockTime;

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "KODA: You don't have permission to unlock");
        require(block.timestamp > _lockTime , "KODA: Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
    }
}

interface ISummitSwapFactory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISummitSwapRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}


contract ShibaApeMoon is Context, IBEP20, LockOwnable { // change contract name
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned; // reflected owned tokens
    mapping (address => uint256) private _tOwned; // total Owned tokens
    mapping (address => mapping (address => uint256)) private _allowances; // allowed allowance for spender

    mapping (address => bool) public _isExcludedFromFee; // excluded address from all fee
    
    mapping (address => bool) public _isExcludedFromReflection; // address excluded from reflection

    address payable public _kodaLiquidityProviderAddress = payable(0x0000000000000000000000000000000000000000); // kapex liquidity address

    string private _name = "Shiba Ape Moon"; // token name
    string private _symbol = "ShibaApeMoon"; // token symbol
    uint8 private _decimals = 9; // token decimals(1 token can be divided into 1e_decimals parts)

    uint256 private constant MAX = ~uint256(0); // maximum possible number uint256 decimal value
    uint256 private _tTotal = 33000 * 10**6 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal)); // maximum _rTotal value after subtracting _tTotal remainder

    uint256 private _tSupply = _tTotal;
    uint256 private _rSupply = _rTotal;

    bool public buyFeeReduced = false; //reduce buy fee to do promotion
    
    uint256 public buyFeeReductionPercentage = 0;
    uint256 public buyFeeReducedEndTime = 0 minutes;
    
    // All fees are with one decimal value. so if you want 0.5 set value to 5, for 10 set 100. so on...

    // Below Fees to be deducted and sent as tokens
    uint256 public _feeReflection = 200; //reflection fee 2%
    uint256 private _previousReflectionFee = _feeReflection; //reflection fee

    // Below Fees to be deducted and sent as BNB/BUSD/or Kapex
    uint256 public _feeTotalBNBDeductible = 800; // 8% all liquidity + dev + marketing fee on each transaction
    uint256 private _previousBNBdeDuctibleFee = _feeTotalBNBDeductible; // restore old deductible fee

    address public summitSwapPair; // for creating WETH pair with our token
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal; // assigning the max reflection token to owner's address  
        
        ISummitSwapRouter01 _summitSwapRouter = ISummitSwapRouter01(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a summitswap pair for this new token
        summitSwapPair = ISummitSwapFactory(_summitSwapRouter.factory())
            .createPair(address(this), _summitSwapRouter.WETH());    
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()]             = true;
        _isExcludedFromFee[address(this)]       = true;
        _isExcludedFromFee[_kodaLiquidityProviderAddress]   = true;


        //Exclude dead address from reflection
        _isExcludedFromReflection[address(0)] = true;
        _isExcludedFromReflection[0x000000000000000000000000000000000000dEaD] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReflection[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**  
     * @dev approves allowance of a spender
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    /**  
     * @dev transfers from a sender to recipient with subtracting spenders allowance with each successful transfer
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "KODA: transfer amount exceeds allowance"));
         return true;
    }

    /**  
     * @dev approves allowance of a spender should set it to zero first than increase
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**  
     * @dev decrease allowance of spender that it can spend on behalf of owner
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "KODA: decreased allowance below zero"));
        return true;
    }

    /**  
     * @dev gives reflected tokens to caller
     */
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcludedFromReflection[sender], "KODA: Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rSupply = _rSupply - rAmount;
    }

    /**  
     * @dev return's reflected amount of an address from given token amount with/without fee deduction
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "KODA: Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    /**  
     * @dev get's exact total tokens of an address from reflected amount
     */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rSupply, "KODA: Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    /**  
     * @dev excludes an address from reflection reward can only be set by owner
     */
    function excludeFromReward(address account) public onlyOwner {
        // require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We can not exclude summitswap router.');
        require(!_isExcludedFromReflection[account], "KODA: Account is already excluded");
        uint256 rBalance = _rOwned[account];
        if(rBalance > 0) {
            uint256 rTokens = tokenFromReflection(rBalance);
            _tOwned[account] = rTokens;
            _rSupply -= rBalance;
            _tSupply -= rTokens;
        }
        _isExcludedFromReflection[account] = true;
    }

    /**  
     * @dev includes an address for reflection reward which was excluded before
     */
    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromReflection[account], "KODA: Account is already included");
        uint256 tOwned = _tOwned[account];
        uint256 rAmount = reflectionFromToken(tOwned, false);

        _tSupply += tOwned;
        _rSupply += rAmount;

        _rOwned[account] = rAmount;
        _tOwned[account] = 0;

        _isExcludedFromReflection[account] = false;
    }
    
    /**  
     * @dev exclude an address from fee
     */
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    /**  
     * @dev include an address for fee
     */
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**  
     * @dev set's reflection fee percentage
     */
    function setReflectFeePercent(uint256 Fee) external onlyOwner {
        require(_feeTotalBNBDeductible.add(Fee) <= 1000, "KODA: Total Deductable fee should be less then or equal to 10%");
        _feeReflection = Fee;
    }
    
    /**  
     * @dev set's BNB deductible fee percentage
     */
    function setTotalBNBDeductibleFeePercent(uint256 Fee) external onlyOwner {
        require(_feeReflection.add(Fee) <= 1000, "KODA: Total Deductible fee should be less then or equal to 10%");
        _feeTotalBNBDeductible = Fee;
    }

    /**  
     * @dev set's koda liquidity provider address
     */
    function setKodaLiquidityProviderAddress(address payable kodaLiquidityAddress) external onlyOwner {
        _kodaLiquidityProviderAddress = kodaLiquidityAddress;
        _isExcludedFromFee[_kodaLiquidityProviderAddress] = true;
    }

    /**  
     * @dev reduce buy fee for a certain amount of time
     */
    function reduceBuyFee(uint256 reductionDuration, uint256 reductionPercentage) external onlyOwner {
        require(reductionPercentage <= 10000, "Buy fee reduction percentage value should be less than equal to 10000");
        buyFeeReducedEndTime = block.timestamp.add(reductionDuration * 1 minutes);
        buyFeeReductionPercentage = reductionPercentage;
        buyFeeReduced = true;
    }

    /**  
     * @dev reflects to all holders, fee deducted from each transaction
     */
    function _reflectFee(uint256 rFee) private {
        _rSupply    = _rSupply.sub(rFee);
        // _tFeeTotal = _tFeeTotal.add(tFee);
    }

    /**  
     * @dev get/calculates all values e.g taxfee, 
     * liquidity fee, actual transfer amount to receiver, 
     * deduction amount from sender
     * amount with reward to all holders
     * amount without reward to all holders
     */
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rLiquidity) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, rLiquidity, tTransferAmount, tLiquidity);
    }

    /**  
     * @dev get/calculates taxfee, liquidity fee
     * without reward amount
     */
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateReflectionFee(tAmount);
        uint256 tLiquidity = calculateDeductibleFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    /**  
     * @dev amount with reward, reflection from transaction
     * total deduction amount from sender with reward
     */
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee, rLiquidity);
    }

    /**  
     * @dev gets current reflection rate
     */
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    /**  
     * @dev gets total supply with/without deducted 
     * exclude caller's total owned and reflection owned 
     */
    function _getCurrentSupply() private view returns(uint256, uint256) {
        // _tSupply is 0 when every token is held by excluded wallet.
        uint256 tSupply = _tSupply;
        if(tSupply == 0) return (_rTotal, _tTotal);
        return (_rSupply, tSupply);
    }
    
    /**  
     * @dev take's liquidity fee tokens from transaction and send to liquidity provider contract
     */
    function _takeLiquidity(address sender, uint256 tLiquidity, uint256 rLiquidity) private {
        if(_isExcludedFromReflection[_kodaLiquidityProviderAddress]) {
            _tOwned[_kodaLiquidityProviderAddress] = _tOwned[_kodaLiquidityProviderAddress].add(tLiquidity);
            _rSupply -= rLiquidity;
            _tSupply -= tLiquidity;
        } else {
            _rOwned[_kodaLiquidityProviderAddress] = _rOwned[_kodaLiquidityProviderAddress].add(rLiquidity);
        }
        emit Transfer(sender, _kodaLiquidityProviderAddress, tLiquidity);
    }

    /**  
     * @dev calculates reflection fee tokens to be deducted
     */
    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_feeReflection).div(
            10**4
        );
    }

    /**  
     * @dev calculates deductible fee tokens to be deducted
     */
    function calculateDeductibleFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_feeTotalBNBDeductible).div(
            10**4
        );
    }
    
    /**  
     * @dev removes all fee from transaction if takefee is set to false
     */
    function removeAllFee() private {
        if(_feeTotalBNBDeductible == 0 && _feeReflection == 0) return;
        
        _previousReflectionFee = _feeReflection;
        _previousBNBdeDuctibleFee = _feeTotalBNBDeductible;
        
        _feeReflection = 0;
        _feeTotalBNBDeductible = 0;
    }

    /**  
     * @dev removes all fee from transaction if takefee is set to false
     */
    function adjustBuyFee() private {
        _previousReflectionFee = _feeReflection;
        _previousBNBdeDuctibleFee = _feeTotalBNBDeductible;
        
        _feeReflection = _feeReflection.mul(buyFeeReductionPercentage).div(10000);
        _feeTotalBNBDeductible = _feeTotalBNBDeductible.mul(buyFeeReductionPercentage).div(10000);
    }
    
    /**  
     * @dev restores all fee after exclude fee transaction completes
     */
    function restoreAllFee() private {
        _feeReflection = _previousReflectionFee;
        _feeTotalBNBDeductible = _previousBNBdeDuctibleFee;
    }

    /**  
     * @dev approves amount of token spender can spend on behalf of an owner
     */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "KODA: approve from the zero address");
        require(spender != address(0), "KODA: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**  
     * @dev transfers token from sender to recipient also auto 
     * send collected fee to kodaLiquidityProvider address(contract).
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0) && to != address(0), "KODA: transfer from/to the Zero address");
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        if(buyFeeReduced && block.timestamp >= buyFeeReducedEndTime)
            buyFeeReduced = false;

        bool buyFeeReductionCheck = buyFeeReduced;
        if(buyFeeReductionCheck && from != summitSwapPair)
            buyFeeReductionCheck = false;
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee,buyFeeReductionCheck);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool reducedBuyFee) private {
        if(!takeFee)
            removeAllFee();
        if(reducedBuyFee && takeFee)
            adjustBuyFee();
        
        if (!_isExcludedFromReflection[sender] && !_isExcludedFromReflection[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromReflection[sender] && !_isExcludedFromReflection[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReflection[sender] && _isExcludedFromReflection[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else {
            _transferBothExcluded(sender, recipient, amount);
        }
        
        if(!takeFee || reducedBuyFee)
            restoreAllFee();
    }

    /**  
     * @dev deduct's balance from sender and 
     * add to recipient with reward for recipient only
     */
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rLiquidity, uint256 tTransferAmount, uint256 tLiquidity) = _getValues(tAmount);
        require(tAmount <=_tOwned[sender],"KODA: transfer amount exceeds Balance");
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _rSupply = _rSupply.add(rAmount);
        _tSupply = _tSupply.add(tAmount);

        _takeLiquidity(sender, tLiquidity, rLiquidity);
        _reflectFee(rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**  
     * @dev deduct's balance from sender and 
     * add to recipient with reward for sender only
     */
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rLiquidity, uint256 tTransferAmount, uint256 tLiquidity) = _getValues(tAmount);
        require(rAmount <=_rOwned[sender],"KODA: transfer amount exceeds Balance");
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);

        _rSupply = _rSupply.sub(rTransferAmount);
        _tSupply = _tSupply.sub(tTransferAmount);

        _takeLiquidity(sender, tLiquidity, rLiquidity);
        _reflectFee(rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**  
     * @dev deduct's balance from sender and 
     * add to recipient with reward for both addresses
     */
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rLiquidity, uint256 tTransferAmount, uint256 tLiquidity) = _getValues(tAmount);
        require(rAmount <=_rOwned[sender],"KODA: transfer amount exceeds Balance");
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(sender, tLiquidity, rLiquidity);
        _reflectFee(rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    /**  
     * @dev Transfer tokens to sender and receiver address with both excluded from reward
     */
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rLiquidity, uint256 tTransferAmount, uint256 tLiquidity) = _getValues(tAmount);
        require(tAmount <=_tOwned[sender],"KODA: transfer amount exceeds Balance");
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        
        _rSupply = _rSupply.add(rAmount.sub(rTransferAmount));
        _tSupply = _tSupply.add(tAmount.sub(tTransferAmount));

        _takeLiquidity(sender, tLiquidity, rLiquidity);
        _reflectFee(rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**  
     * @dev recovers any tokens stuck in Contract's balance
     * NOTE! if ownership is renounced then it will not work
     * NOTE! Contract's Address and Owner's address MUST NOT
     * be excluded from reflection reward
     */
    function recoverTokens(address tokenAddress, address recipient, uint256 amountToRecover, uint256 recoverFeePercentage) public onlyOwner
    {
        IBEP20 token = IBEP20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        require(balance >= amountToRecover, "KODA: Not Enough Tokens in contract to recover");

        address feeRecipient = _msgSender();
        uint256 feeAmount = amountToRecover.mul(recoverFeePercentage).div(10000);
        amountToRecover = amountToRecover.sub(feeAmount);
        if(feeAmount > 0)
            token.transfer(feeRecipient, feeAmount);
        if(amountToRecover > 0)
            token.transfer(recipient, amountToRecover);
    }
    
    //set New swap Pair address!
    function setPairAddress(address newPair) public onlyOwner {
        require(newPair != summitSwapPair, "This pair address is already set");
        summitSwapPair = newPair;
    }
}