contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract Own {
    address public owner;

    function Own() {
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

contract Pause is Own {
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

  // owner call to trigger a stop state
  function emergencyStop() external onlyOwner {
    stopped = true;
  }

  // owner call to restart from the stop state
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
  }

}

contract Puller {

  using SafeMath for uint;
  
  mapping(address => uint) public payments;

  event LogRefundETH(address to, uint value);

  function asyncSend(address dest, uint amount) internal {
    payments[dest] = payments[dest].add(amount);
  }

  // withdrwaw call for refunding balance acumilated by payee
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

contract BasicToken is ERC20Basic {
  
  using SafeMath for uint;
  
  mapping(address => uint) balances;
  
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

contract Token is StandardToken, Own {
  string public constant name = "TribeToken";
  string public constant symbol = "TRIBE";
  uint public constant decimals = 6;

  // Token constructor
  function Token() {
      totalSupply = 200000000000000;
      balances[msg.sender] = totalSupply; // send all created tokens to the owner/creator
  }

  // Burn function to burn a set amount of tokens
  function burner(uint _value) onlyOwner returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Transfer(msg.sender, 0x0, _value);
    return true;
  }

}

contract Crowdsale is Pause, Puller {
    
    using SafeMath for uint;

  	struct Backer {
		uint weiReceived; // Amount of Ether given
		uint coinSent;
	}
    
	//CONSTANTS
	// Maximum number of TRIBE to sell
	uint public constant MAX_CAP = 160000000000000; // 160 000 000 TRIBE
	// Minimum amount to invest
	uint public constant MIN_INVEST_ETHER = 100 finney; // 0.1ETH
	// Crowdsale period
	uint private constant CROWDSALE_PERIOD = 22 days; // 22 days crowdsale run
	// Number of TRIBE per Ether
	uint public constant COIN_PER_ETHER = 3000000000; // 3 000 TRIBE


	//VARIABLES
	// TRIBE contract reference
	Token public coin;
    // Multisig contract that will receive the Ether
	address public multisigEther;
	// Number of Ether received
	uint public etherReceived;
	// Number of TRIBE sent to Ether contributors
	uint public coinSentToEther;
  // Number of TRIBE to burn
  uint public coinToBurn;
	// Crowdsale start time
	uint public startTime;
	// Crowdsale end time
	uint public endTime;
 	// Is crowdsale still on going
	bool public crowdsaleClosed;
	// Refund open variable
	bool public refundsOpen;

	// Backers Ether indexed by their Ethereum address
	mapping(address => Backer) public backers;


	//MODIFIERS
	modifier respectTimeFrame() {
		if ((now < startTime) || (now > endTime )) throw;
		_;
	}
	
	modifier refundStatus() {
		if ((refundsOpen != true )) throw;
		_;
	}

	//EVENTS
	event LogReceivedETH(address addr, uint value);
	event LogCoinsEmited(address indexed from, uint amount);

	//Crowdsale Constructor
	function Crowdsale(address _TRIBEAddress, address _to) {
		coin = Token(_TRIBEAddress);
		multisigEther = _to;
	}
	
	// Default function to receive ether
	function() stopInEmergency respectTimeFrame payable {
		receiveETH(msg.sender);
	}

	 
	// To call to start the crowdsale
	function start() onlyOwner {
		if (startTime != 0) throw; // Crowdsale was already started

		startTime = now ;            
		endTime =  now + CROWDSALE_PERIOD;    
	}

	// Main function on ETH receive
	function receiveETH(address beneficiary) internal {
		if (msg.value < MIN_INVEST_ETHER) throw; // Do not accept investment if the amount is lower than the minimum allowed investment
		
		uint coinToSend = bonus(msg.value.mul(COIN_PER_ETHER).div(1 ether)); // Calculate the amount of tokens to send
		if (coinToSend.add(coinSentToEther) > MAX_CAP) throw;	

		Backer backer = backers[beneficiary];
		coin.transfer(beneficiary, coinToSend); // Transfer TRIBE

		backer.coinSent = backer.coinSent.add(coinToSend);
		backer.weiReceived = backer.weiReceived.add(msg.value); // Update the total wei collected during the crowdfunding for this backer    

		etherReceived = etherReceived.add(msg.value); // Update the total wei collected during the crowdfunding
		coinSentToEther = coinSentToEther.add(coinToSend);

		// Send events
		LogCoinsEmited(msg.sender ,coinToSend);
		LogReceivedETH(beneficiary, etherReceived); 
	}
	

	// Bonus function for the first week
	function bonus(uint amount) internal constant returns (uint) {
		if (now < startTime.add(7 days)) return amount.add(amount.div(5));   // bonus 20%
		return amount;
	}

	// Finalize function
	function finalize() onlyOwner public {

        // Check if the crowdsale has ended or if the old tokens have been sold
    if(coinSentToEther != MAX_CAP){
        if (now < endTime)  throw; // If Crowdsale still running
    }
		
		if (!multisigEther.send(this.balance)) throw; // Move the remaining Ether to the multisig address
		
		uint remains = coin.balanceOf(this);
		if (remains > 0) {
      coinToBurn = coinToBurn.add(remains);
      // Transfer remains to owner to burn
      coin.transfer(owner, remains);
		}
		crowdsaleClosed = true;
	}

	// Drain functions in case of unexpected issues with the smart contract.
  // ETH drain
	function drain() onlyOwner {
    if (!multisigEther.send(this.balance)) throw; //Transfer to team multisig wallet
	}
  // TOKEN drain
  function coinDrain() onlyOwner {
    uint remains = coin.balanceOf(this);
    coin.transfer(owner, remains); // Transfer to owner wallet
	}

	// Change multisig wallet in case its needed
	function changeMultisig(address addr) onlyOwner public {
		if (addr == address(0)) throw;
		multisigEther = addr;
	}

	// Change contract ownership
	function changeTribeOwner() onlyOwner public {
		coin.transferOwnership(owner);
	}

	// Toggle refund state on and off
	function setRefundState() onlyOwner public {
		if(refundsOpen == false){
			refundsOpen = true;
		}else{
			refundsOpen = false;
		}
	}

	//Refund function when minimum cap isnt reached, this is step is step 2, THIS FUNCTION ONLY AVAILABLE AFTER BEING ENABLED.
	//STEP1: From TRIBE token contract use "approve" function with the amount of TRIBE you got in total.
	//STEP2: From TRIBE crowdsale contract use "refund" function with the amount of TRIBE you got in total.
	//STEP3: From TRIBE crowdsale contract use "withdrawPayement" function to recieve the ETH.
	function refund(uint _value) refundStatus public {
		
		if (_value != backers[msg.sender].coinSent) throw; // compare value from backer balance

		coin.transferFrom(msg.sender, address(this), _value); // get the token back to the crowdsale contract

		uint ETHToSend = backers[msg.sender].weiReceived;
		backers[msg.sender].weiReceived=0;

		if (ETHToSend > 0) {
			asyncSend(msg.sender, ETHToSend); // pull payment to get refund in ETH
		}
	}

}

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