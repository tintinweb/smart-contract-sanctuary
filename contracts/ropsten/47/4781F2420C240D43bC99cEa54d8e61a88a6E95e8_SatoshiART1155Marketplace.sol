/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
    using SafeMath for uint256;

    struct Listing {
        bytes1 status; // 0x00 onHold 0x01 onSale 0x02 isDropOfTheDay 0x03 isAuction
        uint256 price;
        uint256 amount;
    }

    mapping (uint256 => mapping(address => Listing)) private _listings;
    ISatoshiART1155 public satoshiART1155;

    constructor (address satoshiART1155Address) {
        satoshiART1155 = ISatoshiART1155(satoshiART1155Address);
    }

    function putToSale(
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external {
        require(
            satoshiART1155.balanceOf(msg.sender, tokenId) >= amount,
            "You are trying to sell more than you have"
        );

        _listings[tokenId][msg.sender] = Listing({
            status: 0x01,
            price: price,
            amount: amount
        });
    }

    function listingOf(
        address account, uint256 id
    ) external view returns (bytes1, uint256, uint256) {
        require(account != address(0), "ERC1155: listing query for the zero address");
        return (
            _listings[id][account].status,
            _listings[id][account].price,
            _listings[id][account].amount
        );
    }

    function buy(
        uint256 tokenId,
        uint256 amount,
        address itemOwner
    ) external payable returns (bool) {
        require(_listings[tokenId][itemOwner].status == 0x01, "buy: trying to buy not listed item");
        require(_listings[tokenId][itemOwner].amount >= amount, "buy: trying to buy more than listed");
        require(satoshiART1155.balanceOf(itemOwner, tokenId) >= amount, "buy: trying to buy more than owned");
        require(msg.value >= _listings[tokenId][itemOwner].price.mul(amount), "buy: not enough fund");

        _listings[tokenId][itemOwner].amount = _listings[tokenId][itemOwner].amount.sub(amount);
        satoshiART1155.safeTransferFrom(itemOwner, msg.sender, tokenId, amount, "");

        return true;
    }
}