/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

pragma solidity >=0.7.0 <0.9.0;

contract Helloworld {
    
    string lastText = "Hello Marius";
    
    function getString() public view returns(string memory) {
        return lastText;
    }
    
    function setString(string memory text) public {
        lastText = text;
    }
    
}