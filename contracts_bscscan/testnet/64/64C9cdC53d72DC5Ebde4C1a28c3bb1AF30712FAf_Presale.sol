/**
 *Submitted for verification at BscScan.com on 2021-07-20
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

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferFromPresale(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

}

contract Presale{
    uint8 currentRound=1;
    uint8 maxRound =3;
    uint256 round1Price= 25000000;
    uint256 round2Price= 18900000;
    uint256 round3Price= 19800000;
 
    uint256 round1Days = 2 days;
    uint256 round2or3Days = 3 days;
    uint256 gapDays = 1 days;
    uint256 withdrawDays = 15 days;
    uint256 totalPresaleDays= 11 days;
    	struct User {
	uint256 tokenBalance;
	uint256 withdRaw;
	}

	mapping (address => User) internal users;
   address tokenContract;
   uint256 presSaleStart;
using SafeMath for uint256;
address owner;
     constructor(address _tokenContract,uint256 startTime)  {
       
         require(_tokenContract != address(this), "Can't let you take all native token");
          tokenContract = _tokenContract;
          presSaleStart=startTime;
       
    }
    
    function deposit() public payable    {
        	User storage user = users[msg.sender];
        uint256 token=0;
        if(block.timestamp<=presSaleStart+round1Days){
            require(msg.value >= 1 ether && msg.value<=20 ether , "Min 1 and MAx 20 BNB Allowed");
            token=msg.value.mul(round1Price).div(1000000000000000000);
        }
        else if(block.timestamp>presSaleStart+round1Days+gapDays&&block.timestamp<=presSaleStart+round1Days+gapDays+round2or3Days){
            require(msg.value >= 1 ether && msg.value<=30 ether , "Min 1 and MAx 30 BNB Allowed");
            token=msg.value.mul(round2Price).div(1000000000000000000);
        }
        else if(block.timestamp>presSaleStart+round1Days+gapDays+round2or3Days&&block.timestamp<=presSaleStart+round1Days+gapDays+round2or3Days+round2or3Days){
            require(msg.value >= 1 ether && msg.value<=50 ether , "Min 1 and MAx 20 BNB Allowed");
            token=msg.value.mul(round3Price).div(1000000000000000000);
        }
        if(token==0){
            require(token>0 , "Token will be greater than 0");
        }else{
        user.tokenBalance=user.tokenBalance.add(token);
        }
       
        
    }
    function claim() public  payable{
       uint256 availableb= availableClaimAmount(msg.sender);
       	User storage user = users[msg.sender];
       	
       	 if( IERC20(tokenContract).balanceOf(address(this))<availableb){
       	     availableb=IERC20(tokenContract).balanceOf(address(this));
       	 }
       	  user.withdRaw=user.withdRaw.add(availableb);
       IERC20(tokenContract).transferFromPresale(address(this),msg.sender,availableb);
       
    }
  function userBalance(address userAdress) public view returns (uint256){
      	User storage user = users[userAdress];
      return user.tokenBalance.sub(user.withdRaw);
  }
  function availableClaimAmount(address userAdress) public view returns (uint256){
      	User storage user = users[userAdress];
      	uint256  balance=user.tokenBalance.sub(user.withdRaw);
      	uint256 claimAmount=0;
      	if(block.timestamp>=presSaleStart+totalPresaleDays){
      	    claimAmount = claimAmount.add(balance.mul(20).div(100));
      	}
      	if(block.timestamp>=presSaleStart+totalPresaleDays+withdrawDays){
      	    claimAmount = claimAmount.add(balance.mul(30).div(100));
      	}
      		if(block.timestamp>=presSaleStart+totalPresaleDays+withdrawDays+withdrawDays){
      	    claimAmount =claimAmount.add(balance.mul(50).div(100));
      	}
      return claimAmount;
  }
}