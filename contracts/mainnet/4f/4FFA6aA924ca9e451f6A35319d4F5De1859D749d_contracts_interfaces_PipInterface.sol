pragma solidity ^0.6.0;


abstract contract PipInterface {
    function read() public virtual returns (bytes32);
}
