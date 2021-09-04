// SPDX-License-Identifier: SpaceSeven

pragma solidity >=0.7.0 <0.9.0;

import "./i_inventory721.sol";
import "./trader721_base.sol";
import "./i_trader721.sol";
import "./safe_math.sol";

contract Trader721Auction is Trader721Base, ITrader721 {
    using SafeMath for uint256;

    // New bet
    event Bet(uint256 indexed _tokenId, address indexed _buyer, uint256 _amount);

    // Percentage of profit
    uint256 private taxPercent;

    // tokenId => price
    mapping(uint256 => uint256) private lotInitialPrice;
    // tokenId => buyer
    mapping(uint256 => address) private lotBetting;
    // tokenId => amount
    mapping(uint256 => uint256) private lotBet;
    // tokenId => auction end time
    mapping(uint256 => uint256) private lotToTime;
    // tokenId => auction end time
    mapping(uint256 => uint256) private lotBidAdditionalTime;


    constructor(address _inventory, uint256 _taxPercent)
    Trader721Base(_inventory)
    {
        require(_taxPercent < 100, "The tax amount is very high");
        taxPercent = _taxPercent;
    }

    // Create new NFT
    function create__(uint256 _tokenId, uint256 _royaltyPercent) public {
        inventory.create__(_tokenId, _royaltyPercent, msg.sender);
    }

    // Create and sale new NFT
    function createAndSale__(uint256 _tokenId, uint256 _royaltyPercent, uint256 _price, uint256 _toTime, uint256 _bidAdditionalTime) external {
        create__(_tokenId, _royaltyPercent);
        sale__(_tokenId, _price, _toTime, _bidAdditionalTime);
    }

    // Start selling token
    function sale__(uint256 _tokenId, uint256 _price, uint256 _toTime, uint256 _bidAdditionalTime) public {
        require(_price > 0, "The price for the NFT must be greater than zero");
        // require(_toTime > 0, "Нельзя такой длинный аукцион");
        require(lotBetting[_tokenId] == address(0), "It is not possible to change the auction");
        if (lotInitialPrice[_tokenId] == 0) {
            inventory.sale__(_tokenId, msg.sender);
        }
        lotInitialPrice[_tokenId] = _price;
        lotToTime[_tokenId] = uint256(_toTime);
        lotBidAdditionalTime[_tokenId] = _bidAdditionalTime;
    }

    // Auction bid
    function buying__(uint256 _tokenId) external payable {
        require(block.timestamp < lotToTime[_tokenId], "The auction is no longer active");
        require(msg.value > lotBet[_tokenId] && msg.value > lotInitialPrice[_tokenId] && msg.value > 0, "Incorrect amount");

        address previousBuyer = lotBetting[_tokenId];
        if (previousBuyer != address(0)) {
            payable(previousBuyer).transfer(lotBet[_tokenId]);
        }
        lotBetting[_tokenId] = msg.sender;
        lotBet[_tokenId] = msg.value;
        lotToTime[_tokenId] = lotToTime[_tokenId].add(lotBidAdditionalTime[_tokenId]);
        emit Bet(_tokenId, msg.sender, msg.value);
    }

    // Finalizing the auction
    function finalization__(uint256 _tokenId) external payable {
        require(block.timestamp >= lotToTime[_tokenId], "The auction is already active");
        if (lotBetting[_tokenId] == address(0)) {
            pause__(_tokenId);
            return;
        }

        uint256 amount = lotBet[_tokenId];

        // Marketplace tax
        uint256 tradeTax = amount.div(100).mul(taxPercent);
        // Creator tax
        uint256 royaltyTax = amount.div(100).mul(inventory.getRoyaltyPercent__(_tokenId));
        // Amount for the last owner of the NFT
        uint256 ownerAmount = amount.sub(tradeTax).sub(royaltyTax);

        amountOfTax = amountOfTax.add(tradeTax);
        if (royaltyTax > 0) {
            payable(inventory.getCreator__(_tokenId)).transfer(royaltyTax);
        }
        payable(inventory.ownerOf(_tokenId)).transfer(ownerAmount);

        inventory.transfer__(_tokenId, lotBetting[_tokenId]);
        deleteLot__(_tokenId);
    }

    // Take it off the market
    function pause__(uint256 _tokenId) public payable {
        require(lotBetting[_tokenId] == address(0), "The auction is already active");
        inventory.pause__(_tokenId, msg.sender);
        deleteLot__(_tokenId);
    }

    // Close (delete) a token
    function close__(uint256 _tokenId) external payable {
        require(lotBetting[_tokenId] == address(0), "The auction is already active");
        inventory.close__(_tokenId, msg.sender);
        deleteLot__(_tokenId);
    }

    // Remove lot from trader (auction)
    function deleteLot__(uint256 _tokenId) internal {
        delete lotInitialPrice[_tokenId];
        delete lotBetting[_tokenId];
        delete lotBet[_tokenId];
        delete lotToTime[_tokenId];
        delete lotBidAdditionalTime[_tokenId];
    }

    function cleanUp__(uint256 _tokenId) override external
    onlyInventory
    {
        require(lotBetting[_tokenId] == address(0), "It is not possible to change the auction");
        deleteLot__(_tokenId);
    }
}