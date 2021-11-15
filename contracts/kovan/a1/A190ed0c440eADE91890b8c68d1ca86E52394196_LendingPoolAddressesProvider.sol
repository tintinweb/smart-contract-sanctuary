//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

contract LendingPoolAddressesProvider{

    address lendingPool;

    constructor (address _lendingPool){
        lendingPool = _lendingPool;
    }

    function getLendingPool() public returns(address){
        return lendingPool;
    }

}

