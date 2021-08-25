/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient,uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}
 
contract Presale{
    
    address private presaleTokenAddress = 0x1fAaC3b514108c4428D967E4A6516205E411ef2a; //USDC Rinkeby
    IERC20 presaleToken = IERC20(presaleTokenAddress);
    
    modifier onlyAdmin(){
        require (msg.sender == admin, 'Only admin accessible');
        _;
    }
    
    address admin;
    uint tokenPrice = 10000000000000000; // 1BNB = 0.01 PresaleTokens
    
     constructor() {
        admin = msg.sender;
     }
     
     function transferPreasleToken() public payable returns(bool){
         presaleToken.transfer(msg.sender, tokenPrice * msg.value);
         return true;
     }
     
     function getPresaleTokenBalance() public view returns(uint){
         return presaleToken.balanceOf(address(this));
     }
     
     function withdrawUnsoldPresaleTokens(uint _amount) public onlyAdmin returns(bool){
         presaleToken.transfer(address(this), _amount);
         return true;
     }
     
     function withdrawETH(uint _amount) public payable onlyAdmin returns(bool) {
         payable(admin).transfer(_amount);
         return true;
     }
     
     function withdrawAllETH() public payable onlyAdmin returns(bool){
         payable(admin).transfer(address(this).balance);
         return true;
     }
     
     function setPresaleValue(uint _price) public payable onlyAdmin returns(bool){
         tokenPrice = _price;
         return true;
     }
     
     function totalTokensSold() public pure returns(uint){
        return 0;
    
     }

     function updatePresaleTokenAddress(address _tokenAddress) public returns(bool){
         presaleTokenAddress = _tokenAddress;
         return true;
     }
}