/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

pragma solidity ^0.8.0;

contract Test {
    uint256 public a;
    mapping(address => bytes) public map;
    
    function setA1() public {
        uint256 temp = 1;
        a = temp;
    }
    
    function setA2() public {
        uint256 temp = 1;
        for (uint256 i = 1; i <= 2000; i++) {
            temp = i;
        }
        a = temp;
    }
    
    function setA3(bytes memory temp) public {
        map[msg.sender] = bytes(temp);
    }
    
    function setA4(string memory temp) public {
        map[msg.sender] = bytes(temp);
    }
    
    bytes public text;
    function setA5(string memory temp) public {
        text = abi.encodePacked(temp);
    }
    
}