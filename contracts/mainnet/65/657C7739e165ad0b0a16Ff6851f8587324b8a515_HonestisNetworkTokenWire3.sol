//Honestis deployment
pragma solidity ^0.4.11;

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}



/**
 * Math operations with safety checks
 */
contract SafeMath {
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
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}



/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, SafeMath {

  /* Token supply got increased and a new owner received these tokens */
  event Minted(address receiver, uint amount);

  /* Actual balances of token holders */
  mapping(address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;

  /* Interface declaration */
  function isToken() public constant returns (bool weAre) {
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


//  Honestis Network Token 
contract HonestisNetworkTokenWire3{

    string public name = "Honestis.Network Token Version 1";
    string public symbol = "HNT";
    uint8 public constant decimals = 18;  // 18 decimal places, the same as ETC/ETH/HEE.
    // The funding cap in weis.
// was not reached about 93% was sold    uint256 public constant tokenCreationCap = 66200 * 1000 * ether ;
	
    // Receives ETH and its own H.N Token endowment.
    address public honestisFort = 0xF03e8E4cbb2865fCc5a02B61cFCCf86E9aE021b5;
    // NOT APPLY
    address public migrationMaster = 0x0f32f4b37684be8a1ce1b2ed765d2d893fa1b419;
    // The current total token supply.
	//totalsupply
  //  uint256 public constant allchainstotalsupply =61172163.78335328 ether;
//    uint256 public constant supply on chain 1st and 2nd     =57872163.78335328 ether;
//	uint256 public constant supply4chains34 = 3300000.0 ether;
uint256 public constant supply = 3300000.0 ether;
		//61172163 783353280000000000
	// was 61168800
	//chains:
	address public firstChainHNw1 = 0x0;
	address public secondChainHNw2 = 0x0;
	address public thirdChainETH = 0x0;
	address public fourthChainETC = 0x0;
				
	struct sendTokenAway{
		StandardToken coinContract;
		uint amount;
		address recipient;
	}
	mapping(uint => sendTokenAway) transfers;
	uint numTransfers=0;
	
  mapping (address => uint256) balances;

  mapping (address => mapping (address => uint256)) allowed;

	event UpdatedTokenInformation(string newName, string newSymbol);	
 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
	
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function HonestisNetworkTokenWire3() {
// BALANCES		
//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
// funcje transfer , fransfer from, allow, allowance , wywalic migrate i mastera , owner tylko do zmiany nazwy ??, total security check 
//early adopters community 1
//balances[0xd57908dbe0e1353771db7f953E74a7936a5aAd70]=                   61172163783353280000000000;
// 1st and 2nd chain balances[0xd57908dbe0e1353771db7f953E74a7936a5aAd70]=57872163783353280000000000;
// 3rd and 4th chain 3300000 000000000000000000;                          +3300000000000000000000000;
 balances[0x8585d5a25b1fa2a0e6c3bcfc098195bac9789be2]=3300000000000000000000000;
}

  
  function transfer(address _to, uint256 _value) returns (bool success) {
    //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
    //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
    //Replace the if with this one instead.
    if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    //if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    //same as above. Replace this line with the following if you want to protect against wrapping uints.
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
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


	function() payable {

   }


function justSendDonations() external {
    if (msg.sender != honestisFort) throw;
	if (!honestisFort.send(this.balance)) throw;
}
	
  function setTokenInformation(string _name, string _symbol) {
    
	   if (msg.sender != honestisFort) {
      throw;
    }
	name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

function setChainsAddresses(address chainAd, int chainnumber) {
    
	   if (msg.sender != honestisFort) {
      throw;
    }
	if(chainnumber==1){firstChainHNw1=chainAd;}
	if(chainnumber==2){secondChainHNw2=chainAd;}
	if(chainnumber==3){thirdChainETH=chainAd;}
	if(chainnumber==4){fourthChainETC=chainAd;}		
  } 

  function HonestisnetworkICOregulations() external returns(string wow) {
	return &#39;Regulations of preICO and ICO are present at website  honestis.network and by using this smartcontract and blockchains you commit that you accept and will follow those rules&#39;;
}
// if accidentally other token was donated to Project Dev


	function sendTokenAw(address StandardTokenAddress, address receiver, uint amount){
		if (msg.sender != honestisFort) {
		throw;
		}
		sendTokenAway t = transfers[numTransfers];
		t.coinContract = StandardToken(StandardTokenAddress);
		t.amount = amount;
		t.recipient = receiver;
		t.coinContract.transfer(receiver, amount);
		numTransfers++;
	}




}


//------------------------------------------------------