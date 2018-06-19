pragma solidity ^0.4.0;

contract TimeLapse {
  uint256 public openingTime;
  uint256 public closingTime;

  uint256 public constructionTime;

  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }
  modifier onlyAfterClosed {
    require(now > closingTime);
    _;
  }

  constructor(uint256 _openingTime, uint256 _closingTime) public {
    require(_openingTime >= now);
    require(_closingTime >= _openingTime);

    constructionTime = now;
    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  function hasClosed() public view returns (bool) {
    return now > closingTime;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Erc20Wallet {
  mapping (address => uint) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)

  event DepositReceived(address from, uint256 value);
  address token;

  uint256 public totalDeposited;

  constructor(address _token) public {
    token = _token;
  }

  function () public payable {
    revert();
  }

  function depositToken(uint amount) public {
    //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
    require (ERC20(token).transferFrom(msg.sender, this, amount));
    totalDeposited += amount;
    tokens[msg.sender] += amount;
    emit DepositReceived(msg.sender, amount);
  }

  function withdrawToken(address payee, uint256 payment) internal{
    totalDeposited -= payment;
    tokens[payee] -= payment;
    require (ERC20(token).transfer(payee, payment));
  }
}


/**
 * @title SplitERC20Payment
 * @dev Base contract that supports multiple payees claiming funds sent to this contract
 * according to the proportion they own.
 */
contract SplitErc20Payment is Erc20Wallet{
  using SafeMath for uint256;

  uint256 public totalShares = 0;
  uint256 public totalReleased = 0;

  mapping(address => uint256) public shares;
  mapping(address => uint256) public released;
  address[] public payees;

  constructor(address _token)
  Erc20Wallet(_token) public{
  }

  function depositToken(uint amount) public{
    super.depositToken(amount);
    if (shares[msg.sender] == 0)
      addPayee(msg.sender, amount);
    else
      addToPayeeBalance(msg.sender, amount);
  }
  /**
   * @dev Claim your share of the balance.
   */
  function claim() public {
    address payee = msg.sender;

    require(shares[payee] > 0);

    uint256 totalReceived = totalDeposited + totalReleased;
    uint256 payment = (totalReceived * shares[payee] / totalShares) - released[payee];

    require(payment != 0);
    require(totalDeposited >= payment);

    released[payee] = released[payee] + payment;
    totalReleased = totalReleased + payment;

    super.withdrawToken(payee, payment);
  }

  /**
   * @dev Add a new payee to the contract.
   * @param _payee The address of the payee to add.
   * @param _shares The number of shares owned by the payee.
   */
  function addPayee(address _payee, uint256 _shares) internal {
    require(_payee != address(0));
    require(_shares > 0);
    require(shares[_payee] == 0);

    payees.push(_payee);
    shares[_payee] = _shares;
    totalShares = totalShares.add(_shares);
  }
  /**
   * @dev Add to payee balance
   * @param _payee The address of the payee to add.
   * @param _shares The number of shares to add to the payee.
   */
  function addToPayeeBalance(address _payee, uint256 _shares) internal {
  require(_payee != address(0));
  require(_shares > 0);
  require(shares[_payee] > 0);

  shares[_payee] += _shares;
  totalShares = totalShares.add(_shares);
  }
}


contract ERC20Vault is TimeLapse, SplitErc20Payment{
  constructor(address _token, uint256 _openingTime, uint256 _closingTime)
  SplitErc20Payment(_token)
  TimeLapse(_openingTime, _closingTime)
  public{
  }

  function claim() public onlyAfterClosed{
    super.claim();
  }

  function depositToken(uint amount) public onlyWhileOpen{
    super.depositToken(amount);
  }
}