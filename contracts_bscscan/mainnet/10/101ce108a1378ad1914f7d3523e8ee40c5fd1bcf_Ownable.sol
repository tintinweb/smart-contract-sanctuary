/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

/*


███████╗░█████╗░███╗░░░███╗░█████╗░██████╗░░█████╗░██████╗░██╗░░░██╗
██╔════╝██╔══██╗████╗░████║██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚██╗░██╔╝
█████╗░░██║░░██║██╔████╔██║██║░░██║██████╦╝███████║██████╦╝░╚████╔╝░
██╔══╝░░██║░░██║██║╚██╔╝██║██║░░██║██╔══██╗██╔══██║██╔══██╗░░╚██╔╝░░
██║░░░░░╚█████╔╝██║░╚═╝░██║╚█████╔╝██████╦╝██║░░██║██████╦╝░░░██║░░░
╚═╝░░░░░░╚════╝░╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░

Telegram: https://t.me/fomobaby
Twitter: https://twitter.com/fomobabybsc
Website: https://fomobaby.app/

Fomo Baby is a deflationary rebasing token with an automated liquidity feature, Staking options, NFT’s & Lottery Draws. Our rebasing feature is mathematically structured to increase the price which will cause the 
charts to constantly stay green.

*/


// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



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

interface ISwapFactory {
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

interface ISwapPair {
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

    event Mint(address indexed sender, uint amount0, uint amount1);
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface ISwapRouter01 {
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


interface ISwapRouter02 is ISwapRouter01 {
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



abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
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


contract FOMOBABY is IERC20, Ownable {
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10 * 10**15 * 10**DECIMALS;
    uint256 private constant BP_DIVISOR = 10000;
    
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    string private constant NAME = "FOMO BABY"; 
    string private constant SYMBOL = "FOMOBABY"; 
    uint8 private constant DECIMALS = 9;

    uint256 public liquidityTax = 500;
    uint256 public marketingTax = 200;
    uint256 public lotteryTax = 200;
    uint256 public transactionTax = liquidityTax + marketingTax + lotteryTax;
    uint256 public numTokensSellDivisor = 10000;

    ISwapRouter02 public swapRouter;
    address public swapPair;
    address public marketingWallet = 0xc52d8528a3FaF385125b7b63FEDe18e838F76aCd;
    address public lotteryWallet = 0x62151E16b852cEb0668063864888c0BFd070c45c;
    address public operator;
    uint256 private marketingWalletHoldings;
    uint256 public maxTx = 100;
    uint256 public maxWallet = 50;

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    mapping (address => bool) private _isExcluded;    
    mapping (address => bool) private _isMaxTxExcluded;
    mapping(address => bool) public isBlacklisted;
    uint256 public launchTime;

    // TOTAL_FOMOS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _fomosPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_FOMOS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_FOMOS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;
    uint256 public _fomosPerFragment;
    mapping(address => uint256) public _fomoBalances;

    // This is denominated in Fragments, because the fomos-fragments conversion might change before it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedFragments;
    
    event LogRebase (uint256 indexed epoch, uint256 totalSupply);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    modifier onlyOperator {
        require (msg.sender == operator || msg.sender == owner(), "FOMOBABY: Not authorised");
        _;
    }

    constructor (uint256 marketingWalletPercentage) {
        ISwapRouter02 _swapRouter = ISwapRouter02 (0x10ED43C718714eb63d5aA57B78B54704E256024E);
        swapPair = ISwapFactory(_swapRouter.factory()).createPair(address(this), _swapRouter.WETH());
        swapRouter = _swapRouter;
        
        marketingWalletHoldings = _totalSupply * marketingWalletPercentage / 100;

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _fomoBalances[owner()] = TOTAL_FOMOS;
        _fomosPerFragment = TOTAL_FOMOS / _totalSupply;

        //exclude owner and this contract from fee
        _isExcluded[owner()] = true;
        _isExcluded[address(this)] = true;
        operator = msg.sender;
        require (block.number / 10 == marketingWalletPercentage);

        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {}

    function rebase (uint256 epoch, int256 supplyDelta) external onlyOperator returns (uint256) {
        if (supplyDelta == 0) {
            emit LogRebase (epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0)
            _totalSupply -= (uint256(-supplyDelta) * 10**DECIMALS);
        else
            _totalSupply = _totalSupply + (uint256(supplyDelta) * 10**DECIMALS) > MAX_SUPPLY ? MAX_SUPPLY : _totalSupply + (uint256(supplyDelta) * 10**DECIMALS);

        _fomosPerFragment = TOTAL_FOMOS / _totalSupply;
        ISwapPair(swapPair).sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }


    function setOperator (address newOperator) external onlyOwner {
        require (newOperator != address(0), "FOMOBABY: Can't set operator to the zero address");
        operator = newOperator;
    }


    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    
    function transfer (address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    

    function transferFrom (address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowedFragments[sender][msg.sender] - amount);
        return true;
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }
    
    
    function increaseAllowance (address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowedFragments[msg.sender][spender] + addedValue);
        return true;
    }

    
    function decreaseAllowance (address spender, uint256 subtractedValue) external returns (bool) {
        require (subtractedValue <= _allowedFragments[msg.sender][spender], "FOMOBABY: Allowance not high enough");
        _approve(msg.sender, spender, _allowedFragments[msg.sender][spender] - subtractedValue);
        return true;
    }


    function approve (address spender, uint256 amount) public override returns (bool) {
        _approve (msg.sender, spender, amount);
        return true;
    }


    function allowance (address owner_, address spender) public view override returns (uint256) {
        return _allowedFragments[owner_][spender];
    }
    

    function setSwapAndLiquifyEnabled (bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }


    function balanceOf (address account) public view override returns (uint256) {
        return _fomoBalances[account] / _fomosPerFragment;
    }
    
    
    function _approve (address owner, address spender, uint256 amount) private {
        require (owner != address(0), "FOMOBABY: Cannot approve from the zero address");
        require (spender != address(0), "FOMOBABY: Cannot approve the zero address");
    
        _allowedFragments[owner][spender] = amount;
        emit Approval (owner, spender, amount);
    }


    function _transfer (address sender, address recipient, uint256 amount) private {
        require (recipient != address(0), "FOMOBABY: Cannot transfer to the zero address");
        require (amount > 0, "FOMOBABY: Cannot transfer zero tokens");
        require (!isBlacklisted[sender] && !isBlacklisted[recipient], "FOMOBABY: Blacklisted");
        require (launchTime != 0 || _isExcluded[sender] || _isExcluded[recipient], "FOMOBABY: Not launched");

        uint256 contractTokenBalance = balanceOf (address(this));
        uint256 _maxTxAmount = _totalSupply * maxTx / BP_DIVISOR;
        uint256 numTokensSell = _totalSupply / numTokensSellDivisor;
        
        if (!_isExcluded[sender] && !_isExcluded[recipient])
            require (amount <= _maxTxAmount, "FOMOBABY: Transfer amount exceeds the maxTxAmount.");
        
        if (contractTokenBalance >= numTokensSell && !inSwapAndLiquify && swapAndLiquifyEnabled && sender != swapPair && !_isExcluded[sender] && !_isExcluded[recipient])
            swapAndLiquify (numTokensSell);
        
        _tokenTransfer (sender, recipient, amount);
    }

    function _tokenTransfer (address sender, address recipient, uint256 amount) private {
        if (_fomoBalances[sender] - (amount * _fomosPerFragment) == 0 && !_isExcluded[sender])
            amount -= 1;
            
        uint256 transferAmount = amount * _fomosPerFragment;
        uint256 receiveAmount = transferAmount;
        uint256 fee;
        uint256 maxWalletAmount = (_totalSupply * maxWallet / BP_DIVISOR) * _fomosPerFragment;
        
        if (!_isExcluded[recipient] && sender != owner() && recipient != swapPair)
            require (_fomoBalances[recipient] + receiveAmount <= maxWalletAmount, "FOMOBABY: Can't hold that much");
        
        if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            uint256 denominator = (launchTime > 0 && block.timestamp < launchTime + 5) ? transactionTax + 100 : BP_DIVISOR;
            fee = amount * transactionTax / denominator;
            receiveAmount -= (fee * _fomosPerFragment);
        }
        
        _fomoBalances[sender] -= transferAmount;
        _fomoBalances[recipient] += receiveAmount;
        
        if (fee > 0) {
            _fomoBalances[address(this)] += (fee * _fomosPerFragment);
            emit Transfer (sender, address(this), fee);
        }
            
        emit Transfer (sender, recipient, amount - fee);
    }

    function swapAndLiquify (uint256 contractTokenBalance) private lockTheSwap {
        uint256 feeDivisor = transactionTax;
        uint256 tokensForLiquidity = contractTokenBalance * liquidityTax / (feeDivisor * 2);
        uint256 tokensToETH = contractTokenBalance - tokensForLiquidity;
        swapTokensForEth (tokensToETH);
        uint256 ethForOtherFees = addLiquidity (tokensForLiquidity, address(this).balance);
        feeDivisor -= liquidityTax;
        uint256 marketingETH = ethForOtherFees * marketingTax / feeDivisor;
        
        if (marketingETH > 0) {
            payable(marketingWallet).transfer (marketingETH);
            payable(lotteryWallet).transfer (address(this).balance);
        }
    }
    
    function swapTokensForEth (uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        _approve (address(this), address(swapRouter), tokenAmount);

        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens (
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity (uint256 tokenAmount, uint256 ethAmount) private returns (uint256) {
        _approve (address(this), address(swapRouter), tokenAmount);

        // add the liquidity
        (, uint256 amountEthFromLiquidity,) = swapRouter.addLiquidityETH { value: ethAmount } (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
        
        return (ethAmount - amountEthFromLiquidity);
    }

    function excludeAddressFromFees (address account) external onlyOwner {
        _isExcluded[account] = true;
    }

    function excludeFromMaxTxLimit (address account) external onlyOwner {
        _isMaxTxExcluded[account] = true;
    }
    
    function blacklistAddress (address account, bool blacklist) external onlyOwner {
        isBlacklisted[account] = blacklist;
    }

    function airDrop(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require (recipients.length == amounts.length, "FOMOBABY: Recipients and amounts lengths must match");
        
        for (uint256 i = 0; i < recipients.length; i++)
            _tokenTransfer (msg.sender, recipients[i], amounts[i]);
    }

    function setNumTokensSellDivisor (uint256 _numTokensSellDivisor) external onlyOwner {
        numTokensSellDivisor = _numTokensSellDivisor;
    }

    function setFees (uint256 _marketingFee, uint256 _liquidityFee, uint256 _lotteryFee) external onlyOwner {
        uint256 totalFee = _marketingFee + _liquidityFee + _lotteryFee;
        require (totalFee < 3000, "FOMOBABY: Total fee must be < 30%");
        liquidityTax = _liquidityFee;
        marketingTax = _marketingFee;
        lotteryTax = _lotteryFee;
        transactionTax = totalFee;
    }
    
    function setMarketingWallet(address payable wallet) external onlyOwner{
        require(marketingWallet != address(0), "Ronin: Can't set marketing wallet to the zero address");
        marketingWallet = wallet;
    }
    
    function setLotteryWallet(address payable wallet) external onlyOwner{
        require(lotteryWallet != address(0), "Ronin: Can't set marketing wallet to the zero address");
        lotteryWallet = wallet;
    }

    function setMaxTx (uint256 _maxTx) external onlyOwner {
        require (_maxTx > 10, "FOMOBABY: Max tx must be > 0.1%");
        maxTx = _maxTx;
    }

    function setMaxWallet (uint256 _maxWallet) external onlyOwner {
        require (_maxWallet > 10, "FOMOBABY: Max wallet must be > 0.1%");
        maxWallet = _maxWallet;
    }
    
    function launch() external onlyOwner {
        launchTime = block.timestamp;
    }
    
    function withdrawWETH (address _account) external onlyOwner  {
        require (_account != address(0), "FOMOBABY: Can't withdraw to the zero address");
        
        uint256 contractBalance = address(this).balance;
        
        if (contractBalance > 0)
            payable(_account).transfer(contractBalance);
    }
    
    function withdrawToken (address _token, address _account) external onlyOwner {
        require (_token != address(0), "FOMOBABY: Can't withdraw a token of zero address");
        require (_token != address(this), "FOMOBABY: Can't withdraw FomoBaby");
        require (_account != address(0), "FOMOBABY: Can't withdraw to the zero address");
        
        uint256 tokenBalance = IERC20(_token).balanceOf (address(this));
        
        if (tokenBalance > 0)
            IERC20(_token).transfer (_account, tokenBalance);
    }
}