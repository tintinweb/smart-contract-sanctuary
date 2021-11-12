/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

pragma solidity =0.5.16;

contract TestCreate2{
    function testCreate2(address token0,address token1)  external returns (address pair) {
        bytes memory bytecode = type(TestPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
    }
}

pragma solidity =0.5.16;

contract TestPair{
    address public token0;
    address public token1;
}