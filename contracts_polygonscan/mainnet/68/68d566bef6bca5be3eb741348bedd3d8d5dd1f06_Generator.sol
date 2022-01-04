/**
 *Submitted for verification at polygonscan.com on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract Generator {

    address public owner;

    uint public seedBlock;
    uint nonce;

    struct Attributes {
        uint8 type1;
        uint8 type2;
        uint8 type3;
        uint8 type4;
        uint8 type5;
        uint8 type6;
        uint8 type7;
        uint8 type8;
        uint8 type9;
    }

    Attributes[] public nfts;
    uint[] public resultArray;

    constructor() {
        owner = msg.sender;  
    }

    //should be 644
    function setReady() public {
        require(msg.sender == owner, "only owner");
        seedBlock = block.number + 10;
    }

    function addNft(Attributes[] calldata _components) public {
        require(msg.sender == owner, "onlyOwner");
        for(uint i = 0; i < _components.length; i++) {
            nfts.push(_components[i]);
            resultArray.push(resultArray.length+1);
        }
    }

    function shuffle() public {
        require(msg.sender == owner, "only owner");
        require(blockhash(seedBlock) != bytes32(0), "too early or expired");

        for (uint256 i = 0; i < resultArray.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(blockhash(seedBlock), tx.gasprice, block.timestamp))) % (resultArray.length - i);
            uint256 temp = resultArray[n];
            resultArray[n] = resultArray[i];
            resultArray[i] = temp;
        }
    }

    function getResultArray() public view returns(uint[] memory) {
        return resultArray;
    }

}