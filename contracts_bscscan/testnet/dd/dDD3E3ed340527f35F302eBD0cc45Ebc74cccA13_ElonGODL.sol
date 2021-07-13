/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

/**
   ElonGODL
  
   The new standard for meme tokens.
   
   Fair lottery draw every 50 transactions.

   3% liquidity tax
   2% lottery tax
   2% marketing tax
   1% burn tax
   
   Tax rates double for sellers.
   
   HODL!
 */

pragma solidity 0.8.6;
// SPDX-License-Identifier: Unlicensed

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
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);


    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract ElonGODL is IERC20, Ownable {
    string private _name = "ElonGODL";
    string private _symbol = "ElonGODL";
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 100000000000 * 10**9;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;
    
    uint256 private _liquidityTaxRate = 3;
    uint256 private _liquidityBalance = 0;
    uint256 private _liquiditySwapAmount = 1000000 * 10**9;
    
    uint256 private _burnTaxRate = 1;
    address private _burnAddress = 0x000000000000000000000000000000000000dEaD;
    
    uint256 private _marketingTaxRate = 2;
    uint256 private _marketingBalance = 0;
    address private _marketingAddress = 0x8DdC70477Fe03fd618a247713E30852027f1d163; // for eth balance, not token balance tracking
    uint256 private _marketingSwapAmount = 1000000 * 10**9;
    
    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;
    
    bool private _isDoingTask = false;
    
    modifier lockTasks {
        _isDoingTask = true;
        _;
        _isDoingTask = false;
    }
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapAndTransferToMarketing(
        uint256 tokensSwapped,
        uint256 ethReceived
    );
    
    event LotteryDraw(
        address account,
        uint256 amount
    );

    constructor() {
        _balances[owner()] = _totalSupply;
        
        // create uniswap router and pair
        _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        // exclude system addresses from holder actions
        _isExcluded[address(this)] = true;
        _isExcluded[owner()] = true;
        
        emit Transfer(address(0), owner(), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function isExcluded(address account) public view returns(bool) {
        return _isExcluded[account];
    }
    
    function liquidityTaxRate() public view returns (uint256) {
        return _liquidityTaxRate;
    }
    
    function liquidityBalance() public view returns (uint256) {
        return _liquidityBalance;
    }
    
    function liquiditySwapAmount() public view returns (uint256) {
        return _liquiditySwapAmount;
    }
    
    function setLiquiditySwapAmount(uint256 amount) public onlyOwner {
        _liquiditySwapAmount = amount;
    }
    
    function marketingTaxRate() public view returns (uint256) {
        return _marketingTaxRate;
    }
    
    function marketingBalance() public view returns (uint256) {
        return _marketingBalance;
    }
    
    function marketingSwapAmount() public view returns (uint256) {
        return _marketingSwapAmount;
    }
    
    function setMarketingSwapAmount(uint256 amount) public onlyOwner {
        _marketingSwapAmount = amount;
    }
    
    function burnTaxRate() public view returns (uint256) {
        return _burnTaxRate;
    }
    
    function burnBalance() public view returns (uint256) {
        return balanceOf(_burnAddress);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + amount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - amount);
        return true;
    }

    function excludeAccount(address account) public onlyOwner {
        _isExcluded[account] = true;
    }
    
    function includeAccount(address account) public onlyOwner {
        _isExcluded[account] = false;
    }
    
    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        bool isSell = to == _uniswapV2Pair;
        
        // only do one task per transaction to minimize gas fees
        if (!_isDoingTask) {
            _doFirstEligibleTask(isSell);
        }
        
        // take taxes then transfer the gross amount
        uint256 taxAmount = _takeTaxes(from, to, amount, isSell);
        uint256 grossAmount = amount - taxAmount;
        
        _transferTokens(from, to, grossAmount);
    }
    
    function _doFirstEligibleTask(bool isSell) private lockTasks {
        // don't swap if sender is uniswap pair (buying)
        if (isSell) {
            if (_liquidityBalance >= _liquiditySwapAmount) {
                _swapAndLiquify(_liquiditySwapAmount);
                return;
            }
           
            if (_marketingBalance >= _marketingSwapAmount) {
                _swapAndTransferToMarketing(_marketingSwapAmount);
                return;
            }
        }
    }
    
    function _swapAndLiquify(uint256 tokenAmount) private {
        // split the contract balance into halves
        uint256 half = tokenAmount / 2;
        uint256 otherHalf = tokenAmount - half;

        // capture the contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        _swapTokensForEth(half);

        // how much ETH did we just swap into?
        uint256 ethAmount = address(this).balance - initialBalance;

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
        
        // remove amount from the liqudity balance
        _liquidityBalance -= tokenAmount;
        
        emit SwapAndLiquify(half, ethAmount, otherHalf);
    }
    
    function _swapAndTransferToMarketing(uint256 tokenAmount) private {
        // capture the contract's current ETH balance.
        uint256 initialBalance = address(this).balance;
        
        // swap tokens for ETH
        _swapTokensForEth(tokenAmount);
        
        // how much ETH did we just swap into?
        uint256 ethAmount = address(this).balance - initialBalance;
        
        // transfer eth to marketing wallet
        payable(_marketingAddress).transfer(ethAmount);
        
        // remove amount from the marketing balance
        _marketingBalance -= tokenAmount;
        
        emit SwapAndTransferToMarketing(tokenAmount, ethAmount);
    }
    
    function _takeTaxes(address sender, address recipient, uint256 transactionAmount, bool isSell) private returns(uint256) {
        // sell tax rate is 2x the standard tax rate
        uint256 factor = isSell ? 2 : 1;
        
        // dont tax transactions from/to excluded accounts
        if (_isEitherExcluded(sender, recipient)) return 0;
        
        uint256 liquidityTaxAmount = _takeLiquidityTax(sender, transactionAmount, factor);
        uint256 marketingTaxAmount = _takeMarketingTax(sender, transactionAmount, factor);
        uint256 burnTaxAmount = _takeBurnTax(sender, transactionAmount, factor);
        
        return liquidityTaxAmount + marketingTaxAmount + burnTaxAmount;
    }
    
    function _takeLiquidityTax(address sender, uint256 transactionAmount, uint256 factor) private returns(uint256) {
        uint256 taxAmount = _getTaxAmount(transactionAmount, _liquidityTaxRate, factor);
        
        _liquidityBalance += taxAmount;
        _transferTokens(sender, address(this), taxAmount);
        
        return taxAmount;
    }
    
    function _takeMarketingTax(address sender, uint256 transactionAmount, uint256 factor) private returns(uint256) {
        uint256 taxAmount = _getTaxAmount(transactionAmount, _marketingTaxRate, factor);
        
        _marketingBalance += taxAmount;
        _transferTokens(sender, address(this), taxAmount);
        
        return taxAmount;
    }
    
    function _takeBurnTax(address sender, uint256 transactionAmount, uint256 factor) private returns(uint256) {
        uint256 taxAmount = _getTaxAmount(transactionAmount, _burnTaxRate, factor);
        
        _transferTokens(sender, _burnAddress, taxAmount);
        
        return taxAmount;
    }
    
    function _transferTokens(address sender, address recipient, uint256 amount) private {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
    }
    
    function _getTaxAmount(uint256 transactionAmount, uint256 baseRate, uint256 factor) private pure returns(uint256) {
        uint256 rate = baseRate * factor;
        uint256 taxAmount = transactionAmount * rate / 100;
        
        return taxAmount;
    }
    
    function _isEitherExcluded(address sender, address recipient) private view returns(bool) {
        return _isExcluded[sender] || _isExcluded[recipient];
    }
    
    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}