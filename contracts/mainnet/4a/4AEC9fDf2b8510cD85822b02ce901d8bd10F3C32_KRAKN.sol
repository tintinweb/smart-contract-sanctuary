/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

/*
                          ```````                                               
                   ``.-:://////////::-.``                                       
                `-:/++oooooooooooooooo++/:-`                                    
             `-:++ooooooooooooooooooooooooo+/-`                                 
           `:/+ooooooooooo/:----:+ooooooooooo+/:`                               
         `:++/++oooooooo/-.......--+oooooooo++/++:`                             
        -/++/:o+oooooo+-............:ooooooo+o::o+/.                            
       :+++o/-+oooooo+-..............:+oooooo+./oo++:                           
      :++++++/-:+++++/````````````````/+++++:.:++++++:                          
     :++++++++/-.-/++:````````````````/++/-.-/++++++++:                         
    .++/:::/++++/.`-++````````````````++-`./++++/:::/++.                        
    /++.-:.`-/++++``/+:``````````````:+/``/+++/-`.:-.++/                        
   .+++/+++: .++/. .++/``          `./+/. ./++. :+++/+++`                       
   -+++++++/` //`  :++-/s+-     `:+s:-++:  `//  /+++++++-                       
   -+++++++/  :-   `/+/:/++`    .+//-/+/`   -:  /+++++++-                       
   -+++++++:  ./.   `/++-          -++/`   ./.  :+++++++-                       
   .++++++/-`` -/:   `-`            `-`   :/- ``-/++++++`                       
    /++/-`   `..`.```                  ```.`..    `-/++/                        
    .++.  ``.`  .                          .  ````  .++.                        
     :/  -///-  .::/-`.://:.`  `.://:.`-/::.  -///-  /:                         
     `/-``-:+/  `:/- `-.--:/-  :/---`-` -/:`  /+:-``-:                          
      `:////++-     `: -++:+.  :+:+/.`/`     -++//:/:`                          
        -/++++/:.`.-//  -:-.   `-:-. `+/-.`.-/++++/.                            
         `:/++++///+++:`            ./+++///++++/:`                             
           `:/+++++++++//----::---://+++++++++/:`                               
             `-:/++++++++++++++++++++++++++/:-`                                 
                `-://++++++++++++++++++//:-`                                    
                   ``.-:::////////:::-.``                                       
                          ````````                                              

    ██╗  ██╗███████╗    ██╗    ██╗  ██╗███████╗███╗   ██╗
    ██║ ██╔╝██║  ██╝   ████╗   ██║ ██╔╝██╔════╝████╗  ██║
    █████╔╝ ███████╗  ██╔═██╗  █████╔╝ █████╗  ██╔██╗ ██║
    ██╔═██╗ ██╔══██║ ████████╗ ██╔═██╗ ██╔══╝  ██║╚██╗██║
    ██║  ██╗██║  ██║██║     ██╗██║  ██╗███████╗██║ ╚████║
    ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝
    

KRAKEN by VP

FIRST TWENTY MINUTES OF TRADING
buy/sell limit 1% total supply

BUY FEES
7% -redistribution 
5% - lottery wallet

SELL FEES (Dynamic - Resets after 24 hours from first sell)
2% price impact limit on all sells

1st sell -
10% dev tax
20% whale wallet
1 hour cooldown period

2nd sell - 
8% dev tax 
17% whale wallet tax
2 hour cooldown period

3rd sell - 
10% dev tax 
20% whale wallet tax
3hour cooldown period

4th sell - 
8% dev tax 
17% whale wallet tax
No more sells allowed until 24 hours after first sell

The Kraken is a legendary sea monster of colossal proportions that originates from Nordic folklore. Striking fear into the
hearts of every sailor, the Kraken’s tentacles wield enough power to pull entire ships underwater, leaving the crew to either 
drown or to be its next meal. Rumor has it that the Kraken is guarding immense riches from its previous victims.

Will investors suffer the same fate, or will they lay claim to what the beast has stolen?

KRAKEN by VP ($KRAKN) is inspired by the popular “buyback wallet” trend. We dove into the communities of the different projects
that utilized this tokenomic and gathered up countless examples as to what investors all liked, disliked and ultimately wanted 
to see. The ultimate goal is to reward our community for holding to the end game with various incentives. Some of the mechanics 
include but are not limited to redistribution, lotteries, buy backs and dynamic sell limits.

Smart contract developed by Alex Liddle
Reach on telegram: @Alex_Saint_Dev

SPDX-License-Identifier: None
*/



pragma solidity ^0.8.4;

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

contract KRAKN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "KRAKEN by VP";
    string private constant _symbol = "KRAKN";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    uint256 public _whaleFee = 17;
    uint256 private _previousWhaleFee = _whaleFee;
    uint256 public _teamFee = 8;
    uint256 private _previousTeamFee = _teamFee;
    
    uint256 public _teamPercent = 30;
    uint256 public _whalePercent = 70;

    uint256 public _reflectionFee = 5;
    uint256 private _previousReflectionFee = _reflectionFee;
    uint256 public _lotteryFee = 5;
    uint256 private _previousLotteryFee = _lotteryFee;
    
    uint256 public _priceImpact = 2;
    
    struct BuyBreakdown {
        uint256 tTransferAmount;
        uint256 tLottery;
        uint256 tReflection;
    }
    
    mapping(address => bool) private bots;
    mapping(address => uint256) private buycooldown;
    mapping(address => uint256) private sellcooldown;
    mapping(address => uint256) private firstsell;
    mapping(address => uint256) private sellnumber;
    address payable private _teamAddress = payable(0x58BfDbb51A62584c023a6439155F5bDcB556660b);
    address payable private _whaleAddress = payable(0x651CB3E19815Fe172Fd730D7a6d439598CCb0010);
    address payable private _lotteryAddress = payable(0x75B63Dfb568F2CF52d984862ac56Af47C17dEE4A);
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    bool private sellCooldownEnabled = false;
    bool private sellOnly = false;
    uint256 private _maxTxAmount;
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event SellOnlyUpdated(bool sellOnly);
    event PercentsUpdated(uint256 _teamPercent, uint256 _whalePercent);
    event FeesUpdated(uint256 _whaleFee, uint256 _teamFee, uint256 _reflectionFee, uint256 _lotteryFee);
    event PriceImpactUpdated(uint256 _priceImpact);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);

        swapEnabled = true;
        cooldownEnabled = false;
        sellCooldownEnabled = true;
        liquidityAdded = true;
        _maxTxAmount = _tTotal.div(100); // start off transaction limit at 1% of total supply

        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_teamAddress] = true;
        _isExcludedFromFee[_whaleAddress] = true;
        _isExcludedFromFee[_lotteryAddress] = true;
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

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }
    
    function setSellCooldownEnabled(bool onoff) external onlyOwner() {
        sellCooldownEnabled = onoff;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    function removeAllFee() private {
        if (_whaleFee == 0 && _teamFee == 0) return;
        _previousTeamFee = _teamFee;
        _previousWhaleFee = _whaleFee;
        _whaleFee = 0;
        _teamFee = 0;
    }

    function restoreAllFee() private {
        _whaleFee = _previousWhaleFee;
        _teamFee = _previousTeamFee;
    }
    
    function setFee(uint256 multiplier) private {
        
        if (multiplier == 2 || multiplier == 4){
            _whaleFee += 0;
            _teamFee += 0;
        }
        if (multiplier == 1 || multiplier == 3){
            _whaleFee += 4;
            _teamFee += 1;
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
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            if (cooldownEnabled) { // only buys are allowed, if enabled
                if (from != address(this) && to != address(this) && from != address(uniswapV2Router) && to != address(uniswapV2Router)) {
                    require(_msgSender() == address(uniswapV2Router) || _msgSender() == uniswapV2Pair,"ERR: Buys only");
                }
            }
            require(!bots[from] && !bots[to]);
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {//buys
                require(tradingOpen);
                require(!sellOnly, "Buys are disabled");
                require(amount <= _maxTxAmount);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled && sellCooldownEnabled) { //sells, transfers (except for buys)
                require(amount <= balanceOf(uniswapV2Pair).mul(_priceImpact).div(100) && amount <= _maxTxAmount);
                require(sellcooldown[from] < block.timestamp);
                if(firstsell[from] + (1 days) < block.timestamp){
                    sellnumber[from] = 0;
                }
                if (sellnumber[from] == 0) {
                    sellnumber[from]++;
                    firstsell[from] = block.timestamp;
                    sellcooldown[from] = block.timestamp + (1 hours);
                }
                else if (sellnumber[from] == 1) {
                    sellnumber[from]++;
                    sellcooldown[from] = block.timestamp + (2 hours);
                }
                else if (sellnumber[from] == 2) {
                    sellnumber[from]++;
                    sellcooldown[from] = block.timestamp + (3 hours);
                }
                else if (sellnumber[from] == 3) {
                    sellnumber[from]++;
                    sellcooldown[from] = firstsell[from] + (1 days);
                }
                if (contractTokenBalance > 0) {
                    swapTokensForEth(contractTokenBalance);
                }
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
                if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                    setFee(sellnumber[from]);
                }
            }
        }
        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee();
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function sendETHToFee(uint256 amount) private {
        _teamAddress.transfer(amount.mul(_teamPercent).div(100));
        _whaleAddress.transfer(amount.mul(_whalePercent).div(100));
    }
    
    function openTrading() public onlyOwner {
        require(liquidityAdded);
        tradingOpen = true;
    }
    
    function enableSellOnly() public onlyOwner {
        sellOnly = true;
        emit SellOnlyUpdated(sellOnly);
    }
    
    function disableSellOnly() public onlyOwner {
        sellOnly = false;
        emit SellOnlyUpdated(sellOnly);
    }

    function manualswap() external {
        require(_msgSender() == _teamAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _teamAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        if (sender == uniswapV2Pair){ //buy order, reflection, and lottery
            _transferStandardBuy(sender, recipient, amount);
        }
        else {
            _transferStandardSell(sender, recipient, amount); //take team and whale (no reflection, or lottery)
        }
        if (!takeFee) restoreAllFee();
    }

    function _transferStandardBuy(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tLottery, uint256 tReflection) = _getValuesBuy(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLottery(tLottery);
        _reflectFee(rReflection, tReflection);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _takeLottery(uint256 tLottery) private {
        uint256 currentRate = _getRate();
        uint256 rLottery = tLottery.mul(currentRate);
        _rOwned[_lotteryAddress] = _rOwned[_lotteryAddress].add(rLottery);
        emit Transfer(address(this), _lotteryAddress, rLottery);
    }

    function _reflectFee(uint256 rReflection, uint256 tReflection) private {
        _rTotal = _rTotal.sub(rReflection);
        _tFeeTotal = _tFeeTotal.add(tReflection);
    }
    
    function _transferStandardSell(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount,, uint256 tTransferAmount, uint256 tTeam, uint256 tWhale) = _getValuesSell(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _takeWhale(tWhale);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }
    
    function _takeWhale(uint256 tWhale) private {
        uint256 currentRate = _getRate();
        uint256 rWhale = tWhale.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rWhale);
    }

    receive() external payable {}

    // Sell GetValues
    function _getValuesSell(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tTeam, uint256 tWhale) = _getTValuesSell(tAmount, _teamFee, _whaleFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTeam) = _getRValuesSell(tAmount, tTeam, tWhale, currentRate);
        return (rAmount, rTransferAmount, rTeam, tTransferAmount, tTeam, tWhale);
    }

    function _getTValuesSell(uint256 tAmount, uint256 teamFee, uint256 whaleFee) private pure returns (uint256, uint256, uint256) {
        uint256 tTeam = tAmount.mul(teamFee).div(100);
        uint256 tWhale = tAmount.mul(whaleFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tTeam).sub(tWhale);
        return (tTransferAmount, tTeam, tWhale);
    }

    function _getRValuesSell(uint256 tAmount, uint256 tTeam, uint256 tWhale, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rWhale = tWhale.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTeam).sub(rWhale);
        return (rAmount, rTransferAmount, rTeam);
    }

    // Buy GetValues
    function _getValuesBuy(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        BuyBreakdown memory buyFees;
        (buyFees.tTransferAmount, buyFees.tLottery, buyFees.tReflection) = _getTValuesBuy(tAmount, _lotteryFee, _reflectionFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _getRValuesBuy(tAmount, buyFees.tLottery, buyFees.tReflection, currentRate);
        return (rAmount, rTransferAmount, rReflection, buyFees.tTransferAmount, buyFees.tLottery, buyFees.tReflection);
    }

    function _getTValuesBuy(uint256 tAmount, uint256 lotteryFee, uint256 reflectionFee) private pure returns (uint256, uint256, uint256) {
        BuyBreakdown memory buyTFees;
        
        buyTFees.tLottery = tAmount.mul(lotteryFee).div(100);
        buyTFees.tReflection = tAmount.mul(reflectionFee).div(100);
        buyTFees.tTransferAmount = tAmount.sub(buyTFees.tLottery).sub(buyTFees.tReflection);
        return (buyTFees.tTransferAmount, buyTFees.tLottery, buyTFees.tReflection);
    }

    function _getRValuesBuy(uint256 tAmount, uint256 tLottery, uint256 tReflection, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rLottery = tLottery.mul(currentRate);
        uint256 rReflection = tReflection.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rLottery).sub(rReflection);
        return (rAmount, rTransferAmount, rReflection);
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
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
  
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }
    
    function setPercents(uint256 teamPercent, uint256 whalePercent) external onlyOwner() {
        require(teamPercent.add(whalePercent) == 100, "Sum of percents must equal 100");
        _teamPercent = teamPercent;
        _whalePercent = whalePercent;
        emit PercentsUpdated(_teamPercent, _whalePercent);
    }
    
    function setTaxes(uint256 whaleFee, uint256 teamFee, uint256 reflectionFee, uint256 lotteryFee) external onlyOwner() {
        require(whaleFee.add(teamFee) < 50, "Sum of sell fees must be less than 50");
        require(reflectionFee.add(lotteryFee) < 50, "Sum of buy fees must be less than 50");
        _whaleFee = whaleFee;
        _teamFee = teamFee;
        _reflectionFee = reflectionFee;
        _lotteryFee = lotteryFee;
        emit FeesUpdated(_whaleFee, _teamFee, _reflectionFee, _lotteryFee);
    }
    
    function setPriceImpact(uint256 priceImpact) external onlyOwner() {
        require(priceImpact < 10, "max price impact must be less than 10");
        _priceImpact = priceImpact;
        emit PriceImpactUpdated(_priceImpact);
    }
}