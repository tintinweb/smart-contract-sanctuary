// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CyBlocGeneScientist {
    uint256 public numOfBits = 5;
    uint256 public numOfslices = 48;
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

    function setNumOfSlice(uint256 _numOfslices) public  {
        numOfslices = _numOfslices;
    }    

    function decode(uint256 _genes) public view returns(uint256 genes) {
        uint8[] memory traits = new uint8[](numOfslices);
        uint256 i;
        for(i = 0; i < numOfslices; i++) {
            traits[i] = _get5Bits(_genes, i);
        }
        genes = encode(traits);
        return genes;
    }  

    function _get5Bits(uint256 _input, uint256 _slot) public view returns(uint8) {
        return uint8(_sliceNumber(_input, uint256(numOfBits), _slot * numOfBits));
    }      

    function _sliceNumber(uint256 _n, uint256 _nbits, uint256 _offset) public view returns (uint256) {
        // mask is made by shifting left an offset number of times
        uint256 mask = uint256((2**_nbits) - 1) << _offset;
        // AND n with mask, and trim to max of _nbits bits
        return uint256((_n & mask) >> _offset);
    }    

    function encode(uint8[] memory _traits) public view returns (uint256 _genes) {
        _genes = 0;
        for(uint256 i = 0; i < numOfslices; i++) {
            _genes = _genes << numOfBits;
            // bitwise OR trait with _genes
            _genes = _genes | _traits[(numOfslices - 1) - i];
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