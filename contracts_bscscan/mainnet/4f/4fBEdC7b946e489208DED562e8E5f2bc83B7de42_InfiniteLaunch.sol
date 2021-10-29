/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
 * =======InfiniteLaunch.io=======
 * Cross-chain launchpad for disruptive Gamefi & NFT projects
 * website    : https://InfiniteLaunch.io
 * telelegram : https://t.me/InfiniteLaunch
 * 
 */
contract InfiniteLaunch is Context, Ownable, IERC20 {

    // Libraries
	using SafeMath for uint256;
    using Address for address;
    
    // Attributes for ERC-20 token
    string private _name = "InfiniteLaunch";
    string private _symbol = "ILA";
    uint8 private _decimals = 18;
    
    mapping (address => uint256) private _balance;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _total = 1 * 10**9 * 10**18;  
    uint256 public  maxTxAmount = 100 * 10**3 * 10**18; // max tranfer 100k token.
    
    //IdoLaunch Community attributes
    bool public paused = false;
    uint256 public communityTax = 2;
    uint256 public burnTax = 1; 
    uint256 public communityFund;
    uint256 public burnableFund;
    bool public transactionFee = true; 
    mapping (address => bool) public blockListEpic; //Blacklist.
    //Lock Tier attributes
    uint256[5] public penatyRate = [
		30,25,20,10,5
    ];
    uint256[5] public penatyTime = [
            604800,1209600,1814400,2592000,5184000
    ];
    uint256 public timeLocked = 5184000 ; //60days
    //Tier Lock List
    struct UserLock {
        uint256 startTimeLock;
        uint256 amount;
    }
    
    uint256 public totalAmountLocked; //total amount locked in contract
    mapping (address => uint256) public userLockedBalance;
    mapping (address => uint256) public userLockedLastEntryTime; 
    mapping (address => bool) public allowPassFeeAddr;

     
    event BlockEpic(address indexed user, bool locked);
    event Locked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event TransactionFeeEnableUpdated(bool enabled );
    event CommunityFundWithdrawn(
        uint256 amount,
        address recepient,
        string reason
    );

    constructor() {
	    _balance[_msgSender()] = _total;
	    
	    communityFund = 0;
        burnableFund = 0; 

        emit Transfer(address(0), _msgSender(), _total);
    }
     
    // --- section 1 --- : Standard ERC 20 functions

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
        return _total;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    // --- section 2 --- : IdoLaunch specific logics
        
    // function _mint (address account , uint256 value) public onlyOwner virtual {
      
    //     _total = _total.add(value);
    //     _balance[account] = _balance[account].add(value); 
    //     emit Transfer(address(0), account, value);

    // }
    
    function burnToken(uint256 amount) public onlyOwner virtual {
        require(amount <= _balance[address(this)], "Cannot burn more than avilable balances");
        require(amount <= burnableFund, "Cannot burn more than burn fund");

        _balance[address(this)] = _balance[address(this)].sub(amount);
        _total = _total.sub(amount);
        burnableFund = burnableFund.sub(amount);

        emit Transfer(address(this), address(0), amount);
    } 
    
    function setTransactionFee(bool _enabled) public onlyOwner {
    	transactionFee = _enabled;
        emit TransactionFeeEnableUpdated(_enabled);
    }
    
    function setMaxTxnAmount(uint256 _amount) public onlyOwner {
        maxTxAmount = _amount;
    }
    //paused
    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    } 
    //blockListEpic
    function setBlockEpic(address _epic) public onlyOwner {
        blockListEpic[_epic] = true;
        emit BlockEpic(_epic, true);
    }
    function setUnBlockEpic(address _epic) public onlyOwner {
        blockListEpic[_epic] = false;
        emit BlockEpic(_epic, false);
    }
    //allowPassFeeAddr
    function setAllowPassFeeAddr(address _epic) public onlyOwner {
        allowPassFeeAddr[_epic] = true;
        emit BlockEpic(_epic, true);
    }
    function setDeleteAllowPassFeeAddr(address _epic) public onlyOwner {
        allowPassFeeAddr[_epic] = false;
        emit BlockEpic(_epic, false);
    } 
    //==set fee  
    function setCommunityTax(uint256 _taxRate) public onlyOwner {
        communityTax = _taxRate;
    }
    function setBurnabTax(uint256 _taxRate) public onlyOwner {
        burnTax = _taxRate;
    } 
 
    //Tier Lock List 
    function setPenatyRate(uint256 _pRate0, uint256 _pRate1, uint256 _pRate2, uint256 _pRate3, uint256 _pRate4) public onlyOwner {
        penatyRate[0] = _pRate0;
        penatyRate[1] = _pRate1;
        penatyRate[2] = _pRate2;
        penatyRate[3] = _pRate3;
        penatyRate[4] = _pRate4;
    } 
    function setPenatyTime(uint256 _pRate0, uint256 _pRate1, uint256 _pRate2, uint256 _pRate3, uint256 _pRate4) public onlyOwner {
        
        penatyTime[0] = _pRate0;
        penatyTime[1] = _pRate1;
        penatyTime[2] = _pRate2;
        penatyTime[3] = _pRate3;
        penatyTime[4] = _pRate4;
    } 
    function setTotalTimeLock(uint256 _timeLocked) public onlyOwner {
        require(_timeLocked > 0 , "Total time locked  > 0");
        timeLocked = _timeLocked;
    }


    function withdrawCommunityFund(uint256 amount, address walletAddress, string memory reason) public onlyOwner() {
        require(amount < communityFund, "You cannot withdraw more funds that you have in community fund");
    	require(amount <= _balance[address(this)], "You cannot withdraw more funds that you have in operation fund");
    	
    	// track operation fund after withdrawal
    	communityFund = communityFund.sub(amount);
    	_balance[address(this)] = _balance[address(this)].sub(amount);
    	_balance[walletAddress] = _balance[walletAddress].add(amount);
    	
    	emit CommunityFundWithdrawn(amount, walletAddress, reason);
    } 
    // --- section 3 --- : Executions 
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    } 
    //_msgSender()
    function _transfer(address fromAddress, address toAddress, uint256 amount) private {
        require(!paused, "ERC20: transfer paused");
        require(fromAddress != address(0) && toAddress != address(0), "ERC20: transfer from/to the zero address");
        require(amount > 0 && amount <= _balance[fromAddress], "Transfer amount invalid");
        if(fromAddress != owner() && toAddress != owner())
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        
        require( !blockListEpic[fromAddress] , "The address in Epic List.");
        
        _balance[fromAddress] = _balance[fromAddress].sub(amount);
        
        //charge fee here.
        uint256 transactionTokenAmount = amount;
        // allowPassFeeAddr[fromAddress] or allowPassFeeAddr[toAddress]
        if (transactionFee && fromAddress != owner() 
            && !allowPassFeeAddr[fromAddress] && !allowPassFeeAddr[toAddress] ){
            transactionTokenAmount = _getValues(amount);
        }
        //real value get.
        _balance[toAddress] = _balance[toAddress].add(transactionTokenAmount);

        emit Transfer(fromAddress, toAddress, transactionTokenAmount);
    }

    function _getValues(uint256 amount) private returns (uint256) {
    	// if not charge fee transaction. 
    	uint256 communityTaxFee = _extractCommunityFund(amount);
    	uint256 burnableFundTax = _extractBurnableFund(amount);
    	uint256 businessTax = burnableFundTax.add(communityTaxFee);
    	uint256 transactionAmount = amount.sub(businessTax);
        
		return transactionAmount;
    }

    function _extractCommunityFund(uint256 amount) private returns (uint256) {
    	uint256 communityFundContribution = _getExtractableFund(amount, communityTax);
    	communityFund = communityFund.add(communityFundContribution);
    	_balance[address(this)] = _balance[address(this)].add(communityFundContribution);
    	return communityFundContribution;
    } 

    function _extractBurnableFund(uint256 amount) private returns (uint256) {
    	(uint256 burnableFundContribution) = _getExtractableFund(amount, burnTax);
    	burnableFund = burnableFund.add(burnableFundContribution);
    	_balance[address(this)] = _balance[address(this)].add(burnableFundContribution);
    	return burnableFundContribution;
    }

    function _getExtractableFund(uint256 amount, uint256 rate) private pure returns (uint256) {
    	return amount.mul(rate).div(10**2);
    }
      
   // --- Section4 Address Tier ---
   /*
    init Lock token, 
    Amount Locked.
    endtimeStamp => time will ended.
    public override returns (bool)
    */
    function createLock(uint256 amount) public returns (bool){
        
        require(amount > 0 && amount <= _balance[msg.sender], "Amount is invalid");

        uint256 userLockAmount = userLockedBalance[msg.sender];  
        //burnableFund = burnableFund.add(burnableFundContribution);
    	_balance[msg.sender] = _balance[msg.sender].sub(amount);
        _balance[address(this)] = _balance[address(this)].add(amount);

        totalAmountLocked  = totalAmountLocked.add(amount);
        userLockAmount = userLockAmount.add(amount);        
        
        userLockedBalance[msg.sender] = userLockAmount;
        userLockedLastEntryTime[msg.sender] = block.timestamp;
        
        emit Locked(msg.sender, amount);

        return true;
    } 

    function getPenatyRate(address account) internal view returns (uint256) {
        
        uint256 timePass = block.timestamp - userLockedLastEntryTime[account]; 
        uint256 pRate = penatyTime[0] ;
        
        for (uint i = 0; i < 5; i++) { 
            if( timePass <= penatyTime[i] ){
                pRate = penatyRate[i];
                return pRate;
            }
        }
        if( timePass >= timeLocked ){
            return 0;
        }
        return 0;
        
    }
    
    function checkBalanceLocked(address account) public view returns (uint256, uint256, uint256) {
        uint256 pRate = getPenatyRate(msg.sender);
        return (userLockedBalance[account] , userLockedLastEntryTime[account], pRate  );
    }
    function withdrawVested() external returns (bool){
        require(  userLockedBalance[msg.sender] <= _balance[address(this)] , "Balance in contract is not enought for vesting"); 
        require(  userLockedBalance[msg.sender] > 0 , "Amount is invalid" );
        
        uint256 toWithdraw;
        uint256 pAmount; 
        uint256 pRate = getPenatyRate(msg.sender);
      
        pAmount = userLockedBalance[msg.sender].mul(pRate).div(10**2);
        
        // penatiy amount add to fund. 
        communityFund = communityFund.add(pAmount); 
        
        toWithdraw =  userLockedBalance[msg.sender].sub(pAmount);
        
        totalAmountLocked = totalAmountLocked.sub(userLockedBalance[msg.sender]);
        userLockedBalance[msg.sender] = 0; 
        
        _balance[msg.sender] = _balance[msg.sender].add(toWithdraw);
        _balance[address(this)] = _balance[address(this)].sub(toWithdraw);
        
        emit Withdrawn(msg.sender, toWithdraw);
        
        return true;
    
    }
    
}