pragma solidity ^0.8.6;
// SPDX-License-Identifier: Unlicensed

import "./GensinLib.sol";

contract GENSINTOEKN is Context, IBEP20, Ownable {
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
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10000000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Genshin NFT";
    string private _symbol = "GENSHIN";
    uint8 private _decimals = 9;
    
    uint256 public _taxFee = 2; //分紅比例
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _marketFee = 2; //市场比例
    uint256 private _previousMarketFee = _marketFee;
	
	uint256 public _destoryFee = 1; //燃燒比例
    uint256 private _previousDestoryFee = _destoryFee;
    
    uint256 public _liquidityFee = 5;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 private _power = 2;

    IPancakeSwapV2Router02 public immutable pancakeSwapV2Router;
    address public immutable pancakeSwapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public _maxTxAmount = 1000000000000000 * 10**9; 
    uint256 private numTokensSellToAddToLiquidity = 5000000000000000 * 10**9; 
	
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        IPancakeSwapV2Router02 _pancakeSwapV2Router = IPancakeSwapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); 
        
       
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
        require(!_isExcluded[sender], "Cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
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
    
        
    struct TAllFee {
        uint256 tFee;
        uint256 tCharity;
        uint256 tBurn;
        uint256 tLiquidity;
    }
    
    struct RParamter {
        uint256 tAmount;
        uint256 tFee;
        uint256 tCharity;
        uint256 tBurn;
        uint256 tLiquidity;
        uint256 currentRate;
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
    
    function setMarketingAddress(address account) external onlyOwner(){
        _marketingAddress = account;
    }

    function setDestroyAddress(address account) external onlyOwner(){
        _destroyAddress = account;
    }
    
    function setLiquidAddress(address account) external onlyOwner() {
        _poolAddress = account;
    }
    
    function getMarketingAddress() public view returns(address){
        return _marketingAddress;
    }
    
    function getDestoryAddress() public view returns(address){
        return _destroyAddress;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setMarketingFeePercent(uint256 marketFee) external onlyOwner() {
        _marketFee = marketFee;
    }
	
	function setDestroyFeePercent(uint256 destoryFee) external onlyOwner() {
        _destoryFee = destoryFee;
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

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from pancakeSwapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, TAllFee memory) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tCharity,uint256 tBurn,uint256 tLiquidity) = _getTValues(tAmount);
        RParamter memory par;
        par.tAmount=tAmount;
        par.tFee = tFee;
        par.tCharity = tCharity;
        par.tBurn = tBurn;
        par.tLiquidity = tLiquidity;
        par.currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(par);
        TAllFee memory tAllFee;
        tAllFee.tFee = tFee;
        tAllFee.tCharity = tCharity;
        tAllFee.tBurn = tBurn;
        tAllFee.tLiquidity = tLiquidity;
        
        return (rAmount, rTransferAmount, rFee, tTransferAmount,tAllFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256,uint256,uint256) {
        uint256 tFee = calculateTaxFee(tAmount); 
        uint256 tDestory = calculateDestoryFee(tAmount);
        uint256 tMarket = calculateMarketFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 temptTransferAmount = tAmount.sub(tFee).sub(tMarket);
        temptTransferAmount = temptTransferAmount.sub(tDestory);
        uint256 tTransferAmount = temptTransferAmount.sub(tLiquidity);
        return (tTransferAmount, tFee, tMarket,tDestory,tLiquidity);
    }



    function _getRValues(RParamter memory _par) private pure returns (uint256, uint256, uint256) {
        // RParamter memory _par;
        uint256 rAmount = _par.tAmount.mul(_par.currentRate);
        uint256 rFee = _par.tFee.mul(_par.currentRate);
        uint256 rCharity = _par.tCharity.mul(_par.currentRate);
        uint256 rBurn = _par.tBurn.mul(_par.currentRate);
        uint256 rLiquidity = _par.tLiquidity.mul(_par.currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rCharity).sub(rBurn).sub(rLiquidity);
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
        _rOwned[_poolAddress] = _rOwned[_poolAddress].add(rLiquidity);
        if(_isExcluded[_poolAddress])
            _tOwned[_poolAddress] = _tOwned[_poolAddress].add(tLiquidity);
    }
	
    function _takeCharity(uint256 tCharity) private {
        uint256 currentRate =  _getRate();
        uint256 rCharity = tCharity.mul(currentRate);
        _rOwned[_marketingAddress] = _rOwned[_marketingAddress].add(rCharity);
        if(_isExcluded[_marketingAddress])
            _tOwned[_marketingAddress] = _tOwned[_marketingAddress].add(tCharity);
    }
	
	function _takeBurn(uint256 tBurn) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[_destroyAddress] = _rOwned[_destroyAddress].add(rBurn);
        if(_isExcluded[_destroyAddress])
            _tOwned[_destroyAddress] = _tOwned[_destroyAddress].add(tBurn);
    }
    

	
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**_power
        );
    }

    function calculateMarketFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketFee).div(
            10**_power
        );
    }
	
	function calculateDestoryFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_destoryFee).div(
            10**_power
        );
    }
    
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**_power
        );
    }
	
    
    function removeAllFee() private {
        if(_taxFee == 0 && _destoryFee == 0 && _marketFee == 0 && _liquidityFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousMarketFee = _marketFee;
		_previousDestoryFee = _destoryFee;
		_previousLiquidityFee = _liquidityFee;
		
        _taxFee = 0;
        _marketFee = 0;
		_destoryFee = 0;
		_liquidityFee = 0;
    }
	
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _marketFee = _previousMarketFee;
		_destoryFee = _previousDestoryFee;
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

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeSwap pair.
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
            emit LogShow('take Fee is false');
        }
        
        //whitelist for bot
        if(_botWhiteListFee[from] || _botWhiteListFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, charity fee
        _tokenTransfer(from,to,amount,takeFee);
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



    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, TAllFee memory tAllFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeCharity(tAllFee.tCharity);
        _takeBurn(tAllFee.tBurn);
        _takeLiquidity(tAllFee.tLiquidity);
        _reflectFee(rFee, tAllFee.tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, TAllFee memory tAllFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeCharity(tAllFee.tCharity);
        _takeBurn(tAllFee.tBurn);
        _takeLiquidity(tAllFee.tLiquidity);
        _reflectFee(rFee, tAllFee.tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount,TAllFee memory tAllFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeCharity(tAllFee.tCharity);
        _takeBurn(tAllFee.tBurn);
        _takeLiquidity(tAllFee.tLiquidity);
        _reflectFee(rFee, tAllFee.tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
	
	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, TAllFee memory tAllFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeCharity(tAllFee.tCharity);
        _takeBurn(tAllFee.tBurn);
        _takeLiquidity(tAllFee.tLiquidity);
        _reflectFee(rFee, tAllFee.tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

}