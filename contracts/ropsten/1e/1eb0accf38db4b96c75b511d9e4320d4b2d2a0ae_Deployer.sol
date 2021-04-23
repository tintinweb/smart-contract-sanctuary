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
    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x3D183034BD415c91998477696AD2125b815c7067);

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