/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

/**
 *Paralism.com EPARA Token V1 on Ethereum
*/
pragma solidity >=0.6.4 <0.8.0;

/**
 * Math operations with safety checks
 */
library SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'add() overflow!');
    }

    function safeSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'sub() underflow!');
    }
    
    function toUint64(uint256 _value) internal pure returns (uint64 z){
        require(_value < 2**64, "toUint64() overflow!");
        return uint64(_value);
    }
}

contract EPARA {
    using SafeMath for uint;
    using SafeMath for uint64;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalLocked;
    uint256 internal _supplyCap;

    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => TokensWithLock) public lock;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event UnFreeze(address indexed from, uint256 value);

    event TransferWithLock(address indexed sender, address indexed owner, uint256 value, uint256 lockTime ,uint256 initLockDays);
    event ReturnLockedTokens(address indexed owner, address indexed sender, uint256 value);
    event UpdateLockTime(address indexed sender, address indexed owner, uint256 lockDays);
    event AllowUpdateLock(address indexed owner, bool allow);
    event RequestToLock(address indexed sender, address indexed owner, uint256 value, uint256 intLockDays);
    event AcceptLock(address indexed owner,address indexed sender, uint256 value, uint256 lockTime);
    event ReduceLockValue(address indexed sender, address indexed owner, uint256 value);

    struct TokensWithLock {
        address sender;
        uint256 lockValue;
        uint64 lockTime;
        bool allowLockTimeUpdate;      
        uint64 initAskTime;
        uint256 askToLock;
    }

    /* Initializes contract with initial supply tokens */
    constructor() public {
        name = "Paralism-EPARA";
        symbol = "EPARA";
        decimals = 9;
        _supplyCap = 21000*10000*(10**9);  //210M
        totalLocked = 0;
        balanceOf[msg.sender] = _supplyCap;         
    }

    function totalSupply() public view returns (uint256){
        return _supplyCap - totalLocked;
    }

    /* Send Tokens */
    function transfer(address _to, uint256 _value) public returns (bool success){
        if (_to == address(0)) revert("transfert to address 0");
        if (balanceOf[msg.sender] < theLockValue(msg.sender).safeAdd(_value)) revert("insufficient balance or locked");

        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);
        balanceOf[_to] = balanceOf[_to].safeAdd(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /* Athorize another address to spend some tokens on your behalf */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /* An athorized address attempts to get the approved amount of tokens */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_to == address(0)) revert("transfert to address 0");
        if (_value > allowance[_from][msg.sender]) revert("transfer more than allowance");
        if (balanceOf[_from] < theLockValue(_from).safeAdd(_value)) revert("insufficient balance or locked");

        allowance[_from][msg.sender] = allowance[_from][msg.sender].safeSub(_value);
        balanceOf[_from] = balanceOf[_from].safeSub(_value);
        balanceOf[_to] = balanceOf[_to].safeAdd(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        if (balanceOf[msg.sender] < theLockValue(msg.sender).safeAdd(_value)) revert("insufficient balance or locked");

        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);
        _supplyCap = _supplyCap.safeSub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function freeze(uint256 _value) public returns (bool success) {
        if (balanceOf[msg.sender] < _value) revert("insufficient balance");

        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);
        freezeOf[msg.sender] = freezeOf[msg.sender].safeAdd(_value);
        emit Freeze(msg.sender, _value);
        return true;
    }

    function unfreeze(uint256 _value) public returns (bool success) {
        if (freezeOf[msg.sender] < _value) revert("insufficient balance.");

        freezeOf[msg.sender] = freezeOf[msg.sender].safeSub(_value);
        balanceOf[msg.sender] = balanceOf[msg.sender].safeAdd(_value);
        emit UnFreeze(msg.sender, _value);
        return true;
    }

    function transferWithLockInit(address _to, uint256 _value, uint256 _initLockdays) public returns (bool success) {
        require(address(0) != _to,"transfer to address 0");

        if (balanceOf[msg.sender] < theLockValue(msg.sender).safeAdd(_value)) revert("insufficient balance or locked");

        if (0 < theLockValue(_to)) {
            require (msg.sender == lock[_to].sender,"others lock detected") ;
            require (_initLockdays == 0,"Lock detected, init fail") ;
        }

        if (0 == theLockValue(_to)) {
            lock[_to].lockTime = (block.timestamp.safeAdd(_initLockdays * 1 days)).toUint64();           //init expriation day.
            lock[_to].sender= msg.sender;                                                   //init sender
        }

        lock[_to].lockValue = lock[_to].lockValue.safeAdd(_value);                          //add lock value
        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);                      //subtract from the sender
        balanceOf[_to] = balanceOf[_to].safeAdd(_value);                                    //add to the recipient
        
        if (true == lock[_to].allowLockTimeUpdate) 
            lock[_to].allowLockTimeUpdate = false;                                         //disable sender change lock time until owner allowed again
        
        emit TransferWithLock(msg.sender, _to, _value, lock[_to].lockTime , _initLockdays);

        totalLocked = totalLocked.safeAdd(_value);    //increase totalLocked
        return true;
    }

    function transferMoreToLock(address _to, uint256 _value) public returns (bool success) {
        if(0 == theLockValue(_to)) revert("NO lock detected");
        return transferWithLockInit(_to,_value,0);
    }

    /*get locked balance*/
    function theLockValue(address _addr) internal returns (uint256 amount){
        if (lock[_addr].lockTime <= block.timestamp) {
            totalLocked = totalLocked.safeSub(lock[_addr].lockValue);           //reduce totalLocked
            lock[_addr].lockValue = 0;                      //reset expired value
        }
        return lock[_addr].lockValue;
    }

    /*get locked balance*/
    function getLockValue(address _addr) public view returns (uint256 amount){
        lock[_addr].lockTime > block.timestamp ? amount = lock[_addr].lockValue : amount = 0;
    }

    /*get lock remaining seconds*/
    function getLockRemainSeconds(address _addr) public view returns (uint256 sec){
        lock[_addr].lockTime > block.timestamp ? sec = lock[_addr].lockTime - block.timestamp : sec = 0;
    }

    /*only with owner permission, locked amount sender can update lock time */
    function updateLockTime(address _addr, uint256 _days)public returns (bool success) {
        require(theLockValue(_addr) > 0,"NO lock detected");
        require(msg.sender == lock[_addr].sender, "others lock detected");
        require(true == lock[_addr].allowLockTimeUpdate,"allowUpdateLockTime is false");

        lock[_addr].lockTime = (block.timestamp.safeAdd(_days * 1 days)).toUint64();
        lock[_addr].allowLockTimeUpdate = false;
        emit UpdateLockTime(msg.sender, _addr, _days);
        return true;
    }

    /*Owner switch on or off to enable lock amount sender update lock time or not*/
    function allowUpdateLockTime(bool _allow) public returns (bool success){
        lock[msg.sender].allowLockTimeUpdate = _allow;
        emit AllowUpdateLock(msg.sender, _allow);
        return true;
    }

    /*receiver can return locked amount to the sender*/
    function returnLockedTokens(uint256 _value) public returns (bool success){
        address _returnTo = lock[msg.sender].sender;
        address _returnFrom = msg.sender;

        uint256 lockValue = theLockValue(_returnFrom);
        require(0 < lockValue, "NO lock detected");
        require(_value <= lockValue,"insufficient lock value");
        require(balanceOf[_returnFrom] >= _value,"insufficient balance");

        balanceOf[_returnFrom] = balanceOf[_returnFrom].safeSub(_value);
        balanceOf[_returnTo] = balanceOf[_returnTo].safeAdd(_value);

        lock[_returnFrom].lockValue = lock[_returnFrom].lockValue.safeSub(_value);   //reduce locked amount

        emit ReturnLockedTokens(_returnFrom, _returnTo, _value);

        totalLocked = totalLocked.safeSub(_value);  //reduce totalLocked
        return true;
    }

    function askToLock(address _to, uint256 _value, uint256 _initLockdays) public returns(bool success) {
        require(balanceOf[_to] >= theLockValue(_to).safeAdd(_value), "insufficient balance to lock");
        if (0 < theLockValue(_to)) {
            require (msg.sender == lock[_to].sender,"others lock detected") ;
            require (_initLockdays == 0,"lock time exist") ;
        }
        lock[_to].askToLock = _value;
        lock[_to].initAskTime = (block.timestamp + _initLockdays * 1 days).toUint64();
        lock[_to].sender = msg.sender;
        
        emit RequestToLock(msg.sender, _to, _value, _initLockdays);
        return true;
    }

    function acceptLockReq(address _sender, uint256 _value) public returns(bool success) {
        require(lock[msg.sender].askToLock == _value,"value incorrect");
        require(balanceOf[msg.sender] >= theLockValue(msg.sender).safeAdd(_value), "insufficient balance or locked");//
        require(_sender == lock[msg.sender].sender,"sender incorrect");

        if(0 == theLockValue(msg.sender)) {
            lock[msg.sender].lockTime = lock[msg.sender].initAskTime;
        }
        lock[msg.sender].lockValue = theLockValue(msg.sender).safeAdd(_value);
        totalLocked = totalLocked.safeAdd(_value);    //increase totalLocked
        
        if (true ==lock[msg.sender].allowLockTimeUpdate) 
            lock[msg.sender].allowLockTimeUpdate = false;           //disable sender change lock time until owner allowed again
            
        emit AcceptLock(msg.sender, _sender, _value, lock[msg.sender].lockTime);
        resetLockReq();
        return true;
    }

    function resetLockReq() public returns(bool success) {
        lock[msg.sender].askToLock = 0;
        lock[msg.sender].initAskTime = 0;
        return true;
    }

    function reduceLockValue(address _to, uint256 _value) public returns(bool success) {
        require(_value <= theLockValue(_to), "insufficient lock balance");
        require (msg.sender == lock[_to].sender,"others lock detected") ;

        lock[_to].lockValue = lock[_to].lockValue.safeSub(_value);
        totalLocked = totalLocked.safeSub(_value);  //reduce totalLocked
        emit ReduceLockValue(msg.sender, _to, _value);
        return true;
    }

    /*Transfer tokens to multiple addresses*/
    function transferForMultiAddresses(address[] memory _addresses, uint256[] memory _amounts) public returns (bool) {
        require(_addresses.length == _amounts.length,"arrays length mismatch");
        for (uint i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0),"transfer to address 0");
            if (balanceOf[msg.sender] < theLockValue(msg.sender).safeAdd(_amounts[i])) revert("insufficient balance or locked");

            balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_amounts[i]);
            balanceOf[_addresses[i]] = balanceOf[_addresses[i]].safeAdd(_amounts[i]);
            emit Transfer(msg.sender, _addresses[i], _amounts[i]);
        }
        return true;
    }
}