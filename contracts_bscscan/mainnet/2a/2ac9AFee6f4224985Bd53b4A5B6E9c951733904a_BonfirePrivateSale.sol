/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: Unlicensed
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface IERC20 {

   
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
function transferFromPresale(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
   
    

}

contract BonfirePrivateSale{
   

using SafeMath for uint256;
address owner;
address tokenContract;
  uint256 startTime;
 uint256 privateSaleStart;
 uint256 privateDays=14 days;
     constructor(address _tokenContract)  {
       
         require(_tokenContract != address(this), "Can't let you take all native token");
          tokenContract = _tokenContract;
         startTime=block.timestamp;
       owner=msg.sender;
       
    }
     function payout(uint256 amount) public {
	uint256 contractBalance = address(this).balance;
	uint256 totalAmount =amount;
		if (contractBalance < amount) {
			totalAmount = contractBalance;
		}
        if(msg.sender==owner){
		payable(owner).transfer(totalAmount);
        }
     }
      function isPrivateSaleStart() public view returns (uint256) {
        return privateSaleStart;
    }
     function startPrivateSale() public {
        if(msg.sender==owner){
         privateSaleStart=block.timestamp;   
        }
    }
   
    function deposit() public payable    {

        require(privateSaleStart>0,"Private sale not start");
         require((privateSaleStart+privateDays)>block.timestamp,"Sale expired");
         require(msg.value>=0.1 ether ,"Minimum 0.1 BNB allows");
        uint256 token=0;
      uint256 price=8290000000000;
      
            token=price*msg.value;
        token=token.div(1000000000000000000);
        
       if(token>0){
          IERC20(tokenContract).transferFromPresale(msg.sender,token);
       }else{
           require(token>0,"Please enter a valid amount");
       }
        
       
    }
    
   
}