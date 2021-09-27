/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// File: Gehirn.sol

/**
 * @title Gehirn von Thomas Wenzlaff
 * @dev Mein Smart Contract mit solidity zum Speichern von IQ auf der Blockchain
 */
contract Gehirn {

    uint256 iq;

    constructor() public {
        // Mittelwert des IQ setzen
        iq = 100;
    }

    function setIQ(uint256 neuerIQ) public payable {
        iq = neuerIQ;
    }

    function getIQ() public view returns (uint256) {
        return iq;
    }

    function getBedeutung() public view returns (string memory) {
        if (iq <= 40) return "Keine Aussagekraft";
        if (iq >= 41 && iq <= 70) return "Weit unterdurchschnittlich – Geistige Behinderung";
        if (iq >= 71 && iq <= 79) return "unterdurchschnittlich";
        if (iq >= 80 && iq <= 89) return "etwas unterdurchschnittlich";
        if (iq >= 90 && iq <=109) return "Durchschnitt";
        if (iq >= 110 && iq <=119) return "hoch";
        if (iq >= 120 && iq <= 129) return "sehr hoch";
        if (iq >= 130 && iq <= 159) return "hochbegabt";
        if (iq > 160) return "Keine Aussagekraft";
    }
}