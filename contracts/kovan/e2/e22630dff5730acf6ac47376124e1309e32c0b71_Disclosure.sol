/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 Varia LLC
pragma solidity 0.8.6;
// @dev Credit to Erich Dylus & Sarah Brennan
contract Disclosure {
    uint256 count;
    string public disclosureTemplate = "https://gateway.pinata.cloud/ipfs/QmR9vB18fJw3HpJNVTrHWkyKCE8xTetTRQhED1H8pTMZaY";
    
    event Signed(uint256 indexed id, string details);
    
    function sign(string calldata details) external returns (uint256 id) {
        count++;
        id = count;
        emit Signed(id, details);
    }
}