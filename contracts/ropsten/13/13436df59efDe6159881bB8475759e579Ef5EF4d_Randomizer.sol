//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;


interface IRandomizer {
    function generateRandomNumbers(uint256 digits, uint256 size) external returns (uint256[] memory);
}

contract Randomizer is IRandomizer {
    // Initializing the state nonce variable
    uint256 internal _nonce = 0;

    // Defining a function to generate a random numbers
    function generateRandomNumbers(uint256 digits, uint256 size) public override returns (uint256[] memory) {
        uint256[] memory numbers = new uint256[](size);

        // Smallest amount which contarct can generate
        uint256 minAmount = 10 ** (digits - 1);

        // Max amount - small amount
        uint256 modules = 10 ** digits - minAmount;

        for (uint256 i = 0; i < size; i++) {
            uint256 randNumber = 0;

            while (true) {
              randNumber = minAmount + _generateNumber(modules);
              _nonce++;

              if (!_isArrayContain(numbers, randNumber)) break;
            }

            numbers[i] = randNumber;
        }
        return numbers;
    }

    function _generateNumber(uint256 modules) internal view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    msg.sender,
                    _nonce
                )
            )
        ) % modules;
    }

    function _isArrayContain(uint256[] memory array, uint256 number) internal pure returns (bool) {
        bool _isContain = false;

        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == number) {
                _isContain = true;
                break;
            }
        }

        return _isContain;
    }
}