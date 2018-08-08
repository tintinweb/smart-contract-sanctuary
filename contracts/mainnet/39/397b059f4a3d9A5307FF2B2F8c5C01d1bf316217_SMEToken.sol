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

contract SMEToken is StandardToken {

    struct Funder{
        address addr;
        uint amount;
    }
	
    Funder[] funder_list;
	
    // metadata
	string public constant name = "Sumerian Token";
    string public constant symbol = "SUMER";
    uint256 public constant decimals = 18;
    string public version = "1.0";
	
	uint256 public constant LOCKPERIOD = 730 days;
	uint256 public constant LOCKAMOUNT1 = 4000000 * 10**decimals;   //LOCK1
	uint256 public constant LOCKAMOUNT2 = 4000000 * 10**decimals;   //LOCK2
	uint256 public constant LOCKAMOUNT3 = 4000000 * 10**decimals;   //LOCK3
	uint256 public constant LOCKAMOUNT4 = 4000000 * 10**decimals;   //LOCK4
	uint256 public constant CORNERSTONEAMOUNT = 2000000 * 10**decimals; //cornerstone
    uint256 public constant PLATAMOUNT = 8000000 * 10**decimals;        //crowdfunding plat	

                        
    address account1 = &#39;0x5a0A46f082C4718c73F5b30667004AC350E2E140&#39;;  //7.5%  First Game	
	address account2 = &#39;0xcD4fC8e4DA5B25885c7d80b6C846afb6b170B49b&#39;;  //30%   Management Team ,Game Company ,Law Support 	
	address account3 = &#39;0x3d382e76b430bF8fd65eA3AD9ADfc3741D4746A4&#39;;  //10%   Technology Operation
	address account4 = &#39;0x005CD1194C1F088d9bd8BF9e70e5e44D2194C029&#39;;  //22.5%  Blockchain Technology
	address account5 = &#39;0x5CA7F20427e4D202777Ea8006dc8f614a289Be2F&#39;;  //30%    Exchange Listing , Marketing , Finance
						
    uint256 val1 = 1 wei;    // 1
    uint256 val2 = 1 szabo;  // 1 * 10 ** 12
    uint256 val3 = 1 finney; // 1 * 10 ** 15
    uint256 val4 = 1 ether;  // 1 * 10 ** 18
	
	address public creator;
	
	
	uint256 public gcStartTime = 0;     // unix timestamp seconds, 2017/07/15 19:00, 1500116400
	uint256 public gcEndTime = 0;       // unix timestamp seconds, 2017/08/15 19:00, 1502794800
	
	uint256 public ccStartTime = 0;     // unix timestamp seconds, 2017/07/01 19:00, 1498906800
	uint256 public ccEndTime = 0;       // unix timestamp seconds, 2017/07/15 19:00, 1500116400


	uint256 public gcSupply = 10000000 * 10**decimals;                 // 10000000 for general customer
	uint256 public constant gcExchangeRate=1000;                       // 1000 SMET per 1 ETH
	
	uint256 public ccSupply = 4000000 * 10**decimals;                 // 4000000 for corporate customer 
	uint256 public constant ccExchangeRate=1250;                      // 1250 SMET per 1 ETH      
	
	uint256 public totalSupply=0;
	
	function getFunder(uint index) public constant returns(address, uint) {
        Funder f = funder_list[index];
        
        return (
            f.addr,
            f.amount
        ); 
    }
	
	function clearSmet(){
	    if (msg.sender != creator) throw;
		balances[creator] += ccSupply;
		balances[creator] += gcSupply;
		ccSupply = 0;
		gcSupply = 0;
		totalSupply = 0;
	}

    // constructor
    function SMEToken(
		uint256 _gcStartTime,
		uint256 _gcEndTime,
		uint256 _ccStartTime,
		uint256 _ccEndTime
		) {
	    creator = msg.sender;
		totalSupply = gcSupply + ccSupply;
		balances[msg.sender] = CORNERSTONEAMOUNT + PLATAMOUNT;    //for cornerstone investors and crowdfunding plat
		balances[account1] = LOCKAMOUNT1;                         //10%   Game Company 
		balances[account2] = LOCKAMOUNT2;                         //10%   Management Team
		balances[account3] = LOCKAMOUNT3;                         //10%   Technology Operation
		balances[account4] = LOCKAMOUNT4;                         //10%   Blockchain Technology
		gcStartTime = _gcStartTime;
		gcEndTime = _gcEndTime;
		ccStartTime = _ccStartTime;
		ccEndTime = _ccEndTime;
    }
	
	function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {	
	    if(msg.sender == account1 || msg.sender == account2 || msg.sender == account3 || msg.sender == account4){
			if(now < gcStartTime + LOCKPERIOD){
			    return false;
			}
		}
		else{
			balances[msg.sender] -= _value;
			balances[_to] += _value;
			Transfer(msg.sender, _to, _value);
			return true;
		}
        
      } else {
        return false;
      }
    }
	

    function createTokens() payable {
	    if (now < ccStartTime) throw;
		if (now > gcEndTime) throw;
	    if (msg.value < val3) throw;
		
		uint256 smtAmount;
		if (msg.value >= 10*val4 && now <= ccEndTime){
			smtAmount = msg.value * ccExchangeRate;
			if (totalSupply < smtAmount) throw;
            if (ccSupply < smtAmount) throw;
            totalSupply -= smtAmount;  
            ccSupply -= smtAmount;    			
            balances[msg.sender] += smtAmount;
		    var new_cc_funder = Funder({addr: msg.sender, amount: msg.value / val3});
		    funder_list.push(new_cc_funder);
		}
        else{
		    if(now < gcStartTime) throw;
			smtAmount = msg.value * gcExchangeRate;
			if (totalSupply < smtAmount) throw;
            if (gcSupply < smtAmount) throw;
            totalSupply -= smtAmount;  
            gcSupply -= smtAmount;    			
            balances[msg.sender] += smtAmount;
		    var new_gc_funder = Funder({addr: msg.sender, amount: msg.value / val3});
		    funder_list.push(new_gc_funder);
		}		
		
        if(!account1.send(msg.value*75/1000)) throw;
		if(!account2.send(msg.value*300/1000)) throw;
		if(!account3.send(msg.value*100/1000)) throw;
		if(!account4.send(msg.value*225/1000)) throw;
		if(!account5.send(msg.value*300/1000)) throw;
    }
	
	// fallback
    function() payable {
        createTokens();
    }

}