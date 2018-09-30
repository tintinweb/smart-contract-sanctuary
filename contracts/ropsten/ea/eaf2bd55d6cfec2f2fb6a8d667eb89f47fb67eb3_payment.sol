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
  event TransferFail(uint256 index, address receiver, uint256 amount);
  event EtherPay(uint256 balance, address[] addressList, uint256[] ratioList);
  event TokenTransfer(address token, address owner, uint256 amount);

  using SafeMath for uint256;

  uint256 constant public GAS_PER_SPLIT_IN_SPLITALL = 10000;

  address public feeWallet;
  uint256 public adminFee = 5 * (10 ** 15); //0.0001 = 10**14, 0.001 = 10**15, 0.01 = 10**16, 0.1 = 10 ** 17

  constructor(address _adminWallet) public {
    require(_adminWallet != address(0));
    feeWallet = _adminWallet;
  }

  function() public payable {

  }

  function payEther(address[] _addressList, uint[] _ratio) external payable {
    require(_addressList.length == _ratio.length);
    uint256 minerFee = GAS_PER_SPLIT_IN_SPLITALL.mul(tx.gasprice);
    uint256 cost = adminFee.mul(_addressList.length).add(minerFee.mul(_addressList.length + 1));
    uint256 amount = msg.value;
    uint256 totalRatio = 0;

    require(amount.sub(cost) > 5000000000000000);  //0.005
    
    for (uint256 i = 0; i < _addressList.length; i++) {
      totalRatio = totalRatio.add(_ratio[i]);
    }

    for (uint256 j = 0; j < _addressList.length; j++) {
      uint256 eth_ = amount.mul(_ratio[j]).div(totalRatio).sub(minerFee).sub(adminFee);
      if (!_addressList[j].send(eth_)) {
        emit TransferFail(j, _addressList[j], eth_);
        return;
      }
    }

    emit EtherPay(amount, _addressList, _ratio);
    feeWallet.transfer(adminFee.mul(_addressList.length).sub(minerFee));
    msg.sender.transfer(minerFee.mul(_addressList.length + 1));
  }

  function transferToken(address token, uint256 amount) external onlyOwner {
    require(amount > 0);
    require(ERC20Basic(token).transfer(msg.sender, amount));
    emit TokenTransfer(token, msg.sender, amount);
  }
}