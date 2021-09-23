// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Game.sol";

contract Market {

    address public link;
    address public generatorAddress;
    Game[] public games;

    struct Bid{
        bool hasBid;
        uint cardNum;
        address bidder;
        uint value;
        uint startTime;
    }

    // struct Offer{
    //     bool isForSale;
    //     uint cardNum;
    //     address seller;
    //     uint minValue;          // in ether
    //     uint startTime;
    // }

    mapping (uint => Bid) public cardBids;
    // mapping (uint => Offer) public cardsOfferedForSale;


    event CardBidEntered(uint indexed cardNum, uint value, address indexed fromAddress);
    event CardBidWithdrawn(uint indexed cardNum, uint value, address indexed fromAddress);
    event CardTransferd(uint indexed cardNum, uint value, address indexed fromAddress, address indexed toAddress);
    // event CardOffered(uint indexed cardNum, uint minValue);
    // event CardNoLongerForSale(uint indexed cardNum);

    constructor(address generatorAddr) {
        link = address(this);
        generatorAddress = generatorAddr;
    }

    modifier onlyGenerator() {
        msg.sender == generatorAddress;
        _;
    }

    function newGame(address contractAddr) public onlyGenerator {
        games.push(Game(contractAddr));
    }

    function _checkGame(uint256 index) private view {
        require(index < 100, "there are only 100 games");
        require(games.length > index, "this game has not started yet");
        require(games[index].marketIsOpen(), "market of game is closed");
    }

    function enterBid(uint256 gameIndex, uint256 cardNum, uint256 value) public {
        _checkGame(gameIndex);
        Game game = games[gameIndex];
        require(game.ownerOf(cardNum) != msg.sender, "you already owned this token");
        require(value != 0, "zero bid value");
        require(value <= game.checkCredit(msg.sender), "not enough eth, please charge your credit.");

        Bid memory existing = cardBids[cardNum];
        require(value > existing.value);

        if (existing.value > 0) {
            // refund the failing bid
            game.increaseCredit(existing.bidder, existing.value);
        }
        
        game.decreaseCredit(msg.sender, value);
        cardBids[cardNum] = Bid(true, cardNum, msg.sender, value, block.timestamp);

        emit CardBidEntered(cardNum, value, msg.sender);
    }

    function withdrawBid(uint256 gameIndex, uint256 cardNum) public {
        _checkGame(gameIndex);
        Game game = games[gameIndex];
        Bid memory bid = cardBids[cardNum];
        require(bid.bidder == msg.sender, "you have not bid for this card");

        //period of time should be passed
        require(block.timestamp - bid.startTime >= 5 minutes, "you cannot withdraw your bid now");

        // credit[msg.sender] += bid.value;
        game.increaseCredit(msg.sender, bid.value);
        cardBids[cardNum] = Bid(false, cardNum, address(0), 0, 0);
        emit CardBidWithdrawn(cardNum, bid.value, msg.sender);
    }

    function acceptBid(uint256 gameIndex, uint256 cardNum, uint minPrice) public {
        _checkGame(gameIndex);
        Game game = games[gameIndex];
        require(game.ownerOf(cardNum) == msg.sender, "market: you are not owner of this card");
        Bid memory bid = cardBids[cardNum];
        require(bid.value != 0, "there is no bid for this token");

        //period of time should be passed
        require(block.timestamp - bid.startTime >= 10 minutes, "you cannot accept the bid now");

        require(bid.value >= minPrice, "the bid value is lesser than minPrice");
        address seller = msg.sender;

        //transfer card from seller to bidder
        game._getCard(bid.bidder, cardNum);

        // cardsOfferedForSale[cardNum] = Offer(false, cardNum, bid.bidder, 0, 0);
        cardBids[cardNum] = Bid(false, cardNum, address(0), 0, 0);

        game.increaseCredit(seller, bid.value);

        emit CardTransferd(cardNum, bid.value, seller, bid.bidder);
    }



    // function offerForSale(uint256 cardNum, uint256 minSalePriceInWei) public {
    //     require(game.ownerOf(cardNum) == msg.sender, "market: you are not owner of this card");
    //     cardsOfferedForSale[cardNum] = Offer(true, cardNum, msg.sender, minSalePriceInWei, block.timestamp);
    //     emit CardOffered(cardNum, minSalePriceInWei);

    // }

    // function noLongerForSale(uint256 cardNum) public {
    //     require(game.ownerOf(cardNum) == msg.sender, "market: you are not owner of this card");
    //     cardsOfferedForSale[cardNum] = Offer(false, cardNum, msg.sender, 0, 0);
    //     emit CardNoLongerForSale(cardNum);
    // }

    // function buyCard(uint cardNum) public {
    //     //period of time should be passed

    //     Offer memory offer = cardsOfferedForSale[cardNum];

    //     require(offer.isForSale, "card is not for sale");
    //     require(credit[msg.sender] >= offer.minValue, "not enough eth, please charge your credit.");
    //     require(offer.seller == game.ownerOf(cardNum), "seller no longer owner of card");

    //     address seller = offer.seller;
    // }

}