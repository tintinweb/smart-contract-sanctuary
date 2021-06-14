/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.4.24;
contract class20{
        
        // uint
        uint8 uinteger = 255; // range = 0 ~ 2^8-1
        
        // int
        int8 integer = 0x7f; // range = -2^(8-1) ~ 2^(8-1)
        
        //there is no float type in solidity
        //float float1;
        
        uint256 public integer_1;
        uint8 public integer_2 = 255; 
        
        bool public boolen_1;
        
        address public address_1;

        bytes2 public bytes_1;
        
        string public string_;

        //SHA256() return 256 bits
        bytes32 byte_2 = blockhash(12);  // 將區塊高度123的block經過hash後回傳
        
        constructor() public {
        integer_1 = 100;
        // float1 = 0.01;
        boolen_1 = true;
        address_1 = 0xeD46c44191c585c3044660c061dA6586EAa17325;
        bytes_1 = 0x12; // 0x represent Hexadecimal System, every character takes 4 bits. In this example is 4 bits * 2 = 8 bits = 1 byte
        string_ = "Hello, This is EM";
        }
}