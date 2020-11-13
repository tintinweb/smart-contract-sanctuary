/**
 * Copyright 2017-2020, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;


interface TheProtocol{
    function getLoanPoolsList(
        uint256 start,
        uint256 count)
        external
        view
        returns (address[] memory loanPoolsList);

    function loanPoolToUnderlying(address _loanPool)
        external
        view
        returns(address);
}

contract TokenRegistry {

    address public bZxContract;

    struct TokenMetadata {
        address token; // iToken
        address asset; // underlying asset
    }

    constructor(
        address _bZxContract)
        public
    {
        bZxContract = _bZxContract;
    }

    function getTokens(
        uint256 _start,
        uint256 _count)
        external
        view
        returns (TokenMetadata[] memory metadata)
    {
        address[] memory loanPool;
        TheProtocol theProtocol = TheProtocol(bZxContract);
        loanPool = theProtocol.getLoanPoolsList(_start, _count);

        metadata = new TokenMetadata[](loanPool.length);
        for(uint256 i = 0; i < loanPool.length; i++){
            metadata[i].token = loanPool[i];
            metadata[i].asset = theProtocol.loanPoolToUnderlying(loanPool[i]);
        }
    }
}