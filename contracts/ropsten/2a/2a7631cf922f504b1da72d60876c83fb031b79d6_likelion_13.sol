/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// GyungHwan Lee

pragma solidity 0.8.0;

contract likelion_13 {
    
    function getcount(uint num) public view returns (uint) {
        uint count = 0;
        uint count2 = 0;
        
        for(uint i = 2; i <= num ; i ++){
            for(uint j = 1; j <= i; j++){
                if(i%j == 0){
                    count2++;
                }
            }
            if(count2 == 2){
                count++;
            }
        }
        return (count);
    }
}