// SPDX-License-Identifier: UNLICENSICED

pragma solidity 0.8.7;

contract Locker {
    
    address private owner;
    address private gullu;
    address private zopi;
    string private directory;
    string private toZopi;
    string private toGullu;
        
    constructor(){
        owner = msg.sender;
        gullu = address(0xB18c88C23ce8F70380163F2D6F8a436eC97e5aD0);
        zopi = address(0xDD70071E4611E568f850899dAdA09C9F58eEE0be);
    }
    
    function addToDirectory(string memory _directory) public onlyUs{
        directory = string(abi.encodePacked(directory, _directory));
        directory = string(abi.encodePacked(directory, ' '));
    }
    
    function getdirectory() public onlyUs view returns (string memory){
        return directory;
    }

    function messageToGullu (string memory _toGullu) public onlyZopi{
        toGullu = string(abi.encodePacked(toGullu, _toGullu));
        toGullu = string(abi.encodePacked(toGullu, ' '));
    }
    
    function getMessageToGullu() public onlyGullu view returns (string memory){
        return toGullu;
    }

    function messageToZopi (string memory _toZopi) public onlyGullu{
        toZopi = string(abi.encodePacked(toZopi, _toZopi));
        toZopi = string(abi.encodePacked(toZopi, ' '));
    }
    
    function getMessageToZopi() public onlyZopi view returns (string memory){
        return toZopi;
    }

    function changeAddressZopi (address _zopi) public onlyOwner{
        zopi = _zopi;
    }

    function changeAddressGullu (address _gullu) public onlyOwner{
        gullu = _gullu;
    }

    modifier onlyZopi() {
        require(msg.sender == zopi, "Not my Zopi");
        _;
    }

    modifier onlyGullu() {
        require(msg.sender == gullu, "Not Gullu");
        _;
    }

    modifier onlyUs() {
        require(msg.sender == gullu || msg.sender == zopi, "Not Gullu or Zopi");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
}