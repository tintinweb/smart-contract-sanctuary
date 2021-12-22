// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract GlobalValues {

    address public AAVE_LENDING_POOL;
    address public AAVE_STAKED_TOKEN;
    address public AAVE_DATA_PROVIDER;

    function ADMIN_ADDRESS() public view returns(address) {
        return address(this);
    }

}