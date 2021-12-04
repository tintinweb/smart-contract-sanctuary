// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
contratto libreria che implementa il sistema di clonazione dei contratti
*/

import '../OwnerBuilder.sol'; 
import '../OnlyBuilder.sol';
import '../SharedStruct.sol';



contract Cloning  { //non penso serva Onlybuilder

    address private _builderAddress;
    OnlyBuilder private ob;

    constructor(address addBuilder){
        ob = OnlyBuilder(addBuilder);
        _builderAddress = ob.getBuilderAddress();
    }

    modifier onlyBuilder(){
        //TODO: si potrebbe mettere un controllo che se builderAddress è vuoto fa prima update
        require(msg.sender == _builderAddress, "permission denied");
        _;
    }

    //TODO non so se sarà meglio toglierla o no
    function getBuilderAddress() public view returns(address){
        return _builderAddress;
    }
    //TODO poi togliere
    function setBuilderAddress(address add) public {
        _builderAddress = add;
    }


    /** chiama la funzione getBuilderAddress dal contratto onlybuilder
    per tenere aggiornato l'indirizzo della builder
    la può chiamare chiunque tanto nell'onlyBuilder la set è esclusiva sull'address amministratore */
    function updateBuilderAddress() public {
        _builderAddress = ob.getBuilderAddress();
    }

    function clone(address addr, TokenStruct memory tokenStruct) public onlyBuilder() returns (address){
        address clonedContract = _clone(addr);
        OwnerBuilder clonContract = OwnerBuilder(clonedContract);
        
        clonContract.initialize(tokenStruct);
        //clonContract.transferOw(_msgSender());
        //meccanismo di trans ownership
        return address(clonedContract); //in teoria questo o clonContract è uguale
    }

    function _clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }
}

//0xE98B6cF0B8a74e71Cb27fdE88A13567e6CBad341

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import './SharedStruct.sol';

/**
address aggiornamibe tramite set get del builder
la init può chiamarla solo il builder
 */

interface OwnerBuilder {


    //init token params after cloning
    function initialize(TokenStruct memory) external;

    function trasferisci(address) external;

    function stampa() external view returns(address);
    
    //essendo dentro la clonazione posso implementare qua i controlli sul chiamante
}

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

struct TokenStruct {
        string tsName;
        string tsSym;
        uint8 tsDec;
        uint256 tsTotSupply;
        uint8 tsBurnFee;
        uint8 tsRfiFee;
        uint8 tsSwapFee;
        uint256 tsLimitBefSwap;
        uint256 tsFeeDivisor;
        address tsDevAddress;
        address tsOwnerAddress;
        uint8 contractType;
    }