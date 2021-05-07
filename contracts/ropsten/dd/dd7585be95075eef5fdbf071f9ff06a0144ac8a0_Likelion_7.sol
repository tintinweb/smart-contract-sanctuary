/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// Sungrae Park

pragma solidity 0.8.0;

contract Likelion_7 {
    function find_multiple(uint n) public pure returns(uint, uint, uint, uint, uint) {

        uint sum_digit; 
        uint cnt9;
        uint cnt11;
        for(uint i=1; i<=n; i++) {
            sum_digit=0;
            uint j = i;
            while(j>0){
                sum_digit += j%10;
                j = j/10;
            }
            cnt9 += sum_digit/9;
            cnt11 += sum_digit/11;
        }
        return(n/2,n/3,n/5,cnt9,cnt11);
    }
}