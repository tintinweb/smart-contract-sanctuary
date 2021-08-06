/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

// SPDX-License-Identifier: GPL-2.0
pragma solidity =0.7.6;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

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

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


contract cneDistributor {
    address constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant cne  = 0x8E7f3d3C40fc9668fF40E2FC42a26F97CbF7af7b;
    address public collector  = 0x84c0a9B2E776974aF843e4698888539D1B250591;

    function getCNE (uint256 usdtAmount) public{
        TransferHelper.safeTransferFrom(usdt, msg.sender, address(this), usdtAmount);
        //no need to convet the decimals, as 6 for usdt and 8 for cne, 0.01 in nature
        TransferHelper.safeTransfer(cne, msg.sender, usdtAmount);
        TransferHelper.safeTransfer(usdt, collector, usdtAmount);
    }
}