pragma solidity ^0.4.19;


contract Dappster {

    /// Lease record, store card tenants details
    /// and lease details
    struct LeaseCard {
        uint id;
        address tenant;
        uint price;
        uint untilBlock;
        string title;
        string url;
        string image;
    }

    /// Record card details
    struct CardDetails {
        uint8 id;
        uint price;
        uint priceLease; // price per block
        uint leaseDuration; // in block
        bool availableBuy;
        bool availableLease;
        uint[] leaseList;
        mapping(uint => LeaseCard) leaseCardStructs;
    }

    /// Record card
    struct Card {
        uint8 id;
        address owner;
        string title;
        string url;
        string image;
        bool nsfw;
    }

    /// Users pending withdrawals
    mapping(address => uint) public pendingWithdrawals;

    mapping(uint8 => Card) public cardStructs; // random access by card key
    uint8[] public cardList; // list of announce keys so we can enumerate them

    mapping(uint8 => CardDetails) public cardDetailsStructs; // random access by card details key
    uint8[] public cardDetailsList; // list of cards details keys so we can enumerate them

    /// Initial card price
    uint public initialCardPrice = 0.1 ether;

    /// Owner cut (1%) . This cut only apply on a user-to-user card transaction
    uint public ownerBuyCut = 100;
    /// fluffyCat cut (10%)
    uint public fluffyCatCut = 1000;

    /// contractOwner can withdraw the funds
    address public contractOwner;
    /// fluffyCat address
    address public fluffyCatAddress = 0x2c00A5013aA2E600663f7b197C98db73bA847e6d;

    /// Contract constructor
    function Dappster() public {
        contractOwner = msg.sender;
    }

    modifier onlyContractOwner() {
        // Throws if called by any account other than the contract owner
        require(msg.sender == contractOwner);
        _;
    }

    modifier onlyCardOwner(uint8 cardId) {
        // Throws if called by any account other than the card owner
        require(msg.sender == cardStructs[cardId].owner);
        _;
    }

    modifier onlyValidCard(uint8 cardId) {
        // Throws if card is not valid
        require(cardId >= 1 && cardId <= 100);
        _;
    }

    /// Return cardList array
    function getCards() public view returns(uint8[]) {
        uint8[] memory result = new uint8[](cardList.length);
        uint8 counter = 0;
        for (uint8 i = 0; i < cardList.length; i++) {
            result[counter] = i;
            counter++;
        }
        return result;
    }

    /// Return cardDetailsList array
    function getCardsDetails() public view returns(uint8[]) {
        uint8[] memory result = new uint8[](cardDetailsList.length);
        uint8 counter = 0;
        for (uint8 i = 0; i < cardDetailsList.length; i++) {
            result[counter] = i;
            counter++;
        }
        return result;
    }

    /// Return card details by id
    function getCardDetails(uint8 cardId) public view onlyValidCard(cardId)
        returns (uint8 id, uint price, uint priceLease, uint leaseDuration, bool availableBuy, bool availableLease) {
            bool _buyAvailability;
            if (cardDetailsStructs[cardId].id == 0 || cardDetailsStructs[cardId].availableBuy) {
                _buyAvailability = true;
            }

            CardDetails storage detail = cardDetailsStructs[cardId];
            return (
                detail.id,
                detail.price,
                detail.priceLease,
                detail.leaseDuration,
                _buyAvailability,
                detail.availableLease
                );
        }

    /// Return card by id
    function getCard(uint8 cardId) public view onlyValidCard(cardId)
        returns (uint8 id, address owner, string title, string url, string image, bool nsfw) {
            Card storage card = cardStructs[cardId];
            id = card.id;
            owner = card.owner;
            title = card.title;
            url = card.url;
            image = card.image;
            nsfw = card.nsfw;
        }

    /// This is called on the initial buy card, user to user buy is at buyCard()
    /// Amount is sent to contractOwner balance and fluffycat get 10% of this amount
    function initialBuyCard(uint8 cardId, string title, string url, string image) public
        onlyValidCard(cardId)
        payable
        returns (bool success)
    {
        // Check sent amount
        uint price = computeInitialPrice(cardId);
        require(msg.value >= price);
        // If owner is 0x0, then we are sure that
        // this is the initial buy
        require(cardStructs[cardId].owner == address(0));

        // Fill card
        _fillCardStruct(cardId, msg.sender, title, url, image);
        // Set nsfw flag to false
        cardStructs[cardId].nsfw = false;
        // Contract credit 10% of price to FluffyCat
        _applyShare(contractOwner, fluffyCatAddress, fluffyCatCut);
        // Initialize card details
        _initCardDetails(cardId, price);
        // Add the card to cardList
        cardList.push(cardId);
        return true;
    }

    /// Perform a user to user buy transaction
    /// Contract owner takes 1% cut on each of this transaction
    function buyCard(uint8 cardId, string title, string url, string image) public
        onlyValidCard(cardId)
        payable
        returns (bool success)
    {
        // Check that this is not an initial buy, i.e. that the
        // card belongs to someone
        require(cardStructs[cardId].owner != address(0));
        // Check if card is on sale
        require(cardDetailsStructs[cardId].availableBuy);
        // Check sent amount
        uint price = cardDetailsStructs[cardId].price;
        require(msg.value >= price);

        address previousOwner = cardStructs[cardId].owner;
        // Take 1% cut on buy
        _applyShare(previousOwner, contractOwner, ownerBuyCut);
        // Fill card
        _fillCardStruct(cardId, msg.sender, title, url, image);
        // Set nsfw flag to false
        cardStructs[cardId].nsfw = false;
        // Disable sell status
        cardDetailsStructs[cardId].availableBuy = false;
        return true;
    }

    /// Allow card owner to edit his card informations
    function editCard(uint8 cardId, string title, string url, string image) public
        onlyValidCard(cardId)
        onlyCardOwner(cardId)
        returns (bool success)
    {
        // Fill card
        _fillCardStruct(cardId, msg.sender, title, url, image);
        // Disable sell status
        return true;
    }

    /// Allow card owner to set his card on sale at specific price
    function sellCard(uint8 cardId, uint price) public
        onlyValidCard(cardId)
        onlyCardOwner(cardId)
        returns (bool success)
    {
        cardDetailsStructs[cardId].price = price;
        cardDetailsStructs[cardId].availableBuy = true;
        return true;
    }

    /// Allow card owner to cancel sell offer
    function cancelSellCard(uint8 cardId) public
        onlyValidCard(cardId)
        onlyCardOwner(cardId)
        returns (bool success)
    {
        cardDetailsStructs[cardId].availableBuy = false;
        return true;
    }

    /// Allow card owner to set his card on lease at fixed price per block and duration
    function setLeaseCard(uint8 cardId, uint priceLease, uint leaseDuration) public
        onlyValidCard(cardId)
        onlyCardOwner(cardId)
        returns (bool success)
    {
        // Card cannot be on sale when setting lease
        // cancelSellCard() first
        require(!cardDetailsStructs[cardId].availableBuy);
        // Card cannot be set on lease while currently leasing
        uint _lastLeaseId = getCardLeaseLength(cardId);
        uint _until = cardDetailsStructs[cardId].leaseCardStructs[_lastLeaseId].untilBlock;
        require(_until < block.number);

        cardDetailsStructs[cardId].priceLease = priceLease;
        cardDetailsStructs[cardId].availableLease = true;
        cardDetailsStructs[cardId].leaseDuration = leaseDuration;
        return true;
    }

    /// Allow card owner to cancel lease offer
    /// Note that this do not interrupt current lease if any
    function cancelLeaseOffer(uint8 cardId) public
        onlyValidCard(cardId)
        onlyCardOwner(cardId)
        returns (bool success)
    {
        cardDetailsStructs[cardId].availableLease = false;
        return true;
    }

    /// Allow future tenant to lease a card
    function leaseCard(uint8 cardId, string title, string url, string image) public
        onlyValidCard(cardId)
        payable
        returns (bool success)
    {
        CardDetails storage details = cardDetailsStructs[cardId];
        // Check that card is avaible to lease
        require(details.availableLease);
        // Get price (per block) and leaseDuration (block)
        uint price = details.priceLease;
        uint leaseDuration = details.leaseDuration;
        uint totalAmount = price * leaseDuration;
        // Check that amount sent is sufficient
        require(msg.value >= totalAmount);
        // Get new lease id
        uint leaseId = getCardLeaseLength(cardId) + 1;
        // Get the block number of lease end
        uint untilBlock = block.number + leaseDuration;
        // Take 1% cut on lease
        Card storage card = cardStructs[cardId];
        address _cardOwner = card.owner;
        _applyShare(_cardOwner, contractOwner, ownerBuyCut);
        // Fill leaseCardStructs
        details.leaseCardStructs[leaseId].id = leaseId;
        details.leaseCardStructs[leaseId].tenant = msg.sender;
        details.leaseCardStructs[leaseId].price = totalAmount;
        details.leaseCardStructs[leaseId].untilBlock = untilBlock;
        details.leaseCardStructs[leaseId].title = title;
        details.leaseCardStructs[leaseId].url = url;
        details.leaseCardStructs[leaseId].image = image;
        // Leases are now unavailable for this card
        details.availableLease = false;
        // Add lease to leases list of correspondant cardDetails
        details.leaseList.push(leaseId);
        return true;
    }

    /// Get last lease from a card
    function getLastLease(uint8 cardId) public view
        returns(uint leaseIndex, address tenant, uint untilBlock, string title, string url, string image)
    {
        uint _leaseIndex = getCardLeaseLength(cardId);
        return getLease(cardId, _leaseIndex);
    }

    /// Get lease from card
    function getLease(uint8 cardId, uint leaseId) public view
        returns(uint leaseIndex, address tenant, uint untilBlock, string title, string url, string image)
    {
        return(
            cardDetailsStructs[cardId].leaseCardStructs[leaseId].id,
            cardDetailsStructs[cardId].leaseCardStructs[leaseId].tenant,
            cardDetailsStructs[cardId].leaseCardStructs[leaseId].untilBlock,
            cardDetailsStructs[cardId].leaseCardStructs[leaseId].title,
            cardDetailsStructs[cardId].leaseCardStructs[leaseId].url,
            cardDetailsStructs[cardId].leaseCardStructs[leaseId].image
        );
    }

    /// Get lease list from a card
    function getCardLeaseLength(uint8 cardId) public view
        returns(uint cardLeasesCount)
    {
        return(cardDetailsStructs[cardId].leaseList.length);
    }

    /// Transfer the ownership of a card
    function transferCardOwnership(address to, uint8 cardId)
        public
        onlyCardOwner(cardId)
        returns (bool success)
    {
        // Transfer card ownership
        cardStructs[cardId].owner = to;
        return true;
    }

    /// Return balance from sender
    function getBalance()
        public
        view
        returns (uint amount)
    {
        return pendingWithdrawals[msg.sender];
    }

    /// Allow address to withdraw their balance
    function withdraw()
        public
        returns (bool)
    {
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
        return true;
    }

    /// Compute initial card price (in wei)
    function computeInitialPrice(uint8 cardId) public view
        onlyValidCard(cardId)
        returns (uint price)
    {
        // 0.1 ether - 0.001 ether * (cardId - 1)
        return initialCardPrice - ((initialCardPrice / 100) * (uint256(cardId) - 1));
    }

    /// Allow contract owner to set NSFW flag on a card
    function setNSFW(uint8 cardId, bool flag) public
        onlyValidCard(cardId)
        onlyContractOwner()
        returns (bool success)
    {
        cardStructs[cardId].nsfw = flag;
        return true;
    }

    /// Fill Card struct
    function _fillCardStruct(uint8 _cardId, address _owner, string _title, string _url, string _image) internal
        returns (bool success)
    {
        cardStructs[_cardId].owner = _owner;
        cardStructs[_cardId].title = _title;
        cardStructs[_cardId].url = _url;
        cardStructs[_cardId].image = _image;
        return true;
    }

    /// Initialize sell card for future
    function _initCardDetails(uint8 cardId, uint price) internal
        returns (bool success)
    {
        // priceLease, leaseDuration set to default value(= 0)
        cardDetailsStructs[cardId].id = cardId;
        cardDetailsStructs[cardId].price = price;
        cardDetailsStructs[cardId].availableBuy = false;
        cardDetailsStructs[cardId].availableLease = false;
        cardDetailsList.push(cardId);
        return true;
    }

    /// Send split amounts to respective balances
    function _applyShare(address _seller, address _auctioneer, uint _cut) internal
        returns (bool success)
    {
        // Compute share
        uint256 auctioneerCut = _computeCut(msg.value, _cut);
        uint256 sellerProceeds = msg.value - auctioneerCut;
        // Credit seller balance
        pendingWithdrawals[_seller] += sellerProceeds;
        // Credit auctionner balance
        pendingWithdrawals[_auctioneer] += auctioneerCut;
        return true;
    }

    /// Compute _cut from a _price
    function _computeCut(uint256 _price, uint256 _cut) internal pure
        returns (uint256)
    {
        return _price * _cut / 10000;
    }
}