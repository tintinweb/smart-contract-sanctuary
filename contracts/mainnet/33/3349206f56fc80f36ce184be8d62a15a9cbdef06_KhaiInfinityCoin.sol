pragma solidity 0.4.25;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address  to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address  to, uint256 value) public returns (bool);
    function approve(address  spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DetailedERC20 is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    
    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping(address => uint256) public balances;
    uint256 public _totalSupply;
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0) && _value != 0 &&_value <= balances[msg.sender],"Please check the amount of transmission error and the amount you send.");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract ERC20Token is BasicToken, ERC20 {
    using SafeMath for uint256;
    event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping (address => mapping (address => uint256)) public allowed;
    mapping (address => uint256) public freezeOf;

    function approve(address _spender, uint256 _value) public returns (bool) {
        
        require(_value == 0 || allowed[msg.sender][_spender] == 0,"Please check the amount you want to approve.");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool success) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract Ownable {
    
    address public owner;
    mapping (address => bool) public admin;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner,"I am not the owner of the wallet.");
        _;
    }
    
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || admin[msg.sender] == true,"It is not the owner or manager wallet address.");
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0) && newOwner != owner && admin[newOwner] == true,"It must be the existing manager wallet, not the existing owner's wallet.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function setAdmin(address newAdmin) onlyOwner public {
        require(admin[newAdmin] != true && owner != newAdmin,"It is not an existing administrator wallet, and it must not be the owner wallet of the token.");
        admin[newAdmin] = true;
    }
    
    function unsetAdmin(address Admin) onlyOwner public {
        require(admin[Admin] != false && owner != Admin,"This is an existing admin wallet, it must not be a token holder wallet.");
        admin[Admin] = false;
    }

}

contract Pausable is Ownable {
    event Pause();
    event Unpause();
    bool public paused = false;
    
    modifier whenNotPaused() {
        require(!paused,"There is a pause.");
        _;
    }
    
    modifier whenPaused() {
        require(paused,"It is not paused.");
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

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0; }	
        uint256 c = a * b;
        require(c / a == b,"An error occurred in the calculation process");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b !=0,"The number you want to divide must be non-zero.");
        uint256 c = a / b;
        require(c * b == a,"An error occurred in the calculation process");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a,"There are more to deduct.");
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a,"The number did not increase.");
        return c;
    }
}

contract BurnableToken is BasicToken, Ownable {
    
    event Burn(address indexed burner, uint256 amount);

    function burn(uint256 _value) onlyOwner public {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }

    function burnAddress(address _from, uint256 _value) onlyOwner public {
        balances[_from] = balances[_from].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
    }
}


contract FreezeToken is BasicToken, Ownable {
    
    event Freezen(address indexed freezer, uint256 amount);
    event UnFreezen(address indexed freezer, uint256 amount);
    mapping (address => uint256) public freezeOf;
    
    function freeze(uint256 _value) onlyOwner public {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        freezeOf[msg.sender] = freezeOf[msg.sender].add(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Freezen(msg.sender, _value);
    }
    
    function unfreeze(uint256 _value) onlyOwner public {
        require(_value <= _totalSupply && freezeOf[msg.sender] >= _value,"The number to be processed is more than the total amount and the number currently frozen.");
        balances[msg.sender] = balances[msg.sender].add(_value);
        freezeOf[msg.sender] = freezeOf[msg.sender].sub(_value);
        _totalSupply = _totalSupply.add(_value);
        emit Freezen(msg.sender, _value);
    }
}


contract KhaiInfinityCoin is BurnableToken,FreezeToken, DetailedERC20, ERC20Token,Pausable{
    using SafeMath for uint256;
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event LockerChanged(address indexed owner, uint256 amount);
    event Recall(address indexed owner, uint256 amount);
    event TimeLockerChanged(address indexed owner, uint256 time, uint256 amount);
    event TimeLockerChangedTime(address indexed owner, uint256 time);
    event TimeLockerChangedBalance(address indexed owner, uint256 amount);
    
    mapping(address => uint) public locked;
    mapping(address => uint) public time;
    mapping(address => uint) public timeLocked;
    mapping(address => uint) public unLockAmount;
    
    string public s_symbol = "KHAI";
    string public s_name = "Khai Infinity Coin";
    uint8 public s_decimals = 18;
    uint256 public TOTAL_SUPPLY = 20*(10**8)*(10**uint256(s_decimals));
    
    constructor() DetailedERC20(s_name, s_symbol, s_decimals) public {
        _totalSupply = TOTAL_SUPPLY;
        balances[owner] = _totalSupply;
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }
    
    function transfer(address _to, uint256 _value)  public whenNotPaused returns (bool){
        require(balances[msg.sender].sub(_value) >= locked[msg.sender].add(timeLocked[msg.sender]),"Attempting to send more than the locked number");
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool){
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        
        return true;
        
    }
    
    function lockOf(address _address) public view returns (uint256 _locker) {
        return locked[_address];
    }
    
    function setLock(address _address, uint256 _value) public onlyOwnerOrAdmin {
        require(_value <= _totalSupply &&_address != address(0),"It is the first wallet or attempted to lock an amount greater than the total holding.");
        locked[_address] = _value;
        emit LockerChanged(_address, _value);
    }
    
    function unlock(address _address, uint256 _value) public onlyOwnerOrAdmin {
        require(_value <= _totalSupply &&_address != address(0),"It is the first wallet or attempted to lock an amount greater than the total holding.");
        locked[_address] = locked[_address].sub(_value);
        emit LockerChanged(_address, _value);
    }
    
    function recall(address _from, uint256 _amount) public onlyOwnerOrAdmin {
        require(_amount != 0 ,"The number you want to retrieve is not zero, it must be greater than zero.");
        uint256 currentLocker = locked[_from];
        uint256 currentBalance = balances[_from];
        require(currentLocker >= _amount && currentBalance >= _amount,"The number you wish to collect must be greater than the holding amount and greater than the locked number.");
        
        uint256 newLock = currentLocker.sub(_amount);
        locked[_from] = newLock;
        emit LockerChanged(_from, newLock);
        
        balances[_from] = balances[_from].sub(_amount);
        balances[owner] = balances[owner].add(_amount);
        emit Transfer(_from, owner, _amount);
        emit Recall(_from, _amount);
        
    }
    
    function transferList(address[] _addresses, uint256[] _balances) public onlyOwnerOrAdmin{
        require(_addresses.length == _balances.length,"The number of wallet arrangements and the number of amounts are different.");
        
        for (uint i=0; i < _addresses.length; i++) {
            balances[msg.sender] = balances[msg.sender].sub(_balances[i]);
            balances[_addresses[i]] = balances[_addresses[i]].add(_balances[i]);
            emit Transfer(msg.sender,_addresses[i],_balances[i]);
        }
    }
    
    function setLockList(address[] _recipients, uint256[] _balances) public onlyOwnerOrAdmin{
        require(_recipients.length == _balances.length,"The number of wallet arrangements and the number of amounts are different.");
        
        for (uint i=0; i < _recipients.length; i++) {
            locked[_recipients[i]] = _balances[i];
            emit LockerChanged(_recipients[i], _balances[i]);
        }
    }
    /**
	* @dev timeLock 10% of the lock quantity is deducted from the customer's wallet every specific time.
	* @param _address Lockable wallet
	* @param _time The time the lock is released
	* @param _value Number of locks
	*/
 
	
    function timeLock(address _address,uint256 _time, uint256 _value) public onlyOwnerOrAdmin{
        require(_address != address(0),"Same as the original wallet address.");
        
		// Divide by 10 to find the number to be subtracted.
        uint256 unlockAmount = _value.div(10);
        
        time[_address] = _time;
		
		//Add the locked count.
        timeLocked[_address] = timeLocked[_address].add(_value);
		
		//unLockAmount Adds the number to be released.
        unLockAmount[_address] = unLockAmount[_address].add(unlockAmount);
		
        emit TimeLockerChanged(_address,_time,_value);
    }
    
    function lockTimeStatus(address _address) public view returns (uint256 _time) {
        return time[_address];
    }
    
    function lockTimeAmountOf(address _address) public view returns (uint256 _value) {
        return unLockAmount[_address];
    }
    
    function lockTimeBalanceOf(address _address) public view returns (uint256 _value) {
        return timeLocked[_address];
    }
    
    function untimeLock(address _address) public onlyOwnerOrAdmin{
        require(_address != address(0),"Same as the original wallet address.");
        
        uint256 unlockAmount = unLockAmount[_address];
        uint256 nextTime = block.timestamp + 30 days;
        time[_address] = nextTime;
        timeLocked[_address] = timeLocked[_address].sub(unlockAmount);
        
        emit TimeLockerChanged(_address,nextTime,unlockAmount);
    }
    
    function timeLockList(address[] _addresses,uint256[] _time, uint256[] _value) public onlyOwnerOrAdmin{
        require(_addresses.length == _value.length && _addresses.length == _time.length); 
        
        for (uint i=0; i < _addresses.length; i++) {
            uint256 unlockAmount = _value[i].div(10);
            time[_addresses[i]] = _time[i];
            timeLocked[_addresses[i]] = timeLocked[_addresses[i]].add(_value[i]);
            unLockAmount[_addresses[i]] = unLockAmount[_addresses[i]].add(unlockAmount);
            emit TimeLockerChanged(_addresses[i],_time[i],_value[i]);    
        }
    }
    
    function unTimeLockList(address[] _addresses) public onlyOwnerOrAdmin{
        
        for (uint i=0; i < _addresses.length; i++) {
            uint256 unlockAmount = unLockAmount[_addresses[i]];
            uint256 nextTime = block.timestamp + 30 days;
            time[_addresses[i]] = nextTime;
            timeLocked[_addresses[i]] = timeLocked[_addresses[i]].sub(unlockAmount);
            emit TimeLockerChanged(_addresses[i],nextTime,unlockAmount);
        }
    }
    
    function timeLockSetTime(address _address,uint256 _time) public onlyOwnerOrAdmin{
        require(_address != address(0),"Same as the original wallet address.");
        
        time[_address] = _time;
        emit TimeLockerChangedTime(_address,_time);

    }
    
    function timeLockSetBalance(address _address,uint256 _value) public onlyOwnerOrAdmin{
        require(_address != address(0),"Same as the original wallet address.");
        
        timeLocked[_address] = _value;
        emit TimeLockerChangedBalance(_address,_value);
    }
    
    function() public payable {
        revert();
    }
}