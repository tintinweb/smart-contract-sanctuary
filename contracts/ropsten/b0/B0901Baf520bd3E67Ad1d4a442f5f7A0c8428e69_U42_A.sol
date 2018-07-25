//from https://github.com/OpenZeppelin/openzeppelin-solidity
//at https://github.com/OpenZeppelin/openzeppelin-solidity/commit/5daaf60d11ee2075260d0f3adfb22b1c536db983

pragma solidity ^0.4.24;


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

// Implementation of the U42 Token Specification (&quot;A&quot; version) -- see &quot;U42 Token Specification (version A).md&quot;
//
// Standard ERC-20 methods and the SafeMath library are adapated from OpenZeppelin&#39;s standard contract types
// as at https://github.com/OpenZeppelin/openzeppelin-solidity/commit/5daaf60d11ee2075260d0f3adfb22b1c536db983
// note that uint256 is used explicitly in place of uint

contract U42_A {
	//use OZ SafeMath to avoid uint256 overflows
	using SafeMath for uint256;

	string public constant name = &quot;U42_A&quot;;
	string public constant symbol = &quot;U42A&quot;;
	uint8 public constant decimals = 18;
	uint256 public constant initialSupply = 525000000 * (10 ** uint256(decimals));
	uint256 public totalSupply_ = initialSupply;

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
		address[] updateAddresses;
		address receiptAddress;
		bool isRemoved;
	}

	//mapping of application addresses to service structs
	mapping (address => mapping (uint32 => Service)) services;

	//mapping of application addresses to lists of services
	mapping (address => uint32[]) servicesLists;

	//mapping of application addresses to lists of removed services
	mapping (address => uint32[]) servicesRemovedLists;

	//methods emit the following events (note that these are a subset 
	// -- the &quot;A&quot; version -- of the full U42 token specification)
	event Transfer (
		address indexed from, 
		address indexed to, 
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


	constructor() public {
		//contract creator holds all tokens at creation
		balances[msg.sender] = totalSupply_;

		//indicate all tokens were sent to contract address
		emit Transfer(address(0), msg.sender, totalSupply_);
	}

	function listSimpleService ( 
			uint32 _serviceId, 
			string _serviceDescription,
			uint256 _tokensRequired,
			address[] _updateAddresses,
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

		//check an empty array was supplied for _updateAddresses -- this contract version
		//does not support update addresses (only updated from the application address)
		require(_updateAddresses.length == 0);

		//add service to services mapping
		services[msg.sender][_serviceId] = Service(
				msg.sender,
				_serviceId,
				true,
				_serviceDescription,
				_tokensRequired,
				1,
				_updateAddresses,
				_receiptAddress,
				false
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
			bool isRemoved ) {

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

			return;
		}
	}

	function getServiceUpdateAddresses (
			address _applicationAddress, 
			uint32 _serviceId ) 
		public view returns (
			address[] updateAddresses ) {

		Service storage s=services[_applicationAddress][_serviceId];

		//services with unset application address indicates an empty/unset struct in the mapping
		if(s.applicationAddress == 0) {
			//return a zero-length array of update addresses -- i.e. there are no update addresses
			return new address[](0);
		} else {
			return s.updateAddresses;
		}	
	}

	function updateServiceDescription (
			address _targetApplicationAddress, 
			uint32 _serviceId, 
			string _serviceDescription ) 
		public returns (
			bool success ) {

		require(_targetApplicationAddress != address(0));

		//u42_a only supports updates by the application address
		require(msg.sender == _targetApplicationAddress);

		//check that service exists
		require(services[_targetApplicationAddress][_serviceId].applicationAddress != 0);

		//check that service is not removed
		require(services[_targetApplicationAddress][_serviceId].isRemoved == false);

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

		require(_targetApplicationAddress != address(0));

		//u42_a only supports updates by the application address
		require(msg.sender == _targetApplicationAddress);

		//check that service exists
		require(services[_targetApplicationAddress][_serviceId].applicationAddress != 0);

		//check that service is not removed
		require(services[_targetApplicationAddress][_serviceId].isRemoved == false);

		//check changed cost of the service is >0 
		require(_tokensPerCredit != 0);

		services[_targetApplicationAddress][_serviceId].tokensPerCredit=_tokensPerCredit;
		
		emit ServiceChanged(_targetApplicationAddress, _serviceId);

		return true;		
	}

	function changeServiceReceiptAddress(
			uint32 _serviceId, 
			address _receiptAddress ) 
		public returns (
			bool success ) {

		//reeipt address can only be changed by application address

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

	function removeService (
			address _targetApplicationAddress, 
			uint32 _serviceId ) 
		public returns (
			bool success ) {

		//u42_a only supports updates by the application address
		require(msg.sender == _targetApplicationAddress);

		//check that service exists
		require(services[_targetApplicationAddress][_serviceId].applicationAddress != 0);

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