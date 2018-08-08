pragma solidity^0.4.11;

/**
 * Math operations with safety checks
 */
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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
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

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


contract CATToken is StandardToken {
	using SafeMath for uint256;
	
	// keccak256 hash of hidden cap
	string public constant HIDDEN_CAP = "0xd22f19d54193ff5e08e7ba88c8e52ec1b9fc8d4e0cf177e1be8a764fa5b375fa";
	
	// Events
	event CreatedCAT(address indexed _creator, uint256 _amountOfCAT);
	event CATRefundedForWei(address indexed _refunder, uint256 _amountOfWei);
	
	// Token data
	string public constant name = "BlockCAT Token";
	string public constant symbol = "CAT";
	uint256 public constant decimals = 18;  // Since our decimals equals the number of wei per ether, we needn&#39;t multiply sent values when converting between CAT and ETH.
	string public version = "1.0";
	
	// Addresses and contracts
	address public executor;
	address public devETHDestination;
	address public devCATDestination;
	address public reserveCATDestination;
	
	// Sale data
	bool public saleHasEnded;
	bool public minCapReached;
	bool public allowRefund;
	mapping (address => uint256) public ETHContributed;
	uint256 public totalETHRaised;
	uint256 public saleStartBlock;
	uint256 public saleEndBlock;
	uint256 public saleFirstEarlyBirdEndBlock;
	uint256 public saleSecondEarlyBirdEndBlock;
	uint256 public constant DEV_PORTION = 20;  // In percentage
	uint256 public constant RESERVE_PORTION = 1;  // In percentage
	uint256 public constant ADDITIONAL_PORTION = DEV_PORTION + RESERVE_PORTION;
	uint256 public constant SECURITY_ETHER_CAP = 1000000 ether;
	uint256 public constant CAT_PER_ETH_BASE_RATE = 300;  // 300 CAT = 1 ETH during normal part of token sale
	uint256 public constant CAT_PER_ETH_FIRST_EARLY_BIRD_RATE = 330;
	uint256 public constant CAT_PER_ETH_SECOND_EARLY_BIRD_RATE = 315;
	
	function CATToken(
		address _devETHDestination,
		address _devCATDestination,
		address _reserveCATDestination,
		uint256 _saleStartBlock,
		uint256 _saleEndBlock
	) {
		// Reject on invalid ETH destination address or CAT destination address
		if (_devETHDestination == address(0x0)) throw;
		if (_devCATDestination == address(0x0)) throw;
		if (_reserveCATDestination == address(0x0)) throw;
		// Reject if sale ends before the current block
		if (_saleEndBlock <= block.number) throw;
		// Reject if the sale end time is less than the sale start time
		if (_saleEndBlock <= _saleStartBlock) throw;

		executor = msg.sender;
		saleHasEnded = false;
		minCapReached = false;
		allowRefund = false;
		devETHDestination = _devETHDestination;
		devCATDestination = _devCATDestination;
		reserveCATDestination = _reserveCATDestination;
		totalETHRaised = 0;
		saleStartBlock = _saleStartBlock;
		saleEndBlock = _saleEndBlock;
		saleFirstEarlyBirdEndBlock = saleStartBlock + 6171;  // Equivalent to 24 hours later, assuming 14 second blocks
		saleSecondEarlyBirdEndBlock = saleFirstEarlyBirdEndBlock + 12342;  // Equivalent to 48 hours later after first early bird, assuming 14 second blocks

		totalSupply = 0;
	}
	
	function createTokens() payable external {
		// If sale is not active, do not create CAT
		if (saleHasEnded) throw;
		if (block.number < saleStartBlock) throw;
		if (block.number > saleEndBlock) throw;
		// Check if the balance is greater than the security cap
		uint256 newEtherBalance = totalETHRaised.add(msg.value);
		if (newEtherBalance > SECURITY_ETHER_CAP) throw; 
		// Do not do anything if the amount of ether sent is 0
		if (0 == msg.value) throw;
		
		// Calculate the CAT to ETH rate for the current time period of the sale
		uint256 curTokenRate = CAT_PER_ETH_BASE_RATE;
		if (block.number < saleFirstEarlyBirdEndBlock) {
			curTokenRate = CAT_PER_ETH_FIRST_EARLY_BIRD_RATE;
		}
		else if (block.number < saleSecondEarlyBirdEndBlock) {
			curTokenRate = CAT_PER_ETH_SECOND_EARLY_BIRD_RATE;
		}
		
		// Calculate the amount of CAT being purchased
		uint256 amountOfCAT = msg.value.mul(curTokenRate);
		
		// Ensure that the transaction is safe
		uint256 totalSupplySafe = totalSupply.add(amountOfCAT);
		uint256 balanceSafe = balances[msg.sender].add(amountOfCAT);
		uint256 contributedSafe = ETHContributed[msg.sender].add(msg.value);

		// Update individual and total balances
		totalSupply = totalSupplySafe;
		balances[msg.sender] = balanceSafe;

		totalETHRaised = newEtherBalance;
		ETHContributed[msg.sender] = contributedSafe;

		CreatedCAT(msg.sender, amountOfCAT);
	}
	
	function endSale() {
		// Do not end an already ended sale
		if (saleHasEnded) throw;
		// Can&#39;t end a sale that hasn&#39;t hit its minimum cap
		if (!minCapReached) throw;
		// Only allow the owner to end the sale
		if (msg.sender != executor) throw;
		
		saleHasEnded = true;

		// Calculate and create developer and reserve portion of CAT
		uint256 additionalCAT = (totalSupply.mul(ADDITIONAL_PORTION)).div(100 - ADDITIONAL_PORTION);
		uint256 totalSupplySafe = totalSupply.add(additionalCAT);

		uint256 reserveShare = (additionalCAT.mul(RESERVE_PORTION)).div(ADDITIONAL_PORTION);
		uint256 devShare = additionalCAT.sub(reserveShare);

		totalSupply = totalSupplySafe;
		balances[devCATDestination] = devShare;
		balances[reserveCATDestination] = reserveShare;
		
		CreatedCAT(devCATDestination, devShare);
		CreatedCAT(reserveCATDestination, reserveShare);

		if (this.balance > 0) {
			if (!devETHDestination.call.value(this.balance)()) throw;
		}
	}

	// Allows BlockCAT to withdraw funds
	function withdrawFunds() {
		// Disallow withdraw if the minimum hasn&#39;t been reached
		if (!minCapReached) throw;
		if (0 == this.balance) throw;

		if (!devETHDestination.call.value(this.balance)()) throw;
	}
	
	// Signals that the sale has reached its minimum funding goal
	function triggerMinCap() {
		if (msg.sender != executor) throw;

		minCapReached = true;
	}

	// Opens refunding.
	function triggerRefund() {
		// No refunds if the sale was successful
		if (saleHasEnded) throw;
		// No refunds if minimum cap is hit
		if (minCapReached) throw;
		// No refunds if the sale is still progressing
		if (block.number < saleEndBlock) throw;
		if (msg.sender != executor) throw;

		allowRefund = true;
	}

	function refund() external {
		// No refunds until it is approved
		if (!allowRefund) throw;
		// Nothing to refund
		if (0 == ETHContributed[msg.sender]) throw;

		// Do the refund.
		uint256 etherAmount = ETHContributed[msg.sender];
		ETHContributed[msg.sender] = 0;

		CATRefundedForWei(msg.sender, etherAmount);
		if (!msg.sender.send(etherAmount)) throw;
	}

	function changeDeveloperETHDestinationAddress(address _newAddress) {
		if (msg.sender != executor) throw;
		devETHDestination = _newAddress;
	}
	
	function changeDeveloperCATDestinationAddress(address _newAddress) {
		if (msg.sender != executor) throw;
		devCATDestination = _newAddress;
	}
	
	function changeReserveCATDestinationAddress(address _newAddress) {
		if (msg.sender != executor) throw;
		reserveCATDestination = _newAddress;
	}
	
	function transfer(address _to, uint _value) {
		// Cannot transfer unless the minimum cap is hit
		if (!minCapReached) throw;
		
		super.transfer(_to, _value);
	}
	
	function transferFrom(address _from, address _to, uint _value) {
		// Cannot transfer unless the minimum cap is hit
		if (!minCapReached) throw;
		
		super.transferFrom(_from, _to, _value);
	}
}