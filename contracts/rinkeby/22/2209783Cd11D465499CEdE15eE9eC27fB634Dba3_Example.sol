/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity 0.8.3;


contract Example {
    bool public wasInteractedWith;
    string public stringExample;
    
    constructor() {
        wasInteractedWith = false;
    }
    
    function setString(string memory _example) public returns (string memory example) {
        stringExample = _example;
        return _example;
        
    }
    function toggleInteraction() public returns (bool _interaction) {
        wasInteractedWith = !wasInteractedWith;
        return wasInteractedWith;
    }
    
    function getString() public view returns(string memory example) {
        return stringExample;
    }
    
}