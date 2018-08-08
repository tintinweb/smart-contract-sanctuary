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
    function receiveApproval(
        address _from, 
        uint256 _amount, 
        address _token, 
        bytes _data
    ) public;
}

//normal contract. already compiled as bin
contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    //block for check//bool private initialed = false;
    address public controller;

    constructor() public {
      //block for check//require(!initialed);
      controller = msg.sender;
      //block for check//initialed = true;
    }

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) onlyController public {
        controller = _newController;
    }
}

//abstract contract. used for interface
contract TokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) payable public returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    //function onTransfer(address _from, address _to, uint _amount) public returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    //function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
}

contract ERC20Token {
    /* This is a slight change to the ERC20 base standard.
      function totalSupply() constant returns (uint256 supply);
      is replaced with:
      uint256 public totalSupply;
      This automatically creates a getter function for the totalSupply.
      This is moved to the base contract since public getter functions are not
      currently recognised as an implementation of the matching abstract
      function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;
    //function totalSupply() public constant returns (uint256 balance);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    mapping (address => uint256) public balanceOf;
    //function balanceOf(address _owner) public constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    mapping (address => mapping (address => uint256)) public allowance;
    //function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenI is ERC20Token, Controlled {

    string public name;                //The Token&#39;s name: e.g. DigixDAO Tokens
    uint8 public decimals = 18;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP


    // ERC20 Methods

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(
        address _spender,
        uint256 _amount,
        bytes _extraData
    ) public returns (bool success);


    // Generate and destroy tokens

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount) public returns (bool);


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint _amount) public returns (bool);

    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) public;


    // Safety Methods

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _tokens The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address[] _tokens) public;


    // Events

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}


contract Token915 is TokenI {
    using SafeMath for uint256;

    address public owner;

    string public techProvider = "WeYii Tech(https://weyii.co)";
    string public officialSite = "https://915club.com";

    mapping (uint8 => uint256[]) public freezeOf; //所有数额，地址与数额合并为uint256，位运算拆分。
    //解锁信息
    uint8  currUnlockStep; //当前解锁step
    uint256 currUnlockSeq; //当前解锁step 内的游标

    mapping (uint8 => bool) public stepUnlockInfo; //所有锁仓，key 使用序号向上增加，value,是否已解锁。
    mapping (address => uint256) public freezeOfUser; //用户所有锁仓，方便用户查询自己锁仓余额
    //mapping (uint8 => uint32) public lastFreezeSeq; //最后的 freezeOf 键值。key: step; value: sequence
    mapping (uint8 => uint256) public stepLockend; //key:锁仓step，value：解锁时间
    //uint8[] public lockSteps;

    bool public transfersEnabled = true;

    /* This generates a public event on the blockchain that will notify clients */
    //event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
    
    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
    
    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        address initialOwner
    ) public {
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

    //要求真实用户
    modifier realUser(address user){
        require(user != 0x0);
        _;
    }

    modifier moreThanZero(uint256 _value){
        require(_value > 0);
        _;
    }

    /// 余额足够
    modifier userEnough(address _user, uint256 _amount) {
        require(balanceOf[_user] >= _amount);
        _;
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) {
            return false;
        }
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

    /// @dev Internal function to determine if an address is a contract
    function addLockStep(uint8 _step, uint _endTime) onlyController external returns(bool) {
        stepLockend[_step] = _endTime;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) realUser(_to) moreThanZero(_value) transable public returns (bool) {
        //require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        //require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                     // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) transable public
        returns (bool success) {
        require(_value == 0 || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    /* decreace allowance*/
    function unApprove(address _spender, uint256 _value) moreThanZero(_value) transable public
        returns (bool success) {
        require(_value == 0 || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].sub(_value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    /**
     * @notice `msg.sender` approves `_spender` to send `_amount` tokens on
     *  its behalf, and then a function is triggered in the contract that is
     *  being approved, `_spender`. This allows users to use their tokens to
     *  interact with contracts in one function call instead of two
     * @param _spender The address of the contract able to transfer the tokens
     * @param _amount The amount of tokens to be approved for transfer
     * @return True if the function call was successful
     */
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) transable public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallReceiver(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) realUser(_from) realUser(_to) moreThanZero(_value) transable public returns (bool success) {
        require(balanceOf[_from] >= _value);                 // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);                           // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function transferMulti(address[] _to, uint256[] _value) transable public returns (bool success, uint256 amount){
        require(_to.length == _value.length && _to.length <= 1024);
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
    
    function transferMultiSameVaule(address[] _to, uint256 _value) transable public returns (bool){
        require(_to.length <= 1024);
        //uint256 balanceOfSender = balanceOf[msg.sender];
        uint256 len = _to.length;
        uint256 amount = _value.mul(len);
        //require(balanceOfSender - amount < balanceOfSender); //check enough and not overflow
        //TODO test
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount); //this maybe will check enough automatically
        address _toI;
        for(uint256 i; i<len; i++){
            _toI = _to[i];
            balanceOf[_toI] = balanceOf[_toI].add(_value);
            emit Transfer(msg.sender, _toI, _value);
        }
        return true;
    }

    //冻结账户
    function freeze(address _user, uint256 _value, uint8 _step) moreThanZero(_value) onlyController public returns (bool success) {
        require(balanceOf[_user] >= _value);
        balanceOf[_user] = balanceOf[_user].sub(_value);
        freezeOfUser[_user] = freezeOfUser[_user].add(_value);
        freezeOf[_step].push(uint256(_user)<<96|_value);
        emit Freeze(_user, _value);
        return true;
    }


    //event info(string name, uint32 value);
    //event info256(string name, uint256 value);
    
    //为用户解锁账户资金
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
    
    //accept ether
    function() payable public {
        //屏蔽控制方的合约类型检查，以兼容发行方无控制合约的情况。
        require(isContract(controller));
        bool proxyPayment = TokenController(controller).proxyPayment.value(msg.value)(msg.sender);
        require(proxyPayment);
    }

////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _user The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _user, uint _amount) onlyController public returns (bool) {
        //require(balanceOf[owner] >= _amount);
        balanceOf[_user] += _amount;
        balanceOf[owner] -= _amount;
        emit Transfer(0, _user, _amount);
        return true;
    }

    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _user The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
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

////////////////
// Enable tokens transfers
////////////////

    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) onlyController public {
        transfersEnabled = _transfersEnabled;
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address[] tokens) onlyOwner public {
        address _token;
        uint256 balance;
        for(uint256 i; i<tokens.length; i++){
            _token = tokens[i];
            if (_token == 0x0) {
                balance = address(this).balance;
                if(balance > 0){
                    owner.transfer(balance);
                }
            }else{
                ERC20Token token = ERC20Token(_token);
                balance = token.balanceOf(address(this));
                token.transfer(owner, balance);
                emit ClaimedTokens(_token, owner, balance);
            }
        }
    }
}