/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// File: SmartLease.sol

contract SmartLease {
    //The address & address payable types store 160-bit Ethereum address.
    //The difference between the two is that the latter type(address payble) permits the following calls: .send(), .transfer(), .call()
    address lessor;
    address payable lessee;

    enum CONTRACT_STATUS {
        CREATED,
        ACTIVE,
        TERMINATED
    }

    //------------------------Setting  the identity of the LESSOR and the LESSEE----------------------------//
    function set_lessor(address _lessor) public {
        lessor = _lessor;
    }

    function get_lessor() public view returns (address) {
        return lessor;
    }

    function set_lessee(address payable _lessee) public {
        lessee = _lessee;
    }

    function get_lessee() public view returns (address) {
        return lessee;
    }
    //------------------------Setting  the profile of the leased CAR--------------------------------------//
}