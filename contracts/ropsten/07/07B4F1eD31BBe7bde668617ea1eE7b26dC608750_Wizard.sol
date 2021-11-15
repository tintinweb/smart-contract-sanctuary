// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.1;

pragma experimental ABIEncoderV2;

interface IUniswapV2Router02{
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
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
}

contract Wizard {
    mapping(address => mapping(address => address)) public allRecipients;
    uint256 deadline = 1645388420; // 20.02.2022 20:20:20

    function spreadEther(address[] memory recipients, uint256[] memory values) public payable {
        for (uint256 i = 0; i < recipients.length; i++)
            payable(recipients[i]).transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0)
            msg.sender.transfer(balance);
    }

    function spreadToken(address token, address[] memory recipients, uint256[] memory values) public {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), total);
        for (uint256 i = 0; i < recipients.length; i++)
            TransferHelper.safeTransfer(token, recipients[i], values[i]);
    }
    
    function setRecipient(address token, address recipient) public {
        allRecipients[token][msg.sender] = recipient;
    }

    function sweepToken(address token, address[] memory senders, address[] memory recipients, uint256[] memory values) public {
        for (uint256 i = 0; i < senders.length; i++) {
            require(allRecipients[token][senders[i]] == recipients[i], "This recipient do not have permission");
            TransferHelper.safeTransferFrom(token, senders[i], address(this), values[i]);
            TransferHelper.safeTransfer(token, recipients[i], values[i]);
        }
    }
    
    function sweepTokenToSender(address token, address[] memory senders, uint256[] memory values) public {
        uint256 total = 0;
        for (uint256 i = 0; i < senders.length; i++) {
            require(allRecipients[token][senders[i]] == msg.sender, "This recipient do not have permission");
            TransferHelper.safeTransferFrom(token, senders[i], address(this), values[i]);
            total += values[i];
        }
        TransferHelper.safeTransfer(token, msg.sender, total);
    }
    
    function sweepAllTokenToSender(address token, address[] memory senders) public {
        uint256 total = 0;
        uint256 value = 0;
        for (uint256 i = 0; i < senders.length; i++) {
            require(allRecipients[token][senders[i]] == msg.sender, "This recipient do not have permission");
            value = IERC20(token).balanceOf(senders[i]);
            TransferHelper.safeTransferFrom(token, senders[i], address(this), value);
            total += value;
        }
        TransferHelper.safeTransfer(token, msg.sender, total);
    }
    
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        uint256 amount;
        uint256 minReturnAmount;
    }
    
    function swap(
        address exchange,
        SwapDescription calldata desc
    )
        public
        returns (uint256 returnAmount)
    {
        address[] memory path = new address[](2);
        path[0] = address(desc.srcToken);
        path[1] = address(desc.dstToken);
        uint[] memory amounts = IUniswapV2Router02(exchange).swapExactTokensForETH(desc.amount, desc.minReturnAmount, path, msg.sender, deadline);
        returnAmount = amounts[1];
    }
    
    function sweepAllTokenToSenderAndSwap(address token, address[] memory senders, address exchange, SwapDescription calldata desc) external {
        sweepAllTokenToSender(token, senders);
        swap(exchange, desc);
    }

}

