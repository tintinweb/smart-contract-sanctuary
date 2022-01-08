// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title SoladayRegistry
 * @dev 
 * @author kethcode (https://github.com/kethcode)
 */
contract SoladaySimpleProxyRemote {

    /*********
    * Events *
    **********/
    event gm_fren();
    
    /************
    * Variables *
    *************/

    /*******************
    * Public Functions *
    ********************/

    function gm() public {
        emit gm_fren();
    }

}