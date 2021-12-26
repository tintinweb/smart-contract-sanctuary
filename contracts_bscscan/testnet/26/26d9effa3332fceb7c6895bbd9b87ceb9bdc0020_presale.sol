/**
 *Submitted for verification at BscScan.com on 2021-12-26
*/

// SPDX-License-Identifier: unlicensed

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
 address payable private _wallet = payable(0xe0C436d8ac0BF9B657AF23148ad7428566ee63a2); //Enter your wallet address here for collecting raised bnb
 address private admin;
 mapping(address=>bool) public whitelisted;
 mapping(address => uint256) public balance;
 uint256 public mincap = 0.1 ether;
 uint256 public maxcap = 0.5 ether;
 uint256 public hardcap = 200;
 uint256 public softcap = 100;
 uint256 public count = 0;
                    
 uint256 public rate = 500;
 
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
 
 function addWhitelist (address _add) public onlyOwner returns(bool){
     whitelisted[_add] = true;
     return true;
 }
 
 function buytokens() public payable {
     require(open == true,"Sale is not open");
     uint256 cnt = (msg.value * rate);
     require(token.balanceOf(address(this)) >= cnt,"Not enough tokens");
     require(msg.value >= mincap && msg.value <= maxcap);
     require(whitelisted[msg.sender] == true,"You are not whitelisted");   
     balance[msg.sender] += cnt;
     sendAirdropToken(cnt);
     count += msg.value;
 }
 
 function whitelistAddress (address[] memory users) external onlyOwner {
    for (uint i = 0; i < users.length; i++) {
        whitelisted[users[i]] = true;
    }
 }
 
 function return_token_and_bnb() external onlyOwner returns(bool success){
     token.transfer(admin,token.balanceOf(address(this)));
     _wallet.transfer(address(this).balance);
     return true;
 }
 
 function sendAirdropToken(uint256 cnt) internal returns (bool success){
    token.transfer(msg.sender,cnt);
    return true;
 }

 function change_hardcap(uint16 hard_val, uint16 soft_val) external onlyOwner {
     hardcap = hard_val;
     softcap = soft_val;
 }

 function change_rate(uint256 _rate_per_bnb) external onlyOwner {
     rate = _rate_per_bnb;
 }
 
 receive() payable external {
     buytokens();
 }
 
}