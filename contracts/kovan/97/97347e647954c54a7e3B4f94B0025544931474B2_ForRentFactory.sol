/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// File: ForRentFactory.sol

contract ForRentFactory {
    uint8 reservationPercentage = 20;

    struct ForRent {
        uint256 forRentId;
        string name;
        address lockBoxAddress;
        uint256 price;
        bool reservated;
        bool paid;
    }

    ForRent[] public forRentArray;
    // lockBoxAddress => ownerAddress
    mapping(address => address) public forRentToOwner;
    // lockBoxAddress => renterAddress
    mapping(address => address) public forRentToRenter;

    function _createForRent(
        string memory _name,
        address _lockBoxAddress,
        uint256 _price
    ) public {
        forRentArray.push(
            ForRent(
                forRentArray.length,
                _name,
                _lockBoxAddress,
                _price,
                false,
                false
            )
        );
        forRentToOwner[_lockBoxAddress] = msg.sender;
    }

    function _freeForRent(uint256 _forRentId) public {
        //Declare forRent
        ForRent storage forRent = forRentArray[_forRentId];

        //Check if user is the owner
        require(
            forRentToOwner[forRent.lockBoxAddress] == msg.sender,
            "Only owner can free"
        );

        //Free
        forRent.reservated = false;
        forRent.paid = true;
        forRentToRenter[forRent.lockBoxAddress] = address(
            0x0000000000000000000000000000000000000000
        );
    }
}