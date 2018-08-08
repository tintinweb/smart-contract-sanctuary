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






/**
 * Crowdsale Smart Contract for VISTA FINTECH
 * This smart contract collects ETH, and in return emits VISTAcoin tokens to the backers
 */
contract VISTACrowdSaleP1 is Pausable {
    
    using SafeMath for uint;
    struct Backer {
        uint weiReceived; // Amount of Ether given
        uint coinSent;
    }
	
    /*
    * Constants
    */
    /* Minimum number of VISTAcoin to sell */
    uint public constant MIN_CAP = 1; // 1 VISTAcoins
    /* Maximum number of VISTAcoin to sell */
    uint public constant MAX_CAP = 5000000; // 5000 VISTAcoins
    /* Minimum amount to invest */
    uint public constant MIN_INVEST_ETHER = 500 finney;
    /* Crowdsale period */
    uint private constant CROWDSALE_PERIOD = 15 days;
    /* Number of VISTAcoins per Ether */
    uint public constant COIN_PER_ETHER = 350; // 1 VISTAcoins/eth
	
	
	
	
    /*
    * Variables
    */
    /* VISTAcoin contract reference */
    VISTAcoin public coin;
    /* Multisig contract that will receive the Ether */
    address public multisigEther;
    /* Number of Ether received */
    uint public etherReceived;
    /* Number of VISTAcoins sent to Ether contributors */
    uint public coinSentToEther;
    /* Crowdsale start time */
    uint public startTime;
    /* Crowdsale end time */
    uint public endTime;
    /* Is crowdsale still on going */
    bool public crowdsaleClosed = false;
    /* Backers Ether indexed by their Ethereum address */
    mapping(address => Backer) public backers;
	
	
	
	
    /*
    * Modifiers
    */
    modifier minCapNotReached() {
        if ((now < endTime) || coinSentToEther >= MIN_CAP ) throw;
        _;
    }
    modifier respectTimeFrame() {
        if ((now < startTime) || (now > endTime )) throw;
        _;
    }
	
	
    /*
     * Event
    */
    event LogReceivedETH(address addr, uint value);
    event LogCoinsEmited(address indexed from, uint amount);
	
	
    /*
     * Constructor
    */
    function VISTACrowdSaleP1(address _VISTAcoinAddress, address _to) {
        coin = VISTAcoin(_VISTAcoinAddress);
        multisigEther = _to;
    }
	
	
    /* 
     * The fallback function corresponds to a donation in ETH
     */
    function() stopInEmergency respectTimeFrame payable {
        if (crowdsaleClosed) throw; //Crowdsale was closed.
		receiveETH(msg.sender);
    }
	
	
    /* 
     * To call to start the crowdsale
     */
    function start() onlyOwner {
        if (startTime != 0) throw; // Crowdsale was already started
        startTime = now ;            
        endTime =  now + CROWDSALE_PERIOD;    
    }
	
	
    /*
     *  Receives a donation in Ether
    */
    function receiveETH(address beneficiary) internal {
        if (msg.value < MIN_INVEST_ETHER) throw; // Don&#39;t accept funding under a predefined threshold        
        uint coinToSend = bonus(msg.value.mul(COIN_PER_ETHER).div(1 ether)); // Compute the number of VISTAcoin to send
        if (coinToSend.add(coinSentToEther) > MAX_CAP) throw;    
        Backer backer = backers[beneficiary];
        coin.transfer(beneficiary, coinToSend); // Transfer VISTAcoins right now
		if (!multisigEther.send(this.balance)) throw; //Transfer ETH to VISTA ECC		
        backer.coinSent = backer.coinSent.add(coinToSend);
        backer.weiReceived = backer.weiReceived.add(msg.value); // Update the total wei collected during the crowdfunding for this backer    
        etherReceived = etherReceived.add(msg.value); // Update the total wei collected during the crowdfunding
        coinSentToEther = coinSentToEther.add(coinToSend);
        // Send events
        LogCoinsEmited(msg.sender ,coinToSend);
        LogReceivedETH(beneficiary, etherReceived); 
    }
    
    /*
     *Compute the VISTAcoin BONUS according to the investment period
     */
    function bonus(uint amount) internal constant returns (uint) {
        return amount.add(amount.div(5));   // bonus 20%
    }
	
	
	
	
    /*  
     * FINALIZE the crowdsale, should be called after ico period
    */
    function finalize() onlyOwner public {
        if (now < endTime) { // Cannot finalise before CROWDSALE_PERIOD or before selling all coins
            if (coinSentToEther == MAX_CAP) {
            } else {
                throw;
            }
        }
        if (!multisigEther.send(this.balance)) throw; // Move the remaining Ether to the multisig address
		getRemainCoins();
        crowdsaleClosed = true;
    }
	
	
    /*  
    * Failsafe drain
    */
    function drain() onlyOwner {
        if (!owner.send(this.balance)) throw;
    }
	
	
    /**
     * Allow to change the team multisig address in the case of emergency.
     */
    function setMultisig(address addr) onlyOwner public {
        if (addr == address(0)) throw;
        multisigEther = addr;
    }
	
	
    /**
     * Manually back VISTAcoin owner address.
     */
    function backVISTAcoinOwner() onlyOwner public {
        coin.transferOwnership(owner);
    }
	
	
    /**
     * Get reamin coins back to owner
     */
    function getRemainCoins() onlyOwner public {
        var remains = MAX_CAP - coinSentToEther;
        Backer backer = backers[owner];
        coin.transfer(owner, remains); // Transfer VISTAcoins right now 
        backer.coinSent = backer.coinSent.add(remains);
        coinSentToEther = coinSentToEther.add(remains);
        // Send events
        LogCoinsEmited(this ,remains);
        LogReceivedETH(owner, etherReceived); 
    }
}