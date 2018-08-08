pragma solidity ^0.4.23;

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
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
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
    require(newOwner != address(0));
    owner = newOwner;
  }

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function minimum( uint a, uint b) internal returns ( uint result) {
    if ( a <= b ) {
      result = a;
    }
    else {
      result = b;
    }
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract OZTToken is StandardToken, Ownable {

	/* Overriding some ERC20 variables */
	string public constant name      = "OZTToken";
	string public constant symbol    = "OZT";
	uint256 public constant decimals = 18;

	uint256 public constant MAX_NUM_OZT_TOKENS    =  730000000 * 10 ** decimals;

	// Freeze duration for Advisors accounts
	uint256 public constant START_ICO_TIMESTAMP   = 1526565600;  // ICO starts at 17.05.2018 @ 2PM UTC
	int public constant DEFROST_MONTH_IN_MINUTES = 43200; // month in minutes
	int public constant DEFROST_MONTHS = 3;

	/*
		modalit&#233;s de sorties des advisors investisseurs ou des earlybirds j’opte pour
		- un Freeze &#224; 6 mois puis au bout du 6&#232;me mois
		- possible de sortir du capital de 50% du montant investi
		- puis par la suite 5% tous les mois ce qui nous donnera une sortie effective au bout de 10 mois et au total &#231;a fera donc 16 mois
	*/

	uint public constant DEFROST_FACTOR = 20;

	// Fields that can be changed by functions
	address[] public vIcedBalances;
	mapping (address => uint256) public icedBalances_frosted;
    mapping (address => uint256) public icedBalances_defrosted;

	// Variable usefull for verifying that the assignedSupply matches that totalSupply
	uint256 public assignedSupply;
	//Boolean to allow or not the initial assignement of token (batch)
	bool public batchAssignStopped = false;
	bool public stopDefrost = false;

	uint oneTokenWeiPrice;
	address defroster;

	function OZTToken() {
		owner                	= msg.sender;
		assignedSupply = 0;

		// mint all tokens
        balances[msg.sender] = MAX_NUM_OZT_TOKENS;
        Transfer(address(0x0), msg.sender, MAX_NUM_OZT_TOKENS);
	}

	function setDefroster(address addr) onlyOwner {
		defroster = addr;
	}

 	modifier onlyDefrosterOrOwner() {
        require(msg.sender == defroster || msg.sender == owner);
        _;
    }

	/**
   * @dev Transfer tokens in batches (of adresses)
   * @param _vaddr address The address which you want to send tokens from
   * @param _vamounts address The address which you want to transfer to
   */
  function batchAssignTokens(address[] _vaddr, uint[] _vamounts, uint[] _vDefrostClass ) onlyOwner {

			require ( batchAssignStopped == false );
			require ( _vaddr.length == _vamounts.length && _vaddr.length == _vDefrostClass.length);
			//Looping into input arrays to assign target amount to each given address
			for (uint index=0; index<_vaddr.length; index++) {

				address toAddress = _vaddr[index];
				uint amount = SafeMath.mul(_vamounts[index], 10 ** decimals);
				uint defrostClass = _vDefrostClass[index]; // 0=ico investor, 1=reserveandteam/advisors

				if (  defrostClass == 0 ) {
					// investor account
					transfer(toAddress, amount);
					assignedSupply = SafeMath.add(assignedSupply, amount);
				}
				else if(defrostClass == 1){

					// Iced account. The balance is not affected here
                    vIcedBalances.push(toAddress);
                    icedBalances_frosted[toAddress] = amount;
					icedBalances_defrosted[toAddress] = 0;
					assignedSupply = SafeMath.add(assignedSupply, amount);
				}
			}
	}

	function getBlockTimestamp() constant returns (uint256){
		return now;
	}

	function getAssignedSupply() constant returns (uint256){
		return assignedSupply;
	}

	function elapsedMonthsFromICOStart() constant returns (int elapsed) {
		elapsed = (int(now-START_ICO_TIMESTAMP)/60)/DEFROST_MONTH_IN_MINUTES;
	}

	function getDefrostFactor()constant returns (uint){
		return DEFROST_FACTOR;
	}

	function lagDefrost()constant returns (int){
		return DEFROST_MONTHS;
	}

	function canDefrost() constant returns (bool){
		int numMonths = elapsedMonthsFromICOStart();
		return  numMonths > DEFROST_MONTHS &&
							uint(numMonths) <= SafeMath.add(uint(DEFROST_MONTHS),  DEFROST_FACTOR/2+1);
	}

	function defrostTokens(uint fromIdx, uint toIdx) onlyDefrosterOrOwner {

		require(now>START_ICO_TIMESTAMP);
		require(stopDefrost == false);
		require(fromIdx>=0 && toIdx<=vIcedBalances.length);
		if(fromIdx==0 && toIdx==0){
			fromIdx = 0;
			toIdx = vIcedBalances.length;
		}

		int monthsElapsedFromFirstDefrost = elapsedMonthsFromICOStart() - DEFROST_MONTHS;
		require(monthsElapsedFromFirstDefrost>0);
		uint monthsIndex = uint(monthsElapsedFromFirstDefrost);
		//require(monthsIndex<=DEFROST_FACTOR);
		require(canDefrost() == true);

		/*
			if monthsIndex == 1 => defrost 50%
			else if monthsIndex <= 10  defrost 5%
		*/

		// Looping into the iced accounts
        for (uint index = fromIdx; index < toIdx; index++) {

			address currentAddress = vIcedBalances[index];
            uint256 amountTotal = SafeMath.add(icedBalances_frosted[currentAddress], icedBalances_defrosted[currentAddress]);
            uint256 targetDeFrosted = 0;
			uint256 fivePercAmount = SafeMath.div(amountTotal, DEFROST_FACTOR);
			if(monthsIndex==1){
				targetDeFrosted = SafeMath.mul(fivePercAmount, 10);  //  10 times 5% = 50%
			}else{
				targetDeFrosted = SafeMath.mul(fivePercAmount, 10) + SafeMath.div(SafeMath.mul(monthsIndex-1, amountTotal), DEFROST_FACTOR);
			}
            uint256 amountToRelease = SafeMath.sub(targetDeFrosted, icedBalances_defrosted[currentAddress]);

		    if (amountToRelease > 0 && targetDeFrosted > 0) {
                icedBalances_frosted[currentAddress] = SafeMath.sub(icedBalances_frosted[currentAddress], amountToRelease);
                icedBalances_defrosted[currentAddress] = SafeMath.add(icedBalances_defrosted[currentAddress], amountToRelease);
				transfer(currentAddress, amountToRelease);
	        }
        }
	}

	function getStartIcoTimestamp() constant returns (uint) {
		return START_ICO_TIMESTAMP;
	}

	function stopBatchAssign() onlyOwner {
			require ( batchAssignStopped == false);
			batchAssignStopped = true;
	}

	function getAddressBalance(address addr) constant returns (uint256 balance)  {
			balance = balances[addr];
	}

	function getAddressAndBalance(address addr) constant returns (address _address, uint256 _amount)  {
			_address = addr;
			_amount = balances[addr];
	}

	function setStopDefrost() onlyOwner {
			stopDefrost = true;
	}

	function killContract() onlyOwner {
		selfdestruct(owner);
	}


}