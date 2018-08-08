/*
 * VISTA FINTECH  
 * SMART CONTRACT FOR CROWNSALE http://www.vistafin.com
 * Edit by Ray Indinor
 * Approved by Jacky Hsieh
 */

pragma solidity ^0.4.11;
library SafeMath {
	function mul(uint a, uint b) internal returns (uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
	
	function div(uint a, uint b) internal returns (uint) {
		assert(b > 0);
		uint c = a / b;
		assert(a == b * c + a % b);
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


contract Ownable {
    address public owner;
    function Ownable() {
        owner = msg.sender;
    }
	
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
	
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}



/*
 * Pausable Function
 * Abstract contract that allows children to implement an emergency stop function. 
 */
contract Pausable is Ownable {
	bool public stopped = false;
	modifier stopInEmergency {
		if (stopped) {
			throw;
		}
		_;
	}
  
	modifier onlyInEmergency {
		if (!stopped) {
			throw;
		}
		_;
	}
	
/*
 * EmergencyStop Function
 * called by the owner on emergency, triggers stopped state 
 */
function emergencyStop() external onlyOwner {
    stopped = true;
	}

	
/*
 * Release EmergencyState Function
 * called by the owner on end of emergency, returns to normal state
 */  

function release() external onlyOwner onlyInEmergency {
    stopped = false;
	}
}

/*
 * ERC20Basic class
 * Abstract contract that allows children to implement ERC20basic persistent data in state variables.
 */ 	
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}


/*
 * ERC20 class
 * Abstract contract that allows children to implement ERC20 persistent data in state variables.
 */ 
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) constant returns (uint);
	function transferFrom(address from, address to, uint value);
	function approve(address spender, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}



/*
 * BasicToken class
 * Abstract contract that allows children to implement BasicToken functions and  persistent data in state variables.
 */

contract BasicToken is ERC20Basic {
  
	using SafeMath for uint;
  
	mapping(address => uint) balances;
  
	/*
	* Fix for the ERC20 short address attack  
	*/
	modifier onlyPayloadSize(uint size) {
		if(msg.data.length < size + 4) {
		throw;
		}
		_;
	}
	
	function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
	}
	
	function balanceOf(address _owner) constant returns (uint balance) {
		return balances[_owner];
	}
}



/*
 * StandardToken class
 * Abstract contract that allows children to implement StandToken functions and  persistent data in state variables.
 */
contract StandardToken is BasicToken, ERC20 {
	mapping (address => mapping (address => uint)) allowed;
	function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }
	function approve(address _spender, uint _value) {
		// To change the approve amount you first have to reduce the addresses`
		//  allowance to zero by calling `approve(_spender, 0)` if it is not
		//  already 0 to mitigate the race condition described here:
		//  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
		if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
	}
	function allowance(address _owner, address _spender) constant returns (uint remaining) {
		return allowed[_owner][_spender];
	}
}



/**
 * ================================================================================
 * VISTA token smart contract. Implements
 * VISTACOIN class
 */
contract VISTAcoin is StandardToken, Ownable {
	string public constant name = "VISTAcoin";
	string public constant symbol = "VTA";
	uint public constant decimals = 0;
	// Constructor
	function VISTAcoin() {
		totalSupply = 50000000;
		balances[msg.sender] = totalSupply; // Send all tokens to owner
	}
}