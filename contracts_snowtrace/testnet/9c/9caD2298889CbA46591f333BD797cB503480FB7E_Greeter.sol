/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract Greeter {
    string private greeting;
    string public baseSeed = "";
    uint256 public seed = 0;
    uint256[][] public setOfAttributes;
    uint256 private attributesIndex = 0;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    // Begining of the random methods
    function setBaseSeed(string memory walletAddress, string memory tokenId) public {
       baseSeed = string(abi.encodePacked(walletAddress, tokenId));
    } 

    function getSeed() public view returns (uint256) {
        return seed;
    }

    function generateRandom() public {
        // Output 0 to 4095
        bytes memory b = bytes(baseSeed);
        
        uint32 i = 0;
        uint256 hash = seed;
        while (i != b.length) {
            uint32 key = uint32(uint(uint8(b[i])));
            hash += key;
            hash = hash + (hash << 10);
            hash ^= hash >> 6;
            i++;
        }
        hash += hash << 3; 
        hash ^= hash >> 11;
        hash += hash << 15;
        seed = (hash & 0xfffffff) / 0x10000;
    }
    // End of the random methods

    function generateAttributeSet(string memory walletAddress, string memory tokenId) public {
        setBaseSeed(walletAddress, tokenId);
        uint i;
        for ( i = 0; i< 10; i++){
            generateRandom();
            uint256 attribute = getSeed();
            if(i!=0){
                setOfAttributes[attributesIndex].push(attribute);
            }else {
                setOfAttributes.push([attribute]);
            }
        }
        attributesIndex ++;
    }

    function getAttributeSet() public view returns (uint256[][] memory) {
        return setOfAttributes;
    }
}