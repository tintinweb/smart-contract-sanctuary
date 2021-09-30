/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

pragma solidity "0.8.7";


contract B {
    event Mint();
    constructor() {
        address(0x1e2A051c1Eb41420C977e83fE506D32EfE0f9f75).call(
                abi.encodeWithSignature("mint()")
            );
    }
}