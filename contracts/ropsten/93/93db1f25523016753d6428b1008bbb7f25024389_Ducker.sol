pragma solidity ^0.4.25;

/*** @title SafeMath*/
library SafeMath {
	function mul(uint a, uint b) internal returns (uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
	function div(uint a, uint b) internal returns (uint) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}
	function sub(uint a, uint b) internal returns (uint) {
		assert(b <= a);
		return a - b;
	}
	function add(uint a, uint b) internal returns (uint) {
		uint c = a + b;
		assert(c >= a);
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


/*** @title ERC20 interface */
contract ERC20 {
  function totalSupply() public view returns (uint256);  
  function balanceOf(address _owner) public view returns (uint256);  
  function transfer(address _to, uint256 _value) public returns (bool);  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);  
  function approve(address _spender, uint256 _value) public returns (bool);  
  function allowance(address _owner, address _spender) public view returns (uint256);  
  event Transfer(address indexed _from, address indexed _to, uint256 _value);  
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*** @title ERC223 interface */
contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}
contract ERC223 {
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public returns(bool);
    function transfer(address to, uint value, bytes data) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint value); //ERC 20 style
    //event Transfer(address indexed from, address indexed to, uint value, bytes data);
}
/*** @title ERC223 token */
contract ERC223Token is ERC223{
	using SafeMath for uint;

	mapping(address => uint256) balances;
  
	function transfer(address _to, uint _value) public returns(bool){
		uint codeLength;
		bytes memory empty;
		assembly {
			// Retrieve the size of the code on target address, this needs assembly .
			codeLength := extcodesize(_to)
		}

		require(_value > 0);
		require(balances[msg.sender] >= _value);
		require(balances[_to]+_value > 0);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		if(codeLength>0) {
			ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
			receiver.tokenFallback(msg.sender, _value, empty);
			return false;
		}
		emit Transfer(msg.sender, _to, _value);
		return true;
	}
  
	function transfer(address _to, uint _value, bytes _data) public returns(bool){
		// Standard function transfer similar to ERC20 transfer with no _data .
		// Added due to backwards compatibility reasons .
		uint codeLength;
		assembly {
			// Retrieve the size of the code on target address, this needs assembly .
			codeLength := extcodesize(_to)
		}

		require(_value > 0);
		require(balances[msg.sender] >= _value);
		require(balances[_to]+_value > 0);
		
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		if(codeLength>0) {
			ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
			receiver.tokenFallback(msg.sender, _value, _data);
			return false;
		}
		emit Transfer(msg.sender, _to, _value);
		return true;
	} 

	function balanceOf(address _owner) public view returns (uint256) {    
		return balances[_owner];
	}
  
}

//////////////////////////////////////////////////////////////////////////
//////////////////////// [Ducker] MAIN ////////////////////////
//////////////////////////////////////////////////////////////////////////
/*** @title Owned */
contract Owned {
	address public owner;
	constructor() public {
		owner = msg.sender;
		owner = 0xa53220c1b414f2E899fB53E3147e5CA6CDC0a79a;
	}
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
}
/*** @title Ding Token */
contract Ducker is ERC223Token, Owned{
    
    string public constant name = "Ducker";
    string public constant symbol = "OXG";
    uint8  public constant decimals = 18;

    uint256 public tokenRemained = 2 * (10 ** 6) * (10 ** 18); // 2 billion DING, decimals set to 18
    uint256 public totalSupply   = 2 * (10 ** 6) * (10 ** 18);
    

    bool public pause=false;

    mapping(address => bool) lockAddresses;
    
    // constructor
    function Ducker(){    
        //allocate to ______
        balances[0xa53220c1b414f2E899fB53E3147e5CA6CDC0a79a]= 2 * (10 ** 6) * (10 ** 18);
        
    }

    // change the contract owner
    function changeOwner(address _new) public onlyOwner{
        owner=_new;
    }


    

    // pause all the transfer on the contract 
    function pauseContract() public onlyOwner{
        pause = true;
    }
    function resumeContract() public onlyOwner{
        pause = false;
    }
    function is_contract_paused() public view returns(bool){
        return pause;
    }
    

    // lock one&#39;s wallet
    function lock(address _addr) public onlyOwner{
        lockAddresses[_addr] = true; 
    }
    function unlock(address _addr) public onlyOwner{
        lockAddresses[_addr] = false; 
    }
    function am_I_locked(address _addr) public view returns(bool){
    	return lockAddresses[_addr];
    }
    
  
    // eth
    
  	
    function() payable {
    
    }
    
    function getETH(uint256 _amount) public onlyOwner{
        msg.sender.transfer(_amount);
    }
     

    /////////////////////////////////////////////////////////////////////
    ///////////////// ERC223 Standard functions /////////////////////////
    /////////////////////////////////////////////////////////////////////
    modifier transferable(address _addr) {
        require(!pause);
    	require(!lockAddresses[_addr]);
    	_;
    }
    function transfer(address _to, uint _value, bytes _data) public transferable(msg.sender) returns (bool) {
    	return super.transfer(_to, _value, _data);
    }
    function transfer(address _to, uint _value) public transferable(msg.sender) returns (bool) {
		return super.transfer(_to, _value);
    }


    /////////////////////////////////////////////////////////////////////
    ///////////////////  Rescue functions  //////////////////////////////
    /////////////////////////////////////////////////////////////////////
    function transferAnyERC20Token(address _tokenAddress, uint256 _value) public onlyOwner returns (bool) {
    	return ERC20(_tokenAddress).transfer(owner, _value);
  	}
}