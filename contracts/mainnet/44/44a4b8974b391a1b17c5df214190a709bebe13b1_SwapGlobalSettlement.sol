/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity 0.6.7;

abstract contract Setter {
    function addAuthorization(address) external virtual;
    function removeAuthorization(address) external virtual;
}

abstract contract GlobalSettlementLike {
    function safeEngine() public virtual returns (address);
    function liquidationEngine() public virtual returns (address);
    function accountingEngine() public virtual returns (address);
    function oracleRelayer() public virtual returns (address);
    function stabilityFeeTreasury() public virtual returns (address);
}

contract SwapGlobalSettlement {

    function execute(address oldGlobalSettlement, address newGlobalSettlement) public {

        // get old GlobalSettlement
        GlobalSettlementLike oldContract = GlobalSettlementLike(oldGlobalSettlement);

        // getting old GlobalSettlement vars
        address safeEngine = oldContract.safeEngine();
        address liquidationEngine = oldContract.liquidationEngine();
        address accountingEngine = oldContract.accountingEngine();
        address oracleRelayer = oldContract.oracleRelayer();
        address stabilityFeeTreasury = oldContract.stabilityFeeTreasury();

        // Authing new GlobalSettlement
        Setter(safeEngine).addAuthorization(newGlobalSettlement);
        Setter(liquidationEngine).addAuthorization(newGlobalSettlement);
        Setter(accountingEngine).addAuthorization(newGlobalSettlement);
        Setter(oracleRelayer).addAuthorization(newGlobalSettlement);
        Setter(stabilityFeeTreasury).addAuthorization(newGlobalSettlement);

        // Deauthing old GlobalSettlement
        Setter(safeEngine).removeAuthorization(oldGlobalSettlement);
        Setter(liquidationEngine).removeAuthorization(oldGlobalSettlement);
        Setter(accountingEngine).removeAuthorization(oldGlobalSettlement);
        Setter(oracleRelayer).removeAuthorization(oldGlobalSettlement);
        Setter(stabilityFeeTreasury).removeAuthorization(address(oldGlobalSettlement));
    }
}