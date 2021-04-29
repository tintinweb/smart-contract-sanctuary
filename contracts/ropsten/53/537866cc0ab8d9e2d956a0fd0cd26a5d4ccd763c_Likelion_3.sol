/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

//YunJun Lee
pragma solidity 0.8.0;


contract Likelion_3 {
    uint[] numbers ;
    uint sum =0;
    uint count =0;

    function Sum() public returns(uint, uint) {

        for ( uint i =1 ; i<=25;i++){
            if (i%2 !=0 && i%3 !=0 && i%5 !=0 && i%7 !=0){
                    numbers.push(i);
                    sum+=i;
                    count+=1;
                }
        }
        return (sum, count);
    }
     function getSum() public view returns(uint, uint){
         return (sum, count);
     }

 
    
     function get(uint a) public view returns(uint) {
     return numbers[a-1];
 }


}