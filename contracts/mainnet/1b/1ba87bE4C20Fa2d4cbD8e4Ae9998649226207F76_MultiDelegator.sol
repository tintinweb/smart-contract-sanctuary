pragma solidity ^0.5.16;

pragma experimental ABIEncoderV2;

interface InvInterface {
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
}

interface XInvInterface {
    function syncDelegate(address user) external;
}

contract MultiDelegator {

    InvInterface public inv;
    XInvInterface xinv;

    constructor (InvInterface _inv, XInvInterface _xinv) public {
        inv = _inv;
        xinv = _xinv;
    }

    function delegateBySig(address delegatee, address[] memory delegator, uint[] memory nonce, uint[] memory expiry, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) public {
        for (uint256 i = 0; i < nonce.length; i++) {
            inv.delegateBySig(delegatee, nonce[i], expiry[i], v[i], r[i], s[i]);
            xinv.syncDelegate(delegator[i]);
        }
    }
}