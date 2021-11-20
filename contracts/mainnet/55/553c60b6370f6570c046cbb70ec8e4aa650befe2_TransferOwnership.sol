/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity ^0.6.7;

abstract contract CurvePoolLike {
    function commit_transfer_ownership(address future_owner) external virtual;
}

contract TransferOwnership {
    function commit_transfer_ownership(address pool, address future_owner) public {
        CurvePoolLike(pool).commit_transfer_ownership(future_owner);
    }
}