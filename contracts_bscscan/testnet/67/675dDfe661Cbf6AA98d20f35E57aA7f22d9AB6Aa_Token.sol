pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

import "./Context.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./DividendTracker.sol";

contract Token is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    BABYBAKEDividendTracker public dividendTracker;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromAntiWhale;
    mapping (address => bool) private _isBlackList;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    

    string private _name;
    string private _symbol;
    uint256 private _decimals;
    
    uint256 public _taxFeeBuy;
    uint256 public _taxFeeSell;
    uint256 private _previousTaxFeeBuy;
    uint256 private _previousTaxFeeSell;
    
    uint256 public _liquidityFeeBuy;
    uint256 public _liquidityFeeSell;
    uint256 private _previousLiquidityFeeBuy;
    uint256 private _previousLiquidityFeeSell;

    uint256 public  _marketingFee;
    uint256 private _previousMarketingFee;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public _marketingWallet ;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public _maxTxAmountSell;
    uint256 public _maxTxAmountBuy;
    uint256 public _maxTxAmountTransfer;
    uint256 public numTokensSellToAddToLiquidity;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor (string memory _NAME, string memory _SYMBOL, uint256 _DECIMALS, uint256 _supply, uint256 _mktFee, uint256 _txFeeBuy,uint256 _lpFeeBuy,uint256 _txFeeSell,uint256 _lpFeeSell,uint256 _MAXAMOUNT_BUY,uint256 _MAXAMOUNT_SELL,uint256 _MAXAMOUNT_TRANSFER,uint256 SELLMAXAMOUNT,address routerAddress,address tokenOwner,address _mkwallet)  public {
        _name = _NAME;
        _symbol = _SYMBOL;
        _decimals = _DECIMALS;
        _tTotal = _supply * 10 ** _decimals;
        _rTotal = (MAX - (MAX % _tTotal));
        _taxFeeBuy = _txFeeBuy;
        _taxFeeSell = _txFeeSell;
        _liquidityFeeBuy = _lpFeeBuy;
        _liquidityFeeSell = _lpFeeSell;
        _previousTaxFeeBuy = _txFeeBuy;
        _previousTaxFeeSell = _txFeeSell;
        _previousLiquidityFeeBuy = _lpFeeBuy;
        _previousLiquidityFeeSell = _lpFeeSell;
        _previousMarketingFee = _mktFee;
        _maxTxAmountBuy = _MAXAMOUNT_BUY * 10 ** _decimals;
        _maxTxAmountSell = _MAXAMOUNT_SELL * 10 ** _decimals;
        _maxTxAmountTransfer = _MAXAMOUNT_TRANSFER * 10 ** _decimals;
        numTokensSellToAddToLiquidity = SELLMAXAMOUNT * 10 ** _decimals;
        _rOwned[tokenOwner] = _rTotal;
        _isExcludedFromAntiWhale[tokenOwner] = true;
        _marketingWallet= _mkwallet;
        
        dividendTracker = new BABYBAKEDividendTracker();
       
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[tokenOwner] = true;
        _isExcludedFromFee[address(this)] = true;
    
        _owner = tokenOwner;
        emit Transfer(address(0), tokenOwner, _tTotal);
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
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
    
    function addBlackList(address account) public onlyOwner {
        _isBlackList[account] = true;
    }
    function removeBlackList(address account) public onlyOwner {
        _isBlackList[account] = false;
    }
    
    function excludeFromAntiWhale(address account) public onlyOwner {
        _isExcludedFromAntiWhale[account] = true;
    }
    
    function includeFromAntiWhale(address account) public onlyOwner {
        _isExcludedFromAntiWhale[account] = false;
    }
    
    function setMarketingFee(uint256 marketingFee) external onlyOwner() {
        _marketingFee = marketingFee;
    }
    
    function setTaxFeePercentBuy(uint256 taxFee) external onlyOwner() {
        _taxFeeBuy = taxFee;
    }
    function setTaxFeePercentSell(uint256 taxFee) external onlyOwner() {
        _taxFeeSell = taxFee;
    }

    function setMarketingWallet(address mkwallet) external onlyOwner(){
        _marketingWallet = mkwallet;
    }
    
    function setLiquidityFeePercentBuy(uint256 liquidityFee) external onlyOwner() {
        _liquidityFeeBuy = liquidityFee;
    }
    function setLiquidityFeePercentSell(uint256 liquidityFee) external onlyOwner() {
        _liquidityFeeSell = liquidityFee;
    }
    
    function setNumTokensSellToAddToLiquidity(uint256 swapNumber) public onlyOwner {
        numTokensSellToAddToLiquidity = swapNumber * 10 ** _decimals;
    }
   
    function setMaxTansactionAmountBuy(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmountBuy = maxTxAmount  * 10 ** _decimals;
    }
    function setMaxTansactionAmountSell(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmountSell = maxTxAmount  * 10 ** _decimals;
    }
    function setMaxTansactionAmountTransfer(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmountTransfer = maxTxAmount  * 10 ** _decimals;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve BNB from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256,uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tMarketing);
    }
    
    function _getValuesSell(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256,uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getTValuesSell(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tMarketing);
        return (tTransferAmount, tFee, tLiquidity, tMarketing);
    }
    function _getTValuesSell(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFeeSell(tAmount);
        uint256 tLiquidity = calculateLiquidityFeeSell(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tMarketing);
       
        return (tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rMarketing);
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
    
    function _takeMarketingFee(uint256 tMarketing) private {
        uint256 currentRate =  _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[_marketingWallet] = _rOwned[_marketingWallet].add(rMarketing);
        if(_isExcluded[_marketingWallet])
            _tOwned[_marketingWallet] = _tOwned[_marketingWallet].add(tMarketing);
    }
    
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFeeBuy).div(
            10**2
        );
    }
    function calculateTaxFeeSell(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFeeSell).div(
            10**2
        );
    }
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFeeBuy).div(
            10**2
        );
    }
    function calculateLiquidityFeeSell(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFeeSell).div(
            10**2
        );
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_taxFeeBuy == 0 && _liquidityFeeBuy == 0 && _taxFeeSell == 0 && _liquidityFeeSell == 0) return;
        
        _previousTaxFeeBuy = _taxFeeBuy;
        _previousTaxFeeSell = _taxFeeSell;
        _previousLiquidityFeeBuy = _liquidityFeeBuy;
        _previousLiquidityFeeSell = _liquidityFeeSell;
        _previousMarketingFee = _marketingFee;
        
        _taxFeeBuy = 0;
        _taxFeeSell = 0;
        _liquidityFeeBuy = 0;
        _liquidityFeeSell = 0;  
        _marketingFee = 0;
        
    }
    
    function restoreAllFee() private {
        _taxFeeBuy = _previousTaxFeeBuy;
        _taxFeeSell = _previousTaxFeeSell;
        _liquidityFeeBuy = _previousLiquidityFeeBuy;
        _liquidityFeeSell = _previousLiquidityFeeSell;
        _marketingFee = _previousMarketingFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function isBlackList(address account) public view returns(bool) {
        return _isBlackList[account];
    }    
    
    function isExcludedFromAntiWhale(address account) public view returns(bool) {
        return _isExcludedFromAntiWhale[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!(isBlackList(from) ) , "User origin in blackList");
        require(!(isBlackList(to) ) , "User destination in blackList");
        if(!(isExcludedFromAntiWhale(from) || isExcludedFromAntiWhale(to))) { // white list of antiwhale excluded from maxAmount
            if(to == uniswapV2Pair){
                require(amount <= _maxTxAmountSell, "Transfer amount exceeds the maxTxAmount sell.");
            }
            else if(from == uniswapV2Pair){
                require(amount <= _maxTxAmountBuy, "Transfer amount exceeds the maxTxAmount buy.");
            }
            
            else{
                require(amount <= _maxTxAmountTransfer, "Transfer amount exceeds the maxTxAmount.");

            }
        }
        
     
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmountBuy)
        {
            contractTokenBalance = _maxTxAmountBuy;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
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
            owner(),
            block.timestamp
        );
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

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 rAmount;uint256 rTransferAmount; uint256 rFee; uint256 tTransferAmount; uint256 tFee; uint256 tLiquidity; uint256 tMarketing;
        if(recipient == uniswapV2Pair){
            ( rAmount,  rTransferAmount,  rFee,  tTransferAmount,  tFee,  tLiquidity, tMarketing) = _getValuesSell(tAmount);
        }
        else{
            ( rAmount,  rTransferAmount,  rFee,  tTransferAmount,  tFee,  tLiquidity, tMarketing) = _getValues(tAmount);    
        }
       
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _takeMarketingFee(tMarketing);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 rAmount;uint256 rTransferAmount; uint256 rFee; uint256 tTransferAmount; uint256 tFee; uint256 tLiquidity; uint256 tMarketing;
        if(recipient == uniswapV2Pair){
            ( rAmount,  rTransferAmount,  rFee,  tTransferAmount,  tFee,  tLiquidity, tMarketing) = _getValuesSell(tAmount);
        }
        else{
            ( rAmount,  rTransferAmount,  rFee,  tTransferAmount,  tFee,  tLiquidity, tMarketing) = _getValues(tAmount);    
        }
       
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _takeMarketingFee(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 rAmount;uint256 rTransferAmount; uint256 rFee; uint256 tTransferAmount; uint256 tFee; uint256 tLiquidity; uint256 tMarketing;
        if(recipient == uniswapV2Pair){
            ( rAmount,  rTransferAmount,  rFee,  tTransferAmount,  tFee,  tLiquidity, tMarketing) = _getValuesSell(tAmount);
        }
        else{
            ( rAmount,  rTransferAmount,  rFee,  tTransferAmount,  tFee,  tLiquidity, tMarketing) = _getValues(tAmount);    
        }
       
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _takeMarketingFee(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 rAmount;uint256 rTransferAmount; uint256 rFee; uint256 tTransferAmount; uint256 tFee; uint256 tLiquidity; uint256 tMarketing;
        if(recipient == uniswapV2Pair){
            ( rAmount,  rTransferAmount,  rFee,  tTransferAmount,  tFee,  tLiquidity, tMarketing) = _getValuesSell(tAmount);
        }
        else{
            ( rAmount,  rTransferAmount,  rFee,  tTransferAmount,  tFee,  tLiquidity, tMarketing) = _getValues(tAmount);    
        }
       
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    
    function RescueBNB() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    
    }
}