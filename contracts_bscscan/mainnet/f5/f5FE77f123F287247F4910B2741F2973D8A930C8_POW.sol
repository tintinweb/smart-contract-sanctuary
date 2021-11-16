/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

/**

 Link Social Media
 Tg : https://t.me/ProjectOneWhale
 
 Website : https://www.onewhale.net/

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

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

library SafeMath {
    function add(uint a1, uint b1) internal pure returns (uint) {
        uint c1 = a1 + b1;
        require(c1 >= a1, "SafeMath: addition overflow");
        return c1;
    }

    function sub(uint a1, uint b1) internal pure returns (uint) {
        return sub(a1, b1, "SafeMath: subtraction overflow");
    }

    function sub(
        uint a1,
        uint b1,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b1 <= a1, errorMessage);
        uint c1 = a1 - b1;
        return c1;
    }

    function mul(uint a1, uint b1) internal pure returns (uint) {
        if (a1 == 0) {
            return 0;
        }
        uint c1 = a1 * b1;
        require(c1 / a1 == b1, "SafeMath: multiplication overflow");
        return c1;
    }

    function div(uint a1, uint b1) internal pure returns (uint) {
        return div(a1, b1, "SafeMath: division by zero");
    }

    function div(
        uint a1,
        uint b1,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b1 > 0, errorMessage);
        uint c1 = a1 / b1;
        return c1;
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

contract POW is Context, IERC20, Ownable {
    
    using SafeMath for uint;

    string private constant _name = "Project: One Whale";
    string private constant _symbol = "POW";
    uint8 private constant _decimals = 9;

    mapping(address => uint) private _rOwned;
    mapping(address => uint) private _tOwned;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint private constant MAX = ~uint(0);
    uint private constant _tTotal = 1000000000000000 * 10**9;
    uint private _rTotal = (MAX - (MAX % _tTotal));
    uint private _tFeeTotal;
    
    //Buy Fee
    uint private _redisFeeOnBuy = 1;
    uint private _taxFeeOnBuy = 3;
    
    //Sell Fee
    uint private _redisFeeOnSell = 1;
    uint private _taxFeeOnSell = 3;
    
    //Original Fee
    uint private _redisFee = _redisFeeOnSell;
    uint private _taxFee = _taxFeeOnSell;
    
    uint private _previousredisFee = _redisFee;
    uint private _previoustaxFee = _taxFee;
    
    mapping (address => bool) public preTrader;
    mapping(address => uint) private cooldown;
    
    address payable private _marketingAddress = payable(0xEAc29C351Ce6cf1e6b588CE0d314a5B034080ffc);
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool private tradingOpen;
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
        
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        
        preTrader[owner()] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalSupply() public pure override returns (uint) {
        return _tTotal;
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function tokenFromReflection(uint rAmount) private view returns (uint) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint currentRate = _getRate();
        return rAmount.div(currentRate);
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
            if (!tradingOpen) {
                require(preTrader[from], "TOKEN: This account cannot send tokens until trading is enabled");
            }
              
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
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint amount) private {
        _marketingAddress.transfer(amount);
    }

    function setTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
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
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint tTeam) private {
        uint currentRate = _getRate();
        uint rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint rFee, uint tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
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
        uint tFee = tAmount.mul(redisFee).div(100);
        uint tTeam = tAmount.mul(taxFee).div(100);
        uint tTransferAmount = tAmount.sub(tFee).sub(tTeam);

        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(uint tAmount, uint tFee, uint tTeam, uint currentRate) private pure returns (uint, uint, uint) {
        uint rAmount = tAmount.mul(currentRate);
        uint rFee = tFee.mul(currentRate);
        uint rTeam = tTeam.mul(currentRate);
        uint rTransferAmount = rAmount.sub(rFee).sub(rTeam);

        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint) {
        (uint rSupply, uint tSupply) = _getCurrentSupply();

        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint, uint) {
        uint rSupply = _rTotal;
        uint tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    
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