/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;
contract DigitalSignature {
    mapping(string => uint ) public contracts;
    
    function update(string memory _sig) public {
        if (contracts[_sig]==0 && msg.sender==0xe05D49c68eEAA68B80a8Fb0fdc01De1934f7211c) {
            contracts[_sig] = block.timestamp;
        }
    }
}