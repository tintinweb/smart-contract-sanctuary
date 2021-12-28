/**
 *Submitted for verification at polygonscan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT
/**
    #HAMPERBLOCK#
    Total Fees by default: 2%
    1% is reflected to holders
    1% is added to LP
*/
pragma solidity ^0.8.2;
interface IQuickSwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IQuickSwapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
}
interface IPinkAntiBot {
    function setTokenOwner(address owner) external;
    function onPreTransferCheck(address from, address to, uint256 amount) external;
}
interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}
contract HamperBlock {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);
    event SwapAndSend(uint256 tokensSwapped,uint256 ethReceived,uint256 tokens);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256)  private _tLocked;
    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private permitedAddress;
    address[] private _excluded;
    address private _devsAddress;
    address private _marketingAddress;
    address private _airdropsAddress;
    address private _SDGAddress;
    address private _rewardPoolAddress;
    IPinkAntiBot public pinkAntiBot;
    bool public pausedPinkAntiBot=false;
    IQuickSwapRouter public quickSwapRouter;
    uint public reflectionFee=1;
    uint private _prevReflectionFee;
    uint public liquidityFee=1;
    uint private _prevLiquidityFee;
    address public quickSwapPair;
    address public owner;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply = 100000000  * 10**decimals();
    uint256 private _rTotal = (MAX - (MAX % _totalSupply));
    uint256 private _tFeeTotal;
    string private _name = "HamperBlock";
    string private _symbol = "HBlock";
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    uint256 public _maxTxAmount = 200000 * 10**decimals(); //0.2% of TS
    uint256 public numTokensSellToAddToLiquidity = 2000 * 10**decimals(); //0.002% of TS
    modifier onlyOwner() {
        require(msg.sender == owner,"Not owner");
        _;
    }
    modifier whenPermited() {
        require(permitedAddress[msg.sender],"Not permited");
        _;
    }
    constructor(){
        owner=msg.sender;
        emit OwnershipTransferred(address(0), owner);
        _devsAddress=0x6ce19c0edcD9E67d21110e2AEb2FAcAaEf17B103;
        _marketingAddress=0x363F1E4A5f8331f3068d670F586ffE85d6076e91;
        _airdropsAddress=0xDa94E8C5fd3c569249c25348effF5b78E9838b3A;
        _SDGAddress=0xF01E5a78Df02E03b257772C7AD91A8152939F42C;
        _rewardPoolAddress=0x69225280E6750D178d7B6804f8B12819E72BC22f;
        //Implement Pink Anti-bot
        pinkAntiBot = IPinkAntiBot(0x56a79881b65B03F27b088B753B6c128485642FC3); //MATIC-MAINNET
        pinkAntiBot.setTokenOwner(owner);
        quickSwapRouter = IQuickSwapRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff); //MATIC-MAINNET
        // Create a uniswap pair for this new token
        quickSwapPair = IQuickSwapFactory(quickSwapRouter.factory()).createPair(address(this), quickSwapRouter.WETH());
        permitedAddress[owner]=true;
        _isExcludedFromFee[owner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromMaxTx[owner] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[address(0x000000000000000000000000000000000000dEaD)] = true;
        _isExcludedFromMaxTx[address(0)] = true;
        _rOwned[address(this)] =_rTotal;
        emit Transfer(address(0), address(this), _totalSupply);
        _tokenTransfer(address(this),_devsAddress,_totalSupply*3/100,false); //3% to devs
        _tokenTransfer(address(this),_marketingAddress,_totalSupply*7/100,false); //7% to marketing
        _tokenTransfer(address(this),_airdropsAddress,_totalSupply*4/100,false); //4% to airdrops
        _tokenTransfer(address(this),_SDGAddress,_totalSupply*1/100,false); //1% to SDG
        _tokenTransfer(address(this),_rewardPoolAddress,_totalSupply*15/100,false); //15% to reward pool
    }
    function setPausedPinkAntiBot(bool paused) public {
        pausedPinkAntiBot=paused;
    }
    function lockTimeOfWallet(address account) public view returns (uint256) {
        return _tLocked[account];
    }
    function devsAddress() public view returns (address) {
        return _devsAddress;
    }
    function marketingAddress() public view returns (address) {
        return _marketingAddress;
    }
    function airdropsAddress() public view returns (address) {
        return _airdropsAddress;
    }
    function rewardPoolAddress() public view returns (address) {
        return _rewardPoolAddress;
    }
    function SDGAddress() public view returns (address) {
        return _SDGAddress;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function decimals() public pure returns (uint8) {
        return 18;
    }
    function balanceOf(address account) public view returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(block.timestamp > _tLocked[msg.sender] , "Wallet is still locked");
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address sender, address spender) public view returns (uint256) {
        return _allowances[sender][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender,address recipient,uint256 amount) public returns (bool) {
        require(block.timestamp > _tLocked[sender] , "Wallet is still locked");
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(address sender,address recipient,uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        if(!pausedPinkAntiBot){
            pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
        }
        if (_isExcludedFromMaxTx[sender] == false && _isExcludedFromMaxTx[recipient] == false) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        if (_maxTxAmount >= numTokensSellToAddToLiquidity && balanceOf(address(this)) >= numTokensSellToAddToLiquidity && !inSwapAndLiquify && sender != quickSwapPair && swapAndLiquifyEnabled) {
            swapAndLiquify(numTokensSellToAddToLiquidity);
        }
        bool takeFee = true;
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            takeFee = false;
        }
        _tokenTransfer(sender,recipient,amount,takeFee);
    }
    function _approve(address sender,address spender,uint256 amount) internal {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        return rAmount/_getRate();
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) internal {
        if(!takeFee){
            _prevLiquidityFee = liquidityFee;
            _prevReflectionFee = reflectionFee;
            liquidityFee = 0; reflectionFee = 0;
        }
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(amount);
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        if (_isExcluded[sender]) {_tOwned[sender] -= amount;}
        if (_isExcluded[recipient]) {_tOwned[recipient] += tTransferAmount;}
        _takeLiquidity(tLiquidity);
        _rTotal -= rFee;
        _tFeeTotal += tFee;
        emit Transfer(sender, recipient, tTransferAmount);
        if(!takeFee){
            liquidityFee = _prevLiquidityFee;
            reflectionFee = _prevReflectionFee;
        }
    }
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity*currentRate;
        _rOwned[address(this)] += rLiquidity;
        if(_isExcluded[address(this)]){
            _tOwned[address(this)] += tLiquidity;
        }
    }
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 currentRate=_getRate();
        uint256 tFee = tAmount*reflectionFee/100;
        uint256 tLiquidity = tAmount*liquidityFee/100;
        uint256 tTransferAmount = tAmount-tFee-tLiquidity;
        uint256 rAmount = tAmount*currentRate;
        uint256 rFee = tFee*currentRate;
        uint256 rLiquidity = tLiquidity*currentRate;
        uint256 rTransferAmount = rAmount-rFee-rLiquidity;
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }
    function _getRate() private view returns (uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _totalSupply;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return _rTotal/_totalSupply;
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_totalSupply) return _rTotal/_totalSupply;
        return rSupply/tSupply;
    }
    function duringPresale() external onlyOwner {
        _maxTxAmount = _totalSupply;
        _prevLiquidityFee = liquidityFee;
        _prevReflectionFee = reflectionFee;
        liquidityFee = 0; reflectionFee = 0;
        swapAndLiquifyEnabled = false;
    }
    function afterPresale() external onlyOwner {
        _maxTxAmount = 200000 * 10**decimals();
        liquidityFee = _prevLiquidityFee;
        reflectionFee = _prevReflectionFee;
    }
    function setMaxTx(uint256 maxTx) external onlyOwner {
        _maxTxAmount = maxTx * 10 ** decimals();
    }
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function lockWallet(uint256 time) public  {
        _tLocked[msg.sender] = block.timestamp + time;
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _totalSupply, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
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
    function excludeOrIncludeFromFee(address account, bool exclude) public onlyOwner {
        _isExcludedFromFee[account] = exclude;
    }
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function isExcludedFromMaxTx(address account) public view returns(bool) {
        return _isExcludedFromMaxTx[account];
    }
    function excludeOrIncludeFromMaxTx(address account, bool exclude) public onlyOwner {
        _isExcludedFromMaxTx[account] = exclude;
    }
    function setMinTokensToSwap(uint256 _minTokens) external onlyOwner() {
        numTokensSellToAddToLiquidity = _minTokens * 10 ** decimals();
    }
    function setTaxFeePercent(uint256 fee) external onlyOwner {
        if(fee <= 100) {
	        reflectionFee = fee/100;
	    }  
    }
    function setLiquidityFeePercent(uint256 fee) external onlyOwner {
        if(fee <= 100) {
	        liquidityFee = fee/100;
	    }  
    }
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    receive() external payable {}
    function swapAndLiquify(uint256 amount) private {
        if(!inSwapAndLiquify){
            inSwapAndLiquify=true;
            uint256 half = amount/2;
            uint256 otherHalf = amount-half;
            uint256 initialBalance = address(this).balance;
            swapTokensForMatic(half);
            uint256 ethToAdd = address(this).balance-initialBalance;
            addLiquidity(otherHalf, ethToAdd);
            emit SwapAndLiquify(half, ethToAdd, otherHalf);
            inSwapAndLiquify=false;
        }
    }
    function swapTokensForMatic(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = quickSwapRouter.WETH();
        _approve(address(this), address(quickSwapRouter), tokenAmount);
        quickSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of Matic
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(quickSwapRouter), tokenAmount);
        quickSwapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
    function setPermitedAddress(address ad, bool permited) public onlyOwner {
        permitedAddress[ad]=permited;
    }
    function isPermitedAddress(address ad) public view returns(bool){
        return permitedAddress[ad];
    }
    function setNewOwner(address newOwner) public onlyOwner {
        permitedAddress[owner] = false;
        _isExcludedFromFee[owner] = false;
        _isExcludedFromMaxTx[owner] = false;
        pinkAntiBot.setTokenOwner(newOwner);
        permitedAddress[newOwner] = true;
        _isExcludedFromFee[newOwner] = true;
        _isExcludedFromMaxTx[newOwner] = true;
        owner=newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
    function transferIfPermited(address sender,address receiver,uint256 amount) public whenPermited {
        require(block.timestamp > _tLocked[sender] , "Wallet is still locked");
        _tokenTransfer(sender,receiver,amount,false);
    }
    function withdrawToken(address _tokenContract, uint256 _amount) public onlyOwner {
        require(block.timestamp > _tLocked[msg.sender] , "Wallet is still locked");
        IERC20(_tokenContract).transfer(msg.sender, _amount);
    }
}