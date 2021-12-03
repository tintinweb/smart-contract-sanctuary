/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)


pragma solidity ^0.8.0;

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

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
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
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
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

interface AntiSnipe {
    function checkUser(address from, address to, uint256 amt) external returns (bool);
    function setLaunch(address _initialLpPair, uint32 _liqAddBlock, uint64 _liqAddStamp) external;
    function setLpPair(address pair, bool enabled) external;
    function setProtections(bool _as, bool _ag, bool _ab, bool _aspecial) external;
    function setGasPriceLimit(uint256 gas) external;
    function removeSniper(address account) external;
    function setBlacklistEnabled(address account, bool enabled) external;
}

contract Archangel is Context, IERC20 {
    address private _owner;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    bool private allowedPresaleExclusion = true;
    mapping (address => bool) private _isSniper;
    mapping (address => bool) private _liquidityHolders;
   
    uint256 private startingSupply;

    string private _name;
    string private _symbol;

    struct FeesStruct {
        uint16 reflectFee;
        uint16 liquidityFee;
        uint16 marketingFee;
        uint16 burnFee;
    }

    struct StaticValuesStruct {
        uint16 maxReflectFee;
        uint16 maxLiquidityFee;
        uint16 maxMarketingFee;
        uint16 maxburnFee;
        uint16 masterTaxDivisor;
    }

    struct Ratios {
        uint16 liquidityRatio;
        uint16 marketingRatio;
        uint16 burnRatio;
        uint16 totalRatio;
    }

    FeesStruct private currentTaxes = FeesStruct({
        reflectFee: 0,
        liquidityFee: 0,
        marketingFee: 0,
        burnFee: 0
        });

    FeesStruct public _buyTaxes = FeesStruct({
        reflectFee: 200,
        liquidityFee: 0,
        marketingFee: 200,
        burnFee: 200
        });

    FeesStruct public _sellTaxes = FeesStruct({
        reflectFee: 200,
        liquidityFee: 0,
        marketingFee: 200,
        burnFee: 200
        });

    FeesStruct public _transferTaxes = FeesStruct({
        reflectFee: 0,
        liquidityFee: 0,
        marketingFee: 0,
        burnFee: 0
        });

    Ratios public _ratios = Ratios({
        liquidityRatio: _buyTaxes.liquidityFee,
        marketingRatio: _buyTaxes.marketingFee,
        burnRatio: _buyTaxes.burnFee,
        totalRatio: _buyTaxes.liquidityFee + _buyTaxes.marketingFee + _buyTaxes.burnFee
        });

    StaticValuesStruct public staticVals = StaticValuesStruct({
        maxReflectFee: 200,
        maxLiquidityFee: 200,
        maxMarketingFee: 200,
        maxburnFee: 200,
        masterTaxDivisor: 10000
        });

    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals;
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    IUniswapV2Router02 public dexRouter;
    address public lpPair;
    address constant private _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address payable private _marketingWallet = payable(0x7b8404be6480C44e25EE8c8446E408b1bfc92451);
    
    bool inSwap;
    bool public contractSwapEnabled = false;
    
    uint256 private _maxTxAmount;
    uint256 public maxTxAmountUI;

    uint256 private _maxWalletSize;
    uint256 public maxWalletSizeUI;

    uint256 private swapThreshold;
    uint256 private swapAmount;

    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    AntiSnipe antiSnipe;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event ContractSwapEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SniperCaught(address sniperAddress);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Caller =/= owner.");
        _;
    }
    
    constructor () payable {
        // Set the owner.
        _owner = msg.sender;
        _approve(_msgSender(), _routerAddress, type(uint256).max);
        _approve(address(this), _routerAddress, type(uint256).max);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[owner()] = true;
    }
    
    bool contractInitialized = false;

    function intializeContract() external onlyOwner {
        require(!contractInitialized, "Contract already initialized.");
        
        _name = "Archangel";
        _symbol = "Archa";
        _decimals = 9;
        _tTotal = 10000000000 * 10**12 * 10**9;
        _rTotal = (MAX - (MAX % _tTotal));

        dexRouter = IUniswapV2Router02(_routerAddress);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;
        
        uint256 percent = 2;
        uint256 divisor = 1000;
        _maxTxAmount = (_tTotal * percent) / divisor;
        maxTxAmountUI = (startingSupply * percent) / divisor;
        percent = 55;
        divisor = 10000;
        _maxWalletSize = (_tTotal * percent) / divisor;
        maxWalletSizeUI = (startingSupply * percent) / divisor;
        swapThreshold = (_tTotal * 5) / 10000;
        swapAmount = (_tTotal * 5) / 1000;
        if(address(antiSnipe) == address(0)){
            antiSnipe = AntiSnipe(address(this));
        }
        contractInitialized = true;     
        _rOwned[owner()] = _rTotal;
        emit Transfer(address(0), owner(), _tTotal);

        _approve(address(this), address(dexRouter), type(uint256).max);

        _transfer(owner(), address(this), balanceOf(owner()));

        dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

        enableTrading();
    }

    receive() external payable {}

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwner(address newOwner) external onlyOwner() {
        require(newOwner != address(0));
        require(newOwner != DEAD);
        setExcludedFromFees(_owner, false);
        setExcludedFromFees(newOwner, true);
        if (tradingEnabled){
            setExcludedFromReward(newOwner, true);
        }
        
        if (_marketingWallet == payable(_owner))
            _marketingWallet = payable(newOwner);
        
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
    
    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function decimals() external view returns (uint8) { return _decimals; }
    function symbol() external view returns (string memory) { return _symbol; }
    function name() external view returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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

    function approveContractContingency() public onlyOwner returns (bool) {
        _approve(address(this), address(dexRouter), type(uint256).max);
        return true;
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
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled == false) {
            lpPairs[pair] = false;
            antiSnipe.setLpPair(pair, false);
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 1 weeks, "Cannot set a new pair this week!");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
            antiSnipe.setLpPair(pair, true);
        }
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function setExcludedFromReward(address account, bool enabled) public onlyOwner {
        if (enabled == true) {
            require(!_isExcluded[account], "Account is already excluded.");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        } else if (enabled == false) {
            require(_isExcluded[account], "Account is already included.");
            if(_excluded.length == 1){
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
            } else {
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
        }
    }

    function setInitializer(address initializer) external onlyOwner {
        require(!_hasLiqBeenAdded, "Liquidity is already in.");
        antiSnipe = AntiSnipe(initializer);
    }

    function removeSniper(address account) external onlyOwner() {
        antiSnipe.removeSniper(account);
    }

    function setProtectionSettings(bool _antiSnipe, bool _antiGas, bool _antiBlock, bool _antiSpecial) external onlyOwner() {
        antiSnipe.setProtections(_antiSnipe, _antiGas, _antiBlock, _antiSpecial);
    }

    function setGasPriceLimit(uint256 gas) external onlyOwner {
        require(gas >= 75, "Too low.");
        antiSnipe.setGasPriceLimit(gas);
    }
    
    function setTaxesBuy(uint16 reflectFee, uint16 liquidityFee, uint16 marketingFee, uint16 burnFee) external onlyOwner {
        require(reflectFee <= staticVals.maxReflectFee && liquidityFee <= staticVals.maxLiquidityFee && marketingFee <= staticVals.maxMarketingFee && burnFee <= staticVals.maxburnFee);
        require(liquidityFee + reflectFee + marketingFee + burnFee <= 4500);
        _buyTaxes.liquidityFee = liquidityFee;
        _buyTaxes.reflectFee = reflectFee;
        _buyTaxes.burnFee = burnFee;
        _buyTaxes.marketingFee = marketingFee;
    }

    function setTaxesSell(uint16 reflectFee, uint16 liquidityFee, uint16 marketingFee, uint16 burnFee) external onlyOwner {
        require(reflectFee <= staticVals.maxReflectFee && liquidityFee <= staticVals.maxLiquidityFee && marketingFee <= staticVals.maxMarketingFee && burnFee <= staticVals.maxburnFee);
        require(liquidityFee + reflectFee + marketingFee + burnFee <= 4500);
        _sellTaxes.liquidityFee = liquidityFee;
        _sellTaxes.reflectFee = reflectFee;
        _sellTaxes.burnFee = burnFee;
        _sellTaxes.marketingFee = marketingFee;
    }

    function setTaxesTransfer(uint16 reflectFee, uint16 liquidityFee, uint16 marketingFee, uint16 burnFee) external onlyOwner {
        require(reflectFee <= staticVals.maxReflectFee && liquidityFee <= staticVals.maxLiquidityFee && marketingFee <= staticVals.maxMarketingFee && burnFee <= staticVals.maxburnFee);
        require(liquidityFee + reflectFee + marketingFee + burnFee <= 4500);
        _transferTaxes.liquidityFee = liquidityFee;
        _transferTaxes.reflectFee = reflectFee;
        _transferTaxes.burnFee = burnFee;
        _transferTaxes.marketingFee = marketingFee;
    }

    function setRatios(uint16 liquidity, uint16 marketing, uint16 burn) external onlyOwner {
        require (liquidity + marketing + burn== 100, "100%");
        _ratios.liquidityRatio = liquidity;
        _ratios.marketingRatio = marketing;
        _ratios.burnRatio = burn;
        _ratios.totalRatio = liquidity + marketing + burn;
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner {
        uint256 check = (_tTotal * percent) / divisor;
        require(check >= (_tTotal / 1000), "Max tx0.1");
        _maxTxAmount = check;
        maxTxAmountUI = (startingSupply * percent) / divisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        uint256 check = (_tTotal * percent) / divisor;
        require(check >= (_tTotal / 1000), "M");
        _maxWalletSize = check;
        maxWalletSizeUI = (startingSupply * percent) / divisor;
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
    }

    function setWallets(address payable marketingWallet) external onlyOwner {
        _marketingWallet = payable(marketingWallet);
    }

    function setContractSwapEnabled(bool _enabled) public onlyOwner {
        contractSwapEnabled = _enabled;
        emit ContractSwapEnabledUpdated(_enabled);
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner() && to != owner() && !_liquidityHolders[to] && !_liquidityHolders[from] && to != DEAD && to != address(0) && from != address(this);}

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Am");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "from the zero address");
        require(to != address(0), "to the zero address");
        require(amount > 0, "must be greater than zero");
        if(_hasLimits(from, to)) {
            if(!tradingEnabled) {
                revert("Trading notenabled");
            }
            if(lpPairs[from] || lpPairs[to]){
                require(amount <= _maxTxAmount, "exceeds the max");
            }
            if(to != _routerAddress && !lpPairs[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "exceeds the maxWalletSize");
            }
        }

        bool takeFee = true;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
        }

        if (lpPairs[to]) {
            if (!inSwap
                && contractSwapEnabled
            ) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= swapThreshold) {
                    if(contractTokenBalance >= swapAmount) { contractTokenBalance = swapAmount; }
                    contractSwap(contractTokenBalance);
                }
            }      
        } 
        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function contractSwap(uint256 contractTokenBalance) private lockTheSwap {
        if (_ratios.totalRatio == 0)
            return;

        if(_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        uint256 toLiquify = ((contractTokenBalance * _ratios.liquidityRatio) / _ratios.totalRatio) / 2;

        uint256 toSwapForEth = contractTokenBalance - toLiquify;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            toSwapForEth,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        //uint256 currentBalance = address(this).balance;
        uint256 liquidityBalance = ((address(this).balance * _ratios.liquidityRatio) / _ratios.totalRatio) / 2;

        if (toLiquify > 0) {
            dexRouter.addLiquidityETH{value: liquidityBalance}(
                address(this),
                toLiquify,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                DEAD,
                block.timestamp
            );
            emit SwapAndLiquify(toLiquify, liquidityBalance, toLiquify);
        }
        if (contractTokenBalance - toLiquify > 0) {
            _marketingWallet.transfer(address(this).balance);
        }
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added");
        if (!_hasLimits(from, to) && to == lpPair) {
            if (from == address(this)){
                _liquidityHolders[owner()] = true;
            } else {
                _liquidityHolders[from] = true;
            }
            _hasLiqBeenAdded = true;
            if(address(antiSnipe) == address(0)){
                antiSnipe = AntiSnipe(address(this));
            }
            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(_hasLiqBeenAdded, "Liquidity must be added.");
        setExcludedFromReward(address(this), true);
        setExcludedFromReward(lpPair, true);
        try antiSnipe.setLaunch(lpPair, uint32(block.number), uint64(block.timestamp)) {} catch {}
        tradingEnabled = true;
    }

    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;

        uint256 rTransferAmount;
        uint256 rAmount;
        uint256 rFee;
    }

    function _finalizeTransfer(address from, address to, uint256 tAmount, bool takeFee) private returns (bool) {
        if (!_hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                revert("Only owner can transfer");
            }
        }

        ExtraValues memory values = _getValues(from, to, tAmount, takeFee);

        _rOwned[from] = _rOwned[from] - values.rAmount;
        _rOwned[to] = _rOwned[to] + values.rTransferAmount;

        if (_isExcluded[from] && !_isExcluded[to]) {
            _tOwned[from] = _tOwned[from] - tAmount;
        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;  
        } else if (_isExcluded[from] && _isExcluded[to]) {
            _tOwned[from] = _tOwned[from] - tAmount;
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;
        }

        if (values.tLiquidity > 0)
            _takeLiquidity(from, values.tLiquidity);
        if (values.rFee > 0 || values.tFee > 0)
            _rTotal -= values.rFee;
            _tFeeTotal += values.tFee;

        emit Transfer(from, to, values.tTransferAmount);
        return true;
    }

    function _getValues(address from, address to, uint256 tAmount, bool takeFee) private returns (ExtraValues memory) {
        ExtraValues memory values;
        uint256 currentRate = _getRate();

        values.rAmount = tAmount * currentRate;

        if (_hasLimits(from, to)) {
            bool checked;
            try antiSnipe.checkUser(from, to, tAmount) returns (bool check) {
                checked = check;
            } catch {
                revert();
            }

            if(!checked) {
                revert();
            }
        }

        if(takeFee) {
            if (lpPairs[to]) {
                currentTaxes.reflectFee = _sellTaxes.reflectFee;
                currentTaxes.liquidityFee = _sellTaxes.liquidityFee;
                currentTaxes.marketingFee = _sellTaxes.marketingFee;
                currentTaxes.burnFee = _sellTaxes.burnFee;
            } else if (lpPairs[from]) {
                currentTaxes.reflectFee = _buyTaxes.reflectFee;
                currentTaxes.liquidityFee = _buyTaxes.liquidityFee;
                currentTaxes.marketingFee = _buyTaxes.marketingFee;
                currentTaxes.burnFee = _buyTaxes.burnFee;
            } else {
                currentTaxes.reflectFee = _transferTaxes.reflectFee;
                currentTaxes.burnFee = _transferTaxes.burnFee;
                currentTaxes.liquidityFee = _transferTaxes.liquidityFee;
                currentTaxes.marketingFee = _transferTaxes.marketingFee;
            }

            values.tFee = (tAmount * currentTaxes.reflectFee) / staticVals.masterTaxDivisor;
            values.tLiquidity = (tAmount * (currentTaxes.liquidityFee + currentTaxes.marketingFee + currentTaxes.burnFee)) / staticVals.masterTaxDivisor;
            values.tTransferAmount = tAmount - (values.tFee + values.tLiquidity);

            values.rFee = values.tFee * currentRate;
        } else {
            values.tFee = 0;
            values.tLiquidity = 0;
            values.tTransferAmount = tAmount;

            values.rFee = 0;
        }
        values.rTransferAmount = values.rAmount - (values.rFee + (values.tLiquidity * currentRate));
        return values;
    }

    function _getRate() private view returns(uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return _rTotal / _tTotal;
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return _rTotal / _tTotal;
        return rSupply / tSupply;
    }
    
    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        _rOwned[address(this)] = _rOwned[address(this)] + (tLiquidity * _getRate());
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
        emit Transfer(sender, address(this), tLiquidity); // Transparency is the key to success.
    }

    function sweepContingency() external onlyOwner {
        require(!_hasLiqBeenAdded, "Cannot call after liquidity.");
        payable(owner()).transfer(address(this).balance);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}