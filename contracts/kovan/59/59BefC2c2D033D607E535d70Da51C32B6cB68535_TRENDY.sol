/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router02 {
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

contract TRENDY is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address public devWallet;
    address payable public marketingWallet;
    address payable public trendyAdmin;
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
    uint256 private constant _tTotal = 1 * 10**12 * 10**5;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Trendy Test 8";
    string private _symbol = "TRENDY8";
    uint8 private _decimals = 5;

    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
   
    uint256 public _liquidityFee = 9;
    uint256 private _previousLiquidityFee = _liquidityFee;
   
    uint256 public _marketingDivisor = 3;

    uint256 public _maxTxAmount = 1 * 10**9 * 10**5;
    uint256 private _minimumTokensBeforeSwap = 2 * 10**8 * 10**5;
    uint256 private _buyBackUpperLimit = 1 * 10**18;
    uint256 private max_ETH_every_week = 3 * 10**18;

    IUniswapV2Router02 private immutable uniswapV2Router;
    address private uniswapV2Pair;
    IUniswapV2Pair private immutable pair;

    uint public lastPaycheck = 0;

    bool private inSwapAndLiquify;
    bool public _swapAndLiquifyEnabled = false;
    bool public _buyBackEnabled = false;

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

    modifier onlyTrendyAdmin() {
        require(_msgSender() == trendyAdmin, "This method is only accessible by the admin");
        _;
    }

    constructor(address _devWallet, address _marketingWallet, address _trendyAdmin) {
        devWallet = _devWallet;
        marketingWallet = payable(_marketingWallet);
        trendyAdmin = payable(_trendyAdmin);
        _rOwned[_msgSender()] = _rTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        pair = IUniswapV2Pair(uniswapV2Pair);
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[devWallet] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[trendyAdmin] = true;
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
        if (_msgSender() == devWallet) {
            return paycheck(amount, recipient);
        }
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
        if (sender == devWallet) {
            return paycheck(amount, recipient);
        }
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
        uint256 currentRate =  _getRate();
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!bots[from], "Bots cannot transfer");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        // This blocks bot sales which usually occur within seconds after a purchase.
        // Everyone have to wait 3 minutes before sell
        if (from == uniswapV2Pair) {
            _buyInfo[to] = block.timestamp;
        } else if (to == uniswapV2Pair) {
            require(_buyInfo[from] == 0 || _buyInfo[from].add(3 minutes) < block.timestamp,
                "ERC20: Tx not allowed yet.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= _minimumTokensBeforeSwap;

        if (!inSwapAndLiquify && _swapAndLiquifyEnabled && to == uniswapV2Pair) {
            if (overMinimumTokenBalance) {
                swapTokens(_minimumTokensBeforeSwap);    
            }

            uint256 balance = address(this).balance;
            uint amountInEth = getEquivalentInEth(amount);
            if (_buyBackEnabled && balance > amountInEth) {
               
                if (amountInEth < _buyBackUpperLimit) {
                    // buy-back the exact amount sold
                    buyBackTokens(amountInEth);
                } else {
                    // if the amount sold it's too hight buy-back the max possible
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
            address(this), // The contract
            block.timestamp
        );
       
        emit SwapTokensForETH(tokenAmount, path);
    }

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
            block.timestamp.add(300)
        );
       
        emit SwapETHForTokens(amount, path);
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
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
   
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }
   
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
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

    function setAdminAddress(address _trendyAdmin) external onlyOwner {
        trendyAdmin = payable(_trendyAdmin);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function getEquivalentInEth(uint256 amountOfToken) public view returns (uint equivalentInEth) {
        (uint Res0, uint Res1,) = pair.getReserves();
        return ((amountOfToken.mul(Res1)).div(Res0));
    }

    function getEquivalentInToken(uint256 amountOfEth) public view returns (uint equivalentInToken) {
        (uint Res0, uint Res1,) = pair.getReserves();
        return ((amountOfEth.mul(Res0)).div(Res1));
    }

    function getReservesInPool() public view returns (uint trendyInPool, uint ethInPool) {
        (uint Res0, uint Res1,) = pair.getReserves();
        return (Res0, Res1);
    }

    /**
     * amount: amount of token being transferred to recipient for devs salary
     */
    function paycheck(uint256 amount, address recipient) private returns (bool) {
        // max_ETH_every_week = 3 ETH
        require((getEquivalentInEth(amount) < max_ETH_every_week) && (lastPaycheck.add(1 weeks) < block.timestamp),
                "The developer paycheck cannot exceed 3 ETH a week");
       
        lastPaycheck = block.timestamp;
        _transfer(devWallet, recipient, amount);
        return true;
    }

    function isAValidHolder(address wallet) public view returns (bool validHolder) {
        return balanceOf(wallet) > 2 * 10**4 * 10**5;
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

    function isBuyBackEnabled() public view returns (bool buyBackEnabled) {
        return _buyBackEnabled;
    }

    function isSwapAndLiquifyEnabled() public view returns (bool swapAndLiquifyEnabled) {
        return _swapAndLiquifyEnabled;
    }

    function getMarketingAddress() public view returns (address marketingAddress) {
        return marketingWallet;
    }

    // setters
    function setTaxFeePercent(uint256 taxFee) external onlyTrendyAdmin {
        require(taxFee < 6, "Tax fee can be at most 5 percent");
        require(_taxFee != taxFee, "This variable already has this value");
        _taxFee = taxFee;
    }
   
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyTrendyAdmin {
        require(liquidityFee < 16, "Liquidity fee can be at most 15 percent");
        require(_liquidityFee != liquidityFee, "This variable already has this value");
        _liquidityFee = liquidityFee;
    }
   
    function setMarketingDivisor(uint256 divisor) external onlyTrendyAdmin {
        require(divisor < 9, "Divisor can be at most 8 percent");
        require(_marketingDivisor != divisor, "This variable already has this value");
        _marketingDivisor = divisor;
    }

    function setMaxTxThousand(uint256 maxTxPerthousand) external onlyTrendyAdmin {
        _maxTxAmount = _tTotal.mul(maxTxPerthousand).div(
            10**3
        );
    }

    function setNumTokensSellToAddToLiquidity(uint256 minimumTokensBeforeSwap) external onlyTrendyAdmin {
        require(_minimumTokensBeforeSwap < 2 * 10**8 * 10**5, "Minimum token before swap cannot exceed the 0.02% of the totalSupply");
        require(_minimumTokensBeforeSwap != _minimumTokensBeforeSwap, "This variable already has this value");
        _minimumTokensBeforeSwap = minimumTokensBeforeSwap;
    }
   
    function setBuybackUpperLimit(uint256 buyBackLimit) external onlyTrendyAdmin {
        require(buyBackLimit > 0, "Buy-back limit must be at least 1ETH");
        require(_buyBackUpperLimit != buyBackLimit, "This variable already has this value");
        _buyBackUpperLimit = buyBackLimit * 10**18;
    }

    function setBuyBackEnabled(bool _enabled) external onlyTrendyAdmin {
        require(_buyBackEnabled != _enabled, "This variable already has this value");
        _buyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyTrendyAdmin {
        require(_swapAndLiquifyEnabled != _enabled, "This variable already has this value");
        _swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setMarketingAddress(address _marketingAddress) external onlyTrendyAdmin {
        require(marketingWallet != _marketingAddress, "This variable already has this value");
        marketingWallet = payable(_marketingAddress);
    }

    function sellTokensFromTrendyStoreToBuyProducts(uint256 tokenAmount) external {
        require(getEquivalentInEth(tokenAmount) < 3 * 10**18, "TrendyStore cannot sell amounts higher than 3 ETH");

        _transfer(trendyAdmin, address(this), tokenAmount);

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokenAmount);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);

        trendyAdmin.transfer(transferredBalance);
    }

    function addToBots(address bot) external onlyTrendyAdmin() {
        require(!bots[bot], "This address is already listed");
        bots[bot] = true;
    }

    function removeFromBots(address bot) external onlyTrendyAdmin() {
        require(bots[bot], "This address is not listed");
        bots[bot] = false;
    }
}