pragma solidity ^0.6.0;

abstract contract IAToken {
    function redeem(uint256 _amount) external virtual;
}
