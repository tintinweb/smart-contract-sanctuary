/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint _nftId
    ) external;
}

contract ezaarAuction {
    event Buy(address winner, uint amount);

    IERC721 public  nft;
    uint public  nftId;

    address payable public seller;
    uint public startingPrice;
    uint public startFrom;
    uint public expires;
    uint public priceDeductionRate;
    address public winner;



    function auc(
        uint _startingPrice,
        uint _priceDeductionRate,
        address _nft,
        uint _nftId,
        uint dayafter
    ) public{
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        startFrom = block.timestamp;
        expires = block.timestamp + dayafter *1 days;
        priceDeductionRate = _priceDeductionRate;

        nft = IERC721(_nft);
        nftId = _nftId;
    }

    function buy() external payable {
        require(block.timestamp < expires, "auction expired");
        require(winner == address(0), "auction finished");

        uint timeElapsed = block.timestamp - startFrom;
        uint deduction = priceDeductionRate * timeElapsed;
        uint price = startingPrice - deduction;

        require(msg.value >= price, "ETH < price");

        winner = msg.sender;
        nft.transferFrom(seller, msg.sender, nftId);
        seller.transfer(msg.value);

        emit Buy(msg.sender, msg.value);
    }
}