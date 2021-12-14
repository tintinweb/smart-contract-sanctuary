/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint value) external;
}


contract Wallet {
    address payable _hotWallet = payable(0x94dD9013DDC1DF3194882eb594F2B443640f9576);
    
    constructor() {
        if (payable(this).balance > 0) {
            _hotWallet.transfer(payable(this).balance);
        }
    }

    function withdraw(IERC20 token) external {
        token.transfer(_hotWallet, token.balanceOf(address(this)));
    }

    receive() external payable {
        _hotWallet.transfer(msg.value);
    }
}


contract WalletsFactory {
    function getBytecode() public pure returns (bytes memory) {
        return type(Wallet).creationCode;
    }

    function computeAddress(bytes32 salt, bytes memory bytecode) external view returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );
        return address(uint160(uint256(_data)));
    }

    function createWallet(bytes32 salt, bytes memory bytecode) external returns (address addr) {
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
    }

    function withdraw(IERC20 token, Wallet wallet) public {
        wallet.withdraw(token);
    }
}