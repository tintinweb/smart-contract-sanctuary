/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

pragma solidity >=0.6.0 <0.8.0;

contract Create2Deployer {
    event Deployed(address addr, uint256 salt);

    function deploy(bytes memory code, uint256 salt) public returns (address addr) {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, salt);
    }
}