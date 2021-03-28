/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity ^0.5.7;

contract test {

    address manager;

    constructor(address _manager) public {
        manager = _manager;
    }

    function dotest() public pure returns (uint dt) {
        return 20;
    }

}