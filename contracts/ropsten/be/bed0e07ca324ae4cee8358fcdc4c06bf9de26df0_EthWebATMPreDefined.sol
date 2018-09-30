pragma solidity 0.4.24;


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  function transfer(address to, uint256 value) public returns(bool);
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract EthWebATMPreDefined is Ownable {

  using SafeMath for uint256;

  uint256 private _totalShares = 0;
  uint256 private _totalCount = 0;

  mapping(address => bool) private isAdmin;
  mapping(address => uint256) private _shares;
  address[] private _payees;

  address public feeWallet;
  uint256 public adminFee = 1 * (10 ** 15); //0.001 = 10**15, 0.01 = 10**16, 0.1 = 10 ** 17

  modifier onlyAdmin {
    require(msg.sender == owner || isAdmin[msg.sender]);
    _;
  }

  constructor(address[] payees, uint256[] shares, address _adminWallet) public {
    require(shares.length == payees.length);
    require(shares.length > 0);
    _totalCount = shares.length;
    _totalShares = 0;
    feeWallet = _adminWallet;

    for (uint256 i = 0; i < shares.length; i++) {
       _addPayee(payees[i], shares[i]);
    }
  }

  function() public payable {

  }

  function _addPayee(address account, uint256 shares_) internal {
    require(account != address(0));
    require(shares_ > 0);
    require(_shares[account] == 0);

    _payees.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares.add(shares_);
  }

  function updateShare(address[] payees, uint256[] shares) external onlyOwner {
    require(shares.length == payees.length);
    require(shares.length > 0);
    _totalCount = shares.length;
    _totalShares = 0;

    for (uint256 i = 0; i < shares.length; i++) {
       _addPayee(payees[i], shares[i]);
    }
  }

  function payEther() external onlyAdmin {
    uint256 amount = address(this).balance;
    uint256 cost = adminFee.mul(_totalCount);
    require(amount.sub(cost) > 0);

    for (uint256 i = 0; i < _totalCount; i++) {
      uint256 payment = amount.mul(_shares[_payees[i]]).div(_totalShares).sub(adminFee);
      require(payment != 0);
      _payees[i].transfer(payment);
    }

    feeWallet.transfer(adminFee.mul(_totalCount));
  }

  function transferToken(address token, uint256 amount) external onlyOwner {
    require(amount > 0);
    require(ERC20Basic(token).transfer(msg.sender, amount));
  }

  function addAdmin(address newAdmin) external onlyOwner {
    isAdmin[newAdmin] = true;
  }

  function removeAdmin(address removedAddress) external onlyOwner {
    isAdmin[removedAddress] = false;
  }

  function updateAdminFee(uint _newFee) external onlyOwner {
    adminFee = _newFee;
  }

  function getBalance() public view onlyAdmin returns(uint) {
    return address(this).balance;
  }

  function checkAdmin(address _checkAddress) public view returns(bool) {
    return isAdmin[_checkAddress];
  }
}