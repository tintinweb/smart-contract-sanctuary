/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.6;

/// @title ApplicationForm
/// @author Laika Blockchain Lab
/// @notice This contract register applicant to application form
contract ApplicationForm {
    mapping(address => bool) public applicants;

    /// @notice Register address of sender to applicationForm
    function register() public {
        applicants[msg.sender] = true;
    }

    /// @notice return status of applicant
    function status(address _applicant) public view returns (bool) {
        return applicants[_applicant];
    }
}