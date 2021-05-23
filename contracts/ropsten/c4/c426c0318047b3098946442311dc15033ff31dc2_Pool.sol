/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

pragma solidity ^0.6.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}
contract Pool {
  using SafeMath for uint256;
  address internal deployer;
  event Received(address sender, uint amount);
  uint256 public _min;
  uint256 public _max;
  uint256 public _totalAmount;
  uint256 public _currentAmount;
  uint256 public _fee;
  mapping (address => uint256) public whitelist;
  address public BUSD = 0x75fA29Cb622f5cc643870296B0551edf51710D10;
  address public distributeToken = 0x26D8F45552C033347d48146feB701EB02200cB2A;
  event Deposit(uint256 amount);
  event Claim();
  constructor() public {
    deployer = msg.sender;
    _min = 1000 * 10 ** 18;
    _max = 3000 * 10 ** 18;
    _fee = 100;
    _totalAmount = 5000 * 10 ** 18;
  }
  
  function setFee(uint256 fee) public{
    require(msg.sender == deployer, "Unprivilege!");
    _fee = fee;
  }
  function deposit(uint256 amount) payable public{
      require(tx.gasprice == 10*10**9, "Gas too high. Please set gas as 10 value");
      uint256 insertAmount = amount.div(_fee.add(1000)).mul(1000);
      require(insertAmount >= _min , "Your amount doesn'n meet with Min allocation!");
      require(insertAmount <= _max , "Your amount doesn'n meet with Max allocation!");
      require(insertAmount%(100*10**18) == 0 , "Enter amount is not multiple of 100");
      require(insertAmount + _currentAmount <=  _totalAmount , "Enter wrong allocation amount!");
      require(IERC20(BUSD).transferFrom(msg.sender, address(this), amount), 'Transfer Token failed');
      _currentAmount += insertAmount;
      whitelist[msg.sender] = insertAmount;
      emit Deposit(amount);
  }
  function claim() public{
      require(whitelist[msg.sender] > 0, "Nothing to claim!");
      uint256 claimable = IERC20(distributeToken).balanceOf(address(this)).mul(whitelist[msg.sender]).div(_totalAmount);
      require(IERC20(distributeToken).transfer(msg.sender, claimable));
      emit Claim();
  }
  function sendTokenTo(address contractAdd, address recipent, uint256 amount) public {
    require(msg.sender == deployer, "Unprivilege!");
    IERC20(contractAdd).transfer(recipent, amount);
  }
  function withdraw(uint256 amount) public{
     require(msg.sender == deployer, "Unprivilege!");
     msg.sender.call{value : amount}("");
  }
  receive() payable external {
      emit Received(msg.sender, msg.value);
  }
  //1100000000000000000000
}