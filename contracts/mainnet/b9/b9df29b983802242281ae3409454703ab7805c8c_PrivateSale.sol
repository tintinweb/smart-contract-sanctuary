pragma solidity 0.4.19;

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


contract PrivateSale {
  using SafeMath for uint256;

  // Address of owner
  address public owner;

  // Address where funds are collected
  address public wallet;

  // Amount of wei raised
  uint256 public weiRaised;

  // Flag to accept or reject payments
  bool public isAcceptingPayments;

  // List of admins who can edit the whitelist
  mapping (address => bool) public whitelistAdmins;

  // List of addresses that are whitelisted for private sale
  mapping (address => bool) public whitelist;
  uint256 public whitelistCount;

  // List of addresses that have made payments
  mapping (address => uint256) public weiPaid;

  uint256 public HARD_CAP = 6666 ether;

  // modifier to check owner
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // modifier to check whitelist admin status
  modifier onlyWhitelistAdmin() {
    require(whitelistAdmins[msg.sender]);
    _;
  }

  // modifier to check if whitelisted address
  modifier isWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  // modifier to check if payments being accepted
  modifier acceptingPayments() {
    require(isAcceptingPayments);
    _;
  }

  /**
   * Constructor
   * @param _wallet Address where collected funds will be forwarded to
   */
  function PrivateSale(address _wallet) public {
    require(_wallet != address(0));
    owner = msg.sender;
    wallet = _wallet;
    whitelistAdmins[msg.sender] = true;
  }

  /**
   * @dev fallback function
   */
  function () isWhitelisted acceptingPayments payable public {
    require(msg.value >= 0.2 ether);
    require(msg.value <= 500 ether);
    require(msg.sender != address(0));
    
    uint256 contribution = msg.value;
    // add to sender&#39;s weiPaid record
    weiPaid[msg.sender] += msg.value;

    // add to amount raised
    weiRaised = weiRaised.add(msg.value);

    if (weiRaised > HARD_CAP) {
      uint256 refundAmount = weiRaised.sub(HARD_CAP);
      msg.sender.transfer(refundAmount);
      contribution = contribution.sub(refundAmount);
      refundAmount = 0;
      weiRaised = HARD_CAP;
      isAcceptingPayments = false;
    }

    // transfer funds to external wallet
    wallet.transfer(contribution);
  }

  /**
   * @dev Start accepting payments
   */
  function acceptPayments() onlyOwner public  {
    isAcceptingPayments = true;
  }

  /**
   * @dev Stop accepting payments
   */
  function rejectPayments() onlyOwner public  {
    isAcceptingPayments = false;
  }

  /**
   *  @dev Add a user to the whitelist admins
   */
  function addWhitelistAdmin(address _admin) onlyOwner public {
    whitelistAdmins[_admin] = true;
  }

  /**
   *  @dev Remove a user from the whitelist admins
   */
  function removeWhitelistAdmin(address _admin) onlyOwner public {
    whitelistAdmins[_admin] = false;
  }

  /**
   * @dev Add an address to the whitelist
   * @param _user The address of the contributor
   */
  function whitelistAddress(address _user) onlyWhitelistAdmin public  {
    whitelist[_user] = true;
  }

  /**
   * @dev Add multiple addresses to the whitelist
   * @param _users The addresses of the contributor
   */
  function whitelistAddresses(address[] _users) onlyWhitelistAdmin public {
    for (uint256 i = 0; i < _users.length; i++) {
      whitelist[_users[i]] = true;
    }
  }

  /**
   * @dev Remove an addresses from the whitelist
   * @param _user The addresses of the contributor
   */
  function unWhitelistAddress(address _user) onlyWhitelistAdmin public  {
    whitelist[_user] = false;
  }

  /**
   * @dev Remove multiple addresses from the whitelist
   * @param _users The addresses of the contributor
   */
  function unWhitelistAddresses(address[] _users) onlyWhitelistAdmin public {
    for (uint256 i = 0; i < _users.length; i++) {
      whitelist[_users[i]] = false;
    }
  }
}