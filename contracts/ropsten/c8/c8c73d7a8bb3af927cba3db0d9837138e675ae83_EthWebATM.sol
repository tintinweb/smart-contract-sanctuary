pragma solidity 0.4.24;


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

contract ERC20Basic {
  function transfer(address to, uint256 value) public returns(bool);
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

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

contract EthWebATM is Ownable {
  event EtherPay(uint256 _eth, address[] receivers, uint256[] shares);
  event TokenTransfer(address token, address owner, uint256 amount);

  using SafeMath for uint256;

  address public feeWallet;
  uint256 public adminFee = 1 * (10 ** 15);

  constructor(address _adminWallet) public{
    require(_adminWallet != address(0));
    feeWallet = _adminWallet;
  }

  function payEther(address[] receivers, uint256[] shares) external payable{
    require(receivers.length == shares.length);
    require(msg.value > adminFee.mul(shares.length));
    uint256 _eth = msg.value;
    uint256 totalshares = 0;
    
    for (uint256 i = 0; i < receivers.length; i++){
      require(shares[i] > 0);
      totalshares = totalshares.add(shares[i]);
    }

    for (uint256 j = 0; j < receivers.length; j++){
      uint256 eth_ = _eth.mul(shares[j]).div(totalshares).sub(adminFee);
      receivers[j].transfer(eth_);
    }

    emit EtherPay(_eth, receivers, shares);
    feeWallet.transfer(adminFee.mul(receivers.length));
  }

  function transferToken(address token, uint256 amount) external onlyOwner{
    require(amount > 0);
    require(ERC20Basic(token).transfer(msg.sender, amount));
    emit TokenTransfer(token, msg.sender, amount);
  }

  function updatefee(uint256 _eth) external onlyOwner{
    adminFee = _eth;
  }
  
  function updateWallet(address _address) external onlyOwner{
    feeWallet = _address;
  }
}