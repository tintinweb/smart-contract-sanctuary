pragma solidity ^0.4.13;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Crowdsale is Ownable {
  using SafeMath for uint256;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  WhitelistedGateway public gateway;
  PendingContributions public pending;

	bool closedManually = false;
	bool acceptWithoutWhitelist = true;
  uint256 minContrib;

	function setPending(bool newValue) public onlyOwner {
		acceptWithoutWhitelist = newValue;
	}

	function setClosedManually(bool newValue) public onlyOwner {
		closedManually = newValue;
	}


  function Crowdsale(uint256 _startTime, uint256 _endTime, address _vault, Whitelist _whitelist, uint256 _minContrib) public {
    // require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_vault != address(0));

    startTime = _startTime;
    endTime = _endTime;
    minContrib = _minContrib;
    gateway = new WhitelistedGateway(_whitelist, _vault);
	pending = new PendingContributions(gateway);
	// allow the pending container to fund the gateway
	gateway.addOwner(pending);
  }

  // fallback function can be used to buy tokens
  function () external payable {
    require(validPurchase());
    forwardFunds();  
  }

  // send ether either to the Gateway or to the PendingContributions
  function forwardFunds() internal {
	if(gateway.isWhitelisted(msg.sender)) {
		gateway.fund.value(msg.value)(msg.sender);
		return;
	} 
	pending.fund.value(msg.value)(msg.sender);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool sufficientPurchase = msg.value >= minContrib;
    bool whitelisted = gateway.isWhitelisted(msg.sender);
    return !closedManually && withinPeriod && sufficientPurchase && (acceptWithoutWhitelist || whitelisted);
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

}

contract PendingContributions is Ownable {
	using SafeMath for uint256;

	mapping(address=>uint256) public contributions;
	WhitelistedGateway public gateway;

	event PendingContributionReceived(address contributor, uint256 value, uint256 timestamp);
	event PendingContributionAccepted(address contributor, uint256 value, uint256 timestamp);
	event PendingContributionWithdrawn(address contributor, uint256 value, uint256 timestamp);

	function PendingContributions(WhitelistedGateway _gateway) public {
		gateway = _gateway;
	}

	modifier onlyWhitelisted(address contributor) {
		require(gateway.isWhitelisted(contributor));
		_;
	}

	function fund(address contributor) payable public onlyOwner {
		contributions[contributor] += msg.value;
		PendingContributionReceived(contributor, msg.value, now);
	}

	function withdraw() public {
		uint256 toTransfer = contributions[msg.sender];
		require(toTransfer > 0);
		contributions[msg.sender] = 0;
		msg.sender.transfer(toTransfer);
		PendingContributionWithdrawn(msg.sender, toTransfer, now);
	}

	function retry(address contributor) public onlyWhitelisted(contributor) {
		uint256 toTransfer = contributions[contributor];
		require(toTransfer > 0);
		gateway.fund.value(toTransfer)(contributor);
		contributions[contributor] = 0;
		PendingContributionAccepted(contributor, toTransfer, now);
	}
}

contract Whitelist is Ownable {
	using SafeMath for uint256;

	mapping(address=>bool) public whitelist;
	
	event Authorized(address candidate, uint timestamp);
	event Revoked(address candidate, uint timestamp);

	function authorize(address candidate) public onlyOwner {
	    whitelist[candidate] = true;
	    Authorized(candidate, now);
	}
	
	// also if not in the list..
	function revoke(address candidate) public onlyOwner {
	    whitelist[candidate] = false;
	    Revoked(candidate, now);
	}
	
	function authorizeMany(address[50] candidates) public onlyOwner {
	    for(uint i = 0; i < candidates.length; i++) {
	        authorize(candidates[i]);
	    }
	}

	function isWhitelisted(address candidate) public view returns(bool) {
		return whitelist[candidate];
	}
}

contract WhitelistedGateway {
	using SafeMath for uint256;

	mapping(address=>bool) public owners;
	mapping(address=>uint) public contributions;
	address public vault;
	Whitelist public whitelist;

	event NewContribution(address contributor, uint256 amount, uint256 timestamp);

	modifier onlyOwners() {
		require(owners[msg.sender]);
		_;
	}

	function addOwner(address newOwner) public onlyOwners {
		owners[newOwner] = true;
	}

	function WhitelistedGateway(Whitelist _whitelist, address _vault) public {
		whitelist = _whitelist;
		vault = _vault;
		owners[msg.sender] = true;
	}

	function isWhitelisted(address candidate) public view returns(bool) {
		return whitelist.isWhitelisted(candidate);
	}

	function fund(address contributor) public payable onlyOwners {
		contributions[contributor] += msg.value;
		vault.transfer(msg.value);
		NewContribution(contributor, msg.value, now);
	}
}