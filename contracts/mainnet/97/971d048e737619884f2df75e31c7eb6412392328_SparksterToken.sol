pragma solidity 0.4.24;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract SparksterToken is StandardToken, Ownable{
	using SafeMath for uint256;
	struct Member {
		mapping(uint256 => uint256) weiBalance; // How much wei has this member contributed for this group?
	}

	struct Group {
		bool distributed; // Whether or not tokens in this group have been distributed.
		bool distributing; // This flag is set when we first enter the distribute function and is there to prevent race conditions, since distribution might take a long time.
		bool unlocked; // Whether or not tokens in this group have been unlocked.
		mapping(address => bool) exists; // If exists[address] is true, this address has made a purchase on this group before.
		string name;
		uint256 ratio; // 1 eth:ratio tokens. This amount represents the decimal amount. ratio*10**decimal = ratio sparks.
		uint256 startTime; // Epoch of crowdsale start time.
		uint256 phase1endTime; // Epoch of phase1 end time.
		uint256 phase2endTime; // Epoch of phase2 end time.
		uint256 deadline; // No contributions allowed after this epoch.
		uint256 max2; // cap of phase2
		uint256 max3; // Total ether this group can collect in phase 3.
		uint256 weiTotal; // How much ether has this group collected?
		uint256 cap; // The hard ether cap.
		uint256 nextDistributionIndex; // The next index to start distributing at.
		address[] addresses; // List of addresses that have made a purchase on this group.
	}

	address oracleAddress;
	bool public transferLock = true; // A Global transfer lock. Set to lock down all tokens from all groups.
	bool public allowedToBuyBack = false;
	bool public allowedToPurchase = false;
	string public name;									 // name for display
	string public symbol;								 //An identifier
	uint8 public decimals;							//How many decimals to show.
	uint256 public penalty;
	uint256 public maxGasPrice; // The maximum allowed gas for the purchase function.
	uint256 internal nextGroupNumber;
	uint256 public sellPrice; // sellPrice wei:1 spark token; we won&#39;t allow to sell back parts of a token.
	mapping(address => Member) internal members;
	mapping(uint256 => Group) internal groups;
	uint256 public openGroupNumber;
	event WantsToPurchase(address walletAddress, uint256 weiAmount, uint256 groupNumber, bool inPhase1);
	event PurchasedCallbackOnAccept(uint256 groupNumber, address[] addresses);
	event WantsToDistribute(uint256 groupNumber);
	event NearingHardCap(uint256 groupNumber, uint256 remainder);
	event ReachedHardCap(uint256 groupNumber);
	event DistributeDone(uint256 groupNumber);
	event DistributedBatch(uint256 groupNumber, uint256 howMany);
	event AirdroppedBatch(address[] addresses);
	event RefundedBatch(address[] addresses);
	event AddToGroup(address walletAddress, uint256 groupNumber);
	event ChangedTransferLock(bool transferLock);
	event ChangedAllowedToPurchase(bool allowedToPurchase);
	event ChangedAllowedToBuyBack(bool allowedToBuyBack);
	event SetSellPrice(uint256 sellPrice);
	
	modifier onlyOwnerOrOracle() {
		require(msg.sender == owner || msg.sender == oracleAddress);
		_;
	}
	
	// Fix for the ERC20 short address attack http://vessenes.com/the-erc20-short-address-attack-explained/
	modifier onlyPayloadSize(uint size) {	 
		require(msg.data.length == size + 4);
		_;
	}

	modifier canTransfer() {
		if (msg.sender != owner) {
			require(!transferLock);
		}
		_;
	}

	modifier canPurchase() {
		require(allowedToPurchase);
		_;
	}

	modifier canSell() {
		require(allowedToBuyBack);
		_;
	}

	function() public payable {
		purchase();
	}

	constructor() public {
		name = "Sparkster";									// Set the name for display purposes
		decimals = 18;					 // Amount of decimals for display purposes
		symbol = "SPRK";							// Set the symbol for display purposes
		setMaximumGasPrice(40);
		mintTokens(435000000);
	}
	
	function setOracleAddress(address newAddress) public onlyOwner returns(bool success) {
		oracleAddress = newAddress;
		return true;
	}

	function removeOracleAddress() public onlyOwner {
		oracleAddress = address(0);
	}

	function setMaximumGasPrice(uint256 gweiPrice) public onlyOwner returns(bool success) {
		maxGasPrice = gweiPrice.mul(10**9); // Convert the gwei value to wei.
		return true;
	}

	function mintTokens(uint256 amount) public onlyOwner {
		// Here, we&#39;ll consider amount to be the full token amount, so we have to get its decimal value.
		uint256 decimalAmount = amount.mul(uint(10)**decimals);
		totalSupply_ = totalSupply_.add(decimalAmount);
		balances[msg.sender] = balances[msg.sender].add(decimalAmount);
		emit Transfer(address(0), msg.sender, decimalAmount); // Per erc20 standards-compliance.
	}

	function purchase() public canPurchase payable returns(bool success) {
		require(msg.sender != address(0)); // Don&#39;t allow the 0 address.
		Member storage memberRecord = members[msg.sender];
		Group storage openGroup = groups[openGroupNumber];
		require(openGroup.ratio > 0); // Group must be initialized.
		uint256 currentTimestamp = block.timestamp;
		require(currentTimestamp >= openGroup.startTime && currentTimestamp <= openGroup.deadline);																 //the timestamp must be greater than or equal to the start time and less than or equal to the deadline time
		require(!openGroup.distributing && !openGroup.distributed); // Don&#39;t allow to purchase if we&#39;re in the middle of distributing this group; Don&#39;t let someone buy tokens on the current group if that group is already distributed.
		require(tx.gasprice <= maxGasPrice); // Restrict maximum gas this transaction is allowed to consume.
		uint256 weiAmount = msg.value;																		// The amount purchased by the current member
		require(weiAmount >= 0.1 ether);
		uint256 weiTotal = openGroup.weiTotal.add(weiAmount); // Calculate total contribution of all members in this group.
		require(weiTotal <= openGroup.cap);														// Check to see if accepting these funds will put us above the hard ether cap.
		uint256 userWeiTotal = memberRecord.weiBalance[openGroupNumber].add(weiAmount);	// Calculate the total amount purchased by the current member
		if (!openGroup.exists[msg.sender]) { // Has this person not purchased on this group before?
			openGroup.addresses.push(msg.sender);
			openGroup.exists[msg.sender] = true;
		}
		if(currentTimestamp <= openGroup.phase1endTime){																			 // whether the current timestamp is in the first phase
			emit WantsToPurchase(msg.sender, weiAmount, openGroupNumber, true);
			return true;
		} else if (currentTimestamp <= openGroup.phase2endTime) { // Are we in phase 2?
			require(userWeiTotal <= openGroup.max2); // Allow to contribute no more than max2 in phase 2.
			emit WantsToPurchase(msg.sender, weiAmount, openGroupNumber, false);
			return true;
		} else { // We&#39;ve passed both phases 1 and 2.
			require(userWeiTotal <= openGroup.max3); // Don&#39;t allow to contribute more than max3 in phase 3.
			emit WantsToPurchase(msg.sender, weiAmount, openGroupNumber, false);
			return true;
		}
	}
	
	function purchaseCallbackOnAccept(uint256 groupNumber, address[] addresses, uint256[] weiAmounts) public onlyOwnerOrOracle returns(bool success) {
		uint256 n = addresses.length;
		require(n == weiAmounts.length, "Array lengths mismatch");
		Group storage theGroup = groups[groupNumber];
		uint256 weiTotal = theGroup.weiTotal;
		for (uint256 i = 0; i < n; i++) {
			Member storage memberRecord = members[addresses[i]];
			uint256 weiAmount = weiAmounts[i];
			weiTotal = weiTotal.add(weiAmount);								 // Calculate the total amount purchased by all members in this group.
			memberRecord.weiBalance[groupNumber] = memberRecord.weiBalance[groupNumber].add(weiAmount);														 // Record the total amount purchased by the current member
		}
		theGroup.weiTotal = weiTotal;
		if (getHowMuchUntilHardCap_(groupNumber) <= 100 ether) {
			emit NearingHardCap(groupNumber, getHowMuchUntilHardCap_(groupNumber));
			if (weiTotal >= theGroup.cap) {
				emit ReachedHardCap(groupNumber);
			}
		}
		emit PurchasedCallbackOnAccept(groupNumber, addresses);
		return true;
	}

	function insertAndApprove(uint256 groupNumber, address[] addresses, uint256[] weiAmounts) public onlyOwnerOrOracle returns(bool success) {
		uint256 n = addresses.length;
		require(n == weiAmounts.length, "Array lengtsh mismatch");
		Group storage theGroup = groups[groupNumber];
		for (uint256 i = 0; i < n; i++) {
			address theAddress = addresses[i];
			if (!theGroup.exists[theAddress]) {
				theGroup.addresses.push(theAddress);
				theGroup.exists[theAddress] = true;
			}
		}
		return purchaseCallbackOnAccept(groupNumber, addresses, weiAmounts);
	}

	function callbackInsertApproveAndDistribute(uint256 groupNumber, address[] addresses, uint256[] weiAmounts) public onlyOwnerOrOracle returns(bool success) {
		uint256 n = addresses.length;
		require(n == weiAmounts.length, "Array lengths mismatch");
		Group storage theGroup = groups[groupNumber];
		if (!theGroup.distributing) {
			theGroup.distributing = true;
		}
		uint256 newOwnerSupply = balances[owner];
		for (uint256 i = 0; i < n; i++) {
			address theAddress = addresses[i];
			Member storage memberRecord = members[theAddress];
			uint256 weiAmount = weiAmounts[i];
			memberRecord.weiBalance[groupNumber] = memberRecord.weiBalance[groupNumber].add(weiAmount);														 // Record the total amount purchased by the current member
			uint256 additionalBalance = weiAmount.mul(theGroup.ratio); // Don&#39;t give cumulative tokens; one address can be distributed multiple times.
			if (additionalBalance > 0) { // No need to waste ticks if they have no tokens to distribute
				balances[theAddress] = balances[theAddress].add(additionalBalance);
				newOwnerSupply = newOwnerSupply.sub(additionalBalance); // Update the available number of tokens.
				emit Transfer(owner, theAddress, additionalBalance); // Notify exchanges of the distribution.
			}
		}
		balances[owner] = newOwnerSupply;
		emit PurchasedCallbackOnAccept(groupNumber, addresses);
		return true;
	}

	function refund(address[] addresses, uint256[] weiAmounts) public onlyOwnerOrOracle returns(bool success) {
		uint256 n = addresses.length;
		require (n == weiAmounts.length, "Array lengths mismatch");
		uint256 thePenalty = penalty;
		for(uint256 i = 0; i < n; i++) {
			uint256 weiAmount = weiAmounts[i];
			address theAddress = addresses[i];
			if (thePenalty <= weiAmount) {
				weiAmount = weiAmount.sub(thePenalty);
				require(address(this).balance >= weiAmount);
				theAddress.transfer(weiAmount);
			}
		}
		emit RefundedBatch(addresses);
		return true;
	}

	function signalDoneDistributing(uint256 groupNumber) public onlyOwnerOrOracle {
		Group storage theGroup = groups[groupNumber];
		theGroup.distributed = true;
		theGroup.distributing = false;
		emit DistributeDone(groupNumber);
	}
	
	function drain() public onlyOwner {
		owner.transfer(address(this).balance);
	}
	
	function setPenalty(uint256 newPenalty) public onlyOwner returns(bool success) {
		penalty = newPenalty;
		return true;
	}
	
	function buyback(uint256 amount) public canSell { // Can&#39;t sell unless owner has allowed it.
		uint256 decimalAmount = amount.mul(uint(10)**decimals); // convert the full token value to the smallest unit possible.
		require(balances[msg.sender].sub(decimalAmount) >= getLockedTokens_(msg.sender)); // Don&#39;t allow to sell locked tokens.
		balances[msg.sender] = balances[msg.sender].sub(decimalAmount); // Do this before transferring to avoid re-entrance attacks; will throw if result < 0.
		// Amount is considered to be how many full tokens the user wants to sell.
		uint256 totalCost = amount.mul(sellPrice); // sellPrice is the per-full-token value.
		require(address(this).balance >= totalCost); // The contract must have enough funds to cover the selling.
		balances[owner] = balances[owner].add(decimalAmount); // Put these tokens back into the available pile.
		msg.sender.transfer(totalCost); // Pay the seller for their tokens.
		emit Transfer(msg.sender, owner, decimalAmount); // Notify exchanges of the sell.
	}

	function fundContract() public onlyOwnerOrOracle payable { // For the owner to put funds into the contract.
	}

	function setSellPrice(uint256 thePrice) public onlyOwner {
		sellPrice = thePrice;
	}
	
	function setAllowedToBuyBack(bool value) public onlyOwner {
		allowedToBuyBack = value;
		emit ChangedAllowedToBuyBack(value);
	}

	function setAllowedToPurchase(bool value) public onlyOwner {
		allowedToPurchase = value;
		emit ChangedAllowedToPurchase(value);
	}
	
	function createGroup(string groupName, uint256 startEpoch, uint256 phase1endEpoch, uint256 phase2endEpoch, uint256 deadlineEpoch, uint256 phase2weiCap, uint256 phase3weiCap, uint256 hardWeiCap, uint256 ratio) public onlyOwner returns (bool success, uint256 createdGroupNumber) {
		createdGroupNumber = nextGroupNumber;
		Group storage theGroup = groups[createdGroupNumber];
		theGroup.name = groupName;
		theGroup.startTime = startEpoch;
		theGroup.phase1endTime = phase1endEpoch;
		theGroup.phase2endTime = phase2endEpoch;
		theGroup.deadline = deadlineEpoch;
		theGroup.max2 = phase2weiCap;
		theGroup.max3 = phase3weiCap;
		theGroup.cap = hardWeiCap;
		theGroup.ratio = ratio;
		nextGroupNumber++;
		success = true;
	}

	function getGroup(uint256 groupNumber) public view returns(string groupName, bool distributed, bool unlocked, uint256 phase2cap, uint256 phase3cap, uint256 cap, uint256 ratio, uint256 startTime, uint256 phase1endTime, uint256 phase2endTime, uint256 deadline, uint256 weiTotal) {
		require(groupNumber < nextGroupNumber);
		Group storage theGroup = groups[groupNumber];
		groupName = theGroup.name;
		distributed = theGroup.distributed;
		unlocked = theGroup.unlocked;
		phase2cap = theGroup.max2;
		phase3cap = theGroup.max3;
		cap = theGroup.cap;
		ratio = theGroup.ratio;
		startTime = theGroup.startTime;
		phase1endTime = theGroup.phase1endTime;
		phase2endTime = theGroup.phase2endTime;
		deadline = theGroup.deadline;
		weiTotal = theGroup.weiTotal;
	}
	
	function getHowMuchUntilHardCap_(uint256 groupNumber) internal view returns(uint256 remainder) {
		Group storage theGroup = groups[groupNumber];
		if (theGroup.weiTotal > theGroup.cap) { // calling .sub in this situation will throw.
			return 0;
		}
		return theGroup.cap.sub(theGroup.weiTotal);
	}
	
	function getHowMuchUntilHardCap() public view returns(uint256 remainder) {
		return getHowMuchUntilHardCap_(openGroupNumber);
	}

	function addMemberToGroup(address walletAddress, uint256 groupNumber) public onlyOwner returns(bool success) {
		emit AddToGroup(walletAddress, groupNumber);
		return true;
	}
	
	function instructOracleToDistribute(uint256 groupNumber) public onlyOwner {
		Group storage theGroup = groups[groupNumber];
		require(groupNumber < nextGroupNumber && !theGroup.distributed); // can&#39;t have already distributed
		emit WantsToDistribute(groupNumber);
	}
	
	function distributeCallback(uint256 groupNumber, uint256 howMany) public onlyOwnerOrOracle returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		require(!theGroup.distributed);
		if (!theGroup.distributing) {
			theGroup.distributing = true;
		}
		uint256 n = theGroup.addresses.length;
		uint256 nextDistributionIndex = theGroup.nextDistributionIndex;
		uint256 exclusiveEndIndex = nextDistributionIndex + howMany;
		if (exclusiveEndIndex > n) {
			exclusiveEndIndex = n;
		}
		uint256 newOwnerSupply = balances[owner];
		for (uint256 i = nextDistributionIndex; i < exclusiveEndIndex; i++) {
			address theAddress = theGroup.addresses[i];
			uint256 balance = getUndistributedBalanceOf_(theAddress, groupNumber);
			if (balance > 0) { // No need to waste ticks if they have no tokens to distribute
				balances[theAddress] = balances[theAddress].add(balance);
				newOwnerSupply = newOwnerSupply.sub(balance); // Update the available number of tokens.
				emit Transfer(owner, theAddress, balance); // Notify exchanges of the distribution.
			}
		}
		balances[owner] = newOwnerSupply;
		if (exclusiveEndIndex < n) {
			emit DistributedBatch(groupNumber, howMany);
		} else { // We&#39;ve finished distributing people
			signalDoneDistributing(groupNumber);
		}
		theGroup.nextDistributionIndex = exclusiveEndIndex; // Usually not necessary if we&#39;ve finished distribution, but if we don&#39;t update this, getHowManyLeftToDistribute will never show 0.
		return true;
	}

	function getHowManyLeftToDistribute(uint256 groupNumber) public view returns(uint256 remainder) {
		Group storage theGroup = groups[groupNumber];
		return theGroup.addresses.length - theGroup.nextDistributionIndex;
	}

	function changeGroupInfo(uint256 groupNumber, uint256 startEpoch, uint256 phase1endEpoch, uint256 phase2endEpoch, uint256 deadlineEpoch, uint256 phase2weiCap, uint256 phase3weiCap, uint256 hardWeiCap, uint256 ratio) public onlyOwner returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		if (startEpoch > 0) {
			theGroup.startTime = startEpoch;
		}
		if (phase1endEpoch > 0) {
			theGroup.phase1endTime = phase1endEpoch;
		}
		if (phase2endEpoch > 0) {
			theGroup.phase2endTime = phase2endEpoch;
		}
		if (deadlineEpoch > 0) {
			theGroup.deadline = deadlineEpoch;
		}
		if (phase2weiCap > 0) {
			theGroup.max2 = phase2weiCap;
		}
		if (phase3weiCap > 0) {
			theGroup.max3 = phase3weiCap;
		}
		if (hardWeiCap > 0) {
			theGroup.cap = hardWeiCap;
		}
		if (ratio > 0) {
			theGroup.ratio = ratio;
		}
		return true;
	}

	function relockGroup(uint256 groupNumber) public onlyOwner returns(bool success) {
		groups[groupNumber].unlocked = true;
		return true;
	}

	function resetGroupInfo(uint256 groupNumber) public onlyOwner returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		theGroup.startTime = 0;
		theGroup.phase1endTime = 0;
		theGroup.phase2endTime = 0;
		theGroup.deadline = 0;
		theGroup.max2 = 0;
		theGroup.max3 = 0;
		theGroup.cap = 0;
		theGroup.ratio = 0;
		return true;
	}

	function unlock(uint256 groupNumber) public onlyOwner returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		require(theGroup.distributed); // Distribution must have occurred first.
		theGroup.unlocked = true;
		return true;
	}
	
	function setGlobalLock(bool value) public onlyOwner {
		transferLock = value;
		emit ChangedTransferLock(transferLock);
	}
	
	function burn(uint256 amount) public onlyOwner {
		// Burns tokens from the owner&#39;s supply and doesn&#39;t touch allocated tokens.
		// Decrease totalSupply and leftOver by the amount to burn so we can decrease the circulation.
		balances[msg.sender] = balances[msg.sender].sub(amount); // Will throw if result < 0
		totalSupply_ = totalSupply_.sub(amount); // Will throw if result < 0
		emit Transfer(msg.sender, address(0), amount);
	}
	
	function splitTokensBeforeDistribution(uint256 splitFactor) public onlyOwner returns (bool success) {
		// SplitFactor is the multiplier per decimal of spark. splitFactor * 10**decimals = splitFactor sparks
		uint256 ownerBalance = balances[msg.sender];
		uint256 multiplier = ownerBalance.mul(splitFactor);
		uint256 increaseSupplyBy = multiplier.sub(ownerBalance); // We need to mint owner*splitFactor - owner additional tokens.
		balances[msg.sender] = multiplier;
		totalSupply_ = totalSupply_.mul(splitFactor);
		emit Transfer(address(0), msg.sender, increaseSupplyBy); // Notify exchange that we&#39;ve minted tokens.
		// Next, increase group ratios by splitFactor, so users will receive ratio * splitFactor tokens per ether.
		uint256 n = nextGroupNumber;
		require(n > 0); // Must have at least one group.
		for (uint256 i = 0; i < n; i++) {
			Group storage currentGroup = groups[i];
			currentGroup.ratio = currentGroup.ratio.mul(splitFactor);
		}
		return true;
	}

	function reverseSplitTokensBeforeDistribution(uint256 splitFactor) public onlyOwner returns (bool success) {
		// SplitFactor is the multiplier per decimal of spark. splitFactor * 10**decimals = splitFactor sparks
		uint256 ownerBalance = balances[msg.sender];
		uint256 divier = ownerBalance.div(splitFactor);
		uint256 decreaseSupplyBy = ownerBalance.sub(divier);
		// We don&#39;t use burnTokens here since the amount to subtract might be more than what the owner currently holds in their unallocated supply which will cause the function to throw.
		totalSupply_ = totalSupply_.div(splitFactor);
		balances[msg.sender] = divier;
		// Notify the exchanges of how many tokens were burned.
		emit Transfer(msg.sender, address(0), decreaseSupplyBy);
		// Next, decrease group ratios by splitFactor, so users will receive ratio / splitFactor tokens per ether.
		uint256 n = nextGroupNumber;
		require(n > 0); // Must have at least one group. Groups are 0-indexed.
		for (uint256 i = 0; i < n; i++) {
			Group storage currentGroup = groups[i];
			currentGroup.ratio = currentGroup.ratio.div(splitFactor);
		}
		return true;
	}

	function airdrop( address[] addresses, uint256[] tokenDecimalAmounts) public onlyOwnerOrOracle returns (bool success) {
		uint256 n = addresses.length;
		require(n == tokenDecimalAmounts.length, "Array lengths mismatch");
		uint256 newOwnerBalance = balances[owner];
		for (uint256 i = 0; i < n; i++) {
			address theAddress = addresses[i];
			uint256 airdropAmount = tokenDecimalAmounts[i];
			if (airdropAmount > 0) {
				uint256 currentBalance = balances[theAddress];
				balances[theAddress] = currentBalance.add(airdropAmount);
				newOwnerBalance = newOwnerBalance.sub(airdropAmount);
				emit Transfer(owner, theAddress, airdropAmount);
			}
		}
		balances[owner] = newOwnerBalance;
		emit AirdroppedBatch(addresses);
		return true;
	}

	function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) canTransfer returns (bool success) {		
		// If the transferrer has purchased tokens, they must be unlocked before they can be used.
		if (msg.sender != owner) { // Owner can transfer anything to anyone.
			require(balances[msg.sender].sub(_value) >= getLockedTokens_(msg.sender));
		}
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) canTransfer returns (bool success) {
		// If the transferrer has purchased tokens, they must be unlocked before they can be used.
		if (msg.sender != owner) { // Owner not affected by locked tokens
			require(balances[_from].sub(_value) >= getLockedTokens_(_from));
		}
		return super.transferFrom(_from, _to, _value);
	}

	function setOpenGroup(uint256 groupNumber) public onlyOwner returns (bool success) {
		require(groupNumber < nextGroupNumber);
		openGroupNumber = groupNumber;
		return true;
	}

	function getLockedTokensInGroup_(address walletAddress, uint256 groupNumber) internal view returns (uint256 balance) {
		Member storage theMember = members[walletAddress];
		if (groups[groupNumber].unlocked) {
			return 0;
		}
		return theMember.weiBalance[groupNumber].mul(groups[groupNumber].ratio);
	}

	function getLockedTokens_(address walletAddress) internal view returns(uint256 balance) {
		uint256 n = nextGroupNumber;
		for (uint256 i = 0; i < n; i++) {
			balance = balance.add(getLockedTokensInGroup_(walletAddress, i));
		}
		return balance;
	}

	function getLockedTokens(address walletAddress) public view returns(uint256 balance) {
		return getLockedTokens_(walletAddress);
	}

	function getUndistributedBalanceOf_(address walletAddress, uint256 groupNumber) internal view returns (uint256 balance) {
		Member storage theMember = members[walletAddress];
		Group storage theGroup = groups[groupNumber];
		if (theGroup.distributed) {
			return 0;
		}
		return theMember.weiBalance[groupNumber].mul(theGroup.ratio);
	}

	function getUndistributedBalanceOf(address walletAddress, uint256 groupNumber) public view returns (uint256 balance) {
		return getUndistributedBalanceOf_(walletAddress, groupNumber);
	}

	function checkMyUndistributedBalance(uint256 groupNumber) public view returns (uint256 balance) {
		return getUndistributedBalanceOf_(msg.sender, groupNumber);
	}

	function transferRecovery(address _from, address _to, uint256 _value) public onlyOwner returns (bool success) {
		// Will be used if someone sends tokens to an incorrect address by accident. This way, we have the ability to recover the tokens. For example, sometimes there&#39;s a problem of lost tokens if someone sends tokens to a contract address that can&#39;t utilize the tokens.
		allowed[_from][msg.sender] = allowed[_from][msg.sender].add(_value); // Authorize the owner to spend on someone&#39;s behalf.
		return transferFrom(_from, _to, _value);
	}
}