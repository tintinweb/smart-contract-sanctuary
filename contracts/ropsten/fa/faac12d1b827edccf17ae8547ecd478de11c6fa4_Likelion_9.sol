/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

// Sungrae Park

pragma solidity 0.8.0;

contract Likelion_9 {
    /*uint[] nums;
    function find_multipleOf4(uint n) public returns(uint) {
        uint cnt = 0;
        while (n != 0){
            nums.push(n%10);
            n /= 10;
        }
        for(uint i=0; i<nums.length; i -=4){
            uint fournum;
            fournum += nums[i] * 1;
            fournum += nums[i+1] * 10;
            fournum += nums[i+2] * 100;
            fournum += nums[i+3] * 1000;
            if(fournum % 4 == 0 && fournum != 0){
                cnt++;
            }
        }
        return cnt;
    }*/
    
    /*function find_multipleOf4(uint n) public returns(uint) {
        uint sum_digit;
        uint cnt;
        while(n>0){
            sum_digit += n%10;
            n = n/10;
            cnt++;
        }
        
        for(uint i=0; i<cnt; i++){
            fournum += n%10
            fournum += (n%100/10)*10
            fournum += (n%100/100)*100
            fournum += (n%10000/1000)*1000
        }
    }*/
}