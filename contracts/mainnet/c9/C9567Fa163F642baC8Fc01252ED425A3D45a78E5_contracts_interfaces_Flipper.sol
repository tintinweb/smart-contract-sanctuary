pragma solidity ^0.6.0;

abstract contract Flipper {
    function bids(uint _bidId) public virtual returns (uint256, uint256, address, uint48, uint48, address, address, uint256);
    function tend(uint id, uint lot, uint bid) virtual external;
    function dent(uint id, uint lot, uint bid) virtual external;
    function deal(uint id) virtual external;
}
