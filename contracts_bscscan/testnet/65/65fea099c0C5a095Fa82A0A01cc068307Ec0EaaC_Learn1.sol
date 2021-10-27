// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./ILotteryTracker.sol";

contract Learn1 is Context, IERC20, Ownable{

    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromAutoLiquidity;
    mapping (address => bool) private _isBlacklisted;
    address [] private _list;
    mapping (address => bool) private _transferExclusions;
    address[] private _excluded;
    address payable public _marketingWallet = payable(0xE38d290DF0316ab35B80C9e143148721a36284D4); 
    address payable public _buyBackWallet = payable(0xE38d290DF0316ab35B80C9e143148721a36284D4); 
    address payable public _lotteryWallet = payable(0xE38d290DF0316ab35B80C9e143148721a36284D4); 
    address public ownerAddress = 0xE38d290DF0316ab35B80C9e143148721a36284D4;
    IERC20 public rewardToken;
    ILotteryTracker public lotteryTracker;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    bool public rewardInBNB = false;
    bool public isEarlySellingEnabled = false;
    mapping(address => bool) _isExcludedFromEarlySellingLimit;
    mapping (address => uint256) private lastBuyTime;
    uint256 public earlySellingFee24HRPercent = 20;
    uint256 public earlySellingFee48HRPercent = 15;
    uint256 public entryDivider = 10000000 * 10**9;
    mapping(address => bool) _isExcludedFromLottery;
    mapping(address => bool) _accountInLottery;
    mapping(address => bool) _isLpPair;

    string private constant _name     = "LEARN";
    string private constant _symbol   = "LEARN";
    uint8  private constant _decimals = 9;
    
    uint256 private  _lotteryTax       = 2;
    uint256 private  _marketingTax       = 4;
    uint256 private  _buyBackTax       = 2;
    uint256 public  _taxFee       = 1; // holders tax
    uint256 public  _liquidityFee = 1; // auto lp tax
    uint256 public  _totalTaxForDistribution  = _lotteryTax.add(_marketingTax).add(_buyBackTax); // total tax for distribution
    uint256 public  _totalFees      = _taxFee.add(_liquidityFee).add(_totalTaxForDistribution);
    
    uint256 public  _maxTxAmount     = 5000 * 10**6 * 10**9;
    uint256 private _minimumTokenBalance = 500 * 10**6 * 10**9;
    
    
    IUniswapV2Router02 public pancakeV2Router;
    address            public pancakeV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    event MinimumTokensBeforeSwapUpdated(uint256 minimumTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event UpdateLastBuyTime(address account, uint256 time);
    event RemoveAccountFromLottery(address account);
    event AddAccountToLottery(address account);
    
    modifier ltsTheSwap{
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor (address _lotteryTracker) {
        _rOwned[ownerAddress] = _rTotal;
        // set default to BUSD 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
        // busd on beta 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47
        rewardToken = IERC20(0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47);
        lotteryTracker = ILotteryTracker(_lotteryTracker);
        // pancake
        //beta router 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        // prod router 0x10ED43C718714eb63d5aA57B78B54704E256024E
        IUniswapV2Router02 _pancakeV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        pancakeV2Pair = IUniswapV2Factory(_pancakeV2Router.factory())
            .createPair(address(this), _pancakeV2Router.WETH());
        pancakeV2Router = _pancakeV2Router;
        
        // exclude system address
        _isExcludedFromFee[ownerAddress]    = true;
        _isExcludedFromFee[address(this)]   = true;
        _isExcludedFromFee[_marketingWallet] = true;
        _isExcludedFromFee[_buyBackWallet] = true;
        _isExcludedFromFee[_lotteryWallet] = true;
        _isExcludedFromEarlySellingLimit[ownerAddress] = true;
        _isExcludedFromEarlySellingLimit[address(this)] = true;
        _isExcludedFromEarlySellingLimit[_marketingWallet] = true;
        _isExcludedFromEarlySellingLimit[_buyBackWallet] = true;
        _isExcludedFromEarlySellingLimit[_lotteryWallet] = true;
        _isExcludedFromEarlySellingLimit[pancakeV2Pair] = true;
        _isExcludedFromEarlySellingLimit[address(pancakeV2Router)] = true;
        _isExcludedFromAutoLiquidity[pancakeV2Pair]            = true;
        _isExcludedFromAutoLiquidity[address(pancakeV2Router)] = true;
        _isExcludedFromLottery[address(this)] = true;
        _isExcludedFromLottery[pancakeV2Pair] = true;
        _isExcludedFromLottery[address(pancakeV2Router)] = true;
        _isLpPair[pancakeV2Pair] = true;
        _isLpPair[address(pancakeV2Router)] = true;
        
        // TO DO
        //_isExcludedFromLottery[ownerAddress] = true;
       // _isExcludedFromLottery[_marketingWallet] = true;
       // _isExcludedFromLottery[_lotteryWallet] = true;
       // _isExcludedFromLottery[_buyBackWallet] = true;

        
        emit Transfer(address(0), ownerAddress, _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        (, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount,0);
        uint256 currentRate = _getRate();

        if (!deductTransferFee) {
            (uint256 rAmount,,) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
            return rAmount;

        } else {
            (, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");

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


    function getLotteryEntryAmount(uint256 amount) internal view returns(uint256) {
        if (amount == 0) {
            return 0;
        }

        uint256 entries = amount / entryDivider;
        if (amount % entryDivider > 0) {
            return entries + 1;
        }

        return entries;
    }

    function setLotteryTracker(address _lotteryTracker) external onlyOwner {
        lotteryTracker = ILotteryTracker(_lotteryTracker);
        _isExcludedFromLottery[address(_lotteryTracker)] = true;
    }


    function setRewardInBNB(bool  a) external onlyOwner{
        rewardInBNB = a;
    }

    function setEarlySellingEnabled(bool  a) external onlyOwner{
        isEarlySellingEnabled = a;
    }
    
    function setRewardToken(address token) external onlyOwner{
       rewardToken = IERC20(token);
    }

    function setExcludedFromLottery(address holder, bool a) external onlyOwner {
        _isExcludedFromLottery[holder] = a;
    }

    function isExcludedFromLottery(address holder) external view returns(bool) {
        return _isExcludedFromLottery[holder];
    }

    function isAccountInLottery(address account) external view returns(bool) {
        if(_accountInLottery[account]){
            return lotteryTracker.isActiveAccount(account);
        }
        return false;
    }

    function setMarketingWallet(address  wallet) external onlyOwner{
        _marketingWallet = payable(wallet);
        _isExcludedFromFee[_marketingWallet] = true;
        _isExcludedFromEarlySellingLimit[_marketingWallet] = true;
       // _isExcludedFromLottery[_marketingWallet] = true;
    }

    function setBuyBackWallet(address  wallet) external onlyOwner{
        _buyBackWallet = payable(wallet);
        _isExcludedFromFee[_buyBackWallet] = true;
        _isExcludedFromEarlySellingLimit[_buyBackWallet] = true;
        //_isExcludedFromLottery[_buyBackWallet] = true;
    }

    function setLotteryWallet(address  wallet) external onlyOwner{
        _lotteryWallet = payable(wallet);
        _isExcludedFromFee[_lotteryWallet] = true;
        _isExcludedFromEarlySellingLimit[_lotteryWallet] = true;
       // _isExcludedFromLottery[_lotteryWallet] = true;
    } 
    
    function setExcludedFromFee(address account, bool e) external onlyOwner {
        _isExcludedFromFee[account] = e;
    }
    // Quantity required for Loto entry
    function setEntryDivider(uint256 entryDividerAmount) external onlyOwner {
        require(entryDividerAmount>0, "EntryDividerAmount  is less than 0");
        entryDivider = entryDividerAmount;
    }

    function setEarlySelling24HRTax(uint256 taxFee) external onlyOwner {
        require(taxFee>0, "Holder tax is less than 0");
        earlySellingFee24HRPercent = taxFee;
    }

    function setEarlySelling48HRTax(uint256 taxFee) external onlyOwner {
        require(taxFee>0, "Holder tax is less than 0");
         earlySellingFee48HRPercent = taxFee;
    }
    
    function setHoldersFeePercent(uint256 taxFee) external onlyOwner {
        require(taxFee>0, "Holder tax is less than 0");
        _taxFee = taxFee;
        _totalFees      = _taxFee.add(_liquidityFee).add(_totalTaxForDistribution);
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        require(liquidityFee>0, "Liquidity tax is less than 0");
        _liquidityFee = liquidityFee;
        _totalFees      = _taxFee.add(_liquidityFee).add(_totalTaxForDistribution);
    }

    function setTotalTaxForDistribution(uint256 lotteryTax,uint256 marketingTax,uint256 buyBackTax) external onlyOwner {
        require(lotteryTax>0, "Lottery tax is less than 0");
        require(marketingTax>0, "Marketing tax is less than 0");
        require(buyBackTax>0, "BuyBack tax is less than 0");
        _totalTaxForDistribution = lotteryTax.add(marketingTax).add(buyBackTax);
        _lotteryTax = lotteryTax;
        _marketingTax = marketingTax;
        _buyBackTax = buyBackTax;
        _totalFees      = _taxFee.add(_liquidityFee).add(_totalTaxForDistribution);
    }
    
    function setMaxTx(uint256 maxTx) external onlyOwner {
        require(maxTx >10000000, "Max transaction is less than 10000000");
        _maxTxAmount = maxTx;
    }

    function setContractSellThreshold(uint256 minimumTokenBalance) external onlyOwner {
        require(minimumTokenBalance > 1000000, "Max transaction is less than 1000000");
        _minimumTokenBalance = minimumTokenBalance;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    receive() external payable {}

    
    function updateNewRouter(address _router) public onlyOwner returns(address _pair) {
       
        IUniswapV2Router02 _pancakeV2Router = IUniswapV2Router02(_router);
        _pair = IUniswapV2Factory(_pancakeV2Router.factory()).getPair(address(this), _pancakeV2Router.WETH());
        if(_pair == address(0)){
            // Pair doesn't exist, create a new one
            _pair = IUniswapV2Factory(_pancakeV2Router.factory())
            .createPair(address(this), _pancakeV2Router.WETH());
        }
        pancakeV2Pair = _pair;
        // Update the router of the contract variables
        pancakeV2Router = _pancakeV2Router;
        _isExcludedFromAutoLiquidity[pancakeV2Pair]            = true;
        _isExcludedFromAutoLiquidity[address(pancakeV2Router)] = true;
        _isExcludedFromEarlySellingLimit[pancakeV2Pair] = true;
        _isExcludedFromEarlySellingLimit[address(pancakeV2Router)] = true;
        _isLpPair[pancakeV2Pair] = true;
        _isLpPair[address(pancakeV2Router)] = true;
        
    }
    

    function setIsLpPair(address a, bool b) external onlyOwner {
        _isLpPair[a] = b;
    }

     function isAddressLpPair(address a) external view returns(bool) {
        return _isLpPair[a];
    }

    function setExcludedFromAutoLiquidity(address a, bool b) external onlyOwner {
        _isExcludedFromAutoLiquidity[a] = b;
    }

    // to blacklist bots
    function blacklist(address _address, bool setTo) external onlyOwner {
        _isBlacklisted[_address] = setTo;
        if(setTo == true){
            _list.push(_address);
        }
        
    }

    function setTransferExclusions(address _address, bool setTo) external onlyOwner {
        _transferExclusions[_address] = setTo;
    }

    function getTransferExclusions(address account) public view returns (bool) {
        return _transferExclusions[account];
    }

    function checkBlackList() public view returns(address[] memory){
        address[] memory response = new address[](_list.length);
        for (uint i = 0; i < _list.length; i++) {
            if(_isBlacklisted[_list[i]] == true){
                response[i] = _list[i];
            }
        }
        return response;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal    = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getTValues(uint256 tAmount, uint256 earlySellingTaxAmount) private view returns (uint256, uint256, uint256) {
        //Total fee for distribution and autolp
        uint256 _totalFeesForBNB = _liquidityFee.add(_totalTaxForDistribution);
        uint256 tFee       = tAmount.mul(_taxFee).div(100);
        uint256 tLiquidity = tAmount.mul(_totalFeesForBNB).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        if(earlySellingTaxAmount>0){
            tLiquidity = tLiquidity.add(earlySellingTaxAmount);
        }
        tTransferAmount = tTransferAmount.sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount    = tAmount.mul(currentRate);
        uint256 rFee       = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        rTransferAmount = rTransferAmount.sub(rLiquidity);
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
    
    function takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) private {
        if (tAmount <= 0) { return; }

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to].add(tAmount);
        }
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
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
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "Cannot transfer from or to a blacklisted address");

        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool isOverMinimumTokenBalance = contractTokenBalance >= _minimumTokenBalance;
        if (
            isOverMinimumTokenBalance &&
            !inSwapAndLiquify &&
            !_isExcludedFromAutoLiquidity[from] &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _minimumTokenBalance;
            swapAndLiquify(contractTokenBalance);
        }
        // When from is LP pair then its a buy
        if(!inSwapAndLiquify && _isLpPair[from]){
            recordLastBuy(to);
        }
        
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private ltsTheSwap {
        
        uint256 _totalFeesForBNB = _liquidityFee.add(_totalTaxForDistribution);
        if(_totalFeesForBNB < 1){
            _totalFeesForBNB = 1;
        }
        // take LP part from total balance
        uint256 lpPart = contractTokenBalance.mul(_liquidityFee).div(_totalFeesForBNB);
        uint256 distributionPart = contractTokenBalance.sub(lpPart);
        uint256 half      = lpPart.div(2);
        uint256 otherHalf = lpPart.sub(half);

        uint256 initialBalance = address(this).balance;
        swapTokensForBnb(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
        // swap and take distribution part
        if( distributionPart > 0)
        {
            initialBalance = address(this).balance;
            swapTokensForBnb(distributionPart);
            newBalance = address(this).balance.sub(initialBalance);
            // devide the converted token to lottery, marketing and Buy back
            if(rewardInBNB){
                uint256 lotteryPart = newBalance.mul(_lotteryTax).div(_totalTaxForDistribution);
                uint256 marketingPart = newBalance.mul(_marketingTax).div(_totalTaxForDistribution);
                uint256 buyBackPart = newBalance.mul(_buyBackTax).div(_totalTaxForDistribution);
                transferToAddressBNB(_lotteryWallet,lotteryPart);
                transferToAddressBNB(_marketingWallet,marketingPart);
                transferToAddressBNB(_buyBackWallet,buyBackPart);
            }else{
                swapAndSendToken(newBalance);
            }
            
        }
    }
function swapAndSendToken(uint256 bnbBalance) private ltsTheSwap {
        uint256 initialBalance = rewardToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = pancakeV2Router.WETH();
        path[1] = address(rewardToken);

        pancakeV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbBalance}(
            0,
            path,
            address(this),
            block.timestamp
        );


        uint256 tokenReceived = rewardToken.balanceOf(address(this)).sub(initialBalance);
        uint256 lotteryPart = tokenReceived.mul(_lotteryTax).div(_totalTaxForDistribution);
        uint256 marketingPart = tokenReceived.mul(_marketingTax).div(_totalTaxForDistribution);
        uint256 buyBackPart = tokenReceived.mul(_buyBackTax).div(_totalTaxForDistribution);
        rewardToken.transfer(_lotteryWallet, lotteryPart);
        rewardToken.transfer(_marketingWallet, marketingPart);
        rewardToken.transfer(_buyBackWallet, buyBackPart);
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeV2Router.WETH();

        _approve(address(this), address(pancakeV2Router), tokenAmount);
        pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(pancakeV2Router), tokenAmount);
        pancakeV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function setExcludedFromEarlySellingLimit(address holder, bool status) external onlyOwner {
        _isExcludedFromEarlySellingLimit[holder] = status;
    }

    function recordLastBuy(address buyer) internal {
        lastBuyTime[buyer] = block.timestamp;
        emit UpdateLastBuyTime(buyer, block.timestamp);
    }

    function getLastBuy(address buyer) external view returns(uint256) {
        return lastBuyTime[buyer];
    }

    function calculateEarlySellingFee(address from, uint256 amount) internal view returns(uint256) {
        if (_isExcludedFromEarlySellingLimit[from]) {
            return 0;
        }
        if (block.timestamp.sub(lastBuyTime[from]) < 24 * 1 hours) {
            return amount.mul(earlySellingFee24HRPercent).div(100);
        }else if (block.timestamp.sub(lastBuyTime[from]) < 48 * 1 hours) {
            return amount.mul(earlySellingFee48HRPercent).div(100);
        }
        return 0;
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        uint256 previousTaxFee       = _taxFee;
        uint256 previousLiquidityFee = _liquidityFee;
        uint256 previousTaxForDistributionFee  = _totalTaxForDistribution;
        uint256 earlySellingTaxAmount = 0;
        if (!takeFee) {
            _taxFee       = 0;
            _liquidityFee = 0;
            _totalTaxForDistribution  = 0;
        }else if(isEarlySellingEnabled){
            earlySellingTaxAmount = calculateEarlySellingFee(sender, amount);
        }
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount,earlySellingTaxAmount);

        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount,earlySellingTaxAmount);

        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount,earlySellingTaxAmount);

        } else {
            _transferStandard(sender, recipient, amount,earlySellingTaxAmount);
        }
        
        if (!takeFee) {
            _taxFee       = previousTaxFee;
            _liquidityFee = previousLiquidityFee;
            _totalTaxForDistribution  = previousTaxForDistributionFee;
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount,uint256 earlySellingTaxAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount,earlySellingTaxAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
        _rOwned[sender]    = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        updateAccountLottery(sender,recipient,tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount,uint256 earlySellingTaxAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount,earlySellingTaxAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        updateAccountLottery(sender,recipient,tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount,uint256 earlySellingTaxAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount,earlySellingTaxAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        updateAccountLottery(sender,recipient,tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount,uint256 earlySellingTaxAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount,earlySellingTaxAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        updateAccountLottery(sender,recipient,tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function updateAccountLottery(address removeAccount, address addAccount, uint256 amount) internal {
        if(_transferExclusions[addAccount]){
            // don't remove the account from lottery as this is approved address, 
            //but we need to reduce the entry from lottery
            uint256 entries = getLotteryEntryAmount(amount);
            lotteryTracker.removeEntryFromWallet(addAccount, entries);
            return;
        }
        if (_accountInLottery[removeAccount]) {
            _accountInLottery[removeAccount] = false;
            if(lotteryTracker.isActiveAccount(removeAccount)){
                lotteryTracker.removeAccount(removeAccount);
            }
            emit RemoveAccountFromLottery(removeAccount);
        }

        if (!_isExcludedFromLottery[addAccount]) {
            uint256 entries = getLotteryEntryAmount(amount);
            lotteryTracker.updateAccount(addAccount, entries);
            if (!_accountInLottery[addAccount]) {
                _accountInLottery[addAccount] = true;
                emit AddAccountToLottery(addAccount);
            }
        }
    }
    
    function transferToAddressBNB(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function transferForeignToken(address _token, address _to) public onlyOwner returns(bool _sent){
        require(_token != address(this), "Clear the contract from junk tokens. This tokens are sent to spam this the contract.");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }
    
    // This is recommended by Certik, if this is not used many BNB will be lost forever.
    function sweep(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }


    function prepareForPresale() public onlyOwner {
        _taxFee       = 0; // holders tax
        _liquidityFee = 0; // auto lp tax
        _totalTaxForDistribution  = 0;
        _totalFees      = _taxFee.add(_liquidityFee).add(_totalTaxForDistribution);
        _maxTxAmount = _tTotal;
        swapAndLiquifyEnabled = false; 
    }
    
    function activateContractAfterPresale() public onlyOwner {
        _maxTxAmount     = 5000 * 10**6 * 10**9;
        swapAndLiquifyEnabled = true;
        _taxFee       = 1; // holders tax
        _liquidityFee = 1; // auto lp tax
        _totalTaxForDistribution  = 8;
        _totalFees      = _taxFee.add(_liquidityFee).add(_totalTaxForDistribution);
    }
        
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.5.0;

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

    event Mint(address indexed sender, uint amount0, uint amount1);
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IUniswapV2Router01.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface ILotteryTracker {
    function updateAccount(address account, uint256 amount) external;
    function removeEntryFromWallet(address account, uint256 amount) external;
    function removeAccount(address account) external;
    function isActiveAccount(address account) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
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