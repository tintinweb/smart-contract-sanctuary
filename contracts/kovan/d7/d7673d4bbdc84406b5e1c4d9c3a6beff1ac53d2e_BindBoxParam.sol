/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// File: Volumes/code/remix/my/BindBox/MathX128.sol



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
// File: Volumes/code/remix/my/BindBox/IBindBoxParam.sol



pragma solidity ^0.8.9;

interface IBindBoxParam {
    function reward(uint amount,uint probabilityX128) external view returns (uint);
}
// File: Volumes/code/remix/my/BindBox/param/BindBoxParam.sol


pragma solidity ^0.8.9;



contract BindBoxParam is IBindBoxParam {
    using MathX128 for uint;
    
    function reward(uint amount,uint probabilityX128) external pure returns (uint award) {
        uint twoX128=probabilityX128.mulX128(probabilityX128);
        uint fourX128=twoX128.mulX128(twoX128);
        uint eightX128=fourX128.mulX128(fourX128);
        uint finalX128=eightX128.mulX128(fourX128).mulX128(twoX128);
        
        uint half=amount/2;
        uint five=amount*5;
        award=finalX128.mulUint(five-half)+half;
    }
    
}