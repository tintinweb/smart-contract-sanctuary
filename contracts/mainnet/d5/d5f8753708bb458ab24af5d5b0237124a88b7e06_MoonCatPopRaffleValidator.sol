/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

interface IMoonCatAcclimator {
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IMoonCatRescue {
    function rescueOrder(uint256 tokenId) external view returns (bytes5);
    function catOwners(bytes5 catId) external view returns (address);
}

interface IMoonCatAccessories {
    function doesMoonCatOwnAccessory (uint256 rescueOrder, uint256 accessoryId) external view returns (bool);
}

library MoonCatBitSet {

    bytes32 constant Mask =  0x0000000000000000000000000000000000000000000000000000000000000001;

    function setBit(bytes32[100] storage set, uint16 index)
        internal
    {
        uint16 wordIndex = index / 256;
        uint16 bitIndex = index % 256;
        bytes32 mask = Mask << (255 - bitIndex);
        set[wordIndex] |= mask;
    }

    function clearBit(bytes32[100] storage set, uint16 index)
        internal
    {
        uint16 wordIndex = index / 256;
        uint16 bitIndex = index % 256;
        bytes32 mask = ~(Mask << (255 - bitIndex));
        set[wordIndex] &= mask;
    }

    function checkBit(bytes32[100] memory set, uint256 index)
        internal
        pure
        returns (bool)
    {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        bytes32 mask = Mask << (255 - bitIndex);
        return (mask & set[wordIndex]) != 0;
    }
}

/**
 * @title MoonCatPop Raffle Validator
 * @dev Does checks for the data submitted to the MoonCatPop raffle contract for validity.
 */
contract MoonCatPopRaffleValidator {

    ///// External Contracts /////
    IMoonCatAcclimator MCA = IMoonCatAcclimator(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69);
    IMoonCatRescue MCR = IMoonCatRescue(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6);
    IMoonCatAccessories ACC = IMoonCatAccessories(0x8d33303023723dE93b213da4EB53bE890e747C63);

    bytes32[100] public Available;

    address immutable raffleContractAddress;

    /**
     * @dev Is a given MoonCat already entered in the raffle?
     */
    function isAvailable (uint256 rescueOrder) public view returns (bool) {
        return MoonCatBitSet.checkBit(Available, rescueOrder);
    }

    /**
     * @dev Callback function for the Raffle contract to check if a ticket should be allowed.
     */
    function validate (address account, bytes memory metadata) public returns (bool) {
        require(msg.sender == raffleContractAddress, "Invalid Sender");
        require(metadata.length >= 4, "Invalid Metadata");

        uint16 rescueOrder;
        assembly {
            rescueOrder := mload(add(add(metadata, 0x2), 0))
        }

        require(MoonCatBitSet.checkBit(Available, rescueOrder), "Already Minted");
        MoonCatBitSet.clearBit(Available, rescueOrder);

        require(MCR.catOwners(MCR.rescueOrder(rescueOrder)) == address(MCA), "Not Acclimated");

        address moonCatOwner = MCA.ownerOf(rescueOrder);
        require((account == moonCatOwner)
                || (account == MCA.getApproved(rescueOrder))
                || (MCA.isApprovedForAll(moonCatOwner, account)),
                "Not Owner or Approved");


        uint16 accessoryCount;
        assembly {
            accessoryCount := mload(add(add(metadata, 0x2), 2))
        }

        require(metadata.length >= accessoryCount * 2 + 4, "Invalid Metadata");

        uint16 accessoryId;
        for (uint i = 0; i < accessoryCount; i++) {
            uint256 offset = (i + 2) * 2;
            assembly {
              accessoryId := mload(add(add(metadata, 0x2), offset))
            }
            require(ACC.doesMoonCatOwnAccessory(rescueOrder, accessoryId), "Accessory Not Owned");
        }

        return true;

    }

    constructor (address raffleContract) {
        for (uint i = 0; i < 100; i++) {
            //initialize all BitSet Values to save ticker buyers gas
            Available[i] = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        raffleContractAddress = raffleContract;
    }
}