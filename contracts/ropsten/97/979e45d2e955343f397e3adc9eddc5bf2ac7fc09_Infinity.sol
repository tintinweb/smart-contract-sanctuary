pragma solidity ^0.4.18;

contract Infinity {
    function getCount() public constant returns (uint count) {
        count = 0;
        while(true){
            count++;
        }
        return count;
    }
}