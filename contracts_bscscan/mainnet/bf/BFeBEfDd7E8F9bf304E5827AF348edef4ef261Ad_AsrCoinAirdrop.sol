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

contract AsrCoinAirdrop{
   

using SafeMath for uint256;
address owner;
address tokenContract;
   struct User {
	
		uint256 checkpoint;
	
	}

	
mapping (address => User) internal users;
     constructor(address _tokenContract)  {
       
         require(_tokenContract != address(this), "Can't let you take all native token");
          tokenContract = _tokenContract;
         
       owner=msg.sender;
    }
    
  function claimAirdrop() public     {
uint256 token=250000000000;
User storage user = users[msg.sender];
if(user.checkpoint>0){
    require(false,"Already Claimed");
}else{
    user.checkpoint=block.timestamp;
      IERC20(tokenContract).transferFromPresale(msg.sender,token);
}
   }

}