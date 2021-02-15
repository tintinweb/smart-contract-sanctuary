/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.7;

/// @author Gil Brodsky
/// @title Documents digital signature - proof of ownership
contract ContentDigitalSignature {
    mapping(string => uint ) public digital_signature_timestamp_unix;
    
    function update(string memory _contentSignature, string memory _fullName, string memory _description) public {
        if (digital_signature_timestamp_unix[_contentSignature]==0 && msg.sender==0xe05D49c68eEAA68B80a8Fb0fdc01De1934f7211c) {
            digital_signature_timestamp_unix[_contentSignature] = block.timestamp;
        }
    }
}