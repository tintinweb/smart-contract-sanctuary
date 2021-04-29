/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

//Jinseon Mon

pragma solidity 0.8.0;

contract likelion_3 {
    uint[] numbers;
    uint len;
    function lion_3 () public view returns(uint,uint) {
        uint sum_number = 0;
        uint count = 0;
        for (uint i =1; i < 25; i++) {
            if ((i%2 != 0) && (i%3 != 0) && (i%5 !=0) && (i%7 != 0))  {
                sum_number = sum_number + i;
                count++;
            }
  
        }
        
        return (sum_number,count);
        
    }
    
    function get(uint a) public  returns(uint) {
            for (uint i =1; i < 25; i++) {
                if ((i%2 != 0) && (i%3 != 0) && (i%5 !=0) && (i%7 != 0))  {
                    numbers.push(i);
                }
  
        }
        
        return numbers[a-1];
    }
}