pragma solidity ^0.7.3;

contract Factory {
    event Deployed(address addr, uint256 salt);

    function deploy(bytes memory code, uint256 salt) public {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
        }

        emit Deployed(addr, salt);
    }
}

