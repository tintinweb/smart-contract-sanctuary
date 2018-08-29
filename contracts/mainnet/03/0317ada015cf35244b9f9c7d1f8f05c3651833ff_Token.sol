pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract ApproveAndCallReceiver {
    function receiveApproval(address _from, uint256 _amount, address _token, bytes _data) public;
}

contract Controlled {
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    address public controller;

    constructor() public {
      controller = msg.sender;
    }

    function changeController(address _newController) onlyController public {
        controller = _newController;
    }
}

contract TokenAbout is Controlled {
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);

    function isContract(address _addr) constant internal returns (bool) {
        if (_addr == 0) {
            return false;
        }
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function claimTokens(address[] tokens) onlyController public {
        require(tokens.length <= 100, "tokens.length too long");
        address _token;
        uint256 balance;
        ERC20Token token;
        for(uint256 i; i<tokens.length; i++){
            _token = tokens[i];
            if (_token == 0x0) {
                balance = address(this).balance;
                if(balance > 0){
                    msg.sender.transfer(balance);
                }
            }else{
                token = ERC20Token(_token);
                balance = token.balanceOf(address(this));
                token.transfer(msg.sender, balance);
                emit ClaimedTokens(_token, msg.sender, balance);
            }
        }
    }
}

contract TokenController {
    function proxyPayment(address _owner) payable public returns(bool);
    function onTransfer(address _from, address _to, uint _amount) public view returns(bool);
    function onApprove(address _owner, address _spender, uint _amount) public view returns(bool);
}

contract ERC20Token {
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenI is ERC20Token, Controlled {
    string public name;                //The Token&#39;s name: e.g. DigixDAO Tokens
    uint8 public decimals = 18;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    function approveAndCall( address _spender, uint256 _amount, bytes _extraData) public returns (bool success);
    function generateTokens(address _owner, uint _amount) public returns (bool);
    function destroyTokens(address _owner, uint _amount) public returns (bool);
    function enableTransfers(bool _transfersEnabled) public;
}

contract Token is TokenI, TokenAbout {
    using SafeMath for uint256;
    address public owner;
    string public techProvider = "WeYii Tech(https://weyii.co)";

    mapping (uint8 => uint256[]) public freezeOf; //所有数额，地址与数额合并为uint256，位运算拆分。
    uint8  currUnlockStep; //当前解锁step
    uint256 currUnlockSeq; //当前解锁step 内的游标

    mapping (uint8 => bool) public stepUnlockInfo; //所有锁仓，key 使用序号向上增加，value,是否已解锁。
    mapping (address => uint256) public freezeOfUser; //用户所有锁仓，方便用户查询自己锁仓余额
    mapping (uint8 => uint256) public stepLockend; //key:锁仓step，value：解锁时

    bool public transfersEnabled = true;

    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    constructor(uint256 initialSupply, string tokenName, string tokenSymbol, address initialOwner) public {
        name = tokenName;
        symbol = tokenSymbol;
        owner = initialOwner;
        totalSupply = initialSupply*uint256(10)**decimals;
        balanceOf[owner] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier ownerOrController(){
        require(msg.sender == owner || msg.sender == controller);
        _;
    }

    modifier transable(){
        require(transfersEnabled);
        _;
    }

    modifier ownerOrUser(address user){
        require(msg.sender == owner || msg.sender == user);
        _;
    }

    modifier userOrController(address user){
        require(msg.sender == user || msg.sender == owner || msg.sender == controller);
        _;
    }

    modifier realUser(address user){
        require(user != 0x0);
        _;
    }

    modifier moreThanZero(uint256 _value){
        require(_value > 0);
        _;
    }

    modifier userEnough(address _user, uint256 _amount) {
        require(balanceOf[_user] >= _amount);
        _;
    }

    function addLockStep(uint8 _step, uint _endTime) onlyController external returns(bool) {
        stepLockend[_step] = _endTime;
    }

    function transfer(address _to, uint256 _value) realUser(_to) moreThanZero(_value) transable public returns (bool) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                     // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    function approve(address _spender, uint256 _value) transable public returns (bool success) {
        require(_value == 0 || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function unApprove(address _spender, uint256 _value) moreThanZero(_value) transable public returns (bool success) {
        require(_value == 0 || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].sub(_value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) transable public returns (bool success) {
        require(approve(_spender, _amount));
        ApproveAndCallReceiver(_spender).receiveApproval(msg.sender, _amount, this, _extraData);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) realUser(_from) realUser(_to) moreThanZero(_value) transable public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function transferMulti(address[] _to, uint256[] _value) transable public returns (bool success, uint256 amount){
        require(_to.length == _value.length && _to.length <= 300, "transfer once should be less than 300, or will be slow");
        uint256 balanceOfSender = balanceOf[msg.sender];
        uint256 len = _to.length;
        for(uint256 j; j<len; j++){
            require(_value[j] <= balanceOfSender); //limit transfer value
            amount = amount.add(_value[j]);
        }
        require(balanceOfSender > amount ); //check enough and not overflow
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        address _toI;
        uint256 _valueI;
        for(uint256 i; i<len; i++){
            _toI = _to[i];
            _valueI = _value[i];
            balanceOf[_toI] = balanceOf[_toI].add(_valueI);
            emit Transfer(msg.sender, _toI, _valueI);
        }
        return (true, amount);
    }
    
    function transferMultiSameValue(address[] _to, uint256 _value) transable public returns (bool){
        require(_to.length <= 300, "transfer once should be less than 300, or will be slow");
        uint256 len = _to.length;
        uint256 amount = _value.mul(len);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        address _toI;
        for(uint256 i; i<len; i++){
            _toI = _to[i];
            balanceOf[_toI] = balanceOf[_toI].add(_value);
            emit Transfer(msg.sender, _toI, _value);
        }
        return true;
    }

    function freeze(address _user, uint256[] _value, uint8[] _step) onlyController public returns (bool success) {
        require(_value.length == _step.length, "length of value and step must be equal");
        require(_value.length <= 100, "lock step should less or equal than 100");
        uint256 amount; //冻结总额
        for(uint i; i<_value.length; i++){
            amount = amount.add(_value[i]);
        }
        require(balanceOf[_user] >= amount, "balance of user must bigger or equal than amount of all steps");
        balanceOf[_user] -= amount;
        freezeOfUser[_user] += amount;
        uint256 _valueI;
        uint8 _stepI;
        for(i=0; i<_value.length; i++){
            _valueI = _value[i];
            _stepI = _step[i];
            freezeOf[_stepI].push(uint256(_user)<<96|_valueI);
        }
        emit Freeze(_user, amount);
        return true;
    }

    function unFreeze(uint8 _step) onlyController public returns (bool unlockOver) {
        require(stepLockend[_step]<now && (currUnlockStep==_step || currUnlockSeq==uint256(0)));
        require(stepUnlockInfo[_step]==false);
        uint256[] memory currArr = freezeOf[_step];
        currUnlockStep = _step;
        if(currUnlockSeq==uint256(0)){
            currUnlockSeq = currArr.length;
        }
        uint256 start = ((currUnlockSeq>99)?(currUnlockSeq-99): 0);

        uint256 userLockInfo;
        uint256 _amount;
        address userAddress;
        for(uint256 end = currUnlockSeq; end>start; end--){
            userLockInfo = freezeOf[_step][end-1];
            _amount = userLockInfo&0xFFFFFFFFFFFFFFFFFFFFFFFF;
            userAddress = address(userLockInfo>>96);
            balanceOf[userAddress] += _amount;
            freezeOfUser[userAddress] = freezeOfUser[userAddress].sub(_amount);
            emit Unfreeze(userAddress, _amount);
        }
        if(start==0){
            stepUnlockInfo[_step] = true;
            currUnlockSeq = 0;
        }else{
            currUnlockSeq = start;
        }
        return true;
    }
    
    function() payable public {
        require(isContract(controller), "controller is not a contract");
        bool proxyPayment = TokenController(controller).proxyPayment.value(msg.value)(msg.sender);
        require(proxyPayment);
    }

    function generateTokens(address _user, uint _amount) onlyController userEnough(owner, _amount) public returns (bool) {
        balanceOf[_user] += _amount;
        balanceOf[owner] -= _amount;
        emit Transfer(0, _user, _amount);
        return true;
    }

    function destroyTokens(address _user, uint _amount) onlyController userEnough(_user, _amount) public returns (bool) {
        require(balanceOf[_user] >= _amount);
        balanceOf[owner] += _amount;
        balanceOf[_user] -= _amount;
        emit Transfer(_user, 0, _amount);
        emit Burn(_user, _amount);
        return true;
    }

    function changeOwner(address newOwner) onlyOwner public returns (bool) {
        balanceOf[newOwner] = balanceOf[owner];
        balanceOf[owner] = 0;
        owner = newOwner;
        return true;
    }

    function enableTransfers(bool _transfersEnabled) onlyController public {
        transfersEnabled = _transfersEnabled;
    }
}