pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

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

pragma solidity ^0.4.23;

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
pragma solidity ^0.4.21;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    function setOwner(bytes32 _node, address _owner) external;
    function setSubnodeOwner(bytes32 _node, bytes32 _label, address _owner) external;
    function setResolver(bytes32 _node, address _resolver) external;
    function setTTL(bytes32 _node, uint64 _ttl) external;
    function owner(bytes32 _node) external view returns (address);
    function resolver(bytes32 _node) external view returns (address);
    function ttl(bytes32 _node) external view returns (uint64);
}

pragma solidity ^0.4.23;

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

    event AddrChanged(bytes32 indexed node, address a);
    event ContentChanged(bytes32 indexed node, bytes32 hash);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexedKey, string key);

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
        interfaceID == INTERFACE_META_ID;
    }
}



/** 
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH) 
 * @notice Sell ENS subdomains of owned domains.
 */
contract ENSSubdomainRegistry is Controlled {
    
    ERC20Token public token;
    ENS public ens;
    PublicResolver public resolver;
    address public parentRegistry;

    uint256 public releaseDelay = 1 years;
    mapping (bytes32 => Domain) public domains;
    mapping (bytes32 => Account) public accounts;
    
    event FundsOwner(bytes32 indexed subdomainhash, address fundsOwner);
    event DomainPrice(bytes32 indexed namehash, uint256 price);
    event DomainMoved(bytes32 indexed namehash, address newRegistry);

    enum NodeState { Free, Owned, Moved }
    struct Domain {
        NodeState state;
        uint256 price;
    }

    struct Account {
        uint256 tokenBalance;
        uint256 creationTime;
        address fundsOwner;
    }

    modifier onlyParentRegistry {
        require(msg.sender == parentRegistry);
        _;
    }

    /** 
     * @notice Initializes a UserRegistry contract 
     * @param _token fee token base 
     * @param _ens Ethereum Name Service root address 
     * @param _resolver Default resolver to use in initial settings
     * @param _parentRegistry Address of old registry (if any) for account migration.
     */
    constructor(
        ERC20Token _token,
        ENS _ens,
        PublicResolver _resolver,
        address _parentRegistry
    ) 
        public 
    {
        token = _token;
        ens = _ens;
        resolver = _resolver;
        parentRegistry = _parentRegistry;
    }

    /**
     * @notice Registers `_userHash` subdomain to `_domainHash` setting msg.sender as owner.
     * @param _userHash choosen unowned subdomain hash 
     * @param _domainHash choosen contract owned domain hash
     * @param _account optional address to set at public resolver
     * @param _pubkeyA optional pubkey part A to set at public resolver
     * @param _pubkeyB optional pubkey part B to set at public resolver
     */
    function register(
        bytes32 _userHash,
        bytes32 _domainHash,
        address _account,
        bytes32 _pubkeyA,
        bytes32 _pubkeyB
    ) 
        external 
        returns(bytes32 subdomainHash) 
    {
        Domain memory domain = domains[_domainHash];
        require(domain.state == NodeState.Owned);
        subdomainHash = keccak256(_domainHash, _userHash);
        require(ens.owner(subdomainHash) == address(0));
        require(accounts[subdomainHash].creationTime == 0);
        accounts[subdomainHash] = Account(domain.price, block.timestamp, msg.sender);
        require(domain.price == 0 || token.allowance(msg.sender, address(this)) >= domain.price);
        
        bool resolvePubkey = _pubkeyA != 0 || _pubkeyB != 0;
        bool resolveAccount = _account != address(0);
        if (resolvePubkey || resolveAccount) {
            //set to self the ownship to setup initial resolver
            ens.setSubnodeOwner(_domainHash, _userHash, address(this));
            ens.setResolver(subdomainHash, resolver); //default resolver
            if (resolveAccount) {
                resolver.setAddr(subdomainHash, _account);
            }
            if (resolvePubkey) {
                resolver.setPubkey(subdomainHash, _pubkeyA, _pubkeyB);
            }
            ens.setOwner(subdomainHash, msg.sender);
        }else {
            //transfer ownship of subdone to registrant
            ens.setSubnodeOwner(_domainHash, _userHash, msg.sender);
        }
        if (domain.price > 0) {   
            //get payment
            require(
                token.transferFrom(
                    address(msg.sender),
                    address(this),
                    domain.price
                )
            );
        }
    }
    
    /** 
     * @notice release subdomain and retrieve locked fee, needs to be called after `releasePeriod` from creation time.
     * @param _userHash `msg.sender` owned subdomain hash 
     * @param _domainHash choosen contract owned domain hash
     */
    function release(
        bytes32 _userHash,
        bytes32 _domainHash
    )
        external 
    {
        bool isDomainController = ens.owner(_domainHash) == address(this);
        bytes32 subdomainHash = keccak256(_domainHash, _userHash);
        Account memory account = accounts[subdomainHash];
        require(account.creationTime > 0);
        if (isDomainController) {
            require(msg.sender == ens.owner(subdomainHash));
            require(account.creationTime + releaseDelay >= block.timestamp);
            ens.setSubnodeOwner(_domainHash, _userHash, address(this));
            ens.setResolver(subdomainHash, address(0));
            ens.setOwner(subdomainHash, address(0));
        } else {
            require(msg.sender == account.fundsOwner);
        }
        delete accounts[subdomainHash];
        if (account.tokenBalance > 0) {
            require(token.transfer(msg.sender, account.tokenBalance));
        }
        
    }

    /** 
     * @notice updates funds owner useful to move subdomain account to new registry.
     * @param _userHash `msg.sender` owned subdomain hash 
     * @param _domainHash choosen contract owned domain hash
     **/
    function updateFundsOwner(
        bytes32 _userHash,
        bytes32 _domainHash
    ) 
        external 
    {
        bytes32 subdomainHash = keccak256(_domainHash, _userHash);
        require(accounts[subdomainHash].creationTime > 0);
        require(msg.sender == ens.owner(subdomainHash));
        require(ens.owner(_domainHash) == address(this));
        accounts[subdomainHash].fundsOwner = msg.sender;
        emit FundsOwner(subdomainHash, msg.sender);

    }    

    /**
     * @notice Migrate account to new registry
     * @param _userHash `msg.sender` owned subdomain hash 
     * @param _domainHash choosen contract owned domain hash
     **/
    function moveAccount(
        bytes32 _userHash,
        bytes32 _domainHash
    ) 
        external 
    {
        bytes32 subdomainHash = keccak256(_domainHash, _userHash);
        require(msg.sender == accounts[subdomainHash].fundsOwner);
        ENSSubdomainRegistry _newRegistry = ENSSubdomainRegistry(ens.owner(_domainHash));
        Account memory account = accounts[subdomainHash];
        delete accounts[subdomainHash];
        require(address(this) == _newRegistry.parentRegistry()); 
        token.approve(_newRegistry, account.tokenBalance);
        _newRegistry.migrateAccount(_userHash, _domainHash, account.tokenBalance, account.creationTime, account.fundsOwner);
    }
    
    /**
        @dev callabe only by parent registry to continue migration of domain
     */
    function migrateDomain(
        bytes32 _domain,
        uint256 _price
    ) 
        external
        onlyParentRegistry
    {
        require(domains[_domain].state == NodeState.Free);
        require(ens.owner(_domain) == address(this));
        domains[_domain] = Domain(NodeState.Owned, _price);
    }
    /**
     * @dev callable only by parent registry for continue user opt-in migration
     * @param _userHash any subdomain hash coming from parent
     * @param _domainHash choosen contract owned domain hash
     * @param _tokenBalance amount being transferred
     * @param _creationTime any value coming from parent
     * @param _fundsOwner fundsOwner for opt-out/release at domain move
     **/
    function migrateAccount(
        bytes32 _userHash,
        bytes32 _domainHash,
        uint256 _tokenBalance,
        uint256 _creationTime,
        address _fundsOwner
    )
        external
        onlyParentRegistry
    {
        bytes32 subdomainHash = keccak256(_domainHash, _userHash);
        accounts[subdomainHash] = Account(_tokenBalance, _creationTime, _fundsOwner);
        if (_tokenBalance > 0) {
            require(token.transferFrom(parentRegistry, address(this), _tokenBalance));
        }
        
    }
     
    /**
     * @notice moves a domain to other Registry (will not move subdomains accounts)
     * @param _newRegistry new registry hodling this domain
     * @param _domain domain being moved
     */
    function moveDomain(
        ENSSubdomainRegistry _newRegistry,
        bytes32 _domain
    ) 
        external
        onlyController
    {
        require(ens.owner(_domain) == address(this));
        require(domains[_domain].state == NodeState.Owned);
        uint256 price = domains[_domain].price;
        domains[_domain].state = NodeState.Moved;
        ens.setOwner(_domain, _newRegistry);
        _newRegistry.migrateDomain(_domain, price);
        emit DomainMoved(_domain, _newRegistry);
    }
       
    /** 
     * @notice Controller include new domain available to register
     * @param _domain domain owned by user registry being activated
     * @param _price cost to register subnode from this node
     */
    function setDomainPrice(
        bytes32 _domain,
        uint256 _price
    ) 
        external
        onlyController
    {
        require(domains[_domain].state == NodeState.Free, "Domain state is not free");
        require(ens.owner(_domain) == address(this), "Registry does not own domain");
        domains[_domain] = Domain(NodeState.Owned, _price);
        emit DomainPrice(_domain, _price);
    }

    /**
     * @notice updates domain price
     * @param _domain active domain being defined price
     * @param _price new price
     */
    function updateDomainPrice(
        bytes32 _domain,
        uint256 _price
    ) 
        external
        onlyController
    {
        Domain storage domain = domains[_domain];
        require(domain.state == NodeState.Owned);
        domain.price = _price;
        emit DomainPrice(_domain, _price);
    }

    /** 
     * @notice updates default public resolver for newly registred subdomains
     * @param _resolver new default resolver  
     */
    function setResolver(
        address _resolver
    ) 
        external
        onlyController
    {
        resolver = PublicResolver(_resolver);
    }

    function getPrice(bytes32 _domainHash) 
        external 
        view 
        returns(uint256 subdomainPrice) 
    {
        subdomainPrice = domains[_domainHash].price;
    }

    function getAccountBalance(bytes32 _subdomainHash)
        external
        view
        returns(uint256 accountBalance) 
    {
        accountBalance = accounts[_subdomainHash].tokenBalance;
    }

    function getFundsOwner(bytes32 _subdomainHash)
        external
        view
        returns(address fundsOwner) 
    {
        fundsOwner = accounts[_subdomainHash].fundsOwner;
    }

    function getCreationTime(bytes32 _subdomainHash)
        external
        view
        returns(uint256 creationTime) 
    {
        creationTime = accounts[_subdomainHash].creationTime;
    }

    function getExpirationTime(bytes32 _subdomainHash)
      external
      view
      returns(uint256 expirationTime)
    {
      expirationTime = accounts[_subdomainHash].creationTime + releaseDelay;
    }

}