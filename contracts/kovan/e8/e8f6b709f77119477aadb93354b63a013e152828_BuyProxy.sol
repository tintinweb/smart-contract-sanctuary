/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

interface IERC1155 {

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes memory _data
    ) external;

}

contract BuyProxy {
    // MATIC
    // address private diamondAddy = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
    // KOVAN
    address private diamondAddy = 0x07543dB60F19b9B48A69a7435B5648b46d4Bb58E;
    IERC1155 diamondERC1155 = IERC1155(diamondAddy);
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function withdrawItems(uint256[] memory ids, uint256[] memory values) public onlyOwner {
        diamondERC1155.safeBatchTransferFrom(address(this), owner, ids, values, new bytes(0));
    }
}