/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens
library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
}

contract MultiDao {
    address public immutable token;

    uint256 public latestWithdrawRequestTime;
    uint256 public latestWithdrawRequestAmount;
    uint256 public constant minWithdrawApprovalInterval = 300;

    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    event WithdrawRequest(uint256 indexed amount, uint256 indexed timestamp);
    event Withdraw(address indexed to, uint256 indexed amount, uint256 indexed timestamp);

    constructor(address _token) {
        token = _token;
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "the new owner is the zero address");
        owner = newOwner;
    }

    function withdrawRequest(uint256 amount) external onlyOwner {
        if (amount > 0) {
            latestWithdrawRequestTime = block.timestamp;
            latestWithdrawRequestAmount = amount;
        } else {
            latestWithdrawRequestTime = 0;
            latestWithdrawRequestAmount = 0;
        }
        emit WithdrawRequest(amount, block.timestamp);
    }

    function withdraw(address to) external onlyOwner {
        require(
            latestWithdrawRequestTime > 0 && latestWithdrawRequestAmount > 0,
            "please do withdraw request firstly"
        );
        require(
            latestWithdrawRequestTime + minWithdrawApprovalInterval < block.timestamp,
            "the minimum withdraw approval interval is not satisfied"
        );
        uint256 amount = latestWithdrawRequestAmount;
        latestWithdrawRequestTime = 0;
        latestWithdrawRequestAmount = 0;
        TransferHelper.safeTransfer(token, to, amount);
        emit Withdraw(to, amount, block.timestamp);
    }
}