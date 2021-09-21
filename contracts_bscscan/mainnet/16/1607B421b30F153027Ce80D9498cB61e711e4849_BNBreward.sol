/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



//pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol



//pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



//pragma solidity ^0.8.0;


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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



//pragma solidity ^0.8.0;

// CAUTION
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

// File: BNBR.sol


library Address {
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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

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


interface UniversalFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface UniversalRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
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
        uint deadline) external;
}



contract BNBreward is Context, Ownable, IERC20 {
    using Address for address;
    using Address for address payable;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping(address => uint256) private _firstSell;
    mapping(address => uint256) private _totSells;
    
    mapping(address => bool) private _isBadActor;


    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 2 * 10**15 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    address payable public RewardPool;
    address payable public MarketingAddress;
    address payable public CharityWallet;

    string private _name = "BNB Rewards";
    string private _symbol = "BNBR";
    uint8 private _decimals = 9;

    struct feeRatesStruct {
      uint256 taxFee;
      uint256 devFee;
      uint256 marketingFee;
      uint256 giveawaysFee;
      uint256 iBNBPoolFee;
      uint256 swapFee;
      uint256 totFees;
    }
    
    feeRatesStruct public buyFees = feeRatesStruct(
     {taxFee: 5000,
      devFee: 1337,
      marketingFee: 1000,
      giveawaysFee: 663,
      iBNBPoolFee: 2000,
      swapFee: 5000, // devFee+marketingFee+giveawaysFee+iBNBPoolFee
      totFees: 15
    });

    feeRatesStruct public sellFees = feeRatesStruct(
     {taxFee: 5000,
      devFee: 1337,
      marketingFee: 1000,
      giveawaysFee: 663,
      iBNBPoolFee: 2000,
      swapFee: 5000, // devFee+marketingFee+giveawaysFee+iBNBPoolFee
      totFees: 15
    });

    feeRatesStruct private appliedFees = buyFees; //default value
    feeRatesStruct private previousFees;

    struct antiwhale {
      uint256 selling_threshold;//this is value/1000 %
      uint256 extra_tax; //this is value %
    }

    antiwhale[3] public antiwhale_measures;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rFee;
      uint256 rSwap;
      uint256 tTransferAmount;
      uint256 tFee;
      uint256 tSwap;
    }

    
    uint256 public maxSellPerDay = _tTotal/1000;
    
    address payable public devWallet = payable(0xAEa4563482437b6D3ECa897b4Ca613C50F9C2638);

    UniversalRouter public pancakeRouter;
    address public pancakePair;
    
    bool inSwap;
    bool public swapEnabled = true;
    uint256 private minTokensToSwap = 50000 * 10**9;
    uint256 public maxTxAmount = _tTotal/100;


    event swapEnabledUpdated(bool enabled);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        _tOwned[_msgSender()] = _tTotal;
        
        UniversalRouter _pancakeRouter = UniversalRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        pancakePair = UniversalFactory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());

         pancakeRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[MarketingAddress] = true;
        _isExcludedFromFee[devWallet] = true;
        _isExcludedFromFee[CharityWallet] = true;
        _isExcludedFromFee[RewardPool] = true;
        _isExcludedFromFee[address(this)] = true;
        
        
        _isExcluded[owner()] = true;
        _isExcluded[MarketingAddress] = true;
        _isExcluded[devWallet] = true;
        _isExcluded[CharityWallet] = true;
        _isExcluded[RewardPool] = true;
        _isExcluded[0x000000000000000000000000000000000000dEaD] = true;

        _excluded.push(owner());
        _excluded.push(MarketingAddress);
        _excluded.push(devWallet);
        _excluded.push(CharityWallet);
        _excluded.push(RewardPool);
        _excluded.push(0x000000000000000000000000000000000000dEaD); 

        antiwhale_measures[0] = antiwhale({selling_threshold: _tTotal*25/100000, extra_tax: 1});//0.025% of initial supply
        antiwhale_measures[1] = antiwhale({selling_threshold: _tTotal*50/100000, extra_tax: 2});//0.05% of initial supply
        antiwhale_measures[2] = antiwhale({selling_threshold: _tTotal*75/100000, extra_tax: 3});//0.075% of initial supply

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    //For new Pancakeswap router version just change it here
    function setRouterAddress(address newRouter) external onlyOwner() returns (address, address){
         UniversalRouter _pancakeRouter = UniversalRouter(newRouter);
         pancakePair = UniversalFactory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());

        return (newRouter, address(pancakePair));
    }

    //To set reward pool address from time to time
    function setRewardPool(address payable _rewardPoolAddress) external onlyOwner() returns (bool) {
        RewardPool = payable(_rewardPoolAddress);
        _isExcludedFromFee[RewardPool] = true;
         return true;
    }

    //To set marketing address from time to time
    function setMktWallet(address payable _mktAddress) external onlyOwner() returns (bool) {
        MarketingAddress = payable(_mktAddress);
        _isExcludedFromFee[MarketingAddress] = true;
        return true;
    }

    //To set charity address from time to time
    function setCharityWallet(address payable _charityAddress) external onlyOwner() returns (bool) {
        CharityWallet = payable(_charityAddress);
        _isExcludedFromFee[CharityWallet] = true;
        return true;
    }

    //To set dev address from time to time
    function setDevWallet(address payable _address) external onlyOwner returns (bool){
        devWallet = _address;
        _isExcludedFromFee[devWallet] = true;
        return true;
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }


    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }


    function totalFeesCharged() public view returns (uint256) {
        return _tFeeTotal;
    }


    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        valuesFromGetValues memory s = _getValues(tAmount, false);
        _rOwned[sender] -= s.rAmount;
        _rTotal -= s.rAmount;
        _tFeeTotal += tAmount;
    }


    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            valuesFromGetValues memory s = _getValues(tAmount, false);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rTransferAmount;
        }
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }


    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function excludeFromReward(address[] memory accounts) public onlyOwner() {
        uint256 length = accounts.length;
        for(uint256 i=0;i<length;i++)
        {
        require(!_isExcluded[accounts[i]], "Account is already excluded");
        if(_rOwned[accounts[i]] > 0) {
            _tOwned[accounts[i]] = tokenFromReflection(_rOwned[accounts[i]]);
        }
        _isExcluded[accounts[i]] = true;
        _excluded.push(accounts[i]);
        }
    }


    function includeInReward(address account) external onlyOwner() {
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
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    receive() external payable {}


    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal     = _rTotal-rFee;
        _tFeeTotal  = _tFeeTotal+tFee;
    }


    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rFee, to_return.rSwap) = _getRValues(to_return,tAmount, takeFee, _getRate());
        return to_return;
    }


    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {
        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        s.tFee = tAmount*appliedFees.totFees*appliedFees.taxFee/1000000;
        s.tSwap = tAmount*appliedFees.totFees*appliedFees.swapFee/1000000;
        s.tTransferAmount = tAmount-s.tFee-s.tSwap;
        return s;
    }


    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 rAmount = tAmount*currentRate;
        if(!takeFee)
        {
            return (rAmount,rAmount,0,0);
        }
        uint256 rFee = s.tFee*currentRate;
        uint256 rSwap = s.tSwap*currentRate;
        uint256 rTransferAmount = rAmount-rFee-rSwap;
        return (rAmount, rTransferAmount, rFee, rSwap);
    }


    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }


    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        uint256 length = _excluded.length;    
        for (uint256 i = 0; i < length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply -=_rOwned[_excluded[i]];
            tSupply -=_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeSwapFees(uint256 rSwap, uint256 tSwap) private {

        _rOwned[address(this)] +=rSwap;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] +=tSwap;
    }
    

    function setBuyFees(uint256 taxFee, uint256 devFee, uint256 marketingFee, uint256 giveawaysFee, uint256 iBNBPoolFee) external onlyOwner{
        buyFees.taxFee = taxFee;
        buyFees.devFee = devFee;
        buyFees.marketingFee = marketingFee;
        buyFees.giveawaysFee = giveawaysFee;
        buyFees.iBNBPoolFee = iBNBPoolFee;
        buyFees.swapFee = devFee+marketingFee+giveawaysFee+iBNBPoolFee;
        require(buyFees.swapFee+buyFees.taxFee == 10000, "sum of all percentages should be 10000");
    }
    
    function setSellFees(uint256 sellTaxFee, uint256 sellDevFee, uint256 sellMarketingFee, uint256 sellGiveawaysFee, uint256 sellIBNBPoolFee) external onlyOwner{
        sellFees.taxFee = sellTaxFee;
        sellFees.devFee = sellDevFee;
        sellFees.marketingFee = sellMarketingFee;
        sellFees.giveawaysFee = sellGiveawaysFee;
        sellFees.iBNBPoolFee = sellIBNBPoolFee;
        sellFees.swapFee = sellDevFee+sellMarketingFee+sellGiveawaysFee+sellIBNBPoolFee;
        require(sellFees.swapFee+sellFees.taxFee == 10000, "sum of all percentages should be 10000");
    }
    
    function setTotalBuyFees(uint256 _totFees) external onlyOwner{
        buyFees.totFees = _totFees;
    }
    
    function setTotalSellFees(uint256 _totSellFees) external onlyOwner{
        sellFees.totFees = _totSellFees;
    }
    
    function setMaxSellAmountPerDay(uint256 amount) external onlyOwner{
        maxSellPerDay = amount * 10**9;
    }
    
    function setAntiwhaleMeasure(uint256[3] memory selling_thresholds, uint256[3] memory extra_taxes ) external onlyOwner{
        //values of selling_threshold (are values in input)/1000 % of total supply , extra taxes are expressed in %
        antiwhale_measures[0] = antiwhale({selling_threshold: _tTotal*selling_thresholds[0]/100000 , extra_tax: extra_taxes[0]});
        antiwhale_measures[1] = antiwhale({selling_threshold: _tTotal*selling_thresholds[1]/100000 , extra_tax: extra_taxes[1]});
        antiwhale_measures[2] = antiwhale({selling_threshold: _tTotal*selling_thresholds[2]/100000 , extra_tax: extra_taxes[2]});
    }

    function setSwapEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
        emit swapEnabledUpdated(_enabled);
    }
    
    function setNumTokensTosSwap(uint256 amount) external onlyOwner{
        minTokensToSwap = amount * 10**9;
    }
    
    function setMaxTxAmount(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10**9;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

        function getAntiwhaleFee(uint256 amount) internal view returns(uint256 sell_tax) {
    
        if(amount < antiwhale_measures[0].selling_threshold) {
          sell_tax=0;
        }
        else if(amount < antiwhale_measures[1].selling_threshold) {
          sell_tax = antiwhale_measures[0].extra_tax;
        }
        else if(amount < antiwhale_measures[2].selling_threshold) {
          sell_tax = antiwhale_measures[1].extra_tax;
        }
        else { sell_tax = antiwhale_measures[2].extra_tax; }

      return sell_tax;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBadActor[from] && !_isBadActor[to], "Bots are not allowed");
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            require(amount <= maxTxAmount, 'you are exceeding maxTxAmount');
        }
        
        if(!_isExcludedFromFee[from] && to == pancakePair){
            if(block.timestamp < _firstSell[from]+24 * 1 hours){
                require(_totSells[from]+amount <= maxSellPerDay, "You can't sell more than maxSellPerDay");
                _totSells[from] += amount;
            }
            else{
                require(amount <= maxSellPerDay, "You can't sell more than maxSellPerDay");
                _firstSell[from] = block.timestamp;
                _totSells[from] = amount;
            }
                
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalance = contractTokenBalance >= minTokensToSwap;
        if (
            overMinTokenBalance &&
            !inSwap &&
            from != pancakePair &&
            swapEnabled
        ) {
            contractTokenBalance = minTokensToSwap;
            swapAndSendToFees(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        bool isSale = false;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        } else
        {
            if(to == pancakePair){
            isSale = true;
            }
        }
             
        // transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee, isSale);
    }
    
    function swapAndSendToFees(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(tokens);
        uint256 transferBalance = address(this).balance-initialBalance;
        devWallet.sendValue(transferBalance*appliedFees.devFee/appliedFees.swapFee);
        CharityWallet.sendValue(transferBalance*appliedFees.giveawaysFee/appliedFees.swapFee);
        RewardPool.sendValue(transferBalance*appliedFees.iBNBPoolFee/appliedFees.swapFee);
        MarketingAddress.sendValue(address(this).balance);

    }


    function swapTokensForBNB(uint256 tokenAmount) private lockTheSwap {

        // generate the pancakeswap pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        if(allowance(address(this), address(pancakeRouter)) < tokenAmount) {
          _approve(address(this), address(pancakeRouter), ~uint256(0));
        }

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }


    // this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee, bool isSale) private {
        if(takeFee){
            if(isSale)
            {
            appliedFees = sellFees;
            appliedFees.totFees += getAntiwhaleFee(_totSells[sender]);
            }
            else
            {
            appliedFees = buyFees;
            }
        }
        
        valuesFromGetValues memory s = _getValues(amount, takeFee);

        if (_isExcluded[sender]) {
            _tOwned[sender] -=amount;
        } 
        if (_isExcluded[recipient]) {
            _tOwned[recipient] += s.tTransferAmount;
        }
        _rOwned[sender] -= s.rAmount;
        _rOwned[recipient] +=s.rTransferAmount;
        
        if(takeFee)
            {
             _takeSwapFees(s.rSwap,s.tSwap);
             _reflectFee(s.rFee, s.tFee);
             emit Transfer(sender, address(this), s.tSwap);
            }
        emit Transfer(sender, recipient, s.tTransferAmount);
    }
    
            //////////////////////////
           /// Emergency functions //
          //////////////////////////


    function rescueBNBFromContract() external onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }
    
    function manualSwap() external onlyOwner{
        uint256 tokensToSwap = balanceOf(address(this));
        swapTokensForBNB(tokensToSwap);
    }
    
    function manualSend() external onlyOwner{
        swapAndSendToFees(balanceOf(address(this)));
    }


    // To be used for snipe-bots and bad actors communicated on with the community.
    function badActorDefenseMechanism(address account, bool isBadActor) external onlyOwner{
        _isBadActor[account] = isBadActor;
    }
    
    function checkBadActor(address account) public view returns(bool){
        return _isBadActor[account];
    }
    
}