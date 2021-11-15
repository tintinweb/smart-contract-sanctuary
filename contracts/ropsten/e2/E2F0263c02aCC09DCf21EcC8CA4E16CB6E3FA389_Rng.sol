// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/IRng.sol";

contract Rng is IRng {

    uint256 constant OLDEST_AVAILABLE_BLOCK = 256;

    function getRandomNumbers(uint256 _quantity) override external view returns (uint256[] memory) {
        uint256[] memory randomNumbers = new uint256[](_quantity);
        randomNumbers[0] = uint256(blockhash(block.number));
        for (uint256 i = 1; i < _quantity; i++) {
            randomNumbers[i] = uint256(blockhash(block.number - randomNumbers[i - 1] % OLDEST_AVAILABLE_BLOCK));
        }
        return randomNumbers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IRng {
    
    /**
     * @param _quantity The quantity of random numbers to output
     * @return A random number array of the given length
     */
    function getRandomNumbers(uint256 _quantity) external returns (uint256[] memory);
}

