/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

//Jinseon Moon
pragma solidity 0.8.0;

contract Lion_8 {
    uint[] numbers;
    
    function lion_8(uint num) public view returns(uint, uint, uint) {
        
        uint count_2 = 0;
        uint count_3 = 0;
        uint count_5 = 0;
        for(uint i = 1; i < num; i++) {
            if((i % 2) == 0) {
                count_2 += 1;
            } else if((i % 3) == 0) {
                count_3 += 1;
            } else if((i % 5) == 0) {
                count_5 += 1;
            }
        }
        
        return(count_2, count_3, count_5);
        
    }
    
    function putNumber(uint num) public {
        
        for(uint i = 1; i < num; i++) {
            numbers.push(i);
        }
    }
    
    function getNumber() public view returns(uint){
        uint a = 0; //1
        uint b = 0; //10
        uint c = 0; //100
        uint sum = 0;
        
        for(uint i = 0; i < numbers.length; i ++) {
            c = uint(numbers[i] / 100);
            b = uint((numbers[i] - (c * 100)) / 10);
            a = uint(numbers[i] - (c * 100) - (b *10));
            
            sum = sum + (a+b+c);
            
        }
        
        return sum;
    }
    
}