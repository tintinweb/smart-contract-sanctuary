/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity ^0.5.0;


contract TokenRequest {

    event NEW(address target, uint256 ts);

    struct REQUEST {
        address target;
        uint256 ts;
    }
    REQUEST[] public _requests;

    constructor(
    )
    public
    {
    }

    function addNewRequest() external {
        REQUEST memory r;
        r.target = msg.sender;
        r.ts = now;
        _requests.push(r);
        emit NEW(r.target, r.ts);
    }
}