/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

//TEST CONTRACT FOR NUBS


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

contract SWE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
    mapping (address => bool) private testers;
    uint256 private constant _tTotal = 1e8 * 10**9;
    
    uint256 private _marketingFee = 3;
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 private _developmentFee = 2;
    uint256 private _previousDevelopmentFee = _developmentFee;
    uint256 private _liquidityFee = 1;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 private _foundationFee = 1;
    uint256 private _previousFoundationFee = _foundationFee;
    uint256 private _rewardFee = 1;
    uint256 private _previousRewardFee = _rewardFee;

    uint256 private tokensForProject;
    uint256 private tokensForDev;
    uint256 private tokensForLiquidity;

    address payable private _projectWallet;
    address payable private _developmentWallet;
    address payable private _liquidityWallet;
    
    string private constant _name = "SWE";
    string private constant _symbol = "SWE";
    uint8 private constant _decimals = 9;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private swapping;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    bool private marketHoursEnabled = false;
    bool private checkHolidays = false;
    bool private isSpecialEvent = false;
    uint256 private tradingActiveBlock = 0; // 0 means trading is not active
    uint256 private blocksToBlacklist = 1;
    uint256 private _maxBuyAmount = _tTotal;
    uint256 private _maxSellAmount = _tTotal;
    uint256 private _maxWalletAmount = _tTotal;
    uint256 private swapTokensAtAmount = 0;
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
    
    event MaxBuyAmountUpdated(uint _maxBuyAmount);
    event MaxSellAmountUpdated(uint _maxSellAmount);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyTesters() {
        require(testers[msg.sender] == true);
            _;
    }

    constructor () {
        _projectWallet = payable(0xF575Eb351257d89E3Fe95AB84b17f46790531d32);
        _developmentWallet = payable(0xF575Eb351257d89E3Fe95AB84b17f46790531d32);
        _liquidityWallet = payable(address(0xdead));
        _rOwned[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_projectWallet] = true;
        _isExcludedFromFee[_developmentWallet] = true;
        _isExcludedFromFee[_liquidityWallet] = true;
        emit Transfer(address(0xF575Eb351257d89E3Fe95AB84b17f46790531d32), _msgSender(), _tTotal);
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
        return _rOwned[account];
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

    function setCooldownEnabled(bool onoff) external onlyTesters() {
        cooldownEnabled = onoff;
    }

    function setMarketHoursEnabled(bool onoff) external onlyTesters() {
        marketHoursEnabled = onoff;
    }

    function setCheckHolidaysEnabled(bool onoff) external onlyTesters() {
        checkHolidays = onoff;
    }

    function setSpecialEvent(bool onoff) external onlyTesters() {
        isSpecialEvent = onoff;
    }

    function setSwapEnabled(bool onoff) external onlyTesters(){
        swapEnabled = onoff;
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
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
            require(!bots[from] && !bots[to]);

            if (marketHoursEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                require(marketOpened(block.timestamp), "Market is closed.");
            }

            takeFee = true;
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] && cooldownEnabled) {
                require(amount <= _maxBuyAmount, "Transfer amount exceeds the maxBuyAmount.");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Exceeds maximum wallet token amount.");
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (30 seconds);
            }
            
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !_isExcludedFromFee[from] && cooldownEnabled) {
                require(amount <= _maxSellAmount, "Transfer amount exceeds the maxSellAmount.");
                shouldSwap = true;
            }
        }

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = (contractTokenBalance > swapTokensAtAmount) && shouldSwap;

        if (canSwap && swapEnabled && !swapping && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForProject + tokensForDev;
        bool success;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        
        uint256 ethForMarketing = ethBalance.mul(tokensForProject).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(tokensForDev).div(totalTokensToSwap);
        
        
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev;
        
        
        tokensForLiquidity = 0;
        tokensForProject = 0;
        tokensForDev = 0;
        
        (success,) = address(_developmentWallet).call{value: ethForDev}("");
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
        
        
        (success,) = address(_projectWallet).call{value: address(this).balance}("");
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _liquidityWallet,
            block.timestamp
        );
    }
        
    function sendETHToFee(uint256 amount) private {
        _projectWallet.transfer(amount.div(2));
        _developmentWallet.transfer(amount.div(2));
    }

    function addTesters(address account) public onlyOwner() {
        testers[account] = true;
        _isExcludedFromFee[account] = true;
    }

    function removeTesters(address account) public onlyOwner() {
        testers[account] = true;
        _isExcludedFromFee[account] = false;
    }
    
    function openTrading() external onlyTesters() {
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
        _maxBuyAmount = 1e5 * 10**9;
        _maxSellAmount = 1e5 * 10**9;
        _maxWalletAmount = 3e5 * 10**9;
        swapTokensAtAmount = 5e4 * 10**9;
        tradingOpen = true;
        tradingActiveBlock = block.number;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
    
    function setBots(address[] memory bots_) public onlyTesters() {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function setMaxBuyAmount(uint256 maxBuy) public onlyTesters() {
        _maxBuyAmount = maxBuy;
    }

    function setMaxSellAmount(uint256 maxSell) public onlyTesters() {
        _maxSellAmount = maxSell;
    }
    
    function setMaxWalletAmount(uint256 maxToken) public onlyTesters() {
        _maxWalletAmount = maxToken;
    }
    
    function setSwapTokensAtAmount(uint256 newAmount) public onlyTesters() {
  	    require(newAmount >= 1e3 * 10**9, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= 5e6 * 10**9, "Swap amount cannot be higher than 0.5% total supply.");
  	    swapTokensAtAmount = newAmount;
  	}

    function setProjectWallet(address projectWallet) public onlyTesters() {
        require(projectWallet != address(0), "projectWallet address cannot be 0");
        _isExcludedFromFee[_projectWallet] = false;
        _projectWallet = payable(projectWallet);
        _isExcludedFromFee[_projectWallet] = true;
    }

    function setDevelopmentWallet(address developmentWallet) public onlyTesters() {
        require(developmentWallet != address(0), "developmentWallet address cannot be 0");
        _isExcludedFromFee[_developmentWallet] = false;
        _developmentWallet = payable(developmentWallet);
        _isExcludedFromFee[_developmentWallet] = true;
    }

    function setLiquidityWallet(address liquidityWallet) public onlyTesters() {
        require(liquidityWallet != address(0), "liquidityWallet address cannot be 0");
        _isExcludedFromFee[_liquidityWallet] = false;
        _liquidityWallet = payable(liquidityWallet);
        _isExcludedFromFee[_liquidityWallet] = true;
    }

    function excludeFromFee(address account) public onlyTesters() {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyTesters() {
        _isExcludedFromFee[account] = false;
    }
    
    function setMarketingFee(uint256 marketingFee) external onlyTesters() {
        require(marketingFee <= 10, "Marketing Fee must be less than 10%");
        _marketingFee = marketingFee;
    }
    
    function setDevelopmentFee(uint256 developmentFee) external onlyTesters() {
        require(developmentFee <= 10, "Development Fee must be less than 10%");
        _developmentFee = developmentFee;
    }
    
    function setLiquidityFee(uint256 liquidityFee) external onlyTesters() {
        require(liquidityFee <= 10, "Liquidity Fee must be less than 10%");
        _liquidityFee = liquidityFee;
    }
    
    function setFoundationFee(uint256 foundationFee) external onlyTesters() {
        require(foundationFee <= 10, "Foundation Fee must be less than 10%");
        _foundationFee = foundationFee;
    }
    
    function setRewardFee(uint256 rewardFee) external onlyTesters() {
        require(rewardFee <= 10, "Reward Fee must be less than 10%");
        _rewardFee = rewardFee;
    }

    function setBlocksToBlacklist(uint256 blocks) public onlyTesters() {
        blocksToBlacklist = blocks;
    }

    function removeAllFee() private {
        if(_marketingFee == 0 && _developmentFee == 0 && _liquidityFee == 0 && _foundationFee == 0 && _rewardFee == 0) return;
        
        _previousMarketingFee = _marketingFee;
        _previousDevelopmentFee = _developmentFee;
        _previousLiquidityFee = _liquidityFee;
        _previousFoundationFee = _foundationFee;
        _previousRewardFee = _rewardFee;
        
        _marketingFee = 0;
        _developmentFee = 0;
        _liquidityFee = 0;
        _foundationFee = 0;
        _rewardFee = 0;
    }
    
    function restoreAllFee() private {
        _marketingFee = _previousMarketingFee;
        _developmentFee = _previousDevelopmentFee;
        _liquidityFee = _previousLiquidityFee;
        _foundationFee = _previousFoundationFee;
        _rewardFee = _previousRewardFee;
    }
    
    function delBot(address notbot) public onlyTesters() {
        bots[notbot] = false;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee) {
            removeAllFee();
        } else {
            amount = _takeFees(sender, amount);
        }

        _transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _takeFees(address sender, uint256 amount) private returns (uint256) {
        uint256 _totalFees;
        uint256 liqFee;
        if(tradingActiveBlock + blocksToBlacklist >= block.number){
            _totalFees = 99;
            liqFee = 92;
        } else {
            _totalFees = _getTotalFees();
            liqFee = _liquidityFee;
        }

        uint256 fees = amount.mul(_totalFees).div(100);
        tokensForProject += fees * (_marketingFee + _rewardFee + _foundationFee) / _totalFees;
        tokensForDev += fees * _developmentFee / _totalFees;
        tokensForLiquidity += fees * liqFee / _totalFees;
            
        if(fees > 0) {
            _transferStandard(sender, address(this), fees);
        }
        	
        return amount -= fees;
    }

    receive() external payable {}
    
    function manualswap() external {
        require(_msgSender() == _projectWallet);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _projectWallet);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function withdrawStuckETH() external onlyTesters() {
        require(!tradingOpen, "Can only withdraw if trading hasn't started");
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function _getTotalFees() private view returns(uint256) {
        return _marketingFee + _developmentFee + _liquidityFee + _foundationFee + _rewardFee;
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