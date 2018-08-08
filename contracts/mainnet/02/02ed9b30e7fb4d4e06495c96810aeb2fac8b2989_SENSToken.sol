pragma solidity^0.4.13;

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


contract SENSToken is StandardToken {
	using SafeMath for uint256;

	string public constant name = "SENS Token";
	string public constant symbol = "SNS";
	uint256 public constant decimals = 18; 
	string public version = "1.0";
	
	address public executor;
	address public devETHDestination;
	address public devSENSDestination;
	
	bool public saleHasEnded;
	bool public minCapReached;
	bool public allowRefund;

	mapping (address => uint256) public ETHContributed;

	uint256 public totalETHRaised;
	uint256 public saleStartBlock;
	uint256 public saleEndBlock;
	uint256 public constant DEV_PORTION = 45;
	uint256 public constant SECURITY_ETHER_CAP = 20000 ether;
	uint256 public constant SENS_PER_ETH_BASE_RATE = 500; 
	
	function SENSToken(
		address _devETHDestination,
		address _devSENSDestination,
		uint256 _saleStartBlock,
		uint256 _saleEndBlock
	) {
		if (_devETHDestination == address(0x0)) throw;
		if (_devSENSDestination == address(0x0)) throw;
		if (_saleEndBlock <= block.number) throw;
		if (_saleEndBlock <= _saleStartBlock) throw;

		executor = msg.sender;

		saleHasEnded = false;
		minCapReached = false;
		allowRefund = false;

		devETHDestination = _devETHDestination;
		devSENSDestination = _devSENSDestination;

		totalETHRaised = 0;
		saleStartBlock = _saleStartBlock;
		saleEndBlock = _saleEndBlock;
		totalSupply = 0;
	}
	
	function createTokens() payable external {
		if (saleHasEnded) throw;
		if (block.number < saleStartBlock) throw;
		if (block.number > saleEndBlock) throw;
		uint256 newEtherBalance = totalETHRaised.add(msg.value);
		if (newEtherBalance > SECURITY_ETHER_CAP) throw; 
		if (0 == msg.value) throw;
		
		uint256 curTokenRate = SENS_PER_ETH_BASE_RATE;
		uint256 amountOfETH = msg.value.mul(curTokenRate);

		uint256 totalSupplySafe = totalSupply.add(amountOfETH);
		uint256 balanceSafe = balances[msg.sender].add(amountOfETH);
		uint256 contributedSafe = ETHContributed[msg.sender].add(msg.value);

		totalSupply = totalSupplySafe;
		balances[msg.sender] = balanceSafe;

		totalETHRaised = newEtherBalance;
		ETHContributed[msg.sender] = contributedSafe;

	}
	
	function endSale() {
		if (saleHasEnded) throw;
		if (!minCapReached) throw;
		if (msg.sender != executor) throw;
		
		saleHasEnded = true;

        uint256 additionalSENS = (totalSupply.mul(DEV_PORTION)).div(100 - DEV_PORTION);
		uint256 totalSupplySafe = totalSupply.add(additionalSENS);

		uint256 devShare = additionalSENS;

		totalSupply = totalSupplySafe;
		balances[devSENSDestination] = devShare;

		if (this.balance > 0) {
			if (!devETHDestination.call.value(this.balance)()) throw;
		}
	}

	function withdrawFunds() {
		if (0 == this.balance) throw;
		if (!devETHDestination.call.value(this.balance)()) throw;
	}
	
	function changeDeveloperETHDestinationAddress(address _newAddress) {
		if (msg.sender != executor) throw;
		devETHDestination = _newAddress;
	}
	
	function changeDeveloperSENSDestinationAddress(address _newAddress) {
		if (msg.sender != executor) throw;
		devSENSDestination = _newAddress;
	}
	
	function transfer(address _to, uint _value) {
		super.transfer(_to, _value);
	}
	
	function transferFrom(address _from, address _to, uint _value) {
		super.transferFrom(_from, _to, _value);
	}
}