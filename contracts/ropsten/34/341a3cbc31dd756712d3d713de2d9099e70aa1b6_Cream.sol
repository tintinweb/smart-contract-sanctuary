/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// SPDX-License-Identifier: Unlicensed

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

contract Cream is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e8 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    uint256 private _marketingFee = 10;
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 private _developmentFee = 5;
    uint256 private _previousDevelopmentFee = _developmentFee;
    uint256 private _liquidityFee = 10;
    uint256 private _previousLiquidityFee = _liquidityFee;
    address payable private _marketingWallet;
    address payable private _developmentWallet;
    
    string private constant _name = "Cream";
    string private constant _symbol = "TCE";
    uint8 private constant _decimals = 9;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    bool private marketHoursEnabled = false;
    bool private checkHolidays = false;
    bool private isSpecialEvent = false;
    uint256 private _maxTxAmount = _tTotal;
    uint256 private _maxWalletAmount = _tTotal;
    uint8 private _sunday = 0;
    uint8 private _saturday = 6;
    uint8 private _openingTimeHr = 14;
    uint8 private _closingTimeHr = 20;
    uint8 private _openingTimeMin = 30;

    struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
            }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;
    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;
    uint16 constant ORIGIN_YEAR = 1970;
    
    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () {
        _marketingWallet = payable(0x596145b224112401Dac592d3b88979ab4797385E);
        _developmentWallet = payable(0x9b57195C8D7544936785bdc3228C02a6fBa1A390);
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        _isExcludedFromFee[_developmentWallet] = true;
        emit Transfer(address(0x64c19A7582DA114524e0Fdf010f8032ba7f72172), _msgSender(), _tTotal);
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

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }

    function setMarketHoursEnabled(bool onoff) external onlyOwner() {
        marketHoursEnabled = onoff;
    }

    function setCheckHolidaysEnabled(bool onoff) external onlyOwner() {
        checkHolidays = onoff;
    }

    function setSpecialEvent(bool onoff) external onlyOwner() {
        isSpecialEvent = onoff;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
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
        bool takeFee = false;
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] && cooldownEnabled) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
                uint256 contractBalanceRecepient = balanceOf(to);
                require(contractBalanceRecepient + amount <= _maxWalletAmount, "Exceeds maximum wallet token amount.");
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (30 seconds);
            }
            
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !_isExcludedFromFee[from] && cooldownEnabled) {
                if (marketHoursEnabled) {
                    require(marketOpened(block.timestamp), "Market is closed.");
                }
                uint256 contractTokenBalance = balanceOf(address(this));
                if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                    swapTokensForEth(contractTokenBalance);
                    uint256 contractETHBalance = address(this).balance;
                    if(contractETHBalance > 0) {
                        sendETHToFee(address(this).balance);
                    }
                }
                takeFee = true;
            }

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
        _marketingWallet.transfer(amount.div(2));
        _developmentWallet.transfer(amount.div(2));
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        marketHoursEnabled = true;
        checkHolidays = true;
        _maxTxAmount = 5e5 * 10**9;
        _maxWalletAmount = 2e6 * 10**9;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
    
    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function removeStrictTxLimit() public onlyOwner {
        _maxTxAmount = 1e8 * 10**9;
    }

    function removeStrictWalletLimit() public onlyOwner {
         _maxWalletAmount = 1e8 * 10**9;
    }

    function setMaxTxAmount(uint256 maxTxn) public onlyOwner {
        _maxTxAmount = maxTxn;
    }
    
    function setMaxWalletAmount(uint256 maxToken) public onlyOwner {
        _maxWalletAmount = maxToken;
    }

    function setMarketingWallet(address marketingWallet) public onlyOwner() {
        _marketingWallet = payable(marketingWallet);
    }

    function setDevelopmentWallet(address developmentWallet) public onlyOwner() {
        _developmentWallet = payable(developmentWallet);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setMarketingFee(uint256 marketingFee) external onlyOwner() {
        _marketingFee = marketingFee;
    }
    
    function setDevelopmentFee(uint256 developmentFee) external onlyOwner() {
        _developmentFee = developmentFee;
    }
    
    function setLiquidityFee(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function removeAllFee() private {
        if(_marketingFee == 0 && _developmentFee == 0 && _liquidityFee == 0) return;
        
        _previousMarketingFee = _marketingFee;
        _previousDevelopmentFee = _developmentFee;
        _previousLiquidityFee = _liquidityFee;
        
        _marketingFee = 0;
        _developmentFee = 0;
        _liquidityFee = 0;
    }
    
    function restoreAllFee() private {
        _marketingFee = _previousMarketingFee;
        _developmentFee = _previousDevelopmentFee;
        _liquidityFee = _previousLiquidityFee;
    }
    
    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee) {
            removeAllFee();
        }
        
        _transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 rTeam = tTeam.mul(_getRate());
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 rLiquidity = tLiquidity.mul(_getRate());
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    }

    receive() external payable {}
    
    function manualswap() external {
        require(_msgSender() == _marketingWallet);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _marketingWallet);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
    

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam, uint256 tLiquidity) = _getTValues(tAmount, _marketingFee, _developmentFee, _liquidityFee);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam, tLiquidity);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee, uint256 liquidityFee) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(TeamFee).div(100);
        uint256 tLiquidity = tAmount.mul(liquidityFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount.sub(tLiquidity), tFee, tTeam, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function marketOpened(uint timestamp) public view returns (bool) {
        _DateTime memory dt = parseTimestamp(timestamp);
        if (dt.weekday == _sunday || dt.weekday == _saturday) {
            return false;
        }
        if (dt.hour < _openingTimeHr || dt.hour > _closingTimeHr) {
            return false;
        }
        if (dt.hour == _openingTimeHr && dt.minute < _openingTimeMin) {
            return false;
        }
        if (checkHolidays) {
            if (dt.month == 1 && (dt.day == 1 || dt.day == 18)) {
                return false;
            }
            if (dt.month == 2 && dt.day == 15) {
                return false;
            }
            if (dt.month == 4 && dt.day == 2) {
                return false;
            }
            if (dt.month == 5 && dt.day == 31) {
                return false;
            }
            if (dt.month == 7 && dt.day == 5) {
                return false;
            }
            if (dt.month == 9 && dt.day == 6) {
                return false;
            }
            if (dt.month == 11 && dt.day == 25) {
                return false;
            }
            if (dt.month == 12 && dt.day == 24) {
                return false;
            }
        }
        if (isSpecialEvent) {
            return false;
        }
        
        return true;
    }

        function isLeapYear(uint16 year) public pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) public pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

    function setSunday(uint8 sunday) external onlyOwner() {
        _sunday = sunday;
    }

    function setSaturday(uint8 saturday) external onlyOwner() {
        _saturday = saturday;
    }

    function setMarketOpeningTimeHr(uint8 openingTimeHr) external onlyOwner() {
        _openingTimeHr = openingTimeHr;
    }

    function setMarketClosingTimeHr(uint8 closingTimeHr) external onlyOwner() {
        _closingTimeHr = closingTimeHr;
    }

    function setMarketOpeningTimeMin(uint8 openingTimeMin) external onlyOwner() {
        _openingTimeMin = openingTimeMin;
    }
}