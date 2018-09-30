pragma solidity ^0.4.24;

/*
*
*
*
*   _  ___               _____
*  (_)/ __|__ _ _ __  __|_   _| _ ___ ___
*  | | (_ / _` | &#39;  \/ -_)| || &#39;_/ -_) -_)
*  |_|\___\__,_|_|_|_\___||_||_| \___\___|
*
*
*
*/

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

// SafeMath methods
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

// Standard ERC20 Token Interface
interface ERC20Token {
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function decimals() external view returns (uint8 _decimals);
    function totalSupply() external view returns (uint256 _totalSupply);
    function balanceOf(address _owner) external view returns (uint256 _balance);
    function transfer(address _to, uint256 _value) external returns (bool _success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
    function approve(address _spender, uint256 _value) external returns (bool _success);
    function allowance(address _owner, address _spender) external view returns (uint256 _remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// the main ERC20-compliant multi-timelock enabled contract
contract iGameTree is SafeMath, Owned, ERC20Token {
    string private constant standard = "0.242";
    string private constant version = "v3.0x";
    string private _name = "igametree";
    string private _symbol = "IGT";
    uint8 private _decimals = 4;
    uint256 private _totalSupply = 2 * 10**8 * uint256(10)**_decimals;
    mapping (address => uint256) private balanceP;
    mapping (address => mapping (address => uint256)) private _allowance;

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
        balanceP[msg.sender] = _totalSupply;
    }

    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // fast-forward the timelocks for all accounts
    function setUnlockEarlier(uint256 _earlier) public onlyOwner {
        earlier = add(earlier, _earlier);
    }

    // delay the timelocks for all accounts
    function setUnlockLater(uint256 _later) public onlyOwner {
        later = add(later, _later);
    }

    // standard ERC20 name function
    function name() public view returns (string) {
        return _name;
    }

    // standard ERC20 symbol function
    function symbol() public view returns (string) {
        return _symbol;
    }

    // standard ERC20 decimals function
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // standard ERC20 totalSupply function
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // standard ERC20 allowance function
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return _allowance[_owner][_spender];
    }

    // show unlocked balance of an account
    function balanceUnlocked(address _address) public view returns (uint256 _balance) {
        _balance = balanceP[_address];
        uint256 i = 0;
        while (i < lockNum[_address]) {
            if (add(now, earlier) >= add(lockTime[_address][i], later)) _balance = add(_balance, lockValue[_address][i]);
            i++;
        }
        return _balance;
    }

    // show timelocked balance of an account
    function balanceLocked(address _address) public view returns (uint256 _balance) {
        _balance = 0;
        uint256 i = 0;
        while (i < lockNum[_address]) {
            if (add(now, earlier) < add(lockTime[_address][i], later)) _balance = add(_balance, lockValue[_address][i]);
            i++;
        }
        return  _balance;
    }

    // standard ERC20 balanceOf with timelock added
    function balanceOf(address _address) public view returns (uint256 _balance) {
        _balance = balanceP[_address];
        uint256 i = 0;
        while (i < lockNum[_address]) {
            _balance = add(_balance, lockValue[_address][i]);
            i++;
        }
        return _balance;
    }

    // show timelocks in an account
    function showLockTimes(address _address) public view validAddress(_address) returns (uint256[] _times) {
        uint i = 0;
        uint256[] memory tempLockTime = new uint256[](lockNum[_address]);
        while (i < lockNum[_address]) {
            tempLockTime[i] = sub(add(lockTime[_address][i], later), earlier);
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
            if (add(now, earlier) >= add(currentLockTime[i], later)) {
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

    // standard ERC20 transfer
    function transfer(address _to, uint256 _value) public validAddress(_to) returns (bool _success) {
        if (lockNum[msg.sender] > 0) calcUnlock(msg.sender);
        require(balanceP[msg.sender] >= _value && _value >= 0);
        balanceP[msg.sender] = sub(balanceP[msg.sender], _value);
        balanceP[_to] = add(balanceP[_to], _value);
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
            totalValue = add(totalValue, _value[i]);
            i++;
        }
        require(balanceP[msg.sender] >= totalValue && totalValue >= 0);
        require(add(lockNum[msg.sender], _time.length) <= 42);
        i = 0;
        while (i < _time.length) {
            if (_value[i] > 0) {
                balanceP[msg.sender] = sub(balanceP[msg.sender], _value[i]);
                lockTime[_to].length = lockNum[_to]+1;
                lockValue[_to].length = lockNum[_to]+1;
                lockTime[_to][lockNum[_to]] = sub(add(add(now, _time[i]), earlier), later);
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
            totalValue = add(totalValue, _value[i]);
            i++;
        }
        require(balanceP[_from] >= totalValue && totalValue >= 0 && _allowance[_from][msg.sender] >= totalValue);
        require(add(lockNum[_from], _time.length) <= 42);
        i = 0;
        while (i < _time.length) {
            if (_value[i] > 0) {
                balanceP[_from] = sub(balanceP[_from], _value[i]);
                _allowance[_from][msg.sender] = sub(_allowance[_from][msg.sender], _value[i]);
                lockTime[_to].length = lockNum[_to]+1;
                lockValue[_to].length = lockNum[_to]+1;
                lockTime[_to][lockNum[_to]] = sub(add(add(now, _time[i]), earlier), later);
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
        require(balanceP[_from] >= _value && _value >= 0 && _allowance[_from][msg.sender] >= _value);
        _allowance[_from][msg.sender] = sub(_allowance[_from][msg.sender], _value);
        balanceP[_from] = sub(balanceP[_from], _value);
        balanceP[_to] = add(balanceP[_to], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    // should only be called when first setting an _allowance
    function approve(address _spender, uint256 _value) public validAddress(_spender) returns (bool _success) {
        if (lockNum[msg.sender] > 0) calcUnlock(msg.sender);
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // increase or decrease _allowance
    function increaseApproval(address _spender, uint _value) public validAddress(_spender) returns (bool _success) {
        _allowance[msg.sender][_spender] = add(_allowance[msg.sender][_spender], _value);
        emit Approval(msg.sender, _spender, _allowance[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _value) public validAddress(_spender) returns (bool _success) {
        if(_value >= _allowance[msg.sender][_spender]) {
            _allowance[msg.sender][_spender] = 0;
        } else {
            _allowance[msg.sender][_spender] = sub(_allowance[msg.sender][_spender], _value);
        }
        emit Approval(msg.sender, _spender, _allowance[msg.sender][_spender]);
        return true;
    }

    // owner may burn own token
    function burn(uint256 _value) public onlyOwner returns (bool _success) {
        if (lockNum[msg.sender] > 0) calcUnlock(msg.sender);
        require(balanceP[msg.sender] >= _value && _value >= 0);
        balanceP[msg.sender] = sub(balanceP[msg.sender], _value);
        _totalSupply = sub(_totalSupply, _value);
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