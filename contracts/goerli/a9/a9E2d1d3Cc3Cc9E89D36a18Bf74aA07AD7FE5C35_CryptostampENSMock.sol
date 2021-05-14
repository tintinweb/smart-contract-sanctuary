/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

/*
 * Crypto stamp ENS Mock for Layer 2
 * This contract mocks/emulates an ENS Registrar for Crypto stamp Collections
 * as well as the needed ENS resolver interfaces to query the forward and
 * reverse name entries.
 *
 * Developed by Capacity Blockchain Solutions GmbH <capacity.at>
 * for Österreichische Post AG <post.at>
 */


// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: contracts/BridgeDataI.sol

/*
 * Interface for data storage of the bridge.
 */

interface BridgeDataI {

    event AddressChanged(string name, address previousAddress, address newAddress);
    event ConnectedChainChanged(string previousConnectedChainName, string newConnectedChainName);
    event TokenURIBaseChanged(string previousTokenURIBase, string newTokenURIBase);
    event TokenSunsetAnnounced(uint256 indexed timestamp);

    /**
     * @dev The name of the chain connected to / on the other side of this bridge head.
     */
    function connectedChainName() external view returns (string memory);

    /**
     * @dev The name of our own chain, used in token URIs handed to deployed tokens.
     */
    function ownChainName() external view returns (string memory);

    /**
     * @dev The base of ALL token URIs, e.g. https://example.com/
     */
    function tokenURIBase() external view returns (string memory);

    /**
     * @dev The sunset timestamp for all deployed tokens.
     * If 0, no sunset is in place. Otherwise, if older than block timestamp,
     * all transfers of the tokens are frozen.
     */
    function tokenSunsetTimestamp() external view returns (uint256);

    /**
     * @dev Set a token sunset timestamp.
     */
    function setTokenSunsetTimestamp(uint256 _timestamp) external;

    /**
     * @dev Set an address for a name.
     */
    function setAddress(string memory name, address newAddress) external;

    /**
     * @dev Get an address for a name.
     */
    function getAddress(string memory name) external view returns (address);
}

// File: contracts/CollectionsI.sol

/*
 * Interface for the Collections factory.
 */


/**
 * @dev Outward-facing interface of a Collections contract.
 */
interface CollectionsI is IERC721 {

    /**
     * @dev Emitted when a new collection is created.
     */
    event NewCollection(address indexed owner, address collectionAddress);

    /**
     * @dev Emitted when a collection is destroyed.
     */
    event KilledCollection(address indexed owner, address collectionAddress);

    /**
     * @dev Creates a new Collection. For calling from other contracts,
     * returns the address of the new Collection.
     */
    function create(address _notificationContract,
                    string calldata _ensName,
                    string calldata _ensSubdomainName,
                    address _ensSubdomainRegistrarAddress,
                    address _ensReverseRegistrarAddress)
    external payable
    returns (address);

    /**
     * @dev Create a collection for a different owner. Only callable by a
     * create controller role. For calling from other contracts, returns the
     * address of the new Collection.
     */
    function createFor(address payable _newOwner,
                       address _notificationContract,
                       string calldata _ensName,
                       string calldata _ensSubdomainName,
                       address _ensSubdomainRegistrarAddress,
                       address _ensReverseRegistrarAddress)
    external payable
    returns (address);

    /**
     * @dev Removes (burns) an empty Collection. Only the Collection contract itself can call this.
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev Returns if a Collection NFT exists for the specified `tokenId`.
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @dev Returns whether the given spender can transfer a given `collectionAddr`.
     */
    function isApprovedOrOwnerOnCollection(address spender, address collectionAddr) external view returns (bool);

    /**
     * @dev Returns the Collection address for a token ID.
     */
    function collectionAddress(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the token ID for a Collection address.
     */
    function tokenIdForCollection(address collectionAddr) external view returns (uint256);

    /**
     * @dev Returns true if a Collection exists at this address, false if not.
     */
    function collectionExists(address collectionAddr) external view returns (bool);

    /**
     * @dev Returns the owner of the Collection with the given address.
     */
    function collectionOwner(address collectionAddr) external view returns (address);

    /**
     * @dev Returns a Collection address owned by `owner` at a given `index` of
     * its Collections list. Mirrors `tokenOfOwnerByIndex` in ERC721Enumerable.
     */
    function collectionOfOwnerByIndex(address owner, uint256 index) external view returns (address);

}

// File: contracts/ENSSimpleRegistrarI.sol

/*
 * Interface for simple ENS Registrar
 * Exposing a registerAddr() signature modeled after the sample at
 * https://docs.ens.domains/contract-developer-guide/writing-a-registrar
 * together with the setAddr() from the AddrResolver.
 */

interface ENSSimpleRegistrarI {
    function registerAddr(bytes32 label, address target) external;
}

// File: contracts/ENSReverseI.sol

/*
 * Interface for ENS reverse name resolution
 * Exposing the name() signature used by any reverse resolver for Ethereum names
 */

interface ENSReverseI {
    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}

// File: contracts/ENSReverseRegistrarI.sol

/*
 * Interfaces for ENS Reverse Registrar
 * See https://github.com/ensdomains/ens/blob/master/contracts/ReverseRegistrar.sol for full impl
 * Also see https://github.com/wealdtech/wealdtech-solidity/blob/master/contracts/ens/ENSReverseRegister.sol
 *
 * Use this as follows (registryAddress is the address of the ENS registry to use):
 * -----
 * // This hex value is caclulated by namehash('addr.reverse')
 * bytes32 public constant ENS_ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
 * function registerReverseENS(address registryAddress, string memory calldata) external {
 *     require(registryAddress != address(0), "need a valid registry");
 *     address reverseRegistrarAddress = ENSRegistryOwnerI(registryAddress).owner(ENS_ADDR_REVERSE_NODE)
 *     require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * or
 * -----
 * function registerReverseENS(address reverseRegistrarAddress, string memory calldata) external {
 *    require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * ENS deployments can be found at https://docs.ens.domains/ens-deployments
 * E.g. Etherscan can be used to look up that owner on those contracts.
 * namehash.hash("addr.reverse") == "0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2"
 * Ropsten: ens.owner(namehash.hash("addr.reverse")) == "0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c"
 * Mainnet: ens.owner(namehash.hash("addr.reverse")) == "0x084b1c3C81545d370f3634392De611CaaBFf8148"
 */

interface ENSRegistryOwnerI {
    function owner(bytes32 node) external view returns (address);
}

interface ENSReverseRegistrarI {
    event NameChanged(bytes32 indexed node, string name);
    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the calling account.
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setName(string calldata name) external returns (bytes32);
}

// File: contracts/ENSAddrI.sol

/*
 * Interface for ENS Addr
 * Exposing the addr() signature used by any address resolver for Ethereum names
 */

interface ENSAddrI {
    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address);
}

// File: contracts/ENSAddrResolverI.sol

/*
 * Interface for ENS Addr Resolver
 * Exposing the setAddr() signature used by the public resolver for Ethereum names
 */

interface ENSAddrResolverI {
    event AddrChanged(bytes32 indexed node, address a);
    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) external;
}

// File: contracts/CryptostampENSMock.sol

/*
 * Mock ENS subdomain registrar/provider for Crypto stamp collections on Layer 2.
 * Originally builds on the sample custom FIFS registrar: https://docs.ens.domains/contract-developer-guide/writing-a-registrar
 * As we do not have actual ENS on Layer 2 for now, this provides all functionality
 * for storing names and resolving forward and reverse queries as well.
 */











contract CryptostampENSMock is ERC165, ENSSimpleRegistrarI, ENSReverseRegistrarI, ENSAddrI, ENSReverseI {

    BridgeDataI public bridgeData;

    bytes32 public rootNode;

    mapping(bytes32 => address) public override addr;
    mapping(bytes32 => string) public override name;

    // namehash('addr.reverse')
    bytes32 public constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
    address public constant blockAddress = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    event BridgeDataChanged(address indexed previousBridgeData, address indexed newBridgeData);
    event Registered(bytes32 indexed label, bytes32 subnode, address indexed target);
    event Unregistered(bytes32 indexed label, bytes32 subnode);
    event Blocked(bytes32 indexed label, bytes32 subnode);
    event ENSReverseRegistered(string name, bytes32 node, address owner);

    constructor(address _bridgeDataAddress, bytes32 _rootNode)
    {
        bridgeData = BridgeDataI(_bridgeDataAddress);
        require(address(bridgeData) != address(0x0), "You need to provide an actual bridge data contract.");
        rootNode = _rootNode;
    }

    modifier onlySubdomainControl()
    {
        require(msg.sender == bridgeData.getAddress("subdomainControl"), "subdomainControl key required for this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == bridgeData.getAddress("tokenAssignmentControl"), "tokenAssignmentControl key required for this function.");
        _;
    }

    /*** Enable adjusting variables after deployment ***/

    function setBridgeData(BridgeDataI _newBridgeData)
    external
    onlySubdomainControl
    {
        require(address(_newBridgeData) != address(0x0), "You need to provide an actual bridge data contract.");
        emit BridgeDataChanged(address(bridgeData), address(_newBridgeData));
        bridgeData = _newBridgeData;
    }

    /*** ERC165 ***/

    function supportsInterface(bytes4 interfaceId)
    public view override
    returns (bool)
    {
        return interfaceId == type(ENSAddrI).interfaceId ||
               interfaceId == type(ENSReverseI).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    /*** ENS registration ***/

    // Call this with the label of the subnode, which is keccak256(bytes(_name)),
    // and the target address it should point to (owner of the subnode).
    function registerAddr(bytes32 _label, address _target)
    external override
    {
        bytes32 lNode = keccak256(abi.encodePacked(rootNode, _label));

        if (msg.sender != bridgeData.getAddress("subdomainControl")) {
            require(msg.sender == _target && CollectionsI(bridgeData.getAddress("Collections")).collectionExists(msg.sender), "You cannot register this address.");
        }
        require(addr[lNode] == address(0), "Already registered.");

        addr[lNode] = _target;
        emit Registered(_label, lNode, _target);
    }

    // The subdomain controller can revert a name to unregistered.
    function unregister(bytes32 _label)
    external
    onlySubdomainControl
    {
        bytes32 lNode = keccak256(abi.encodePacked(rootNode, _label));
        require(addr[lNode] != address(0), "Not registered.");

        addr[lNode] = address(0);
        emit Unregistered(_label, lNode);
    }

    // The subdomain controller can block a name so nobody can actually use it.
    // This is done by registering the name a target address of 0x1.
    function blockRegistration(bytes32 _label)
    external
    onlySubdomainControl
    {
        bytes32 lNode = keccak256(abi.encodePacked(rootNode, _label));
        addr[lNode] = blockAddress;
        emit Blocked(_label, lNode);
    }

    /*** ENS reverse name registrar ***/

    function setName(string calldata _name)
    external override
    returns (bytes32)
    {
        bytes32 aNode = node(msg.sender);
        emit ENSReverseRegistered(_name, aNode, msg.sender);
        emit NameChanged(aNode, _name);
        name[aNode] = _name;
        return aNode;
    }

    // The subdomain controller can remove a registered name.
    function removeName(bytes32 _node)
    external
    onlySubdomainControl
    {
        require(bytes(name[_node]).length > 0, "Not registered.");

        name[_node] = "";
        emit NameChanged(_node, "");
    }

    function node(address _addr)
    public pure
    returns (bytes32) {
        bytes32 label = keccak256(abi.encodePacked(_addr));
        return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, label));
    }

    /*** Enable reverse ENS registration ***/

    // Call this with the address of the reverse registrar for the respecitve network and the ENS name to register.
    // The reverse registrar can be found as the owner of 'addr.reverse' in the ENS system.
    // See https://docs.ens.domains/ens-deployments for address of ENS deployments, e.g. Etherscan can be used to look up that owner on those.
    // namehash.hash("addr.reverse") == "0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2"
    // Ropsten: ens.owner(namehash.hash("addr.reverse")) == "0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c"
    // Mainnet: ens.owner(namehash.hash("addr.reverse")) == "0x084b1c3C81545d370f3634392De611CaaBFf8148"
    function registerReverseENS(address _reverseRegistrarAddress, string calldata _name)
    external
    onlySubdomainControl
    {
       require(_reverseRegistrarAddress != address(0), "need a valid reverse registrar");
       ENSReverseRegistrarI(_reverseRegistrarAddress).setName(_name);
    }

    /*** Make sure currency or NFT doesn't get stranded in this contract ***/

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueToken(address _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        IERC20 erc20Token = IERC20(_foreignToken);
        erc20Token.transfer(_to, erc20Token.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }

}