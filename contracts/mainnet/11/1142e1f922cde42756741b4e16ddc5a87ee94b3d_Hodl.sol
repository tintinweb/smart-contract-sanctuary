pragma solidity ^0.4.13;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract CATContract is Ownable, Pausable {
	CATServicePaymentCollector public catPaymentCollector;
	uint public contractFee = 0.1 * 10**18; // Base fee is 0.1 CAT
	// Limits all transactions to a small amount to avoid financial risk with early code
	uint public ethPerTransactionLimit = 0.1 ether;
	string public contractName;
	string public versionIdent = "0.1.0";

	event ContractDeployed(address indexed byWho);
	event ContractFeeChanged(uint oldFee, uint newFee);
	event ContractEthLimitChanged(uint oldLimit, uint newLimit);

	event CATWithdrawn(uint numOfTokens);

	modifier blockCatEntryPoint() {
		// Collect payment
		catPaymentCollector.collectPayment(msg.sender, contractFee);
		ContractDeployed(msg.sender);
		_;
	}

	modifier limitTransactionValue() {
		require(msg.value <= ethPerTransactionLimit);
		_;
	}

	function CATContract(address _catPaymentCollector, string _contractName) {
		catPaymentCollector = CATServicePaymentCollector(_catPaymentCollector);
		contractName = _contractName;
	}

	// Administrative functions

	function changeContractFee(uint _newFee) external onlyOwner {
		// _newFee is assumed to be given in full CAT precision (18 decimals)
		ContractFeeChanged(contractFee, _newFee);
		contractFee = _newFee;
	}

	function changeEtherTxLimit(uint _newLimit) external onlyOwner {
		ContractEthLimitChanged(ethPerTransactionLimit, _newLimit);
		ethPerTransactionLimit = _newLimit;
	}

	function withdrawCAT() external onlyOwner {
		StandardToken CAT = catPaymentCollector.CAT();
		uint ourTokens = CAT.balanceOf(this);
		CAT.transfer(owner, ourTokens);
		CATWithdrawn(ourTokens);
	}
}

contract CATServicePaymentCollector is Ownable {
	StandardToken public CAT;
	address public paymentDestination;
	uint public totalDeployments = 0;
	mapping(address => bool) public registeredServices;
	mapping(address => uint) public serviceDeployCount;
	mapping(address => uint) public userDeployCount;

	event CATPayment(address indexed service, address indexed payer, uint price);
	event EnableService(address indexed service);
	event DisableService(address indexed service);
	event ChangedPaymentDestination(address indexed oldDestination, address indexed newDestination);

	event CATWithdrawn(uint numOfTokens);
	
	function CATServicePaymentCollector(address _CAT) {
		CAT = StandardToken(_CAT);
		paymentDestination = msg.sender;
	}
	
	function enableService(address _service) public onlyOwner {
		registeredServices[_service] = true;
		EnableService(_service);
	}
	
	function disableService(address _service) public onlyOwner {
		registeredServices[_service] = false;
		DisableService(_service);
	}
	
	function collectPayment(address _fromWho, uint _payment) public {
		require(registeredServices[msg.sender] == true);
		
		serviceDeployCount[msg.sender]++;
		userDeployCount[_fromWho]++;
		totalDeployments++;
		
		CAT.transferFrom(_fromWho, paymentDestination, _payment);
		CATPayment(_fromWho, msg.sender, _payment);
	}

	// Administrative functions

	function changePaymentDestination(address _newPaymentDest) external onlyOwner {
		ChangedPaymentDestination(paymentDestination, _newPaymentDest);
		paymentDestination = _newPaymentDest;
	}

	function withdrawCAT() external onlyOwner {
		uint ourTokens = CAT.balanceOf(this);
		CAT.transfer(owner, ourTokens);
		CATWithdrawn(ourTokens);
	}
}

contract Hodl is CATContract {
    uint public instanceId = 1;
    mapping(uint => HodlInstance) public instances;

    uint public maximumHodlDuration = 4 weeks;

    event HodlCreated(uint indexed id, address indexed instOwner, uint hodlAmount, uint endTime);
    event HodlWithdrawn(uint indexed id, address indexed byWho, uint hodlAmount);

    event MaximumHodlDurationChanged(uint oldLimit, uint newLimit);

    struct HodlInstance {
        uint instId;
        address instOwner;
        bool hasBeenWithdrawn;
        uint hodlAmount;
        uint endTime;
    }

    modifier onlyInstanceOwner(uint _instId) {
        require(instances[_instId].instOwner == msg.sender);
        _;
    }
    
    modifier instanceExists(uint _instId) {
        require(instances[_instId].instId == _instId);
        _;
    }

    // Chain constructor
    function Hodl(address _catPaymentCollector) CATContract(_catPaymentCollector, "Hodl") {}

    function createNewHodl(uint _endTime) external payable blockCatEntryPoint limitTransactionValue whenNotPaused returns (uint currentId) {
        // Cannot hodl in the past
        require(_endTime >= now);
        // Cannot hodl for longer than the max cap on duration
        require((_endTime - now) <= maximumHodlDuration);
        // Cannot hodl nothing
        require(msg.value > 0);

        currentId = instanceId;
        address instanceOwner = msg.sender;
        uint hodlAmount = msg.value;
        uint endTime = _endTime;
        HodlInstance storage curInst = instances[currentId];

        curInst.instId = currentId;
        curInst.instOwner = instanceOwner;
        curInst.hasBeenWithdrawn = false;
        curInst.hodlAmount = hodlAmount;
        curInst.endTime = endTime;
        
        HodlCreated(currentId, instanceOwner, hodlAmount, endTime);
        instanceId++;
    }

    function withdraw(uint _instId) external onlyInstanceOwner(_instId) instanceExists(_instId) whenNotPaused {
        HodlInstance storage curInst = instances[_instId];
        // The hodl has passed its unlock date
        require(now >= curInst.endTime);
        // The hodl has not been withdrawn before
        require(curInst.hasBeenWithdrawn == false);

        curInst.hasBeenWithdrawn = true;
        curInst.instOwner.transfer(curInst.hodlAmount);
        HodlWithdrawn(_instId, msg.sender, curInst.hodlAmount);
    }

    function changeMaximumHodlDuration(uint _newLimit) external onlyOwner {
        MaximumHodlDurationChanged(maximumHodlDuration, _newLimit);
        maximumHodlDuration = _newLimit;
    }

    // Information functions
    function getHodlOwner(uint _instId) constant external returns (address) {
        return instances[_instId].instOwner;
    }

    function getHodlHasBeenWithdrawn(uint _instId) constant external returns (bool) {
        return instances[_instId].hasBeenWithdrawn;
    }

    function getHodlAmount(uint _instId) constant external returns (uint) {
        return instances[_instId].hodlAmount;
    }

    function getEndTime(uint _instId) constant external returns (uint) {
        return instances[_instId].endTime;
    }

    function getTimeUntilEnd(uint _instId) constant external returns (int) {
        return int(instances[_instId].endTime - now);
    }
}