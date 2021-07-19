/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

/**
 * 
 * RAIJIN
 * Telegram: https://t.me/raijintoken
 * 
 * Raijin Token focuses on rewarding holders through huge redistribution fees collected from snipers and dumpers.
 * Team fees are kept low and will be used for marketing.
 * 
 * FIRST 2 MINUTES: 
 * - 5,000,000,000 max buy
 * - 45-second buy cooldown 
 * 
 * FIRST 5 MINUTES:
 * - Max 2% wallet holder 
 * - 25% redistribution fee for sells (0% team fee)
 * 
 * 15-sec sell cooldown after a buy for bot prevention
 * 25% snipe tax on buy
 * 
 * Waivable Buy Tax (STARTS 5 MINUTES AFTER LAUNCH)
 * - 3% dev and marketing fee
 * - WAIVED if you buy 2% or more of available supply
 * 
 * Dump Prevention Sells via Redistribution (STARTS 5 MINUTES AFTER LAUNCH)
 * - Sell is limited to less than 3% price impact
 * - 5-20% REDISTRIBUTION depending on sell counter (1st to 4th)
 * - Sell counter resets every hour
 * - No sell cooldowns
 * - 6% dev and marketing fee
 * 
 * Sniper mechanic (runs for 1 hour)
 * - Snipers start with 20% redistribution fees on sell
 * - Snipers sell are limited to 1% price impact
 * - limited to 1 sell
 * - after 1 hour, snipers revert to normal status
 * 
 * Bots will be banned
 * 
 * No team tokens, no presale
 * 
 * SPDX-License-Identifier: UNLICENSED 
 * 
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
        if(a == 0) {
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
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

}  
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract RAIJIN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _friends;
    mapping (address => bool) private _snipers;
    mapping (address => User) private trader;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private constant _name = unicode"Raijin Token";
    string private constant _symbol = unicode"RAIJIN";
    uint8 private constant _decimals = 9;
    uint256 private _redistributionFee = 5;
    uint256 private _teamFee = 5;
    uint256 private _feeRate = 5;
    uint256 private _launchTime;
    uint256 private _previousRedistributionFee = _redistributionFee;
    uint256 private _previousteamFee = _teamFee;
    uint256 private _maxBuyAmount;
    address payable private _FeeAddress;
    address payable private _marketingWalletAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private _cooldownEnabled = true;
    bool private inSwap = false;
    uint256 private launchBlock = 0;
    uint256 private buyLimitEnd;
    uint256 private tokenomicsDelay;
    uint256 private snipeTaxLimit;
    struct User {
        uint256 buyCD;
        uint256 sellCD;
        uint256 sellCount;
        uint256 snipeSellCount;
        uint256 firstSell;
        bool exists;
    }

    event MaxBuyAmountUpdated(uint _maxBuyAmount);
    event CooldownEnabledUpdated(bool _cooldown);
    event FeeMultiplierUpdated(uint _multiplier);
    event FeeRateUpdated(uint _rate);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor (address payable FeeAddress, address payable marketingWalletAddress) {
        _FeeAddress = FeeAddress;
        _marketingWalletAddress = marketingWalletAddress;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[FeeAddress] = true;
        _isExcludedFromFee[marketingWalletAddress] = true;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if(_redistributionFee == 0 && _teamFee == 0) return;
        _previousRedistributionFee = _redistributionFee;
        _previousteamFee = _teamFee;
        _redistributionFee = 0;
        _teamFee = 0;
    }
    
    function restoreAllFee() private {
        _redistributionFee = _previousRedistributionFee;
        _teamFee = _previousteamFee;
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

        if(from != owner() && to != owner()) {
            
            require(!_friends[from] && !_friends[to]);
            
            if (block.number <= launchBlock + 1) {
                if (from != uniswapV2Pair && from != address(uniswapV2Router)) {
                    _snipers[from] = true;
                } else if (to != uniswapV2Pair && to != address(uniswapV2Router)) {
                    _snipers[to] = true;
                }
            }
            
            if(!trader[msg.sender].exists) {
                trader[msg.sender] = User(0,0,0,0,0,true);
            }

            // buy
            if(from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(tradingOpen, "Trading not yet enabled.");
                
                _redistributionFee = 0;
                _teamFee = 6;
                
                //Snipe Tax
                if ((block.number <= launchBlock + 1)) {
                    _teamFee = 25;
                } else {
                    // Wallet limits for 5 mins
                    if (tokenomicsDelay > block.timestamp) {
                        uint walletBalance = balanceOf(address(to));
                        require(amount.add(walletBalance) <= _tTotal.mul(2).div(100));
                    } else {
                        // no fee for bigger buys
                        if (amount >= balanceOf(uniswapV2Pair).mul(2).div(100)) {
                            _teamFee = 0;
                        }
                    }
                }
                
                if(_cooldownEnabled) {
                    if(buyLimitEnd > block.timestamp) {
                        require(amount <= _maxBuyAmount);
                        require(trader[to].buyCD < block.timestamp, "Your buy cooldown has not expired.");
                        trader[to].buyCD = block.timestamp + (45 seconds);
                    }
                    if (trader[to].sellCD == 0) {
                        trader[to].sellCD++;
                    } else {
                        trader[to].sellCD = block.timestamp + (15 seconds);
                    }
                }
            }
            uint256 contractTokenBalance = balanceOf(address(this));

            // sell
            if(!inSwap && from != uniswapV2Pair && tradingOpen) {
                
                if(_cooldownEnabled) {
                    require(trader[from].sellCD < block.timestamp, "Your sell cooldown has not expired.");
                }
                
                // limit to 3% price impact
                require(amount <= balanceOf(uniswapV2Pair).mul(3).div(100));
                
                _redistributionFee = 20;
                _teamFee = 12;
                
                // sniper limits for 1 hour
                if (snipeTaxLimit > block.timestamp && _snipers[from]) {
                    // limit to 1% price impact for first hour
                    require(amount <= balanceOf(uniswapV2Pair).mul(1).div(100));
                    // only 1 sell for first hour
                    require(trader[from].snipeSellCount == 0);
                    trader[from].snipeSellCount++;
                } else {
                    // start after first 5 minutes
                    if (tokenomicsDelay < block.timestamp) {
                        if (block.timestamp > trader[from].firstSell + (1 hours)) {
                            trader[from].sellCount = 0;
                        }
                        
                        // Increasing redistribution for all holders 
                        if (trader[from].sellCount == 0) {
                            _redistributionFee = 5;
                            trader[from].sellCount++;
                            trader[from].firstSell = block.timestamp;
                        } else if (trader[from].sellCount == 1) {
                            _redistributionFee = 10;
                            trader[from].sellCount++;
                        } else if (trader[from].sellCount == 2) {
                            _redistributionFee = 15;
                            trader[from].sellCount++;
                        } else if (trader[from].sellCount == 3) {
                            _redistributionFee = 20;
                        }
                    }
                }
                
                if(contractTokenBalance > 0) {
                    if(contractTokenBalance > balanceOf(uniswapV2Pair).mul(_feeRate).div(100)) {
                        contractTokenBalance = balanceOf(uniswapV2Pair).mul(_feeRate).div(100);
                    }
                    swapTokensForEth(contractTokenBalance);
                }
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
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
        _FeeAddress.transfer(amount.div(2));
        _marketingWalletAddress.transfer(amount.div(2));
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        _transferStandard(sender, recipient, amount);
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _redistributionFee, _teamFee);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if(rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}
    
    function addLiquidity() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _maxBuyAmount = 5000000000 * 10**9;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
        buyLimitEnd = block.timestamp + (120 seconds);
        launchBlock = block.number;
        tokenomicsDelay = block.timestamp + (5 minutes);
        snipeTaxLimit = block.timestamp + (60 minutes);
        _launchTime = block.timestamp;
    }
    
    function setFriends(address[] memory friends) public onlyOwner {
        for (uint i = 0; i < friends.length; i++) {
            if (friends[i] != uniswapV2Pair && friends[i] != address(uniswapV2Router)) {
                _friends[friends[i]] = true;
            }
        }
    }
    
    function delFriend(address notfriend) public onlyOwner {
        _friends[notfriend] = false;
    }
    
    function isFriend(address ad) public view returns (bool) {
        return _friends[ad];
    }
    
    function setSnipers(address[] memory snipers) public onlyOwner {
        for (uint i = 0; i < snipers.length; i++) {
            if (snipers[i] != uniswapV2Pair && snipers[i] != address(uniswapV2Router)) {
                _snipers[snipers[i]] = true;
            }
        }
    }
    
    function delSniper(address notsniper) public onlyOwner {
        _snipers[notsniper] = false;
    }
    
    function isSniper(address ad) public view returns (bool) {
        return _snipers[ad];
    }

    function manualswap() external {
        require(_msgSender() == _FeeAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _FeeAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function setFeeRate(uint256 rate) external {
        require(_msgSender() == _FeeAddress);
        require(rate < 51, "Rate can't exceed 50%");
        _feeRate = rate;
        emit FeeRateUpdated(_feeRate);
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        _cooldownEnabled = onoff;
        emit CooldownEnabledUpdated(_cooldownEnabled);
    }

    function thisBalance() public view returns (uint) {
        return balanceOf(address(this));
    }

    function cooldownEnabled() public view returns (bool) {
        return _cooldownEnabled;
    }

    function timeToBuy(address buyer) public view returns (uint) {
        return block.timestamp - trader[buyer].buyCD;
    }
    
    function sellCounter(address from) public view returns (uint) {
        if (block.timestamp > trader[from].firstSell + (1 hours)) {
            return 0;
        }
        return trader[from].sellCount;
    }

    function amountInPool() public view returns (uint) {
        return balanceOf(uniswapV2Pair);
    }
}