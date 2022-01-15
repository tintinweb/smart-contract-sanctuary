/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

/**

______       ______ _______  ________  ______  _______   ______  
 /      \|  \  |  \      \       \|        \/      \|       \ /      \ 
|  ▓▓▓▓▓▓\ ▓▓  | ▓▓\▓▓▓▓▓▓ ▓▓▓▓▓▓▓\\▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓\ ▓▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓___\▓▓ ▓▓__| ▓▓ | ▓▓ | ▓▓__/ ▓▓  | ▓▓  | ▓▓__| ▓▓ ▓▓__| ▓▓ ▓▓  | ▓▓
 \▓▓    \| ▓▓    ▓▓ | ▓▓ | ▓▓    ▓▓  | ▓▓  | ▓▓    ▓▓ ▓▓    ▓▓ ▓▓  | ▓▓
 _\▓▓▓▓▓▓\ ▓▓▓▓▓▓▓▓ | ▓▓ | ▓▓▓▓▓▓▓\  | ▓▓  | ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓\ ▓▓  | ▓▓
|  \__| ▓▓ ▓▓  | ▓▓_| ▓▓_| ▓▓__/ ▓▓  | ▓▓  | ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓__/ ▓▓
 \▓▓    ▓▓ ▓▓  | ▓▓   ▓▓ \ ▓▓    ▓▓  | ▓▓  | ▓▓  | ▓▓ ▓▓  | ▓▓\▓▓    ▓▓
  \▓▓▓▓▓▓ \▓▓   \▓▓\▓▓▓▓▓▓\▓▓▓▓▓▓▓    \▓▓   \▓▓   \▓▓\▓▓   \▓▓ \▓▓▓▓▓▓


TELEGRAM : https://t.me/ShibTaroPortal
WEBSITE :  https://shibtaro.com/
TWITTER :  https://twitter.com/shib_taro
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
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
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
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
    function factory() external view returns (address);
}

interface IUniswapV2Router01 {
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

contract SHIBTARO is Context, IERC20 {
    // Ownership moved to in-contract for customizability.
    address private _owner;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _liquidityHolders;

    uint256 private startingSupply = 10_000_000_000;

    string private _name = "SHIBTARO";
    string private _symbol = "SHIBTARO";

    uint256 public _devFee       = 300; // 3% (3 x 100)
    uint256 public _liquidityFee = 300; // 3% (3 x 100)
    uint256 public _marketingFee = 800; // 8% (8 x 100)
    uint256 public _sumTotalFees = _devFee + _liquidityFee + _marketingFee;

    uint8 constant private _decimals      = 9;
    uint256 constant private _decimalsMul = _decimals;
    uint256 private _tTotal               = startingSupply * 10**_decimalsMul;

    IUniswapV2Router02 public dexRouter;
    address public lpPair;

    // UNI ROUTER
    address private _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address constant public DEAD             = 0x000000000000000000000000000000000000dEaD;
    address payable private _teamWallet      = payable(0x0d4326fb09BDb5bA12706E9F96e68371ac06bFAD);
    address payable private _marketingWallet = payable(0x5a49601608B1D192339196b8DD0aA30A6EF86809);
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    
    uint256 private maxTxPercent = 1;
    uint256 private maxTxDivisor = 100;
    uint256 private _maxTxAmount = (_tTotal * maxTxPercent) / maxTxDivisor;
    uint256 public maxTxAmountUI = (startingSupply * maxTxPercent) / maxTxDivisor;

    uint256 private maxWalletPercent = 1;
    uint256 private maxWalletDivisor = 100;
    uint256 private _maxWalletSize = (_tTotal * maxWalletPercent) / maxWalletDivisor;
    uint256 public maxWalletSizeUI = (startingSupply * maxWalletPercent) / maxWalletDivisor;

    uint256 private swapThreshold = (_tTotal * 5) / 10000;
    uint256 private swapAmount = (_tTotal * 5) / 1000;

    bool public startTrade                = true;
    uint256 private _liqAddBlock          = 0;
    bool public _hasLiqBeenAddedInitially = false;

    mapping(address => bool) public _isBlacklisted;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Caller =/= owner.");
        _;
    }
    
    constructor () payable {
        _tOwned[_msgSender()] = _tTotal;

        // Set the owner.
        _owner = msg.sender;

        dexRouter                                      = IUniswapV2Router02(_routerAddress);
        lpPair                                         = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair]                                = true;
        _allowances[address(this)][address(dexRouter)] = type(uint256).max;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[owner()] = true;

        // Approve the owner for PancakeSwap, timesaver.
        _approve(_msgSender(), _routerAddress, _tTotal);


        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    receive() external payable {}

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================
    // Ownable removed as a lib and added here to allow for custom transfers and recnouncements.
    // This allows for removal of ownership privelages from the owner once renounced or transferred.
    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwner(address newOwner) external onlyOwner() {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        setExcludedFromFees(_owner, false);
        setExcludedFromFees(newOwner, true);
        
        if (_marketingWallet == payable(_owner))
            _marketingWallet = payable(newOwner);
        
        _allowances[_owner][newOwner] = balanceOf(_owner);
        if(balanceOf(_owner) > 0) {
            _transfer(_owner, newOwner, balanceOf(_owner));
        }
        
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
        
    }

    function renounceOwnership() public virtual onlyOwner() {
        setExcludedFromFees(_owner, false);
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveMax(address spender) public returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function setNewRouter(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            lpPair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled == false) {
            lpPairs[pair] = false;
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 1 weeks, "One week cooldown.");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
        }
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function setStartTrade(bool enabled) public onlyOwner {
        startTrade = enabled;
    }

    function setFees(uint256 dev, uint256 liquidity, uint256 marketing) external onlyOwner {
        _devFee = dev;
        _liquidityFee = liquidity;
        _marketingFee = marketing;
        _sumTotalFees = _devFee + _liquidityFee + _marketingFee;
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner {
        uint256 check = (_tTotal * percent) / divisor;
        require(check >= (_tTotal / 1000), "Must be above 0.1% of total supply.");
        _maxTxAmount = check;
        maxTxAmountUI = (startingSupply * percent) / divisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        uint256 check = (_tTotal * percent) / divisor;
        require(check >= (_tTotal / 1000), "Must be above 0.1% of total supply.");
        _maxWalletSize = check;
        maxWalletSizeUI = (startingSupply * percent) / divisor;
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
    }

    function setWallets(address payable marketingWallet, address payable teamWallet) external onlyOwner {
        _marketingWallet = payable(marketingWallet);
        _teamWallet = payable(teamWallet);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: Zero address.");
        require(to != address(0), "ERC20: Zero address.");
        require(amount > 0, "Must >0.");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');

        if (!startTrade) {
            revert('Trading is not active!');
        }

        if (_liqAddBlock == 0) {
            _checkLiquidityAdd(from, to);
        }
        
        if(_hasLimits(from, to)) {
            if(lpPairs[from] || lpPairs[to]){
                require(amount <= _maxTxAmount, "Exceeds the maxTxAmount.");
            }
            if(to != _routerAddress && !lpPairs[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            }
        }

        bool takeFee = true;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
        }

        if (to == lpPair) {
            if (!inSwapAndLiquify && swapAndLiquifyEnabled) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= swapThreshold) {
                    if(contractTokenBalance >= swapAmount) { 
                        contractTokenBalance = swapAmount;
                    }
                    swapAndLiquify(contractTokenBalance);
                }
            }      
        }

        if (from == lpPair) {
            if (_liqAddBlock == block.number && _hasLimits(from, to)) {
                _isBlacklisted[to] = true;
                revert('FrontRunning is Bad!');
            }
        }

        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        if (_liquidityFee + _marketingFee + _devFee == 0) { return; }

        uint256 toLiquifyHalf = ((contractTokenBalance * _liquidityFee) / _sumTotalFees) / 2;

        uint256 toSwapForEth = contractTokenBalance - toLiquifyHalf;
        swapTokensForEth(toSwapForEth);

        uint256 currentBalance = address(this).balance;
        uint256 liquidityBalance = ((currentBalance * _liquidityFee) / _sumTotalFees) / 2;

        if (toLiquifyHalf > 0) {
            addLiquidity(toLiquifyHalf, liquidityBalance);
            emit SwapAndLiquify(toLiquifyHalf, liquidityBalance, toLiquifyHalf);
        }
        if (currentBalance - liquidityBalance > 0) {
            _marketingWallet.transfer(((currentBalance * _marketingFee) / _sumTotalFees));
            _teamWallet.transfer(address(this).balance);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            DEAD,
            block.timestamp
        );
    }

    function _checkLiquidityAdd(address from, address to) private {
        if (!_hasLiqBeenAddedInitially) {
            if (!_hasLimits(from, to) && to == lpPair) {
                _liqAddBlock = block.number; 
            }

            _liquidityHolders[from] = true;
            _hasLiqBeenAddedInitially = true;

            swapAndLiquifyEnabled = true;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }

    function _finalizeTransfer(address from, address to, uint256 amount, bool takeFee) private returns (bool) {

        _tOwned[from] -= amount;
        uint256 amountReceived = (takeFee) ? takeTaxes(from, amount) : amount;
        _tOwned[to] += amountReceived;

        emit Transfer(from, to, amountReceived);
        return true;
    }

    function takeTaxes(address from, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount * _sumTotalFees) / 10**4;

        _tOwned[address(this)] += feeAmount;
        emit Transfer(from, address(this), feeAmount);

        return amount - feeAmount;
    }

    function potOfGreedBuy() public onlyOwner {
        // half buy tax
        _sumTotalFees = _sumTotalFees / 2;
    }

    function potOfGreedSell() public onlyOwner {
        // double sell tax
        _sumTotalFees = _sumTotalFees * 2;
    }

    function resetFees() public onlyOwner {
        _devFee       = 300; // 3% (3 x 100)
        _liquidityFee = 300; // 3% (3 x 100)
        _marketingFee = 800; // 8% (8 x 100)
        _sumTotalFees = _devFee + _liquidityFee + _marketingFee;
    }
}