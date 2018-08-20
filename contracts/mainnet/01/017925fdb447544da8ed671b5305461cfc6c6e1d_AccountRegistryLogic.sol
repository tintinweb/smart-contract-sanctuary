pragma solidity 0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract SigningLogicInterface {
  function recoverSigner(bytes32 _hash, bytes _sig) external pure returns (address);
  function generateRequestAttestationSchemaHash(
    address _subject,
    address _attester,
    address _requester,
    bytes32 _dataHash,
    uint256[] _typeIds,
    bytes32 _nonce
    ) external view returns (bytes32);
  function generateAttestForDelegationSchemaHash(
    address _subject,
    address _requester,
    uint256 _reward,
    bytes32 _paymentNonce,
    bytes32 _dataHash,
    uint256[] _typeIds,
    bytes32 _requestNonce
    ) external view returns (bytes32);
  function generateContestForDelegationSchemaHash(
    address _requester,
    uint256 _reward,
    bytes32 _paymentNonce
  ) external view returns (bytes32);
  function generateStakeForDelegationSchemaHash(
    address _subject,
    uint256 _value,
    bytes32 _paymentNonce,
    bytes32 _dataHash,
    uint256[] _typeIds,
    bytes32 _requestNonce,
    uint256 _stakeDuration
    ) external view returns (bytes32);
  function generateRevokeStakeForDelegationSchemaHash(
    uint256 _subjectId,
    uint256 _attestationId
    ) external view returns (bytes32);
  function generateAddAddressSchemaHash(
    address _senderAddress,
    bytes32 _nonce
    ) external view returns (bytes32);
  function generateVoteForDelegationSchemaHash(
    uint16 _choice,
    address _voter,
    bytes32 _nonce,
    address _poll
    ) external view returns (bytes32);
  function generateReleaseTokensSchemaHash(
    address _sender,
    address _receiver,
    uint256 _amount,
    bytes32 _uuid
    ) external view returns (bytes32);
  function generateLockupTokensDelegationSchemaHash(
    address _sender,
    uint256 _amount,
    bytes32 _nonce
    ) external view returns (bytes32);
}

interface AccountRegistryInterface {
  function accountIdForAddress(address _address) public view returns (uint256);
  function addressBelongsToAccount(address _address) public view returns (bool);
  function createNewAccount(address _newUser) external;
  function addAddressToAccount(
    address _newAddress,
    address _sender
    ) external;
  function removeAddressFromAccount(address _addressToRemove) external;
}

/**
 * @title Bloom account registry
 * @notice Account Registry Logic provides a public interface for Bloom and users to 
 * create and control their Bloom Ids.
 * Users can associate create and accept invites and associate additional addresses with their BloomId.
 * As the Bloom protocol matures, this contract can be upgraded to enable new capabilities
 * without needing to migrate the underlying Account Registry storage contract.
 *
 * In order to invite someone, a user must generate a new public key private key pair
 * and sign their own ethereum address. The user provides this signature to the
 * `createInvite` function where the public key is recovered and the invite is created.
 * The inviter should then share the one-time-use private key out of band with the recipient.
 * The recipient accepts the invite by signing their own address and passing that signature
 * to the `acceptInvite` function. The contract should recover the same public key, demonstrating
 * that the recipient knows the secret and is likely the person intended to receive the invite.
 *
 * @dev This invite model is supposed to aid usability by not requiring the inviting user to know
 *   the Ethereum address of the recipient. If the one-time-use private key is leaked then anyone
 *   else can accept the invite. This is an intentional tradeoff of this invite system. A well built
 *   dApp should generate the private key on the backend and sign the user&#39;s address for them. Likewise,
 *   the signing should also happen on the backend (not visible to the user) for signing an address to
 *   accept an invite. This reduces the private key exposure so that the dApp can still require traditional
 *   checks like verifying an associated email address before finally signing the user&#39;s Ethereum address.
 *
 * @dev The private key generated for this invite system should NEVER be used for an Ethereum address.
 *   The private key should be used only for the invite flow and then it should effectively be discarded.
 *
 * @dev If a user DOES know the address of the person they are inviting then they can still use this
 *   invite system. All they have to do then is sign the address of the user being invited and share the
 *   signature with them.
 */
contract AccountRegistryLogic is Ownable{

  SigningLogicInterface public signingLogic;
  AccountRegistryInterface public registry;
  address public registryAdmin;

  /**
   * @notice The AccountRegistry constructor configures the signing logic implementation
   *  and creates an account for the user who deployed the contract.
   * @dev The owner is also set as the original registryAdmin, who has the privilege to
   *  create accounts outside of the normal invitation flow.
   * @param _signingLogic The address of the deployed SigningLogic contract
   * @param _registry The address of the deployed account registry
   */
  constructor(
    SigningLogicInterface _signingLogic,
    AccountRegistryInterface _registry
    ) public {
    signingLogic = _signingLogic;
    registry = _registry;
    registryAdmin = owner;
  }

  event AccountCreated(uint256 indexed accountId, address indexed newUser);
  event InviteCreated(address indexed inviter, address indexed inviteAddress);
  event InviteAccepted(address recipient, address indexed inviteAddress);
  event AddressAdded(uint256 indexed accountId, address indexed newAddress);
  event AddressRemoved(uint256 indexed accountId, address indexed oldAddress);
  event RegistryAdminChanged(address oldRegistryAdmin, address newRegistryAdmin);
  event SigningLogicChanged(address oldSigningLogic, address newSigningLogic);
  event AccountRegistryChanged(address oldRegistry, address newRegistry);

  /**
   * @dev Addresses with Bloom accounts already are not allowed
   */
  modifier onlyNonUser {
    require(!registry.addressBelongsToAccount(msg.sender));
    _;
  }

  /**
   * @dev Addresses without Bloom accounts already are not allowed
   */
  modifier onlyUser {
    require(registry.addressBelongsToAccount(msg.sender));
    _;
  }

  /**
   * @dev Zero address not allowed
   */
  modifier nonZero(address _address) {
    require(_address != 0);
    _;
  }

  /**
   * @dev Restricted to registryAdmin
   */
  modifier onlyRegistryAdmin {
    require(msg.sender == registryAdmin);
    _;
  }

  // Signatures contain a nonce to make them unique. usedSignatures tracks which signatures
  //  have been used so they can&#39;t be replayed
  mapping (bytes32 => bool) public usedSignatures;

  // Mapping of public keys as Ethereum addresses to invite information
  // NOTE: the address keys here are NOT Ethereum addresses, we just happen
  // to work with the public keys in terms of Ethereum address strings because
  // this is what `ecrecover` produces when working with signed text.
  mapping(address => bool) public pendingInvites;

  /**
   * @notice Change the implementation of the SigningLogic contract by setting a new address
   * @dev Restricted to AccountRegistry owner and new implementation address cannot be 0x0
   * @param _newSigningLogic Address of new SigningLogic implementation
   */
  function setSigningLogic(SigningLogicInterface _newSigningLogic) public nonZero(_newSigningLogic) onlyOwner {
    address oldSigningLogic = signingLogic;
    signingLogic = _newSigningLogic;
    emit SigningLogicChanged(oldSigningLogic, signingLogic);
  }

  /**
   * @notice Change the address of the registryAdmin, who has the privilege to create new accounts
   * @dev Restricted to AccountRegistry owner and new admin address cannot be 0x0
   * @param _newRegistryAdmin Address of new registryAdmin
   */
  function setRegistryAdmin(address _newRegistryAdmin) public onlyOwner nonZero(_newRegistryAdmin) {
    address _oldRegistryAdmin = registryAdmin;
    registryAdmin = _newRegistryAdmin;
    emit RegistryAdminChanged(_oldRegistryAdmin, registryAdmin);
  }

  /**
   * @notice Change the address of AccountRegistry, which enables authorization of subject comments
   * @dev Restricted to owner and new address cannot be 0x0
   * @param _newRegistry Address of new Account Registry contract
   */
  function setAccountRegistry(AccountRegistryInterface _newRegistry) public nonZero(_newRegistry) onlyOwner {
    address oldRegistry = registry;
    registry = _newRegistry;
    emit AccountRegistryChanged(oldRegistry, registry);
  }

  /**
   * @notice Create an invite using the signing model described in the contract description
   * @dev Recovers public key of invitation key pair using 
   * @param _sig Signature of one-time-use keypair generated for invite
   */
  function createInvite(bytes _sig) public onlyUser {
    address inviteAddress = signingLogic.recoverSigner(keccak256(abi.encodePacked(msg.sender)), _sig);
    require(!pendingInvites[inviteAddress]);
    pendingInvites[inviteAddress] = true;
    emit InviteCreated(msg.sender, inviteAddress);
  }

  /**
   * @notice Accept an invite using the signing model described in the contract description
   * @dev Recovers public key of invitation key pair
   * Assumes signed message matches format described in recoverSigner
   * Restricted to addresses that are not already registered by a user
   * Invite is accepted by setting recipient to nonzero address for invite associated with recovered public key
   * and creating an account for the sender
   * @param _sig Signature for `msg.sender` via the same key that issued the initial invite
   */
  function acceptInvite(bytes _sig) public onlyNonUser {
    address inviteAddress = signingLogic.recoverSigner(keccak256(abi.encodePacked(msg.sender)), _sig);
    require(pendingInvites[inviteAddress]);
    pendingInvites[inviteAddress] = false;
    createAccountForUser(msg.sender);
    emit InviteAccepted(msg.sender, inviteAddress);
  }

  /**
   * @notice Create an account instantly without an invitation
   * @dev Restricted to the "invite admin" which is managed by the Bloom team
   * @param _newUser Address of the user receiving an account
   */
  function createAccount(address _newUser) public onlyRegistryAdmin {
    createAccountForUser(_newUser);
  }

  /**
   * @notice Create an account for a user and emit an event
   * @dev Records address as taken so it cannot be used to sign up for another account
   *  accountId is a unique ID across all users generated by calculating the length of the accounts array
   *  addressId is the position in the unordered list of addresses associated with a user account 
   *  AccountInfo is a struct containing accountId and addressId so all addresses can be found for a user
   * new Login structs represent user accounts. The first one is pushed onto the array associated with a user&#39;s accountID
   * To push a new account onto the same Id, accounts array should be addressed accounts[_accountID - 1].push
   * @param _newUser Address of the new user
   */
  function createAccountForUser(address _newUser) internal nonZero(_newUser) {
    registry.createNewAccount(_newUser);
    uint256 _accountId = registry.accountIdForAddress(_newUser);
    emit AccountCreated(_accountId, _newUser);
  }

  /**
   * @notice Add an address to an existing id on behalf of a user to pay the gas costs
   * @param _newAddress Address to add to account
   * @param _newAddressSig Signed message from new address confirming ownership by the sender
   * @param _senderSig Signed message from address currently associated with account confirming intention
   * @param _sender User requesting this action
   * @param _nonce uuid used when generating sigs to make them one time use
   */
  function addAddressToAccountFor(
    address _newAddress,
    bytes _newAddressSig,
    bytes _senderSig,
    address _sender,
    bytes32 _nonce
    ) public onlyRegistryAdmin {
    addAddressToAccountForUser(_newAddress, _newAddressSig, _senderSig, _sender, _nonce);
  }

  /**
   * @notice Add an address to an existing id by a user
   * @dev Wrapper for addAddressTooAccountForUser with msg.sender as sender
   * @param _newAddress Address to add to account
   * @param _newAddressSig Signed message from new address confirming ownership by the sender
   * @param _senderSig Signed message from msg.sender confirming intention by the sender
   * @param _nonce uuid used when generating sigs to make them one time use
   */
  function addAddressToAccount(
    address _newAddress,
    bytes _newAddressSig,
    bytes _senderSig,
    bytes32 _nonce
    ) public onlyUser {
    addAddressToAccountForUser(_newAddress, _newAddressSig, _senderSig, msg.sender, _nonce);
  }

  /**
   * @notice Add an address to an existing id 
   * @dev Checks that new address signed _sig 
   * @param _newAddress Address to add to account
   * @param _newAddressSig Signed message from new address confirming ownership by the sender
   * @param _senderSig Signed message from new address confirming ownership by the sender
   * @param _sender User requesting this action
   * @param _nonce uuid used when generating sigs to make them one time use
   */
  function addAddressToAccountForUser(
    address _newAddress,
    bytes _newAddressSig,
    bytes _senderSig,
    address _sender,
    bytes32 _nonce
    ) private nonZero(_newAddress) {

    require(!usedSignatures[keccak256(abi.encodePacked(_newAddressSig))], "Signature not unique");
    require(!usedSignatures[keccak256(abi.encodePacked(_senderSig))], "Signature not unique");

    usedSignatures[keccak256(abi.encodePacked(_newAddressSig))] = true;
    usedSignatures[keccak256(abi.encodePacked(_senderSig))] = true;

    // Confirm new address is signed by current address
    bytes32 _currentAddressDigest = signingLogic.generateAddAddressSchemaHash(_newAddress, _nonce);
    require(_sender == signingLogic.recoverSigner(_currentAddressDigest, _senderSig));

    // Confirm current address is signed by new address
    bytes32 _newAddressDigest = signingLogic.generateAddAddressSchemaHash(_sender, _nonce);
    require(_newAddress == signingLogic.recoverSigner(_newAddressDigest, _newAddressSig));

    registry.addAddressToAccount(_newAddress, _sender);
    uint256 _accountId = registry.accountIdForAddress(_newAddress);
    emit AddressAdded(_accountId, _newAddress);
  }

  /**
   * @notice Remove an address from an account for a user
   * @dev Restricted to admin
   * @param _addressToRemove Address to remove from account
   */
  function removeAddressFromAccountFor(
    address _addressToRemove
  ) public onlyRegistryAdmin {
    uint256 _accountId = registry.accountIdForAddress(_addressToRemove);
    registry.removeAddressFromAccount(_addressToRemove);
    emit AddressRemoved(_accountId, _addressToRemove);
  }
}