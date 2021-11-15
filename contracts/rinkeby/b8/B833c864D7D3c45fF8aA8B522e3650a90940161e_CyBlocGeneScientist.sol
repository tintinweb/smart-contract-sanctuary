// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract CyBlocGeneScientist {

    function validateGene(uint256 gene) public pure returns (bool) {
        return gene > 0;
    }

    function generateGene(uint256 class, uint256[3] memory traits) public view returns (uint256, string memory) {

        uint256 newGenes = 0;
        string memory newGenesString = string(abi.encodePacked(toString(class), ''));
        for(uint256 i = 0; i < traits.length; i++) {
            if(traits[i] == 0){
                newGenesString = string(abi.encodePacked(newGenesString, '0000'));
            } else {
                newGenesString = string(abi.encodePacked(newGenesString, toString(traits[i])));
            }
            
        }
        newGenesString = string(abi.encodePacked(newGenesString, '000000'));
        newGenes = toUint(newGenesString);
        return (newGenes, newGenesString);

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

    /**
    * Convert bytes to uint
    */
    function toUint(string memory _string)
    public pure
    returns(uint256 _result) {

        bytes memory _data = bytes(_string);
        uint256 _offset = 0;
        uint256 _segment = _offset + _data.length;
        uint256 count = 0;
        for (uint256 i = _segment; i > 0 ; i--) {
            _result |= uint256(uint8(_data[i-1])) << ((count++)*8);
        }
    }    

    // parseInt(parseFloat*10^_b)
    function parseInt(string memory _string) public pure returns (uint256 result) {
        bytes memory b = bytes(_string);
        uint i;
        result = 0;
        uint totNum = b.length;
        totNum--;

        for (i = 0; i < b.length; i++) {
            uint c = uint256(uint8(b[i]));

            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
                totNum--;
            }
        }

        return result;
    }
}

