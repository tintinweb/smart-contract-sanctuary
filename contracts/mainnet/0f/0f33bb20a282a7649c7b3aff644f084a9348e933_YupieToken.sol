pragma solidity ^0.4.11;

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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
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

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
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
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract YupieToken is StandardToken {
	using SafeMath for uint256;

    // EVENTS
    event CreatedYUPIE(address indexed _creator, uint256 _amountOfYUPIE);

	
	// TOKEN DATA
	string public constant name = "YUPIE";
	string public constant symbol = "YUP";
	uint256 public constant decimals = 18;
	string public version = "1.0";

	// YUPIE TOKEN PURCHASE LIMITS
	uint256 public maxPresaleSupply; 														// MAX TOTAL DURING PRESALE (0.8% of MAXTOTALSUPPLY)

	// PURCHASE DATES
	uint256 public constant preSaleStartTime = 1502784000; 									// GMT: Tuesday, August 15, 2017 8:00:00 AM
	uint256 public constant preSaleEndTime = 1505671200; 									// GMT: Sunday, September 17, 2017 6:00:00 PM
	uint256 public saleStartTime = 1509523200; 												// GMT: Wednesday, November 1, 2017 8:00:00 AM
	uint256 public saleEndTime = 1512115200; 												// GMT: Friday, December 1, 2017 8:00:00 AM

	// PURCHASE BONUSES
	uint256 public lowEtherBonusLimit = 5 * 1 ether; 										// 5+ Ether
	uint256 public lowEtherBonusValue = 110;												// 10% Discount
	uint256 public midEtherBonusLimit = 24 * 1 ether; 										// 24+ Ether
	uint256 public midEtherBonusValue = 115;												// 15% Discount
	uint256 public highEtherBonusLimit = 50 * 1 ether; 										// 50+ Ether
	uint256 public highEtherBonusValue = 120; 												// 20% Discount
	uint256 public highTimeBonusLimit = 0; 													// 1-12 Days
	uint256 public highTimeBonusValue = 120; 												// 20% Discount
	uint256 public midTimeBonusLimit = 1036800; 											// 12-24 Days
	uint256 public midTimeBonusValue = 115; 												// 15% Discount
	uint256 public lowTimeBonusLimit = 2073600;												// 24+ Days
	uint256 public lowTimeBonusValue = 110;													// 10% Discount

	// PRICING INFO
	uint256 public constant YUPIE_PER_ETH_PRE_SALE = 3000;  								// 3000 YUPIE = 1 ETH
	uint256 public constant YUPIE_PER_ETH_SALE = 1000;  									// 1000 YUPIE = 1 ETH
	
	// ADDRESSES
	address public constant ownerAddress = 0x20C84e76C691e38E81EaE5BA60F655b8C388718D; 		// The owners address

	// STATE INFO	
	bool public allowInvestment = true;														// Flag to change if transfering is allowed
	uint256 public totalWEIInvested = 0; 													// Total WEI invested
	uint256 public totalYUPIESAllocated = 0;												// Total YUPIES allocated
	mapping (address => uint256) public WEIContributed; 									// Total WEI Per Account


	// INITIALIZATIONS FUNCTION
	function YupieToken() {
		require(msg.sender == ownerAddress);

		totalSupply = 631*1000000*1000000000000000000; 										// MAX TOTAL YUPIES 631 million
		uint256 totalYUPIESReserved = totalSupply.mul(55).div(100);							// 55% reserved for Crowdholding
		maxPresaleSupply = totalSupply*8/1000 + totalYUPIESReserved; 						// MAX TOTAL DURING PRESALE (0.8% of MAXTOTALSUPPLY)

		balances[msg.sender] = totalYUPIESReserved;
		totalYUPIESAllocated = totalYUPIESReserved;				
	}


	// FALL BACK FUNCTION TO ALLOW ETHER DONATIONS
	function() payable {

		require(allowInvestment);

		// Smallest investment is 0.00001 ether
		uint256 amountOfWei = msg.value;
		require(amountOfWei >= 10000000000000);

		uint256 amountOfYUPIE = 0;
		uint256 absLowTimeBonusLimit = 0;
		uint256 absMidTimeBonusLimit = 0;
		uint256 absHighTimeBonusLimit = 0;
		uint256 totalYUPIEAvailable = 0;

		// Investment periods
		if (block.timestamp > preSaleStartTime && block.timestamp < preSaleEndTime) {
			// Pre-sale ICO
			amountOfYUPIE = amountOfWei.mul(YUPIE_PER_ETH_PRE_SALE);
			absLowTimeBonusLimit = preSaleStartTime + lowTimeBonusLimit;
			absMidTimeBonusLimit = preSaleStartTime + midTimeBonusLimit;
			absHighTimeBonusLimit = preSaleStartTime + highTimeBonusLimit;
			totalYUPIEAvailable = maxPresaleSupply - totalYUPIESAllocated;
		} else if (block.timestamp > saleStartTime && block.timestamp < saleEndTime) {
			// ICO
			amountOfYUPIE = amountOfWei.mul(YUPIE_PER_ETH_SALE);
			absLowTimeBonusLimit = saleStartTime + lowTimeBonusLimit;
			absMidTimeBonusLimit = saleStartTime + midTimeBonusLimit;
			absHighTimeBonusLimit = saleStartTime + highTimeBonusLimit;
			totalYUPIEAvailable = totalSupply - totalYUPIESAllocated;
		} else {
			// Invalid investment period
			revert();
		}

		// Check that YUPIES calculated greater than zero
		assert(amountOfYUPIE > 0);

		// Apply Bonuses
		if (amountOfWei >= highEtherBonusLimit) {
			amountOfYUPIE = amountOfYUPIE.mul(highEtherBonusValue).div(100);
		} else if (amountOfWei >= midEtherBonusLimit) {
			amountOfYUPIE = amountOfYUPIE.mul(midEtherBonusValue).div(100);
		} else if (amountOfWei >= lowEtherBonusLimit) {
			amountOfYUPIE = amountOfYUPIE.mul(lowEtherBonusValue).div(100);
		}
		if (block.timestamp >= absLowTimeBonusLimit) {
			amountOfYUPIE = amountOfYUPIE.mul(lowTimeBonusValue).div(100);
		} else if (block.timestamp >= absMidTimeBonusLimit) {
			amountOfYUPIE = amountOfYUPIE.mul(midTimeBonusValue).div(100);
		} else if (block.timestamp >= absHighTimeBonusLimit) {
			amountOfYUPIE = amountOfYUPIE.mul(highTimeBonusValue).div(100);
		}

		// Max sure it doesn&#39;t exceed remaining supply
		assert(amountOfYUPIE <= totalYUPIEAvailable);

		// Update total YUPIE balance
		totalYUPIESAllocated = totalYUPIESAllocated + amountOfYUPIE;

		// Update user YUPIE balance
		uint256 balanceSafe = balances[msg.sender].add(amountOfYUPIE);
		balances[msg.sender] = balanceSafe;

		// Update total WEI Invested
		totalWEIInvested = totalWEIInvested.add(amountOfWei);

		// Update total WEI Invested by account
		uint256 contributedSafe = WEIContributed[msg.sender].add(amountOfWei);
		WEIContributed[msg.sender] = contributedSafe;

		// CHECK VALUES
		assert(totalYUPIESAllocated <= totalSupply);
		assert(totalYUPIESAllocated > 0);
		assert(balanceSafe > 0);
		assert(totalWEIInvested > 0);
		assert(contributedSafe > 0);

		// CREATE EVENT FOR SENDER
		CreatedYUPIE(msg.sender, amountOfYUPIE);
	}
	
	
	// CHANGE PARAMETERS METHODS
	function transferEther(address addressToSendTo, uint256 value) {
		require(msg.sender == ownerAddress);
		addressToSendTo.transfer(value);
	}	
	function changeAllowInvestment(bool _allowInvestment) {
		require(msg.sender == ownerAddress);
		allowInvestment = _allowInvestment;
	}
	function changeSaleTimes(uint256 _saleStartTime, uint256 _saleEndTime) {
		require(msg.sender == ownerAddress);
		saleStartTime = _saleStartTime;
		saleEndTime	= _saleEndTime;
	}
	function changeEtherBonuses(uint256 _lowEtherBonusLimit, uint256 _lowEtherBonusValue, uint256 _midEtherBonusLimit, uint256 _midEtherBonusValue, uint256 _highEtherBonusLimit, uint256 _highEtherBonusValue) {
		require(msg.sender == ownerAddress);
		lowEtherBonusLimit = _lowEtherBonusLimit;
		lowEtherBonusValue = _lowEtherBonusValue;
		midEtherBonusLimit = _midEtherBonusLimit;
		midEtherBonusValue = _midEtherBonusValue;
		highEtherBonusLimit = _highEtherBonusLimit;
		highEtherBonusValue = _highEtherBonusValue;
	}
	function changeTimeBonuses(uint256 _highTimeBonusLimit, uint256 _highTimeBonusValue, uint256 _midTimeBonusLimit, uint256 _midTimeBonusValue, uint256 _lowTimeBonusLimit, uint256 _lowTimeBonusValue) {
		require(msg.sender == ownerAddress);
		highTimeBonusLimit = _highTimeBonusLimit;
		highTimeBonusValue = _highTimeBonusValue;
		midTimeBonusLimit = _midTimeBonusLimit;
		midTimeBonusValue = _midTimeBonusValue;
		lowTimeBonusLimit = _lowTimeBonusLimit;
		lowTimeBonusValue = _lowTimeBonusValue;
	}

}