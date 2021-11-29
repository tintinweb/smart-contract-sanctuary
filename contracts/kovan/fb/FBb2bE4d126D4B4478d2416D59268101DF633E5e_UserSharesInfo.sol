/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-04
*/

// @title dKeys Key Info
// @author Atomrigs Lab
// SPDX-License-Identifier: MIT

pragma solidity 0.5.6;

contract UserSharesInfo {

    struct SharesInfo {
        address ourAddress;
        address party1;
        address party2;
    }

    string public name = "dekey Shares Info Contract";
    uint256 public deployedBlock;
    address creator;

    mapping(bytes32 => SharesInfo) public userSharesInfo;
    mapping(address => address) public addressForwards;

    modifier onlyOwner(address addr) {
        require(addr == tx.origin);
        _;
    }

    constructor() public {
        deployedBlock = block.number;
        creator = msg.sender;
    }

    function _addAddressShares(bytes32 user, address addr, address party1, address party2) 
        private {

        userSharesInfo[user] = SharesInfo({
            ourAddress: addr,
            party1: party1,
            party2: party2
        });
    }
    
    function addAddressShares(bytes32 user, address addr, address party1, address party2) 
        public onlyOwner(addr) {
        _addAddressShares(user, addr, party1, party2);
    }    

    function getHash(address addr, address party1, address party2) 
        public pure 
        returns (bytes32) {
        return keccak256(abi.encodePacked(addr, party1, party2));
    }

    function verifyAddress(address addr, bytes32 hash, uint8 v, bytes32 r, bytes32 s) 
        public pure returns (bool) {
        return addr == ecrecover(hash, v, r, s);
    }
    
    function proxyAddressShares(bytes32 user, address addr, address party1, address party2, 
        uint8 v, bytes32 r, bytes32 s) 
        public {
        bytes32 hash = getHash(addr, party1, party2);
        require(verifyAddress(addr, hash, v, r, s));
        _addAddressShares(user, addr, party1, party2);
    }
    
    function forwardAddress(address addr, address newAddr) 
        public onlyOwner(addr) {
        
        addressForwards[addr] = newAddr;
    }
  
}