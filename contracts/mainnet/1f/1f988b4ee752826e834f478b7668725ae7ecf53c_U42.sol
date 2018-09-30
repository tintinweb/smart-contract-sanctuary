// Implementation of the U42 Token Specification -- see "U42 Token Specification.md"
//
// Standard ERC-20 methods and the SafeMath library are adapated from OpenZeppelin&#39;s standard contract types
// as at https://github.com/OpenZeppelin/openzeppelin-solidity/commit/5daaf60d11ee2075260d0f3adfb22b1c536db983
// note that uint256 is used explicitly in place of uint

pragma solidity ^0.4.24;

//safemath extensions added to uint256
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

contract U42 {
	//use OZ SafeMath to avoid uint256 overflows
	using SafeMath for uint256;

	string public constant name = "U42";
	string public constant symbol = "U42";
	uint8 public constant decimals = 18;
	uint256 public constant initialSupply = 525000000 * (10 ** uint256(decimals));
	uint256 internal totalSupply_ = initialSupply;
	address public contractOwner;

	//token balances
	mapping(address => uint256) balances;

	//for each balance address, map allowed addresses to amount allowed
	mapping (address => mapping (address => uint256)) internal allowed;

	//each service is represented by a Service struct 
	struct Service {
		address applicationAddress;
		uint32 serviceId;
		bool isSimple;
		string serviceDescription;
		uint256 tokensPerCredit;
		uint256 maxCreditsPerProvision;
		address updateAddress;
		address receiptAddress;
		bool isRemoved;
		uint256 provisionHead;
	}

	struct Provision {
		uint256 tokensPerCredit;
		uint256 creditsRemaining;
		uint256 applicationReference;
		address userAddress;
		uint256 creditsProvisioned;
	}

	//mapping of application addresses to service structs
	mapping (address => mapping (uint32 => Service)) services;

	//mapping of application addresses to service structs to provisions
	mapping (address => mapping (uint32 => mapping (uint256 => Provision))) provisions;

	//mapping of application addresses to lists of services
	mapping (address => uint32[]) servicesLists;

	//mapping of application addresses to lists of removed services
	mapping (address => uint32[]) servicesRemovedLists;

	//methods emit the following events
	event Transfer (
		address indexed from, 
		address indexed to, 
		uint256 value );

	event TokensBurned (
		address indexed burner, 
		uint256 value );

	event Approval (
		address indexed owner,
		address indexed spender,
		uint256 value );

	event NewService (
		address indexed applicationAddress,
		uint32 serviceId );

	event ServiceChanged (
		address indexed applicationAddress,
		uint32 serviceId );

	event ServiceRemoved (
		address indexed applicationAddress,
		uint32 serviceId );

	event CompleteSimpleProvision (
		address indexed applicationAddress,
		uint32 indexed serviceId,
		address indexed userAddress,
		uint256 multiple,
		uint256 applicationReference );

	event ReferenceConfirmed (
		address indexed applicationAddress,
		uint256 indexed applicationReference, 
		address indexed confirmedBy, 
		uint256 confirmerTokensMinimum );

	event StartProvision (
	    address indexed applicationAddress, 
	    uint32 indexed serviceId, 
	    address indexed userAddress,
	    uint256 provisionId,
	    uint256 serviceCredits,
	    uint256 tokensPerCredit, 
	    uint256 applicationReference );

	event UpdateProvision (
	    address indexed applicationAddress,
	    uint32 indexed serviceId,
	    uint256 indexed provisionId,
	    uint256 creditsRemaining );

	event CompleteProvision (
	    address indexed applicationAddress,
	    uint32 indexed serviceId,
	    uint256 indexed provisionId,
	    uint256 creditsOutstanding );

	event SignalProvisionRefund (
	    address indexed applicationAddress,
	    uint32 indexed serviceId,
	    uint256 indexed provisionId,
	    uint256 tokenValue );

	event TransferBecauseOf (
		address indexed applicationAddress,
	    uint32 indexed serviceId,
	    uint256 indexed provisionId,
	    address from,
	    address to,
	    uint256 value );

	event TransferBecauseOfAggregate (
		address indexed applicationAddress,
	    uint32 indexed serviceId,
	    uint256[] provisionIds,
	    uint256[] tokenAmounts,
	    address from,
	    address to,
	    uint256 value );


	constructor() public {
		//contract creator holds all tokens at creation
		balances[msg.sender] = totalSupply_;

		//record contract owner for later reference (e.g. in ownerBurn)
		contractOwner=msg.sender;

		//indicate all tokens were sent to contract address
		emit Transfer(address(0), msg.sender, totalSupply_);
	}

	function listSimpleService ( 
			uint32 _serviceId, 
			string _serviceDescription,
			uint256 _tokensRequired,
			address _updateAddress,
			address _receiptAddress	) 
		public returns (
			bool success ) {

		//check service id is not 0
		require(_serviceId != 0);

		//check service doesn&#39;t already exist for this application id
		require(services[msg.sender][_serviceId].applicationAddress == 0);

		//check cost of the service is >0 
		require(_tokensRequired != 0);

		//check receiptAddress is not address(0)
		require(_receiptAddress != address(0));

		//update address should be address(0) or a non-sender address
		require(_updateAddress != msg.sender);

		//add service to services mapping
		services[msg.sender][_serviceId] = Service(
				msg.sender,
				_serviceId,
				true,
				_serviceDescription,
				_tokensRequired,
				1,
				_updateAddress,
				_receiptAddress,
				false,
				0
			);

		//add service to servicesLists for application
		servicesLists[msg.sender].push(_serviceId);

		//emit NewService
		emit NewService(msg.sender, _serviceId);

		return true;
	}

	function listService ( 
			uint32 _serviceId, 
			string _serviceDescription,
			uint256 _tokensPerCredit,
			uint256 _maxCreditsPerProvision,
			address _updateAddress,
			address _receiptAddress	) 
		public returns (
			bool success ) {

		//check service id is not 0
		require(_serviceId != 0);

		//check service doesn&#39;t already exist for this application id
		require(services[msg.sender][_serviceId].applicationAddress == 0);

		//check cost of the service is >0 
		require(_tokensPerCredit != 0);

		//check receiptAddress is not address(0)
		require(_receiptAddress != address(0));

		//update address should be address(0) or a non-sender address
		require(_updateAddress != msg.sender);

		//add service to services mapping
		services[msg.sender][_serviceId] = Service(
				msg.sender,
				_serviceId,
				false,
				_serviceDescription,
				_tokensPerCredit,
				_maxCreditsPerProvision,
				_updateAddress,
				_receiptAddress,
				false,
				0
			);

		//add service to servicesLists for application
		servicesLists[msg.sender].push(_serviceId);

		//emit NewService
		emit NewService(msg.sender, _serviceId);

		return true;
	}

	function getServicesForApplication ( 
			address _applicationAddress ) 
		public view returns (
			uint32[] serviceIds ) {

		return servicesLists[_applicationAddress];
	}

	function getRemovedServicesForApplication (
			address _applicationAddress ) 
		public view returns (
			uint32[] serviceIds ) {

		return servicesRemovedLists[_applicationAddress];
	}

	function isServiceRemoved (
			address _applicationAddress,
			uint32 _serviceId )
		public view returns (
			bool ) {

		//returns true if service has been removed
		return services[_applicationAddress][_serviceId].isRemoved;
	}

	function getServiceInformation ( 
			address _applicationAddress, 
			uint32 _serviceId )
		public view returns (
			bool exists,
			bool isSimple,
			string serviceDescription,
			uint256 tokensPerCredit,
			uint256 maxCreditsPerProvision,
			address receiptAddress,
			bool isRemoved,
			uint256 provisionHead ) {

		Service storage s=services[_applicationAddress][_serviceId];

		//services with unset application address indicates an empty/unset struct in the mapping
		if(s.applicationAddress == 0) {
			//first return parameter indicates whether the service exists
			exists=false;
			return;

		} else {
			exists=true;
			isSimple=s.isSimple;
			//note that the returned service description can&#39;t be read in solidity funtion call
			serviceDescription=s.serviceDescription;
			tokensPerCredit=s.tokensPerCredit;
			maxCreditsPerProvision=s.maxCreditsPerProvision;
			receiptAddress=s.receiptAddress;
			isRemoved=s.isRemoved;
			provisionHead=s.provisionHead;

			return;
		}
	}

	function getServiceUpdateAddress (
			address _applicationAddress, 
			uint32 _serviceId ) 
		public view returns (
			address updateAddress ) {

		Service storage s=services[_applicationAddress][_serviceId];

		return s.updateAddress;
	}

	function updateServiceDescription (
			address _targetApplicationAddress, 
			uint32 _serviceId, 
			string _serviceDescription ) 
		public returns (
			bool success ) {

		//get the referenced service
		Service storage s=services[_targetApplicationAddress][_serviceId];

		//check that service exists
		require(s.applicationAddress != 0);

		//update must be by the application address or, if specified, update address
		require(msg.sender == _targetApplicationAddress || 
			( s.updateAddress != address(0) && msg.sender == s.updateAddress ));

		//check that service is not removed
		require(s.isRemoved == false);

		services[_targetApplicationAddress][_serviceId].serviceDescription=_serviceDescription;
		
		emit ServiceChanged(_targetApplicationAddress, _serviceId);

		return true;
	}

	function updateServiceTokensPerCredit (
			address _targetApplicationAddress, 
			uint32 _serviceId, 
			uint256 _tokensPerCredit ) 
		public returns (
			bool success ) {

		//get the referenced service
		Service storage s=services[_targetApplicationAddress][_serviceId];

		//check that service exists
		require(s.applicationAddress != 0);

		//update must be by the application address or, if specified, update address
		require(msg.sender == _targetApplicationAddress || 
			( s.updateAddress != address(0) && msg.sender == s.updateAddress ));

		//check that service is not removed
		require(s.isRemoved == false);

		//check changed cost of the service is >0 
		require(_tokensPerCredit != 0);

		services[_targetApplicationAddress][_serviceId].tokensPerCredit=_tokensPerCredit;
		
		emit ServiceChanged(_targetApplicationAddress, _serviceId);

		return true;		
	}

	function updateServiceMaxCreditsPerProvision (
			address _targetApplicationAddress,
			uint32 _serviceId,
			uint256 _maxCreditsPerProvision )
		public returns (
			bool sucess ) {

		//get the referenced service
		Service storage s=services[_targetApplicationAddress][_serviceId];

		//check that service exists
		require(s.applicationAddress != 0);

		//update must be by the application address or, if specified, update address
		require(msg.sender == _targetApplicationAddress || 
			( s.updateAddress != address(0) && msg.sender == s.updateAddress ));

		//check that service is not removed
		require(s.isRemoved == false);

		//note that credits per provision can be == 0 (no limit)

		//change max credits per provision for this service
		services[_targetApplicationAddress][_serviceId].maxCreditsPerProvision=_maxCreditsPerProvision;

		emit ServiceChanged(_targetApplicationAddress, _serviceId);
	
		return true;		
	}

	function changeServiceReceiptAddress(
			uint32 _serviceId, 
			address _receiptAddress ) 
		public returns (
			bool success ) {

		//receipt address can only be changed by application address

		//check that service exists
		require(services[msg.sender][_serviceId].applicationAddress != 0);

		//check that service is not removed
		require(services[msg.sender][_serviceId].isRemoved == false);

		//check changed receiptAddress is not address(0)
		require(_receiptAddress != address(0));

		services[msg.sender][_serviceId].receiptAddress=_receiptAddress;
		
		emit ServiceChanged(msg.sender, _serviceId);

		return true;		
	}

	function changeServiceUpdateAddress (
			uint32 _serviceId,
			address _updateAddress )
		public returns (
			bool success ) {

		//update address can only be changed by application address

		//check that service exists
		require(services[msg.sender][_serviceId].applicationAddress != 0);

		//check that service is not removed
		require(services[msg.sender][_serviceId].isRemoved == false);

		//note: update address can be address(0)
		//change the update address
		services[msg.sender][_serviceId].updateAddress=_updateAddress;

		emit ServiceChanged(msg.sender, _serviceId);

		return true;
	}

	function removeService (
			address _targetApplicationAddress, 
			uint32 _serviceId ) 
		public returns (
			bool success ) {

		//check that service exists
		require(services[_targetApplicationAddress][_serviceId].applicationAddress != 0);

		//update must be by the application address or, if specified, update address
		require(msg.sender == _targetApplicationAddress || 
			( services[_targetApplicationAddress][_serviceId].updateAddress != address(0) 
			   && msg.sender == services[_targetApplicationAddress][_serviceId].updateAddress 
			  ));

		//check that service is not already removed
		require(services[_targetApplicationAddress][_serviceId].isRemoved == false);

		//add to removed array
		servicesRemovedLists[_targetApplicationAddress].push(_serviceId);

		//change value of isRemoved to true
		services[_targetApplicationAddress][_serviceId].isRemoved = true;

		emit ServiceRemoved(_targetApplicationAddress, _serviceId);

		return true;
	}

	function transferToSimpleService (
			address _applicationAddress, 
			uint32 _serviceId, 
			uint256 _tokenValue, 
			uint256 _applicationReference, 
			uint256 _multiple ) 
		public returns (
			bool success ) {

		//requested multiple must be >= 1
		require(_multiple > 0);

		//get the referenced service
		Service storage s=services[_applicationAddress][_serviceId];

		//service must exist
		require(s.applicationAddress != 0);

		//check that service is not removed
		require(services[_applicationAddress][_serviceId].isRemoved == false);

		//check that service is a simple service
		require(s.isSimple == true);

		//expected value is the token cost of the service multiplied by the requested multiple
		uint256 expectedValue=s.tokensPerCredit.mul(_multiple);

		//supplied token value must equal expected value
		require(expectedValue == _tokenValue);

		//transfer the tokens -- this verifies the sender owns the tokens
		transfer(s.receiptAddress, _tokenValue);

		//this starts and ends a simple provision at a single point in time 
		emit CompleteSimpleProvision(_applicationAddress, _serviceId, msg.sender, _multiple, _applicationReference);

		return true;
	}


	function transferToService (
			address _applicationAddress, 
			uint32 _serviceId, 
			uint256 _tokenValue, 
			uint256 _credits,
			uint256 _applicationReference ) 
		public returns (
			uint256 provisionId ) {

		//get the referenced service
		Service storage s=services[_applicationAddress][_serviceId];

		//service must exist
		require(s.applicationAddress != 0);

		//check that service is not removed
		require(services[_applicationAddress][_serviceId].isRemoved == false);

		//check that service is not a simple service
		require(s.isSimple == false);

		//verify: value == credits * tokens per credit
		require(_tokenValue == (_credits.mul(s.tokensPerCredit)));

		//verify: max credits == 0 OR (value/tokens per credit) <= max credits per provision
		require( s.maxCreditsPerProvision == 0 ||
			_credits <= s.maxCreditsPerProvision);

		//increment provision head and use as provision id
		s.provisionHead++;
		uint256 pid = s.provisionHead;

		//create provision in mapping
		provisions[_applicationAddress][_serviceId][pid] = Provision (
				s.tokensPerCredit,
				_credits,
				_applicationReference,
				msg.sender,
				_credits		
			);

		//transfer the tokens
		transfer(s.receiptAddress, _tokenValue);

		//emits a start provision 
		emit StartProvision(_applicationAddress, _serviceId, msg.sender, pid, _credits, s.tokensPerCredit, _applicationReference);

		//return provision id
		return pid;
	}

	function getProvisionCreditsRemaining (
			address _applicationAddress,
			uint32 _serviceId,
		    uint256 _provisionId )
		public view returns (
			uint256 credits) {

		//get the referenced service
		Service storage s=services[_applicationAddress][_serviceId];

		//service must exist
		require(s.applicationAddress != 0);

		//check that service is not removed
		require(services[_applicationAddress][_serviceId].isRemoved == false);		

		//get & check that the provision exists (address at userAddress)
		Provision storage p=provisions[_applicationAddress][_serviceId][_provisionId];
		require(p.userAddress != 0);

		//return the credits remaining for this provision
		return p.creditsRemaining;
	}

	function updateProvision (
		    address _applicationAddress,
		    uint32 _serviceId,
		    uint256 _provisionId,
		    uint256 _creditsRemaining )
		public returns (
			bool success ) {

		//credits remaining must be >0, complete provision should be used to set to 0
		require(_creditsRemaining > 0);

		//get the referenced service
		Service storage s=services[_applicationAddress][_serviceId];

		//check that service exists
		require(s.applicationAddress != 0);

		//update must be by the application address or, if specified, update address
		require(msg.sender == _applicationAddress || 
			( s.updateAddress != address(0) && msg.sender == s.updateAddress ));

		//check that service is not removed
		require(s.isRemoved == false);

		//get & check that the provision exists (address at userAddress)
		Provision storage p=provisions[_applicationAddress][_serviceId][_provisionId];
		require(p.userAddress != 0);

		//update the credits remaining
		p.creditsRemaining=_creditsRemaining;
	
		//fires UpdateProvision
		emit UpdateProvision(_applicationAddress, _serviceId, _provisionId, _creditsRemaining);

		return true;		
	}

	function completeProvision (
		    address _applicationAddress,
		    uint32 _serviceId,
		    uint256 _provisionId,
		    uint256 _creditsOutstanding )
		public returns (
			bool success ) {

		//get the referenced service
		Service storage s=services[_applicationAddress][_serviceId];

		//check that service exists
		require(s.applicationAddress != 0);

		//update must be by the application address or, if specified, update address
		require(msg.sender == _applicationAddress || 
			( s.updateAddress != address(0) && msg.sender == s.updateAddress ));

		//check that service is not removed
		require(s.isRemoved == false);

		//get & check that the provision exists (address at userAddress)
		Provision storage p=provisions[_applicationAddress][_serviceId][_provisionId];
		require(p.userAddress != 0);

		if(_creditsOutstanding > 0) {
			//can only signal refund total of credits originally provisioned
			require(_creditsOutstanding <= p.creditsProvisioned);

			emit SignalProvisionRefund(_applicationAddress, _serviceId, _provisionId, _creditsOutstanding.mul(p.tokensPerCredit));
		}

		//credits remaining on service is set to 0
		p.creditsRemaining=0;

		//fires CompleteProvision
		emit CompleteProvision(_applicationAddress, _serviceId, _provisionId, _creditsOutstanding);

		return true;
	}


	function confirmReference (
			address _applicationAddress,
			uint256 _applicationReference,
			uint256 _senderTokensMinimum )
		public returns (
			bool success ) {

		//sender must have some tokens - if 0 is passed to _senderTokensMinimum
		//then it is assumed that the method is checking that the sender has any amount
		//of tokens (>0)
		require(balances[msg.sender] > 0);

		//sender must have min tokens if specified
		require(_senderTokensMinimum == 0 
			|| balances[msg.sender] >= _senderTokensMinimum);

		emit ReferenceConfirmed(_applicationAddress, _applicationReference, msg.sender, _senderTokensMinimum);

		return true;
	}


	function transferBecauseOf (
		    address _to,
		    uint256 _value,
		    address _applicationAddress,
		    uint32 _serviceId,
		    uint256 _provisionId )
		public returns (
			bool success ) {

		//get the referenced service
		Service storage s=services[_applicationAddress][_serviceId];

		//check that service exists
		require(s.applicationAddress != 0);

		//check that service is not removed
		require(s.isRemoved == false);

		//provision ID can be optional, but if it&#39;s supplied it must exist
		if(_provisionId != 0) {
			//get & check that the provision exists (address at userAddress)
			Provision storage p=provisions[_applicationAddress][_serviceId][_provisionId];
			require(p.userAddress != 0);
		}

		//do the transfer
		transfer(_to, _value);

		emit TransferBecauseOf(_applicationAddress, _serviceId, _provisionId, msg.sender, _to, _value);

		return true;
	}


	function transferBecauseOfAggregate (
		    address _to,
		    uint256 _value,
		    address _applicationAddress,
		    uint32 _serviceId,
		    uint256[] _provisionIds,
		    uint256[] _tokenAmounts )
		public returns (
			bool success ) {

		//get the referenced service
		Service storage s=services[_applicationAddress][_serviceId];

		//check that service exists
		require(s.applicationAddress != 0);

		//check that service is not removed
		require(s.isRemoved == false);

		//do the transfer
		transfer(_to, _value);

		emit TransferBecauseOfAggregate(_applicationAddress, _serviceId, _provisionIds, _tokenAmounts, msg.sender, _to, _value);

		return true;
	}

	function ownerBurn ( 
			uint256 _value )
		public returns (
			bool success) {

		//only the contract owner can burn tokens
		require(msg.sender == contractOwner);

		//can only burn tokens held by the owner
		require(_value <= balances[contractOwner]);

		//total supply of tokens is decremented when burned
		totalSupply_ = totalSupply_.sub(_value);

		//balance of the contract owner is reduced (the contract owner&#39;s tokens are burned)
		balances[contractOwner] = balances[contractOwner].sub(_value);

		//burning tokens emits a transfer to 0, as well as TokensBurned
		emit Transfer(contractOwner, address(0), _value);
		emit TokensBurned(contractOwner, _value);

		return true;

	}
	
	
	function totalSupply ( ) public view returns (
		uint256 ) {

		return totalSupply_;
	}

	function balanceOf (
			address _owner ) 
		public view returns (
			uint256 ) {

		return balances[_owner];
	}

	function transfer (
			address _to, 
			uint256 _value ) 
		public returns (
			bool ) {

		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		emit Transfer(msg.sender, _to, _value);
		return true;
	}

   	//changing approval with this method has the same underlying issue as https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   	//in that transaction order can be modified in a block to spend, change approval, spend again
   	//the method is kept for ERC-20 compatibility, but a set to zero, set again or use of the below increase/decrease should be used instead
	function approve (
			address _spender, 
			uint256 _value ) 
		public returns (
			bool ) {

		allowed[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function increaseApproval (
			address _spender, 
			uint256 _addedValue ) 
		public returns (
			bool ) {

		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval (
			address _spender,
			uint256 _subtractedValue ) 
		public returns (
			bool ) {

		uint256 oldValue = allowed[msg.sender][_spender];

		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function allowance (
			address _owner, 
			address _spender ) 
		public view returns (
			uint256 remaining ) {

		return allowed[_owner][_spender];
	}

	function transferFrom (
			address _from, 
			address _to, 
			uint256 _value ) 
		public returns (
			bool ) {

		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

}