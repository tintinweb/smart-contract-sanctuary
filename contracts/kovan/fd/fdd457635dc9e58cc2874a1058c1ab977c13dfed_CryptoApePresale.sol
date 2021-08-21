/**
 *Submitted for verification at Etherscan.io on 2021-08-20
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

contract CryptoApePresale {
    
 IERC20 token;
 bool public open = false;
 address payable private _wallet = payable(0x05Dc135fD33732C3f123a243f554746857f15917); //change your wallet here 
 enum PreSaleStage {Round1, Round2}        
 PreSaleStage public stage = PreSaleStage.Round1;
 address private admin;
 mapping(address=>bool) public whitelisted;
 mapping(address => uint256) public balance;
 uint256 public mincap = 1760000000; //17.6 MILLION (MIN 0.1 BNB PER ADDRESS)
 uint256 public maxcap = 2*17600000000; // 352 MILLION TOKENS (MAX 2 BNB PER ADDRESS)
 uint256 private hardcap = 250000000000000000000; //250 BNB
 uint256 private count = 0;
 address[] private _whitelist;
                    
 uint256 public rate = 176;
 uint256 div = 10000000000;
 
 
 constructor ( address _token) {
     token = IERC20(_token);
     admin = msg.sender;
 }
 
 modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }
 // OPEN SALE 
 function opensale() public onlyOwner {
     open = true;
 }
 
 //CLOSE SALE MANUALLY
 
 function closesale() public onlyOwner {
     open = false;
 }
 
 //CHANGE PRESALE ROUND
 
 function changeRound() external onlyOwner returns(bool){
     require(stage == PreSaleStage.Round1);
     stage = PreSaleStage.Round2;
     return true;
 }
  // ADD WHITELIST ONE BY ONE
 
 function addWhitelist (address _add) public onlyOwner returns(bool){
     whitelisted[_add] = true;
     _whitelist.push(_add);
     return true;
 }
 
  // RETURNS whitelisted ADDRESS
 
 function showWhitelistAddresses() public view returns(address[] memory){
        address[] memory ret = new address[](_whitelist.length);
        for (uint i = 0; i < _whitelist.length; i++) {
            
            ret[i] = _whitelist[i];
            
        }
        return ret;
    }

 
 function buytokens() public payable {
     count += msg.value;
     require(open == true);
     require(msg.value >= 0.1 ether && msg.value <= 2 ether);
     uint256 cnt = (msg.value * rate)/div;
     require(token.balanceOf(address(this)) >= cnt);
     require(cnt >= mincap && cnt <= maxcap);
     require(balance[msg.sender]+cnt <= maxcap);
     if(stage == PreSaleStage.Round1){
         require(whitelisted[msg.sender] == true);
        //  require(msg.value >= 0.1 ether && msg.value <= 2 ether);
         _wallet.transfer(msg.value);
         balance[msg.sender] += cnt;
         sendAirdropToken(cnt);
     }
     else{
         balance[msg.sender] += cnt;
         sendAirdropToken(cnt);
         _wallet.transfer(msg.value);
     }
     if(count >= hardcap){
         open = false;
     }
 }
 
 // ADD MULTIPLE WHITELIST ADDRESS
 function whitelistMultipleAddress (address[] memory users) external onlyOwner {
    for (uint i = 0; i < users.length; i++) {
        whitelisted[users[i]] = true;
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