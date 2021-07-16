//SourceUnit: BaseTRC20.sol

pragma solidity ^0.5.8;

import "./ITRC20.sol";
import "./Context.sol";
import "./SafeMath.sol";

contract BaseTRC20 is Context,ITRC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TRC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TRC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "TRC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "TRC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract TRC20Detailed is BaseTRC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;


    constructor (string memory name, string memory symbol, uint8 decimals,uint256 initSupply) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _mint(_msgSender(), initSupply) ;
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
}



//SourceUnit: CaculateIncrease.sol

pragma solidity ^0.5.8;

import './Date.sol';

contract CaculateIncrease is Date{ 
    
    int private start_year;
    int private start_month;
    int private start_day;
    
    int private year;
    int private month;
    int private next_day;
    
    uint private _start_time;
    
    uint private _count;
    uint private _count_months;
    
    uint private _first_months = 6;
    uint private _first_mul = 10;
    uint private _second_months = 18;
    uint private _second_mul = 8;
    uint private _third_months = 42;
    uint private _third_mul = 5;
    uint private _fouth_months = 78;
    uint private _fouth_mul = 3;
    uint private _fifth_months = 120;
    uint private _fifth_mul = 2;

    
    function _initDate(int _year,int _month,int _day) internal {
        year = _year;
        month = _month; 
        next_day = _day;
        start_year = _year;
        start_month = _month;
        start_day = _day;
        _start_time = block.timestamp;
        _count = 0;
        _count_months = 0 ;
    }
    
    function _getIncrease(uint _now_num) internal view returns(uint){
        if(_count>0){ 
            uint _this_time = _start_time + _count * 1 days;
            require(_this_time < block.timestamp,"it's not time , can not increase");
        }
        uint _increase_per = _getIncreasePer();
        require(_increase_per>0,"can not increase , ended");
        uint _increase = _now_num*_increase_per/100/30;
        return _increase;
    } 
    
    function _parseInteger(uint amount,uint nums )internal pure returns(uint){
        return amount/nums*nums;
    }
    
    function _getIncreasePer()internal view returns(uint){
        if(_count_months<_first_months){
            return _first_mul;
        }else if(_count_months<_second_months){
            return _second_mul;
        }else if(_count_months<_third_months){
            return _third_mul;
        }else if(_count_months<_fouth_months){
            return _fouth_mul;
        }else if(_count_months<_fifth_months){
            return _fifth_mul;
        }else{
            return _fifth_mul;
        }
    }

    function _modTime() internal {
        int _days = _getMonthDays(year,month);
        if(next_day<_days){
            next_day = next_day + 1;
        }else{
            if(month==12){
                year = year + 1;
                month = 1;
                next_day = 1;
            }else{
                month = month + 1;
                next_day = 1;
            }
            _count_months = _count_months + 1;
        }
        _count = _count + 1 ;
    }
    
    function getYear() public view returns(int){
        return year;
    }
    
    function getMonth() public view returns(int){
        return month;
    }
    
    function getNextDay() public view returns(int){
        return next_day;
    }
    function getStartYear() public view returns(int){
        return start_year;
    }
    
    function getStartMonth() public view returns(int){
        return start_month;
    }
    
    function getStartDay() public view returns(int){
        return start_day;
    }
    function getCount() public view returns(uint){
        return _count;
    }
}

//SourceUnit: CoinIDCToken.sol

pragma solidity ^0.5.8;

import "./Context.sol";
import "./BaseTRC20.sol";
import "./CaculateIncrease.sol";

contract CoinIDCToken is TRC20Detailed,CaculateIncrease {
    address private _owner;
    uint private count;
    uint private _now_nums;
    uint private _added_nums;
    bool private start = false;
    bool private end = false;
    uint private _parseNum = 1000000;
    uint private maxNum = 1000000000000000;
    
    constructor() public TRC20Detailed ("CoinIDC Token", "IDCT", 6,10000000000000){
        _owner = _msgSender();   
        _now_nums = 10000000000000;
    }
    
    function startToken(int _year,int _month,int _day) public returns (bool) {
        require(!start, "token started");
        require(_msgSender() == _owner, "need permission");
        _initDate(_year,_month,_day);
        start = true;
        return true;
    } 
    //increase amount to one address
    function increase(address toAddress) public returns (bool){
        require(start,"token not start");
        require(!end,"token increase end");
        require(_msgSender() == _owner, "need permission");
        _mod_now_nums();
        //get increase amount 
        uint _increaseAmount = _getIncrease(_now_nums);
        // parse amount
        _increaseAmount = _parseInteger(_increaseAmount,_parseNum);
        if(_increaseAmount + _now_nums + _added_nums >=maxNum ){
            _increaseAmount = maxNum - _added_nums - _now_nums;
            end = true;
        }
        // increase
        _increase(toAddress,_increaseAmount);
        _added_nums = _added_nums + _increaseAmount;
        // modify time for this increase
        _modTime();
        return true;
    }
    function burn(uint amount) public returns (bool){
        require(_msgSender() == _owner, "need permission");
        _burn(_msgSender(),amount);
    }
    
    function _mod_now_nums() internal{
        if(getNextDay()==1){
            _now_nums = _now_nums + _added_nums;
            _added_nums = 0 ;
        }
    }
    
    function _increase(address account, uint amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");
        _mint(account, amount);
    }
}


//SourceUnit: Context.sol

pragma solidity ^0.5.8;

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

//SourceUnit: Date.sol

pragma solidity ^0.5.8;

contract Date {
    
    function _getMonthDays(int _year , int _month) internal pure returns(int) {
        int _days;
        if(_month==1||_month==3||_month==5||_month==7||_month==8||_month==10||_month==12){
            _days = 31;
        }else if(_month==2){
            if(_year%100==0){
                if(_year%400==0){
                    _days = 29;
                }else{
                    _days = 28;
                }
            }else if(_year%4==0){
                _days = 29;
            }else{
                _days = 28;
            }
        }else{
            _days = 30;
        }
        
        return _days;
    }
    
}

//SourceUnit: ITRC20.sol

pragma solidity ^0.5.8;

contract TRC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract ITRC20 is TRC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(address src, address dst, uint wad) public returns (bool);
}




//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}