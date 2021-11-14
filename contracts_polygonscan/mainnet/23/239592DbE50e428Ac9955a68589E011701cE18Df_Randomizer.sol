/**
 *Submitted for verification at polygonscan.com on 2021-11-14
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
    @author The Calystral Team
    @title A contract for Randomization
*/
contract Randomizer {
    /*==============================
    =            EVENTS            =
    ==============================*/
    /**
        @dev MUST emit when any random position is assigned.
        The `userAddress` argument MUST be the user's address.
        The `position` argument MUST be the random position.
    */
    event OnRandomPositionAssigned(
        address indexed userAddress,
        uint256 position
    );

    /*==============================
    =          CONSTANTS           =
    ==============================*/

    /*==============================
    =            STORAGE           =
    ==============================*/
    /// @dev A counter which is used to prevent identical outcomes for multiple rolls within the same block.
    uint256 private _randomnessNonce;

    /*==============================
    =          MODIFIERS           =
    ==============================*/

    /*==============================
    =          CONSTRUCTOR         =
    ==============================*/
    /** 
        @notice Creates and initializes the contract.
        @dev Creates and initializes the contract.
    */
    constructor() {}

    /*==============================
    =      PUBLIC & EXTERNAL       =
    ==============================*/
    /**
        @notice Assigns a user a random positon.
        @dev Assigns a user a random positon.
        Uint256 as the position space where each position is unique due to chance.
        _randomnessNonce is increased after the whole loop sine we use gasLeft() as well.
        Emits the `OnRandomPositionAssigned` event.
        @param userAddresses  The receiver
    */
    function assignRandomPosition(address[] calldata userAddresses) public {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            emit OnRandomPositionAssigned(
                userAddresses[i],
                _getRandomUnit256()
            );
        }
        _randomnessNonce++;
    }

    /*==============================
    =          RESTRICTED          =
    ==============================*/

    /*==============================
    =          VIEW & PURE         =
    ==============================*/
    /**
        @notice Mints a single card as an NFT.
        @dev    Creates a random number between 0 and uin256.
                Uses a nonce + gasLeft to prevent same outcomes in one block.
        @return A random uint256
    */
    function _getRandomUnit256() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        gasleft(),
                        _randomnessNonce
                    )
                )
            );
    }

    /*==============================
    =      INTERNAL & PRIVATE      =
    ==============================*/
}