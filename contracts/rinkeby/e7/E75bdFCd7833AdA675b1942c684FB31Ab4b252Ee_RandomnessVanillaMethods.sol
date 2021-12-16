// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract RandomnessVanillaMethods {
    
    address public methodsContract;

    function setGlobalParameters(address methods) external {
        methodsContract = methods;
    }

    /**
     * DIIMIIM: FOR PRODUCTION PURPOSE ONLY !!!
     */
    function getRandomNumber(bytes memory input) external view returns(uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty, 
                    block.timestamp, 
                    block.gaslimit,
                    blockhash(block.number-1),
                    input
                )
            )
        );
    }

}