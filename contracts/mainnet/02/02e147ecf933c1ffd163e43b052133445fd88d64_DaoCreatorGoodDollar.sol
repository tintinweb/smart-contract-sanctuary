/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

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

// File: @daostack/arc/contracts/controller/Controller.sol

pragma solidity ^0.5.4;





/**
 * @title Controller contract
 * @dev A controller controls the organizations tokens, reputation and avatar.
 * It is subject to a set of schemes and constraints that determine its behavior.
 * Each scheme has it own parameters and operation permissions.
 */
contract Controller is ControllerInterface {

    struct Scheme {
        bytes32 paramsHash;  // a hash "configuration" of the scheme
        bytes4  permissions; // A bitwise flags of permissions,
                             // All 0: Not registered,
                             // 1st bit: Flag if the scheme is registered,
                             // 2nd bit: Scheme can register other schemes
                             // 3rd bit: Scheme can add/remove global constraints
                             // 4th bit: Scheme can upgrade the controller
                             // 5th bit: Scheme can call genericCall on behalf of
                             //          the organization avatar
    }

    struct GlobalConstraint {
        address gcAddress;
        bytes32 params;
    }

    struct GlobalConstraintRegister {
        bool isRegistered; //is registered
        uint256 index;    //index at globalConstraints
    }

    mapping(address=>Scheme) public schemes;

    Avatar public avatar;
    DAOToken public nativeToken;
    Reputation public nativeReputation;
  // newController will point to the new controller after the present controller is upgraded
    address public newController;
  // globalConstraintsPre that determine pre conditions for all actions on the controller

    GlobalConstraint[] public globalConstraintsPre;
  // globalConstraintsPost that determine post conditions for all actions on the controller
    GlobalConstraint[] public globalConstraintsPost;
  // globalConstraintsRegisterPre indicate if a globalConstraints is registered as a pre global constraint
    mapping(address=>GlobalConstraintRegister) public globalConstraintsRegisterPre;
  // globalConstraintsRegisterPost indicate if a globalConstraints is registered as a post global constraint
    mapping(address=>GlobalConstraintRegister) public globalConstraintsRegisterPost;

    event MintReputation (address indexed _sender, address indexed _to, uint256 _amount);
    event BurnReputation (address indexed _sender, address indexed _from, uint256 _amount);
    event MintTokens (address indexed _sender, address indexed _beneficiary, uint256 _amount);
    event RegisterScheme (address indexed _sender, address indexed _scheme);
    event UnregisterScheme (address indexed _sender, address indexed _scheme);
    event UpgradeController(address indexed _oldController, address _newController);

    event AddGlobalConstraint(
        address indexed _globalConstraint,
        bytes32 _params,
        GlobalConstraintInterface.CallPhase _when);

    event RemoveGlobalConstraint(address indexed _globalConstraint, uint256 _index, bool _isPre);

    constructor( Avatar _avatar) public {
        avatar = _avatar;
        nativeToken = avatar.nativeToken();
        nativeReputation = avatar.nativeReputation();
        schemes[msg.sender] = Scheme({paramsHash: bytes32(0), permissions: bytes4(0x0000001F)});
    }

  // Do not allow mistaken calls:
   // solhint-disable-next-line payable-fallback
    function() external {
        revert();
    }

  // Modifiers:
    modifier onlyRegisteredScheme() {
        require(schemes[msg.sender].permissions&bytes4(0x00000001) == bytes4(0x00000001));
        _;
    }

    modifier onlyRegisteringSchemes() {
        require(schemes[msg.sender].permissions&bytes4(0x00000002) == bytes4(0x00000002));
        _;
    }

    modifier onlyGlobalConstraintsScheme() {
        require(schemes[msg.sender].permissions&bytes4(0x00000004) == bytes4(0x00000004));
        _;
    }

    modifier onlyUpgradingScheme() {
        require(schemes[msg.sender].permissions&bytes4(0x00000008) == bytes4(0x00000008));
        _;
    }

    modifier onlyGenericCallScheme() {
        require(schemes[msg.sender].permissions&bytes4(0x00000010) == bytes4(0x00000010));
        _;
    }

    modifier onlyMetaDataScheme() {
        require(schemes[msg.sender].permissions&bytes4(0x00000010) == bytes4(0x00000010));
        _;
    }

    modifier onlySubjectToConstraint(bytes32 func) {
        uint256 idx;
        for (idx = 0; idx < globalConstraintsPre.length; idx++) {
            require(
            (GlobalConstraintInterface(globalConstraintsPre[idx].gcAddress))
            .pre(msg.sender, globalConstraintsPre[idx].params, func));
        }
        _;
        for (idx = 0; idx < globalConstraintsPost.length; idx++) {
            require(
            (GlobalConstraintInterface(globalConstraintsPost[idx].gcAddress))
            .post(msg.sender, globalConstraintsPost[idx].params, func));
        }
    }

    modifier isAvatarValid(address _avatar) {
        require(_avatar == address(avatar));
        _;
    }

    /**
     * @dev Mint `_amount` of reputation that are assigned to `_to` .
     * @param  _amount amount of reputation to mint
     * @param _to beneficiary address
     * @return bool which represents a success
     */
    function mintReputation(uint256 _amount, address _to, address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("mintReputation")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit MintReputation(msg.sender, _to, _amount);
        return nativeReputation.mint(_to, _amount);
    }

    /**
     * @dev Burns `_amount` of reputation from `_from`
     * @param _amount amount of reputation to burn
     * @param _from The address that will lose the reputation
     * @return bool which represents a success
     */
    function burnReputation(uint256 _amount, address _from, address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("burnReputation")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit BurnReputation(msg.sender, _from, _amount);
        return nativeReputation.burn(_from, _amount);
    }

    /**
     * @dev mint tokens .
     * @param  _amount amount of token to mint
     * @param _beneficiary beneficiary address
     * @return bool which represents a success
     */
    function mintTokens(uint256 _amount, address _beneficiary, address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("mintTokens")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit MintTokens(msg.sender, _beneficiary, _amount);
        return nativeToken.mint(_beneficiary, _amount);
    }

  /**
   * @dev register a scheme
   * @param _scheme the address of the scheme
   * @param _paramsHash a hashed configuration of the usage of the scheme
   * @param _permissions the permissions the new scheme will have
   * @return bool which represents a success
   */
    function registerScheme(address _scheme, bytes32 _paramsHash, bytes4 _permissions, address _avatar)
    external
    onlyRegisteringSchemes
    onlySubjectToConstraint("registerScheme")
    isAvatarValid(_avatar)
    returns(bool)
    {

        Scheme memory scheme = schemes[_scheme];

    // Check scheme has at least the permissions it is changing, and at least the current permissions:
    // Implementation is a bit messy. One must recall logic-circuits ^^

    // produces non-zero if sender does not have all of the perms that are changing between old and new
        require(bytes4(0x0000001f)&(_permissions^scheme.permissions)&(~schemes[msg.sender].permissions) == bytes4(0));

    // produces non-zero if sender does not have all of the perms in the old scheme
        require(bytes4(0x0000001f)&(scheme.permissions&(~schemes[msg.sender].permissions)) == bytes4(0));

    // Add or change the scheme:
        schemes[_scheme].paramsHash = _paramsHash;
        schemes[_scheme].permissions = _permissions|bytes4(0x00000001);
        emit RegisterScheme(msg.sender, _scheme);
        return true;
    }

    /**
     * @dev unregister a scheme
     * @param _scheme the address of the scheme
     * @return bool which represents a success
     */
    function unregisterScheme( address _scheme, address _avatar)
    external
    onlyRegisteringSchemes
    onlySubjectToConstraint("unregisterScheme")
    isAvatarValid(_avatar)
    returns(bool)
    {
    //check if the scheme is registered
        if (_isSchemeRegistered(_scheme) == false) {
            return false;
        }
    // Check the unregistering scheme has enough permissions:
        require(bytes4(0x0000001f)&(schemes[_scheme].permissions&(~schemes[msg.sender].permissions)) == bytes4(0));

    // Unregister:
        emit UnregisterScheme(msg.sender, _scheme);
        delete schemes[_scheme];
        return true;
    }

    /**
     * @dev unregister the caller's scheme
     * @return bool which represents a success
     */
    function unregisterSelf(address _avatar) external isAvatarValid(_avatar) returns(bool) {
        if (_isSchemeRegistered(msg.sender) == false) {
            return false;
        }
        delete schemes[msg.sender];
        emit UnregisterScheme(msg.sender, msg.sender);
        return true;
    }

    /**
     * @dev add or update Global Constraint
     * @param _globalConstraint the address of the global constraint to be added.
     * @param _params the constraint parameters hash.
     * @return bool which represents a success
     */
    function addGlobalConstraint(address _globalConstraint, bytes32 _params, address _avatar)
    external
    onlyGlobalConstraintsScheme
    isAvatarValid(_avatar)
    returns(bool)
    {
        GlobalConstraintInterface.CallPhase when = GlobalConstraintInterface(_globalConstraint).when();
        if ((when == GlobalConstraintInterface.CallPhase.Pre)||
            (when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            if (!globalConstraintsRegisterPre[_globalConstraint].isRegistered) {
                globalConstraintsPre.push(GlobalConstraint(_globalConstraint, _params));
                globalConstraintsRegisterPre[_globalConstraint] =
                GlobalConstraintRegister(true, globalConstraintsPre.length-1);
            }else {
                globalConstraintsPre[globalConstraintsRegisterPre[_globalConstraint].index].params = _params;
            }
        }
        if ((when == GlobalConstraintInterface.CallPhase.Post)||
            (when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            if (!globalConstraintsRegisterPost[_globalConstraint].isRegistered) {
                globalConstraintsPost.push(GlobalConstraint(_globalConstraint, _params));
                globalConstraintsRegisterPost[_globalConstraint] =
                GlobalConstraintRegister(true, globalConstraintsPost.length-1);
            }else {
                globalConstraintsPost[globalConstraintsRegisterPost[_globalConstraint].index].params = _params;
            }
        }
        emit AddGlobalConstraint(_globalConstraint, _params, when);
        return true;
    }

    /**
     * @dev remove Global Constraint
     * @param _globalConstraint the address of the global constraint to be remove.
     * @return bool which represents a success
     */
     // solhint-disable-next-line code-complexity
    function removeGlobalConstraint (address _globalConstraint, address _avatar)
    external
    onlyGlobalConstraintsScheme
    isAvatarValid(_avatar)
    returns(bool)
    {
        GlobalConstraintRegister memory globalConstraintRegister;
        GlobalConstraint memory globalConstraint;
        GlobalConstraintInterface.CallPhase when = GlobalConstraintInterface(_globalConstraint).when();
        bool retVal = false;

        if ((when == GlobalConstraintInterface.CallPhase.Pre)||
            (when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            globalConstraintRegister = globalConstraintsRegisterPre[_globalConstraint];
            if (globalConstraintRegister.isRegistered) {
                if (globalConstraintRegister.index < globalConstraintsPre.length-1) {
                    globalConstraint = globalConstraintsPre[globalConstraintsPre.length-1];
                    globalConstraintsPre[globalConstraintRegister.index] = globalConstraint;
                    globalConstraintsRegisterPre[globalConstraint.gcAddress].index = globalConstraintRegister.index;
                }
                globalConstraintsPre.length--;
                delete globalConstraintsRegisterPre[_globalConstraint];
                retVal = true;
            }
        }
        if ((when == GlobalConstraintInterface.CallPhase.Post)||
            (when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            globalConstraintRegister = globalConstraintsRegisterPost[_globalConstraint];
            if (globalConstraintRegister.isRegistered) {
                if (globalConstraintRegister.index < globalConstraintsPost.length-1) {
                    globalConstraint = globalConstraintsPost[globalConstraintsPost.length-1];
                    globalConstraintsPost[globalConstraintRegister.index] = globalConstraint;
                    globalConstraintsRegisterPost[globalConstraint.gcAddress].index = globalConstraintRegister.index;
                }
                globalConstraintsPost.length--;
                delete globalConstraintsRegisterPost[_globalConstraint];
                retVal = true;
            }
        }
        if (retVal) {
            emit RemoveGlobalConstraint(
            _globalConstraint,
            globalConstraintRegister.index,
            when == GlobalConstraintInterface.CallPhase.Pre
            );
        }
        return retVal;
    }

  /**
    * @dev upgrade the Controller
    *      The function will trigger an event 'UpgradeController'.
    * @param  _newController the address of the new controller.
    * @return bool which represents a success
    */
    function upgradeController(address _newController, Avatar _avatar)
    external
    onlyUpgradingScheme
    isAvatarValid(address(_avatar))
    returns(bool)
    {
        require(newController == address(0));   // so the upgrade could be done once for a contract.
        require(_newController != address(0));
        newController = _newController;
        avatar.transferOwnership(_newController);
        require(avatar.owner() == _newController);
        if (nativeToken.owner() == address(this)) {
            nativeToken.transferOwnership(_newController);
            require(nativeToken.owner() == _newController);
        }
        if (nativeReputation.owner() == address(this)) {
            nativeReputation.transferOwnership(_newController);
            require(nativeReputation.owner() == _newController);
        }
        emit UpgradeController(address(this), newController);
        return true;
    }

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
    onlyGenericCallScheme
    onlySubjectToConstraint("genericCall")
    isAvatarValid(address(_avatar))
    returns (bool, bytes memory)
    {
        return avatar.genericCall(_contract, _data, _value);
    }

  /**
   * @dev send some ether
   * @param _amountInWei the amount of ether (in Wei) to send
   * @param _to address of the beneficiary
   * @return bool which represents a success
   */
    function sendEther(uint256 _amountInWei, address payable _to, Avatar _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("sendEther")
    isAvatarValid(address(_avatar))
    returns(bool)
    {
        return avatar.sendEther(_amountInWei, _to);
    }

    /**
    * @dev send some amount of arbitrary ERC20 Tokens
    * @param _externalToken the address of the Token Contract
    * @param _to address of the beneficiary
    * @param _value the amount of ether (in Wei) to send
    * @return bool which represents a success
    */
    function externalTokenTransfer(IERC20 _externalToken, address _to, uint256 _value, Avatar _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("externalTokenTransfer")
    isAvatarValid(address(_avatar))
    returns(bool)
    {
        return avatar.externalTokenTransfer(_externalToken, _to, _value);
    }

    /**
    * @dev transfer token "from" address "to" address
    *      One must to approve the amount of tokens which can be spend from the
    *      "from" account.This can be done using externalTokenApprove.
    * @param _externalToken the address of the Token Contract
    * @param _from address of the account to send from
    * @param _to address of the beneficiary
    * @param _value the amount of ether (in Wei) to send
    * @return bool which represents a success
    */
    function externalTokenTransferFrom(
    IERC20 _externalToken,
    address _from,
    address _to,
    uint256 _value,
    Avatar _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("externalTokenTransferFrom")
    isAvatarValid(address(_avatar))
    returns(bool)
    {
        return avatar.externalTokenTransferFrom(_externalToken, _from, _to, _value);
    }

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
    onlyRegisteredScheme
    onlySubjectToConstraint("externalTokenIncreaseApproval")
    isAvatarValid(address(_avatar))
    returns(bool)
    {
        return avatar.externalTokenApproval(_externalToken, _spender, _value);
    }

    /**
    * @dev metaData emits an event with a string, should contain the hash of some meta data.
    * @param _metaData a string representing a hash of the meta data
    * @param _avatar Avatar
    * @return bool which represents a success
    */
    function metaData(string calldata _metaData, Avatar _avatar)
        external
        onlyMetaDataScheme
        isAvatarValid(address(_avatar))
        returns(bool)
        {
        return avatar.metaData(_metaData);
    }

    /**
     * @dev getNativeReputation
     * @param _avatar the organization avatar.
     * @return organization native reputation
     */
    function getNativeReputation(address _avatar) external isAvatarValid(_avatar) view returns(address) {
        return address(nativeReputation);
    }

    function isSchemeRegistered(address _scheme, address _avatar) external isAvatarValid(_avatar) view returns(bool) {
        return _isSchemeRegistered(_scheme);
    }

    function getSchemeParameters(address _scheme, address _avatar)
    external
    isAvatarValid(_avatar)
    view
    returns(bytes32)
    {
        return schemes[_scheme].paramsHash;
    }

    function getSchemePermissions(address _scheme, address _avatar)
    external
    isAvatarValid(_avatar)
    view
    returns(bytes4)
    {
        return schemes[_scheme].permissions;
    }

    function getGlobalConstraintParameters(address _globalConstraint, address) external view returns(bytes32) {

        GlobalConstraintRegister memory register = globalConstraintsRegisterPre[_globalConstraint];

        if (register.isRegistered) {
            return globalConstraintsPre[register.index].params;
        }

        register = globalConstraintsRegisterPost[_globalConstraint];

        if (register.isRegistered) {
            return globalConstraintsPost[register.index].params;
        }
    }

   /**
    * @dev globalConstraintsCount return the global constraint pre and post count
    * @return uint256 globalConstraintsPre count.
    * @return uint256 globalConstraintsPost count.
    */
    function globalConstraintsCount(address _avatar)
        external
        isAvatarValid(_avatar)
        view
        returns(uint, uint)
        {
        return (globalConstraintsPre.length, globalConstraintsPost.length);
    }

    function isGlobalConstraintRegistered(address _globalConstraint, address _avatar)
        external
        isAvatarValid(_avatar)
        view
        returns(bool)
        {
        return (globalConstraintsRegisterPre[_globalConstraint].isRegistered ||
                globalConstraintsRegisterPost[_globalConstraint].isRegistered);
    }

    function _isSchemeRegistered(address _scheme) private view returns(bool) {
        return (schemes[_scheme].permissions&bytes4(0x00000001) != bytes4(0));
    }
}

// File: @daostack/infra/contracts/votingMachines/IntVoteInterface.sol

pragma solidity ^0.5.4;

interface IntVoteInterface {
    //When implementing this interface please do not only override function and modifier,
    //but also to keep the modifiers on the overridden functions.
    modifier onlyProposalOwner(bytes32 _proposalId) {revert(); _;}
    modifier votable(bytes32 _proposalId) {revert(); _;}

    event NewProposal(
        bytes32 indexed _proposalId,
        address indexed _organization,
        uint256 _numOfChoices,
        address _proposer,
        bytes32 _paramsHash
    );

    event ExecuteProposal(bytes32 indexed _proposalId,
        address indexed _organization,
        uint256 _decision,
        uint256 _totalReputation
    );

    event VoteProposal(
        bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _voter,
        uint256 _vote,
        uint256 _reputation
    );

    event CancelProposal(bytes32 indexed _proposalId, address indexed _organization );
    event CancelVoting(bytes32 indexed _proposalId, address indexed _organization, address indexed _voter);

    /**
     * @dev register a new proposal with the given parameters. Every proposal has a unique ID which is being
     * generated by calculating keccak256 of a incremented counter.
     * @param _numOfChoices number of voting choices
     * @param _proposalParameters defines the parameters of the voting machine used for this proposal
     * @param _proposer address
     * @param _organization address - if this address is zero the msg.sender will be used as the organization address.
     * @return proposal's id.
     */
    function propose(
        uint256 _numOfChoices,
        bytes32 _proposalParameters,
        address _proposer,
        address _organization
        ) external returns(bytes32);

    function vote(
        bytes32 _proposalId,
        uint256 _vote,
        uint256 _rep,
        address _voter
    )
    external
    returns(bool);

    function cancelVote(bytes32 _proposalId) external;

    function getNumberOfChoices(bytes32 _proposalId) external view returns(uint256);

    function isVotable(bytes32 _proposalId) external view returns(bool);

    /**
     * @dev voteStatus returns the reputation voted for a proposal for a specific voting choice.
     * @param _proposalId the ID of the proposal
     * @param _choice the index in the
     * @return voted reputation for the given choice
     */
    function voteStatus(bytes32 _proposalId, uint256 _choice) external view returns(uint256);

    /**
     * @dev isAbstainAllow returns if the voting machine allow abstain (0)
     * @return bool true or false
     */
    function isAbstainAllow() external pure returns(bool);

    /**
     * @dev getAllowedRangeOfChoices returns the allowed range of choices for a voting machine.
     * @return min - minimum number of choices
               max - maximum number of choices
     */
    function getAllowedRangeOfChoices() external pure returns(uint256 min, uint256 max);
}

// File: @daostack/infra/contracts/votingMachines/VotingMachineCallbacksInterface.sol

pragma solidity ^0.5.4;


interface VotingMachineCallbacksInterface {
    function mintReputation(uint256 _amount, address _beneficiary, bytes32 _proposalId) external returns(bool);
    function burnReputation(uint256 _amount, address _owner, bytes32 _proposalId) external returns(bool);

    function stakingTokenTransfer(IERC20 _stakingToken, address _beneficiary, uint256 _amount, bytes32 _proposalId)
    external
    returns(bool);

    function getTotalReputationSupply(bytes32 _proposalId) external view returns(uint256);
    function reputationOf(address _owner, bytes32 _proposalId) external view returns(uint256);
    function balanceOfStakingToken(IERC20 _stakingToken, bytes32 _proposalId) external view returns(uint256);
}

// File: @daostack/arc/contracts/universalSchemes/UniversalSchemeInterface.sol

pragma solidity ^0.5.4;


contract UniversalSchemeInterface {

    function getParametersFromController(Avatar _avatar) internal view returns(bytes32);
    
}

// File: @daostack/arc/contracts/universalSchemes/UniversalScheme.sol

pragma solidity ^0.5.4;





contract UniversalScheme is UniversalSchemeInterface {
    /**
    *  @dev get the parameters for the current scheme from the controller
    */
    function getParametersFromController(Avatar _avatar) internal view returns(bytes32) {
        require(ControllerInterface(_avatar.owner()).isSchemeRegistered(address(this), address(_avatar)),
        "scheme is not registered");
        return ControllerInterface(_avatar.owner()).getSchemeParameters(address(this), address(_avatar));
    }
}

// File: openzeppelin-solidity/contracts/cryptography/ECDSA.sol

pragma solidity ^0.5.0;

/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
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

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// File: @daostack/infra/contracts/libs/RealMath.sol

pragma solidity ^0.5.4;

/**
 * RealMath: fixed-point math library, based on fractional and integer parts.
 * Using uint256 as real216x40, which isn't in Solidity yet.
 * Internally uses the wider uint256 for some math.
 *
 * Note that for addition, subtraction, and mod (%), you should just use the
 * built-in Solidity operators. Functions for these operations are not provided.
 *
 */


library RealMath {

    /**
     * How many total bits are there?
     */
    uint256 constant private REAL_BITS = 256;

    /**
     * How many fractional bits are there?
     */
    uint256 constant private REAL_FBITS = 40;

    /**
     * What's the first non-fractional bit
     */
    uint256 constant private REAL_ONE = uint256(1) << REAL_FBITS;

    /**
     * Raise a real number to any positive integer power
     */
    function pow(uint256 realBase, uint256 exponent) internal pure returns (uint256) {

        uint256 tempRealBase = realBase;
        uint256 tempExponent = exponent;

        // Start with the 0th power
        uint256 realResult = REAL_ONE;
        while (tempExponent != 0) {
            // While there are still bits set
            if ((tempExponent & 0x1) == 0x1) {
                // If the low bit is set, multiply in the (many-times-squared) base
                realResult = mul(realResult, tempRealBase);
            }
                // Shift off the low bit
            tempExponent = tempExponent >> 1;
            if (tempExponent != 0) {
                // Do the squaring
                tempRealBase = mul(tempRealBase, tempRealBase);
            }
        }

        // Return the final result.
        return realResult;
    }

    /**
     * Create a real from a rational fraction.
     */
    function fraction(uint216 numerator, uint216 denominator) internal pure returns (uint256) {
        return div(uint256(numerator) * REAL_ONE, uint256(denominator) * REAL_ONE);
    }

    /**
     * Multiply one real by another. Truncates overflows.
     */
    function mul(uint256 realA, uint256 realB) private pure returns (uint256) {
        // When multiplying fixed point in x.y and z.w formats we get (x+z).(y+w) format.
        // So we just have to clip off the extra REAL_FBITS fractional bits.
        uint256 res = realA * realB;
        require(res/realA == realB, "RealMath mul overflow");
        return (res >> REAL_FBITS);
    }

    /**
     * Divide one real by another real. Truncates overflows.
     */
    function div(uint256 realNumerator, uint256 realDenominator) private pure returns (uint256) {
        // We use the reverse of the multiplication trick: convert numerator from
        // x.y to (x+z).(y+w) fixed point, then divide by denom in z.w fixed point.
        return uint256((uint256(realNumerator) * REAL_ONE) / uint256(realDenominator));
    }

}

// File: @daostack/infra/contracts/votingMachines/ProposalExecuteInterface.sol

pragma solidity ^0.5.4;

interface ProposalExecuteInterface {
    function executeProposal(bytes32 _proposalId, int _decision) external returns(bool);
}

// File: openzeppelin-solidity/contracts/math/Math.sol

pragma solidity ^0.5.0;

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    /**
    * @dev Returns the largest of two numbers.
    */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
    * @dev Returns the smallest of two numbers.
    */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
    * @dev Calculates the average of two numbers. Since these are integers,
    * averages of an even and odd number cannot be represented, and will be
    * rounded down.
    */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @daostack/infra/contracts/votingMachines/GenesisProtocolLogic.sol

pragma solidity ^0.5.4;











/**
 * @title GenesisProtocol implementation -an organization's voting machine scheme.
 */
contract GenesisProtocolLogic is IntVoteInterface {
    using SafeMath for uint256;
    using Math for uint256;
    using RealMath for uint216;
    using RealMath for uint256;
    using Address for address;

    enum ProposalState { None, ExpiredInQueue, Executed, Queued, PreBoosted, Boosted, QuietEndingPeriod}
    enum ExecutionState { None, QueueBarCrossed, QueueTimeOut, PreBoostedBarCrossed, BoostedTimeOut, BoostedBarCrossed}

    //Organization's parameters
    struct Parameters {
        uint256 queuedVoteRequiredPercentage; // the absolute vote percentages bar.
        uint256 queuedVotePeriodLimit; //the time limit for a proposal to be in an absolute voting mode.
        uint256 boostedVotePeriodLimit; //the time limit for a proposal to be in boost mode.
        uint256 preBoostedVotePeriodLimit; //the time limit for a proposal
                                          //to be in an preparation state (stable) before boosted.
        uint256 thresholdConst; //constant  for threshold calculation .
                                //threshold =thresholdConst ** (numberOfBoostedProposals)
        uint256 limitExponentValue;// an upper limit for numberOfBoostedProposals
                                   //in the threshold calculation to prevent overflow
        uint256 quietEndingPeriod; //quite ending period
        uint256 proposingRepReward;//proposer reputation reward.
        uint256 votersReputationLossRatio;//Unsuccessful pre booster
                                          //voters lose votersReputationLossRatio% of their reputation.
        uint256 minimumDaoBounty;
        uint256 daoBountyConst;//The DAO downstake for each proposal is calculate according to the formula
                               //(daoBountyConst * averageBoostDownstakes)/100 .
        uint256 activationTime;//the point in time after which proposals can be created.
        //if this address is set so only this address is allowed to vote of behalf of someone else.
        address voteOnBehalf;
    }

    struct Voter {
        uint256 vote; // YES(1) ,NO(2)
        uint256 reputation; // amount of voter's reputation
        bool preBoosted;
    }

    struct Staker {
        uint256 vote; // YES(1) ,NO(2)
        uint256 amount; // amount of staker's stake
        uint256 amount4Bounty;// amount of staker's stake used for bounty reward calculation.
    }

    struct Proposal {
        bytes32 organizationId; // the organization unique identifier the proposal is target to.
        address callbacks;    // should fulfill voting callbacks interface.
        ProposalState state;
        uint256 winningVote; //the winning vote.
        address proposer;
        //the proposal boosted period limit . it is updated for the case of quiteWindow mode.
        uint256 currentBoostedVotePeriodLimit;
        bytes32 paramsHash;
        uint256 daoBountyRemain; //use for checking sum zero bounty claims.it is set at the proposing time.
        uint256 daoBounty;
        uint256 totalStakes;// Total number of tokens staked which can be redeemable by stakers.
        uint256 confidenceThreshold;
        //The percentage from upper stakes which the caller for the expiration was given.
        uint256 expirationCallBountyPercentage;
        uint[3] times; //times[0] - submittedTime
                       //times[1] - boostedPhaseTime
                       //times[2] -preBoostedPhaseTime;
        bool daoRedeemItsWinnings;
        //      vote      reputation
        mapping(uint256   =>  uint256    ) votes;
        //      vote      reputation
        mapping(uint256   =>  uint256    ) preBoostedVotes;
        //      address     voter
        mapping(address =>  Voter    ) voters;
        //      vote        stakes
        mapping(uint256   =>  uint256    ) stakes;
        //      address  staker
        mapping(address  => Staker   ) stakers;
    }

    event Stake(bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _staker,
        uint256 _vote,
        uint256 _amount
    );

    event Redeem(bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _beneficiary,
        uint256 _amount
    );

    event RedeemDaoBounty(bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _beneficiary,
        uint256 _amount
    );

    event RedeemReputation(bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _beneficiary,
        uint256 _amount
    );

    event StateChange(bytes32 indexed _proposalId, ProposalState _proposalState);
    event GPExecuteProposal(bytes32 indexed _proposalId, ExecutionState _executionState);
    event ExpirationCallBounty(bytes32 indexed _proposalId, address indexed _beneficiary, uint256 _amount);
    event ConfidenceLevelChange(bytes32 indexed _proposalId, uint256 _confidenceThreshold);

    mapping(bytes32=>Parameters) public parameters;  // A mapping from hashes to parameters
    mapping(bytes32=>Proposal) public proposals; // Mapping from the ID of the proposal to the proposal itself.
    mapping(bytes32=>uint) public orgBoostedProposalsCnt;
           //organizationId => organization
    mapping(bytes32        => address     ) public organizations;
          //organizationId => averageBoostDownstakes
    mapping(bytes32           => uint256              ) public averagesDownstakesOfBoosted;
    uint256 constant public NUM_OF_CHOICES = 2;
    uint256 constant public NO = 2;
    uint256 constant public YES = 1;
    uint256 public proposalsCnt; // Total number of proposals
    IERC20 public stakingToken;
    address constant private GEN_TOKEN_ADDRESS = 0x543Ff227F64Aa17eA132Bf9886cAb5DB55DCAddf;
    uint256 constant private MAX_BOOSTED_PROPOSALS = 4096;

    /**
     * @dev Constructor
     */
    constructor(IERC20 _stakingToken) public {
      //The GEN token (staking token) address is hard coded in the contract by GEN_TOKEN_ADDRESS .
      //This will work for a network which already hosted the GEN token on this address (e.g mainnet).
      //If such contract address does not exist in the network (e.g ganache)
      //the contract will use the _stakingToken param as the
      //staking token address.
        if (address(GEN_TOKEN_ADDRESS).isContract()) {
            stakingToken = IERC20(GEN_TOKEN_ADDRESS);
        } else {
            stakingToken = _stakingToken;
        }
    }

  /**
   * @dev Check that the proposal is votable
   * a proposal is votable if it is in one of the following states:
   *  PreBoosted,Boosted,QuietEndingPeriod or Queued
   */
    modifier votable(bytes32 _proposalId) {
        require(_isVotable(_proposalId));
        _;
    }

    /**
     * @dev register a new proposal with the given parameters. Every proposal has a unique ID which is being
     * generated by calculating keccak256 of a incremented counter.
     * @param _paramsHash parameters hash
     * @param _proposer address
     * @param _organization address
     */
    function propose(uint256, bytes32 _paramsHash, address _proposer, address _organization)
        external
        returns(bytes32)
    {
      // solhint-disable-next-line not-rely-on-time
        require(now > parameters[_paramsHash].activationTime, "not active yet");
        //Check parameters existence.
        require(parameters[_paramsHash].queuedVoteRequiredPercentage >= 50);
        // Generate a unique ID:
        bytes32 proposalId = keccak256(abi.encodePacked(this, proposalsCnt));
        proposalsCnt = proposalsCnt.add(1);
         // Open proposal:
        Proposal memory proposal;
        proposal.callbacks = msg.sender;
        proposal.organizationId = keccak256(abi.encodePacked(msg.sender, _organization));

        proposal.state = ProposalState.Queued;
        // solhint-disable-next-line not-rely-on-time
        proposal.times[0] = now;//submitted time
        proposal.currentBoostedVotePeriodLimit = parameters[_paramsHash].boostedVotePeriodLimit;
        proposal.proposer = _proposer;
        proposal.winningVote = NO;
        proposal.paramsHash = _paramsHash;
        if (organizations[proposal.organizationId] == address(0)) {
            if (_organization == address(0)) {
                organizations[proposal.organizationId] = msg.sender;
            } else {
                organizations[proposal.organizationId] = _organization;
            }
        }
        //calc dao bounty
        uint256 daoBounty =
        parameters[_paramsHash].daoBountyConst.mul(averagesDownstakesOfBoosted[proposal.organizationId]).div(100);
        if (daoBounty < parameters[_paramsHash].minimumDaoBounty) {
            proposal.daoBountyRemain = parameters[_paramsHash].minimumDaoBounty;
        } else {
            proposal.daoBountyRemain = daoBounty;
        }
        proposal.totalStakes = proposal.daoBountyRemain;
        proposals[proposalId] = proposal;
        proposals[proposalId].stakes[NO] = proposal.daoBountyRemain;//dao downstake on the proposal

        emit NewProposal(proposalId, organizations[proposal.organizationId], NUM_OF_CHOICES, _proposer, _paramsHash);
        return proposalId;
    }

    /**
      * @dev executeBoosted try to execute a boosted or QuietEndingPeriod proposal if it is expired
      * @param _proposalId the id of the proposal
      * @return uint256 expirationCallBounty the bounty amount for the expiration call
     */
    function executeBoosted(bytes32 _proposalId) external returns(uint256 expirationCallBounty) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Boosted || proposal.state == ProposalState.QuietEndingPeriod,
        "proposal state in not Boosted nor QuietEndingPeriod");
        require(_execute(_proposalId), "proposal need to expire");
        uint256 expirationCallBountyPercentage =
        // solhint-disable-next-line not-rely-on-time
        (uint(1).add(now.sub(proposal.currentBoostedVotePeriodLimit.add(proposal.times[1])).div(15)));
        if (expirationCallBountyPercentage > 100) {
            expirationCallBountyPercentage = 100;
        }
        proposal.expirationCallBountyPercentage = expirationCallBountyPercentage;
        expirationCallBounty = expirationCallBountyPercentage.mul(proposal.stakes[YES]).div(100);
        require(stakingToken.transfer(msg.sender, expirationCallBounty), "transfer to msg.sender failed");
        emit ExpirationCallBounty(_proposalId, msg.sender, expirationCallBounty);
    }

    /**
     * @dev hash the parameters, save them if necessary, and return the hash value
     * @param _params a parameters array
     *    _params[0] - _queuedVoteRequiredPercentage,
     *    _params[1] - _queuedVotePeriodLimit, //the time limit for a proposal to be in an absolute voting mode.
     *    _params[2] - _boostedVotePeriodLimit, //the time limit for a proposal to be in an relative voting mode.
     *    _params[3] - _preBoostedVotePeriodLimit, //the time limit for a proposal to be in an preparation
     *                  state (stable) before boosted.
     *    _params[4] -_thresholdConst
     *    _params[5] -_quietEndingPeriod
     *    _params[6] -_proposingRepReward
     *    _params[7] -_votersReputationLossRatio
     *    _params[8] -_minimumDaoBounty
     *    _params[9] -_daoBountyConst
     *    _params[10] -_activationTime
     * @param _voteOnBehalf - authorized to vote on behalf of others.
    */
    function setParameters(
        uint[11] calldata _params, //use array here due to stack too deep issue.
        address _voteOnBehalf
    )
    external
    returns(bytes32)
    {
        require(_params[0] <= 100 && _params[0] >= 50, "50 <= queuedVoteRequiredPercentage <= 100");
        require(_params[4] <= 16000 && _params[4] > 1000, "1000 < thresholdConst <= 16000");
        require(_params[7] <= 100, "votersReputationLossRatio <= 100");
        require(_params[2] >= _params[5], "boostedVotePeriodLimit >= quietEndingPeriod");
        require(_params[8] > 0, "minimumDaoBounty should be > 0");
        require(_params[9] > 0, "daoBountyConst should be > 0");

        bytes32 paramsHash = getParametersHash(_params, _voteOnBehalf);
        //set a limit for power for a given alpha to prevent overflow
        uint256 limitExponent = 172;//for alpha less or equal 2
        uint256 j = 2;
        for (uint256 i = 2000; i < 16000; i = i*2) {
            if ((_params[4] > i) && (_params[4] <= i*2)) {
                limitExponent = limitExponent/j;
                break;
            }
            j++;
        }

        parameters[paramsHash] = Parameters({
            queuedVoteRequiredPercentage: _params[0],
            queuedVotePeriodLimit: _params[1],
            boostedVotePeriodLimit: _params[2],
            preBoostedVotePeriodLimit: _params[3],
            thresholdConst:uint216(_params[4]).fraction(uint216(1000)),
            limitExponentValue:limitExponent,
            quietEndingPeriod: _params[5],
            proposingRepReward: _params[6],
            votersReputationLossRatio:_params[7],
            minimumDaoBounty:_params[8],
            daoBountyConst:_params[9],
            activationTime:_params[10],
            voteOnBehalf:_voteOnBehalf
        });
        return paramsHash;
    }

    /**
     * @dev redeem a reward for a successful stake, vote or proposing.
     * The function use a beneficiary address as a parameter (and not msg.sender) to enable
     * users to redeem on behalf of someone else.
     * @param _proposalId the ID of the proposal
     * @param _beneficiary - the beneficiary address
     * @return rewards -
     *           [0] stakerTokenReward
     *           [1] voterReputationReward
     *           [2] proposerReputationReward
     */
     // solhint-disable-next-line function-max-lines,code-complexity
    function redeem(bytes32 _proposalId, address _beneficiary) public returns (uint[3] memory rewards) {
        Proposal storage proposal = proposals[_proposalId];
        require((proposal.state == ProposalState.Executed)||(proposal.state == ProposalState.ExpiredInQueue),
        "Proposal should be Executed or ExpiredInQueue");
        Parameters memory params = parameters[proposal.paramsHash];
        uint256 lostReputation;
        if (proposal.winningVote == YES) {
            lostReputation = proposal.preBoostedVotes[NO];
        } else {
            lostReputation = proposal.preBoostedVotes[YES];
        }
        lostReputation = (lostReputation.mul(params.votersReputationLossRatio))/100;
        //as staker
        Staker storage staker = proposal.stakers[_beneficiary];
        uint256 totalStakes = proposal.stakes[NO].add(proposal.stakes[YES]);
        uint256 totalWinningStakes = proposal.stakes[proposal.winningVote];

        if (staker.amount > 0) {
            uint256 totalStakesLeftAfterCallBounty =
            totalStakes.sub(proposal.expirationCallBountyPercentage.mul(proposal.stakes[YES]).div(100));
            if (proposal.state == ProposalState.ExpiredInQueue) {
                //Stakes of a proposal that expires in Queue are sent back to stakers
                rewards[0] = staker.amount;
            } else if (staker.vote == proposal.winningVote) {
                if (staker.vote == YES) {
                    if (proposal.daoBounty < totalStakesLeftAfterCallBounty) {
                        uint256 _totalStakes = totalStakesLeftAfterCallBounty.sub(proposal.daoBounty);
                        rewards[0] = (staker.amount.mul(_totalStakes))/totalWinningStakes;
                    }
                } else {
                    rewards[0] = (staker.amount.mul(totalStakesLeftAfterCallBounty))/totalWinningStakes;
                }
            }
            staker.amount = 0;
        }
            //dao redeem its winnings
        if (proposal.daoRedeemItsWinnings == false &&
            _beneficiary == organizations[proposal.organizationId] &&
            proposal.state != ProposalState.ExpiredInQueue &&
            proposal.winningVote == NO) {
            rewards[0] =
            rewards[0].add((proposal.daoBounty.mul(totalStakes))/totalWinningStakes).sub(proposal.daoBounty);
            proposal.daoRedeemItsWinnings = true;
        }

        //as voter
        Voter storage voter = proposal.voters[_beneficiary];
        if ((voter.reputation != 0) && (voter.preBoosted)) {
            if (proposal.state == ProposalState.ExpiredInQueue) {
              //give back reputation for the voter
                rewards[1] = ((voter.reputation.mul(params.votersReputationLossRatio))/100);
            } else if (proposal.winningVote == voter.vote) {
                rewards[1] = ((voter.reputation.mul(params.votersReputationLossRatio))/100)
                .add((voter.reputation.mul(lostReputation))/proposal.preBoostedVotes[proposal.winningVote]);
            }
            voter.reputation = 0;
        }
        //as proposer
        if ((proposal.proposer == _beneficiary)&&(proposal.winningVote == YES)&&(proposal.proposer != address(0))) {
            rewards[2] = params.proposingRepReward;
            proposal.proposer = address(0);
        }
        if (rewards[0] != 0) {
            proposal.totalStakes = proposal.totalStakes.sub(rewards[0]);
            require(stakingToken.transfer(_beneficiary, rewards[0]), "transfer to beneficiary failed");
            emit Redeem(_proposalId, organizations[proposal.organizationId], _beneficiary, rewards[0]);
        }
        if (rewards[1].add(rewards[2]) != 0) {
            VotingMachineCallbacksInterface(proposal.callbacks)
            .mintReputation(rewards[1].add(rewards[2]), _beneficiary, _proposalId);
            emit RedeemReputation(
            _proposalId,
            organizations[proposal.organizationId],
            _beneficiary,
            rewards[1].add(rewards[2])
            );
        }
    }

    /**
     * @dev redeemDaoBounty a reward for a successful stake.
     * The function use a beneficiary address as a parameter (and not msg.sender) to enable
     * users to redeem on behalf of someone else.
     * @param _proposalId the ID of the proposal
     * @param _beneficiary - the beneficiary address
     * @return redeemedAmount - redeem token amount
     * @return potentialAmount - potential redeem token amount(if there is enough tokens bounty at the organization )
     */
    function redeemDaoBounty(bytes32 _proposalId, address _beneficiary)
    public
    returns(uint256 redeemedAmount, uint256 potentialAmount) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Executed);
        uint256 totalWinningStakes = proposal.stakes[proposal.winningVote];
        Staker storage staker = proposal.stakers[_beneficiary];
        if (
            (staker.amount4Bounty > 0)&&
            (staker.vote == proposal.winningVote)&&
            (proposal.winningVote == YES)&&
            (totalWinningStakes != 0)) {
            //as staker
                potentialAmount = (staker.amount4Bounty * proposal.daoBounty)/totalWinningStakes;
            }
        if ((potentialAmount != 0)&&
            (VotingMachineCallbacksInterface(proposal.callbacks)
            .balanceOfStakingToken(stakingToken, _proposalId) >= potentialAmount)) {
            staker.amount4Bounty = 0;
            proposal.daoBountyRemain = proposal.daoBountyRemain.sub(potentialAmount);
            require(
            VotingMachineCallbacksInterface(proposal.callbacks)
            .stakingTokenTransfer(stakingToken, _beneficiary, potentialAmount, _proposalId));
            redeemedAmount = potentialAmount;
            emit RedeemDaoBounty(_proposalId, organizations[proposal.organizationId], _beneficiary, redeemedAmount);
        }
    }

    /**
     * @dev shouldBoost check if a proposal should be shifted to boosted phase.
     * @param _proposalId the ID of the proposal
     * @return bool true or false.
     */
    function shouldBoost(bytes32 _proposalId) public view returns(bool) {
        Proposal memory proposal = proposals[_proposalId];
        return (_score(_proposalId) > threshold(proposal.paramsHash, proposal.organizationId));
    }

    /**
     * @dev threshold return the organization's score threshold which required by
     * a proposal to shift to boosted state.
     * This threshold is dynamically set and it depend on the number of boosted proposal.
     * @param _organizationId the organization identifier
     * @param _paramsHash the organization parameters hash
     * @return uint256 organization's score threshold as real number.
     */
    function threshold(bytes32 _paramsHash, bytes32 _organizationId) public view returns(uint256) {
        uint256 power = orgBoostedProposalsCnt[_organizationId];
        Parameters storage params = parameters[_paramsHash];

        if (power > params.limitExponentValue) {
            power = params.limitExponentValue;
        }

        return params.thresholdConst.pow(power);
    }

  /**
   * @dev hashParameters returns a hash of the given parameters
   */
    function getParametersHash(
        uint[11] memory _params,//use array here due to stack too deep issue.
        address _voteOnBehalf
    )
        public
        pure
        returns(bytes32)
        {
        //double call to keccak256 to avoid deep stack issue when call with too many params.
        return keccak256(
            abi.encodePacked(
            keccak256(
            abi.encodePacked(
                _params[0],
                _params[1],
                _params[2],
                _params[3],
                _params[4],
                _params[5],
                _params[6],
                _params[7],
                _params[8],
                _params[9],
                _params[10])
            ),
            _voteOnBehalf
        ));
    }

    /**
      * @dev execute check if the proposal has been decided, and if so, execute the proposal
      * @param _proposalId the id of the proposal
      * @return bool true - the proposal has been executed
      *              false - otherwise.
     */
     // solhint-disable-next-line function-max-lines,code-complexity
    function _execute(bytes32 _proposalId) internal votable(_proposalId) returns(bool) {
        Proposal storage proposal = proposals[_proposalId];
        Parameters memory params = parameters[proposal.paramsHash];
        Proposal memory tmpProposal = proposal;
        uint256 totalReputation =
        VotingMachineCallbacksInterface(proposal.callbacks).getTotalReputationSupply(_proposalId);
        //first divide by 100 to prevent overflow
        uint256 executionBar = (totalReputation/100) * params.queuedVoteRequiredPercentage;
        ExecutionState executionState = ExecutionState.None;
        uint256 averageDownstakesOfBoosted;
        uint256 confidenceThreshold;

        if (proposal.votes[proposal.winningVote] > executionBar) {
         // someone crossed the absolute vote execution bar.
            if (proposal.state == ProposalState.Queued) {
                executionState = ExecutionState.QueueBarCrossed;
            } else if (proposal.state == ProposalState.PreBoosted) {
                executionState = ExecutionState.PreBoostedBarCrossed;
            } else {
                executionState = ExecutionState.BoostedBarCrossed;
            }
            proposal.state = ProposalState.Executed;
        } else {
            if (proposal.state == ProposalState.Queued) {
                // solhint-disable-next-line not-rely-on-time
                if ((now - proposal.times[0]) >= params.queuedVotePeriodLimit) {
                    proposal.state = ProposalState.ExpiredInQueue;
                    proposal.winningVote = NO;
                    executionState = ExecutionState.QueueTimeOut;
                } else {
                    confidenceThreshold = threshold(proposal.paramsHash, proposal.organizationId);
                    if (_score(_proposalId) > confidenceThreshold) {
                        //change proposal mode to PreBoosted mode.
                        proposal.state = ProposalState.PreBoosted;
                        // solhint-disable-next-line not-rely-on-time
                        proposal.times[2] = now;
                        proposal.confidenceThreshold = confidenceThreshold;
                    }
                }
            }

            if (proposal.state == ProposalState.PreBoosted) {
                confidenceThreshold = threshold(proposal.paramsHash, proposal.organizationId);
              // solhint-disable-next-line not-rely-on-time
                if ((now - proposal.times[2]) >= params.preBoostedVotePeriodLimit) {
                    if (_score(_proposalId) > confidenceThreshold) {
                        if (orgBoostedProposalsCnt[proposal.organizationId] < MAX_BOOSTED_PROPOSALS) {
                         //change proposal mode to Boosted mode.
                            proposal.state = ProposalState.Boosted;
                         // solhint-disable-next-line not-rely-on-time
                            proposal.times[1] = now;
                            orgBoostedProposalsCnt[proposal.organizationId]++;
                         //add a value to average -> average = average + ((value - average) / nbValues)
                            averageDownstakesOfBoosted = averagesDownstakesOfBoosted[proposal.organizationId];
                          // solium-disable-next-line indentation
                            averagesDownstakesOfBoosted[proposal.organizationId] =
                                uint256(int256(averageDownstakesOfBoosted) +
                                ((int256(proposal.stakes[NO])-int256(averageDownstakesOfBoosted))/
                                int256(orgBoostedProposalsCnt[proposal.organizationId])));
                        }
                    } else {
                        proposal.state = ProposalState.Queued;
                    }
                } else { //check the Confidence level is stable
                    uint256 proposalScore = _score(_proposalId);
                    if (proposalScore <= proposal.confidenceThreshold.min(confidenceThreshold)) {
                        proposal.state = ProposalState.Queued;
                    } else if (proposal.confidenceThreshold > proposalScore) {
                        proposal.confidenceThreshold = confidenceThreshold;
                        emit ConfidenceLevelChange(_proposalId, confidenceThreshold);
                    }
                }
            }
        }

        if ((proposal.state == ProposalState.Boosted) ||
            (proposal.state == ProposalState.QuietEndingPeriod)) {
            // solhint-disable-next-line not-rely-on-time
            if ((now - proposal.times[1]) >= proposal.currentBoostedVotePeriodLimit) {
                proposal.state = ProposalState.Executed;
                executionState = ExecutionState.BoostedTimeOut;
            }
        }

        if (executionState != ExecutionState.None) {
            if ((executionState == ExecutionState.BoostedTimeOut) ||
                (executionState == ExecutionState.BoostedBarCrossed)) {
                orgBoostedProposalsCnt[tmpProposal.organizationId] =
                orgBoostedProposalsCnt[tmpProposal.organizationId].sub(1);
                //remove a value from average = ((average * nbValues) - value) / (nbValues - 1);
                uint256 boostedProposals = orgBoostedProposalsCnt[tmpProposal.organizationId];
                if (boostedProposals == 0) {
                    averagesDownstakesOfBoosted[proposal.organizationId] = 0;
                } else {
                    averageDownstakesOfBoosted = averagesDownstakesOfBoosted[proposal.organizationId];
                    averagesDownstakesOfBoosted[proposal.organizationId] =
                    (averageDownstakesOfBoosted.mul(boostedProposals+1).sub(proposal.stakes[NO]))/boostedProposals;
                }
            }
            emit ExecuteProposal(
            _proposalId,
            organizations[proposal.organizationId],
            proposal.winningVote,
            totalReputation
            );
            emit GPExecuteProposal(_proposalId, executionState);
            ProposalExecuteInterface(proposal.callbacks).executeProposal(_proposalId, int(proposal.winningVote));
            proposal.daoBounty = proposal.daoBountyRemain;
        }
        if (tmpProposal.state != proposal.state) {
            emit StateChange(_proposalId, proposal.state);
        }
        return (executionState != ExecutionState.None);
    }

    /**
     * @dev staking function
     * @param _proposalId id of the proposal
     * @param _vote  NO(2) or YES(1).
     * @param _amount the betting amount
     * @return bool true - the proposal has been executed
     *              false - otherwise.
     */
    function _stake(bytes32 _proposalId, uint256 _vote, uint256 _amount, address _staker) internal returns(bool) {
        // 0 is not a valid vote.
        require(_vote <= NUM_OF_CHOICES && _vote > 0, "wrong vote value");
        require(_amount > 0, "staking amount should be >0");

        if (_execute(_proposalId)) {
            return true;
        }
        Proposal storage proposal = proposals[_proposalId];

        if ((proposal.state != ProposalState.PreBoosted) &&
            (proposal.state != ProposalState.Queued)) {
            return false;
        }

        // enable to increase stake only on the previous stake vote
        Staker storage staker = proposal.stakers[_staker];
        if ((staker.amount > 0) && (staker.vote != _vote)) {
            return false;
        }

        uint256 amount = _amount;
        require(stakingToken.transferFrom(_staker, address(this), amount), "fail transfer from staker");
        proposal.totalStakes = proposal.totalStakes.add(amount); //update totalRedeemableStakes
        staker.amount = staker.amount.add(amount);
        //This is to prevent average downstakes calculation overflow
        //Note that any how GEN cap is 100000000 ether.
        require(staker.amount <= 0x100000000000000000000000000000000, "staking amount is too high");
        require(proposal.totalStakes <= 0x100000000000000000000000000000000, "total stakes is too high");

        if (_vote == YES) {
            staker.amount4Bounty = staker.amount4Bounty.add(amount);
        }
        staker.vote = _vote;

        proposal.stakes[_vote] = amount.add(proposal.stakes[_vote]);
        emit Stake(_proposalId, organizations[proposal.organizationId], _staker, _vote, _amount);
        return _execute(_proposalId);
    }

    /**
     * @dev Vote for a proposal, if the voter already voted, cancel the last vote and set a new one instead
     * @param _proposalId id of the proposal
     * @param _voter used in case the vote is cast for someone else
     * @param _vote a value between 0 to and the proposal's number of choices.
     * @param _rep how many reputation the voter would like to stake for this vote.
     *         if  _rep==0 so the voter full reputation will be use.
     * @return true in case of proposal execution otherwise false
     * throws if proposal is not open or if it has been executed
     * NB: executes the proposal if a decision has been reached
     */
     // solhint-disable-next-line function-max-lines,code-complexity
    function internalVote(bytes32 _proposalId, address _voter, uint256 _vote, uint256 _rep) internal returns(bool) {
        require(_vote <= NUM_OF_CHOICES && _vote > 0, "0 < _vote <= 2");
        if (_execute(_proposalId)) {
            return true;
        }

        Parameters memory params = parameters[proposals[_proposalId].paramsHash];
        Proposal storage proposal = proposals[_proposalId];

        // Check voter has enough reputation:
        uint256 reputation = VotingMachineCallbacksInterface(proposal.callbacks).reputationOf(_voter, _proposalId);
        require(reputation > 0, "_voter must have reputation");
        require(reputation >= _rep, "reputation >= _rep");
        uint256 rep = _rep;
        if (rep == 0) {
            rep = reputation;
        }
        // If this voter has already voted, return false.
        if (proposal.voters[_voter].reputation != 0) {
            return false;
        }
        // The voting itself:
        proposal.votes[_vote] = rep.add(proposal.votes[_vote]);
        //check if the current winningVote changed or there is a tie.
        //for the case there is a tie the current winningVote set to NO.
        if ((proposal.votes[_vote] > proposal.votes[proposal.winningVote]) ||
            ((proposal.votes[NO] == proposal.votes[proposal.winningVote]) &&
            proposal.winningVote == YES)) {
            if (proposal.state == ProposalState.Boosted &&
            // solhint-disable-next-line not-rely-on-time
                ((now - proposal.times[1]) >= (params.boostedVotePeriodLimit - params.quietEndingPeriod))||
                proposal.state == ProposalState.QuietEndingPeriod) {
                //quietEndingPeriod
                if (proposal.state != ProposalState.QuietEndingPeriod) {
                    proposal.currentBoostedVotePeriodLimit = params.quietEndingPeriod;
                    proposal.state = ProposalState.QuietEndingPeriod;
                }
                // solhint-disable-next-line not-rely-on-time
                proposal.times[1] = now;
            }
            proposal.winningVote = _vote;
        }
        proposal.voters[_voter] = Voter({
            reputation: rep,
            vote: _vote,
            preBoosted:((proposal.state == ProposalState.PreBoosted) || (proposal.state == ProposalState.Queued))
        });
        if ((proposal.state == ProposalState.PreBoosted) || (proposal.state == ProposalState.Queued)) {
            proposal.preBoostedVotes[_vote] = rep.add(proposal.preBoostedVotes[_vote]);
            uint256 reputationDeposit = (params.votersReputationLossRatio.mul(rep))/100;
            VotingMachineCallbacksInterface(proposal.callbacks).burnReputation(reputationDeposit, _voter, _proposalId);
        }
        emit VoteProposal(_proposalId, organizations[proposal.organizationId], _voter, _vote, rep);
        return _execute(_proposalId);
    }

    /**
     * @dev _score return the proposal score (Confidence level)
     * For dual choice proposal S = (S+)/(S-)
     * @param _proposalId the ID of the proposal
     * @return uint256 proposal score as real number.
     */
    function _score(bytes32 _proposalId) internal view returns(uint256) {
        Proposal storage proposal = proposals[_proposalId];
        //proposal.stakes[NO] cannot be zero as the dao downstake > 0 for each proposal.
        return uint216(proposal.stakes[YES]).fraction(uint216(proposal.stakes[NO]));
    }

    /**
      * @dev _isVotable check if the proposal is votable
      * @param _proposalId the ID of the proposal
      * @return bool true or false
    */
    function _isVotable(bytes32 _proposalId) internal view returns(bool) {
        ProposalState pState = proposals[_proposalId].state;
        return ((pState == ProposalState.PreBoosted)||
                (pState == ProposalState.Boosted)||
                (pState == ProposalState.QuietEndingPeriod)||
                (pState == ProposalState.Queued)
        );
    }
}

// File: @daostack/infra/contracts/votingMachines/GenesisProtocol.sol

pragma solidity ^0.5.4;




/**
 * @title GenesisProtocol implementation -an organization's voting machine scheme.
 */
contract GenesisProtocol is IntVoteInterface, GenesisProtocolLogic {
    using ECDSA for bytes32;

    // Digest describing the data the user signs according EIP 712.
    // Needs to match what is passed to Metamask.
    bytes32 public constant DELEGATION_HASH_EIP712 =
    keccak256(abi.encodePacked(
    "address GenesisProtocolAddress",
    "bytes32 ProposalId",
    "uint256 Vote",
    "uint256 AmountToStake",
    "uint256 Nonce"
    ));

    mapping(address=>uint256) public stakesNonce; //stakes Nonce

    /**
     * @dev Constructor
     */
    constructor(IERC20 _stakingToken)
    public
    // solhint-disable-next-line no-empty-blocks
    GenesisProtocolLogic(_stakingToken) {
    }

    /**
     * @dev staking function
     * @param _proposalId id of the proposal
     * @param _vote  NO(2) or YES(1).
     * @param _amount the betting amount
     * @return bool true - the proposal has been executed
     *              false - otherwise.
     */
    function stake(bytes32 _proposalId, uint256 _vote, uint256 _amount) external returns(bool) {
        return _stake(_proposalId, _vote, _amount, msg.sender);
    }

    /**
     * @dev stakeWithSignature function
     * @param _proposalId id of the proposal
     * @param _vote  NO(2) or YES(1).
     * @param _amount the betting amount
     * @param _nonce nonce value ,it is part of the signature to ensure that
              a signature can be received only once.
     * @param _signatureType signature type
              1 - for web3.eth.sign
              2 - for eth_signTypedData according to EIP #712.
     * @param _signature  - signed data by the staker
     * @return bool true - the proposal has been executed
     *              false - otherwise.
     */
    function stakeWithSignature(
        bytes32 _proposalId,
        uint256 _vote,
        uint256 _amount,
        uint256 _nonce,
        uint256 _signatureType,
        bytes calldata _signature
        )
        external
        returns(bool)
        {
        // Recreate the digest the user signed
        bytes32 delegationDigest;
        if (_signatureType == 2) {
            delegationDigest = keccak256(
                abi.encodePacked(
                    DELEGATION_HASH_EIP712, keccak256(
                        abi.encodePacked(
                        address(this),
                        _proposalId,
                        _vote,
                        _amount,
                        _nonce)
                    )
                )
            );
        } else {
            delegationDigest = keccak256(
                        abi.encodePacked(
                        address(this),
                        _proposalId,
                        _vote,
                        _amount,
                        _nonce)
                    ).toEthSignedMessageHash();
        }
        address staker = delegationDigest.recover(_signature);
        //a garbage staker address due to wrong signature will revert due to lack of approval and funds.
        require(staker != address(0), "staker address cannot be 0");
        require(stakesNonce[staker] == _nonce);
        stakesNonce[staker] = stakesNonce[staker].add(1);
        return _stake(_proposalId, _vote, _amount, staker);
    }

    /**
     * @dev voting function
     * @param _proposalId id of the proposal
     * @param _vote NO(2) or YES(1).
     * @param _amount the reputation amount to vote with . if _amount == 0 it will use all voter reputation.
     * @param _voter voter address
     * @return bool true - the proposal has been executed
     *              false - otherwise.
     */
    function vote(bytes32 _proposalId, uint256 _vote, uint256 _amount, address _voter)
    external
    votable(_proposalId)
    returns(bool) {
        Proposal storage proposal = proposals[_proposalId];
        Parameters memory params = parameters[proposal.paramsHash];
        address voter;
        if (params.voteOnBehalf != address(0)) {
            require(msg.sender == params.voteOnBehalf);
            voter = _voter;
        } else {
            voter = msg.sender;
        }
        return internalVote(_proposalId, voter, _vote, _amount);
    }

  /**
   * @dev Cancel the vote of the msg.sender.
   * cancel vote is not allow in genesisProtocol so this function doing nothing.
   * This function is here in order to comply to the IntVoteInterface .
   */
    function cancelVote(bytes32 _proposalId) external votable(_proposalId) {
       //this is not allowed
        return;
    }

    /**
      * @dev execute check if the proposal has been decided, and if so, execute the proposal
      * @param _proposalId the id of the proposal
      * @return bool true - the proposal has been executed
      *              false - otherwise.
     */
    function execute(bytes32 _proposalId) external votable(_proposalId) returns(bool) {
        return _execute(_proposalId);
    }

  /**
    * @dev getNumberOfChoices returns the number of choices possible in this proposal
    * @return uint256 that contains number of choices
    */
    function getNumberOfChoices(bytes32) external view returns(uint256) {
        return NUM_OF_CHOICES;
    }

    /**
      * @dev getProposalTimes returns proposals times variables.
      * @param _proposalId id of the proposal
      * @return proposals times array
      */
    function getProposalTimes(bytes32 _proposalId) external view returns(uint[3] memory times) {
        return proposals[_proposalId].times;
    }

    /**
     * @dev voteInfo returns the vote and the amount of reputation of the user committed to this proposal
     * @param _proposalId the ID of the proposal
     * @param _voter the address of the voter
     * @return uint256 vote - the voters vote
     *        uint256 reputation - amount of reputation committed by _voter to _proposalId
     */
    function voteInfo(bytes32 _proposalId, address _voter) external view returns(uint, uint) {
        Voter memory voter = proposals[_proposalId].voters[_voter];
        return (voter.vote, voter.reputation);
    }

    /**
    * @dev voteStatus returns the reputation voted for a proposal for a specific voting choice.
    * @param _proposalId the ID of the proposal
    * @param _choice the index in the
    * @return voted reputation for the given choice
    */
    function voteStatus(bytes32 _proposalId, uint256 _choice) external view returns(uint256) {
        return proposals[_proposalId].votes[_choice];
    }

    /**
    * @dev isVotable check if the proposal is votable
    * @param _proposalId the ID of the proposal
    * @return bool true or false
    */
    function isVotable(bytes32 _proposalId) external view returns(bool) {
        return _isVotable(_proposalId);
    }

    /**
    * @dev proposalStatus return the total votes and stakes for a given proposal
    * @param _proposalId the ID of the proposal
    * @return uint256 preBoostedVotes YES
    * @return uint256 preBoostedVotes NO
    * @return uint256 total stakes YES
    * @return uint256 total stakes NO
    */
    function proposalStatus(bytes32 _proposalId) external view returns(uint256, uint256, uint256, uint256) {
        return (
                proposals[_proposalId].preBoostedVotes[YES],
                proposals[_proposalId].preBoostedVotes[NO],
                proposals[_proposalId].stakes[YES],
                proposals[_proposalId].stakes[NO]
        );
    }

  /**
    * @dev getProposalOrganization return the organizationId for a given proposal
    * @param _proposalId the ID of the proposal
    * @return bytes32 organization identifier
    */
    function getProposalOrganization(bytes32 _proposalId) external view returns(bytes32) {
        return (proposals[_proposalId].organizationId);
    }

    /**
      * @dev getStaker return the vote and stake amount for a given proposal and staker
      * @param _proposalId the ID of the proposal
      * @param _staker staker address
      * @return uint256 vote
      * @return uint256 amount
    */
    function getStaker(bytes32 _proposalId, address _staker) external view returns(uint256, uint256) {
        return (proposals[_proposalId].stakers[_staker].vote, proposals[_proposalId].stakers[_staker].amount);
    }

    /**
      * @dev voteStake return the amount stakes for a given proposal and vote
      * @param _proposalId the ID of the proposal
      * @param _vote vote number
      * @return uint256 stake amount
    */
    function voteStake(bytes32 _proposalId, uint256 _vote) external view returns(uint256) {
        return proposals[_proposalId].stakes[_vote];
    }

  /**
    * @dev voteStake return the winningVote for a given proposal
    * @param _proposalId the ID of the proposal
    * @return uint256 winningVote
    */
    function winningVote(bytes32 _proposalId) external view returns(uint256) {
        return proposals[_proposalId].winningVote;
    }

    /**
      * @dev voteStake return the state for a given proposal
      * @param _proposalId the ID of the proposal
      * @return ProposalState proposal state
    */
    function state(bytes32 _proposalId) external view returns(ProposalState) {
        return proposals[_proposalId].state;
    }

   /**
    * @dev isAbstainAllow returns if the voting machine allow abstain (0)
    * @return bool true or false
    */
    function isAbstainAllow() external pure returns(bool) {
        return false;
    }

    /**
     * @dev getAllowedRangeOfChoices returns the allowed range of choices for a voting machine.
     * @return min - minimum number of choices
               max - maximum number of choices
     */
    function getAllowedRangeOfChoices() external pure returns(uint256 min, uint256 max) {
        return (YES, NO);
    }

    /**
     * @dev score return the proposal score
     * @param _proposalId the ID of the proposal
     * @return uint256 proposal score.
     */
    function score(bytes32 _proposalId) public view returns(uint256) {
        return  _score(_proposalId);
    }
}

// File: @daostack/arc/contracts/votingMachines/VotingMachineCallbacks.sol

pragma solidity ^0.5.4;




contract VotingMachineCallbacks is VotingMachineCallbacksInterface {

    struct ProposalInfo {
        uint256 blockNumber; // the proposal's block number
        Avatar avatar; // the proposal's avatar
    }

    modifier onlyVotingMachine(bytes32 _proposalId) {
        require(proposalsInfo[msg.sender][_proposalId].avatar != Avatar(address(0)), "only VotingMachine");
        _;
    }

    // VotingMaching  ->  proposalId  ->  ProposalInfo
    mapping(address => mapping(bytes32 => ProposalInfo)) public proposalsInfo;

    function mintReputation(uint256 _amount, address _beneficiary, bytes32 _proposalId)
    external
    onlyVotingMachine(_proposalId)
    returns(bool)
    {
        Avatar avatar = proposalsInfo[msg.sender][_proposalId].avatar;
        if (avatar == Avatar(0)) {
            return false;
        }
        return ControllerInterface(avatar.owner()).mintReputation(_amount, _beneficiary, address(avatar));
    }

    function burnReputation(uint256 _amount, address _beneficiary, bytes32 _proposalId)
    external
    onlyVotingMachine(_proposalId)
    returns(bool)
    {
        Avatar avatar = proposalsInfo[msg.sender][_proposalId].avatar;
        if (avatar == Avatar(0)) {
            return false;
        }
        return ControllerInterface(avatar.owner()).burnReputation(_amount, _beneficiary, address(avatar));
    }

    function stakingTokenTransfer(
        IERC20 _stakingToken,
        address _beneficiary,
        uint256 _amount,
        bytes32 _proposalId)
    external
    onlyVotingMachine(_proposalId)
    returns(bool)
    {
        Avatar avatar = proposalsInfo[msg.sender][_proposalId].avatar;
        if (avatar == Avatar(0)) {
            return false;
        }
        return ControllerInterface(avatar.owner()).externalTokenTransfer(_stakingToken, _beneficiary, _amount, avatar);
    }

    function balanceOfStakingToken(IERC20 _stakingToken, bytes32 _proposalId) external view returns(uint256) {
        Avatar avatar = proposalsInfo[msg.sender][_proposalId].avatar;
        if (proposalsInfo[msg.sender][_proposalId].avatar == Avatar(0)) {
            return 0;
        }
        return _stakingToken.balanceOf(address(avatar));
    }

    function getTotalReputationSupply(bytes32 _proposalId) external view returns(uint256) {
        ProposalInfo memory proposal = proposalsInfo[msg.sender][_proposalId];
        if (proposal.avatar == Avatar(0)) {
            return 0;
        }
        return proposal.avatar.nativeReputation().totalSupplyAt(proposal.blockNumber);
    }

    function reputationOf(address _owner, bytes32 _proposalId) external view returns(uint256) {
        ProposalInfo memory proposal = proposalsInfo[msg.sender][_proposalId];
        if (proposal.avatar == Avatar(0)) {
            return 0;
        }
        return proposal.avatar.nativeReputation().balanceOfAt(_owner, proposal.blockNumber);
    }
}

// File: @daostack/arc/contracts/universalSchemes/SchemeRegistrar.sol

pragma solidity ^0.5.4;






/**
 * @title A registrar for Schemes for organizations
 * @dev The SchemeRegistrar is used for registering and unregistering schemes at organizations
 */

contract SchemeRegistrar is UniversalScheme, VotingMachineCallbacks, ProposalExecuteInterface {
    event NewSchemeProposal(
        address indexed _avatar,
        bytes32 indexed _proposalId,
        address indexed _intVoteInterface,
        address _scheme,
        bytes32 _parametersHash,
        bytes4 _permissions,
        string _descriptionHash
    );

    event RemoveSchemeProposal(address indexed _avatar,
        bytes32 indexed _proposalId,
        address indexed _intVoteInterface,
        address _scheme,
        string _descriptionHash
    );

    event ProposalExecuted(address indexed _avatar, bytes32 indexed _proposalId, int256 _param);
    event ProposalDeleted(address indexed _avatar, bytes32 indexed _proposalId);

    // a SchemeProposal is a  proposal to add or remove a scheme to/from the an organization
    struct SchemeProposal {
        address scheme; //
        bool addScheme; // true: add a scheme, false: remove a scheme.
        bytes32 parametersHash;
        bytes4 permissions;
    }

    // A mapping from the organization (Avatar) address to the saved data of the organization:
    mapping(address=>mapping(bytes32=>SchemeProposal)) public organizationsProposals;

    // A mapping from hashes to parameters (use to store a particular configuration on the controller)
    struct Parameters {
        bytes32 voteRegisterParams;
        bytes32 voteRemoveParams;
        IntVoteInterface intVote;
    }

    mapping(bytes32=>Parameters) public parameters;

    /**
    * @dev execution of proposals, can only be called by the voting machine in which the vote is held.
    * @param _proposalId the ID of the voting in the voting machine
    * @param _param a parameter of the voting result, 1 yes and 2 is no.
    */
    function executeProposal(bytes32 _proposalId, int256 _param) external onlyVotingMachine(_proposalId) returns(bool) {
        Avatar avatar = proposalsInfo[msg.sender][_proposalId].avatar;
        SchemeProposal memory proposal = organizationsProposals[address(avatar)][_proposalId];
        require(proposal.scheme != address(0));
        delete organizationsProposals[address(avatar)][_proposalId];
        emit ProposalDeleted(address(avatar), _proposalId);
        if (_param == 1) {

          // Define controller and get the params:
            ControllerInterface controller = ControllerInterface(avatar.owner());

          // Add a scheme:
            if (proposal.addScheme) {
                require(controller.registerScheme(
                        proposal.scheme,
                        proposal.parametersHash,
                        proposal.permissions,
                        address(avatar))
                );
            }
          // Remove a scheme:
            if (!proposal.addScheme) {
                require(controller.unregisterScheme(proposal.scheme, address(avatar)));
            }
        }
        emit ProposalExecuted(address(avatar), _proposalId, _param);
        return true;
    }

    /**
    * @dev hash the parameters, save them if necessary, and return the hash value
    */
    function setParameters(
        bytes32 _voteRegisterParams,
        bytes32 _voteRemoveParams,
        IntVoteInterface _intVote
    ) public returns(bytes32)
    {
        bytes32 paramsHash = getParametersHash(_voteRegisterParams, _voteRemoveParams, _intVote);
        parameters[paramsHash].voteRegisterParams = _voteRegisterParams;
        parameters[paramsHash].voteRemoveParams = _voteRemoveParams;
        parameters[paramsHash].intVote = _intVote;
        return paramsHash;
    }

    function getParametersHash(
        bytes32 _voteRegisterParams,
        bytes32 _voteRemoveParams,
        IntVoteInterface _intVote
    ) public pure returns(bytes32)
    {
        return keccak256(abi.encodePacked(_voteRegisterParams, _voteRemoveParams, _intVote));
    }

    /**
    * @dev create a proposal to register a scheme
    * @param _avatar the address of the organization the scheme will be registered for
    * @param _scheme the address of the scheme to be registered
    * @param _parametersHash a hash of the configuration of the _scheme
    * @param _permissions the permission of the scheme to be registered
    * @param _descriptionHash proposal's description hash
    * @return a proposal Id
    * @dev NB: not only proposes the vote, but also votes for it
    */
    function proposeScheme(
        Avatar _avatar,
        address _scheme,
        bytes32 _parametersHash,
        bytes4 _permissions,
        string memory _descriptionHash
    )
    public
    returns(bytes32)
    {
        // propose
        require(_scheme != address(0), "scheme cannot be zero");
        Parameters memory controllerParams = parameters[getParametersFromController(_avatar)];

        bytes32 proposalId = controllerParams.intVote.propose(
            2,
            controllerParams.voteRegisterParams,
            msg.sender,
            address(_avatar)
        );

        SchemeProposal memory proposal = SchemeProposal({
            scheme: _scheme,
            parametersHash: _parametersHash,
            addScheme: true,
            permissions: _permissions
        });
        emit NewSchemeProposal(
            address(_avatar),
            proposalId,
            address(controllerParams.intVote),
            _scheme, _parametersHash,
            _permissions,
            _descriptionHash
        );
        organizationsProposals[address(_avatar)][proposalId] = proposal;
        proposalsInfo[address(controllerParams.intVote)][proposalId] = ProposalInfo({
            blockNumber:block.number,
            avatar:_avatar
        });
        return proposalId;
    }

    /**
    * @dev propose to remove a scheme for a controller
    * @param _avatar the address of the controller from which we want to remove a scheme
    * @param _scheme the address of the scheme we want to remove
    * @param _descriptionHash proposal description hash
    * NB: not only registers the proposal, but also votes for it
    */
    function proposeToRemoveScheme(Avatar _avatar, address _scheme, string memory _descriptionHash)
    public
    returns(bytes32)
    {
        require(_scheme != address(0), "scheme cannot be zero");
        bytes32 paramsHash = getParametersFromController(_avatar);
        Parameters memory params = parameters[paramsHash];

        IntVoteInterface intVote = params.intVote;
        bytes32 proposalId = intVote.propose(2, params.voteRemoveParams, msg.sender, address(_avatar));
        organizationsProposals[address(_avatar)][proposalId].scheme = _scheme;
        emit RemoveSchemeProposal(address(_avatar), proposalId, address(intVote), _scheme, _descriptionHash);
        proposalsInfo[address(params.intVote)][proposalId] = ProposalInfo({
            blockNumber:block.number,
            avatar:_avatar
        });
        return proposalId;
    }
}

// File: @daostack/arc/contracts/universalSchemes/UpgradeScheme.sol

pragma solidity ^0.5.4;






/**
 * @title A scheme to manage the upgrade of an organization.
 * @dev The scheme is used to upgrade the controller of an organization to a new controller.
 */

contract UpgradeScheme is UniversalScheme, VotingMachineCallbacks, ProposalExecuteInterface {

    event NewUpgradeProposal(
        address indexed _avatar,
        bytes32 indexed _proposalId,
        address indexed _intVoteInterface,
        address _newController,
        string _descriptionHash
    );

    event ChangeUpgradeSchemeProposal(
        address indexed _avatar,
        bytes32 indexed _proposalId,
        address indexed _intVoteInterface,
        address _newUpgradeScheme,
        bytes32 _params,
        string _descriptionHash
    );

    event ProposalExecuted(address indexed _avatar, bytes32 indexed _proposalId, int256 _param);
    event ProposalDeleted(address indexed _avatar, bytes32 indexed _proposalId);

    // Details of an upgrade proposal:
    struct UpgradeProposal {
        address upgradeContract; // Either the new controller we upgrade to, or the new upgrading scheme.
        bytes32 params; // Params for the new upgrading scheme.
        uint256 proposalType; // 1: Upgrade controller, 2: change upgrade scheme.
    }

    // A mapping from the organization's (Avatar) address to the saved data of the organization:
    mapping(address=>mapping(bytes32=>UpgradeProposal)) public organizationsProposals;

    // A mapping from hashes to parameters (use to store a particular configuration on the controller)
    struct Parameters {
        bytes32 voteParams;
        IntVoteInterface intVote;
    }

    mapping(bytes32=>Parameters) public parameters;

    /**
    * @dev execution of proposals, can only be called by the voting machine in which the vote is held.
    * @param _proposalId the ID of the voting in the voting machine
    * @param _param a parameter of the voting result, 1 yes and 2 is no.
    */
    function executeProposal(bytes32 _proposalId, int256 _param) external onlyVotingMachine(_proposalId) returns(bool) {
        Avatar avatar = proposalsInfo[msg.sender][_proposalId].avatar;
        UpgradeProposal memory proposal = organizationsProposals[address(avatar)][_proposalId];
        require(proposal.proposalType != 0);
        delete organizationsProposals[address(avatar)][_proposalId];
        emit ProposalDeleted(address(avatar), _proposalId);
        // Check if vote was successful:
        if (_param == 1) {

        // Define controller and get the params:
            ControllerInterface controller = ControllerInterface(avatar.owner());
        // Upgrading controller:
            if (proposal.proposalType == 1) {
                require(controller.upgradeController(proposal.upgradeContract, avatar));
            }

        // Changing upgrade scheme:
            if (proposal.proposalType == 2) {
                bytes4 permissions = controller.getSchemePermissions(address(this), address(avatar));
                require(
                controller.registerScheme(proposal.upgradeContract, proposal.params, permissions, address(avatar))
                );
                if (proposal.upgradeContract != address(this)) {
                    require(controller.unregisterSelf(address(avatar)));
                }
            }
        }
        emit ProposalExecuted(address(avatar), _proposalId, _param);
        return true;
    }

    /**
    * @dev hash the parameters, save them if necessary, and return the hash value
    */
    function setParameters(
        bytes32 _voteParams,
        IntVoteInterface _intVote
    ) public returns(bytes32)
    {
        bytes32 paramsHash = getParametersHash(_voteParams, _intVote);
        parameters[paramsHash].voteParams = _voteParams;
        parameters[paramsHash].intVote = _intVote;
        return paramsHash;
    }

    /**
    * @dev return a hash of the given parameters
    */
    function getParametersHash(
        bytes32 _voteParams,
        IntVoteInterface _intVote
    ) public pure returns(bytes32)
    {
        return  (keccak256(abi.encodePacked(_voteParams, _intVote)));
    }

    /**
    * @dev propose an upgrade of the organization's controller
    * @param _avatar avatar of the organization
    * @param _newController address of the new controller that is being proposed
    * @param _descriptionHash proposal description hash
    * @return an id which represents the proposal
    */
    function proposeUpgrade(Avatar _avatar, address _newController, string memory _descriptionHash)
        public
        returns(bytes32)
    {
        Parameters memory params = parameters[getParametersFromController(_avatar)];
        bytes32 proposalId = params.intVote.propose(2, params.voteParams, msg.sender, address(_avatar));
        UpgradeProposal memory proposal = UpgradeProposal({
            proposalType: 1,
            upgradeContract: _newController,
            params: bytes32(0)
        });
        organizationsProposals[address(_avatar)][proposalId] = proposal;
        emit NewUpgradeProposal(
        address(_avatar),
        proposalId,
        address(params.intVote),
        _newController,
        _descriptionHash
        );
        proposalsInfo[address(params.intVote)][proposalId] = ProposalInfo({
            blockNumber:block.number,
            avatar:_avatar
        });
        return proposalId;
    }

    /**
    * @dev propose to replace this scheme by another upgrading scheme
    * @param _avatar avatar of the organization
    * @param _scheme address of the new upgrading scheme
    * @param _params the parameters of the new upgrading scheme
    * @param _descriptionHash proposal description hash
    * @return an id which represents the proposal
    */
    function proposeChangeUpgradingScheme(
        Avatar _avatar,
        address _scheme,
        bytes32 _params,
        string memory _descriptionHash
    )
        public
        returns(bytes32)
    {
        Parameters memory params = parameters[getParametersFromController(_avatar)];
        IntVoteInterface intVote = params.intVote;
        bytes32 proposalId = intVote.propose(2, params.voteParams, msg.sender, address(_avatar));
        require(organizationsProposals[address(_avatar)][proposalId].proposalType == 0);

        UpgradeProposal memory proposal = UpgradeProposal({
            proposalType: 2,
            upgradeContract: _scheme,
            params: _params
        });
        organizationsProposals[address(_avatar)][proposalId] = proposal;

        emit ChangeUpgradeSchemeProposal(
            address(_avatar),
            proposalId,
            address(params.intVote),
            _scheme,
            _params,
            _descriptionHash
        );
        proposalsInfo[address(intVote)][proposalId] = ProposalInfo({
            blockNumber:block.number,
            avatar:_avatar
        });
        return proposalId;
    }
}

// File: @daostack/infra/contracts/votingMachines/AbsoluteVote.sol

pragma solidity ^0.5.4;







contract AbsoluteVote is IntVoteInterface {
    using SafeMath for uint;

    struct Parameters {
        uint256 precReq; // how many percentages required for the proposal to be passed
        address voteOnBehalf; //if this address is set so only this address is allowed
                              // to vote of behalf of someone else.
    }

    struct Voter {
        uint256 vote; // 0 - 'abstain'
        uint256 reputation; // amount of voter's reputation
    }

    struct Proposal {
        bytes32 organizationId; // the organization Id
        bool open; // voting open flag
        address callbacks;
        uint256 numOfChoices;
        bytes32 paramsHash; // the hash of the parameters of the proposal
        uint256 totalVotes;
        mapping(uint=>uint) votes;
        mapping(address=>Voter) voters;
    }

    event AVVoteProposal(bytes32 indexed _proposalId, bool _isProxyVote);

    mapping(bytes32=>Parameters) public parameters;  // A mapping from hashes to parameters
    mapping(bytes32=>Proposal) public proposals; // Mapping from the ID of the proposal to the proposal itself.
    mapping(bytes32=>address) public organizations;

    uint256 public constant MAX_NUM_OF_CHOICES = 10;
    uint256 public proposalsCnt; // Total amount of proposals

  /**
   * @dev Check that the proposal is votable (open and not executed yet)
   */
    modifier votable(bytes32 _proposalId) {
        require(proposals[_proposalId].open);
        _;
    }

    /**
     * @dev register a new proposal with the given parameters. Every proposal has a unique ID which is being
     * generated by calculating keccak256 of a incremented counter.
     * @param _numOfChoices number of voting choices
     * @param _paramsHash defined the parameters of the voting machine used for this proposal
     * @param _organization address
     * @return proposal's id.
     */
    function propose(uint256 _numOfChoices, bytes32 _paramsHash, address, address _organization)
        external
        returns(bytes32)
    {
        // Check valid params and number of choices:
        require(parameters[_paramsHash].precReq > 0);
        require(_numOfChoices > 0 && _numOfChoices <= MAX_NUM_OF_CHOICES);
        // Generate a unique ID:
        bytes32 proposalId = keccak256(abi.encodePacked(this, proposalsCnt));
        proposalsCnt = proposalsCnt.add(1);
        // Open proposal:
        Proposal memory proposal;
        proposal.numOfChoices = _numOfChoices;
        proposal.paramsHash = _paramsHash;
        proposal.callbacks = msg.sender;
        proposal.organizationId = keccak256(abi.encodePacked(msg.sender, _organization));
        proposal.open = true;
        proposals[proposalId] = proposal;
        if (organizations[proposal.organizationId] == address(0)) {
            if (_organization == address(0)) {
                organizations[proposal.organizationId] = msg.sender;
            } else {
                organizations[proposal.organizationId] = _organization;
            }
        }
        emit NewProposal(proposalId, organizations[proposal.organizationId], _numOfChoices, msg.sender, _paramsHash);
        return proposalId;
    }

    /**
     * @dev voting function
     * @param _proposalId id of the proposal
     * @param _vote a value between 0 to and the proposal number of choices.
     * @param _amount the reputation amount to vote with . if _amount == 0 it will use all voter reputation.
     * @param _voter voter address
     * @return bool true - the proposal has been executed
     *              false - otherwise.
     */
    function vote(
        bytes32 _proposalId,
        uint256 _vote,
        uint256 _amount,
        address _voter)
        external
        votable(_proposalId)
        returns(bool)
        {

        Proposal storage proposal = proposals[_proposalId];
        Parameters memory params = parameters[proposal.paramsHash];
        address voter;
        if (params.voteOnBehalf != address(0)) {
            require(msg.sender == params.voteOnBehalf);
            voter = _voter;
        } else {
            voter = msg.sender;
        }
        return internalVote(_proposalId, voter, _vote, _amount);
    }

  /**
   * @dev Cancel the vote of the msg.sender: subtract the reputation amount from the votes
   * and delete the voter from the proposal struct
   * @param _proposalId id of the proposal
   */
    function cancelVote(bytes32 _proposalId) external votable(_proposalId) {
        cancelVoteInternal(_proposalId, msg.sender);
    }

    /**
      * @dev execute check if the proposal has been decided, and if so, execute the proposal
      * @param _proposalId the id of the proposal
      * @return bool true - the proposal has been executed
      *              false - otherwise.
     */
    function execute(bytes32 _proposalId) external votable(_proposalId) returns(bool) {
        return _execute(_proposalId);
    }

  /**
   * @dev getNumberOfChoices returns the number of choices possible in this proposal
   * excluding the abstain vote (0)
   * @param _proposalId the ID of the proposal
   * @return uint256 that contains number of choices
   */
    function getNumberOfChoices(bytes32 _proposalId) external view returns(uint256) {
        return proposals[_proposalId].numOfChoices;
    }

  /**
   * @dev voteInfo returns the vote and the amount of reputation of the user committed to this proposal
   * @param _proposalId the ID of the proposal
   * @param _voter the address of the voter
   * @return uint256 vote - the voters vote
   *        uint256 reputation - amount of reputation committed by _voter to _proposalId
   */
    function voteInfo(bytes32 _proposalId, address _voter) external view returns(uint, uint) {
        Voter memory voter = proposals[_proposalId].voters[_voter];
        return (voter.vote, voter.reputation);
    }

    /**
     * @dev voteStatus returns the reputation voted for a proposal for a specific voting choice.
     * @param _proposalId the ID of the proposal
     * @param _choice the index in the
     * @return voted reputation for the given choice
     */
    function voteStatus(bytes32 _proposalId, uint256 _choice) external view returns(uint256) {
        return proposals[_proposalId].votes[_choice];
    }

    /**
      * @dev isVotable check if the proposal is votable
      * @param _proposalId the ID of the proposal
      * @return bool true or false
    */
    function isVotable(bytes32 _proposalId) external view returns(bool) {
        return  proposals[_proposalId].open;
    }

    /**
     * @dev isAbstainAllow returns if the voting machine allow abstain (0)
     * @return bool true or false
     */
    function isAbstainAllow() external pure returns(bool) {
        return true;
    }

    /**
     * @dev getAllowedRangeOfChoices returns the allowed range of choices for a voting machine.
     * @return min - minimum number of choices
               max - maximum number of choices
     */
    function getAllowedRangeOfChoices() external pure returns(uint256 min, uint256 max) {
        return (0, MAX_NUM_OF_CHOICES);
    }

    /**
     * @dev hash the parameters, save them if necessary, and return the hash value
    */
    function setParameters(uint256 _precReq, address _voteOnBehalf) public returns(bytes32) {
        require(_precReq <= 100 && _precReq > 0);
        bytes32 hashedParameters = getParametersHash(_precReq, _voteOnBehalf);
        parameters[hashedParameters] = Parameters({
            precReq: _precReq,
            voteOnBehalf: _voteOnBehalf
        });
        return hashedParameters;
    }

    /**
     * @dev hashParameters returns a hash of the given parameters
     */
    function getParametersHash(uint256 _precReq, address _voteOnBehalf) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_precReq, _voteOnBehalf));
    }

    function cancelVoteInternal(bytes32 _proposalId, address _voter) internal {
        Proposal storage proposal = proposals[_proposalId];
        Voter memory voter = proposal.voters[_voter];
        proposal.votes[voter.vote] = (proposal.votes[voter.vote]).sub(voter.reputation);
        proposal.totalVotes = (proposal.totalVotes).sub(voter.reputation);
        delete proposal.voters[_voter];
        emit CancelVoting(_proposalId, organizations[proposal.organizationId], _voter);
    }

    function deleteProposal(bytes32 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        for (uint256 cnt = 0; cnt <= proposal.numOfChoices; cnt++) {
            delete proposal.votes[cnt];
        }
        delete proposals[_proposalId];
    }

    /**
      * @dev execute check if the proposal has been decided, and if so, execute the proposal
      * @param _proposalId the id of the proposal
      * @return bool true - the proposal has been executed
      *              false - otherwise.
     */
    function _execute(bytes32 _proposalId) internal votable(_proposalId) returns(bool) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 totalReputation =
        VotingMachineCallbacksInterface(proposal.callbacks).getTotalReputationSupply(_proposalId);
        uint256 precReq = parameters[proposal.paramsHash].precReq;
        // Check if someone crossed the bar:
        for (uint256 cnt = 0; cnt <= proposal.numOfChoices; cnt++) {
            if (proposal.votes[cnt] > (totalReputation/100)*precReq) {
                Proposal memory tmpProposal = proposal;
                deleteProposal(_proposalId);
                emit ExecuteProposal(_proposalId, organizations[tmpProposal.organizationId], cnt, totalReputation);
                return ProposalExecuteInterface(tmpProposal.callbacks).executeProposal(_proposalId, int(cnt));
            }
        }
        return false;
    }

    /**
     * @dev Vote for a proposal, if the voter already voted, cancel the last vote and set a new one instead
     * @param _proposalId id of the proposal
     * @param _voter used in case the vote is cast for someone else
     * @param _vote a value between 0 to and the proposal's number of choices.
     * @return true in case of proposal execution otherwise false
     * throws if proposal is not open or if it has been executed
     * NB: executes the proposal if a decision has been reached
     */
    function internalVote(bytes32 _proposalId, address _voter, uint256 _vote, uint256 _rep) internal returns(bool) {
        Proposal storage proposal = proposals[_proposalId];
        // Check valid vote:
        require(_vote <= proposal.numOfChoices);
        // Check voter has enough reputation:
        uint256 reputation = VotingMachineCallbacksInterface(proposal.callbacks).reputationOf(_voter, _proposalId);
        require(reputation > 0, "_voter must have reputation");
        require(reputation >= _rep);
        uint256 rep = _rep;
        if (rep == 0) {
            rep = reputation;
        }
        // If this voter has already voted, first cancel the vote:
        if (proposal.voters[_voter].reputation != 0) {
            cancelVoteInternal(_proposalId, _voter);
        }
        // The voting itself:
        proposal.votes[_vote] = rep.add(proposal.votes[_vote]);
        proposal.totalVotes = rep.add(proposal.totalVotes);
        proposal.voters[_voter] = Voter({
            reputation: rep,
            vote: _vote
        });
        // Event:
        emit VoteProposal(_proposalId, organizations[proposal.organizationId], _voter, _vote, rep);
        emit AVVoteProposal(_proposalId, (_voter != msg.sender));
        // execute the proposal if this vote was decisive:
        return _execute(_proposalId);
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

// File: contracts/dao/DaoCreator.sol

pragma solidity >0.5.4;









/**
 * @title ControllerCreator for creating a single controller. Taken from @daostack.
 */
contract ControllerCreatorGoodDollar {
    function create(Avatar _avatar, address _sender) public returns (address) {
        Controller controller = new Controller(_avatar);
        controller.registerScheme(
            _sender,
            bytes32(0),
            bytes4(0x0000001f),
            address(_avatar)
        );
        controller.unregisterScheme(address(this), address(_avatar));
        return address(controller);
    }
}

/**
 * @title Contract for adding founders to the DAO. Separated from DaoCreator to reduce
 * contract sizes
 */
contract AddFoundersGoodDollar {
    ControllerCreatorGoodDollar private controllerCreatorGoodDollar;

    constructor(ControllerCreatorGoodDollar _controllerCreatorGoodDollar) public {
        controllerCreatorGoodDollar = _controllerCreatorGoodDollar;
    }

    /**
     * @param _founders An array with the addresses of the founders of the organization
     * @param _avatarTokenAmount Amount of tokens that the avatar receive on new organization
     * @param _foundersReputationAmount An array of amount of reputation that the
     *   founders receive in the new organization
     */
    function addFounders(
        GoodDollar nativeToken,
        Reputation nativeReputation,
        address _sender,
        address[] memory _founders,
        uint256 _avatarTokenAmount,
        uint256[] memory _foundersReputationAmount
    ) public returns (Avatar) {
        Avatar avatar = new Avatar("GoodDollar", nativeToken, nativeReputation);

        //mint token to avatar
        nativeToken.mint(address(avatar), _avatarTokenAmount);

        // Mint reputation for founders:
        for (uint256 i = 0; i < _founders.length; i++) {
            require(_founders[i] != address(0), "Founder cannot be zero address");
            if (_foundersReputationAmount[i] > 0) {
                nativeReputation.mint(_founders[i], _foundersReputationAmount[i]);
            }
        }
        // Create Controller:
        ControllerInterface controller = ControllerInterface(
            controllerCreatorGoodDollar.create(avatar, msg.sender)
        );

        // Set fee recipient and Transfer ownership:
        nativeToken.setFeeRecipient(address(avatar));

        avatar.transferOwnership(address(controller));
        nativeToken.transferOwnership(address(avatar));
        nativeReputation.transferOwnership(address(controller));

        // Add minters
        nativeToken.addMinter(_sender);
        nativeToken.addMinter(address(avatar));
        nativeToken.addMinter(address(controller));
        nativeToken.renounceMinter();
        return (avatar);
    }
}

/**
 * @title Genesis Scheme that creates organizations. Taken and modified from @daostack.
 */
contract DaoCreatorGoodDollar {
    Avatar public avatar;
    address public lock;

    event NewOrg(address _avatar);
    event InitialSchemesSet(address _avatar);

    AddFoundersGoodDollar private addFoundersGoodDollar;

    constructor(AddFoundersGoodDollar _addFoundersGoodDollar) public {
        addFoundersGoodDollar = _addFoundersGoodDollar;
    }

    /**
     * @dev Create a new organization
     * @param _tokenName The name of the token associated with the organization
     * @param _tokenSymbol The symbol of the token
     * @param _founders An array with the addresses of the founders of the organization
     * @param _avatarTokenAmount Amount of tokens that the avatar receive in the new organization
     * @param _foundersReputationAmount An array of amount of reputation that the
     *   founders receive in the new organization
     * @param  _cap token cap - 0 for no cap.
     * @return The address of the avatar of the controller
     */
    function forgeOrg(
        string calldata _tokenName,
        string calldata _tokenSymbol,
        uint256 _cap,
        FeeFormula _formula,
        Identity _identity,
        address[] calldata _founders,
        uint256 _avatarTokenAmount,
        uint256[] calldata _foundersReputationAmount
    ) external returns (address) {
        //The call for the private function is needed to bypass a deep stack issues
        return
            _forgeOrg(
                _tokenName,
                _tokenSymbol,
                _cap,
                _formula,
                _identity,
                _founders,
                _avatarTokenAmount,
                _foundersReputationAmount
            );
    }

    /**
     * @dev Set initial schemes for the organization.
     * @param _avatar organization avatar (returns from forgeOrg)
     * @param _schemes the schemes to register for the organization
     * @param _params the schemes parameters
     * @param _permissions the schemes permissions.
     * @param _metaData dao meta data hash
     */
    function setSchemes(
        Avatar _avatar,
        address[] calldata _schemes,
        bytes32[] calldata _params,
        bytes4[] calldata _permissions,
        string calldata _metaData
    ) external {
        // this action can only be executed by the account that holds the lock
        // for this controller
        require(lock == msg.sender, "Message sender is not lock");
        // register initial schemes:
        ControllerInterface controller = ControllerInterface(_avatar.owner());
        for (uint256 i = 0; i < _schemes.length; i++) {
            controller.registerScheme(
                _schemes[i],
                _params[i],
                _permissions[i],
                address(_avatar)
            );
        }
        controller.metaData(_metaData, _avatar);
        // Unregister self:
        controller.unregisterScheme(address(this), address(_avatar));
        // Remove lock:
        lock = address(0);
        emit InitialSchemesSet(address(_avatar));
    }

    /**
     * @dev Create a new organization
     * @param _tokenName The name of the token associated with the organization
     * @param _tokenSymbol The symbol of the token
     * @param _founders An array with the addresses of the founders of the organization
     * @param _avatarTokenAmount Amount of tokens that the avatar receive on startup
     * @param _foundersReputationAmount An array of amount of reputation that the
     *   founders receive in the new organization
     * @param  _cap token cap - 0 for no cap.
     * @return The address of the avatar of the controller
     */
    function _forgeOrg(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cap,
        FeeFormula _formula,
        Identity _identity,
        address[] memory _founders,
        uint256 _avatarTokenAmount,
        uint256[] memory _foundersReputationAmount
    ) private returns (address) {
        // Create Token, Reputation and Avatar:
        require(lock == address(0), "Lock already exists");
        require(
            _founders.length == _foundersReputationAmount.length,
            "Founder reputation missing"
        );
        require(_founders.length > 0, "Must have at least one founder");
        GoodDollar nativeToken = new GoodDollar(
            _tokenName,
            _tokenSymbol,
            _cap,
            _formula,
            _identity,
            address(0)
        );
        Reputation nativeReputation = new Reputation();

        // renounce minter
        nativeToken.addMinter(address(addFoundersGoodDollar));
        nativeToken.renounceMinter();

        nativeToken.transferOwnership(address(addFoundersGoodDollar));
        nativeReputation.transferOwnership(address(addFoundersGoodDollar));

        avatar = addFoundersGoodDollar.addFounders(
            nativeToken,
            nativeReputation,
            msg.sender,
            _founders,
            _avatarTokenAmount,
            _foundersReputationAmount
        );

        nativeToken.addPauser(address(avatar));

        lock = msg.sender;

        emit NewOrg(address(avatar));
        return (address(avatar));
    }
}