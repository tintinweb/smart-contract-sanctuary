pragma solidity ^0.4.23;

// File: contracts/grapevine/crowdsale/GrapevineWhitelistInterface.sol

/**
 * @title Grapevine Whitelist extends the zeppelin Whitelist and adding off-chain signing capabilities.
 * @dev Grapevine Crowdsale
 **/
contract GrapevineWhitelistInterface {

  /**
   * @dev Function to check if an address is whitelisted or not
   * @param _address address The address to be checked.
   */
  function whitelist(address _address) view external returns (bool);

 
  /**
   * @dev Handles the off-chain whitelisting.
   * @param _addr Address of the sender.
   * @param _sig signed message provided by the sender.
   */
  function handleOffchainWhitelisted(address _addr, bytes _sig) external returns (bool);
}

// File: openzeppelin-solidity/contracts/ECRecovery.sol

/**
 * @title Eliptic curve signature operations
 *
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 *
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 *
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * @dev and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      "\x19Ethereum Signed Message:\n32",
      hash
    );
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/ownership/rbac/Roles.sol

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

// File: openzeppelin-solidity/contracts/ownership/rbac/RBAC.sol

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * @dev Supports unlimited numbers of roles and addresses.
 * @dev See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 *  for you to write your own implementation of this interface using Enums or similar.
 * It&#39;s also recommended that you define constants in the contract, like ROLE_ADMIN below,
 *  to avoid typos.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

// File: openzeppelin-solidity/contracts/access/SignatureBouncer.sol

/**
 * @title SignatureBouncer
 * @author PhABC and Shrugs
 * @dev Bouncer allows users to submit a signature as a permission to do an action.
 * If the signature is from one of the authorized bouncer addresses, the signature
 * is valid. The owner of the contract adds/removes bouncers.
 * Bouncer addresses can be individual servers signing grants or different
 * users within a decentralized club that have permission to invite other members.
 * 
 * This technique is useful for whitelists and airdrops; instead of putting all
 * valid addresses on-chain, simply sign a grant of the form
 * keccak256(`:contractAddress` + `:granteeAddress`) using a valid bouncer address.
 * Then restrict access to your crowdsale/whitelist/airdrop using the
 * `onlyValidSignature` modifier (or implement your own using isValidSignature).
 * 
 * See the tests Bouncer.test.js for specific usage examples.
 */
contract SignatureBouncer is Ownable, RBAC {
  using ECRecovery for bytes32;

  string public constant ROLE_BOUNCER = "bouncer";

  /**
   * @dev requires that a valid signature of a bouncer was provided
   */
  modifier onlyValidSignature(bytes _sig)
  {
    require(isValidSignature(msg.sender, _sig));
    _;
  }

  /**
   * @dev allows the owner to add additional bouncer addresses
   */
  function addBouncer(address _bouncer)
    onlyOwner
    public
  {
    require(_bouncer != address(0));
    addRole(_bouncer, ROLE_BOUNCER);
  }

  /**
   * @dev allows the owner to remove bouncer addresses
   */
  function removeBouncer(address _bouncer)
    onlyOwner
    public
  {
    require(_bouncer != address(0));
    removeRole(_bouncer, ROLE_BOUNCER);
  }

  /**
   * @dev is the signature of `this + sender` from a bouncer?
   * @return bool
   */
  function isValidSignature(address _address, bytes _sig)
    internal
    view
    returns (bool)
  {
    return isValidDataHash(
      keccak256(address(this), _address),
      _sig
    );
  }

  /**
   * @dev internal function to convert a hash to an eth signed message
   * @dev and then recover the signature and check it against the bouncer role
   * @return bool
   */
  function isValidDataHash(bytes32 hash, bytes _sig)
    internal
    view
    returns (bool)
  {
    address signer = hash
      .toEthSignedMessageHash()
      .recover(_sig);
    return hasRole(signer, ROLE_BOUNCER);
  }
}

// File: contracts/grapevine/crowdsale/GrapevineWhitelist.sol

/**
 * @title Grapevine Whitelist extends the zeppelin Whitelist and adding off-chain signing capabilities.
 * @dev Grapevine Crowdsale
 **/
contract GrapevineWhitelist is SignatureBouncer, GrapevineWhitelistInterface {

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);
  event UselessEvent(address addr, bytes sign, bool ret);

  mapping(address => bool) public whitelist;

  address crowdsale;

  constructor(address _signer) public {
    require(_signer != address(0));
    addBouncer(_signer);
  }

  modifier onlyOwnerOrCrowdsale() {
    require(msg.sender == owner || msg.sender == crowdsale);
    _;
  }

  /**
   * @dev Function to check if an address is whitelisted
   * @param _address address The address to be checked.
   */
  function whitelist(address _address) view external returns (bool) {
    return whitelist[_address];
  }
  
  /**
   * @dev Function to set the crowdsale address
   * @param _crowdsale address The address of the crowdsale.
   */
  function setCrowdsale(address _crowdsale) external onlyOwner {
    require(_crowdsale != address(0));
    crowdsale = _crowdsale;
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addAddressesToWhitelist(address[] _beneficiaries) external onlyOwnerOrCrowdsale {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      addAddressToWhitelist(_beneficiaries[i]);
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeAddressFromWhitelist(address _beneficiary) external onlyOwnerOrCrowdsale {
    whitelist[_beneficiary] = false;
    emit WhitelistedAddressRemoved(_beneficiary);
  }

  /**
   * @dev Handles the off-chain whitelisting.
   * @param _addr Address of the sender.
   * @param _sig signed message provided by the sender.
   */
  function handleOffchainWhitelisted(address _addr, bytes _sig) external onlyOwnerOrCrowdsale returns (bool) {
    bool valid;
    // no need for consuming gas when the address is already whitelisted 
    if (whitelist[_addr]) {
      valid = true;
    } else {
      valid = isValidSignature(_addr, _sig);
      if (valid) {
        // no need for consuming gas again if the address calls the contract again. 
        addAddressToWhitelist(_addr);
      }
    }
    return valid;
  }

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addAddressToWhitelist(address _beneficiary) public onlyOwnerOrCrowdsale {
    whitelist[_beneficiary] = true;
    emit WhitelistedAddressAdded(_beneficiary);
  }
}