/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

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

contract Manager is Ownable {
    
    address[] managers;

    modifier onlyManagers() {
        bool exist = false;
        if(owner == msg.sender) {
            exist = true;
        } else {
            uint index = 0;
            (exist, index) = existManager(msg.sender);
        }
        require(exist);
        _;
    }
    
    function getManagers() public view returns (address[] memory){
        return managers;
    }
    
    function existManager(address _to) private view returns (bool, uint) {
        for (uint i = 0 ; i < managers.length; i++) {
            if (managers[i] == _to) {
                return (true, i);
            }
        }
        return (false, 0);
    }
    function addManager(address _to) onlyOwner public {
        bool exist = false;
        uint index = 0;
        (exist, index) = existManager(_to);
        
        require(!exist);
        
        managers.push(_to);
    }
    function deleteManager(address _to) onlyOwner public {
        bool exist = false;
        uint index = 0;
        (exist, index) = existManager(_to);
        
        require(exist);
   
        uint lastElementIndex = managers.length - 1; 
        managers[index] = managers[lastElementIndex];

        delete managers[managers.length - 1];
        managers.length--;
    }

}

contract Pausable is Manager {
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

    function pause() onlyManagers whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyManagers whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Token is ERC20, Pausable {

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

  

    mapping(address => sUserInfo) user;

    event Burn(uint256 value);

    function () public payable {
        revert();
    }
    
    function validTransfer(address _from, address _to, uint256 _value, bool _lockCheck) internal view returns (bool) {
        require(_to != address(this));
        require(_to != address(0));
        require(user[_from].balance >= _value);
        if(_lockCheck) {
            require(user[_from].lock == false);
        }
    }

    function lock(address _owner) public onlyManagers returns (bool) {
        require(user[_owner].lock == false);

        user[_owner].lock = true;
        return true;
    }
    function unlock(address _owner) public onlyManagers returns (bool) {
        require(user[_owner].lock == true);
        user[_owner].lock = false;
       return true;
    }
 
    function burn(uint256 _value) public onlyOwner returns (bool) {
        require(_value <= user[msg.sender].balance);
        user[msg.sender].balance = user[msg.sender].balance.sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_value);
        return true;
    }
    function mint(uint256 _value) public onlyOwner returns (bool) {
        require(_value > 0);
        user[msg.sender].balance = user[msg.sender].balance.add(_value);
        totalSupply = totalSupply.add(_value);
        emit Transfer(address(0), msg.sender, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(_value == 0 || user[msg.sender].allowed[_spender] == 0); 
        user[msg.sender].allowed[_spender] = _value; 
        emit Approval(msg.sender, _spender, _value);
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
    
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        validTransfer(msg.sender, _to, _value, true);

        user[msg.sender].balance = user[msg.sender].balance.sub(_value);
        user[_to].balance = user[_to].balance.add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferMulti(address[] _to, uint256[] _value) public whenNotPaused returns (bool) {
        require(_to.length == _value.length);
        
        for(uint256 i = 0; i < _value.length; i++){
           transfer(_to[i], _value[i]);
        }
        
        return true;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    function balanceOf(address _owner) public view returns (uint256) {
        return user[_owner].balance;
    }
    function lockState(address _owner) public view returns (bool) {
        return user[_owner].lock;
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return user[_owner].allowed[_spender];
    }
    
}

contract LockBalance is Manager {
    

    struct sLockInfo {
        uint256[] lockBalanceStandard;
        uint256[] startTime;
        uint256[] endTime;
    }
    
    using SafeMath for uint256;

    mapping(address => sLockInfo) lockUser;

    event Lock(address indexed from, uint256 value, uint256 endTime);
    
    function setLockUser(address _to, uint256 _value, uint256 _endTime) onlyManagers public {
        require(_endTime > now); 
        require(_value > 0); 
        lockUser[_to].lockBalanceStandard.push(_value);
        lockUser[_to].startTime.push(now);
        lockUser[_to].endTime.push(_endTime);

        emit Lock(_to, _value, _endTime);
    }
    function setLockUserMulti(address[] _to, uint256[] _value, uint256[] _endTime) onlyManagers public {  
        require(_to.length > 0);
        require(_to.length == _value.length);
        require(_to.length == _endTime.length);
       
        for(uint256 i = 0; i < _to.length; i++){
            setLockUser(_to[i], _value[i], _endTime[i]);
        }
    }
    
  
    function lockBalanceIndividual(address _owner, uint _index) internal view returns (uint256) {
        if(now < lockUser[_owner].endTime[_index]) {
            return lockUser[_owner].lockBalanceStandard[_index];
        } else {
            return 0;
        }
    }
        

    function deleteLockUserInfo(address _to, uint256 _startTime, uint256 _endTime) onlyManagers public {

        bool isExists = false;
        uint256 index = 0;
        for(uint256 i = 0; i < lockUser[_to].startTime.length; i++) {
            if(lockUser[_to].startTime[i] == _startTime && lockUser[_to].endTime[i] == _endTime) {
                isExists = true;
                index = i;
                break;
            }
        }
        require(isExists);

        for(uint256 k = index; k < lockUser[_to].startTime.length - 1; k++){
            lockUser[_to].lockBalanceStandard[k] = lockUser[_to].lockBalanceStandard[k + 1];
            lockUser[_to].startTime[k] = lockUser[_to].startTime[k + 1];
            lockUser[_to].endTime[k] = lockUser[_to].endTime[k + 1];
        }

        delete lockUser[_to].lockBalanceStandard[lockUser[_to].lockBalanceStandard.length - 1];
        lockUser[_to].lockBalanceStandard.length--;
        
        delete lockUser[_to].startTime[lockUser[_to].startTime.length - 1];
        lockUser[_to].startTime.length--;
        
        delete lockUser[_to].endTime[lockUser[_to].endTime.length - 1];
        lockUser[_to].endTime.length--;
        
    }
    function deleteLockUserInfos(address _to, uint256[] _startTime, uint256[] _endTime) onlyManagers public {
        require(_startTime.length == _endTime.length);
        for(uint256 i = 0; i < _startTime.length; i++){
            deleteLockUserInfo(_to, _startTime[i], _endTime[i]);
        }
    }

   
    function lockUserInfo(address _owner) public view returns (uint256[], uint256[], uint256[], uint256[]) {
        
        uint256[] memory balance = new uint256[](lockUser[_owner].lockBalanceStandard.length);
        for(uint256 i = 0; i < lockUser[_owner].lockBalanceStandard.length; i++){
            balance[i] = balance[i].add(lockBalanceIndividual(_owner, i));
        }
        
        return (
        lockUser[_owner].lockBalanceStandard,
        balance,
        lockUser[_owner].startTime,
        lockUser[_owner].endTime);
    }
    function lockBalanceAll(address _owner) public view returns (uint256) {
        uint256 lockBalance = 0;
        for(uint256 i = 0; i < lockUser[_owner].lockBalanceStandard.length; i++){
            lockBalance = lockBalance.add(lockBalanceIndividual(_owner, i));
        }
        return lockBalance;
    }
    
}

contract LockBalanceSingle is Manager {
    
    using SafeMath for uint256;

    mapping(address => uint256) lockUserSingle;

    event LockSingle(address indexed from, uint256 value);
    
    function setLockUserSingle(address _to, uint256 _value) onlyManagers public {
        require(_to != address(0));
        
        lockUserSingle[_to] = _value;
        
        emit LockSingle(_to, _value);
    }
    function setLockUserSingleMulti(address[] _to, uint256[] _value) onlyManagers public {  
        require(_to.length == _value.length);
   
        for(uint256 i = 0; i < _to.length; i++){
            setLockUserSingle(_to[i], _value[i]);
        }
    }
   
    function lockBalanceSingle(address _owner) public view returns (uint256) {
        return lockUserSingle[_owner];
    }
   
}

contract StandardToken is Token, LockBalance, LockBalanceSingle {

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 supply_) public {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        uint256 initialSupply = supply_;
        totalSupply = initialSupply * 10 ** uint(decimals);
        user[owner].balance = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }


    bool public finishRestore = false; 
    
    function isFinishRestore() public onlyOwner { 
        finishRestore = true; 
    }     
  
    function validTransfer(address _from, address _to, uint256 _value, bool _lockCheck) internal view returns (bool) {
        super.validTransfer(_from, _to, _value, _lockCheck);
        if(_lockCheck) {
            require(_value <= useBalanceOf(_from));
        }
    }

    function transferWithtLockUser(address _to, uint256 _amount, uint256[] _lockAmount, uint256[] _endTime) onlyManagers public {  
        require(_lockAmount.length > 0);
        require(_lockAmount.length == _endTime.length);
        
        transfer(_to, _amount);
        
        for(uint256 i = 0; i < _lockAmount.length; i++){
            setLockUser(_to, _lockAmount[i], _endTime[i]);
        }
        
    }
    
    function transferWithtLockUserSingle(address _to, uint256 _amount, uint256 _lockAmount) onlyManagers public {  

        transfer(_to, _amount);
        setLockUserSingle(_to, _lockAmount);
        
    }
    
    function transferWithtLockUserSingleMulti(address[] _to, uint256[] _amount, uint256[] _lockAmount) onlyManagers public {  
        require(_to.length > 0);
        require(_to.length == _amount.length);
        require(_amount.length == _lockAmount.length);
        
        for(uint256 i = 0; i < _amount.length; i++){
            transfer(_to[i], _amount[i]);
            setLockUserSingle(_to[i], _lockAmount[i]);
        }
        
        
    }

    function transferRestore(address _from, address _to, uint256 _value) public onlyOwner returns (bool) {
        require(!finishRestore);

        require(_to != address(this));
        require(_to != address(0));
        require(user[_from].balance >= _value);
        
        user[_from].balance = user[_from].balance.sub(_value);
        user[_to].balance = user[_to].balance.add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }
    function useBalanceOf(address _owner) public view returns (uint256) {
        return balanceOf(_owner).sub(lockBalanceAll(_owner)).sub(lockBalanceSingle(_owner));
    }
  

}