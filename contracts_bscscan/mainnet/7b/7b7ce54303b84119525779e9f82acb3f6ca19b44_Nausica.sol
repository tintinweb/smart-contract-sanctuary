/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Ownable is Context {address private _owner; address private _previousOwner; event OwnershipTransferred (address indexed previousOwner, address indexed newOwner);

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

library SafeMatha6 {
    function a6Add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMatha6: addition overflow");
        return c;
    }

    function a6Sub(uint a, uint b) internal pure returns (uint) {
        return a6Sub(a, b, "SafeMatha6: subtraction overflow");
    }

    function a6Sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;
        return c;
    }

    function a6Mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMatha6: multiplication overflow");
        return c;
    }

    function a6Div(uint a, uint b) internal pure returns (uint) {
        return a6Div(a, b, "SafeMatha6: division by zero");
    }

    function a6Div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Nausica is Context, IERC20, Ownable {
    
    using SafeMatha6 for uint;

    string private constant _namea6 = "SUPER MUSK";
    string private constant _symbola6 = "SMUSK";
    uint8 private constant _decimalsa6 = 9;

    mapping(address => uint) private _rOwned;
    mapping(address => uint) private _tOwned;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint private constant MAX = ~uint(0);
    uint private constant _tTotala6 = 10000000000000 * 10**9;
    uint private _rTotala6 = (MAX - (MAX % _tTotala6));
    uint private _tFeeTotal;
    
    //Buy Fee
    uint private _redisFeeOnBuy = 2;
    uint private _taxFeeOnBuy = 2;
    
    //Sell Fee
    uint private _redisFeeOnSell = 2;
    uint private _taxFeeOnSell = 2;
    
    //Original Fee
    uint private _redisFee = _redisFeeOnSell;
    uint private _taxFee = _taxFeeOnSell;
    
    uint private _previousredisFee = _redisFee;
    uint private _previoustaxFee = _taxFee;
    
    mapping (address => bool) public preTrader;
    mapping(address => uint) private cooldown;
    
    address payable private _marketingAddress = payable(0x5Bd9b314973BfB7e801444C60d491abad3108EaB);
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    
    bool private inSwap = false;
    bool private swapEnabled = true;
    
    uint public _maxTxAmount = 100000000000000 * 10**9;
    uint public _maxWalletSize = 100000000000000 * 10**9;
    uint public _swapTokensAtAmount = 1000000000000 * 10**9;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        
        _rOwned[_msgSender()] = _rTotala6;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        
        preTrader[owner()] = true;

        emit Transfer(address(0), _msgSender(), _tTotala6);
    }

    function name() public pure returns (string memory) {
        return _namea6;
    }

    function symbol() public pure returns (string memory) {
        return _symbola6;
    }

    function decimals() public pure returns (uint8) {
        return _decimalsa6;
    }

    function totalSupply() public pure override returns (uint) {
        return _tTotala6;
    }

    function balanceOf(address account) public view override returns (uint) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].a6Sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tokenFromReflection(uint rAmount) private view returns (uint) {
        require(
            rAmount <= _rTotala6,
            "Amount must be less than total reflections"
        );
        uint currentRate = _getRate();
        return rAmount.a6Div(currentRate);
    }

    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;
    
        _previousredisFee = _redisFee;
        _previoustaxFee = _taxFee;
        
        _redisFee = 0;
        _taxFee = 0;
    }

    function restoreAllFee() private {
        _redisFee = _previousredisFee;
        _taxFee = _previoustaxFee;
    }

    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            
            //Trade start check
           
              
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            
            
            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }
            
            uint contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

            if(contractTokenBalance >= _maxTxAmount)
            {
                contractTokenBalance = _maxTxAmount;
            }
            
            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled) {
                swapTokensForEth(contractTokenBalance);
                uint contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        
        bool takeFee = true;

        //Transfer Tokens
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {
            
            //Set Fee for Buys
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnBuy;
                _taxFee = _taxFeeOnBuy;
            }
    
            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnSell;
                _taxFee = _taxFeeOnSell;
            }
            
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapTokensForEth(uint tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function sendETHToFee(uint amount) private {
        _marketingAddress.transfer(amount);
    }


    function manualswap() external {
        require(_msgSender() == _marketingAddress);
        uint contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _marketingAddress);
        uint contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint tAmount) private {
        (uint rAmount, uint rTransferAmount, uint rFee, uint tTransferAmount, uint tFee, uint tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].a6Sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].a6Add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint tTeam) private {
        uint currentRate = _getRate();
        uint rTeam = tTeam.a6Mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].a6Add(rTeam);
    }

    function _reflectFee(uint rFee, uint tFee) private {
        _rTotala6 = _rTotala6.a6Sub(rFee);
        _tFeeTotal = _tFeeTotal.a6Add(tFee);
    }

    receive() external payable {}

    function _getValues(uint tAmount) private view returns (uint, uint, uint, uint, uint, uint) {
        (uint tTransferAmount, uint tFee, uint tTeam) =
            _getTValues(tAmount, _redisFee, _taxFee);
        uint currentRate = _getRate();
        (uint rAmount, uint rTransferAmount, uint rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint tAmount, uint redisFee, uint taxFee) private pure returns (uint, uint, uint) {
        uint tFee = tAmount.a6Mul(redisFee).a6Div(100);
        uint tTeam = tAmount.a6Mul(taxFee).a6Div(100);
        uint tTransferAmount = tAmount.a6Sub(tFee).a6Sub(tTeam);

        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(uint tAmount, uint tFee, uint tTeam, uint currentRate) private pure returns (uint, uint, uint) {
        uint rAmount = tAmount.a6Mul(currentRate);
        uint rFee = tFee.a6Mul(currentRate);
        uint rTeam = tTeam.a6Mul(currentRate);
        uint rTransferAmount = rAmount.a6Sub(rFee).a6Sub(rTeam);

        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint) {
        (uint rSupply, uint tSupply) = _getCurrentSupply();

        return rSupply.a6Div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint, uint) {
        uint rSupply = _rTotala6;
        uint tSupply = _tTotala6;
        if (rSupply < _rTotala6.a6Div(_tTotala6)) return (_rTotala6, _tTotala6);
    
        return (rSupply, tSupply);
    }
    
    function setFee(uint redisFeeOnBuy, uint redisFeeOnSell, uint taxFeeOnBuy, uint taxFeeOnSell) public onlyOwner {
        _redisFeeOnBuy = redisFeeOnBuy;
        _redisFeeOnSell = redisFeeOnSell;
        
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
    }

    //Set minimum tokens required to swap.
    function setMinSwapTokensThreshold(uint swapTokensAtAmount) public onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
    }
    
    //Set minimum tokens required to swap.
    function toggleSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }
    
    //Set MAx transaction
    function setMaxTxnAmount(uint maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }
    
    function setMaxWalletSize(uint maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }
 
    function allowPreTrading(address account, bool allowed) public onlyOwner {
        require(preTrader[account] != allowed, "TOKEN: Already enabled.");
        preTrader[account] = allowed;
    }
}