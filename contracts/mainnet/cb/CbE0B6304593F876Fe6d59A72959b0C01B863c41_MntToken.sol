pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }

    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

}

// @title The Contract is Mongolian National MDEX Token Issue.
//
// @Author: Tim Wars
// @Date: 2018.8.1
// @Seealso: ERC20
//
contract MntToken {

    // === Event ===
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint value);
    event TransferLocked(address indexed from, address indexed to, uint value, uint8 locktype);
	event Purchased(address indexed recipient, uint purchase, uint amount);

    // === Defined ===
    using SafeMath for uint;

    // --- Owner Section ---
    address public owner;
    bool public frozen = false; //

    // --- ERC20 Token Section ---
    uint8 constant public decimals = 6;
    uint public totalSupply = 100*10**(8+uint256(decimals));  // ***** 100 * 100 Million
    string constant public name = "MDEX Token | Mongolia National Blockchain Digital Assets Exchange Token";
    string constant public symbol = "MNT";

    mapping(address => uint) ownerance; // Owner Balance
    mapping(address => mapping(address => uint)) public allowance; // Allower Balance

    // --- Locked Section ---
    uint8 LOCKED_TYPE_MAX = 2; // ***** Max locked type
    uint private constant RELEASE_BASE_TIME = 1533686888; // ***** (2018-08-08 08:08:08) Private Lock phase start datetime (UTC seconds)
    address[] private lockedOwner;
    mapping(address => uint) public lockedance; // Lockeder Balance
    mapping(address => uint8) public lockedtype; // Locked Type
    mapping(address => uint8) public unlockedstep; // Unlocked Step

    uint public totalCirculating; // Total circulating token amount

    // === Modifier ===

    // --- Owner Section ---
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isNotFrozen() {
        require(!frozen);
        _;
    }

    // --- ERC20 Section ---
    modifier hasEnoughBalance(uint _amount) {
        require(ownerance[msg.sender] >= _amount);
        _;
    }

    modifier overflowDetected(address _owner, uint _amount) {
        require(ownerance[_owner] + _amount >= ownerance[_owner]);
        _;
    }

    modifier hasAllowBalance(address _owner, address _allower, uint _amount) {
        require(allowance[_owner][_allower] >= _amount);
        _;
    }

    modifier isNotEmpty(address _addr, uint _value) {
        require(_addr != address(0));
        require(_value != 0);
        _;
    }

    modifier isValidAddress {
        assert(0x0 != msg.sender);
        _;
    }

    // --- Locked Section ---
    modifier hasntLockedBalance(address _checker) {
        require(lockedtype[_checker] == 0);
        _;
    }

    modifier checkLockedType(uint8 _locktype) {
        require(_locktype > 0 && _locktype <= LOCKED_TYPE_MAX);
        _;
    }

    // === Constructor ===
    constructor() public {
        owner = msg.sender;
        ownerance[msg.sender] = totalSupply;
        totalCirculating = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // --- ERC20 Token Section ---
    function approve(address _spender, uint _value)
        isNotFrozen
        isValidAddress
        public returns (bool success)
    {
        require(_value == 0 || allowance[msg.sender][_spender] == 0); // must spend to 0 where pre approve balance.
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value)
        isNotFrozen
        isValidAddress
        overflowDetected(_to, _value)
        public returns (bool success)
    {
        require(ownerance[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);

        ownerance[_to] = ownerance[_to].add(_value);
        ownerance[_from] = ownerance[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public
        constant returns (uint balance)
    {
        balance = ownerance[_owner] + lockedance[_owner];
        return balance;
    }


    function available(address _owner) public
        constant returns (uint)
    {
        return ownerance[_owner];
    }

    function transfer(address _to, uint _value) public
        isNotFrozen
        isValidAddress
        isNotEmpty(_to, _value)
        hasEnoughBalance(_value)
        overflowDetected(_to, _value)
        returns (bool success)
    {
        ownerance[msg.sender] = ownerance[msg.sender].sub(_value);
        ownerance[_to] = ownerance[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // --- Owner Section ---
    function transferOwner(address _newOwner)
        isOwner
        public returns (bool success)
    {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
        return true;
    }

    function freeze()
        isOwner
        public returns (bool success)
    {
        frozen = true;
        return true;
    }

    function unfreeze()
        isOwner
        public returns (bool success)
    {
        frozen = false;
        return true;
    }

    function burn(uint _value)
        isNotFrozen
        isValidAddress
        hasEnoughBalance(_value)
        public returns (bool success)
    {
        ownerance[msg.sender] = ownerance[msg.sender].sub(_value);
        ownerance[0x0] = ownerance[0x0].add(_value);
        totalSupply = totalSupply.sub(_value);
        totalCirculating = totalCirculating.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    // --- Locked Section ---
    function transferLocked(address _to, uint _value, uint8 _locktype) public
        isNotFrozen
        isOwner
        isValidAddress
        isNotEmpty(_to, _value)
        hasEnoughBalance(_value)
        hasntLockedBalance(_to)
        checkLockedType(_locktype)
        returns (bool success)
    {
        require(msg.sender != _to);
        ownerance[msg.sender] = ownerance[msg.sender].sub(_value);
        if (_locktype == 1) {
            lockedance[_to] = _value;
            lockedtype[_to] = _locktype;
            lockedOwner.push(_to);
            totalCirculating = totalCirculating.sub(_value);
            emit TransferLocked(msg.sender, _to, _value, _locktype);
        } else if (_locktype == 2) {
            uint _first = _value / 100 * 8; // prevent overflow
            ownerance[_to] = ownerance[_to].add(_first);
            lockedance[_to] = _value.sub(_first);
            lockedtype[_to] = _locktype;
            lockedOwner.push(_to);
            totalCirculating = totalCirculating.sub(_value.sub(_first));
            emit Transfer(msg.sender, _to, _first);
            emit TransferLocked(msg.sender, _to, _value.sub(_first), _locktype);
        }
        return true;
    }

    // *****
    // Because too many unlocking steps * accounts, it will burn lots of GAS !!!!!!!!!!!!!!!!!!!!!!!!!!!
    // Because too many unlocking steps * accounts, it will burn lots of GAS !!!!!!!!!!!!!!!!!!!!!!!!!!!
    //
    // LockedType 1 : after 6 monthes / release 10 % per month; 10 steps
    // LockedType 2 :  before 0 monthes / release 8 % per month; 11 steps / 1 step has release real balance init.
    function unlock(address _locker, uint _delta, uint8 _locktype) private
        returns (bool success)
    {
        if (_locktype == 1) {
            if (_delta < 6 * 30 days) {
                return false;
            }
            uint _more1 = _delta.sub(6 * 30 days);
            uint _step1 = _more1 / 30 days;
            for(uint8 i = 0; i < 10; i++) {
                if (unlockedstep[_locker] == i && i < 9 && i <= _step1 ) {
                    ownerance[_locker] = ownerance[_locker].add(lockedance[_locker] / (10 - i));
                    lockedance[_locker] = lockedance[_locker].sub(lockedance[_locker] / (10 - i));
                    unlockedstep[_locker] = i + 1;
                } else if (i == 9 && unlockedstep[_locker] == 9 && _step1 == 9){
                    ownerance[_locker] = ownerance[_locker].add(lockedance[_locker]);
                    lockedance[_locker] = 0;
                    unlockedstep[_locker] = 0;
                    lockedtype[_locker] = 0;
                }
            }
        } else if (_locktype == 2) {
            if (_delta < 30 days) {
                return false;
            }
            uint _more2 = _delta - 30 days;
            uint _step2 = _more2 / 30 days;
            for(uint8 j = 0; j < 11; j++) {
                if (unlockedstep[_locker] == j && j < 10 && j <= _step2 ) {
                    ownerance[_locker] = ownerance[_locker].add(lockedance[_locker] / (11 - j));
                    lockedance[_locker] = lockedance[_locker].sub(lockedance[_locker] / (11 - j));
                    unlockedstep[_locker] = j + 1;
                } else if (j == 10 && unlockedstep[_locker] == 10 && _step2 == 10){
                    ownerance[_locker] = ownerance[_locker].add(lockedance[_locker]);
                    lockedance[_locker] = 0;
                    unlockedstep[_locker] = 0;
                    lockedtype[_locker] = 0;
                }
            }
        }
        return true;
    }

    function lockedCounts() public view
        returns (uint counts)
    {
        return lockedOwner.length;
    }

    function releaseLocked() public
        isNotFrozen
        returns (bool success)
    {
        require(now > RELEASE_BASE_TIME);
        uint delta = now - RELEASE_BASE_TIME;
        uint lockedAmount;
        for (uint i = 0; i < lockedOwner.length; i++) {
            if ( lockedance[lockedOwner[i]] > 0) {
                lockedAmount = lockedance[lockedOwner[i]];
                unlock(lockedOwner[i], delta, lockedtype[lockedOwner[i]]);
                totalCirculating = totalCirculating.add(lockedAmount - lockedance[lockedOwner[i]]);
            }
        }
        return true;
    }


}