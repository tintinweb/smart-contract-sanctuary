pragma solidity ^0.4.24;

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

// File: openzeppelin-solidity/contracts/access/roles/PauserRole.sol

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

  /**
   * @return true if the contract is paused, false otherwise.
   */
  function paused() public view returns(bool) {
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

// File: contracts/LoanMaster.sol

contract LoanMaster is Pausable, Ownable {

    using SafeMath for uint256;

    event Deposited(address indexed creditor, uint256 deposit, uint256 balance);

    event DebtorApproved(address indexed debtor, uint256 loanAmount, uint256 interestRate);

    event Collateralized(address indexed debtor, uint256 loanAmount, uint256 tokenAmount);

    uint256 public balance = 0;
    uint256 private _totalDeposit = 0;
    uint256 private _loanCap;
    uint16 private _minTenorDays;
    uint16 private _maxTenorDays;
    address private _collateralToken;
    uint256 private _exchangeRate;
    uint256 private _interestRate;
    address private _creditor;
    address private _underwriter;

    // Note that the first value is 0 therefore must be assigned to an invalid state,
    // otherwise we won&#39;t be able to tell nonexist orders by looking in to the orders map.
    enum OrderState {INVALID, PRE_APPROVED, COLLATERALIZED, CLEARED, DEFAULT_CLEARED}

    struct Order {
        uint256 amount;
        uint256 interestRate;
        uint256 repaid;
        uint256 collateralDueDate;
        uint256 dueDate;
        OrderState state;
    }

    mapping(address => Order) private _orders;

    uint256 constant rateDecimals = 8;

    constructor(uint256 loanCap, uint16 minTenorDays, uint16 maxTenorDays,
                address collateralToken, uint256 exchangeRate,
                uint256 interestRate, address creditor, address underwriter) public {
        require(minTenorDays >= 10 && maxTenorDays <= 30 && minTenorDays <= maxTenorDays, "invalid tenor days");
        require(loanCap >= 0.01 ether && loanCap <= 999.99 ether, "loan cap must be between 0.01 and 999.99 ether inclusive");
        require(interestRate <= (10 ** rateDecimals) / 1000, "daily interest rate must not exeed 0.1%");

        _loanCap = loanCap;
        _minTenorDays = minTenorDays;
        _maxTenorDays = maxTenorDays;
        _collateralToken = collateralToken;
        _exchangeRate = exchangeRate;
        _interestRate = interestRate;
        _creditor = creditor;
        _underwriter = underwriter;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyCreditor() {
        require(isCreditor(), "creditor required");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isCreditor() private view returns(bool) {
        return msg.sender == _creditor;
    }

    modifier onlyDebtor() {
        require(isDebtor(), "debtor required");
        _;
    }

    function isDebtor() private view returns(bool) {
        return _orders[msg.sender].state != OrderState.INVALID;
    }

    modifier onlyUnderwriter() {
        require(isUnderwriter(), "Underwriter required");
        _;
    }

    function isUnderwriter() private view returns(bool) {
        return msg.sender == _underwriter;
    }

    /*
    function terminate() public onlyOwner() {
        _creditor.transfer(balance);
    }
    */

    // fallback eth receiver
    function () public payable {
        if (msg.sender == _creditor) {
            deposit();
        } else if (isDebtor()) {
            repay();
        } else {
            revert("only creditor or debtor may send ETH");
        }
    }

    function deposit() public payable onlyCreditor {
        require(_totalDeposit.add(msg.value) <= _loanCap, "total deposit must not exceed loanCap");

        balance = balance.add(msg.value);
        _totalDeposit = _totalDeposit.add(msg.value);

        emit Deposited(_creditor, msg.value, balance);
    }

    // TODO: do we need a public getRepaidAmount(address debtor) ?
    function getRepaidAmount() public view onlyDebtor returns(uint256) {
        return _orders[msg.sender].repaid;
    }

    function repay() public payable onlyDebtor {
        Order memory order = _orders[msg.sender];
        require(order.state == OrderState.COLLATERALIZED, "repayment is only accepted when loan is established");

        uint256 repaid = order.repaid.add(msg.value);
        require(repaid <= order.amount, "you&#39;re repaying too much");
        _orders[msg.sender].repaid = order.repaid.add(msg.value);

        // TODO: transfer eth to creditor when fully repaid, and return token to debtor after substracting interests
    }

    function preapprove(address debtor, uint256 amount, uint256 interestRate, uint16 tenorDays)
            public onlyUnderwriter {
        require(amount > 0, "amount must not be 0");
        require(tenorDays >= _minTenorDays && tenorDays <= _maxTenorDays, "invalid tenor days");
        require(interestRate <= (10 ** rateDecimals) / 1000, "daily interest rate must not exeed 0.1%");

        _orders[debtor] = Order({
            amount: amount,
            interestRate: interestRate,
            repaid: 0,
            collateralDueDate: now + 1 days,
            dueDate: now + tenorDays * 1 days,
            state: OrderState.PRE_APPROVED
        });

        emit DebtorApproved(debtor, amount, interestRate);
    }

    function collateralize(uint256 tokenAmount) public onlyDebtor {
        address debtor = msg.sender;
        Order memory order = _orders[debtor];

        require(now <= order.collateralDueDate, "too late for collaterals");
        require(order.state == OrderState.PRE_APPROVED, "you may not collateralize twice");

        // note that exchangeRate is based on token/ether, needs div(10 ** 18) here to convert Wei back to Ether
        uint256 collateralAmount = order.amount.mul(10 ** rateDecimals).div(_exchangeRate).div(uint256(10) ** 18);
        require(tokenAmount == collateralAmount, "incorrect token amount");

        ERC20 erc20token = ERC20(_collateralToken);

        require(erc20token.balanceOf(debtor) >= collateralAmount, "insufficient token balance");
        // Debtor must preauthorize transfer allowance to this contract first
        // NOTE: "this" is different to "owner"!
        require(erc20token.allowance(debtor, this) >= collateralAmount, "insufficient allowance");

        require(
            erc20token.transferFrom(
                debtor,
                this,
                tokenAmount
            ),
            "token transfer failed"
        );
        _orders[debtor].state = OrderState.COLLATERALIZED;

        require(balance >= order.amount, "insufficient eth on contract");
        balance = balance.sub(order.amount);
        debtor.transfer(order.amount);

        emit Collateralized(debtor, order.amount, tokenAmount);
    }
}