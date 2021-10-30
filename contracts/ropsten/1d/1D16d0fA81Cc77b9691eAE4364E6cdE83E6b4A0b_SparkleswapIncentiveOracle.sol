// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

contract SparkleswapIncentiveOracle {

    address private _o;
    bool private _p;
    uint128 private _rTx;
    uint128 private _rLp;
    

    constructor(uint128 _initialTX, uint128 _initialLP)
    {
        _o = msg.sender;
        _rTx = _initialTX;
        _rLp = _initialLP;
    }

    function P()
    external
    {
        require(_o == msg.sender, "1");

        _p = !_p;
    }

    function R() 
    external
    view
    returns(uint128, uint128)
    {
        if(_p) 
            return (0, 0);
        else
            return (_rTx, _rLp);
    }

    function RTX() 
    external
    view
    returns(uint256)
    {
        if(_p) 
            return uint256(0);
        else
            return uint256(_rTx);
    }

    function RLP() 
    external
    view
    returns(uint256)
    {
        if(_p) 
            return uint256(0);
        else
            return uint256(_rLp);
    }

    /**  
     * @dev Set the internal gas rebate to a new value
     * @param _newTX storage slot to update 0 = rebateTX 1 = rebateLP
     * @param _newLP New rebate value
     */
    function SR(uint128 _newTX, uint128 _newLP) 
    external
    {
        require(_o == msg.sender, "1");
        
        _rTx = _newTX;
        _rLp = _newLP;
        emit ERU(_rTx, _rLp);
    }

    /**
     * @dev Event Signal: SparkleSwap Gas Rebate for TXs has been updated
     */
    event ERU(uint128, uint128);
    
}