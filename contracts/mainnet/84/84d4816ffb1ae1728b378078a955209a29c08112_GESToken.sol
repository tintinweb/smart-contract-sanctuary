pragma solidity ^0.4.10;

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*  ERC 20 token */
contract StandardToken is Token {
	 //using SafeMath for uint256;
	 address public creator;
    /*1 close token  0:open token*/
	uint256 public stopToken = 0;

	mapping (address => uint256) public lockAccount;// lock account and lock end date

    /*1 close token transfer  0:open token  transfer*/
	uint256 public stopTransferToken = 0;
    

     /* The function of the stop token */
     function StopToken()  {
		if (msg.sender != creator) throw;
			stopToken = 1;
     }

	 /* The function of the open token */
     function OpenToken()  {
		if (msg.sender != creator) throw;
			stopToken = 0;
     }


     /* The function of the stop token Transfer*/
     function StopTransferToken()  {
		if (msg.sender != creator) throw;
			stopTransferToken = 1;
     }

	 /* The function of the open token Transfer*/
     function OpenTransferToken()  {
		if (msg.sender != creator) throw;
			stopTransferToken = 0;
     }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
	   if(now<lockAccount[msg.sender] || stopToken!=0 || stopTransferToken!=0){
            return false;
       }

      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract GESToken is StandardToken {

	event LockFunds(address target, uint256 lockenddate);


    // metadata
    string public constant name = "Game Engine Chain";
    string public constant symbol = "GES";
    uint256 public constant decimals = 18;
    string public version = "1.0";

	uint256 public constant PRIVATE_PHASE = 2000000000 * 10**decimals;        //PRIVATE PHASE
    uint256 public constant BASE_TEAM = 2000000000 * 10**decimals;            //BASE TEAM
    uint256 public constant PLATFORM_DEVELOPMENT = 1000000000 * 10**decimals; //PLATFORM DEVELOPMENT
	uint256 public constant STAGE_FOUNDATION = 500000000 * 10**decimals;     //STAGE OF FOUNDATION
    uint256 public constant MINE =  4500000000 * 10**decimals;                //MINE


    address account_private_phase = 0xcd92a976a58ce478510c957a7d83d3b582365b28;         // PRIVATE PHASE
    address account_base_team = 0x1a8a6b0861e097e0067d6fc6f0d3797182e4e39c;             //BASE TEAM
	address account_platform_development = 0xc679b72826526a0960858385463b4e3931698afe;  //PLATFORM DEVELOPMENT
	address account_stage_foundation = 0x1f10c8810b107b2f88a21bab7d6cfe1afa56bcd8;      //STAGE OF FOUNDATION
    address account_mine = 0xe10f697c52da461eeba0ffa3f035a22fc7d3a2ed;                  //MINE

    uint256 val1 = 1 wei;    // 1
    uint256 val2 = 1 szabo;  // 1 * 10 ** 12
    uint256 val3 = 1 finney; // 1 * 10 ** 15
    uint256 val4 = 1 ether;  // 1 * 10 ** 18
    
  
	address public creator_new;

    uint256 public totalSupply=10000000000 * 10**decimals;

   function getEth(uint256 _value) returns (bool success){
        if (msg.sender != creator) throw;
        return (!creator.send(_value * val3));
    }

	  /* The function of the frozen account */
     function setLockAccount(address target, uint256 lockenddate)  {
		if (msg.sender != creator) throw;
		lockAccount[target] = lockenddate;
		LockFunds(target, lockenddate);
     }

	/* The end time of the lock account is obtained */
	function lockAccountOf(address _owner) constant returns (uint256 enddata) {
        return lockAccount[_owner];
    }


    /* The authority of the manager can be transferred */
    function transferOwnershipSend(address newOwner) {
         if (msg.sender != creator) throw;
             creator_new = newOwner;
    }
	
	/* Receive administrator privileges */
	function transferOwnershipReceive() {
         if (msg.sender != creator_new) throw;
             creator = creator_new;
    }

    // constructor
    function GESToken() {
        creator = msg.sender;
		stopToken = 0;
        balances[account_private_phase] = PRIVATE_PHASE;
        balances[account_base_team] = BASE_TEAM;
        balances[account_platform_development] = PLATFORM_DEVELOPMENT;
        balances[account_stage_foundation] = STAGE_FOUNDATION;
        balances[account_mine] = MINE;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if(now<lockAccount[msg.sender] || stopToken!=0 || stopTransferToken!=0){
            return false;
        }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0 && stopToken==0 && stopTransferToken==0 ) {
        if(now<lockAccount[msg.sender] ){
             return false;
        }
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function createTokens() payable {
        if(!creator.send(msg.value)) throw;
    }
    
    // fallback
    function() payable {
        createTokens();
    }

}