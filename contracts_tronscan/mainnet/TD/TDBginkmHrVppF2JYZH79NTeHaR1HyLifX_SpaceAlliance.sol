//SourceUnit: SpaceAlliance.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity >=0.6.0 <0.8.0;
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
    constructor () public {
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

interface IJustswapFactory {
    event NewExchange(address indexed token, address indexed exchange);
    function initializeFactory(address template) external;
    function createExchange(address token) external returns (address payable);
    function getExchange(address token) external view returns (address payable);
    function getToken(address token) external view returns (address);
    function getTokenWihId(uint256 token_id) external view returns (address);
}


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



pragma solidity >=0.6.0 <0.8.0;

contract SpaceAlliance is Context, ITRC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) private _isExcludedFromFee;
    mapping (address => uint256) private _isExcludedFromReward;
    address[] private _excludedFromReward;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _decimals = 8;
    uint256 private constant _tTotal = 10**11 * 10**8;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 public _taxFeeBuy = 3;
    uint256 public _taxFeeSell = 9;

    uint256 public _liquidityFee = 3;

    uint256 private withdrawableBalance;

    IJustswapExchange public justswapExchange;

    uint256 constant SWAP_AND_LIQUIFY_DISABLED = 0;
    uint256 constant SWAP_AND_LIQUIFY_ENABLED = 1;
    uint256 constant IN_SWAP_AND_LIQUIFY = 2;
    uint256 LiqStatus = SWAP_AND_LIQUIFY_ENABLED;

    uint256 public _maxTxAmount = ~uint256(0);
    uint256 public numTokensSellToAddToLiquidity = 10**8 * 10**8;

    string private constant _name = 'Space Alliance';
    string private constant _symbol = 'SPACE';
    bool exchangeCreated=false;
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 TRXReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        LiqStatus = IN_SWAP_AND_LIQUIFY;
        _;
        LiqStatus = SWAP_AND_LIQUIFY_ENABLED;
    }

    receive() external payable {}

    constructor (address addr) public {
        _rOwned[addr] = _rTotal;

        //exclude owner and this contract from fee
        _isExcludedFromFee[addr] = 1;
        _isExcludedFromFee[address(this)] = 1;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function createExchange( address addr) public{
        require(_msgSender() == owner());
        require(!exchangeCreated);
        justswapExchange = IJustswapExchange(
            IJustswapFactory(addr).createExchange(address(this))
        );
        exchangeCreated = true;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account] == 1) return _tOwned[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TRC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TRC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account] == 1;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account] == 1;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Can't exceed total reflections");
        return rAmount.div(_getRate());
    }

    function excludeFromReward(address account) public onlyOwner {
        require(_isExcludedFromReward[account] == 0, "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = 1;
        _excludedFromReward.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcludedFromReward[account] == 1, "Account is already included");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length.sub(1)];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = 0;
                _excludedFromReward.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = 1;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = 0;
    }

    function setTaxFeeBuyPercent(uint256 taxFee) public onlyOwner {
        _taxFeeBuy = taxFee;
    }

    function setTaxFeeSellPercent(uint256 taxFee) public onlyOwner {
        _taxFeeSell = taxFee;
    }


    function setLiquidityFeePercent(uint256 liquidityFee) public onlyOwner {
        _liquidityFee = liquidityFee;
    }


    function setMaxTxPercent(uint256 maxTxPercent) public onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(100);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        LiqStatus = _enabled ? 1 : 0;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setNumTokensSellToAddToLiquidity(uint256 _numTokensSellToAddToLiquidity) public onlyOwner {
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        if (rFee != 0) _rTotal = _rTotal.sub(rFee);
        if (tFee != 0) _tFeeTotal = tFee.add(_tFeeTotal);
    }

    function _getValues(uint256 tAmount, uint256 taxFee, uint256 liqFee) private view
    returns (
        uint256 rAmount,
        uint256 rTransferAmount,
        uint256 rFee,
        uint256 tTransferAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 rate) {

        tFee = tAmount.mul(taxFee).div(100);
        tLiquidity = tAmount.mul(liqFee).div(100);
        tTransferAmount = tAmount.sub(tLiquidity).sub(tFee);
        rate = _getRate();

        rAmount = rate.mul(tAmount);
        rFee = rate.mul(tFee);
        rTransferAmount = rate.mul(tTransferAmount);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rTotal_ = _rTotal;
        uint256 rSupply = rTotal_;

        uint256 tTotal_ = _tTotal;
        uint256 tSupply = tTotal_;

        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            address excludedFromReward = _excludedFromReward[i];
            uint256 rOwned = _rOwned[excludedFromReward];
            uint256 tOwned = _tOwned[excludedFromReward];

            if (rOwned > rSupply || tOwned > tSupply) return (rTotal_, tTotal_);
            rSupply = rSupply.sub(rOwned);
            tSupply = tSupply.sub(tOwned);
        }
        if (rSupply < rTotal_.div(tTotal_)) return (rTotal_, tTotal_);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity, uint256 rate) private {
        if (tLiquidity == 0) return;

        _rOwned[address(this)] = _rOwned[address(this)].add(tLiquidity.mul(rate));

        if(_isExcludedFromReward[address(this)] == 1)
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
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
        require(amount > 0, "Transfer amount can't be zero");

        address __owner = owner();
        if(from != __owner && to != __owner)
            require(amount <= _maxTxAmount, "Amount exceeds the maxTxAmount");


        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap+liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is justswap pair.

        bool overMinTokenBalance;
        if (balanceOf(address(this)) >= numTokensSellToAddToLiquidity) {
            if (_maxTxAmount >= numTokensSellToAddToLiquidity) {
                overMinTokenBalance = true;
            }
        }

        if (
            overMinTokenBalance &&
            LiqStatus == SWAP_AND_LIQUIFY_ENABLED &&
            from != address(justswapExchange)
        ) {
            //add liquidity
            _swapAndLiquify(numTokensSellToAddToLiquidity);
        }

        //if any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = _isExcludedFromFee[from] == 0 && _isExcludedFromFee[to] == 0;

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // swap tokens for TRX
        uint256 currentBalance = _swapTokensForTRX(half);
        require(otherHalf > 0 && currentBalance > 0, 'Swap failed');

        // add liquidity to justswap
        require(_addLiquidity(otherHalf, currentBalance) != 0, 'Liquidity failed');

        // fix the forever locked TRXs as per the certik's audit for SafeMoon
        withdrawableBalance = address(this).balance;
        emit SwapAndLiquify(half, currentBalance, otherHalf);
    }

    function _swapTokensForTRX(uint256 tokenAmount) private returns(uint256) {
        _approve(address(this), address(justswapExchange), tokenAmount);

        // make the swap

        return justswapExchange.tokenToTrxSwapInput(
            tokenAmount,
            1, // accept any amount of TRX
            MAX
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 TRXAmount) private returns(uint256) {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(justswapExchange), tokenAmount);

        // add the liquidity
        return justswapExchange.addLiquidity{value: TRXAmount}(
            1, // slippage is unavoidable
            tokenAmount,
            MAX
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        bool sale = recipient == address(justswapExchange) ? true : false;

        (uint256 rAmount, uint256 rTransferAmount,
        uint256 rFee, uint256 tTransferAmount,
        uint256 tFee, uint256 tLiquidity,
        uint256 rate) = sale ? _getValues(amount, takeFee ? _taxFeeSell : 0, takeFee ? _liquidityFee : 0) :
        _getValues(amount, takeFee ? _taxFeeBuy : 0, takeFee ? _liquidityFee : 0);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] += rTransferAmount;

        if (_isExcludedFromReward[sender] == 1) {
            _tOwned[sender] = _tOwned[sender].sub(amount);
        }

        if (_isExcludedFromReward[recipient] == 1) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }

        _takeLiquidity(tLiquidity, rate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
/**
     * @dev The owner can withdraw TRX collected in the contract from `swapAndLiquify`
     * or if someone (accidentally) sends TRX directly to the contract.
     *
     * Note: This addresses the contract flaw pointed out in the Certik Audit of Safemoon (SSL-03):
     *
     * The swapAndLiquify function converts half of the contractTokenBalance SafeMoon tokens to BNB.
     * For every swapAndLiquify function call, a small amount of BNB remains in the contract.
     * This amount grows over time with the swapAndLiquify function being called
     * throughout the life of the contract. The Safemoon contract does not contain a method
     * to withdraw these funds, and the BNB will be locked in the Safemoon contract forever.
     * https://www.certik.org/projects/safemoon
     */
    function withdrawLockedTRX(address payable recipient) external onlyOwner {
        require(recipient != address(0), "Cannot withdraw the TRX balance to the zero address");
        require(withdrawableBalance > 0, "The TRX balance must be greater than 0");

        // prevent re-entrancy attacks
        uint256 amount = withdrawableBalance;
        withdrawableBalance = 0;
        recipient.transfer(amount);
    }
}