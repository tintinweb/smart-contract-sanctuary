/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
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

    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
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
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract IngaruInu is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Ingaru Inu";
    string private constant _symbol = "IGU";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 private _devTax;
    uint256 private _buyDevTax = 8;
    uint256 private _sellDevTax = 0;

    uint256 private _marketingTax;
    uint256 private _buyMarketingTax = 8;
    uint256 private _sellMarketingTax = 5;

    uint256 private _salesTax;
    uint256 private _buySalesTax = 6;
    uint256 private _sellSalesTax = 5;

    uint256 private _totalBuyTax = _buyDevTax + _buyMarketingTax + _buySalesTax;
    uint256 private _totalSellTax = _sellDevTax + _sellMarketingTax + _sellSalesTax;

    uint256 private _summedTax = _marketingTax+_salesTax;
    uint256 private _numOfTokensToExchangeForTeam = 500000 * 10**9;
    uint256 private _routermax = 5000000000 * 10**9;

    // Bot detection
    mapping(address => bool) private bots;
    mapping(address => uint256) private cooldown;
    address payable private _Marketingfund;
    address payable private _Deployer;
    address payable private _devWalletAddress;
    address payable private _holdings;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    bool private enableLevelSell = false;
    uint256 private _maxTxAmount = _tTotal;
    uint256 public launchBlock;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address payable marketingTaxAddress, address payable devfeeAddr, address payable depAddr, address payable holdings) {
        _Marketingfund = marketingTaxAddress;
        _Deployer = depAddr;
        _devWalletAddress = devfeeAddr;
        _holdings = holdings;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_Marketingfund] = true;
        _isExcludedFromFee[_devWalletAddress] = true;
        _isExcludedFromFee[_Deployer] = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // bsc 0x10ED43C718714eb63d5aA57B78B54704E256024E eth 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

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

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
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

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }

    function setLevelSellEnabled(bool enable) external onlyOwner {
        enableLevelSell = enable;
    }

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if (_devTax == 0 && _summedTax == 0) return;
        _devTax = 0;
        _summedTax = 0;
    }

    function restoreAllFee() private {
        _devTax = _buyDevTax;
        _marketingTax = _buyMarketingTax;
        _salesTax = _buySalesTax;
        _summedTax = _marketingTax+_salesTax;
    }

     function takeBuyFee() private {
        _salesTax = _buySalesTax;
        _marketingTax = _buyMarketingTax;
        _devTax = _buyDevTax;
        _summedTax = _marketingTax+_salesTax;
    }

    function takeSellFee() private {
        _devTax = _sellDevTax;
        _salesTax = _sellSalesTax;
        _marketingTax = _sellMarketingTax;
        _summedTax = _sellSalesTax+_sellMarketingTax;
    }

    function levelSell(uint256 amount, address sender) private returns (uint256) {
        uint256 sellTax = amount.mul(_totalSellTax).div(100);
        _rOwned[sender] = _rOwned[sender].sub(sellTax);
        _rOwned[address(this)] = _rOwned[address(this)].add(sellTax);

        uint256 tAmount = amount.sub(sellTax);
        uint256 prevEthBalance = address(this).balance;
        swapTokensForEth(sellTax);
        uint256 newEthBalance = address(this).balance;

        uint256 balanceDelta = newEthBalance - prevEthBalance;

        if (balanceDelta > 0) {
            sendETHForSellTax(balanceDelta);
        }
        
        return tAmount;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (from != owner() && to != owner()) {
            if (cooldownEnabled) {
                if (
                    from != address(this) &&
                    to != address(this) &&
                    from != address(uniswapV2Router) &&
                    to != address(uniswapV2Router)
                ) {
                    require(
                        _msgSender() == address(uniswapV2Router) ||
                            _msgSender() == uniswapV2Pair,
                        "ERR: Uniswap only"
                    );
                }
            }
            if(from != address(this)){
                require(amount <= _maxTxAmount);
            }
            require(!bots[from] && !bots[to] && !bots[msg.sender]);

            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to] &&
                cooldownEnabled
            ) {
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (15 seconds);
            }
              
            uint256 contractTokenBalance = balanceOf(address(this));
            
            if(contractTokenBalance >= _routermax)
            {
                contractTokenBalance = _routermax;
            }

            bool overMinTokenBalance = contractTokenBalance >= _numOfTokensToExchangeForTeam;
            if (!inSwap && swapEnabled && overMinTokenBalance && from != uniswapV2Pair && from != address(uniswapV2Router)
            ) {
                // We need to swap the current tokens to ETH and send to the team wallet
                swapTokensForEth(contractTokenBalance);
                
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        if (from != owner() && to != owner() && to != uniswapV2Pair) {
            require(swapEnabled, "Swap disabled");
            _tokenTransfer(from, to, amount, takeFee);
        } else {
            _tokenTransfer(from, to, amount, takeFee);
        }

     
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isBlackListed(address account) public view returns (bool) {
        return bots[account];
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap{
            // generate the uniswap pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();

            _approve(address(this), address(uniswapV2Router), type(uint256).max);

            // make the swap
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
    }

    function sendETHToFee(uint256 amount) private {
        _Marketingfund.transfer(amount.div(_totalBuyTax).mul(_buyMarketingTax));
        _devWalletAddress.transfer(amount.div(_totalBuyTax).mul(_buyDevTax));
        _Deployer.transfer(amount.div(_totalBuyTax).mul(_buySalesTax));
    }

    function sendETHForSellTax(uint256 amount) private {
        _holdings.transfer(amount);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "trading is already open");
        swapEnabled = true;
        cooldownEnabled = false;
        _maxTxAmount = 25000000000 * 10**9;
        launchBlock = block.number;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }
    
    function setSwapEnabled(bool enabled) external onlyOwner() {
        swapEnabled = enabled;
    }
        

    function manualswap() external onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external onlyOwner() {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function setBots(address[] memory bots_) public onlyOwner() {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function setBot(address _bot) external onlyOwner() {
        bots[_bot] = true;
    }

    function delBot(address notbot) public onlyOwner() {
        bots[notbot] = false;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        uint256 amountToTx = amount;
            if (!takeFee) {
                removeAllFee();
            }
            else if(sender == uniswapV2Pair) {
                takeBuyFee();
            }
            else if(recipient == uniswapV2Pair) {
                takeSellFee();
                if (enableLevelSell) {
                uint256 remainder = levelSell(amount, sender);
                amountToTx = remainder;
                }
            }
            else {
                takeSellFee();
            }
            
        _transferStandard(sender, recipient, amountToTx);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTValues(tAmount, _devTax, _summedTax);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 taxFee,
        uint256 TeamFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _taxFee = taxFee > 0 ? taxFee : 1;
        uint256 _TeamFee = TeamFee > 0 ? TeamFee : 1;

        uint256 tFee = tAmount.mul(_taxFee).div(100);
        uint256 tTeam = tAmount.mul(_TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }
    function setRouterPercent(uint256 maxRouterPercent) external onlyOwner() {
        require(maxRouterPercent > 0, "Amount must be greater than 0");
        _routermax = _tTotal.mul(maxRouterPercent).div(10**4);
    }
    
    function _setTeamFee(uint256 teamFee) external onlyOwner() {
        require(teamFee >= 1 && teamFee <= 25, 'teamFee should be in 1 - 25');
        _summedTax = teamFee;
    }
}