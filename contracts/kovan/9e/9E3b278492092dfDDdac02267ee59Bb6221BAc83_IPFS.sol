// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract IPFS {
    
    function convertCID(uint256 cid) external pure returns(string memory cidString) {
        return string(abi.encodePacked(cid));
    }
    
}