// SPDX-License-Identifier: MIT

  /**
   * LYNC Network
   * https://lync.network
   *
   * Additional details for contract and wallet information:
   * https://lync.network/tracking/
   *
   * The cryptocurrency network designed for passive token rewards for its community.
   */

pragma solidity ^0.7.0;

import "./ERC1155.sol";

contract LYNCCrafter is ERC1155 {

    address public owner;
    address public rewardContract;
    uint256 public cardID = 1;
    uint256 public cardCountETH = 9950;
    uint256 public cardCountLYNC = 9975;

    //Card statistics
    struct CardStats {
        string collectionName;
        uint256 cardType;
        uint256 boostAmount;
        uint256 redeemInitial;
        uint256 redeemLeft;
        uint256 redeemInterval;
        uint256 useLastTimeStamp;
        uint256 tokenReward;
        uint256 percentageReward;
    }

    //Events
    event BulkCardCrafted(address indexed _to, uint256 cardID, uint256 _amountOfCards, uint256 _tokenReward, uint256 _percentageReward);
    event CollectionCardCrafted(address indexed _to, uint256 cardID, uint256 _redeemInitial, uint256 _redeemInterval, uint256 _tokenReward, uint256 _percentageReward);
    event BoosterCardCrafted(address indexed _to, uint256 cardID, uint256 _amountOfCards, uint256 _boostAmount);
    event BulkBoosterCardIncreased(address indexed _to, uint256 _amountOfCards, uint256 _cardID);
    event RewardCardCrafted(address indexed _to, uint256 _cardCounter);
    event CardStatsUpdated(uint256 _cardID);
    event BoosterCardApplied(uint256 _cardID, uint256 _newRedeemTotal);
    event CardBurned(uint256 _cardID, uint256 _amount);
    event CardBurnedByOwner(address indexed _cardholder, uint256 _cardID, uint256 _amount);
    event RewardContractAddressUpdated(address indexed _previousRewardAddress, address indexed _newRewardAddress);
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event OwnershipRenounced(address indexed _previousOwner, address indexed _newOwner);

    //Mappings
    mapping(uint256 => CardStats) public cards;
    mapping(string => mapping(uint256 => uint256)) public collections;

    //Constructor
    constructor(string memory _uri) ERC1155(_uri) {
        owner = msg.sender;
    }

    //Craft a destructable / bulk card
    function craftBulkCard(address _to, uint256 _amountOfCards, uint256 _tokenReward, uint256 _percentageReward) public onlyOwner {

        //Craft and add stats
        _mint(_to, cardID, _amountOfCards, "");
        cards[cardID].cardType = 1;
        cards[cardID].tokenReward = _tokenReward;
        cards[cardID].percentageReward = _percentageReward;
        emit BulkCardCrafted(_to, cardID,  _amountOfCards, _tokenReward, _percentageReward);

        //Update cardID
        cardID += 1;
    }

    //Craft a collection card
    function craftCollectionCard(address _to, string memory _collectionName, uint256 _amountOfCards, uint256 _redeemInitial, uint256 _redeemInterval, uint256 _tokenReward, uint256 _percentageReward) public onlyOwner {

        //Make sure collection name is unique
        require(collections[_collectionName][0] == 0, "This collection name aready exists!");

        //Record the size of the collection
        collections[_collectionName][0] = _amountOfCards;

        //Loop to create multiple cards
        for (uint256 i = 1; i <= _amountOfCards; i++) {

            //Add this card into the collection
            collections[_collectionName][i] = cardID;

            //Mint the card and add stats to card
            _mint(_to, cardID, 1, "");
            cards[cardID].collectionName = _collectionName;
            cards[cardID].cardType = 2;
            cards[cardID].redeemInitial = _redeemInitial;
            cards[cardID].redeemLeft = _redeemInitial;
            cards[cardID].redeemInterval = _redeemInterval;
            cards[cardID].tokenReward = _tokenReward;
            cards[cardID].percentageReward = _percentageReward;
            emit CollectionCardCrafted(_to, cardID, _redeemInitial, _redeemInterval, _tokenReward, _percentageReward);

            //Update the cardID
            cardID += 1;
        }
    }

    //Craft a booster card
    function craftBoosterCard(address _to, uint256 _amountOfCards, uint256 _boostAmount) public onlyOwner {
        _mint(_to, cardID, _amountOfCards, "");
        cards[cardID].cardType = 3;
        cards[cardID].boostAmount = _boostAmount;
        emit BoosterCardCrafted(_to, cardID, _amountOfCards, _boostAmount);

        //Update the cardID
        cardID += 1;
    }

    //Increase a destructable / booster card quantity
    function increaseBulkBoosterCard(address _to, uint256 _amountOfCards, uint256 _cardID) public onlyOwner {

        //Check card type and cardID count
        require(cards[_cardID].cardType != 2, "Cannot increase a collection / unique card");
        require(_cardID > 0 && _cardID < cardID, "Card ID has not been crafted yet");

        //Increase cards
        _mint(_to, _cardID, _amountOfCards, "");
        emit BulkBoosterCardIncreased(_to, _amountOfCards, _cardID);
    }

    //Craft a reward card
    function craftRewardCard(address _to, uint256 _cardID, string memory _collectionName) public onlyRewardContract {

        //Set counters
        uint256 _cardCounter;

        if(_cardID < 3) {
            _cardCounter = cardCountETH;
            cardCountETH += 1;
        } else {
            _cardCounter = cardCountLYNC;
            cardCountLYNC += 1;
        }

        //Increase the size of the collection
        collections[_collectionName][0] += 1;

        //Crafter the card and add stats
        _mint(_to, _cardCounter, 1, "");
        cards[_cardCounter].collectionName = _collectionName;
        cards[_cardCounter].cardType = 2;
        cards[_cardCounter].redeemInitial = 6;
        cards[_cardCounter].redeemLeft = 6;
        cards[_cardCounter].redeemInterval = 28;
        cards[_cardCounter].tokenReward = 400;
        cards[_cardCounter].percentageReward = 4;
        emit RewardCardCrafted(_to, _cardCounter);
    }

    //Update collection / unique card redeem count and timestamp
    function updateCardStats(uint256 _cardID) public onlyRewardContract {
        cards[_cardID].redeemLeft -= 1;
        cards[_cardID].useLastTimeStamp = block.timestamp;
        emit CardStatsUpdated(_cardID);
    }

    //Apply booster card to collection / unique card
    function applyCardBooster(uint256 _cardID, uint256 _newRedeemTotal) public onlyRewardContract {
        cards[_cardID].redeemLeft += _newRedeemTotal;
        emit BoosterCardApplied(_cardID, _newRedeemTotal);
    }

    //Burn card
    function burnCard(address _cardholder, uint256 _cardID, uint256 _amount) public onlyRewardContract {
        _burn(_cardholder, _cardID, _amount);
        emit CardBurned(_cardID, _amount);
    }

    //Owner burn card overide
    function ownerBurnCard(address _cardholder, uint256 _cardID, uint256 _amount) public onlyOwner {
        _burn(_cardholder, _cardID, _amount);
        emit CardBurnedByOwner(_cardholder, _cardID, _amount);
    }

    //Update the reward contract address
    function updateRewardContractAddress(address _newRewardContractAddress) public onlyOwner {
        require(_newRewardContractAddress != address(0), "New reward contract address cannot be a zero address");
        emit RewardContractAddressUpdated(rewardContract, _newRewardContractAddress);
        rewardContract = _newRewardContractAddress;
    }

    //Transfer ownership to new owner
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be a zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    //Remove owner from the contract
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner, address(0));
        owner = address(0);
    }

    //Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender, "Only the owner of the crafter contract can call this function");
        _;
    }

    modifier onlyRewardContract() {
        require(rewardContract == msg.sender, "Only the reward contract address can call this function");
        _;
    }
}