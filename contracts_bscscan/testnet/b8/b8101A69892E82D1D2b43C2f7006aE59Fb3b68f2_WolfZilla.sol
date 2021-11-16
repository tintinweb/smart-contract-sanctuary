/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

/*

WolfZilla, * The Howling Zilla*

3% Reflections
2% Liquidity
4% Marketing


Telegram:
https://t.me/WolfZillaOfficial

Website:
https://www.WolfZilla.finance/

Twitter:
https://twitter.com/WolfZilla_Token

*/


pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

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


abstract contract Authorized{
    address private _owner;
    address private _previousOwner;
    mapping (address => bool) _authorized;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        _authorized[_owner] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyAuthorized {
        require(_authorized[msg.sender], "Authorization: caller is not the authorized");
        _;
    }
    
    function manageAuthorization(address account, bool authorize) public onlyOwner {
        _authorized[account] = authorize;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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


contract WolfZilla is IERC20, Authorized {
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    mapping (address => bool) public isPair;
   
    string private _name = "WolfZilla";
    string private _symbol = "WolfZilla";
    uint8 private _decimals = 9 ;
    uint256 private DECIMALS = 10 ** _decimals;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1e15 * DECIMALS;   // 1 Quadrillion tokens, total supply
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    uint256 public _taxFee = 3;
    uint256 private _previousTaxFee = _taxFee;   
    
    uint256 public _liquidityFee = 2;
    uint256 public _marketingFee = 4;    
    uint256 private _totalLPFee = 6;
    uint256 private _previousTotalLPFee = _totalLPFee; 
    
    IUniswapV2Router02 public uniswapV2Router;    
    address public uniswapV2Pair;
    address public deadAddress = address(0x000000000000000000000000000000000000dEaD); 
    address public marketingAddress; 
    address public autoLiquidityReceiver;
    
    uint256 public swapTokensAtAmount = 2 * _tTotal / 1000;  // 0.2% of total supply, 2e12  tokens   
    uint256 public maxTx = 5 * _tTotal / 1000;               // 0.5% of total supply, 5e12  tokens  
    uint256 public maxWallet = 20 * _tTotal / 1000;          // 2.0% of total supply, 20e12 tokens
    
    uint256 private nAntiBotBlocks;
    uint256 private launchBlock;
    bool public tradingIsEnabled = false;
    bool public antiBotActive = false;
    bool private swapping = false;
    bool private inBurn = false;
    bool private accumulatingForBurn = false;
    uint256 burnAmount = 0;
    
    bool intensify = false;
    uint256 intensifyDuration = 0;
    uint256 intensifyStart = 0;
    
    event Launch(uint256 indexed nAntiBotBlocks);
    event SetFees(uint256 indexed liquidityFee, uint256 indexed marketingFee, uint256 indexed totalFee);
    event SetTradeRestrictions(uint256 indexed maxTx, uint256 indexed maxWallet);
    event SetSwapTokensAtAmount(uint256 indexed swapTokensAtAmount);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );  
    
    constructor () {
        _rOwned[msg.sender] = _rTotal;
        marketingAddress = msg.sender;
        autoLiquidityReceiver = msg.sender;
        
        
        //0x10ED43C718714eb63d5aA57B78B54704E256024E 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        isPair[uniswapV2Pair] = true;
        uniswapV2Router = _uniswapV2Router;
        
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[deadAddress] = true;
        excludeFromReward(deadAddress);
        
        emit Transfer(address(0), msg.sender, _tTotal);
    }
    
    modifier inSwap{
        swapping = true;
        _; 
        swapping = false;
        
    }
    
    modifier inburn{
        inBurn = true;
        _; 
        inBurn = false;
        
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
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(_allowances[msg.sender][spender] >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {    
        return _tFeeTotal;
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
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
    
     function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _getValues(uint256 tAmount, address from) private returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount, from);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount, address from) private returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount, from);
        uint256 tLiquidity = calculateLiquidityFee(tAmount, from);
        uint256 tTransferAmount = tAmount - tFee - tLiquidity;
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
    }
    
    function rush(uint256 _minutes) external onlyAuthorized {
        require(_minutes <= 2 * 60, "Rush may not last over two hours.");
        intensify = true;
        intensifyDuration = _minutes * 1 minutes;
        intensifyStart = block.timestamp;
    }
    
    function calculateTaxFee(uint256 _amount, address from) private returns (uint256) {
        if (_taxFee == 0 && _totalLPFee == 0){
            return 0;
        }
        uint256 fee = 0;
        
        if(intensify){
            uint256 halfTime = intensifyStart  + intensifyDuration / 2;
            uint256 fullTime = intensifyStart  + intensifyDuration;
            
            if(block.timestamp < halfTime){
                fee = isPair[from] ? 0 : 10; 
            }
            else if(block.timestamp < fullTime){
                fee = isPair[from] ? 2 : 8; 
            }
            else{
                fee = _taxFee;
                intensify = false;
            }
        }
        else{
            fee = _taxFee;
        }
        
        return _amount * fee / 10**2;
    }
    
    function calculateLiquidityFee(uint256 _amount, address from) private returns (uint256) {
        if (_taxFee == 0 && _totalLPFee == 0){
            return 0;
        }
        uint256 fee = 0;
        
        if(intensify){
            uint256 halfTime = intensifyStart  + intensifyDuration / 2;
            uint256 fullTime = intensifyStart  + intensifyDuration;
            
            if(block.timestamp < halfTime){
                fee = isPair[from] ? 0 : 10; 
            }
            else if(block.timestamp < fullTime){
                fee = isPair[from] ? 3 : 7;
            }
            else{
                fee = _totalLPFee;
                intensify = false;
            }
        }
        else{
            fee = _totalLPFee;
        }
        
        return _amount * fee / 10**2;
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousTotalLPFee = _totalLPFee;
        
        _taxFee = 0;
        _totalLPFee = 0;
    }
     
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _totalLPFee = _previousTotalLPFee;
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
    
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "WolfZilla: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        
        isPair[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
     function launch(uint256 _nAntiBotBlocks) public onlyOwner{
        require(!tradingIsEnabled, "Project already launched.");
        nAntiBotBlocks = _nAntiBotBlocks;
        launchBlock = block.number;
        tradingIsEnabled = true;
        antiBotActive = true;
        
        emit Launch(nAntiBotBlocks);   
    }
    
    function setFees(uint256 marketingFee, uint256 liquidityFee, uint256 taxFee) public onlyOwner{
        require(0 <= taxFee && taxFee <= 6, "Requested tax fee out of acceptable range.");
        require(0 <= liquidityFee && liquidityFee <= 6 , "Requested liquidity fee out of acceptable range.");
        require(0 <= marketingFee && marketingFee <= 6, "Requested marketing fee out of acceptable range.");
        require(0 < marketingFee + liquidityFee, "Total liquidity fee amount must be strictly positive.");
        
        _taxFee = taxFee;
        _liquidityFee = liquidityFee;
        _marketingFee = marketingFee; 
        _totalLPFee = _liquidityFee + _marketingFee;
        
        emit SetFees(_liquidityFee, _marketingFee, _taxFee);  
    }
    
    function setTradeRestrictions(uint256 _maxTx, uint256 _maxWallet) public onlyOwner{
        require(_maxTx * DECIMALS >= (5 * _tTotal / 1000), "Requested max transaction amount too low.");
        require(_maxWallet * DECIMALS >= (20 * _tTotal / 1000), "Requested max allowable wallet amount too low.");
        
        maxTx = _maxTx * DECIMALS;
        maxWallet = _maxWallet * DECIMALS;
        
        emit SetTradeRestrictions(maxTx, maxWallet);
    }
    function setSwapTokensAtAmount(uint256 _swapTokensAtAmount) public onlyOwner{
        require(_tTotal / 1000 <= _swapTokensAtAmount * DECIMALS && _swapTokensAtAmount * DECIMALS <= 2 * _tTotal / 100,
        "Requested contract swap amount out of acceptable range.");
        
        swapTokensAtAmount = _swapTokensAtAmount * DECIMALS;
         
         emit SetSwapTokensAtAmount(swapTokensAtAmount);  
    }  
        
    function checkValidTrade(address from, address to, uint256 amount) private view{
        if (from != owner() && to != owner() && to != deadAddress) {
            require(tradingIsEnabled, "Project has yet to launch.");
            require(amount <= maxTx, "Transfer amount exceeds the max allowable."); 
            if (isPair[from]){
                require(balanceOf(address(to)) + amount <= maxWallet, 
                "Token purchase implies violation of max allowable wallet amount restriction.");
            }
        } 
    }

    function _transfer(address from, address to, uint256 amount) private {
        if(amount == 0) {
            return;
        }
    
        checkValidTrade(from, to, amount);
        bool takeFee = tradingIsEnabled && !swapping;
        
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        if(takeFee && antiBotActive) {
            uint256 fees;
            if(block.number < launchBlock + nAntiBotBlocks){ 
                fees = amount * 99 / 100;
                amount = amount - fees;
                takeFee = false;
                _tokenTransfer(from, address(this), fees, takeFee);
            }
            else{
                antiBotActive = false; 
            }
        	
        }
        
        if(accumulatingForBurn){
            if(shouldBurn()){
                burn(burnAmount);
            }    
        }
        else if(shouldSwap(to)) { 
            swapTokens(swapTokensAtAmount);
        }
        _tokenTransfer(from, to, amount, takeFee);
    }
    
    function shouldBurn() private view returns (bool){
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canBurn = contractTokenBalance >= burnAmount;
        return tradingIsEnabled && canBurn &&
        !inBurn && !antiBotActive;
    }
    
    function burn(uint256 _burnAmount) private inburn {
        uint256 currentRate =  _getRate();
        uint256 rBurn = _burnAmount * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] - rBurn;
        _rOwned[deadAddress] = _rOwned[deadAddress] + rBurn;
        _tOwned[deadAddress] = _tOwned[deadAddress] + _burnAmount;
       
        emit Transfer(address(this), deadAddress, _burnAmount);
        accumulatingForBurn = false;
    }   
    
    function shouldSwap(address to) private view returns (bool){
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        
        return tradingIsEnabled && canSwap && !swapping &&
        isPair[to] && !antiBotActive;
    }

    function swapTokens(uint256 tokens) inSwap private {
        
        uint256 LPtokens = tokens * _liquidityFee / _totalLPFee;
        uint256 halfLPTokens = LPtokens / 2;
        uint256 marketingtokens = tokens - LPtokens;
        
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(halfLPTokens + marketingtokens); 
         
        uint256 newBalance = address(this).balance - initialBalance;
        
        // alpha = _liquidityFee.div(_totalLPFee).div(2);
        // bnbForLP = newBalance.mul(alpha).div(1 - alpha);
        
        uint256 bnbForLP = newBalance * _liquidityFee / _totalLPFee / 2
        / ( 1e3 - 1e3 * _liquidityFee / _totalLPFee / 2 ) * 1e3;
        
        
        uint256 bnbForMarketing = newBalance - bnbForLP;
        
        (bool temp,) = payable(marketingAddress).call{value: bnbForMarketing, gas: 30000}(""); temp; //warning-suppresion 
        
        if (halfLPTokens > 0){
        addLiquidity(halfLPTokens, bnbForLP);
        }
        emit SwapAndLiquify(halfLPTokens, bnbForLP);   
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            autoLiquidityReceiver,
            block.timestamp
        );
    }
    
    function planBurn(uint256 _burnNumerator, uint256 _burnDenominator) public onlyAuthorized {
        burnAmount = _tTotal * _burnNumerator / _burnDenominator;
        accumulatingForBurn = true;
    } 
      
    function buybackStuckBNB(uint256 percent) public onlyAuthorized {
        uint256 amountToBuyBack = address(this).balance * percent / 100;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountToBuyBack}(
            0, // accept any amount of Tokens
            path,
            deadAddress, 
            block.timestamp
        );
    } 
    
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee(); 
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, sender);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, sender);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, sender);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, sender);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function airdrop(address sender, address[] calldata recipients, uint256[] calldata values) external onlyOwner {
        require(recipients.length == values.length, "Mismatch between Address and token count");
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(sender, recipients[i], values[i] * DECIMALS);
        }
    }
    
    receive() external payable {}

}