// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import './AbstractSubdomainRegistrar.sol';
import './IBaseRegistrar.sol';
import './IResolver.sol';
import './IWhitelist.sol';
import './ERC721.sol';

/**
 * @dev Implements an ENS registrar that sells whitelisted subdomains on behalf of their owners.
 */
contract MojiRegistrar is AbstractSubdomainRegistrar, ERC721 {

    struct Domain {
        string name;
        address payable owner;
        uint price;
    }

    IWhitelist immutable public whitelist;
    IResolver immutable public resolver;

    address public registrarSigner;
    mapping (bytes32 => Domain) domains;

    uint256 constant private MIN_PRICE_UNIT = 10**14;
    string constant private MESSAGE_PREFIX = '\x19Ethereum Signed Message:\n32';

    constructor(ENS ens, IWhitelist _whitelist, IResolver _resolver, address _registrarSigner) AbstractSubdomainRegistrar(ens) ERC721('Moji', 'MOJI') public {
      whitelist = _whitelist;
      resolver = _resolver;
      registrarSigner = _registrarSigner;
      _setBaseURI('ipfs://');
    }

    /**
     * @dev owner returns the address of the account that controls a domain.
     *      Initially this is a null address. If the name has been
     *      transferred to this contract, then the internal mapping is consulted
     *      to determine who controls it. If the owner is not set,
     *      the owner of the domain in the Registrar is returned.
     * @param label The label hash of the deed to check.
     * @return The address owning the deed.
     */
    function owner(bytes32 label) public override view returns (address) {
        if (domains[label].owner != address(0x0)) {
            return domains[label].owner;
        }
        return IBaseRegistrar(registrar).ownerOf(uint256(label));
    }

    /**
     * @dev Transfers internal control of a name to a new account. Does not update
     *      ENS.
     * @param name The name to transfer.
     * @param newOwner The address of the new owner.
     */
    function transfer(string memory name, address payable newOwner) public owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        emit OwnerChanged(label, domains[label].owner, newOwner);
        domains[label].owner = newOwner;
    }

    /**
     * @dev Configures a domain, optionally transferring it to a new owner.
     * @param name The name to configure.
     * @param price The maximum price in wei to charge for subdomain registrations.
     * @param _owner The address to assign ownership of this domain to.
     * @param _transfer The address to set as the transfer address for the name
     *        when the permanent registrar is replaced. Can only be set to a non-zero
     *        value once.
     */
    function configureDomainFor(string memory name, uint price, address payable _owner, address _transfer) public override owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        Domain storage domain = domains[label];

        if (IBaseRegistrar(registrar).ownerOf(uint256(label)) != address(this)) {
            IBaseRegistrar(registrar).transferFrom(msg.sender, address(this), uint256(label));
            IBaseRegistrar(registrar).reclaim(uint256(label), address(this));
        }

        if (domain.owner != _owner) {
            domain.owner = _owner;
        }

        if (keccak256(bytes(domain.name)) != label) {
            // New listing
            domain.name = name;
        }

        domain.price = price;

        emit DomainConfigured(label);
    }

    /**
     * @dev Returns information about a subdomain.
     * @param label The label hash for the domain.
     * @param subdomain The label for the subdomain.
     * @return domain The name of the domain, or an empty string if the subdomain
     *                is unavailable.
     * @return price The price to register the subdomain, in wei.
     * @return rent The rent to retain a subdomain, in wei per second.
     */
    function query(bytes32 label, string calldata subdomain) external override view returns (string memory domain, uint price, uint rent) {
        bytes32 node = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subnode = keccak256(abi.encodePacked(node, keccak256(bytes(subdomain))));

        if (ens.owner(subnode) != address(0x0)) {
            return ('', 0, 0);
        }

        Domain storage data = domains[label];
        return (data.name, getSubdomainPrice(data, bytes(subdomain)), 0);
    }

    /**
     * @dev Registers a <=32 bytes whitelisted subdomain.
     * @param label The label hash of the domain to register a subdomain of.
     * @param subdomain The desired subdomain label.
     * @param _subdomainOwner The account that should own the newly configured subdomain.
     * @param metadata The metadata uri and signature used to prove validity.
     */
    function register(bytes32 label, string calldata subdomain, address _subdomainOwner, Metadata memory metadata) external override not_stopped payable {
        address subdomainOwner = _subdomainOwner;
        bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes memory subdomainBytes = bytes(subdomain);
        bytes32 subdomainLabel = keccak256(subdomainBytes);

        // Subdomain must be 32 bytes or less
        require(subdomainBytes.length <= 32, 'subdomain too long');

        // Subdomain must be whitelisted
        require(whitelist.isBytesWhitelisted(subdomainBytes), 'subdomain not whitelisted');

        // Subdomain must not be registered already
        require(ens.owner(keccak256(abi.encodePacked(domainNode, subdomainLabel))) == address(0));

        // Subdomain bytes + metadata uri must be signed by the `registrarSigner`
        address actualSigner = getActualMetadataSigner(subdomainBytes, metadata);
        require(actualSigner == registrarSigner, 'subdomain metadata uri is invalid');

        Domain storage domain = domains[label];

        // Domain must be available for registration
        require(keccak256(bytes(domain.name)) == label);

        // User must have paid enough
        uint256 subdomainPrice = getSubdomainPrice(domain, subdomainBytes);
        require(msg.value >= subdomainPrice);

        // Send the registration fee
        domain.owner.transfer(msg.value);

        // Register the domain
        if (subdomainOwner == address(0x0)) {
            subdomainOwner = msg.sender;
        }

        bytes32 subnode = keccak256(abi.encodePacked(domainNode, subdomainLabel));

        // Set the subdomain owner so we can configure it
        ens.setSubnodeOwner(domainNode, subdomainLabel, address(this));

        // Set the subdomain's resolver
        ens.setResolver(subnode, address(resolver));

        // Set the address record on the resolver
        resolver.setAddr(subnode, subdomainOwner);

        uint256 tokenId = uint256(subnode);
        _safeMint(_subdomainOwner, tokenId);
        _setTokenURI(tokenId, metadata.uri);

        emit NewRegistration(label, subdomain, subdomainOwner, subdomainPrice);
    }

    function rentDue(bytes32 label, string calldata subdomain) external override view returns (uint timestamp) {
        return 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    /**
     * @dev Returns the subdomain price, rounded down to the nearest multiple of `MIN_PRICE_UNIT`.
     * @param domain The domain instance.
     * @param subdomainBytes The subdomain bytes.
     * @return The rounded subdomain price.
     */
    function getSubdomainPrice(Domain storage domain, bytes memory subdomainBytes) private view returns (uint256) {
        uint256 subdomainPrice = domain.price / (subdomainBytes.length / 4);
        return subdomainPrice - (subdomainPrice % MIN_PRICE_UNIT);
    }

    /**
     * @dev Migrates the domain to a new registrar.
     * @param name The name of the domain to migrate.
     */
    function migrate(string memory name) public owner_only(keccak256(bytes(name))) {
        require(stopped);
        require(migration != address(0x0));

        bytes32 label = keccak256(bytes(name));
        Domain storage domain = domains[label];

        IBaseRegistrar(registrar).approve(migration, uint256(label));

        MojiRegistrar(migration).configureDomainFor(
            domain.name,
            domain.price,
            domain.owner,
            address(0x0)
        );

        delete domains[label];

        emit DomainTransferred(label, name);
    }

    /**
     * @dev This function will revert. No rent is required.
     */
    function payRent(bytes32 label, string calldata subdomain) external override payable {
        revert();
    }

    /**
     * @dev Update the address record on the resolver following a successful transfer
     * @param from The token sender
     * @param to The token receiver
     * @param tokenId The id of the token being transferred
     */
    function _transfer(address from, address to, uint256 tokenId) internal override {
        super._transfer(from, to, tokenId);
        resolver.setAddr(bytes32(tokenId), to);
    }

    /**
     * @dev Change the registrar signer. This function can only be called by the registrar owner.
     * @param newSigner The new signer address
     */
    function changeSigner(address newSigner) public registrar_owner_only {
        registrarSigner = newSigner;
    }

    /**
     * @dev Get the actual signer of the provided subdomain and metadata uri
     * @param subdomain The subdomain bytes
     * @param metadata The metadata uri and signature
     */
    function getActualMetadataSigner(bytes memory subdomain, Metadata memory metadata) private returns (address) {
        bytes32 metadataHash = keccak256(abi.encodePacked(subdomain, metadata.uri));
        bytes32 messageHash = keccak256(abi.encodePacked(MESSAGE_PREFIX, metadataHash));
        return ecrecover(messageHash, metadata.signature.v, metadata.signature.r, metadata.signature.s);
    }
}