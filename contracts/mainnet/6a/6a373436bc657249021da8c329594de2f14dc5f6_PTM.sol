pragma solidity ^0.4.25;

/*
*
*
*  ___ _      _                 _
*  | _ \ |__ _| |_ _ __  ___ _ _| |_
*  |  _/ / _` |  _| &#39;  \/ -_) &#39; \  _|
*  |_| |_\__,_|\__|_|_|_\___|_||_\__|
*
*
*/

// SafeMath methods
library SafeMath {
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        assert(c >= _a);
        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_a >= _b);
        return _a - _b;
    }

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a * _b;
        assert(_a == 0 || c / _a == _b);
        return c;
    }
}

// Contract must have an owner
contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _owner) onlyOwner public {
        owner = _owner;
    }
}

// Standard ERC20 Token Interface
interface ERC20Token {
    function name() external view returns (string name_);
    function symbol() external view returns (string symbol_);
    function decimals() external view returns (uint8 decimals_);
    function totalSupply() external view returns (uint256 totalSupply_);
    function balanceOf(address _owner) external view returns (uint256 _balance);
    function transfer(address _to, uint256 _value) external returns (bool _success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
    function approve(address _spender, uint256 _value) external returns (bool _success);
    function allowance(address _owner, address _spender) external view returns (uint256 _remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// the main ERC20-compliant multi-timelock enabled contract
contract PTM is Owned, ERC20Token {
    using SafeMath for uint256;

    string private constant standard = "201810";
    string private constant version = "5.0";
    string private name_ = "platment";
    string private symbol_ = "PTM";
    uint8 private decimals_ = 18;
    uint256 private totalSupply_ = uint256(10)**uint256(10) * uint256(10)**uint256(decimals_);
    mapping (address => uint256) private balanceP;
    mapping (address => mapping (address => uint256)) private allowed;

    mapping (address => uint256[]) private lockTime;
    mapping (address => uint256[]) private lockValue;
    mapping (address => uint256) private lockNum;
    uint256 private later = 0;
    uint256 private earlier = 0;

    // burn token event
    event Burn(address indexed _from, uint256 _value);

    // timelock-related events
    event TransferLocked(address indexed _from, address indexed _to, uint256 _time, uint256 _value);
    event TokenUnlocked(address indexed _address, uint256 _value);

    // safety method-related events
    event WrongTokenEmptied(address indexed _token, address indexed _addr, uint256 _amount);
    event WrongEtherEmptied(address indexed _addr, uint256 _amount);

    // constructor for the ERC20 Token
    constructor() public {
        balanceP[msg.sender] = totalSupply_;
    }

    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // fast-forward the timelocks for all accounts
    function setUnlockEarlier(uint256 _earlier) public onlyOwner {
        earlier = earlier.add(_earlier);
    }

    // delay the timelocks for all accounts
    function setUnlockLater(uint256 _later) public onlyOwner {
        later = later.add(_later);
    }

    // standard ERC20 name function
    function name() public view returns (string) {
        return name_;
    }

    // standard ERC20 symbol function
    function symbol() public view returns (string) {
        return symbol_;
    }

    // standard ERC20 decimals function
    function decimals() public view returns (uint8) {
        return decimals_;
    }

    // standard ERC20 totalSupply function
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    // standard ERC20 allowance function
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

    // show unlocked balance of an account
    function balanceUnlocked(address _address) public view returns (uint256 _balance) {
        _balance = balanceP[_address];
        uint256 i = 0;
        while (i < lockNum[_address]) {
            if (now.add(earlier) >= lockTime[_address][i].add(later)) _balance = _balance.add(lockValue[_address][i]);
            i++;
        }
        return _balance;
    }

    // show timelocked balance of an account
    function balanceLocked(address _address) public view returns (uint256 _balance) {
        _balance = 0;
        uint256 i = 0;
        while (i < lockNum[_address]) {
            if (now.add(earlier) < lockTime[_address][i].add(later)) _balance = _balance.add(lockValue[_address][i]);
            i++;
        }
        return  _balance;
    }

    // standard ERC20 balanceOf with timelock added
    function balanceOf(address _address) public view returns (uint256 _balance) {
        _balance = balanceP[_address];
        uint256 i = 0;
        while (i < lockNum[_address]) {
            _balance = _balance.add(lockValue[_address][i]);
            i++;
        }
        return _balance;
    }

    // show timelocks in an account
    function showLockTimes(address _address) public view validAddress(_address) returns (uint256[] _times) {
        uint i = 0;
        uint256[] memory tempLockTime = new uint256[](lockNum[_address]);
        while (i < lockNum[_address]) {
            tempLockTime[i] = lockTime[_address][i].add(later).sub(earlier);
            i++;
        }
        return tempLockTime;
    }

    // show values locked in an account&#39;s timelocks
    function showLockValues(address _address) public view validAddress(_address) returns (uint256[] _values) {
        return lockValue[_address];
    }

    function showLockNum(address _address) public view validAddress(_address) returns (uint256 _lockNum) {
        return lockNum[_address];
    }

    // Calculate and process the timelock states of an account
    function calcUnlock(address _address) private {
        uint256 i = 0;
        uint256 j = 0;
        uint256[] memory currentLockTime;
        uint256[] memory currentLockValue;
        uint256[] memory newLockTime = new uint256[](lockNum[_address]);
        uint256[] memory newLockValue = new uint256[](lockNum[_address]);
        currentLockTime = lockTime[_address];
        currentLockValue = lockValue[_address];
        while (i < lockNum[_address]) {
            if (now.add(earlier) >= currentLockTime[i].add(later)) {
                balanceP[_address] = balanceP[_address].add(currentLockValue[i]);
                emit TokenUnlocked(_address, currentLockValue[i]);
            } else {
                newLockTime[j] = currentLockTime[i];
                newLockValue[j] = currentLockValue[i];
                j++;
            }
            i++;
        }
        uint256[] memory trimLockTime = new uint256[](j);
        uint256[] memory trimLockValue = new uint256[](j);
        i = 0;
        while (i < j) {
            trimLockTime[i] = newLockTime[i];
            trimLockValue[i] = newLockValue[i];
            i++;
        }
        lockTime[_address] = trimLockTime;
        lockValue[_address] = trimLockValue;
        lockNum[_address] = j;
    }

    // standard ERC20 transfer
    function transfer(address _to, uint256 _value) public validAddress(_to) returns (bool _success) {
        if (lockNum[msg.sender] > 0) calcUnlock(msg.sender);
        require(balanceP[msg.sender] >= _value && _value >= 0);
        balanceP[msg.sender] = balanceP[msg.sender].sub(_value);
        balanceP[_to] = balanceP[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // transfer Token with timelocks
    function transferLocked(address _to, uint256[] _time, uint256[] _value) public validAddress(_to) returns (bool _success) {
        require(_value.length == _time.length);

        if (lockNum[msg.sender] > 0) calcUnlock(msg.sender);
        uint256 i = 0;
        uint256 totalValue = 0;
        while (i < _value.length) {
            totalValue = totalValue.add(_value[i]);
            i++;
        }
        require(balanceP[msg.sender] >= totalValue && totalValue >= 0);
        require(lockNum[_to].add(_time.length) <= 42);
        i = 0;
        while (i < _time.length) {
            if (_value[i] > 0) {
                balanceP[msg.sender] = balanceP[msg.sender].sub(_value[i]);
                lockTime[_to].length = lockNum[_to]+1;
                lockValue[_to].length = lockNum[_to]+1;
                lockTime[_to][lockNum[_to]] = now.add(_time[i]).add(earlier).sub(later);
                lockValue[_to][lockNum[_to]] = _value[i];
                lockNum[_to]++;
            }

            // emit custom TransferLocked event
            emit TransferLocked(msg.sender, _to, _time[i], _value[i]);

            // emit standard Transfer event for wallets
            emit Transfer(msg.sender, _to, _value[i]);

            i++;
        }
        return true;
    }

    // TransferFrom Token with timelocks
    function transferLockedFrom(address _from, address _to, uint256[] _time, uint256[] _value) public
	    validAddress(_from) validAddress(_to) returns (bool success) {
        require(_value.length == _time.length);

        if (lockNum[_from] > 0) calcUnlock(_from);
        uint256 i = 0;
        uint256 totalValue = 0;
        while (i < _value.length) {
            totalValue = totalValue.add(_value[i]);
            i++;
        }
        require(balanceP[_from] >= totalValue && totalValue >= 0 && allowed[_from][msg.sender] >= totalValue);
        require(lockNum[_to].add(_time.length) <= 42);
        i = 0;
        while (i < _time.length) {
            if (_value[i] > 0) {
                balanceP[_from] = balanceP[_from].sub(_value[i]);
                allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value[i]);
                lockTime[_to].length = lockNum[_to]+1;
                lockValue[_to].length = lockNum[_to]+1;
                lockTime[_to][lockNum[_to]] = now.add(_time[i]).add(earlier).sub(later);
                lockValue[_to][lockNum[_to]] = _value[i];
                lockNum[_to]++;
            }

            // emit custom TransferLocked event
            emit TransferLocked(_from, _to, _time[i], _value[i]);

            // emit standard Transfer event for wallets
            emit Transfer(_from, _to, _value[i]);

            i++;
        }
        return true;
    }

    // standard ERC20 transferFrom
    function transferFrom(address _from, address _to, uint256 _value) public validAddress(_from) validAddress(_to) returns (bool _success) {
        if (lockNum[_from] > 0) calcUnlock(_from);
        require(balanceP[_from] >= _value && _value >= 0 && allowed[_from][msg.sender] >= _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balanceP[_from] = balanceP[_from].sub(_value);
        balanceP[_to] = balanceP[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    // should only be called when first setting an allowed
    function approve(address _spender, uint256 _value) public validAddress(_spender) returns (bool _success) {
        if (lockNum[msg.sender] > 0) calcUnlock(msg.sender);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // increase or decrease allowed
    function increaseApproval(address _spender, uint _value) public validAddress(_spender) returns (bool _success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_value);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _value) public validAddress(_spender) returns (bool _success) {
        if(_value >= allowed[msg.sender][_spender]) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_value);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    // owner may burn own token
    function burn(uint256 _value) public onlyOwner returns (bool _success) {
        if (lockNum[msg.sender] > 0) calcUnlock(msg.sender);
        require(balanceP[msg.sender] >= _value && _value >= 0);
        balanceP[msg.sender] = balanceP[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    // safety methods
    function () public payable {
        revert();
    }

    function emptyWrongToken(address _addr) onlyOwner public {
        ERC20Token wrongToken = ERC20Token(_addr);
        uint256 amount = wrongToken.balanceOf(address(this));
        require(amount > 0);
        require(wrongToken.transfer(msg.sender, amount));

        emit WrongTokenEmptied(_addr, msg.sender, amount);
    }

    // shouldn&#39;t happen, just in case
    function emptyWrongEther() onlyOwner public {
        uint256 amount = address(this).balance;
        require(amount > 0);
        msg.sender.transfer(amount);

        emit WrongEtherEmptied(msg.sender, amount);
    }

}