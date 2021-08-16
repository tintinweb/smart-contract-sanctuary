/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

pragma solidity >=0.5.8;

/**
 * @title True random number generator
 * @notice This is a contract to generate a true random number on blockchai.
 * Though true random number generators doesn't require seed. But, to simplify
 * the functions i used seed and other terms used in PRNGs,
 * seed should be enough to generate a random number, but to randomize the pattern
 * even more i added two more functions with salt and sugar.
 */
contract Test {
    uint8 ID = 0;
    /**
        * @notice Generates a random number between 0 - 100
        * @param seed The seed to generate different number if block.timestamp is same
        * for two or more numbers.
        */
    function Rand(uint256 seed)public {
        bytes32 bHash = blockhash(block.number - 1);
        uint8 randomNumber = uint8(
            uint256(keccak256(abi.encodePacked(block.timestamp, bHash, seed))) % 100
        );
        ID = randomNumber;
    }

    
}