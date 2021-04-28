/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// Ko Eun NA

pragma solidity 0.8.0;

contract likelion_2{
    
    function Sum() public view returns (uint256){
        uint256 sum =0;
        for (uint256 i = 0; i <= 25; i++) {
            if (i/2 != 0 && i/3 !=0 && i/5 !=0 && i/7 !=0){
            sum = sum + i;  
            i++;
            }
        return sum;
        }
    }
}