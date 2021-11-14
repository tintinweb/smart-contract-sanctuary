/**
 *Submitted for verification at polygonscan.com on 2021-11-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGaussianRNG {
    function getGaussianRandomNumbers(uint256 salt, uint256 n) external view returns (uint256, int256[] memory);
    function reproduceGaussianRandomNumbers(uint256 seed, uint256 n) external view returns (int256[] memory);
    function countOnes(uint256 n) external pure returns (uint256);
}

///@author Simon Tian
///@title A novel on-chain Gaussian random number generator.
contract GaussianRNG is IGaussianRNG {
    /// A Gaussian random number generator
    /// @param salt A user provided number to create a seed, this can be from an
    /// off-chain or another on-chain reliable source of randomness, to avoid
    /// being manipulated by miners.
    /// @param n The number of random numbers to be generated, ideally < 1000
    /// @return seed The seed for this sequence of numbers, which can be used
    /// in another function for reproducing the same sequence of numbers.
    /// @return nums Desired sequence of Gaussian random numbers
    function getGaussianRandomNumbers(uint256 salt, uint256 n)
        public
        view
        override
        returns(uint256, int256[] memory)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(salt + block.timestamp)));
        return (seed, _GaussianRNG(seed, n));
    }

    /// To reproduce Gaussian random numbers with a given seed
    /// @param seed Seed value for a sequence of random numbers
    /// @param n The number of random numbers to be generated
    /// @return sequence of random numbers
    /// @notice This function is used for recreating a sequence of numbers given
    /// seed generated in the previous function.
    function reproduceGaussianRandomNumbers(uint256 seed, uint256 n)
        public
        pure
        override
        returns(int256[] memory)
    {
        return _GaussianRNG(seed, n);
    }

    /// An internal function generating Gaussian random numbers
    /// @param seed Seed value for a sequence of random numbers
    /// @param n The number of random numbers to be generated
    /// @return sequence of random numbers
    function _GaussianRNG(uint256 seed, uint256 n)
        internal
        pure
        returns (int256[] memory)
    {
        uint256 _num = uint256(keccak256(abi.encodePacked(seed)));
        int256[] memory results = new int256[](n);

        for (uint256 i = 0; i < n; i++) {
            uint256 result = _countOnes(_num);
            results[i] = int256(result * 125) - 16000;
            _num = uint256(keccak256(abi.encodePacked(_num)));
        }

        return results;
    }

    /// A public function for counting number of 1s in the binary representation
    /// of a hashed value produced by the keccak256 hashing algorithm.
    /// @param n The number to be checked.
    /// @return count The number of 1's.
    function countOnes(uint256 n) public pure override returns (uint256) {
        return _countOnes(n);
    }

    /// An internal function in assembly to count number of 1's
    /// https://www.geeksforgeeks.org/count-set-bits-in-an-integer/
    /// @param n The number to be checked.
    /// @return count The number of 1s.
    function _countOnes(uint256 n) internal pure returns (uint256 count) {
        assembly {
            for { } gt(n, 0) { } {
                n := and(n, sub(n, 1))
                count := add(count, 1)
            }
        }
    }
}