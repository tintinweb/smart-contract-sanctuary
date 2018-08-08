pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
 * @title HolderBase
 * @notice HolderBase handles data & funcitons for token or ether holders.
 * HolderBase contract can distribute only one of ether or token.
 */
contract HolderBase is Ownable {
  using SafeMath for uint256;

  uint8 public constant MAX_HOLDERS = 64; // TODO: tokyo-input should verify # of holders
  uint256 public coeff;
  bool public distributed;
  bool public initialized;

  struct Holder {
    address addr;
    uint96 ratio;
  }

  Holder[] public holders;

  event Distributed();

  function HolderBase(uint256 _coeff) public {
    require(_coeff != 0);
    coeff = _coeff;
  }

  function getHolderCount() public view returns (uint256) {
    return holders.length;
  }

  function initHolders(address[] _addrs, uint96[] _ratios) public onlyOwner {
    require(!initialized);
    require(holders.length == 0);
    require(_addrs.length != 0);
    require(_addrs.length <= MAX_HOLDERS);
    require(_addrs.length == _ratios.length);

    uint256 accRatio;

    for(uint8 i = 0; i < _addrs.length; i++) {
      if (_addrs[i] != address(0)) {
        // address will be 0x00 in case of "crowdsale".
        holders.push(Holder(_addrs[i], _ratios[i]));
      }

      accRatio = accRatio.add(uint256(_ratios[i]));
    }

    require(accRatio <= coeff);

    initialized = true;
  }

  /**
   * @dev Distribute ether to `holder`s according to ratio.
   * Remaining ether is transfered to `wallet` from the close
   * function of RefundVault contract.
   */
  function distribute() internal {
    require(!distributed, "Already distributed");
    uint256 balance = this.balance;

    require(balance > 0, "No ether to distribute");
    distributed = true;

    for (uint8 i = 0; i < holders.length; i++) {
      uint256 holderAmount = balance.mul(uint256(holders[i].ratio)).div(coeff);

      holders[i].addr.transfer(holderAmount);
    }

    emit Distributed(); // A single log to reduce gas
  }

  /**
   * @dev Distribute ERC20 token to `holder`s according to ratio.
   */
  function distributeToken(ERC20Basic _token, uint256 _targetTotalSupply) internal {
    require(!distributed, "Already distributed");
    distributed = true;

    for (uint8 i = 0; i < holders.length; i++) {
      uint256 holderAmount = _targetTotalSupply.mul(uint256(holders[i].ratio)).div(coeff);
      deliverTokens(_token, holders[i].addr, holderAmount);
    }

    emit Distributed(); // A single log to reduce gas
  }

  // Override to distribute tokens
  function deliverTokens(ERC20Basic _token, address _beneficiary, uint256 _tokens) internal {}
}


/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  /**
   * @param _wallet Vault address
   */
  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  /**
   * @param investor Investor address
   */
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  /**
   * @param investor Investor address
   */
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}


/**
 * @title MultiHolderVault
 * @dev This contract distribute ether to multiple address.
 */
contract MultiHolderVault is HolderBase, RefundVault {
  using SafeMath for uint256;

  function MultiHolderVault(address _wallet, uint256 _ratioCoeff)
    public
    HolderBase(_ratioCoeff)
    RefundVault(_wallet)
  {}

  function close() public onlyOwner {
    require(state == State.Active);
    require(initialized);

    super.distribute(); // distribute ether to holders
    super.close(); // transfer remaining ether to wallet
  }
}