/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.7;

contract ContentDigitalSignature {
   struct envelope {
     string name;
     uint timestamp;
     bool isValue;
   }
    mapping(string => envelope ) public contracts;

    function update(string memory _contentSignature, string memory _name) public {
        if (!contracts[_contentSignature].isValue && msg.sender==0xe05D49c68eEAA68B80a8Fb0fdc01De1934f7211c) {
            envelope memory _envelope;
            _envelope.name=_name;
            _envelope.timestamp=block.timestamp;
            _envelope.isValue=true;
            contracts[_contentSignature]=_envelope;
        }
    }
}