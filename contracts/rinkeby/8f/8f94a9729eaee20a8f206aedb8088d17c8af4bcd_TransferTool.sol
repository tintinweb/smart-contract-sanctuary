/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

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
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract TransferTool {
    using SafeMath for uint256;

    function transferEthsAvg(address[] memory _tos) payable public {
        require(_tos.length > 0);
        uint256 vv = address(this).balance / _tos.length;
        for (uint256 i = 0; i < _tos.length; i++) {
            TransferHelper.safeTransferETH(_tos[i], vv);
        }
    }

    function transferEths(address[] memory _tos, uint256[] memory values) payable public {
        require(_tos.length > 0 && _tos.length == values.length);
        for (uint256 i = 0; i < _tos.length; i++) {
            TransferHelper.safeTransferETH(_tos[i], values[i]);
        }
    }

    function transferEth(address _to) payable public {
        require(_to != address(0));
        TransferHelper.safeTransferETH(_to, msg.value);
    }

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function transferTokensAvg(address from, address tokenAddress, address[] memory _tos, uint256 v) public {
        require(_tos.length > 0);
        for (uint256 i = 0; i < _tos.length; i++) {
            TransferHelper.safeTransferFrom(tokenAddress, from, _tos[i], v);
        }
    }

    function transferTokens(address from, address tokenAddress, address[] memory _tos, uint256[] memory values) public {
        require(_tos.length > 0 && _tos.length == values.length);
        for (uint256 i = 0; i < _tos.length; i++) {
            TransferHelper.safeTransferFrom(tokenAddress, from, _tos[i], values[i]);
        }
    }
}