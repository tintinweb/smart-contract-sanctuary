/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.6;

/// @title A DummyContract
/// @author Laika Blockchain Lab
/// @notice This contract give out address to ApplicationForm
contract DummyContract {
    address private applicationForm = 0x888b1FFf8111Ac73831EFC5f3D22cA9669D2F094;

    /// @notice Give out address to ApplicationForm
    /// @return address to ApplicationForm
    function getApplicationForm() public view returns(address){
        return applicationForm;
    }
}