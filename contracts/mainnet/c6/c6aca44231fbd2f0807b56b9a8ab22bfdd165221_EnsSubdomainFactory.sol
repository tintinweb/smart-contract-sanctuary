pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// EnsSubdomainFactory - allows creating and configuring custom ENS subdomains with one contract call.
//
// (c) Radek Ostrowski / https://startonchain.com - The MIT Licence.
// ----------------------------------------------------------------------------

/**
* @title EnsRegistry
* @dev Extract of the interface for ENS Registry
*/
contract EnsRegistry {
	function setOwner(bytes32 node, address owner) public;
	function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
	function setResolver(bytes32 node, address resolver) public;
}

/**
* @title EnsResolver
* @dev Extract of the interface for ENS Resolver
*/
contract EnsResolver {
	function setAddr(bytes32 node, address addr) public;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
   * @dev Allows the current owner to transfer control of the contract to a new owner.
   * @param _owner The address to transfer ownership to.
   */
  function transferOwnership(address _owner) public onlyOwner {
    require(_owner != address(0));
    owner = _owner;
    emit OwnershipTransferred(owner, _owner);
  }
}

/**
* @title EnsSubdomainFactory
* @dev Allows to create and configure a subdomain for Ethereum ENS in one call.
* After deploying this contract, change the owner of the top level domain you want to use
* to this deployed contract address.
*/
contract EnsSubdomainFactory is Ownable {
	EnsRegistry public registry = EnsRegistry(0x314159265dD8dbb310642f98f50C066173C1259b);
	EnsResolver public resolver = EnsResolver(0x5FfC014343cd971B7eb70732021E26C35B744cc4);

	event SubdomainCreated(bytes32 indexed subdomain, address indexed owner);

	constructor() public {
		owner = msg.sender;
	}

	/**
	* @dev The owner can take away the ownership of any top level domain owned by this contract.
	*/
	function setDomainOwner(bytes32 _node, address _owner) onlyOwner public {
		registry.setOwner(_node, _owner);
	}

	/**
	* @dev Allows to create a subdomain, set its resolver and set its target address
	* @param _node - namehash of parent domain name e.g. namehash("startonchain.eth")
	* @param _subnode - namehash of sub with parent domain name e.g. namehash("radek.startonchain.eth")
	* @param _label - hash of subdomain name only e.g. "radek"
	* @param _owner - address that will become owner of this new subdomain
	* @param _target - address that this new domain will resolve to
	*/
	function newSubdomain(bytes32 _node, bytes32 _subnode, bytes32 _label, address _owner, address _target) public {
		//create new subdomain, temporarily this smartcontract is the owner
		registry.setSubnodeOwner(_node, _label, address(this));
		//set public resolver for this domain
		registry.setResolver(_subnode, resolver);
		//set the destination address
		resolver.setAddr(_subnode, _target);
		//change the ownership back to requested owner
		registry.setOwner(_subnode, _owner);
		emit SubdomainCreated(_label, _owner);
	}
}