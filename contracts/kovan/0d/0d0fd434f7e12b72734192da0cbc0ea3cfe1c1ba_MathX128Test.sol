/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// File: Volumes/code/remix/my/new_cow/MathX128.sol



pragma solidity ^0.8.7;

library MathX128 {
    uint constant x128=(1<<128)-1;
    
    uint constant oneX128=(1<<128);
    
    function mulX128(uint l, uint r) internal pure returns(uint result) {
        uint l_high=l>>128;
        uint r_high=r>>128;
        uint l_low=(l&x128);
        uint r_low=(r&x128);
        result=((l_high*r_high)<<128) + (l_high*r_low) + (r_high*l_low) + ((l_low*r_low)>>128);
    }
    
    function mulUint(uint l,uint r) internal pure returns(uint result) {
        result=(l*r)>>128;
    }
    
    function toPercentage(uint numberX128,uint decimal) internal pure returns(uint result) {
        numberX128*=100;
        if(decimal>0){
            numberX128*=10**decimal;
        }
        return numberX128>>128;
    }
    
    function toX128(uint percentage,uint decimal) internal pure returns(uint result) {
        uint divisor=100;
        if(decimal>0)
            divisor*=10**decimal;
        return oneX128*percentage/divisor;
    }
}
// File: Volumes/code/remix/my/new_cow/test/MathX128Test.sol



pragma solidity ^0.8.9;


contract MathX128Test {
    function toPercentage(uint numberX128,uint decimal) public pure returns(uint result) {
        return MathX128.toPercentage(numberX128,decimal);
    }
    
    function toX128(uint percentage,uint decimal) public pure returns(uint result) {
        return MathX128.toX128(percentage,decimal);
    }
    
    function mulX128(uint l, uint r) public pure returns(uint result) {
        return MathX128.mulX128(l,r);
    }
}