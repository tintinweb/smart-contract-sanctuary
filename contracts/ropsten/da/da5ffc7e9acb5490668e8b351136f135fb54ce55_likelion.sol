/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

//Jinseon Mon

pragma solidity 0.8.0;

contract likelion {
    
    function lion () public view returns(uint256,uint256) {
        uint256 sum_number = 0;
        uint256 count = 0;
        for (uint i =1; i < 25; i++) {
            if ((i%2 != 0) && (i%3 != 0) && (i%5 !=0) && (i%7 != 0))  {
                sum_number = sum_number + i;
                count++;
            }
  
        }
        
        return (sum_number,count);
        
    }
}