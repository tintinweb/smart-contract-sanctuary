// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

// ErrNum:
//  1 - OnlyOwner

contract SparkleSwapGasRebateOracleV3 {

    address private _owner;
    uint128 private _rebateTX;
    uint128 private _rebateLP;

    constructor(uint128 _initialTX, uint128 _initialLP)
    {
        _owner = msg.sender;
        _rebateTX = _initialTX;
        _rebateLP = _initialLP;
    }

    function getRebate() 
    external
    view
    returns(uint128, uint128)
    {
        return (_rebateTX, _rebateLP);
    }

    /**  
     * @dev Set the internal gas rebate to a new value
     * @param _newTX storage slot to update 0 = rebateTX 1 = rebateLP
     * @param _newLP New rebate value
     */
    function setRebate(uint128 _newTX, uint128 _newLP) 
    external
    {
        require(_owner == msg.sender, "1");
        
        _rebateTX = _newTX;
        _rebateLP = _newLP;
        emit RebateUpdated(_rebateTX, _rebateLP);
    }

    /**
     * @dev Event Signal: SparkleSwap Gas Rebate for TXs has been updated
     */
    event RebateUpdated(uint128, uint128);
    
}