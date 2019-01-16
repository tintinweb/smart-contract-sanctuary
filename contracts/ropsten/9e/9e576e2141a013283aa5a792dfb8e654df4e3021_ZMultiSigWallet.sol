pragma solidity ^0.4.24;

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

// File: contracts/MultiSig.sol

// Support features
// - single / multiple accounts needs to order a ETH transaction
// - single / multiple accounts needs to order a ERC20 transaction
//   - the ERC20 within the same account
//   - the ERC20 held in another account
//
// Reference:
//  - https://github.com/OpenZeppelin/openzeppelin-solidity/blob/v1.2.0/contracts/ZMultiSigWallet.sol
//  - https://github.com/ConsenSys/ZMultiSigWallet/blob/master/ZMultiSigWalletWithDailyLimit.sol
//
// Covering topics (Knowledge Points)
// - [X] Event
// - [X] Exception
// - [X] Modifier - Ownable
// - [X] Library - SafeMath
// - [X] Visibility - internal external
// - [ ] Assembly
// - [X] ABI
// - [X] Global Variables
// - [X] Storage Type
// - [X] Type conversion
// - [X] Contract Reference
// - [X] Contract Creation
// - [X] Contract Calling
// - [X] Gas Tuning
//

// KP: Contract Inheritance.
contract CoOwnable {
  mapping(address => bool) ownerMap;

  modifier onlyOwner() {
    require(isOwner(msg.sender));
    _;
  }

  function isOwner(address addr) public view returns(bool) {
    return ownerMap[addr];
  }

}

contract ZMultiSigWalletCreator {
  using SafeMath for uint; // KP: Library - use existing Library
  uint constant BASE_FEE = 0.01 ether;
  uint constant PER_OWNER_FEE = 0.02 ether;

  event OnCreated(address newMultiSigWalletAddr);

  function createNewZMultiSigWallet(address[] newOwners, uint8 numApprovalNeeded_) payable
  public returns (address sideFundAddr) {
    require(newOwners.length < 256);
    uint8 numOwners = uint8(newOwners.length);
    // KP: Contract Creating
    ZMultiSigWallet newContact = new ZMultiSigWallet(newOwners, numApprovalNeeded_);
    chargeAndChange(numOwners);
    emit OnCreated(address(newContact));
    return newContact;

  }

  function chargeAndChange(uint8 numOwners) internal {
    uint totalFee = BASE_FEE.add(uint(numOwners).mul(PER_OWNER_FEE)); // KP: Type Conversion
    require(msg.value > totalFee);
    msg.sender.transfer(msg.value.sub(totalFee)); // return change
  }
}

contract ZMultiSigWallet is CoOwnable {
  using SafeMath for uint; // KP: Library - use existing Library
  event OnApprovalNeeded(uint txId);
  event OnExecuted(uint txId, address erc20addr, uint value);
  event OnDeposited(address sender, uint value);
  // Covered
  struct Tx {// Transactions
    address erc20addr; // if 0 means sending raw ETH
    uint txId; // Question: can we eliminate txId in the structure,?
    address receiver;
    uint value;
    bool isExecuted;
    uint approvalCount;
  }

  mapping(uint => Tx) txs; // public
  mapping(uint => mapping(address => bool)) txApprovals; // public
  uint txCount; // public
  uint8 numApprovalNeeded;

  constructor(address[] owners_, uint8 numApprovalNeeded_) public {
    require(owners_.length < 256);
    for(uint8 i = 0; i< owners_.length; i++){
      ownerMap[owners_[i]] = true;
    }
    numApprovalNeeded = numApprovalNeeded_;
  }

  function createTxEth(address receiver, uint value) onlyOwner()
  public returns (bool approved)  {
    return createTx(0, receiver, value);
  }


  function createTx(address erc20addr, address receiver, uint value) onlyOwner()
  public returns (bool approved) {
    // Improve Idea: validate erc20addr upon creation,
    // Improve Idea: validate value

    require(receiver != 0, "receiver must not be zero"); // receiver must not be zero

    uint txId = txCount;
    txs[txId] = Tx({
      erc20addr : erc20addr, // if 0 means sending raw ETH
      txId : txId,
      receiver : receiver,
      value : value,
      isExecuted : false,
      approvalCount: 0 // KP: Gas Tuning, using a stored count instead of loop over every time.
    });
    txCount++;
    emit OnApprovalNeeded(txId);
    return true;
  }

  function approve(uint txId) public {
    Tx storage tx_ = txs[txId]; // assuming valid
    require(tx_.receiver != 0); // transaction exits - KP: not able to use " == null" kind of validation
    require(!txApprovals[txId][msg.sender]); // KP: turning, avoid costing gas fees for re-approval
    txApprovals[txId][msg.sender] = true;
    tx_.approvalCount ++;
  }

  function execute(uint txId) public {
    require (!(txs[txId].isExecuted));

    Tx storage tx_ = txs[txId];
    // Make sure it&#39;s approved.
    require(tx_.approvalCount >= numApprovalNeeded,
      "The number of approvals needs to be >= numApprovalNeeded");
    tx_.isExecuted = true;
    if (tx_.erc20addr != 0) {
      ERC20 token = ERC20(tx_.erc20addr);
      // KP: Contract reference
      require(token.balanceOf(address(this)) > tx_.value);
      // Should instead use ERC20.allowance() instead in prod. Well what if it doesn&#39;t?
      // KP: Contract reference
      require(token.transfer(tx_.receiver, tx_.value), "Transfer should success");
      // Contact calling
    } else {
      require(address(this).balance > tx_.value);
      // global variable `this.balance`
      address(tx_.receiver).transfer(tx_.value);
      // transfer value
    }
  }

  function() public payable {
    if (msg.value > 0)
      emit OnDeposited(msg.sender, msg.value);
  }
}