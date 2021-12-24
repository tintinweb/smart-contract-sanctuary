/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

/**
 *
_____/\\\\\\\\\\\____/\\\________/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\____/\\\________/\\\____/\\\\\\\\\_________/\\\\\\\\\_____/\\\\\\\\\\\_        
 ___/\\\/////////\\\_\/\\\_______\/\\\_\/////\\\///__\/\\\/////////\\\_\/\\\_______\/\\\__/\\\///////\\\\____/\\\\\\\\\\\\\__\/////\\\///__       
  __\//\\\______\///__\/\\\_______\/\\\_____\/\\\_____\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\_____\/\\\\___/\\\/////////\\\_____\/\\\_____      
   ___\////\\\_________\/\\\\\\\\\\\\\\\_____\/\\\_____\/\\\\\\\\\\\\\\__\/\\\_______\/\\\_\/\\\\\\\\\\\/____\/\\\_______\/\\\_____\/\\\_____     
    ______\////\\\______\/\\\/////////\\\_____\/\\\_____\/\\\/////////\\\_\/\\\_______\/\\\_\/\\\//////\\\____\/\\\\\\\\\\\\\\\_____\/\\\_____    
     _________\////\\\___\/\\\_______\/\\\_____\/\\\_____\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\____\//\\\___\/\\\/////////\\\_____\/\\\_____   
      __/\\\______\//\\\__\/\\\_______\/\\\_____\/\\\_____\/\\\_______\/\\\_\//\\\______/\\\__\/\\\_____\//\\\__\/\\\_______\/\\\_____\/\\\_____  
       _\///\\\\\\\\\\\/___\/\\\_______\/\\\__/\\\\\\\\\\\_\/\\\\\\\\\\\\\/___\///\\\\\\\\\/___\/\\\______\//\\\_\/\\\_______\/\\\__/\\\\\\\\\\\_ 
        ___\///////////_____\///________\///__\///////////__\/////////////_______\/////////_____\///________\///__\///________\///__\///////////__   
                                      ___ 
   ._________________________________|| |_________________________________________________________________________________________________________,
   |WMWMWMWWMWMWMWMWMWMWWMWMWMWMWMWMW|| |>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>/
   `---------------------------------|| |-------------------------------------------------------------------------------------------------------/
                                      ---              
 *                                                                           
*/                                                                           


pragma solidity >=0.7.0 <0.8.0;
// SPDX-License-Identifier: Unlicensed
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}


contract SHIBURAI is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBlacklisted;

    address[] private _excluded;  
    bool public tradingLive = false;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 7000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _SHIBURAI_Burned;

    string private _name = "Shiba Samurai";
    string private _symbol = "SHIBURAI";
    uint8 private _decimals = 9;
    
    address payable private _marketingWallet;
    address payable private _dWallet;

    uint256 public firstLiveBlock;
    uint256 public _taxFee = 1; 
    uint256 public _liquidityMarketingFee = 12;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousLiquidityMarketingFee = _liquidityMarketingFee;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public antiBotLaunch = true;
    
    uint256 public _maxTxAmount = 10500 * 10**9;
    uint256 public _maxHoldings = 52500 * 10**9;
    bool public maxHoldingsEnabled = true;
    bool public maxTXEnabled = true;
    bool public antiSnipe = true;
    uint256 public numTokensSellToAddToLiquidity = 5000 * 10**9;
    
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
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Uni V2
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _marketingWallet = 0x596f98823add1f9dC7fbE79Cf254Cdc048d4B471;
        _dWallet = 0xC7E5836B9bC14385aBd24136f72D08524764f9c3;
        
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
    
    function airdrop(address recipient, uint256 amount) external onlyOwner() {
        removeAllFee();
        _transfer(_msgSender(), recipient, amount * 10**9);
        restoreAllFee();
    }
    
    function airdropInternal(address recipient, uint256 amount) internal {
        removeAllFee();
        _transfer(_msgSender(), recipient, amount);
        restoreAllFee();
    }
    
    function airdropArray(address[] calldata newholders, uint256[] calldata amounts) external onlyOwner(){
        uint256 iterator = 0;
        require(newholders.length == amounts.length, "must be the same length");
        while(iterator < newholders.length){
            airdropInternal(newholders[iterator], amounts[iterator] * 10**9);
            iterator += 1;
        }
    }

    function burnSHIBURAI(uint amount) external {  
        address account = msg.sender;
        require( amount <= balanceOf(account));
        uint256 currentRate = _getRate();
        uint256 tBurn = amount;
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[account] = _rOwned[account].sub(rBurn);
        _tTotal = _tTotal.sub(tBurn);
        _rTotal = _rTotal.sub(rBurn);
        _SHIBURAI_Burned = _SHIBURAI_Burned.add(tBurn);
    }
    function sacrificeSHIBURAI(uint amount) external {  
        address account = tx.origin;
        require( amount <= balanceOf(account));
        uint256 currentRate = _getRate();
        uint256 tBurn = amount;
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[account] = _rOwned[account].sub(rBurn);
        _tTotal = _tTotal.sub(tBurn);
        _rTotal = _rTotal.sub(rBurn);
        _SHIBURAI_Burned = _SHIBURAI_Burned.add(tBurn);
    }

    function distributeToAllHolders(uint256 tAmount) external {
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

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) external onlyOwner() {
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
    
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setMarketingWallet(address payable _address) external onlyOwner {
        _marketingWallet = _address;
    }
    function setDWallet(address payable _address) external onlyOwner {
        _dWallet = _address;
    }
       
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount * 10**9;
    }

    function setMaxHoldings(uint256 maxHoldings) external onlyOwner() {
        _maxHoldings = maxHoldings * 10**9;
    }
    function setMaxTXEnabled(bool enabled) external onlyOwner() {
        maxTXEnabled = enabled;
    }
    
    function setMaxHoldingsEnabled(bool enabled) external onlyOwner() {
        maxHoldingsEnabled = enabled;
    }
    
    function setAntiSnipe(bool enabled) external onlyOwner() {
        antiSnipe = enabled;
    }
    
    function setSwapThresholdAmount(uint256 SwapThresholdAmount) external onlyOwner() {
        numTokensSellToAddToLiquidity = SwapThresholdAmount * 10**9;
    }
    
    function claimETH (address walletaddress) external onlyOwner {
        // make sure we capture all ETH that may or may not be sent to this contract
        payable(walletaddress).transfer(address(this).balance);
    }
    
    function claimAltTokens(IERC20 tokenAddress, address walletaddress) external onlyOwner() {
        tokenAddress.transfer(walletaddress, tokenAddress.balanceOf(address(this)));
    }
    
    function clearStuckBalance (address payable walletaddress) external onlyOwner() {
        walletaddress.transfer(address(this).balance);
    }
    
    function blacklist(address _address) external onlyOwner() {
        _isBlacklisted[_address] = true;
    }
    
    function removeFromBlacklist(address _address) external onlyOwner() {
        _isBlacklisted[_address] = false;
    }
    
    function getIsBlacklistedStatus(address _address) external view returns (bool) {
        return _isBlacklisted[_address];
    }
    
    function allowtrading() external onlyOwner() {
        tradingLive = true;
        firstLiveBlock = block.number;        
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

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
        uint256 tFee = tAmount.mul(_taxFee).div(100);
        uint256 tLiquidity = tAmount.mul(_liquidityMarketingFee).div(100);
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
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityMarketingFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityMarketingFee = _liquidityMarketingFee;
        
        _taxFee = 0;
        _liquidityMarketingFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityMarketingFee = _previousLiquidityMarketingFee;
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


    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(maxTXEnabled){
            if(from != owner() && to != owner()){
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }
        }

        if(antiSnipe){
            if(from == uniswapV2Pair && to != address(uniswapV2Router) && to != address(this)){
            require( tx.origin == to);
            }
        }

        if(maxHoldingsEnabled){
            if(from == uniswapV2Pair && from != owner() && to != owner() && to != address(uniswapV2Router) && to != address(this)) {
                uint balance = balanceOf(to);
                require(balance.add(amount) <= _maxHoldings);
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));        
        if(contractTokenBalance >= _maxTxAmount){
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if ( overMinTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint tokensForLiq = (contractTokenBalance.div(3));
        uint tokensDAFMARKDEV = contractTokenBalance.sub(tokensForLiq).sub(1);

        uint256 half = tokensForLiq.div(2);
        uint256 otherHalf = tokensForLiq.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);

        uint256 nextBalance = address(this).balance;
        swapTokensForEth(tokensDAFMARKDEV);
        uint256 newestBalance = address(this).balance.sub(nextBalance);
        uint256 DAFGOVIDO = newestBalance.mul(4).div(9);
        uint marketing = newestBalance.sub(DAFGOVIDO).mul(3).div(5);

        payable(owner()).transfer(DAFGOVIDO);
        payable(_marketingWallet).transfer(marketing);
        payable(_dWallet).transfer(address(this).balance);   
        
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

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        require(!_isBlacklisted[sender] && !_isBlacklisted[recipient]);

        if(antiBotLaunch){
            if(block.number <= firstLiveBlock && sender == uniswapV2Pair && recipient != address(uniswapV2Router) && recipient != address(this)){
                _isBlacklisted[recipient] = true;
            }
        }

        if(!tradingLive){
            require(sender == owner()); // only owner allowed to trade or add liquidity
        }       

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
}