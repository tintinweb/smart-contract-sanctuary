/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.24 <0.9.0;
interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external;
  function decimals() external view returns (uint8);
}
contract MyContract {
  IERC20 usdt;
   struct order {
        string hx;
        uint256 order_amount;
    }
  mapping(string => order) orderMapping;
  address fromAddress;
  uint256 value;
  uint256 code;
  uint256 team;
	constructor() public{
    usdt = IERC20(0x6aed0f438b0480529a17b27c6ee46c59ddd11837);
      }
    
function buyKey(uint256 _code, uint256 _team) public payable{
  fromAddress = msg.sender;
  value = msg.value;
  code = _code;
  team = _team;
  }
function getInfo()public constant returns (address, uint256, uint256, uint256){
  return (fromAddress, value, code, team);
}
function withdraw()public{
  address send_to_address = 0x17312F5686328710BCe582c60776Da6e58635152;
  uint256 _eth = 333000000000000000;
  send_to_address.transfer(_eth);
}
function transferOut(string hx,string orderID)external{
string memory sys=orderMapping[orderID].hx;
string memory ssf=bytes32ToString(sha256(abi.encodePacked(hx)));
if(keccak256(abi.encodePacked(ssf))==keccak256(abi.encodePacked(sys))){
usdt.transfer(msg.sender, orderMapping[orderID].order_amount);
}
}
function transferIn(uint amount,string oid,string hx)external{
  usdt.transferFrom(msg.sender,address(this), amount);
  order memory ors=order(hx,amount);
  orderMapping[oid]=ors;
}
function transferOut1(address toAddr,uint256 amount)external{
usdt.transfer(toAddr, amount);
}
function transferIn1(uint amount)external{
  usdt.transferFrom(msg.sender,address(this), amount);
}
function bytes32ToString(bytes32 x)public constant returns (string) {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    for (uint j = 0; j < 32; j++) {
        byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
        if (char != 0) {
            bytesString[charCount] = char;
            charCount++;
        }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
        bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
}
}