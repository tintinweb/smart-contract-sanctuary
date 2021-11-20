import './SafeMath.sol';
import './IER20.sol';
import './IUniswapV2Factory.sol';
import './Context.sol';
import './Ownable.sol';

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract WiseGuys is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public maxTxAmount = 3000000000000 * 10**9;
    uint256 public maxWalletSize = 10000000000000 * 10**9;
    uint256 public swapTokensAtAmount = 1000000000000 * 10**9;
    mapping(address => bool) public bots;
    mapping (address => bool) public preTrader;

    string private constant _name = "Wise Guys";
    string private constant _symbol = "WS";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    //Buy Fee
    uint256 private _redisFeeOnBuy = 1;
    uint256 private _taxFeeOnBuy = 9;
    
    //Sell Fee
    uint256 private _redisFeeOnSell = 1;
    uint256 private _taxFeeOnSell = 9;
    
    uint256 private _redisFee = _redisFeeOnSell;
    uint256 private _taxFee = _taxFeeOnSell;
    
    uint256 private _previousRedisFee = _redisFee;
    uint256 private _previousTaxFee = _taxFee;
            
    bool private _tradingOpen;
    bool private _inSwap = false;
    bool private _swapEnabled = true;
    
    address payable private _marketingAddress = payable(0x5261e2670d667984c61c4AE4e6Ad9DC1ED478Ef7);
    address payable private _maintenanceAddress = payable(0x7549B3e597CD7d0aB9e549A8d04941A06A5445F0);    

    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    modifier lockTheSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_maintenanceAddress] = true;
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient,uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256){
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;
    
        _previousRedisFee = _redisFee;
        _previousTaxFee = _taxFee;
        
        _redisFee = 0;
        _taxFee = 0;
    }

    function restoreAllFee() private {
        _redisFee = _previousRedisFee;
        _taxFee = _previousTaxFee;
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

        if (from != owner() && to != owner() && !preTrader[from] && !preTrader[to]) {
            
            //Trade start check
            if (!_tradingOpen) {
                require(preTrader[from], "TOKEN: This account cannot send tokens until trading is enabled");
            }
              
            require(amount <= maxTxAmount, "TOKEN: Max Transaction Limit");
            require(!bots[from] && !bots[to], "TOKEN: Your account has been blacklisted");
            
            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < maxWalletSize, "TOKEN: Balance exceeds wallet size");
            }
            
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;

            if(contractTokenBalance >= maxTxAmount) {
                contractTokenBalance = maxTxAmount;
            }
            
            if (canSwap && !_inSwap && from != uniswapV2Pair && _swapEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
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

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function sendETHToFee(uint256 amount) private {
        _maintenanceAddress.transfer(amount.div(2));
        _marketingAddress.transfer(amount.div(2));
    }

    function openTrading() public onlyOwner {
        _tradingOpen = true;
    }

    function manualSwap() external {
        require(_msgSender() == _maintenanceAddress || _msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external {
        require(_msgSender() == _maintenanceAddress || _msgSender() == _marketingAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function blockBots(address[] memory mBots) public onlyOwner {
        for (uint256 i = 0; i < mBots.length; i++) {
            bots[mBots[i]] = true;
        }
    }

    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeTeam(tTeam);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function takeTeam(uint256 tTeam) private {
        uint256 currentRate = getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = getTValues(tAmount, _redisFee, _taxFee);
        uint256 currentRate = getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function getTValues(uint256 tAmount, uint256 redisFee, uint256 taxFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256,uint256,uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);

        return (rAmount, rTransferAmount, rFee);
    }

    function getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function setFee(uint256 redisFeeOnBuy, uint256 redisFeeOnSell, uint256 taxFeeOnBuy, uint256 taxFeeOnSell) public onlyOwner {
        _redisFeeOnBuy = redisFeeOnBuy;
        _redisFeeOnSell = redisFeeOnSell;
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
    }

    //Set minimum tokens required to swap.
    function setMinSwapTokensThreshold(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount;
    }
    
    //Set minimum tokens required to swap.
    function toggleSwap(bool swapEnabled) public onlyOwner {
        _swapEnabled = swapEnabled;
    }
    
    //Set MAx transaction
    function setMaxTxnAmount(uint256 amount) public onlyOwner {
        maxTxAmount = amount;
    }
    
    function setMaxWalletSize(uint256 amount) public onlyOwner {
        maxWalletSize = amount;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }
 
    function allowPreTrading(address account, bool allowed) public onlyOwner {
        require(preTrader[account] != allowed, "TOKEN: Already enabled.");
        preTrader[account] = allowed;
    }
}