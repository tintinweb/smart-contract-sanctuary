/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BlockhashStorage {

    mapping (uint256=>bytes32) public blocknumberToHash;
    
    event BlockhashStored(uint256 blocknumber, bytes32 blockhash);

    // STORE / MUTATIVE FUNCTIONS

    function store() public {
        uint256 currentBlock = block.number;
        blocknumberToHash[currentBlock-1] = blockhash(currentBlock-1);
    }

    function store(uint256 blocknumber) public {
        blocknumberToHash[blocknumber] = blockhash(blocknumber);
    }


    function store(uint256[] calldata blocknumbers) public {
        for (uint256 i = 0; i<blocknumbers.length; i++) {
            blocknumberToHash[blocknumbers[i]] = blockhash(blocknumbers[i]);
        }
    }
    
    function store(uint256 blocknumberFrom, uint256 blocknumberTo) public {
        for (uint256 blocknumber = blocknumberFrom; blocknumber<=blocknumberTo; blocknumber++) {
            blocknumberToHash[blocknumber] = blockhash(blocknumber);
        }
    }
    
    // Stores blockhashes of the latest 256 blocks (skipping the ones that are already there)
    function store256() public {
        uint256 currentBlock = block.number;
        for (uint256 blocknumber = currentBlock - 1; blocknumber >= currentBlock - 256; blocknumber--) {
            if (blocknumberToHash[blocknumber] == 0) {
                blocknumberToHash[blocknumber] = blockhash(blocknumber);
            }
        }
    }
    
    // RETRIEVE / VIEW FUNCTIONS

    function retrieve() public view returns (bytes32) {
        return blocknumberToHash[block.number - 1];
    }

    function retrieve(uint256 blocknumber) public view returns (bytes32) {
        return blocknumberToHash[blocknumber];
    }
    
    function retrieve(uint256[] calldata blocknumbers) public view returns(bytes32[] memory) {
        bytes32[] memory blockhashes = new bytes32[](blocknumbers.length);
        for (uint256 i = 0; i < blocknumbers.length; i++) {
            blockhashes[i] = blocknumberToHash[blocknumbers[i]];
        }
        return blockhashes;
    }

    function retrieve(uint256 blocknumberFrom, uint256 blocknumberTo) public view returns(bytes32[] memory) {
        bytes32[] memory blockhashes = new bytes32[](blocknumberTo-blocknumberFrom + 1);
        for (uint256 i = 0; i <= blocknumberTo - blocknumberFrom; i++) {
            blockhashes[i] = blocknumberToHash[blocknumberFrom + i];
        }
        return blockhashes;
    }
    
    // Returns 256 latest blockhashes with [0] being the current block and going to the past
    function retrieve256() public view returns(bytes32[] memory) {
        bytes32[] memory blockhashes = new bytes32[](256);
        for (uint256 i=0; i<256; i++) {
            blockhashes[i] = blocknumberToHash[block.number - i];
        }
        return blockhashes;
    }

}