/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

pragma solidity ^0.8.0;

contract RecyclingPlatform{
uint256 private ethRclPrice = 227135;
uint256 private mE18 = 1000000000000000000; // *****************************!

uint256 private ethRclPriceZ = 227135000000000000000000;

//uint256 amount = msg.value * ethRclPrice * mE18 / mE18; // ?? *******************************!function buyRCL() public payable {

//uint256 ethValue = amount * mE18  / ( ethRclPrice * mE18 ); // ?? ******************************! function sellRCL(uint256 amount) public

function buyRCLZ() public payable  returns (uint256){
        uint256 amount = msg.value * ethRclPriceZ / 1000000000000000000;
        return amount;

    }

 function sellRCLZ(uint256 amount) view public returns (uint256) {
        uint256 ethValue = amount * 1000000000000000000 / ethRclPriceZ;
        require(amount > 0 && ethValue > 0, 'RecyclingPlatform: too small amount');
        return ethValue;
    }   


 function buyRCL() public payable  returns (uint256){
        uint256 amount = msg.value * ethRclPrice ; 
         return amount;

    }

 function sellRCL(uint256 amount) view public returns (uint256) {
        uint256 ethValue = amount  / ( ethRclPrice  );
        return ethValue;
    }  
    
}