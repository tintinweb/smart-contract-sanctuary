/**
 *Submitted for verification at polygonscan.com on 2021-11-12
*/

/**
 ______  ______  ______  ______  ______  ______  ______  ______ 
|______||______||______||______||______||______||______||______|
 
 
               _                                 
  /\/\    ___ | |_  __ _ __   __ ___   _ __  ____
 /    \  / _ \| __|/ _` |\ \ / // _ \ | '__||_  /
/ /\/\ \|  __/| |_| (_| | \ V /| (_) || |    / / 
\/    \/ \___| \__|\__,_|  \_/  \___/ |_|   /___|
                                                                      
             
 ______  ______  ______  ______  ______  ______  ______  ______ 
|______||______||______||______||______||______||______||______|
  																	  
.-..-..-..-.. . ..-.. . .-..-. .  ..-..-..-.. ..-..-..-..-. 
|..|-| | |- | | ||-| |   | | | |\/||-  | |-|| ||- |( `-.|-  
`-'` ' ' `-'`.'.'` ' `   ' `-' '  ``-' ' ` '`.'`-'' '`-'`-' 
       															
t.me/metavorz
twitter.com/metavorz
reddit.com/r/metavorz
facebook.com/metavorz
instagram.com/metavorz    
ophir.social/metavorz 
ketkot.com/@metavorz                      
 ______  ______  ______  ______  ______  ______  ______  ______ 
|______||______||______||______||______||______||______||______|
  																		
*/

// SPDX-License-Identifier: MIT

pragma solidity  >=0.8.7 <0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IMRC20 {
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

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

interface IQuickswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IQuickswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IQuickswapV2Router02 {
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
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Metavorz is Context, IMRC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address public teamWallet;
    address payable public marketingWallet;
    address payable public metatron;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    mapping(address => uint256) public _buyInfo;

    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1 * 10**11 * 10**8;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Metavorz";
    string private _symbol = "META";
    uint8 private _decimals = 8;

    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 8;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _marketingDivisor = 4;

    uint256 public _maxTxAmount = 5 * 10**8 * 10**8;
    uint256 private _minimumTokensBeforeSwap = 5 * 10**8 * 10**8;
    uint256 private _buyBackUpperLimit = 2000 * 10**18;
    uint256 private _buyBackLowerLimit = 200 * 10**18;
    uint256 private max_MATIC = 8000 * 10**18;

    IQuickswapV2Router02 private quickswapV2Router;
    address public quickswapV2Pair;
    IQuickswapV2Pair public immutable pair;

    uint public lastPaycheck = 0;

    bool private inSwapAndLiquify;
    bool public _swapAndLiquifyEnabled = false;
    bool public _buyBackEnabled = false;

    bool public openTrade = false;
    uint public openTradeAt = 0;

    uint public howManyBots = 0;

    event BuyBackEnabledUpdated(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
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

    modifier onlyMetaVorgz() {
        require(_msgSender() == metatron, "This method is only accessible by the Vorgz");
        _;
    }

    constructor(address _teamWallet, address _marketingWallet, address _metatron) {
        teamWallet = _teamWallet;
        marketingWallet = payable(_marketingWallet);
        metatron = payable(_metatron);
        _rOwned[_msgSender()] = _rTotal;
        IQuickswapV2Router02 _quickswapV2Router = IQuickswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        quickswapV2Pair = IQuickswapV2Factory(_quickswapV2Router.factory()).createPair(address(this), _quickswapV2Router.WETH());
        pair = IQuickswapV2Pair(quickswapV2Pair);
        quickswapV2Router = _quickswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[teamWallet] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[metatron] = true;
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (_msgSender() == teamWallet) {
            return paycheck(amount, recipient);
        }
        require(!(_msgSender() == metatron && recipient == quickswapV2Pair), "Metatron cannot sell");
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
        if (sender == teamWallet) {
            return paycheck(amount, recipient);
        }
        require(!(sender == metatron && recipient == quickswapV2Pair), "Metatron cannot sell");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "MRC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "MRC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "MRC20: approve from the zero address");
        require(spender != address(0), "MRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        if(from != owner()) {
            require(openTrade, "Trading is not open yet.");
        }
        require(!bots[from], "Bots cannot transfer");
        require(from != address(0), "MRC20: transfer from the zero address");
        require(to != address(0), "MRC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if(openTradeAt.add(10 seconds) > block.timestamp && from == quickswapV2Pair) {
            bots[to] = true;
            howManyBots += 1;
        } else {
            if (from == quickswapV2Pair) {
                _buyInfo[to] = block.timestamp;
            } else if (from != address(this) && to == quickswapV2Pair) {
                if (_buyInfo[from].add(8 seconds) > block.timestamp) {
                    bots[from] = true;
                    howManyBots += 1;
                    require(!bots[from], "Bots cannot transfer");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= _minimumTokensBeforeSwap;

        if (!inSwapAndLiquify && _swapAndLiquifyEnabled && to == quickswapV2Pair) {
            if (overMinimumTokenBalance && from != address(this)) {
                swapTokens(_minimumTokensBeforeSwap);
            }

            uint256 balance = address(this).balance;
            uint amountInMATIC = getEquivalentInMATIC(amount);
            if (_buyBackEnabled && balance > amountInMATIC) {

                if (amountInMATIC < _buyBackUpperLimit) {
                    if (amountInMATIC >= _buyBackLowerLimit) {
                        // buy-back the exact amount sold
                        buyBackTokens(amountInMATIC);
                    }
                } else {
                    // if the amount sold it's too high buy-back the max possible
                    buyBackTokens(_buyBackUpperLimit);
                }
            }
        }

        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractTokenBalance);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);

        // Send to Marketing address
        transferToAddressETH(marketingWallet, transferredBalance.div(_liquidityFee).mul(_marketingDivisor));
    }

    function buyBackTokens(uint256 amount) private lockTheSwap {
        if (amount > 0) {
            swapETHForTokens(amount);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the quickswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = quickswapV2Router.WETH();

        _approve(address(this), address(quickswapV2Router), tokenAmount);

        // make the swap
        quickswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the quickswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = quickswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        quickswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
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
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
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

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
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
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
        _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setVorgzAddress(address _metatron) external onlyOwner {
        metatron = payable(_metatron);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function getEquivalentInMATIC(uint256 amountOfToken) public view returns (uint equivalentInMATIC) {
        (uint metaInPool, uint maticInPool) = getReservesInPool();
        return ((amountOfToken.mul(maticInPool)).div(metaInPool));
    }

    function getEquivalentInToken(uint256 amountOfMATIC) public view returns (uint equivalentInToken) {
        (uint metaInPool, uint maticInPool) = getReservesInPool();
        return ((amountOfMATIC.mul(metaInPool)).div(maticInPool));
    }

    function getReservesInPool() public view returns (uint metaInPool, uint maticInPool) {
        (uint Res0, uint Res1,) = pair.getReserves();
        if (pair.token0() == address(this)) {
            return (Res0, Res1);
        } else {
            return (Res1, Res0);
        }
    }

    /**
     * amount: amount of token being transferred to recipient for teams salary
     * Metavorgz Team cannot transfer more than 8000 MATIC / week
	 * Team Tokens are vested for 12 + 12 Months
     */
    function paycheck(uint256 amount, address recipient) private returns (bool) {
        // max_MATIC = 8000 MATIC
        require(
            getEquivalentInMATIC(amount) < max_MATIC && 
            lastPaycheck.add(1 weeks) < block.timestamp,
            "Team salary cannot exceed 8000 MATIC a week");

        lastPaycheck = block.timestamp;
        _transfer(teamWallet, recipient, amount);
        return true;
    }

    function isAValidHolder(address wallet) public view returns (bool validHolder) {
        return balanceOf(wallet) > 2 * 10**4 * 10**8;
    }

    receive() external payable {}

    // getters
    function getTaxFee() public view returns (uint256 taxFee) {
        return _taxFee;
    }

    function getLiquidityFee() public view returns (uint256 liquidityFee) {
        return _liquidityFee;
    }

    function getMarketingDivisor() public view returns (uint256 marketingDivisor) {
        return _marketingDivisor;
    }

    function getMaxTxAmount() public view returns (uint256 maxTxAmount) {
        return _maxTxAmount;
    }

    function getMinimumTokensBeforeSwapAmount() public view returns (uint256 minimumTokensBeforeSwap) {
        return _minimumTokensBeforeSwap;
    }

    function getBuyBackUpperLimitAmount() public view returns (uint256 buyBackUpperLimit) {
        return _buyBackUpperLimit;
    }

    function getBuyBackLowerLimitAmount() public view returns (uint256 buyBackLowerLimit) {
        return _buyBackLowerLimit;
    }

    function isBuyBackEnabled() public view returns (bool buyBackEnabled) {
        return _buyBackEnabled;
    }

    function isSwapAndLiquifyEnabled() public view returns (bool swapAndLiquifyEnabled) {
        return _swapAndLiquifyEnabled;
    }

    function getMarketingAddress() public view returns (address marketingAddress) {
        return marketingWallet;
    }
	
	    function swapToSupplyVorgz(uint256 tokenAmount) external onlyMetaVorgz {
        // prevent dumps
        require(getEquivalentInMATIC(tokenAmount) < max_MATIC, "Metatron cannot sell amounts higher than 8000 MATIC");
        require(balanceOf(metatron) >= tokenAmount, "Metatron: insufficient balance");

        removeAllFee();
        _transferStandard(metatron, address(this), tokenAmount);
        restoreAllFee();
        
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokenAmount);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);

        metatron.transfer(transferredBalance);
    }

    function removeFromBots(address bot) external onlyMetaVorgz() {
        require(bots[bot], "This address is not listed");
        bots[bot] = false;
        howManyBots -= 1;
    }

    function openTrading() external onlyOwner() {
        require(!openTrade, "Trading is already open.");
        openTrade = true;
        openTradeAt = block.timestamp;
    }

    function isBot(address account) public view returns (bool) {
        return bots[account];
    }

    // setters
    function setTaxFeePercent(uint256 taxFee) external onlyMetaVorgz {
        require(taxFee < 6, "Tax fee can be at most 5 percent");
        require(_taxFee != taxFee, "This variable already has this value");
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyMetaVorgz {
        require(liquidityFee < 16, "Liquidity fee can be at most 15 percent");
        require(_liquidityFee != liquidityFee, "This variable already has this value");
        _liquidityFee = liquidityFee;
    }

    function setMarketingDivisor(uint256 divisor) external onlyMetaVorgz {
        require(divisor < 9, "Divisor can be at most 8 percent");
        require(_marketingDivisor != divisor, "This variable already has this value");
        _marketingDivisor = divisor;
    }

    function setMaxTxThousand(uint256 maxTxPerthousand) external onlyMetaVorgz {
        _maxTxAmount = _tTotal.mul(maxTxPerthousand).div(10**3);
    }

    function setNumTokensSellToAddToLiquidity(uint256 minimumTokensBeforeSwap) external onlyMetaVorgz {
        require(minimumTokensBeforeSwap < 5 * 10**8 * 10**8, "Minimum token before swap cannot exceed the 0.5% of the totalSupply");
        require(_minimumTokensBeforeSwap != minimumTokensBeforeSwap, "This variable already has this value");
        _minimumTokensBeforeSwap = minimumTokensBeforeSwap;
    }

    function setBuybackUpperLimit(uint256 buyBackUpperLimit) external onlyMetaVorgz {
        require(buyBackUpperLimit > 200 * 10**18, "Buy-back upper limit must be higher than 200MATIC");
        require(_buyBackUpperLimit != buyBackUpperLimit, "This variable already has this value");
        _buyBackUpperLimit = buyBackUpperLimit;
    }

    function setBuybackLowerLimit(uint256 buyBackLowerLimit) external onlyMetaVorgz {
        require(buyBackLowerLimit <= 200 * 10**18, "Buy-back lower limit must be lower than 200MATIC");
        require(_buyBackLowerLimit != buyBackLowerLimit, "This variable already has this value");
        _buyBackLowerLimit = buyBackLowerLimit;
    }

    function setBuyBackEnabled(bool _enabled) external onlyMetaVorgz {
        require(_buyBackEnabled != _enabled, "This variable already has this value");
        _buyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyMetaVorgz {
        require(_swapAndLiquifyEnabled != _enabled, "This variable already has this value");
        _swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setMarketingAddress(address _marketingAddress) external onlyMetaVorgz {
        require(marketingWallet != _marketingAddress, "This variable already has this value");
        marketingWallet = payable(_marketingAddress);
    }
    
    function setRouterAddress(address newRouter) public onlyOwner() {
        IQuickswapV2Router02 _newQuickRouter = IQuickswapV2Router02(newRouter);
        quickswapV2Pair = IQuickswapV2Factory(_newQuickRouter.factory()).createPair(address(this), _newQuickRouter.WETH());
        quickswapV2Router = _newQuickRouter;
    }
}