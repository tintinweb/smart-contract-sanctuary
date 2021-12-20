/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

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

// File: ../contracts/dao/schemes/SchemeGuard.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


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
}

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

// File: ../contracts/identity/IdentityAdminRole.sol

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

// File: ../contracts/identity/Identity.sol

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

// File: ../contracts/identity/IdentityGuard.sol

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

// File: ../contracts/dao/schemes/FeeFormula.sol

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

// File: ../contracts/dao/schemes/FormulaHolder.sol

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

// File: ../contracts/token/ERC677/ERC677.sol

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

// File: ../contracts/token/ERC677/ERC677Receiver.sol

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

// File: ../contracts/token/ERC677Token.sol

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

// File: ../contracts/token/ERC677BridgeToken.sol

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

// File: ../contracts/token/GoodDollar.sol

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

// File: ../contracts/DSMath.sol

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }
    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// File: contracts/BancorFormula.sol

pragma solidity >0.5.4;


contract BancorFormula {
    using SafeMath for uint256;

    uint16 public version = 6;

    uint256 private constant ONE = 1;
    uint32 private constant MAX_RATIO = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    /**
     * Auto-generated via 'PrintIntScalingFactors.py'
     */
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

    /**
     * Auto-generated via 'PrintLn2ScalingFactors.py'
     */
    uint256 private constant LN2_NUMERATOR = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    /**
     * Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
     */
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

    /**
     * Auto-generated via 'PrintFunctionConstructor.py'
     */
    uint256[128] private maxExpArray;

    constructor() public {
        //  maxExpArray[  0] = 0x6bffffffffffffffffffffffffffffffff;
        //  maxExpArray[  1] = 0x67ffffffffffffffffffffffffffffffff;
        //  maxExpArray[  2] = 0x637fffffffffffffffffffffffffffffff;
        //  maxExpArray[  3] = 0x5f6fffffffffffffffffffffffffffffff;
        //  maxExpArray[  4] = 0x5b77ffffffffffffffffffffffffffffff;
        //  maxExpArray[  5] = 0x57b3ffffffffffffffffffffffffffffff;
        //  maxExpArray[  6] = 0x5419ffffffffffffffffffffffffffffff;
        //  maxExpArray[  7] = 0x50a2ffffffffffffffffffffffffffffff;
        //  maxExpArray[  8] = 0x4d517fffffffffffffffffffffffffffff;
        //  maxExpArray[  9] = 0x4a233fffffffffffffffffffffffffffff;
        //  maxExpArray[ 10] = 0x47165fffffffffffffffffffffffffffff;
        //  maxExpArray[ 11] = 0x4429afffffffffffffffffffffffffffff;
        //  maxExpArray[ 12] = 0x415bc7ffffffffffffffffffffffffffff;
        //  maxExpArray[ 13] = 0x3eab73ffffffffffffffffffffffffffff;
        //  maxExpArray[ 14] = 0x3c1771ffffffffffffffffffffffffffff;
        //  maxExpArray[ 15] = 0x399e96ffffffffffffffffffffffffffff;
        //  maxExpArray[ 16] = 0x373fc47fffffffffffffffffffffffffff;
        //  maxExpArray[ 17] = 0x34f9e8ffffffffffffffffffffffffffff;
        //  maxExpArray[ 18] = 0x32cbfd5fffffffffffffffffffffffffff;
        //  maxExpArray[ 19] = 0x30b5057fffffffffffffffffffffffffff;
        //  maxExpArray[ 20] = 0x2eb40f9fffffffffffffffffffffffffff;
        //  maxExpArray[ 21] = 0x2cc8340fffffffffffffffffffffffffff;
        //  maxExpArray[ 22] = 0x2af09481ffffffffffffffffffffffffff;
        //  maxExpArray[ 23] = 0x292c5bddffffffffffffffffffffffffff;
        //  maxExpArray[ 24] = 0x277abdcdffffffffffffffffffffffffff;
        //  maxExpArray[ 25] = 0x25daf6657fffffffffffffffffffffffff;
        //  maxExpArray[ 26] = 0x244c49c65fffffffffffffffffffffffff;
        //  maxExpArray[ 27] = 0x22ce03cd5fffffffffffffffffffffffff;
        //  maxExpArray[ 28] = 0x215f77c047ffffffffffffffffffffffff;
        //  maxExpArray[ 29] = 0x1fffffffffffffffffffffffffffffffff;
        //  maxExpArray[ 30] = 0x1eaefdbdabffffffffffffffffffffffff;
        //  maxExpArray[ 31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
        maxExpArray[32] = 0x1c35fedd14ffffffffffffffffffffffff;
        maxExpArray[33] = 0x1b0ce43b323fffffffffffffffffffffff;
        maxExpArray[34] = 0x19f0028ec1ffffffffffffffffffffffff;
        maxExpArray[35] = 0x18ded91f0e7fffffffffffffffffffffff;
        maxExpArray[36] = 0x17d8ec7f0417ffffffffffffffffffffff;
        maxExpArray[37] = 0x16ddc6556cdbffffffffffffffffffffff;
        maxExpArray[38] = 0x15ecf52776a1ffffffffffffffffffffff;
        maxExpArray[39] = 0x15060c256cb2ffffffffffffffffffffff;
        maxExpArray[40] = 0x1428a2f98d72ffffffffffffffffffffff;
        maxExpArray[41] = 0x13545598e5c23fffffffffffffffffffff;
        maxExpArray[42] = 0x1288c4161ce1dfffffffffffffffffffff;
        maxExpArray[43] = 0x11c592761c666fffffffffffffffffffff;
        maxExpArray[44] = 0x110a688680a757ffffffffffffffffffff;
        maxExpArray[45] = 0x1056f1b5bedf77ffffffffffffffffffff;
        maxExpArray[46] = 0x0faadceceeff8bffffffffffffffffffff;
        maxExpArray[47] = 0x0f05dc6b27edadffffffffffffffffffff;
        maxExpArray[48] = 0x0e67a5a25da4107fffffffffffffffffff;
        maxExpArray[49] = 0x0dcff115b14eedffffffffffffffffffff;
        maxExpArray[50] = 0x0d3e7a392431239fffffffffffffffffff;
        maxExpArray[51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
        maxExpArray[52] = 0x0c2d415c3db974afffffffffffffffffff;
        maxExpArray[53] = 0x0bad03e7d883f69bffffffffffffffffff;
        maxExpArray[54] = 0x0b320d03b2c343d5ffffffffffffffffff;
        maxExpArray[55] = 0x0abc25204e02828dffffffffffffffffff;
        maxExpArray[56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
        maxExpArray[57] = 0x09deaf736ac1f569ffffffffffffffffff;
        maxExpArray[58] = 0x0976bd9952c7aa957fffffffffffffffff;
        maxExpArray[59] = 0x09131271922eaa606fffffffffffffffff;
        maxExpArray[60] = 0x08b380f3558668c46fffffffffffffffff;
        maxExpArray[61] = 0x0857ddf0117efa215bffffffffffffffff;
        maxExpArray[62] = 0x07ffffffffffffffffffffffffffffffff;
        maxExpArray[63] = 0x07abbf6f6abb9d087fffffffffffffffff;
        maxExpArray[64] = 0x075af62cbac95f7dfa7fffffffffffffff;
        maxExpArray[65] = 0x070d7fb7452e187ac13fffffffffffffff;
        maxExpArray[66] = 0x06c3390ecc8af379295fffffffffffffff;
        maxExpArray[67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
        maxExpArray[68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
        maxExpArray[69] = 0x05f63b1fc104dbd39587ffffffffffffff;
        maxExpArray[70] = 0x05b771955b36e12f7235ffffffffffffff;
        maxExpArray[71] = 0x057b3d49dda84556d6f6ffffffffffffff;
        maxExpArray[72] = 0x054183095b2c8ececf30ffffffffffffff;
        maxExpArray[73] = 0x050a28be635ca2b888f77fffffffffffff;
        maxExpArray[74] = 0x04d5156639708c9db33c3fffffffffffff;
        maxExpArray[75] = 0x04a23105873875bd52dfdfffffffffffff;
        maxExpArray[76] = 0x0471649d87199aa990756fffffffffffff;
        maxExpArray[77] = 0x04429a21a029d4c1457cfbffffffffffff;
        maxExpArray[78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
        maxExpArray[79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
        maxExpArray[80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
        maxExpArray[81] = 0x0399e96897690418f785257fffffffffff;
        maxExpArray[82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
        maxExpArray[83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
        maxExpArray[84] = 0x032cbfd4a7adc790560b3337ffffffffff;
        maxExpArray[85] = 0x030b50570f6e5d2acca94613ffffffffff;
        maxExpArray[86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
        maxExpArray[87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
        maxExpArray[88] = 0x02af09481380a0a35cf1ba02ffffffffff;
        maxExpArray[89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
        maxExpArray[90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
        maxExpArray[91] = 0x025daf6654b1eaa55fd64df5efffffffff;
        maxExpArray[92] = 0x0244c49c648baa98192dce88b7ffffffff;
        maxExpArray[93] = 0x022ce03cd5619a311b2471268bffffffff;
        maxExpArray[94] = 0x0215f77c045fbe885654a44a0fffffffff;
        maxExpArray[95] = 0x01ffffffffffffffffffffffffffffffff;
        maxExpArray[96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
        maxExpArray[97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
        maxExpArray[98] = 0x01c35fedd14b861eb0443f7f133fffffff;
        maxExpArray[99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
        maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
        maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
        maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
        maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
        maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
        maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
        maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
        maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
        maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
        maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
        maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
        maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
        maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
        maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
        maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
        maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
        maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
        maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
        maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
        maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
        maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
        maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
        maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
        maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
        maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
        maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
        maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
        maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
    }

    /**
     * @dev given a token supply, reserve balance, ratio and a deposit amount (in the reserve token),
     * calculates the return for a given conversion (in the main token)
     *
     * Formula:
     * Return = _supply * ((1 + _depositAmount / _reserveBalance) ^ (_reserveRatio / 1000000) - 1)
     *
     * @param _supply              token total supply
     * @param _reserveBalance      total reserve balance
     * @param _reserveRatio        reserve ratio, represented in ppm, 1-1000000
     * @param _depositAmount       deposit amount, in reserve token
     *
     * @return purchase return amount
     */
    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _depositAmount
    ) public view returns (uint256) {
        // validate input
        require(
            _supply > 0 &&
                _reserveBalance > 0 &&
                _reserveRatio > 0 &&
                _reserveRatio <= MAX_RATIO
        );

        // special case for 0 deposit amount
        if (_depositAmount == 0) return 0;

        // special case if the ratio = 100%
        if (_reserveRatio == MAX_RATIO)
            return _supply.mul(_depositAmount) / _reserveBalance;

        uint256 result;
        uint8 precision;
        uint256 baseN = _depositAmount.add(_reserveBalance);
        (result, precision) = power(baseN, _reserveBalance, _reserveRatio, MAX_RATIO);
        uint256 temp = _supply.mul(result) >> precision;
        return temp - _supply;
    }

    /**
     * @dev given a token supply, reserve balance, ratio and a sell amount (in the main token),
     * calculates the return for a given conversion (in the reserve token)
     *
     * Formula:
     * Return = _reserveBalance * (1 - (1 - _sellAmount / _supply) ^ (1000000 / _reserveRatio))
     *
     * @param _supply              token total supply
     * @param _reserveBalance      total reserve
     * @param _reserveRatio        constant reserve Ratio, represented in ppm, 1-1000000
     * @param _sellAmount          sell amount, in the token itself
     *
     * @return sale return amount
     */
    function calculateSaleReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _sellAmount
    ) public view returns (uint256) {
        // validate input
        require(
            _supply > 0 &&
                _reserveBalance > 0 &&
                _reserveRatio > 0 &&
                _reserveRatio <= MAX_RATIO &&
                _sellAmount <= _supply
        );

        // special case for 0 sell amount
        if (_sellAmount == 0) return 0;

        // special case for selling the entire supply
        if (_sellAmount == _supply) return _reserveBalance;

        // special case if the ratio = 100%
        if (_reserveRatio == MAX_RATIO) return _reserveBalance.mul(_sellAmount) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _sellAmount;
        (result, precision) = power(_supply, baseD, MAX_RATIO, _reserveRatio);
        uint256 temp1 = _reserveBalance.mul(result);
        uint256 temp2 = _reserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev given two reserve balances/ratios and a sell amount (in the first reserve token),
     * calculates the return for a conversion from the first reserve token to the second reserve token (in the second reserve token)
     * note that prior to version 4, you should use 'calculateCrossConnectorReturn' instead
     *
     * Formula:
     * Return = _toReserveBalance * (1 - (_fromReserveBalance / (_fromReserveBalance + _amount)) ^ (_fromReserveRatio / _toReserveRatio))
     *
     * @param _fromReserveBalance      input reserve balance
     * @param _fromReserveRatio        input reserve ratio, represented in ppm, 1-1000000
     * @param _toReserveBalance        output reserve balance
     * @param _toReserveRatio          output reserve ratio, represented in ppm, 1-1000000
     * @param _amount                  input reserve amount
     *
     * @return second reserve amount
     */
    function calculateCrossReserveReturn(
        uint256 _fromReserveBalance,
        uint32 _fromReserveRatio,
        uint256 _toReserveBalance,
        uint32 _toReserveRatio,
        uint256 _amount
    ) public view returns (uint256) {
        // validate input
        require(
            _fromReserveBalance > 0 &&
                _fromReserveRatio > 0 &&
                _fromReserveRatio <= MAX_RATIO &&
                _toReserveBalance > 0 &&
                _toReserveRatio > 0 &&
                _toReserveRatio <= MAX_RATIO
        );

        // special case for equal ratios
        if (_fromReserveRatio == _toReserveRatio)
            return _toReserveBalance.mul(_amount) / _fromReserveBalance.add(_amount);

        uint256 result;
        uint8 precision;
        uint256 baseN = _fromReserveBalance.add(_amount);
        (result, precision) = power(
            baseN,
            _fromReserveBalance,
            _fromReserveRatio,
            _toReserveRatio
        );
        uint256 temp1 = _toReserveBalance.mul(result);
        uint256 temp2 = _toReserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev given a smart token supply, reserve balance, total ratio and an amount of requested smart tokens,
     * calculates the amount of reserve tokens required for purchasing the given amount of smart tokens
     *
     * Formula:
     * Return = _reserveBalance * (((_supply + _amount) / _supply) ^ (MAX_RATIO / _totalRatio) - 1)
     *
     * @param _supply              smart token supply
     * @param _reserveBalance      reserve token balance
     * @param _totalRatio          total ratio, represented in ppm, 2-2000000
     * @param _amount              requested amount of smart tokens
     *
     * @return amount of reserve tokens
     */
    function calculateFundCost(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _totalRatio,
        uint256 _amount
    ) public view returns (uint256) {
        // validate input
        require(
            _supply > 0 &&
                _reserveBalance > 0 &&
                _totalRatio > 1 &&
                _totalRatio <= MAX_RATIO * 2
        );

        // special case for 0 amount
        if (_amount == 0) return 0;

        // special case if the total ratio = 100%
        if (_totalRatio == MAX_RATIO)
            return (_amount.mul(_reserveBalance) - 1) / _supply + 1;

        uint256 result;
        uint8 precision;
        uint256 baseN = _supply.add(_amount);
        (result, precision) = power(baseN, _supply, MAX_RATIO, _totalRatio);
        uint256 temp = ((_reserveBalance.mul(result) - 1) >> precision) + 1;
        return temp - _reserveBalance;
    }

    /**
     * @dev given a smart token supply, reserve balance, total ratio and an amount of smart tokens to liquidate,
     * calculates the amount of reserve tokens received for selling the given amount of smart tokens
     *
     * Formula:
     * Return = _reserveBalance * (1 - ((_supply - _amount) / _supply) ^ (MAX_RATIO / _totalRatio))
     *
     * @param _supply              smart token supply
     * @param _reserveBalance      reserve token balance
     * @param _totalRatio          total ratio, represented in ppm, 2-2000000
     * @param _amount              amount of smart tokens to liquidate
     *
     * @return amount of reserve tokens
     */
    function calculateLiquidateReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _totalRatio,
        uint256 _amount
    ) public view returns (uint256) {
        // validate input
        require(
            _supply > 0 &&
                _reserveBalance > 0 &&
                _totalRatio > 1 &&
                _totalRatio <= MAX_RATIO * 2 &&
                _amount <= _supply
        );

        // special case for 0 amount
        if (_amount == 0) return 0;

        // special case for liquidating the entire supply
        if (_amount == _supply) return _reserveBalance;

        // special case if the total ratio = 100%
        if (_totalRatio == MAX_RATIO) return _amount.mul(_reserveBalance) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _amount;
        (result, precision) = power(_supply, baseD, MAX_RATIO, _totalRatio);
        uint256 temp1 = _reserveBalance.mul(result);
        uint256 temp2 = _reserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev General Description:
     *     Determine a value of precision.
     *     Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
     *     Return the result along with the precision used.
     *
     * Detailed Description:
     *     Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
     *     The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
     *     The larger "precision" is, the more accurately this value represents the real value.
     *     However, the larger "precision" is, the more bits are required in order to store this value.
     *     And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
     *     This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     *     Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
     *     This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
     *     This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".
     *     Since we rely on unsigned-integer arithmetic and "base < 1" ==> "log(base) < 0", this function does not support "_baseN < _baseD".
     */
    function power(
        uint256 _baseN,
        uint256 _baseD,
        uint32 _expN,
        uint32 _expD
    ) internal view returns (uint256, uint8) {
        require(_baseN < MAX_NUM);

        uint256 baseLog;
        uint256 base = (_baseN * FIXED_1) / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        } else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = (baseLog * _expN) / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        } else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (
                generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision),
                precision
            );
        }
    }

    /**
     * @dev computes log(x / FIXED_1) * FIXED_1.
     * This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.
     */
    function generalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += ONE << (i - 1);
                }
            }
        }

        return (res * LN2_NUMERATOR) / LN2_DENOMINATOR;
    }

    /**
     * @dev computes the largest integer smaller than or equal to the binary logarithm of the input.
     */
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        } else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    /**
     * @dev the global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
     * - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
     * - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
     */
    function findPositionInMaxExpArray(uint256 _x) internal view returns (uint8) {
        uint8 lo = MIN_PRECISION;
        uint8 hi = MAX_PRECISION;

        while (lo + 1 < hi) {
            uint8 mid = (lo + hi) / 2;
            if (maxExpArray[mid] >= _x) lo = mid;
            else hi = mid;
        }

        if (maxExpArray[hi] >= _x) return hi;
        if (maxExpArray[lo] >= _x) return lo;

        require(false);
        return 0;
    }

    /**
     * @dev this function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
     * it approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
     * it returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
     * the global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
     * the maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     */
    function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision;
        res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }

    /**
     * @dev computes log(x / FIXED_1) * FIXED_1
     * Input range: FIXED_1 <= x <= LOG_EXP_MAX_VAL - 1
     * Auto-generated via 'PrintFunctionOptimalLog.py'
     * Detailed description:
     * - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
     * - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
     * - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
     * - The natural logarithm of the input is calculated by summing up the intermediate results above
     * - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
     */
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {
            res += 0x40000000000000000000000000000000;
            x = (x * FIXED_1) / 0xd3094c70f034de4b96ff7d5b6f99fcd8;
        } // add 1 / 2^1
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {
            res += 0x20000000000000000000000000000000;
            x = (x * FIXED_1) / 0xa45af1e1f40c333b3de1db4dd55f29a7;
        } // add 1 / 2^2
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {
            res += 0x10000000000000000000000000000000;
            x = (x * FIXED_1) / 0x910b022db7ae67ce76b441c27035c6a1;
        } // add 1 / 2^3
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {
            res += 0x08000000000000000000000000000000;
            x = (x * FIXED_1) / 0x88415abbe9a76bead8d00cf112e4d4a8;
        } // add 1 / 2^4
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {
            res += 0x04000000000000000000000000000000;
            x = (x * FIXED_1) / 0x84102b00893f64c705e841d5d4064bd3;
        } // add 1 / 2^5
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {
            res += 0x02000000000000000000000000000000;
            x = (x * FIXED_1) / 0x8204055aaef1c8bd5c3259f4822735a2;
        } // add 1 / 2^6
        if (x >= 0x810100ab00222d861931c15e39b44e99) {
            res += 0x01000000000000000000000000000000;
            x = (x * FIXED_1) / 0x810100ab00222d861931c15e39b44e99;
        } // add 1 / 2^7
        if (x >= 0x808040155aabbbe9451521693554f733) {
            res += 0x00800000000000000000000000000000;
            x = (x * FIXED_1) / 0x808040155aabbbe9451521693554f733;
        } // add 1 / 2^8

        z = y = x - FIXED_1;
        w = (y * y) / FIXED_1;
        res +=
            (z * (0x100000000000000000000000000000000 - y)) /
            0x100000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^01 / 01 - y^02 / 02
        res +=
            (z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) /
            0x200000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^03 / 03 - y^04 / 04
        res +=
            (z * (0x099999999999999999999999999999999 - y)) /
            0x300000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^05 / 05 - y^06 / 06
        res +=
            (z * (0x092492492492492492492492492492492 - y)) /
            0x400000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^07 / 07 - y^08 / 08
        res +=
            (z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) /
            0x500000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^09 / 09 - y^10 / 10
        res +=
            (z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) /
            0x600000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^11 / 11 - y^12 / 12
        res +=
            (z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) /
            0x700000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^13 / 13 - y^14 / 14
        res +=
            (z * (0x088888888888888888888888888888888 - y)) /
            0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16

        return res;
    }

    /**
     * @dev computes e ^ (x / FIXED_1) * FIXED_1
     * input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
     * auto-generated via 'PrintFunctionOptimalExp.py'
     * Detailed description:
     * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
     * - The exponentiation of each binary exponent is given (pre-calculated)
     * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
     * - The exponentiation of the input is calculated by multiplying the intermediate results above
     * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
     */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = (z * y) / FIXED_1;
        res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = (z * y) / FIXED_1;
        res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = (z * y) / FIXED_1;
        res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = (z * y) / FIXED_1;
        res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = (z * y) / FIXED_1;
        res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = (z * y) / FIXED_1;
        res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = (z * y) / FIXED_1;
        res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = (z * y) / FIXED_1;
        res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = (z * y) / FIXED_1;
        res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0)
            res =
                (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) /
                0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
        if ((x & 0x020000000000000000000000000000000) != 0)
            res =
                (res * 0x18ebef9eac820ae8682b9793ac6d1e778) /
                0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
        if ((x & 0x040000000000000000000000000000000) != 0)
            res =
                (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) /
                0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
        if ((x & 0x080000000000000000000000000000000) != 0)
            res =
                (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) /
                0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
        if ((x & 0x100000000000000000000000000000000) != 0)
            res =
                (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) /
                0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
        if ((x & 0x200000000000000000000000000000000) != 0)
            res =
                (res * 0x00960aadc109e7a3bf4578099615711d7) /
                0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
        if ((x & 0x400000000000000000000000000000000) != 0)
            res =
                (res * 0x0002bf84208204f5977f9a8cf01fdc307) /
                0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

        return res;
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function calculateCrossConnectorReturn(
        uint256 _fromConnectorBalance,
        uint32 _fromConnectorWeight,
        uint256 _toConnectorBalance,
        uint32 _toConnectorWeight,
        uint256 _amount
    ) public view returns (uint256) {
        return
            calculateCrossReserveReturn(
                _fromConnectorBalance,
                _fromConnectorWeight,
                _toConnectorBalance,
                _toConnectorWeight,
                _amount
            );
    }
}

// File: contracts/GoodMarketMaker.sol

pragma solidity >0.5.4;









/**
@title Dynamic reserve ratio market maker
*/
contract GoodMarketMaker is BancorFormula, DSMath, SchemeGuard {
    using SafeMath for uint256;

    // For calculate the return value on buy and sell
    BancorFormula bancor;

    // Entity that holds a reserve token
    struct ReserveToken {
        // Determines the reserve token balance
        // that the reserve contract holds
        uint256 reserveSupply;
        // Determines the current ratio between
        // the reserve token and the GD token
        uint32 reserveRatio;
        // How many GD tokens have been minted
        // against that reserve token
        uint256 gdSupply;
    }

    // The map which holds the reserve token entities
    mapping(address => ReserveToken) public reserveTokens;

    // Emits when a change has occurred in a
    // reserve balance, i.e. buy / sell will
    // change the balance
    event BalancesUpdated(
        // The account who initiated the action
        address indexed caller,
        // The address of the reserve token
        address indexed reserveToken,
        // The incoming amount
        uint256 amount,
        // The return value
        uint256 returnAmount,
        // The updated total supply
        uint256 totalSupply,
        // The updated reserve balance
        uint256 reserveBalance
    );

    // Emits when the ratio changed. The caller should be the Avatar by definition
    event ReserveRatioUpdated(address indexed caller, uint256 nom, uint256 denom);

    // Emits when new tokens should be minted
    // as a result of incoming interest.
    // That event will be emitted after the
    // reserve entity has been updated
    event InterestMinted(
        // The account who initiated the action
        address indexed caller,
        // The address of the reserve token
        address indexed reserveToken,
        // How much new reserve tokens been
        // added to the reserve balance
        uint256 addInterest,
        // The GD supply in the reserve entity
        // before the new minted GD tokens were
        // added to the supply
        uint256 oldSupply,
        // The number of the new minted GD tokens
        uint256 mint
    );

    // Emits when new tokens should be minted
    // as a result of a reserve ratio expansion
    // change. This change should have occurred
    // on a regular basis. That event will be
    // emitted after the reserve entity has been
    // updated
    event UBIExpansionMinted(
        // The account who initiated the action
        address indexed caller,
        // The address of the reserve token
        address indexed reserveToken,
        // The reserve ratio before the expansion
        uint256 oldReserveRatio,
        // The GD supply in the reserve entity
        // before the new minted GD tokens were
        // added to the supply
        uint256 oldSupply,
        // The number of the new minted GD tokens
        uint256 mint
    );

    // Defines the daily change in the reserve ratio in RAY precision.
    // In the current release, only global ratio expansion is supported.
    // That will be a part of each reserve token entity in the future.
    uint256 public reserveRatioDailyExpansion;

    /**
     * @dev Constructor
     * @param _avatar The avatar of the DAO
     * @param _nom The numerator to calculate the global `reserveRatioDailyExpansion` from
     * @param _denom The denominator to calculate the global `reserveRatioDailyExpansion` from
     */
    constructor(
        Avatar _avatar,
        uint256 _nom,
        uint256 _denom
    ) public SchemeGuard(_avatar) {
        reserveRatioDailyExpansion = rdiv(_nom, _denom);
    }

    modifier onlyActiveToken(ERC20 _token) {
        ReserveToken storage rtoken = reserveTokens[address(_token)];
        require(rtoken.gdSupply > 0, "Reserve token not initialized");
        _;
    }

    /**
     * @dev Allows the DAO to change the daily expansion rate
     * it is calculated by _nom/_denom with e27 precision. Emits
     * `ReserveRatioUpdated` event after the ratio has changed.
     * Only Avatar can call this method.
     * @param _nom The numerator to calculate the global `reserveRatioDailyExpansion` from
     * @param _denom The denominator to calculate the global `reserveRatioDailyExpansion` from
     */
    function setReserveRatioDailyExpansion(uint256 _nom, uint256 _denom)
        public
        onlyAvatar
    {
        require(_denom > 0, "denominator must be above 0");
        reserveRatioDailyExpansion = rdiv(_nom, _denom);
        emit ReserveRatioUpdated(msg.sender, _nom, _denom);
    }

    // NOTICE: In the current release, if there is a wish to add another reserve token,
    //  `end` method in the reserve contract should be called first. Then, the DAO have
    //  to deploy a new reserve contract that will own the market maker. A scheme for
    // updating the new reserve must be deployed too.

    /**
     * @dev Initialize a reserve token entity with the given parameters
     * @param _token The reserve token
     * @param _gdSupply Initial supply of GD to set the price
     * @param _tokenSupply Initial supply of reserve token to set the price
     * @param _reserveRatio The starting reserve ratio
     */
    function initializeToken(
        ERC20 _token,
        uint256 _gdSupply,
        uint256 _tokenSupply,
        uint32 _reserveRatio
    ) public onlyOwner {
        reserveTokens[address(_token)] = ReserveToken({
            gdSupply: _gdSupply,
            reserveSupply: _tokenSupply,
            reserveRatio: _reserveRatio
        });
    }

    /**
     * @dev Calculates how much to decrease the reserve ratio for _token by
     * the `reserveRatioDailyExpansion`
     * @param _token The reserve token to calculate the reserve ratio for
     * @return The new reserve ratio
     */
    function calculateNewReserveRatio(ERC20 _token)
        public
        view
        onlyActiveToken(_token)
        returns (uint32)
    {
        ReserveToken memory reserveToken = reserveTokens[address(_token)];
        uint32 ratio = reserveToken.reserveRatio;
        if (ratio == 0) {
            ratio = 1e6;
        }
        return
            uint32(
                rmul(
                    uint256(ratio).mul(1e21), // expand to e27 precision
                    reserveRatioDailyExpansion
                )
                    .div(1e21) // return to e6 precision
            );
    }

    /**
     * @dev Decreases the reserve ratio for _token by the `reserveRatioDailyExpansion`
     * @param _token The token to change the reserve ratio for
     * @return The new reserve ratio
     */
    function expandReserveRatio(ERC20 _token)
        public
        onlyOwner
        onlyActiveToken(_token)
        returns (uint32)
    {
        ReserveToken storage reserveToken = reserveTokens[address(_token)];
        uint32 ratio = reserveToken.reserveRatio;
        if (ratio == 0) {
            ratio = 1e6;
        }
        reserveToken.reserveRatio = calculateNewReserveRatio(_token);
        return reserveToken.reserveRatio;
    }

    /**
     * @dev Calculates the buy return in GD according to the given _tokenAmount
     * @param _token The reserve token buying with
     * @param _tokenAmount The amount of reserve token buying with
     * @return Number of GD that should be given in exchange as calculated by the bonding curve
     */
    function buyReturn(ERC20 _token, uint256 _tokenAmount)
        public
        view
        onlyActiveToken(_token)
        returns (uint256)
    {
        ReserveToken memory rtoken = reserveTokens[address(_token)];
        return
            calculatePurchaseReturn(
                rtoken.gdSupply,
                rtoken.reserveSupply,
                rtoken.reserveRatio,
                _tokenAmount
            );
    }

    /**
     * @dev Calculates the sell return in _token according to the given _gdAmount
     * @param _token The desired reserve token to have
     * @param _gdAmount The amount of GD that are sold
     * @return Number of tokens that should be given in exchange as calculated by the bonding curve
     */
    function sellReturn(ERC20 _token, uint256 _gdAmount)
        public
        view
        onlyActiveToken(_token)
        returns (uint256)
    {
        ReserveToken memory rtoken = reserveTokens[address(_token)];
        return
            calculateSaleReturn(
                rtoken.gdSupply,
                rtoken.reserveSupply,
                rtoken.reserveRatio,
                _gdAmount
            );
    }

    /**
     * @dev Updates the _token bonding curve params. Emits `BalancesUpdated` with the
     * new reserve token information.
     * @param _token The reserve token buying with
     * @param _tokenAmount The amount of reserve token buying with
     * @return (gdReturn) Number of GD that will be given in exchange as calculated by the bonding curve
     */
    function buy(ERC20 _token, uint256 _tokenAmount)
        public
        onlyOwner
        onlyActiveToken(_token)
        returns (uint256)
    {
        uint256 gdReturn = buyReturn(_token, _tokenAmount);
        ReserveToken storage rtoken = reserveTokens[address(_token)];
        rtoken.gdSupply = rtoken.gdSupply.add(gdReturn);
        rtoken.reserveSupply = rtoken.reserveSupply.add(_tokenAmount);
        emit BalancesUpdated(
            msg.sender,
            address(_token),
            _tokenAmount,
            gdReturn,
            rtoken.gdSupply,
            rtoken.reserveSupply
        );
        return gdReturn;
    }

    /**
     * @dev Updates the _token bonding curve params. Emits `BalancesUpdated` with the
     * new reserve token information.
     * @param _token The desired reserve token to have
     * @param _gdAmount The amount of GD that are sold
     * @return Number of tokens that will be given in exchange as calculated by the bonding curve
     */
    function sell(ERC20 _token, uint256 _gdAmount)
        public
        onlyOwner
        onlyActiveToken(_token)
        returns (uint256)
    {
        ReserveToken storage rtoken = reserveTokens[address(_token)];
        require(rtoken.gdSupply > _gdAmount, "GD amount is higher than the total supply");
        uint256 tokenReturn = sellReturn(_token, _gdAmount);
        rtoken.gdSupply = rtoken.gdSupply.sub(_gdAmount);
        rtoken.reserveSupply = rtoken.reserveSupply.sub(tokenReturn);
        emit BalancesUpdated(
            msg.sender,
            address(_token),
            _gdAmount,
            tokenReturn,
            rtoken.gdSupply,
            rtoken.reserveSupply
        );
        return tokenReturn;
    }

    /**
     * @dev Calculates the sell return with contribution in _token and update the bonding curve params.
     * Emits `BalancesUpdated` with the new reserve token information.
     * @param _token The desired reserve token to have
     * @param _gdAmount The amount of GD that are sold
     * @param _contributionGdAmount The number of GD tokens that will not be traded for the reserve token
     * @return Number of tokens that will be given in exchange as calculated by the bonding curve
     */
    function sellWithContribution(
        ERC20 _token,
        uint256 _gdAmount,
        uint256 _contributionGdAmount
    ) public onlyOwner onlyActiveToken(_token) returns (uint256) {
        require(
            _gdAmount >= _contributionGdAmount,
            "GD amount is lower than the contribution amount"
        );
        ReserveToken storage rtoken = reserveTokens[address(_token)];
        require(rtoken.gdSupply > _gdAmount, "GD amount is higher than the total supply");

        // Deduces the convertible amount of GD tokens by the given contribution amount
        uint256 amountAfterContribution = _gdAmount.sub(_contributionGdAmount);

        // The return value after the deduction
        uint256 tokenReturn = sellReturn(_token, amountAfterContribution);
        rtoken.gdSupply = rtoken.gdSupply.sub(_gdAmount);
        rtoken.reserveSupply = rtoken.reserveSupply.sub(tokenReturn);
        emit BalancesUpdated(
            msg.sender,
            address(_token),
            _contributionGdAmount,
            tokenReturn,
            rtoken.gdSupply,
            rtoken.reserveSupply
        );
        return tokenReturn;
    }

    /**
     * @dev Current price of GD in `token`. currently only cDAI is supported.
     * @param _token The desired reserve token to have
     * @return price of GD
     */
    function currentPrice(ERC20 _token)
        public
        view
        onlyActiveToken(_token)
        returns (uint256)
    {
        ReserveToken memory rtoken = reserveTokens[address(_token)];
        GoodDollar gooddollar = GoodDollar(address(avatar.nativeToken()));
        return
            calculateSaleReturn(
                rtoken.gdSupply,
                rtoken.reserveSupply,
                rtoken.reserveRatio,
                (10**uint256(gooddollar.decimals()))
            );
    }

    //TODO: need real calculation and tests
    /**
     * @dev Calculates how much G$ to mint based on added token supply (from interest)
     * and on current reserve ratio, in order to keep G$ price the same at the bonding curve
     * formula to calculate the gd to mint: gd to mint =
     * addreservebalance * (gdsupply / (reservebalance * reserveratio))
     * @param _token the reserve token
     * @param _addTokenSupply amount of token added to supply
     * @return how much to mint in order to keep price in bonding curve the same
     */
    function calculateMintInterest(ERC20 _token, uint256 _addTokenSupply)
        public
        view
        onlyActiveToken(_token)
        returns (uint256)
    {
        GoodDollar gooddollar = GoodDollar(address(avatar.nativeToken()));
        uint256 decimalsDiff = uint256(27).sub(uint256(gooddollar.decimals()));
        //resulting amount is in RAY precision
        //we divide by decimalsdiff to get precision in GD (2 decimals)
        return rdiv(_addTokenSupply, currentPrice(_token)).div(10**decimalsDiff);
    }

    /**
     * @dev Updates bonding curve based on _addTokenSupply and new minted amount
     * @param _token The reserve token
     * @param _addTokenSupply Amount of token added to supply
     * @return How much to mint in order to keep price in bonding curve the same
     */
    function mintInterest(ERC20 _token, uint256 _addTokenSupply)
        public
        onlyOwner
        returns (uint256)
    {
        if (_addTokenSupply == 0) {
            return 0;
        }
        uint256 toMint = calculateMintInterest(_token, _addTokenSupply);
        ReserveToken storage reserveToken = reserveTokens[address(_token)];
        uint256 gdSupply = reserveToken.gdSupply;
        uint256 reserveBalance = reserveToken.reserveSupply;
        reserveToken.gdSupply = gdSupply.add(toMint);
        reserveToken.reserveSupply = reserveBalance.add(_addTokenSupply);
        emit InterestMinted(
            msg.sender,
            address(_token),
            _addTokenSupply,
            gdSupply,
            toMint
        );
        return toMint;
    }

    /**
     * @dev Calculate how much G$ to mint based on expansion change (new reserve
     * ratio), in order to keep G$ price the same at the bonding curve. the
     * formula to calculate the gd to mint: gd to mint =
     * (reservebalance / (newreserveratio * currentprice)) - gdsupply
     * @param _token The reserve token
     * @return How much to mint in order to keep price in bonding curve the same
     */
    function calculateMintExpansion(ERC20 _token)
        public
        view
        onlyActiveToken(_token)
        returns (uint256)
    {
        ReserveToken memory reserveToken = reserveTokens[address(_token)];
        uint32 newReserveRatio = calculateNewReserveRatio(_token); // new reserve ratio
        uint256 reserveDecimalsDiff = uint256(
            uint256(27).sub(ERC20Detailed(address(_token)).decimals())
        ); // //result is in RAY precision
        uint256 denom = rmul(
            uint256(newReserveRatio).mul(1e21),
            currentPrice(_token).mul(10**reserveDecimalsDiff)
        ); // (newreserveratio * currentprice) in RAY precision
        GoodDollar gooddollar = GoodDollar(address(avatar.nativeToken()));
        uint256 gdDecimalsDiff = uint256(27).sub(uint256(gooddollar.decimals()));
        uint256 toMint = rdiv(
            reserveToken.reserveSupply.mul(10**reserveDecimalsDiff), // reservebalance in RAY precision
            denom
        )
            .div(10**gdDecimalsDiff); // return to gd precision
        return toMint.sub(reserveToken.gdSupply);
    }

    /**
     * @dev Updates bonding curve based on expansion change and new minted amount
     * @param _token The reserve token
     * @return How much to mint in order to keep price in bonding curve the same
     */
    function mintExpansion(ERC20 _token) public onlyOwner returns (uint256) {
        uint256 toMint = calculateMintExpansion(_token);
        ReserveToken storage reserveToken = reserveTokens[address(_token)];
        uint256 gdSupply = reserveToken.gdSupply;
        uint256 ratio = reserveToken.reserveRatio;
        reserveToken.gdSupply = gdSupply.add(toMint);
        expandReserveRatio(_token);
        emit UBIExpansionMinted(msg.sender, address(_token), ratio, gdSupply, toMint);
        return toMint;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol

pragma solidity ^0.5.0;



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
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

// File: ../contracts/dao/schemes/FeelessScheme.sol

pragma solidity >0.5.4;





/**
 * @dev Contract for letting scheme add itself to identity
 * to allow transferring GoodDollar without paying fees
 * and transfer ownership to Avatar
 */
contract FeelessScheme is SchemeGuard, IdentityGuard {
    /* @dev Constructor
     * @param _identity The identity contract
     * @param _avatar The avatar of the DAO
     */
    constructor(Identity _identity, Avatar _avatar)
        public
        SchemeGuard(_avatar)
        IdentityGuard(_identity)
    {}

    /* @dev Internal function to add contract to identity.
     * Can only be called if scheme is registered.
     */
    function addRights() internal onlyRegistered {
        controller.genericCall(
            address(identity),
            abi.encodeWithSignature("addContract(address)", address(this)),
            avatar,
            0
        );
        transferOwnership(address(avatar));
    }

    /* @dev Internal function to remove contract from identity.
     * Can only be called if scheme is registered.
     */
    function removeRights() internal onlyRegistered {
        controller.genericCall(
            address(identity),
            abi.encodeWithSignature("removeContract(address)", address(this)),
            avatar,
            0
        );
    }
}

// File: ../contracts/dao/schemes/ActivePeriod.sol

pragma solidity >0.5.4;


/* @title Abstract contract responsible for ensuring a scheme is only usable within a set period
 */
contract ActivePeriod {
    uint256 public periodStart;
    uint256 public periodEnd;

    bool public isActive;

    Avatar avatar;

    event SchemeStarted(address indexed by, uint256 time);
    event SchemeEnded(address indexed by, uint256 time);

    /* @dev modifier that requires scheme to be active
     */
    modifier requireActive() {
        require(isActive, "is not active");
        _;
    }

    /* @dev modifier that requires scheme to not be active
     */
    modifier requireNotActive() {
        require(!isActive, "cannot start twice");
        _;
    }

    /* @dev modifier that requires current time to be after period start and before period end
     */
    modifier requireInPeriod() {
        require(now >= periodStart && now < periodEnd, "not in period");
        _;
    }

    /* @dev modifier that requires current time to be after period end
     */
    modifier requirePeriodEnd() {
        require(now >= periodEnd, "period has not ended");
        _;
    }

    /* @dev Constructor. requires end period to be larger than start period
     * Sets local period parameters and sets isActive to false
     * @param _periodStart The time from when the contract can be started
     * @param _periodEnd The time from when the contract can be ended
     * @param _avatar DAO avatar
     */
    constructor(
        uint256 _periodStart,
        uint256 _periodEnd,
        Avatar _avatar
    ) public {
        require(_periodStart < _periodEnd, "start cannot be after nor equal to end");

        periodStart = _periodStart;
        periodEnd = _periodEnd;
        avatar = _avatar;

        isActive = false;
    }

    /* @dev Function to start scheme. Must be inactive and within period.
     * Sets isActive to true and emits event with address that started and
     * current time.
     */
    function start() public requireInPeriod requireNotActive {
        isActive = true;
        emit SchemeStarted(msg.sender, now);
    }

    /* @dev Function to end scheme. Must be after assigned period end.
     * Calls internal function internalEnd, passing along the avatar
     * @param _avatar the avatar of the dao
     */
    function end() public requirePeriodEnd {
        return internalEnd(avatar);
    }

    /* @dev internal end function. Must be active to run.
     * Sets contract to inactive, emits an event with caller and
     * current time, and self-destructs the contract, transferring any
     * eth in the contract to the avatar address
     * @param _avatar the avatar of the dao
     */
    function internalEnd(Avatar _avatar) internal requireActive {
        isActive = false;
        emit SchemeEnded(msg.sender, now);
        selfdestruct(address(_avatar));
    }
}

// File: contracts/GoodReserveCDai.sol

pragma solidity >0.5.4;











interface cERC20 {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeemUnderlying(uint256 mintAmount) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function balanceOf(address addr) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

interface ContributionCalc {
    function calculateContribution(
        GoodMarketMaker _marketMaker,
        GoodReserveCDai _reserve,
        address _contributer,
        ERC20 _token,
        uint256 _gdAmount
    ) external view returns (uint256);
}

/**
@title Reserve based on cDAI and dynamic reserve ratio market maker
*/
contract GoodReserveCDai is DSMath, FeelessScheme, ActivePeriod {
    using SafeMath for uint256;

    // DAI token address
    ERC20 public dai;

    // cDAI token address
    cERC20 public cDai;

    // The address of the market maker contract
    // which makes the calculations and holds
    // the token and accounts info
    GoodMarketMaker public marketMaker;

    // The fund manager receives the minted tokens
    // when executing `mintInterestAndUBI`
    address public fundManager;

    // The block interval defines the number of
    // blocks that shall be passed before the
    // next execution of `mintInterestAndUBI`
    uint256 public blockInterval;

    // The last block number which
    // `mintInterestAndUBI` has been executed in
    uint256 public lastMinted;

    // The contribution contract is responsible
    // for calculates the contribution amount
    // when selling GD
    ContributionCalc public contribution;

    modifier onlyFundManager {
        require(msg.sender == fundManager, "Only FundManager can call this method");
        _;
    }

    modifier onlyCDai(ERC20 token) {
        require(address(token) == address(cDai), "Only cDAI is supported");
        _;
    }

    // Emits when GD tokens are purchased
    event TokenPurchased(
        // The initiate of the action
        address indexed caller,
        // The convertible token address
        // which the GD tokens were
        // purchased with
        address indexed reserveToken,
        // Reserve tokens amount
        uint256 reserveAmount,
        // Minimal GD return that was
        // permitted by the caller
        uint256 minReturn,
        // Actual return after the
        // conversion
        uint256 actualReturn
    );

    // Emits when GD tokens are sold
    event TokenSold(
        // The initiate of the action
        address indexed caller,
        // The convertible token address
        // which the GD tokens were
        // sold to
        address indexed reserveToken,
        // GD tokens amount
        uint256 gdAmount,
        // The amount of GD tokens that
        // was contributed during the
        // conversion
        uint256 contributionAmount,
        // Minimal reserve tokens return
        // that was permitted by the caller
        uint256 minReturn,
        // Actual return after the
        // conversion
        uint256 actualReturn
    );

    // Emits when the contribution contract
    // address is updated
    event ContributionAddressUpdated(
        // The initiate of the action
        address indexed caller,
        // Previous contribution
        // contract address
        address prevAddress,
        // The updated contribution
        // contract address
        address newAddress
    );

    // Emits when new GD tokens minted
    event UBIMinted(
        //epoch of UBI
        uint256 indexed day,
        //the token paid as interest
        address indexed interestToken,
        //wei amount of interest paid in interestToken
        uint256 interestReceived,
        // Amount of GD tokens that was
        // added to the supply as a result
        // of `mintInterest`
        uint256 gdInterestMinted,
        // Amount of GD tokens that was
        // added to the supply as a result
        // of `mintExpansion`
        uint256 gdExpansionMinted,
        // Amount of GD tokens that was
        // minted to the `interestCollector`
        uint256 gdInterestTransferred,
        // Amount of GD tokens that was
        // minted to the `ubiCollector`
        uint256 gdUbiTransferred
    );

    /**
     * @dev Constructor
     * @param _dai The address of DAI
     * @param _cDai The address of cDAI
     * @param _fundManager The address of the fund manager contract
     * @param _avatar The avatar of the DAO
     * @param _identity The identity contract
     * @param _marketMaker The address of the market maker contract
     * @param _contribution The address of the contribution contract
     * @param _blockInterval How many blocks should be passed before the next execution of `mintInterestAndUBI`
     */
    constructor(
        ERC20 _dai,
        cERC20 _cDai,
        address _fundManager,
        Avatar _avatar,
        Identity _identity,
        address _marketMaker,
        ContributionCalc _contribution,
        uint256 _blockInterval
    ) public FeelessScheme(_identity, _avatar) ActivePeriod(now, now * 2, _avatar) {
        dai = _dai;
        cDai = _cDai;
        fundManager = _fundManager;
        marketMaker = GoodMarketMaker(_marketMaker);
        blockInterval = _blockInterval;
        lastMinted = block.number.div(blockInterval);
        contribution = _contribution;
    }

    /**
     * @dev Start function. Adds this contract to identity as a feeless scheme.
     * Can only be called if scheme is registered
     */
    function start() public onlyRegistered {
        addRights();

        // Adds the reserve as a minter of the GD token
        controller.genericCall(
            address(avatar.nativeToken()),
            abi.encodeWithSignature("addMinter(address)", address(this)),
            avatar,
            0
        );
        super.start();
    }

    /**
     * @dev Allows the DAO to change the market maker contract
     * @param _marketMaker address of the new contract
     */
    function setMarketMaker(address _marketMaker) public onlyAvatar {
        marketMaker = GoodMarketMaker(_marketMaker);
    }

    /**
     * @dev Allows the DAO to change the fund manager contract
     * @param _fundManager address of the new contract
     */
    function setFundManager(address _fundManager) public onlyAvatar {
        fundManager = _fundManager;
    }

    /**
     * @dev Allows the DAO to change the block interval
     * @param _blockInterval the new value
     */
    function setBlockInterval(uint256 _blockInterval) public onlyAvatar {
        blockInterval = _blockInterval;
    }

    /**
     * @dev Allows the DAO to change the contribution formula contract
     * @param _contribution address of the new contribution contract
     */
    function setContributionAddress(address _contribution) public onlyAvatar {
        address prevAddress = address(contribution);
        contribution = ContributionCalc(_contribution);
        emit ContributionAddressUpdated(msg.sender, prevAddress, _contribution);
    }

    /**
     * @dev Converts `buyWith` tokens to GD tokens and updates the bonding curve params.
     * `buy` occurs only if the GD return is above the given minimum. It is possible
     * to buy only with cDAI and when the contract is set to active. MUST call to
     * `buyWith` `approve` prior this action to allow this contract to accomplish the
     * conversion.
     * @param _buyWith The tokens that should be converted to GD tokens
     * @param _tokenAmount The amount of `buyWith` tokens that should be converted to GD tokens
     * @param _minReturn The minimum allowed return in GD tokens
     * @return (gdReturn) How much GD tokens were transferred
     */
    function buy(
        ERC20 _buyWith,
        uint256 _tokenAmount,
        uint256 _minReturn
    ) public requireActive onlyCDai(_buyWith) returns (uint256) {
        require(
            _buyWith.allowance(msg.sender, address(this)) >= _tokenAmount,
            "You need to approve cDAI transfer first"
        );
        require(
            _buyWith.transferFrom(msg.sender, address(this), _tokenAmount) == true,
            "transferFrom failed, make sure you approved cDAI transfer"
        );
        uint256 gdReturn = marketMaker.buy(_buyWith, _tokenAmount);
        require(gdReturn >= _minReturn, "GD return must be above the minReturn");
        ERC20Mintable(address(avatar.nativeToken())).mint(msg.sender, gdReturn);
        emit TokenPurchased(
            msg.sender,
            address(_buyWith),
            _tokenAmount,
            _minReturn,
            gdReturn
        );
        return gdReturn;
    }

    /**
     * @dev Converts GD tokens to `sellTo` tokens and update the bonding curve params.
     * `sell` occurs only if the token return is above the given minimum. Notice that
     * there is a contribution amount from the given GD that remains in the reserve.
     * It is only possible to sell to cDAI and only when the contract is set to
     * active. MUST be called to G$ `approve` prior to this action to allow this
     * contract to accomplish the conversion.
     * @param _sellTo The tokens that will be received after the conversion
     * @param _gdAmount The amount of GD tokens that should be converted to `_sellTo` tokens
     * @param _minReturn The minimum allowed `sellTo` tokens return
     * @return (tokenReturn) How much `sellTo` tokens were transferred
     */
    function sell(
        ERC20 _sellTo,
        uint256 _gdAmount,
        uint256 _minReturn
    ) public requireActive onlyCDai(_sellTo) returns (uint256) {
        ERC20Burnable(address(avatar.nativeToken())).burnFrom(msg.sender, _gdAmount);
        uint256 contributionAmount = contribution.calculateContribution(
            marketMaker,
            this,
            msg.sender,
            _sellTo,
            _gdAmount
        );
        uint256 tokenReturn = marketMaker.sellWithContribution(
            _sellTo,
            _gdAmount,
            contributionAmount
        );
        require(tokenReturn >= _minReturn, "Token return must be above the minReturn");
        require(_sellTo.transfer(msg.sender, tokenReturn) == true, "Transfer failed");
        emit TokenSold(
            msg.sender,
            address(_sellTo),
            _gdAmount,
            contributionAmount,
            _minReturn,
            tokenReturn
        );
        return tokenReturn;
    }

    /**
     * @dev Current price of GD in `token`. currently only cDAI is supported.
     * @param _token The desired reserve token to have
     * @return price of GD
     */
    function currentPrice(ERC20 _token) public view returns (uint256) {
        return marketMaker.currentPrice(_token);
    }

    /**
     * @dev Checks if enough blocks have passed so it would be possible to
     * execute `mintInterestAndUBI` according to the length of `blockInterval`
     * @return (bool) True if enough blocks have passed
     */
    function canMint() public view returns (bool) {
        return block.number.div(blockInterval) > lastMinted;
    }

    /**
     * @dev Anyone can call this to trigger calculations.
     * Reserve sends UBI to Avatar DAO and returns interest to FundManager.
     * @param _interestToken The token that was transfered to the reserve
     * @param _transfered How much was transfered to the reserve for UBI in `_interestToken`
     * @param _interest Out of total transfered how much is the interest (in `_interestToken`)
     * that needs to be paid back (some interest might be donated)
     * @return (gdInterest, gdUBI) How much GD interest was minted and how much GD UBI was minted
     */
    function mintInterestAndUBI(
        ERC20 _interestToken,
        uint256 _transfered,
        uint256 _interest
    )
        public
        requireActive
        onlyCDai(_interestToken)
        onlyFundManager
        returns (uint256, uint256)
    {
        require(canMint(), "Need to wait for the next interval");
        uint256 price = currentPrice(_interestToken);
        uint256 gdInterestToMint = marketMaker.mintInterest(_interestToken, _transfered);
        GoodDollar gooddollar = GoodDollar(address(avatar.nativeToken()));
        uint256 precisionLoss = uint256(27).sub(uint256(gooddollar.decimals()));
        uint256 gdInterest = rdiv(_interest, price).div(10**precisionLoss);
        uint256 gdExpansionToMint = marketMaker.mintExpansion(_interestToken);
        uint256 gdUBI = gdInterestToMint.sub(gdInterest);
        gdUBI = gdUBI.add(gdExpansionToMint);
        uint256 toMint = gdUBI.add(gdInterest);
        ERC20Mintable(address(avatar.nativeToken())).mint(fundManager, toMint);
        lastMinted = block.number.div(blockInterval);
        emit UBIMinted(
            lastMinted,
            address(_interestToken),
            _transfered,
            gdInterestToMint,
            gdExpansionToMint,
            gdInterest,
            gdUBI
        );
        return (gdInterest, gdUBI);
    }

    /**
     * @dev Making the contract inactive after it has transferred the cDAI funds to `_avatar`
     * and has transferred the market maker ownership to `_avatar`. Inactive means that
     * buy / sell / mintInterestAndUBI actions will no longer be active. Only the Avatar can
     * executes this method
     */
    function end() public onlyAvatar {
        // remaining cDAI tokens in the current reserve contract
        uint256 remainingReserve = cDai.balanceOf(address(this));
        if (remainingReserve > 0) {
            require(
                cDai.transfer(address(avatar), remainingReserve),
                "cdai transfer failed"
            );
        }
        require(cDai.balanceOf(address(this)) == 0, "Funds transfer has failed");
        GoodDollar gooddollar = GoodDollar(address(avatar.nativeToken()));
        marketMaker.transferOwnership(address(avatar));
        gooddollar.renounceMinter();
        super.internalEnd(avatar);
    }

    /**
     * @dev method to recover any stuck erc20 tokens (ie compound COMP)
     * @param _token the ERC20 token to recover
     */
    function recover(ERC20 _token) public onlyAvatar {
        require(
            _token.transfer(address(avatar), _token.balanceOf(address(this))),
            "recover transfer failed"
        );
    }
}

// File: contracts/ContributionCalculation.sol

pragma solidity >0.5.4;







/* @title Contribution calculation for selling gd tokens
 */
contract ContributionCalculation is DSMath {
    using SafeMath for uint256;

    Avatar avatar;
    // The contribution ratio, declares how much
    // to contribute from the given amount
    uint256 public sellContributionRatio;

    // Emits when the contribution ratio is updated
    event SellContributionRatioUpdated(
        address indexed caller,
        uint256 nom,
        uint256 denom
    );

    /** @dev modifier to check if caller is avatar
     */
    modifier onlyAvatar() {
        require(address(avatar) == msg.sender, "only Avatar can call this method");
        _;
    }

    /**
     * @dev Constructor
     * @param _avatar The avatar of the DAO
     * @param _nom The numerator to calculate the contribution ratio from
     * @param _denom The denominator to calculate the contribution ratio from
     */
    constructor(
        Avatar _avatar,
        uint256 _nom,
        uint256 _denom
    ) public {
        sellContributionRatio = rdiv(_nom, _denom);
        avatar = _avatar;
    }

    /**
     * @dev Allow the DAO to change the sell contribution rate
     * it is calculated by _nom/_denom with e27 precision. Emits
     * that the contribution ratio was updated.
     * @param _nom the nominator
     * @param _denom the denominator
     */
    function setContributionRatio(uint256 _nom, uint256 _denom) external onlyAvatar {
        require(_denom > 0, "denominator must be above 0");
        sellContributionRatio = rdiv(_nom, _denom);
        emit SellContributionRatioUpdated(msg.sender, _nom, _denom);
    }

    /**
     * @dev Calculate the amount after contribution during the sell action. There is a
     * `sellContributionRatio` percent contribution
     * @param _marketMaker The market maker address
     * @param _reserve The reserve address
     * @param _contributer The contributer address
     * @param _token The token to convert from
     * @param _gdAmount The total GD amount to contribute from
     * @return (contributionAmount) The contribution amount for sell
     */
    function calculateContribution(
        GoodMarketMaker _marketMaker,
        GoodReserveCDai _reserve,
        address _contributer,
        ERC20 _token,
        uint256 _gdAmount
    ) external view returns (uint256) {
        uint256 decimalsDiff = uint256(27).sub(2); // 2 gooddollar decimals
        uint256 contributionAmount = rmul(
            _gdAmount.mul(10**decimalsDiff), // expand to e27 precision
            sellContributionRatio
        )
            .div(10**decimalsDiff); // return to e2 precision
        require(_gdAmount > contributionAmount, "Calculation error");
        return contributionAmount;
    }
}