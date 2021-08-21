//SourceUnit: ITRC20.sol

pragma solidity ^0.5.5;

/*
 * @title TRC20 interface (compatible with ERC20 interface)
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface ITRC20 {
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


//SourceUnit: KTY.sol

pragma solidity ^0.5.5;
import "./TRC20.sol";


/**
 * @title TRC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on TRON all the operations are done in sun.
 *
 * Example inherits from basic TRC20 implementation but can be modified to
 * extend from other ITRC20-based tokens:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/1536
 */
contract KTY is TRC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value)
    public
    isNotPaused
    isNotBlackListed(_msgSender())
    {
        _burn(_msgSender(), value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The address which you want to send tokens from
     * @param value uint256 The amount of token to be burned
     */
    function burnFrom(address from, uint256 value)
    public
    isNotPaused
    isNotBlackListed(from)
    isNotBlackListed(_msgSender())
     {
        _burnFrom(from, value);
    }

}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.5;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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


//SourceUnit: TRC20.sol

pragma solidity ^0.5.5;

import "./ITRC20.sol";
import "./SafeMath.sol";
// import "./context.sol";
import "./adminRole.sol";
/**
 * @title Standard TRC20 token (compatible with ERC20 token)
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract TRC20 is ITRC20,AdminControl {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    constructor () internal {
        _mint(_msgSender(),200 * 1e6 * 1e6); //200 Millions
    }
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
    function transfer(address to, uint256 value)
    public
    isNotPaused
    isNotBlackListed(to)
    isNotBlackListed(_msgSender())
    returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
    public
    isNotPaused
    isNotBlackListed(spender)
    isNotBlackListed(_msgSender())
    returns (bool) {
        require(spender != address(0));

        _allowed[_msgSender()][spender] = value;
        emit Approval(_msgSender(), spender, value);
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
    isNotPaused
    isNotBlackListed(to)
    isNotBlackListed(from)
    isNotBlackListed(_msgSender())
    returns (bool)
    {
        _allowed[from][_msgSender()] = _allowed[from][_msgSender()].sub(value);
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
    isNotPaused
    isNotBlackListed(spender)
    isNotBlackListed(_msgSender())
    returns (bool)
    {
        require(spender != address(0));

        _allowed[_msgSender()][spender] = (
        _allowed[_msgSender()][spender].add(addedValue));
        emit Approval(_msgSender(), spender, _allowed[_msgSender()][spender]);
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
    isNotPaused
    isNotBlackListed(spender)
    isNotBlackListed(_msgSender())
    returns (bool)
    {
        require(spender != address(0));

        _allowed[_msgSender()][spender] = (
        _allowed[_msgSender()][spender].sub(subtractedValue));
        emit Approval(_msgSender(), spender, _allowed[_msgSender()][spender]);
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
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
        require(account != address(0));

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
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        _allowed[account][_msgSender()] = _allowed[account][_msgSender()].sub(
            value);
        _burn(account, value);
    }

}


//SourceUnit: adminRole.sol

pragma solidity ^0.5.5;

import "./roles.sol";
import "./context.sol";
// import "./safeMath.sol";


contract AdminRole is Context{

    using Admins for Admins.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event OwnershipTransfer(address indexed account);

    Admins.Role private _admins;
    address private ownerAddr;
    bool public currentState;


    constructor () internal {
        _addAdmin(_msgSender());
        _changeOwner(_msgSender());
        currentState = true;
    }

    modifier onlyOwner() {
        require(_msgSender() == Owner(),"AdminRole: caller is not owner");
        _;
      }

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()) || _msgSender() == Owner(),"AdminRole: caller does not have the Admin role");
        _;
    }
    modifier isNotPaused() {
        require(currentState,"ContractAdmin : paused contract for action");
        _;
    }

    function changeState(bool _state) public onlyAdmin returns(bool){
        require(_state != currentState,"ContractAdmin : same state");
        currentState = _state;
        return _state;
    }

    function Owner() public view returns (address) {
        return ownerAddr;
    }

    function changeOwner(address account) external onlyOwner {
      _changeOwner(account);
    }

    function _changeOwner(address account)internal{
      require(account != address(0) && account != ownerAddr ,"AdminRole: Address is Owner or zero address");
       ownerAddr = account;
       emit OwnershipTransfer(account);
    }


    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addAdmin(address account) public onlyAdmin {

        _addAdmin(account);
    }
    function removeAdmin(address account) public onlyAdmin {
        _removeAdmin(account);
    }

    function renounceAdmin() public{
        _removeAdmin(_msgSender());
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}





contract BlockRole is Context,AdminRole{

  using blocks for blocks.Role;

  event BlockAdded(address indexed account);
  event BlockRemoved(address indexed account);

  blocks.Role private _blockedUser;


  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

    modifier isNotBlackListed(address account){
       require(!getBlackListStatus(account),"ContractAdmin : Address restricted");
        _;
    }
    modifier callerNotBlackListed(){
       require(!getBlackListStatus(_msgSender()),"ContractAdmin : Address restricted");
        _;
    }

    function addBlackList(address account) public onlyAdmin {
      _addBlackList(account);
    }

    function removeBlackList(address account) public onlyAdmin {
      _removeBlackList(account);
    }

    function getBlackListStatus(address account) public view returns (bool) {
      return _blockedUser.has(account);
    }

    function _addBlackList(address account) internal {
      _blockedUser.add(account);
      emit BlockAdded(account);
    }

    function _removeBlackList(address account) internal {
      _blockedUser.remove(account);
      emit BlockRemoved(account);

    }

}


contract FundController is Context,AdminRole{

constructor() internal {}

  /*
  * @title claimTRX
  * @dev it can let admin withdraw trx from contract
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function claimTRX(address payable to, uint256 value)
  external
  onlyAdmin
  returns (bool)
  {
    require(address(this).balance >= value, "FundController: insufficient balance");

    (bool success, ) = to.call.value(value)("");
    require(success, "FundController: unable to send value, accepter may have reverted");
    return true;
  }
  /*
  * @title claimTRC10
  * @dev it can let admin withdraw any trc10 from contract
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  * @param token The tokenId of token to be transferred.

  */
   function claimTRC10(address payable to, uint256 value, uint256 token)
   external
   onlyAdmin
   returns (bool)
  {
    require(value <=  address(this).tokenBalance(token), "FundController: Not enought Token Available");
    to.transferToken(value, token);
    return true;
  }
  /*
  * @title claimTRC20
  * @dev it can let admin withdraw any trc20 from contract
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  * @param token The contract address of token to be transferred.

  */
  function claimTRC20(address to, uint256 value, address token)
  external
  onlyAdmin
  returns (bool)
  {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    bool result = success && (data.length == 0 || abi.decode(data, (bool)));
    require(result, "FundController: unable to transfer value, recipient or token may have reverted");
    return true;
  }

    //Fallback
    function() external payable { }

    function kill() public onlyOwner {
      selfdestruct(_msgSender());
    }

}
contract AdminControl is AdminRole,BlockRole,FundController{
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.

  constructor () internal { }

}


//SourceUnit: context.sol

pragma solidity ^0.5.5;

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
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


//SourceUnit: roles.sol

pragma solidity ^0.5.5;

/**
 * @title Admins
 * @dev Library for managing addresses assigned to a Role.
 */
library Admins {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Admins: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Admins: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Admins: account is the zero address");
        return role.bearer[account];
    }
}


/**
 * @title blocks
 * @dev Library for managing addresses assigned to restriction.
 */

library blocks {

  struct Role{
    /// @dev Black Lists
    mapping (address => bool) bearer;
  }

  /**
   * @dev remove an account access to this contract
   */
  function add(Role storage role, address account) internal {
      require(!has(role, account),"blocks: account already has role");

      role.bearer[account] = true;
  }

  /**
   * @dev give back an blocked account's access to this contract
   */
  function remove(Role storage role, address account) internal {
      require(has(role, account), "blocks: account does not have role");

      role.bearer[account] = false;
  }

  /**
   * @dev check if an account has blocked to use this contract
   * @return bool
   */
  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0), "blocks: account is the zero address");
      return role.bearer[account];
  }

}