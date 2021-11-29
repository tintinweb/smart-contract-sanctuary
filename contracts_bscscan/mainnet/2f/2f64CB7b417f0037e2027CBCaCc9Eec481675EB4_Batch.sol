/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ITransferEnable {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

contract Batch {
    function TransferERC20(address _address, address[] memory _toAddresses, uint256 _amount) external {
        for (uint256 i; i < _toAddresses.length; i++) {
            ITransferEnable(_address).transferFrom(msg.sender, _toAddresses[i], _amount);
        }
    }
    function TransferETH(address[] memory _toAddresses, uint256 _amount) external payable {
        require(_toAddresses.length*_amount == msg.value, "invalid value");
        for (uint256 i; i < _toAddresses.length; i++) {
            payable(_toAddresses[i]).transfer(_amount);
        }
    }
}