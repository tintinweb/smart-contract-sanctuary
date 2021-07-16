//SourceUnit: cade_token_update.sol

pragma solidity ^0.5.4;


contract ERC20 {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function transfer(address to, uint256 value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
     
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}


contract CADE is ERC20 {
    
    using SafeMath for uint256;
    uint256 constant TOTAL_SUPPLY = 10000000000;

    string public name = "CADE";
    string public symbol = "CADE";
    uint8 public decimals = 18;
    uint256 public totalSupply = TOTAL_SUPPLY*10**uint256(decimals);
    
	address public owner;
	address public minter;  
	
	bool public transferStatus;
	bool public contractStatus;
	bool public withdrawStatus;
	uint256 public poolAmount;
	uint256 public withdrawLimit; //set in 6 decimals

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    mapping (address => uint256) public deposits;
    mapping (address => bool) public userStatus;
    mapping (address => uint256) public freezeOf;

    event Mint(address useraddr, uint256 amount, uint256 time);
    event Deposit(address useraddr, uint256 amount, uint256 time);
    event Withdraw(address useraddr, uint256 amount, uint256 time);
    event Freeze(address useraddr, uint256 amount, uint256 time);
    event UnFreeze(address useraddr, uint256 amount, uint256 time);

    constructor(address marketing, address team, address reserve, address consoledev, address _partner, uint256 _withdrawlimit, address _minter) public {
		owner = msg.sender;
		contractStatus = true;
		transferStatus = false;
		withdrawStatus = true;
		minter = _minter;
        init(marketing, team, reserve, consoledev, _partner, _minter);
        withdrawLimit = _withdrawlimit; //should be in 6 decimals
        
    }
    
    /**
     * @dev init
    */
    function init(address _market, address _team, address _reserve, address _consoledev, address _partner, address _minter) internal {
		balances[_market] = 1000000000*10**uint(decimals);
		balances[_team] = 2000000000*10**uint(decimals);
		balances[_reserve] = 500000000*10**uint(decimals);
		balances[_consoledev] = 500000000*10**uint(decimals);
		balances[_partner] = 500000000*10**uint(decimals);
		balances[_minter] = 4500000000*10**uint(decimals);
		
        emit Transfer(address(0), _market, balances[_market]);
        emit Transfer(address(0), _team, balances[_team]);
        emit Transfer(address(0), _reserve, balances[_reserve]);
        emit Transfer(address(0), _consoledev, balances[_consoledev]);
        emit Transfer(address(0), _partner, balances[_partner]);
        emit Transfer(address(0), _minter, balances[_minter]);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    modifier contractActive() {
        require(contractStatus, "Contract is inactive");
        _;
    }
    
    modifier userCheck() {
        require(!userStatus[msg.sender], "Invalid user");
        _;
    }
    
    modifier isUnlocked() {
        require(transferStatus, "Locked");
        _;
    }
    
    modifier withdrawActive() {
        require(withdrawStatus, "Withdraw status inactive");
        _;
    }
    
    /**
     * @dev changeOwner
     * @param _newOwner Newowner address
    */
    function changeOwner(address _newOwner) public onlyOwner contractActive returns (bool){
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
        return true;
    }

    /**
     * @dev Transfer token 
     * @param _to Receiver address
     * @param _value Amount of the tokens
    */
    function transfer(address _to, uint256 _value) public contractActive userCheck isUnlocked returns (bool) {
        require(_to != address(0), "Null address");                                         
		require(_value > 0, "Invalid Value"); 
        require(balances[msg.sender] >= _value, "Insufficient balance");
        _transfer(msg.sender, _to, _value); 
        return true;
    }
 
    /**
     * @dev Approve tokens 
     * @param _spender Spender address
     * @param _value amount of tokens to approve
    */
    function approve(address _spender, uint256 _value) public contractActive returns (bool) {
        require(_spender != address(0), "Null address");
        require(_value > 0, "Invalid value");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @dev To view approved balance
     * @param holder holder address
     * @param delegate spender address
    */ 
    function allowance(address holder, address delegate) public view returns (uint256) {
        return allowed[holder][delegate];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from  holder address
     * @param _to  Receiver address
     * @param _value  amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public contractActive userCheck isUnlocked returns (bool) {
        require(_to != address(0), "Null address");
        require(_from != address(0), "Null address");
        require(_value > 0, "Invalid value"); 
        require(_value <= balances[_from], "Insufficient balance");
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    function minterTransfer(address _to, uint256 _amount) public contractActive userCheck returns (bool) {
        require(msg.sender == minter, "Only minter");
        require(_to != address(0), "Null address");
        require(_amount > 0, "Invalid value");
        require(balances[minter] >= _amount, "Insufficient balance");
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @dev Internal Transfer function
    */
    function _transfer(address _from, address _to, uint256 _value) internal {
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value); 
    }
    
    /**
     * @dev Freeze tokens - User can freeze tokens.
     * @param _amount  The amount of tokens to be freeze
    */
    function freeze(uint256 _amount) public userCheck contractActive returns(bool){
        require(_amount > 0, "Invalid amount");
        require(balances[msg.sender] >= _amount, "Insufficient amount");
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        freezeOf[msg.sender] = freezeOf[msg.sender].add(_amount);
        emit Freeze(msg.sender, _amount, now);
        return true;
    }
    
    /**
     * @dev UnFreeze tokens
     * @param _amount  The amount of tokens to be unfreeze
    */
    function unFreeze(uint256 _amount) public userCheck contractActive returns(bool){
        require(_amount > 0, "Invalid amount");
        require(freezeOf[msg.sender] >= _amount, "Insufficient amount");
        freezeOf[msg.sender] = freezeOf[msg.sender].sub(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        emit UnFreeze(msg.sender, _amount, now);
        return true;
    }
    
    /**
     * @dev Mine tokens
    */
    function mine() public onlyOwner returns(bool){
        return true;
    }
    
    /**
     * @dev Deposit TRX
    */
    function deposit() public contractActive payable returns(bool){
        require(msg.value > 0, "Invalid amount");
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        poolAmount = poolAmount.add(msg.value);
        emit Deposit(msg.sender, msg.value, now);
        return true;
    }
    
    /**
     * @dev withdraw TRX
     * @param _amount Amount to withdraw 
     * @param user User addres to withdraw
     * @param _flag false:User true:Admin
    */
    function withdraw(uint256 _amount, address payable user, bool _flag) public contractActive onlyOwner withdrawActive returns(bool){
        require(_amount > 0, "Invalid Amount");
        require(user != address(0), "Invalid address");
        require(poolAmount >= _amount, "Insufficient balance");
        if (!_flag) {
            require(withdrawLimit >= _amount, "Greater than withdrawLimit");
        }
        poolAmount = poolAmount.sub(_amount);
        user.transfer(_amount);
        emit Withdraw(user, _amount, now);
        return true;
    }
        
    /**
     * @dev addBlacklist
     * @param _user user to Blacklist 
    */
    function addBlacklist(address _user)public onlyOwner returns(bool){
       require(_user != address(0), "Invalid address");
       require(!userStatus[_user], "Already in blacklist");
       userStatus[_user] = true;
       return true;
    }
    
    /**
     * @dev removeBlacklist
     * @param _user user to be removed from Blacklist 
    */
    function removeBlacklist(address _user)public onlyOwner returns(bool){
        require(_user != address(0), "Invalid address");
        require(userStatus[_user], "Not in blacklist");
        userStatus[_user] = false;
        return true;
    }
    
    /**
     * @dev updatecontractStatus to change the status of the contract from active to inactive
     * @param _status Contract status
    */
    function updateContractstatus(bool _status) public onlyOwner returns(bool) {
        require(contractStatus != _status, "Invalid contract status");
        contractStatus = _status;
        return true;
    }
    
    /**
     * @dev update transferLock
     * @param _status Transfer status
    */
    function updateTransferlock(bool _status) public onlyOwner returns(bool) {
        require(transferStatus != _status, "Invalid transfer status");
        transferStatus = _status;
        return true;
    }
        
    /**
     * @dev update withdraw status
     * @param _status Withdraw status
    */
    function updateWithdrawstatus(bool _status) public onlyOwner returns(bool) {
        require(withdrawStatus != _status, "Invalid withdraw status");
        withdrawStatus = _status;
        return true;
    }
            
    /**
     * @dev update withdraw Limit
     * @param _limit Withdraw limit, set in 6 decimals
    */
    function updateWithdrawlimit(uint256 _limit) public onlyOwner returns(bool) {
        require(withdrawLimit != _limit, "Invalid withdraw status");
        withdrawLimit = _limit;
        return true;
    }
}