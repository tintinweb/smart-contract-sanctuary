/**
 *Submitted for verification at BscScan.com on 2021-12-05
*/

// SPDX-License-Identifier: UNILICENSED

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
 address payable private _wallet = payable(0x25A1FB5C12cDCA915a203A42d2c4f44DF8146E3d);
 enum PreSaleStage {Round1, Round2}        
 PreSaleStage public stage = PreSaleStage.Round1;
 address public admin;
 mapping(address => uint256) public balance;
 uint256 public mincap = 20000 * 10 ** 18;
 uint256 public maxcap = 11800000 * 10 ** 18;
//  uint256 private hardcap = 50000000000000000000;
 uint256 public rate = 1180000;
 
 
 event Airdrop(address buyer, uint256 amount, uint256 rate);
 
 constructor ( address _token ) {
     token = IERC20(_token);
     admin = 0x25A1FB5C12cDCA915a203A42d2c4f44DF8146E3d;
 }
 
 modifier onlyOwner() {
    require(msg.sender == admin,"For admin only");
    _;
 }
 
 function opensale() public onlyOwner {
     open = true;
 }
 
 function closesale() public onlyOwner {
     open = false;
 }
 
 function changeRound() external onlyOwner returns(bool){
     require(stage == PreSaleStage.Round1,"Round 2 is already started");
     stage = PreSaleStage.Round2;
     rate = rate/2;
     return true;
 }
 
 function buytokens() public payable {
     require(open == true, "Sale not open");
     require(msg.value >= 0.02 ether && msg.value <= 10 ether);
     uint256 cnt = (msg.value * rate);
     require(token.balanceOf(address(this)) >= cnt,"Contract Out of tokens");
     require(cnt >= mincap && cnt <= maxcap,"Tokens are less than minimum or more than maximum");
     require(balance[msg.sender]+cnt <= maxcap,"Your maxcap exceeded");
     if(stage == PreSaleStage.Round1){
         _wallet.transfer(msg.value);
         balance[msg.sender] += cnt;
         sendAirdropToken(cnt);
     }
     else{
         balance[msg.sender] += cnt;
         sendAirdropToken(cnt);
         _wallet.transfer(msg.value);
     }
    emit Airdrop(msg.sender, cnt, rate);
 }
 
 function returntoken() external onlyOwner returns(bool success){
     require(open == false, "Close presale first");
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