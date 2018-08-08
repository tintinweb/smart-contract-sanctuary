pragma solidity ^0.4.11;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
	function mul(uint a, uint b) internal returns (uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
	function safeSub(uint a, uint b) internal returns (uint) {
		assert(b <= a);
		return a - b;
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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
	bool public stopped;
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
	// called by the owner on emergency, triggers stopped state
	function emergencyStop() external onlyOwner {
		stopped = true;
	}
	// called by the owner on end of emergency, returns to normal state
	function release() external onlyOwner onlyInEmergency {
		stopped = false;
	}
}



/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract PullPayment {
	using SafeMath for uint;

	mapping(address => uint) public payments;
	event LogRefundETH(address to, uint value);
	/**
	*  Store sent amount as credit to be pulled, called by payer 
	**/
	function asyncSend(address dest, uint amount) internal {
		payments[dest] = payments[dest].add(amount);
	}
	// withdraw accumulated balance, called by payee
	function withdrawPayments() {
		address payee = msg.sender;
		uint payment = payments[payee];

		if (payment == 0) {
			throw;
		}
		if (this.balance < payment) {
		    throw;
		}
		payments[payee] = 0;
		if (!payee.send(payment)) {
		    throw;
		}
		LogRefundETH(payee,payment);
	}
}



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
	uint public totalSupply;
	function balanceOf(address who) constant returns (uint);
	function transfer(address to, uint value);
	event Transfer(address indexed from, address indexed to, uint value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) constant returns (uint);
	function transferFrom(address from, address to, uint value);
	function approve(address spender, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
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


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {
	mapping (address => mapping (address => uint)) allowed;
	function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
		var _allowance = allowed[_from][msg.sender];
		balances[_to] = balances[_to].add(_value);
		balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
    }
	function approve(address _spender, uint _value) {
		if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
	}
	function allowance(address _owner, address _spender) constant returns (uint remaining) {
		return allowed[_owner][_spender];
	}
}


/**
 *  Devvote tokens contract.
 */
contract DevotteToken is StandardToken, Ownable {
	
  using SafeMath for uint;
  

    /**
     * Variables
    */
    string public constant name = "DEVVOTE";
    string public constant symbol = "VVE";
    uint256 public constant decimals = 0;

   
    /**
     * @dev Contract constructor
     */ 
    function DevotteToken() {
    totalSupply = 100000000;
    balances[msg.sender] = totalSupply;
    }
    
    
    /**
    *  Burn away the specified amount of ClusterToken tokens.
    * @return Returns success boolean.
    */
    function burn(uint _value) onlyOwner returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Transfer(msg.sender, 0x0, _value);
        return true;
    }
    
}


contract DevvotePrefund is Pausable, PullPayment {
    
    using SafeMath for uint;
    
    
    enum memberRanking { Executive, boardMember, ActiveMember, supportingMember }
    memberRanking ranking;


  	struct Backer {
		uint weiReceived;
		uint coinSent;
		memberRanking userRank;
	}

	/*
	* Constants
	*/

	uint public constant MIN_CAP = 5000; // 
	uint public constant MAX_CAP = 250000; // 
	
	/* Minimum amount to invest */
	uint public constant MIN_INVEST_ETHER = 100 finney;
	uint public constant MIN_INVEST_BOARD = 10 ether ;
	uint public constant MIN_INVEST_ACTIVE = 3 ether;
	uint public constant MIN_INVEST_SUPPORT = 100 finney;

	uint private constant DevvotePrefund_PERIOD = 30 days;

	uint public constant COIN_PER_ETHER = 1000;
	uint public constant COIN_PER_ETHER_BOARD = 2500;
	uint public constant COIN_PER_ETHER_ACTIVE = 1500;
	uint public constant COIN_PER_ETHER_SUPPORT = 1000;


	/*
	* Variables
	*/

	DevotteToken public coin;
	address public multisigEther;
	uint public etherReceived;
	uint public coinSentToEther;

	uint public startTime;
	uint public endTime;
	bool public DevvotePrefundClosed;

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
	function DevvotePrefund(address _devvoteAddress, address _to) {
		coin = DevotteToken(_devvoteAddress);
		multisigEther = _to;
		start();
	}

	/* 
	 * The fallback function corresponds to a donation in ETH
	 */
	function() stopInEmergency respectTimeFrame payable {
		receiveETH(msg.sender);
	}

	/* 
	 * To call to start the DevvotePrefund
	 */
	function start() onlyOwner {
		if (startTime != 0) throw; // DevvotePrefund was already started

		startTime = now ;            
		endTime =  now + DevvotePrefund_PERIOD;    
	}

	/*
	 *	Receives a donation in Ether
	*/
	function receiveETH(address beneficiary) internal {
	    
	    memberRanking setRank;
	    uint coinToSend;
	    
		if (msg.value < MIN_INVEST_ETHER) throw; 
		
		
		if (msg.value < MIN_INVEST_ACTIVE && msg.value >= MIN_INVEST_ETHER ) { 
		    setRank = memberRanking.supportingMember;
		    coinToSend = bonus(msg.value.mul(COIN_PER_ETHER_SUPPORT).div(1 ether));
		}
		if (msg.value < MIN_INVEST_BOARD  && msg.value >= MIN_INVEST_ACTIVE) {
		    setRank = memberRanking.ActiveMember;
		    coinToSend = bonus(msg.value.mul(COIN_PER_ETHER_ACTIVE).div(1 ether));
		}
		if (msg.value >= MIN_INVEST_BOARD ) {
		    setRank = memberRanking.boardMember;
		    coinToSend = bonus(msg.value.mul(COIN_PER_ETHER_BOARD).div(1 ether));
		}
		
		
		if (coinToSend.add(coinSentToEther) > MAX_CAP) throw;	

		Backer backer = backers[beneficiary];
		coin.transfer(beneficiary, coinToSend); 
		backer.coinSent = backer.coinSent.add(coinToSend);
		backer.weiReceived = backer.weiReceived.add(msg.value);    
		backer.userRank = setRank;

		etherReceived = etherReceived.add(msg.value);
		coinSentToEther = coinSentToEther.add(coinToSend);

		LogCoinsEmited(msg.sender ,coinToSend);
		LogReceivedETH(beneficiary, etherReceived); 
	}
	

	/*
	 *Compute the Devvote bonus according to the investment period
	 */
	function bonus(uint amount) internal constant returns (uint) {
		return amount.add(amount.div(5));   // bonus 20%
	}

	/*	
	 * Finalize the DevvotePrefund, should be called after the refund period
	*/
	function finalize() onlyOwner public {

		if (now < endTime) { // Cannot finalise before DevvotePrefund_PERIOD or before selling all coins
			if (coinSentToEther == MAX_CAP) {
			} else {
				throw;
			}
		}

		if (coinSentToEther < MIN_CAP && now < endTime + 15 days) throw; // If MIN_CAP is not reached donors have 15days to get refund before we can finalise

		if (!multisigEther.send(this.balance)) throw; // Move the remaining Ether to the multisig address
		
		uint remains = coin.balanceOf(this);
		if (remains > 0) { // Burn the rest of Devvotes
			if (!coin.burn(remains)) throw ;
		}
		DevvotePrefundClosed = true;
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
	 * Manually back Devvote owner address.
	 */
	function backDevvoteOwner() onlyOwner public {
		coin.transferOwnership(owner);
	}

	/**
	 * Transfer remains to owner in case if impossible to do min invest
	 */
	function getRemainCoins() onlyOwner public {
		var remains = MAX_CAP - coinSentToEther;
		uint minCoinsToSell = bonus(MIN_INVEST_ETHER.mul(COIN_PER_ETHER) / (1 ether));

		if(remains > minCoinsToSell) throw;

		Backer backer = backers[owner];
		coin.transfer(owner, remains); // Transfer Devvotes right now 

		backer.coinSent = backer.coinSent.add(remains);

		coinSentToEther = coinSentToEther.add(remains);

		// Send events
		LogCoinsEmited(this ,remains);
		LogReceivedETH(owner, etherReceived); 
	}


	/* 
  	 * When MIN_CAP is not reach:
  	 * 1) backer call the "approve" function of the Devvote token contract with the amount of all Devvotes they got in order to be refund
  	 * 2) backer call the "refund" function of the DevvotePrefund contract with the same amount of Devvotes
   	 * 3) backer call the "withdrawPayments" function of the DevvotePrefund contract to get a refund in ETH
   	 */
	function refund(uint _value) minCapNotReached public {
		
		if (_value != backers[msg.sender].coinSent) throw; // compare value from backer balance

		coin.transferFrom(msg.sender, address(this), _value); // get the token back to the DevvotePrefund contract

		if (!coin.burn(_value)) throw ; // token sent for refund are burnt

		uint ETHToSend = backers[msg.sender].weiReceived;
		backers[msg.sender].weiReceived=0;

		if (ETHToSend > 0) {
			asyncSend(msg.sender, ETHToSend); // pull payment to get refund in ETH
		}
	}

}