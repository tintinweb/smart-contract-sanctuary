//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract Mystery{
    event Transfer(bool success, bytes data);
    function transferItem(address _contract, address from, uint256 id) public payable returns (bool) {
        require(msg.value > 0, "Transfer failed.");
        (bool success, ) = from.call{value:msg.value}("");
        require(success, "Transfer failed.");
        IERC1155(_contract).safeTransferFrom(from, msg.sender, id, 1, "");
        emit Transfer(true, "");
        return true;
    }
}