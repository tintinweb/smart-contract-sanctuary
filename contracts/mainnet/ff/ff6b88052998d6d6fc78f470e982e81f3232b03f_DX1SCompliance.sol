/**
 *Submitted for verification at Etherscan.io on 2020-10-15
*/

// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @tokenysolutions/t-rex/contracts/roles/Ownable.sol

pragma solidity 0.6.2;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @tokenysolutions/t-rex/contracts/compliance/ICompliance.sol

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2019, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.2;

interface ICompliance {

    /**
    *  this event is emitted when the Agent has been added on the allowedList of this Compliance.
    *  the event is emitted by the Compliance constructor and by the addTokenAgent function
    *  `_agentAddress` is the address of the Agent to add
    */
    event TokenAgentAdded(address _agentAddress);

    /**
    *  this event is emitted when the Agent has been removed from the agent list of this Compliance.
    *  the event is emitted by the Compliance constructor and by the removeTokenAgent function
    *  `_agentAddress` is the address of the Agent to remove
    */
    event TokenAgentRemoved(address _agentAddress);

    /**
    *  this event is emitted when a token has been bound to the compliance contract
    *  the event is emitted by the bindToken function
    *  `_token` is the address of the token to bind
    */
    event TokenBound(address _token);

    /**
    *  this event is emitted when a token has been unbound from the compliance contract
    *  the event is emitted by the unbindToken function
    *  `_token` is the address of the token to unbind
    */
    event TokenUnbound(address _token);

    /**
    *  @dev Returns true if the Address is in the list of token agents
    *  @param _agentAddress address of this agent
    */
    function isTokenAgent(address _agentAddress) external view returns (bool);

    /**
    *  @dev Returns true if the address given corresponds to a token that is bound with the Compliance contract
    *  @param _token address of the token
    */
    function isTokenBound(address _token) external view returns (bool);

    /**
     *  @dev adds an agent to the list of token agents
     *  @param _agentAddress address of the agent to be added
     *  Emits a TokenAgentAdded event
     */
    function addTokenAgent(address _agentAddress) external;

    /**
    *  @dev remove Agent from the list of token agents
    *  @param _agentAddress address of the agent to be removed (must be added first)
    *  Emits a TokenAgentRemoved event
    */
    function removeTokenAgent(address _agentAddress) external;

    /**
     *  @dev binds a token to the compliance contract
     *  @param _token address of the token to bind
     *  Emits a TokenBound event
     */
    function bindToken(address _token) external;

    /**
    *  @dev unbinds a token from the compliance contract
    *  @param _token address of the token to unbind
    *  Emits a TokenUnbound event
    */
    function unbindToken(address _token) external;


   /**
    *  @dev checks that the transfer is compliant.
    *  default compliance always returns true
    *  READ ONLY FUNCTION, this function cannot be used to increment
    *  counters, emit events, ...
    *  @param _from The address of the sender
    *  @param _to The address of the receiver
    *  @param _amount The amount of tokens involved in the transfer
    */
    function canTransfer(address _from, address _to, uint256 _amount) external view returns (bool);

   /**
    *  @dev function called whenever tokens are transferred
    *  from one wallet to another
    *  this function can update state variables in the compliance contract
    *  these state variables being used by `canTransfer` to decide if a transfer
    *  is compliant or not depending on the values stored in these state variables and on
    *  the parameters of the compliance smart contract
    *  @param _from The address of the sender
    *  @param _to The address of the receiver
    *  @param _amount The amount of tokens involved in the transfer
    */
    function transferred(address _from, address _to, uint256 _amount) external;

   /**
    *  @dev function called whenever tokens are created
    *  on a wallet
    *  this function can update state variables in the compliance contract
    *  these state variables being used by `canTransfer` to decide if a transfer
    *  is compliant or not depending on the values stored in these state variables and on
    *  the parameters of the compliance smart contract
    *  @param _to The address of the receiver
    *  @param _amount The amount of tokens involved in the transfer
    */
    function created(address _to, uint256 _amount) external;

   /**
    *  @dev function called whenever tokens are destroyed
    *  this function can update state variables in the compliance contract
    *  these state variables being used by `canTransfer` to decide if a transfer
    *  is compliant or not depending on the values stored in these state variables and on
    *  the parameters of the compliance smart contract
    *  @param _from The address of the receiver
    *  @param _amount The amount of tokens involved in the transfer
    */
    function destroyed(address _from, uint256 _amount) external;

   /**
    *  @dev function used to transfer the ownership of the compliance contract
    *  to a new owner, giving him access to the `OnlyOwner` functions implemented on the contract
    *  @param newOwner The address of the new owner of the compliance contract
    *  This function can only be called by the owner of the compliance contract
    *  emits an `OwnershipTransferred` event
    */
    function transferOwnershipOnComplianceContract(address newOwner) external;
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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

// File: @onchain-id/solidity/contracts/IERC734.sol

pragma solidity ^0.6.2;

/**
 * @dev Interface of the ERC734 (Key Holder) standard as defined in the EIP.
 */
interface IERC734 {
    /**
     * @dev Definition of the structure of a Key.
     *
     * Specification: Keys are cryptographic public keys, or contract addresses associated with this identity.
     * The structure should be as follows:
     *   - key: A public key owned by this identity
     *      - purposes: uint256[] Array of the key purposes, like 1 = MANAGEMENT, 2 = EXECUTION
     *      - keyType: The type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
     *      - key: bytes32 The public key. // Its the Keccak256 hash of the key
     */
    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }

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

// File: @onchain-id/solidity/contracts/IERC735.sol

pragma solidity ^0.6.2;

/**
 * @dev Interface of the ERC735 (Claim Holder) standard as defined in the EIP.
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
     * @dev Definition of the structure of a Claim.
     *
     * Specification: Claims are information an issuer has about the identity holder.
     * The structure should be as follows:
     *   - claim: A claim published for the Identity.
     *      - topic: A uint256 number which represents the topic of the claim. (e.g. 1 biometric, 2 residence (ToBeDefined: number schemes, sub topics based on number ranges??))
     *      - scheme : The scheme with which this claim SHOULD be verified or how it should be processed. Its a uint256 for different schemes. E.g. could 3 mean contract verification, where the data will be call data, and the issuer a contract address to call (ToBeDefined). Those can also mean different key types e.g. 1 = ECDSA, 2 = RSA, etc. (ToBeDefined)
     *      - issuer: The issuers identity contract address, or the address used to sign the above signature. If an identity contract, it should hold the key with which the above message was signed, if the key is not present anymore, the claim SHOULD be treated as invalid. The issuer can also be a contract address itself, at which the claim can be verified using the call data.
     *      - signature: Signature which is the proof that the claim issuer issued a claim of topic for this identity. it MUST be a signed message of the following structure: `keccak256(abi.encode(identityHolder_address, topic, data))`
     *      - data: The hash of the claim data, sitting in another location, a bit-mask, call data, or actual data based on the claim scheme.
     *      - uri: The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
     */
    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }

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

// File: @onchain-id/solidity/contracts/IIdentity.sol

pragma solidity ^0.6.2;



interface IIdentity is IERC734, IERC735 {}

// File: @onchain-id/solidity/contracts/IClaimIssuer.sol

pragma solidity ^0.6.2;


interface IClaimIssuer is IIdentity {
    function revokeClaim(bytes32 _claimId, address _identity) external returns(bool);
    function getRecoveredAddress(bytes calldata sig, bytes32 dataHash) external pure returns (address);
    function isClaimRevoked(bytes calldata _sig) external view returns (bool);
    function isClaimValid(IIdentity _identity, uint256 claimTopic, bytes calldata sig, bytes calldata data) external view returns (bool);
}

// File: @tokenysolutions/t-rex/contracts/registry/ITrustedIssuersRegistry.sol

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2019, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.2;


interface ITrustedIssuersRegistry {

   /**
    *  this event is emitted when a trusted issuer is added in the registry.
    *  the event is emitted by the addTrustedIssuer function
    *  `trustedIssuer` is the address of the trusted issuer's ClaimIssuer contract
    *  `claimTopics` is the set of claims that the trusted issuer is allowed to emit
    */
    event TrustedIssuerAdded(IClaimIssuer indexed trustedIssuer, uint[] claimTopics);

   /**
    *  this event is emitted when a trusted issuer is removed from the registry.
    *  the event is emitted by the removeTrustedIssuer function
    *  `trustedIssuer` is the address of the trusted issuer's ClaimIssuer contract
    */
    event TrustedIssuerRemoved(IClaimIssuer indexed trustedIssuer);

   /**
    *  this event is emitted when the set of claim topics is changed for a given trusted issuer.
    *  the event is emitted by the updateIssuerClaimTopics function
    *  `trustedIssuer` is the address of the trusted issuer's ClaimIssuer contract
    *  `claimTopics` is the set of claims that the trusted issuer is allowed to emit
    */
    event ClaimTopicsUpdated(IClaimIssuer indexed trustedIssuer, uint[] claimTopics);

   /**
    *  @dev registers a ClaimIssuer contract as trusted claim issuer.
    *  Requires that a ClaimIssuer contract doesn't already exist
    *  Requires that the claimTopics set is not empty
    *  @param _trustedIssuer The ClaimIssuer contract address of the trusted claim issuer.
    *  @param _claimTopics the set of claim topics that the trusted issuer is allowed to emit
    *  This function can only be called by the owner of the Trusted Issuers Registry contract
    *  emits a `TrustedIssuerAdded` event
    */
    function addTrustedIssuer(IClaimIssuer _trustedIssuer, uint[] calldata _claimTopics) external;

   /**
    *  @dev Removes the ClaimIssuer contract of a trusted claim issuer.
    *  Requires that the claim issuer contract to be registered first
    *  @param _trustedIssuer the claim issuer to remove.
    *  This function can only be called by the owner of the Trusted Issuers Registry contract
    *  emits a `TrustedIssuerRemoved` event
    */
    function removeTrustedIssuer(IClaimIssuer _trustedIssuer) external;

   /**
    *  @dev Updates the set of claim topics that a trusted issuer is allowed to emit.
    *  Requires that this ClaimIssuer contract already exists in the registry
    *  Requires that the provided claimTopics set is not empty
    *  @param _trustedIssuer the claim issuer to update.
    *  @param _claimTopics the set of claim topics that the trusted issuer is allowed to emit
    *  This function can only be called by the owner of the Trusted Issuers Registry contract
    *  emits a `ClaimTopicsUpdated` event
    */
    function updateIssuerClaimTopics(IClaimIssuer _trustedIssuer, uint[] calldata _claimTopics) external;

   /**
    *  @dev Function for getting all the trusted claim issuers stored.
    *  @return array of all claim issuers registered.
    */
    function getTrustedIssuers() external view returns (IClaimIssuer[] memory);

   /**
    *  @dev Checks if the ClaimIssuer contract is trusted
    *  @param _issuer the address of the ClaimIssuer contract
    *  @return true if the issuer is trusted, false otherwise.
    */
    function isTrustedIssuer(address _issuer) external view returns(bool);

   /**
    *  @dev Function for getting all the claim topic of trusted claim issuer
    *  Requires the provided ClaimIssuer contract to be registered in the trusted issuers registry.
    *  @param _trustedIssuer the trusted issuer concerned.
    *  @return The set of claim topics that the trusted issuer is allowed to emit
    */
    function getTrustedIssuerClaimTopics(IClaimIssuer _trustedIssuer) external view returns(uint[] memory);

   /**
    *  @dev Function for checking if the trusted claim issuer is allowed
    *  to emit a certain claim topic
    *  @param _issuer the address of the trusted issuer's ClaimIssuer contract
    *  @param _claimTopic the Claim Topic that has to be checked to know if the `issuer` is allowed to emit it
    *  @return true if the issuer is trusted for this claim topic.
    */
    function hasClaimTopic(address _issuer, uint _claimTopic) external view returns(bool);

   /**
    *  @dev Transfers the Ownership of TrustedIssuersRegistry to a new Owner.
    *  @param _newOwner The new owner of this contract.
    *  This function can only be called by the owner of the Trusted Issuers Registry contract
    *  emits an `OwnershipTransferred` event
    */
    function transferOwnershipOnIssuersRegistryContract(address _newOwner) external;
}

// File: @tokenysolutions/t-rex/contracts/registry/IClaimTopicsRegistry.sol

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2019, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.2;

interface IClaimTopicsRegistry {

   /**
    *  this event is emitted when a claim topic has been added to the ClaimTopicsRegistry
    *  the event is emitted by the 'addClaimTopic' function
    *  `claimTopic` is the required claim added to the Claim Topics Registry
    */
    event ClaimTopicAdded(uint256 indexed claimTopic);

   /**
    *  this event is emitted when a claim topic has been removed from the ClaimTopicsRegistry
    *  the event is emitted by the 'removeClaimTopic' function
    *  `claimTopic` is the required claim removed from the Claim Topics Registry
    */
    event ClaimTopicRemoved(uint256 indexed claimTopic);

   /**
    * @dev Add a trusted claim topic (For example: KYC=1, AML=2).
    * Only owner can call.
    * emits `ClaimTopicAdded` event
    * @param _claimTopic The claim topic index
    */
    function addClaimTopic(uint256 _claimTopic) external;

   /**
    *  @dev Remove a trusted claim topic (For example: KYC=1, AML=2).
    *  Only owner can call.
    *  emits `ClaimTopicRemoved` event
    *  @param _claimTopic The claim topic index
    */
    function removeClaimTopic(uint256 _claimTopic) external;

   /**
    *  @dev Get the trusted claim topics for the security token
    *  @return Array of trusted claim topics
    */
    function getClaimTopics() external view returns (uint256[] memory);

   /**
    *  @dev Transfers the Ownership of ClaimTopics to a new Owner.
    *  Only owner can call.
    *  @param _newOwner The new owner of this contract.
    */
    function transferOwnershipOnClaimTopicsRegistryContract(address _newOwner) external;
}

// File: @tokenysolutions/t-rex/contracts/registry/IIdentityRegistryStorage.sol

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2019, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.2;


interface IIdentityRegistryStorage {

   /**
    *  this event is emitted when an Identity is registered into the storage contract.
    *  the event is emitted by the 'registerIdentity' function
    *  `investorAddress` is the address of the investor's wallet
    *  `identity` is the address of the Identity smart contract (onchainID)
    */
    event IdentityStored(address indexed investorAddress, IIdentity indexed identity);

   /**
    *  this event is emitted when an Identity is removed from the storage contract.
    *  the event is emitted by the 'deleteIdentity' function
    *  `investorAddress` is the address of the investor's wallet
    *  `identity` is the address of the Identity smart contract (onchainID)
    */
    event IdentityUnstored(address indexed investorAddress, IIdentity indexed identity);

   /**
    *  this event is emitted when an Identity has been updated
    *  the event is emitted by the 'updateIdentity' function
    *  `oldIdentity` is the old Identity contract's address to update
    *  `newIdentity` is the new Identity contract's
    */
    event IdentityModified(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);

   /**
    *  this event is emitted when an Identity's country has been updated
    *  the event is emitted by the 'updateCountry' function
    *  `investorAddress` is the address on which the country has been updated
    *  `country` is the numeric code (ISO 3166-1) of the new country
    */
    event CountryModified(address indexed investorAddress, uint16 indexed country);

   /**
    *  this event is emitted when an Identity Registry is bound to the storage contract
    *  the event is emitted by the 'addIdentityRegistry' function
    *  `identityRegistry` is the address of the identity registry added
    */
    event IdentityRegistryBound(address indexed identityRegistry);

   /**
    *  this event is emitted when an Identity Registry is unbound from the storage contract
    *  the event is emitted by the 'removeIdentityRegistry' function
    *  `identityRegistry` is the address of the identity registry removed
    */
    event IdentityRegistryUnbound(address indexed identityRegistry);

   /**
    *  @dev Returns the identity registries linked to the storage contract
    */
    function linkedIdentityRegistries() external view returns (address[] memory);

   /**
    *  @dev Returns the onchainID of an investor.
    *  @param _userAddress The wallet of the investor
    */
    function storedIdentity(address _userAddress) external view returns (IIdentity);

   /**
    *  @dev Returns the country code of an investor.
    *  @param _userAddress The wallet of the investor
    */
    function storedInvestorCountry(address _userAddress) external view returns (uint16);

   /**
    *  @dev adds an identity contract corresponding to a user address in the storage.
    *  Requires that the user doesn't have an identity contract already registered.
    *  This function can only be called by an address set as agent of the smart contract
    *  @param _userAddress The address of the user
    *  @param _identity The address of the user's identity contract
    *  @param _country The country of the investor
    *  emits `IdentityStored` event
    */
    function addIdentityToStorage(address _userAddress, IIdentity _identity, uint16 _country) external;

   /**
    *  @dev Removes an user from the storage.
    *  Requires that the user have an identity contract already deployed that will be deleted.
    *  This function can only be called by an address set as agent of the smart contract
    *  @param _userAddress The address of the user to be removed
    *  emits `IdentityUnstored` event
    */
    function removeIdentityFromStorage(address _userAddress) external;

   /**
    *  @dev Updates the country corresponding to a user address.
    *  Requires that the user should have an identity contract already deployed that will be replaced.
    *  This function can only be called by an address set as agent of the smart contract
    *  @param _userAddress The address of the user
    *  @param _country The new country of the user
    *  emits `CountryModified` event
    */
    function modifyStoredInvestorCountry(address _userAddress, uint16 _country) external;

   /**
    *  @dev Updates an identity contract corresponding to a user address.
    *  Requires that the user address should be the owner of the identity contract.
    *  Requires that the user should have an identity contract already deployed that will be replaced.
    *  This function can only be called by an address set as agent of the smart contract
    *  @param _userAddress The address of the user
    *  @param _identity The address of the user's new identity contract
    *  emits `IdentityModified` event
    */
    function modifyStoredIdentity(address _userAddress, IIdentity _identity) external;

   /**
    *  @notice Transfers the Ownership of the Identity Registry Storage to a new Owner.
    *  This function can only be called by the wallet set as owner of the smart contract
    *  @param _newOwner The new owner of this contract.
    */
    function transferOwnershipOnIdentityRegistryStorage(address _newOwner) external;

   /**
    *  @notice Adds an identity registry as agent of the Identity Registry Storage Contract.
    *  This function can only be called by the wallet set as owner of the smart contract
    *  This function adds the identity registry to the list of identityRegistries linked to the storage contract
    *  @param _identityRegistry The identity registry address to add.
    */
    function bindIdentityRegistry(address _identityRegistry) external;

   /**
    *  @notice Removes an identity registry from being agent of the Identity Registry Storage Contract.
    *  This function can only be called by the wallet set as owner of the smart contract
    *  This function removes the identity registry from the list of identityRegistries linked to the storage contract
    *  @param _identityRegistry The identity registry address to remove.
    */
    function unbindIdentityRegistry(address _identityRegistry) external;
}

// File: @tokenysolutions/t-rex/contracts/registry/IIdentityRegistry.sol

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2019, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.2;






interface IIdentityRegistry {

   /**
    *  this event is emitted when the ClaimTopicsRegistry has been set for the IdentityRegistry
    *  the event is emitted by the IdentityRegistry constructor
    *  `claimTopicsRegistry` is the address of the Claim Topics Registry contract
    */
    event ClaimTopicsRegistrySet(address indexed claimTopicsRegistry);

   /**
    *  this event is emitted when the IdentityRegistryStorage has been set for the IdentityRegistry
    *  the event is emitted by the IdentityRegistry constructor
    *  `identityStorage` is the address of the Identity Registry Storage contract
    */
    event IdentityStorageSet(address indexed identityStorage);

   /**
    *  this event is emitted when the ClaimTopicsRegistry has been set for the IdentityRegistry
    *  the event is emitted by the IdentityRegistry constructor
    *  `trustedIssuersRegistry` is the address of the Trusted Issuers Registry contract
    */
    event TrustedIssuersRegistrySet(address indexed trustedIssuersRegistry);

   /**
    *  this event is emitted when an Identity is registered into the Identity Registry.
    *  the event is emitted by the 'registerIdentity' function
    *  `investorAddress` is the address of the investor's wallet
    *  `identity` is the address of the Identity smart contract (onchainID)
    */
    event IdentityRegistered(address indexed investorAddress, IIdentity indexed identity);

   /**
    *  this event is emitted when an Identity is removed from the Identity Registry.
    *  the event is emitted by the 'deleteIdentity' function
    *  `investorAddress` is the address of the investor's wallet
    *  `identity` is the address of the Identity smart contract (onchainID)
    */
    event IdentityRemoved(address indexed investorAddress, IIdentity indexed identity);

   /**
    *  this event is emitted when an Identity has been updated
    *  the event is emitted by the 'updateIdentity' function
    *  `oldIdentity` is the old Identity contract's address to update
    *  `newIdentity` is the new Identity contract's
    */
    event IdentityUpdated(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);

   /**
    *  this event is emitted when an Identity's country has been updated
    *  the event is emitted by the 'updateCountry' function
    *  `investorAddress` is the address on which the country has been updated
    *  `country` is the numeric code (ISO 3166-1) of the new country
    */
    event CountryUpdated(address indexed investorAddress, uint16 indexed country);

   /**
    *  @dev Register an identity contract corresponding to a user address.
    *  Requires that the user doesn't have an identity contract already registered.
    *  This function can only be called by a wallet set as agent of the smart contract
    *  @param _userAddress The address of the user
    *  @param _identity The address of the user's identity contract
    *  @param _country The country of the investor
    *  emits `IdentityRegistered` event
    */
    function registerIdentity(address _userAddress, IIdentity _identity, uint16 _country) external;

   /**
    *  @dev Removes an user from the identity registry.
    *  Requires that the user have an identity contract already deployed that will be deleted.
    *  This function can only be called by a wallet set as agent of the smart contract
    *  @param _userAddress The address of the user to be removed
    *  emits `IdentityRemoved` event
    */
    function deleteIdentity(address _userAddress) external;

   /**
    *  @dev Replace the actual identityRegistryStorage contract with a new one.
    *  This function can only be called by the wallet set as owner of the smart contract
    *  @param _identityRegistryStorage The address of the new Identity Registry Storage
    *  emits `IdentityStorageSet` event
    */
    function setIdentityRegistryStorage(address _identityRegistryStorage) external;

   /**
    *  @dev Replace the actual claimTopicsRegistry contract with a new one.
    *  This function can only be called by the wallet set as owner of the smart contract
    *  @param _claimTopicsRegistry The address of the new claim Topics Registry
    *  emits `ClaimTopicsRegistrySet` event
    */
    function setClaimTopicsRegistry(address _claimTopicsRegistry) external;

   /**
    *  @dev Replace the actual trustedIssuersRegistry contract with a new one.
    *  This function can only be called by the wallet set as owner of the smart contract
    *  @param _trustedIssuersRegistry The address of the new Trusted Issuers Registry
    *  emits `TrustedIssuersRegistrySet` event
    */
    function setTrustedIssuersRegistry(address _trustedIssuersRegistry) external;

   /**
    *  @dev Updates the country corresponding to a user address.
    *  Requires that the user should have an identity contract already deployed that will be replaced.
    *  This function can only be called by a wallet set as agent of the smart contract
    *  @param _userAddress The address of the user
    *  @param _country The new country of the user
    *  emits `CountryUpdated` event
    */
    function updateCountry(address _userAddress, uint16 _country) external;

   /**
    *  @dev Updates an identity contract corresponding to a user address.
    *  Requires that the user address should be the owner of the identity contract.
    *  Requires that the user should have an identity contract already deployed that will be replaced.
    *  This function can only be called by a wallet set as agent of the smart contract
    *  @param _userAddress The address of the user
    *  @param _identity The address of the user's new identity contract
    *  emits `IdentityUpdated` event
    */
    function updateIdentity(address _userAddress, IIdentity _identity) external;

   /**
    *  @dev function allowing to register identities in batch
    *  This function can only be called by a wallet set as agent of the smart contract
    *  Requires that none of the users has an identity contract already registered.
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _userAddresses The addresses of the users
    *  @param _identities The addresses of the corresponding identity contracts
    *  @param _countries The countries of the corresponding investors
    *  emits _userAddresses.length `IdentityRegistered` events
    */
    function batchRegisterIdentity(address[] calldata _userAddresses, IIdentity[] calldata _identities, uint16[] calldata _countries) external;

   /**
    *  @dev This functions checks whether a wallet has its Identity registered or not
    *  in the Identity Registry.
    *  @param _userAddress The address of the user to be checked.
    *  @return 'True' if the address is contained in the Identity Registry, 'false' if not.
    */
    function contains(address _userAddress) external view returns (bool);

   /**
    *  @dev This functions checks whether an identity contract
    *  corresponding to the provided user address has the required claims or not based
    *  on the data fetched from trusted issuers registry and from the claim topics registry
    *  @param _userAddress The address of the user to be verified.
    *  @return 'True' if the address is verified, 'false' if not.
    */
    function isVerified(address _userAddress) external view returns (bool);

   /**
    *  @dev Returns the onchainID of an investor.
    *  @param _userAddress The wallet of the investor
    */
    function identity(address _userAddress) external view returns (IIdentity);

   /**
    *  @dev Returns the country code of an investor.
    *  @param _userAddress The wallet of the investor
    */
    function investorCountry(address _userAddress) external view returns (uint16);

   /**
    *  @dev Returns the IdentityRegistryStorage linked to the current IdentityRegistry.
    */
    function identityStorage() external view returns (IIdentityRegistryStorage);

   /**
    *  @dev Returns the TrustedIssuersRegistry linked to the current IdentityRegistry.
    */
    function issuersRegistry() external view returns (ITrustedIssuersRegistry);

   /**
    *  @dev Returns the ClaimTopicsRegistry linked to the current IdentityRegistry.
    */
    function topicsRegistry() external view returns (IClaimTopicsRegistry);

   /**
    *  @notice Transfers the Ownership of the Identity Registry to a new Owner.
    *  This function can only be called by the wallet set as owner of the smart contract
    *  @param _newOwner The new owner of this contract.
    */
    function transferOwnershipOnIdentityRegistryContract(address _newOwner) external;

   /**
    *  @notice Adds an address as _agent of the Identity Registry Contract.
    *  This function can only be called by the wallet set as owner of the smart contract
    *  @param _agent The _agent's address to add.
    */
    function addAgentOnIdentityRegistryContract(address _agent) external;

   /**
    *  @notice Removes an address from being _agent of the Identity Registry Contract.
    *  This function can only be called by the wallet set as owner of the smart contract
    *  @param _agent The _agent's address to remove.
    */
    function removeAgentOnIdentityRegistryContract(address _agent) external;
}

// File: @tokenysolutions/t-rex/contracts/token/IToken.sol

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2019, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.2;




///interface
interface IToken is IERC20 {

   /**
    *  this event is emitted when the token information is updated.
    *  the event is emitted by the token constructor and by the setTokenInformation function
    *  `_newName` is the name of the token
    *  `_newSymbol` is the symbol of the token
    *  `_newDecimals` is the decimals of the token
    *  `_newVersion` is the version of the token, current version is 3.0
    *  `_newOnchainID` is the address of the onchainID of the token
    */
    event UpdatedTokenInformation(string _newName, string _newSymbol, uint8 _newDecimals, string _newVersion, address _newOnchainID);

   /**
    *  this event is emitted when the IdentityRegistry has been set for the token
    *  the event is emitted by the token constructor and by the setIdentityRegistry function
    *  `_identityRegistry` is the address of the Identity Registry of the token
    */
    event IdentityRegistryAdded(address indexed _identityRegistry);

   /**
    *  this event is emitted when the Compliance has been set for the token
    *  the event is emitted by the token constructor and by the setCompliance function
    *  `_compliance` is the address of the Compliance contract of the token
    */
    event ComplianceAdded(address indexed _compliance);

   /**
    *  this event is emitted when an investor successfully recovers his tokens
    *  the event is emitted by the recoveryAddress function
    *  `_lostWallet` is the address of the wallet that the investor lost access to
    *  `_newWallet` is the address of the wallet that the investor provided for the recovery
    *  `_investorOnchainID` is the address of the onchainID of the investor who asked for a recovery
    */
    event RecoverySuccess(address _lostWallet, address _newWallet, address _investorOnchainID);

   /**
    *  this event is emitted when the wallet of an investor is frozen or unfrozen
    *  the event is emitted by setAddressFrozen and batchSetAddressFrozen functions
    *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
    *  `_isFrozen` is the freezing status of the wallet
    *  if `_isFrozen` equals `true` the wallet is frozen after emission of the event
    *  if `_isFrozen` equals `false` the wallet is unfrozen after emission of the event
    *  `_owner` is the address of the agent who called the function to freeze the wallet
    */
    event AddressFrozen(address indexed _userAddress, bool indexed _isFrozen, address indexed _owner);

   /**
    *  this event is emitted when a certain amount of tokens is frozen on a wallet
    *  the event is emitted by freezePartialTokens and batchFreezePartialTokens functions
    *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
    *  `_amount` is the amount of tokens that are frozen
    */
    event TokensFrozen(address indexed _userAddress, uint256 _amount);

   /**
    *  this event is emitted when a certain amount of tokens is unfrozen on a wallet
    *  the event is emitted by unfreezePartialTokens and batchUnfreezePartialTokens functions
    *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
    *  `_amount` is the amount of tokens that are unfrozen
    */
    event TokensUnfrozen(address indexed _userAddress, uint256 _amount);

   /**
    *  this event is emitted when the token is paused
    *  the event is emitted by the pause function
    *  `_userAddress` is the address of the wallet that called the pause function
    */
    event Paused(address _userAddress);

   /**
    *  this event is emitted when the token is unpaused
    *  the event is emitted by the unpause function
    *  `_userAddress` is the address of the wallet that called the unpause function
    */
    event Unpaused(address _userAddress);

   /**
    * @dev Returns the number of decimals used to get its user representation.
    * For example, if `decimals` equals `2`, a balance of `505` tokens should
    * be displayed to a user as `5,05` (`505 / 1 ** 2`).
    *
    * Tokens usually opt for a value of 18, imitating the relationship between
    * Ether and Wei.
    *
    * NOTE: This information is only used for _display_ purposes: it in
    * no way affects any of the arithmetic of the contract, including
    * balanceOf() and transfer().
    */
    function decimals() external view returns (uint8);

   /**
    * @dev Returns the name of the token.
    */
    function name() external view returns (string memory);

   /**
    * @dev Returns the address of the onchainID of the token.
    * the onchainID of the token gives all the information available
    * about the token and is managed by the token issuer or his agent.
    */
    function onchainID() external view returns (address);

   /**
    * @dev Returns the symbol of the token, usually a shorter version of the
    * name.
    */
    function symbol() external view returns (string memory);

   /**
    * @dev Returns the TREX version of the token.
    * current version is 3.0.0
    */
    function version() external view returns (string memory);

   /**
    *  @dev Returns the Identity Registry linked to the token
    */
    function identityRegistry() external view returns (IIdentityRegistry);

   /**
    *  @dev Returns the Compliance contract linked to the token
    */
    function compliance() external view returns (ICompliance);

   /**
    * @dev Returns true if the contract is paused, and false otherwise.
    */
    function paused() external view returns (bool);

   /**
    *  @dev Returns the freezing status of a wallet
    *  if isFrozen returns `true` the wallet is frozen
    *  if isFrozen returns `false` the wallet is not frozen
    *  isFrozen returning `true` doesn't mean that the balance is free, tokens could be blocked by
    *  a partial freeze or the whole token could be blocked by pause
    *  @param _userAddress the address of the wallet on which isFrozen is called
    */
    function isFrozen(address _userAddress) external view returns (bool);

   /**
    *  @dev Returns the amount of tokens that are partially frozen on a wallet
    *  the amount of frozen tokens is always <= to the total balance of the wallet
    *  @param _userAddress the address of the wallet on which getFrozenTokens is called
    */
    function getFrozenTokens(address _userAddress) external view returns (uint256);

   /**
    *  @dev sets the token name
    *  @param _name the name of token to set
    *  Only the owner of the token smart contract can call this function
    *  emits a `UpdatedTokenInformation` event
    */
    function setName(string calldata _name) external;

   /**
    *  @dev sets the token symbol
    *  @param _symbol the token symbol to set
    *  Only the owner of the token smart contract can call this function
    *  emits a `UpdatedTokenInformation` event
    */
    function setSymbol(string calldata _symbol) external;

   /**
    *  @dev sets the onchain ID of the token
    *  @param _onchainID the address of the onchain ID to set
    *  Only the owner of the token smart contract can call this function
    *  emits a `UpdatedTokenInformation` event
    */
    function setOnchainID(address _onchainID) external;

   /**
    *  @dev pauses the token contract, when contract is paused investors cannot transfer tokens anymore
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `Paused` event
    */
    function pause() external;

   /**
    *  @dev unpauses the token contract, when contract is unpaused investors can transfer tokens
    *  if their wallet is not blocked & if the amount to transfer is <= to the amount of free tokens
    *  This function can only be called by a wallet set as agent of the token
    *  emits an `Unpaused` event
    */
    function unpause() external;

   /**
    *  @dev sets an address frozen status for this token.
    *  @param _userAddress The address for which to update frozen status
    *  @param _freeze Frozen status of the address
    *  This function can only be called by a wallet set as agent of the token
    *  emits an `AddressFrozen` event
    */
    function setAddressFrozen(address _userAddress, bool _freeze) external;

   /**
    *  @dev freezes token amount specified for given address.
    *  @param _userAddress The address for which to update frozen tokens
    *  @param _amount Amount of Tokens to be frozen
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `TokensFrozen` event
    */
    function freezePartialTokens(address _userAddress, uint256 _amount) external;

   /**
    *  @dev unfreezes token amount specified for given address
    *  @param _userAddress The address for which to update frozen tokens
    *  @param _amount Amount of Tokens to be unfrozen
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `TokensUnfrozen` event
    */
    function unfreezePartialTokens(address _userAddress, uint256 _amount) external;

   /**
    *  @dev sets the Identity Registry for the token
    *  @param _identityRegistry the address of the Identity Registry to set
    *  Only the owner of the token smart contract can call this function
    *  emits an `IdentityRegistryAdded` event
    */
    function setIdentityRegistry(address _identityRegistry) external;

   /**
    *  @dev sets the compliance contract of the token
    *  @param _compliance the address of the compliance contract to set
    *  Only the owner of the token smart contract can call this function
    *  emits a `ComplianceAdded` event
    */
    function setCompliance(address _compliance) external;

   /**
    *  @dev force a transfer of tokens between 2 whitelisted wallets
    *  In case the `from` address has not enough free tokens (unfrozen tokens)
    *  but has a total balance higher or equal to the `amount`
    *  the amount of frozen tokens is reduced in order to have enough free tokens
    *  to proceed the transfer, in such a case, the remaining balance on the `from`
    *  account is 100% composed of frozen tokens post-transfer.
    *  Require that the `to` address is a verified address,
    *  @param _from The address of the sender
    *  @param _to The address of the receiver
    *  @param _amount The number of tokens to transfer
    *  @return `true` if successful and revert if unsuccessful
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `TokensUnfrozen` event if `_amount` is higher than the free balance of `_from`
    *  emits a `Transfer` event
    */
    function forcedTransfer(address _from, address _to, uint256 _amount) external returns (bool);

   /**
    *  @dev mint tokens on a wallet
    *  Improved version of default mint method. Tokens can be minted
    *  to an address if only it is a verified address as per the security token.
    *  @param _to Address to mint the tokens to.
    *  @param _amount Amount of tokens to mint.
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `Transfer` event
    */
    function mint(address _to, uint256 _amount) external;

   /**
    *  @dev burn tokens on a wallet
    *  In case the `account` address has not enough free tokens (unfrozen tokens)
    *  but has a total balance higher or equal to the `value` amount
    *  the amount of frozen tokens is reduced in order to have enough free tokens
    *  to proceed the burn, in such a case, the remaining balance on the `account`
    *  is 100% composed of frozen tokens post-transaction.
    *  @param _userAddress Address to burn the tokens from.
    *  @param _amount Amount of tokens to burn.
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `TokensUnfrozen` event if `_amount` is higher than the free balance of `_userAddress`
    *  emits a `Transfer` event
    */
    function burn(address _userAddress, uint256 _amount) external;

   /**
    *  @dev recovery function used to force transfer tokens from a
    *  lost wallet to a new wallet for an investor.
    *  @param _lostWallet the wallet that the investor lost
    *  @param _newWallet the newly provided wallet on which tokens have to be transferred
    *  @param _investorOnchainID the onchainID of the investor asking for a recovery
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `TokensUnfrozen` event if there is some frozen tokens on the lost wallet if the recovery process is successful
    *  emits a `Transfer` event if the recovery process is successful
    *  emits a `RecoverySuccess` event if the recovery process is successful
    *  emits a `RecoveryFails` event if the recovery process fails
    */
    function recoveryAddress(address _lostWallet, address _newWallet, address _investorOnchainID) external returns (bool);

   /**
    *  @dev function allowing to issue transfers in batch
    *  Require that the msg.sender and `to` addresses are not frozen.
    *  Require that the total value should not exceed available balance.
    *  Require that the `to` addresses are all verified addresses,
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_toList.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _toList The addresses of the receivers
    *  @param _amounts The number of tokens to transfer to the corresponding receiver
    *  emits _toList.length `Transfer` events
    */
    function batchTransfer(address[] calldata _toList, uint256[] calldata _amounts) external;

   /**
    *  @dev function allowing to issue forced transfers in batch
    *  Require that `_amounts[i]` should not exceed available balance of `_fromList[i]`.
    *  Require that the `_toList` addresses are all verified addresses
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_fromList.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _fromList The addresses of the senders
    *  @param _toList The addresses of the receivers
    *  @param _amounts The number of tokens to transfer to the corresponding receiver
    *  This function can only be called by a wallet set as agent of the token
    *  emits `TokensUnfrozen` events if `_amounts[i]` is higher than the free balance of `_fromList[i]`
    *  emits _fromList.length `Transfer` events
    */
    function batchForcedTransfer(address[] calldata _fromList, address[] calldata _toList, uint256[] calldata _amounts) external;

   /**
    *  @dev function allowing to mint tokens in batch
    *  Require that the `_toList` addresses are all verified addresses
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_toList.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _toList The addresses of the receivers
    *  @param _amounts The number of tokens to mint to the corresponding receiver
    *  This function can only be called by a wallet set as agent of the token
    *  emits _toList.length `Transfer` events
    */
    function batchMint(address[] calldata _toList, uint256[] calldata _amounts) external;

   /**
    *  @dev function allowing to burn tokens in batch
    *  Require that the `_userAddresses` addresses are all verified addresses
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _userAddresses The addresses of the wallets concerned by the burn
    *  @param _amounts The number of tokens to burn from the corresponding wallets
    *  This function can only be called by a wallet set as agent of the token
    *  emits _userAddresses.length `Transfer` events
    */
    function batchBurn(address[] calldata _userAddresses, uint256[] calldata _amounts) external;

   /**
    *  @dev function allowing to set frozen addresses in batch
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _userAddresses The addresses for which to update frozen status
    *  @param _freeze Frozen status of the corresponding address
    *  This function can only be called by a wallet set as agent of the token
    *  emits _userAddresses.length `AddressFrozen` events
    */
    function batchSetAddressFrozen(address[] calldata _userAddresses, bool[] calldata _freeze) external;

   /**
    *  @dev function allowing to freeze tokens partially in batch
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _userAddresses The addresses on which tokens need to be frozen
    *  @param _amounts the amount of tokens to freeze on the corresponding address
    *  This function can only be called by a wallet set as agent of the token
    *  emits _userAddresses.length `TokensFrozen` events
    */
    function batchFreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _amounts) external;

   /**
    *  @dev function allowing to unfreeze tokens partially in batch
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _userAddresses The addresses on which tokens need to be unfrozen
    *  @param _amounts the amount of tokens to unfreeze on the corresponding address
    *  This function can only be called by a wallet set as agent of the token
    *  emits _userAddresses.length `TokensUnfrozen` events
    */
    function batchUnfreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _amounts) external;

   /**
    *  @dev transfers the ownership of the token smart contract
    *  @param _newOwner the address of the new token smart contract owner
    *  This function can only be called by the owner of the token
    *  emits an `OwnershipTransferred` event
    */
    function transferOwnershipOnTokenContract(address _newOwner) external;

   /**
    *  @dev adds an agent to the token smart contract
    *  @param _agent the address of the new agent of the token smart contract
    *  This function can only be called by the owner of the token
    *  emits an `AgentAdded` event
    */
    function addAgentOnTokenContract(address _agent) external;

   /**
    *  @dev remove an agent from the token smart contract
    *  @param _agent the address of the agent to remove
    *  This function can only be called by the owner of the token
    *  emits an `AgentRemoved` event
    */
    function removeAgentOnTokenContract(address _agent) external;

}

// File: contracts/compliance/BasicCompliance.sol

pragma solidity 0.6.2;




abstract contract BasicCompliance is Ownable, ICompliance {

    /// Mapping between agents and their statuses
    mapping(address => bool) private _tokenAgentsList;

    /// Mapping of tokens linked to the compliance contract
    IToken _tokenBound;

    /**
     * @dev Throws if called by any address that is not a token bound to the compliance.
     */
    modifier onlyToken() {
        require(isToken(), "error : this address is not a token bound to the compliance contract");
        _;
    }

    /**
    *  @dev Returns the ONCHAINID (Identity) of the _userAddress
    *  @param _userAddress Address of the wallet
    */
    function _getIdentity(address _userAddress) internal view returns (address) {
        return address(_tokenBound.identityRegistry().identity(_userAddress));
    }

    function _getCountry(address _userAddress) internal view returns (uint16) {
        return _tokenBound.identityRegistry().investorCountry(_userAddress);
    }

    /**
    *  @dev See {ICompliance-isTokenAgent}.
    */
    function isTokenAgent(address _agentAddress) public override view returns (bool) {
        if (!_tokenAgentsList[_agentAddress]) {
            return false;
        }
        return true;
    }

    /**
    *  @dev See {ICompliance-isTokenBound}.
    */
    function isTokenBound(address _token) public override view returns (bool) {
        if (_token != address(_tokenBound)){
            return false;
        }
        return true;
    }

    /**
     *  @dev See {ICompliance-addTokenAgent}.
     */
    function addTokenAgent(address _agentAddress) external override onlyOwner {
        require(!_tokenAgentsList[_agentAddress], "This Agent is already registered");
        _tokenAgentsList[_agentAddress] = true;
        emit TokenAgentAdded(_agentAddress);
    }

    /**
    *  @dev See {ICompliance-isTokenAgent}.
    */
    function removeTokenAgent(address _agentAddress) external override onlyOwner {
        require(_tokenAgentsList[_agentAddress], "This Agent is not registered yet");
        _tokenAgentsList[_agentAddress] = false;
        emit TokenAgentRemoved(_agentAddress);
    }

    /**
     *  @dev See {ICompliance-bindToken}.
     */
    function bindToken(address _token) external override onlyOwner {
        require(_token != address(_tokenBound), "This token is already bound");
        _tokenBound = IToken(_token);
        emit TokenBound(_token);
    }

    /**
    *  @dev See {ICompliance-unbindToken}.
    */
    function unbindToken(address _token) external override onlyOwner {
        require(_token == address(_tokenBound), "This token is not bound yet");
        delete _tokenBound;
        emit TokenUnbound(_token);
    }

    /**
    *  @dev Returns true if the sender corresponds to a token that is bound with the Compliance contract
    */
    function isToken() internal view returns (bool) {
        return isTokenBound(msg.sender);
    }

    /**
    *  @dev See {ICompliance-transferOwnershipOnComplianceContract}.
    */
    function transferOwnershipOnComplianceContract(address newOwner) external override onlyOwner {
        transferOwnership(newOwner);
    }

}

// File: contracts/features/CountryRestrictions.sol

pragma solidity 0.6.2;


abstract contract CountryRestrictions is BasicCompliance {

    /**
     *  this event is emitted whenever a Country has been restricted.
     *  the event is emitted by 'addCountryRestriction' and 'batchRestrictCountries' functions.
     *  `_country` is the numeric ISO 3166-1 of the restricted country.
     */
    event AddedRestrictedCountry(uint16 _country);

    /**
     *  this event is emitted whenever a Country has been unrestricted.
     *  the event is emitted by 'removeCountryRestriction' and 'batchUnrestrictCountries' functions.
     *  `_country` is the numeric ISO 3166-1 of the unrestricted country.
     */
    event RemovedRestrictedCountry(uint16 _country);

    /// Mapping between country and their restriction status
    mapping(uint16 => bool) private _restrictedCountries;

    /**
    *  @dev Returns true if country is Restricted
    *  @param _country, numeric ISO 3166-1 standard of the country to be checked
    */
    function isCountryRestricted(uint16 _country) public view returns (bool) {
        return (_restrictedCountries[_country]);
    }

    /**
    *  @dev Adds country restriction.
    *  Identities from those countries will be forbidden to manipulate Tokens linked to this Compliance.
    *  @param _country Country to be restricted, should be expressed by following numeric ISO 3166-1 standard
    *  Only the owner of the Compliance smart contract can call this function
    *  emits an `AddedRestrictedCountry` event
    */
    function addCountryRestriction(uint16 _country) external onlyOwner {
        _restrictedCountries[_country] = true;
        emit AddedRestrictedCountry(_country);
    }

    /**
     *  @dev Removes country restriction.
     *  Identities from those countries will again be authorised to manipulate Tokens linked to this Compliance.
     *  @param _country Country to be unrestricted, should be expressed by following numeric ISO 3166-1 standard
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `RemovedRestrictedCountry` event
     */
    function removeCountryRestriction(uint16 _country) external onlyOwner {
        _restrictedCountries[_country] = false;
        emit RemovedRestrictedCountry(_country);
    }

    /**
    *  @dev Adds countries restriction in batch.
    *  Identities from those countries will be forbidden to manipulate Tokens linked to this Compliance.
    *  @param _countries Countries to be restricted, should be expressed by following numeric ISO 3166-1 standard
    *  Only the owner of the Compliance smart contract can call this function
    *  emits an `AddedRestrictedCountry` event
    */
    function batchRestrictCountries(uint16[] calldata _countries) external onlyOwner {
        for (uint i = 0; i < _countries.length; i++) {
            _restrictedCountries[_countries[i]] = true;
            emit AddedRestrictedCountry(_countries[i]);
        }
    }

    /**
     *  @dev Removes countries restriction in batch.
     *  Identities from those countries will again be authorised to manipulate Tokens linked to this Compliance.
     *  @param _countries Countries to be unrestricted, should be expressed by following numeric ISO 3166-1 standard
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `RemovedRestrictedCountry` event
     */
    function batchUnrestrictCountries(uint16[] calldata _countries) external onlyOwner {
        for (uint i = 0; i < _countries.length; i++) {
            _restrictedCountries[_countries[i]] = false;
            emit RemovedRestrictedCountry(_countries[i]);
        }
    }

    function transferActionOnCountryRestrictions(address _from, address _to, uint256 _value) internal {}

    function creationActionOnCountryRestrictions(address _to, uint256 _value) internal {}

    function destructionActionOnCountryRestrictions(address _from, uint256 _value) internal {}


    function complianceCheckOnCountryRestrictions (address _from, address _to, uint256 _value)
    internal view returns (bool) {
        uint16 receiverCountry = _getCountry(_to);
        address senderIdentity = _getIdentity(_from);
        if (isCountryRestricted(receiverCountry)) {
            return false;
        }
        return true;
    }
}

// File: contracts/features/SupplyLimit.sol

pragma solidity 0.6.2;


abstract contract SupplyLimit is BasicCompliance {

    /**
     *  this event is emitted when the supply limit has been set.
     *  `_limit` is the max amount of tokens in circulation.
     */
    event SupplyLimitSet(uint256 _limit);

    uint256 public supplyLimit;

    /**
     *  @dev sets supply limit.
     *  Supply limit has to be smaller or equal to the actual supply.
     *  @param _limit max amount of tokens to be created
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `SupplyLimitSet` event
     */
    function setSupplyLimit(uint256 _limit) external onlyOwner {
        supplyLimit = _limit;
        emit SupplyLimitSet(_limit);
    }


    function transferActionOnSupplyLimit(address _from, address _to, uint256 _value) internal {}

    function creationActionOnSupplyLimit(address _to, uint256 _value) internal {
        require(_tokenBound.totalSupply() <= supplyLimit, "cannot mint more tokens");
    }

    function destructionActionOnSupplyLimit(address _from, uint256 _value) internal {}


    function complianceCheckOnSupplyLimit (address _from, address _to, uint256 _value)
    internal view returns (bool) {
        uint ActualSupply = _tokenBound.totalSupply();
        if (isTokenAgent(_from) && (ActualSupply + _value) > supplyLimit) {
            return false;
        }
        return true;
    }
}

// File: contracts/compliance/custom_contracts/DX1SCompliance.sol

pragma solidity 0.6.2;



contract DX1SCompliance is CountryRestrictions, SupplyLimit {

    /**
    *  @dev See {ICompliance-transferred}.
    */
    function transferred(address _from, address _to, uint256 _value) external onlyToken override {
        transferActionOnCountryRestrictions(_from, _to, _value);
        transferActionOnSupplyLimit(_from, _to, _value);
    }

    /**
     *  @dev See {ICompliance-created}.
     */
    function created(address _to, uint256 _value) external onlyToken override {
        creationActionOnCountryRestrictions(_to, _value);
        creationActionOnSupplyLimit(_to, _value);
    }

    /**
     *  @dev See {ICompliance-destroyed}.
     */
    function destroyed(address _from, uint256 _value) external onlyToken override {
        destructionActionOnCountryRestrictions(_from, _value);
        destructionActionOnSupplyLimit(_from, _value);
    }

    /**
     *  @dev See {ICompliance-canTransfer}.
     */
    function canTransfer(address _from, address _to, uint256 _value) external view override returns (bool) {
        if (
        !complianceCheckOnSupplyLimit(_from, _to, _value)
        ||
        !complianceCheckOnCountryRestrictions(_from, _to, _value)
        ){
            return false;
        }
        return true;
    }
}