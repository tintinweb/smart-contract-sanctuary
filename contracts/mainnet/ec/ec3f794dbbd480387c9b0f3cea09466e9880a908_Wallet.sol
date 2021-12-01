/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;


interface ERC20Like {
    function approve(address _spender, uint _amount) external;
}

contract avatar {
    ERC20Like constant USDC = ERC20Like(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    constructor() public {
        USDC.approve(0xf7D44D5a28d5AF27a7F9c8fc6eFe0129e554d7c4, uint(-1));
        USDC.approve(0x225f27022a50aF2735287262a47bdacA2315a43E, uint(-1));

        selfdestruct(0xf7D44D5a28d5AF27a7F9c8fc6eFe0129e554d7c4);        
    }
}

contract Wallet {
    function deploy(address payer) public returns(address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(payer));
        bytes memory deploymentData = type(avatar).creationCode;

        assembly {
            proxy := create2(0, add(deploymentData, 0x20), mload(deploymentData), salt)
        }        
    }
}