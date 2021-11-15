// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.11;

contract SupportBridge {
    function generateMessage(address _account, uint256 _amount, uint256 _chainId, uint256 _nonce, bytes32 _txHash, address _contractAddress) public pure returns(bytes memory) {
        return abi.encodePacked(_account, _amount, _chainId, _nonce, _txHash, _contractAddress);
    }
}

