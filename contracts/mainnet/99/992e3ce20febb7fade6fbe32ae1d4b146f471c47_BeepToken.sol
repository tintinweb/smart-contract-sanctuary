pragma solidity 0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
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

/**
 * @title RBACWithAdmin
 * @author Matt Condon (@Shrugs)
 * @dev It&#39;s recommended that you define constants in the contract,
 * @dev like ROLE_ADMIN below, to avoid typos.
 */
contract RBACWithAdmin is RBAC {
  /**
   * A constant role name for indicating admins.
   */
  string public constant ROLE_ADMIN = "admin";

  /**
   * @dev modifier to scope access to admins
   * // reverts
   */
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

  /**
   * @dev constructor. Sets msg.sender as admin by default
   */
  constructor()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }
}

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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title ERC865Token Token
 *
 * ERC865Token allows users paying transfers in tokens instead of gas
 * https://github.com/ethereum/EIPs/issues/865
 *
 */

contract ERC865 {

    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function approvePreSigned(
        bytes _signature,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function increaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function decreaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);
}

/**
 * @title ERC865Token Token
 *
 * ERC865Token allows users paying transfers in tokens instead of gas
 * https://github.com/ethereum/EIPs/issues/865
 *
 */

contract ERC865Token is ERC865, StandardToken, Ownable {

    /* Nonces of transfers performed */
    mapping(bytes => bool) signatures;
    /* mapping of nonces of each user */
    mapping (address => uint256) nonces;

    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event ApprovalPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);

    bytes4 internal constant transferSig = 0x48664c16;
    bytes4 internal constant approvalSig = 0xf7ac9c2e;
    bytes4 internal constant increaseApprovalSig = 0xa45f71ff;
    bytes4 internal constant decreaseApprovalSig = 0x59388d78;

    //return nonce using function
    function getNonce(address _owner) public view returns (uint256 nonce){
      return nonces[_owner];
    }


    /**
     * @notice Submit a presigned transfer
     * @param _signature bytes The signature, issued by the owner.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(signatures[_signature] == false);

        bytes32 hashedTx = recoverPreSignedHash(address(this), transferSig, _to, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        require(_nonce == nonces[from].add(1));
        require(_value.add(_fee) <= balances[from]);

        nonces[from] = _nonce;
        signatures[_signature] = true;
        balances[from] = balances[from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }

    /**
     * @notice Submit a presigned approval
     * @param _signature bytes The signature, issued by the owner.
     * @param _spender address The address which will spend the funds.
     * @param _value uint256 The amount of tokens to allow.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function approvePreSigned(
        bytes _signature,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(signatures[_signature] == false);

        bytes32 hashedTx = recoverPreSignedHash(address(this), approvalSig, _spender, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        require(_nonce == nonces[from].add(1));
        require(_value.add(_fee) <= balances[from]);

        nonces[from] = _nonce;
        signatures[_signature] = true;
        allowed[from][_spender] =_value;
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, _value);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, _value, _fee);
        return true;
    }

    /**
     * @notice Increase the amount of tokens that an owner allowed to a spender.
     * @param _signature bytes The signature, issued by the owner.
     * @param _spender address The address which will spend the funds.
     * @param _addedValue uint256 The amount of tokens to increase the allowance by.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function increaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(signatures[_signature] == false);

        bytes32 hashedTx = recoverPreSignedHash(address(this), increaseApprovalSig, _spender, _addedValue, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        require(_nonce == nonces[from].add(1));
        require(allowed[from][_spender].add(_addedValue).add(_fee) <= balances[from]);
        //require(_addedValue <= allowed[from][_spender]);

        nonces[from] = _nonce;
        signatures[_signature] = true;
        allowed[from][_spender] = allowed[from][_spender].add(_addedValue);
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, allowed[from][_spender]);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowed[from][_spender], _fee);
        return true;
    }

    /**
     * @notice Decrease the amount of tokens that an owner allowed to a spender.
     * @param _signature bytes The signature, issued by the owner
     * @param _spender address The address which will spend the funds.
     * @param _subtractedValue uint256 The amount of tokens to decrease the allowance by.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function decreaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(signatures[_signature] == false);

        bytes32 hashedTx = recoverPreSignedHash(address(this), decreaseApprovalSig, _spender, _subtractedValue, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        require(_nonce == nonces[from].add(1));
        //require(_subtractedValue <= balances[from]);
        //require(_subtractedValue <= allowed[from][_spender]);
        //require(_subtractedValue <= allowed[from][_spender]);
        require(_fee <= balances[from]);

        nonces[from] = _nonce;
        signatures[_signature] = true;
        uint oldValue = allowed[from][_spender];
        if (_subtractedValue > oldValue) {
            allowed[from][_spender] = 0;
        } else {
            allowed[from][_spender] = oldValue.sub(_subtractedValue);
        }
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, _subtractedValue);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowed[from][_spender], _fee);
        return true;
    }

    /**
     * @notice Transfer tokens from one address to another
     * @param _signature bytes The signature, issued by the spender.
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the spender.
     * @param _nonce uint256 Presigned transaction number.
     */
    /*function transferFromPreSigned(
        bytes _signature,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(signatures[_signature] == false);
        signatures[_signature] = true;

        bytes32 hashedTx = transferFromPreSignedHashing(address(this), _from, _to, _value, _fee, _nonce);

        address spender = recover(hashedTx, _signature);
        require(spender != address(0));
        require(_value.add(_fee) <= balances[_from])​;

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][spender] = allowed[_from][spender].sub(_value);

        balances[spender] = balances[spender].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Transfer(_from, _to, _value);
        emit Transfer(spender, msg.sender, _fee);
        return true;
    }*/

     /**
      * @notice Hash (keccak256) of the payload used by recoverPreSignedHash
      * @param _token address The address of the token
      * @param _spender address The address which will spend the funds.
      * @param _value uint256 The amount of tokens.
      * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
      * @param _nonce uint256 Presigned transaction number.
      */    
    function recoverPreSignedHash(
        address _token,
        bytes4 _functionSig,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
        )
      public pure returns (bytes32)
      {
        return keccak256(_token, _functionSig, _spender, _value, _fee, _nonce);
    }

    /**
     * @notice Recover signer address from a message by using his signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes sig) public pure returns (address) {
      bytes32 r;
      bytes32 s;
      uint8 v;

      //Check the signature length
      if (sig.length != 65) {
        return (address(0));
      }

      // Divide the signature in r, s and v variables
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
        return ecrecover(hash, v, r, s);
      }
    }

}

contract BeepToken is ERC865Token, RBAC{

    string public constant name = "Beepnow Token";
    string public constant symbol = "BPN";
    uint8 public constant decimals = 0;
    
    /* Mapping of whitelisted users */
    mapping (address => bool) transfersBlacklist;
    string constant ROLE_ADMIN = "admin";
    string constant ROLE_DELEGATE = "delegate";

    bytes4 internal constant transferSig = 0x48664c16;

    event UserInsertedInBlackList(address indexed user);
    event UserRemovedFromBlackList(address indexed user);
    event TransferWhitelistOnly(bool flag);
    event DelegatedEscrow(address indexed guest, address indexed beeper, uint256 total, uint256 nonce, bytes signature);
    event DelegatedRemittance(address indexed guest, address indexed beeper, uint256 value, uint256 _fee, uint256 nonce, bytes signature);

	modifier onlyAdmin() {
        require(hasRole(msg.sender, ROLE_ADMIN));
        _;
    }

    modifier onlyAdminOrDelegates() {
        require(hasRole(msg.sender, ROLE_ADMIN) || hasRole(msg.sender, ROLE_DELEGATE));
        _;
    }

    /*modifier onlyWhitelisted(bytes _signature, address _from, uint256 _value, uint256 _fee, uint256 _nonce) {
        bytes32 hashedTx = recoverPreSignedHash(address(this), transferSig, _from, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(!isUserInBlackList(from));
        _;
    }*/

    function onlyWhitelisted(bytes _signature, address _from, uint256 _value, uint256 _fee, uint256 _nonce) internal view returns(bool) {
        bytes32 hashedTx = recoverPreSignedHash(address(this), transferSig, _from, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(!isUserInBlackList(from));
        return true;
    }

    function addAdmin(address _addr) onlyOwner public {
        addRole(_addr, ROLE_ADMIN);
    }

    function removeAdmin(address _addr) onlyOwner public {
        removeRole(_addr, ROLE_ADMIN);
    }

    function addDelegate(address _addr) onlyAdmin public {
        addRole(_addr, ROLE_DELEGATE);
    }

    function removeDelegate(address _addr) onlyAdmin public {
        removeRole(_addr, ROLE_DELEGATE);
    }

    constructor(address _Admin, address reserve) public {
        require(_Admin != address(0));
        require(reserve != address(0));
        totalSupply_ = 17500000000;
		balances[reserve] = totalSupply_;
        emit Transfer(address(0), reserve, totalSupply_);
        addRole(_Admin, ROLE_ADMIN);
    }

    /**
     * Is the address allowed to transfer
     * @return true if the sender can transfer
     */
    function isUserInBlackList(address _user) public constant returns (bool) {
        require(_user != 0x0);
        return transfersBlacklist[_user];
    }


    /**
     *  User removed from Blacklist
     */
    function whitelistUserForTransfers(address _user) onlyAdmin public {
        require(isUserInBlackList(_user));
        transfersBlacklist[_user] = false;
        emit UserRemovedFromBlackList(_user);
    }

    /**
     *  User inserted into Blacklist
     */
    function blacklistUserForTransfers(address _user) onlyAdmin public {
        require(!isUserInBlackList(_user));
        transfersBlacklist[_user] = true;
        emit UserInsertedInBlackList(_user);
    }

    /**
    * @notice transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!isUserInBlackList(msg.sender));
        return super.transfer(_to, _value);
    }

    /**
     * @notice Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0));
        require(_to != address(0));
        require(!isUserInBlackList(_from));
        return super.transferFrom(_from, _to, _value);
    }

    function transferPreSigned(bytes _signature, address _to, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdminOrDelegates public returns (bool){
        require(_to != address(0));
        onlyWhitelisted(_signature, _to, _value, _fee, _nonce);
        return super.transferPreSigned(_signature, _to, _value, _fee, _nonce);
    }

    function approvePreSigned(bytes _signature, address _spender, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdminOrDelegates public returns (bool){
        require(_spender != address(0));
        onlyWhitelisted(_signature, _spender, _value, _fee, _nonce);
        return super.approvePreSigned(_signature, _spender, _value, _fee, _nonce);
    }

    function increaseApprovalPreSigned(bytes _signature, address _spender, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdminOrDelegates public returns (bool){
        require(_spender != address(0));
        onlyWhitelisted(_signature, _spender, _value, _fee, _nonce);
        return super.increaseApprovalPreSigned(_signature, _spender, _value, _fee, _nonce);
    }

    function decreaseApprovalPreSigned(bytes _signature, address _spender, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdminOrDelegates public returns (bool){
        require(_spender != address(0));
        onlyWhitelisted(_signature, _spender, _value, _fee, _nonce);
        return super.decreaseApprovalPreSigned(_signature, _spender, _value, _fee, _nonce);
    }

    /*function transferFromPreSigned(bytes _signature, address _from, address _to, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdminOrDelegates public returns (bool){
        require(_from != address(0));
        require(_to != address(0));
        onlyWhitelisted(_signature, _spender, _value, _fee, _nonce);
        return super.transferPreSigned(_signature, _to, _value, _fee, _nonce);
    }*/

    /* Locking funds. User signs the offline transaction and the admin will execute this, through which the admin account the funds */
    function delegatedSignedEscrow(bytes _signature, address _from, address _to, address _admin, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdmin public returns (bool){
        require(_from != address(0));
        require(_to != address(0));
        require(_admin != address(0));
        onlyWhitelisted(_signature, _from, _value, _fee, _nonce); 
        require(hasRole(_admin, ROLE_ADMIN));
        require(_nonce == nonces[_from].add(1));
        require(signatures[_signature] == false);
        uint256 _total = _value.add(_fee);
        require(_total <= balances[_from]);

        nonces[_from] = _nonce;
        signatures[_signature] = true;
        balances[_from] = balances[_from].sub(_total);
        balances[_admin] = balances[_admin].add(_total);

        emit Transfer(_from, _admin, _total);
        emit DelegatedEscrow(_from, _to, _total, _nonce, _signature);
        return true;
    }

    /* Releasing funds.  User signs the offline transaction and the admin will execute this, in which other user receives the funds. */
    function delegatedSignedRemittance(bytes _signature, address _from, address _to, address _admin, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdmin public returns (bool){
        require(_from != address(0));
        require(_to != address(0));
        require(_admin != address(0));
        onlyWhitelisted(_signature, _from, _value, _fee, _nonce);
        require(hasRole(_admin, ROLE_ADMIN));
        require(_nonce == nonces[_from].add(1));
        require(signatures[_signature] == false);
        require(_value.add(_fee) <= balances[_from]);

        nonces[_from] = _nonce;
        signatures[_signature] = true;
        balances[_from] = balances[_from].sub(_value).sub(_fee);
        balances[_admin] = balances[_admin].add(_fee);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        emit Transfer(_from, _admin, _fee);
        emit DelegatedRemittance(_from, _to, _value, _fee, _nonce, _signature);
        return true;
    }
    
}