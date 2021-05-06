/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

//Younwoo Noh

pragma solidity 0.8.0;

contract Likelion_7 {
    uint a;
    string b;



    function pushScore(uint a) public view returns(uint) {
            if(a <= 3) {
               return a ** 2;
            } else if (a <= 6) {
                return a *= 2;
            } else if (a <= 9) {
                return a %= 3;
            } else {
                return a;
            }
    }
}