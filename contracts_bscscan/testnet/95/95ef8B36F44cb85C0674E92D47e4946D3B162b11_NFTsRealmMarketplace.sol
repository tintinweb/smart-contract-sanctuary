// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./MarketplaceStorage.sol";
import "../interfaces/IWFTM.sol";
import "../interfaces/INFTsRealm.sol";

contract NFTsRealmMarketplace is MarketplaceStorage, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // ============ Immutable Storage ============
    // The address of the WFTM contract, so that FTM can be transferred via WFTM if native FTM transfers fail.
    address public immutable WFTMAddress;
    // The address that initially is able to recover assets.
    address public immutable adminRecoveryAddress;

    // ============ Events ============
    // All of the details of a new auction, with an index created for the tokenId.
    event AuctionCreated(
        uint256 indexed tokenId,
        uint256 auctionStart,
        uint256 duration,
        uint256 reservePrice,
        string paymentType,
        address creator
    );

    // All of the details of a new bid, with an index created for the tokenId.
    event AuctionBid(
        uint256 indexed tokenId,
        address nftContractAddress,
        address sender,
        uint256 value
    );

    // All of the details of an auction's cancelation, with an index created for the tokenId.
    event AuctionCanceled(
        uint256 indexed tokenId,
        address nftContractAddress,
        address creator
    );

    // All of the details of an auction's close, with an index created for the tokenId.
    event AuctionEnded(
        uint256 indexed tokenId,
        address nftContractAddress,
        address creator,
        address winner,
        uint256 amount,
        address nftCreator
    );

    // Emitted in the case that the contract is paused.
    event Paused(address account);

    // Emitted when the contract is unpaused.
    event Unpaused(address account);

    event Purchase(
        address indexed previousOwner,
        address indexed newOwner,
        uint256 price,
        uint256 nftID
    );

    event Minted(
        address indexed minter,
        uint256 price,
        uint256 nftID,
        string uri,
        bool status
    );

    event Burned(uint256 nftID);

    event PriceUpdate(
        address indexed owner,
        uint256 oldPrice,
        uint256 newPrice,
        uint256 nftID
    );

    event NftListStatus(address indexed owner, uint256 nftID, bool isListed);

    event Received(address, uint256);

    event Giveaway(
        address indexed sender,
        address indexed receiver,
        uint256 tokenId
    );

    // ============ Modifiers ============
    // Reverts if the sender is not admin, or admin functionality has been turned off.
    modifier onlyAdminRecovery() {
        require(adminRecoveryAddress == msg.sender, "Not admin");
        _;
    }

    modifier onlyAdminRecoveryEnabled() {
        require(
            adminRecoveryAddress == msg.sender && adminRecoveryEnabled(),
            "Not admin"
        );
        _;
    }

    // Reverts if the sender is not the auction's creator.
    modifier onlyAuctionCreator(address nftAddress, uint256 tokenId) {
        require(
            auctions[nftAddress][tokenId].creator == msg.sender,
            "Not auction creator"
        );
        _;
    }

    // Reverts if the sender is not the auction's creator or winner.
    modifier onlyAuctionCreatorOrWinner(address nftAddress, uint256 tokenId) {
        require(
            auctions[nftAddress][tokenId].creator == msg.sender ||
                auctions[nftAddress][tokenId].bidder == msg.sender,
            "Not auction creator nor winner"
        );
        _;
    }

    // Reverts if the contract is paused.
    modifier whenNotPaused() {
        require(!paused(), "paused");
        _;
    }

    // Reverts if the auction does not exist.
    modifier auctionExists(address nftAddress, uint256 tokenId) {
        require(
            !auctionCreatorIsNull(nftAddress, tokenId),
            "Auction doesn't exist"
        );
        _;
    }

    // Reverts if the auction exists.
    modifier auctionNonExistant(address nftAddress, uint256 tokenId) {
        require(
            auctionCreatorIsNull(nftAddress, tokenId),
            "Auction already exists"
        );
        _;
    }

    // Reverts if the auction is expired.
    modifier auctionNotExpired(address nftAddress, uint256 tokenId) {
        require(
            auctions[nftAddress][tokenId].firstBidTime == 0 ||
                block.timestamp < auctionEnds(nftAddress, tokenId),
            "Auction expired"
        );
        _;
    }

    // Reverts if the auction is not complete. Auction is complete if there was a bid, and the time has run out.
    modifier auctionComplete(address nftAddress, uint256 tokenId) {
        require(
            auctions[nftAddress][tokenId].firstBidTime > 0 &&
                block.timestamp >= auctionEnds(nftAddress, tokenId),
            "Auction hasn't completed"
        );
        _;
    }

    modifier validNftAddress(address nftAddress) {
        require(
            IERC165(nftAddress).supportsInterface(ERC721_INTERFACE_ID),
            "Invalid ERC721"
        );
        _;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // ============ Constructor ============
    constructor(
        address WFTMAddress_,
        address adminRecoveryAddress_,
        address dmdPaymentAddress_,
        address dmdTokenAddress_
    ) {
        WFTMAddress = WFTMAddress_;
        adminRecoveryAddress = adminRecoveryAddress_;
        payoutAddressMap["DMD"] = dmdPaymentAddress_;
        tokenAddressMap["DMD"] = dmdTokenAddress_;
        _paused = false;
        _adminRecoveryEnabled = true;
    }

    // ============ internal functions ============
    function _validate(address _nftAddress, uint256 _tokenId) internal view {
        List memory list = lists[_nftAddress][_tokenId];
        require(list.status, "Item not listed");
        require(
            msg.sender != IERC721(_nftAddress).ownerOf(_tokenId),
            "Can't buy owned item"
        );
    }

    function _transferERC20(
        address _from,
        address _to,
        uint256 _amount,
        address _tokenAddress
    ) internal {
        require(IERC20(_tokenAddress).transferFrom(_from, _to, _amount));
    }

    /**
     * @dev Open token Trade
     * @param _nftAddress The nft collection address
     * @param _tokenId The token id
     * @param _price trade price
     * @param _paymentToken The trade payment token type: "FTM", "DMD" or other token name
     */
    function _openTrade(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price,
        string memory _paymentToken
    ) internal {
        List storage list = lists[_nftAddress][_tokenId];
        require(list.owner == msg.sender, "Sender is not owner");
        require(list.status == false, "Already opened");

        IERC721(_nftAddress).approve(address(this), _tokenId);
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);

        list.status = true;
        list.price = _price;
        list.paymentToken = _paymentToken;
    }

    /**
     * @dev Close Trade
     * @param _nftAddress The nft collection address
     * @param _tokenId The token id
     */
    function _closeTrade(address _nftAddress, uint256 _tokenId) external {
        List storage list = lists[_nftAddress][_tokenId];
        require(list.owner == msg.sender, "Sender is not owner");
        require(list.status == true, "Already colsed");

        IERC721(_nftAddress).transferFrom(address(this), msg.sender, _tokenId);

        list.status = true;
        if (auctions[_nftAddress][_tokenId].creator == msg.sender) {
            delete auctions[_nftAddress][_tokenId];
        }
    }

    // =========== Private functions ==========
    // Will attempt to transfer FTM, but will transfer WFTM instead if it fails.
    function _transferFTMOrWFTM(address payable to, uint256 value) private {
        // Try to transfer FTM to the given recipient.
        if (!attemptFTMTransfer(to, value)) {
            // If the transfer fails, wrap and send as WFTM, so that
            // the auction is not impeded and the recipient still
            // can claim FTM via the WFTM contract (similar to escrow).
            IWFTM(WFTMAddress).deposit{value: value}();
            IWFTM(WFTMAddress).transfer(to, value);
            // At this point, the recipient can unwrap WFTM.
        }
    }

    // Sending FTM is not guaranteed complete, and the method used here will return false if
    // it fails. For example, a contract can block FTM transfer, or might use
    // an excessive amount of gas, thereby griefing a new bidder.
    // We should limit the gas used in transfers, and handle failure cases.
    function attemptFTMTransfer(address payable to, uint256 value)
        private
        returns (bool)
    {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send FTM to the recipient.
        // NOTE: This might allow the recipient to attempt a limited reentrancy attack.
        (bool success, ) = to.call{value: value, gas: 30000}("");
        return success;
    }

    // ============ public functions ============
    /**
     * @dev List multiple nft tokens
     * @param _isNew Set as new
     * @param _nftAddress The nft collection address
     * @param _newTokenIds The tokenId array
     * @param _creators The creator array
     * @param _prices The price array
     * @param _owners The owner array
     * @param _royalties The royalty array
     * @param _listedMap The listed status array
     */
    function addCreatorMap(
        bool _isNew,
        address _nftAddress,
        uint256[] memory _newTokenIds,
        address[] memory _creators,
        uint256[] memory _prices,
        address[] memory _owners,
        uint256[] memory _royalties,
        bool[] memory _listedMap
    ) external onlyAdminRecovery validNftAddress(_nftAddress) {
        require(
            _newTokenIds.length == _creators.length &&
                _newTokenIds.length == _prices.length &&
                _newTokenIds.length == _owners.length &&
                _newTokenIds.length == _royalties.length &&
                _newTokenIds.length == _listedMap.length,
            "Mismatched array params"
        );

        if (_isNew) _tokenIds.reset();

        for (uint256 i = 0; i < _newTokenIds.length; i++) {
            _tokenIds.increment();
            List storage list = lists[_nftAddress][_newTokenIds[i]];
            list.paymentToken = "";
            list.price = _prices[i];
            list.royalty = _royalties[i];
            list.creator = payable(_creators[i]);
            list.owner = payable(_owners[i]);
            list.status = _listedMap[i];
        }
    }

    // ============ public functions ============

    /**
     * @dev Giveaway
     * @param _to to address
     * @param _nftAddress The nft collection address
     * @param _tokenId The token id
     * @param _price The token price
     * @param _paymentToken The trade payment type: "FTM", "DMD" or other token name
     * @param _royalty The royalty amount
     * @param _tokenUri The token uri of nft token
     * Emits a {Giveaway} event.
     */
    function giveaway(
        address _to,
        address _nftAddress,
        uint256 _tokenId,
        string memory _paymentToken,
        uint256 _price,
        uint256 _royalty,
        string memory _tokenUri
    ) external validNftAddress(_nftAddress) {
        if (_tokenId == 0) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();

            List storage newList = lists[_nftAddress][newTokenId];
            newList.price = _price;
            newList.paymentToken = _paymentToken;
            newList.royalty = _royalty;
            newList.creator = payable(msg.sender);
            newList.owner = payable(_to);
            newList.status = false;

            INFTsRealm(_nftAddress).mint(newTokenId, _to, _tokenUri);
            emit Giveaway(msg.sender, _to, newTokenId);
        } else {
            List storage list = lists[_nftAddress][_tokenId];

            if (list.status == false) {
                IERC721(_nftAddress).transferFrom(msg.sender, _to, _tokenId);
            } else {
                require(list.owner == msg.sender, "Sender is not owner");
                IERC721(_nftAddress).transferFrom(address(this), _to, _tokenId);
                list.status == false;
            }
            list.owner = payable(_to);
            emit Giveaway(msg.sender, _to, _tokenId);
        }
    }

    /**
     * @dev Burn nft token
     * @param _nftAddress The nft collection address
     * @param _tokenId The token id
     */
    function burn(address _nftAddress, uint256 _tokenId)
        external
        validNftAddress(_nftAddress)
    {
        INFTsRealm(_nftAddress).burn(_tokenId);
        delete lists[_nftAddress][_tokenId];
    }

    /**
     * @dev Buy new token: mint new nft token
     * @param _nftAddress The nft collection address
     * @param _creator The creator address
     * @param _paymentToken The trade payment type: "FTM", "DMD" or other token name
     * @param _price The trade price
     * @param _royalty The royalty
     * @param _tokenUri The tokenUri of nft token
     * Emit {Purchase} event
     */
    function buyNew(
        address _nftAddress,
        address _creator,
        string memory _paymentToken,
        uint256 _price,
        uint256 _royalty,
        string memory _tokenUri
    ) external payable {
        require(
            payoutAddressMap[_paymentToken] != address(0),
            "Invalid payment token"
        );
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        List storage list = lists[_nftAddress][newTokenId];
        list.paymentToken = _paymentToken;
        list.price = _price;
        list.royalty = _royalty;
        list.creator = payable(_creator);

        // require(address(msg.sender).balance >= priceMap[newTokenId], "Error, the amount is lower");
        // 2.5% commission cut

        uint256 _commissionValue = 0;
        uint256 _sellerValue = 0;

        if (
            keccak256(abi.encodePacked((_paymentToken))) ==
            keccak256(abi.encodePacked(("FTM")))
        ) {
            require(msg.value >= list.price, "Not enough balance");
            _commissionValue = (list.price * marketFeeForFTM) / 1000;
            _sellerValue = list.price - _commissionValue;
        } else {
            require(
                IERC20(tokenAddressMap[_paymentToken]).balanceOf(msg.sender) >=
                    list.price,
                "Not enough balance"
            );

            _commissionValue = (list.price * marketFeeForToken) / 1000;
            _sellerValue = list.price - _commissionValue;
        }

        if (
            keccak256(abi.encodePacked((_paymentToken))) ==
            keccak256(abi.encodePacked(("FTM")))
        ) {
            _transferFTMOrWFTM(payable(_creator), _sellerValue);
            _transferFTMOrWFTM(
                payable(adminRecoveryAddress),
                _commissionValue / 2
            );
            _transferFTMOrWFTM(
                payable(payoutAddressMap[_paymentToken]),
                _commissionValue / 2
            );
        } else {
            _transferERC20(
                msg.sender,
                _creator,
                _sellerValue,
                tokenAddressMap[_paymentToken]
            );
            _transferERC20(
                msg.sender,
                adminRecoveryAddress,
                _commissionValue / 2,
                tokenAddressMap[_paymentToken]
            );
            _transferERC20(
                msg.sender,
                payoutAddressMap[_paymentToken],
                _commissionValue / 2,
                tokenAddressMap[_paymentToken]
            );
        }

        list.status = false;
        list.owner = payable(msg.sender);
        INFTsRealm(_nftAddress).mint(newTokenId, msg.sender, _tokenUri);

        emit Purchase(_creator, msg.sender, list.price, newTokenId);
    }

    /**
     * @dev Buy existing token
     * @param _nftAddress The nft collection address
     * @param _tokenId The token id
     * @param _paymentToken The trade payment type: "FTM", "DMD" or other token name
     * @param _price The token price
     * Emit {Purchase} event
     */
    function buy(
        address _nftAddress,
        uint256 _tokenId,
        string memory _paymentToken,
        uint256 _price
    ) external payable validNftAddress(_nftAddress) {
        require(
            payoutAddressMap[_paymentToken] != address(0),
            "Invalid payment token"
        );
        _validate(_nftAddress, _tokenId);
        List storage list = lists[_nftAddress][_tokenId];

        require(list.price == _price, "Price not matching");
        require(
            keccak256(abi.encodePacked((_paymentToken))) ==
                keccak256(abi.encodePacked(list.paymentToken)),
            "Invalid Payment token"
        );
        address _previousOwner = list.owner;

        // 5% commission cut
        uint256 _royaltyValue = (list.price * list.royalty) / 100;
        // _owner.transfer(_owner, _sellerValue);

        uint256 _commissionValue = 0;
        uint256 _sellerValue = 0;

        if (
            keccak256(abi.encodePacked((_paymentToken))) ==
            keccak256(abi.encodePacked(("FTM")))
        ) {
            require(msg.value >= list.price, "Not enough balance");
            _commissionValue = (list.price * marketFeeForFTM) / 1000;
            _sellerValue = list.price - _commissionValue - _royaltyValue;
        } else {
            require(
                IERC20(tokenAddressMap[_paymentToken]).balanceOf(msg.sender) >=
                    list.price,
                "Not enough balance"
            );
            _commissionValue = (list.price * marketFeeForToken) / 1000;
            _sellerValue = list.price - _commissionValue - _royaltyValue;
        }

        if (
            keccak256(abi.encodePacked((_paymentToken))) ==
            keccak256(abi.encodePacked(("FTM")))
        ) {
            _transferFTMOrWFTM(payable(list.owner), _sellerValue);
            _transferFTMOrWFTM(payable(list.creator), _royaltyValue);
            _transferFTMOrWFTM(
                payable(adminRecoveryAddress),
                _commissionValue / 2
            );
            _transferFTMOrWFTM(
                payable(payoutAddressMap[_paymentToken]),
                _commissionValue / 2
            );
        } else {
            _transferERC20(
                msg.sender,
                (list.owner),
                _sellerValue,
                tokenAddressMap[_paymentToken]
            );
            _transferERC20(
                msg.sender,
                (list.creator),
                _royaltyValue,
                tokenAddressMap[_paymentToken]
            );
            _transferERC20(
                msg.sender,
                (adminRecoveryAddress),
                _commissionValue / 2,
                tokenAddressMap[_paymentToken]
            );
            _transferERC20(
                msg.sender,
                (payoutAddressMap[_paymentToken]),
                _commissionValue / 2,
                tokenAddressMap[_paymentToken]
            );
        }

        IERC721(_nftAddress).transferFrom(address(this), msg.sender, _tokenId);
        list.owner = payable(msg.sender);
        list.status = false;

        emit Purchase(_previousOwner, msg.sender, list.price, _tokenId);
    }

    /**
     * @dev Update token price
     * @param _nftAddress The nft collection address
     * @param _tokenId The id of token id
     * @param _price The buy token price
     * @param _paymentToken The trade payment type: "FTM", "DMD" or other token name
     * Emit {PriceUpdate} event
     */
    function updateTokenPrice(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price,
        string memory _paymentToken
    ) external returns (bool) {
        List storage list = lists[_nftAddress][_tokenId];
        require(msg.sender == list.owner, "Sender is not the owner");

        uint256 oldPrice = list.price;
        list.price = _price;
        list.paymentToken = _paymentToken;

        emit PriceUpdate(msg.sender, oldPrice, _price, _tokenId);
        return true;
    }

    /**
     * @dev Update status of listed token
     * @param _nftAddress The nft collection address
     * @param _tokenId The token id
     * @param _status The list status
     * Emit {NftListStatus} event
     */
    function updateTokenListingStatus(
        address _nftAddress,
        uint256 _tokenId,
        bool _status
    ) external returns (bool) {
        require(
            msg.sender == IERC721(_nftAddress).ownerOf(_tokenId),
            "Sender is not the owner"
        );
        List storage list = lists[_nftAddress][_tokenId];
        list.status = _status;

        emit NftListStatus(msg.sender, _tokenId, _status);
        return true;
    }

    /**
     * @dev Create Auction
     * @param _nftAddress The nft collection address
     * @param _tokenId The token id for trade
     * @param _isNewToken The buy token price
     * @param _tokenUri The token uri: only needed for new token
     * @param _duration The duration of auction
     * @param _paymentToken The trade payment type: "FTM", "DMD" or other token name
     * @param _reservePrice The minimum bid price of auction
     * @param _creator The creator
     * Emit {AuctionCreated} event
     */
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        bool _isNewToken,
        string memory _tokenUri,
        uint256 _duration,
        string memory _paymentToken,
        uint256 _reservePrice,
        address _creator
    )
        external
        nonReentrant
        validNftAddress(_nftAddress)
        whenNotPaused
        auctionNonExistant(_nftAddress, _tokenId)
    {
        // Check basic input requirements are reasonable.
        require(_creator != address(0));

        // create a new nft token if it's new
        if (_isNewToken) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _tokenId = newTokenId;

            List storage list = lists[_nftAddress][_tokenId];
            list.price = _reservePrice;
            list.paymentToken = _paymentToken;
            list.creator = payable(_creator);

            INFTsRealm(_nftAddress).mint(_tokenId, msg.sender, _tokenUri);
        }

        lists[_nftAddress][_tokenId].owner = payable(msg.sender);
        _openTrade(_nftAddress, _tokenId, _reservePrice, _paymentToken);

        uint256 auctionStart = block.timestamp;
        auctions[_nftAddress][_tokenId] = Auction({
            duration: _duration,
            reservePrice: _reservePrice,
            paymentType: _paymentToken,
            creatorFeePercent: 50,
            creator: _creator,
            fundsRecipient: payable(adminRecoveryAddress),
            amount: 0,
            firstBidTime: auctionStart,
            bidder: payable(address(0))
        });

        // Emit an event describing the new auction.
        emit AuctionCreated(
            _tokenId,
            auctionStart,
            _duration,
            _reservePrice,
            _paymentToken,
            _creator
        );
    }

    /**
     * @dev Create Bid: bid to existing auction
     * @param _nftAddress The nft collection address
     * @param _tokenId The token id for auction
     * @param _paymentToken The trade payment type: "FTM", "DMD" or other token name
     * @param _amount The bid amount
     * Emit {AuctionBid} event
     */
    function createBid(
        address _nftAddress,
        uint256 _tokenId,
        string memory _paymentToken,
        uint256 _amount
    )
        external
        payable
        nonReentrant
        whenNotPaused
        auctionExists(_nftAddress, _tokenId)
        auctionNotExpired(_nftAddress, _tokenId)
    {
        Auction storage auction = auctions[_nftAddress][_tokenId];
        require(_amount > 0, "Amount must be greater than 0");
        require(
            keccak256(abi.encodePacked((_paymentToken))) ==
                keccak256(abi.encodePacked(auction.paymentType)),
            "Invalid PaymentType"
        );

        if (
            keccak256(abi.encodePacked((_paymentToken))) ==
            keccak256(abi.encodePacked(("FTM")))
        ) {
            require(_amount == msg.value, "Amount doesn't equal msg.value");
        } else {
            require(
                IERC20(tokenAddressMap[_paymentToken]).balanceOf(msg.sender) >=
                    _amount,
                "Not enough balance"
            );
        }
        // Check if the current bid amount is 0.
        if (auction.amount == 0) {
            // If so, it is the first bid.
            // auctions[tokenId].firstBidTime = block.timestamp;
            // We only need to check if the bid matches reserve bid for the first bid,
            // since future checks will need to be higher than any previous bid.
            require(
                _amount >= auction.reservePrice,
                "Must bid reservePrice or more"
            );
        } else {
            // Check that the new bid is sufficiently higher than the previous bid, by
            // the percentage defined as MIN_BID_INCREMENT_PERCENT (10% as a default).
            require(
                _amount >=
                    auction.amount +
                        (auction.amount * MIN_BID_INCREMENT_PERCENT) /
                        100,
                "MIN_BID_INCREMENT required"
            );

            // Refund the previous bidder.
            if (
                keccak256(abi.encodePacked((_paymentToken))) ==
                keccak256(abi.encodePacked(("FTM")))
            ) {
                _transferFTMOrWFTM(auction.bidder, auction.amount);
            } else {
                IERC20(tokenAddressMap[_paymentToken]).transfer(
                    auction.bidder,
                    auction.amount
                );
            }
        }

        // Update the current auction.
        auction.amount = _amount;
        auction.bidder = payable(msg.sender);

        // send tokens to marketplace
        if (
            keccak256(abi.encodePacked((_paymentToken))) !=
            keccak256(abi.encodePacked(("FTM")))
        ) {
            _transferERC20(
                msg.sender,
                address(this),
                _amount,
                tokenAddressMap[_paymentToken]
            );
        }

        // Compare the auction's end time with the current time plus the 15 minute extension,
        // to see whether we're near the auctions end and should extend the auction.
        if (
            auctionEnds(_nftAddress, _tokenId) < block.timestamp + TIME_BUFFER
        ) {
            // We add onto the duration whenever time increment is required, so
            // that the auctionEnds at the current time plus the buffer.
            auction.duration +=
                block.timestamp +
                TIME_BUFFER -
                auctionEnds(_nftAddress, _tokenId);
        }
        // Emit the event that a bid has been made.
        emit AuctionBid(_tokenId, _nftAddress, msg.sender, _amount);
    }

    /**
     * @dev End existing auction
     * @param _nftAddress The nft collection address
     * @param _tokenId The token id
     * Emit {AuctionEnded} event
     */
    function endAuction(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused
        validNftAddress(_nftAddress)
        auctionComplete(_nftAddress, _tokenId)
        onlyAuctionCreatorOrWinner(_nftAddress, _tokenId)
    {
        Auction memory auction = auctions[_nftAddress][_tokenId];
        List storage list = lists[_nftAddress][_tokenId];
        // Store relevant auction data in memory for the life of this function.
        address winner = auction.bidder;
        uint256 amount = auction.amount;
        address creator = auction.creator;
        string memory paymentType = auction.paymentType;

        // Remove all auction data for this token from storage.
        delete auctions[_nftAddress][_tokenId];

        // We don't use safeTransferFrom, to prevent reverts at this point,
        // which would break the auction.
        if (winner == address(0)) {
            IERC721(_nftAddress).transferFrom(address(this), creator, _tokenId);
            list.owner = payable(creator);
        } else {
            IERC721(_nftAddress).transferFrom(address(this), winner, _tokenId);
            if (
                keccak256(abi.encodePacked((paymentType))) ==
                keccak256(abi.encodePacked(("FTM")))
            ) {
                uint256 _commissionValue = (amount * marketFeeForFTM) / 1000;
                _transferFTMOrWFTM(
                    payable(adminRecoveryAddress),
                    _commissionValue / 2
                );
                _transferFTMOrWFTM(
                    payable(payoutAddressMap[paymentType]),
                    _commissionValue / 2
                );

                uint256 _royaltyValue = 0;
                if (creator != list.creator) {
                    _royaltyValue = (amount * list.royalty) / 100;
                    _transferFTMOrWFTM(payable(list.creator), _royaltyValue);
                }

                _transferFTMOrWFTM(
                    payable(creator),
                    amount - _royaltyValue - _commissionValue
                );
            } else {
                uint256 _commissionValue = (amount * marketFeeForToken) / 1000;
                _transferERC20(
                    msg.sender,
                    adminRecoveryAddress,
                    _commissionValue / 2,
                    tokenAddressMap[paymentType]
                );

                _transferERC20(
                    msg.sender,
                    payoutAddressMap[paymentType],
                    _commissionValue / 2,
                    tokenAddressMap[paymentType]
                );

                uint256 _royaltyValue = 0;
                if (creator != list.creator) {
                    _royaltyValue = (amount * list.royalty) / 100;
                    _transferERC20(
                        msg.sender,
                        list.creator,
                        _royaltyValue,
                        tokenAddressMap[paymentType]
                    );
                }
                _transferERC20(
                    msg.sender,
                    creator,
                    amount - _royaltyValue - _commissionValue,
                    tokenAddressMap[paymentType]
                );
            }

            list.owner = payable(winner);
        }

        list.status = false;

        // Emit an event describing the end of the auction.
        emit AuctionEnded(
            _tokenId,
            _nftAddress,
            creator,
            winner,
            amount,
            list.creator
        );
    }

    /**
     * @dev Cancel existing auction
     * @param _nftAddress The nft collection address
     * @param _tokenId The token id
     * Emit {AuctionCanceled} event
     */
    function cancelAuction(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
        validNftAddress(_nftAddress)
        auctionExists(_nftAddress, _tokenId)
        onlyAuctionCreator(_nftAddress, _tokenId)
    {
        Auction memory auction = auctions[_nftAddress][_tokenId];
        List storage list = lists[_nftAddress][_tokenId];
        // Check that there hasn't already been a bid for this NFT.
        require(uint256(auction.amount) == 0, "Auction already started");
        // Pull the creator address before removing the auction.
        address creator = auction.creator;

        // Remove all data about the auction.
        delete auctions[_nftAddress][_tokenId];

        // Transfer the NFT back to the creator.
        IERC721(_nftAddress).transferFrom(address(this), creator, _tokenId);

        list.status = false;
        list.owner = payable(creator);

        // Emit an event describing that the auction has been canceled.
        emit AuctionCanceled(_tokenId, _nftAddress, creator);
    }

    // ============ Admin Functions ============

    // Irrevocably turns off admin recovery.
    function turnOffAdminRecovery() external onlyAdminRecovery {
        _adminRecoveryEnabled = false;
    }

    function pauseContract() external onlyAdminRecoveryEnabled {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpauseContract() external onlyAdminRecoveryEnabled {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // Allows the admin to transfer any NFT from this contract to the recovery address.
    function recoverNFT(address _nftAddress, uint256 _tokenId)
        external
        validNftAddress(_nftAddress)
        onlyAdminRecoveryEnabled
    {
        IERC721(_nftAddress).transferFrom(
            address(this),
            adminRecoveryAddress,
            _tokenId
        );
    }

    function setTokenAddress(
        string memory _paymentToken,
        address _tokenAddress,
        address _payoutAddress
    ) external onlyAdminRecoveryEnabled {
        tokenAddressMap[_paymentToken] = _tokenAddress;
        payoutAddressMap[_paymentToken] = _payoutAddress;
    }

    function setMarketFeeForFantom(
        uint256 _newMarketFeeForFTM
    ) external onlyAdminRecoveryEnabled {
        require(_newMarketFeeForFTM > 1, "Invalid MarketFee For FTM");
        marketFeeForFTM = _newMarketFeeForFTM;
    }

    function setMarketFeeForToken(
        uint256 _newMarketFeeForToken
    ) external onlyAdminRecoveryEnabled {
        require(_newMarketFeeForToken > 1, "Invalid MarketFee For Token");
        marketFeeForToken = _newMarketFeeForToken;
    }

    function withdraw() external onlyAdminRecoveryEnabled {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawToken(string memory _tokenName)
        external
        onlyAdminRecoveryEnabled
    {
        require(tokenAddressMap[_tokenName] != address(0), "Invalid token");
        IERC20(tokenAddressMap[_tokenName]).transfer(
            msg.sender,
            IERC20(tokenAddressMap[_tokenName]).balanceOf(address(this))
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MarketplaceStorage {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // ============ Structs ============

    struct Auction {
        // The value of the current highest bid.
        uint256 amount;
        // The amount of time that the auction should run for, after the first bid was made.
        uint256 duration;
        // The time of the first bid.
        uint256 firstBidTime;
        // The minimum price of the first bid.
        uint256 reservePrice;
        // The token type that is used in token trander in auction.
        string paymentType;
        // The creator fee percent.
        uint8 creatorFeePercent;
        // The address of the auction's creator. The creator can cancel the auction if it hasn't had a bid yet.
        address creator;
        // The address of the current highest bid address.
        address payable bidder;
        // The address that should receive funds once the NFT is sold.
        address payable fundsRecipient;
    }

    struct List {
        // The payToken ("FTM" or "DMD")
        string paymentToken;
        // The list prirce
        uint256 price;
        // The royalty
        uint256 royalty;
        // The nft creator
        address payable creator;
        // The nft owner
        address payable owner;
        // The listed status
        bool status;
    }

    // ============ Constants ============

    // The minimum amount of time left in an auction after a new bid is created; 15 min.
    uint16 public constant TIME_BUFFER = 900;
    // The FTM needed above the current bid for a new bid to be valid; 0.001 FTM.
    uint8 public constant MIN_BID_INCREMENT_PERCENT = 10;
    // Interface constant for ERC721, to check values in constructor.
    bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;

    uint256 public marketFeeForFTM = 75;
    uint256 public marketFeeForToken = 50;

    bool internal _adminRecoveryEnabled;
    bool internal _paused;

    /// @notice NftAddress -> Token ID -> Auction
    mapping(address => mapping(uint256 => Auction)) public auctions;
    /// @notice NftAddress -> Token ID -> List
    mapping(address => mapping(uint256 => List)) public lists;
    /// @notice PaymentToken -> Token address
    mapping(string => address) public tokenAddressMap;
    /// @notice PaymentToken -> Payout address
    mapping(string => address) public payoutAddressMap;

    Counters.Counter internal _tokenIds;

    // Returns true if the contract is paused.
    function paused() public view returns (bool) {
        return _paused;
    }

    // Returns true if admin recovery is enabled.
    function adminRecoveryEnabled() public view returns (bool) {
        return _adminRecoveryEnabled;
    }

    // get List
    function getList(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (List memory)
    {
        return lists[_nftAddress][_tokenId];
    }

    // get Auction
    function getAuction(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (Auction memory)
    {
        return auctions[_nftAddress][_tokenId];
    }

    // Returns true if the auction's creator is set to the null address.
    function auctionCreatorIsNull(address nftAddress, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        // The auction does not exist if the creator is the null address,
        // since the NFT would not have been transferred in `createAuction`.
        return auctions[nftAddress][tokenId].creator == address(0);
    }

    // Returns the timestamp at which an auction will finish.
    function auctionEnds(address nftAddress, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        // Derived by adding the auction's duration to the time of the first bid.
        // NOTE: duration can be extended conditionally after each new bid is added.
        return
            auctions[nftAddress][tokenId].firstBidTime +
            auctions[nftAddress][tokenId].duration;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IWFTM {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../utils/Decimal.sol";

/**
 * @title Interface for Zora Protocol's Market
 */
interface INFTsRealm {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function burn(uint256 tokenId) external;

    function mint(
        uint256 id,
        address to,
        string memory tokenURI
    ) external;

    function mintAll(
        uint256[] memory ids,
        address[] memory tos,
        string[] memory tokenURIs
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.3;

import "./Math.sol";

/*
 * @title Decimal
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE_POW = 18;
    uint256 constant BASE = 10**BASE_POW;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Functions ============

    function one() internal pure returns (D256 memory) {
        return D256({value: BASE});
    }

    function onePlus(D256 memory d) internal pure returns (D256 memory) {
        return D256({value: d.value.add(BASE)});
    }

    function mul(uint256 target, D256 memory d)
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, d.value, BASE);
    }

    function div(uint256 target, D256 memory d)
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, BASE, d.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Math
 *
 * Library for non-standard Math functions
 * NOTE: This file is a clone of the dydx protocol's Decimal.sol contract.
 * It was forked from https://github.com/dydxprotocol/solo at commit
 * 2d8454e02702fe5bc455b848556660629c3cad36. It has not been modified other than to use a
 * newer solidity in the pragma to match the rest of the contract suite of this project.
 */
library Math {
    using SafeMath for uint256;

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        return target.mul(numerator).div(denominator);
    }

    /*
     * Return target * (numerator / denominator), but rounded up.
     */
    function getPartialRoundUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        if (target == 0 || numerator == 0) {
            // SafeMath will check for zero denominator
            return SafeMath.div(0, denominator);
        }
        return target.mul(numerator).sub(1).div(denominator).add(1);
    }

    function to128(uint256 number) internal pure returns (uint128) {
        uint128 result = uint128(number);
        require(result == number, "Math: Unsafe cast to uint128");
        return result;
    }

    function to96(uint256 number) internal pure returns (uint96) {
        uint96 result = uint96(number);
        require(result == number, "Math: Unsafe cast to uint96");
        return result;
    }

    function to32(uint256 number) internal pure returns (uint32) {
        uint32 result = uint32(number);
        require(result == number, "Math: Unsafe cast to uint32");
        return result;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}