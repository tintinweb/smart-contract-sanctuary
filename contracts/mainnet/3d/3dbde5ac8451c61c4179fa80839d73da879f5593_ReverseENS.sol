/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

pragma solidity ^0.8.0;

interface IReverseRegistrar {
    function setName(string memory name) external returns (bytes32);
}

contract ReverseENS {

    IReverseRegistrar public constant REVERSE_REGISTRAR = IReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);

    function setReverse(string calldata name) external {
        REVERSE_REGISTRAR.setName(name);
    }
}