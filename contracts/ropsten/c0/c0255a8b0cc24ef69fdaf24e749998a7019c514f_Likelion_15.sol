/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

//JinAe Byeon

pragma solidity 0.8.0;

contract Likelion_15 {
    function root(uint i) public view returns(uint[] memory){
        uint[] memory array;
        for(uint b=i; b/10<=0; b=i/10){
            uint a = b%10;
            // array.push(a);
        }
        return(array);
    }
}