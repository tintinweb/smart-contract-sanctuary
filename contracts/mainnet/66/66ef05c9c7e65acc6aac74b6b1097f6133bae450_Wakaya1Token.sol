/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero"); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address payable private _owner;

  /**
   * Event that notifies clients about the ownership transference
   * @param previousOwner Address registered as the former owner
   * @param newOwner Address that is registered as the new owner
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns (address payable) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == _owner, "Ownable: Caller is not the owner");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0), "Ownable: New owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface IERC20 {

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address to, uint256 value) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 value)
    external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external view returns (uint256);

  /**
   * Event that notifies clients about the amount transferred
   * @param from Address owner of the transferred funds
   * @param to Destination address
   * @param value Amount of tokens transferred
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  /**
   * Event that notifies clients about the amount approved to be spent
   * @param owner Address owner of the approved funds
   * @param spender The address authorized to spend the funds
   * @param value Amount of tokens approved
   */
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title ERC20
 *
 * @dev Implementation of the basic standard token
 * functions declared in the IERC20 interface.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;

  uint256 public totalSupply;

  constructor(uint256 initialSupply) {
    require(msg.sender != address(0), "ERC20: create from the zero address");
    totalSupply = initialSupply;
    balances[msg.sender] = initialSupply;
    emit Transfer(address(0), msg.sender, initialSupply);
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param account The address to query the balance of.
   * @return An uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address account) external view override returns (uint256) {
    return balances[account];
  }

  /**
   * @dev Transfer token for a specified address
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
  function transfer(address to, uint256 value) public override returns (bool) {
    require(value <= balances[msg.sender], "ERC20: balance is not enough");
    require(to != address(0), "ERC20: transfer to the zero address");

    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);
    emit Transfer(msg.sender, to, value);
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
    override
    returns (bool)
  {
    require(value <= balances[from]);
    require(value <= allowed[from][msg.sender]);
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
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
  function approve(address spender, uint256 value) public override returns (bool) {
    require(spender != address(0), "ERC20: approve to the zero address");

    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
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
    external
    view
    override
    returns (uint256)
  {
    return allowed[owner][spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
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
    require(spender != address(0), "ERC20: spender is the zero address");

    allowed[msg.sender][spender] = (
      allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
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
    require(spender != address(0), "ERC20: spender is the zero address");

    allowed[msg.sender][spender] = (
      allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }
}

/**
 * @title Wakaya1Token
 * @dev Contract for token Wakaya 1 Token
 **/
contract Wakaya1Token is ERC20, Ownable {

  string public constant name = "Wakaya 1 Token";
  string public constant symbol = "WKY1";
  uint8 public constant decimals = 18;

  // Contract hash is the SHA-256 hash for the document of the security contract
  string public contractHash = "3CF0591CD6B34DA949E8A2F647E97AE352C6A96D743E38125685264FFD317A5F";

  /**
   * Event that notifies the update of the contract hash
   * @param previousContractHash Address registered as the former owner
   * @param newContractHash Address that is registered as the new owner
   */
  event ContractHashUpdated(
    string previousContractHash,
    string newContractHash
  );

  // Initial supply is the balance assigned to the owner
  uint256 private constant _initialSupply = 75000 * (10 ** uint256(decimals));

  /**
   * @dev Constructor
   */
  constructor()
    ERC20(_initialSupply)
  {
    require(msg.sender != address(0), "Wakaya 1 Token: Create contract from the zero address");
    emit ContractHashUpdated("", contractHash);
  }

  /**
   * @dev Allows to transfer out the ether balance that was sent into this contract
   */
  function withdrawEther() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0, "Wakaya 1 Token: No ether available to be withdrawn");
    owner().transfer(totalBalance);
  }

  /**
   * @dev Function for updating the contract hash, whenever the contract document is updated a new hash is generated
   * @param newContractHash The hash of the updated contract document.
   */
  function updateContractHash(string calldata newContractHash) external onlyOwner {
    emit ContractHashUpdated(contractHash, newContractHash);
    contractHash = newContractHash;
  }
}