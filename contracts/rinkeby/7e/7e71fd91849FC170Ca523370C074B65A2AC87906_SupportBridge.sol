// SPDX-License-Identifier: BSD-3-Clause
pragma solidity >=0.7.0 <0.9.0;

contract SupportBridge {
    function generateMessage(string memory _account, uint256 _amount, uint256 _chainId, uint256 _nonce, string memory _txHash, string memory _contractAddress) public pure returns(bytes memory) {
        return abi.encodePacked(_account, _amount, _chainId, _nonce, _txHash, _contractAddress);
    }
}

