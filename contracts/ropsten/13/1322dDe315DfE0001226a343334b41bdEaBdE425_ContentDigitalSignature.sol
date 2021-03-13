/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.5.7;

/// @author Gil Brodsky
/// @title Proof of digital artifact existence - www.ourwebsite.com

contract ContentDigitalSignature {
    
    mapping(string => string ) public  digital_signature;
    
    modifier onlyOwner() {
        require (msg.sender == 0xe05D49c68eEAA68B80a8Fb0fdc01De1934f7211c);
        _;
    }
    
    function update(string memory _contentSignature, string memory _comment) public onlyOwner {
        digital_signature[_contentSignature] = _comment;
    }

}