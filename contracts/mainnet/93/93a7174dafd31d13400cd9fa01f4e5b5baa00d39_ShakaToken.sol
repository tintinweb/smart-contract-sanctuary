pragma solidity ^0.4.25;

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

// File: openzeppelin-solidity/contracts/access/roles/MinterRole.sol

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, MinterRole {
  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol

/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract ERC20Capped is ERC20Mintable {

  uint256 private _cap;

  constructor(uint256 cap)
    public
  {
    require(cap > 0);
    _cap = cap;
  }

  /**
   * @return the cap for the token minting.
   */
  function cap() public view returns(uint256) {
    return _cap;
  }

  function _mint(address account, uint256 value) internal {
    require(totalSupply().add(value) <= _cap);
    super._mint(account, value);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ERC20Burnable is ERC20 {

  /**
   * @dev Burns a specific amount of tokens.
   * @param value The amount of token to be burned.
   */
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param from address The address which you want to send tokens from
   * @param value uint256 The amount of token to be burned
   */
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

/**
 * Utility library of inline functions on addresses
 */
library Address {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

// File: openzeppelin-solidity/contracts/introspection/ERC165Checker.sol

/**
 * @title ERC165Checker
 * @dev Use `using ERC165Checker for address`; to include this library
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
library ERC165Checker {
  // As per the EIP-165 spec, no interface should ever match 0xffffffff
  bytes4 private constant _InterfaceId_Invalid = 0xffffffff;

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
   */

  /**
   * @notice Query if a contract supports ERC165
   * @param account The address of the contract to query for support of ERC165
   * @return true if the contract at account implements ERC165
   */
  function _supportsERC165(address account)
    internal
    view
    returns (bool)
  {
    // Any contract that implements ERC165 must explicitly indicate support of
    // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
    return _supportsERC165Interface(account, _InterfaceId_ERC165) &&
      !_supportsERC165Interface(account, _InterfaceId_Invalid);
  }

  /**
   * @notice Query if a contract implements an interface, also checks support of ERC165
   * @param account The address of the contract to query for support of an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @return true if the contract at account indicates support of the interface with
   * identifier interfaceId, false otherwise
   * @dev Interface identification is specified in ERC-165.
   */
  function _supportsInterface(address account, bytes4 interfaceId)
    internal
    view
    returns (bool)
  {
    // query support of both ERC165 as per the spec and support of _interfaceId
    return _supportsERC165(account) &&
      _supportsERC165Interface(account, interfaceId);
  }

  /**
   * @notice Query if a contract implements interfaces, also checks support of ERC165
   * @param account The address of the contract to query for support of an interface
   * @param interfaceIds A list of interface identifiers, as specified in ERC-165
   * @return true if the contract at account indicates support all interfaces in the
   * interfaceIds list, false otherwise
   * @dev Interface identification is specified in ERC-165.
   */
  function _supportsAllInterfaces(address account, bytes4[] interfaceIds)
    internal
    view
    returns (bool)
  {
    // query support of ERC165 itself
    if (!_supportsERC165(account)) {
      return false;
    }

    // query support of each interface in _interfaceIds
    for (uint256 i = 0; i < interfaceIds.length; i++) {
      if (!_supportsERC165Interface(account, interfaceIds[i])) {
        return false;
      }
    }

    // all interfaces supported
    return true;
  }

  /**
   * @notice Query if a contract implements an interface, does not check ERC165 support
   * @param account The address of the contract to query for support of an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @return true if the contract at account indicates support of the interface with
   * identifier interfaceId, false otherwise
   * @dev Assumes that account contains a contract that supports ERC165, otherwise
   * the behavior of this method is undefined. This precondition can be checked
   * with the `supportsERC165` method in this library.
   * Interface identification is specified in ERC-165.
   */
  function _supportsERC165Interface(address account, bytes4 interfaceId)
    private
    view
    returns (bool)
  {
    // success determines whether the staticcall succeeded and result determines
    // whether the contract at account indicates support of _interfaceId
    (bool success, bool result) = _callERC165SupportsInterface(
      account, interfaceId);

    return (success && result);
  }

  /**
   * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
   * @param account The address of the contract to query for support of an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @return success true if the STATICCALL succeeded, false otherwise
   * @return result true if the STATICCALL succeeded and the contract at account
   * indicates support of the interface with identifier interfaceId, false otherwise
   */
  function _callERC165SupportsInterface(
    address account,
    bytes4 interfaceId
  )
    private
    view
    returns (bool success, bool result)
  {
    bytes memory encodedParams = abi.encodeWithSelector(
      _InterfaceId_ERC165,
      interfaceId
    );

    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let encodedParams_data := add(0x20, encodedParams)
      let encodedParams_size := mload(encodedParams)

      let output := mload(0x40)  // Find empty storage location using "free memory pointer"
      mstore(output, 0x0)

      success := staticcall(
        30000,                 // 30k gas
        account,              // To addr
        encodedParams_data,
        encodedParams_size,
        output,
        0x20                   // Outputs are 32 bytes long
      )

      result := mload(output)  // Load the result
    }
  }
}

// File: openzeppelin-solidity/contracts/introspection/IERC165.sol

/**
 * @title IERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

// File: openzeppelin-solidity/contracts/introspection/ERC165.sol

/**
 * @title ERC165
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
   */

  /**
   * @dev a mapping of interface id to whether or not it&#39;s supported
   */
  mapping(bytes4 => bool) private _supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    internal
  {
    _registerInterface(_InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

  /**
   * @dev internal method for registering an interface
   */
  function _registerInterface(bytes4 interfaceId)
    internal
  {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

// File: erc-payable-token/contracts/token/ERC1363/IERC1363.sol

/**
 * @title IERC1363 Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for a Payable Token contract as defined in
 *  https://github.com/ethereum/EIPs/issues/1363
 */
contract IERC1363 is IERC20, ERC165 {
  /*
   * Note: the ERC-165 identifier for this interface is 0x4bbee2df.
   * 0x4bbee2df ===
   *   bytes4(keccak256(&#39;transferAndCall(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;transferAndCall(address,uint256,bytes)&#39;)) ^
   *   bytes4(keccak256(&#39;transferFromAndCall(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;transferFromAndCall(address,address,uint256,bytes)&#39;))
   */

  /*
   * Note: the ERC-165 identifier for this interface is 0xfb9ec8ce.
   * 0xfb9ec8ce ===
   *   bytes4(keccak256(&#39;approveAndCall(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;approveAndCall(address,uint256,bytes)&#39;))
   */

  /**
   * @notice Transfer tokens from `msg.sender` to another address
   *  and then call `onTransferReceived` on receiver
   * @param to address The address which you want to transfer to
   * @param value uint256 The amount of tokens to be transferred
   * @return true unless throwing
   */
  function transferAndCall(address to, uint256 value) public returns (bool);

  /**
   * @notice Transfer tokens from `msg.sender` to another address
   *  and then call `onTransferReceived` on receiver
   * @param to address The address which you want to transfer to
   * @param value uint256 The amount of tokens to be transferred
   * @param data bytes Additional data with no specified format, sent in call to `to`
   * @return true unless throwing
   */
  function transferAndCall(address to, uint256 value, bytes data) public returns (bool); // solium-disable-line max-len

  /**
   * @notice Transfer tokens from one address to another
   *  and then call `onTransferReceived` on receiver
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 The amount of tokens to be transferred
   * @return true unless throwing
   */
  function transferFromAndCall(address from, address to, uint256 value) public returns (bool); // solium-disable-line max-len


  /**
   * @notice Transfer tokens from one address to another
   *  and then call `onTransferReceived` on receiver
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 The amount of tokens to be transferred
   * @param data bytes Additional data with no specified format, sent in call to `to`
   * @return true unless throwing
   */
  function transferFromAndCall(address from, address to, uint256 value, bytes data) public returns (bool); // solium-disable-line max-len, arg-overflow

  /**
   * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
   *  and then call `onApprovalReceived` on spender
   *  Beware that changing an allowance with this method brings the risk that someone may use both the old
   *  and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   *  race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   *  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender address The address which will spend the funds
   * @param value uint256 The amount of tokens to be spent
   */
  function approveAndCall(address spender, uint256 value) public returns (bool); // solium-disable-line max-len

  /**
   * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
   *  and then call `onApprovalReceived` on spender
   *  Beware that changing an allowance with this method brings the risk that someone may use both the old
   *  and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   *  race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   *  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender address The address which will spend the funds
   * @param value uint256 The amount of tokens to be spent
   * @param data bytes Additional data with no specified format, sent in call to `spender`
   */
  function approveAndCall(address spender, uint256 value, bytes data) public returns (bool); // solium-disable-line max-len
}

// File: erc-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol

/**
 * @title IERC1363Receiver Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for any contract that wants to support transferAndCall or transferFromAndCall
 *  from ERC1363 token contracts as defined in
 *  https://github.com/ethereum/EIPs/issues/1363
 */
contract IERC1363Receiver {
  /*
   * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
   * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
   */

  /**
   * @notice Handle the receipt of ERC1363 tokens
   * @dev Any ERC1363 smart contract calls this function on the recipient
   *  after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
   *  transfer. Return of other than the magic value MUST result in the
   *  transaction being reverted.
   *  Note: the token contract address is always the message sender.
   * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
   * @param from address The address which are token transferred from
   * @param value uint256 The amount of tokens transferred
   * @param data bytes Additional data with no specified format
   * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
   *  unless throwing
   */
  function onTransferReceived(address operator, address from, uint256 value, bytes data) external returns (bytes4); // solium-disable-line max-len, arg-overflow
}

// File: erc-payable-token/contracts/token/ERC1363/IERC1363Spender.sol

/**
 * @title IERC1363Spender Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for any contract that wants to support approveAndCall
 *  from ERC1363 token contracts as defined in
 *  https://github.com/ethereum/EIPs/issues/1363
 */
contract IERC1363Spender {
  /*
   * Note: the ERC-165 identifier for this interface is 0x7b04a2d0.
   * 0x7b04a2d0 === bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
   */

  /**
   * @notice Handle the approval of ERC1363 tokens
   * @dev Any ERC1363 smart contract calls this function on the recipient
   *  after an `approve`. This function MAY throw to revert and reject the
   *  approval. Return of other than the magic value MUST result in the
   *  transaction being reverted.
   *  Note: the token contract address is always the message sender.
   * @param owner address The address which called `approveAndCall` function
   * @param value uint256 The amount of tokens to be spent
   * @param data bytes Additional data with no specified format
   * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`
   *  unless throwing
   */
  function onApprovalReceived(address owner, uint256 value, bytes data) external returns (bytes4); // solium-disable-line max-len
}

// File: erc-payable-token/contracts/token/ERC1363/ERC1363.sol

/**
 * @title ERC1363
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Implementation of an ERC1363 interface
 */
contract ERC1363 is ERC20, IERC1363 { // solium-disable-line max-len
  using Address for address;

  /*
   * Note: the ERC-165 identifier for this interface is 0x4bbee2df.
   * 0x4bbee2df ===
   *   bytes4(keccak256(&#39;transferAndCall(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;transferAndCall(address,uint256,bytes)&#39;)) ^
   *   bytes4(keccak256(&#39;transferFromAndCall(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;transferFromAndCall(address,address,uint256,bytes)&#39;))
   */
  bytes4 internal constant _InterfaceId_ERC1363Transfer = 0x4bbee2df;

  /*
   * Note: the ERC-165 identifier for this interface is 0xfb9ec8ce.
   * 0xfb9ec8ce ===
   *   bytes4(keccak256(&#39;approveAndCall(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;approveAndCall(address,uint256,bytes)&#39;))
   */
  bytes4 internal constant _InterfaceId_ERC1363Approve = 0xfb9ec8ce;

  // Equals to `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC1363Receiver(0).onTransferReceived.selector`
  bytes4 private constant _ERC1363_RECEIVED = 0x88a7ca5c;

  // Equals to `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`
  // which can be also obtained as `IERC1363Spender(0).onApprovalReceived.selector`
  bytes4 private constant _ERC1363_APPROVED = 0x7b04a2d0;

  constructor() public {
    // register the supported interfaces to conform to ERC1363 via ERC165
    _registerInterface(_InterfaceId_ERC1363Transfer);
    _registerInterface(_InterfaceId_ERC1363Approve);
  }

  function transferAndCall(
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    return transferAndCall(to, value, "");
  }

  function transferAndCall(
    address to,
    uint256 value,
    bytes data
  )
    public
    returns (bool)
  {
    require(transfer(to, value));
    require(
      _checkAndCallTransfer(
        msg.sender,
        to,
        value,
        data
      )
    );
    return true;
  }

  function transferFromAndCall(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    // solium-disable-next-line arg-overflow
    return transferFromAndCall(from, to, value, "");
  }

  function transferFromAndCall(
    address from,
    address to,
    uint256 value,
    bytes data
  )
    public
    returns (bool)
  {
    require(transferFrom(from, to, value));
    require(
      _checkAndCallTransfer(
        from,
        to,
        value,
        data
      )
    );
    return true;
  }

  function approveAndCall(
    address spender,
    uint256 value
  )
    public
    returns (bool)
  {
    return approveAndCall(spender, value, "");
  }

  function approveAndCall(
    address spender,
    uint256 value,
    bytes data
  )
    public
    returns (bool)
  {
    approve(spender, value);
    require(
      _checkAndCallApprove(
        spender,
        value,
        data
      )
    );
    return true;
  }

  /**
   * @dev Internal function to invoke `onTransferReceived` on a target address
   *  The call is not executed if the target address is not a contract
   * @param from address Representing the previous owner of the given token value
   * @param to address Target address that will receive the tokens
   * @param value uint256 The amount mount of tokens to be transferred
   * @param data bytes Optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function _checkAndCallTransfer(
    address from,
    address to,
    uint256 value,
    bytes data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return false;
    }
    bytes4 retval = IERC1363Receiver(to).onTransferReceived(
      msg.sender, from, value, data
    );
    return (retval == _ERC1363_RECEIVED);
  }

  /**
   * @dev Internal function to invoke `onApprovalReceived` on a target address
   *  The call is not executed if the target address is not a contract
   * @param spender address The address which will spend the funds
   * @param value uint256 The amount of tokens to be spent
   * @param data bytes Optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function _checkAndCallApprove(
    address spender,
    uint256 value,
    bytes data
  )
    internal
    returns (bool)
  {
    if (!spender.isContract()) {
      return false;
    }
    bytes4 retval = IERC1363Spender(spender).onApprovalReceived(
      msg.sender, value, data
    );
    return (retval == _ERC1363_APPROVED);
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: eth-token-recover/contracts/TokenRecover.sol

/**
 * @title TokenRecover
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Allow to recover any ERC20 sent into the contract for error
 */
contract TokenRecover is Ownable {

  /**
   * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
   * @param tokenAddress The token contract address
   * @param tokenAmount Number of tokens to be sent
   */
  function recoverERC20(
    address tokenAddress,
    uint256 tokenAmount
  )
    public
    onlyOwner
  {
    IERC20(tokenAddress).transfer(owner(), tokenAmount);
  }
}

// File: contracts/access/roles/OperatorRole.sol

contract OperatorRole {
  using Roles for Roles.Role;

  event OperatorAdded(address indexed account);
  event OperatorRemoved(address indexed account);

  Roles.Role private _operators;

  constructor() internal {
    _addOperator(msg.sender);
  }

  modifier onlyOperator() {
    require(isOperator(msg.sender));
    _;
  }

  function isOperator(address account) public view returns (bool) {
    return _operators.has(account);
  }

  function addOperator(address account) public onlyOperator {
    _addOperator(account);
  }

  function renounceOperator() public {
    _removeOperator(msg.sender);
  }

  function _addOperator(address account) internal {
    _operators.add(account);
    emit OperatorAdded(account);
  }

  function _removeOperator(address account) internal {
    _operators.remove(account);
    emit OperatorRemoved(account);
  }
}

// File: contracts/token/BaseToken.sol

/**
 * @title BaseToken
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Implementation of the BaseToken
 */
contract BaseToken is ERC20Detailed, ERC20Capped, ERC20Burnable, ERC1363, OperatorRole, TokenRecover {

  event MintFinished();
  event TransferEnabled();

  // indicates if minting is finished
  bool private _mintingFinished = false;

  // indicates if transfer is enabled
  bool private _transferEnabled = false;

  /**
   * @dev Tokens can be minted only before minting finished
   */
  modifier canMint() {
    require(!_mintingFinished);
    _;
  }

  /**
   * @dev Tokens can be moved only after if transfer enabled or if you are an approved operator
   */
  modifier canTransfer(address from) {
    require(_transferEnabled || isOperator(from));
    _;
  }

  /**
   * @param name Name of the token
   * @param symbol A symbol to be used as ticker
   * @param decimals Number of decimals. All the operations are done using the smallest and indivisible token unit
   * @param cap Maximum number of tokens mintable
   * @param initialSupply Initial token supply
   */
  constructor(
    string name,
    string symbol,
    uint8 decimals,
    uint256 cap,
    uint256 initialSupply
  )
    ERC20Detailed(name, symbol, decimals)
    ERC20Capped(cap)
    public
  {
    if (initialSupply > 0) {
      _mint(owner(), initialSupply);
    }
  }

  /**
   * @return if minting is finished or not
   */
  function mintingFinished() public view returns (bool) {
    return _mintingFinished;
  }

  /**
   * @return if transfer is enabled or not
   */
  function transferEnabled() public view returns (bool) {
    return _transferEnabled;
  }

  function mint(address to, uint256 value) public canMint returns (bool) {
    return super.mint(to, value);
  }

  function transfer(address to, uint256 value) public canTransfer(msg.sender) returns (bool) {
    return super.transfer(to, value);
  }

  function transferFrom(address from, address to, uint256 value) public canTransfer(from) returns (bool) {
    return super.transferFrom(from, to, value);
  }

  /**
   * @dev Function to stop minting new tokens
   */
  function finishMinting() public onlyOwner canMint {
    _mintingFinished = true;
    _transferEnabled = true;

    emit MintFinished();
    emit TransferEnabled();
  }

  /**
 * @dev Function to enable transfers.
 */
  function enableTransfer() public onlyOwner {
    _transferEnabled = true;

    emit TransferEnabled();
  }

  /**
   * @dev remove the `operator` role from address
   * @param account Address you want to remove role
   */
  function removeOperator(address account) public onlyOwner {
    _removeOperator(account);
  }

  /**
   * @dev remove the `minter` role from address
   * @param account Address you want to remove role
   */
  function removeMinter(address account) public onlyOwner {
    _removeMinter(account);
  }
}

// File: contracts/token/ShakaToken.sol

/**
 * @title ShakaToken
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Implementation of the Shaka Token
 */
contract ShakaToken is BaseToken {

  /**
   * @param name Name of the token
   * @param symbol A symbol to be used as ticker
   * @param decimals Number of decimals. All the operations are done using the smallest and indivisible token unit
   * @param cap Maximum number of tokens mintable
   * @param initialSupply Initial token supply
   */
  constructor(
    string name,
    string symbol,
    uint8 decimals,
    uint256 cap,
    uint256 initialSupply
  )
    BaseToken(
      name,
      symbol,
      decimals,
      cap,
      initialSupply
    )
    public
  {}
}