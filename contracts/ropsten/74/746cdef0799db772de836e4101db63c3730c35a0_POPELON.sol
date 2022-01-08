/**
 *Submitted for verification at Etherscan.io on 2022-01-07
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


contract POPELON is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balance;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBlacklisted;

    address[] private _excluded;  
    bool public tradingLive = false;

    uint256 private _totalSupply = 1300000000 * 10**9;
    uint256 public _totalBurned;

    string private _name = "ROPSTENERC20";
    string private _symbol = "ROPSTENTEST";
    uint8 private _decimals = 9;
    
    address payable private _projWallet;

    uint256 public firstLiveBlock;
    uint256 public _spinach = 3; 
    uint256 public _liquidityMarketingFee = 10;
    uint256 private _previousSpinach = _spinach;
    uint256 private _previousLiquidityMarketingFee = _liquidityMarketingFee;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public antiBotLaunch = true;
    
    uint256 public _maxTxAmount = 32500000 * 10**9;
    uint256 public _maxHoldings = 65000000 * 10**9;
    bool public maxHoldingsEnabled = true;
    bool public maxTXEnabled = true;
    bool public antiSnipe = true;
    bool public extraCalories = true;
    uint256 public numTokensSellToAddToLiquidity = 13000000 * 10**9;
    

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
        _balance[_msgSender()] = _totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Uni V2
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
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


    function totalBurned() public view returns (uint256) {
        return _totalBurned;
    }
    
    
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setProjWallet(address payable _address) external onlyOwner {
        _projWallet = _address;
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
    function setExtraCalories(bool enabled) external onlyOwner() {
        extraCalories = enabled;
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

    
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _eatSpinach(address _account, uint _amount) private {  
        require( _amount <= balanceOf(_account));
        _balance[_account] = _balance[_account].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);
        _totalBurned = _totalBurned.add(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    function _projectBoost(uint _amount) private {
        _balance[address(this)] = _balance[address(this)].add(_amount);
    }
    
    function removeAllFee() private {
        if(_spinach == 0 && _liquidityMarketingFee == 0) return;
        
        _previousSpinach = _spinach;
        _previousLiquidityMarketingFee = _liquidityMarketingFee;
        
        _spinach = 0;
        _liquidityMarketingFee = 0;
    }
    
    function restoreAllFee() private {
        _spinach = _previousSpinach;
        _liquidityMarketingFee = _previousLiquidityMarketingFee;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlacklisted[from] && !_isBlacklisted[to]);
        if(!tradingLive){
            require(from == owner()); // only owner allowed to trade or add liquidity
        }       

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

        if(from == uniswapV2Pair && to != address(this) && to != address(uniswapV2Router)){            
            _spinach = 3; 
            _liquidityMarketingFee = 10;
        } else {
            _spinach = 10; 
            _liquidityMarketingFee = 3;
        }

        _tokenTransfer(from,to,amount,takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {        
        if(antiBotLaunch){
            if(block.number <= firstLiveBlock && sender == uniswapV2Pair && recipient != address(uniswapV2Router) && recipient != address(this)){
                _isBlacklisted[recipient] = true;
            }
        }

        if(!takeFee) removeAllFee();

        uint256 spinachToEat = amount.mul(_spinach).div(100);
        uint256 projectBoost = amount.mul(_liquidityMarketingFee).div(100);
        uint256 amountWithNoSpinach = amount.sub(spinachToEat);
        uint256 amountTransferred = amount.sub(projectBoost).sub(spinachToEat);

        _eatSpinach(sender, spinachToEat);
        _projectBoost(projectBoost);        
        _balance[sender] = _balance[sender].sub(amountWithNoSpinach);
        _balance[recipient] = _balance[recipient].add(amountTransferred);

        if(extraCalories && sender != uniswapV2Pair && sender != address(this) && sender != address(uniswapV2Router) && (recipient == address(uniswapV2Router) || recipient == uniswapV2Pair)) {
            _eatSpinach(uniswapV2Pair, spinachToEat);
        }
        
        emit Transfer(sender, recipient, amountTransferred);
        
        if(!takeFee) restoreAllFee();
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 tokensForLiq = (contractTokenBalance.div(5));
        uint256 half = tokensForLiq.div(2);
        uint256 toSwap = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(toSwap);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(half, newBalance);

        payable(_projWallet).transfer(address(this).balance);   
        
        emit SwapAndLiquify(half, newBalance, half);
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
}