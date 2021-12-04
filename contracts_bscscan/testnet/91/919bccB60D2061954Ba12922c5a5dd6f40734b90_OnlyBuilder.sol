// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/** offre il metodo getBuilderAddress che serve per far funzionare il modificatore 
del contratto Cloning che garantisce l'uso della funzione clone solo ed esclusivamente
a un contratto specifico, in questo caso al contratto builder

è inoltre presente un sistema di amministrazione con un address specificato in fase di deploy
per eventualmente cambiare il builder address nel caso in cui sia necessario rideployare
il contratto builder */

/**
address aggiornamibe tramite set get del builder
la init può chiamarla solo il builder
 */

/**
nel costruttore viene settato l'address dell'amministratore
l'amministratore può modificare l'address del contratto di builder
la funzione get restituisce l'indirizzo del contratto di builder
 */
contract OnlyBuilder {
    //TODO: evento sull'aggiornamento del builder address

    address private _builderAddress;
    address private immutable _AmministrationAddress;

    constructor (address add){
        _AmministrationAddress = add;
    }

    modifier onlyAmministrator(){
        require(msg.sender == _AmministrationAddress, "Permission denied");
        _;
    }

    function updateBuilderAddress(address newAddress_) public onlyAmministrator(){
        _builderAddress = newAddress_;
    }

    function getBuilderAddress() public returns(address) { //da capire se aggiungere view o mettere internal
        return _builderAddress;
    }

    function getAmministratorAddress() public returns(address){
        return _AmministrationAddress;
    }

    

    //essendo dentro la clonazione posso implementare qua i controlli sul chiamante
}