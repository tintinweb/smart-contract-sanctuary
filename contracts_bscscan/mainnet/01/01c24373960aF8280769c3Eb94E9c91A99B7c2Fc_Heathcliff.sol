/**
 *Submitted for verification at BscScan.com on 2021-11-11
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

library SafeMathb3 {
    function b3Add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMathb3: addition overflow");
        return c;
    }

    function b3Sub(uint a, uint b) internal pure returns (uint) {
        return b3Sub(a, b, "SafeMathb3: subtraction overflow");
    }

    function b3Sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;
        return c;
    }

    function b3Mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMathb3: multiplication overflow");
        return c;
    }

    function b3Div(uint a, uint b) internal pure returns (uint) {
        return b3Div(a, b, "SafeMathb3: division by zero");
    }

    function b3Div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
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

contract Heathcliff is Context, IERC20, Ownable {
    
    using SafeMathb3 for uint;

    string private constant _nameb3 = "Heathcliff";
    string private constant _symbolb3 = "HEATCLIFF";
    uint8 private constant _decimalsb3 = 9;

    mapping(address => uint) private _rOwned;
    mapping(address => uint) private _tOwned;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint private constant MAX = ~uint(0);
    uint private constant _tTotalb3 = 1000000000000 * 10**9;
    uint private _rTotalb3 = (MAX - (MAX % _tTotalb3));
    uint private _tFeeTotal;
    
    //Buy Fee
    uint private _redisFeeOnBuy = 4;
    uint private _taxFeeOnBuy = 2;
    
    //Sell Fee
    uint private _redisFeeOnSell = 5;
    uint private _taxFeeOnSell = 1;
    
    //Original Fee
    uint private _redisFee = _redisFeeOnSell;
    uint private _taxFee = _taxFeeOnSell;
    
    uint private _previousredisFee = _redisFee;
    uint private _previoustaxFee = _taxFee;
    
    mapping (address => bool) public preTrader;
    mapping(address => uint) private cooldown;
    
    address payable private _marketingAddress = payable(0xf4e9d710780c80FFC5Cd44352FBd7152ECd002a3);
    
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
        
        _rOwned[_msgSender()] = _rTotalb3;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        
        preTrader[owner()] = true;

        emit Transfer(address(0), _msgSender(), _tTotalb3);
    }

    function name() public pure returns (string memory) {
        return _nameb3;
    }

    function symbol() public pure returns (string memory) {
        return _symbolb3;
    }

    function decimals() public pure returns (uint8) {
        return _decimalsb3;
    }

    function totalSupply() public pure override returns (uint) {
        return _tTotalb3;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].b3Sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tokenFromReflection(uint rAmount) private view returns (uint) {
        require(
            rAmount <= _rTotalb3,
            "Amount must be less than total reflections"
        );
        uint currentRate = _getRate();
        return rAmount.b3Div(currentRate);
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
        _rOwned[sender] = _rOwned[sender].b3Sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].b3Add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint tTeam) private {
        uint currentRate = _getRate();
        uint rTeam = tTeam.b3Mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].b3Add(rTeam);
    }

    function _reflectFee(uint rFee, uint tFee) private {
        _rTotalb3 = _rTotalb3.b3Sub(rFee);
        _tFeeTotal = _tFeeTotal.b3Add(tFee);
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
        uint tFee = tAmount.b3Mul(redisFee).b3Div(100);
        uint tTeam = tAmount.b3Mul(taxFee).b3Div(100);
        uint tTransferAmount = tAmount.b3Sub(tFee).b3Sub(tTeam);

        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(uint tAmount, uint tFee, uint tTeam, uint currentRate) private pure returns (uint, uint, uint) {
        uint rAmount = tAmount.b3Mul(currentRate);
        uint rFee = tFee.b3Mul(currentRate);
        uint rTeam = tTeam.b3Mul(currentRate);
        uint rTransferAmount = rAmount.b3Sub(rFee).b3Sub(rTeam);

        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint) {
        (uint rSupply, uint tSupply) = _getCurrentSupply();

        return rSupply.b3Div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint, uint) {
        uint rSupply = _rTotalb3;
        uint tSupply = _tTotalb3;
        if (rSupply < _rTotalb3.b3Div(_tTotalb3)) return (_rTotalb3, _tTotalb3);
    
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