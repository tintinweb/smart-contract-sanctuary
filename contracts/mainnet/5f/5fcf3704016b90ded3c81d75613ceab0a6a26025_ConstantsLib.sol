/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.4.25;



/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */



library ConstantsLib {
    // Get the fraction that represents the entirety, equivalent of 100%
    function PARTS_PER()
    public
    pure
    returns (int256)
    {
        return 1e18;
    }
}