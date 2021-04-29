/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

//yeong hae
pragma solidity >=0.7.0 <0.9.0;

contract Likelion_3{
    uint[] num;
    
    function n_sum() public {
        uint sum = 0;
        uint count = 0;
        
        for(uint i = 1; i <= 25; i++){
            if (i%2 != 0 && i%3 != 0 && i%5 !=0 && i%7 !=0) {
                sum = sum + i;
                count = count + 1;
            }
        }
        num.push(sum);
        num.push(count);
    }
    
    function arr(uint a) public view returns(uint){
        return num[a];
    }
}