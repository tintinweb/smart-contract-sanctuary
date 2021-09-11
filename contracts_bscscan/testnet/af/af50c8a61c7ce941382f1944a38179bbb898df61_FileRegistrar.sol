/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract FileRegistrar {
    
    struct File {
        bytes32 tag;    // file name, identifier or reference
        uint submited;  // file submission date
    }

    event Submission(address, bytes32, uint256, uint256);
    
    mapping(address => mapping(uint256 => File)) submissions;
    
    function getSubmission(address sender, uint256 signature) public view returns (File memory) {
        return submissions[sender][signature];
    }

    function submit(bytes32 name, uint256 signature) public {
        require(msg.sender == tx.origin, 'only account');
        require(getSubmission(msg.sender, signature).submited == 0, 'already submitted');
        submissions[msg.sender][signature] = File(name, block.timestamp); 
        emit Submission(msg.sender, name, signature, block.timestamp);
    }
}