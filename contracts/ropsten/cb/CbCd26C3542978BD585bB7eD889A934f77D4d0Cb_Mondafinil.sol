/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

pragma solidity 0.8.1;

contract Mondafinil {
    
    string public firstParagraph;
    string public secondParagraph;
    string public saying;
    string public title;
    
    address internal owner;  
    
    modifier onlyAddress(address _address) {
        require (_address == msg.sender);
        _;
    }

    constructor() {
        owner = msg.sender;  
    }
    
    function setTitle(string memory _title) public onlyAddress(0x4F0dD40A7C4b0eECb4822991721308d2350f4517) {
        title = _title;
    }
    
    function setSaying(string memory _saying) public onlyAddress(0xD1F83a476D8504c3EFb634a6ab8fe7f49aca0627) {
        saying = _saying;
    }
    
    function setFirstParagraph(string memory _par1) public onlyAddress(0x4F0dD40A7C4b0eECb4822991721308d2350f4517) {
        firstParagraph = _par1;
    }

    function setSecondParagraph(string memory _par2) public onlyAddress(0xD1F83a476D8504c3EFb634a6ab8fe7f49aca0627) {
        secondParagraph = _par2;
    }

}