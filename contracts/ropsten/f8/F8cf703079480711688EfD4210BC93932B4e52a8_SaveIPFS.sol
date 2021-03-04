/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

// SPDX-License-Identifier: MIT
// File: contracts/SaveIPFS.sol

pragma solidity >=0.4.22 <0.9.0;

contract SaveIPFS {

    //FIELD VARIABLES
    address private owner; // 
    uint public saveIndex; // 

    //MAPPINGS
    mapping (address=>bytes32[]) public ipfs; //  
    
    //EVENTS
    event Upload(bytes32 indexed ipfsAddress, uint256 indexed id);
    event Download(uint indexed number);

    //MODIFIERS
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
        saveIndex = 0;
    }

    function upload(bytes32 ipfsAddress) public payable returns (bool success) {
        require(ipfsAddress.length != 0, "ipfs hash is invalid");
        uint256 currentIndex = saveIndex;
        ipfs[msg.sender].push(ipfsAddress);
        saveIndex += 1;
        emit Upload(ipfsAddress, currentIndex);
        return true;
    }

    function download(uint number) external returns (bytes32 ipfsAddr) {
        require(ipfs[msg.sender][number].length != 0, "file index is invalid");
        emit Download(number);
        return ipfs[msg.sender][number];
    }

    function getLength() external view returns (uint length) {
        return ipfs[msg.sender].length;
    }
}