pragma solidity 0.4.24;


// File openzeppelin-solidity/contracts/token/ERC20/<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c188849382f3f1efb2aead81b7f0eff0f3eff1">[email&#160;protected]</a>

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address _who) external view returns (uint256);

  function allowance(address _owner, address _spender)
    external view returns (uint256);

  function transfer(address _to, uint256 _value) external returns (bool);

  function approve(address _spender, uint256 _value)
    external returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


// File openzeppelin-solidity/contracts/math/<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b5e6d4d3d0f8d4c1dd9bc6dad9f5c3849b84879b85">[email&#160;protected]</a>

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


// File openzeppelin-solidity/contracts/token/ERC20/<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4005120372706e332f2c0036716e71726e70">[email&#160;protected]</a>

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private balances_;

  mapping (address => mapping (address => uint256)) private allowed_;

  uint256 private totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances_[_owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed_[_owner][_spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances_[msg.sender]);
    require(_to != address(0));

    balances_[msg.sender] = balances_[msg.sender].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed_[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances_[_from]);
    require(_value <= allowed_[_from][msg.sender]);
    require(_to != address(0));

    balances_[_from] = balances_[_from].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed_[msg.sender][_spender] = (
      allowed_[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed_[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed_[msg.sender][_spender] = 0;
    } else {
      allowed_[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param _account The account that will receive the created tokens.
   * @param _amount The amount that will be created.
   */
  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);
    totalSupply_ = totalSupply_.add(_amount);
    balances_[_account] = balances_[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  function _burn(address _account, uint256 _amount) internal {
    require(_account != 0);
    require(_amount <= balances_[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances_[_account] = balances_[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal _burn function.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed_[_account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed_[_account][msg.sender] = allowed_[_account][msg.sender].sub(
      _amount);
    _burn(_account, _amount);
  }
}


// File openzeppelin-solidity/contracts/token/ERC20/<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c89ba9aead8d9a8bfaf8e6bba7a488bef9e6f9fae6f8">[email&#160;protected]</a>

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    IERC20 _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    IERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    IERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}


// File openzeppelin-solidity/contracts/ownership/<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a4ebd3cac5c6c8c18ad7cbc8e4d2958a95968a94">[email&#160;protected]</a>

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
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
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


// File openzeppelin-solidity/contracts/access/rbac/<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3a6855565f49144955567a4c0b140b08140a">[email&#160;protected]</a>

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage _role, address _account)
    internal
  {
    _role.bearer[_account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage _role, address _account)
    internal
  {
    _role.bearer[_account] = false;
  }

  /**
   * @dev check if an account has this role
   * // reverts
   */
  function check(Role storage _role, address _account)
    internal
    view
  {
    require(has(_role, _account));
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage _role, address _account)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_account];
  }
}


// File openzeppelin-solidity/contracts/access/rbac/<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="44160605076a372b280432756a75766a74">[email&#160;protected]</a>

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  /**
   * @dev reverts if addr does not have role
   * @param _operator address
   * @param _role the name of the role
   * // reverts
   */
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

  /**
   * @dev determine if addr has role
   * @param _operator address
   * @param _role the name of the role
   * @return bool
   */
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

  /**
   * @dev add a role to an address
   * @param _operator address
   * @param _role the name of the role
   */
  function _addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  /**
   * @dev remove a role from an address
   * @param _operator address
   * @param _role the name of the role
   */
  function _removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param _role the name of the role
   * // reverts
   */
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param _roles the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] _roles) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < _roles.length; i++) {
  //         if (hasRole(msg.sender, _roles[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}


// File openzeppelin-solidity/contracts/cryptography/<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1451575047553a677b785462253a25263a24">[email&#160;protected]</a>

/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param _hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param _signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 _hash, bytes _signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (_signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(_signature, 32))
      s := mload(add(_signature, 64))
      v := byte(0, mload(add(_signature, 96)))
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
      return ecrecover(_hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 _hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
    );
  }
}


// File openzeppelin-solidity/contracts/access/<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="12417b757c7366676077507d677c7177603c617d7e5264233c23203c22">[email&#160;protected]</a>

/**
 * @title SignatureBouncer
 * @author PhABC, Shrugs and aflesher
 * @dev Bouncer allows users to submit a signature as a permission to do an action.
 * If the signature is from one of the authorized bouncer addresses, the signature
 * is valid. The owner of the contract adds/removes bouncers.
 * Bouncer addresses can be individual servers signing grants or different
 * users within a decentralized club that have permission to invite other members.
 * This technique is useful for whitelists and airdrops; instead of putting all
 * valid addresses on-chain, simply sign a grant of the form
 * keccak256(abi.encodePacked(`:contractAddress` + `:granteeAddress`)) using a valid bouncer address.
 * Then restrict access to your crowdsale/whitelist/airdrop using the
 * `onlyValidSignature` modifier (or implement your own using _isValidSignature).
 * In addition to `onlyValidSignature`, `onlyValidSignatureAndMethod` and
 * `onlyValidSignatureAndData` can be used to restrict access to only a given method
 * or a given method with given parameters respectively.
 * See the tests Bouncer.test.js for specific usage examples.
 * @notice A method that uses the `onlyValidSignatureAndData` modifier must make the _signature
 * parameter the "last" parameter. You cannot sign a message that has its own
 * signature in it so the last 128 bytes of msg.data (which represents the
 * length of the _signature data and the _signaature data itself) is ignored when validating.
 * Also non fixed sized parameters make constructing the data in the signature
 * much more complex. See https://ethereum.stackexchange.com/a/50616 for more details.
 */
contract SignatureBouncer is Ownable, RBAC {
  using ECDSA for bytes32;

  // Name of the bouncer role.
  string private constant ROLE_BOUNCER = "bouncer";
  // Function selectors are 4 bytes long, as documented in
  // https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector
  uint256 private constant METHOD_ID_SIZE = 4;
  // Signature size is 65 bytes (tightly packed v + r + s), but gets padded to 96 bytes
  uint256 private constant SIGNATURE_SIZE = 96;

  /**
   * @dev requires that a valid signature of a bouncer was provided
   */
  modifier onlyValidSignature(bytes _signature)
  {
    require(_isValidSignature(msg.sender, _signature));
    _;
  }

  /**
   * @dev requires that a valid signature with a specifed method of a bouncer was provided
   */
  modifier onlyValidSignatureAndMethod(bytes _signature)
  {
    require(_isValidSignatureAndMethod(msg.sender, _signature));
    _;
  }

  /**
   * @dev requires that a valid signature with a specifed method and params of a bouncer was provided
   */
  modifier onlyValidSignatureAndData(bytes _signature)
  {
    require(_isValidSignatureAndData(msg.sender, _signature));
    _;
  }

  /**
   * @dev Determine if an account has the bouncer role.
   * @return true if the account is a bouncer, false otherwise.
   */
  function isBouncer(address _account) public view returns(bool) {
    return hasRole(_account, ROLE_BOUNCER);
  }

  /**
   * @dev allows the owner to add additional bouncer addresses
   */
  function addBouncer(address _bouncer)
    public
    onlyOwner
  {
    require(_bouncer != address(0));
    _addRole(_bouncer, ROLE_BOUNCER);
  }

  /**
   * @dev allows the owner to remove bouncer addresses
   */
  function removeBouncer(address _bouncer)
    public
    onlyOwner
  {
    _removeRole(_bouncer, ROLE_BOUNCER);
  }

  /**
   * @dev is the signature of `this + sender` from a bouncer?
   * @return bool
   */
  function _isValidSignature(address _address, bytes _signature)
    internal
    view
    returns (bool)
  {
    return _isValidDataHash(
      keccak256(abi.encodePacked(address(this), _address)),
      _signature
    );
  }

  /**
   * @dev is the signature of `this + sender + methodId` from a bouncer?
   * @return bool
   */
  function _isValidSignatureAndMethod(address _address, bytes _signature)
    internal
    view
    returns (bool)
  {
    bytes memory data = new bytes(METHOD_ID_SIZE);
    for (uint i = 0; i < data.length; i++) {
      data[i] = msg.data[i];
    }
    return _isValidDataHash(
      keccak256(abi.encodePacked(address(this), _address, data)),
      _signature
    );
  }

  /**
    * @dev is the signature of `this + sender + methodId + params(s)` from a bouncer?
    * @notice the _signature parameter of the method being validated must be the "last" parameter
    * @return bool
    */
  function _isValidSignatureAndData(address _address, bytes _signature)
    internal
    view
    returns (bool)
  {
    require(msg.data.length > SIGNATURE_SIZE);
    bytes memory data = new bytes(msg.data.length - SIGNATURE_SIZE);
    for (uint i = 0; i < data.length; i++) {
      data[i] = msg.data[i];
    }
    return _isValidDataHash(
      keccak256(abi.encodePacked(address(this), _address, data)),
      _signature
    );
  }

  /**
   * @dev internal function to convert a hash to an eth signed message
   * and then recover the signature and check it against the bouncer role
   * @return bool
   */
  function _isValidDataHash(bytes32 _hash, bytes _signature)
    internal
    view
    returns (bool)
  {
    address signer = _hash
      .toEthSignedMessageHash()
      .recover(_signature);
    return isBouncer(signer);
  }
}


// File contracts/bouncers/EscrowedERC20Bouncer.sol

contract EscrowedERC20Bouncer is SignatureBouncer {
  using SafeERC20 for IERC20;

  uint256 public nonce;

  modifier onlyBouncer()
  {
    require(isBouncer(msg.sender), "DOES_NOT_HAVE_BOUNCER_ROLE");
    _;
  }

  modifier validDataWithoutSender(bytes _signature)
  {
    require(_isValidSignatureAndData(address(this), _signature), "INVALID_SIGNATURE");
    _;
  }

  constructor(address _bouncer)
    public
  {
    addBouncer(_bouncer);
  }

  /**
   * allow anyone with a valid bouncer signature for the msg data to send `_amount` of `_token` to `_to`
   */
  function withdraw(uint256 _nonce, IERC20 _token, address _to, uint256 _amount, bytes _signature)
    public
    validDataWithoutSender(_signature)
  {
    require(_nonce > nonce, "NONCE_GT_NONCE_REQUIRED");
    nonce = _nonce;
    _token.safeTransfer(_to, _amount);
  }

  /**
   * Allow the bouncer to withdraw all of the ERC20 tokens in the contract
   */
  function withdrawAll(IERC20 _token, address _to)
    public
    onlyBouncer
  {
    _token.safeTransfer(_to, _token.balanceOf(address(this)));
  }
}


// File openzeppelin-solidity/contracts/token/ERC20/<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7f3a2d3c4d4f3216110b1e1d131a510c10133f094e514e4d514f">[email&#160;protected]</a>

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract ERC20Mintable is ERC20, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    _mint(_to, _amount);
    emit Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


// File contracts/bouncers/MintableERC20Bouncer.sol

contract MintableERC20Bouncer is SignatureBouncer {

  uint256 public nonce;

  modifier validDataWithoutSender(bytes _signature)
  {
    require(_isValidSignatureAndData(address(this), _signature), "INVALID_SIGNATURE");
    _;
  }

  constructor(address _bouncer)
    public
  {
    addBouncer(_bouncer);
  }

  /**
   * allow anyone with a valid bouncer signature for the msg data to mint `_amount` of `_token` to `_to`
   */
  function mint(uint256 _nonce, ERC20Mintable _token, address _to, uint256 _amount, bytes _signature)
    public
    validDataWithoutSender(_signature)
  {
    require(_nonce > nonce, "NONCE_GT_NONCE_REQUIRED");
    nonce = _nonce;
    _token.mint(_to, _amount);
  }
}


// File openzeppelin-solidity/contracts/token/ERC20/<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="490c1b0a7b790d2c3d2820252c2d673a2625093f7867787b6779">[email&#160;protected]</a>

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}


// File openzeppelin-solidity/contracts/proposals/ERC1046/<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="11457e7a747f5c746570757065703f627e7d5167203f20233f21">[email&#160;protected]</a>

/**
 * @title ERC-1047 Token Metadata
 * @dev See https://eips.ethereum.org/EIPS/eip-1046
 * @dev tokenURI must respond with a URI that implements https://eips.ethereum.org/EIPS/eip-1047
 * @dev TODO - update https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC721/IERC721.sol#L17 when 1046 is finalized
 */
contract ERC20TokenMetadata is IERC20 {
  function tokenURI() external view returns (string);
}


contract ERC20WithMetadata is ERC20TokenMetadata {
  string private tokenURI_ = "";

  constructor(string _tokenURI)
    public
  {
    tokenURI_ = _tokenURI;
  }

  function tokenURI() external view returns (string) {
    return tokenURI_;
  }
}


// File contracts/tokens/KataToken.sol

contract KataToken is ERC20, ERC20Detailed, ERC20Mintable, ERC20WithMetadata {
  constructor(
    string _name,
    string _symbol,
    uint8 _decimals,
    string _tokenURI
  )
    ERC20WithMetadata(_tokenURI)
    ERC20Detailed(_name, _symbol, _decimals)
    public
  {}
}


// File contracts/deploy/TokenAndBouncerDeployer.sol

contract TokenAndBouncerDeployer is Ownable {
  event Deployed(address indexed token, address indexed bouncer);

  function deploy(
    string _name,
    string _symbol,
    uint8 _decimals,
    string _tokenURI,
    address _signer
  )
    public
    onlyOwner
  {
    MintableERC20Bouncer bouncer = new MintableERC20Bouncer(_signer);
    KataToken token = new KataToken(_name, _symbol, _decimals, _tokenURI);
    token.transferOwnership(address(bouncer));

    emit Deployed(address(token), address(bouncer));

    selfdestruct(msg.sender);
  }
}


// File contracts/mocks/MockToken.sol

contract MockToken is ERC20Detailed, ERC20Mintable {
  constructor(string _name, string _symbol, uint8 _decimals)
    ERC20Detailed(_name, _symbol, _decimals)
    ERC20Mintable()
    ERC20()
    public
  {

  }
}


// File contracts/old/ClaimableToken.sol

// import "./MintableERC721Token.sol";
// import "openzeppelin-solidity/contracts/token/ERC721/DefaultTokenURI.sol";


// contract ClaimableToken is DefaultTokenURI, MintableERC721Token {

//   constructor(string _name, string _symbol, string _tokenURI)
//     MintableERC721Token(_name, _symbol)
//     DefaultTokenURI(_tokenURI)
//     public
//   {

//   }
// }


// File contracts/old/ClaimableTokenDeployer.sol

// import "./ClaimableTokenMinter.sol";
// import "./ClaimableToken.sol";


// contract ClaimableTokenDeployer {
//   ClaimableToken public token;
//   ClaimableTokenMinter public minter;

//   constructor(
//     string _name,
//     string _symbol,
//     string _tokenURI,
//     address _bouncer
//   )
//     public
//   {
//     token = new ClaimableToken(_name, _symbol, _tokenURI);
//     minter = new ClaimableTokenMinter(token);
//     token.addOwner(msg.sender);
//     token.addMinter(address(minter));
//     minter.addOwner(msg.sender);
//     minter.addBouncer(_bouncer);
//   }
// }


// File contracts/old/ClaimableTokenMinter.sol

// import "./ClaimableToken.sol";
// import "openzeppelin-solidity/contracts/access/ERC721Minter.sol";
// import "openzeppelin-solidity/contracts/access/NonceTracker.sol";


// contract ClaimableTokenMinter is NonceTracker, ERC721Minter {

//   constructor(ClaimableToken _token)
//     ERC721Minter(_token)
//     public
//   {

//   }

//   function mint(bytes _sig)
//     withAccess(msg.sender, 1)
//     public
//     returns (uint256)
//   {
//     return super.mint(_sig);
//   }
// }