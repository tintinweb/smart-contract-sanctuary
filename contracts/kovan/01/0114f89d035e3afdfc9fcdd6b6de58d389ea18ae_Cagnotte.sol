/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* CAGNOTTE Groupe 3 */

/*
un smart contract pour créer une cagnotte collective
et une fois que l’on a atteint le plafond de la cagnotte
on envoie automatiquement ces fonds vers le destinateur préalablement définis.

- cagnotte : compte cagnotte
- detect plafond
- envoi fond destinataire (compte)
- envoi des fonds par users
*/

contract Cagnotte {
    
    //address addCagnotte;
    address destinataire;
    uint limitPlafond;
    uint funds;

    constructor(/* address _addCagnotte,*/ address _destinataire,uint _plafond) {
		//addCagnotte = _addCagnotte;
		destinataire = _destinataire;
        limitPlafond = _plafond;
    }

    function addFondUser() payable external {
		// ajout fond addCagnotte (automatique)
		/*
        address payable player = payable(msg.sender);
        //require(address(this).balance > 0);
        // Envoie toute la balance (monaire) à celui qui à résolu le contract
        player.transfer(msg.value);
		*/
		// detect le plafond
		if(address(this).balance >= limitPlafond) {
			sendCoin();
			// end game
		}
        //exemple
        // >> https://kovan.etherscan.io/address/0x7D40Eb66aD44C3bF0355c9657f612f2Ca09d81a1

	}

    function sendCoin() public payable {
		// transaction
        address payable target = payable(destinataire);
        //require(address(this).balance >= limitPlafond);
        // Envoie toute la balance (monaire) à celui qui à résolu le contract
        target.transfer(address(this).balance);
	}
}

// https://www.une-blockchain.fr/solidity-transferer-des-ether-rendre-une-fonction-payante/