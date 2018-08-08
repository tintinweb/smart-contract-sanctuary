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

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
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

contract TGCToken is StandardToken {

	mapping (address => uint256) public lockAccount;// lock account and lock end date

	event LockFunds(address target, uint256 lockenddate);


    // metadata
    string public constant name = "Time Game Coin";
    string public constant symbol = "TGC";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    uint256 public constant PRIVATEPLACEMENT = 25000000 * 10**decimals;  //  BASE INVEST
    uint256 public constant AMOUNT_BASETEAM = 50000000 * 10**decimals;   // BASE TEAM
    uint256 public constant RESEARCH_DEVELOPMENT =  100000000 * 10**decimals; //RESEARCH DEVELOPMENT 0Month
    uint256 public constant MINING_OUTPUT = 325000000 * 10**decimals; //MINING OUTPUT

    address account_privateplacement = 0x91efD09fEBb4faE04667bF2AFf7b7B29892E7B36;//PRIVATE PLACEMENT
    address account_baseteam = 0xe48f5617Ae488D0e0246Fa195b45374c70005318;  // BASE TEAM
    address account_research_development = 0xfeCbF6771f207aa599691756ea94c9019321354F;  // LEGAL ADVISER
    address account_mining_output = 0x7d517F5e62831F4BB43b54bcBE32389CD5d76903;  // MINING OUTPUT
                
    uint256 val1 = 1 wei;    // 1
    uint256 val2 = 1 szabo;  // 1 * 10 ** 12
    uint256 val3 = 1 finney; // 1 * 10 ** 15
    uint256 val4 = 1 ether;  // 1 * 10 ** 18
    
    address public creator;
	address public creator_new;

    uint256 public totalSupply=500000000 * 10**decimals;

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
    function TGCToken() {
        creator = msg.sender;
        balances[account_privateplacement] = PRIVATEPLACEMENT;
        balances[account_baseteam] = AMOUNT_BASETEAM;
        balances[account_research_development] = RESEARCH_DEVELOPMENT;
        balances[account_mining_output] = MINING_OUTPUT;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if(now<lockAccount[msg.sender] ){
            return false;
        }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
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