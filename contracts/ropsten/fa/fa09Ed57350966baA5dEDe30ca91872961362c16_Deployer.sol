/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-25
*/

pragma solidity ^0.5.0;


interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}


contract Deployer {
    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x2830d07b186cf1e1fB6B20D9e8CA78Cd59E19d8C);

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
    }

    function chiDeploy(bytes memory data) public discountCHI returns(address contractAddress) {
        assembly {
            contractAddress := create(0, add(data, 32), mload(data))
        }
    }


    function chiDeploy2(uint256 salt, bytes memory data) public discountCHI returns(address contractAddress) {
        assembly {
            contractAddress := create2(0, add(data, 32), mload(data), salt)
        }
    }
}