pragma solidity ^0.4.4;

/**
 * The ENS registry contract.
 */
contract ENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping(bytes32=>Record) records;

    // Permits modifications only by the owner of the specified node.
    modifier only_owner(bytes32 node) {
        if (records[node].owner != msg.sender) throw;
        _;
    }

    /**
     * Constructs a new ENS registrar.
     */
    function ENS() {
        records[0].owner = msg.sender;
    }

    /**
     * Returns the address that owns the specified node.
     */
    function owner(bytes32 node) constant returns (address) {
        return records[node].owner;
    }

    /**
     * Returns the address of the resolver for the specified node.
     */
    function resolver(bytes32 node) constant returns (address) {
        return records[node].resolver;
    }

    /**
     * Returns the TTL of a node, and any records associated with it.
     */
    function ttl(bytes32 node) constant returns (uint64) {
        return records[node].ttl;
    }

    /**
     * Transfers ownership of a node to a new address. May only be called by the current
     * owner of the node.
     * @param node The node to transfer ownership of.
     * @param owner The address of the new owner.
     */
    function setOwner(bytes32 node, address owner) only_owner(node) {
        Transfer(node, owner);
        records[node].owner = owner;
    }

    /**
     * Transfers ownership of a subnode sha3(node, label) to a new address. May only be
     * called by the owner of the parent node.
     * @param node The parent node.
     * @param label The hash of the label specifying the subnode.
     * @param owner The address of the new owner.
     */
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) only_owner(node) {
        var subnode = sha3(node, label);
        NewOwner(node, label, owner);
        records[subnode].owner = owner;
    }

    /**
     * Sets the resolver address for the specified node.
     * @param node The node to update.
     * @param resolver The address of the resolver.
     */
    function setResolver(bytes32 node, address resolver) only_owner(node) {
        NewResolver(node, resolver);
        records[node].resolver = resolver;
    }

    /**
     * Sets the TTL for the specified node.
     * @param node The node to update.
     * @param ttl The TTL in seconds.
     */
    function setTTL(bytes32 node, uint64 ttl) only_owner(node) {
        NewTTL(node, ttl);
        records[node].ttl = ttl;
    }
}

/**
 * @dev A basic interface for ENS resolvers.
 */
contract Resolver {
  function supportsInterface(bytes4 interfaceID) public pure returns (bool);
  function addr(bytes32 node) public view returns (address);
  function setAddr(bytes32 node, address addr) public;
}

contract RegistrarInterface {
  event OwnerChanged(bytes32 indexed label, address indexed oldOwner, address indexed newOwner);
  event DomainConfigured(bytes32 indexed label);
  event DomainUnlisted(bytes32 indexed label);
  event NewRegistration(bytes32 indexed label, string subdomain, address indexed owner, address indexed referrer, uint price);
  event RentPaid(bytes32 indexed label, string subdomain, uint amount, uint expirationDate);

  // InterfaceID of these four methods is 0xc1b15f5a
  function query(bytes32 label, string subdomain) view returns(string domain, uint signupFee, uint rent, uint referralFeePPM);
  function register(bytes32 label, string subdomain, address owner, address referrer, address resolver) public payable;

  function rentDue(bytes32 label, string subdomain) public view returns(uint timestamp);
  function payRent(bytes32 label, string subdomain) public payable;
}
/**
 * @dev Implements an ENS registrar that sells subdomains on behalf of their owners.
 *
 * Users may register a subdomain by calling `register` with the name of the domain
 * they wish to register under, and the label hash of the subdomain they want to
 * register. They must also specify the new owner of the domain, and the referrer,
 * who is paid an optional finder&#39;s fee. The registrar then configures a simple
 * default resolver, which resolves `addr` lookups to the new owner, and sets
 * the `owner` account as the owner of the subdomain in ENS.
 *
 * New domains may be added by calling `configureDomain`, then transferring
 * ownership in the ENS registry to this contract. Ownership in the contract
 * may be transferred using `transfer`, and a domain may be unlisted for sale
 * using `unlistDomain`. There is (deliberately) no way to recover ownership
 * in ENS once the name is transferred to this registrar.
 *
 * Critically, this contract does not check two key properties of a listed domain:
 *
 * - Is the name UTS46 normalised?
 * - Is the Deed held by an appropriate custodian contract?
 *
 * User applications MUST check these two elements for each domain before
 * offering them to users for registration.
 *
 * Applications should additionally check that the domains they are offering to
 * register are controlled by this registrar, since calls to `register` will
 * fail if this is not the case.
 */
contract SubdomainRegistrar is RegistrarInterface {
  // namehash(&#39;eth&#39;)
  bytes32 constant public TLD_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

  ENS public ens;

  struct Domain {
    string name;
    address owner;
    uint price;
    uint referralFeePPM;
  }

  mapping(bytes32=>Domain) domains;

  function SubdomainRegistrar(ENS _ens) public {
    ens = _ens;
  }

  /**
   * @dev owner returns the address of the account that controls a domain.
   *      Initially this is the owner of the name in ENS. If the name has been
   *      transferred to this contract, then the internal mapping is consulted
   *      to determine who controls it.
   * @param label The label hash of the deed to check.
   * @return The address owning the deed.
   */
  function owner(bytes32 label) public view returns(address ret) {
      ret = ens.owner(keccak256(TLD_NODE, label));
      if(ret == address(this)) {
        ret = domains[label].owner;
      }
  }

  modifier owner_only(bytes32 label) {
      require(owner(label) == msg.sender);
      _;
  }

  /**
   * @dev Transfers internal control of a name to a new account. Does not update
   *      ENS.
   * @param name The name to transfer.
   * @param newOwner The address of the new owner.
   */
  function transfer(string name, address newOwner) public owner_only(keccak256(name)) {
    var label = keccak256(name);
    OwnerChanged(keccak256(name), domains[label].owner, newOwner);
    domains[label].owner = newOwner;
  }

  /**
   * @dev Sets the resolver record for a name in ENS.
   * @param name The name to set the resolver for.
   * @param resolver The address of the resolver
   */
  function setResolver(string name, address resolver) public owner_only(keccak256(name)) {
    var label = keccak256(name);
    var node = keccak256(TLD_NODE, label);
    ens.setResolver(node, resolver);
  }

  /**
   * @dev Configures a domain for sale.
   * @param name The name to configure.
   * @param price The price in wei to charge for subdomain registrations
   * @param referralFeePPM The referral fee to offer, in parts per million
   */
  function configureDomain(string name, uint price, uint referralFeePPM) public owner_only(keccak256(name)) {
    var label = keccak256(name);
    var domain = domains[label];

    if(keccak256(domain.name) != label) {
      // New listing
      domain.name = name;
    }
    if(domain.owner != msg.sender) {
      domain.owner = msg.sender;
    }
    domain.price = price;
    domain.referralFeePPM = referralFeePPM;
    DomainConfigured(label);
  }

  /**
   * @dev Unlists a domain
   * May only be called by the owner.
   * @param name The name of the domain to unlist.
   */
  function unlistDomain(string name) public owner_only(keccak256(name)) {
    var label = keccak256(name);
    var domain = domains[label];
    DomainUnlisted(label);

    domain.name = &#39;&#39;;
    domain.owner = owner(label);
    domain.price = 0;
    domain.referralFeePPM = 0;
  }

  /**
   * @dev Returns information about a subdomain.
   * @param label The label hash for the domain.
   * @param subdomain The label for the subdomain.
   * @return domain The name of the domain, or an empty string if the subdomain
   *                is unavailable.
   * @return price The price to register a subdomain, in wei.
   * @return rent The rent to retain a subdomain, in wei per second.
   * @return referralFeePPM The referral fee for the dapp, in ppm.
   */
  function query(bytes32 label, string subdomain) view returns(string domain, uint price, uint rent, uint referralFeePPM) {
    var node = keccak256(TLD_NODE, label);
    var subnode = keccak256(node, keccak256(subdomain));

    if(ens.owner(subnode) != 0) {
      return (&#39;&#39;, 0, 0, 0);
    }

    var data = domains[label];
    return (data.name, data.price, 0, data.referralFeePPM);
  }

  /**
   * @dev Registers a subdomain.
   * @param label The label hash of the domain to register a subdomain of.
   * @param subdomain The desired subdomain label.
   * @param subdomainOwner The account that should own the newly configured subdomain.
   * @param referrer The address of the account to receive the referral fee.
   */
  function register(bytes32 label, string subdomain, address subdomainOwner, address resolver, address referrer) public payable {
    var domainNode = keccak256(TLD_NODE, label);
    var subdomainLabel = keccak256(subdomain);

    // Subdomain must not be registered already.
    require(ens.owner(keccak256(domainNode, subdomainLabel)) == address(0));

    var domain = domains[label];

    // Domain must be available for registration
    require(keccak256(domain.name) == label);

    // User must have paid enough
    require(msg.value >= domain.price);

    // Send any extra back
    if(msg.value > domain.price) {
      msg.sender.transfer(msg.value - domain.price);
    }

    // Send any referral fee
    var total = domain.price;
    if(domain.referralFeePPM * domain.price > 0 && referrer != 0 && referrer != domain.owner) {
      var referralFee = (domain.price * domain.referralFeePPM) / 1000000;
      referrer.transfer(referralFee);
      total -= referralFee;
    }

    // Send the registration fee
    if(total > 0) {
      domain.owner.transfer(total);
    }

    // Register the domain
    if(subdomainOwner == 0) {
      subdomainOwner = msg.sender;
    }
    doRegistration(domainNode, subdomainLabel, subdomainOwner, Resolver(resolver));

    NewRegistration(label, subdomain, subdomainOwner, referrer, domain.price);
  }

  function doRegistration(bytes32 node, bytes32 label, address subdomainOwner, Resolver resolver) internal {
    // Get the subdomain so we can configure it
    ens.setSubnodeOwner(node, label, this);

    var subnode = keccak256(node, label);
    // Set the subdomain&#39;s resolver
    ens.setResolver(subnode, resolver);

    // Set the address record on the resolver
    resolver.setAddr(subnode, subdomainOwner);

    // Pass ownership of the new subdomain to the registrant
    ens.setOwner(subnode, subdomainOwner);
  }

  function supportsInterface(bytes4 interfaceID) constant returns (bool) {
    return (
         (interfaceID == 0x01ffc9a7) // supportsInterface(bytes4)
      || (interfaceID == 0xc1b15f5a) // RegistrarInterface
    );
  }

  function rentDue(bytes32 label, string subdomain) public view returns(uint timestamp) {
    return 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  }

  function payRent(bytes32 label, string subdomain) public payable {
    revert();
  }
}