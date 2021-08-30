// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./PetMinting.sol"; 

contract PetCore is PetMinting{

    constructor (string memory _baseUri) {

        _createPet(0, 0, 0, address(0));
        _setBaseURI(_baseUri);

    }

    /// @dev Reject all Eth from sent here, unless it's from the auction contract.
    receive() external payable{
       require( msg.sender == address(saleAuction), "Reject");
    }

    /// @notice Returns all the relevant information about a specific pet.
    /// @param _id The ID of the pet of interest.
    function getPet(uint256 _id)
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
        Pet storage _pet = pets[_id];

        // if this variable is 0 then it's not gestating
        isGestating = (_pet.siringWithId != 0);
        isReady = (_pet.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(_pet.cooldownIndex);
        nextActionAt = uint256(_pet.cooldownEndBlock);
        siringWithId = uint256(_pet.siringWithId);
        birthTime = uint256(_pet.birthTime);
        matronId = uint256(_pet.matronId);
        sireId = uint256(_pet.sireId);
        generation = uint256(_pet.generation);
    }

     // @dev Allows the owner to capture the balance available to the contract.
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        // Subtract all the currently pregnant pets we have, plus 1 of margin.
        uint256 subtractFees = (pregnantPets + 1) * autoBirthFee;

        if (balance > subtractFees) {
            payable(msg.sender).transfer(balance - subtractFees);
        }
    }
}