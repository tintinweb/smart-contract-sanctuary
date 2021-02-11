/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

pragma solidity ^0.7.4;
// SPDX-License-Identifier: UNLICENSED;

contract SceneOuverte {

    string[24] public programme;
    uint emplacementsLibres = 24;
    
    function enregistrer(string memory artist) public {
        programme[24-emplacementsLibres] = artist;
        emplacementsLibres = emplacementsLibres - 1;
    }

}