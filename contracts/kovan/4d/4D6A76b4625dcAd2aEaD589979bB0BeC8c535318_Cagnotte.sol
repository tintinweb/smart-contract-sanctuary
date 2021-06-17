/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* CAGNOTTE Groupe 3 */

/*
exercice du 17/06/2021
un smart contract pour créer une cagnotte collective
et une fois que l’on a atteint le plafond de la cagnotte
on envoie automatiquement ces fonds vers le destinateur préalablement définis.
*/

contract Cagnotte {
    
    address destinataire;
    uint limitPlafond;
    uint funds;

    constructor(address _destinataire,uint _plafond) {
		destinataire = _destinataire;
        limitPlafond = _plafond;
    }

    fallback() external payable {}

    function getBalance() external view returns (uint) {
        return uint(address(this).balance);
    }
    
    function sendCoin() external {
        address payable target = payable(destinataire);
        require(address(this).balance >= limitPlafond);
        target.transfer(address(this).balance);
	}
}