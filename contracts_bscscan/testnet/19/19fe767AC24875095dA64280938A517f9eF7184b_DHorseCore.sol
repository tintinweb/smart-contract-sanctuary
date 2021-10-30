// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./DHorseMinting.sol"; 

contract DHorseCore is DHorseMinting{

    constructor (string memory _baseUri) {

        _createHorse(0, 0, 0, address(0));
        _setBaseURI(_baseUri);

    }

    /// @dev Reject all Eth from sent here, unless it's from the auction contract.
    receive() external payable{
       require( msg.sender == address(saleAuction), "Reject");
    }

    /// @notice Returns all the relevant information about a specific DHorse.
    /// @param _id The ID of the DHorse of interest.
    function getDHorse(uint256 _id)
        external
        view
        returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation
    ) {
        Horse storage _Horse = Horses[_id];

        // if this variable is 0 then it's not gestating
        isGestating = (_Horse.siringWithId != 0);
        isReady = (_Horse.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(_Horse.cooldownIndex);
        nextActionAt = uint256(_Horse.cooldownEndBlock);
        siringWithId = uint256(_Horse.siringWithId);
        birthTime = uint256(_Horse.birthTime);
        matronId = uint256(_Horse.matronId);
        sireId = uint256(_Horse.sireId);
        generation = uint256(_Horse.generation);
    }

     // @dev Allows the owner to capture the balance available to the contract.
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        // Subtract all the currently pregnant Horses we have, plus 1 of margin.
        uint256 subtractFees = (pregnantHorses + 1) * autoBirthFee;

        if (balance > subtractFees) {
            payable(msg.sender).transfer(balance - subtractFees);
        }
    }
}