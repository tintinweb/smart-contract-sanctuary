/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

pragma solidity ^0.4.24;
contract class20{
        //鼓勵同學按照影片的東西打出來，因為remix都會提示，不會打錯啦！
        uint8 public integer_1; //uint8 可存 0 ~ 255
        //型態          變去名稱
        uint256 public integer_2 = 200;
        
        bool public boolen_1;
        
        address public address_1;

        bytes2 public bytes_1;
        
        string public string_;

        //there is no float type in solidity
        //float float1;
        constructor() public {
        integer_1 = 255; 
        // float1 = 0.01;
        boolen_1 = true;
        address_1 = 0xeD46c44191c585c3044660c061dA6586EAa17325;
        bytes_1 = 0x12;
        string_ = "安安，我是西西";
        }
        
        function setString(string _test) public{
            string_ = _test;
            
        }
}