pragma solidity ^0.4.24;


/**
 * @title MerkleProof
 * @dev Merkle proof verification based on
 * https://github.com/ameensol/merkle-tree-solidity/blob/master/src/MerkleProof.sol
 */
library MerkleProof {
    /**
    * @dev Verifies a Merkle proof proving the existence of a leaf in a Merkle tree. Assumes that each pair of leaves
    * and each pair of pre-images are sorted.
    * @param _proof Merkle proof containing sibling hashes on the branch from the leaf to the root of the Merkle tree
    * @param _root Merkle root
    * @param _leaf Leaf of Merkle tree
    */
    function verifyProof(
        bytes32[] _proof,
        bytes32 _root,
        bytes32 _leaf
    )
        internal
        pure
        returns (bool)
    {
        bytes32 computedHash = _leaf;

        for (uint256 i = 0; i < _proof.length; i++) {
            bytes32 proofElement = _proof[i];

            if (computedHash < proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == _root;
    }
}

contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    address public controller;

    constructor() internal { 
        controller = msg.sender; 
    }

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}


// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

interface ERC20Token {

    /**
     * @notice send `_value` token to `_to` from `msg.sender`
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) external returns (bool success);

    /**
     * @notice `msg.sender` approves `_spender` to spend `_value` tokens
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) external returns (bool success);

    /**
     * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /**
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    /**
     * @notice return total supply of tokens
     */
    function totalSupply() external view returns (uint256 supply);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

interface ENS {

  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);


  function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
  function setResolver(bytes32 node, address resolver) public;
  function setOwner(bytes32 node, address owner) public;
  function setTTL(bytes32 node, uint64 ttl) public;
  function owner(bytes32 node) public view returns (address);
  function resolver(bytes32 node) public view returns (address);
  function ttl(bytes32 node) public view returns (uint64);

}


/**
 * A simple resolver anyone can use; only allows the owner of a node to set its
 * address.
 */
contract PublicResolver {

    bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant CONTENT_INTERFACE_ID = 0xd8389dc5;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;
    bytes4 constant ABI_INTERFACE_ID = 0x2203ab56;
    bytes4 constant PUBKEY_INTERFACE_ID = 0xc8690233;
    bytes4 constant TEXT_INTERFACE_ID = 0x59d1d43c;
    bytes4 constant MULTIHASH_INTERFACE_ID = 0xe89401a1;

    event AddrChanged(bytes32 indexed node, address a);
    event ContentChanged(bytes32 indexed node, bytes32 hash);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexedKey, string key);
    event MultihashChanged(bytes32 indexed node, bytes hash);

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    struct Record {
        address addr;
        bytes32 content;
        string name;
        PublicKey pubkey;
        mapping(string=>string) text;
        mapping(uint256=>bytes) abis;
        bytes multihash;
    }

    ENS ens;

    mapping (bytes32 => Record) records;

    modifier only_owner(bytes32 node) {
        require(ens.owner(node) == msg.sender);
        _;
    }

    /**
     * Constructor.
     * @param ensAddr The ENS registrar contract.
     */
    constructor(ENS ensAddr) public {
        ens = ensAddr;
    }

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param addr The address to set.
     */
    function setAddr(bytes32 node, address addr) public only_owner(node) {
        records[node].addr = addr;
        emit AddrChanged(node, addr);
    }

    /**
     * Sets the content hash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * Note that this resource type is not standardized, and will likely change
     * in future to a resource type based on multihash.
     * @param node The node to update.
     * @param hash The content hash to set
     */
    function setContent(bytes32 node, bytes32 hash) public only_owner(node) {
        records[node].content = hash;
        emit ContentChanged(node, hash);
    }

    /**
     * Sets the multihash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The multihash to set
     */
    function setMultihash(bytes32 node, bytes hash) public only_owner(node) {
        records[node].multihash = hash;
        emit MultihashChanged(node, hash);
    }
    
    /**
     * Sets the name associated with an ENS node, for reverse records.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param name The name to set.
     */
    function setName(bytes32 node, string name) public only_owner(node) {
        records[node].name = name;
        emit NameChanged(node, name);
    }

    /**
     * Sets the ABI associated with an ENS node.
     * Nodes may have one ABI of each content type. To remove an ABI, set it to
     * the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(bytes32 node, uint256 contentType, bytes data) public only_owner(node) {
        // Content types must be powers of 2
        require(((contentType - 1) & contentType) == 0);
        
        records[node].abis[contentType] = data;
        emit ABIChanged(node, contentType);
    }
    
    /**
     * Sets the SECP256k1 public key associated with an ENS node.
     * @param node The ENS node to query
     * @param x the X coordinate of the curve point for the public key.
     * @param y the Y coordinate of the curve point for the public key.
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) public only_owner(node) {
        records[node].pubkey = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(bytes32 node, string key, string value) public only_owner(node) {
        records[node].text[key] = value;
        emit TextChanged(node, key, key);
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string key) public view returns (string) {
        return records[node].text[key];
    }

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x, y the X and Y coordinates of the curve point for the public key.
     */
    function pubkey(bytes32 node) public view returns (bytes32 x, bytes32 y) {
        return (records[node].pubkey.x, records[node].pubkey.y);
    }

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) public view returns (uint256 contentType, bytes data) {
        Record storage record = records[node];
        for (contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && record.abis[contentType].length > 0) {
                data = record.abis[contentType];
                return;
            }
        }
        contentType = 0;
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) public view returns (string) {
        return records[node].name;
    }

    /**
     * Returns the content hash associated with an ENS node.
     * Note that this resource type is not standardized, and will likely change
     * in future to a resource type based on multihash.
     * @param node The ENS node to query.
     * @return The associated content hash.
     */
    function content(bytes32 node) public view returns (bytes32) {
        return records[node].content;
    }

    /**
     * Returns the multihash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated multihash.
     */
    function multihash(bytes32 node) public view returns (bytes) {
        return records[node].multihash;
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view returns (address) {
        return records[node].addr;
    }

    /**
     * Returns true if the resolver implements the interface specified by the provided hash.
     * @param interfaceID The ID of the interface to check for.
     * @return True if the contract implements the requested interface.
     */
    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == ADDR_INTERFACE_ID ||
        interfaceID == CONTENT_INTERFACE_ID ||
        interfaceID == NAME_INTERFACE_ID ||
        interfaceID == ABI_INTERFACE_ID ||
        interfaceID == PUBKEY_INTERFACE_ID ||
        interfaceID == TEXT_INTERFACE_ID ||
        interfaceID == MULTIHASH_INTERFACE_ID ||
        interfaceID == INTERFACE_META_ID;
    }
}


/** 
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH) 
 * @notice Registers usernames as ENS subnodes of the domain `ensNode`
 */
contract UsernameRegistrar is Controlled, ApproveAndCallFallBack {
    
    ERC20Token public token;
    ENS public ensRegistry;
    PublicResolver public resolver;
    address public parentRegistry;

    uint256 public constant releaseDelay = 365 days;
    mapping (bytes32 => Account) public accounts;
    mapping (bytes32 => SlashReserve) reservedSlashers;

    //Slashing conditions
    uint256 public usernameMinLength;
    bytes32 public reservedUsernamesMerkleRoot;
    
    event RegistryState(RegistrarState state);
    event RegistryPrice(uint256 price);
    event RegistryMoved(address newRegistry);
    event UsernameOwner(bytes32 indexed nameHash, address owner);

    enum RegistrarState { Inactive, Active, Moved }
    bytes32 public ensNode;
    uint256 public price;
    RegistrarState public state;
    uint256 public reserveAmount;

    struct Account {
        uint256 balance;
        uint256 creationTime;
        address owner;
    }

    struct SlashReserve {
        address reserver;
        uint256 blockNumber;
    }

    /**
     * @notice Callable only by `parentRegistry()` to continue migration of ENSSubdomainRegistry.
     */
    modifier onlyParentRegistry {
        require(msg.sender == parentRegistry, "Migration only.");
        _;
    }

    /** 
     * @notice Initializes UsernameRegistrar contract. 
     * The only parameter from this list that can be changed later is `_resolver`.
     * Other updates require a new contract and migration of domain.
     * @param _token ERC20 token with optional `approveAndCall(address,uint256,bytes)` for locking fee.
     * @param _ensRegistry Ethereum Name Service root contract address.
     * @param _resolver Public Resolver for resolving usernames.
     * @param _ensNode ENS node (domain) being used for usernames subnodes (subdomain)
     * @param _usernameMinLength Minimum length of usernames 
     * @param _reservedUsernamesMerkleRoot Merkle root of reserved usernames
     * @param _parentRegistry Address of old registry (if any) for optional account migration.
     */
    constructor(
        ERC20Token _token,
        ENS _ensRegistry,
        PublicResolver _resolver,
        bytes32 _ensNode,
        uint256 _usernameMinLength,
        bytes32 _reservedUsernamesMerkleRoot,
        address _parentRegistry
    ) 
        public 
    {
        require(address(_token) != address(0), "No ERC20Token address defined.");
        require(address(_ensRegistry) != address(0), "No ENS address defined.");
        require(address(_resolver) != address(0), "No Resolver address defined.");
        require(_ensNode != bytes32(0), "No ENS node defined.");
        token = _token;
        ensRegistry = _ensRegistry;
        resolver = _resolver;
        ensNode = _ensNode;
        usernameMinLength = _usernameMinLength;
        reservedUsernamesMerkleRoot = _reservedUsernamesMerkleRoot;
        parentRegistry = _parentRegistry;
        setState(RegistrarState.Inactive);
    }

    /**
     * @notice Registers `_label` username to `ensNode` setting msg.sender as owner.
     * Terms of name registration:
     * - SNT is deposited, not spent; the amount is locked up for 1 year.
     * - After 1 year, the user can release the name and receive their deposit back (at any time).
     * - User deposits are completely protected. The contract controller cannot access them.
     * - User&#39;s address(es) will be publicly associated with the ENS name.
     * - User must authorise the contract to transfer `price` `token.name()`  on their behalf.
     * - Usernames registered with less then `usernameMinLength` characters can be slashed.
     * - Usernames contained in the merkle tree of root `reservedUsernamesMerkleRoot` can be slashed.
     * - Usernames starting with `0x` and bigger then 12 characters can be slashed.
     * - If terms of the contract change—e.g. Status makes contract upgrades—the user has the right to release the username and get their deposit back.
     * @param _label Choosen unowned username hash.
     * @param _account Optional address to set at public resolver.
     * @param _pubkeyA Optional pubkey part A to set at public resolver.
     * @param _pubkeyB Optional pubkey part B to set at public resolver.
     */
    function register(
        bytes32 _label,
        address _account,
        bytes32 _pubkeyA,
        bytes32 _pubkeyB
    ) 
        external 
        returns(bytes32 namehash) 
    {
        return registerUser(msg.sender, _label, _account, _pubkeyA, _pubkeyB);
    }
    
    /** 
     * @notice Release username and retrieve locked fee, needs to be called 
     * after `releasePeriod` from creation time by ENS registry owner of domain 
     * or anytime by account owner when domain migrated to a new registry.
     * @param _label Username hash.
     */
    function release(
        bytes32 _label
    )
        external 
    {
        bytes32 namehash = keccak256(abi.encodePacked(ensNode, _label));
        Account memory account = accounts[_label];
        require(account.creationTime > 0, "Username not registered.");
        if (state == RegistrarState.Active) {
            require(msg.sender == ensRegistry.owner(namehash), "Not owner of ENS node.");
            require(block.timestamp > account.creationTime + releaseDelay, "Release period not reached.");
        } else {
            require(msg.sender == account.owner, "Not the former account owner.");
        }
        delete accounts[_label];
        if (account.balance > 0) {
            reserveAmount -= account.balance;
            require(token.transfer(msg.sender, account.balance), "Transfer failed");
        }
        if (state == RegistrarState.Active) {
            ensRegistry.setSubnodeOwner(ensNode, _label, address(this));
            ensRegistry.setResolver(namehash, address(0));
            ensRegistry.setOwner(namehash, address(0));
        } else {
            address newOwner = ensRegistry.owner(ensNode);
            //Low level call, case dropUsername not implemented or failing, proceed release. 
            //Invert (!) to supress warning, return of this call have no use.
            !newOwner.call.gas(80000)(
                abi.encodeWithSignature(
                    "dropUsername(bytes32)",
                    _label
                )
            );
        }
        emit UsernameOwner(namehash, address(0));   
    }

    /** 
     * @notice update account owner, should be called by new ens node owner 
     * to update this contract registry, otherwise former owner can release 
     * if domain is moved to a new registry. 
     * @param _label Username hash.
     **/
    function updateAccountOwner(
        bytes32 _label
    ) 
        external 
    {
        bytes32 namehash = keccak256(abi.encodePacked(ensNode, _label));
        require(msg.sender == ensRegistry.owner(namehash), "Caller not owner of ENS node.");
        require(accounts[_label].creationTime > 0, "Username not registered.");
        require(ensRegistry.owner(ensNode) == address(this), "Registry not owner of registry.");
        accounts[_label].owner = msg.sender;
        emit UsernameOwner(namehash, msg.sender);
    }  

    /**
     * @notice secretly reserve the slashing reward to `msg.sender`
     * @param _secret keccak256(abi.encodePacked(namehash, creationTime, reserveSecret)) 
     */
    function reserveSlash(bytes32 _secret) external {
        require(reservedSlashers[_secret].blockNumber == 0, "Already Reserved");
        reservedSlashers[_secret] = SlashReserve(msg.sender, block.number);
    }

    /**
     * @notice Slash username smaller then `usernameMinLength`.
     * @param _username Raw value of offending username.
     */
    function slashSmallUsername(
        string _username,
        uint256 _reserveSecret
    ) 
        external 
    {
        bytes memory username = bytes(_username);
        require(username.length < usernameMinLength, "Not a small username.");
        slashUsername(username, _reserveSecret);
    }

    /**
     * @notice Slash username starting with "0x" and with length greater than 12.
     * @param _username Raw value of offending username.
     */
    function slashAddressLikeUsername(
        string _username,
        uint256 _reserveSecret
    ) 
        external 
    {
        bytes memory username = bytes(_username);
        require(username.length > 12, "Too small to look like an address.");
        require(username[0] == byte("0"), "First character need to be 0");
        require(username[1] == byte("x"), "Second character need to be x");
        for(uint i = 2; i < 7; i++){
            byte b = username[i];
            require((b >= 48 && b <= 57) || (b >= 97 && b <= 102), "Does not look like an address");
        }
        slashUsername(username, _reserveSecret);
    }  

    /**
     * @notice Slash username that is exactly a reserved name.
     * @param _username Raw value of offending username.
     * @param _proof Merkle proof that name is listed on merkle tree.
     */
    function slashReservedUsername(
        string _username,
        bytes32[] _proof,
        uint256 _reserveSecret
    ) 
        external 
    {   
        bytes memory username = bytes(_username);
        require(
            MerkleProof.verifyProof(
                _proof,
                reservedUsernamesMerkleRoot,
                keccak256(username)
            ),
            "Invalid Proof."
        );
        slashUsername(username, _reserveSecret);
    }

    /**
     * @notice Slash username that contains a non alphanumeric character.
     * @param _username Raw value of offending username.
     * @param _offendingPos Position of non alphanumeric character.
     */
    function slashInvalidUsername(
        string _username,
        uint256 _offendingPos,
        uint256 _reserveSecret
    ) 
        external
    { 
        bytes memory username = bytes(_username);
        require(username.length > _offendingPos, "Invalid position.");
        byte b = username[_offendingPos];
        
        require(!((b >= 48 && b <= 57) || (b >= 97 && b <= 122)), "Not invalid character.");
    
        slashUsername(username, _reserveSecret);
    }

    /**
     * @notice Clear resolver and ownership of unowned subdomians.
     * @param _labels Sequence to erase.
     */
    function eraseNode(
        bytes32[] _labels
    ) 
        external 
    {
        uint len = _labels.length;
        require(len != 0, "Nothing to erase");
        bytes32 label = _labels[len - 1];
        bytes32 subnode = keccak256(abi.encodePacked(ensNode, label));
        require(ensRegistry.owner(subnode) == address(0), "First slash/release top level subdomain");
        ensRegistry.setSubnodeOwner(ensNode, label, address(this));
        if(len > 1) {
            eraseNodeHierarchy(len - 2, _labels, subnode);
        }
        ensRegistry.setResolver(subnode, 0);
        ensRegistry.setOwner(subnode, 0);
    }

    /**
     * @notice Migrate account to new registry, opt-in to new contract.
     * @param _label Username hash.
     **/
    function moveAccount(
        bytes32 _label,
        UsernameRegistrar _newRegistry
    ) 
        external 
    {
        require(state == RegistrarState.Moved, "Wrong contract state");
        require(msg.sender == accounts[_label].owner, "Callable only by account owner.");
        require(ensRegistry.owner(ensNode) == address(_newRegistry), "Wrong update");
        Account memory account = accounts[_label];
        delete accounts[_label];

        token.approve(_newRegistry, account.balance);
        _newRegistry.migrateUsername(
            _label,
            account.balance,
            account.creationTime,
            account.owner
        );
    }

    /** 
     * @notice Activate registration.
     * @param _price The price of registration.
     */
    function activate(
        uint256 _price
    ) 
        external
        onlyController
    {
        require(state == RegistrarState.Inactive, "Registry state is not Inactive");
        require(ensRegistry.owner(ensNode) == address(this), "Registry does not own registry");
        price = _price;
        setState(RegistrarState.Active);
        emit RegistryPrice(_price);
    }

    /** 
     * @notice Updates Public Resolver for resolving users.
     * @param _resolver New PublicResolver.
     */
    function setResolver(
        address _resolver
    ) 
        external
        onlyController
    {
        resolver = PublicResolver(_resolver);
    }

    /**
     * @notice Updates registration price.
     * @param _price New registration price.
     */
    function updateRegistryPrice(
        uint256 _price
    ) 
        external
        onlyController
    {
        require(state == RegistrarState.Active, "Registry not owned");
        price = _price;
        emit RegistryPrice(_price);
    }
  
    /**
     * @notice Transfer ownership of ensNode to `_newRegistry`.
     * Usernames registered are not affected, but they would be able to instantly release.
     * @param _newRegistry New UsernameRegistrar for hodling `ensNode` node.
     */
    function moveRegistry(
        UsernameRegistrar _newRegistry
    ) 
        external
        onlyController
    {
        require(_newRegistry != this, "Cannot move to self.");
        require(ensRegistry.owner(ensNode) == address(this), "Registry not owned anymore.");
        setState(RegistrarState.Moved);
        ensRegistry.setOwner(ensNode, _newRegistry);
        _newRegistry.migrateRegistry(price);
        emit RegistryMoved(_newRegistry);
    }

    /** 
     * @notice Opt-out migration of username from `parentRegistry()`.
     * Clear ENS resolver and subnode owner.
     * @param _label Username hash.
     */
    function dropUsername(
        bytes32 _label
    ) 
        external 
        onlyParentRegistry
    {
        require(accounts[_label].creationTime == 0, "Already migrated");
        bytes32 namehash = keccak256(abi.encodePacked(ensNode, _label));
        ensRegistry.setSubnodeOwner(ensNode, _label, address(this));
        ensRegistry.setResolver(namehash, address(0));
        ensRegistry.setOwner(namehash, address(0));
    }

    /**
     * @notice Withdraw not reserved tokens
     * @param _token Address of ERC20 withdrawing excess, or address(0) if want ETH.
     * @param _beneficiary Address to send the funds.
     **/
    function withdrawExcessBalance(
        address _token,
        address _beneficiary
    )
        external 
        onlyController 
    {
        require(_beneficiary != address(0), "Cannot burn token");
        if (_token == address(0)) {
            _beneficiary.transfer(address(this).balance);
        } else {
            ERC20Token excessToken = ERC20Token(_token);
            uint256 amount = excessToken.balanceOf(address(this));
            if(_token == address(token)){
                require(amount > reserveAmount, "Is not excess");
                amount -= reserveAmount;
            } else {
                require(amount > 0, "No balance");
            }
            excessToken.transfer(_beneficiary, amount);
        }
    }

    /**
     * @notice Withdraw ens nodes not belonging to this contract.
     * @param _domainHash Ens node namehash.
     * @param _beneficiary New owner of ens node.
     **/
    function withdrawWrongNode(
        bytes32 _domainHash,
        address _beneficiary
    ) 
        external
        onlyController
    {
        require(_beneficiary != address(0), "Cannot burn node");
        require(_domainHash != ensNode, "Cannot withdraw main node");   
        require(ensRegistry.owner(_domainHash) == address(this), "Not owner of this node");   
        ensRegistry.setOwner(_domainHash, _beneficiary);
    }

    /**
     * @notice Gets registration price.
     * @return Registration price.
     **/
    function getPrice() 
        external 
        view 
        returns(uint256 registryPrice) 
    {
        return price;
    }
    
    /**
     * @notice reads amount tokens locked in username 
     * @param _label Username hash.
     * @return Locked username balance.
     **/
    function getAccountBalance(bytes32 _label)
        external
        view
        returns(uint256 accountBalance) 
    {
        accountBalance = accounts[_label].balance;
    }

    /**
     * @notice reads username account owner at this contract, 
     * which can release or migrate in case of upgrade.
     * @param _label Username hash.
     * @return Username account owner.
     **/
    function getAccountOwner(bytes32 _label)
        external
        view
        returns(address owner) 
    {
        owner = accounts[_label].owner;
    }

    /**
     * @notice reads when the account was registered 
     * @param _label Username hash.
     * @return Registration time.
     **/
    function getCreationTime(bytes32 _label)
        external
        view
        returns(uint256 creationTime) 
    {
        creationTime = accounts[_label].creationTime;
    }

    /**
     * @notice calculate time where username can be released 
     * @param _label Username hash.
     * @return Exact time when username can be released.
     **/
    function getExpirationTime(bytes32 _label)
        external
        view
        returns(uint256 releaseTime)
    {
        uint256 creationTime = accounts[_label].creationTime;
        if (creationTime > 0){
            releaseTime = creationTime + releaseDelay;
        }
    }

    /**
     * @notice calculate reward part an account could payout on slash 
     * @param _label Username hash.
     * @return Part of reward
     **/
    function getSlashRewardPart(bytes32 _label)
        external
        view
        returns(uint256 partReward)
    {
        uint256 balance = accounts[_label].balance;
        if (balance > 0) {
            partReward = balance / 3;
        }
    }

    /**
     * @notice Support for "approveAndCall". Callable only by `token()`.  
     * @param _from Who approved.
     * @param _amount Amount being approved, need to be equal `getPrice()`.
     * @param _token Token being approved, need to be equal `token()`.
     * @param _data Abi encoded data with selector of `register(bytes32,address,bytes32,bytes32)`.
     */
    function receiveApproval(
        address _from,
        uint256 _amount,
        address _token,
        bytes _data
    ) 
        public
    {
        require(_amount == price, "Wrong value");
        require(_token == address(token), "Wrong token");
        require(_token == address(msg.sender), "Wrong call");
        require(_data.length <= 132, "Wrong data length");
        bytes4 sig;
        bytes32 label;
        address account;
        bytes32 pubkeyA;
        bytes32 pubkeyB;
        (sig, label, account, pubkeyA, pubkeyB) = abiDecodeRegister(_data);
        require(
            sig == bytes4(0xb82fedbb), //bytes4(keccak256("register(bytes32,address,bytes32,bytes32)"))
            "Wrong method selector"
        );
        registerUser(_from, label, account, pubkeyA, pubkeyB);
    }
   
    /**
     * @notice Continues migration of username to new registry.
     * @param _label Username hash.
     * @param _tokenBalance Amount being transfered from `parentRegistry()`.
     * @param _creationTime Time user registrated in `parentRegistry()` is preserved. 
     * @param _accountOwner Account owner which migrated the account.
     **/
    function migrateUsername(
        bytes32 _label,
        uint256 _tokenBalance,
        uint256 _creationTime,
        address _accountOwner
    )
        external
        onlyParentRegistry
    {
        if (_tokenBalance > 0) {
            require(
                token.transferFrom(
                    parentRegistry,
                    address(this),
                    _tokenBalance
                ), 
                "Error moving funds from old registar."
            );
            reserveAmount += _tokenBalance;
        }
        accounts[_label] = Account(_tokenBalance, _creationTime, _accountOwner);
    }

    /**
     * @dev callable only by parent registry to continue migration
     * of registry and activate registration.
     * @param _price The price of registration.
     **/
    function migrateRegistry(
        uint256 _price
    ) 
        external
        onlyParentRegistry
    {
        require(state == RegistrarState.Inactive, "Not Inactive");
        require(ensRegistry.owner(ensNode) == address(this), "ENS registry owner not transfered.");
        price = _price;
        setState(RegistrarState.Active);
        emit RegistryPrice(_price);
    }

    /**
     * @notice Registers `_label` username to `ensNode` setting msg.sender as owner.
     * @param _owner Address registering the user and paying registry price.
     * @param _label Choosen unowned username hash.
     * @param _account Optional address to set at public resolver.
     * @param _pubkeyA Optional pubkey part A to set at public resolver.
     * @param _pubkeyB Optional pubkey part B to set at public resolver.
     */
    function registerUser(
        address _owner,
        bytes32 _label,
        address _account,
        bytes32 _pubkeyA,
        bytes32 _pubkeyB
    ) 
        internal 
        returns(bytes32 namehash)
    {
        require(state == RegistrarState.Active, "Registry unavailable.");
        namehash = keccak256(abi.encodePacked(ensNode, _label));
        require(ensRegistry.owner(namehash) == address(0), "ENS node already owned.");
        require(accounts[_label].creationTime == 0, "Username already registered.");
        accounts[_label] = Account(price, block.timestamp, _owner);
        if(price > 0) {
            require(token.allowance(_owner, address(this)) >= price, "Unallowed to spend.");
            require(
                token.transferFrom(
                    _owner,
                    address(this),
                    price
                ),
                "Transfer failed"
            );
            reserveAmount += price;
        } 
    
        bool resolvePubkey = _pubkeyA != 0 || _pubkeyB != 0;
        bool resolveAccount = _account != address(0);
        if (resolvePubkey || resolveAccount) {
            //set to self the ownership to setup initial resolver
            ensRegistry.setSubnodeOwner(ensNode, _label, address(this));
            ensRegistry.setResolver(namehash, resolver); //default resolver
            if (resolveAccount) {
                resolver.setAddr(namehash, _account);
            }
            if (resolvePubkey) {
                resolver.setPubkey(namehash, _pubkeyA, _pubkeyB);
            }
            ensRegistry.setOwner(namehash, _owner);
        } else {
            //transfer ownership of subdone directly to registrant
            ensRegistry.setSubnodeOwner(ensNode, _label, _owner);
        }
        emit UsernameOwner(namehash, _owner);
    }
    
    /**
     * @dev Removes account hash of `_username` and send account.balance to msg.sender.
     * @param _username Username being slashed.
     */
    function slashUsername(
        bytes _username,
        uint256 _reserveSecret
    ) 
        internal 
    {
        bytes32 label = keccak256(_username);
        bytes32 namehash = keccak256(abi.encodePacked(ensNode, label));
        uint256 amountToTransfer = 0;
        uint256 creationTime = accounts[label].creationTime;
        address owner = ensRegistry.owner(namehash);
        if(creationTime == 0) {
            require(
                owner != address(0) ||
                ensRegistry.resolver(namehash) != address(0),
                "Nothing to slash."
            );
        } else {
            assert(creationTime != block.timestamp);
            amountToTransfer = accounts[label].balance;
            delete accounts[label];
        }

        ensRegistry.setSubnodeOwner(ensNode, label, address(this));
        ensRegistry.setResolver(namehash, address(0));
        ensRegistry.setOwner(namehash, address(0));
        
        if (amountToTransfer > 0) {
            reserveAmount -= amountToTransfer;
            uint256 partialDeposit = amountToTransfer / 3;
            amountToTransfer = partialDeposit * 2; // reserve 1/3 to network (controller)
            bytes32 secret = keccak256(abi.encodePacked(namehash, creationTime, _reserveSecret));
            SlashReserve memory reserve = reservedSlashers[secret];
            require(reserve.reserver != address(0), "Not reserved.");
            require(reserve.blockNumber < block.number, "Cannot reveal in same block");
            delete reservedSlashers[secret];

            require(token.transfer(reserve.reserver, amountToTransfer), "Error in transfer.");
        }
        emit UsernameOwner(namehash, address(0));
    }

    function setState(RegistrarState _state) private {
        state = _state;
        emit RegistryState(_state);
    }

    /**
     * @notice recursively erase all _labels in _subnode
     * @param _idx recursive position of _labels to erase
     * @param _labels list of subnode labes
     * @param _subnode subnode being erased
     */
    function eraseNodeHierarchy(
        uint _idx,
        bytes32[] _labels,
        bytes32 _subnode
    ) 
        private 
    {
        // Take ownership of the node
        ensRegistry.setSubnodeOwner(_subnode, _labels[_idx], address(this));
        bytes32 subnode = keccak256(abi.encodePacked(_subnode, _labels[_idx]));

        // Recurse if there are more labels
        if (_idx > 0) {
            eraseNodeHierarchy(_idx - 1, _labels, subnode);
        }

        // Erase the resolver and owner records
        ensRegistry.setResolver(subnode, 0);
        ensRegistry.setOwner(subnode, 0);
    }

    /**
     * @dev Decodes abi encoded data with selector for "register(bytes32,address,bytes32,bytes32)".
     * @param _data Abi encoded data.
     * @return Decoded registry call.
     */
    function abiDecodeRegister(
        bytes _data
    ) 
        private 
        pure 
        returns(
            bytes4 sig,
            bytes32 label,
            address account,
            bytes32 pubkeyA,
            bytes32 pubkeyB
        )
    {
        assembly {
            sig := mload(add(_data, add(0x20, 0)))
            label := mload(add(_data, 36))
            account := mload(add(_data, 68))
            pubkeyA := mload(add(_data, 100))
            pubkeyB := mload(add(_data, 132))
        }
    }
}