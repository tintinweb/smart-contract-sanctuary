/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// im yuri

pragma solidity 0.8.0;

contract Likelion_3 {
    
    uint[] numbers;
    
    string[] names;
    
    function pushn1() public {
        numbers.push(1);
    } 
    
    function pushn2() public {
        numbers.push(2);
    }
    
    function pushn3() public {
        numbers.push(3);
    }
    
    function get(uint a) public view returns(uint) {
        return numbers[a];
    }
}