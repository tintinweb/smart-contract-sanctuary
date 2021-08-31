// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CyBlocGeneScientist {

    function validateGene(uint256 gene) public pure returns (bool) {
        return gene > 0;
    }

    function generateGene(uint256 class, uint256[3] memory traits) public pure returns (uint256) {
        return class + traits.length;
    }

    function parseGene(uint256 gene) public pure returns (uint256 class, uint256[3] memory traits) {
        uint256  numOfDigist = 10;

        class = _sliceNumber(gene, (numOfDigist * 12), 0);
        traits[0] = _sliceNumber(gene, (numOfDigist * 8), (numOfDigist * 2));
        traits[1] = _sliceNumber(gene, (numOfDigist * 4), (numOfDigist * 6));
        traits[2] = _sliceNumber(gene, 0, (numOfDigist * 10));

    }

    function mixGenes(uint256[2] memory genes, uint256 randomNumber) public pure returns (uint256) {
        return genes[0] + genes[1] + randomNumber;
    }

    // function setNumOfTrait(uint256 _numOfTraits) public  {
    //     numOfTraits = _numOfTraits;
    // }    

    // function setBitClass(uint256 _bitClass) public  {
    //     bitClass = _bitClass;
    // }    

    // function setBitTrait(uint256 _bitTrait) public  {
    //     bitTrait = _bitTrait;
    // }       

    // function decode(uint256 _genes) public view returns(uint256 class, uint256 trait, uint8[] memory _classs, uint8[] memory _traits) {
    //     uint8[] memory traits = new uint8[](20);
    //     uint8[] memory classs = new uint8[](2);
    //     uint256 i;
    //     for(i = 0; i < 20; i++) {
    //         traits[i] = _getnBits(_genes, i, bitTrait);
    //     }
    //     _traits = traits;
    //     uint256 j;
    //     for(j = 0; j < 2; j++) {
    //         classs[j] = _getnBits(_genes, j, bitClass);
    //     }
    //     _classs = classs;
    //     trait = encode(traits, 20, bitTrait);  
    //     class = encode(classs, 2, bitClass);  
    // }

    // function _getnBits(uint256 _input, uint256 _slot, uint256 _numOfBits) public view returns(uint8) {
    //     return uint8(_sliceNumber(_input, uint256(_numOfBits), _slot * _numOfBits));
    // } 

    // function _sliceNumber(uint256 _n, uint256 _nbits, uint256 _offset) public view returns (uint256) {
    //     // mask is made by shifting left an offset number of times
    //     uint256 mask = uint256((2**_nbits) - 1) << _offset;
    //     // AND n with mask, and trim to max of _nbits bits
    //     return uint256((mask & _n) >> _offset);
    // }  

    // function encode(uint8[] memory _traits, uint256 _numOfDigi, uint256 _numOfBits) public view returns (uint256 _genes) {
    //     _genes = 0;
    //     for(uint256 i = 0; i < _numOfDigi; i++) {
    //         _genes = _genes << _numOfBits;
    //         // bitwise OR trait with _genes
    //         _genes = _genes | _traits[(_numOfDigi - 1) - i];
    //     }
    //     return _genes;
    // }

    function _sliceNumber(uint256 _number, uint256 _pos, uint256 _offset) internal pure returns (uint256) {
        uint256 number = _number;
        uint256 digits = number / _pos;
        digits = digits % _offset;
        return digits;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}