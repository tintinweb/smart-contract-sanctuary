contract Token {

    function totalSupply() constant returns (uint256 supply) {}

    function balanceOf(address _owner) constant returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    function approve(address _spender, uint256 _value) returns (bool success) {}

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SafeMath{
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
	
	function safeSub(uint a, uint b) internal returns (uint) {
    	assert(b <= a);
    	return a - b;
  }

	function safeAdd(uint a, uint b) internal returns (uint) {
    	uint c = a + b;
    	assert(c >= a);
    	return c;
  }
	function assert(bool assertion) internal {
	    if (!assertion) {
	      revert();
	    }
	}
}


contract StandardToken is Token , SafeMath{

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to],_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to],_value);
            balances[_from] = safeSub(balances[_from],_value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
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
    uint256 public totalSupply;
}

contract Ownable {
  address public owner = msg.sender;

  /// @notice check if the caller is the owner of the contract
  modifier onlyOwner {
    if (msg.sender != owner) throw;
    _;
  }

  /// @notice change the owner of the contract
  /// @param _newOwner the address of the new owner of the contract.
  function changeOwner(address _newOwner)
  onlyOwner
  {
    if(_newOwner == 0x0) throw;
    owner = _newOwner;
  }
}
contract StrHelper{
  function uintToString(uint256 v) constant returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    function appendUintToString(string inStr, uint256 v) constant returns (string str) {
        uint maxlength = 78;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }
}

contract Ex is StandardToken, Ownable, StrHelper {
    
    
  event Mint(address indexed to, uint256 amount);
  event Minty(string announcement);
  
    string public name = "Ex Token";   
    string public description = "Mining reward for running an Ex Node";
    string public additionalInfo = "The value of Ex token is set at &#163;1000. The lowest denomination of the Ex token is 0.01 (&#163;10); anything below this should be paid in smiles, good wishes and agreeable nods. VAT applicable on all transactions.";
    string public moreInfo = "As of Oct 2018, the Ex Network has sold 20% of it&#39;s equity @ &#163;10k per share to fend for the startup costs. Thus evaluating the Coy @ &#163;1M at the time of idea floating.";
    string public evenMoreInfo = "&#163;1M worth of Ex tokens to be split 80-20% between the two parties holding equity at genesis time. Initial Supply =  1000 &#128420;";
    uint8 public decimals = 2;
    string public symbol = "&#128420;";
  
///////////////////
///////////////////  
function () {
        throw;
    }
///////////////////
///////////////////
function Ex() {
   
   /*
   Description: As of Oct 2018, the Ex Network has sold 20% of it&#39;s equity @ &#163;10k per share to fend for the startup costs. Thus evaluating the Coy @ &#163;1M at the time of idea floating.
   Distribution: &#163;1M worth of Ex tokens to be split 80-20% between the two parties represented below.
   Initial supply: 1000 &#128420;
   */

        mint(0x07777ae0a01ca3db33fc0128f7cc9fdbb783118c,20000);
        mint(0x07777c1ab6d8ee46c3b616819bdf7900373fc530,80000);
    }
///////////////////
///////////////////  
function mint(
    address _to,
    uint256 _amount
  )
    public
    onlyOwner
    returns (bool)
  {
    totalSupply = safeAdd(totalSupply,_amount);
    balances[_to] = safeAdd(balances[_to],_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    Minty(appendUintToString("Ex tokens generated in this round: ",_amount));
    return true;
  }
///////////////////
///////////////////
function mintMulti(
    address[] _to,
    uint256[] _amount
  )
    public
    onlyOwner
    returns (bool)
  {
      if(_to.length != _amount.length)
      return(false);
      
      uint256 i = 0;
      uint256 total=0;
        while (i < _to.length) {
            totalSupply = safeAdd(totalSupply,_amount[i]);
            balances[_to[i]] = safeAdd(balances[_to[i]],_amount[i]);
            Mint(_to[i], _amount[i]);
            Transfer(address(0), _to[i], _amount[i]);
            total=safeAdd(total,_amount[i]);
           i += 1;
        }
    
      Minty(appendUintToString("Ex tokens generated in this round: ",total));
      return true;
  }
  

}