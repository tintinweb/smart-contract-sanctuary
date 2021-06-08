/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity 0.5.16;

contract Test {
    string _privnote;
    
    function edit(string memory str) public {
        _privnote = str;
    }
    
    
    function read() public view returns (string memory) {
        return _privnote;
    }
}