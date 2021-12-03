//"SPDX-License-Identifier: MIT"

pragma solidity ^0.8.4;


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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library DateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        uint year;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        uint year;
        uint month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        //require(fromTimestamp <= toTimestamp);
        if (fromTimestamp <= toTimestamp) _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
        else _hours = 0;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        //require(fromTimestamp <= toTimestamp);
        if (fromTimestamp <= toTimestamp) _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
        else _minutes = 0;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        //require(fromTimestamp <= toTimestamp);
        if (fromTimestamp <= toTimestamp) _seconds = toTimestamp - fromTimestamp;
        else _seconds = 0;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        // The account hash of 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned for non-contract addresses,
        // so-called Externally Owned Account (EOA)
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
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

contract TokenNew is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using DateTimeLibrary for uint;

    string private _name = "TokenNew";
    string private _symbol = "TKNN";
    uint8 private _decimals = 9;

    struct tokenHolders {
        address addresses;
        uint256 valuesBefore;
        uint256 valuesAfterGross;
        uint256 valuesAfterNet;
        uint256 amountToTrasfer;
        uint256 valuesReflections;
        uint256 valuesReflectionsAccumulated;
        bool inserted;
        bool updated;
        uint lastSellTransferTime;
        uint claimTime;
        uint256 NFTPercentageMax;
    }
    mapping (address => tokenHolders) private _tokenHoldersList;
    address[] private _tokenHoldersAccounts;

    mapping (address => uint256) private _reflectionBalance;
    mapping (address => uint256) private _tokenBalance;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tokenTotal = 100_000_000_000e9; // TOTAL AMOUNT : 100.000.000.000 tokens
    uint256 private _reflectionTotal = (MAX - (MAX % _tokenTotal));
    uint256 private _tokenCirculatingTotal = 100_000_000_000e9; // totale crcolante espresso come somma dei balance degli holders esclusi i token in liquidity
    uint256 private _tokenNoSellTotal = 100_000_000_000e9; // totale dei token posseduti da holders che non hanno mai venduto

    mapping(address => bool) private _blacklist; // non può usare più la funzione _transfer quindi non può ne vendere ne comprare
    mapping(address => uint) private _lockedlist; // non può usare più la funzione _transfer quindi non può ne vendere ne comprare questo accade quando il balance supera il BalanceOfMax permesso
    // quando _lockedlisted = 1 sono indirizzi considerati bloccati perchè hanno superato il 3% del total amount
    // quando _lockedlisted = 2 sono indirizzi esclusi dal controllo
    // quando _lockedlisted != 1 o 2  sono indirizzi non ancora mappati
    mapping (address => bool) private _isExcludedFromTaxFee;
    mapping (address => bool) private _isExcludedFromForBuyFee;
    mapping (address => bool) private _isExcludedFromAntiSellFee;
    mapping (address => bool) private _isExcludedFromReward; // esclusione dal reward
    address[] private _excludedFromReward;
    //address[] private _tokenHolders;
    uint256 _refrectionsToContract;

    bool private _autoMode = false; // allo start disattiva il calcolo della Anti Sell fee tramite Oracolo
    uint256 private _antiSellFeeFromOracle = 3; // variable% taxation in BNB to avoid Sells
    uint256 private _previousAntiSellFeeFromOracle = _antiSellFeeFromOracle;

    uint256 private _taxFee = 1; // 5% redistribuition
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _forBuyFee = 2; // 5% forBuy fee divisa tra NFT Fee pari al 2% e Marketing Fee pari al 3%
    uint256 private _previousForBuyFee = _forBuyFee;

    uint256 private _taxfeeTotal;
    uint256 private _buybackTotal;

    bool private _tradingIsEnabled = true;
    bool private _isDistribuitionInWethEnabled = true;
    bool private _inSwapAndLiquify;

    uint256 private _maxTxAmount = 200_000_000e9; // Max transferrable in one transaction (0,2% of _tokenTotal)
    uint256 private _minTokensBeforeSwap = 200_000e9; // una volta accumulati questi token li bende e fa lo swap
    uint256 private _balanceOfMaxPermitted = 3_000_000_000e9; // massimo permesso nell'account di un holder, superato il quale viene posto in Locked List (3% del total amount)
    // trasformandoli in BNB mandandoli nel wallet buyBack, dovrebbe causare un crollo dello 0,04% della curva del prezzo

    address private _antiDipAddress = 0x813491240Bca4b20dbd9AB21f99eb2DccE2a6f3E; ///
    address private _marketingAddress = 0x346d2feeD83B3bfe7c3C9887991edDfEaFf81B53; ///
    address private _forBuyAddress = address(this); // For Buy address -  usa il contratto stesso come wallet per raccogliere queste fee
    address private _antiSellAddress = address(this); // Anti Sell address -  usa il contratto stesso come wallet per raccogliere queste fee
    address private _gameDevAddress = 0xDf430DA77C2cc6eB9EeF2dc77F794040042a73be; //

    uint256 private _marketingWalletPercent = 16;
    uint256 private _nftWalletPercent = 8;
    uint256 private _antiDipToReflectToHoldersWalletPercent = 15;
    uint256 private _taxFeeWalletPercent = 16;
    uint256 private _gameDevWalletPercent = 15;
    uint256 private _antiDipWalletPercent = 30;

    // tempo di elaborazione medio di un blocco su BSC = 3 secondi
    uint private _periodTime_1m = 60; // 1 minuto = 20 blocchi
    uint private _periodTime_5m = 300; // 5 minuti = 100 blocchi
    uint private _periodTime_15m = 900; // 15 minuti = 300 blocchi
    uint private _periodTime_30m = 1800; // 30 minut1 = 600 blocchi
    uint private _periodTime_1h = 3600; // 1 ora = 1.200 blocchi
    uint private _periodTime_2h = 7200; // 2 ore = 2.400 blocchi
    uint private _periodTime_4h = 14400; // 4 ore = 4.800 blocchi
    uint private _periodTime_6h = 21600; // 6 ore = 7.200 blocchi
    uint private _periodTime_12h = 43200; // 12 ore = 14.400 blocchi
    uint private _periodTime_1d = 86400; // 1 giorno = 28.800 blocchi
    uint private _periodTime_1W = 604800; // 1 settimana = 201.600 blocchi
    uint private _periodTime_1M = 2592000; // 1 mese = 864.000 blocchi
    uint private _periodTime_3M = 7776000; // 3 mesi = 2.592.000 blocchi
    uint private _periodTime_6M = 15552000; // 6 mesi = 5.184.000 blocchi
    uint private _periodTime_1Y = 31104000; // 1 anno = 10.368.000 blocchi

    uint private _epoch_1 = _periodTime_30m; // periodo di distribuzione reward in WETH a holders normali e wallet team
    uint private _epoch_2 = _periodTime_4h; // periodo di distribuzione reward in WETH a holders che non hanno mai venduto
    uint private _epochClaimNft = _periodTime_1W; // tempo che passa dal listing al momento in cui sdi potrà fare il claim NFT

    uint private _nextDistributionTime_1; // orario di start della prossima distribuzione 1
    uint private _nextDistributionTime_2; // orario di start della prossima distribuzione 2
    uint private _claimNftDistributionTime; // orario di start per la distribuzione del claim NFT dopo il listing

    uint256 private _balanceNeededClaim;

    bool private _antiBotMode = false;
    bool private _lockedListMode = false;
    uint256 private _maxGWeiPermitted = 8000000000; // 8 GWei
    mapping(address => bool) private _botUser;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    ///////////// Token's contract addressess BSC Mainnet///////////////////
    // address public constant ETH_BinanceToken = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    // address public constant USDC_BinanceToken = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    // address public constant BUSD_BinanceToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    // address public constant Cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    // address public constant USDT_BinanceToken = 0x55d398326f99059fF775485246999027B3197955;

    ///////////// Token's contract addressess BSC Testnet ///////////////////
    //address public constant ETH_BinanceToken = 0x8babbb98678facc7342735486c851abd7a0d17ca;
    address public constant BUSD_BinanceToken = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    //address public constant USDT_BinanceToken = 0x7ef95a0fee0dd31b22626fa2e10ee6a223f8a684;


    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived, uint256 tokensIntoLiqudity);
    event antiBotActivated(address bot, uint256 gWeiPaid);
    event UserLocked(address useraddress, uint256 balance);

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor ()  {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // Pancake Router Testnet
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Pancake Router Mainnet
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _reflectionBalance[_msgSender()] = _reflectionTotal;

        // inerisce l'owner tra gli holders
        _tokenHoldersList[_msgSender()].inserted = true;
        _tokenHoldersList[_msgSender()].updated = true;
        _tokenHoldersList[_msgSender()].valuesBefore = _tokenTotal;
        _tokenHoldersList[_msgSender()].valuesAfterGross = _tokenTotal;
        _tokenHoldersList[_msgSender()].valuesAfterNet = _tokenTotal;
        _tokenHoldersList[_msgSender()].amountToTrasfer = 0;
        _tokenHoldersList[_msgSender()].valuesReflections = 0;
        _tokenHoldersList[_msgSender()].valuesReflectionsAccumulated = 0;
        _tokenHoldersList[_msgSender()].lastSellTransferTime = 0;
        _tokenHoldersList[_msgSender()].claimTime = 0;
        _tokenHoldersAccounts.push(_msgSender());

        // inerisce address(this), cioè il contratto, tra gli holders
        _tokenHoldersList[address(this)].inserted = true;
        _tokenHoldersList[address(this)].updated = true;
        _tokenHoldersList[address(this)].valuesBefore = 0;
        _tokenHoldersList[address(this)].valuesAfterGross = 0;
        _tokenHoldersList[address(this)].valuesAfterNet = 0;
        _tokenHoldersList[address(this)].amountToTrasfer = 0;
        _tokenHoldersList[address(this)].valuesReflections = 0;
        _tokenHoldersList[address(this)].valuesReflectionsAccumulated = 0;
        _tokenHoldersList[address(this)].lastSellTransferTime = 0;
        _tokenHoldersList[address(this)].claimTime = 0;
        _tokenHoldersAccounts.push(address(this));

        //exclude owner, this contract and uniswapV2Pair from locked list accounts
        // quando _lockedlisted = 1 sono indirizzi considerati bloccati perchè hanno superato il 3% del total amount
        // quando _lockedlisted = 2 sono indirizzi esclusi dal controllo
        // quando _lockedlisted != 1 o 2  sono indirizzi non ancora mappati
        _lockedlist[owner()] = 2;
        _lockedlist[address(this)] = 2;
        _lockedlist[uniswapV2Pair] = 2;

        //exclude owner and this contract from taxFee
        _isExcludedFromTaxFee[owner()] = true;
        _isExcludedFromTaxFee[address(this)] = true;

        //_isExcludedFromTaxFee[_forBuyAddress] = true;
        //_isExcludedFromTaxFee[_antiSellAddress] = true;

        //exclude owner and this contract from forBuyFee
        _isExcludedFromForBuyFee[owner()] = true;
        _isExcludedFromForBuyFee[address(this)] = true;
        //_isExcludedFromForBuyFee[_forBuyAddress] = true;
        //_isExcludedFromForBuyFee[_antiSellAddress] = true;

        //exclude owner and this contract from Anti Sell fee
        _isExcludedFromAntiSellFee[owner()] = true;
        _isExcludedFromAntiSellFee[address(this)] = true;
        //_isExcludedFromAntiSellFee[_forBuyAddress] = true;
        //_isExcludedFromAntiSellFee[_antiSellAddress] = true;

        //exclude il pair uniswap dal reward
        _isExcludedFromReward[uniswapV2Pair] = true;
        _excludedFromReward.push(uniswapV2Pair);

        emit Transfer(address(0), _msgSender(), _tokenTotal);
    }

    function mint(address _account, uint256 _amount) public onlyOwner returns (bool) {
        require(_account != address(0), "BEP20: mint to the zero address");
        _tokenTotal = _tokenTotal.add(_amount);
         if (_isExcludedFromReward[_account]) {
           _tokenBalance[_account].add(_amount);
         }
         else
         {
            _reflectionBalance[_account].add(_amount);
         }
        emit Transfer(address(0), _account, _amount);
        return true;
    }

    function burn(address _account, uint256 _amount) public onlyOwner returns (bool) {
        require(_account != address(0), "BEP20: burn from the zero address");
        require(_tokenTotal >= _amount, "BEP20: total supply must be >= amout");
        _tokenTotal = _tokenTotal.sub(_amount);
         if (_isExcludedFromReward[_account]) {
              require(_tokenBalance[_account] >= _amount, "BEP20: the balance of account must be >= of amount");
             _tokenBalance[_account].sub(_amount);
         }
         else
         {
              require(_reflectionBalance[_account] >= _amount, "BEP20: the balance of account must be >= of amount");
             _reflectionBalance[_account].sub(_amount);
         }
        emit Transfer(_account, address(0), _amount);
        return true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function get_AntiDipAddress() external view returns (address) {
        return _antiDipAddress;
    }

    function get_MarketingAddress() external view returns (address) {
        return _marketingAddress;
    }

    function get_ContractAddress() external view returns (address) {
        return address(this);
    }

    function get_TaxFee() external view returns (uint256) {
        return _taxFee;
    }

    function get_ForBuyFee() external view returns (uint256) {
        return _forBuyFee;
    }

    function totalSupply() public view override returns (uint256) {
        return _tokenTotal;
    }

    function get_maxTXAmountPerTransfer() external view returns (uint256) {
        return _maxTxAmount;
    }

    function get_AntiSellAutoFromOracle() external view returns (bool) {
        return _autoMode;
    }

    function get_antiSellFeeFromOracle() external view returns (uint256) {
        return _antiSellFeeFromOracle;
    }

    function set_antiSellFeeFromOracle(uint256 antiSellFeeFromOracle) external onlyOwner returns (uint256) {
        _antiSellFeeFromOracle = antiSellFeeFromOracle;
        return _antiSellFeeFromOracle;
    }

    function get_marketingWalletPercent() external view returns (uint256) {
        return _marketingWalletPercent;
    }

    function get_nftWalletPercent() external view returns (uint256) {
        return _nftWalletPercent;
    }

    function get_antiDipToReflectToHoldersWalletPercent() external view returns (uint256) {
        return _antiDipToReflectToHoldersWalletPercent;
    }

    function get_taxFeeWalletPercent() external view returns (uint256) {
        return _taxFeeWalletPercent;
    }

    function get_antiDipWalletPercent() external view returns (uint256) {
        return _antiDipWalletPercent;
    }

    function get_gameDevWalletPercent() external view returns (uint256) {
        return _gameDevWalletPercent;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function set_PresaleParameters (
      uint256 _MaxTXPerThousand,
      //address payable _newForBuyAddress,
      //address payable _newAntiSellAddress,
      address payable _newAntiDipAddress,
      address payable _newMarketingAddress,
      address payable _newGameDevAddress,
      bool _antiSellAutoFromOracle

    ) external onlyOwner {
        removeTaxFee();
        removeForBuyFee();
        removeAntiSellFee();
        set_AntiSellAutoFromOracle(_antiSellAutoFromOracle); // settare a false
        set_MaxTxPerThousand(_MaxTXPerThousand); // settare a 1000
        set_TradingIsEnabled(false);
        set_DistribuitionInWethEnabled(false);
        changeAntiDipAddress(_newAntiDipAddress);
        changeMarketingAddress(_newMarketingAddress);
        changeGameDevAddress(_newGameDevAddress);
        set_LockedListMode(false);
    }

    function set_PancakeSwapParameters1 (
      uint256 _MaxTXPerThousand,
      bool _antiSellAutoFromOracle,
      bool _enableTrading,
      bool _enableDistribuitionInWeth,
      uint256 _marketingWalletPerc,
      uint256 _nftWalletPerc,
      uint256 _antiDipToReflectToHoldersWalletPerc

    ) external onlyOwner {
        restoreTaxFee();
        restoreForBuyFee();
        restoreAntiSellFee();
        set_AntiSellAutoFromOracle(_antiSellAutoFromOracle); // settare a true
        set_MaxTxPerThousand(_MaxTXPerThousand); // settare a 2
        set_TradingIsEnabled(_enableTrading); // mettere a true se si vuole permettere il trading da subito
        set_DistribuitionInWethEnabled(_enableDistribuitionInWeth); // mettere a true se si vuole swappare ed inviare reflections
        changeMarketingWalletPercent(_marketingWalletPerc); // impostare a 16 per avere 16% del contenuto del wallet antidip
        changeNftWalletPercent(_nftWalletPerc); // impostare a 8 per avere 8% del contenuto del wallet antidip
        changeAntiDipToReflectToHoldersWalletPercent(_antiDipToReflectToHoldersWalletPerc); // impostare a 15 per avere 15% del contenuto del wallet antidip
    }

    function set_PancakeSwapParameters2 (
      uint256 _taxFeeWalletPerc,
      uint256 _antiDipWalletPerc,
      uint256 _gameDevWalletPerc,
      uint epochPeriod1,
      uint epochPeriod2,
      uint epochClaimNftPeriod

    ) external onlyOwner {
        changeTaxFeeWalletPercent(_taxFeeWalletPerc); // impostare a 16 per avere 16% del contenuto del wallet antidip
        changeAntiDipWalletPercent(_antiDipWalletPerc); // impostare a 30 per avere 30% del contenuto del wallet antidip
        changeGameDevWalletPercent(_gameDevWalletPerc); // impostare a 15 per avere 15% del contenuto del wallet antidip
        set_AntiBot(true);
        set_Epoch(1,epochPeriod1);
        set_Epoch(2,epochPeriod2);
        set_EpochClaimNft(epochClaimNftPeriod);
        set_NextDistributionTime(1);
        set_NextDistributionTime(2);
        set_ClaimNftDistributionTime();
        set_LockedListMode(true);
    }

    function randomNumber() public view returns(uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) /
                    (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                    (block.timestamp)) + block.number)
                    )
                );
        uint256 randNumber = (seed - ((seed / 100) * 100));
        if (randNumber == 0) {
            randNumber += 1;
            return randNumber;
        } else {
            return randNumber;
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BNB20: transfer amount exceeds allowance"));
        _transfer2(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BNB20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function calculateTotalTaxFee() external view returns (uint256) {
        return _taxfeeTotal;
    }

    function calculateTotalBuyBack() external view returns (uint256) {
        return _buybackTotal;
    }

    function tokenFromReflection(uint256 reflectionAmount) public view returns(uint256) {
        require(reflectionAmount <= _reflectionTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return reflectionAmount.div(currentRate);
    }

    function reflectionFromToken(uint256 tokenAmount) public view returns(uint256) {
        require(tokenAmount <= _tokenTotal, "Amount must be less than supply");
        uint256 currentRate =  _getRate();
        return tokenAmount.mul(currentRate);
    }

    function excludeFromReward(address account) external onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(_reflectionBalance[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromReward[account], "Account is already excluded");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _tokenBalance[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }

    function excludeFromTaxFee(address account) external onlyOwner {
        _isExcludedFromTaxFee[account] = true;
    }

    function includeInTaxFee (address account) external onlyOwner {
        _isExcludedFromTaxFee[account] = false;
    }

    function excludeFromForBuyFee(address account) external onlyOwner {
        _isExcludedFromForBuyFee[account] = true;
    }

    function includeInForBuyFee (address account) external onlyOwner {
        _isExcludedFromForBuyFee[account] = false;
    }

    function excludeFromAntiSellFee(address account) external onlyOwner {
        _isExcludedFromAntiSellFee[account] = true;
    }

    function includeInAntiSellFee(address account) external onlyOwner {
        _isExcludedFromAntiSellFee[account] = false;
    }

    function set_BlackList(address account, bool value) public onlyOwner {
        _blacklist[account] = value;
    }

    function get_BlackList(address account) public view returns (bool) {
        return _blacklist[account];
    }

    function set_BotUser(address account, bool value) public onlyOwner {
        _botUser[account] = value;
    }

    function get_BotUser(address account) public view returns (bool) {
        return _botUser[account];
    }

    function set_LockedListValue(address account, uint value) public onlyOwner {
        _lockedlist[account] = value;
    }

    function get_LockedListValue(address account) public view returns (uint) {
        return _lockedlist[account];
    }

    function set_FeePercent(uint256 taxFee, uint256 forBuyFee) public onlyOwner {
        _taxFee = taxFee;
        _forBuyFee = forBuyFee;
    }

    function set_AntiSellAutoFromOracle(bool autoMode) public onlyOwner {
        _autoMode = autoMode;
    }

    function set_AntiBot(bool antiBotMode) public onlyOwner {
        _antiBotMode = antiBotMode;
    }

    function get_AntiBot() external view returns (bool) {
        return _antiBotMode;
    }

    function set_LockedListMode(bool lockedListMode) public onlyOwner {
        _lockedListMode = lockedListMode;
    }

    function get_LockedListMode() external view returns (bool) {
        return _lockedListMode;
    }

    function set_MaxGWeiPermitted(uint256 maxGWeiPermitted) public onlyOwner {
        _maxGWeiPermitted = maxGWeiPermitted;
    }

    function get_MaxGWeiPermitted() external view returns (uint256) {
        return _maxGWeiPermitted;
    }

    function set_MaxTxPerThousand(uint256 maxTxThousand) public onlyOwner { // expressed in per thousand and not in percent
        _maxTxAmount = _tokenTotal.mul(maxTxThousand).div(10**3);
    }

    function get_Epoch(uint set) public view returns (uint) {
        // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
        // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
        if (set == 1) return _epoch_1;
        else if (set == 2) return _epoch_2;
        else return 0;
    }

    function set_Epoch(uint set, uint epochPeriod) public onlyOwner returns (bool) {
        // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
        // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
        if (set == 1) {
            _epoch_1 = epochPeriod;
            return true;
        }
        else if (set == 2) {
            _epoch_2 = epochPeriod;
            return true;
        }
        else return false;
    }

    function set_EpochClaimNft(uint epochclaimnftperiod) public onlyOwner returns (bool) {
        _epochClaimNft = epochclaimnftperiod;
        return true;
    }

    function get_EpochClaimNft() public view returns (uint) {
        return _epochClaimNft;
    }

    function set_NextDistributionTime (uint set) public onlyOwner returns (bool) {
        // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
        // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
        if (set == 1) {
            _nextDistributionTime_1 = block.timestamp.add(_epoch_1);
            return true;
        }
        else if (set == 2) {
            _nextDistributionTime_2 = block.timestamp.add(_epoch_2);
            return true;
        }
        else return false;
    }

    function get_NextDistributionTime (uint set) public view returns (uint) {
        // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
        // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
        if (set == 1) return _nextDistributionTime_1;
        else if (set == 2) return _nextDistributionTime_2;
        else return 0;
    }

    function set_ClaimNftDistributionTime () public onlyOwner returns (bool) {
        _claimNftDistributionTime = block.timestamp.add(_epochClaimNft);
        return true;
    }

    function get_ClaimNftDistributionTime () public view returns (uint) {
        return _claimNftDistributionTime;
    }

    function get_RemainingTimeToNextDistribution(uint set) public view returns (uint[] memory) {
        // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
        // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
        uint[] memory remainingtime = new uint[](3);
        uint _hoursTotal = DateTimeLibrary.diffHours(block.timestamp, get_NextDistributionTime(set));
        uint _minutesTotal = DateTimeLibrary.diffMinutes(block.timestamp, get_NextDistributionTime(set));
        uint _secondsTotal = DateTimeLibrary.diffSeconds(block.timestamp, get_NextDistributionTime(set));
        uint _hoursInMinutes = _hoursTotal.mul(60);
        uint _hoursInSeconds = _hoursTotal.mul(3600);
        uint _minutes;
        uint _minutesInSeconds;
        uint _seconds;
        if (_hoursTotal != 0) _minutes = _minutesTotal.mod(_hoursInMinutes);
        else _minutes = _minutesTotal;
        _minutesInSeconds = _minutes.mul(60);
        if (_hoursInSeconds.add(_minutesInSeconds) != 0) _seconds = _secondsTotal.mod(_hoursInSeconds.add(_minutesInSeconds));
        else _seconds = _secondsTotal;
        remainingtime[0] = _hoursTotal;
        remainingtime[1] = _minutes;
        remainingtime[2] = _seconds;
        return remainingtime;
    }

    function get_RemainingTimeToNftClaim() public view returns (uint[] memory) {
        uint[] memory remainingtime = new uint[](3);
        uint _hoursTotal = DateTimeLibrary.diffHours(block.timestamp, get_ClaimNftDistributionTime());
        uint _minutesTotal = DateTimeLibrary.diffMinutes(block.timestamp, get_ClaimNftDistributionTime());
        uint _secondsTotal = DateTimeLibrary.diffSeconds(block.timestamp, get_ClaimNftDistributionTime());
        uint _hoursInMinutes = _hoursTotal.mul(60);
        uint _hoursInSeconds = _hoursTotal.mul(3600);
        uint _minutes;
        uint _minutesInSeconds;
        uint _seconds;
        if (_hoursTotal != 0) _minutes = _minutesTotal.mod(_hoursInMinutes);
        else _minutes = _minutesTotal;
        _minutesInSeconds = _minutes.mul(60);
        if (_hoursInSeconds.add(_minutesInSeconds) != 0) _seconds = _secondsTotal.mod(_hoursInSeconds.add(_minutesInSeconds));
        else _seconds = _secondsTotal;
        remainingtime[0] = _hoursTotal;
        remainingtime[1] = _minutes;
        remainingtime[2] = _seconds;
        return remainingtime;
    }

    function get_NowTime () public view returns (uint) {
        return block.timestamp;
    }

    function changeAntiDipAddress(address payable _newaddress) public onlyOwner {
        _antiDipAddress = _newaddress;
    }

    function changeMarketingAddress(address payable _newaddress) public onlyOwner {
        _marketingAddress = _newaddress;
    }

    function changeGameDevAddress(address payable _newaddress) public onlyOwner {
        _gameDevAddress = _newaddress;
    }

    function changeMarketingWalletPercent(uint256  _newpercent) public onlyOwner {
        _marketingWalletPercent = _newpercent;
    }

    function changeNftWalletPercent(uint256  _newpercent) public onlyOwner {
        _nftWalletPercent = _newpercent;
    }

    function changeAntiDipToReflectToHoldersWalletPercent(uint256  _newpercent) public onlyOwner {
        _antiDipToReflectToHoldersWalletPercent = _newpercent;
    }

    function changeTaxFeeWalletPercent(uint256  _newpercent) public onlyOwner {
        _taxFeeWalletPercent = _newpercent;
    }

    function changeAntiDipWalletPercent(uint256  _newpercent) public onlyOwner {
        _antiDipWalletPercent = _newpercent;
    }

    function changeGameDevWalletPercent(uint256  _newpercent) public onlyOwner {
        _gameDevWalletPercent = _newpercent;
    }

    function set_MinTokensBeforeSwap(uint256 amount) external onlyOwner {
        _minTokensBeforeSwap = amount;
    }

    function _updateTaxFeeTotal(uint256 rFee, uint256 tFee) private {
        _reflectionTotal = _reflectionTotal.sub(rFee);
        _taxfeeTotal = _taxfeeTotal.add(tFee);
    }

    function set_WalletsPercent(
        uint256 _marketingWallPercent,
        uint256 _nftWallPercent,
        uint256 _antiDipToReflectToHoldersWallPercent,
        uint256 _taxFeeWallPercent,
        uint256 _antiDipWallPercent
        ) external onlyOwner {

        _marketingWalletPercent = _marketingWallPercent;
        _nftWalletPercent = _nftWallPercent;
        _antiDipToReflectToHoldersWalletPercent = _antiDipToReflectToHoldersWallPercent;
        _taxFeeWalletPercent = _taxFeeWallPercent;
        _taxFeeWalletPercent = _taxFeeWallPercent;
        _antiDipWalletPercent = _antiDipWallPercent;
    }

    function _updateBuyBackTotal(uint256 tForBuy, uint256 tAntiSell) private {
        _buybackTotal = _buybackTotal.add(tForBuy).add(tAntiSell);
    }

    function set_TradingIsEnabled(bool enabled) public onlyOwner {
        _tradingIsEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }

    function get_tradingIsEnabled() external view returns (bool) {
        return _tradingIsEnabled;
    }

    function set_DistribuitionInWethEnabled(bool enabled) public onlyOwner {
        _isDistribuitionInWethEnabled = enabled;
    }

    function get_DistribuitionInWethEnabled() external view returns (bool) {
        return _isDistribuitionInWethEnabled;
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////// funzioni di get per il transfer ////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tForBuy = calculateForBuyFee(tAmount);
        uint256 tAntiSell = calculateAntiSellFee(tAmount);
        uint256 totaltFees = tFee.add(tForBuy).add(tAntiSell);
        uint256 tTransferAmount = tAmount.sub(totaltFees);
        return (tTransferAmount, tForBuy, tAntiSell, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tForBuy, uint256 tAntiSell, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 reflectionAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rForBuy = tForBuy.mul(currentRate);
        uint256 rAntiSell = tAntiSell.mul(currentRate);
        uint256 totalrFees = rFee.add(rForBuy).add(rAntiSell);
        uint256 rTransferAmount = reflectionAmount.sub(totalrFees);
        return (reflectionAmount, rTransferAmount, rFee);
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////// funzioni di get per il transferfrom ////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////

    function _getTValues2(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee2(tAmount);
        uint256 tForBuy = calculateForBuyFee2(tAmount);
        uint256 tAntiSell = calculateAntiSellFee2(tAmount);
        uint256 totaltFees = tFee.add(tForBuy).add(tAntiSell);
        uint256 tTransferAmount = tAmount.sub(totaltFees);
        return (tTransferAmount, tForBuy, tAntiSell, tFee);
    }

    function _getRValues2(uint256 tAmount, uint256 tFee, uint256 tForBuy, uint256 tAntiSell, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 reflectionAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rForBuy = tForBuy.mul(currentRate);
        uint256 rAntiSell = tAntiSell.mul(currentRate);
        uint256 totalrFees = rFee.add(rForBuy).add(rAntiSell);
        uint256 rTransferAmount = reflectionAmount.sub(totalrFees);
        return (reflectionAmount, rTransferAmount, rFee);
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// funzioni di get comuni //////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _reflectionTotal;
        uint256 tSupply = _tokenTotal;
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_reflectionBalance[_excludedFromReward[i]] > rSupply || _tokenBalance[_excludedFromReward[i]] > tSupply) return (_reflectionTotal, _tokenTotal);
            rSupply = rSupply.sub(_reflectionBalance[_excludedFromReward[i]]);
            tSupply = tSupply.sub(_tokenBalance[_excludedFromReward[i]]);
        }
        if (rSupply < _reflectionTotal.div(_tokenTotal)) return (_reflectionTotal, _tokenTotal);
        return (rSupply, tSupply);
    }

    function _takeForBuy(uint256 tForBuy) private {
        uint256 currentRate =  _getRate();
        uint256 rForBuy = tForBuy.mul(currentRate);
        _reflectionBalance[_forBuyAddress] = _reflectionBalance[_forBuyAddress].add(rForBuy);
        if(_isExcludedFromReward[_forBuyAddress])
            _tokenBalance[_forBuyAddress] = _tokenBalance[_forBuyAddress].add(tForBuy);
    }

    function _takeAntiSell(uint256 tAntiSell) private {
        uint256 currentRate =  _getRate();
        uint256 rAntiSell = tAntiSell.mul(currentRate);
        _reflectionBalance[_antiSellAddress] = _reflectionBalance[_antiSellAddress].add(rAntiSell);
        if(_isExcludedFromReward[_antiSellAddress])
            _tokenBalance[_antiSellAddress] = _tokenBalance[_antiSellAddress].add(tAntiSell);
    }
//////////////////////////////////////////////////////////////////////////////////////////////
////////// funzioni utilizzate per il calcolo delle fee dal transfer /////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateForBuyFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_forBuyFee).div(10**2);
    }

    function calculateAntiSellFee(uint256 _amount) private pure returns (uint256) {
        return _amount.mul(0).div(10**2);
    }

//////////////////////////////////////////////////////////////////////////////////////////////
////////// funzioni utilizzate per il calcolo delle fee dal transferfrom /////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

    function calculateTaxFee2(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateForBuyFee2(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_forBuyFee).div(10**2);
    }

    function calculateAntiSellFee2(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_antiSellFeeFromOracle).div(10**2);
    }

//////////////////////////////////////////////////////////////////////////////////////////////

    function removeTaxFee() private {
        if(_taxFee == 0) return;
        _previousTaxFee = _taxFee;
        _taxFee = 0;
    }

    function removeForBuyFee() private {
        if(_forBuyFee == 0) return;
        _previousForBuyFee = _forBuyFee;
        _forBuyFee = 0;
    }

    function removeAntiSellFee() private {
        if(_antiSellFeeFromOracle == 0) return;
        _previousAntiSellFeeFromOracle = _antiSellFeeFromOracle;
        _antiSellFeeFromOracle = 0;
    }

    function restoreTaxFee() private {
        _taxFee = _previousTaxFee;
    }

    function restoreForBuyFee() private {
        _forBuyFee = _previousForBuyFee;
    }

    function restoreAntiSellFee() private {
        _antiSellFeeFromOracle = _previousAntiSellFeeFromOracle;
    }

    function isExcludedFromTaxFee(address account) external view returns(bool) {
        return _isExcludedFromTaxFee[account];
    }

    function isExcludedFromForBuyFee(address account) external view returns(bool) {
        return _isExcludedFromForBuyFee[account];
    }

    function isExcludedFromAntiSellFee(address account) external view returns(bool) {
        return _isExcludedFromAntiSellFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BNB20: approve from the zero address");
        require(spender != address(0), "BNB20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////// funzione di transfer per il transferfrom ////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

    function _transfer2(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BNB20: transfer from the zero address");
        require(to != address(0), "BNB20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_tradingIsEnabled, "Trading disabled !");
        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(get_BlackList(to) == false, "this account is Black listed!");
        }

        if (_lockedListMode) { // impedisce agli utenti di fare trading se hanno raggiunto un alta percentuale di balance
            require(get_LockedListValue(to) != 1, "this account is Locked! his balance over 3% of total amount");
            emit UserLocked(to, balanceOf(to));    
        }

        if (_antiBotMode) { // impedisce agli sniper di conprare dal pool, con GWei >= 8, normalmente pancakeswap permette Gwei = 4,5,6
            if(tx.gasprice >= _maxGWeiPermitted){
                set_BotUser(to,true);
                emit antiBotActivated(to, tx.gasprice);
            }
            require(get_BotUser(to) == false, "Bots are not welcome !");
        }

        //indicates if fee should be deducted from transferfrom
        bool takeAntiSellFee = true;

        if(_isExcludedFromAntiSellFee[from] || _isExcludedFromAntiSellFee[to]){
            takeAntiSellFee = false;
        }
        //transfer amount, it will take antiSell fee
        _tokenTransfer2(from,to,amount,takeAntiSellFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer2(address sender, address recipient, uint256 amount, bool takeAntiSellFee) private {
        if(!takeAntiSellFee)
            removeAntiSellFee();

        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded2(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded2(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard2(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded2(sender, recipient, amount);
        } else {
            _transferStandard2(sender, recipient, amount);
        }
        if(!takeAntiSellFee)
            restoreAntiSellFee();
    }

    function _transferStandard2(address sender, address recipient, uint256 tAmount) private {
        uint lastselltime = block.timestamp;
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues2(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues2(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        set_LastSellTransferTimeFromAddressTokenHolder(lastselltime,recipient);
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded2(address sender, address recipient, uint256 tAmount) private {
        uint lastselltime = block.timestamp;
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues2(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues2(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _tokenBalance[recipient] = _tokenBalance[recipient].add(tTransferAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        set_LastSellTransferTimeFromAddressTokenHolder(lastselltime,recipient);
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded2(address sender, address recipient, uint256 tAmount) private {
        uint lastselltime = block.timestamp;
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues2(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues2(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _tokenBalance[sender] = _tokenBalance[sender].sub(tAmount);
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        set_LastSellTransferTimeFromAddressTokenHolder(lastselltime,recipient);
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded2(address sender, address recipient, uint256 tAmount) private {
        uint lastselltime = block.timestamp;
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues2(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues2(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _tokenBalance[sender] = _tokenBalance[sender].sub(tAmount);
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _tokenBalance[recipient] = _tokenBalance[recipient].add(tTransferAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        set_LastSellTransferTimeFromAddressTokenHolder(lastselltime,recipient);
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    //////////////////// funzione di transfer per il transfer ///////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BNB20: transfer from the zero address");
        require(to != address(0), "BNB20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_tradingIsEnabled, "Trading disabled !");
        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(get_BlackList(from) == false, "this account is Black listed!");
        }

        if (_lockedListMode) { // impedisce agli utenti di fare trading se hanno raggiunto un alta percentuale di balance
            require(get_LockedListValue(from) != 1, "this account is Locked! his balance over 3% of total amount");
            emit UserLocked(from, balanceOf(from));    
        }

        if (_antiBotMode) { // impedisce agli sniper di conprare dal pool, con GWei >= 8, normalmente pancakeswap permette Gwei = 4,5,6
            if(tx.gasprice >= _maxGWeiPermitted){
                set_BotUser(from,true);
                emit antiBotActivated(from, tx.gasprice);
            }
            require(get_BotUser(from) == false, "Bots are not welcome !");
        }  

        //indicates if and wich fees should be deducted from transfer
        bool takeTaxFee = true;
        bool takeForBuyFee = true;

        if(_isExcludedFromTaxFee[from] || _isExcludedFromTaxFee[to]){
            takeTaxFee = false;
        }
        if(_isExcludedFromForBuyFee[from] || _isExcludedFromForBuyFee[to]){
            takeForBuyFee = false;
        }
        //transfer amount, it will take redistribuition fee, antiSell fee, forBuy fee
        _tokenTransfer(from,to,amount,takeTaxFee,takeForBuyFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeTaxFee, bool takeForBuyFee) private {
        if(!takeTaxFee) removeTaxFee();
        if(!takeForBuyFee) removeForBuyFee();

        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if(!takeTaxFee) restoreTaxFee();
        if(!takeForBuyFee) restoreForBuyFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _tokenBalance[recipient] = _tokenBalance[recipient].add(tTransferAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _tokenBalance[sender] = _tokenBalance[sender].sub(tAmount);
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _tokenBalance[sender] = _tokenBalance[sender].sub(tAmount);
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _tokenBalance[recipient] = _tokenBalance[recipient].add(tTransferAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////// funzioni per loswap dei token in BNB e la distribuzione ai vari wallet del team //////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    function _updateDistributeAllinWETH(address sender) internal virtual {
      uint256 constractBal=balanceOf(address(this));
      bool overMinTokenBalance = constractBal >= _minTokensBeforeSwap;
      if (!_inSwapAndLiquify && overMinTokenBalance && sender != uniswapV2Pair && _tradingIsEnabled) {
        if (_isDistribuitionInWethEnabled) _distributeInWETH(constractBal);
      }
    }

    function _swapTokensForBNB(uint256 tokenAmount) private {
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

    function _swapBNBForWETH(uint256 BNBAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = BUSD_BinanceToken;
        _approve(address(this), address(BUSD_BinanceToken), BNBAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            BNBAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _distributeInWETH(uint256 amount) private lockTheSwap {
        // primo swap effettuato per trasformare una piccola porzione di tokens in BNB
        _swapTokensForBNB(amount);
        IERC20 BNB = IERC20(address(uniswapV2Router));
        uint256 BNB_Balance = BNB.balanceOf(address(this));

        // secondo swap effettuato per trasformare tutti i BNB precedentemente swappati in WETH (Ether pegged Binance)
        _swapBNBForWETH(BNB_Balance);
        IERC20 WETH = IERC20(address(BUSD_BinanceToken));
        uint256 WETH_Balance = WETH.balanceOf(address(this));

        uint256 amountToTranfer = WETH_Balance;
        uint256 amountMarketingToTranfer = amountToTranfer.mul(16).div(100); // _marketingWalletPercent = 16;
        uint256 amountNftToTranfer = amountToTranfer.mul(8).div(100); // _nftWalletPercent = 8;
        uint256 amountAntiDipToReflectToHoldersAddressToTranfer = amountToTranfer.mul(15).div(100); // _zntiDipToReflectToHoldersWalletPercent = 15; // sarebbe il 25% del totale rimasto nel wallert antidip che risulta 60%
        uint256 amountTaxFeeToTranfer = amountToTranfer.mul(16).div(100); // _taxFeeWalletPercent = 16;
        uint256 amountGameDevToTranfer = amountToTranfer.mul(15).div(100); // _marketingWalletPercent = 15;
        uint256 amountAntiDipToTranferFirstStepToDivideVariables = amountToTranfer.sub(amountMarketingToTranfer).sub(amountNftToTranfer).sub(amountAntiDipToReflectToHoldersAddressToTranfer);
        uint256 amountAntiDipToTranfer = amountAntiDipToTranferFirstStepToDivideVariables.sub(amountTaxFeeToTranfer).sub(amountGameDevToTranfer); // _antiDipWalletPercent = 30

        uint nextdistributiontime_1 = get_NextDistributionTime(1);
        uint nextdistributiontime_2 = get_NextDistributionTime(2);

        if (block.timestamp >= nextdistributiontime_1) {
            _distributeToAllHolders(amountTaxFeeToTranfer);
            _distributeToNftHolders(amountNftToTranfer);
            _distributeToAntiDip(amountAntiDipToTranfer);
            _distributeToMarketing(amountMarketingToTranfer);
            _distributeToGameDev(amountGameDevToTranfer);
            set_NextDistributionTime(1);
        }
        if (block.timestamp >= nextdistributiontime_2) {
            _distributeToNoSellHolders(amountAntiDipToReflectToHoldersAddressToTranfer);
            set_NextDistributionTime(2);
        }
    }

    function _distributeToAllHolders(uint256 tokenAmount) private {
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 amountToSend;

        for (uint256 i = 0; i < size ; i++) {
            keyAddress = _tokenHoldersAccounts[i];
            amountToSend = balanceOf(keyAddress).div(_tokenCirculatingTotal).mul(tokenAmount); // calcola la porzione da inviare ad ogni holders
            if (!_isExcludedFromReward[keyAddress]) payable(keyAddress).transfer(amountToSend);
        }
    }

    function _distributeToNftHolders(uint256 tokenAmount) private {
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 amountToSend;
        uint256 nftPercentageMax;
        uint256 tempTokenCirculatingTotal;
        uint256 tempBalance;

        for (uint256 i = 0; i < size ; i++) {
            keyAddress = _tokenHoldersAccounts[i];
            nftPercentageMax = get_NFTPercentageMaxFromAddressTokenHolder(keyAddress);
            tempBalance = balanceOf(keyAddress).add(balanceOf(keyAddress).mul(nftPercentageMax).div(100));
            tempTokenCirculatingTotal = _tokenCirculatingTotal.sub(balanceOf(keyAddress)).add(tempBalance);
            amountToSend = tempBalance.div(tempTokenCirculatingTotal).mul(tokenAmount); // calcola la porzione da inviare ad ogni holders che ha NFT nel wallet aggiungendo ai suoi token una porzione % data dalla carta
        }
        if (!_isExcludedFromReward[keyAddress]) payable(keyAddress).transfer(amountToSend);
    }

    function _distributeToNoSellHolders(uint256 tokenAmount) private {
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 amountToSend;
        uint lastselltime;
        for (uint256 i = 0; i < size ; i++) {
            keyAddress = _tokenHoldersAccounts[i];
            lastselltime = _tokenHoldersList[keyAddress].lastSellTransferTime;
            if (lastselltime == 0) {// non ha mai venduto
                amountToSend = balanceOf(keyAddress).div(_tokenNoSellTotal).mul(tokenAmount); // calcola la porzione da inviare ad ogni holders
                if (!_isExcludedFromReward[keyAddress]) payable(keyAddress).transfer(amountToSend);
            }
        }
    }

    function _distributeToAntiDip(uint256 tokenAmount) private {
        payable(_antiDipAddress).transfer(tokenAmount);
    }

    function _distributeToMarketing(uint256 tokenAmount) private {
        payable(_marketingAddress).transfer(tokenAmount);
    }

    function _distributeToGameDev(uint256 tokenAmount) private {
        payable(_gameDevAddress).transfer(tokenAmount);
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////// funzioni del mapping TokenHolder /////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////

    function get_ValueBeforeFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].valuesBefore;
    }

    function get_ValueAfterGrossFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].valuesAfterGross;
    }

    function get_ValueAfterNetFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].valuesAfterNet;
    }

    function get_ValueReflectionsFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].valuesReflections;
    }

    function get_ValueReflectionsAccumulatedFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].valuesReflectionsAccumulated;
    }

    function get_AmountToTransferFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].amountToTrasfer;
    }

    function get_ReflectionsFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].valuesReflections;
    }

    function get_LastSellTransferTimeFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].lastSellTransferTime;
    }

    function set_LastSellTransferTimeFromAddressTokenHolder(uint lastselltime,address addr) private {
        _tokenHoldersList[addr].lastSellTransferTime = lastselltime;
    }

    function get_ClaimTimeFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].claimTime;
    }

    function get_NFTPercentageMaxFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].NFTPercentageMax;
    }

    function set_NFTPercentageMaxTokenHolder(address addr, uint256 percentagemax) public onlyOwner returns(bool) {
        _tokenHoldersList[addr].NFTPercentageMax = percentagemax;
        return true;
    }

    function get_InsertedFromAddressTokenHolder(address addr) public view returns (bool) {
        return _tokenHoldersList[addr].inserted;
    }

    function get_SizeTokenHolder() public view returns (uint) {
        return _tokenHoldersAccounts.length;
    }

    function get_TokenHolderList() public view returns (address[] memory) {
        return _tokenHoldersAccounts;
    }

    function set_AllValuesTokenHolder(
        address addr,
        uint256 valbefore,
        uint256 valaftergross,
        uint256 valafternet,
        uint256 amounttotransfer,
        uint256 valreflections,
        uint256 valreflectionsaccumulated,
        bool updated
        ) private {

        if (_tokenHoldersList[addr].inserted) {
            _tokenHoldersList[addr].valuesBefore = valbefore;
            _tokenHoldersList[addr].valuesAfterGross = valaftergross;
            _tokenHoldersList[addr].valuesAfterNet = valafternet;
            _tokenHoldersList[addr].amountToTrasfer = amounttotransfer;
            _tokenHoldersList[addr].valuesReflections = valreflections;
            _tokenHoldersList[addr].valuesReflectionsAccumulated = valreflectionsaccumulated;
            _tokenHoldersList[addr].updated = updated;
        } else {
            _tokenHoldersList[addr].inserted = true;
            _tokenHoldersList[addr].valuesBefore = valbefore;
            _tokenHoldersList[addr].valuesAfterGross = valaftergross;
            _tokenHoldersList[addr].valuesAfterNet = valafternet;
            _tokenHoldersList[addr].amountToTrasfer = amounttotransfer;
            _tokenHoldersList[addr].valuesReflections = valreflections;
            _tokenHoldersList[addr].valuesReflectionsAccumulated = valreflectionsaccumulated;
            _tokenHoldersList[addr].updated = updated;
            _tokenHoldersAccounts.push(addr);
        }
    }

    function _resetUpdatedTokenHolder() private {
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        for (uint256 i = 0; i < size ; i++) {
            keyAddress = _tokenHoldersAccounts[i];
            _tokenHoldersList[keyAddress].updated = false;
        }
    }
    /////////////////////////////////////////////////////////////////////////////////////////
    ///////////// funzioni per aggiornamento dei dati dei token holders /////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////


    function _updateSenderTokenHolderValues (
        address sender,
        uint256 tAmount
        ) private {

        // setta i valori del sender
        uint256 ValueBefore_sender = get_ValueBeforeFromAddressTokenHolder(sender);
        uint256 valuesReflections_sender = get_ValueReflectionsFromAddressTokenHolder(sender);
        uint256 balanceOf_sender = balanceOf(sender);
        uint256 ValueAfterNet_sender = ValueBefore_sender.sub(tAmount);

        set_AllValuesTokenHolder(
            sender, // sender
            ValueBefore_sender, // before
            balanceOf_sender, // afterGross
            ValueAfterNet_sender, // afterNet
            tAmount, // amount
            balanceOf_sender.sub(ValueAfterNet_sender), // reflections
            valuesReflections_sender.add(balanceOf_sender.sub(ValueAfterNet_sender)), // reflections accumulated
            true);
    }

    function _updateRecipientTokenHolderValues (
        address recipient,
        uint256 tAmount,
        uint256 tForBuy,
        uint256 tAntiSell,
        uint256 tFee
        ) private {

        // setta i valori del recipient
        uint256 ValueBefore_recipient = get_ValueBeforeFromAddressTokenHolder(recipient);
        uint256 valuesReflections_recipient = get_ValueReflectionsFromAddressTokenHolder(recipient);
        uint256 balanceOf_recipient = balanceOf(recipient);
        uint256 fees_recipient = tFee.add(tAntiSell).add(tForBuy);
        uint256 ValueAfterNet_recipient = ValueBefore_recipient.add(tAmount).sub(fees_recipient);

        set_AllValuesTokenHolder(
            recipient,
            ValueBefore_recipient,
            balanceOf_recipient,
            ValueAfterNet_recipient,
            tAmount,
            balanceOf_recipient.sub(ValueAfterNet_recipient), // reflections
            valuesReflections_recipient.add(balanceOf_recipient.sub(ValueAfterNet_recipient)), // reflections accumulated
            true);
    }

    function _updateContractTokenHolderValues (
        uint256 tAmount,
        uint256 tForBuy,
        uint256 tAntiSell
        ) private {

        // setta i valori del contratto
        uint256 ValueBefore_contract = get_ValueBeforeFromAddressTokenHolder(address(this));
        uint256 balanceOf_contract = balanceOf(address(this));
        uint256 fees_contract = tAntiSell.add(tForBuy);
        uint256 valuesReflections_contract = get_ValueReflectionsFromAddressTokenHolder(address(this));
        uint256 ValueAfterNet_contract = ValueBefore_contract.add(fees_contract);

        if (fees_contract > 0) {
            set_AllValuesTokenHolder(
                address(this),
                ValueBefore_contract,
                balanceOf_contract,
                ValueAfterNet_contract,
                tAmount,
                balanceOf_contract.sub(ValueAfterNet_contract), // reflections
                valuesReflections_contract.add(balanceOf_contract.sub(ValueAfterNet_contract)), // reflections accumulated
                true);
        }
    }

    function _updateOthersTokenHolderValues (
        uint256 tAmount
        ) private {

        // setta i valori di tutti gli altri holder non updated
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 ValueBefore_other;
        uint256 valuesReflections_other;
        uint256 balanceOf_other;

        for (uint256 i = 0; i < size ; i++) {
            keyAddress = _tokenHoldersAccounts[i];
            if(!_tokenHoldersList[keyAddress].updated) {
                ValueBefore_other = get_ValueBeforeFromAddressTokenHolder(keyAddress);
                valuesReflections_other = get_ValueReflectionsFromAddressTokenHolder(keyAddress);
                balanceOf_other = balanceOf(keyAddress);
                set_AllValuesTokenHolder(
                    keyAddress, // holder address
                    ValueBefore_other, // before
                    balanceOf_other, // afterGross
                    ValueBefore_other, // afterNet
                    tAmount, // amount
                    balanceOf_other.sub(ValueBefore_other), // reflections
                    valuesReflections_other.add(balanceOf_other.sub(ValueBefore_other)), // reflections accumulated
                    true);
            }
        }
    }

    function _exchangeBeforeAfterTokenHolderValues (
        )  private {

        // scambia alla fine dell'operazione transfer il before con afterNet
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 ValueAfterNet;
        uint256 NFTPercentageMax;
        uint256 totalReflections = 0;
        _tokenCirculatingTotal = 0;
        _tokenNoSellTotal = 0;

        for (uint256 i = 0; i < size ; i++) {
            keyAddress = _tokenHoldersAccounts[i];
            if(_tokenHoldersList[keyAddress].updated) {
                ValueAfterNet = get_ValueAfterNetFromAddressTokenHolder(keyAddress);
                NFTPercentageMax = get_NFTPercentageMaxFromAddressTokenHolder(keyAddress);
                _tokenHoldersList[keyAddress].valuesBefore = ValueAfterNet;
                _reBalance(keyAddress);
                totalReflections = totalReflections.add(get_ValueReflectionsFromAddressTokenHolder(keyAddress));

                // Calcola il totale dei token ciorcolanti posseduti dagli holders e degli holders che non hanno mai venduto
                _tokenCirculatingTotal = _tokenCirculatingTotal.add(balanceOf(keyAddress)); // totale crcolante espresso come somma dei balance degli holders esclusi i token in liquidity
                if (_tokenHoldersList[keyAddress].lastSellTransferTime == 0) _tokenNoSellTotal = _tokenNoSellTotal.add(balanceOf(keyAddress)); // totale dei token posseduti da holders che non hanno mai venduto
                //if (ValueAfterNet == 0 && NFTPercentageMax == 0) _removeAddressTokenHolder(keyAddress);

            }
        }
        _reBalanceContract(totalReflections);
    }

    function _reBalance (address account
        )  private {

        // riporta il balance degli account al valore senza interessi AfterNet
        uint256 ValueAfterNet = get_ValueAfterNetFromAddressTokenHolder(account);
        uint accountLockedListed = get_LockedListValue(account);
        if (_isExcludedFromReward[account]) _tokenBalance[account]=ValueAfterNet;
        else _reflectionBalance[account] = reflectionFromToken(ValueAfterNet);
        if (balanceOf(account) >= _balanceOfMaxPermitted && accountLockedListed==0) set_LockedListValue(account,1); // inserisce l'account in Locked list se il suo balance supera il 3% del total amount
    }

    function _reBalanceContract (uint256 totalReflections
        )  private {
        // assegna al contratto le reflections calcolate nell'ultima operazione di transfer o transferfrom, in tale calcolo deve
        // comprendere anche le sue di reflection perchè nell'array _reflectionBalance non c'era alcuna reflection fino a questo momento neanche quelle del contratto.
        // Quindi nel balance del contratto saranno assorbite le seguenti voci:
        // somma delle refelctionAccoumulated da tutti gli holders (contratto compreso) + fees totali pagate solo al contratto (fromBuyFee + antiSellFee)
        if (_isExcludedFromReward[address(this)]) _tokenBalance[address(this)]=_tokenBalance[address(this)].add(totalReflections);
        else _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(reflectionFromToken(totalReflections));
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////// funzioni da usare per il claim NFT /////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////

    function set_balanceNeededClaim(uint256 balanceNeeded) external onlyOwner {
        _balanceNeededClaim = balanceNeeded;
    }

    function get_balanceNeededClaim() external view returns (uint256) {
        return _balanceNeededClaim;
    }

    // verificala condizione 1 del claim ovvero se il saldo del balance è sufficiente
    function get_claimCheck1(address addr) external view returns (uint256, bool) {
        uint256 balanceNeeded = _balanceNeededClaim;
        bool _check = false;
        if (balanceOf(addr) >= balanceNeeded) _check = true;
        else _check = false;
        return (balanceOf(addr), _check);
    }

    // verificala condizione 2 del claim ovvero se è passato un certo periodo (circa una settimana) dalla data di listing
    function get_claimCheck2() external view returns (uint[] memory, bool _check) {
        uint _now = block.timestamp;
        uint[] memory timeResult = new uint[](3);
        if (_now >= _claimNftDistributionTime) _check = true;
        else _check = false;
        for (uint i = 0; i<timeResult.length; i++) {timeResult[i] = get_RemainingTimeToNftClaim()[i];
        }
        return (timeResult, _check);
    }

    // verificala condizione 3 del claim ovvero se non si è mai venduto fino a quel momento
    function get_claimCheck3(address addr) external view returns (bool) {
        bool _check = false;
        uint _lastselltransaction = _tokenHoldersList[addr].lastSellTransferTime;
        if (_lastselltransaction == 0) _check = true;
        else _check = false;
        return (_check);
    }

    // verificala condizione 4 del claim ovvero se non si è mai fatto un claim
    function get_claimCheck4(address addr) external view returns (bool) {
        bool _check = false;
        uint _claimTime = _tokenHoldersList[addr].claimTime;
        if (_claimTime == 0) _check = true;
        else _check = false;
        return (_check);
    }


    /////////////////////////////////////////////////////////////////////////////////////////

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    receive() external payable {}
}