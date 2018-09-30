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

contract payment is Ownable {
  event EtherPay(uint256 balance, address[] _receivers, uint256[] _shares);
  event TokenTransfer(address token, address owner, uint256 amount);

  using SafeMath for uint256;

  address public feeWallet;
  uint256 public adminFee = 2 * (10 ** 15); //0.0001 = 10**14, 0.001 = 10**15, 0.01 = 10**16, 0.1 = 10 ** 17

  constructor(address _adminWallet) public {
    require(_adminWallet != address(0));
    feeWallet = _adminWallet;
  }

  function() public payable {

  }

  function payEther(address[] _receivers, uint256[] _shares) public payable {
    uint256 pay = msg.value;
    require(_receivers.length == _shares.length);
    require(_receivers.length > 0);

    // require(pay.sub(adminFee.mul(_receivers.length)) > 5000000000000000);  //0.005

    uint256 totalShares = 0;
    uint256 fee = 0;
    
    uint256 length = _receivers.length;
    for (uint256 i = 0; i < length; i++) {
      totalShares += _shares[i];
    }
    for (uint256 j = 0; j < length; j++) {
      uint256 eth_ = pay.mul(_shares[j]).div(totalShares);
      fee += adminFee;
      _receivers[j].transfer(eth_ - adminFee);
    }
    // for (uint256 i = 0; i < _receivers.length; i++) {
    //   require(_receivers[i] != address(0));
    //   require(_shares[i] > 0);
    //   fee += adminFee;
    //   totalShares = totalShares.add(_shares[i]);
    // }
    // for (uint256 j = 0; j < _receivers.length; j++) {
    //   uint256 eth_ = pay.mul(_shares[j]).div(totalShares);
    //   _receivers[j].transfer(eth_.sub(adminFee));
    // }
    emit EtherPay(pay, _receivers, _shares);
    feeWallet.transfer(fee);
    // feeWallet.transfer(adminFee.mul(_receivers.length));
  }
  function transferToken(address token, uint256 amount) external onlyOwner{
    require(amount > 0);
    require(ERC20Basic(token).transfer(msg.sender, amount));
    emit TokenTransfer(token, msg.sender, amount);
  }
  function updateFee(uint256 _fee) public onlyOwner{
    adminFee = _fee;
  }
  function updateFeeWallet(address _address) public onlyOwner{
    feeWallet = _address;
  }
}