/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

pragma solidity ^0.8.7;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract FreeTransfer {

    function transfer(
        address[] memory addressList, 
        uint256[] memory tokenAmountList,
        address tokenAddress
    ) public payable {
        uint256 baseLength = addressList.length;
        require(baseLength == tokenAmountList.length, 'Different Length');
        if (tokenAddress == address(0x0)) {
            for (uint256 i = 0; i < baseLength; i++) {
                TransferHelper.safeTransferETH(addressList[i], tokenAmountList[i]);
            }
            uint256 nowBalance = payable(address(this)).balance;
            if (nowBalance > 0) {
                TransferHelper.safeTransferETH(msg.sender, nowBalance);
            }
        } else {
            require(msg.value == 0, 'NO ETH');
            for (uint256 i = 0; i < baseLength; i++) {
                TransferHelper.safeTransferFrom(tokenAddress, msg.sender, addressList[i], tokenAmountList[i]);
            }
        }
    }
}