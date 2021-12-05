/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// File: @ensdomains/ens/contracts/ENS.sol

pragma solidity >=0.4.24;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/Resolver.sol

pragma solidity ^0.5.0;


/**
 * @dev A basic interface for ENS resolvers.
 */
contract Resolver {
    function supportsInterface(bytes4 interfaceID) public pure returns (bool);
    function addr(bytes32 node) public view returns (address);
    function setAddr(bytes32 node, address addr) public;
}

// File: contracts/RegistrarInterface.sol

pragma solidity ^0.5.0;

contract RegistrarInterface {
    event OwnerChanged(bytes32 indexed label, address indexed oldOwner, address indexed newOwner);
    event DomainConfigured(bytes32 indexed label);
    event DomainUnlisted(bytes32 indexed label);
    event NewRegistration(bytes32 indexed label, string subdomain, address indexed owner);
    event RentPaid(bytes32 indexed label, string subdomain, uint amount, uint expirationDate);

    // InterfaceID of these four methods is 0xc1b15f5a
    function query(bytes32 label, string calldata subdomain) external view returns (string memory domain);
    function register(bytes32 label, string calldata subdomain, address owner, address resolver) external payable;

    function rentDue(bytes32 label, string calldata subdomain) external view returns (uint timestamp);
    function payRent(bytes32 label, string calldata subdomain) external payable;
}

// File: contracts/AbstractSubdomainRegistrar.sol

pragma solidity ^0.5.0;




contract AbstractSubdomainRegistrar is RegistrarInterface {

    // namehash('eth')
    bytes32 constant public TLD_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    bool public stopped = false;
    address public registrarOwner;
    address public migration;

    address public registrar;

    ENS public ens;

    modifier owner_only(bytes32 label) {
        require(owner(label) == msg.sender);
        _;
    }

    modifier not_stopped() {
        require(!stopped);
        _;
    }

    modifier registrar_owner_only() {
        require(msg.sender == registrarOwner);
        _;
    }

    event DomainTransferred(bytes32 indexed label, string name);

    constructor(ENS _ens) public {
        ens = _ens;
        registrar = ens.owner(TLD_NODE);
        registrarOwner = msg.sender;
    }

    function doRegistration(bytes32 node, bytes32 label, address subdomainOwner, Resolver resolver) internal {
        // Get the subdomain so we can configure it
        ens.setSubnodeOwner(node, label, address(this));

        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        // Set the subdomain's resolver
        ens.setResolver(subnode, address(resolver));

        // Set the address record on the resolver
        resolver.setAddr(subnode, subdomainOwner);

        // Pass ownership of the new subdomain to the registrant
        ens.setOwner(subnode, subdomainOwner);
    }

    function undoRegistration(bytes32 subnode, Resolver resolver) internal {
        // // Get the subdomain so we can configure it
        // ens.setSubnodeOwner(node, label, address(this));

        // bytes32 subnode = keccak256(abi.encodePacked(node, label));
        // // Set the subdomain's resolver
        // ens.setResolver(subnode, address(resolver));

        // Set the address record back to 0x0 on the resolver
        resolver.setAddr(subnode, address(0));

        // Set ownership of the new subdomain to the 0x0 address
        ens.setOwner(subnode, address(0)); 
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return (
            (interfaceID == 0x01ffc9a7) // supportsInterface(bytes4)
            || (interfaceID == 0xc1b15f5a) // RegistrarInterface
        );
    }

    function rentDue(bytes32 label, string calldata subdomain) external view returns (uint timestamp) {
        return 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    /**
     * @dev Sets the resolver record for a name in ENS.
     * @param name The name to set the resolver for.
     * @param resolver The address of the resolver
     */
    function setResolver(string memory name, address resolver) public owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        bytes32 node = keccak256(abi.encodePacked(TLD_NODE, label));
        ens.setResolver(node, resolver);
    }

    /**
     * @dev Configures a domain for sale.
     * @param name The name to configure.
     */
    function configureDomain(string memory name) public {
        configureDomainFor(name, msg.sender, address(0x0));
    }

    /**
     * @dev Stops the registrar, disabling configuring of new domains.
     */
    function stop() public not_stopped registrar_owner_only {
        stopped = true;
    }

    /**
     * @dev Sets the address where domains are migrated to.
     * @param _migration Address of the new registrar.
     */
    function setMigrationAddress(address _migration) public registrar_owner_only {
        require(stopped);
        migration = _migration;
    }

    function transferOwnership(address newOwner) public registrar_owner_only {
        registrarOwner = newOwner;
    }

    /**
     * @dev Returns information about a subdomain.
     * @param label The label hash for the domain.
     * @param subdomain The label for the subdomain.
     * @return domain The name of the domain, or an empty string if the subdomain
     *                is unavailable.
     */
    function query(bytes32 label, string calldata subdomain) external view returns (string memory domain);

    function owner(bytes32 label) public view returns (address);
    function configureDomainFor(string memory name, address payable _owner, address _transfer) public;
}

// File: @ensdomains/ens/contracts/Deed.sol

pragma solidity >=0.4.24;

interface Deed {

    function setOwner(address payable newOwner) external;
    function setRegistrar(address newRegistrar) external;
    function setBalance(uint newValue, bool throwOnFailure) external;
    function closeDeed(uint refundRatio) external;
    function destroyDeed() external;

    function owner() external view returns (address);
    function previousOwner() external view returns (address);
    function value() external view returns (uint);
    function creationDate() external view returns (uint);

}

// File: @ensdomains/ens/contracts/Registrar.sol

pragma solidity >=0.4.24;


interface Registrar {

    enum Mode { Open, Auction, Owned, Forbidden, Reveal, NotYetAvailable }

    event AuctionStarted(bytes32 indexed hash, uint registrationDate);
    event NewBid(bytes32 indexed hash, address indexed bidder, uint deposit);
    event BidRevealed(bytes32 indexed hash, address indexed owner, uint value, uint8 status);
    event HashRegistered(bytes32 indexed hash, address indexed owner, uint value, uint registrationDate);
    event HashReleased(bytes32 indexed hash, uint value);
    event HashInvalidated(bytes32 indexed hash, string indexed name, uint value, uint registrationDate);

    function state(bytes32 _hash) external view returns (Mode);
    function startAuction(bytes32 _hash) external;
    function startAuctions(bytes32[] calldata _hashes) external;
    function newBid(bytes32 sealedBid) external payable;
    function startAuctionsAndBid(bytes32[] calldata hashes, bytes32 sealedBid) external payable;
    function unsealBid(bytes32 _hash, uint _value, bytes32 _salt) external;
    function cancelBid(address bidder, bytes32 seal) external;
    function finalizeAuction(bytes32 _hash) external;
    function transfer(bytes32 _hash, address payable newOwner) external;
    function releaseDeed(bytes32 _hash) external;
    function invalidateName(string calldata unhashedName) external;
    function eraseNode(bytes32[] calldata labels) external;
    function transferRegistrars(bytes32 _hash) external;
    function acceptRegistrarTransfer(bytes32 hash, Deed deed, uint registrationDate) external;
    function entries(bytes32 _hash) external view returns (Mode, address, uint, uint, uint);
}

// File: contracts/DeadDotComSeance.sol

pragma solidity ^0.5.0;

contract DeadDotComSeance {
  function ownerOf(uint256 tokenId) public view returns (address);
}

// File: contracts/SubdomainRegistrar.sol

pragma solidity ^0.5.0;




/**
 * @dev Implements an ENS registrar that sells subdomains on behalf of their owners.
 *
 * Users may register a subdomain by calling `register` with the name of the domain
 * they wish to register under, and the label hash of the subdomain they want to
 * register. They must also specify the new owner of the domain, and the referrer,
 * who is paid an optional finder's fee. The registrar then configures a simple
 * default resolver, which resolves `addr` lookups to the new owner, and sets
 * the `owner` account as the owner of the subdomain in ENS.
 *
 * New domains may be added by calling `configureDomain`, then transferring
 * ownership in the ENS registry to this contract. Ownership in the contract
 * may be transferred using `transfer`, and a domain may be unlisted for sale
 * using `unlistDomain`. There is (deliberately) no way to recover ownership
 * in ENS once the name is transferred to this registrar.
 *
 * Critically, this contract does not check one key property of a listed domain:
 *
 * - Is the name UTS46 normalised?
 *
 * User applications MUST check these two elements for each domain before
 * offering them to users for registration.
 *
 * Applications should additionally check that the domains they are offering to
 * register are controlled by this registrar, since calls to `register` will
 * fail if this is not the case.


 * Dead DotCom Seance Logic
  - There are X ENS names that are each associated with a group of NFTs.
  - If someone owns one of the NFTs associated with the ENS name, they can register a subdomain of that ENS name
  - If they transfer that NFT, the new owner can register a new subdomain of the ENS name.
  - When a new



 */
contract SubdomainRegistrar is AbstractSubdomainRegistrar {


    struct Domain {
        string name;
        // bytes32 label;
        uint256 editionsize;
    }

    modifier new_registrar() {
        require(ens.owner(TLD_NODE) != address(registrar));
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == oowner);
        _;
    }

    function owner(bytes32 label) public view returns (address) {
        // if (domains[label].owner != address(0x0)) {
            return address(this);
            // return domains[label].owner;
        // }

        // return BaseRegistrar(registrar).ownerOf(uint256(label));
    }

    event TransferAddressSet(bytes32 indexed label, address addr);
    // Resolver resolver = 0x004976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41; // mainnet
    Resolver resolver;// = Resolver(0x00b14fdee4391732ea9d2267054ead2084684c0ad8); // rinkeby
    
    DeadDotComSeance deadDotComSeance;
    address oowner;
    mapping (uint256 => string) idToSubdomain;
    bytes32[] idToDomain;

    mapping (bytes32 => uint256) labelToId;
    mapping (bytes32 => Domain) public domains;

    constructor(ENS ens, DeadDotComSeance _deadDotComSeance, Resolver _resolver) AbstractSubdomainRegistrar(ens) public {
        resolver = _resolver;
        deadDotComSeance = _deadDotComSeance;
        oowner = msg.sender;

        domains[keccak256(bytes("petsdotcom"))]= Domain("petsdotcom", 0);
        idToDomain.push(keccak256(bytes("petsdotcom")));

        domains[keccak256(bytes("alladvantage"))]= Domain("alladvantage", 15);
        idToDomain.push(keccak256(bytes("alladvantage")));

        domains[keccak256(bytes("bidland"))]= Domain("bidland", 20);
        idToDomain.push(keccak256(bytes("bidland")));

        domains[keccak256(bytes("bizbuyer"))]= Domain("bizbuyer", 20);
        idToDomain.push(keccak256(bytes("bizbuyer")));

        domains[keccak256(bytes("capacityweb"))]= Domain("capacityweb", 21);
        idToDomain.push(keccak256(bytes("capacityweb")));

        domains[keccak256(bytes("cashwars"))]= Domain("cashwars", 26);
        idToDomain.push(keccak256(bytes("cashwars")));

        domains[keccak256(bytes("ecircles"))]= Domain("ecircles", 22);
        idToDomain.push(keccak256(bytes("ecircles")));

        domains[keccak256(bytes("efanshop"))]= Domain("efanshop", 28);
        idToDomain.push(keccak256(bytes("efanshop")));

        domains[keccak256(bytes("ehobbies"))]= Domain("ehobbies", 16);
        idToDomain.push(keccak256(bytes("ehobbies")));

        domains[keccak256(bytes("elaw"))]= Domain("elaw", 19);
        idToDomain.push(keccak256(bytes("elaw")));

        domains[keccak256(bytes("exchangepath"))]= Domain("exchangepath", 29);
        idToDomain.push(keccak256(bytes("exchangepath")));

        domains[keccak256(bytes("financialprinter"))]= Domain("financialprinter", 15);
        idToDomain.push(keccak256(bytes("financialprinter")));

        domains[keccak256(bytes("funbug"))]= Domain("funbug", 29);
        idToDomain.push(keccak256(bytes("funbug")));

        domains[keccak256(bytes("heavenlydoor"))]= Domain("heavenlydoor", 32);
        idToDomain.push(keccak256(bytes("heavenlydoor")));

        domains[keccak256(bytes("iharvest"))]= Domain("iharvest", 40);
        idToDomain.push(keccak256(bytes("iharvest")));

        domains[keccak256(bytes("misterswap"))]= Domain("misterswap", 17);
        idToDomain.push(keccak256(bytes("misterswap")));

        domains[keccak256(bytes("netmorf"))]= Domain("netmorf", 25);
        idToDomain.push(keccak256(bytes("netmorf")));

        domains[keccak256(bytes("popularpower"))]= Domain("popularpower", 22);
        idToDomain.push(keccak256(bytes("popularpower")));

        domains[keccak256(bytes("stickynetworks"))]= Domain("stickynetworks", 24);
        idToDomain.push(keccak256(bytes("stickynetworks")));

        domains[keccak256(bytes("thirdvoice"))]= Domain("thirdvoice", 16);
        idToDomain.push(keccak256(bytes("thirdvoice")));

        domains[keccak256(bytes("wingspanbank"))]= Domain("wingspanbank", 54);
        idToDomain.push(keccak256(bytes("wingspanbank")));
    }

    function updateOwner(address newOwner) public {
        require(msg.sender == oowner);
        oowner = newOwner;
    }

    // /**
    //  * @dev Configures a domain, optionally transferring it to a new owner.
    //  * @param name The name to configure.
    //  * @param _owner The address to assign ownership of this domain to.
    //  * @param _transfer The address to set as the transfer address for the name
    //  *        when the permanent registrar is replaced. Can only be set to a non-zero
    //  *        value once.
    //  */
    function configureDomainFor(string memory name, address payable _owner, address _transfer) public owner_only(keccak256(bytes(name))) {
        // bytes32 label = keccak256(bytes(name));
        // Domain storage domain = domains[label];

        // if (BaseRegistrar(registrar).ownerOf(uint256(label)) != address(this)) {
        //     BaseRegistrar(registrar).transferFrom(msg.sender, address(this), uint256(label));
        //     BaseRegistrar(registrar).reclaim(uint256(label), address(this));
        // }

        // if (domain.owner != _owner) {
        //     domain.owner = _owner;
        // }

        // if (keccak256(bytes(domain.name)) != label) {
        //     // New listing
        //     domain.name = name;
        // }

        // emit DomainConfigured(label);
    }

    // function configureDomainFor(uint256 _workId, string memory name, uint256 _editionsize) public onlyOwner() {
    //     bytes32 label = keccak256(bytes(name));
    //     domains[label].name = name;
    //     domains[label].editionsize = _editionsize;

    //     emit DomainConfigured(label);
    // }

    // /**
    //  * @dev Returns information about a subdomain.
    //  * @param label The label hash for the domain.
    //  * @param subdomain The label for the subdomain.
    //  * @return domain The name of the domain, or an empty string if the subdomain
    //  *                is unavailable.
    //  */
    function query(bytes32 label, string calldata subdomain) external view returns (string memory domain) {
        bytes32 node = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subnode = keccak256(abi.encodePacked(node, keccak256(bytes(subdomain))));

        if (ens.owner(subnode) != address(0x0)) {
            return ("");
        }

        Domain storage data = domains[label];
        return (data.name);
    }
    function queryByName(string calldata name, string calldata subdomain) external view returns (uint256 id) {
        bytes32 label = keccak256(bytes(name));
        bytes32 node = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subnode = keccak256(abi.encodePacked(node, keccak256(bytes(subdomain))));
        return labelToId[subnode];
    } 
    // /**
    //  * @dev Returns information about a subdomain.
    //  * @param label The label hash for the domain.
    //  * @param subdomain The label for the subdomain.
    //  * @return domain The name of the domain, or an empty string if the subdomain
    //  *                is unavailable.
    //  */
    function queryById(uint256 id) external view returns (string memory subdomain) {
        return idToSubdomain[id];
    }
    function register(bytes32 label, string calldata subdomain, address owner, address resolver) external payable {
        revert("nope");
    }


    // /**
    //  * @dev Registers a subdomain.
    //  * @param label The label hash of the domain to register a subdomain of.
    //  * @param subdomain The desired subdomain label.
    //  * @param _subdomainOwner The account that should own the newly configured subdomain.
    //  */
    function registerSubdomain(string calldata subdomain, uint256 tokenId) external not_stopped payable {

        // make sure msg.sender is the owner of the NFT tokenId
        address subdomainOwner = msg.sender;
        // TODO: re-enable for mainnet
        // address subdomainOwner = DotComSeance.ownerOf(tokenId);
        // require(subdomainOwner == msg.sender, "can't register a subdomain for an NFT you don't own");

        // make sure that the tokenId is correlated to the domain
        uint256 workId = tokenId / 100;
        uint256 editionId = tokenId % 100;

        bytes32 label = idToDomain[workId];
        Domain storage domain = domains[label];
        // bytes32 label = keccak256(bytes(domain.name));
        // bytes32 label = domain.label;
        // uint256 editionsize = domain.editionsize;

        bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subdomainLabel = keccak256(bytes(subdomain));
        bytes32 subnode = keccak256(abi.encodePacked(domainNode, subdomainLabel));

        // Subdomain must not be registered already.
        require(ens.owner(subnode) == address(0));

        // if subdomain was previously registered, delete it
        string memory _subdomain = idToSubdomain[tokenId];
        if (bytes(_subdomain).length == 0) {
            bytes32 _subdomainLabel = keccak256(bytes(subdomain));
            bytes32 _subnode = keccak256(abi.encodePacked(domainNode, _subdomainLabel));
            undoRegistration(subnode, resolver);
        }

        doRegistration(domainNode, subdomainLabel, subdomainOwner, resolver);
        idToSubdomain[tokenId] = subdomain;
        labelToId[subnode] = tokenId;

        emit NewRegistration(label, subdomain, subdomainOwner);
    }

    // /**
    //  * @dev Upgrades the domain to a new registrar.
    //  * @param name The name of the domain to transfer.
    //  */
    // function upgrade(string memory name) public owner_only(keccak256(bytes(name))) new_registrar {
    //     bytes32 label = keccak256(bytes(name));
    //     address transfer = domains[label].transferAddress;

    //     require(transfer != address(0x0));

    //     delete domains[label];

    //     Registrar(registrar).transfer(label, address(uint160((transfer))));
    //     emit DomainTransferred(label, name);
    // }

    // /**
    //  * @dev Migrates the domain to a new registrar.
    //  * @param name The name of the domain to migrate.
    //  */
    // function migrate(string memory name) public owner_only(keccak256(bytes(name))) {
    //     require(stopped);
    //     require(migration != address(0x0));

    //     bytes32 label = keccak256(bytes(name));
    //     Domain storage domain = domains[label];

    //     Registrar(registrar).transfer(label, address(uint160((migration))));

    //     SubdomainRegistrar(migration).configureDomainFor(
    //         domain.name,
    //         domain.owner,
    //         domain.transferAddress
    //     );

    //     delete domains[label];

    //     emit DomainTransferred(label, name);
    // }

    function payRent(bytes32 label, string calldata subdomain) external payable {
        revert();
    }

    function deed(bytes32 label) internal view returns (Deed) {
        (, address deedAddress,,,) = Registrar(registrar).entries(label);
        return Deed(deedAddress);
    }
}