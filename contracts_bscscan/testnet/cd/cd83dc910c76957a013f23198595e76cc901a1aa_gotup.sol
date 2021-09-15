/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);

}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}


contract gotup is Context, IERC20, Ownable {

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1e15  * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "gotup";
    string private _symbol = "gup";
    uint8 private _decimals = 9;
    
    uint256 public _taxFee = 3;
    uint256 public _buybackFee = 9;  
    uint256 public _marketingFee = 4;
    
    uint256 public sellTaxFee = 6;
    uint256 public sellBuybackFee = 8;
    uint256 public sellMarketingFee = 9;
    
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousBuybackFee = _buybackFee;
	uint256 private _previousMarketingFee = _marketingFee;

    address public marketingWallet = 0x4642F02A1A5755fEeAD4B557c0CE3302D1Ad2550;
    address public buybackWallet = 0xFF455E184475D04F3194d41C5Bcb6111723aB831;

    IRouter public router;
    address public pair;
    
    bool inSwap;
    bool public swapEnabled = true;
    uint256 public swapThreshold = 300000000 * 10**9;
    uint256 public maxBuyAmount = 1271190000000 * 10**9;
    uint256 public maxSellAmount = 22222000000 * 10**9;

    event SwapEnabled(bool enabled);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;

        IRouter _router = IRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a uniswap pair for this new token
        pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        // set the rest of the contract variables
        router = _router;
        
        _isExcluded[pair] = true;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[buybackWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        
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
    
    function updatePair(address newPair) external onlyOwner{
        pair = newPair;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function setRouterAddress(address newRouter) external onlyOwner {
        //give the option to change the router down the line 
        IRouter _newRouter = IRouter(newRouter);
        address get_pair = IFactory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        //checks if pair already exists
        if (get_pair == address(0)) {
            pair = IFactory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            pair = get_pair;
        }
        router = _newRouter;
    }   

    function setMarketingWallet(address _marketingWallet) external onlyOwner()  {
        marketingWallet = _marketingWallet;
        _isExcludedFromFee[marketingWallet] = true;
    }
    
    function setBuybackWallet(address _buybackWallet) external onlyOwner(){
        buybackWallet = _buybackWallet;
        _isExcludedFromFee[buybackWallet] = true;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;
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
    
    
         ///////////////////
        /// Update Fees ///
       ///////////////////
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
        _previousTaxFee = taxFee;
    }

	function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        _marketingFee = marketingFee;
        _previousMarketingFee = marketingFee;
    }
    
    function setBuybackFeePercent(uint256 buybackFee) external onlyOwner() {
        _buybackFee = buybackFee;
        _previousBuybackFee = buybackFee;
    }
    
    function setSellFees(uint256 sellTax, uint256 sellMarketing, uint256 sellBuyback) external onlyOwner{
        sellTaxFee = sellTax;
        sellMarketingFee = sellMarketing;
        sellBuybackFee = sellBuyback;
    }
    
    /// @notice Updates swapEnabled
    /// @param _enabled If "true" internal swaps are enabled, "false" they are disabled
    function setSwapEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
        emit SwapEnabled(_enabled);
    }
    
    function setMaxBuyAndSellAmounts(uint256 maxBuy, uint256 maxSell) external onlyOwner{
        maxBuyAmount = maxBuy * 10**9;
        maxSellAmount = maxSell * 10**9;
    }
    
     //to recieve BNB from router when swaping
    receive() external payable {}

     function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal     = _rTotal - (rFee);
        _tFeeTotal  = _tFeeTotal + (tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tBuyback, uint256 tMarketing) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tBuyback, tMarketing, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBuyback, tMarketing);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tBuyback = calculateBuybackFee(tAmount);
		uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount - (tFee) - (tBuyback) - (tMarketing);
        return (tTransferAmount, tFee, tBuyback, tMarketing);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBuyback, uint256 tMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * (currentRate);
        uint256 rFee = tFee * (currentRate);
        uint256 rBuyback = tBuyback * (currentRate);
		uint256 rMarketing = tMarketing * (currentRate);
        uint256 rTransferAmount = rAmount - (rFee) - (rBuyback) - (rMarketing);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / (tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - (_rOwned[_excluded[i]]);
            tSupply = tSupply - (_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal / (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeBuyback(uint256 tBuyback) private {
        uint256 currentRate =  _getRate();
        uint256 rBuyback = tBuyback * (currentRate);
        _rOwned[address(this)] = _rOwned[address(this)] + (rBuyback);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + (tBuyback);
    }

	function _takeMarketing(uint256 tMarketing) private {
	  uint256 currentRate =  _getRate();
        uint256 rMarketing = tMarketing * (currentRate);
        _rOwned[address(this)] = _rOwned[address(this)] + (rMarketing);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + (tMarketing);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount * (_taxFee) / 100;
    }

    function calculateBuybackFee(uint256 _amount) private view returns (uint256) {
        return _amount * (_buybackFee) / 100;
    }
	function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount * (_marketingFee) / 100;
    }
    
    /// @notice Updates threshold to trigger internal swaps for buyback and marketingTokens
    function setSwapThreshold(uint256 amount) external onlyOwner{
        swapThreshold = amount * 10**9;
    }
    
    /// @notice Rescues BNB sent by mistake to this contract
    function rescueBNBFromContract() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    /// @notice Rescues tokens sent by mistake to this contract.
    /// @dev gup tokens can't be rescued
    function rescueAnyBEP20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        require(_tokenAddr != address(this), "Cannot transfer out gup!");
        IERC20(_tokenAddr).transfer(_to, _amount);
    }
    
    function applySellFees() internal{
        _previousTaxFee = _taxFee;
        _previousBuybackFee = _buybackFee;
		_previousMarketingFee = _marketingFee;

        _taxFee = sellTaxFee;
        _buybackFee = sellBuybackFee;
        _marketingFee = sellMarketingFee;
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _buybackFee == 0 && _marketingFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousBuybackFee = _buybackFee;
		_previousMarketingFee = _marketingFee;

        _taxFee = 0;
        _buybackFee = 0;
		_marketingFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _buybackFee = _previousBuybackFee;
		_marketingFee = _previousMarketingFee;
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

    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(!_isExcludedFromFee[to] && from == pair && !inSwap){
            require(amount <= maxBuyAmount, "Amount is exceeding maxBuyAmount");
        }
        
        if(!_isExcludedFromFee[from] && to == pair && !inSwap){
            require(amount <= maxSellAmount, "Amount is exceeding maxSellAmount");
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapThreshold;
        if (canSwap && !inSwap && from != pair && swapEnabled) {
            swapAndSendToFees(swapThreshold);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        bool isSale = false;
        
        // check if it is a sell, if true ---> apply sell fees
        if(to == pair) isSale = true;
        
        //transfer amount, it will take tax, marketing, buyback fee
        _tokenTransfer(from,to,amount,takeFee, isSale);
    }

    function swapAndSendToFees(uint256 tokens) private lockTheSwap {
        uint256 initBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 totSwapped = address(this).balance - initBalance;
        // Send BNB to marketing
        uint256 marketingAmt = totSwapped / (_marketingFee + _buybackFee) * _marketingFee;
        if(marketingAmt > 0){
            payable(marketingWallet).transfer(marketingAmt);
        }
        if(totSwapped - marketingAmt > 0){
            payable(buybackWallet).transfer(totSwapped - marketingAmt);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee, bool isSale) private {
        if(!takeFee)
            removeAllFee();
            
        else if(isSale) applySellFees();
            
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient,  amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient,  amount);
        } else {
            _transferStandard(sender, recipient,  amount);
        }
        
        if(!takeFee || isSale)
            restoreAllFee();
    }

   function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBuyback, uint256 tMarketing) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);

		_takeBuyback(tBuyback);
		_takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
     function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBuyback, uint256 tMarketing) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);

		_takeBuyback(tBuyback);
		_takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBuyback, uint256 tMarketing) = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);

		_takeBuyback(tBuyback);
		_takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBuyback, uint256 tMarketing) = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
		_takeBuyback(tBuyback);
		_takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    
}