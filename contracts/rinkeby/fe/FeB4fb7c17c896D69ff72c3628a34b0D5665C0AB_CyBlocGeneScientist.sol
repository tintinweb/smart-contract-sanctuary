// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CyBlocGeneScientist {
    uint256 public numOfBits = 5;
    uint256 public bitClass = 10;
    uint256 public bitTrait = 20;
    uint256 public numOfTraits = 3;
    function validateGene(uint256 gene) public pure returns (bool) {
        return gene > 0;
    }

    function generateGene(uint256 class, uint256[3] memory traits) public pure returns (uint256) {
        return class + traits.length;
    }

    function parseGene(uint256 gene) public pure returns (uint256 class, uint256[3] memory traits) {
        return (gene, [uint256(0), uint256(0), uint256(0)]);
    }

    function mixGenes(uint256[2] memory genes, uint256 randomNumber) public pure returns (uint256) {
        return genes[0] + genes[1] + randomNumber;
    }

    function setNumOfBit(uint256 _numOfBits) public  {
        numOfBits = _numOfBits;
    }

    function setNumOfTrait(uint256 _numOfTraits) public  {
        numOfTraits = _numOfTraits;
    }    

    function setBitClass(uint256 _bitClass) public  {
        bitClass = _bitClass;
    }    

    function setBitTrait(uint256 _bitTrait) public  {
        bitTrait = _bitTrait;
    }       

    function decode(uint256 _genes) public view returns(uint256 class, uint256 trait) {
        // uint8[] memory traits = new uint8[](numOfTraits);
        
        // uint256 i;
        // for(i = 0; i < numOfTraits; i++) {
        //     traits[i] = _getBits(_genes, i, bitTrait);
        // }

        class = _sliceNumber(_genes, 0, bitClass);
        trait = _sliceNumber(_genes, 11, bitTrait);
        return (class, trait);
    }  

    function _get5Bits(uint256 _input, uint256 _slot,uint256 _numOfBit) public view returns(uint8) {
        return uint8(_sliceNumber(_input, uint256(_numOfBit), _slot * _numOfBit));
    }      

    function _sliceNumber(uint256 _n, uint256 _nbits, uint256 _offset) public view returns (uint256) {
        // mask is made by shifting left an offset number of times
        uint256 mask = uint256((2**_nbits) - 1) << _offset;
        // AND n with mask, and trim to max of _nbits bits
        return uint256((_n & mask) >> _offset);
    }    

    function encode(uint8[] memory _traits, uint256 _numOfBit) public view returns (uint256 _genes) {
        _genes = 0;
        for(uint256 i = 0; i < numOfTraits; i++) {
            _genes = _genes << 5;
            // bitwise OR trait with _genes
            _genes = _genes | _traits[(numOfTraits - 1) - i];
        }
        return _genes;
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