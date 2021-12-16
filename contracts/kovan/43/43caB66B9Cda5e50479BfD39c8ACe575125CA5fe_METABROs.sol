/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT

interface IERC20 {

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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
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
    address private _previousOwner;
    uint256 private _lockTime;

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
    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function getUnlockTime() external view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) external virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() external virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
    }
}

// pragma solidity >=0.5.0;

interface IUniSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

}

// pragma solidity >=0.6.2;

interface IUniSwapRouter {
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract METABROs is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _tOwned; // total Owned tokens
    mapping (address => mapping (address => uint256)) private _allowances; // allowed allowance for spender
    mapping (address => bool) public isExcludedFromAntiWhale; // Limits how many tokens can an address hold

    mapping (address => bool) public isExcludedFromFee; // excluded address from all fee

    mapping (address => uint256) private _transactionCheckpoint;
    mapping(address => bool) public isExcludedFromTransactionCoolDown; // Address to be excluded from transaction cooldown
    uint256 private _transactionCoolTime = 120; //Cool down time between each transaction per address
    
    mapping (address => bool) public isBlacklisted; // blocks an address from buy and selling

    address payable public maintainanceAddress = payable(0x5b4148132cb0eA7Ae6FAfE128E7dd4f59d5726E1); // Maintainance Address
    address payable public developmentAddress  = payable(0x2B842AB69366070EA5837dd9D0396c2C60C26038); // Development Address
    address payable public marketingAddress    = payable(0x21bE198885f5AC237294715972B4838966a95De0); // Marketing Address

    string private _name = "Meta Bros"; //token name
    string private _symbol = "$MB"; // token symbol
    uint8 private _decimals = 18; // 1 token can be divided into 1e_decimals parts

    uint256 private _tTotal = 1000000 * 10**6 * 10**_decimals;
    
    // All fees are with one decimal value. so if you want 0.5 set value to 5, for 10 set 100. so on...

    // Below Fees to be deducted and sent as ETH
    uint256 public liquidityFee = 20; // actual liquidity fee 2%

    uint256 public marketingFee = 60; // marketing fee 6%

    uint256 public developmentFee = 30; // development fee 3%

    uint256 public maintainanceFee = 10; // Project Maintainance fee 1%

    uint256 public sellExtraFee = 20; // extra fee on sell 2%.

    uint256 private _totalFee =liquidityFee.add(marketingFee).add(developmentFee).add(maintainanceFee); // Liquidity + Marketing + Development + Mainitainance fee on each transaction
    uint256 private _previousTotalFee = _totalFee; // restore old fees

    bool public antiBotEnabled = true; //enables anti bot restrictions(max txn amount, max wallet holding transaction cooldown)

    IUniSwapRouter public uniSwapRouter; // uniSwap router assiged using address
    address public uniSwapPair; // for creating WETH pair with our token
    
    bool inSwapAndLiquify; // after each successfull swapandliquify disable the swapandliquify
    bool public swapAndLiquifyEnabled = true; // set auto swap to ETH and liquify collected liquidity fee
    
    uint256 public maxTxnAmount = 1000 * 10**6 * 10**_decimals; // max allowed tokens tranfer per transaction
    uint256 public minTokensSwapToAndTransferTo = 500 * 10**6 * 10**_decimals; // min token liquidity fee collected before swapandLiquify
    uint256 public maxTokensPerAddress            = 2000 * 10**6 * 10**_decimals; // Max number of tokens that an address can hold
    
    //PRESALE
    uint256 public sPrice;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap); //event fire min token liquidity fee collected before swapandLiquify 
    event SwapAndLiquifyEnabledUpdated(bool enabled); // event fire set auto swap to ETH and liquify collected liquidity fee
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqiudity
    ); // fire event how many tokens were swapedandLiquified
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    } // modifier to after each successfull swapandliquify disable the swapandliquify
    
    constructor () {
        _tOwned[_msgSender()] = _tTotal; // assigning the max token to owner's address  
        
        IUniSwapRouter _uniSwapRouter = IUniSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniSwap pair for this new token
        uniSwapPair = IUniSwapFactory(_uniSwapRouter.factory())
            .createPair(address(this), _uniSwapRouter.WETH());    

        // set the rest of the contract variables
        uniSwapRouter = _uniSwapRouter;
        
        //exclude owner and this contract from fee
        isExcludedFromFee[owner()]             = true;
        isExcludedFromFee[address(this)]       = true;
        isExcludedFromFee[marketingAddress]    = true;
        isExcludedFromFee[developmentAddress]  = true;
        isExcludedFromFee[maintainanceAddress] = true;

        //Exclude's below addresses from per account tokens limit
        isExcludedFromAntiWhale[owner()]                 = true;
        isExcludedFromAntiWhale[uniSwapPair]             = true;
        isExcludedFromAntiWhale[address(this)]           = true;
        isExcludedFromAntiWhale[marketingAddress]        = true;
        isExcludedFromAntiWhale[developmentAddress]      = true;
        isExcludedFromAntiWhale[maintainanceAddress]     = true;
        isExcludedFromAntiWhale[address(_uniSwapRouter)] = true;

        //Exclude's below addresses from transaction cooldown
        isExcludedFromTransactionCoolDown[owner()]                 = true;
        isExcludedFromTransactionCoolDown[uniSwapPair]             = true;
        isExcludedFromTransactionCoolDown[address(this)]           = true;
        isExcludedFromTransactionCoolDown[marketingAddress]        = true;
        isExcludedFromTransactionCoolDown[developmentAddress]      = true;
        isExcludedFromTransactionCoolDown[maintainanceAddress]     = true;
        isExcludedFromTransactionCoolDown[address(_uniSwapRouter)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
        sPrice = 100000*10**18;
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
        return _tOwned[account];
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
     * @dev transfers from a sender to receipent with subtracting spenders allowance with each successfull transfer
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**  
     * @dev exclude an address from fee
     */
    function excludeFromFee(address account) external onlyOwner {
        isExcludedFromFee[account] = true;
    }
    
    /**  
     * @dev include an address for fee
     */
    function includeInFee(address account) external onlyOwner {
        isExcludedFromFee[account] = false;
    }

    /**  
     * @dev exclude an address from per address tokens limit
     */
    function excludedFromAntiWhale(address account) external onlyOwner {
        isExcludedFromAntiWhale[account] = true;
    }

    /**  
     * @dev include an address in per address tokens limit
     */
    function includeInAntiWhale(address account) external onlyOwner {
        isExcludedFromAntiWhale[account] = false;
    }

    /**  
     * @dev set's Development fee percentage
     */
    function setDevelopmentFeePercent(uint256 Fee) external onlyOwner {
        developmentFee = Fee;
        _totalFee = liquidityFee.add(marketingFee).add(developmentFee).add(maintainanceFee);
    }

        /**  
     * @dev set's marketing fee percentage
     */
    function setMarketingFeePercent(uint256 Fee) external onlyOwner {
        marketingFee = Fee;
        _totalFee = liquidityFee.add(marketingFee).add(developmentFee).add(maintainanceFee);
    }

    /**  
     * @dev set's Maintainance fee percentage
     */
    function setMaintainanceFeePercent(uint256 Fee) external onlyOwner {
        maintainanceFee = Fee;
        _totalFee = liquidityFee.add(marketingFee).add(developmentFee).add(maintainanceFee);
    }
    
    /**  
     * @dev set's liquidity fee percentage
     */
    function setLiquidityFeePercent(uint256 Fee) external onlyOwner {
        liquidityFee = Fee;
        _totalFee = liquidityFee.add(marketingFee).add(developmentFee).add(maintainanceFee);
    }

    /**  
     * @dev set's sell extra fee percentage
     */
    function setSellExtraFeePercent(uint256 Fee) external onlyOwner {
        sellExtraFee = Fee;
    }
   
    /**  
     * @dev set's max amount of tokens percentage 
     * that can be transfered in each transaction from an address
     */
    function setMaxTxnTokens(uint256 maxTxnTokens) external onlyOwner {
        maxTxnAmount = maxTxnTokens.mul( 10**_decimals );
    }

    /**  
     * @dev set's max amount of tokens
     * that an address can hold
     */
    function setMaxTokenPerAddress(uint256 maxTokens) external onlyOwner {
        maxTokensPerAddress = maxTokens.mul( 10**_decimals );
    }

    /**  
     * @dev set's minimmun amount of tokens required 
     * before swaped and ETH send to  wallet
     * same value will be used for auto swapandliquifiy threshold
     */
    function setMinTokensSwapAndTransfer(uint256 minAmount) external onlyOwner {
        minTokensSwapToAndTransferTo = minAmount.mul( 10 ** _decimals);
    }

    /**  
     * @dev set's marketing address
     */
    function setMarketingFeeAddress(address payable wallet) external onlyOwner {
        marketingAddress = wallet;
    }

    /**  
     * @dev set's development address
     */
    function setDevelopmentFeeAddress(address payable wallet) external onlyOwner {
        developmentAddress = wallet;
    }

    /**  
     * @dev set's maintainnance address
     */
    function setMaintainaceFeeAddress(address payable wallet) external onlyOwner {
        maintainanceAddress = wallet;
    }

    /**  
     * @dev set's auto SwapandLiquify when contract's token balance threshold is reached
     */
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    /**
    * @dev Sets transactions on time periods or cooldowns. Buzz Buzz Bots.
    * Can only be set by owner set in seconds.
    */
    function setTransactionCooldownTime(uint256 transactiontime) external onlyOwner {
        _transactionCoolTime = transactiontime;
    }

    /**
     * @dev Exclude's an address from transactions from cooldowns.
     * Can only be set by owner.
     */
    function excludedFromTransactionCooldown(address account) external onlyOwner {
        isExcludedFromTransactionCoolDown[account] = true;
    }

    /**
     * @dev Include's an address in transactions from cooldowns.
     * Can only be set by owner.
     */
    function includeInTransactionCooldown(address account) external onlyOwner {
        isExcludedFromTransactionCoolDown[account] = false;
    }

    /**
     * @dev enable/disable antibot measures
     */
    function setAntiBotEnabled(bool value) external onlyOwner {
        antiBotEnabled = value;
    }
    
     //to recieve ETH from uniSwapRouter when swaping
    receive() external payable {}

    /**  
     * @dev get/calculates all values e.g taxfee, 
     * liquidity fee, actual transfer amount to receiver, 
     * deuction amount from sender
     * amount with reward to all holders
     * amount without reward to all holders
     */
    function _getValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = calculateFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }
    
    /**  
     * @dev take's fee tokens from tansaction and saves in contract
     */
    function _takeFee(address account, uint256 tFee) private {
        if(tFee > 0) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tFee);
            emit Transfer(account, address(this), tFee);
        }
    }

    /**  
     * @dev calculates fee tokens to be deducted
     */
    function calculateFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_totalFee).div(
            10**3
        );
    }

    /**  
     * @dev increase fee if selling
     */
    function increaseFee() private {
        _totalFee = _totalFee.add(sellExtraFee);
    }
    
    /**  
     * @dev removes all fee from transaction if takefee is set to false
     */
    function removeAllFee() private {
        if(_totalFee == 0) return;
        
        _previousTotalFee = _totalFee;
        _totalFee = 0;
    }

    /**  
     * @dev restores all fee after exclude fee transaction completes
     */
    function restoreAllFee() private {
        _totalFee = _previousTotalFee;
    }

    /**  
     * @dev decrease fee after selling
     */
    function decreaseFee() private {
        _totalFee = _totalFee.sub(sellExtraFee);
    }

    /**  
     * @dev approves amount of token spender can spend on behalf of an owner
     */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    bool public saleend = false;
    
    function setEndSale(bool _saleend) public onlyOwner() returns(bool){
        return saleend = _saleend;
    }

     bool public allowed = false;
    
    modifier afterSaleEnd(address from){
        require(allowed ==true|| from== address(this) || from == owner());
        _;
    }
    function setAllowed(bool _allowed) public onlyOwner() returns(bool){
        return allowed = _allowed;
    }

    /**  
     * @dev transfers token from sender to recipient also auto 
     * swapsandliquify if contract's token balance threshold is reached
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private afterSaleEnd(from){
        require(from != address(0) && to != address(0), "ERC20: transfer from or two the zero address");
        require(!isBlacklisted[from], "You are Blacklisted");
        if(antiBotEnabled) {
            require(balanceOf(to) + amount <= maxTokensPerAddress || isExcludedFromAntiWhale[to],
            "Max tokens limit for this account exceeded. Or try lower amount");
            require(isExcludedFromTransactionCoolDown[from] || block.timestamp >= _transactionCheckpoint[from] + _transactionCoolTime,
            "Wait for transaction cooldown time to end before making a tansaction");
            require(isExcludedFromTransactionCoolDown[to] || block.timestamp >= _transactionCheckpoint[to] + _transactionCoolTime,
            "Wait for transaction cooldown time to end before making a tansaction");
            if(from != owner() && to != owner())
                require(amount <= maxTxnAmount, "Transfer amount exceeds the maxTxAmount.");

            _transactionCheckpoint[from] = block.timestamp;
            _transactionCheckpoint[to] = block.timestamp;
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniSwap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        bool takeFee; 
        if(saleend==true)
        {
        if(contractTokenBalance >= maxTxnAmount)
        {
            contractTokenBalance = maxTxnAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >=minTokensSwapToAndTransferTo;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniSwapPair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance =minTokensSwapToAndTransferTo;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        takeFee = true;
        
        //if any account belongs to isExcludedFromFee account then remove the fee
        if(isExcludedFromFee[from] || isExcludedFromFee[to]){
            takeFee = false;
        }
        }
        //transfer amount, it will take tax fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    /**  
     * @dev swapsAndLiquify tokens to uniSwap if swapandliquify is enabled
     */
    function swapAndLiquify(uint256 tokenBalance) private lockTheSwap {
        // first split contract into marketing fee and liquidity fee
        uint256 swapPercent = developmentFee.add(marketingFee).add(maintainanceFee).add(liquidityFee/2);
        uint256 swapTokens = tokenBalance.div(_totalFee).mul(swapPercent);
        uint256 liquidityTokens = tokenBalance.sub(swapTokens);
        uint256 initialBalance = address(this).balance;
        
        swapTokensForEth(swapTokens);

        uint256 transferredBalance = address(this).balance.sub(initialBalance);
        uint256 developmentAmount = 0;
        uint256 maintainanceAmount = 0;
        uint256 marketingAmount = 0;

        if(developmentFee > 0)
        {
            developmentAmount = transferredBalance.mul(developmentFee).div(swapPercent);

            developmentAddress.transfer(developmentAmount);
        }

        if(marketingFee > 0)
        {
            marketingAmount = transferredBalance.mul(marketingFee).div(swapPercent);

            marketingAddress.transfer(marketingAmount);
        }

        if(maintainanceFee > 0)
        {
            maintainanceAmount = transferredBalance.mul(maintainanceFee).div(swapPercent);

            maintainanceAddress.transfer(maintainanceAmount);
        }
        
        if(liquidityFee > 0)
        {
            transferredBalance = transferredBalance.sub(developmentAmount).sub(marketingAmount).sub(maintainanceAmount);
            addLiquidity(owner(), liquidityTokens, transferredBalance);

            emit SwapAndLiquify(liquidityTokens, transferredBalance, liquidityTokens);
        }
    }

    /**  
     * @dev swap's exact amount of tokens for ETH if swapandliquify is enabled
     */
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniSwapRouter.WETH();

        _approve(address(this), address(uniSwapRouter), tokenAmount);

        // make the swap
        uniSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /**  
     * @dev add's liquidy to uniSwap if swapandliquify is enabled
     */
    function addLiquidity(address recipient, uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniSwapRouter), tokenAmount);

        // add the liquidity
        uniSwapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            recipient,
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(recipient == uniSwapPair && sellExtraFee > 0)
            increaseFee();
        if(!takeFee)
            removeAllFee();

        (uint256 tTransferAmount, uint256 tFee) = _getValues(amount);
        _tOwned[sender] = _tOwned[sender].sub(amount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);

        _takeFee(sender, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        
        
        if(!takeFee)
            restoreAllFee();
        if(recipient == uniSwapPair && sellExtraFee > 0)
            decreaseFee();
    }

    /**  
     * @dev Blacklist a singel wallet from buying and selling
     */
    function blacklistSingleWallet(address account) external onlyOwner{
        if(isBlacklisted[account] == true) return;
        isBlacklisted[account] = true;
    }

    /**  
     * @dev Blacklist multiple wallets from buying and selling
     */
    function blacklistMultipleWallets(address[] calldata accounts) external onlyOwner{
        require(accounts.length < 800, "Can not blacklist more then 800 address in one transaction");
        for (uint256 i; i < accounts.length; ++i) {
            isBlacklisted[accounts[i]] = true;
        }
    }
    
    /**  
     * @dev un blacklist a singel wallet from buying and selling
     */
    function unBlacklistSingleWallet(address account) external onlyOwner{
         if(isBlacklisted[account] == false) return;
        isBlacklisted[account] = false;
    }

    /**  
     * @dev un blacklist multiple wallets from buying and selling
     */
    function unBlacklistMultipleWallets(address[] calldata accounts) external onlyOwner {
        require(accounts.length < 800, "Can not Unblacklist more then 800 address in one transaction");
        for (uint256 i; i < accounts.length; ++i) {
            isBlacklisted[accounts[i]] = false;
        }
    }

    /**  
     * @dev recovers any tokens stuck in Contract's address
     * NOTE! if ownership is renounced then it will not work
     */
    function recoverTokens(address tokenAddress, address recipient, uint256 amountToRecover) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        
        require(balance >= amountToRecover, "Not Enough Tokens in contract to recover");

        if(amountToRecover > 0)
            token.transfer(recipient, amountToRecover);
    }
    
    /**  
     * @dev recovers any ETH stuck in Contract's balance
     * NOTE! if ownership is renounced then it will not work
     */
    function recoverETH() external onlyOwner {
        address payable recipient = _msgSender();
        if(address(this).balance > 0)
            recipient.transfer(address(this).balance);
    }
    
    //New uniswap router version?
    //No problem, just change it!
    function setRouterAddress(address newRouter) external onlyOwner {
        IUniSwapRouter _newUniSwapRouter = IUniSwapRouter(newRouter);
        uniSwapPair = IUniSwapFactory(_newUniSwapRouter.factory()).createPair(address(this), _newUniSwapRouter.WETH());
        uniSwapRouter = _newUniSwapRouter;

        isExcludedFromAntiWhale[uniSwapPair]           = true;
        isExcludedFromTransactionCoolDown[uniSwapPair] = true;
    }

    //PRESALE
    function tokenSale(address _refer) public payable returns (bool success){
    //require(sSBlock <= block.number && block.number <= sEBlock);
    //require(sTot < sCap || sCap == 0);
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice*_eth) / 1 ether;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
    _transfer(address(this), msg.sender, _tkns);
    return true;
  }
    
  
 function setSalePrice(uint256 newSalePrice) external onlyOwner() {
        sPrice = newSalePrice;
    }   

    function claim(uint amount) public onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(amount);
    }
    
    function withdrawToken() external onlyOwner {
        IERC20 erc20token = IERC20(address(this));
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
    }
}