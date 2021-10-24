// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./IERC721.sol";
import "./IBOX.sol";
import "./IERC721Receiver.sol";

contract MarketPlace is IERC721Receiver, Ownable {
    using SafeMath for uint256;

    struct Order {
        uint256 tokenId;
        address owner;
        uint256 price;
    }

    // for query
    struct Item {
        uint256 tokenId;
        uint256 tokenType;
        uint256 tokenAttribute;
        address owner;
        uint256 price;
    }

    address public box;
    address public usdt;

    uint256 public feePercent = 5; // 5 => 5%

    address public fixedWallet;

    // orders
    uint256[] public orderIds;
    mapping(uint256 => uint256) public idToIndex;
    mapping(uint256 => Order) public orders;

    uint256 index = 1;

    uint256 public totalTradeVolume;

    constructor (address _box, address _usdt) {
        // USDT: 0x55d398326f99059fF775485246999027B3197955
        box = _box;
        usdt = _usdt;

        fixedWallet = _msgSender();

        orderIds.push(uint256(0));
    }

    function setBox(address _box) public onlyOwner {
        box = _box;
    }

    function setUSDT(address _usdt) public onlyOwner {
        usdt = _usdt;
    }

    function setFixedWallet(address account) public onlyOwner {
        fixedWallet = account;
    }

    function setFeePercent(uint256 value) public onlyOwner {
        feePercent = value;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override pure returns (bytes4) {
        bytes4 _ERC721_RECEIVED = 0x150b7a02;
        return _ERC721_RECEIVED;
    }

    // Move the last element to the deleted spot.
    // Remove the last element.
    function deleteOrder(uint256 tokenId) internal {
        uint256 idx = idToIndex[tokenId];
        require(idx > 0, "id2index error");
        require(idx < orderIds.length, "index out of range");

        uint256 lastId = orderIds[orderIds.length-1];
        orderIds[idx] = lastId;
        orderIds.pop();
        // delete an orderIds item, index - 1
        index--;

        idToIndex[lastId] = idx;

        delete idToIndex[tokenId];
        delete orders[tokenId];
    }

    function sell(uint256 tokenId, uint256 price) public {
        require(_msgSender() == IERC721(box).ownerOf(tokenId), "not token owner");

        // transfer nft
        IERC721(box).safeTransferFrom(_msgSender(), address(this), tokenId);

        // create order
        orders[tokenId] =
            Order({
                tokenId: tokenId,
                owner: _msgSender(),
                price: price
            });

        // add new orderIds item, index +1
        idToIndex[tokenId] = index++;
        orderIds.push(tokenId);
    }

    function cancel(uint256 tokenId) public {
        require(_msgSender() == orders[tokenId].owner, "not token owner");
        // delete order
        deleteOrder(tokenId);
        // transfer nft to sender
        IERC721(box).safeTransferFrom(address(this), _msgSender(), tokenId);
    }

    function buy(uint256 tokenId) public {
        Order storage ord = orders[tokenId];
        require(ord.tokenId > 0, "token not on sell");

        uint256 fee = feePercent.mul(ord.price).div(100);
        uint256 amount = ord.price.sub(fee);
        // transfer to seller
        TransferHelper.safeTransferFrom(usdt, _msgSender(), ord.owner, amount);
        // transfer fee to fixed wallet
        TransferHelper.safeTransferFrom(usdt, _msgSender(), fixedWallet, fee);

        // transfer nft to buyer
        IERC721(box).safeTransferFrom(address(this), _msgSender(), tokenId);

        // update total trade volume
        totalTradeVolume = totalTradeVolume.add(ord.price);

        // delete order, the last operation
        deleteOrder(tokenId);
    }

    function getAllOrders() public view returns (Item[] memory) {
        uint256 len = orderIds.length - 1;
        Item[] memory items = new Item[](len);
        for (uint256 i = 0; i < len; i++) {
            uint256 id = orderIds[i+1];
            Order memory ord = orders[id];
            items[i] = Item(ord.tokenId, IBOX(box).getType(id), IBOX(box).getAttribute(id), ord.owner, ord.price);
        }
        return items;
    }

    function withdrawUSDT(uint256 amount) public onlyOwner {
        TransferHelper.safeTransfer(usdt, owner(), amount);
    }

    function transferBox(address to, uint256 tokenId) public onlyOwner {
        IERC721(box).safeTransferFrom(address(this), to, tokenId);
    }
}