//SourceUnit: TokenForJustswap.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IJustswapExchange {
    event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed
    tokens_bought);
    event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256
    indexed trx_bought);
    event AddLiquidity(address indexed provider, uint256 indexed trx_amount, uint256
    indexed token_amount);
    event RemoveLiquidity(address indexed provider, uint256 indexed trx_amount, uint256
    indexed token_amount);

    receive() external payable;

    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256
    output_reserve) external view returns (uint256);
    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256
    output_reserve) external view returns (uint256);
    function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable
    returns (uint256);
    function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address
    recipient) external payable returns(uint256);
    function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external
    payable returns(uint256);
    function trxToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address
    recipient) external payable returns (uint256);
    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline)
    external returns (uint256);
    function tokenToTrxTransferInput(uint256 tokens_sold, uint256 min_trx, uint256
    deadline, address recipient) external returns (uint256);
    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256
    deadline) external returns (uint256);
    function tokenToTrxTransferOutput(uint256 trx_bought, uint256 max_tokens, uint256
    deadline, address recipient) external returns (uint256);
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought,
    uint256 min_trx_bought, uint256 deadline, address token_addr) external returns (uint256);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought,
    uint256 min_trx_bought, uint256 deadline, address recipient, address token_addr) external
    returns (uint256);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold,
    uint256 max_trx_sold, uint256 deadline, address token_addr) external returns (uint256);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold,
    uint256 max_trx_sold, uint256 deadline, address recipient, address token_addr) external
    returns (uint256);
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought,
    uint256 min_trx_bought, uint256 deadline, address exchange_addr) external returns
    (uint256);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256
    min_tokens_bought, uint256 min_trx_bought, uint256 deadline, address recipient, address
    exchange_addr) external returns (uint256);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256
    max_tokens_sold, uint256 max_trx_sold, uint256 deadline, address exchange_addr)
    external returns (uint256);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256
    max_tokens_sold, uint256 max_trx_sold, uint256 deadline, address recipient, address
    exchange_addr) external returns (uint256);
    function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);
    function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns
    (uint256);
    function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);
    function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);
    function tokenAddress() external view returns (address);
    function factoryAddress() external view returns (address);
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline)
    external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens, uint256
    deadline) external returns (uint256, uint256);
}


// File contracts/external/IJustswapFactory.sol



interface IJustswapFactory {
    event NewExchange(address indexed token, address indexed exchange);
    function initializeFactory(address template) external;
    function createExchange(address token) external returns (address payable);
    function getExchange(address token) external view returns (address payable);
    function getToken(address token) external view returns (address);
    function getTokenWihId(uint256 token_id) external view returns (address);
}




interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}





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


contract TokenForJustswap is Context, ITRC20, Ownable {
    using SafeMath for uint256; // only for custom reverts on sub

    mapping (address => uint256) internal _rOwned;
    mapping (address => uint256) internal _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) private _isExcludedFromFee;
    mapping (address => uint256) internal _isExcludedFromReward;

    uint256 private constant MAX = type(uint256).max;
    uint256 private immutable _decimals;
    uint256 internal immutable _tTotal; // real total supply
    uint256 internal _tIncludedInReward;
    uint256 internal _rTotal;
    uint256 internal _rIncludedInReward;
    uint256 internal _tFeeTotal;

    uint256 public _taxFee;
    uint256 public _liquidityFee;
    uint256 public _feeToAddress;
    uint256 public totalBurned;

    address public immutable justswapExchange;
    address public liquidityOwner;
    address public feeBeneficiary;

    uint256 constant SWAP_AND_LIQUIFY_DISABLED = 0;
    uint256 constant SWAP_AND_LIQUIFY_ENABLED = 1;
    uint256 constant IN_SWAP_AND_LIQUIFY = 2;
    uint256 LiqStatus;

    uint256 public _maxTxAmount;
    uint256 private numTokensSellToAddToLiquidity;

    string private _name; 
    string private _symbol;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 trxReceived,
        uint256 tokensIntoLiqudity
    );
    event LiquidityOwnerChanged(address newLiquidityOwner);
    event FeeBeneficiaryChanged(address newBeneficiary);


    modifier lockTheSwap {
        LiqStatus = IN_SWAP_AND_LIQUIFY;
        _;
        LiqStatus = SWAP_AND_LIQUIFY_ENABLED;
    }

    constructor ( 
        string memory tName, 
        string memory tSymbol, 
        uint256 totalAmount,
        uint256 tDecimals, 
        uint256 tTaxFee, 
        uint256 tLiquidityFee,
        uint256 maxTxAmount,
        uint256 _numTokensSellToAddToLiquidity,
        bool _swapAndLiquifyEnabled,

        address justswapFactory
        ) {
        _name = tName;
        _symbol = tSymbol;
        _tTotal = totalAmount;
        _tIncludedInReward = totalAmount;
        _rTotal = (MAX - (MAX % totalAmount));
        _decimals = tDecimals;
        _taxFee = tTaxFee;
        _liquidityFee = tLiquidityFee;
        _maxTxAmount = maxTxAmount;
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;

        if (_swapAndLiquifyEnabled) {
            LiqStatus = SWAP_AND_LIQUIFY_ENABLED;
        }

        _rOwned[_msgSender()] = _rTotal;
        _rIncludedInReward = _rTotal;

        liquidityOwner = _msgSender();

        justswapExchange = IJustswapFactory(justswapFactory).createExchange(address(this));

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = 1;
        _isExcludedFromFee[address(this)] = 1;

        emit Transfer(address(0), _msgSender(), totalAmount);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint256) {
        return _decimals;
    }

    function totalSupply() external view override virtual returns (uint256) {
        return _tTotal - totalBurned;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function burn(uint256 amount) external returns(bool) {
        require(balanceOf(_msgSender()) >= amount, 'Not enough tokens');
        totalBurned += amount;

        if(_isExcludedFromReward[_msgSender()] == 1) {
            _tOwned[_msgSender()] -= amount;
        }
        else {
            uint256 rate = _getRate();
            _rOwned[_msgSender()] -= amount * rate;
            _tIncludedInReward -= amount;
            _rIncludedInReward -= amount * rate;
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TRC20: transfer amount exceeds allowance"));
        return true; 
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TRC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromReward[account] == 1;
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account] == 1;
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) external {
        address sender = _msgSender();
        require(_isExcludedFromReward[sender] == 0, "Forbidden for excluded addresses");
        
        uint256 rAmount = tAmount * _getRate();
        _tFeeTotal += tAmount;
        _rOwned[sender] -= rAmount;
        _rTotal -= rAmount;
        _rIncludedInReward -= rAmount;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = 1;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = 0;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal * maxTxPercent / 100;
    }

    function setNumTokensSellToAddToLiquidity(uint256 newNumTokensSellToAddToLiquidity) external onlyOwner {
        numTokensSellToAddToLiquidity = newNumTokensSellToAddToLiquidity;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        LiqStatus = _enabled ? 1 : 0;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setLiquidityOwner(address newLiquidityOwner) external onlyOwner {
        liquidityOwner = newLiquidityOwner;
        emit LiquidityOwnerChanged(newLiquidityOwner);
    }

    function setToAddressFee(uint256 newFeeToAddressPercent) external onlyOwner {
        _feeToAddress = newFeeToAddressPercent;
    }

    function setFeeBeneficiary(address newBeneficiary) external onlyOwner {
        feeBeneficiary = newBeneficiary;
        emit FeeBeneficiaryChanged(newBeneficiary);
    }

    receive() external payable {}

    function excludeFromReward(address account) public onlyOwner {
        require(_isExcludedFromReward[account] == 0, "Account is already excluded");
        if(_rOwned[account] != 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
            _tIncludedInReward -= _tOwned[account];
            _rIncludedInReward -= _rOwned[account];
            _rOwned[account] = 0;
            
        }
        _isExcludedFromReward[account] = 1;
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcludedFromReward[account] == 1, "Account is already included");

        _rOwned[account] = reflectionFromToken(_tOwned[account], false);
        _rIncludedInReward += _rOwned[account];
        _tIncludedInReward += _tOwned[account];
        _tOwned[account] = 0;
        _isExcludedFromReward[account] = 0;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account] == 1) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            return tAmount * _getRate();
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount, true);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Can't exceed total reflections");
        return rAmount / _getRate();
    }

    function _reflectFee(uint256 rFee, uint256 tFee) internal {
        if (rFee != 0) {
            _rTotal -= rFee;
            _rIncludedInReward -= rFee;
        }
        if (tFee != 0) _tFeeTotal += tFee;
    }

    function _getValues(uint256 tAmount, bool takeFee) internal view
    returns (
        uint256 rAmount, 
        uint256 rTransferAmount, 
        uint256 rFee, 
        uint256 tTransferAmount, 
        uint256 tFee, 
        uint256 tLiquidity,
        uint256 rate) {

        tTransferAmount = tAmount;
        if (takeFee) {
            tFee = tAmount * _taxFee / 100;
            tLiquidity = tAmount * _liquidityFee / 100;
            tTransferAmount -= tLiquidity + tFee + (tAmount*_feeToAddress)/100;
        }
        
        rate = _getRate();

        rAmount = rate * tAmount;
        rFee = rate * tFee;
        rTransferAmount = rate * tTransferAmount;
    }

    function _getRate() internal view returns(uint256) {
        uint256 rIncludedInReward = _rIncludedInReward; // gas savings

        uint256 koeff = _rTotal / _tTotal;

        if (rIncludedInReward < koeff) return koeff;
        return rIncludedInReward / _tIncludedInReward;
    }

    function _takeLiquidity(uint256 tLiquidity, uint256 rate) internal {
        if (tLiquidity == 0) return;
        
        if(_isExcludedFromReward[address(this)] == 1) {
            _tOwned[address(this)] += tLiquidity;
            _tIncludedInReward -= tLiquidity;
            _rIncludedInReward -= tLiquidity * rate;
        }
        else {
            _rOwned[address(this)] += tLiquidity * rate;
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "TRC20: transfer from the zero address");
        require(to != address(0), "TRC20: transfer to the zero address");
        require(amount != 0, "Transfer amount can't be zero");

        address __owner = owner();
        if(from != __owner && to != __owner)
            require(amount <= _maxTxAmount, "Amount exceeds the maxTxAmount");


        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity; // gas savings
        if (
            balanceOf(address(this)) >= _numTokensSellToAddToLiquidity &&
            _maxTxAmount >= _numTokensSellToAddToLiquidity &&
            LiqStatus == SWAP_AND_LIQUIFY_ENABLED &&
            from != justswapExchange
        ) {
            //add liquidity
            _swapAndLiquify(_numTokensSellToAddToLiquidity);
        }

        //if any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = _isExcludedFromFee[from] == 0 && _isExcludedFromFee[to] == 0 && to != justswapExchange;

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function getOptimalAmountToSell(int X, int dX) private pure returns(uint256) {
        int denom = 1000000;
        int f = 997000;
        dX = dX - 1;
        unchecked {
            int T1 = X*(X*(denom + f)**2 + 4*denom*dX*f);

            // square root
            int z = (T1 + 1) / 2;
            int sqrtT1 = T1;
            while (z < sqrtT1) {
                sqrtT1 = z;
                z = (T1 / z + z) / 2;
            }

            return uint(
                ( 2*denom*dX*X )/
                ( sqrtT1 + X*(denom + f) )
            );
        }
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into parts
        uint256 part = getOptimalAmountToSell(int(balanceOf(justswapExchange)), int(contractTokenBalance));
        uint256 otherPart = contractTokenBalance - part;

        // capture the contract's current trx balance.
        // this is so that we can capture exactly the amount of trx that the
        // swap creates, and not make the liquidity event include any trx that
        // has been manually sent to the contract
        uint256 currentBalance = address(this).balance;

        // swap tokens for trx
        _swapTokensForTrx(part);

        // how much trx did we just swap into?
        currentBalance = address(this).balance - currentBalance;

        // we can receive a bit more TRX than required
        uint amountOfTrxForToken = (justswapExchange.balance*(otherPart - 1))/balanceOf(justswapExchange);
        if (amountOfTrxForToken < currentBalance) {
            currentBalance = amountOfTrxForToken;
        }

        // add liquidity to justswap
        _addLiquidity(otherPart, currentBalance);

        emit SwapAndLiquify(part, currentBalance, otherPart);
    }

    function _swapTokensForTrx(uint256 tokenAmount) private returns(uint256) {
        _approve(address(this), justswapExchange, tokenAmount);

        // make the swap
        return IJustswapExchange(payable(justswapExchange)).tokenToTrxSwapInput(
            tokenAmount, 
            1, // accept any amount of TRX 
            MAX
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 trxAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), justswapExchange, tokenAmount);

        // add the liquidity
        uint256 liq =  IJustswapExchange(payable(justswapExchange)).addLiquidity{value: trxAmount}(
            1, // slippage is unavoidable 
            tokenAmount, 
            MAX
        );
        ITRC20(justswapExchange).transfer(liquidityOwner, liq);

    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal virtual {
        if (takeFee) {
            _tokenTransfer(sender, feeBeneficiary, (amount*_feeToAddress)/100, false);
        }
            
        (uint256 rAmount, uint256 rTransferAmount, 
        uint256 rFee, uint256 tTransferAmount, 
        uint256 tFee, uint256 tLiquidity,
        uint256 rate) = _getValues(amount, takeFee);

        {
            bool isSenderExcluded = _isExcludedFromReward[sender] == 1;
            bool isRecipientExcluded = _isExcludedFromReward[recipient] == 1;

            if (isSenderExcluded) {
                _tOwned[sender] -= amount;
                
                if (isRecipientExcluded) {
                    _tIncludedInReward += tFee + tLiquidity;
                    _rIncludedInReward += rFee + tLiquidity * rate;  
                } else {
                    _tIncludedInReward += amount;
                    _rIncludedInReward += rAmount;              
                }
            } else {
                _rOwned[sender] -= rAmount;
            }

            if (isRecipientExcluded) {
                _tOwned[recipient] += tTransferAmount;

                if (!isSenderExcluded) {
                    _tIncludedInReward -= tTransferAmount;
                    _rIncludedInReward -= rTransferAmount;
                }
            } else {
                _rOwned[recipient] += rTransferAmount;
            }
        }

        
        _takeLiquidity(tLiquidity, rate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}