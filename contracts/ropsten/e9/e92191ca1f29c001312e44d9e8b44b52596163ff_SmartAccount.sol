pragma solidity ^0.4.24;


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
  * @dev prefix a bytes32 value with &quot;\x19Ethereum Signed Message:&quot;
  * @dev and hash the result
  */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(abi.encodePacked(&quot;\x19Ethereum Signed Message:\n32&quot;, hash));
  }
}


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


/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of &quot;user permissions&quot;.
*/
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


/**
* Modified from original to use the hashedName (bytes32) instead of roleName (string) 
* 
*
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

  mapping (bytes32 => Roles.Role) private roles;

  event RoleAdded(address addr, bytes32 hashedName);
  event RoleRemoved(address addr, bytes32 hashedName);

  /**
  * @dev reverts if addr does not have role
  * @param addr address
  * @param hashedName the hashed name of the role
  * // reverts
  */
  function checkRole(address addr, bytes32 hashedName)
    view
    public
  {
    roles[hashedName].check(addr);
  }

  /**
  * @dev determine if addr has role
  * @param addr address
  * @param hashedName the hashed name of the role
  * @return bool
  */
  function hasRole(address addr, bytes32 hashedName)
    view
    public
    returns (bool)
  {
    return roles[hashedName].has(addr);
  }

  /**
  * @dev add a role to an address
  * @param addr address
  * @param hashedName the hashed name of the role
  */
  function addRole(address addr, bytes32 hashedName)
    internal
  { 
    roles[hashedName].add(addr);
    emit RoleAdded(addr, hashedName);
  }

  /**
  * @dev remove a role from an address
  * @param addr address
  * @param hashedName the hashed name of the role
  */
  function removeRole(address addr, bytes32 hashedName)
    internal
  {
    roles[hashedName].remove(addr);
    emit RoleRemoved(addr, hashedName);
  }

  /**
  * @dev modifier to scope access to a single role (uses msg.sender as addr)
  * @param hashedName the hashed name of the role
  * // reverts
  */
  modifier onlyRole(bytes32 hashedName) {
    checkRole(msg.sender, hashedName);
    _;
  }
}


/**
* Modified from original to use the hashedName (bytes32) instead of roleName (string) 
* 
* 
* @title SignatureBouncer
* @author PhABC and Shrugs
* @dev Bouncer allows users to submit a signature as a permission to do an action.
* @dev If the signature is from one of the authorized bouncer addresses, the signature
* @dev is valid. The owner of the contract adds/removes bouncers.
* @dev Bouncer addresses can be individual servers signing grants or different
* @dev users within a decentralized club that have permission to invite other members.
* @dev This technique is useful for whitelists and airdrops; instead of putting all
* @dev valid addresses on-chain, simply sign a grant of the form
* @dev keccak256(`:contractAddress` + `:granteeAddress`) using a valid bouncer address.
* @dev Then restrict access to your crowdsale/whitelist/airdrop using the
* @dev `onlyValidSignature` modifier (or implement your own using isValidSignature).
* @dev See the tests Bouncer.test.js for specific usage examples.
*/
contract SignatureBouncer is Ownable, RBAC {
  using ECRecovery for bytes32;

  bytes32 public constant ROLE_BOUNCER = keccak256(&quot;bouncer&quot;);

  /**
  * @dev requires that a valid signature of a bouncer was provided
  */
  modifier onlyValidSignature(bytes _sig) {
    require(isValidSignature(msg.sender, _sig));
    _;
  }
  
  /**
  * @dev requires a valid address 
  */
  modifier validAddress(address _address) {
    require(_address != address(0));
    _;
  }

  /**
  * @dev Modified from original to allows any bouncer to add additional bouncer addresses
  */
  function addBouncer(address _bouncer)
    validAddress(_bouncer)
    public
  {
    require(msg.sender == owner || hasRole(msg.sender, ROLE_BOUNCER));
    addRole(_bouncer, ROLE_BOUNCER);
  }

  /**
  * @dev Modified from original to allows any bouncer to remove bouncer addresses
  */
  function removeBouncer(address _bouncer)
    validAddress(_bouncer)
    public
  {
    require(msg.sender == owner || hasRole(msg.sender, ROLE_BOUNCER));
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
    keccak256(abi.encodePacked(address(this), _address)),
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


contract AccountRoles {
  bytes32 public constant ROLE_TRANSFER_ETHER = keccak256(&quot;transfer_ether&quot;);
  bytes32 public constant ROLE_TRANSFER_TOKEN = keccak256(&quot;transfer_token&quot;);
  bytes32 public constant ROLE_TRANSFER_OWNERSHIP = keccak256(&quot;transfer_ownership&quot;);	
  
  /**
  * @dev modifier to validate the roles 
  * @param roles to be validated
  * // reverts
  */
  modifier validAccountRoles(bytes32[] roles) {
    for (uint8 i = 0; i < roles.length; i++) {
      require(roles[i] == ROLE_TRANSFER_ETHER 
      || roles[i] == ROLE_TRANSFER_TOKEN
      || roles[i] == ROLE_TRANSFER_OWNERSHIP, &quot;Invalid account role&quot;);
    }
    _;
  }
}


/**
* @title SignatureAccount
* @dev Account roles manager to authorize addresses
*/
contract SignatureAccount is AccountRoles, SignatureBouncer {
  /**
  * @dev allows a bouncer address to add account roles to an address
  */
  function addRoles(bytes32[] _roles, address _address)
    onlyRole(ROLE_BOUNCER)
    validAddress(_address)
    validAccountRoles(_roles)
    public
  {
    for (uint8 i = 0; i < _roles.length; i++) {
      addRole(_address, _roles[i]);
    }
  }
  
  /**
  * @dev allows a bouncer address to remove account roles from an address
  */
  function removeRoles(bytes32[] _roles, address _address)
    onlyRole(ROLE_BOUNCER)
    validAddress(_address)
    validAccountRoles(_roles)
    public
  {
    for (uint8 i = 0; i < _roles.length; i++) {
      removeRole(_address, _roles[i]);
    }
  }
}

contract IExtension {
  function getRoles() pure public returns(bytes32[]);
}


contract SmartAccount is SignatureAccount {
  string public version = &quot;0.0.1&quot;;

  bytes4 public constant TRANSFER_TOKEN = bytes4(keccak256(&quot;transfer(address,uint256)&quot;)); //ERC20
  bytes4 public constant TRANSFER_TOKEN_DATA = bytes4(keccak256(&quot;transfer(address,uint256,bytes)&quot;)); //ERC223
  bytes4 public constant TRANSFER_TOKEN_CUSTOM = bytes4(keccak256(&quot;transfer(address,uint256,bytes,string)&quot;)); //ERC223
  
  struct Extension {
    address extension;
    uint256 addedDate;
  }
  
  Extension[] public extensions;
  bool public refundGas;

  event SetGasRefund(address responsable, bool refundGas);
  event AddExtension(address responsable, address extension, bytes32[] roles);
  event RemoveExtension(address responsable, address extension);
  event TransferOwnership(address sender, address owner, address newOwner);
  event ExecuteCall(address sender, address destination, uint256 value, uint256 gasLimit, bytes data);
  event ExecuteDelegate(address sender, address destination, uint256 gasLimit, bytes data);
  event ExecuteCreate(address sender, address newContract);

  constructor() 
    public 
  {
    addBouncer(msg.sender);
  }

  function() 
    payable 
    external 
  {
    require(msg.value > 0);  
  }

  function extensionsCount() 
    view 
    external 
    returns(uint256) 
  {
    return extensions.length;
  }

  function extensionByIndex(uint256 _index) 
    view 
    external 
    returns(address extension, uint256 addedDate) 
  {
    return (extensions[_index].extension, extensions[_index].addedDate);
  }
  
  function onlyBouncerSetGasRefund(bool _refundGas) 
    onlyRole(ROLE_BOUNCER)
    external 
  {
    refundGas = _refundGas;
    emit SetGasRefund(msg.sender, refundGas);
  }

  function onlyBouncerAddExtension(address _extension)
    onlyRole(ROLE_BOUNCER)
    external 
  {
    if (refundGas) {
      uint256 startGas = gasleft();
      addExtension(_extension);
      address(msg.sender).transfer(getRefundGasAmount(startGas));
    } else {
      addExtension(_extension);
    }
  }
  
  function onlyBouncerRemoveExtension(address _extension) 
    onlyRole(ROLE_BOUNCER)
    external 
  {
    if (refundGas) {
      uint256 startGas = gasleft();
      removeExtension(_extension);
      address(msg.sender).transfer(getRefundGasAmount(startGas));
    } else {
      removeExtension(_extension);
    }
  }

  function onlyBouncerExecuteDelegatecall(address _destination, uint256 _gasLimit, bytes _data) 
    onlyRole(ROLE_BOUNCER)
    external 
  {
    require(validDestination(_destination));
    if (refundGas) {
      uint256 startGas = 1500 + gasleft();
      internalExecuteDelegatecall(_destination, _gasLimit, _data);
      address(msg.sender).transfer(getRefundGasAmount(startGas));
    } else {
      internalExecuteDelegatecall(_destination, _gasLimit, _data);
    }
  }
  
  function onlyBouncerExecuteCall(address _destination, uint256 _value, uint256 _gasLimit, bytes _data) 
    onlyRole(ROLE_BOUNCER)
    external 
  {
    if (refundGas) {
      uint256 startGas = gasleft();
      executeCall(_destination, _value, _gasLimit, _data);
      address(msg.sender).transfer(getRefundGasAmount(startGas));
    } else {
      executeCall(_destination, _value, _gasLimit, _data);
    }
  }
  
  function onlyBouncerTransferOwnership(address _newOwner) 
    onlyRole(ROLE_BOUNCER)
    external 
  {
    if (refundGas) {
      uint256 startGas = gasleft();
      transferOwnership(_newOwner);
      address(msg.sender).transfer(getRefundGasAmount(startGas));
    } else {
      transferOwnership(_newOwner);
    }
  }
  
  function onlyBouncerCreateContract(bytes _data) 
    onlyRole(ROLE_BOUNCER)
    external 
  {
    if (refundGas) {
      uint256 startGas = gasleft();
      createContract(_data);
      address(msg.sender).transfer(getRefundGasAmount(startGas));
    } else {
      createContract(_data);
    }
  }
  
  function executeSignedCall(address _destination, uint256 _value, uint256 _gasLimit, bytes _data, bytes _sign) 
    public 
  {
    require(validDestination(_destination));
    require(isValidDataHash(keccak256(abi.encodePacked(address(this), _destination, _value, _data)), _sign));
    internalExecuteCall(_destination, _value, _gasLimit, _data);
  }
  
  function transferOwnership(address _newOwner) 
    validAddress(_newOwner)
    public
  {
    require(hasRole(msg.sender, ROLE_BOUNCER) || hasRole(msg.sender, ROLE_TRANSFER_OWNERSHIP));
    owner = _newOwner;
    emit TransferOwnership(msg.sender, owner, _newOwner);
  }
  
  function createContract(bytes _data) 
    public 
  {
    require(validCall(0, _data));
    address newContract;
    assembly {
      newContract := create(0, add(_data, 0x20), mload(_data))
    }
    require(newContract != address(0));
    emit ExecuteCreate(msg.sender, newContract); 
  }

  function executeCall(address _destination, uint256 _value, uint256 _gasLimit, bytes _data) 
    public 
  {
    require(validDestination(_destination));
    require(validCall(_value, _data));
    internalExecuteCall(_destination, _value, _gasLimit, _data);
  }
  
  function addExtension(address _extension) 
    private 
  {
    for (uint256 i = 0; i < extensions.length; ++i) {
      require(extensions[i].extension != _extension, &quot;Extension already added&quot;);
    }
    bytes32[] memory roles = IExtension(_extension).getRoles();
    addRoles(roles, _extension);
    extensions.push(Extension(_extension, now));
    emit AddExtension(msg.sender, _extension, roles);
  }
  
  function removeExtension(address _extension) 
    private 
  {
    Extension memory last = extensions[extensions.length - 1];
    Extension memory toBeRemoved;
    if (last.extension != _extension) {
      for (uint256 i = 0; i < extensions.length; ++i) {
        if (extensions[i].extension == _extension) {
          toBeRemoved = extensions[i];
          extensions[i] = last;
          break;
        }
      }
      require(toBeRemoved.extension != address(0));
    } else {
      toBeRemoved = last;
    }
    extensions.length--;
    removeRoles(IExtension(_extension).getRoles(), _extension);
    emit RemoveExtension(msg.sender, _extension);
  }
  
  function validDestination(address _destination)
    view
    internal
    returns(bool)
  {
    return (_destination != address(this) && _destination != address(0));
  }
  
  function validCall(uint256 _value, bytes _data) 
    view
    internal
    returns(bool)
  {
    if (hasRole(msg.sender, ROLE_BOUNCER)) {
      return true;
    }
    Extension memory extension;
    for (uint256 i = 0; i < extensions.length; ++i) {
      if (extensions[i].extension == msg.sender) {
        extension = extensions[i];
        break;
      }
    }
    if (extension.extension == address(0)) {
      return false;
    }
    if (_value > 0) {
      return hasRole(msg.sender, ROLE_TRANSFER_ETHER);
    }
    if (_data.length == 0) {
      return false;
    }
    bytes4 functionSignature;
    assembly {
      functionSignature := mload(add(_data, 32))
    }
    if (functionSignature == TRANSFER_TOKEN 
      || functionSignature == TRANSFER_TOKEN_DATA 
      || functionSignature == TRANSFER_TOKEN_CUSTOM) 
    {
      return hasRole(msg.sender, ROLE_TRANSFER_TOKEN);
    }
    return true;
  }
  
  function getRefundGasAmount(uint256 _startGas)
    view
    internal
    returns(uint256)
  {
    return (23200 + (_startGas - gasleft())) * tx.gasprice; 
  }

  function internalExecuteCall(address _destination, uint256 _value, uint256 _gasLimit, bytes _data) 
    private 
  {
    if (_gasLimit > 0) {
      require(_destination.call.value(_value).gas(_gasLimit)(_data));
    } else {
      require(_destination.call.value(_value)(_data));
    }
    emit ExecuteCall(msg.sender, _destination, _value, _gasLimit, _data);   
  }
  
  function internalExecuteDelegatecall(address _destination, uint256 _gasLimit, bytes _data)
    private
  {
    if (_gasLimit > 0) {
      require(_destination.delegatecall.gas(_gasLimit)(_data));
    } else {
      require(_destination.delegatecall(_data));
    }
    emit ExecuteDelegate(msg.sender, _destination, _gasLimit, _data);     
  }
}