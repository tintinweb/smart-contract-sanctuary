pragma solidity ^0.4.18;

contract Owned {
    address public owner;

    function Owned() public {
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

contract SafeMath {
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

contract Token is SafeMath, Owned {
    uint256 constant DAY_IN_SECONDS = 86400;
    string public constant standard = "0.66";
    string public name = "";
    string public symbol = "";
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceP;
    mapping (address => mapping (address => uint256)) public allowance;

    mapping (address => uint256[]) public lockTime;
    mapping (address => uint256[]) public lockValue;
    mapping (address => uint256) public lockNum;
    mapping (address => bool) public locker;
    uint256 public later = 0;
    uint256 public earlier = 0;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event TransferredLocked(address indexed _from, address indexed _to, uint256 _time, uint256 _value);
    event TokenUnlocked(address indexed _address, uint256 _value);

    function Token(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0);

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

        balanceP[msg.sender] = _totalSupply;

    }

    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    function addLocker(address _address) public validAddress(_address) onlyOwner {
        locker[_address] = true;
    }

    function removeLocker(address _address) public validAddress(_address) onlyOwner {
        locker[_address] = false;
    }

    function setUnlockEarlier(uint256 _earlier) public onlyOwner {
        earlier = add(earlier, _earlier);
    }

    function setUnlockLater(uint256 _later) public onlyOwner {
        later = add(later, _later);
    }

    function balanceUnlocked(address _address) public view returns (uint256 _balance) {
        _balance = balanceP[_address];
        uint256 i = 0;
        while (i < lockNum[_address]) {
            if (add(now, earlier) > add(lockTime[_address][i], later)) _balance = add(_balance, lockValue[_address][i]);
            i++;
        }
        return _balance;
    }

    function balanceLocked(address _address) public view returns (uint256 _balance) {
        _balance = 0;
        uint256 i = 0;
        while (i < lockNum[_address]) {
            if (add(now, earlier) < add(lockTime[_address][i], later)) _balance = add(_balance, lockValue[_address][i]);
            i++;
        }
        return  _balance;
    }

    function balanceOf(address _address) public view returns (uint256 _balance) {
        _balance = balanceP[_address];
        uint256 i = 0;
        while (i < lockNum[_address]) {
            _balance = add(_balance, lockValue[_address][i]);
            i++;
        }
        return _balance;
    }

    function showTime(address _address) public view validAddress(_address) returns (uint256[] _time) {
        uint i = 0;
        uint256[] memory tempLockTime = new uint256[](lockNum[_address]);
        while (i < lockNum[_address]) {
            tempLockTime[i] = sub(add(lockTime[_address][i], later), earlier);
            i++;
        }
        return tempLockTime;
    }

    function showValue(address _address) public view validAddress(_address) returns (uint256[] _value) {
        return lockValue[_address];
    }

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
            if (add(now, earlier) > add(currentLockTime[i], later)) {
                balanceP[_address] = add(balanceP[_address], currentLockValue[i]);
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

    function transfer(address _to, uint256 _value) public validAddress(_to) returns (bool success) {
        if (lockNum[msg.sender] > 0) calcUnlock(msg.sender);
        if (balanceP[msg.sender] >= _value && _value > 0) {
            balanceP[msg.sender] = sub(balanceP[msg.sender], _value);
            balanceP[_to] = add(balanceP[_to], _value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    function transferLocked(address _to, uint256[] _time, uint256[] _value) public validAddress(_to) returns (bool success) {
        require(_value.length == _time.length);

        if (lockNum[msg.sender] > 0) calcUnlock(msg.sender);
        uint256 i = 0;
        uint256 totalValue = 0;
        while (i < _value.length) {
            totalValue = add(totalValue, _value[i]);
            i++;
        }
        if (balanceP[msg.sender] >= totalValue && totalValue > 0) {
            i = 0;
            while (i < _time.length) {
                balanceP[msg.sender] = sub(balanceP[msg.sender], _value[i]);
                lockTime[_to].length = lockNum[_to]+1;
                lockValue[_to].length = lockNum[_to]+1;
                lockTime[_to][lockNum[_to]] = add(now, _time[i]);
                lockValue[_to][lockNum[_to]] = _value[i];
                emit TransferredLocked(msg.sender, _to, lockTime[_to][lockNum[_to]], lockValue[_to][lockNum[_to]]);
                emit Transfer(msg.sender, _to, lockValue[_to][lockNum[_to]]);
                lockNum[_to]++;
                i++;
            }
            return true;
        }
        else {
            return false;
        }
    }

    function transferLockedFrom(address _from, address _to, uint256[] _time, uint256[] _value) public 
	    validAddress(_from) validAddress(_to) returns (bool success) {
        require(locker[msg.sender]);
        require(_value.length == _time.length);

        if (lockNum[_from] > 0) calcUnlock(_from);
        uint256 i = 0;
        uint256 totalValue = 0;
        while (i < _value.length) {
            totalValue = add(totalValue, _value[i]);
            i++;
        }
        if (balanceP[_from] >= totalValue && totalValue > 0) {
            i = 0;
            while (i < _time.length) {
                balanceP[_from] = sub(balanceP[_from], _value[i]);
                lockTime[_to].length = lockNum[_to]+1;
                lockValue[_to].length = lockNum[_to]+1;
                lockTime[_to][lockNum[_to]] = add(now, _time[i]);
                lockValue[_to][lockNum[_to]] = _value[i];
                emit TransferredLocked(_from, _to, lockTime[_to][lockNum[_to]], lockValue[_to][lockNum[_to]]);
                emit Transfer(_from, _to, lockValue[_to][lockNum[_to]]);
                lockNum[_to]++;
                i++;
            }
            return true;
        }
        else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public validAddress(_from) validAddress(_to) returns (bool success) {
        if (lockNum[_from] > 0) calcUnlock(_from);
        if (balanceP[_from] >= _value && _value > 0) {
            allowance[_from][msg.sender] = sub(allowance[_from][msg.sender], _value);
            balanceP[_from] = sub(balanceP[_from], _value);
            balanceP[_to] = add(balanceP[_to], _value);
            emit Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value) public validAddress(_spender) returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        if (lockNum[msg.sender] > 0) calcUnlock(msg.sender);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function () public payable {
        revert();
    }

}