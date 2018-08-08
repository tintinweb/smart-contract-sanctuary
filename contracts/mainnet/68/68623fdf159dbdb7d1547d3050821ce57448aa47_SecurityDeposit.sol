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

contract SecurityDeposit is CATContract {
    uint public depositorLimit = 100;
    uint public instanceId = 1;
    mapping(uint => SecurityInstance) public instances;
    
    event SecurityDepositCreated(uint indexed id, address indexed instOwner, string ownerNote, string depositPurpose, uint depositAmount);
    event Deposit(uint indexed id, address indexed depositor, uint depositAmount, string note);
    event DepositClaimed(uint indexed id, address indexed fromWho, uint amountClaimed);
    event RefundSent(uint indexed id, address indexed toWho, uint amountRefunded);

    event DepositorLimitChanged(uint oldLimit, uint newLimit);

    enum DepositorState {None, Active, Claimed, Refunded}
    
    struct SecurityInstance {
        uint instId;
        address instOwner;
        string ownerNote;
        string depositPurpose;
        uint depositAmount;
        mapping(address => DepositorState) depositorState;
        mapping(address => string) depositorNote;
        address[] depositors;
    }
    
    modifier onlyInstanceOwner(uint _instId) {
        require(instances[_instId].instOwner == msg.sender);
        _;
    }
    
    modifier instanceExists(uint _instId) {
        require(instances[_instId].instId == _instId);
        _;
    }

    // Chain constructor to pass along CAT payment address, and contract name
    function SecurityDeposit(address _catPaymentCollector) CATContract(_catPaymentCollector, "Security Deposit") {}
    
    function createNewSecurityDeposit(string _ownerNote, string _depositPurpose, uint _depositAmount) external blockCatEntryPoint whenNotPaused returns (uint currentId) {
        // Deposit can&#39;t be greater than maximum allowed for each user
        require(_depositAmount <= ethPerTransactionLimit);
        // Cannot have a 0 deposit security deposit
        require(_depositAmount > 0);

        currentId = instanceId;
        address instanceOwner = msg.sender;
        uint depositAmountETH = _depositAmount;
        SecurityInstance storage curInst = instances[currentId];

        curInst.instId = currentId;
        curInst.instOwner = instanceOwner;
        curInst.ownerNote = _ownerNote;
        curInst.depositPurpose = _depositPurpose;
        curInst.depositAmount = depositAmountETH;
        
        SecurityDepositCreated(currentId, instanceOwner, _ownerNote, _depositPurpose, depositAmountETH);
        instanceId++;
    }
    
    function deposit(uint _instId, string _note) external payable instanceExists(_instId) limitTransactionValue whenNotPaused {
        SecurityInstance storage curInst = instances[_instId];
        // Must deposit the right amount
        require(curInst.depositAmount == msg.value);
        // Cannot have more depositors than the limit
        require(curInst.depositors.length < depositorLimit);
        // Cannot double-deposit
        require(curInst.depositorState[msg.sender] == DepositorState.None);

        curInst.depositorState[msg.sender] = DepositorState.Active;
        curInst.depositorNote[msg.sender] = _note;
        curInst.depositors.push(msg.sender);
        
        Deposit(curInst.instId, msg.sender, msg.value, _note);
    }
    
    function claim(uint _instId, address _whoToClaim) public onlyInstanceOwner(_instId) instanceExists(_instId) whenNotPaused returns (bool) {
        SecurityInstance storage curInst = instances[_instId];
        
        // Can only call if the state is active
        if(curInst.depositorState[_whoToClaim] != DepositorState.Active) {
            return false;
        }

        curInst.depositorState[_whoToClaim] = DepositorState.Claimed;
        curInst.instOwner.transfer(curInst.depositAmount);
        DepositClaimed(_instId, _whoToClaim, curInst.depositAmount);
        
        return true;
    }
    
    function refund(uint _instId, address _whoToRefund) public onlyInstanceOwner(_instId) instanceExists(_instId) whenNotPaused returns (bool) {
        SecurityInstance storage curInst = instances[_instId];
        
        // Can only call if state is active
        if(curInst.depositorState[_whoToRefund] != DepositorState.Active) {
            return false;
        }

        curInst.depositorState[_whoToRefund] = DepositorState.Refunded;
        _whoToRefund.transfer(curInst.depositAmount);
        RefundSent(_instId, _whoToRefund, curInst.depositAmount);
        
        return true;
    }
    
    function claimFromSeveral(uint _instId, address[] _toClaim) external onlyInstanceOwner(_instId) instanceExists(_instId) whenNotPaused {
        for(uint i = 0; i < _toClaim.length; i++) {
            claim(_instId, _toClaim[i]);
        }
    }
    
    function refundFromSeveral(uint _instId, address[] _toRefund) external onlyInstanceOwner(_instId) instanceExists(_instId) whenNotPaused {
        for(uint i = 0; i < _toRefund.length; i++) {
            refund(_instId, _toRefund[i]);
        }
    }
    
    function claimAll(uint _instId) external onlyInstanceOwner(_instId) instanceExists(_instId) whenNotPaused {
        SecurityInstance storage curInst = instances[_instId];
        
        for(uint i = 0; i < curInst.depositors.length; i++) {
            claim(_instId, curInst.depositors[i]);
        }
    }
    
    function refundAll(uint _instId) external onlyInstanceOwner(_instId) instanceExists(_instId) whenNotPaused {
        SecurityInstance storage curInst = instances[_instId];
        
        for(uint i = 0; i < curInst.depositors.length; i++) {
            refund(_instId, curInst.depositors[i]);
        }
    }

    function changeDepositorLimit(uint _newLimit) external onlyOwner {
        DepositorLimitChanged(depositorLimit, _newLimit);
        depositorLimit = _newLimit;
    }
    
    // Information functions
    
    function getInstanceMetadata(uint _instId) constant external returns (address instOwner, string ownerNote, string depositPurpose, uint depositAmount) {
        instOwner = instances[_instId].instOwner;
        ownerNote = instances[_instId].ownerNote;
        depositPurpose = instances[_instId].depositPurpose;
        depositAmount = instances[_instId].depositAmount;
    }
    
    function getAllDepositors(uint _instId) constant external returns (address[]) {
        return instances[_instId].depositors;
    }
    
    function checkInfo(uint _instId, address _depositor) constant external returns (DepositorState depositorState, string note) {
        depositorState = instances[_instId].depositorState[_depositor];
        note = instances[_instId].depositorNote[_depositor];
    }

    // Metrics

    function getDepositInstanceCount() constant external returns (uint) {
        return instanceId - 1; // ID is 1-indexed
    }
}