pragma solidity 0.4.23;

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
 *  @title TokenSale
 *  @dev Martin Halford, CTO, BlockGrain (AgriChain Pty Ltd) - April 2018
 */
contract TokenSale {
  using SafeMath for uint256;

  // Address of owner
  address public owner;

  // Address where funds are collected
  address public wallet;

  // Amount of raised (in Wei)
  uint256 public amountRaised;

  // Upper limit of the amount to be collected
  uint256 public saleLimit = 25000 ether;

  // Minimum contribution permitted
  uint256 public minContribution = 0.5 ether;

  // Maximum contribution permitted
  uint256 public maxContribution = 500 ether;

  // Flag to accept or reject payments
  bool public isAcceptingPayments;

  // List of admins who can edit the whitelist
  mapping (address => bool) public tokenSaleAdmins;

  // List of addresses that are whitelisted for private sale
  mapping (address => bool) public whitelist;

  // List of addresses that have made payments (in Wei)
  mapping (address => uint256) public amountPaid;

  // modifier to check owner
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // modifier to check whitelist admin status
  modifier onlyAdmin() {
    require(tokenSaleAdmins[msg.sender]);
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
  constructor(address _wallet) public {
    require(_wallet != address(0));
    owner = msg.sender;
    wallet = _wallet;
    tokenSaleAdmins[msg.sender] = true;
  }

  /**
   * @dev fallback function
   */
  function () isWhitelisted acceptingPayments payable public {
    uint256 _contribution = msg.value;
    require(_contribution >= minContribution);
    require(_contribution <= maxContribution);
    require(msg.sender != address(0));

    // add to sender&#39;s amountPaid record
    amountPaid[msg.sender] += _contribution;

    // add to amount raised
    amountRaised = amountRaised.add(_contribution);

    // handle edge case where amountRaised exceeds saleLimit
    if (amountRaised > saleLimit) {
      uint256 _refundAmount = amountRaised.sub(saleLimit);
      msg.sender.transfer(_refundAmount);
      _contribution = _contribution.sub(_refundAmount);
      _refundAmount = 0;
      amountRaised = saleLimit;
      isAcceptingPayments = false;
    }

    // transfer funds to external wallet
    wallet.transfer(_contribution);
  }

  /**
   * @dev Start accepting payments
   */
  function acceptPayments() onlyAdmin public  {
    isAcceptingPayments = true;
  }

  /**
   * @dev Stop accepting payments
   */
  function rejectPayments() onlyAdmin public  {
    isAcceptingPayments = false;
  }

  /**
   *  @dev Add a user to the whitelist admins
   */
  function addAdmin(address _admin) onlyOwner public {
    tokenSaleAdmins[_admin] = true;
  }

  /**
   *  @dev Remove a user from the whitelist admins
   */
  function removeAdmin(address _admin) onlyOwner public {
    tokenSaleAdmins[_admin] = false;
  }

  /**
   * @dev Add an address to the whitelist
   * @param _contributor The address of the contributor
   */
  function whitelistAddress(address _contributor) onlyAdmin public  {
    whitelist[_contributor] = true;
  }

  /**
   * @dev Add multiple addresses to the whitelist
   * @param _contributors The addresses of the contributor
   */
  function whitelistAddresses(address[] _contributors) onlyAdmin public {
    for (uint256 i = 0; i < _contributors.length; i++) {
      whitelist[_contributors[i]] = true;
    }
  }

  /**
   * @dev Remove an addresses from the whitelist
   * @param _contributor The addresses of the contributor
   */
  function unWhitelistAddress(address _contributor) onlyAdmin public  {
    whitelist[_contributor] = false;
  }

  /**
   * @dev Remove multiple addresses from the whitelist
   * @param _contributors The addresses of the contributor
   */
  function unWhitelistAddresses(address[] _contributors) onlyAdmin public {
    for (uint256 i = 0; i < _contributors.length; i++) {
      whitelist[_contributors[i]] = false;
    }
  }

  /**
   * @dev Update the sale limit
   * @param _saleLimit The updated sale limit value
   */
  function updateSaleLimit(uint256 _saleLimit) onlyAdmin public {
    saleLimit = _saleLimit;
  }

  /**
    * @dev Update the minimum contribution
    * @param _minContribution The updated minimum contribution value
    */
  function updateMinContribution(uint256 _minContribution) onlyAdmin public {
    minContribution = _minContribution;
  }

  /**
    * @dev Update the maximum contribution
    * @param _maxContribution The updated maximum contribution value
    */
  function updateMaxContribution(uint256 _maxContribution) onlyAdmin public {
    maxContribution = _maxContribution;
  }

}