// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract CyBlocGeneScientist {

    function validateGene(uint256 gene) public pure returns (bool) {
        return gene > 0;
    }

    function generateGene(uint256 class, uint256[3] memory traits) public pure returns (uint256 newGenes, string memory geneString) {
        uint256 newGenes = class;
        string memory genesString;
        for(uint256 i = 0; i < traits.length; i++) {
            genesString = string(abi.encodePacked(newGenes, toString(traits[i])));
        }
        geneString = genesString;

    }

    function parseGene(uint256 gene) public pure returns (uint256 class, uint256[3] memory traits) {

        class = _sliceNumber(gene, (10 ** 18), 0);
        traits[0] = _sliceNumber(gene, (10 ** 14), (10 ** 4));
        traits[1] = _sliceNumber(gene, (10 ** 10), (10 ** 4));
        traits[2] = _sliceNumber(gene, (10 ** 6), (10 ** 4));

    }

    function mixGenes(uint256[2] memory genes, uint256 randomNumber) public pure returns (uint256) {
        return genes[0] + genes[1] + randomNumber;
    }

    function _sliceNumber(uint256 _number, uint256 _pos, uint256 _offset) internal pure returns (uint256) {
        uint256 number = _number;
        uint256 digits = number / _pos;
        if (_offset > 0){
            return digits % _offset;
        } else {
            return digits;
        }
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

