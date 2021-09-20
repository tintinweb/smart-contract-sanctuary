/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-9-20
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.0;

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract MyCoinToken is Ownable {
    using SafeMath for uint;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    mapping(address => bool) public adminAddress;
    mapping(string => mapping(address => bool)) public daySellRecords;
    mapping(string => mapping(address => bool)) public dayBounsReceiveRecords;
    mapping(string => uint256) public dayPoolBouns;
    mapping(string => uint256) public dayPoolBounsPiece;
    mapping(string => mapping(address => uint256)) public todayBuyToken;

    address private termAddress = 0xFB268aB63357D5ea4EbB343DA876832dfa5f55C0;

    uint256 _burnFee = 1;
    uint256 _termFee = 1;
    uint256 _bounsFee = 6;

    uint256 public totalBurn;
    uint256 eachPiece = 1680 * 10 ** uint256(decimals());
    uint256 minBounsJoin = eachPiece;
    
    uint256 tTotal = 1680000 * 10 ** uint256(decimals());
    uint256 public bounsTime = 1625068800;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address routeAddress) public {
        _name = "中秋月饼";
        _symbol = "ZQYB";
        _mint(_msgSender(), tTotal);

        adminAddress[_msgSender()] = true;
        adminAddress[termAddress] = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routeAddress);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 9;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender,address recipient,uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function setAdminAddress(address account, bool ok) public onlyOwner returns(bool){
        adminAddress[account] = ok;
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        if(adminAddress[sender] || adminAddress[recipient]){
            _standerTransfer(sender, recipient, amount);
            return;
        }
        
        //only use at remove liquidity
        if(sender == uniswapV2Pair && recipient == address(uniswapV2Router)){
            _standerTransfer(sender, recipient, amount);
            return;
        }
        _userTransfer(sender, recipient, amount);
    }

    function _standerTransfer(address sender, address recipient, uint256 amount) private {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] =  _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _userTransfer(address sender, address recipient, uint256 amount) private {
        uint256 _burnToken = amount.mul(_burnFee).div(100);
        totalBurn = totalBurn.add(_burnToken);

        uint256 _termToken = amount.mul(_termFee).div(100);
        _balances[termAddress] = _balances[termAddress].add(_termToken);

        uint256 _bounsToken = amount.mul(_bounsFee).div(100);
        _balances[address(this)] = _balances[address(this)].add(_bounsToken);
        emit Transfer(sender, termAddress, _termToken);
        emit Transfer(sender, address(0), _burnToken);
        emit Transfer(sender, address(this), _bounsToken);

        //sell token
        if(sender != address(this) && recipient == uniswapV2Pair){
            _setSellRecords(sender, 0);
        }

        //transfer between tow account
        if((sender != address(this) && sender != uniswapV2Pair) && (recipient != address(this) && recipient != uniswapV2Pair)){
            _setSellRecords(sender, 0);
        }

        uint256 realAmount = amount.sub(_burnToken).sub(_termToken).sub(_bounsToken);
        if(sender == owner() || sender == uniswapV2Pair){
            _setTodayBuyToken(recipient, realAmount);
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(realAmount);
        emit Transfer(sender, recipient, realAmount);
    }

    function _setSellRecords(address account, uint256 timestamp) internal {
        if(timestamp == 0){
            timestamp = getTime();
        }
        string memory nowDate = getNowDate(timestamp);
        if(daySellRecords[nowDate][account] == false){
            daySellRecords[nowDate][account] = true;
        }
    }

    function _setTodayBuyToken(address account, uint256 token) internal {
        string memory nowDate = getNowDate(getTime());
        todayBuyToken[nowDate][account] = todayBuyToken[nowDate][account].add(token);
    }

    function _getMarketTotalToken() public view returns(uint256){
        return _totalSupply
        .sub(_balances[termAddress])
        .sub(totalBurn)
        .sub(_balances[owner()])
        .sub(_balances[uniswapV2Pair]);
    }

    function getDays() public view returns(string memory, string memory){
        uint256 step = 86400;
        string memory yesToday = getNowDate(getTime() - step);
        string memory twoYesToday = getNowDate(getTime() - step.mul(2));
        return (yesToday, twoYesToday);
    }

    //cut half to the bouns pool
    function _sumTheBounsPool(string memory yesToday, string memory twoYesToday) internal returns(uint256){
        if(dayPoolBouns[yesToday] == 0){
            dayPoolBouns[yesToday] = _balances[address(this)].div(2);
            _balances[address(this)] = _balances[address(this)].sub(dayPoolBouns[yesToday]);
            dayPoolBouns[yesToday] = dayPoolBouns[yesToday].add(dayPoolBouns[twoYesToday]);
            dayPoolBouns[twoYesToday] = 0;
        }
        return dayPoolBouns[yesToday];
    }

    // sum the each piece can get the bouns token
    function _sumBounsPiece(string memory yesToday) internal {
        if(dayPoolBounsPiece[yesToday] == 0){
            uint256 marketTotalToken = _getMarketTotalToken();//marketToken
            dayPoolBounsPiece[yesToday] = dayPoolBouns[yesToday].mul(10**uint256(decimals())).div(marketTotalToken).mul(eachPiece).div(10**uint256(decimals()));
        }
    }
    
    function sumBounsPiece(string memory yesToday, uint256 num) public onlyOwner returns(bool){
        dayPoolBounsPiece[yesToday] = num * 10 ** uint256(decimals());
    }
    
    function sumTheBounsPool(string memory yesToday, string memory twoYesToday) public onlyOwner{
        dayPoolBouns[yesToday] = _balances[address(this)].div(2);
        _balances[address(this)] = _balances[address(this)].sub(dayPoolBouns[yesToday]);
        dayPoolBouns[yesToday] = dayPoolBouns[yesToday].add(dayPoolBouns[twoYesToday]);
        dayPoolBouns[twoYesToday] = 0;
    }

    function _sumCanGetToken(string memory yesToday, uint256 balancePiece) internal returns(uint256) {
        uint256 _yesTodayToken = dayPoolBounsPiece[yesToday].mul(balancePiece);
        dayPoolBouns[yesToday] = dayPoolBouns[yesToday].sub(_yesTodayToken);
        return _yesTodayToken;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    //account get the token at the website
    function receiveBounsToken() external returns(uint256){
        require(bounsTime > 0 && getTime() >= bounsTime, "not the time to receiveBounsToken");
        
        address sender = _msgSender();
        require(balanceOf(sender) >= minBounsJoin, "holder token less than 1kw");

        (string memory yesToday,string memory twoYesToday) = getDays();
        string memory nowDate = getNowDate(getTime());

        //check is has receive
        require(dayBounsReceiveRecords[nowDate][sender]==false, "you has receive today");

        //check if has sell action
        require(daySellRecords[yesToday][sender]==false, "you sell or Transfer yestoday");
        require(daySellRecords[nowDate][sender]==false, "you sell or Transfer today");

        //cut half current bouns pool to the day pool
        _sumTheBounsPool(yesToday, twoYesToday);

        //sum the piece
        _sumBounsPiece(yesToday);

        uint256 yesTodayBalance = balanceOf(sender).sub(todayBuyToken[nowDate][sender]);
        require(yesTodayBalance >= minBounsJoin, "yesToday balance less than minBounsJoin");
        uint256 balancePiece = yesTodayBalance.div(eachPiece);

        uint256 canGetToken = _sumCanGetToken(yesToday, balancePiece);
        _balances[sender] = _balances[sender].add(canGetToken);
        dayBounsReceiveRecords[nowDate][sender] = true;
        emit Transfer(address(this), sender, canGetToken);
        return canGetToken;
    }

    function webShowCanGetToken() public view returns(uint256,uint256,uint256,uint256){
        address sender = _msgSender();
        (string memory yesToday, string memory twoYesToday) = getDays();
        string memory nowDate = getNowDate(getTime());

        uint256 yesTodayPoolBouns = dayPoolBouns[yesToday];
        if(yesTodayPoolBouns == 0){
            yesTodayPoolBouns = _balances[address(this)].div(2);
            yesTodayPoolBouns = yesTodayPoolBouns.add(dayPoolBouns[twoYesToday]);
        }

        uint256 yesTodayPoolPiece = dayPoolBounsPiece[yesToday];
        //sum the piece
        if(yesTodayPoolPiece == 0){
            uint256 marketTotalToken = _getMarketTotalToken();//marketToken
            if(marketTotalToken > 0){
                yesTodayPoolPiece = yesTodayPoolBouns.mul(10**uint256(decimals())).div(marketTotalToken).mul(eachPiece).div(10**uint256(decimals()));
            }
        }

        //check if has receive
        if(dayBounsReceiveRecords[nowDate][sender]){
            return (5, 0, yesTodayPoolBouns, yesTodayPoolPiece);
        }

        uint256 yesTodayBalance = balanceOf(sender).sub(todayBuyToken[nowDate][sender]);
        if(yesTodayBalance < minBounsJoin){
            return (1, 0, yesTodayPoolBouns, yesTodayPoolPiece);//balance < minBounsJoin
        }

        uint256 balancePiece = yesTodayBalance.div(eachPiece);
        //check yestoday if has sell or transfer action
        if(daySellRecords[yesToday][sender]){
            return (2, 0, yesTodayPoolBouns, yesTodayPoolPiece);
        }

        //check today if has sell or transfer action
        if(daySellRecords[nowDate][sender]){
            return (3, 0, yesTodayPoolBouns, yesTodayPoolPiece);
        }
        return (4, yesTodayPoolPiece.mul(balancePiece), yesTodayPoolBouns, yesTodayPoolPiece);
    }
    
    function setBounsTime(uint256 timestamp) public onlyOwner{
        bounsTime = timestamp;
    }

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

    function isLeapYear(uint16 year) internal pure returns (bool) {
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

    function leapYearsBefore(uint year) internal pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
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
            }else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
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

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function getNowDate(uint256 timestamp) public pure returns(string memory){
        uint256 year = getYear(timestamp);
        _DateTime memory dt = parseTimestamp(timestamp);

        string memory monthStr = toString(uint(dt.month));
        if(dt.month <= 9){
            monthStr = strConcat("0", monthStr);
        }

        string memory dayStr = toString(uint(dt.day));
        if(dt.day <= 9){
            dayStr = strConcat("0", dayStr);
        }
        return strConcat(toString(year), monthStr, dayStr);
    }

    function getTime() public view returns(uint256){
        return now;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}