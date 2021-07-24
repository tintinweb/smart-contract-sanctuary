// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./EIP712MetaTransaction.sol";

struct Transformation {
    uint32 _uint32;
    bytes _bytes;
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract GasSwap is EIP712MetaTransaction("GasSwap", "1") {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    receive() external payable {}

    function withdrawToken(IERC20 token, uint256 amount)
        external
        onlyOwner
    {
        require(token.transfer(msg.sender, amount));
    }

    // Transfer ETH held by this contract to the sender/owner.
    function withdrawETH(uint256 amount)
        external
        onlyOwner
    {
        payable(msg.sender).transfer(amount);
    }

    // Swaps ERC20->MATIC tokens held by this contract using a 0x-API quote.
    function fillQuote(address spender, address swapTarget, bytes calldata swapCallData) payable external returns (uint256)
    {
        require(msgSender().balance <= 1000000000000000000, "SENDER_BALANCE_EXCEEDS_LIMIT");
        (address inputToken,address outputToken,uint256 inputAmount,uint256 minOutputAmount,) = abi.decode(swapCallData[4:], (address,address,uint256,uint256,Transformation[]));
        require(outputToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, "INVALID_OUTPUT_TOKEN");
        IERC20 sellToken = IERC20(inputToken);
        require(sellToken.transferFrom(msgSender(), address(this), inputAmount), "TRANSFER_FAILED");
        require(sellToken.approve(spender, uint256(0)), "APPROVAL_WIPE_FAILED");
        require(sellToken.approve(spender, inputAmount), "REAPPROVAL_FAILED");
        (bool success, bytes memory res) = swapTarget.call{value: msg.value}(swapCallData);
        uint256 outputTokenAmount = abi.decode(res, (uint256));
        require(success, string(concat(bytes("SWAP_FAILED: "),bytes(getRevertMsg(res)))));
        require(outputTokenAmount >= minOutputAmount, "SWAP_VALUE_MISMATCH");
        payable(msgSender()).transfer(outputTokenAmount);
        return outputTokenAmount;
    }

    function concat(bytes memory a, bytes memory b) internal pure returns (bytes memory) {
        return abi.encodePacked(a, b);
    }

    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length < 68)
            return 'Transaction reverted silently';

        assembly {
            _returnData := add(_returnData, 0x04)
        }

        return abi.decode(_returnData, (string));
    }
}