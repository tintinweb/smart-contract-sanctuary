/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

pragma solidity 0.6.0;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

interface IErc20Contract {
  function transferPresale1(address recipient, uint amount) external returns (bool);
}
contract LuckyPreSale1 {
  using SafeMath for uint;
  uint public constant _minimumDepositBNBAmount = 0.1 ether; // Minimum deposit is 1 BNB
  uint public constant _maximumDepositBNBAmount = 20 ether; // Maximum deposit is 20 BNB
  uint public constant _bnbAmountCap = 800 ether; // Allow cap at 800 BNB
  uint256 public startBlock;
  uint256 public endBlock;
  address payable public _admin; // Admin address
  address public _erc20Contract; // External erc20 contract
  uint256 public totalBNBAmout;
  address[] public addressList;
  event debug1(uint256 number,address _address);
  struct UserInfo{
  uint256 BuyTokenAmount;
  uint256 BNBAmout;
  }
  mapping (address => UserInfo) public userInfo;
  constructor() public {
    _admin = msg.sender;
    _erc20Contract = 0x3D8343bb49D068e054bee52Cc8FEDA1862b2e756;
    startBlock = 11231700;
    endBlock = 11451700;
  }
  modifier onlyAdmin() {
    require(_admin == msg.sender);
    _;
  }
  event Deposit(address indexed _from, uint _value);
  function transferOwnership(address payable admin) public onlyAdmin {
    require(admin != address(0), "Zero address");
    _admin = admin;
  }
receive() external payable{
  require(block.number >= startBlock,'Wait for pre-sale start!');
  require(msg.value >= _minimumDepositBNBAmount, 'it is less than minimum amount');
  require(msg.value <= _maximumDepositBNBAmount, 'it is more than maximum amount');
  userInfo[msg.sender].BNBAmout = userInfo[msg.sender].BNBAmout.add(msg.value);
  userInfo[msg.sender].BuyTokenAmount = userInfo[msg.sender].BuyTokenAmount.add(msg.value.mul(5000));
  if(userInfo[msg.sender].BNBAmout > 0){
      addressList.push(address(msg.sender));
}
}
  function Distribute() external onlyAdmin {
  require(block.number >= endBlock, "Distribution fail, have not reached the distribution date");
  IErc20Contract erc20Contract = IErc20Contract(_erc20Contract);
  for(uint256 i = 0;i < addressList.length; i++){
      address depositor = addressList[i];
      erc20Contract.transferPresale1(depositor,userInfo[depositor].BuyTokenAmount);
}

}
function withdrawAll() external onlyAdmin {
  _admin.transfer(address(this).balance);
}}