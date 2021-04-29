/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

//Jinae Byeon

pragma solidity >=0.7.0 <0.9.0;

contract Likelion_3 {
    uint[] numbers;
    function result() public view returns(uint,uint){
        uint256 sum = 0;
        uint256 count = 0;
        uint256 i = 1;
        
        while (i<=25){
            if ((i%2!=0)&&(i%3!=0)&&(i%5!=0)&&(i%7!=0)){
                sum=sum+i;
                count=count+1;
                // numbers.push(i);
            }
            i=i+1;
        }
        return (sum,count);
    }
    function get(uint a) public view returns(uint){
        return numbers[a-1];
    }
}