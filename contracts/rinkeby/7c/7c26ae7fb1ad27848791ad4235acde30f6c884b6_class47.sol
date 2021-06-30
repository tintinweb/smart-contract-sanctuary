/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.4.24;
contract class47{
    mapping(address=>uint8)public balance;
    
    //帳號 0xed46c44191c585c3044660c061da6586eaa17325 //data 100
    function set(address addr,uint8 amount)public{
        balance[addr] = amount;
    }
    
    //帳號+data 0xed46c44191c585c3044660c061da6586eaa1732564
    function small_set(bytes21 data)public returns (bytes20) {
        address addr = address(bytes20(data));
        balance[addr] = uint8(data[20]);
    }   
}