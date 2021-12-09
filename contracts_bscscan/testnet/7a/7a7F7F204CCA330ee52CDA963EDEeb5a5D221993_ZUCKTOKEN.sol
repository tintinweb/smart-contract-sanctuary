pragma solidity ^0.8.6;
// SPDX-License-Identifier: Unlicensed

import "./zuckRebaseLib.sol";

contract ZUCKTOKEN is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    event LogShow(string msg);
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isIncludedFromFee;
    
    mapping (address => bool) private _botWhiteListFee;

    mapping (address => bool) private _isExcluded;

    address[] private _excluded;

    address private _marketingAddress = address(0); // account 4
	
	address private _destroyAddress = address(0); // account 5
	
	address private _poolAddress = address(0); // pool address set by yourself

    uint256 private startMintDate = 1632412800; // when can start to sale
    
    address private _liquidAddress = address(0);
    // PCS ROUTER
    address constant private _routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    
    bool public tradingEnabled = false;

    bool public liquifyEnabled = true; 

   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "ZuckMeta";
    string private _symbol = "ZUCK";
    uint8 private _decimals = 9;
    
    uint256 public _marketingFee = 2; 
    uint256 private _previousMarketFee = _marketingFee;
    
    uint256 public _liquidityFee = 3;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 public _taxFee = 3;   // taxFee used for reflecting the tokens
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _power = 2;

    IPancakeSwapV2Router02 public immutable pancakeSwapV2Router;
    address public immutable pancakeSwapV2Pair;
    
    bool inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true;
    
    uint256 public _maxTxAmount = 800000000000 * 10**9; 
    uint256 private numTokensSellToAddToLiquidity = 800000000000 * 10**9; 
	
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        IPancakeSwapV2Router02 _pancakeSwapV2Router = IPancakeSwapV2Router02(_routerAddress); 
        
       
         // Create a pancakeSwap pair for this new token
        pancakeSwapV2Pair = IPancakeSwapV2Factory(_pancakeSwapV2Router.factory())
            .createPair(address(this), _pancakeSwapV2Router.WETH());

        // set the rest of the contract variables
        pancakeSwapV2Router = _pancakeSwapV2Router;
        
        _isIncludedFromFee[owner()] = false; 
        _isIncludedFromFee[address(this)] = false;
		
        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function transfer(address recipient, uint256 amount) public override returns (bool)  {
        require(
            startMintDate != 0 && startMintDate <= block.timestamp,
            "early"
        );
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setStartTradeDate(uint256 _startMintDate) external onlyOwner {
        startMintDate = _startMintDate;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) internal virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) internal virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }


    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
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

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) private {
        require(!_isExcluded[account], "Already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) private {
        require(_isExcluded[account], "Already included");
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
    
    function includeFee(address account) public onlyOwner {
        _isIncludedFromFee[account] = true;
    }
    
    function excludeBotFromFee(address account) public onlyOwner{
        _botWhiteListFee[account] = true;
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isIncludedFromFee[account] = false;
    }
    
    function setLiquifyEnableTrade(bool _liquifyEnabled) public onlyOwner{
        liquifyEnabled = _liquifyEnabled;
    }
    
    function setMarketingAddress(address account) external onlyOwner(){
        _marketingAddress = account;
    }
    
    function setLiquidAddress(address account) external onlyOwner() {
        _poolAddress = account;
        _liquidAddress = account;
    }
    
    function getMarketingAddress() public view returns(address){
        return _marketingAddress;
    }
    
    function getliquifyEnabled() public view returns(bool){
        return liquifyEnabled;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        _marketingFee = marketingFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
    
    function setRadion(uint256 power) external onlyOwner(){
        _power = power;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }

     //to recieve ETH from pancakeSwapV2Router when swaping
    receive() external payable {}

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
        _rOwned[_poolAddress] = _rOwned[_poolAddress].add(rLiquidity);
        if(_isExcluded[_poolAddress])
            _tOwned[_poolAddress] = _tOwned[_poolAddress].add(tLiquidity);
    }
	
    function _takeMarket(uint256 tMarket) private {
        uint256 currentRate =  _getRate();
        uint256 rMarket = tMarket.mul(currentRate);
        _rOwned[_marketingAddress] = _rOwned[_marketingAddress].add(rMarket);
        if(_isExcluded[_marketingAddress])
            _tOwned[_marketingAddress] = _tOwned[_marketingAddress].add(tMarket);
    }


    function calculateMarketFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(
            10**_power
        );
    }
	
    
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**_power
        );
    }
	
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**_power
        );
    }

    
    function removeAllFee() private {
        if(_marketingFee == 0 && _liquidityFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousMarketFee = _marketingFee;
		_previousLiquidityFee = _liquidityFee;

        _marketingFee = 0;
		_liquidityFee = 0;
        _taxFee = 0;
    }
	
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _marketingFee = _previousMarketFee;
		_liquidityFee = _previousLiquidityFee;

    }

    function isIncludeFromFee(address account) public view returns(bool) {
        return _isIncludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakeSwapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer，默认是FALSe
        bool takeFee = false;
        
        //set pancakeRouter LP address
        if(_isIncludedFromFee[from] || _isIncludedFromFee[to]){
            takeFee = true;
        }
        
        //whitelist for bot
        if(_botWhiteListFee[from] || _botWhiteListFee[to]){
            takeFee = false;
        }
		
		if(from == _liquidAddress || to == _liquidAddress ){
            takeFee = true;
		    require(liquifyEnabled == true,'liquid trade disable');
		}

        if(_hasLimits(from, to)) {
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
        }
		
        _tokenTransfer(from,to,amount,takeFee);
    }

    function _hasLimits(address from, address to) private pure returns(bool) {
        if(from == _routerAddress || to == _routerAddress){
            return true;
        }
        return false;
    }
    
    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        tradingEnabled = true;
    }
    
    //this method is responsible for taking all fee, if takeFee is true
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

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256,uint256) {
        (uint256 tTransferAmount, uint256 tFee,uint256 tLiquidity,uint256 tMarket) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarket,_getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee,tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256,uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tMarket = calculateMarketFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tMarket);
        return (tTransferAmount, tFee,tLiquidity,tMarket);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity,uint256 tMarket, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMakert = tMarket.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rMakert);
        return (rAmount, rTransferAmount, rFee);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee,uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee,uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee,uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
	
	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee,uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    

    function swapAndLiquify(uint256 contractTokenBalance) private {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to pancakeSwap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancakeSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeSwapV2Router.WETH();

        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);

        // make the swap
        pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);

        // add the liquidity
        pancakeSwapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }



    
    

}