/**
 *Submitted for verification at Etherscan.io on 2021-12-06
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

    function undoRegistration(bytes32 node, bytes32 label, Resolver resolver) internal {
        // // Get the subdomain so we can configure it
        ens.setSubnodeOwner(node, label, address(this));

        bytes32 subnode = keccak256(abi.encodePacked(node, label));
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
    Subdomain Registrar is heavily modified from 
    https://github.com/ensdomains/subdomain-registrar
 */

contract SubdomainRegistrar is AbstractSubdomainRegistrar {

    modifier onlyOwner() {
        require(msg.sender == oowner);
        _;
    }

    event NewSubdomain(string domain, string subdomain, uint256 tokenId, address tokenOwner, string oldSubdomain);

    Resolver resolver;
    DeadDotComSeance deadDotComSeance;
    address oowner;
    mapping (uint256 => string) idToSubdomain;
    bytes32[] idToDomain;

    mapping (bytes32 => uint256) labelToId;
    mapping (bytes32 => string) public domains;

    constructor(ENS ens, DeadDotComSeance _deadDotComSeance, Resolver _resolver) AbstractSubdomainRegistrar(ens) public {
        resolver = _resolver;
        deadDotComSeance = _deadDotComSeance;
        oowner = msg.sender;

        domains[keccak256(bytes("petsdotcom"))]= "petsdotcom";
        idToDomain.push(keccak256(bytes("petsdotcom")));

        domains[keccak256(bytes("alladvantage"))]= "alladvantage";
        idToDomain.push(keccak256(bytes("alladvantage")));

        domains[keccak256(bytes("bidland"))]= "bidland";
        idToDomain.push(keccak256(bytes("bidland")));

        domains[keccak256(bytes("bizbuyer"))]= "bizbuyer";
        idToDomain.push(keccak256(bytes("bizbuyer")));

        domains[keccak256(bytes("capacityweb"))]= "capacityweb";
        idToDomain.push(keccak256(bytes("capacityweb")));

        domains[keccak256(bytes("cashwars"))]= "cashwars";
        idToDomain.push(keccak256(bytes("cashwars")));

        domains[keccak256(bytes("ecircles"))]= "ecircles";
        idToDomain.push(keccak256(bytes("ecircles")));

        domains[keccak256(bytes("efanshop"))]= "efanshop";
        idToDomain.push(keccak256(bytes("efanshop")));

        domains[keccak256(bytes("ehobbies"))]= "ehobbies";
        idToDomain.push(keccak256(bytes("ehobbies")));

        domains[keccak256(bytes("elaw"))]= "elaw";
        idToDomain.push(keccak256(bytes("elaw")));

        domains[keccak256(bytes("exchangepath"))]= "exchangepath";
        idToDomain.push(keccak256(bytes("exchangepath")));

        domains[keccak256(bytes("financialprinter"))]= "financialprinter";
        idToDomain.push(keccak256(bytes("financialprinter")));

        domains[keccak256(bytes("funbug"))]= "funbug";
        idToDomain.push(keccak256(bytes("funbug")));

        domains[keccak256(bytes("heavenlydoor"))]= "heavenlydoor";
        idToDomain.push(keccak256(bytes("heavenlydoor")));

        domains[keccak256(bytes("iharvest"))]= "iharvest";
        idToDomain.push(keccak256(bytes("iharvest")));

        domains[keccak256(bytes("misterswap"))]= "misterswap";
        idToDomain.push(keccak256(bytes("misterswap")));

        domains[keccak256(bytes("netmorf"))]= "netmorf";
        idToDomain.push(keccak256(bytes("netmorf")));

        domains[keccak256(bytes("popularpower"))]= "popularpower";
        idToDomain.push(keccak256(bytes("popularpower")));

        domains[keccak256(bytes("stickynetworks"))]= "stickynetworks";
        idToDomain.push(keccak256(bytes("stickynetworks")));

        domains[keccak256(bytes("thirdvoice"))]= "thirdvoice";
        idToDomain.push(keccak256(bytes("thirdvoice")));

        domains[keccak256(bytes("wingspanbank"))]= "wingspanbank";
        idToDomain.push(keccak256(bytes("wingspanbank")));
    }

    // admin

    function updateOwner(address newOwner) public onlyOwner {
        oowner = newOwner;
    }
    function updateResolver(Resolver _resolver) public onlyOwner {
        require(msg.sender == oowner);
        resolver = _resolver;
    }

    // meat and potatoes

    function registerSubdomain(string calldata subdomain, uint256 tokenId) external not_stopped payable {
        // make sure msg.sender is the owner of the NFT tokenId
        address subdomainOwner = deadDotComSeance.ownerOf(tokenId);
        require(subdomainOwner == msg.sender, "cant register a subdomain for an NFT you dont own");

        // make sure that the tokenId is correlated to the domain
        uint256 workId = tokenId / 100;

        // guille works are all part of workId 0
        if (workId == 0) {
            workId = tokenId % 100;
        }

        bytes32 label = idToDomain[workId - 1];

        bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subdomainLabel = keccak256(bytes(subdomain));
        bytes32 subnode = keccak256(abi.encodePacked(domainNode, subdomainLabel));

        // Subdomain must not be registered already.
        require(ens.owner(subnode) == address(0), "subnode already owned");

        // if subdomain was previously registered, delete it
        string memory oldSubdomain = idToSubdomain[tokenId];
        if (bytes(oldSubdomain).length != 0) {
            bytes32 oldSubdomainLabel = keccak256(bytes(oldSubdomain));
            undoRegistration(domainNode, oldSubdomainLabel, resolver);
        }

        doRegistration(domainNode, subdomainLabel, subdomainOwner, resolver);
        idToSubdomain[tokenId] = subdomain;

        emit NewSubdomain(domains[label], subdomain, tokenId, subdomainOwner, oldSubdomain);
    }

    // admin

    function unregister(string calldata subdomain, uint256 tokenId) external onlyOwner {
        uint256 workId = tokenId / 100;

        if (workId == 0) {
            workId = tokenId % 100;
        }
        bytes32 label = idToDomain[workId - 1];
        bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 _subdomain = keccak256(bytes(subdomain));
        undoRegistration(domainNode, _subdomain, resolver);
    }

    // Don't want to modify too much of the inherited ENS stuff.
    // Everything below is just to satisfy interface and might be used for ENS frontent.

    function register(bytes32 label, string calldata subdomain, address owner, address resolver) external payable {
        revert("nope");
    }
    function payRent(bytes32 label, string calldata subdomain) external payable {
        revert("nope");
    }
    function configureDomainFor(string memory name, address payable _owner, address _transfer) public owner_only(keccak256(bytes(name))) {
        revert("nope");
    }
    function deed(bytes32 label) internal view returns (Deed) {
        (, address deedAddress,,,) = Registrar(registrar).entries(label);
        return Deed(deedAddress);
    }
    function owner(bytes32 label) public view returns (address) {
        return address(this);
    }
    function query(bytes32 label, string calldata subdomain) external view returns (string memory domain) {
        bytes32 node = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subnode = keccak256(abi.encodePacked(node, keccak256(bytes(subdomain))));
        if (ens.owner(subnode) != address(0x0)) {
            return ("");
        }
        return domains[label];
    }
}