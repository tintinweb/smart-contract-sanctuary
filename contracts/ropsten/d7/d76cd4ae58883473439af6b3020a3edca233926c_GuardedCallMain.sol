/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract GuardedCall {
    mapping(bytes => uint256) authorizations;
    uint public count;
    
    constructor() {
        count = 1;
    }
    
    function authorize(bytes memory claim) public returns (bool hadEffect) {
        if (authorizations[claim] != 0) return false;
        authorizations[claim] = uint256(uint160(msg.sender));
        return true;
    }
    
    function discardAuthorization(bytes memory claim) public returns (bool hadEffect) {
        if (authorizations[claim] != uint256(uint160(msg.sender))) return false;
        authorizations[claim] = 0;
        return true;
    }
    
    function process(bytes memory claim) public {
        require(authorizations[claim] != 0, "GuardedCall: unauthorized");
        count += 1;
    }
}

contract GuardedCallMain {
    function seq2(GuardedCall gc, bytes memory claim) public {
        gc.authorize(claim);
        gc.process(claim);
    }
    function seq3(GuardedCall gc, bytes memory claim) public {
        gc.authorize(claim);
        gc.process(claim);
        gc.discardAuthorization(claim);
    }
}