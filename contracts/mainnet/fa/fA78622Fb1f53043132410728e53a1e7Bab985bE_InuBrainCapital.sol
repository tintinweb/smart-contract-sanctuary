/**

InuBrain Capital: IBC 

A friendly ghost has been spotted wandering around on the Ethereum Mainnet - a generous ghost named InuBrain Capital. InuBrain Capital's ambition is to become the biggest, best managed, and friendliest Ethereum reflection token on the ETH network! And as is befitting for a ghost, it manifests itself in stealth...

InuBrain Capital has the vision not just give our holders passive income but also the best meme "Inu" on board. 

Tax for Buying/Selling: 14%
    - 6% of each transaction sent to holders as ETH transactions
    - 5% of each transaction sent to Marketing Wallet
    - 3% of each transaction sent to the Liquidity Pool

Earning Dashboard:
https://inubrain.capital

Telegram:
http://T.me/InuBrainCapital

Twitter:
https://twitter.com/InuBrainCapital


*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract InuBrainCapital is Ownable, IERC20 {
    address UNISWAPROUTER = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string private _name = "InuBrain Capital";
    string private _symbol = "IBC";

    uint256 public marketingFeeBPS = 500;
    uint256 public liquidityFeeBPS = 300;
    uint256 public dividendFeeBPS = 600;
    uint256 public totalFeeBPS = 1400;

    uint256 public swapTokensAtAmount = 10000000 * (10**18);
    uint256 public lastSwapTime;
    bool swapAllToken = true;

    bool public swapEnabled = true;
    bool public taxEnabled = true;
    bool public compoundingEnabled = true;

    uint256 private _totalSupply;
    bool private swapping;

    address marketingWallet;
    address liquidityWallet;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private _whiteList;

    event SwapAndAddLiquidity(uint256 tokensSwapped, uint256 nativeReceived, uint256 tokensIntoLiquidity);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event SwapEnabled(bool enabled);
    event TaxEnabled(bool enabled);
    event CompoundingEnabled(bool enabled);

    DividendTracker public dividendTracker;
    IUniswapV2Router02 public uniswapV2Router;
    
    address public uniswapV2Pair;

    uint256 public maxTxBPS = 100;
    uint256 public maxWalletBPS = 300;

    bool isOpen = false;

    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    constructor(address _marketingWallet, address _liquidityWallet, address[] memory whitelistAddress) {
        marketingWallet = _marketingWallet;
        liquidityWallet = _liquidityWallet;
        includeToWhiteList(whitelistAddress);
        
        dividendTracker = new DividendTracker(address(this), UNISWAPROUTER);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(UNISWAPROUTER);

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router), true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(dividendTracker), true);

        excludeFromMaxTx(owner(), true);
        excludeFromMaxTx(address(this), true);
        excludeFromMaxTx(address(dividendTracker), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(dividendTracker), true);

        _mint(owner(), 1000000000000 * (10**18));
    }

    receive() external payable {

    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }    
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }    

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "InuBrain: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "InuBrain: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }    

    function openTrading() external onlyOwner {
        isOpen = true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(isOpen || sender == owner() || recipient == owner() || _whiteList[sender] || _whiteList[recipient], "Not Open");

        require(sender != address(0), "InuBrain: transfer from the zero address");
        require(recipient != address(0), "InuBrain: transfer to the zero address");

        uint256 _maxTxAmount = totalSupply() * maxTxBPS / 10000;
        uint256 _maxWallet = totalSupply() * maxWalletBPS / 10000;
        require(amount <= _maxTxAmount || _isExcludedFromMaxTx[sender], "TX Limit Exceeded");
        
        if (sender != owner() && recipient != address(this)  && recipient != address(DEAD) && recipient != uniswapV2Pair){
            uint256 currentBalance = balanceOf(recipient);
            require(_isExcludedFromMaxWallet[recipient] || (currentBalance + amount <= _maxWallet));
        }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "InuBrain: transfer amount exceeds balance");

        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 contractNativeBalance = address(this).balance;

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(swapEnabled &&
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[sender] && // no swap on remove liquidity step 1 or DEX buy
            sender != address(uniswapV2Router) && // no swap on remove liquidity step 2
            sender != owner() &&
            recipient != owner()
        ) {
            swapping = true;

            if(!swapAllToken){
                contractTokenBalance = swapTokensAtAmount;
            }
            _executeSwap(contractTokenBalance, contractNativeBalance);

            lastSwapTime = block.timestamp;
            swapping = false;
        }

        bool takeFee;

        if(sender == address(uniswapV2Pair) || recipient == address(uniswapV2Pair)) {
            takeFee = true;
        }

        if(_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }

        if(swapping || !taxEnabled) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees = amount * totalFeeBPS / 10000;
            amount -= fees;
            _executeTransfer(sender, address(this), fees);
        }

        _executeTransfer(sender, recipient, amount);

        dividendTracker.setBalance(payable(sender), balanceOf(sender));
        dividendTracker.setBalance(payable(recipient), balanceOf(recipient));
    }

    function _executeTransfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "InuBrain: transfer from the zero address");
        require(recipient != address(0), "InuBrain: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "InuBrain: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);       
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "InuBrain: approve from the zero address");
        require(spender != address(0), "InuBrain: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "InuBrain: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "InuBrain: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "InuBrain: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function swapTokensForNative(uint256 tokens) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokens);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0, // accept any amount of native
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokens, uint256 native) private {
        _approve(address(this), address(uniswapV2Router), tokens);
        uniswapV2Router.addLiquidityETH{value: native}(
            address(this),
            tokens,
            0, // slippage unavoidable
            0, // slippage unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    function includeToWhiteList(address[] memory _users) private {
        for(uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }

    function _executeSwap(uint256 tokens, uint256 native) private {
        if(tokens <= 0) {
            return;
        }

        uint256 swapTokensMarketing;
        if(address(marketingWallet) != address(0)) {
            swapTokensMarketing = tokens * marketingFeeBPS / totalFeeBPS;
        }

        uint256 swapTokensDividends;
        if(dividendTracker.totalSupply() > 0) {
            swapTokensDividends = tokens * dividendFeeBPS / totalFeeBPS;
        }

        uint256 tokensForLiquidity = tokens - swapTokensMarketing - swapTokensDividends;
        uint256 swapTokensLiquidity = tokensForLiquidity / 2;
        uint256 addTokensLiquidity = tokensForLiquidity - swapTokensLiquidity;
        uint256 swapTokensTotal = swapTokensMarketing + swapTokensDividends + swapTokensLiquidity;

        uint256 initNativeBal = address(this).balance;
        swapTokensForNative(swapTokensTotal);
        uint256 nativeSwapped = (address(this).balance - initNativeBal) + native;

        uint256 nativeMarketing = nativeSwapped * swapTokensMarketing / swapTokensTotal;
        uint256 nativeDividends = nativeSwapped * swapTokensDividends / swapTokensTotal;
        uint256 nativeLiquidity = nativeSwapped - nativeMarketing - nativeDividends;

        if(nativeMarketing > 0) {
            payable(marketingWallet).transfer(nativeMarketing);
        }

        addLiquidity(addTokensLiquidity, nativeLiquidity);
        emit SwapAndAddLiquidity(swapTokensLiquidity, nativeLiquidity, addTokensLiquidity);

        if(nativeDividends > 0) {
            (bool success, ) = address(dividendTracker).call{value: nativeDividends}("");
            if(success) {
                emit SendDividends(swapTokensDividends, nativeDividends);
            }
        }
    }    

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "InuBrain: account is already set to requested state");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
      return _isExcludedFromFees[account];
    }

    function manualSendDividend(uint256 amount, address holder) external onlyOwner {
        dividendTracker.manualSendDividend(amount, holder);
    }

    function excludeFromDividends(address account, bool excluded) public onlyOwner {
        dividendTracker.excludeFromDividends(account, excluded);
    }

    function isExcludedFromDividends(address account) public view returns (bool) {
        return dividendTracker.isExcludedFromDividends(account);
    }

    function setWallet(address payable _marketingWallet, address payable _liquidityWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
        liquidityWallet = _liquidityWallet;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "InuBrain: DEX pair can not be removed");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function setFee(uint256 _marketingFee, uint256 _liquidityFee, uint256 _dividendFee) external onlyOwner{
        marketingFeeBPS = _marketingFee;
        liquidityFeeBPS = _liquidityFee;
        dividendFeeBPS = _dividendFee;
        totalFeeBPS = _marketingFee + _liquidityFee + _dividendFee;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "InuBrain: automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if(value) {
            dividendTracker.excludeFromDividends(pair, true);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "InuBrain: the router is already set to the new address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
          .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function claim() public {
        dividendTracker.processAccount(payable(_msgSender()));
    }

    function compound() public {
        require(compoundingEnabled, "InuBrain: compounding is not enabled");
        dividendTracker.compoundAccount(payable(_msgSender()));
    }

    function withdrawableDividendOf(address account) public view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }    

    function withdrawnDividendOf(address account) public view returns (uint256) {
        return dividendTracker.withdrawnDividendOf(account);
    }

    function accumulativeDividendOf(address account) public view returns (uint256) {
        return dividendTracker.accumulativeDividendOf(account);
    }

    function getAccountInfo(address account) public view returns (address, uint256, uint256, uint256, uint256) {
        return dividendTracker.getAccountInfo(account);
    }

    function getLastClaimTime(address account) public view returns (uint256) {
        return dividendTracker.getLastClaimTime(account);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner () {
        swapEnabled = _enabled;
        emit SwapEnabled(_enabled);
    }

    function setTaxEnabled(bool _enabled) external onlyOwner () {
        taxEnabled = _enabled;
        emit TaxEnabled(_enabled);
    }

    function setCompoundingEnabled(bool _enabled) external onlyOwner () {
        compoundingEnabled = _enabled;
        emit CompoundingEnabled(_enabled);
    }

    function updateDividendSettings(bool _swapEnabled, uint256 _swapTokensAtAmount, bool _swapAllToken) external onlyOwner () {
        swapEnabled = _swapEnabled;
        swapTokensAtAmount = _swapTokensAtAmount;
        swapAllToken = _swapAllToken;
    }

    function setMaxTxBPS(uint256 bps) external onlyOwner () {
        require(bps >= 75 && bps <= 10000, "BPS must be between 75 and 10000");
        maxTxBPS = bps;
    }

    function excludeFromMaxTx(address account, bool excluded) public onlyOwner () {
        _isExcludedFromMaxTx[account] = excluded;
    }

    function isExcludedFromMaxTx(address account) public view returns (bool) {
        return _isExcludedFromMaxTx[account];
    }

    function setMaxWalletBPS(uint256 bps) external onlyOwner () {
        require(bps >= 175 && bps <= 10000, "BPS must be between 175 and 10000");
        maxWalletBPS = bps;
    }

    function excludeFromMaxWallet(address account, bool excluded) public onlyOwner () {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    function isExcludedFromMaxWallet(address account) public view returns (bool) {
        return _isExcludedFromMaxWallet[account];
    }    

    function rescueToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function rescueETH(uint256 _amount) external onlyOwner{
        payable(msg.sender).transfer(_amount);
    }
}

contract DividendTracker is Ownable, IERC20 {
    address UNISWAPROUTER;

    string private _name = "InuBrain_DividendTracker";
    string private _symbol = "InuBrain_DividendTracker";  

    uint256 public lastProcessedIndex;

    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;

    uint256 constant private magnitude = 2**128;
    uint256 public immutable minTokenBalanceForDividends;
    uint256 private magnifiedDividendPerShare;
    uint256 public totalDividendsDistributed;
    uint256 public totalDividendsWithdrawn;
    
    address public tokenAddress;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => int256) private magnifiedDividendCorrections;
    mapping (address => uint256) private withdrawnDividends;
    mapping (address => uint256) private lastClaimTimes;

    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
    event ExcludeFromDividends(address indexed account, bool excluded);
    event Claim(address indexed account, uint256 amount);
    event Compound(address indexed account, uint256 amount, uint256 tokens);

    struct AccountInfo {
        address account;
        uint256 withdrawableDividends;
        uint256 totalDividends;
        uint256 lastClaimTime;
    }

    constructor(address _tokenAddress, address _uniswapRouter) {
        minTokenBalanceForDividends = 2500000 * (10**18);
        tokenAddress = _tokenAddress;
        UNISWAPROUTER = _uniswapRouter;
    }

    receive() external payable {
        distributeDividends();
    }

    function distributeDividends() public payable {
        require(_totalSupply > 0);
        if(msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare + ((msg.value * magnitude) / _totalSupply);
            emit DividendsDistributed(msg.sender, msg.value);
            totalDividendsDistributed += msg.value;
        }
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }
        if(newBalance >= minTokenBalanceForDividends) {
            _setBalance(account, newBalance);
        } else {
            _setBalance(account, 0);
        }
    }

    function excludeFromDividends(address account, bool excluded) external onlyOwner {
        require(excludedFromDividends[account] != excluded, "InuBrain_DividendTracker: account already set to requested state");
        excludedFromDividends[account] = excluded;
        if(excluded) {
            _setBalance(account, 0);
        } else {
            uint256 newBalance = IERC20(tokenAddress).balanceOf(account);
            if(newBalance >= minTokenBalanceForDividends) {
                _setBalance(account, newBalance);
            } else {
                _setBalance(account, 0);
            }
        }
        emit ExcludeFromDividends(account, excluded);
    }

    function isExcludedFromDividends(address account) public view returns (bool) {
        return excludedFromDividends[account];
    }

    function manualSendDividend(uint256 amount, address holder) external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(holder).transfer(amount > 0 ? amount : contractETHBalance);
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = _balances[account];
        if(newBalance > currentBalance) {
            uint256 addAmount = newBalance - currentBalance;
            _mint(account, addAmount);
        } else if(newBalance < currentBalance) {
            uint256 subAmount = currentBalance - newBalance;
            _burn(account, subAmount);
        }
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "InuBrain_DividendTracker: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
          - int256(magnifiedDividendPerShare * amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "InuBrain_DividendTracker: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "InuBrain_DividendTracker: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
          + int256(magnifiedDividendPerShare * amount);    
    }

    function processAccount(address payable account) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount);
            return true;
        }
        return false;
    }

    function _withdrawDividendOfUser(address payable account) private returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(account);
        if(_withdrawableDividend > 0) {
            withdrawnDividends[account] += _withdrawableDividend;
            totalDividendsWithdrawn += _withdrawableDividend;
            emit DividendWithdrawn(account, _withdrawableDividend);
            (bool success, ) = account.call{value: _withdrawableDividend, gas: 3000}("");
            if(!success) {
                withdrawnDividends[account] -= _withdrawableDividend;
                totalDividendsWithdrawn -= _withdrawableDividend;
                return 0;
            }
            return _withdrawableDividend;
        }
        return 0;
    }

    function compoundAccount(address payable account) public onlyOwner returns (bool) {
        (uint256 amount, uint256 tokens) = _compoundDividendOfUser(account);
        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Compound(account, amount, tokens);
            return true;
        }
        return false;
    }

    function _compoundDividendOfUser(address payable account) private returns (uint256, uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(account);
        if(_withdrawableDividend > 0) {
            withdrawnDividends[account] += _withdrawableDividend;
            totalDividendsWithdrawn += _withdrawableDividend;
            emit DividendWithdrawn(account, _withdrawableDividend);

            IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(UNISWAPROUTER);

            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();            
            path[1] = address(tokenAddress);

            bool success;
            uint256 tokens;

            uint256 initTokenBal = IERC20(tokenAddress).balanceOf(account);
            try uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _withdrawableDividend}(
              0,
              path,
              address(account),
              block.timestamp
            ) {
              success = true;
              tokens = IERC20(tokenAddress).balanceOf(account) - initTokenBal;
            } catch Error(string memory /*err*/) {
              success = false;
            }

            if(!success) {
                withdrawnDividends[account] -= _withdrawableDividend;
                totalDividendsWithdrawn -= _withdrawableDividend;
                return (0, 0);
            }            

            return (_withdrawableDividend, tokens);
        }
        return (0, 0);
    }

    function withdrawableDividendOf(address account) public view returns (uint256) {
        return accumulativeDividendOf(account) - withdrawnDividends[account];
    }

    function withdrawnDividendOf(address account) public view returns (uint256) {
        return withdrawnDividends[account];
    }

    function accumulativeDividendOf(address account) public view returns (uint256) {
        int256 a = int256(magnifiedDividendPerShare * balanceOf(account));
        int256 b = magnifiedDividendCorrections[account]; // this is an explicit int256 (signed)
        return uint256(a + b) / magnitude;
    }

    function getAccountInfo(address account) public view returns (address, uint256, uint256, uint256, uint256) {
        AccountInfo memory info;
        info.account = account;
        info.withdrawableDividends = withdrawableDividendOf(account);
        info.totalDividends = accumulativeDividendOf(account);
        info.lastClaimTime = lastClaimTimes[account];
        return (
            info.account,
            info.withdrawableDividends,
            info.totalDividends,
            info.lastClaimTime,
            totalDividendsWithdrawn
        );
    }

    function getLastClaimTime(address account) public view returns (uint256) {
        return lastClaimTimes[account];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("InuBrain_DividendTracker: method not implemented");
    }

    function allowance(address, address) public pure override returns (uint256) {
        revert("InuBrain_DividendTracker: method not implemented");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("InuBrain_DividendTracker: method not implemented");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("InuBrain_DividendTracker: method not implemented");
    }
}