/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

pragma solidity ^ 0.4.26;

library SafeMath {

 function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
  if (a == 0) {
   return 0;
  }
  c = a * b;
  assert(c / a == b);
  return c;
 }

 function div(uint256 a, uint256 b) internal pure returns(uint256) {
  return a / b;
 }

 function sub(uint256 a, uint256 b) internal pure returns(uint256) {
  assert(b <= a);
  return a - b;
 }

 function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
  c = a + b;
  assert(c >= a);
  return c;
 }

}

contract TOKEN {
 function totalSupply() external view returns(uint256);
 function balanceOf(address account) external view returns(uint256);
 function transfer(address recipient, uint256 amount) external returns(bool);
 function allowance(address owner, address spender) external view returns(uint256);
 function approve(address spender, uint256 amount) external returns(bool);
 function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
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

contract CLWPR is Ownable {

 string public name = "CLWPR Club";
 string public symbol = "CLWPR";
 uint8 constant public decimals = 18;
 uint256 internal entryFee_ = 10; // 10%
 uint256 internal transferFee_ = 1;
 uint256 internal exitFee_ = 10; // 10%
 uint256 internal referralFee_ = 20; // 2% of the 10% fee 
 uint256 constant internal magnitude = 2 ** 64;
 mapping(address => uint256) internal stakeholders;
 TOKEN erc20;
 
 constructor() public {
  erc20 = TOKEN(address(0x9208E76E9CdC4Df70216421B928C4a9b46adfc61));
 }
 
 function checkAndTransfer(uint256 _amount) private {
  require(erc20.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
 }
 
 function buy(uint256 _amount) public returns(uint256) {
     checkAndTransfer(_amount);
     return purchaseTokens(msg.sender, _amount);
 }
 
 function purchaseTokens(address _customerAddress, uint256 _amount) public returns(uint256) {
    uint256 _amountOfTokens = SafeMath.mul(SafeMath.div(_amount, 100), (100 - entryFee_));
    stakeholders[_customerAddress] = SafeMath.add(stakeholders[_customerAddress], _amountOfTokens);
    return _amountOfTokens;
 }
 
 function balanceOf(address _customerAddress) public view returns(uint256) {
  return stakeholders[_customerAddress];
 }
 
}