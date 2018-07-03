pragma solidity ^0.4.23;

contract GeneScience {

    function isGeneScience() public pure returns (bool) {
        return true;
    }

    function uintToBytes(uint256 x) public pure returns (bytes b) {
        b = new bytes(32);
        for (uint i = 0; i < 32; i++) {
            b[i] = byte(uint8(x / (2**(8*(31 - i)))));
        }
    }

    function mixGenes(uint256 genes1, uint256 genes2) public pure returns (uint256) {
        // convert uint256 genes to iterable byte(32) arrays
        bytes memory b1 = uintToBytes(genes1);
        bytes memory b2 = uintToBytes(genes2);

        // bytes32 is castable back to uint256
        bytes32 newGenes;

        // mix genes
        for (uint i = 0; i < 32; i++) {
            if (i % 2 == 0) {
                newGenes |= bytes32(b1[i] & 0xFF) >> (i * 8);
            } else {
                newGenes |= bytes32(b2[i] & 0xFF) >> (i * 8);
            }
        }

        return uint256(newGenes);
    }

    function randomGenes() public view returns (uint256) {
        return uint256(keccak256(now));
    }
}