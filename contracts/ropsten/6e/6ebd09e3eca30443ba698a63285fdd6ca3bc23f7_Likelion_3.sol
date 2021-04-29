/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

//Sungrae Park

pragma solidity 0.8.0;

contract Likelion_3 {
    uint[] nums;
    uint sum = 0;
    uint cnt = 0;
    function mod_1to25_2() public returns(uint, uint) {
        delete nums;
        uint i;
        sum = 0;
        cnt = 0;
        for(i = 1; i<25; i++) {
            if( i % 2 != 0 && i % 3 != 0 &&  i % 5 != 0 &&  i % 7 != 0 ) {
                sum+=i;
                cnt++;
                nums.push(i);
            }
        }
        
        return (sum, cnt);
    }
    
    function arrayIndex(uint n) public view returns(uint) {
        return nums[n];
    }
    
}