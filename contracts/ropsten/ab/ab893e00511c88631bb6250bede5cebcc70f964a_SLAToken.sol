pragma solidity ^0.4.24;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
   Prevent Overflow for integr
 */
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

contract StandardToken {
	// bring-in SafeMath
    using SafeMath for uint256;
   
    // Coin Name definition 
    string public name;
    // Coin A.K.A. definition
    string public symbol;
	//Coin decimals definition
    uint8 public  decimals;
	// Coin total amounts
	uint256 public totalSupply;
	uint256 public init_Supply;
   
	//Transaction Owner   from Coin _value to _to receiver account 
    function transfer(address _to, uint256 _value) public returns (bool success);

    // _from account transfer _value coins to _to account 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    // Transaction Owner authoriz _spender for _value amounts , then _spender can use transferfrom method 
    // to transfer coins to another receiver account 
    
	function approve(address _spender, uint256 _value) public returns (bool success);

	// _spender query how much coins left that comes from _owner 
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

	// Transfer success event 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
	// Owner authorization approval event 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// Setup the owner manager of smart contract 
contract Owned {

    // sub-fuction of modifer as administrator 
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;//do something 
    }

	//The owener declartion 
    address public owner;

	//contract constructor 
    constructor() public {
        owner = msg.sender;
    }
	//new owner address, default is null 
    address newOwner=0x0;

	// update owner 
    event OwnerUpdate(address _prevOwner, address _newOwner);

    //from current owner to new owner ( it have to use acceptOwnership method )
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    //new owner accept ownership 
    function acceptOwnership() public{
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

// Coin controlled Contract 
contract Controlled is Owned{

	// First constructor
    constructor() public {
       setExclude(msg.sender,true);
    }

    // setup if transfer be actived or not , true is Yes , use transferAllowed for implemenation 
    bool public transferEnabled = true;

    // Lock account ，true is enable lock 
    bool lockFlag=false;
	// locked acount group，address账户，bool是否被锁，true: be locked ， if lockFlag=true it can not transferred.
    mapping(address => bool) locked;
	// VIP account not limited by transferEnabled and lockFlag，bool is true: VIP actived .
    mapping(address => bool) exclude;

	//setup transferEnabled value
    function enableTransfer(bool _enable) public onlyOwner returns (bool success){
        transferEnabled=_enable;
		return true;
    }

	//setup lockFlag value 
    function disableLock(bool _enable) public onlyOwner returns (bool success){
        lockFlag=_enable;
        return true;
    }

	// add _addr to locked acccount
    function addLock(address _addr) public onlyOwner returns (bool success){
        require(_addr!=msg.sender);
        locked[_addr]=true;
        return true;
    }

	//setup VIP account 
    function setExclude(address _addr,bool _enable) public onlyOwner returns (bool success){
        exclude[_addr]=_enable;
        return true;
    }

	// unlock _addr account 
    function removeLock(address _addr) public onlyOwner returns (bool success){
        locked[_addr]=false;
        return true;
    }
	//excute transferAllowed function
    modifier transferAllowed(address _addr) {
        if (!exclude[_addr]) {
            require(transferEnabled,"transfer is not enabeled now!");
            if(lockFlag){
                require(!locked[_addr],"you are locked!");
            }
        }
        _;
    }

}

// modify contract nick name 
contract SLAToken is StandardToken,Controlled {

	// mapping account addressses 
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) internal allowed;
	// setup the total coin amounts , coin full and  nickname, decimals: 18 is default 
	constructor() public {
        init_Supply = 50000000;
        name = "Test Token BITSENSE 5 ";  
        symbol = "SLA";
        decimals = 4;
        totalSupply = init_Supply * (10 ** uint256(decimals));
        
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public transferAllowed(msg.sender) returns (bool success) {
		require(_to != address(0));
		require(_value <= balanceOf[msg.sender]);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public transferAllowed(_from) returns (bool success) {
		require(_to != address(0));
        require(_value <= balanceOf[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}