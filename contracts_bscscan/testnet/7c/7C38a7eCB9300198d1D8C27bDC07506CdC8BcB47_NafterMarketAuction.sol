// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC1155TokenCreator.sol";

/**
 * @title IERC1155CreatorRoyalty Token level royalty interface.
 */
interface IERC1155CreatorRoyalty is IERC1155TokenCreator {
    /**
     * @dev Get the royalty fee percentage for a specific ERC1155 contract.
     * @param _tokenId uint256 token ID.
     * @return uint8 wei royalty fee.
     */
    function getERC1155TokenRoyaltyPercentage(
        uint256 _tokenId
    ) external view returns (uint8);

    /**
     * @dev Utililty function to calculate the royalty fee for a token.
     * @param _tokenId uint256 token ID.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateRoyaltyFee(
        uint256 _tokenId,
        uint256 _amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @title IERC1155 Non-Fungible Token Creator basic interface
 */
interface IERC1155TokenCreator {
    /**
     * @dev Gets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function tokenCreator(uint256 _tokenId)
    external
    view
    returns (address payable);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @title IMarketplaceSettings Settings governing a marketplace.
 */
interface IMarketplaceSettings {
    /////////////////////////////////////////////////////////////////////////
    // Marketplace Min and Max Values
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the max value to be used with the marketplace.
     * @return uint256 wei value.
     */
    function getMarketplaceMaxValue() external view returns (uint256);

    /**
     * @dev Get the max value to be used with the marketplace.
     * @return uint256 wei value.
     */
    function getMarketplaceMinValue() external view returns (uint256);

    /////////////////////////////////////////////////////////////////////////
    // Marketplace Fee
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the marketplace fee percentage.
     * @return uint8 wei fee.
     */
    function getMarketplaceFeePercentage() external view returns (uint8);

    /**
     * @dev Utility function for calculating the marketplace fee for given amount of wei.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateMarketplaceFee(uint256 _amount)
    external
    view
    returns (uint256);

    /////////////////////////////////////////////////////////////////////////
    // Primary Sale Fee
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the primary sale fee percentage for a specific ERC1155 contract.
     * @return uint8 wei primary sale fee.
     */
    function getERC1155ContractPrimarySaleFeePercentage()
    external
    view
    returns (uint8);

    /**
     * @dev Utility function for calculating the primary sale fee for given amount of wei
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculatePrimarySaleFee(uint256 _amount)
    external
    view
    returns (uint256);

    /**
     * @dev Check whether the ERC1155 token has sold at least once.
     * @param _tokenId uint256 token ID.
     * @return bool of whether the token has sold.
     */
    function hasERC1155TokenSold(uint256 _tokenId)
    external
    view
    returns (bool);

    /**
     * @dev Mark a token as sold.

     * Requirements:
     *
     * - `_contractAddress` cannot be the zero address.

     * @param _tokenId uint256 token ID.
     * @param _hasSold bool of whether the token should be marked sold or not.
     */
    function markERC1155Token(
        uint256 _tokenId,
        bool _hasSold
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


/**
 * @dev Interface for interacting with the Nafter contract that holds Nafter beta tokens.
 */
interface INafter {

    /**
     * @dev Gets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function creatorOfToken(uint256 _tokenId)
    external
    view
    returns (address payable);

    /**
     * @dev Gets the Service Fee
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function getServiceFee(uint256 _tokenId)
    external
    view
    returns (uint8);

    /**
     * @dev Gets the price type
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     * @return get the price type
     */
    function getPriceType(uint256 _tokenId, address _owner)
    external
    view 
    returns (uint8);

    /**
     * @dev update price only from auction.
     * @param _price price of the token
     * @param _tokenId uint256 id of the token.
     * @param _owner address of the token owner
     */
    function setPrice(uint256 _price, uint256 _tokenId, address _owner) external;
    /**
     * @dev update bids only from auction.
     * @param _bid bid Amount
     * @param _bidder bidder address
     * @param _tokenId uint256 id of the token.
     * @param _owner address of the token owner
     */
    function setBid(uint256 _bid, address _bidder, uint256 _tokenId, address _owner) external;

    /**
     * @dev get tokenIds length
     */
    function getTokenIdsLength() external view returns (uint256);

    /**
     * @dev get token Id
     * @param _index uint256 index
     */
    function getTokenId(uint256 _index) external view returns(uint256);

    /**
     * @dev Gets the owners
     * @param _tokenId uint256 ID of the token
     */
    function getOwners(uint256 _tokenId)
    external
    view 
    returns (address[] memory owners);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface INafterMarketAuction {
    /**
     * @dev Set the token for sale. The owner of the token must be the sender and have the marketplace approved.
     * @param _tokenId uint256 ID of the token
     * @param _amount uint256 wei value that the item is for sale
     */
    function setSalePrice(
        uint256 _tokenId,
        uint256 _amount,
        address _owner
    ) external;    

    function setInitialBidPriceWithRange(
        uint256 _bidAmount, 
        uint256 _startTime, 
        uint256 _endTime,
        address _owner, 
        uint256 _tokenId
    ) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ISendValueProxy {
    function sendValue(address payable _to) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SendValueProxy.sol";

/**
 * @dev Contract with a ISendValueProxy that will catch reverts when attempting to transfer funds.
 */

contract MaybeSendValue {
    SendValueProxy proxy;

    constructor() internal {
        proxy = new SendValueProxy();
    }

    /**
     * @dev Maybe send some wei to the address via a proxy. Returns true on success and false if transfer fails.
     * @param _to address to send some value to.
     * @param _value uint256 amount to send.
     */
    function maybeSendValue(address payable _to, uint256 _value)
    internal
    returns (bool)
    {

        _to.transfer(_value);

        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./INafterMarketAuction.sol";
import "./IERC1155CreatorRoyalty.sol";
import "./IMarketplaceSettings.sol";
import "./Payments.sol";
import "./INafter.sol";

contract NafterMarketAuction is INafterMarketAuction, Ownable, Payments {
    using SafeMath for uint256;

    /////////////////////////////////////////////////////////////////////////
    // Structs
    /////////////////////////////////////////////////////////////////////////

    // The active bid for a given token, contains the bidder, the marketplace fee at the time of the bid, and the amount of wei placed on the token
    struct ActiveBid {
        address payable bidder;
        uint8 marketplaceFee;
        uint256 amount;
    }

    struct ActiveBidRange {
        uint256 startTime;
        uint256 endTime;
    }

    // The sale price for a given token containing the seller and the amount of wei to be sold for
    struct SalePrice {
        address payable seller;
        uint256 amount;
    }

    /////////////////////////////////////////////////////////////////////////
    // State Variables
    /////////////////////////////////////////////////////////////////////////

    // Marketplace Settings Interface
    IMarketplaceSettings public iMarketplaceSettings;

    // Creator Royalty Interface
    IERC1155CreatorRoyalty public iERC1155CreatorRoyalty;

    // Nafter contract
    INafter public nafter;
    //erc1155 contract
    IERC1155 public erc1155;

    // Mapping from ERC1155 contract to mapping of tokenId to sale price.
    mapping(uint256 => mapping(address => SalePrice)) private salePrice;
    // Mapping of ERC1155 contract to mapping of token ID to the current bid amount.
    mapping(uint256 => mapping(address =>ActiveBid)) private activeBid;
    mapping(uint256 => mapping(address =>ActiveBidRange)) private activeBidRange;

    // A minimum increase in bid amount when out bidding someone.
    uint8 public minimumBidIncreasePercentage; // 10 = 10%

    /////////////////////////////////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////////////////////////////////
    event Sold(
        address indexed _buyer,
        address indexed _seller,
        uint256 _amount,
        uint256 _tokenId
    );

    event SetSalePrice(
        uint256 _amount,
        uint256 _tokenId
    );

    event Bid(
        address indexed _bidder,
        uint256 _amount,
        uint256 _tokenId
    );

    event SetInitialBidPriceWithRange(
        uint256 _bidAmount, 
        uint256 _startTime, 
        uint256 _endTime, 
        address _owner, 
        uint256 _tokenId
    );
    event AcceptBid(
        address indexed _bidder,
        address indexed _seller,
        uint256 _amount,
        uint256 _tokenId
    );

    event CancelBid(
        address indexed _bidder,
        uint256 _amount,
        uint256 _tokenId
    );


    /////////////////////////////////////////////////////////////////////////
    // Constructor
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Initializes the contract setting the market settings and creator royalty interfaces.
     * @param _iMarketSettings address to set as iMarketplaceSettings.
     * @param _iERC1155CreatorRoyalty address to set as iERC1155CreatorRoyalty.
     * @param _nafter address of the nafter contract
     */
    constructor(address _iMarketSettings, address _iERC1155CreatorRoyalty, address _nafter)
    public
    {
        require(
            _iMarketSettings != address(0),
            "constructor::Cannot have null address for _iMarketSettings"
        );

        require(
            _iERC1155CreatorRoyalty != address(0),
            "constructor::Cannot have null address for _iERC1155CreatorRoyalty"
        );

        require(
            _nafter != address(0),
            "constructor::Cannot have null address for _nafter"
        );

        // Set iMarketSettings
        iMarketplaceSettings = IMarketplaceSettings(_iMarketSettings);

        // Set iERC1155CreatorRoyalty
        iERC1155CreatorRoyalty = IERC1155CreatorRoyalty(_iERC1155CreatorRoyalty);

        nafter = INafter(_nafter);
        erc1155 = IERC1155(_nafter);

        minimumBidIncreasePercentage = 10;
    }

    /////////////////////////////////////////////////////////////////////////
    // Get owner of the token
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev get owner of the token
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function isOwnerOfTheToken(uint256 _tokenId, address _owner) public view returns(bool) {
        uint256 balance = erc1155.balanceOf(_owner, _tokenId);
        return balance > 0;
    }

    /////////////////////////////////////////////////////////////////////////
    // Get token sale price against token id
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev get the token sale price against token id
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function getSalePrice(uint256 _tokenId, address _owner) external view returns(address payable, uint256){
        SalePrice memory sp = salePrice[_tokenId][_owner];
        return (sp.seller ,sp.amount);
    }

    /////////////////////////////////////////////////////////////////////////
    // get active big against tokenId
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev get active bid against token Id
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function getActiveBid(uint256 _tokenId, address _owner) external view returns(address payable, uint8, uint256){
        ActiveBid memory ab = activeBid[_tokenId][_owner];
        return (ab.bidder , ab.marketplaceFee, ab.amount);
    }

    /////////////////////////////////////////////////////////////////////////
    // get active bid range against token id
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev get active bid range against token id
     * @param _tokenId uint256 ID of the token
     */
    function getActiveBidRange(uint256 _tokenId, address _owner) external view returns(uint256, uint256){
        ActiveBidRange memory abr = activeBidRange[_tokenId][_owner];
        return (abr.startTime, abr.endTime);
    }

    /////////////////////////////////////////////////////////////////////////
    // setIMarketplaceSettings
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Admin function to set the marketplace settings.
     * Rules:
     * - only owner
     * - _address != address(0)
     * @param _address address of the IMarketplaceSettings.
     */
    function setMarketplaceSettings(address _address) public onlyOwner {
        require(
            _address != address(0),
            "setMarketplaceSettings::Cannot have null address for _iMarketSettings"
        );

        iMarketplaceSettings = IMarketplaceSettings(_address);
    }

     /////////////////////////////////////////////////////////////////////////
    // seNafter
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Admin function to set the marketplace settings.
     * Rules:
     * - only owner
     * - _address != address(0)
     * @param _address address of the IMarketplaceSettings.
     */
    function setNafter(address _address) public onlyOwner {
        require(
            _address != address(0),
            "setNafter::Cannot have null address for _INafter"
        );

        nafter = INafter(_address);
        erc1155 = IERC1155(_address);
    }

    /////////////////////////////////////////////////////////////////////////
    // setIERC1155CreatorRoyalty
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Admin function to set the IERC1155CreatorRoyalty.
     * Rules:
     * - only owner
     * - _address != address(0)
     * @param _address address of the IERC1155CreatorRoyalty.
     */
    function setIERC1155CreatorRoyalty(address _address) public onlyOwner {
        require(
            _address != address(0),
            "setIERC1155CreatorRoyalty::Cannot have null address for _iERC1155CreatorRoyalty"
        );

        iERC1155CreatorRoyalty = IERC1155CreatorRoyalty(_address);
    }

    /////////////////////////////////////////////////////////////////////////
    // setMinimumBidIncreasePercentage
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Admin function to set the minimum bid increase percentage.
     * Rules:
     * - only owner
     * @param _percentage uint8 to set as the new percentage.
     */
    function setMinimumBidIncreasePercentage(uint8 _percentage)
    public
    onlyOwner
    {
        minimumBidIncreasePercentage = _percentage;
    }

    /////////////////////////////////////////////////////////////////////////
    // Modifiers (as functions)
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Checks that the token owner is approved for the ERC1155Market
     * @param _owner address of the token owner
     */
    function ownerMustHaveMarketplaceApproved(
        address _owner
    ) internal view {
        require(
            erc1155.isApprovedForAll(_owner, address(this)),
            "owner must have approved contract"
        );
    }

    /**
     * @dev Checks that the token is owned by the sender
     * @param _tokenId uint256 ID of the token
     */
    function senderMustBeTokenOwner(uint256 _tokenId)
    internal
    view
    {
        bool isOwner = isOwnerOfTheToken(_tokenId, msg.sender);

        require(isOwner || msg.sender == address(nafter), 'sender must be the token owner');
    }

    /////////////////////////////////////////////////////////////////////////
    // setSalePrice
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Set the token for sale. The owner of the token must be the sender and have the marketplace approved.
     * @param _tokenId uint256 ID of the token
     * @param _amount uint256 wei value that the item is for sale
     * @param _owner address of the token owner
     */
    function setSalePrice(
        uint256 _tokenId,
        uint256 _amount,
        address _owner
    ) external override {
        // The owner of the token must have the marketplace approved
        ownerMustHaveMarketplaceApproved(_owner);

        // The sender must be the token owner
        senderMustBeTokenOwner(_tokenId);

        if (_amount == 0) {
            // Set not for sale and exit
            _resetTokenPrice(_tokenId, _owner);
            emit SetSalePrice(_amount, _tokenId);
            return;
        }

        salePrice[_tokenId][_owner] = SalePrice(payable(_owner), _amount);
        nafter.setPrice(_amount, _tokenId, _owner);
        emit SetSalePrice(_amount, _tokenId);
    }

    /**
     * @dev restore data from old contract, only call by owner
     * @param _oldAddress address of old contract.
     * @param _oldNafterAddress get the token ids from the old nafter contract.
     * @param _startIndex start index of array
     * @param _endIndex end index of array
     */
    function restore(address _oldAddress, address _oldNafterAddress, uint256 _startIndex, uint256 _endIndex) external onlyOwner {
        NafterMarketAuction oldContract = NafterMarketAuction(_oldAddress);
        INafter oldNafterContract = INafter(_oldNafterAddress);

        uint256 length = oldNafterContract.getTokenIdsLength();
        require(_startIndex < length, "wrong start index");
        require(_endIndex <= length, "wrong end index");

        for(uint i = _startIndex; i < _endIndex; i++){
            uint256 tokenId = oldNafterContract.getTokenId(i);
            
            address[] memory owners = oldNafterContract.getOwners(tokenId);
            for (uint j = 0; j < owners.length; j++){
                address owner = owners[j];
                (address payable sender, uint256 amount) = oldContract.getSalePrice(tokenId, owner);
                salePrice[tokenId][owner] = SalePrice(sender, amount);

                (address payable bidder, uint8 marketplaceFee, uint256 bidAmount) = oldContract.getActiveBid(tokenId, owner);
                activeBid[tokenId][owner] = ActiveBid(bidder, marketplaceFee, bidAmount);

                (uint256 startTime, uint256 endTime) = oldContract.getActiveBidRange(tokenId, owner);
                activeBidRange[tokenId][owner] = ActiveBidRange(startTime, endTime);
            }
        }
        setMinimumBidIncreasePercentage(oldContract.minimumBidIncreasePercentage());
    }
    /////////////////////////////////////////////////////////////////////////
    // safeBuy
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Purchase the token with the expected amount. The current token owner must have the marketplace approved.
     * @param _tokenId uint256 ID of the token
     * @param _amount uint256 wei amount expecting to purchase the token for.
     * @param _owner address of the token owner
     */
    function safeBuy(
        uint256 _tokenId,
        uint256 _amount,
        address _owner
    ) external payable {
        // Make sure the tokenPrice is the expected amount
        require(
            salePrice[_tokenId][_owner].amount == _amount,
            "safeBuy::Purchase amount must equal expected amount"
        );
        
    }

    /////////////////////////////////////////////////////////////////////////
    // buy
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Purchases the token if it is for sale.
     * @param _tokenId uint256 ID of the token.
     * @param _owner address of the token owner
     */
    function buy(uint256 _tokenId, address _owner) public payable {
        // The owner of the token must have the marketplace approved
        ownerMustHaveMarketplaceApproved(_owner);

        // Check that the person who set the price still owns the token.
        require(
            _priceSetterStillOwnsTheToken(_tokenId, _owner),
            "buy::Current token owner must be the person to have the latest price."
        ); 

        uint8 priceType = nafter.getPriceType(_tokenId, _owner);
        require(priceType == 0, "buy is only allowed for fixed sale");

        SalePrice memory sp = salePrice[_tokenId][_owner];

        // Check that token is for sale.
        require(sp.amount > 0, "buy::Tokens priced at 0 are not for sale.");

        // Check that enough ether was sent.
        require(
            tokenPriceFeeIncluded(_tokenId, _owner) == msg.value,
            "buy::Must purchase the token for the correct price"
        );

        // Wipe the token price.
        _resetTokenPrice(_tokenId, _owner);

        // Transfer token.
        erc1155.safeTransferFrom(_owner, msg.sender, _tokenId, 1, '');

        // if the buyer had an existing bid, return it
        if (_addressHasBidOnToken(msg.sender, _tokenId, _owner)) {
            _refundBid(_tokenId, _owner);
        }

        // Payout all parties.
        address payable owner = _makePayable(owner());
        Payments.payout(
            sp.amount,
            !iMarketplaceSettings.hasERC1155TokenSold(_tokenId),
            nafter.getServiceFee(_tokenId),
            iERC1155CreatorRoyalty.getERC1155TokenRoyaltyPercentage(
                _tokenId
            ),
            iMarketplaceSettings.getERC1155ContractPrimarySaleFeePercentage(),
            _makePayable(_owner),
            owner,
            iERC1155CreatorRoyalty.tokenCreator(_tokenId),
            owner
        );

        // Set token as sold
        iMarketplaceSettings.markERC1155Token(_tokenId, true);

        emit Sold(msg.sender, _owner, sp.amount, _tokenId);
    }

    /////////////////////////////////////////////////////////////////////////
    // tokenPrice
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Gets the sale price of the token
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     * @return uint256 sale price of the token
     */
    function tokenPrice(uint256 _tokenId, address _owner)
    external
    view
    returns (uint256)
    {
        // The owner of the token must have the marketplace approved
        ownerMustHaveMarketplaceApproved(_owner);
        // TODO: Make sure to write test to verify that this returns 0 when it fails

        if (_priceSetterStillOwnsTheToken(_tokenId, _owner)) {
            return salePrice[_tokenId][_owner].amount;
        }
        return 0;
    }

    /////////////////////////////////////////////////////////////////////////
    // tokenPriceFeeIncluded
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Gets the sale price of the token including the marketplace fee.
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     * @return uint256 sale price of the token including the fee.
     */
    function tokenPriceFeeIncluded(uint256 _tokenId, address _owner)
    public
    view
    returns (uint256)
    {
        // The owner of the token must have the marketplace approved
        ownerMustHaveMarketplaceApproved(_owner);
        // TODO: Make sure to write test to verify that this returns 0 when it fails

        if (_priceSetterStillOwnsTheToken(_tokenId, _owner)) {
            return
            salePrice[_tokenId][_owner].amount.add(
                salePrice[_tokenId][_owner].amount.mul(
                    nafter.getServiceFee(_tokenId)
                ).div(100)
            );
        }
        return 0;
    }

    /////////////////////////////////////////////////////////////////////////
    // setInitialBidPriceWithRange
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev set
     * @param _bidAmount uint256 value in wei to bid.
     * @param _startTime end time of bid
     * @param _endTime end time of bid
     * @param _owner address of the token owner
     * @param _tokenId uint256 ID of the token
     */
    function setInitialBidPriceWithRange(uint256 _bidAmount, uint256 _startTime, uint256 _endTime, address _owner, uint256 _tokenId) external override {
        require(_bidAmount > 0, "setInitialBidPriceWithRange::Cannot bid 0 Wei.");
        senderMustBeTokenOwner(_tokenId);
        _setBid(_bidAmount, payable(_owner), _tokenId, _owner);
        _setBidRange(_startTime,  _endTime, _tokenId, _owner);

        emit SetInitialBidPriceWithRange(_bidAmount, _startTime, _endTime, _owner, _tokenId);
    }

    /////////////////////////////////////////////////////////////////////////
    // bid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Bids on the token, replacing the bid if the bid is higher than the current bid. You cannot bid on a token you already own.
     * @param _newBidAmount uint256 value in wei to bid.
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function bid(
        uint256 _newBidAmount,
        uint256 _tokenId,
        address _owner
    ) external payable {
        // Check that bid is greater than 0.
        require(_newBidAmount > 0, "bid::Cannot bid 0 Wei.");

        // Check that bid is higher than previous bid
        uint256 currentBidAmount =
        activeBid[_tokenId][_owner].amount;
        require(
            _newBidAmount > currentBidAmount &&
            _newBidAmount >=
            currentBidAmount.add(
                currentBidAmount.mul(minimumBidIncreasePercentage).div(100)
            ),
            "bid::Must place higher bid than existing bid + minimum percentage."
        );

        // Check that enough ether was sent.
        uint256 requiredCost =
        _newBidAmount.add(
            _newBidAmount.mul(
                nafter.getServiceFee(_tokenId)
            ).div(100)
        );
        require(
            requiredCost <= msg.value,
            "bid::Must purchase the token for the correct price."
        );

        //Check bid range
        ActiveBidRange memory range = activeBidRange[_tokenId][_owner];
        uint8 priceType = nafter.getPriceType(_tokenId, _owner);
        
        require(priceType == 1 || priceType == 2, "bid is not valid for fixed sale");
        if(priceType == 1)
            require(range.startTime < block.timestamp && range.endTime > block.timestamp , "bid::can't place bid'");

        // Check that bidder is not owner.
        require(_owner != msg.sender, "bid::Bidder cannot be owner.");

        // Refund previous bidder.
        _refundBid(_tokenId, _owner);

        // Set the new bid.
        _setBid(_newBidAmount, msg.sender, _tokenId, _owner);
        nafter.setBid(_newBidAmount, msg.sender, _tokenId, _owner);
        emit Bid(msg.sender, _newBidAmount, _tokenId);
    }

    /////////////////////////////////////////////////////////////////////////
    // safeAcceptBid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Accept the bid on the token with the expected bid amount.
     * @param _tokenId uint256 ID of the token
     * @param _amount uint256 wei amount of the bid
     * @param _owner address of the token owner
     */
    function safeAcceptBid(
        uint256 _tokenId,
        uint256 _amount,
        address _owner
    ) external {
        // Make sure accepting bid is the expected amount
        require(
            activeBid[_tokenId][_owner].amount == _amount,
            "safeAcceptBid::Bid amount must equal expected amount"
        );
        acceptBid(_tokenId, _owner);
    }

    /////////////////////////////////////////////////////////////////////////
    // acceptBid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Accept the bid on the token.
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function acceptBid(uint256 _tokenId, address _owner) public {
        // The sender must be the token owner
        senderMustBeTokenOwner(_tokenId);

        // The owner of the token must have the marketplace approved
        ownerMustHaveMarketplaceApproved(_owner);


        // Check that a bid exists.
        require(
            _tokenHasBid(_tokenId, _owner),
            "acceptBid::Cannot accept a bid when there is none."
        );

        // Get current bid on token

        ActiveBid memory currentBid =
        activeBid[_tokenId][_owner];

        // Wipe the token price and bid.
        _resetTokenPrice(_tokenId, _owner);
        _resetBid(_tokenId, _owner);

        // Transfer token.
        erc1155.safeTransferFrom(msg.sender, currentBid.bidder, _tokenId, 1, '');

        // Payout all parties.
        address payable owner = _makePayable(owner());
        Payments.payout(
            currentBid.amount,
            !iMarketplaceSettings.hasERC1155TokenSold(_tokenId),
            nafter.getServiceFee(_tokenId),
            iERC1155CreatorRoyalty.getERC1155TokenRoyaltyPercentage(
                _tokenId
            ),
            iMarketplaceSettings.getERC1155ContractPrimarySaleFeePercentage(),
            msg.sender,
            owner,
            iERC1155CreatorRoyalty.tokenCreator(_tokenId),
            owner
        );

        iMarketplaceSettings.markERC1155Token(_tokenId, true);

        emit AcceptBid(
            currentBid.bidder,
            msg.sender,
            currentBid.amount,
            _tokenId
        );
    }

    /////////////////////////////////////////////////////////////////////////
    // cancelBid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Cancel the bid on the token.
     * @param _tokenId uint256 ID of the token.
     * @param _owner address of the token owner
     */
    function cancelBid(uint256 _tokenId, address _owner) external {
        // Check that sender has a current bid.
        require(
            _addressHasBidOnToken(msg.sender, _tokenId, _owner),
            "cancelBid::Cannot cancel a bid if sender hasn't made one."
        );

        // Refund the bidder.
        _refundBid(_tokenId, _owner);

        emit CancelBid(
            msg.sender,
            activeBid[_tokenId][_owner].amount,
            _tokenId
        );
    }

    /////////////////////////////////////////////////////////////////////////
    // currentBidDetailsOfToken
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Function to get current bid and bidder of a token.
     * @param _tokenId uin256 id of the token.
     * @param _owner address of the token owner
     */
    function currentBidDetailsOfToken( uint256 _tokenId, address _owner)
    public
    view
    returns (uint256, address)
    {
        return (
        activeBid[_tokenId][_owner].amount,
        activeBid[_tokenId][_owner].bidder
        );
    }

    /////////////////////////////////////////////////////////////////////////
    // _priceSetterStillOwnsTheToken
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Checks that the token is owned by the same person who set the sale price.
     * @param _tokenId uint256 id of the.
     * @param _owner address of the token owner
     */
    function _priceSetterStillOwnsTheToken(
        uint256 _tokenId, 
        address _owner
    ) internal view returns (bool) {
        
        return
        _owner ==
        salePrice[_tokenId][_owner].seller;
    }

    /////////////////////////////////////////////////////////////////////////
    // _resetTokenPrice
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to set token price to 0 for a given contract.
     * @param _tokenId uin256 id of the token.
     * @param _owner address of the token owner
     */
    function _resetTokenPrice(uint256 _tokenId, address _owner)
    internal
    {
        salePrice[_tokenId][_owner] = SalePrice(address(0), 0);
    }

    /////////////////////////////////////////////////////////////////////////
    // _addressHasBidOnToken
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function see if the given address has an existing bid on a token.
     * @param _bidder address that may have a current bid.
     * @param _tokenId uin256 id of the token.
     * @param _owner address of the token owner
     */
    function _addressHasBidOnToken(
        address _bidder,
        uint256 _tokenId, 
        address _owner)
    internal view returns (bool) {
        return activeBid[_tokenId][_owner].bidder == _bidder;
    }

    /////////////////////////////////////////////////////////////////////////
    // _tokenHasBid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function see if the token has an existing bid.
     * @param _tokenId uin256 id of the token.
     * @param _owner address of the token owner
     */
    function _tokenHasBid(
        uint256 _tokenId, 
        address _owner)
    internal
    view
    returns (bool)
    {
        return activeBid[_tokenId][_owner].bidder != address(0);
    }

    /////////////////////////////////////////////////////////////////////////
    // _refundBid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to return an existing bid on a token to the
     *      bidder and reset bid.
     * @param _tokenId uin256 id of the token.
     * @param _owner address of the token owner
     */
    function _refundBid(uint256 _tokenId, address _owner) internal {
        ActiveBid memory currentBid =
        activeBid[_tokenId][_owner];
        if (currentBid.bidder == address(0)) {
            return;
        }
        Payments.refund(
            currentBid.marketplaceFee,
            currentBid.bidder,
            currentBid.amount
        );
        _resetBid(_tokenId, _owner);
    }

    /////////////////////////////////////////////////////////////////////////
    // _resetBid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to reset bid by setting bidder and bid to 0.
     * @param _tokenId uin256 id of the token.
     * @param _owner address of the token owner
     */
    function _resetBid(uint256 _tokenId, address _owner) internal {
        activeBid[_tokenId][_owner] = ActiveBid(
            address(0),
            0,
            0
        );
    }

    /////////////////////////////////////////////////////////////////////////
    // _setBid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to set a bid.
     * @param _amount uint256 value in wei to bid. Does not include marketplace fee.
     * @param _bidder address of the bidder.
     * @param _tokenId uin256 id of the token.
     * @param _owner address of the token owner
     */
    function _setBid(
        uint256 _amount,
        address payable _bidder,
        uint256 _tokenId, 
        address _owner
    ) internal {
        // Check bidder not 0 address.
        require(_bidder != address(0), "Bidder cannot be 0 address.");

        // Set bid.
        activeBid[_tokenId][_owner] = ActiveBid(
            _bidder,
            nafter.getServiceFee(_tokenId),
            _amount
        );
    }

    /////////////////////////////////////////////////////////////////////////
    // _setBidRange
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to set a bid range.
     * @param _startTime start time UTC.
     * @param _endTime end Time range.
     * @param _tokenId uin256 id of the token.
     */
    function _setBidRange(
        uint256 _startTime,
        uint256 _endTime, 
        uint256 _tokenId,
        address _owner
    ) internal {
        activeBidRange[_tokenId][_owner] = ActiveBidRange(_startTime,  _endTime);
    }

    /////////////////////////////////////////////////////////////////////////
    // _makePayable
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to set a bid.
     * @param _address non-payable address
     * @return payable address
     */
    function _makePayable(address _address)
    internal
    pure
    returns (address payable)
    {
        return address(uint160(_address));
    }

    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SendValueOrEscrow.sol";

/**
 * @title Payments contract for Nafter Marketplaces.
 */
contract Payments is SendValueOrEscrow {
    using SafeMath for uint256;
    using SafeMath for uint8;

    /////////////////////////////////////////////////////////////////////////
    // refund
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to refund an address. Typically for canceled bids or offers.
     * Requirements:
     *
     *  - _payee cannot be the zero address
     *
     * @param _marketplacePercentage uint8 percentage of the fee for the marketplace.
     * @param _amount uint256 value to be split.
     * @param _payee address seller of the token.
     */
    function refund(
        uint8 _marketplacePercentage,
        address payable _payee,
        uint256 _amount
    ) internal {
        require(
            _payee != address(0),
            "refund::no payees can be the zero address"
        );

        if (_amount > 0) {
            SendValueOrEscrow.sendValueOrEscrow(
                _payee,
                _amount.add(
                    calcPercentagePayment(_amount, _marketplacePercentage)
                )
            );
        }
    }

    /////////////////////////////////////////////////////////////////////////
    // payout
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to pay the seller, creator, and maintainer.
     * Requirements:
     *
     *  - _marketplacePercentage + _royaltyPercentage + _primarySalePercentage <= 100
     *  - no payees can be the zero address
     *
     * @param _amount uint256 value to be split.
     * @param _isPrimarySale bool of whether this is a primary sale.
     * @param _marketplacePercentage uint8 percentage of the fee for the marketplace.
     * @param _royaltyPercentage uint8 percentage of the fee for the royalty.
     * @param _primarySalePercentage uint8 percentage primary sale fee for the marketplace.
     * @param _payee address seller of the token.
     * @param _marketplacePayee address seller of the token.
     * @param _royaltyPayee address seller of the token.
     * @param _primarySalePayee address seller of the token.
     */
    function payout(
        uint256 _amount,
        bool _isPrimarySale,
        uint8 _marketplacePercentage,
        uint8 _royaltyPercentage,
        uint8 _primarySalePercentage,
        address payable _payee,
        address payable _marketplacePayee,
        address payable _royaltyPayee,
        address payable _primarySalePayee
    ) internal {
        require(
            _marketplacePercentage <= 100,
            "payout::marketplace percentage cannot be above 100"
        );
        require(
            _royaltyPercentage.add(_primarySalePercentage) <= 100,
            "payout::percentages cannot go beyond 100"
        );
        require(
            _payee != address(0) &&
            _primarySalePayee != address(0) &&
            _marketplacePayee != address(0) &&
            _royaltyPayee != address(0),
            "payout::no payees can be the zero address"
        );

        // Note:: Solidity is kind of terrible in that there is a limit to local
        //        variables that can be put into the stack. The real pain is that
        //        one can put structs, arrays, or mappings into memory but not basic
        //        data types. Hence our payments array that stores these values.
        uint256[4] memory payments;

        // uint256 marketplacePayment
        payments[0] = calcPercentagePayment(_amount, _marketplacePercentage);

        // uint256 royaltyPayment
        payments[1] = calcRoyaltyPayment(
            _isPrimarySale,
            _amount,
            _royaltyPercentage
        );

        // uint256 primarySalePayment
        payments[2] = calcPrimarySalePayment(
            _isPrimarySale,
            _amount,
            _primarySalePercentage
        );

        // uint256 payeePayment
        payments[3] = _amount.sub(payments[1]).sub(payments[2]);

        // marketplacePayment
        if (payments[0] > 0) {
            SendValueOrEscrow.sendValueOrEscrow(_marketplacePayee, payments[0]);
        }

        // royaltyPayment
        if (payments[1] > 0) {
            SendValueOrEscrow.sendValueOrEscrow(_royaltyPayee, payments[1]);
        }
        // primarySalePayment
        if (payments[2] > 0) {
            SendValueOrEscrow.sendValueOrEscrow(_primarySalePayee, payments[2]);
        }
        // payeePayment
        if (payments[3] > 0) {
            SendValueOrEscrow.sendValueOrEscrow(_payee, payments[3]);
        }
    }

    /////////////////////////////////////////////////////////////////////////
    // calcRoyaltyPayment
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Private function to calculate Royalty amount.
     *      If primary sale: 0
     *      If no royalty percentage: 0
     *      otherwise: royalty in wei
     * @param _isPrimarySale bool of whether this is a primary sale
     * @param _amount uint256 value to be split
     * @param _percentage uint8 royalty percentage
     * @return uint256 wei value owed for royalty
     */
    function calcRoyaltyPayment(
        bool _isPrimarySale,
        uint256 _amount,
        uint8 _percentage
    ) private pure returns (uint256) {
        if (_isPrimarySale) {
            return 0;
        }
        return calcPercentagePayment(_amount, _percentage);
    }

    /////////////////////////////////////////////////////////////////////////
    // calcPrimarySalePayment
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Private function to calculate PrimarySale amount.
     *      If not primary sale: 0
     *      otherwise: primary sale in wei
     * @param _isPrimarySale bool of whether this is a primary sale
     * @param _amount uint256 value to be split
     * @param _percentage uint8 royalty percentage
     * @return uint256 wei value owed for primary sale
     */
    function calcPrimarySalePayment(
        bool _isPrimarySale,
        uint256 _amount,
        uint8 _percentage
    ) private pure returns (uint256) {
        if (_isPrimarySale) {
            return calcPercentagePayment(_amount, _percentage);
        }
        return 0;
    }

    /////////////////////////////////////////////////////////////////////////
    // calcPercentagePayment
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to calculate percentage value.
     * @param _amount uint256 wei value
     * @param _percentage uint8  percentage
     * @return uint256 wei value based on percentage.
     */
    function calcPercentagePayment(uint256 _amount, uint8 _percentage)
    internal
    pure
    returns (uint256)
    {
        return _amount.mul(_percentage).div(100);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/payment/PullPayment.sol";
import "./MaybeSendValue.sol";
/**
 * @dev Contract to make payments. If a direct transfer fails, it will store the payment in escrow until the address decides to pull the payment.
 */
contract SendValueOrEscrow is MaybeSendValue, PullPayment {
    /////////////////////////////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////////////////////////////
    event SendValue(address indexed _payee, uint256 amount);

    /////////////////////////////////////////////////////////////////////////
    // sendValueOrEscrow
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Send some value to an address.
     * @param _to address to send some value to.
     * @param _value uint256 amount to send.
     */
    function sendValueOrEscrow(address payable _to, uint256 _value) internal {
        // attempt to make the transfer
        bool successfulTransfer = MaybeSendValue.maybeSendValue(_to, _value);
        // if it fails, transfer it into escrow for them to redeem at their will.
        if (!successfulTransfer) {
            _asyncTransfer(_to, _value);
        }
        emit SendValue(_to, _value);
    }
}

// SPDX-License-Identifier: MI
pragma solidity 0.6.12;

import "./ISendValueProxy.sol";

/**
 * @dev Contract that attempts to send value to an address.
 */
contract SendValueProxy is ISendValueProxy {
    /**
     * @dev Send some wei to the address.
     * @param _to address to send some value to.
     */
    function sendValue(address payable _to) external payable override {
        // Note that `<address>.transfer` limits gas sent to receiver. It may
        // not support complex contract operations in the future.
        _to.transfer(msg.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private _escrow;

    constructor () internal {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{ value: amount }(dest);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../math/SafeMath.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

 /**
  * @title Escrow
  * @dev Base escrow contract, holds funds designated for a payee until they
  * withdraw them.
  *
  * Intended usage: This contract (and derived escrow contracts) should be a
  * standalone contract, that only interacts with the contract that instantiated
  * it. That way, it is guaranteed that all Ether will be handled according to
  * the `Escrow` rules, and there is no need to check for payable functions or
  * transfers in the inheritance tree. The contract that uses the escrow as its
  * payment method should be its owner, and provide public methods redirecting
  * to the escrow's deposit and withdraw.
  */
contract Escrow is Ownable {
    using SafeMath for uint256;
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] = _deposits[payee].add(amount);

        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}