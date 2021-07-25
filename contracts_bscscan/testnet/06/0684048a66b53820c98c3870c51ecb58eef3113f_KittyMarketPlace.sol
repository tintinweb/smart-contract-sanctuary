pragma solidity ^0.5.12;

import "./Ownable.sol";
import "./KittyFactory.sol";
import "./IKittyMarketplace.sol";

contract KittyMarketPlace is Ownable, IKittyMarketPlace {
    KittyFactory internal _kittyContract;

    struct Offer {
        address payable seller;
        uint256 price;
        uint256 index;
        uint256 tokenId;
        bool isSireOffer;
        bool active;
    }

    Offer[] offers;
    mapping(uint256 => Offer) tokenIdToOffer;

    constructor(address _kittyContractAddress) public {
        setKittyContract(_kittyContractAddress);
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(
            msg.sender == _kittyContract.ownerOf(_tokenId),
            "not token owner"
        );
        _;
    }

    modifier activeOffer(uint256 _tokenId) {
        require(hasActiveOffer(_tokenId), "offer not active");
        _;
    }

    modifier noActiveOffer(uint256 _tokenId) {
        require(!hasActiveOffer(_tokenId), "duplicate offer");
        _;
    }

    modifier marketApproved() {
        require(
            _kittyContract.isApprovedForAll(msg.sender, address(this)),
            "market must be approved operator"
        );
        _;
    }

    function hasActiveOffer(uint256 _tokenId) public view returns (bool) {
        return tokenIdToOffer[_tokenId].active;
    }

    /**
     * Set the current KittyContract address and initialize the instance of Kittycontract.
     * Requirement: Only the contract owner can call.
     */
    function setKittyContract(address _kittyContractAddress) public onlyOwner {
        _kittyContract = KittyFactory(_kittyContractAddress);
    }

    /**
     * Get the details about a offer for _tokenId. Throws an error if there is no active offer for _tokenId.
     */
    function getOffer(uint256 _tokenId)
        external
        view
        activeOffer(_tokenId)
        returns (
            address seller,
            uint256 price,
            uint256 index,
            uint256 tokenId,
            bool isSireOffer,
            bool active
        )
    {
        Offer storage offer = tokenIdToOffer[_tokenId];
        seller = offer.seller;
        price = offer.price;
        index = offer.index;
        tokenId = offer.tokenId;
        isSireOffer = offer.isSireOffer;
        active = offer.active;
    }

    /**
     * Get all tokenId's that are currently for sale. Returns an empty arror if none exist.
     */
    function getAllTokenOnSale()
        external
        view
        returns (uint256[] memory listOfOffers)
    {
        return _getActiveOffers(false);
    }

    function _getActiveOffers(bool isSireOffer)
        internal
        view
        returns (uint256[] memory listOfOffers)
    {
        if (offers.length == 0) {
            return new uint256[](0);
        }

        // count the number of active orders
        uint256 count = 0;
        for (uint256 i = 0; i < offers.length; i++) {
            Offer storage offer = offers[i];
            if (offer.active && offer.isSireOffer == isSireOffer) {
                count++;
            }
        }

        // create an array of active orders
        listOfOffers = new uint256[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < offers.length; i++) {
            Offer storage offer = offers[i];
            if (offer.active && offer.isSireOffer == isSireOffer) {
                listOfOffers[j] = offer.tokenId;
                j++;
            }
            if (j >= count) {
                return listOfOffers;
            }
        }

        return listOfOffers;
    }

    /**
     * Get all tokenId's with active sire offers.
     * Returns an empty array if none exist.
     */
    function getAllSireOffers()
        external
        view
        returns (uint256[] memory listOfOffers)
    {
        return _getActiveOffers(true);
    }

    /**
     * Creates a new offer for _tokenId for the price _price.
     * Emits the MarketTransaction event with txType "Create offer"
     * Requirement: Only the owner of _tokenId can create an offer.
     * Requirement: There can only be one active offer for a token at a time.
     * Requirement: Marketplace contract (this) needs to be an approved operator when the offer is created.
     */
    function setOffer(uint256 _price, uint256 _tokenId)
        external
        marketApproved
        onlyTokenOwner(_tokenId)
        noActiveOffer(_tokenId)
    {
        _setOffer(_price, _tokenId, "Create", false);
    }

    function _setOffer(
        uint256 _price,
        uint256 _tokenId,
        string memory _txType,
        bool isSireOffer
    ) internal {
        Offer memory newOffer = Offer(
            msg.sender,
            _price,
            offers.length,
            _tokenId,
            isSireOffer,
            true
        );

        offers.push(newOffer);
        tokenIdToOffer[_tokenId] = newOffer;

        emit MarketTransaction(_txType, msg.sender, _tokenId);
    }

    /**
     * Creates a new siring offer for @param _tokenId at @param _price
     * Emits the MarketTransaction event with txType "Sire Offer"
     * Requirement: The sire must be ready to breed
     * Requirement: Only the owner of _tokenId can create an offer.
     * Requirement: There can only be one active offer for a token at a time.
     * Requirement: Marketplace contract (this) needs to be an approved operator when the offer is created.
     */
    function setSireOffer(uint256 _price, uint256 _tokenId)
        external
        marketApproved
        onlyTokenOwner(_tokenId)
        noActiveOffer(_tokenId)
    {
        require(_kittyContract.readyToBreed(_tokenId), "on cooldown");

        _setOffer(_price, _tokenId, "Sire Offer", true);
    }

    /**
     * Removes an existing offer.
     * Emits the MarketTransaction event with txType "Remove offer"
     * Requirement: Only the seller of _tokenId can remove an offer.
     */
    function removeOffer(uint256 _tokenId)
        external
        onlyTokenOwner(_tokenId)
        activeOffer(_tokenId)
    {
        _setOfferInactive(_tokenId);

        emit MarketTransaction("Remove", msg.sender, _tokenId);
    }

    function _setOfferInactive(uint256 _tokenId) internal {
        offers[tokenIdToOffer[_tokenId].index].active = false;
        delete tokenIdToOffer[_tokenId];
    }

    /**
     * Executes the purchase of _tokenId.
     * Sends the funds to the seller and transfers the token using transferFrom in Kittycontract.
     * Emits the MarketTransaction event with txType "Buy".
     * Requirement: The msg.value needs to equal the price of _tokenId
     * Requirement: There must be an active offer for _tokenId
     */
    function buyKitty(uint256 _tokenId) external payable activeOffer(_tokenId) {
        Offer memory offer = tokenIdToOffer[_tokenId];
        require(msg.value == offer.price, "payment must be exact");

        _executeOffer(offer);

        // tranfer kitty ownership
        _kittyContract.transferFrom(offer.seller, msg.sender, _tokenId);

        // emit event
        emit MarketTransaction("Buy", msg.sender, _tokenId);
    }

    function _executeOffer(Offer memory offer) internal {
        // Important: remove offer BEFORE payment
        // to prevent re-entry attack
        _setOfferInactive(offer.tokenId);

        // tansfer funds from buyer to seller
        // TODO: make payment PULL istead of push
        if (offer.price > 0) {
            offer.seller.transfer(offer.price);
        }
    }

    /**
     * Purchase of siring rites
     * Sends funds to the seller and sets sire approval for the matron
     * Emits a MarketTransaction event with TxType "Sire Rites"
     * Requirement: The msg.value needs to equal the siring price of _tokenId
     * Requirement: msg.sender owns _matronTokenId
     * Requirement: _matronTokenId is ready to breed
     * Requirement: There must be an active sire offer for _sireTokenId
     */
    function buySireRites(uint256 _sireTokenId, uint256 _matronTokenId)
        external
        payable
        activeOffer(_sireTokenId)
    {
        Offer memory offer = tokenIdToOffer[_sireTokenId];
        require(msg.value == offer.price, "payment must be exact");
        require(
            _kittyContract.readyToBreed(_matronTokenId),
            "matron on cooldown"
        );

        _executeOffer(offer);

        // set sire rites
        _kittyContract.sireApprove(_sireTokenId, _matronTokenId, true);
        uint256 kittenId = _kittyContract.breed(_sireTokenId, _matronTokenId);
        _kittyContract.transferFrom(address(this), msg.sender, kittenId);

        emit MarketTransaction("Sire Rites", msg.sender, _sireTokenId);
    }
}