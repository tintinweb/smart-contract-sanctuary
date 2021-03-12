/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

pragma solidity ^0.5.0;

contract Deployer {
    event Deployed(address contractAddress);
    
    function deploy(uint256 salt, bytes memory data) public returns(address contractAddress) {
        assembly {
            contractAddress := create2(0, add(data, 32), mload(data), salt)
        }
        emit Deployed(contractAddress);
    }
}