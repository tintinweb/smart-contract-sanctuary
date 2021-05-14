/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

//JinAe Byeon

pragma solidity 0.8.0;

contract Likelion_13 {
    function result(uint num) public view returns(uint){
        uint count = 1;
        for(uint i=2; i<=num; i++){
            uint check = 0;
            for(uint j=1; j<i; j++){
                if(i%j==0){
                    check++;
                }
            }
            if(check==1){
                count++;
            }
        }
        return count;
    }
    function result2(uint unixtime) public view returns(uint,uint,uint){
        uint year = 1970 + unixtime / (60*60*24*365);
        uint month = unixtime % (60*60*24*365) / (60*60*24) / 30;
        uint day = unixtime % (60*60*24*365) / (60*60*24) % 30;
        return (year, month, day);
    }
}