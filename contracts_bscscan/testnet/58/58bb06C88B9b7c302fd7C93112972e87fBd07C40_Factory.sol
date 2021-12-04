// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//importo l'interfaccia
import './FactoryInterface.sol';

import './libraries/Cloning.sol';
//import './libraries/TGSharedStruct.sol';

import './OwnerBuilder.sol'; 

import "@openzeppelin/contracts/utils/Context.sol";

//import './SharedStruct.sol'; //T

contract Factory is FactoryInterface, Context {

    //TODO: aggiunta dei contratti da clonare va gestita con modificatore
    
    /*TEMP PER VEDERE NUOVI CONTRATTI */
    address[] contracts;
    Cloning private cloning;

    mapping(uint8 => address) private typesOfContracts;

    constructor(address addCloning){
        cloning = Cloning(addCloning);
    }

    function getContractCount() public view returns(uint contractCount) { //TODO togliere
        return contracts.length;
    }

    function getTypeContractAddress(uint8 index) public view returns(address) { //TODO solo amministratore
        return typesOfContracts[index];
    }

    function setTypeContract(address add, uint8 i) public   { //TODO SOLO AMMINISTRATORE
        typesOfContracts[i] = add;
    }


    function createToken(  //TODO il chiamante può essere solo la pagina web (come?) (anche amministratore ?)
        TokenStruct memory struttura
        ) public override returns(address success){

        //i controlli li faccio gia nel frontend quindi si potrebbero togliere
        require(bytes(struttura.tsName).length > 0, "token name cannot be empty");
        require(bytes(struttura.tsSym).length > 0, "token symbol cannot be empty");
        require(struttura.tsDec >= 0, "token decimal must be >0");
        //TODO: controllo che la struttura non sia vuota
        //TODO: enable/disable factory sistema
        //TODO: tutt i i metodi dic reazione payable


        
        //NB IL CONTROLLO PER L'ADDRESS LO FACCIO IN CONTRACTMODEL CON ADDRESS(1)
        //QUINDI SUL FRONTEND ANDRà IMPOSTATO QUESTO SE UNO NON SPECIFICA:
        //0x0000000000000000000000000000000000000001

        /**
        0 erc20
        1 erc20 + burn
        2 erc20 + rfi
        3 erc20 + burn + rfi
        4 erc20 + burn + rfi + swap
         */
/*
        TokenStruct memory tokenStruct = TokenStruct(
            name_,
            sym_, 
            decimals_, 
            totSupply_, 
            burnFee_, 
            rfiFee_, 
            swapFee_, 
            limitBefSwap_, 
            feeDivisor_, 
            devAddress_, 
            ownerAddress_
            );*/

        address clonedContract = cloning.clone(typesOfContracts[struttura.contractType], struttura);
        contracts.push(clonedContract);
        OwnerBuilder A = OwnerBuilder(clonedContract);
        A.trasferisci(_msgSender());
        _prova(A);
        return address(clonedContract);


    /*
        //tipologie di token
        //TODO si potrebbe mettere evento per tipo di token creato
        //NB a tutte è possibile attivare e disattivare charity
        if ((burnFee_==0) && (rfiFee_==0) && (swapFee_==0)) { //erc20  0
            tokenStruct = TokenStruct(name_, sym_, decimals_, totSupply_, 0, 0, 0, 0, 0, devAddress_, ownerAddress_);
            address clonedContract = clone(0x5E35CFa02a4183A4C3aECa607f5Dcd408224A55B, tokenStruct); // ADDRESS DA CLONARE //  new contractModel(tokName, tokSym, tokStruct);
            contracts.push(clonedContract);
            //TODO qua va fatta l'init del token con la struttura -> no perchè dovrei importarlo, la faccio nel costruttore 
            //non so se posso farla dopo perchè non ho il contratto sotto mano
            
            return address(clonedContract); //TODO: controllo se è un address non sarebbe male

        }else if((burnFee_>0) && (rfiFee_==0) && (swapFee_==0)) {// erc20 + burn  1
            tokenStruct = TokenStruct( name_, sym_, decimals_, totSupply_, 0, 0, burnFee_, 0, feeDivisor_, devAddress_, ownerAddress_);
            address clonedContract = clone(address(1), tokenStruct); // ADDRESS DA CLONARE //  new contractModel(tokName, tokSym, tokStruct);
            contracts.push(clonedContract);
            //TODO qua va fatta l'init del token con la struttura -> no perchè dovrei importarlo, la faccio nel costruttore 
            return address(clonedContract); //TODO: controllo se è un address non sarebbe male

    
        }else if((burnFee_==0) && (rfiFee_>0) && (swapFee_==0)) {// erc20 + rfi  2
            tokenStruct = TokenStruct( name_, sym_, decimals_, totSupply_, 0, 0, burnFee_, 0, feeDivisor_, devAddress_, ownerAddress_);
            address clonedContract = clone(address(1), tokenStruct); // ADDRESS DA CLONARE //  new contractModel(tokName, tokSym, tokStruct);
            contracts.push(clonedContract);
            //TODO qua va fatta l'init del token con la struttura -> no perchè dovrei importarlo, la faccio nel costruttore 
            return address(clonedContract); //TODO: controllo se è un address non sarebbe male

    
        }else if((burnFee_>0) && (rfiFee_>0) && (swapFee_==0)) {// erc20 + burn + RFI  3
            tokenStruct = TokenStruct( name_, sym_, decimals_, totSupply_, 0, 0, burnFee_, 0, feeDivisor_, devAddress_, ownerAddress_);
            address clonedContract = clone(address(1), tokenStruct); // ADDRESS DA CLONARE //  new contractModel(tokName, tokSym, tokStruct);
            contracts.push(clonedContract);
            //TODO qua va fatta l'init del token con la struttura -> no perchè dovrei importarlo, la faccio nel costruttore 
            return address(clonedContract); //TODO: controllo se è un address non sarebbe male

    
        }else if((burnFee_>0) && (rfiFee_>0) && (swapFee_>0)) {// erc20 + burn + RFI + swap  4
            tokenStruct = TokenStruct( name_, sym_, decimals_, totSupply_, 0, 0, burnFee_, 0, feeDivisor_, devAddress_, ownerAddress_);
            address clonedContract = clone(address(1), tokenStruct); // ADDRESS DA CLONARE //  new contractModel(tokName, tokSym, tokStruct);
            contracts.push(clonedContract);
            //TODO qua va fatta l'init del token con la struttura -> no perchè dovrei importarlo, la faccio nel costruttore 
            return address(clonedContract); //TODO: controllo se è un address non sarebbe male

    
        }else {
            //TODO: si potrebbe mettere errore + evento d'errore
        }
        */
        

        
    }

    function _prova(OwnerBuilder a) public view returns(address) {
        address pluto = a.stampa();
        return pluto;
        
    }





}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import './SharedStruct.sol';

interface FactoryInterface {
    function createToken(
        TokenStruct memory struttura
        ) external returns(address success);
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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