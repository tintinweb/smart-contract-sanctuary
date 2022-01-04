/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*  NFT 的賣方部署此合約，為 NFT 設定起始價格。
    1. 拍賣持續7天。
    2. NFT 的價格會隨著時間的推移而下降。
    3. 參與者可以通過存入大於智能合約計算的當前價格的 ETH 來購買。
    4. 當有買家成功購買 NFT 時，拍賣結束。*/

// 使用ERC721做為標準
interface IERC721 { // 利用interface 讓我們不用寫ERC721的code
    function transferFrom(
        address _from,
        address _to,
        uint _nftId
    ) external; // 外部合約可以呼叫他做transfer
}

contract DutchAuction {
    event Buy(address winner, uint amount); // cheap storage

    IERC721 public immutable nft; // 不可變
    uint public immutable nftId; // 不可變

    address payable public seller; // 賣家
    uint public startingPrice; // 起始價格
    uint public startAt; // 開始拍賣時間
    uint public expiresAt; // 拍賣結束時間
    uint public priceDeductionRate; // 價個下降幅度
    address public winner; // 最後贏家

    constructor(
        uint _startingPrice,
        uint _priceDeductionRate,
        address _nft,
        uint _nftId
    ) {
        seller = payable(msg.sender); // 讓賣家可以接收以太幣
        startingPrice = _startingPrice;
        startAt = block.timestamp; // 開始時間為建立此合約的時間
        expiresAt = block.timestamp + 1 days; // ˙天後到期
        priceDeductionRate = _priceDeductionRate;

        nft = IERC721(_nft);
        nftId = _nftId;
    }

    // 購買function, 當我出的價格大於當前產品價格即成功
    function buy() external payable { 
        require(block.timestamp < expiresAt, "auction expired"); // 拍賣結束時間到期
        require(winner == address(0), "auction finished"); // 買家成功購買

        // 產品價格降幅 => 價格會等於起始價格 - 降幅
        uint timeElapsed = block.timestamp - startAt;
        uint deduction = priceDeductionRate * timeElapsed;
        uint price = startingPrice - deduction;

        require(msg.value >= price, "ETH < price");

        winner = msg.sender;
        nft.transferFrom(seller, msg.sender, nftId); // nft轉送給贏家
        seller.transfer(msg.value); // 賣家得到ETH

        emit Buy(msg.sender, msg.value); // 觸發 Buy 這個 event
    }

}