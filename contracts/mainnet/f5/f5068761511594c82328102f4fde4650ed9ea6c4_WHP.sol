pragma solidity ^0.4.18;

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

contract WHP is StandardToken {
	
    // metadata
	string public constant name = "WHP";
    string public constant symbol = "WHP";
    uint256 public constant decimals = 18;
    string public version = "1.0";
	
    address private creator;     
	mapping (address => uint256) private blackmap;
	mapping (address => uint256) private releaseamount;

    modifier onlyCreator() {
    require(msg.sender == creator);
    _;
   }
   
   function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
   }
   
   function addBlackAccount(address _b) public onlyCreator {
    require(_addressNotNull(_b));
    blackmap[_b] = 1;
   }
   
   function clearBlackAccount(address _b) public onlyCreator {
    require(_addressNotNull(_b));
    blackmap[_b] = 0;
   }
   
   function checkBlackAccount(address _b) public returns (uint256) {
       require(_addressNotNull(_b));
       return blackmap[_b];
   }
   
   function setReleaseAmount(address _b, uint256 _a) public onlyCreator {
       require(_addressNotNull(_b));
       require(balances[_b] >= _a);
       releaseamount[_b] = _a;
   }
   
   function setReleaseAmountToCreator(uint256 _a) public onlyCreator {
       balances[creator] += _a;
   }
   
   function checkReleaseAmount(address _b) public returns (uint256) {
       require(_addressNotNull(_b));
       return releaseamount[_b];
   }
  

    uint256 public amount = 10* 10000 * 10000 * 10**decimals;

    // constructor
    function WHP() {
	    creator = msg.sender;
		totalSupply = amount;
		balances[creator] = amount;                          
    }
	
	
	function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {	
	    if(blackmap[msg.sender] != 0){
	        if(releaseamount[msg.sender] < _value){
	            return false;
	        }
	        else{
	            releaseamount[msg.sender] -= _value;
	            balances[msg.sender] -= _value;
			    balances[_to] += _value;
			    Transfer(msg.sender, _to, _value);
			    return true;
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

}