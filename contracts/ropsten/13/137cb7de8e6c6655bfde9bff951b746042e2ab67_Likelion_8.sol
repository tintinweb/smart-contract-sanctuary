/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

//JinAe Byeon

pragma solidity 0.8.0;

contract Likelion_8 {
    function result (uint a) public view returns(uint,uint,uint,uint,uint) {
        uint two = 0;
        uint three = 0;
        uint five = 0;
        uint nine = 0;
        uint eleven = 0;
        for (uint i=1; i<=a; i++){
            if (i%2==0){
                two++;
            }
            if (i%3==0){
                three++;
            }
            if (i%5==0){
                five++;
            }
            uint x = (i%10)+(i/10);
            if (x%9==0){
                nine++;
            }
            if (x%11==0){
                eleven++;
            }
        }
        return(two,three,five,nine,eleven);
    }
}