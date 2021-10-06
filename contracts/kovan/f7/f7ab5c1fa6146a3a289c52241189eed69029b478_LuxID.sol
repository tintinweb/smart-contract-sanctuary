/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// File: contracts/identity/interface/IERC734.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev interface of the ERC734 (Key Holder) standard as defined in the EIP.
 */
interface IERC734 {

    /**
     * @dev Emitted when an execution request was approved.
     *
     * Specification: MUST be triggered when approve was successfully called.
     */
    event Approved(uint256 indexed executionId, bool approved);

    /**
     * @dev Emitted when an execute operation was approved and successfully performed.
     *
     * Specification: MUST be triggered when approve was called and the execution was successfully approved.
     */
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when an execution request was performed via `execute`.
     *
     * Specification: MUST be triggered when execute was successfully called.
     */
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when a key was added to the Identity.
     *
     * Specification: MUST be triggered when addKey was successfully called.
     */
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when a key was removed from the Identity.
     *
     * Specification: MUST be triggered when removeKey was successfully called.
     */
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when the list of required keys to perform an action was updated.
     *
     * Specification: MUST be triggered when changeKeysRequired was successfully called.
     */
    event KeysRequiredChanged(uint256 purpose, uint256 number);


    /**
     * @dev Adds a _key to the identity. The _purpose specifies the purpose of the key.
     *
     * Triggers Event: `KeyAdded`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) external returns (bool success);

    /**
    * @dev Approves an execution or claim addition.
    *
    * Triggers Event: `Approved`, `Executed`
    *
    * Specification:
    * This SHOULD require n of m approvals of keys purpose 1, if the _to of the execution is the identity contract itself, to successfully approve an execution.
    * And COULD require n of m approvals of keys purpose 2, if the _to of the execution is another contract, to successfully approve an execution.
    */
    function approve(uint256 _id, bool _approve) external returns (bool success);

    /**
     * @dev Passes an execution instruction to an ERC725 identity.
     *
     * Triggers Event: `ExecutionRequested`, `Executed`
     *
     * Specification:
     * SHOULD require approve to be called with one or more keys of purpose 1 or 2 to approve this execution.
     * Execute COULD be used as the only accessor for `addKey` and `removeKey`.
     */
    function execute(address _to, uint256 _value, bytes calldata _data) external payable returns (uint256 executionId);

    /**
     * @dev Returns the full key data, if present in the identity.
     */
    function getKey(bytes32 _key) external view returns (uint256[] memory purposes, uint256 keyType, bytes32 key);

    /**
     * @dev Returns the list of purposes associated with a key.
     */
    function getKeyPurposes(bytes32 _key) external view returns(uint256[] memory _purposes);

    /**
     * @dev Returns an array of public key bytes32 held by this identity.
     */
    function getKeysByPurpose(uint256 _purpose) external view returns (bytes32[] memory keys);

    /**
     * @dev Returns TRUE if a key is present and has the given purpose. If the key is not present it returns FALSE.
     */
    function keyHasPurpose(bytes32 _key, uint256 _purpose) external view returns (bool exists);

    /**
     * @dev Removes _purpose for _key from the identity.
     *
     * Triggers Event: `KeyRemoved`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function removeKey(bytes32 _key, uint256 _purpose) external returns (bool success);
}

// File: contracts/identity/interface/IERC735.sol

/**
 * @dev interface of the ERC735 (Claim Holder) standard as defined in the EIP.
 */
interface IERC735 {

    /**
     * @dev Emitted when a claim request was performed.
     *
     * Specification: Is not clear
     */
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was added.
     *
     * Specification: MUST be triggered when a claim was successfully added.
     */
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was removed.
     *
     * Specification: MUST be triggered when removeClaim was successfully called.
     */
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was changed.
     *
     * Specification: MUST be triggered when changeClaim was successfully called.
     */
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Get a claim by its ID.
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function getClaim(bytes32 _claimId) external view returns(uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri);

    /**
     * @dev Returns an array of claim IDs by topic.
     */
    function getClaimIdsByTopic(uint256 _topic) external view returns(bytes32[] memory claimIds);

    /**
     * @dev Add or update a claim.
     *
     * Triggers Event: `ClaimRequested`, `ClaimAdded`, `ClaimChanged`
     *
     * Specification: Requests the ADDITION or the CHANGE of a claim from an issuer.
     * Claims can requested to be added by anybody, including the claim holder itself (self issued).
     *
     * _signature is a signed message of the following structure: `keccak256(abi.encode(address identityHolder_address, uint256 topic, bytes data))`.
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address + uint256 topic))`.
     *
     * This COULD implement an approval process for pending claims, or add them right away.
     * MUST return a claimRequestId (use claim ID) that COULD be sent to the approve function.
     */
    function addClaim(uint256 _topic, uint256 _scheme, address issuer, bytes calldata _signature, bytes calldata _data, string calldata _uri) external returns (bytes32 claimRequestId);

    /**
     * @dev Removes a claim.
     *
     * Triggers Event: `ClaimRemoved`
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function removeClaim(bytes32 _claimId) external returns (bool success);
}

// File: contracts/identity/interface/IIdentity.sol



interface IIdentity is IERC734, IERC735 {}

// File: contracts/identity/interface/IClaimIssuer.sol



interface IClaimIssuer is IIdentity {
    function revokeClaim(bytes32 _claimId, address _identity) external returns(bool);
    function getRecoveredAddress(bytes calldata sig, bytes32 dataHash) external pure returns (address);
    function isClaimRevoked(bytes calldata _sig) external view returns (bool);
    function isClaimValid(IIdentity _identity, uint256 claimTopic, bytes calldata sig, bytes calldata data) external view returns (bool);
}

// File: contracts/identity/proxy/access/Context.sol


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/identity/proxy/access/Ownable.sol


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/luxID/interface/IFactory.sol

pragma solidity ^0.8.0;

interface IFactory {
    function createIdentity(address _wallet) external returns (address);

    function isValidLuxID(address _identity) external view returns (bool);
}

// File: contracts/luxID/LuxID.sol




contract LuxID is Ownable {

    /// event emitted when an identity is registered
    event IdentityRegistered(address wallet, address identity);
    /// event emitted when a new issuer is added
    event TrustedIssuerAdded(address issuer, uint[] claimTopics);
    /// event emitted when an existing issuer is updated
    event TrustedIssuerUpdated(address issuer, uint[] claimTopics);
    /// event emitted when trust is revoked for an issuer
    event TrustedIssuerRemoved(address issuer);
    /// event emitted when a claim requirement pattern is created
    event ClaimRequirementAdded(uint checkType, uint[] claimTopics);
    /// event emitted when a claim requirement pattern is updated
    event ClaimRequirementUpdated(uint checkType, uint[] claimTopics);
    /// event emitted when the factory address is set
    event FactorySet(address _factory);

    /// address of the identity contracts factory
    address public factory;

    /// correspondence table linking wallets and identities
    mapping(address => address) public linkedIdentity;
    /// claims required to validate a pattern
    mapping(uint => uint[]) public requiredClaims;
    /// correspondence table linking trusted issuers and the claim topics they are trusted for
    mapping(address => uint[]) public trustedIssuerClaims;

    constructor () {
        // claim pattern corresponding to an owner role on the LuxID contract (similar to owner role)
        requiredClaims[1] = [42];
    }

    function setFactory(address _factory) external onlyOwner {
        factory = _factory;
        emit FactorySet(_factory);
    }

    /// function used by the factory to register a newly created identity with the wallet of the creator
    function registerIdentity (address _wallet, address _identity) public {
        // check if the caller of function is owner, factory or corresponding to the owner claim pattern
        require (msg.sender == factory || this.owner() == msg.sender || check(1, linkedIdentity[msg.sender])
        , 'invalid sender');
        // check if the wallet is already registered with an identity
        // one wallet cannot be linked to multiple identities
        require(linkedIdentity[_wallet] == address(0), 'wallet already registered');
        // link wallet with identity
        linkedIdentity[_wallet] = _identity;
        // emit event related to identity addition
        emit IdentityRegistered(_wallet, _identity);
    }

    /// function checking if a wallet is corresponding to an identity or not
    function isRegistered (address _wallet) public view returns (bool) {
        // check if the wallet is linked with an identity in the mapping
        if (linkedIdentity[_wallet] != address(0)){
            return true;
        }
        return false;
    }

    /// create a claim requirement pattern
    function requireClaims(uint _checkType, uint[] memory _claimTopics) external {
        // check if the caller of function is owner, factory or corresponding to the owner claim pattern
        require (this.owner() == msg.sender || check(1, linkedIdentity[msg.sender]), 'invalid sender');
        // check if the claim requirement pattern already exists,
        require ((requiredClaims[_checkType]).length == 0, 'checkType already exists');
        // set the array of topics corresponding to the pattern id
        requiredClaims[_checkType] = _claimTopics;
        emit ClaimRequirementAdded (_checkType, _claimTopics);
    }

    /// create a claim requirement pattern
    function updateRequiredClaims(uint _checkType, uint[] memory _claimTopics) external {
        // check if the caller of function is owner, factory or corresponding to the owner claim pattern
        require (this.owner() == msg.sender || check(1, linkedIdentity[msg.sender]), 'invalid sender');
        // check if the claim requirement pattern already exists,
        require ((requiredClaims[_checkType]).length != 0, 'checkType does not exist');
        // set the array of topics corresponding to the pattern id
        requiredClaims[_checkType] = _claimTopics;
        emit ClaimRequirementUpdated (_checkType, _claimTopics);
    }

    // function to check if an identity is valid for a claim pattern
    function check(uint _checkType, address _identity) public view returns(bool) {
        // check that the identity was deployed by the factory, other identities are not allowed
        require((IFactory(factory)).isValidLuxID(_identity), 'invalid identity contract');
        // fetch the claim topics required for this pattern
        uint[] memory requiredClaimTopics = requiredClaims[_checkType];
        // verify that the claim pattern to check exists
        require(requiredClaimTopics.length != 0, 'invalid checkType');
        // claim variables
        uint256 foundClaimTopic;
        uint256 scheme;
        address issuer;
        bytes memory sig;
        bytes memory data;
        uint256 claimTopic;
        // for loop on the claims required by the pattern
        for (claimTopic = 0; claimTopic < requiredClaimTopics.length; claimTopic++) {
            // fetch claim IDs held by the identity
            bytes32[] memory claimIds = (IIdentity(_identity)).getClaimIdsByTopic(requiredClaimTopics[claimTopic]);
            // if identity is not containing any claim, check is returning false
            if (claimIds.length == 0) {
                return false;
            }
            // for loop on the claims held by the identity to compare with the required claim currently checked
            for (uint256 j = 0; j < claimIds.length; j++) {
                (foundClaimTopic, scheme, issuer, sig, data, ) = (IIdentity(_identity)).getClaim(claimIds[j]);

                try IClaimIssuer(issuer).isClaimValid(IIdentity(_identity), requiredClaimTopics[claimTopic], sig,
                    data) returns(bool _validity){
                    if (
                        _validity
                        && hasClaimTopic(issuer, requiredClaimTopics[claimTopic])
                    ) {
                        j = claimIds.length;
                    }
                    if (!hasClaimTopic(issuer, requiredClaimTopics[claimTopic]) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!_validity && j == (claimIds.length - 1)) {
                        return false;
                    }
                }
                catch {
                    if (j == (claimIds.length - 1)) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    function checkWithClaims(uint[] calldata _claims, address _identity) public view returns(bool) {
        require((IFactory(factory)).isValidLuxID(_identity), 'invalid identity contract');
        uint[] memory requiredClaimTopics = _claims;
        require(requiredClaimTopics.length != 0, 'invalid checkType');
        uint256 foundClaimTopic;
        uint256 scheme;
        address issuer;
        bytes memory sig;
        bytes memory data;
        uint256 claimTopic;
        for (claimTopic = 0; claimTopic < requiredClaimTopics.length; claimTopic++) {
            bytes32[] memory claimIds = (IIdentity(_identity)).getClaimIdsByTopic(requiredClaimTopics[claimTopic]);
            if (claimIds.length == 0) {
                return false;
            }
            for (uint256 j = 0; j < claimIds.length; j++) {
                (foundClaimTopic, scheme, issuer, sig, data, ) = (IIdentity(_identity)).getClaim(claimIds[j]);

                try IClaimIssuer(issuer).isClaimValid(IIdentity(_identity), requiredClaimTopics[claimTopic], sig,
                    data) returns(bool _validity){
                    if (
                        _validity
                        && hasClaimTopic(issuer, requiredClaimTopics[claimTopic])
                    ) {
                        j = claimIds.length;
                    }
                    if (!hasClaimTopic(issuer, requiredClaimTopics[claimTopic]) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!_validity && j == (claimIds.length - 1)) {
                        return false;
                    }
                }
                catch {
                    if (j == (claimIds.length - 1)) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    function addTrustedIssuer(address _issuer, uint[] memory _claimTopics) external {
        require (this.owner() == msg.sender || check(1, linkedIdentity[msg.sender]), 'invalid sender');
        require ((trustedIssuerClaims[_issuer]).length == 0, 'trusted issuer already exists');
        trustedIssuerClaims[_issuer] = _claimTopics;
        emit TrustedIssuerAdded(_issuer, _claimTopics);
    }

    function removeTrustedIssuer(address _issuer) external {
        require (this.owner() == msg.sender || check(1, linkedIdentity[msg.sender]), 'invalid sender');
        require ((trustedIssuerClaims[_issuer]).length != 0, 'issuer does not exist');
        delete trustedIssuerClaims[_issuer];
        emit TrustedIssuerRemoved(_issuer);

    }

    function updateTrustedIssuer(address _issuer, uint[] memory _claimTopics) external {
        require (this.owner() == msg.sender || check(1, linkedIdentity[msg.sender]), 'invalid sender');
        require ((trustedIssuerClaims[_issuer]).length != 0, 'issuer does not exist');
        trustedIssuerClaims[_issuer] = _claimTopics;
        emit TrustedIssuerAdded(_issuer, _claimTopics);
    }

    function isTrustedIssuer(address _issuer) public view returns(bool) {
        if ((trustedIssuerClaims[_issuer]).length != 0){
            return true;
        }
        return false;
    }

    function hasClaimTopic(address _issuer, uint _topic) public view returns (bool) {
        require (isTrustedIssuer(_issuer), 'address is not issuer');
        uint length = trustedIssuerClaims[_issuer].length;
        uint[] memory claimTopics = trustedIssuerClaims[_issuer];
        for (uint256 i = 0; i < length; i++) {
            if (claimTopics[i] == _topic) {
                return true;
            }
        }
        return false;
    }

}