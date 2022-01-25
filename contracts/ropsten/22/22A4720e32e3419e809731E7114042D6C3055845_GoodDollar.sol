/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

/**
 *Submitted for verification at Etherscan.io on 2020-08-02
*/

// File: openzeppelin-solidity/contracts/access/Roles.sol

pragma solidity ^0.5.0;

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
     * @dev remove an account's access to this role
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
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
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
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/access/roles/PauserRole.sol

pragma solidity ^0.5.0;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.5.0;


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
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
    function isOwner() public view returns (bool) {
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

// File: @daostack/infra/contracts/Reputation.sol

pragma solidity ^0.5.4;



/**
 * @title Reputation system
 * @dev A DAO has Reputation System which allows peers to rate other peers in order to build trust .
 * A reputation is use to assign influence measure to a DAO'S peers.
 * Reputation is similar to regular tokens but with one crucial difference: It is non-transferable.
 * The Reputation contract maintain a map of address to reputation value.
 * It provides an onlyOwner functions to mint and burn reputation _to (or _from) a specific address.
 */

contract Reputation is Ownable {

    uint8 public decimals = 18;             //Number of decimals of the smallest unit
    // Event indicating minting of reputation to an address.
    event Mint(address indexed _to, uint256 _amount);
    // Event indicating burning of reputation for an address.
    event Burn(address indexed _from, uint256 _amount);

      /// @dev `Checkpoint` is the structure that attaches a block number to a
      ///  given value, the block number attached is the one that last changed the
      ///  value
    struct Checkpoint {

    // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;

          // `value` is the amount of reputation at a specific block number
        uint128 value;
    }

      // `balances` is the map that tracks the balance of each address, in this
      //  contract when the balance changes the block number that the change
      //  occurred is also included in the map
    mapping (address => Checkpoint[]) balances;

      // Tracks the history of the `totalSupply` of the reputation
    Checkpoint[] totalSupplyHistory;

    /// @notice Constructor to create a Reputation
    constructor(
    ) public
    {
    }

    /// @dev This function makes it easy to get the total number of reputation
    /// @return The total number of reputation
    function totalSupply() public view returns (uint256) {
        return totalSupplyAt(block.number);
    }

  ////////////////
  // Query balance and totalSupply in History
  ////////////////
    /**
    * @dev return the reputation amount of a given owner
    * @param _owner an address of the owner which we want to get his reputation
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

      /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
      /// @param _owner The address from which the balance will be retrieved
      /// @param _blockNumber The block number when the balance is queried
      /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint256 _blockNumber)
    public view returns (uint256)
    {
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            return 0;
          // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

      /// @notice Total amount of reputation at a specific `_blockNumber`.
      /// @param _blockNumber The block number when the totalSupply is queried
      /// @return The total amount of reputation at `_blockNumber`
    function totalSupplyAt(uint256 _blockNumber) public view returns(uint256) {
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            return 0;
          // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

      /// @notice Generates `_amount` reputation that are assigned to `_owner`
      /// @param _user The address that will be assigned the new reputation
      /// @param _amount The quantity of reputation generated
      /// @return True if the reputation are generated correctly
    function mint(address _user, uint256 _amount) public onlyOwner returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint256 previousBalanceTo = balanceOf(_user);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_user], previousBalanceTo + _amount);
        emit Mint(_user, _amount);
        return true;
    }

      /// @notice Burns `_amount` reputation from `_owner`
      /// @param _user The address that will lose the reputation
      /// @param _amount The quantity of reputation to burn
      /// @return True if the reputation are burned correctly
    function burn(address _user, uint256 _amount) public onlyOwner returns (bool) {
        uint256 curTotalSupply = totalSupply();
        uint256 amountBurned = _amount;
        uint256 previousBalanceFrom = balanceOf(_user);
        if (previousBalanceFrom < amountBurned) {
            amountBurned = previousBalanceFrom;
        }
        updateValueAtNow(totalSupplyHistory, curTotalSupply - amountBurned);
        updateValueAtNow(balances[_user], previousBalanceFrom - amountBurned);
        emit Burn(_user, amountBurned);
        return true;
    }

  ////////////////
  // Internal helper functions to query and set a value in a snapshot array
  ////////////////

      /// @dev `getValueAt` retrieves the number of reputation at a given block number
      /// @param checkpoints The history of values being queried
      /// @param _block The block number to retrieve the value at
      /// @return The number of reputation being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint256 _block) internal view returns (uint256) {
        if (checkpoints.length == 0) {
            return 0;
        }

          // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock) {
            return checkpoints[checkpoints.length-1].value;
        }
        if (_block < checkpoints[0].fromBlock) {
            return 0;
        }

          // Binary search of the value in the array
        uint256 min = 0;
        uint256 max = checkpoints.length-1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

      /// @dev `updateValueAtNow` used to update the `balances` map and the
      ///  `totalSupplyHistory`
      /// @param checkpoints The history of data being updated
      /// @param _value The new number of reputation
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint256 _value) internal {
        require(uint128(_value) == _value); //check value is in the 128 bits bounderies
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
            oldCheckPoint.value = uint128(_value);
        }
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
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
    function allowance(address owner, address spender) public view returns (uint256) {
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
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
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
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol

pragma solidity ^0.5.0;


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

// File: @daostack/arc/contracts/controller/DAOToken.sol

pragma solidity ^0.5.4;





/**
 * @title DAOToken, base on zeppelin contract.
 * @dev ERC20 compatible token. It is a mintable, burnable token.
 */

contract DAOToken is ERC20, ERC20Burnable, Ownable {

    string public name;
    string public symbol;
    // solhint-disable-next-line const-name-snakecase
    uint8 public constant decimals = 18;
    uint256 public cap;

    /**
    * @dev Constructor
    * @param _name - token name
    * @param _symbol - token symbol
    * @param _cap - token cap - 0 value means no cap
    */
    constructor(string memory _name, string memory _symbol, uint256 _cap)
    public {
        name = _name;
        symbol = _symbol;
        cap = _cap;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        if (cap > 0)
            require(totalSupply().add(_amount) <= cap);
        _mint(_to, _amount);
        return true;
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: @daostack/arc/contracts/libs/SafeERC20.sol

/*

SafeERC20 by daostack.
The code is based on a fix by SECBIT Team.

USE WITH CAUTION & NO WARRANTY

REFERENCE & RELATED READING
- https://github.com/ethereum/solidity/issues/4116
- https://medium.com/@chris_77367/explaining-unexpected-reverts-starting-with-solidity-0-4-22-3ada6e82308c
- https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
- https://gist.github.com/BrendanChou/88a2eeb80947ff00bcf58ffdafeaeb61

*/
pragma solidity ^0.5.4;



library SafeERC20 {
    using Address for address;

    bytes4 constant private TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 constant private TRANSFERFROM_SELECTOR = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 constant private APPROVE_SELECTOR = bytes4(keccak256(bytes("approve(address,uint256)")));

    function safeTransfer(address _erc20Addr, address _to, uint256 _value) internal {

        // Must be a contract addr first!
        require(_erc20Addr.isContract());

        (bool success, bytes memory returnValue) =
        // solhint-disable-next-line avoid-low-level-calls
        _erc20Addr.call(abi.encodeWithSelector(TRANSFER_SELECTOR, _to, _value));
        // call return false when something wrong
        require(success);
        //check return value
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }

    function safeTransferFrom(address _erc20Addr, address _from, address _to, uint256 _value) internal {

        // Must be a contract addr first!
        require(_erc20Addr.isContract());

        (bool success, bytes memory returnValue) =
        // solhint-disable-next-line avoid-low-level-calls
        _erc20Addr.call(abi.encodeWithSelector(TRANSFERFROM_SELECTOR, _from, _to, _value));
        // call return false when something wrong
        require(success);
        //check return value
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }

    function safeApprove(address _erc20Addr, address _spender, uint256 _value) internal {

        // Must be a contract addr first!
        require(_erc20Addr.isContract());

        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero.
        require((_value == 0) || (IERC20(_erc20Addr).allowance(address(this), _spender) == 0));

        (bool success, bytes memory returnValue) =
        // solhint-disable-next-line avoid-low-level-calls
        _erc20Addr.call(abi.encodeWithSelector(APPROVE_SELECTOR, _spender, _value));
        // call return false when something wrong
        require(success);
        //check return value
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }
}

// File: @daostack/arc/contracts/controller/Avatar.sol

pragma solidity ^0.5.4;







/**
 * @title An Avatar holds tokens, reputation and ether for a controller
 */
contract Avatar is Ownable {
    using SafeERC20 for address;

    string public orgName;
    DAOToken public nativeToken;
    Reputation public nativeReputation;

    event GenericCall(address indexed _contract, bytes _data, uint _value, bool _success);
    event SendEther(uint256 _amountInWei, address indexed _to);
    event ExternalTokenTransfer(address indexed _externalToken, address indexed _to, uint256 _value);
    event ExternalTokenTransferFrom(address indexed _externalToken, address _from, address _to, uint256 _value);
    event ExternalTokenApproval(address indexed _externalToken, address _spender, uint256 _value);
    event ReceiveEther(address indexed _sender, uint256 _value);
    event MetaData(string _metaData);

    /**
    * @dev the constructor takes organization name, native token and reputation system
    and creates an avatar for a controller
    */
    constructor(string memory _orgName, DAOToken _nativeToken, Reputation _nativeReputation) public {
        orgName = _orgName;
        nativeToken = _nativeToken;
        nativeReputation = _nativeReputation;
    }

    /**
    * @dev enables an avatar to receive ethers
    */
    function() external payable {
        emit ReceiveEther(msg.sender, msg.value);
    }

    /**
    * @dev perform a generic call to an arbitrary contract
    * @param _contract  the contract's address to call
    * @param _data ABI-encoded contract call to call `_contract` address.
    * @param _value value (ETH) to transfer with the transaction
    * @return bool    success or fail
    *         bytes - the return bytes of the called contract's function.
    */
    function genericCall(address _contract, bytes memory _data, uint256 _value)
    public
    onlyOwner
    returns(bool success, bytes memory returnValue) {
      // solhint-disable-next-line avoid-call-value
        (success, returnValue) = _contract.call.value(_value)(_data);
        emit GenericCall(_contract, _data, _value, success);
    }

    /**
    * @dev send ethers from the avatar's wallet
    * @param _amountInWei amount to send in Wei units
    * @param _to send the ethers to this address
    * @return bool which represents success
    */
    function sendEther(uint256 _amountInWei, address payable _to) public onlyOwner returns(bool) {
        _to.transfer(_amountInWei);
        emit SendEther(_amountInWei, _to);
        return true;
    }

    /**
    * @dev external token transfer
    * @param _externalToken the token contract
    * @param _to the destination address
    * @param _value the amount of tokens to transfer
    * @return bool which represents success
    */
    function externalTokenTransfer(IERC20 _externalToken, address _to, uint256 _value)
    public onlyOwner returns(bool)
    {
        address(_externalToken).safeTransfer(_to, _value);
        emit ExternalTokenTransfer(address(_externalToken), _to, _value);
        return true;
    }

    /**
    * @dev external token transfer from a specific account
    * @param _externalToken the token contract
    * @param _from the account to spend token from
    * @param _to the destination address
    * @param _value the amount of tokens to transfer
    * @return bool which represents success
    */
    function externalTokenTransferFrom(
        IERC20 _externalToken,
        address _from,
        address _to,
        uint256 _value
    )
    public onlyOwner returns(bool)
    {
        address(_externalToken).safeTransferFrom(_from, _to, _value);
        emit ExternalTokenTransferFrom(address(_externalToken), _from, _to, _value);
        return true;
    }

    /**
    * @dev externalTokenApproval approve the spender address to spend a specified amount of tokens
    *      on behalf of msg.sender.
    * @param _externalToken the address of the Token Contract
    * @param _spender address
    * @param _value the amount of ether (in Wei) which the approval is referring to.
    * @return bool which represents a success
    */
    function externalTokenApproval(IERC20 _externalToken, address _spender, uint256 _value)
    public onlyOwner returns(bool)
    {
        address(_externalToken).safeApprove(_spender, _value);
        emit ExternalTokenApproval(address(_externalToken), _spender, _value);
        return true;
    }

    /**
    * @dev metaData emits an event with a string, should contain the hash of some meta data.
    * @param _metaData a string representing a hash of the meta data
    * @return bool which represents a success
    */
    function metaData(string memory _metaData) public onlyOwner returns(bool) {
        emit MetaData(_metaData);
        return true;
    }


}

// File: @daostack/arc/contracts/globalConstraints/GlobalConstraintInterface.sol

pragma solidity ^0.5.4;


contract GlobalConstraintInterface {

    enum CallPhase { Pre, Post, PreAndPost }

    function pre( address _scheme, bytes32 _params, bytes32 _method ) public returns(bool);
    function post( address _scheme, bytes32 _params, bytes32 _method ) public returns(bool);
    /**
     * @dev when return if this globalConstraints is pre, post or both.
     * @return CallPhase enum indication  Pre, Post or PreAndPost.
     */
    function when() public returns(CallPhase);
}

// File: @daostack/arc/contracts/controller/ControllerInterface.sol

pragma solidity ^0.5.4;



/**
 * @title Controller contract
 * @dev A controller controls the organizations tokens ,reputation and avatar.
 * It is subject to a set of schemes and constraints that determine its behavior.
 * Each scheme has it own parameters and operation permissions.
 */
interface ControllerInterface {

    /**
     * @dev Mint `_amount` of reputation that are assigned to `_to` .
     * @param  _amount amount of reputation to mint
     * @param _to beneficiary address
     * @return bool which represents a success
    */
    function mintReputation(uint256 _amount, address _to, address _avatar)
    external
    returns(bool);

    /**
     * @dev Burns `_amount` of reputation from `_from`
     * @param _amount amount of reputation to burn
     * @param _from The address that will lose the reputation
     * @return bool which represents a success
     */
    function burnReputation(uint256 _amount, address _from, address _avatar)
    external
    returns(bool);

    /**
     * @dev mint tokens .
     * @param  _amount amount of token to mint
     * @param _beneficiary beneficiary address
     * @param _avatar address
     * @return bool which represents a success
     */
    function mintTokens(uint256 _amount, address _beneficiary, address _avatar)
    external
    returns(bool);

  /**
   * @dev register or update a scheme
   * @param _scheme the address of the scheme
   * @param _paramsHash a hashed configuration of the usage of the scheme
   * @param _permissions the permissions the new scheme will have
   * @param _avatar address
   * @return bool which represents a success
   */
    function registerScheme(address _scheme, bytes32 _paramsHash, bytes4 _permissions, address _avatar)
    external
    returns(bool);

    /**
     * @dev unregister a scheme
     * @param _avatar address
     * @param _scheme the address of the scheme
     * @return bool which represents a success
     */
    function unregisterScheme(address _scheme, address _avatar)
    external
    returns(bool);

    /**
     * @dev unregister the caller's scheme
     * @param _avatar address
     * @return bool which represents a success
     */
    function unregisterSelf(address _avatar) external returns(bool);

    /**
     * @dev add or update Global Constraint
     * @param _globalConstraint the address of the global constraint to be added.
     * @param _params the constraint parameters hash.
     * @param _avatar the avatar of the organization
     * @return bool which represents a success
     */
    function addGlobalConstraint(address _globalConstraint, bytes32 _params, address _avatar)
    external returns(bool);

    /**
     * @dev remove Global Constraint
     * @param _globalConstraint the address of the global constraint to be remove.
     * @param _avatar the organization avatar.
     * @return bool which represents a success
     */
    function removeGlobalConstraint (address _globalConstraint, address _avatar)
    external  returns(bool);

  /**
    * @dev upgrade the Controller
    *      The function will trigger an event 'UpgradeController'.
    * @param  _newController the address of the new controller.
    * @param _avatar address
    * @return bool which represents a success
    */
    function upgradeController(address _newController, Avatar _avatar)
    external returns(bool);

    /**
    * @dev perform a generic call to an arbitrary contract
    * @param _contract  the contract's address to call
    * @param _data ABI-encoded contract call to call `_contract` address.
    * @param _avatar the controller's avatar address
    * @param _value value (ETH) to transfer with the transaction
    * @return bool -success
    *         bytes  - the return value of the called _contract's function.
    */
    function genericCall(address _contract, bytes calldata _data, Avatar _avatar, uint256 _value)
    external
    returns(bool, bytes memory);

  /**
   * @dev send some ether
   * @param _amountInWei the amount of ether (in Wei) to send
   * @param _to address of the beneficiary
   * @param _avatar address
   * @return bool which represents a success
   */
    function sendEther(uint256 _amountInWei, address payable _to, Avatar _avatar)
    external returns(bool);

    /**
    * @dev send some amount of arbitrary ERC20 Tokens
    * @param _externalToken the address of the Token Contract
    * @param _to address of the beneficiary
    * @param _value the amount of ether (in Wei) to send
    * @param _avatar address
    * @return bool which represents a success
    */
    function externalTokenTransfer(IERC20 _externalToken, address _to, uint256 _value, Avatar _avatar)
    external
    returns(bool);

    /**
    * @dev transfer token "from" address "to" address
    *      One must to approve the amount of tokens which can be spend from the
    *      "from" account.This can be done using externalTokenApprove.
    * @param _externalToken the address of the Token Contract
    * @param _from address of the account to send from
    * @param _to address of the beneficiary
    * @param _value the amount of ether (in Wei) to send
    * @param _avatar address
    * @return bool which represents a success
    */
    function externalTokenTransferFrom(
    IERC20 _externalToken,
    address _from,
    address _to,
    uint256 _value,
    Avatar _avatar)
    external
    returns(bool);

    /**
    * @dev externalTokenApproval approve the spender address to spend a specified amount of tokens
    *      on behalf of msg.sender.
    * @param _externalToken the address of the Token Contract
    * @param _spender address
    * @param _value the amount of ether (in Wei) which the approval is referring to.
    * @return bool which represents a success
    */
    function externalTokenApproval(IERC20 _externalToken, address _spender, uint256 _value, Avatar _avatar)
    external
    returns(bool);

    /**
    * @dev metaData emits an event with a string, should contain the hash of some meta data.
    * @param _metaData a string representing a hash of the meta data
    * @param _avatar Avatar
    * @return bool which represents a success
    */
    function metaData(string calldata _metaData, Avatar _avatar) external returns(bool);

    /**
     * @dev getNativeReputation
     * @param _avatar the organization avatar.
     * @return organization native reputation
     */
    function getNativeReputation(address _avatar)
    external
    view
    returns(address);

    function isSchemeRegistered( address _scheme, address _avatar) external view returns(bool);

    function getSchemeParameters(address _scheme, address _avatar) external view returns(bytes32);

    function getGlobalConstraintParameters(address _globalConstraint, address _avatar) external view returns(bytes32);

    function getSchemePermissions(address _scheme, address _avatar) external view returns(bytes4);

    /**
     * @dev globalConstraintsCount return the global constraint pre and post count
     * @return uint256 globalConstraintsPre count.
     * @return uint256 globalConstraintsPost count.
     */
    function globalConstraintsCount(address _avatar) external view returns(uint, uint);

    function isGlobalConstraintRegistered(address _globalConstraint, address _avatar) external view returns(bool);
}

// File: contracts/dao/schemes/SchemeGuard.sol

pragma solidity >0.5.4;




/* @dev abstract contract for ensuring that schemes have been registered properly
 * Allows setting zero Avatar in situations where the Avatar hasn't been created yet
 */
contract SchemeGuard is Ownable {
    Avatar avatar;
    ControllerInterface internal controller = ControllerInterface(0);

    /** @dev Constructor. only sets controller if given avatar is not null.
     * @param _avatar The avatar of the DAO.
     */
    constructor(Avatar _avatar) public {
        avatar = _avatar;

        if (avatar != Avatar(0)) {
            controller = ControllerInterface(avatar.owner());
        }
    }

    /** @dev modifier to check if caller is avatar
     */
    modifier onlyAvatar() {
        require(address(avatar) == msg.sender, "only Avatar can call this method");
        _;
    }

    /** @dev modifier to check if scheme is registered
     */
    modifier onlyRegistered() {
        require(isRegistered(), "Scheme is not registered");
        _;
    }

    /** @dev modifier to check if scheme is not registered
     */
    modifier onlyNotRegistered() {
        require(!isRegistered(), "Scheme is registered");
        _;
    }

    /** @dev modifier to check if call is a scheme that is registered
     */
    modifier onlyRegisteredCaller() {
        require(isRegistered(msg.sender), "Calling scheme is not registered");
        _;
    }

    /** @dev Function to set a new avatar and controller for scheme
     * can only be done by owner of scheme
     */
    function setAvatar(Avatar _avatar) public onlyOwner {
        avatar = _avatar;
        controller = ControllerInterface(avatar.owner());
    }

    /** @dev function to see if an avatar has been set and if this scheme is registered
     * @return true if scheme is registered
     */
    function isRegistered() public view returns (bool) {
        return isRegistered(address(this));
    }

    /** @dev function to see if an avatar has been set and if this scheme is registered
     * @return true if scheme is registered
     */
    function isRegistered(address scheme) public view returns (bool) {
        require(avatar != Avatar(0), "Avatar is not set");

        if (!(controller.isSchemeRegistered(scheme, address(avatar)))) {
            return false;
        }
        return true;
    }
}

// File: contracts/identity/IdentityAdminRole.sol

pragma solidity >0.5.4;



/**
 * @title Contract managing the identity admin role
 */
contract IdentityAdminRole is Ownable {
    using Roles for Roles.Role;

    event IdentityAdminAdded(address indexed account);
    event IdentityAdminRemoved(address indexed account);

    Roles.Role private IdentityAdmins;

    /* @dev constructor. Adds caller as an admin
     */
    constructor() internal {
        _addIdentityAdmin(msg.sender);
    }

    /* @dev Modifier to check if caller is an admin
     */
    modifier onlyIdentityAdmin() {
        require(isIdentityAdmin(msg.sender), "not IdentityAdmin");
        _;
    }

    /**
     * @dev Checks if account is identity admin
     * @param account Account to check
     * @return Boolean indicating if account is identity admin
     */
    function isIdentityAdmin(address account) public view returns (bool) {
        return IdentityAdmins.has(account);
    }

    /**
     * @dev Adds a identity admin account. Is only callable by owner.
     * @param account Address to be added
     * @return true if successful
     */
    function addIdentityAdmin(address account) public onlyOwner returns (bool) {
        _addIdentityAdmin(account);
        return true;
    }

    /**
     * @dev Removes a identity admin account. Is only callable by owner.
     * @param account Address to be removed
     * @return true if successful
     */
    function removeIdentityAdmin(address account) public onlyOwner returns (bool) {
        _removeIdentityAdmin(account);
        return true;
    }

    /**
     * @dev Allows an admin to renounce their role
     */
    function renounceIdentityAdmin() public {
        _removeIdentityAdmin(msg.sender);
    }

    /**
     * @dev Internal implementation of addIdentityAdmin
     */
    function _addIdentityAdmin(address account) internal {
        IdentityAdmins.add(account);
        emit IdentityAdminAdded(account);
    }

    /**
     * @dev Internal implementation of removeIdentityAdmin
     */
    function _removeIdentityAdmin(address account) internal {
        IdentityAdmins.remove(account);
        emit IdentityAdminRemoved(account);
    }
}

// File: contracts/identity/Identity.sol

pragma solidity >0.5.4;







/* @title Identity contract responsible for whitelisting
 * and keeping track of amount of whitelisted users
 */
contract Identity is IdentityAdminRole, SchemeGuard, Pausable {
    using Roles for Roles.Role;
    using SafeMath for uint256;

    Roles.Role private blacklist;
    Roles.Role private whitelist;
    Roles.Role private contracts;

    uint256 public whitelistedCount = 0;
    uint256 public whitelistedContracts = 0;
    uint256 public authenticationPeriod = 14;

    mapping(address => uint256) public dateAuthenticated;
    mapping(address => uint256) public dateAdded;

    mapping(address => string) public addrToDID;
    mapping(bytes32 => address) public didHashToAddress;

    event BlacklistAdded(address indexed account);
    event BlacklistRemoved(address indexed account);

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    event ContractAdded(address indexed account);
    event ContractRemoved(address indexed account);

    constructor() public SchemeGuard(Avatar(0)) {}

    /* @dev Sets a new value for authenticationPeriod.
     * Can only be called by Identity Administrators.
     * @param period new value for authenticationPeriod
     */
    function setAuthenticationPeriod(uint256 period) public onlyOwner whenNotPaused {
        authenticationPeriod = period;
    }

    /* @dev Sets the authentication date of `account`
     * to the current time.
     * Can only be called by Identity Administrators.
     * @param account address to change its auth date
     */
    function authenticate(address account)
        public
        onlyRegistered
        onlyIdentityAdmin
        whenNotPaused
    {
        dateAuthenticated[account] = now;
    }

    /* @dev Adds an address as whitelisted.
     * Can only be called by Identity Administrators.
     * @param account address to add as whitelisted
     */
    function addWhitelisted(address account)
        public
        onlyRegistered
        onlyIdentityAdmin
        whenNotPaused
    {
        _addWhitelisted(account);
    }

    /* @dev Adds an address as whitelisted under a specific ID
     * @param account The address to add
     * @param did the ID to add account under
     */
    function addWhitelistedWithDID(address account, string memory did)
        public
        onlyRegistered
        onlyIdentityAdmin
        whenNotPaused
    {
        _addWhitelistedWithDID(account, did);
    }

    /* @dev Removes an address as whitelisted.
     * Can only be called by Identity Administrators.
     * @param account address to remove as whitelisted
     */
    function removeWhitelisted(address account)
        public
        onlyRegistered
        onlyIdentityAdmin
        whenNotPaused
    {
        _removeWhitelisted(account);
    }

    /* @dev Renounces message sender from whitelisted
     */
    function renounceWhitelisted() public whenNotPaused {
        _removeWhitelisted(msg.sender);
    }

    /* @dev Returns true if given address has been added to whitelist
     * @param account the address to check
     * @return a bool indicating weather the address is present in whitelist
     */
    function isWhitelisted(address account) public view returns (bool) {
        uint256 daysSinceAuthentication = (now.sub(dateAuthenticated[account])) / 1 days;
        return
            (daysSinceAuthentication <= authenticationPeriod) && whitelist.has(account);
    }

    /* @dev Function that gives the date the given user was added
     * @param account The address to check
     * @return The date the address was added
     */
    function lastAuthenticated(address account) public view returns (uint256) {
        return dateAuthenticated[account];
    }

    // /**
    //  *
    //  * @dev Function to transfer whitelisted privilege to another address
    //  * relocates did of sender to give address
    //  * @param account The address to transfer to
    //  */
    // function transferAccount(address account) public whenNotPaused {
    //     ERC20 token = avatar.nativeToken();
    //     require(!isBlacklisted(account), "Cannot transfer to blacklisted");
    //     require(token.balanceOf(account) == 0, "Account is already in use");
    //     require(isWhitelisted(msg.sender), "Requester need to be whitelisted");

    //     require(
    //         keccak256(bytes(addrToDID[account])) == keccak256(bytes("")),
    //         "address already has DID"
    //     );

    //     string memory did = addrToDID[msg.sender];
    //     bytes32 pHash = keccak256(bytes(did));

    //     uint256 balance = token.balanceOf(msg.sender);
    //     token.transferFrom(msg.sender, account, balance);
    //     _removeWhitelisted(msg.sender);
    //     _addWhitelisted(account);
    //     addrToDID[account] = did;
    //     didHashToAddress[pHash] = account;
    // }

    /* @dev Adds an address to blacklist.
     * Can only be called by Identity Administrators.
     * @param account address to add as blacklisted
     */
    function addBlacklisted(address account)
        public
        onlyRegistered
        onlyIdentityAdmin
        whenNotPaused
    {
        blacklist.add(account);
        emit BlacklistAdded(account);
    }

    /* @dev Removes an address from blacklist
     * Can only be called by Identity Administrators.
     * @param account address to remove as blacklisted
     */
    function removeBlacklisted(address account)
        public
        onlyRegistered
        onlyIdentityAdmin
        whenNotPaused
    {
        blacklist.remove(account);
        emit BlacklistRemoved(account);
    }

    /* @dev Function to add a Contract to list of contracts
     * @param account The address to add
     */
    function addContract(address account)
        public
        onlyRegistered
        onlyIdentityAdmin
        whenNotPaused
    {
        require(isContract(account), "Given address is not a contract");
        contracts.add(account);
        _addWhitelisted(account);

        emit ContractAdded(account);
    }

    /* @dev Function to remove a Contract from list of contracts
     * @param account The address to add
     */
    function removeContract(address account)
        public
        onlyRegistered
        onlyIdentityAdmin
        whenNotPaused
    {
        contracts.remove(account);
        _removeWhitelisted(account);

        emit ContractRemoved(account);
    }

    /* @dev Function to check if given contract is on list of contracts.
     * @param address to check
     * @return a bool indicating if address is on list of contracts
     */
    function isDAOContract(address account) public view returns (bool) {
        return contracts.has(account);
    }

    /* @dev Internal function to add to whitelisted
     * @param account the address to add
     */
    function _addWhitelisted(address account) internal {
        whitelist.add(account);

        whitelistedCount += 1;
        dateAdded[account] = now;
        dateAuthenticated[account] = now;

        if (isContract(account)) {
            whitelistedContracts += 1;
        }

        emit WhitelistedAdded(account);
    }

    /* @dev Internal whitelisting with did function.
     * @param account the address to add
     * @param did the id to register account under
     */
    function _addWhitelistedWithDID(address account, string memory did) internal {
        bytes32 pHash = keccak256(bytes(did));
        require(didHashToAddress[pHash] == address(0), "DID already registered");

        addrToDID[account] = did;
        didHashToAddress[pHash] = account;

        _addWhitelisted(account);
    }

    /* @dev Internal function to remove from whitelisted
     * @param account the address to add
     */
    function _removeWhitelisted(address account) internal {
        whitelist.remove(account);

        whitelistedCount -= 1;
        delete dateAuthenticated[account];

        if (isContract(account)) {
            whitelistedContracts -= 1;
        }

        string memory did = addrToDID[account];
        bytes32 pHash = keccak256(bytes(did));

        delete dateAuthenticated[account];
        delete addrToDID[account];
        delete didHashToAddress[pHash];

        emit WhitelistedRemoved(account);
    }

    /* @dev Returns true if given address has been added to the blacklist
     * @param account the address to check
     * @return a bool indicating weather the address is present in the blacklist
     */
    function isBlacklisted(address account) public view returns (bool) {
        return blacklist.has(account);
    }

    /* @dev Function to see if given address is a contract
     * @return true if address is a contract
     */
    function isContract(address _addr) internal view returns (bool) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
        return length > 0;
    }
}

// File: contracts/identity/IdentityGuard.sol

pragma solidity >0.5.4;



/* @title The IdentityGuard contract
 * @dev Contract containing an identity and
 * modifiers to ensure proper access
 */
contract IdentityGuard is Ownable {
    Identity public identity;

    /* @dev Constructor. Checks if identity is a zero address
     * @param _identity The identity contract.
     */
    constructor(Identity _identity) public {
        require(_identity != Identity(0), "Supplied identity is null");
        identity = _identity;
    }

    /* @dev Modifier that requires the sender to be not blacklisted
     */
    modifier onlyNotBlacklisted() {
        require(!identity.isBlacklisted(msg.sender), "Caller is blacklisted");
        _;
    }

    /* @dev Modifier that requires the given address to be not blacklisted
     * @param _account The address to be checked
     */
    modifier requireNotBlacklisted(address _account) {
        require(!identity.isBlacklisted(_account), "Receiver is blacklisted");
        _;
    }

    /* @dev Modifier that requires the sender to be whitelisted
     */
    modifier onlyWhitelisted() {
        require(identity.isWhitelisted(msg.sender), "is not whitelisted");
        _;
    }

    /* @dev Modifier that requires the given address to be whitelisted
     * @param _account the given address
     */
    modifier requireWhitelisted(address _account) {
        require(identity.isWhitelisted(_account), "is not whitelisted");
        _;
    }

    /* @dev Modifier that requires the sender to be an approved DAO contract
     */
    modifier onlyDAOContract() {
        require(identity.isDAOContract(msg.sender), "is not whitelisted contract");
        _;
    }

    /* @dev Modifier that requires the given address to be whitelisted
     * @param _account the given address
     */
    modifier requireDAOContract(address _contract) {
        require(identity.isDAOContract(_contract), "is not whitelisted contract");
        _;
    }

    /* @dev Modifier that requires the sender to have been whitelisted
     * before or on the given date
     * @param date The time sender must have been added before
     */
    modifier onlyAddedBefore(uint256 date) {
        require(
            identity.lastAuthenticated(msg.sender) <= date,
            "Was not added within period"
        );
        _;
    }

    /* @dev Modifier that requires sender to be an identity admin
     */
    modifier onlyIdentityAdmin() {
        require(identity.isIdentityAdmin(msg.sender), "not IdentityAdmin");
        _;
    }

    /* @dev Allows owner to set a new identity contract if
     * the given identity contract has been registered as a scheme
     */
    function setIdentity(Identity _identity) public onlyOwner {
        require(_identity.isRegistered(), "Identity is not registered");
        identity = _identity;
    }
}

// File: contracts/dao/schemes/FeeFormula.sol

pragma solidity >0.5.4;




/**
 * @title Fee formula abstract contract
 */
contract AbstractFees is SchemeGuard {
    constructor() public SchemeGuard(Avatar(0)) {}

    function getTxFees(
        uint256 _value,
        address _sender,
        address _recipient
    ) public view returns (uint256, bool);
}

/**
 * @title Fee formula contract
 * contract that provides a function to calculate
 * fees as a percentage of any given value
 */
contract FeeFormula is AbstractFees {
    using SafeMath for uint256;

    uint256 public percentage;
    bool public constant senderPays = false;

    /**
     * @dev Constructor. Requires the given percentage parameter
     * to be less than 100.
     * @param _percentage the percentage to calculate fees of
     */
    constructor(uint256 _percentage) public {
        require(_percentage < 100, "Percentage should be <100");
        percentage = _percentage;
    }

    /**  @dev calculates the fee of given value.
     * @param _value the value of the transaction to calculate fees from
     * @param _sender address sending.
     *  @param _recipient address receiving.
     * @return the transactional fee for given value
     */
    function getTxFees(
        uint256 _value,
        address _sender,
        address _recipient
    ) public view returns (uint256, bool) {
        return (_value.mul(percentage).div(100), senderPays);
    }
}

// File: contracts/dao/schemes/FormulaHolder.sol

pragma solidity >0.5.4;



/* @title Contract in charge of setting registered fee formula schemes to contract
 */
contract FormulaHolder is Ownable {
    AbstractFees public formula;

    /* @dev Constructor. Requires that given formula is a valid contract.
     * @param _formula The fee formula contract.
     */
    constructor(AbstractFees _formula) public {
        require(_formula != AbstractFees(0), "Supplied formula is null");
        formula = _formula;
    }

    /* @dev Sets the given fee formula contract. Is only callable by owner.
     * Reverts if formula has not been registered by DAO.
     * @param _formula the new fee formula scheme
     */
    function setFormula(AbstractFees _formula) public onlyOwner {
        _formula.isRegistered();
        formula = _formula;
    }
}

// File: contracts/token/ERC677/ERC677.sol

pragma solidity >0.5.4;

/* @title ERC677 interface
 */
interface ERC677 {
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    function transferAndCall(
        address,
        uint256,
        bytes calldata
    ) external returns (bool);
}

// File: contracts/token/ERC677/ERC677Receiver.sol

pragma solidity >0.5.4;

/* @title ERC677Receiver interface
 */
interface ERC677Receiver {
    function onTokenTransfer(
        address _from,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Pausable.sol

pragma solidity ^0.5.0;



/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers.
 **/
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

// File: contracts/token/ERC677Token.sol

pragma solidity >0.5.4;





/* @title ERC677Token contract.
 */
contract ERC677Token is ERC677, DAOToken, ERC20Pausable {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cap
    ) public DAOToken(_name, _symbol, _cap) {}

    /**
     * @dev transfer token to a contract address with additional data if the recipient is a contact.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @param _data The extra data to be passed to the receiving contract.
     * @return true if transfer is successful
     */
    function _transferAndCall(
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal whenNotPaused returns (bool) {
        bool res = super.transfer(_to, _value);
        emit Transfer(msg.sender, _to, _value, _data);

        if (isContract(_to)) {
            require(contractFallback(_to, _value, _data), "Contract fallback failed");
        }
        return res;
    }

    /* @dev Contract fallback function. Is called if transferAndCall is called
     * to a contract
     */
    function contractFallback(
        address _to,
        uint256 _value,
        bytes memory _data
    ) private returns (bool) {
        ERC677Receiver receiver = ERC677Receiver(_to);
        require(
            receiver.onTokenTransfer(msg.sender, _value, _data),
            "Contract Fallback failed"
        );
        return true;
    }

    /* @dev Function to check if given address is a contract
     * @param _addr Address to check
     * @return true if given address is a contract
     */

    function isContract(address _addr) internal view returns (bool) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
        return length > 0;
    }
}

// File: openzeppelin-solidity/contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.0;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// File: contracts/token/ERC677BridgeToken.sol

pragma solidity >0.5.4;



contract ERC677BridgeToken is ERC677Token, MinterRole {
    address public bridgeContract;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cap
    ) public ERC677Token(_name, _symbol, _cap) {}

    function setBridgeContract(address _bridgeContract) public onlyMinter {
        require(
            _bridgeContract != address(0) && isContract(_bridgeContract),
            "Invalid bridge contract"
        );
        bridgeContract = _bridgeContract;
    }
}

// File: contracts/token/GoodDollar.sol

pragma solidity >0.5.4;




/**
 * @title The GoodDollar ERC677 token contract
 */
contract GoodDollar is ERC677BridgeToken, IdentityGuard, FormulaHolder {
    address feeRecipient;

    // Overrides hard-coded decimal in DAOToken
    uint256 public constant decimals = 2;

    /**
     * @dev constructor
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     * @param _cap the cap of the token. no cap if 0
     * @param _formula the fee formula contract
     * @param _identity the identity contract
     * @param _feeRecipient the address that receives transaction fees
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cap,
        AbstractFees _formula,
        Identity _identity,
        address _feeRecipient
    )
        public
        ERC677BridgeToken(_name, _symbol, _cap)
        IdentityGuard(_identity)
        FormulaHolder(_formula)
    {
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Processes fees from given value and sends
     * remainder to given address
     * @param to the address to be sent to
     * @param value the value to be processed and then
     * transferred
     * @return a boolean that indicates if the operation was successful
     */
    function transfer(address to, uint256 value) public returns (bool) {
        uint256 bruttoValue = processFees(msg.sender, to, value);
        return super.transfer(to, bruttoValue);
    }

    /**
     * @dev Approve the passed address to spend the specified
     * amount of tokens on behalf of msg.sender
     * @param spender The address which will spend the funds
     * @param value The amount of tokens to be spent
     * @return a boolean that indicates if the operation was successful
     */
    function approve(address spender, uint256 value) public returns (bool) {
        return super.approve(spender, value);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from The address which you want to send tokens from
     * @param to The address which you want to transfer to
     * @param value the amount of tokens to be transferred
     * @return a boolean that indicates if the operation was successful
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        uint256 bruttoValue = processFees(from, to, value);
        return super.transferFrom(from, to, bruttoValue);
    }

    /**
     * @dev Processes transfer fees and calls ERC677Token transferAndCall function
     * @param to address to transfer to
     * @param value the amount to transfer
     * @param data The data to pass to transferAndCall
     * @return a bool indicating if transfer function succeeded
     */
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool) {
        uint256 bruttoValue = processFees(msg.sender, to, value);
        return super._transferAndCall(to, bruttoValue, data);
    }

    /**
     * @dev Minting function
     * @param to the address that will receive the minted tokens
     * @param value the amount of tokens to mint
     * @return a boolean that indicated if the operation was successful
     */
    function mint(address to, uint256 value)
        public
        onlyMinter
        requireNotBlacklisted(to)
        returns (bool)
    {
        if (cap > 0) {
            require(totalSupply().add(value) <= cap, "Cannot increase supply beyond cap");
        }
        super._mint(to, value);
        return true;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public onlyNotBlacklisted {
        super.burn(value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The address which you want to send tokens from
     * @param value uint256 The amount of token to be burned
     */
    function burnFrom(address from, uint256 value)
        public
        onlyNotBlacklisted
        requireNotBlacklisted(from)
    {
        super.burnFrom(from, value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allows a spender
     * @param spender The address which will spend the funds
     * @param addedValue The amount of tokens to increase the allowance by
     * @return a boolean that indicated if the operation was successful
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender
     * @param spender The address which will spend the funds
     * @param subtractedValue The amount of tokens to decrease the allowance by
     * @return a boolean that indicated if the operation was successful
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
     * @dev Gets the current transaction fees
     * @return an uint256 that represents
     * the current transaction fees
     */
    function getFees(uint256 value) public view returns (uint256, bool) {
        return formula.getTxFees(value, address(0), address(0));
    }

    /**
     * @dev Gets the current transaction fees
     * @return an uint256 that represents
     * the current transaction fees
     */
    function getFees(
        uint256 value,
        address sender,
        address recipient
    ) public view returns (uint256, bool) {
        return formula.getTxFees(value, sender, recipient);
    }

    /**
     * @dev Sets the address that receives the transactional fees.
     * can only be called by owner
     * @param _feeRecipient The new address to receive transactional fees
     */
    function setFeeRecipient(address _feeRecipient) public onlyOwner {
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Sends transactional fees to feeRecipient address from given address
     * @param account The account that sends the fees
     * @param value The amount to subtract fees from
     * @return an uint256 that represents the given value minus the transactional fees
     */
    function processFees(
        address account,
        address recipient,
        uint256 value
    ) internal returns (uint256) {
        (uint256 txFees, bool senderPays) = getFees(value, account, recipient);
        if (txFees > 0 && !identity.isDAOContract(msg.sender)) {
            require(
                senderPays == false || value.add(txFees) <= balanceOf(account),
                "Not enough balance to pay TX fee"
            );
            if (account == msg.sender) {
                super.transfer(feeRecipient, txFees);
            } else {
                super.transferFrom(account, feeRecipient, txFees);
            }

            return senderPays ? value : value.sub(txFees);
        }
        return value;
    }
}