// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Uniswap.sol";
import "./PairHelper.sol";

contract OnPlanet is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using PairHelper for address;

    struct TransferDetails {
        uint112 balance0;
        uint112 balance1;
        uint32 blockNumber;
        address to;
        address origin;
    }
    TransferDetails lastTransfer;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10**9 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    string private _name = "OnPlanet";
    string private _symbol = "OP";

    // Large data type for maths
    uint256 private constant _decimals = 18;

    // Short data type for decimals function (no per function conversion)
    uint8 private constant _decimalsShort = uint8(_decimals);

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public stakingAddress = 0x000000000000000000000000000000000000dEaD;

    address payable public devAddress = payable(0x238c83A3E8bc75207786F3f23F69c9a4293f4b8B); 
    address payable public marketingAddress = payable(0x848964a4a3d84708c008c456616D818bA4dEb336); 
    
    mapping (address => uint256) private _rOwned; 
    mapping (address => uint256) private _tOwned; 
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private lastCoolDownTrade;

    address[] private hodler;
    address[] private _excluded;
    address[] public allEcosystemContracts;
    mapping(address => bool) private _isHodler;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isOnPlanetEcosystemContract;

    mapping(address => bool) private bots;
    mapping(address => uint256) private firstSellTime;
    mapping(address => uint256) private sellNumbers;
   
    uint256 public _taxFee;
    uint256 private _defaultTaxFee;

    uint256 public _liquidityFee;
    uint256 private _defaultLiquidityFee;

    uint256 public teamDivisor = 3;

    bool public ethBuyBack = true;
    bool public isReflection = true;

    bool public buyBackEnabled = false;
    bool public swapAndLiquifyEnabled = false;
    
    uint256 public _maxSellCount = 3; 
    uint256 public _maxTxAmount = 5000000 * 10**_decimals; 
    uint256 public minimumTokensBeforeSwap = 125000 * 10**_decimals;

    uint256 private buyBackUpperLimit = 10 * 10**_decimals;
    uint256 private buyBackTriggerTokenLimit = 1 * 10**6 * 10**_decimals;
    uint256 private buyBackMinAvailability = 1 * 10**_decimals; //1 BNB

    uint256 private buyVolume = 0;
    uint256 private sellVolume = 0;
    uint256 private nextBuybackAmount = 0;
    uint256 private buyBackTriggerVolume = 100 * 10**6 * 10**_decimals;

    uint256 private tradingStart = MAX;
    uint256 private tradingStartCooldown = MAX;

    uint256 private constant _FALSE = 1;
    uint256 private constant _TRUE = 2;

    uint256 private _checkingTokens;
    uint256 private _inSwapAndLiquify;

    uint256 private _tFeeTotal;
    uint256 private _tradeStartMaxTxAmount = _tTotal.div(1000); // Max txn 0.1% of supply

    IUniswapV2Router02 public immutable uniswapV2Router; 
    address public uniswapV2Pair;   
    address public _buyback_token_addr = 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47; 
    
    event BuyBackEnabledUpdated(bool enabled);
    event EthBuyBack(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event SwapTokensForTokens(uint256 amountIn, address[] path);

    event ExcludeFromFeeUpdated(address account);
    event IncludeInFeeUpdated(address account);

    event LiquidityFeeUpdated(uint256 prevValue, uint256 newValue);
    event MaxTxAmountUpdated(uint256 prevValue, uint256 newValue);
    
    event MinTokensBeforeSwapUpdated(uint256 prevValue, uint256 newValue);
    event BuybackMinAvailabilityUpdated(uint256 prevValue, uint256 newValue);

    event BuybackUpperLimitUpdated(uint256 prevValue, uint256 newValue);
    event BuyBackTriggerTokenLimitUpdated(uint256 prevValue, uint256 newValue);

    event TradingEnabled();
    event StakingAddressUpdated(address _addr);

    event OnPlanetEcosystemContractAdded(address contractAddress);
    event OnPlanetEcosystemContractRemoved(address contractAddress);
    
    modifier lockTheSwap() {
        require(_inSwapAndLiquify != _TRUE);
        _inSwapAndLiquify = _TRUE;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _inSwapAndLiquify = _FALSE;
    }

    modifier tokenCheck() {
        require(_checkingTokens != _TRUE);
        _checkingTokens = _TRUE;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _checkingTokens = _FALSE;
    }

    constructor() {
        // require(
        //     routerAddress != address(0),
        //     "routerAddress should not be the zero address"
        // );

        _rOwned[_msgSender()] = _rTotal;
        _tOwned[_msgSender()] = _tTotal;

        _checkingTokens = _FALSE;
        _inSwapAndLiquify = _FALSE;

        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Pancakeswap router mainnet - BSC
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //Testnet
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); //Sushiswap router mainnet - Polygon
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Uniswap V2 router mainnet - ETH
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff); //Quickswap V2 router mainnet - Polygon
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcluded[uniswapV2Pair] = true; 
        _excluded.push(uniswapV2Pair);

        _isHodler[owner()] = true;
        hodler.push(owner());

        _isHodler[address(this)] = true;
        hodler.push(address(this));

        _isHodler[uniswapV2Pair] = true;
        hodler.push(uniswapV2Pair);
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimalsShort;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function manualBuyback(uint256 amount, uint256 numOfDecimals)
        external
        onlyBuybackOwner
    {
        require(amount > 0 && numOfDecimals >= 0, "Invalid Input");

        uint256 value = amount.mul(10**18).div(10**numOfDecimals);

        if(ethBuyBack){
            swapETHForTokensNoFee(
                address(this),
                stakingAddress,
                value
            );
        }else{
            swapTokensForTokens(
                _buyback_token_addr,
                address(this),
                stakingAddress,
                value
            );
        }
    }

    function buyBackTokens(uint256 amount) private lockTheSwap {
        if (amount > 0) {
            if(ethBuyBack){
                swapETHForTokensNoFee(
                    address(this),
                    stakingAddress,
                    amount
                );
            }else{
                swapTokensForTokens(
                    _buyback_token_addr,
                    address(this),
                    stakingAddress,
                    amount
                );
            }
        }
    }

    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
        uint256 initialBalance;
        uint256 transferredBalance;

        if(ethBuyBack){
            initialBalance = address(this).balance;
            swapTokensForEth(
                address(this),
                address(this),
                contractTokenBalance
            );
            transferredBalance = address(this).balance.sub(initialBalance);

            transferToAddressETH(marketingAddress, transferredBalance.mul(teamDivisor).div(_liquidityFee).div(2));
            transferToAddressETH(devAddress, transferredBalance.mul(teamDivisor).div(_liquidityFee).div(2));
       }else{
            initialBalance = IERC20(_buyback_token_addr).balanceOf(address(this));
            swapTokensForTokens(
                address(this),
                _buyback_token_addr,
                address(this),
                contractTokenBalance
            );
            transferredBalance = IERC20(_buyback_token_addr).balanceOf(address(this)).sub(initialBalance);

            IERC20(_buyback_token_addr).transfer(marketingAddress, transferredBalance.mul(teamDivisor).div(_liquidityFee).div(2));
            IERC20(_buyback_token_addr).transfer(devAddress, transferredBalance.mul(teamDivisor).div(_liquidityFee).div(2));
       }
    }

    function setBuybackUpperLimit(uint256 buyBackLimit, uint256 numOfDecimals)
        external
        onlyBuybackOwner
    {
        uint256 prevValue = buyBackUpperLimit;
        buyBackUpperLimit = buyBackLimit.div(10**numOfDecimals).mul(10**18);
        emit BuybackUpperLimitUpdated(prevValue, buyBackUpperLimit);
    }

    function setBuybackTriggerTokenLimit(uint256 buyBackTriggerLimit)
        external
        onlyBuybackOwner
    {
        uint256 prevValue = buyBackTriggerTokenLimit;
        buyBackTriggerTokenLimit = buyBackTriggerLimit;
        emit BuyBackTriggerTokenLimitUpdated(
            prevValue,
            buyBackTriggerTokenLimit
        );
    }

    function setBuybackMinAvailability(uint256 amount, uint256 numOfDecimals)
        external
        onlyBuybackOwner
    {
        uint256 prevValue = buyBackMinAvailability;
        buyBackMinAvailability = amount.div(10**numOfDecimals).mul(10**18);
        emit BuybackMinAvailabilityUpdated(prevValue, buyBackMinAvailability);
    }

    function setBuyBackEnabled(bool _enabled) public onlyBuybackOwner {
        buyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }

    function setTradingEnabled(uint256 _tradeStartDelay, uint256 _tradeStartCoolDown) external onlyOwner {
        require(_tradeStartDelay < 10, "tradeStartDelay should be less than 10 minutes");
        require(_tradeStartCoolDown < 120, "tradeStartCoolDown should be less than 120 minutes");
        require(_tradeStartDelay < _tradeStartCoolDown, "tradeStartDelay must be less than tradeStartCoolDown");
        // Can only be called once
        require(tradingStart == MAX && tradingStartCooldown == MAX, "Trading has already started");
        // Set initial values
        _taxFee = _defaultTaxFee = 2;
        _liquidityFee = _defaultLiquidityFee = 8;
        _maxTxAmount = _tradeStartMaxTxAmount;

        setBuyBackEnabled(true);
        setSwapAndLiquifyEnabled(true);
        // Add time buffer to allow switching on trading on every chain
        // before announcing to community
        tradingStart = block.timestamp + _tradeStartDelay * 1 minutes;
        tradingStartCooldown = tradingStart + _tradeStartCoolDown * 1 minutes;
        // Announce to blockchain immediately, even though trades
        // can't start until delay passes (snipers no sniping)
        emit TradingEnabled();
    }

    function isTradingEnabled() public view returns (bool) {
        // Trading has been set and has time buffer has elapsed
        return tradingStart < block.timestamp;
    }

    function inTradingStartCoolDown() public view returns (bool) {
        // Trading has been started and the cool down period has elapsed
        return tradingStartCooldown >= block.timestamp;
    }

    function maxTxCooldownAmount() public view returns (uint256) {
        return _tTotal.div(2000);
    }

    function inTokenCheck() private view returns (bool) {
        return _checkingTokens == _TRUE;
    }

    function inSwapAndLiquify() private view returns (bool) {
        return _inSwapAndLiquify == _TRUE;
    }

    function setReflectionOn(bool enabled)public onlyOwner{
        isReflection = enabled;
    }

    function transferBalance(address payable _transferWallet) external onlyOwner {
        _transferWallet.transfer(address(this).balance);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(!bots[from] && !bots[to], "ERR: banned transfer");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!inTokenCheck(), "Invalid reentrancy from token0/token1 balanceOf check");

        address _owner = owner();
        bool isIgnoredAddress = from == _owner || to == _owner ||
             _isOnPlanetEcosystemContract[from] || _isOnPlanetEcosystemContract[to];

        require(amount <= _maxTxAmount || isIgnoredAddress, "Transfer amount exceeds the maxTxAmount");

        bool _isTradingEnabled = isTradingEnabled();
        require(_isTradingEnabled || isIgnoredAddress, "Trading is not enabled");

        bool notInSwapAndLiquify = !inSwapAndLiquify();
        if (inTradingStartCoolDown() && !isIgnoredAddress && notInSwapAndLiquify) {
            validateDuringTradingCoolDown(to, from, amount);
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        // Following block is for the contract to convert the tokens to ETH and do the buy back
        if (!inSwapAndLiquify() && swapAndLiquifyEnabled && to == uniswapV2Pair) {
            if (overMinimumTokenBalance) {
                contractTokenBalance = minimumTokensBeforeSwap;
                swapTokens(contractTokenBalance);
            }

            if (buyBackEnabled && address(this).balance > buyBackMinAvailability 
                && buyVolume.add(sellVolume) > buyBackTriggerVolume) 
            {
                if (nextBuybackAmount > address(this).balance) {
                    nextBuybackAmount = address(this).balance;
                }

                if (nextBuybackAmount > 0) {
                    buyBackTokens(nextBuybackAmount);
                    nextBuybackAmount = 0; //reset the next buyback amount
                    buyVolume = 0; //reset the buy volume
                    sellVolume = 0; // reset the sell volume
                }
            }

            if(firstSellTime[from] + (1 days) < block.timestamp){
                sellNumbers[from] = 0;
            }

            if (sellNumbers[from] == 0) {
                firstSellTime[from] = block.timestamp;
                sellNumbers[from] = sellNumbers[from] + 1;
            }else if (sellNumbers[from] < _maxSellCount ) { 
                sellNumbers[from] = sellNumbers[from] + 1;
            }else{
                sellNumbers[from] = 1;
            }

            setMultiFee(sellNumbers[from]);
        }

        // Compute Sell Volume and set the next buyback amount
        if (to == uniswapV2Pair) {
            sellVolume = sellVolume.add(amount);
            if (amount > buyBackTriggerTokenLimit) {
                uint256 balance = address(this).balance;
                if (balance > buyBackUpperLimit) balance = buyBackUpperLimit;
                nextBuybackAmount = nextBuybackAmount.add(balance.div(100));
            }
        }

        // Compute Buy Volume
        if (from == uniswapV2Pair) buyVolume = buyVolume.add(amount);

        bool takeFee = true;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        // For safety Liquidity Adds should only be done by an owner, 
        // and transfers to and from OnPlanet Ecosystem contracts
        // are not considered LP adds
        if (isIgnoredAddress || buybackOwner() == _msgSender()) {
            // Clear transfer data
            _clearTransferIfNeeded();
        } else if (notInSwapAndLiquify) {
            // Not in a swap during a LP add, so record the transfer details
            _recordPotentialLiquidityAddTransaction(to);
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _recordPotentialLiquidityAddTransaction(address to)
        private
        tokenCheck {
        uint112 balance0 = uint112(balanceOf(to));
        address token1 = to.token1();
        if (token1 == address(this)) {
            // Switch token so token1 is always other side of pair
            token1 = to.token0();
        }

        uint112 balance1;
        if (token1 == address(0)) {
            // Not a LP pair, or not yet (contract being created)
            balance1 = 0;
        } else {
            balance1 = uint112(IERC20(token1).balanceOf(to));
        }

        lastTransfer = TransferDetails({
            balance0: balance0,
            balance1: balance1,
            blockNumber: uint32(block.number),
            to: to,
            origin: tx.origin
        });
    }

    function _clearTransferIfNeeded() private {
        // Not Liquidity Add or is owner, clear data from same block to allow balanceOf
        if (lastTransfer.blockNumber == uint32(block.number)) {
            // Don't need to clear if different block
            lastTransfer = TransferDetails({
                balance0: 0,
                balance1: 0,
                blockNumber: 0,
                to: address(0),
                origin: address(0)
            });
        }
    }

    function swapTokensForEth(
        address tokenAddress,
        address toAddress,
        uint256 tokenAmount
    ) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = uniswapV2Router.WETH();

        IERC20(tokenAddress).approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            toAddress, // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function swapETHForTokensNoFee(
        address tokenAddress,
        address toAddress,
        uint256 amount
    ) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenAddress;

        // make the swap
        uniswapV2Router.swapExactETHForTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            toAddress, // The contract
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
    }

    function swapTokensForTokens(
        address fromTokenAddress,
        address toTokenAddress,
        address toAddress,
        uint256 tokenAmount
    ) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = fromTokenAddress;
        path[1] = uniswapV2Router.WETH();
        path[2] = toTokenAddress;

        IERC20(fromTokenAddress).approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of Tokens
            path,
            toAddress, // The contract
            block.timestamp.add(120)
        );

        emit SwapTokensForTokens(tokenAmount, path);
    }

    function validateDuringTradingCoolDown(address to, address from, uint256 amount) private {
        address pair = uniswapV2Pair;
        bool disallow;

        // Disallow multiple same source trades in same block
        if (from == pair) {
            disallow = lastCoolDownTrade[to] == block.number || lastCoolDownTrade[tx.origin] == block.number;
            lastCoolDownTrade[to] = block.number;
            lastCoolDownTrade[tx.origin] = block.number;
        } else if (to == pair) {
            disallow = lastCoolDownTrade[from] == block.number || lastCoolDownTrade[tx.origin] == block.number;
            lastCoolDownTrade[from] = block.number;
            lastCoolDownTrade[tx.origin] = block.number;
        }

        require(!disallow, "Multiple trades in same block from same source are not allowed during trading start cooldown");

        require(amount <= maxTxCooldownAmount(), "Max transaction is 0.05% of total supply during trading start cooldown");
    }

    // account must be recorded in _transfer and same block
    function _validateIfLiquidityAdd(address account, uint112 balance0)
        private
        view
    {
        // Test to see if this tx is part of a Liquidity Add
        // using the data recorded in _transfer
        TransferDetails memory _lastTransfer = lastTransfer;
        if (_lastTransfer.origin == tx.origin) {
            // May be same transaction as _transfer, check LP balances
            address token1 = account.token1();

            if (token1 == address(this)) {
                // Switch token so token1 is always other side of pair
                token1 = account.token0();
            }

            // Not LP pair
            if (token1 == address(0)) return;

            uint112 balance1 = uint112(IERC20(token1).balanceOf(account));

            if (balance0 > _lastTransfer.balance0 &&
                balance1 > _lastTransfer.balance1) {
                // Both pair balances have increased, this is a Liquidty Add
                require(false, "Liquidity can be added by the owner only");
            }
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function buyBackUpperLimitAmount() public view returns (uint256) {
        return buyBackUpperLimit;
    }
    
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
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

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!_isHodler[recipient] && amount > 0){
            _isHodler[recipient] = true;
            hodler.push();
        }
        restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
	    _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
    	_tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
    	_tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }
    
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        
        _taxFee = 0;
        _liquidityFee = 0;
    }
    
    function restoreAllFee() private {
        if(isReflection)
            _taxFee = _defaultTaxFee;
        else
            _taxFee = 0;
        _liquidityFee = _defaultLiquidityFee;
    }

    function setMultiFee(uint256 multiplier) private {
        _liquidityFee = _liquidityFee * multiplier;
    }

    function setBotAddress(address _botAddress, bool enabled) public onlyOwner {
        bots[_botAddress] = enabled;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setDefaultTaxFeePercent(uint256 defaultTaxFee) external onlyOwner() {
        _defaultTaxFee = defaultTaxFee;
    }
    
    function setDefaultLiquidityFeePercent(uint256 defaultLiquidityFee) external onlyOwner() {
        _defaultLiquidityFee = defaultLiquidityFee;
    }
    
    function setMaxSellCount(uint256 maxCount) external onlyOwner(){
        _maxSellCount = maxCount;
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }
    
    function setTeamDivisor(uint256 divisor) external onlyOwner() {
        teamDivisor = divisor;
    }

    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external onlyOwner() {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }
    
     function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
        buyBackUpperLimit = buyBackLimit * 10**18;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner() {
        marketingAddress = payable(_marketingAddress);
    }

    function setDeveloperAddress(address _devAddress) external onlyOwner(){
        devAddress = payable(_devAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setEthBuyback(bool _enabled) public onlyOwner {
        ethBuyBack = _enabled;
        emit EthBuyBack(_enabled);
    }

    function setReflectionEnabled(bool _enabled) public onlyOwner {
        isReflection = _enabled;

        if(isReflection){
            for (uint256 i = 0; i < _excluded.length; i++) {
                _tOwned[_excluded[i]] = 0;
                _isExcluded[_excluded[i]] = false;
                _excluded.pop();
            }
        }else{
            for(uint256 i = 0; i < hodler.length; i++){
                if(_rOwned[hodler[i]] > 0) {
                    _tOwned[hodler[i]] = tokenFromReflection(_rOwned[hodler[i]]);
                }
                _isExcluded[hodler[i]] = true;
                _excluded.push(hodler[i]);
            }
        }
    }

    function setBuyBackTokenAddress(address _addr) public onlyOwner {
        _buyback_token_addr = _addr;
    }

    function updateStakingAddress(address _addr) public onlyOwner {
        stakingAddress = _addr;
        emit StakingAddressUpdated(_addr);
    }

    function _onPlanetEcosystemContractAdd(address contractAddress) private {
        _isOnPlanetEcosystemContract[contractAddress] = true;
        allEcosystemContracts.push(contractAddress);

        emit OnPlanetEcosystemContractAdded(contractAddress);
        excludeFromFee(contractAddress);
    }

    function onPlanetEcosystemContractRemove(address contractAddress) external onlyOwner {
        require(
            _isOnPlanetEcosystemContract[contractAddress],
            "contractAddress is not included as OnPlanet Ecosystem contract"
        );

        _isOnPlanetEcosystemContract[contractAddress] = false;

        for (uint256 i = 0; i < allEcosystemContracts.length; i++) {
            if (allEcosystemContracts[i] == contractAddress) {
                allEcosystemContracts[i] = allEcosystemContracts[allEcosystemContracts.length - 1];
                allEcosystemContracts.pop();
                break;
            }
        }
        
        emit OnPlanetEcosystemContractRemoved(contractAddress);
    }
    
    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function balanceOf(address account) public view override returns (uint256){
        uint256 balance0 = _balanceOf(account);
        uint256 balance1 = tokenFromReflection(_rOwned[account]);

        if (
            !inSwapAndLiquify() &&
            lastTransfer.blockNumber == uint32(block.number) &&
            account == lastTransfer.to
        ) {
            // Balance being checked is same address as last to in _transfer
            // check if likely same txn and a Liquidity Add
            _validateIfLiquidityAdd(account, uint112(balance0));
        }

        if(isReflection && !_isExcluded[account])
            return balance1;

        return balance0;
    }

    function _balanceOf(address account) private view returns (uint256) {
        return _tOwned[account];
    }

    receive() external payable {}
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "./Context.sol";

contract Ownable is Context {
    address private _owner;
    address private _buybackOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyBuybackOwner() {
        require(
            _buybackOwner == _msgSender(),
            "Ownable: caller is not the buyback owner"
        );
        _;
    }

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _buybackOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferBuybackOwnership(address newOwner)
        external
        virtual
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_buybackOwner, newOwner);
        _buybackOwner = newOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function buybackOwner() public view returns (address) {
        return _buybackOwner;
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./Uniswap.sol";

// helper methods for discovering LP pair addresses
library PairHelper {
    bytes private constant token0Selector =
        abi.encodeWithSelector(IUniswapV2Pair.token0.selector);
    bytes private constant token1Selector =
        abi.encodeWithSelector(IUniswapV2Pair.token1.selector);

    function token0(address pair) internal view returns (address) {
        return token(pair, token0Selector);
    }

    function token1(address pair) internal view returns (address) {
        return token(pair, token1Selector);
    }

    function token(address pair, bytes memory selector)
        private
        view
        returns (address)
    {
        // Do not check if pair is not a contract to avoid warning in txn log
        if (!isContract(pair)) return address(0); 

        (bool success, bytes memory data) = pair.staticcall(selector);

        if (success && data.length >= 32) {
            return abi.decode(data, (address));
        }
        
        return address(0);
    }

    function isContract(address account) private view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }

        return (codehash != accountHash && codehash != 0x0);
    }
}