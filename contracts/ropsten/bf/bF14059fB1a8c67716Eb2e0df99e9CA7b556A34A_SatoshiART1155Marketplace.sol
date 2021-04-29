/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface ISatoshiART1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

contract SatoshiART1155Marketplace {
    struct Listing {
        bytes1 status; // 0x00 onHold 0x01 onSale 0x02 isDropOfTheDay 0x03 isAuction
        uint256 price;
        uint256 amount;
    }

    mapping (uint256 => mapping(address => Listing)) private _listings;
    ISatoshiART1155 public _satoshiART1155;

    constructor (address satoshiART1155Address) {
        _satoshiART1155 = ISatoshiART1155(satoshiART1155Address);
    }

    function putToSale(
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external {
        require(
            _satoshiART1155.balanceOf(msg.sender, tokenId) >= amount,
            "You are trying to sell more than you have"
        );

        _satoshiART1155.setApprovalForAll(address(this), true);

        _listings[tokenId][msg.sender] = Listing({
            status: 0x01,
            price: price,
            amount: amount
        });
    }

    function listingOf(
        address account, uint256 id
    ) public view returns (bytes1, uint256, uint256) {
        require(account != address(0), "ERC1155: listing query for the zero address");
        return (
            _listings[id][account].status,
            _listings[id][account].price,
            _listings[id][account].amount
        );
    }
}