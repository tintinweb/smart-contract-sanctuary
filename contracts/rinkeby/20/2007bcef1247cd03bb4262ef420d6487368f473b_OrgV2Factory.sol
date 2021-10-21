/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address spender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ENS {
    function owner(bytes32) external view returns (address);
    function setOwner(bytes32, address) external;
    function resolver(bytes32) external view returns (address);
    function setSubnodeOwner(bytes32, bytes32, address) external returns (bytes32);
}

interface ReverseRegistrar {
    function setName(string memory name) external returns (bytes32);
    function node(address addr) external view returns (bytes32);
}

/// A Radicle Org.
contract OrgV1 {
    /// Object anchor.
    struct Anchor {
        // A tag that can be used to discriminate between anchor types.
        uint32 tag;
        // The hash being anchored in multihash format.
        bytes multihash;
    }

    /// Output of namehash("addr.reverse").
    bytes32 public constant ADDR_REVERSE_NODE =
        0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    /// Org owner.
    address public owner;

    /// Latest anchor for each object.
    mapping (bytes32 => Anchor) public anchors;

    // -- EVENTS --

    /// An object was anchored.
    event Anchored(bytes32 id, uint32 tag, bytes multihash);

    /// An object was unanchored.
    event Unanchored(bytes32 id);

    /// The org owner changed.
    event OwnerChanged(address newOwner);

    /// The org name changed.
    event NameChanged(string name);

    /// Construct a new org instance, by providing an owner address.
    constructor(address _owner) {
        owner = _owner;
    }

    // -- OWNER METHODS --

    /// Functions that can only be called by the org owner.
    modifier ownerOnly {
        require(msg.sender == owner, "Org: Only the org owner can perform this action");
        _;
    }

    /// Set the org owner.
    function setOwner(address newOwner) public ownerOnly {
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }

    /// Anchor an object to the org, by providing its hash in *multihash* format.
    /// This method should be used for adding new objects to the org, as well as
    /// updating existing ones.
    ///
    /// The `id` parameter is the unique identifier of the object being anchored.
    ///
    /// The `tag` parameter may be used to discriminate between different types
    /// of anchors.
    function anchor(
        bytes32 id,
        uint32 tag,
        bytes calldata multihash
    ) public ownerOnly {
        anchors[id] = Anchor(tag, multihash);
        emit Anchored(id, tag, multihash);
    }

    /// Unanchor an object from the org.
    function unanchor(bytes32 id) public ownerOnly {
        delete anchors[id];
        emit Unanchored(id);
    }

    /// Transfer funds from this contract to the owner contract.
    function recoverFunds(IERC20 token, uint256 amount) public ownerOnly returns (bool) {
        return token.transfer(msg.sender, amount);
    }

    /// Configures the caller's reverse ENS record to point to the provided name.
    /// The address of the ENS registry is passed as the second parameter.
    function setName(string memory name, ENS ens) public ownerOnly returns (bytes32) {
        ReverseRegistrar registrar = ReverseRegistrar(ens.owner(ADDR_REVERSE_NODE));
        bytes32 node = registrar.setName(name);
        emit NameChanged(name);

        return node;
    }
}


interface SafeFactory {
    function createProxy(address masterCopy, bytes memory data) external returns (Safe);
}

interface Resolver {
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);
    function setAddr(bytes32, address) external;
    function addr(bytes32 node) external returns (address);
    function name(bytes32 node) external returns (string memory);
}

interface Registrar {
    function commit(bytes32 commitment) external;
    function commitWithPermit(
        bytes32 commitment,
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function register(string calldata name, address owner, uint256 salt) external;
    function ens() external view returns (address);
    function radNode() external view returns (bytes32);
    function rad() external view returns (address);
    function registrationFeeRad() external view returns (uint256);
    function minCommitmentAge() external view returns (uint256);
}

interface Safe {
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;

    function getThreshold() external returns (uint256);
    function isOwner(address owner) external returns (bool);
}

/// Factory for orgs.
contract OrgV2Factory {
    SafeFactory immutable safeFactory;
    address immutable safeMasterCopy;

    // Radicle ENS domain.
    string public radDomain = ".radicle.eth";

    /// An org was created. Includes the org and owner address as well as the name.
    event OrgCreated(address org, address owner, string domain);

    constructor(
        address _safeFactory,
        address _safeMasterCopy
    ) {
        safeFactory = SafeFactory(_safeFactory);
        safeMasterCopy = _safeMasterCopy;
    }

    /// Commitments to org names.
    mapping (bytes32 => bytes32) public commitments;

    /// Commit to a new org name.
    ///
    /// The commitment must commit to this contract as the owner, while the owner
    /// digest should be a hash of the desired owner of the name, once setup is complete.
    ///
    /// The same salt should be used for both parameters. For the owner digest,
    /// the contract expects `keccak256(abi.encodePacked(owner, salt))`.
    /// In the case of a multi-sig, the owners array should be used.
    ///
    /// @param registrar The Radicle registrar.
    /// @param commitment The commitment that will be submitted to the registrar.
    /// @param ownerDigest The designated owner of the name, once setup is complete.
    function commitToOrgName(
        Registrar registrar,
        bytes32 commitment,
        bytes32 ownerDigest
    ) public {
        commitments[commitment] = ownerDigest;

        uint256 fee = registrar.registrationFeeRad();
        if (fee > 0) {
            IERC20 rad = IERC20(registrar.rad());

            require(
                rad.transferFrom(msg.sender, address(this), fee),
                "OrgFactory: transfer of registration fee from sender must succeed"
            );
            require(
                rad.approve(address(registrar), fee),
                "OrgFactory: approval of registration fee to registrar must succeed"
            );
        }
        registrar.commit(commitment);
    }

    /// Commit to a new org name, using *permit*.
    ///
    /// See `commitToOrgName`.
    function commitToOrgNameWithPermit(
        Registrar registrar,
        bytes32 commitment,
        bytes32 ownerDigest,
        address permitOwner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        commitments[commitment] = ownerDigest;
        registrar.commitWithPermit(commitment, permitOwner, value, deadline, v, r, s);
    }

    /// Register a pre-committed name, create an org and associate the two
    /// together.
    ///
    /// To use this method, one must commit to a name and use this contract's
    /// address as the owner committed to. This method will transfer ownership
    /// of the name to the given owner after completing the registration.
    ///
    /// To set additional ENS records for the given name, one may include
    /// optional calldata using the `resolverData` parameter.
    ///
    /// @param owner The owner of the org.
    /// @param name Name to register and associate with the org.
    /// @param salt Commitment salt used in `commit` transaction.
    /// @param resolverData Data payload for optional resolver multicall.
    /// @param registrar Address of the Radicle registrar.
    function registerAndCreateOrg(
        address owner,
        string memory name,
        uint256 salt,
        bytes[] calldata resolverData,
        Registrar registrar
    ) public returns (OrgV1, bytes32) {
        require(address(registrar) != address(0), "OrgFactory: registrar must not be zero");
        require(owner != address(0), "OrgFactory: owner must not be zero");

        {
            bytes32 ownerDigest = redeemCommitment(name, salt);
            require(keccak256(abi.encodePacked(owner, salt)) == ownerDigest, "OrgFactory: owners must match commitment");
        }

        // Temporarily set the owner of the name to this contract.
        // It will be transfered to the given owner once the setup
        // is complete.
        registrar.register(name, address(this), salt);

        ENS ens = ENS(registrar.ens());
        bytes32 root = registrar.radNode();
        bytes32 label = keccak256(bytes(name));

        return setupOrg(
            owner,
            resolverData,
            string(abi.encodePacked(name, radDomain)),
            root,
            label,
            ens
        );
    }

    /// Register a pre-committed name, create an org owned by multiple owners,
    /// and associated the two together.
    ///
    /// @param owners The owners of the org.
    /// @param threshold The minimum number of signatures to perform org transactions.
    /// @param name Name to register and associate with the org.
    /// @param salt Commitment salt used in `commit` transaction.
    /// @param resolverData Data payload for optional resolver multicall.
    /// @param registrar Address of the Radicle registrar.
    function registerAndCreateOrg(
        address[] memory owners,
        uint256 threshold,
        string memory name,
        uint256 salt,
        bytes[] calldata resolverData,
        Registrar registrar
    ) public returns (OrgV1, bytes32) {
        require(address(registrar) != address(0), "OrgFactory: registrar must not be zero");

        {
            bytes32 ownerDigest = redeemCommitment(name, salt);
            require(keccak256(abi.encodePacked(owners, salt)) == ownerDigest, "OrgFactory: owners must match commitment");
        }

        registrar.register(name, address(this), salt);

        ENS ens = ENS(registrar.ens());
        bytes32 root = registrar.radNode();
        bytes32 label = keccak256(bytes(name));

        return setupOrg(
            owners,
            threshold,
            resolverData,
            string(abi.encodePacked(name, radDomain)),
            root,
            label,
            ens
        );
    }

    /// Registers a name that is owned by this contract, and reclaims it by
    /// transfering it back to the owner.
    ///
    /// This is useful in emergency situations when a commitment was created
    /// with this contract as the owner, but completing the flow and creating
    /// an org is not desirable.
    ///
    /// @param registrar Address of the Radicle registrar.
    /// @param parent ENS parent node for the name, eg. `namehash("radicle.eth")`.
    /// @param name Name committed to, eg. "cloudhead".
    /// @param salt Salt committed to.
    /// @param owner Address this name should be transfered to after registration.
    function registerAndReclaim(
        Registrar registrar,
        bytes32 parent,
        string memory name,
        uint256 salt,
        address owner
    ) public {
        ENS ens = ENS(registrar.ens());

        bytes32 ownerDigest = redeemCommitment(name, salt);
        require(keccak256(abi.encodePacked(owner, salt)) == ownerDigest, "OrgFactory: owner must match commitment");

        registrar.register(name, address(this), salt);

        bytes32 node = keccak256(abi.encodePacked(parent, keccak256(bytes(name))));
        ens.setOwner(node, owner);
    }

    /// Setup an org with multiple owners.
    function setupOrg(
        address[] memory owners,
        uint256 threshold,
        bytes[] calldata resolverData,
        string memory domain,
        bytes32 parent,
        bytes32 label,
        ENS ens
    ) private returns (OrgV1, bytes32) {
        require(owners.length > 0, "OrgFactory: owners must not be empty");
        require(threshold > 0, "OrgFactory: threshold must be greater than zero");
        require(threshold <= owners.length, "OrgFactory: threshold must be lesser than or equal to owner count");

        // Deploy safe.
        Safe safe = safeFactory.createProxy(safeMasterCopy, new bytes(0));
        safe.setup(owners, threshold, address(0), new bytes(0), address(0), address(0), 0, payable(address(0)));

        return setupOrg(address(safe), resolverData, domain, parent, label, ens);
    }

    /// Setup an org with an existing owner.
    function setupOrg(
        address owner,
        bytes[] calldata resolverData,
        string memory domain,
        bytes32 parent,
        bytes32 label,
        ENS ens
    ) private returns (OrgV1, bytes32) {
        require(address(ens) != address(0), "OrgFactory: ENS address must not be zero");

        // Create org, temporarily holding ownership.
        OrgV1 org = new OrgV1(address(this));
        // Get the ENS node for the name associated with this org.
        bytes32 node = keccak256(abi.encodePacked(parent, label));
        // Get the ENS resolver for the node.
        Resolver resolver = Resolver(ens.resolver(node));
        // Set the address of the ENS name to this org.
        resolver.setAddr(node, address(org));
        // Set any other ENS records.
        resolver.multicall(resolverData);
        // Set org ENS reverse-record.
        org.setName(domain, ens);
        // Transfer ownership of the org to the owner.
        org.setOwner(owner);
        // Transfer ownership of the name to the owner.
        ens.setOwner(node, owner);

        emit OrgCreated(address(org), owner, domain);

        return (org, node);
    }

    /// Redeem a previously made commitment.
    function redeemCommitment(string memory name, uint256 salt) private returns (bytes32) {
        bytes32 commitment = keccak256(abi.encodePacked(name, address(this), salt));
        bytes32 ownerDigest = commitments[commitment];

        require(ownerDigest != bytes32(0), "OrgFactory: commitment not found");
        delete commitments[commitment];

        return ownerDigest;
    }
}