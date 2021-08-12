/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract presale {
    
 IERC20 token;
 bool public open = false;
 address payable private _wallet = payable(0x05Dc135fD33732C3f123a243f554746857f15917);
 enum PreSaleStage {Round1, Round2}
 PreSaleStage public stage = PreSaleStage.Round1;
 address private admin;
 mapping(address=>bool) public whitelisted;
 mapping(address => uint256) public balance;
 uint256 public mincap = 17600000000000000000;
 uint256 public maxcap = 2*176000000000000000000;
 uint256 public rate = 176;
 
 
 constructor ( address _token) {
     token = IERC20(_token);
     admin = msg.sender;
 }
 
 modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }
 
 function opensale() public onlyOwner {
     open = true;
 }
 
 function closesale() public onlyOwner {
     open = false;
 }
 
 function changeRound() external onlyOwner returns(bool){
     require(stage == PreSaleStage.Round1);
     stage = PreSaleStage.Round2;
     return true;
 }
 
 function addWhitelist (address _add) public onlyOwner returns(bool){
     whitelisted[_add] = true;
     return true;
 }
 
 function buytokens() public payable {
     require(open == true);
     require(msg.value >= 0.1 ether && msg.value <= 2 ether);
     uint256 cnt = msg.value * rate;
     require(token.balanceOf(address(this)) >= cnt);
     require(cnt >= mincap && cnt <= maxcap);
     require(balance[msg.sender]+cnt <= maxcap);
     if(stage == PreSaleStage.Round1){
         require(whitelisted[msg.sender] == true);
         balance[msg.sender] += cnt;
         sendAirdropToken(cnt);
         _wallet.transfer(msg.value);
     }
     else{
         balance[msg.sender] += cnt;
         sendAirdropToken(cnt);
         _wallet.transfer(msg.value);
     }
 }
 
 function returntoken() external onlyOwner returns(bool success){
     token.transfer(admin,token.balanceOf(address(this)));
     return true;
 }
 
 function sendAirdropToken(uint256 cnt) internal returns (bool success){
    token.transfer(msg.sender,cnt);
    return true;
 }
 
 receive() payable external {
     buytokens();
 } 
}