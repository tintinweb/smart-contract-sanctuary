/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

/// @title Voting with delegation.
contract QChain {
    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
    struct Shift {
        uint index;
        string date;
        string jsonData;
        string user;
        bool status;
    }

    address public shiftAddress;

    Shift[] public shifts;

    // This declares a state variable that
    // stores a `Shift` struct for each possible address.
    mapping(address => Shift[]) public shiftsAddresses;


    constructor() {
    }

    function insertShift(
        address userAddress,
        uint _index,
        string memory _date,
        string memory _jsonData,
        string memory _user,
        bool _status
    ) public {
        shiftsAddresses[userAddress].push(Shift({
            index: _index,
            date: _date,
            jsonData: _jsonData,
            user: _user,
            status: _status
        }));
    }


    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    function getShift(
        address userAddress
    ) public view
            returns (Shift[] memory _currentShifts)
    {
        return shiftsAddresses[userAddress];
    }
}