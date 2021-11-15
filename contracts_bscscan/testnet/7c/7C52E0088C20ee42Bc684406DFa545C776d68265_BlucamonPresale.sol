// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract BlucamonPresale {
    address blucamonOwnershipContract;

    constructor(address _address) {
        blucamonOwnershipContract = _address;
    }

    function isClaim() public returns (bool) {
        (bool result, ) = blucamonOwnershipContract.call(
            abi.encodeWithSignature("isClaimed()")
        );
        return result;
    }
}

