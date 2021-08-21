/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

pragma solidity 0.7.5;

contract Helloworld {
    
    string lastText = "Hello Filip";
    
    function getString() public view returns(string memory) {
        return lastText;
    } 
    
    function setString(string memory text) public {
        lastText = text;
    }
    
}