/**
 *Submitted for verification at Etherscan.io on 2021-12-15
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

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

contract SwapTokens {
    address public immutable srcToken;
    address public immutable dstToken;

    // eg. if swap rate 1:100 (src:dst), then numeratorOfRate=100, denominatorOfRate=1
    // eg. if swap rate 2:3 (src:dst), then numeratorOfRate=3, denominatorOfRate=2
    uint256 public immutable numeratorOfRate;
    uint256 public immutable denominatorOfRate;

    uint256 public latestWithdrawRequestTime;
    uint256 public latestWithdrawRequestAmount;
    uint256 public constant minWithdrawApprovalInterval = 200;

    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    event Swapped(address indexed sender, uint256 indexed srcAmount, uint256 indexed dstAmount);

    constructor(address _srcToken, address _dstToken, uint256 _numeratorOfRate, uint256 _denominatorOfRate) {
        srcToken = _srcToken;
        dstToken = _dstToken;
        numeratorOfRate = _numeratorOfRate;
        denominatorOfRate = _denominatorOfRate;
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "the new owner is the zero address");
        owner = newOwner;
    }

    /// @dev swap with `srcAmount` of `srcToken` to get `dstToken`.
    /// Returns swap result of `dstAmount` of `dstToken`.
    /// Requirements:
    ///   - `msg.sender` must have approved at least `srcAmount` `srcToken` to `address(this)`.
    ///   - `address(this)` must have at least `dstAmount` `dstToken`.
    function swap(uint256 srcAmount) external returns (uint256 dstAmount) {
        dstAmount = srcAmount * numeratorOfRate / denominatorOfRate;
        TransferHelper.safeTransferFrom(srcToken, msg.sender, address(this), srcAmount);
        TransferHelper.safeTransfer(dstToken, msg.sender, dstAmount);
        emit Swapped(msg.sender, srcAmount, dstAmount);
        return dstAmount;
    }

    function withdrawRequest(uint256 amount) external onlyOwner {
        if (amount > 0) {
            latestWithdrawRequestTime = block.timestamp;
            latestWithdrawRequestAmount = amount;
        } else {
            latestWithdrawRequestTime = 0;
            latestWithdrawRequestAmount = 0;
        }
    }

    function withdraw() external onlyOwner {
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
        TransferHelper.safeTransfer(dstToken, msg.sender, amount);
    }
}