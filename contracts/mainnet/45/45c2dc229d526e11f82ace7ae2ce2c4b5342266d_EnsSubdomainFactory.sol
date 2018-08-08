pragma solidity ^0.4.24;

// ---------------------------------------------------------------------------------------------------
// EnsSubdomainFactory - allows creating and configuring custom ENS subdomains with one contract call.
//
// (c) Radek Ostrowski / https://startonchain.com - The MIT Licence.
// Source: https://github.com/radek1st/ens-subdomain-factory
// ---------------------------------------------------------------------------------------------------

/**
* @title EnsRegistry
* @dev Extract of the interface for ENS Registry
*/
contract EnsRegistry {
	function setOwner(bytes32 node, address owner) public;
	function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
	function setResolver(bytes32 node, address resolver) public;
	function owner(bytes32 node) public view returns (address);
}

/**
* @title EnsResolver
* @dev Extract of the interface for ENS Resolver
*/
contract EnsResolver {
	function setAddr(bytes32 node, address addr) public;
}

/**
* @title EnsSubdomainFactory
* @dev Allows to create and configure a first level subdomain for Ethereum ENS in one call.
* After deploying this contract, change the owner of the top level domain you want to use
* to this deployed contract address.
*/
contract EnsSubdomainFactory {
	address public owner;
    EnsRegistry public registry = EnsRegistry(0x314159265dD8dbb310642f98f50C066173C1259b);
	EnsResolver public resolver = EnsResolver(0x5FfC014343cd971B7eb70732021E26C35B744cc4);
    bytes32 ethNameHash = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

	event SubdomainCreated(string indexed domain, string indexed subdomain, address indexed creator);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
	* @dev Allows to create a subdomain (e.g. "radek.startonchain.eth"), 
	* set its resolver and set its target address
	* @param _topLevelDomain - parent domain name e.g. "startonchain"
	* @param _subDomain - sub domain name only e.g. "radek"
	* @param _owner - address that will become owner of this new subdomain
	* @param _target - address that this new domain will resolve to
	*/
	function newSubdomain(string _topLevelDomain, string _subDomain, address _owner, address _target) public {
	    //create namehash for the top domain
	    bytes32 topLevelNamehash = keccak256(abi.encodePacked(ethNameHash, keccak256(abi.encodePacked(_topLevelDomain))));
	    //make sure this contract owns the top level domain
        require(registry.owner(topLevelNamehash) == address(this), "this contract should own top level domain");
	    //create labelhash for the sub domain
	    bytes32 subDomainLabelhash = keccak256(abi.encodePacked(_subDomain));
	    //create namehash for the sub domain
	    bytes32 subDomainNamehash = keccak256(abi.encodePacked(topLevelNamehash, subDomainLabelhash));
        //make sure it is not already owned
        require(registry.owner(subDomainNamehash) == address(0), "sub domain already owned");
		//create new subdomain, temporarily this smartcontract is the owner
		registry.setSubnodeOwner(topLevelNamehash, subDomainLabelhash, address(this));
		//set public resolver for this domain
		registry.setResolver(subDomainNamehash, resolver);
		//set the destination address
		resolver.setAddr(subDomainNamehash, _target);
		//change the ownership back to requested owner
		registry.setOwner(subDomainNamehash, _owner);
		
		emit SubdomainCreated(_topLevelDomain, _subDomain, msg.sender);
	}

	/**
	* @dev The contract owner can take away the ownership of any top level domain owned by this contract.
	*/
	function transferDomainOwnership(bytes32 _node, address _owner) public onlyOwner {
		registry.setOwner(_node, _owner);
	}

	/**
	 * @dev Allows the current owner to transfer control of the contract to a new owner.
	 * @param _owner The address to transfer ownership to.
	 */
	function transferContractOwnership(address _owner) public onlyOwner {
	  require(_owner != address(0));
	  owner = _owner;
	  emit OwnershipTransferred(owner, _owner);
	}
}