/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity ^0.5.10;

contract generateNumber {
    uint public A;
    uint public B;
    uint public C;
    uint public D;
    uint public E;
    uint public F;
    
    function random1() external returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender))) % 9;
        A = randomnumber;
        return randomnumber;
    }
    
    function random2() external returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender))) % 9;
        B = randomnumber;
        return randomnumber;
    }
    
    function random3() external returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender))) % 9;
        C = randomnumber;
        return randomnumber;
    }
    
    function random4() external returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender))) % 9;
        D = randomnumber;
        return randomnumber;
    }
    
    function random5() external returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender))) % 9;
        E = randomnumber;
        return randomnumber;
    }
    
    function random6() external returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender))) % 9;
        F = randomnumber;
        return randomnumber;
    }
}