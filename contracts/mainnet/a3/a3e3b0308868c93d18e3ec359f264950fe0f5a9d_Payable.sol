pragma solidity ^0.4.18;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);

  event Transfer(address indexed from, address indexed to, uint256 value);

  function totalSupply() public constant returns (uint256);

  function balanceOf(address who) public constant returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  function allowance(address owner, address spender) public constant returns (uint256);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
}


/**
 * @title ERC20 token
 *
 * @dev Implementation of the ERC20 token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20Token is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   * @return An uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    public returns (bool success)
  {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    public returns (bool success)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address[] public owners;

  event OwnerAdded(address indexed authorizer, address indexed newOwner, uint256 index);

  event OwnerRemoved(address indexed authorizer, address indexed oldOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owners.push(msg.sender);
    OwnerAdded(0x0, msg.sender, 0);
  }

  /**
   * @dev Throws if called by any account other than one owner.
   */
  modifier onlyOwner() {
    bool isOwner = false;

    for (uint256 i = 0; i < owners.length; i++) {
      if (msg.sender == owners[i]) {
        isOwner = true;
        break;
      }
    }

    require(isOwner);
    _;
  }

  /**
   * @dev Allows one of the current owners to add a new owner
   * @param newOwner The address give ownership to.
   */
  function addOwner(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    uint256 i = owners.push(newOwner) - 1;
    OwnerAdded(msg.sender, newOwner, i);
  }

  /**
   * @dev Allows one of the owners to remove other owner
   */
  function removeOwner(uint256 index) onlyOwner public {
    address owner = owners[index];
    owners[index] = owners[owners.length - 1];
    delete owners[owners.length - 1];
    OwnerRemoved(msg.sender, owner);
  }

  function ownersCount() constant public returns (uint256) {
    return owners.length;
  }
}


contract UpgradableStorage is Ownable {

  // Address of the current implementation
  address internal _implementation;

  event NewImplementation(address implementation);

  /**
  * @dev Tells the address of the current implementation
  * @return address of the current implementation
  */
  function implementation() public view returns (address) {
    return _implementation;
  }
}


/**
 * @title Upgradable
 * @dev This contract represents an upgradable contract
 */
contract Upgradable is UpgradableStorage {
  function initialize() public payable { }
}


/**
 * Base Contract (KNW)
 * Upgradable Standard ECR20 Token
 */
contract Base is Upgradable, ERC20Token {
  function name() pure public returns (string) {
    return &#39;Knowledge.io&#39;;
  }

  function symbol() pure public returns (string) {
    return &#39;KNW&#39;;
  }

  function decimals() pure public returns (uint8) {
    return 8;
  }

  function INITIAL_SUPPLY() pure public returns (uint) {
    /** 150,000,000.00000000 KNW tokens */
    return 15000000000000000;
  }

  function totalSupply() view public returns (uint) {
    return INITIAL_SUPPLY();
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * A token upgrade mechanism where users can upgrade tokens
 * to the next smart contract revision.
 *
 * First envisioned by Golem and Lunyr projects.
 */
contract Legacy is Base {
  using SafeMath for uint256;

  /** The contract from which we upgrade */
  Legacy public prevContract;

  /**
   * Somebody has upgraded some of their tokens.
   */
  event UpgradeFrom(address indexed _from, address indexed _to, uint256 _value);

  /**
   * Previous contract available.
   */
  event PrevContractSet(address contractAddress);

  modifier fromPrevContract() {
    require(msg.sender == address(prevContract));
    _;
  }

  function upgradeFrom(address holder, uint256 value) fromPrevContract public returns (bool) {
    balances[holder] = value;
    Transfer(address(0), holder, value);
    UpgradeFrom(address(prevContract), holder, value);

    return true;
  }

  function setPrevContract(address contractAddress) onlyOwner public returns (bool) {
    require(contractAddress != 0x0);
    prevContract = Legacy(contractAddress);
    PrevContractSet(contractAddress);

    return true;
  }
}


/**
 * Payable is meant to execute the `transfer` method of the ERC20 Token
 * and log a Pay message with a reference message to bind the payment to an
 * order id or some other identifier
 */
contract Payable is Legacy {
  struct PaymentRequest {
    uint256 fee;
    uint256 value;
    address seller;
  }

  mapping (address => mapping(string => PaymentRequest)) private pendingPayments;

  event Pay(
    address indexed from,
    address indexed seller,
    address indexed store,
    uint256 value,
    uint256 fee,
    string ref
  );

  function requestPayment(uint256 value, uint256 fee, string ref, address to) public {
    pendingPayments[msg.sender][ref] = PaymentRequest(fee, value, to);
  }

  function cancelPayment(string ref) public {
    delete pendingPayments[msg.sender][ref];
  }

  function paymentInfo(address store, string ref) public view returns (uint256 value, uint256 fee, address seller) {
    PaymentRequest memory paymentRequest = pendingPayments[store][ref];
    value = paymentRequest.value;
    fee = paymentRequest.fee;
    seller = paymentRequest.seller;
  }

  function pay(address store, string ref) public returns (bool) {
    PaymentRequest memory paymentRequest = pendingPayments[store][ref];

    if (paymentRequest.fee > 0) {
      assert(transfer(store, paymentRequest.fee));
    }

    assert(transfer(paymentRequest.seller, paymentRequest.value));

    Pay(msg.sender, paymentRequest.seller, store, paymentRequest.value, paymentRequest.fee, ref);
    delete pendingPayments[store][ref];

    return true;
  }
}