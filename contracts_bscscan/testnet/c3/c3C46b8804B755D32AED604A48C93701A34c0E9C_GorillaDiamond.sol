/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

/**
   #GORILLA DIAMOND INCORPORATED:
   5% fee divided into 2.5% burn & 2.5% fee auto add to the liquidity pool.
   6% fee auto distribute to all holders.
   Website: https://www.gorilladiamond.com
   Discord Server: https://discord.gg/Es4SxUh2WE
   Telegram: https://t.me/gorilladiamond
   Twitter: https://twitter.com/GorillaDiamondT
   Reddit: https://www.reddit.com/r/GorillaDiamondInc/
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

interface IERC20 {
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
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
        uint deadline
    ) external;
}

contract GorillaDiamond is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint256 private constant MAX = ~uint256(0);

    mapping (address => uint256) public tokensOwned;
    mapping (address => uint256) public reflectionsOwned;
    mapping (address => mapping (address => uint256)) public override allowance;

    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isExcludedFromReward;
    address[] private _excluded;

    uint256 public constant override totalSupply = 1000000000 * 10**6 * 10**9;
    uint256 public totalReflections = (MAX - (MAX % totalSupply));
    uint256 public totalFees;

    string public constant name = "GorillaDiamond";
    string public constant symbol = "GDT";
    uint8 public constant decimals = 9;
    
    uint256 public _taxFee = 6; // REFLECTION RATE
    uint256 public _liquidityFee = 5; // BURN RATE

    IUniswapV2Router public constant uniswapV2Router = IUniswapV2Router(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    address public immutable uniswapV2Pair;
    
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public _maxTxAmount = 5000000 * 10**6 * 10**9;
    uint256 private immutable numTokensSellToAddToLiquidity = 500000 * 10**6 * 10**9;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    
    constructor () public {
        reflectionsOwned[_msgSender()] = totalReflections;
        
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        
        //exclude owner and this contract from fee
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), totalSupply);
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, allowance[_msgSender()][spender].add(addedValue));

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, allowance[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));

        return true;
    }

    function reflectionFromToken(uint256 tokenAmount, bool deductTransferFee) public view returns (uint256) {
        require(tokenAmount <= totalSupply, "Amount must be less than supply");

        (uint256 reflectionAmount, uint256 reflectionTransferAmount,,,,) = _getValues(tokenAmount);

        return deductTransferFee ? reflectionTransferAmount : reflectionAmount;
    }

    function tokenFromReflection(uint256 reflectionAmount) public view returns (uint256) {
        require(reflectionAmount <= totalReflections, "Amount must be less than total reflections");

        return reflectionAmount.div(_getRate());
    }

    function excludeFromReward(address account) public onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!isExcludedFromReward[account], "Account is already excluded");

        if (reflectionsOwned[account] > 0) {
            tokensOwned[account] = tokenFromReflection(reflectionsOwned[account]);
        }

        isExcludedFromReward[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(isExcludedFromReward[account], "Account is already excluded");

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                tokensOwned[account] = 0;
                isExcludedFromReward[account] = false;
                _excluded.pop();

                break;
            }
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return isExcludedFromReward[account] ? tokensOwned[account] : tokenFromReflection(reflectionsOwned[account]);
    }
    
    function excludeFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }
   
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = totalSupply.mul(maxTxPercent).div(10**2);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;

        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function _getTokenValues(uint256 amount) private view returns (uint256 transferAmount, uint256 fee, uint256 liquidity) {
        fee = amount.mul(_taxFee).div(10**2);
        liquidity = amount.mul(_liquidityFee).div(10**2);
        transferAmount = amount.sub(fee).sub(liquidity);

        return (transferAmount, fee, liquidity);
    }

    function _getReflectionValues(
        uint256 tokenAmount,
        uint256 tokenFee,
        uint256 tokenLiquidity,
        uint256 currentRate
    ) internal pure returns (uint256 amount, uint256 transferAmount, uint256 fee) {
        amount = tokenAmount.mul(currentRate);
        fee = tokenFee.mul(currentRate);

        uint256 reflectionLiquidity = tokenLiquidity.mul(currentRate);
        transferAmount = amount.sub(fee).sub(reflectionLiquidity);

        return (amount, transferAmount, fee);
    }

    function _getCurrentSupply() internal view returns (uint256 reflectionSupply, uint256 tokenSupply) {
        reflectionSupply = totalReflections;
        tokenSupply = totalSupply;

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (reflectionsOwned[_excluded[i]] > reflectionSupply || tokensOwned[_excluded[i]] > tokenSupply) return (totalReflections, totalSupply);

            reflectionSupply = reflectionSupply.sub(reflectionsOwned[_excluded[i]]);
            tokenSupply = tokenSupply.sub(tokensOwned[_excluded[i]]);
        }

        return reflectionSupply < totalReflections.div(totalSupply) ? (totalReflections, totalSupply) : (reflectionSupply, tokenSupply);
    }

    function _getRate() internal view returns (uint256) {
        (uint256 reflectionSupply, uint256 tokenSupply) = _getCurrentSupply();

        return reflectionSupply.div(tokenSupply);
    }

    function _getValues(uint256 tokenAmount) internal view returns (
        uint256 reflectionAmount,
        uint256 reflectionTransferAmount,
        uint256 reflectionFee,
        uint256 tokenTransferAmount,
        uint256 tokenFee,
        uint256 tokenLiquidity
    ) {
        (tokenTransferAmount, tokenFee, tokenLiquidity) = _getTokenValues(tokenAmount);
        (reflectionAmount, reflectionTransferAmount, reflectionFee) = _getReflectionValues(tokenAmount, tokenFee, tokenLiquidity, _getRate());

        return (reflectionAmount, reflectionTransferAmount, reflectionFee, tokenTransferAmount, tokenFee, tokenLiquidity);
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();

        require(!isExcludedFromReward[sender], "Excluded addresses cannot call this function");

        (uint256 reflectionAmount,,,,,) = _getValues(tAmount);

        reflectionsOwned[sender] = reflectionsOwned[sender].sub(reflectionAmount);
        totalReflections = totalReflections.sub(reflectionAmount);
        totalFees = totalFees.add(tAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    function _swapTokensForEth(uint256 tokenAmount) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _swapAndLiquify(uint256 amount) internal lockTheSwap {
        // split the amount into halves
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        _swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        _addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _transferStandard(address sender, address recipient, uint256 tokenAmount) internal returns (uint256) {
        (uint256 reflectionAmount, uint256 reflectionTransferAmount, uint256 reflectionFee, uint256 tokenTransferAmount, uint256 tokenFee, uint256 tokenLiquidity) = _getValues(tokenAmount);

        reflectionsOwned[sender] = reflectionsOwned[sender].sub(reflectionAmount);
        reflectionsOwned[recipient] = reflectionsOwned[recipient].add(reflectionTransferAmount);

        // take liquidity
        uint256 reflectionLiquidity = tokenLiquidity.mul(_getRate());
        reflectionsOwned[address(this)] = reflectionsOwned[address(this)].add(reflectionLiquidity);

        if (isExcludedFromReward[address(this)]) {
          tokensOwned[address(this)] = tokensOwned[address(this)].add(tokenLiquidity);
        }
        
        // reflect fee
        totalReflections = totalReflections.sub(reflectionFee);
        totalFees = totalFees.add(tokenFee);

        emit Transfer(sender, recipient, tokenTransferAmount);

        return tokenTransferAmount;
    }

    // This method is responsible for taking all fee, if possible
    function _tokenTransfer(address sender, address recipient, uint256 amount) internal {
        // if any account belongs to isExcludedFromFee account then remove the fee from transfer
        bool takeFee = !isExcludedFromFee[sender] && !isExcludedFromFee[recipient];
        uint256 previousTaxFee;
        uint256 previousLiquidityFee;

        if (!takeFee) {
            previousTaxFee = _taxFee;
            previousLiquidityFee = _liquidityFee;
            _taxFee = 0;
            _liquidityFee = 0;
        }

        uint256 tokenTransferAmount;

        if (isExcludedFromReward[sender]) {
            if (isExcludedFromReward[recipient]) {
                tokenTransferAmount = _transferStandard(sender, recipient, amount);
                tokensOwned[sender] = tokensOwned[sender].sub(amount);
                tokensOwned[recipient] = tokensOwned[recipient].add(tokenTransferAmount);
            } else {
                _transferStandard(sender, recipient, amount);
                tokensOwned[sender] = tokensOwned[sender].sub(amount);
            }
        } else {
            if (isExcludedFromReward[recipient]) {
                tokenTransferAmount = _transferStandard(sender, recipient, amount);
                tokensOwned[recipient] = tokensOwned[recipient].add(tokenTransferAmount);
            } else {
                _transferStandard(sender, recipient, amount);
            }
        }
        
        if (!takeFee) {
            _taxFee = previousTaxFee;
            _liquidityFee = previousLiquidityFee;
        }
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(from == owner() || to == owner() || amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        if (
            swapAndLiquifyEnabled &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            contractTokenBalance >= numTokensSellToAddToLiquidity
        ) {
            // add liquidity
            _swapAndLiquify(numTokensSellToAddToLiquidity);
        }
        
        // transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

        return true;
    }

    // to receive ETH from uniswapV2Router when swapping
    receive() external payable {
    }
}