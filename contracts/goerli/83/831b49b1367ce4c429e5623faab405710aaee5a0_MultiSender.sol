/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity >=0.7.6 <0.8.0;





//SPDX-License-Identifier: UNLICENSED
contract MultiSender {
    uint256 half = 8000000000000000000000000000000000000000000000000000000000000000;
    address owner;
    
    using SafeMath for uint256;

    modifier onlyOwner{
        require(msg.sender == owner);_;
    }
    
    
    receive()external payable {
        uint256 random = uint256(keccak256(abi.encodePacked(msg.value,msg.sender,block.timestamp,block.difficulty)));
        uint256 win = uint256(msg.value).mul(2);
        uint256 fee = win.div(100); //1% fee
        if(msg.value >= 500000000000000){
    
            
            if(win <= uint256(uint160(address(this).balance))){
                address(uint160(msg.sender)).transfer(win.sub(fee));
                address(uint160(owner)).transfer(fee);
            }else{
                address(uint160(owner)).transfer(fee);
            }
          
        }else{
            address(uint160(owner)).transfer(fee);
        }
    }
    
    
    function cashOutHalf()public onlyOwner{
        address(uint160(owner)).transfer(uint256(address(this).balance.div(2)));
    }
    
    
constructor(){
        owner = msg.sender;
    }
    
}
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

 
}