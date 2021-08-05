/**
 *Submitted for verification at Etherscan.io on 2021-01-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.4;

/* Questo è uno smart contract di notarizzazione e 
    viene realizzato senza finalità commerciali */
    
contract Notarizzazione {

    string datoRegistrato; //creo una variabile di stato per contenere il dato da notarizzare
    
    /* Creo una funzione per notarizzare il dato. 
    L'azione che deve compiere la funzione è quella di inserire all'interno della variabile
    di stato "datoRegistrato" il codice hash che le comunicherò.  */
    function notarizzaDato(string memory _dato) public {
        datoRegistrato = _dato;
    }
}