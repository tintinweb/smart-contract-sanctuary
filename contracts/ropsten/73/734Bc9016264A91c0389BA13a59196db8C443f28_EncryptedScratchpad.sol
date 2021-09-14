/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

pragma solidity 0.8.7;

contract EncryptedScratchpad{
    
    mapping(address => string) public scratchpadMapping;
    
    function write(string memory scratchpadText) public {
        scratchpadMapping[msg.sender] = scratchpadText;
    }
    
    function read() public view returns(string memory){
        return scratchpadMapping[msg.sender];
    }
    
    function read(address addr) public view returns(string memory){
        return scratchpadMapping[addr];
    }
    
    
    
}