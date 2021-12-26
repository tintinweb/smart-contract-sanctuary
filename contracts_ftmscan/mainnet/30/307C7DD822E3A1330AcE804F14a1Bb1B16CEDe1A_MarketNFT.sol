// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

contract MarketNFT is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;

    /* ******************* 写死配置 ****************** */
    
    ERC721 public erc721;
    ERC20 public erc20;


    
    /* ******************* 可改配置 ****************** */

    // 手续费率 * 100
    uint private fee;
    // 最低价格
    uint private minPrice;



    /* ******************* 业务数据 ****************** */

    // index => tokenId
    uint[] public tokenIds;
    // tokenId ==> Item
    mapping(uint => Goods) private listings;



    /* ********************* 定义 ******************** */

    // 商品
    struct Goods {
        uint index;
        uint tokenId;
        address owner;  // 拥有者
        uint price;     // 价格
        uint payout;    // 支出 = 价格 - 手续费
    }

    // 事件
    event Bought(uint listId);               // 购买
    event Listed(uint listId);               // 上架
    event Unlisted(uint listId);             // 下架
    event FeeChanged(uint fee);              // 修改手续费率
    event MinPriceChanged(uint minPrice);    // 修改最低价格



    /* ********************* 写函数 ******************** */

    // 构造
    constructor(ERC721 erc721_, ERC20 erc20_, uint8 fee_, uint minPrice_) {
        erc721 = erc721_;
        erc20 = erc20_;
        fee = fee_;
        minPrice = minPrice_;
    }

    // 挂卖
    function list(uint tokenId, uint price) external nonReentrant {
        require(erc721.ownerOf(tokenId) == msg.sender, "Token is not yours");
        uint payout = price - ((price * fee) / 100);
        require(price >= minPrice, "Price too low");

        // 保存商品信息
        listings[tokenId] = Goods({
            index: tokenIds.length,
            tokenId: tokenId,
            owner: msg.sender,
            price: price,
            payout: payout
        });
        tokenIds.push(tokenId);

        // 转账
        erc721.transferFrom(msg.sender, address(this), tokenId);
        emit Listed(tokenId);
    }

    // 买
    function buy(uint tokenId) external nonReentrant {
        Goods memory goods = listings[tokenId];
        require(goods.owner != address(0), "token not listed");
        erc721.transferFrom(address(this), msg.sender, goods.tokenId);
        erc20.safeTransferFrom(msg.sender, address(this), goods.price);
        erc20.transfer(goods.owner, goods.payout);
        remove(tokenId);
        emit Bought(tokenId);
    }

    // 下架
    function unlist(uint tokenId) external nonReentrant {
        Goods memory goods = listings[tokenId];
        require(goods.owner == msg.sender, "not owner");
        erc721.transferFrom(address(this), goods.owner, goods.tokenId);
        remove(tokenId);
        emit Unlisted(tokenId);
    }



    /* ********************** 读函数 ********************* */

    // 获取卖单(范围)
    function getGoodsRange(uint startIdx, uint endIdx) public view returns (Goods[] memory result) {
        result = new Goods[](endIdx - startIdx);
        for (uint i = startIdx; i < endIdx; i++) {
            result[i - startIdx] = listings[tokenIds[i]];
        }
    }

    // 获取卖单(所有)
    function getGoodsAll() public view returns (Goods[] memory) {
        return getGoodsRange(0, tokenIds.length);
    }

    // 获取卖单(分页)
    function getGoodsPage(uint pageIdx, uint pageSize) public view returns (Goods[] memory) {
        uint startIdx = pageIdx * pageSize;
        require(startIdx <= tokenIds.length, "Page number too high");
        uint pageEnd = startIdx + pageSize;
        uint endIdx = pageEnd <= tokenIds.length ? pageEnd : tokenIds.length;
        return getGoodsRange(startIdx, endIdx);
    }

    // 获取卖单数量(根据地址)
    function getGoodsSizeByOwner(address owner) public view returns (uint) {
        uint size = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (listings[tokenIds[i]].owner == owner) {
                size++;
            }
        }
        return size;
    }

    // 获取卖单(根据地址)
    function getGoodsByOwner(address owner) public view returns (Goods[] memory result) {
        result = new Goods[](getGoodsSizeByOwner(owner));
        uint index = 0;
        Goods memory goods;
        for (uint i = 0; i < tokenIds.length; i++) {
            goods = listings[tokenIds[i]];
            if (goods.owner == owner) {
                result[index] = goods;
                index++;
            }
        }
    }

    // 公共数据查询
    function query_summary() public view returns (uint, uint, uint) {
        return (fee, minPrice, tokenIds.length);
    }



    /* ******************* 写函数-owner ****************** */

    // 归集收益
    function collectFees() external onlyOwner {
        erc20.transfer(owner, erc20.balanceOf(address(this)));
    }

    // 设置手续费率 * 100
    function setFee(uint fee_) external onlyOwner {
        require(fee <= 20, "don't be greater than 20%!");
        fee = fee_;
        emit FeeChanged(fee);
    }

    // 设置最低价格
    function setMinPrice(uint minPrice_) external onlyOwner {
        minPrice = minPrice_;
        emit MinPriceChanged(minPrice);
    }



    /* ******************* 私有 ****************** */

    // 移除商品
    function remove(uint tokenId) private {
        uint256 tokenIndex = listings[tokenId].index;
        uint256 lastTokenId = tokenIds[tokenIds.length - 1];    // 最后一个上架NFT
        tokenIds[tokenIndex] = lastTokenId;                     // 最后一个上架NFT在tokenIds位置前移
        listings[lastTokenId].index = tokenIndex;               // 当前一个上架NFT在listings位置后移
        delete listings[tokenId];                               // listings中删除
        tokenIds.pop();                                         // tokenIds中删除
    }

}