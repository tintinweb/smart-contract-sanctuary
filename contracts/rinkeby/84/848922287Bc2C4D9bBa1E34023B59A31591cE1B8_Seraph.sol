// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}. EDIT: Not on this implementation
 * the {_transferOwnership} method must be called during the initialization of
 * the contract.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 *
 * The {renounceOwnership} method has been disabled for security purposes on Seraph
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        revert("Ownable: Renounce ownership not allowed");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @author Halborn
 * @notice Seraph storage
 * @dev This contract will be used to keep track of the storage layout when dealing with proxies
 * on Seraph. Any new storage variable should be added at the end of this contract, extending
 * the storage, and solving storage collision as detailed in
 * https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies#storage-collisions-between-implementation-versions
 *
 */
contract SeraphStorage {

    /// @notice State machine status used for each call permit
    /// NotExists -> Permit does not exist
    /// PermitCreated -> When the permit is created (aka signed)
    /// PermitSigned -> When all the peers have signed the permit. If no peers are required for the
    /// function, this is the default state for newly created call permits
    /// HalbornApproved -> Halborn has approved the permit
    /// Executed -> Permit successfully triggered
    /// PermitRejected -> A peer did reject
    /// HalbornRejected -> Halborn did reject the permit
    enum PermitStage {
        NotExists,
        PermitCreated,
        PermitSigned,
        HalbornApproved,
        Executed,
        PermitRejected,
        HalbornRejected
    }

    /// @notice Valid peer voting states
    /// NotAllowed -> The peer is not allowed to vote for this permit
    /// Allowed -> The peer is allowed to vote for this permit
    /// Accept -> The peer accepts the permit
    /// Reject -> The peer does not accept the permit, it will automatically be rejected
    enum PeerVote {
        NotAllowed,
        Allowed,
        Accept,
        Reject
    }

    /**
    * @dev
    * All structs will need two fields
    * - The same fields that are used to identify the struct (used to verify existence)
    * - The parent identifier if a relationship exists
    *
    * The former is used to verify that the object does exist
    * the latter is used to verify ownership of the struct object
    *
    * The storage mapping is very simple, we keep all structs on
    * a single mapping with the identifier for that struct and the object itself.
    *
    * Ex:
    * A contract is identified by an address
    * mapping(address => Contract) public contracts;
    *
    * We then keep a different mapping with the parent relationship identifier
    * and an array of identifiers
    *
    * Ex:
    * In this case the parent identifier is clientId, which is of bytes4 type
    * mapping(bytes4 => address[]) public _clientContracts;
    *
    * Using the described method we can:
    * - Fetch any object by its identifier
    * - Get all objects for a given parentId (frontend purpose)
    * - Verify that an object is for a given parentId (Using internal relationship identifier field)
    * - Verify the existence of an object (Using internal identifier field)
    *
    * NOTE:
    *
    * It's possible to have the same function signature for two different contracts,
    * that's why we need to map each function selector to a Contract.
    *
    * Without collision in mind, the mapping will be `mapping(bytes4 => Function)`, as
    * described previously. However, two contracts could not have the same function
    * signature and as a result, the later function would override the former selector
    * causing a discrepancy in the ownership of the Function.
    *
    * For this reason, a Contract-Function mapping is kept. This allows removing the
    * relationship identifier on the Function struct since the owner is already verified
    * by the `contractAddress` key on the mapping.
    *
    * The full struct layout and dependency is drawn below. The Client, Contract, and Function
    * struct are kept in storage as previously mentioned. The CallPermit objects allow
    * sticking all elements together. This object will contain the client, contract, function
    * selector, and the allowed calldata. Any value that does not match will be considered as an
    * invalid permit.

    * Furthermore, a keccak256 of the contract, function selector and the calldata (obtained
    * with msg.data) will be computed and stored in the permit itself for validation. External
    * contract using the `withSeraph` modifier do not know anything about permits and the only
    * way to obtain a reference to the corresponding permit is by using a cache system of
    * pending permits mapped using the hash of the contract/function and the allowed calldata.
    *
    * By using this method we are also preventing multiple permits for the same
    * contract/function with the same calldata to coexist (Preventing permit duplications).
    * However, different calldata from the same contract/function pair will be allowed since
    * they will produce a different hash value and have a different cache entry.
    *
    * When the contract is either executed or rejected, the cache entry will be invalidated
    * and the permit reference from an external contract disabled. The final status will be
    * reflected on the corresponding CallPermit object.
    *
    * The reason behind using this is because, by default, mapping returns 0 if the key is not
    * tracked. That means that if a new permit is added the cache value will be 0, causing
    * the permit at index 0 to be fetched. This would imply having to check all the permit
    * values with the new created one to make sure it is really different. If the permit was
    * the same we would have to validate the stage for not being executed or rejected.
    * Moreover, length checks on callPermits and out-of-bounds checks would also be needed.
    *
    * For code simplicity and easier development the cache value will be valid until the
    * permit is either executed or rejected. When the cache is discarded, both values will
    * be set to zero and some gas refunded. This method would allow discarding new created
    * permits from the default index of 0 with a simple boolean check. Storing and then
    * refunding the boolean cost would get back 75% of the cost, a total of 5000 gas would
    * be paid.
    *
    *
    *           ┌─────────────────┐     ┌───────────────┐
    *           │ CallPermitCache │  ┌─►│   CallPermit  │
    *           ├─────────────────┤  │  ├───────────────┤
    *           │ _permitId       ├──┘  │  _permitHash  │
    *           │                 │     │  ...          │
    *           └─────────────────┘     └──────┬────────┘
    *                                          │
    *        ┌───────────────────────┬─────────┴───────────┐
    *        │                       │                     │
    *        │             ┌─────────┼─────────────────────┼─────────┐
    *        │             │         │                     │         │
    * ┌──────▼───────┐     │ ┌───────▼──────────┐   ┌──────▼───────┐ │
    * │    Client    │◄──┐ │ │     Contract     │   │   Function   │ │
    * ├──────────────┤   │ │ ├──────────────────┤   ├──────────────┤ │
    * │  _clientId   │   │ │ │ _contractAddress │   │  _selector   │ │
    * │              │   └─┼─┤ _clientId        │   │              │ │
    * │  ...         │     │ │ ...              │   │  ...         │ │
    * └──────────────┘     │ └──────────────────┘   └──────────────┘ │
    *                      │                                         │
    *                      └─────────────────────────────────────────┘
    *                     mapping(address => mapping(bytes4 => Function))
    *
    * Clients will be able to generate call permits by signing on Seraph. The call permits
    * will be linked with previous registered contracts and functions. When a permit
    * is signed, a cache entry will be genearated, preventing duplication and retreaval
    * from an external calling contract (that does not have permitId knowdlege) from the
    * the checkUnblocked function.
    *
    * During function creation on Seraph, it is possible to specify the number of peers
    * that a function will require. Those peers will be allowed to vote for the permit,
    * accepting or rejecting it. If any of the peers reject the permit, it will be
    * invalidated. If all the peers accept the permit, the state will me moved and the
    * permit will be pending for Halborn approval. The votes are registered into Seraph
    * and each peer can access their permits for approval.
    *
    */


    /// @notice Struct representing a call permit that will create a client.
    struct CallPermit {
        /// @notice The actual id of the permit
        uint256 _permitId;

        /// @dev It is less expensive to use uint256 than uint32/uint64/uint224 here
        uint256 _timestamp;

        /// @notice Data for permit verification and ownership
        bytes4 _clientId;
        address _contractAddress;
        bytes4 _functionSelector;

        /// @notice State machine state for this call permit
        PermitStage _stage;

        /// The keccak256 of the permit data + callData
        bytes32 _permitHash;

        /// The actual call data, used with the function signature
        /// to decode the actual parameters
        bytes _callData;

        /// @notice The number of required peers for this permit that are needed to move
        /// the state. The value is taken from the contract/function pair.
        uint256 _requiredPeers;

        /// @notice _accepted is not always used, it will depend
        /// on wheter the _requiredPeers value is not zero
        /// It does not cost any extra gas to create an struct in storage with zero fields
        uint256 _acceptedPeers;

    }

    /// @notice Struct representing each function of a contract that is being protected. As
    /// stated, the function is on a per-contract basis. Two functions with the same selector
    /// can not exist on the same contract, but on different contracts.
    struct Function {
        /// @notice Identifier for a Function object
        bytes4 _selector;

        /// @notice Full signature of the function. Used to generate the {_selector}.
        /// ex. emergencyWithdraw(address)
        string _signature;

        // Relationship parent identifier is not required in this case since the function is
        // already mapped on a contractAddress and can only be accessed by that key

        /// @notice The wallet allowed to call the sign function. We are using a
        /// per function wallet, so the same client can have multiple private keys for
        /// different purposes and functions
        address _wallet;

        /// @notice The amount of co-signing peers required for this function
        /// Default to 0
        uint256 _requiredPeers;

        /// @notice Used to count how many times this function was triggered, used only if
        /// the function is protected
        uint256 _eventCount;

        /// @notice If this function is protected. If not protected {checkUnblocked} will not be
        /// checked
        bool _isProtected;
    }

    /// @notice Struct representing a contract. Only one contract address can exist. That means
    /// that two clients can not have the same contract address.
    struct Contract {
        /// @notice Identifier for a Contract object
        address _contractAddress;

        /// @notice The name of the contract. Used mainly for the frontend and visibility.
        string _name;

        /// @notice Contract relationship parent identifier
        bytes4 _clientId;

        /// @notice If this contract is protected. If not protected {checkUnblocked} will not be
        /// checked
        bool _isProtected;
    }

    /// @notice Struct representing a client. Clients are identified by a byte4 field. The value is
    /// extracted from the keccak256 of the Client name and identified on all Seraph code as clientId.
    struct Client {
        /// @notice The identifier for a Client object
        bytes4 _clientId;

        /// @notice The name of the client. It is used to generate the {_clientId} with keccak256.
        string _name;

        /// @notice Used to store a GUID for an AWS KMS
        /// @dev Used to verify ownership with the {_walletsToClientID} and {Client._kmsWallet} variables.
        /// NOTE: When changing the values on {_walletsToClientID}, this field should be reflected as well.
        bytes16 _kmsKeyID;

        /// @notice Used to store the wallet address generates from the AWS KMS key.
        /// @dev Used to verify ownership with the {_walletsToClientID} storage variable. NOTE: When changing
        /// the values on {_walletsToClientID}, this field should be reflected as well.
        address _kmsWallet;

        /// @notice If this client is protected. If not protected {checkUnblocked} will not be
        /// checked
        bool _isProtected;
    }

    /// STORAGE VARIABLES DEFINITIONS

    /// @notice A mapping of all the permits on the system, the value is incremental. The counter
    /// used is `lastCallPermitId`
    mapping(uint256 => CallPermit) public callPermits;
    uint256 public lastCallPermitId;

    /// @notice Only one permit per function with the same call data can exist
    /// We can not allow to have the same permit more than once without approving the previous.
    /// The key is a hash, calculated using contractAddress, functionSelector and the call data
    /// and the value is the permit ID. It keeps track of none executed pending permits based
    /// on the hash (address+function+calldata)
    mapping(bytes32 => uint256) internal _hashToPermitId;

    /// @notice
    /// Matching the peer with the vote
    mapping(uint256 => mapping(address => PeerVote)) internal _callPermitPeerVote;
    mapping(uint256 => address[]) internal _callPermitPeers;

    /// @notice To store permits for a peer
    mapping(address => uint256[]) internal _peerCallPermits;

    /// @notice Used to access all function selectors for a specific contract address.
    ///
    /// @dev 1 to N: One contract has many function selectors
    mapping(address => bytes4[]) internal _contractFunctions;

    /// @notice Used to get a function object based on the contract address and the function selector
    ///
    /// @dev Its possible to have the same function signature for two different contracts,
    /// thats why we need to map each contract address with each own selector mapping
    ///
    /// Without collision in mind the mapping will be `mapping(bytes4 => Function)`, similar
    /// to the contracts mapping, but two contracts could not have the same function
    /// signature since the later would override the former selector.
    ///
    /// 1 to 1 (by Contract): One function selectors has one Function struct
    mapping(address => mapping(bytes4 => Function)) public functions;

    /// @notice Used to access all contract addresses for a specific client
    ///
    /// @dev 1 to N: One clientId has many contracts
    mapping(bytes4 => address[]) internal _clientContracts;

    /// @notice Used to access a contract object based on its address identifier
    ///
    /// @dev We don't use a mapping based on client id since only one contract address can cohexist
    // and two clients can not have the same address.
    // 1 to 1: One address has one Contract struct.
    mapping(address => Contract) public contracts;

    /// @notice used to access a client object based on the client id.
    ///
    /// @dev 1 to 1: One clientId has one Client struct
    mapping(bytes4 => Client) public clients;

    /// @notice Used to access all registered client ids.
    ///
    /// @dev A single array is kept, since no parent relationship exists
    bytes4[] internal _clientsId;

    /// @notice Whether seraph was has been _initialised or not.
    /// @dev This value can only be changed on the initializer modifier
    bool internal _initialised;

    /// @notice Used to access the client id for a specific wallet that is allowed to sign.
    /// This wallet is controlled by the client. Only one wallet can be used per client.
    /// However, a client can have multiple wallets, one per each function if desidered.
    mapping(address => bytes4) internal _walletsToClientID;

    /// @notice KMS wallets to client id mapping. Used to verify existency and ownership of
    /// the calling address on {approve}.
    ///
    /// @dev Those wallets are generated by AWS KMS. Only one AWS KMS wallet should exist per client
    /// although this mapping allows two wallets to have the same client id.
    ///
    /// We could be using a ClientIdToWallets mapping but it would be imposible to verify that a single
    /// kms wallet is not shared between clients.
    ///
    /// Single ownership can be verified by checking the key address with the Client._kmsWallet field.
    /// This prevents the client from having 2 different wallets. When the _kmsWalletsToClientID is
    /// updated, the Client._kmsWallet and Client._kmsKeyID should be reflected as well.
    mapping(address => bytes4) internal _kmsWalletsToClientID;

    /// @notice KMS wallet used for administrative purpose on Seraph. Halborn will not have control of
    /// the private key. Only Lambda code will be allowed to sign with it.
    ///
    /// @dev This wallet will be set once, but a setter will exist in case of KMS outage so we can
    /// replicate the administration using a mutisig wallet. Only a single administrative
    /// address will exist.
    address public kmsAdminWallet;

    /// @notice KMS wallet GUID that generates the {kmsAdminWallet} wallet.
    /// Only Lambda code will be allowed to sign with it.
    ///
    /// @dev This wallet will be set once, but a setter will exist in case of KMS outage so we can
    /// replicate the administration using a mutisig wallet. Only a single KMS ID can exist.
    bytes16 public kmsAdminKeyId;
}

/**
 * @notice
 * Seraph ™ is a smart contract integrated security and notary solution developed by Halborn that bridges
 * the gap between decentralized and centralized administration.
 *
 * Seraph protects smart contract DEVELOPERS by:
 *
 * - Removing the risk of completely revoking contract ownership.
 * - Providing an incident response and notification service to facilitate easy and fast smart contract administration and operations.
 * - Separates the personal risk that comes with single key custody.
 * - Increases community and investor confidence in the security of their funds.
 *
 * Seraph protects smart contract USERS by:
 *
 * - Removing the risk of centralized administration and liquidity access.
 * - Providing third-party security oversight to validate all contract operations are legitimate
 *
 * Seraph, allows clients to protect critical functions for owned contracts by registering them into the system.
 * Once the functions are registered, the clients will be allowed to create call permits for them. Once the permit
 * is approved by Halborn, the function will be executable and the client can call it. Seraph is proxy safe, contracts
 * are registered based on the proxy address, allowing client code to be upgraded.
 *
 * To create a call permit, the sign process must be done from the registered wallet for the given client function. The
 * system allows registering a different wallet per function, very convenient if using an RBAC system to enforce
 * least privilege access. Furthermore, the call permit must contain the exact same data that will be used during execution.
 * This allows Halborn or any external party to see what call data will be used and approve call permits based on that.
 *
 * Seraph, allows peers to co-sign call permits. Each registered function on the system specifies the number
 * of external peers that will be co-signing a call permit. During permit creation, the client will specify which peers
 * to co-sign with. The peer will be allowed to see the decoded call data and approve or reject the permit. If any of the
 * peers reject the permit, the permit will be invalidated.
 *
 * After all peers agree with the permit, Halborn will have the final vote on it. Halborn will be allowed to approve or
 * reject the permit based on our Incident Response Team. If the permit is approved, the client will be notified and allowed
 * to execute the function with only the registered permit call data. If the permit is rejected, the function will not be
 * executable and a new permit would have to be requested.
 *
 * In order to use Seraph, the client will include a modifier for each function that wants to be protected. The only required
 * external method to use Seraph is `checkUnblocked`, an interface must be included into the code:
 *
 *      interface HalbornSeraph {
 *          function checkUnblocked(bytes4, bytes calldata) external;
 *      }
 *
 * The following modifier and constant variable should be added to the code (NOTE: No storage modification is made). The
 * `PROXY_ADDRESS`, will be given to all Halborn clients, once the proxy contract is deployed. The Seraph address will
 * always be the same even if a code upgrade takes place.
 *
 *      HalbornSeraph constant seraph_address = HalbornSeraph(PROXY_ADDRESS);
 *
 *      modifier withSeraph() {
 *          seraph_address.checkUnblocked(msg.sig, msg.data);
 *          _;
 *      }
 *
 * Finally, the `withSeraph` modifier should be added on each function that wants to be protected:
 *
 *      function functionToProtect() external withSeraph {
 *      }
 *
 * @dev
 * Seraph does keep the Storage on a separated contract named SeraphStorage for simplicity and upgradability,
 * only code logic is present on Seraph contract
 *
 * On Seraph the initialization is taken care by the {initSeraph} function, this function will be called whenever
 * the proxy links to this logic contract To ensure that the initialize function can only be called once, a
 * simple modifier named `initializer` is used.
 *
 * When the contrat is deployed, no owner or administrative wallets are present. That means, that
 * Seraph is not operable until {initSeraph} is called.
 *
 * The client id will be used to login to our frontend system, the client will either:
 *
 * - Provide the name, that will be computed using keccak256 to get the clientId
 * - Connect the wallet and use {_walletsToClientID} to extract the clientId
 *
 * Either way can later be used to filter out contract and functions for that speficic client.
 * If the client has multiwallet (multiple wallets per different functions), this wallet can be
 * compared against each Function._wallet for further filtering.
 */
contract Seraph is Ownable, SeraphStorage {

    event NewAdminKMS(address _old, address _new);

    event NewClient(bytes4 _clientId, string _name, bytes16 _kmsId, address _kmsWallet);
    event NewClientProtection(bytes4 indexed _clientId, bool _protected);
    event NewClientKMS(bytes4 _clientId, address _old, address _new);

    event NewFunction(bytes4 indexed _clientId, address indexed _contractAddress, address _clientWallet, bytes4 _functionSelector, string _functionSignature, uint256 _requiredPeers);
    event NewFunctionPeers(address indexed _contractAddress, bytes4 indexed _functionSelector, uint256 _newPeers);
    event NewFunctionWallet(address indexed _contractAddress, bytes4 indexed _functionSelector, address _old, address _new);
    event NewFunctionProtection(address indexed _contractAddress, bytes4 _functionSelector, bool _protected);

    event NewContract(bytes4 indexed _clientId, address _contractAddress, string _contractName);
    event NewContractName(address indexed _contractAddress, string _old, string _new);
    event NewContractProtection(address indexed _contractAddress, bool _protected);

    event NewPermit(uint256 _permitId, bytes4 indexed _clientId, address indexed _contractAddress, bytes4 indexed _functionSelector, bytes _callData, address[] _peers);

    event PermitVoted(uint256 indexed _permitId, address indexed _peer);
    event PermitAccepted(uint256 indexed _permitId);
    event PermitRejected(uint256 indexed _permitId);

    event PermitApproved(uint256 indexed _permitId);
    event PermitRejectedByHalborn(uint256 indexed _permitId);

    event PermitExecuted(uint256 indexed _permitId, bytes4 indexed _clientId, address indexed _contractAddress, bytes4 _functionSelector, bytes _callData);
    event UnprotectedExecuted(bytes4 indexed _clientId, address indexed _contractAddress, bytes4 indexed _functionSelector, bytes _callData);

    //////////////////////////
    // Permission modifiers //
    //////////////////////////

    /**
     * @notice Modifier used to verify that the sender is the KMS administrative wallet
     */
    modifier onlySeraphAdmin(){
        require(msg.sender == kmsAdminWallet, "Seraph: Only Seraph KMS wallet allowed");
        _;
    }

    /**
     * @notice Modifier used to verify that the sender is the KMS wallet for a given permitId
     * @dev Refer to {_kmsWalletsToClientID} on why we don't check Client._kmsWallet ownership.
     *
     * @param permitId The permit id to get the client id and verify ownership of KMS wallet
     */
    modifier onlyKMSPermit(uint256 permitId){
        require(_kmsWalletsToClientID[msg.sender] != 0, "Seraph: Caller is not from KMS");
        require(_kmsWalletsToClientID[msg.sender] == callPermits[permitId]._clientId, "Seraph: This KMS key is not for this client");
        // NOTE: This should not happen, the _kmsWalletsToClientID value should always match _kmsWallet
        // require(clients[callPermits[permitId]._clientId]._kmsWallet == msg.sender, "Seraph: Invalid KMS for this client");
        _;
    }

    /**
     * @notice Modifier used to verify that a client exists by using its {clientId} identifier.
     * @dev To check existency, the identifier value should be different than zero and the
     * object should contain the same indentifier that is refered with.
     *
     * @param clientId The client identifier that will be checked
     */
    modifier clientExists(bytes4 clientId){
        require(clientId != bytes4(0), "Seraph: Client ID must be different than zero");
        require(clients[clientId]._clientId == clientId, "Seraph: Client does not exist");
        _;
    }

    /**
     * @notice Modifier used to verify that a contract exists by using its {contractAddress} identifier.
     * @dev To check existency, the identifier value should be different than zero and the
     * object should contain the same indentifier that is refered with.
     *
     * @param contractAddress The contract identifier that will be checked
     */
    modifier contractExists(address contractAddress){
        require(contractAddress != address(0), "Seraph: Contract address must be different than zero");
        require(contracts[contractAddress]._contractAddress == contractAddress, "Seraph: Contract is not tracked");
        _;
    }

    /**
     * @notice Modifier used to verify that a function for a given contract exists by using
     * its {functionSelector} identifier and the key parent {contractAddress} identifier.
     * @dev To check existency, the functionSelector value should be different than zero. Having an invalid
     * {contractAddress}, including a zero one, would cause the check to fail since the {_selector} will be
     * zero by default. Since the function is stored on a per contract bases, no verification function is needed
     * since the function can only be accessed if the {contractAddress} is known.
     *
     * @param contractAddress The contract where the functionSelector is supposed to live.
     * @param functionSelector The function identifier that will be checked
     */
    modifier functionExists(address contractAddress, bytes4 functionSelector){
        require(functionSelector != bytes4(0), "Seraph: Function selector must be different than zero");
        require(functions[contractAddress][functionSelector]._selector == functionSelector, "Seraph: Function is not tracked for this contract");
        _;
    }

    /**
     * @notice Modifier used to detect if a permit exists or not.
     *
     * @dev The permitId must be less than the lastCallPermitId and bigger than 0.
     * The 0 permitId is used as the default for none existing permits
     * No need to check for stage != NotExists, since the permit will exist if
     * the id is less than that value
     *
     * @param permitId The actual permit id to check existency
     */
    modifier permitExists(uint256 permitId){
        require(permitId > 0 && permitId <= lastCallPermitId, "Seraph: Permit not found");
        _;
    }

    /**
     * @notice Modifier used to verify that the contract is not initialised already
     */
    modifier initializer(){
        require(!_initialised, "Seraph: Contract already initialised");
        _;
        _initialised = true;
    }

    ////////////////////////
    // Internal functions //
    ////////////////////////

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `_isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     * @param addr The actual address to check for being a contract
     */
    function _isContract(address addr) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }

    /**
     * @notice This function will add a function to a given {clientId} and {contractAddress}.
     * If this function requires co-signing with external peers, the amount should be specified
     * under {requiredPeers}. If the function alreay exists, nothing happens.
     *
     * @dev The function parameters must be checked for being valid or different than zero.
     * If the parameters are valid it will check if the function already exists, after validating
     * the contract, using the {functionSelector} identifier. This function should check that
     * the generated functionSelector is different than zero. Since a function is mapped on a
     * contract address no ownership verification will be performed
     *
     * @param contractAddress The contract address indentifier. Only one address can exist
     * @param clientWallet The wallet authorized to sign the permission for this function. A client
     * can have different wallets for different protected functions.
     * @param functionSignature The function signature that will be displayed on the frontend. It
     * will be used to calculate the function selector.
     * @param requiredPeers If this function require peers, the amount should be speficied. 0 if
     * no peers are required to co-sign
     */
    function _addFunctionToContract(address contractAddress, address clientWallet, string calldata functionSignature, uint256 requiredPeers) internal {

        require(clientWallet != address(0), "Seraph: clientWallet must be different than zero");

        bytes4 functionSelector = getFunctionSelector(functionSignature);
        require(functionSelector != bytes4(0), "Seraph: The function selector must be different than zero");


        // If the function is not tracked, we will add it. Ignore otherwise
        if (functions[contractAddress][functionSelector]._selector == bytes4(0)) {

            Function storage _function = functions[contractAddress][functionSelector];

            _function._signature = functionSignature;
            _function._wallet = clientWallet;
            _function._requiredPeers = requiredPeers;

            // Identifier and parent identifier
            _function._selector = functionSelector;
            _function._isProtected = true;

            _contractFunctions[contractAddress].push(functionSelector);

            emit NewFunction(
                contracts[contractAddress]._clientId,
                contractAddress,
                clientWallet,
                functionSelector,
                functionSignature,
                requiredPeers);
        }


    }

    /**
     * @notice This function will add a contract to a given `clientId` for a given `contractAddress`. If the contract
     * already exists, it will verify the ownership using `clientId` and return
     *
     * @param clientId The client owner for this contract. If the contract exists it will be used
     * to verify ownership
     * @param contractAddress The contract address indentifier. Only one address can exist
     * @param contractName The name of the contract. Mainly used for frontend purpose
     */
    function _addContractToClient(bytes4 clientId, address contractAddress, string calldata contractName) internal {

        require(contractAddress != address(0), "Seraph: contractAddress must be different than zero");
        require(_isContract(contractAddress), "Seraph: contractAddress is not a contract");

        if (contracts[contractAddress]._contractAddress == address(0)) {

            Contract storage _contract = contracts[contractAddress];

            _contract._name = contractName;

            // Identifier and parent identifier
            _contract._contractAddress = contractAddress;
            _contract._clientId = clientId;
            _contract._isProtected = true;

            _clientContracts[clientId].push(contractAddress);

            emit NewContract(
                clientId,
                contractAddress,
                contractName);

        } else {
            require(contracts[contractAddress]._clientId == clientId, "Seraph: Contract is from another client");
        }

    }

    /**
     * @notice The wallet is controlled by the client and allows to sign permits.
     * Only one wallet can be used per client. However, a client can have multiple wallets,
     * one per each function if desidered.
     *
     * @param clientId The client owner for this contract. If the contract exists it will be used
     * to verify ownership
     * @param clientWallet The wallet authorized to sign the permission for this function. A client
     * can have different wallets for different protected functions.
     */
    function _addWalletToClient(bytes4 clientId, address clientWallet) internal {
        // The wallet should not be used already
        if (_walletsToClientID[clientWallet] == bytes4(0)){
            _walletsToClientID[clientWallet] = clientId;
        } else {
            // If the wallet is already used, it should be for the same client
            require(_walletsToClientID[clientWallet] == clientId, "Seraph: The provided wallet is from another client");
        }
    }

    /**
     * @notice This function will add a permit to the internal Seraph storage for a given `contractAddress`, `functionSelector`.
     * This call permit will only be valid for the given {callData}, and any other calling data will be invalid. Furthermore, if the
     * function requires signing peers a list of them should be provided under {peers}. The function will also check for cached
     * pending permits and revert if there is already one with the same call data for the same contract/function pair.
     *
     * @dev If no peers are required, the status should be PermitStage.PermitSigned, otherwise we must iterate over all the
     * peers and keep track of them under the list of allowed peers for the created permit. A new cache entry should be created
     * if a new permit is added.
     *
     * @param contractAddress The contract address indentifier.
     * @param functionSelector The function selector for the given contract.
     * @param callData The only valid calldata that will be allowed to trigger the function (abi encoded with function selector). It must contain the
     * actual full call data with the functionSelector being the first 4 bytes.
     * @param requiredPeers If this permit require peers, the amount should be speficied. 0 if no peers are required to co-sign
     * @param peers A list containing all the peers that will be allowed to co-sign with the client this permit
     */
    function _addPermit(address contractAddress, bytes4 functionSelector, bytes calldata callData, uint256 requiredPeers, address[] calldata peers) internal {

        require(requiredPeers == peers.length, "Seraph: Invalid number of peers for this function");

        // NOTE: Think about hash collision
        bytes32 _permitHash = getPermitHash(contractAddress, functionSelector, callData);

        /// @notice If the cache value is valid this means that a pending permit for this permit hash exists. If the cache
        /// value is not valid, we are fetching a new cache reference for an unexistent permit.
        require(_hashToPermitId[_permitHash] == 0, "Seraph: Only one pending permit with the same calldata per contract/function is allowed");

        CallPermit memory _permit;

        // NOTE: Incrementing first is very important since the ID of 0 is used for none existing permits
        uint256 _newPermitId = ++lastCallPermitId;

        // Extract the clientId from the owner of the contract
        _permit._permitId = _newPermitId;
        _permit._timestamp = block.timestamp;
        _permit._clientId = contracts[contractAddress]._clientId;
        _permit._contractAddress = contractAddress;
        _permit._functionSelector = functionSelector;

        if (requiredPeers == 0){
            // If no required peers, the function is consideres as already signed by peers
            _permit._stage = PermitStage.PermitSigned;
        } else {
            _permit._stage = PermitStage.PermitCreated;

            _permit._requiredPeers = requiredPeers;

            for(uint256 i=0; i < requiredPeers; i++) {
                address _peer = peers[i];
                _callPermitPeerVote[_newPermitId][_peer] = PeerVote.Allowed;
                _peerCallPermits[_peer].push(_newPermitId);
            }

            _callPermitPeers[_newPermitId] = peers;
        }

        _permit._permitHash = _permitHash;
        _permit._callData = callData;

        callPermits[_newPermitId] = _permit;

        // Add the permit id to cache for the permit hash fast reference to the permit id
        _addCache(_permitHash, _newPermitId);
    }

    /**
     * @notice This function returns the string representation of the given PermitStage
     *
     * @param stage The PermitStage to return the string representation from
     */
    function _getPermitStageName(PermitStage stage) internal pure returns (string memory nameStage){

        if      (stage == PermitStage.PermitCreated) nameStage = "PermitCreated";
        else if (stage == PermitStage.PermitSigned) nameStage = "PermitSigned";
        else if (stage == PermitStage.HalbornApproved) nameStage = "HalbornApproved";
        else if (stage == PermitStage.Executed) nameStage = "Executed";
        else if (stage == PermitStage.PermitRejected) nameStage = "PermitRejected";
        else if (stage == PermitStage.HalbornRejected) nameStage = "HalbornRejected";
        else if (stage == PermitStage.NotExists) nameStage = "NotExists";
    }

    /**
     * @notice Internal function used to check a `found` state with an `expected` state, if the
     * states do not match, a dynamic revert string will be generated.
     *
     * @param found The found PermitStage
     * @param expected The expected PermitStage
     */
    function _checkState(PermitStage found, PermitStage expected) internal pure {
        if (found != expected){
            revert(
                string(
                    abi.encodePacked(
                        "Seraph: Invalid call permit state, was expecting ",
                        _getPermitStageName(expected),
                        " but found ",
                        _getPermitStageName(found)
                    )
                )
            );
        }
    }

    /**
     * @notice Internal function that will add a permitId to the internal hash cache system
     * The key will be the actual permit hash obtained using the {getPermitHash} function.
     *
     * @param permitHash The permit hash, used as the key on the cache
     * @param permitId The actual permit id that the cache will reference
     */
    function _addCache(bytes32 permitHash, uint256 permitId) internal {
        _hashToPermitId[permitHash] = permitId;
    }

    /**
     * @notice The internal function that will remove and invalidate the internal cache entry
     * for a given {permitHash}
     *
     * @param permitHash The permit hash that will be removed and invalidated
     */
    function _invalidateCache(bytes32 permitHash) internal {
        _hashToPermitId[permitHash] = 0;
    }

    /////////////////////////////////
    // External functions (Lambda) //
    /////////////////////////////////

    /**
     * @notice Function used during Seraph initialisation to transfer ownership to a multisig wallet and
     * KMS administrative permissions.
     *
     * @dev Should only be callable once. The {newGnosisHalbornWallet} will be transfered ownership and
     * {newkmsAdminWallet} will be the wallet with administrative permission on Seraph. NOTE: When the
     * contrat is deployed, no owner or administrative wallets are present. That means, that Seraph is
     * not operable until {initSeraph} is called.
     *
     * @param newGnosisHalbornWallet The owner of Seraph. It will only be allowed to change KMS admin wallet
     * @param newkmsAdminKeyId It is the AWS GUID for the key that generates the {newkmsAdminWallet} public address.
     * @param newkmsAdminWallet The KMS admin wallet. It will be allowed to administrate Seraph.
     */
    function initSeraph(address newGnosisHalbornWallet, bytes16 newkmsAdminKeyId, address newkmsAdminWallet) external initializer {

        require(newGnosisHalbornWallet != address(0), "Seraph: newGnosisHalbornWallet must be different than 0");

        _transferOwnership(newGnosisHalbornWallet);

        kmsAdminWallet = newkmsAdminWallet;
        kmsAdminKeyId = newkmsAdminKeyId;

        emit NewAdminKMS(address(0), newkmsAdminWallet);
    }

    /**
     * @notice This function will add a function to a given {clientId} and {contractAddress}.
     * This is the public interface for {_addContractToClient}, {_addFunctionToContract} and
     * {_addWalletToClient} function were all the parameters are checked. Only seraph KMS admin
     * wallet can call it ({onlySeraphAdmin}).
     *
     * @dev The {clientId} should exist before calling this function ({clientExists}).
     *
     * @param clientId The client owner for this contract. If the contract exists it will be used
     * to verify ownership
     * @param contractAddress The contract address indentifier. Only one address can exist
     * @param contractName The name of the contract. Mainly used for frontend purpose
     * @param clientWallet The wallet authorized to sign the permission for this function. A client
     * can have different wallets for different protected functions.
     * @param functionSignature The function signature that will be displayed on the frontend. It
     * will be used to calculate the function selector.
     */
    function addFunctionToContract(bytes4 clientId, address contractAddress, string calldata contractName, string calldata functionSignature, address clientWallet, uint256 requiredPeers) external onlySeraphAdmin clientExists(clientId){

        _addContractToClient(clientId, contractAddress, contractName);

        _addFunctionToContract(contractAddress, clientWallet, functionSignature, requiredPeers);

        _addWalletToClient(clientId, clientWallet);

    }

    /**
     * @notice Batchable version of {addFunctionToContrat}
     * We allow multiple contract to be added. Each contract does have a
     * {contractName}. For each contract, we can have multiple functions, and
     * in consecuence {clientWallets} and {requiredPeers}
     *
     * @param clientId The client owner for this contract. If the contract exists it will be used
     * to verify ownership
     * @param contractAddresses All the contracts we are adding functions for. Only one address can exist
     * @param contractNames All the name of the contracts
     * @param functionSignatures All the function signature that will be added for each contract. It
     * will be used to calculate the function selector.
     * @param clientWallets All the wallets authorized to sign the permission for each contract/function. A client
     * can have different wallets for different protected functions.
     * @param requiredPeers The amount of required peers for each contract/function authorized to co-sign the permit
     */
    function addFunctionToContractMultiple(bytes4 clientId, address[] calldata contractAddresses, string[] calldata contractNames, string[][] calldata functionSignatures, address[][] calldata clientWallets, uint256[][] calldata requiredPeers) external onlySeraphAdmin clientExists(clientId){

        require(contractAddresses.length == contractNames.length &&
                contractNames.length == functionSignatures.length &&
                functionSignatures.length == clientWallets.length &&
                clientWallets.length == requiredPeers.length, "Seraph: Different contract array lengths");

        for (uint256 contractIndex = 0; contractIndex < contractAddresses.length; contractIndex++) {

            _addContractToClient(clientId, contractAddresses[contractIndex], contractNames[contractIndex]);

            require(functionSignatures[contractIndex].length == clientWallets[contractIndex].length &&
                    clientWallets[contractIndex].length == requiredPeers[contractIndex].length , "Seraph: Different function array lengths");

            for (uint256 functionIndex = 0; functionIndex < functionSignatures[contractIndex].length; functionIndex++) {

                _addFunctionToContract(
                    contractAddresses[contractIndex],
                    clientWallets[contractIndex][functionIndex],
                    functionSignatures[contractIndex][functionIndex],
                    requiredPeers[contractIndex][functionIndex]);

                _addWalletToClient(clientId, clientWallets[contractIndex][functionIndex]);
            }
        }

    }

    /**
     * @notice This function will add a new client to the system and track the KMS
     * wallet for it. A {kmsWallet} will only be permited to approve functions
     * for the client that has it. Only one KMS is allowed per client. Only seraph
     * KMS admin wallet can call it ({onlySeraphAdmin}).
     * @dev The generated {clientId} should be different than zero and the kmsWallet
     * should not be tracked already. {kmsWallet} must be the generated from {kmsID}.
     * The KMS wallet to client mapping ({_kmsWalletsToClientID}) should be updated and
     * verified for existency
     *
     * @param name The name of the client. The client ID will be extracted from this name.
     * @param kmsId It is the AWS GUID for the key that generates the {kmsWallet} public address.
     * @param kmsWallet The public address generated using the KMS ID (`kmsId`).
     */
    function addClient(string calldata name, bytes16 kmsId, address kmsWallet) external onlySeraphAdmin {
        bytes4 clientId = getClientId(name);

        require(clientId != bytes4(0), "Seraph: Client Id is 0");
        require(clients[clientId]._clientId == bytes4(0), "Seraph: Client already exists");

        // Only one kms per client exist, no need to check {kmsId}. {kmsWallet} must be
        // generated using {kmsId}.
        require(_kmsWalletsToClientID[kmsWallet] == 0, "Seraph: KMS wallet already used");

        Client storage _client = clients[clientId];

        _client._clientId = clientId;

        _client._name = name;
        _client._kmsKeyID = kmsId;
        _client._kmsWallet = kmsWallet;
        _client._isProtected = true;

        _clientsId.push(clientId);

        _kmsWalletsToClientID[kmsWallet] = clientId;

        emit NewClient(
            clientId,
            name,
            kmsId,
            kmsWallet);

    }

    /**
     * @notice This function will reject a given permitId. It will verify that
     * the permit exists and make sure it is not executed already
     * Only seraph KMS admin wallet can call it ({onlySeraphAdmin}).
     * @dev The permit must exists. The only state that the permit can not be rejected from
     * is `Executed` or `Rejected`
     *
     * @param permitId The permit ID to reject
     */
    function reject(uint256 permitId) external onlySeraphAdmin permitExists(permitId) {

        CallPermit storage _permit =  callPermits[permitId];

        require(_permit._stage < PermitStage.Executed, "Seraph: Can not reject an executed or already rejected permit");

        _permit._stage = PermitStage.HalbornRejected;

        _invalidateCache(_permit._permitHash);

        emit PermitRejectedByHalborn(permitId);
    }

    /**
     * @notice It unblocks the state of a function and allows {checkUnblocked} to succeed.
     * This function can only be called from the registered KMS key for that client
     * though AWS lambda. It will verify that the client already did sign.
     *
     * @dev A full chain verification is required for the {clientId}, {contractAddress}
     * and {functionSelector}. {clientId} should be validated, first by checking that
     * the KMS caller is for the given clientId, and that the client owns {contractAddress}.
     *
     * @param permitId The permit Id to approve. The only valid signer is the KMS address
     * for the client ID of the given `permitId`.
     */
    function approve(uint256 permitId) external permitExists(permitId) onlyKMSPermit(permitId) {

        CallPermit storage _permit = callPermits[permitId];

        _checkState(_permit._stage, PermitStage.PermitSigned);

        _permit._stage = PermitStage.HalbornApproved;

        emit PermitApproved(permitId);
    }

    ////////////////////////////////////////////
    // External functions (Clients and peers) //
    ////////////////////////////////////////////

    /**
     * @notice It sign a `permitId` from any address. It will check if the address
     * is a valid peer for the permit and if already voted.
     *
     * @dev The peer will be disallowed once the vote is made. This will prevent
     * double voting.
     *
     * @param permitId The permit Id that the peer will sign
     * @param vote The vote of the peer for the `permitId`
     */
    function signPeer(uint256 permitId, PeerVote vote) external permitExists(permitId) {

        CallPermit storage _permit = callPermits[permitId];

        // NOTE: No need to check for _requiredPeers, no peer will be allowed for permits that do not require peers
        require(_callPermitPeerVote[permitId][msg.sender] == PeerVote.Allowed, "Seraph: Signer not allowed or already voted");

        /// @notice Solidity will already add a check for the enum argument being less that the max value. Just
        /// in case this is not a future feature, we will check for both valid values
        require(vote == PeerVote.Accept || vote == PeerVote.Reject, "Seraph: Only Accept or Reject are valid as a vote");

        _checkState(_permit._stage, PermitStage.PermitCreated);

        /// @notice Store the vote
        _callPermitPeerVote[permitId][msg.sender] = vote;

        emit PermitVoted(permitId, msg.sender);

        if(vote == PeerVote.Accept){
            uint256 accepted = _permit._acceptedPeers;
            accepted += 1;

            if(accepted == _permit._requiredPeers){
                _permit._stage = PermitStage.PermitSigned;
                emit PermitAccepted(permitId);
            }
            _permit._acceptedPeers = accepted;
        } else {
            _permit._stage = PermitStage.PermitRejected;
            _invalidateCache(_permit._permitHash);
            emit PermitRejected(permitId);
        }
    }

    /**
     * @notice It will sign the client authorization for a given {contractAddress} and
     * {functionSelector}. The function must verify that `msg.sender` is allowed for this function.
     *
     * @dev The function should not be already signed and only a function verification is needed
     * since the wallet is checked for the given function and the clientId does not have
     * any implication on that wallet. The authorized wallets are on a per function bases.
     *
     * @param contractAddress The contract where the functionSelector is from.
     * @param functionSelector The function from which the permit will be created.
     * @param callData The valid calldata that will be allowed to trigger the function (abi encoded with function selector)
     * @param peers List of peers addresses that will be allowed to co-sign the permit.
     */
    function sign(address contractAddress, bytes4 functionSelector, bytes calldata callData, address[] calldata peers) external contractExists(contractAddress) functionExists(contractAddress, functionSelector) returns(uint256) {

        Function memory _function = functions[contractAddress][functionSelector];
        // Only the wallet for that function is allowed to create permits
        require(_function._wallet == msg.sender, "Seraph: Signer is not allowed to create permits for this contract function");

        _addPermit(contractAddress, functionSelector, callData, _function._requiredPeers, peers);

        emit NewPermit(
            lastCallPermitId,
            contracts[contractAddress]._clientId,
            contractAddress,
            functionSelector,
            callData,
            peers);

        return lastCallPermitId;
    }

    /**
     * @notice This function is used to check if any of the specified identifiers
     * is not protected. The function must be called with a valid `contractAddress`
     * and `functionSelector`. Otherwise the returned value will be false by default,
     * showing that the contract/function is not protected.
     *
     * @param contractAddress The contract were the `functionSelector` is from
     * @param functionSelector The function identifier
     * @return It will return false if any of the full chain {_isProtected} is false.
     * Returning true otherwise
     */
    function isFunctionProtected(address contractAddress, bytes4 functionSelector) public view returns(bool){
        if (!functions[contractAddress][functionSelector]._isProtected ||
            !contracts[contractAddress]._isProtected ||
            !clients[contracts[contractAddress]._clientId]._isProtected
        ){
            return false;
        }

        return true;
    }

    /**
     * @notice This function is used to check if any of the specified identifiers
     * is not protected. The function must be called with a valid `contractAddress`
     * Otherwise the returned value will be false by default, showing that the contract
     # is not protected
     *
     * @param contractAddress The contract to check protection
     * @return It will return false if any of the full chain {_isProtected} is false.
     * Returning true otherwise
     */
    function isContractProtected(address contractAddress) external view returns(bool){
        if (!contracts[contractAddress]._isProtected ||
            !clients[contracts[contractAddress]._clientId]._isProtected
        ){
            return false;
        }

        return true;
    }

    /**
     * @notice This function will return if the permitId is unblocked
     *
     * @param permitId The permit Id to check the state
     * @return It will return true if the state is halborn approved
     */
    function isUnblocked(uint256 permitId) external view permitExists(permitId) returns(bool) {
        CallPermit memory _permit = callPermits[permitId];
        return _permit._stage == PermitStage.HalbornApproved;
    }

    /**
     * @notice It will verify that the calling contract and given signature is approved
     * by Halborn to be executed. If any of the hierarchy objects is not protected it will
     * return, allowing the execution to continue. This function is part of the modifier
     * that the client will need to use Seraph.
     *
     * @dev  We should be aware of all functions calling {checkUnblocked} thats why we need
     * to verify that the calling function exists. Verifying that the function exists
     * allows {_isCallerProtected} to not fetch unexisting states (defaulting to false)
     *
     * @param functionSelector The function identifier that will be checked. This parameter
     * is send using {msg.sig} by the Seraph modifier that the client will implement
     * @param callData The only valid calldata that will be allowed to trigger the function (abi encoded with function selector)
     */
    function checkUnblocked(bytes4 functionSelector, bytes calldata callData) external contractExists(msg.sender) functionExists(msg.sender, functionSelector) {

        if (!isFunctionProtected(msg.sender, functionSelector)){
            emit UnprotectedExecuted(
                contracts[msg.sender]._clientId,
                msg.sender,
                functionSelector,
                callData);
            return;
        }

        bytes32 _permitHash = getPermitHash(msg.sender, functionSelector, callData);

        // If the cache entry is not valid, that means that the permit is not found
        // There is no need to check for _permit._permitHash == _permitHash since the key for the cached permit
        // is actually the same hash. If the cache is valid, we are verifying that indeed the permit should be from
        // the actual contractAddress, functionSelector and callData.
        require(_hashToPermitId[_permitHash] != 0, "Seraph: No permit for this function with this call data has been signed");

        // NOTE:
        // The hash is computed using the contract address, function selector and calldata. However, extending calldata
        // without execution permissions is possible in solidity. Having this in mind, it would be possible, from a
        // tehoreticall standpoint, to have a hash collision with an already pending permit hash.
        //
        // If there was a hash collision for a none executed contract the {_permitId} check would pass and the returned
        // {_permitId} would be from the collided hash.
        //
        // Checking for the contractAddress, functionSelector and callData length would limit the hash collision
        // to only the same function for the same contract with different callData. Probabily random generated
        // data used to get the hash collision would result in invalid function execution.
        CallPermit storage _permit = callPermits[_hashToPermitId[_permitHash]];

        require(
            _permit._contractAddress == msg.sender &&
            _permit._functionSelector == functionSelector &&
            _permit._callData.length == callData.length
            );

        /// @notice Only approved will be executed
        _checkState(_permit._stage, PermitStage.HalbornApproved);

        /// Execution
        /// @notice The contract will be executed at this point, update the event and permit stage
        functions[msg.sender][functionSelector]._eventCount +=1;

        _permit._stage = PermitStage.Executed;

        /// @notice Reset the cache
        _invalidateCache(_permitHash);

        emit PermitExecuted(
            _hashToPermitId[_permitHash],
            _permit._clientId,
            msg.sender,
            functionSelector,
            callData
            );
    }

    //////////////////////
    // Getter functions //
    //////////////////////

    /**
     * @notice Function that returns the client ID based on the client name.
     * @dev This ID is used on the entire Seraph contract to refer to a client. It is possible that
     * a client produces an ID where the first 4 bytes are 0's (0x00000000....). The {clientExists} modifier
     * does already check for the clientId being different than zero, but direct access to the clientId should
     * take care of this possibility.
     *
     * @param clientName The name of the client to get the ID for
     * @return Client ID as bytes4 is returned
     */
    function getClientId(string calldata clientName) public pure returns(bytes4) {
        return bytes4(keccak256(abi.encodePacked(clientName)));
    }

    /**
     * @notice Function that returns the function selector for a given function signature
     * @dev This selector is used on the entire Seraph contract to refer to a given function. It is possible that
     * a signature produces a selector where the first 4 bytes are 0's (0x00000000....).
     * The {functionExists} modifier does already check for the functionSelector for being different than zero,
     * but direct access to the selector should take care of this possibility.
     *
     * @param functionSignature The function signature to get the selector for
     * @return Function selector as bytes4 is returned
     */
    function getFunctionSelector(string calldata functionSignature) public pure returns(bytes4) {
        return bytes4(keccak256(abi.encodePacked(functionSignature)));
    }

    /**
     * @notice It will calculate the permit hash used internally to validate the calldata for a given {contractAddress}
     * and {functionSelector}. The returned value is a keccak256 of the packed {contractAddress}, {functionSelector}
     * and {callData}.
     *
     * @param contractAddress The contract address of containing the {functionSelector}
     * @param functionSelector The actual function of the permit
     * @param callData The only valid calldata that will be allowed to trigger the function (abi encoded with function selector).
     */
    function getPermitHash(address contractAddress, bytes4 functionSelector, bytes calldata callData) public pure returns(bytes32){
        return keccak256(abi.encodePacked(contractAddress, functionSelector, callData));
    }

    /**
     * @notice Getter that returns a list of all permits
     * @return All permits
     */
    function getAllPermits() external view returns(CallPermit[] memory) {
        CallPermit[] memory _permits = new CallPermit[](lastCallPermitId);
        for (uint256 i = 1; i <= lastCallPermitId; i++) {
            _permits[i-1] = callPermits[i];
        }
        return _permits;
    }

    /**
     * @notice Getter that returns a list of clients
     * @return All clients
     */
    function getAllClients() external view returns(Client[] memory) {
        Client[] memory _clients = new Client[](_clientsId.length);
        for (uint256 i = 0; i < _clientsId.length; i++) {
            _clients[i] = clients[_clientsId[i]];
        }
        return _clients;
    }

    /**
     * @notice Getter that returns a list of contracts
     *
     * @param clientId The client identifier to get the contracts from
     * @return All contracts for a given {clientId}
     */
    function getAllClientContracts(bytes4 clientId) external view returns(Contract[] memory) {
        Contract[] memory _contracts = new Contract[](_clientContracts[clientId].length);
        for (uint256 i = 0; i < _clientContracts[clientId].length; i++) {
            _contracts[i] = contracts[_clientContracts[clientId][i]];
        }
        return _contracts;
    }

    /**
     * @notice Getter that returns a list of functions
     *
     * @param contractAddress The contract address to get the functions from
     * @return All functions for a given {contractAddress}
     */
    function getAllContractFunctions(address contractAddress) external view returns(Function[] memory) {
        Function[] memory _functions = new Function[](_contractFunctions[contractAddress].length);
        for (uint256 i = 0; i < _contractFunctions[contractAddress].length; i++) {
            _functions[i] = functions[contractAddress][_contractFunctions[contractAddress][i]];
        }
        return _functions;
    }

    /**
     * @notice It will return all the peers that are allowed to sign a {permitId}
     * @param permitId The actual permit id to get the peers from
     */
    function getPermitPeers(uint256 permitId) external view returns(address[] memory) {
        return _callPermitPeers[permitId];
    }

    /**
     * @notice It will get the peer vote for a specified permitId
     * @param permitId The actual permit id to get the vote for
     * @param peer The peer to get the vote for
     */
    function getPermitPeerVote(uint256 permitId, address peer) external view returns(PeerVote) {
        return _callPermitPeerVote[permitId][peer];
    }

    /**
     * @notice It will return all permit ids that a peer can vote for.
     * @param peer The address of the peer
     */
    function getPeerPermits(address peer) external view returns(uint256[] memory) {
        return _peerCallPermits[peer];
    }

    //////////////////////
    // Setter functions //
    //////////////////////

    /**
     * @notice Function present in case of AWS KMS failure or migration. This allows the owner (multisig)
     * to set a new KMS admin wallet that will have privileges to add clients, contracts and functions and
     * update them.
     *
     * @param newKeyId It is the AWS GUID for the key that generates the {newWallet} public address.
     * @param newWallet The new wallet used for administrative purpose on Seraph. Only KMS wallets should be
     * given here unless AWS KMS failure occurs.
     */
    function setKMSAdminWallet(bytes16 newKeyId, address newWallet) external onlyOwner {
        require(newWallet != address(0), "Seraph: new kmsAdminWallet must be different than 0");
        address _old = kmsAdminWallet;

        kmsAdminWallet = newWallet;
        kmsAdminKeyId = newKeyId;

        emit NewAdminKMS(_old, newWallet);
    }

    /**
     * @notice It will change the wallet address for the given contract/function
     * to {newWallet}. Only seraph KMS admin wallet can call it ({onlySeraphAdmin}).
     * @dev Function should exist in order to change the {_wallet} value
     *
     * @param contractAddress The contract address that the wallet will be changed
     * @param functionSelector The function identifier that the wallet will be changed
     * @param newWallet The new wallet for this function that will generate permits
     */
    function setFunctionWallet(address contractAddress, bytes4 functionSelector, address newWallet) external onlySeraphAdmin contractExists(contractAddress) functionExists(contractAddress, functionSelector) {
        address _old = functions[contractAddress][functionSelector]._wallet;
        functions[contractAddress][functionSelector]._wallet = newWallet;
        emit NewFunctionWallet(contractAddress, functionSelector, _old, newWallet);
    }

    /**
     * @notice It will change the required peers for the given contract/function
     * to {newPeers}. Only seraph KMS admin wallet can call it ({onlySeraphAdmin}).
     * @dev Function should exist in order to change the {_requiredPeers} value
     *
     * @param contractAddress The contract address that the functionSelector is from
     * @param functionSelector The function identifier where the required peers will be changed
     * @param newPeers The new number of required peers
     */
    function setFunctionRequiredPeers(address contractAddress, bytes4 functionSelector, uint256 newPeers) external onlySeraphAdmin contractExists(contractAddress) functionExists(contractAddress, functionSelector) {
        functions[contractAddress][functionSelector]._requiredPeers = newPeers;
        emit NewFunctionPeers(contractAddress, functionSelector, newPeers);
    }

    /**
     * @notice It will change the name of a contract
     * Only seraph KMS admin wallet can call it ({onlySeraphAdmin}).
     * @dev Contract should exist in order to change the {_name} value
     *
     * @param contractAddress The contract address that the name will be changed
     * @param newName The new name to set the contract to
     */
    function setContractName(address contractAddress, string calldata newName) external onlySeraphAdmin contractExists(contractAddress) {
        string memory _old = contracts[contractAddress]._name;
        contracts[contractAddress]._name = newName;
        emit NewContractName(contractAddress, _old, newName);
    }

    /**
     * @notice It will change the client KMS key for a given client ID. This function
     * will be used to renew a client's key or to migrate.
     *
     * Only seraph KMS admin wallet can call it ({onlySeraphAdmin}).
     *
     * @dev Client should exist in order to change the kms wallet
     * The _kmsWalletsToClientID should be reflected as well, removing the old key
     * and storing the new reference
     *
     * @param clientId The client id to change the kms key for
     * @param newKmsId It is the AWS GUID for the key that generates the {kmsWallet} public address.
     * @param newKmsWallet The public address generated from the KMS ID key
     */
    function setClientKMSWallet(bytes4 clientId, bytes16 newKmsId, address newKmsWallet) external onlySeraphAdmin clientExists(clientId) {
        require(_kmsWalletsToClientID[newKmsWallet] == 0, "Seraph: KMS wallet already used");

        Client storage _client = clients[clientId];

        address _oldWallet = _client._kmsWallet;

        _client._kmsWallet = newKmsWallet;
        _client._kmsKeyID = newKmsId;

        _kmsWalletsToClientID[_oldWallet] = 0;

        emit NewClientKMS(clientId, _oldWallet, newKmsWallet);
    }

    /**
     * @notice It will change the protection state for the given {clientId} and set it
     * to {value}. Only seraph KMS admin wallet can call it ({onlySeraphAdmin}).
     * @dev Client should exist in order to change the {_isProtected} value
     *
     * @param clientId The client identifier that the protection will be changed
     * @param value The new protect state
     */
    function setClientProtected(bytes4 clientId, bool value) external onlySeraphAdmin clientExists(clientId) {
        clients[clientId]._isProtected = value;
        emit NewClientProtection(clientId, value);
    }

    /**
     * @notice It will change the protection state for the given {contractAddress} and set it
     * to {value}. Only seraph KMS admin wallet can call it ({onlySeraphAdmin}).
     * @dev Contract should exist in order to change the {_isProtected} value
     *
     * @param contractAddress The contract address that the protection will be changed
     * @param value The new protect state
     */
    function setContractProtected(address contractAddress, bool value) external onlySeraphAdmin contractExists(contractAddress) {
        contracts[contractAddress]._isProtected = value;
        emit NewContractProtection(contractAddress, value);
    }

    /**
     * @notice It will change the protection state for the given contract/function
     * and set it to {value}. Only seraph KMS admin wallet can call it ({onlySeraphAdmin}).
     * @dev Function should exist in order to change the {_isProtected} value
     *
     * @param contractAddress The contract address that the protection will be changed
     * @param functionSelector The function identifier that the protection will be changed
     * @param value The new protect state
     */
    function setFunctionProtected(address contractAddress, bytes4 functionSelector, bool value) external onlySeraphAdmin contractExists(contractAddress) functionExists(contractAddress, functionSelector) {
        functions[contractAddress][functionSelector]._isProtected = value;
        emit NewFunctionProtection(contractAddress, functionSelector, value);
    }

}