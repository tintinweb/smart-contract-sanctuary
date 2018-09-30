pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(uint256 value);
    event Burn(uint256 value);
}

contract Token is ERC20, Ownable, Pausable {

    struct sUserInfo {
        uint256 balance;
        bool lock;
        mapping(address => uint256) allowed;
    }
    
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => sUserInfo) public user;

    constructor() public {
        name = "TOKEN";
        symbol = "TK";
        decimals = 18;
        uint256 initialSupply = 10000;
        totalSupply = initialSupply * 10 ** uint(decimals);
        user[owner].balance = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function () public payable {
        revert();
    }
    

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return user[_owner].balance;
    }

    function lockState(address _owner) public view returns (bool) {
        return user[_owner].lock;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return user[_owner].allowed[_spender];
    }

    function lock(address _owner) public onlyOwner returns (bool) {
        require(user[_owner].lock == false);
        user[_owner].lock = true;
        return true;
    }

    function unlock(address _owner) public onlyOwner returns (bool) {
        require(user[_owner].lock == true);
        user[_owner].lock = false;
        return true;
    }

    function mint(uint256 _amount) onlyOwner public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        user[owner].balance = user[owner].balance.add(_amount);
        emit Mint(_amount);
        return true;
    }
    
    function burn(address _to, uint256 _value) public onlyOwner returns (bool) {
        require(_value <= user[_to].balance);
        user[_to].balance = user[_to].balance.sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_value);
        return true;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(_value > 0);
        user[msg.sender].allowed[_spender] = _value; 
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function validTransfer(address _from, address _to, uint256 _value, bool _lockCheck) internal {
        require(_from != address(0));
        require(_to != address(0));
        require(user[_from].balance >= _value);
        if(_lockCheck) {
            require(user[_from].lock == false);
        }
    }
    
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        validTransfer(msg.sender, _to, _value, true);

        user[msg.sender].balance = user[msg.sender].balance.sub(_value);
        user[_to].balance = user[_to].balance.add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        validTransfer(_from, _to, _value, true);
        require(_value <=  user[_from].allowed[msg.sender]);

        user[_from].balance = user[_from].balance.sub(_value);
        user[_to].balance = user[_to].balance.add(_value);

        user[_from].allowed[msg.sender] = user[_from].allowed[msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function distribute(address _to, uint256 _value) public onlyOwner returns (bool) {
        validTransfer(owner, _to, _value, false);
       
        user[owner].balance = user[owner].balance.sub(_value);
        user[_to].balance = user[_to].balance.add(_value);
       
        emit Transfer(owner, _to, _value);
        return true;
    }
}

contract LockBalance is Ownable {
    
    enum eLockType {None, Atype, Btype, Ctype, Dtype, Etype}
    
    struct sLockDate {
        uint256 goalTime;
        uint256[] lockTime;
        uint8[] lockPercent;
    }
    
    struct sLockInfo {
        eLockType lockType;
        uint256 lockBalance;
        uint256 lockBalanceStandard;
    }
    
    using SafeMath for uint256;

    mapping(uint => sLockDate) lockDate;
    mapping(address => sLockInfo) lockUser;

    constructor() public {

        addLockDate(eLockType.Atype,            0, 100);
        lockDate[uint(eLockType.Atype)].goalTime = 9999999999;//2019.10.1

        addLockDate(eLockType.Btype, 210 * 1 days, 100);
        addLockDate(eLockType.Btype, 180 * 1 days, 80);
        addLockDate(eLockType.Btype, 150 * 1 days, 70);
        addLockDate(eLockType.Btype, 120 * 1 days, 50);
        addLockDate(eLockType.Btype,  90 * 1 days, 30);
        addLockDate(eLockType.Btype,  60 * 1 days, 20);
        addLockDate(eLockType.Btype,  30 * 1 days, 10);
        lockDate[uint(eLockType.Btype)].goalTime = 9999999999;//2019.7.1
    }
    
    function addLockDate(eLockType _lockType, uint256 _second, uint8 _percent) onlyOwner public {
        sLockDate storage lockInfo = lockDate[uint(_lockType)];

        bool isExists = false;
        for(uint i = 0; i < lockInfo.lockTime.length; i++) {
            if(lockInfo.lockTime[i] == _second) {
                isExists = true;
                break;
            }
        }
        if(!isExists) {
            lockInfo.lockTime.push(_second);
            lockInfo.lockPercent.push(_percent);
        }
    }
    
    function deleteLockDate(eLockType _lockType, uint256 _second) onlyOwner public {
        sLockDate storage lockInfo = lockDate[uint(_lockType)];
        
        bool isExists = false;
        uint index = 0;
        for(uint i = 0; i < lockInfo.lockTime.length; i++) {
            if(lockInfo.lockTime[i] == _second) {
                isExists = true;
                index = i;
                break;
            }
        }
        
        if(isExists) {
            for (uint k = index; k < lockInfo.lockTime.length - 1; k++){
                lockInfo.lockTime[k] = lockInfo.lockTime[k + 1];
                lockInfo.lockPercent[k] = lockInfo.lockPercent[k + 1];
            }
            delete lockInfo.lockTime[lockInfo.lockTime.length - 1];
            lockInfo.lockTime.length--;
            delete lockInfo.lockPercent[lockInfo.lockPercent.length - 1];
            lockInfo.lockPercent.length--;
        }
        
    }
    
    function setGoalTime(eLockType _type, uint256 _timeStamp) onlyOwner public {
        lockDate[uint(_type)].goalTime = _timeStamp;
    }


    function setLockUser(address _to, eLockType _lockType, uint256 _value) onlyOwner public {
        
        lockUser[_to].lockType = _lockType;
        lockUser[_to].lockBalanceStandard = _value;
        
        setLockBalance(_to);
    }
    
    function setLockBalance(address _owner) internal {
        uint256 curLockBalance = lockBalance(_owner);
        if(curLockBalance != lockUser[_owner].lockBalance ) {
            lockUser[_owner].lockBalance = curLockBalance;
        }
    }
    
    function lockBalance(address _owner) internal returns (uint256) {
        uint8 percent = 0;
        uint256 nowTime = now;
        
        if(lockUser[_owner].lockType != eLockType.None) {
            sLockDate storage lockInfo = lockDate[uint(lockUser[_owner].lockType)];
            
            if(lockInfo.goalTime > nowTime) {
                uint256 remain = lockInfo.goalTime.sub(nowTime);
            
                for (uint i = 0 ; i < lockInfo.lockTime.length; i++) {
                    if(remain > lockInfo.lockTime[i]) {
                        if(percent < lockInfo.lockPercent[i]){
                            percent = lockInfo.lockPercent[i];
                            break;
                        }
                    }
                }//for
                
            }
        }
        if(percent == 0){
            return 0;
        } else {
            return lockUser[_owner].lockBalanceStandard.div(100).mul(percent);
        }
    }

    function lockTypeInfo(eLockType _type) public view returns (uint256, uint256[], uint8[]) {
        uint key = uint(_type);
        return (lockDate[key].goalTime, lockDate[key].lockTime, lockDate[key].lockPercent);
    }
    
    function lockUserInfo(address _owner) public view returns (uint, uint256, uint256) {
        return (uint(lockUser[_owner].lockType), lockUser[_owner].lockBalanceStandard, lockUser[_owner].lockBalance);
    }
}

contract HenaCoin is Token, LockBalance {
    
    address[] specialUser;

    bool internalRefreshLock = false;
    
    event LockUser(eLockType _type, address[] _to);

    constructor() public {
        name = "HenaCoin";
        symbol = "HENA";
        decimals = 18;
        uint256 initialSupply = 150000000;
        totalSupply = initialSupply * 10 ** uint(decimals);
        user[owner].balance = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function validTransfer(address _from, address _to, uint256 _value, bool _lockCheck) internal {
        
        super.validTransfer(_from, _to, _value, _lockCheck);
        
        if(_lockCheck && lockUser[_from].lockBalance > 0) {
            if(internalRefreshLock) {
                setLockBalance(_from);   
            }
            require(user[_from].balance >= lockUser[_from].lockBalance.add(_value));    
        }
    }
        
    function setInterRefreshLock(bool _lock) onlyOwner public {
        internalRefreshLock = _lock;
    }
    
    function setRefreshLockBalance(address _owner) onlyOwner public {
        setLockBalance(_owner);
    }

    function setLockUser(eLockType _type, address[] _to) onlyOwner public {  
        for(uint i = 0; i < _to.length; i++){
            setLockUser(_to[i], _type, balanceOf(_to[i]));
        }
        
        emit LockUser(_type, _to);
    }
        
    function distributeSpecial(address _to, uint256 _value) onlyOwner public returns (bool) {
        
        bool result = distribute(_to, _value);
        
        setLockUser(_to, eLockType.Atype, balanceOf(_to));
        
        bool isContain = false;
        for (uint i = 0 ; i < specialUser.length; i++) {
            if (specialUser[i] == _to) {
                isContain = true;
                break;
            }
        }
        if(!isContain)
            specialUser.push(_to);

        return result;
    }
      
    function useBalanceOf(address _owner) public view returns (uint256) {
        return balanceOf(_owner).sub(lockBalance(_owner));
    }
    
    function specialUsers() public view returns (address[]){
        return specialUser;
    }
    
    function interRefreshLock() public view returns (bool) {
        return internalRefreshLock;
    }
}