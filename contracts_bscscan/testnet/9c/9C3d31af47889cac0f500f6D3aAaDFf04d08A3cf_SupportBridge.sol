// SPDX-License-Identifier: BSD-3-Clause
pragma solidity >=0.7.0 <0.9.0;

contract SupportBridge {
    function generateMessage(address _userWallet, uint256 _amount, address _withdraERC20, address _depositedERC20, uint256 _chainId, uint256 _nonce, bytes32 _txHash, address _contractAddress) public pure returns(bytes memory) {
        return abi.encodePacked(_userWallet, _amount, _withdraERC20, _depositedERC20, _chainId, _nonce, _txHash, _contractAddress);
    }
}