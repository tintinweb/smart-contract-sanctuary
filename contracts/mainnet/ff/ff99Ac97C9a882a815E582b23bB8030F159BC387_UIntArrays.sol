// contracts/UIntArrays.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


library UIntArrays {
    function sum(uint[] memory _array) public pure returns (uint result) {
        result = 0;
        for (uint i = 0; i < _array.length; i++){
            result += _array[i];
        }
    }

    function randomIndexFromWeightedArray(uint[] memory _weightedArray, uint _randomNumber) public pure returns (uint) {
        uint totalSumWeight = sum(_weightedArray);
        require(totalSumWeight > 0, "Array has no weight");
        uint randomSumWeight = _randomNumber % totalSumWeight;
        uint currentSumWeight = 0;

        for (uint i = 0; i < _weightedArray.length; i++) {
            currentSumWeight += _weightedArray[i];
            if (randomSumWeight < currentSumWeight) {
                return i;
            }
        }

        return _weightedArray.length - 1;
    } 

    function hash(uint[] memory _array, uint _endIndex) public pure returns (bytes32) {
        bytes memory encoded;
        for (uint i = 0; i < _endIndex; i++) {
            encoded = abi.encode(encoded, _array[i]);
        }

        return keccak256(encoded);
    }

    function arrayFromPackedUint(uint _packed, uint _size) public pure returns (uint[] memory) {
        uint[] memory array = new uint[](_size);

        for (uint i = 0; i < _size; i++) {
            array[i] = uint256(uint16(_packed >> (i * 16)));
        }

        return array;
    }

    function packedUintFromArray(uint[] memory _array) public pure returns (uint _packed) {
        require(_array.length < 17, "pack array > 16");
        for (uint i = 0; i < _array.length; i++) {
            _packed |= _array[i] << (i * 16);
        }
    }

    function elementFromPackedUint(uint _packed, uint _index) public pure returns (uint) {
        return uint256(uint16(_packed >> (_index * 16)));
    }

    function decrementPackedUint(uint _packed, uint _index, uint _number) public pure returns (uint result) {
        result = _packed & ~(((1 << 16) - 1) << (_index * 16));
        result |= (elementFromPackedUint(_packed, _index) - _number) << (_index * 16);
    }

    function incrementPackedUint(uint _packed, uint _index, uint _number) public pure returns (uint result) {
        result = _packed & ~(((1 << 16) - 1) << (_index * 16));
        result |= (elementFromPackedUint(_packed, _index) + _number) << (_index * 16);
    }

    function mergeArrays(uint[] memory _array1, uint[] memory _array2, bool _isPositive) public pure returns (uint[] memory) {
        for (uint i = 0; i < _array1.length; i++) {
            if (_isPositive) {
                _array1[i] += _array2[i];
            } else {
                _array1[i] -= _array2[i];
            }
            
        }
        return _array1;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 20
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