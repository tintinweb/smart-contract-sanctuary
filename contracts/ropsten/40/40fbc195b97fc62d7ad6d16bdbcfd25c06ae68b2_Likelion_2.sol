/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity 0.8.0;

contract Likelion_2 {
    function mod_1to25() public view returns(uint) {
        uint i;
        uint sum=0;
        for(i = 1; i<25; i++) {
            if( i % 2 != 0 && i % 3 != 0 &&  i % 5 != 0 &&  i % 7 != 0 ) {
                sum+=i;
            }
        }
        
        return sum;
    }
}