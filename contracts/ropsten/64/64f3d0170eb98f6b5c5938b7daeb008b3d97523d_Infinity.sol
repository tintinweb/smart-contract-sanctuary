pragma solidity ^0.4.18;

contract Infinity {
    function getCount(uint init) public constant returns (uint res) {
        res = init;
        while(true){
            res++;
        }
        return res;
    }
}