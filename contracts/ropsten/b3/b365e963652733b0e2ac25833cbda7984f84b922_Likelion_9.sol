/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

//JinAe Byeon

pragma solidity 0.8.0;

contract Likelion_9 {
    function result (uint a) public view returns(uint){
        uint count = 0;
        uint one = a%10000;
        uint two = a/10000;
        if(one%4==0){
            count++;
        }
        while (two>9999){
            one = two%10000;
            two = two/10000;
            if(one%4==0){
                count++;
            }
        }
        if(two%4==0){
            count++;
        }
        return(count);
    }
}