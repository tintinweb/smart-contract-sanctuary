// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {IKODAV3Minter} from "../core/IKODAV3Minter.sol";
import {IKODAV3PrimarySaleMarketplace} from "../marketplace/IKODAV3Marketplace.sol";
import {IKOAccessControlsLookup} from "../access/IKOAccessControlsLookup.sol";

contract MintingFactory is Context {

    event AdminMintingPeriodChanged(uint256 _mintingPeriod);
    event AdminMaxMintsInPeriodChanged(uint256 _maxMintsInPeriod);
    event AdminFrequencyOverrideChanged(address _account, bool _override);

    IKOAccessControlsLookup public accessControls;

    IKODAV3Minter public koda;

    IKODAV3PrimarySaleMarketplace public marketplace;

    modifier canMintAgain(){
        require(_canCreateNewEdition(_msgSender()), "Caller unable to create yet");
        _;
    }

    // Minting allowance period
    uint256 public mintingPeriod = 30 days;

    // Limit of mints with in the period
    uint256 public maxMintsInPeriod = 15;

    // Frequency override list for users - you can temporarily add in address which disables the freeze time check
    mapping(address => bool) public frequencyOverride;

    struct MintingPeriod {
        uint128 mints;
        uint128 firstMintInPeriod;
    }

    // How many mints within the current minting period
    mapping(address => MintingPeriod) mintingPeriodConfig;

    enum SaleType {
        BUY_NOW, OFFERS, STEPPED, RESERVE
    }

    constructor(
        IKOAccessControlsLookup _accessControls,
        IKODAV3Minter _koda,
        IKODAV3PrimarySaleMarketplace _marketplace
    ) {
        accessControls = _accessControls;
        koda = _koda;
        marketplace = _marketplace;
    }

    function mintToken(
        SaleType _saleType,
        uint128 _startDate,
        uint128 _basePrice,
        uint128 _stepPrice,
        string calldata _uri,
        uint256 _merkleIndex,
        bytes32[] calldata _merkleProof
    ) canMintAgain external {
        require(accessControls.isVerifiedArtist(_merkleIndex, _msgSender(), _merkleProof), "Caller must have minter role");

        // Make tokens & edition
        uint256 editionId = koda.mintBatchEdition(1, _msgSender(), _uri);

        setupSalesMechanic(editionId, _saleType, _startDate, _basePrice, _stepPrice);
        _recordSuccessfulMint(_msgSender());
    }

    function mintBatchEdition(
        SaleType _saleType,
        uint96 _editionSize,
        uint128 _startDate,
        uint128 _basePrice,
        uint128 _stepPrice,
        string calldata _uri,
        uint256 _merkleIndex,
        bytes32[] calldata _merkleProof
    ) canMintAgain external {
        require(accessControls.isVerifiedArtist(_merkleIndex, _msgSender(), _merkleProof), "Caller must have minter role");

        // Make tokens & edition
        uint256 editionId = koda.mintBatchEdition(_editionSize, _msgSender(), _uri);

        setupSalesMechanic(editionId, _saleType, _startDate, _basePrice, _stepPrice);
        _recordSuccessfulMint(_msgSender());
    }

    function mintBatchEditionAndComposeERC20s(
        SaleType _saleType,
        uint128[] calldata _config,
        string calldata _uri,
        address[] calldata _erc20s,
        uint256[] calldata _amounts,
        bytes32[] calldata _merkleProof
    ) canMintAgain external {
        require(accessControls.isVerifiedArtist(_config[0], _msgSender(), _merkleProof), "Caller must have minter role");

        uint256 editionId = koda.mintBatchEditionAndComposeERC20s(uint96(_config[1]), _msgSender(), _uri, _erc20s, _amounts);

        setupSalesMechanic(editionId, _saleType, _config[2], _config[3], _config[4]);
        _recordSuccessfulMint(_msgSender());
    }

    function mintConsecutiveBatchEdition(
        SaleType _saleType,
        uint96 _editionSize,
        uint128 _startDate,
        uint128 _basePrice,
        uint128 _stepPrice,
        string calldata _uri,
        uint256 _merkleIndex,
        bytes32[] calldata _merkleProof
    ) canMintAgain external {
        require(accessControls.isVerifiedArtist(_merkleIndex, _msgSender(), _merkleProof), "Caller must have minter role");

        // Make tokens & edition
        uint256 editionId = koda.mintConsecutiveBatchEdition(_editionSize, _msgSender(), _uri);

        setupSalesMechanic(editionId, _saleType, _startDate, _basePrice, _stepPrice);
        _recordSuccessfulMint(_msgSender());
    }

    function setupSalesMechanic(uint256 _editionId, SaleType _saleType, uint128 _startDate, uint128 _basePrice, uint128 _stepPrice) internal {
        if (SaleType.BUY_NOW == _saleType) {
            marketplace.listEdition(_msgSender(), _editionId, _basePrice, _startDate);
        }
        else if (SaleType.STEPPED == _saleType) {
            marketplace.listSteppedEditionAuction(_msgSender(), _editionId, _basePrice, _stepPrice, _startDate);
        }
        else if (SaleType.OFFERS == _saleType) {
            marketplace.enableEditionOffers(_editionId, _startDate);
        } else if (SaleType.RESERVE == _saleType) {
            // use base price for reserve price
            marketplace.listEditionForReserveAuction(_msgSender(), _editionId, _basePrice, _startDate);
        }
    }

    /// Internal helpers

    function _canCreateNewEdition(address _account) internal view returns (bool) {
        // if frequency is overridden then assume they can mint
        if (frequencyOverride[_account]) {
            return true;
        }

        // if within the period range, check remaining allowance
        if (_getNow() <= mintingPeriodConfig[_account].firstMintInPeriod + mintingPeriod) {
            return mintingPeriodConfig[_account].mints < maxMintsInPeriod;
        }

        // if period expired - can mint another one
        return true;
    }

    function _recordSuccessfulMint(address _account) internal {
        MintingPeriod storage period = mintingPeriodConfig[_account];

        uint256 endOfCurrentMintingPeriodLimit = period.firstMintInPeriod + mintingPeriod;

        // if first time use, set the first timestamp to be now abd start counting
        if (period.firstMintInPeriod == 0) {
            period.firstMintInPeriod = _getNow();
            period.mints = period.mints + 1;
        }
        // if still within the minting period, record the new mint
        else if (_getNow() <= endOfCurrentMintingPeriodLimit) {
            period.mints = period.mints + 1;
        }
        // if we are outside of the window reset the limit and record a new single mint
        else if (endOfCurrentMintingPeriodLimit < _getNow()) {
            period.mints = 1;
            period.firstMintInPeriod = _getNow();
        }
    }

    function _getNow() internal virtual view returns (uint128) {
        return uint128(block.timestamp);
    }

    /// Public helpers

    function canCreateNewEdition(address _account) public view returns (bool) {
        return _canCreateNewEdition(_account);
    }

    function currentMintConfig(address _account) public view returns (uint128 mints, uint128 firstMintInPeriod) {
        MintingPeriod memory config = mintingPeriodConfig[_account];
        return (
        config.mints,
        config.firstMintInPeriod
        );
    }

    function setFrequencyOverride(address _account, bool _override) external {
        require(accessControls.hasAdminRole(_msgSender()), "Caller must have admin role");
        frequencyOverride[_account] = _override;
        emit AdminFrequencyOverrideChanged(_account, _override);
    }

    function setMintingPeriod(uint256 _mintingPeriod) public {
        require(accessControls.hasAdminRole(_msgSender()), "Caller must have admin role");
        mintingPeriod = _mintingPeriod;
        emit AdminMintingPeriodChanged(_mintingPeriod);
    }

    function setMaxMintsInPeriod(uint256 _maxMintsInPeriod) public {
        require(accessControls.hasAdminRole(_msgSender()), "Caller must have admin role");
        maxMintsInPeriod = _maxMintsInPeriod;
        emit AdminMaxMintsInPeriodChanged(_maxMintsInPeriod);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IKODAV3Minter {

    function mintBatchEdition(uint96 _editionSize, address _to, string calldata _uri) external returns (uint256 _editionId);

    function mintBatchEditionAndComposeERC20s(uint96 _editionSize, address _to, string calldata _uri, address[] calldata _erc20s, uint256[] calldata _amounts) external returns (uint256 _editionId);

    function mintConsecutiveBatchEdition(uint96 _editionSize, address _to, string calldata _uri) external returns (uint256 _editionId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IEditionBuyNowMarketplace {
    event EditionListed(uint256 indexed _editionId, uint256 _price, uint256 _startDate);
    event EditionPriceChanged(uint256 indexed _editionId, uint256 _price);
    event EditionDeListed(uint256 indexed _editionId);
    event EditionPurchased(uint256 indexed _editionId, uint256 indexed _tokenId, address indexed _buyer, uint256 _price);

    function listEdition(address _creator, uint256 _editionId, uint128 _listingPrice, uint128 _startDate) external;

    function delistEdition(uint256 _editionId) external;

    function buyEditionToken(uint256 _editionId) external payable;

    function buyEditionTokenFor(uint256 _editionId, address _recipient) external payable;

    function setEditionPriceListing(uint256 _editionId, uint128 _listingPrice) external;
}

interface IEditionOffersMarketplace {
    event EditionAcceptingOffer(uint256 indexed _editionId, uint128 _startDate);
    event EditionBidPlaced(uint256 indexed _editionId, address indexed _bidder, uint256 _amount);
    event EditionBidWithdrawn(uint256 indexed _editionId, address indexed _bidder);
    event EditionBidAccepted(uint256 indexed _editionId, uint256 indexed _tokenId, address indexed _bidder, uint256 _amount);
    event EditionBidRejected(uint256 indexed _editionId, address indexed _bidder, uint256 _amount);

    function enableEditionOffers(uint256 _editionId, uint128 _startDate) external;

    function placeEditionBid(uint256 _editionId) external payable;

    function withdrawEditionBid(uint256 _editionId) external;

    function rejectEditionBid(uint256 _editionId) external;

    function acceptEditionBid(uint256 _editionId, uint256 _offerPrice) external;
}

interface IEditionSteppedMarketplace {
    event EditionSteppedSaleListed(uint256 indexed _editionId, uint128 _basePrice, uint128 _stepPrice, uint128 _startDate);
    event EditionSteppedSaleBuy(uint256 indexed _editionId, uint256 indexed _tokenId, address indexed _buyer, uint256 _price, uint16 _currentStep);

    function listSteppedEditionAuction(address _creator, uint256 _editionId, uint128 _basePrice, uint128 _stepPrice, uint128 _startDate) external;

    function buyNextStep(uint256 _editionId) external payable;

    function convertSteppedAuctionToListing(uint256 _editionId, uint128 _listingPrice) external;
}

interface IReserveAuctionMarketplace {
    event EditionListedForReserveAuction(uint256 indexed _editionId, uint256 _reservePrice, uint128 _startDate);
    event BidPlacedOnReserveAuction(uint256 indexed _editionId, address indexed _bidder, uint256 _amount);
    event ReserveAuctionResulted(uint256 indexed _editionId, uint256 _finalPrice, address indexed _winner, address indexed _resulter);
    event BidWithdrawnFromReserveAuction(uint256 _editionId, address indexed _bidder, uint128 _bid);
    event ReservePriceUpdated(uint256 indexed _editionId, uint256 _reservePrice);
    event ReserveAuctionConvertedToBuyItNow(uint256 indexed _editionId, uint128 _listingPrice, uint128 _startDate);

    function listEditionForReserveAuction(address _creator, uint256 _editionId, uint128 _reservePrice, uint128 _startDate) external;
    function placeBidOnReserveAuction(uint256 _editionId) external payable;
    function resultReserveAuction(uint256 _editionId) external;
    function withdrawBidFromReserveAuction(uint256 _editionId) external;
    function updateReservePriceForReserveAuction(uint256 _editionId, uint128 _reservePrice) external;
    function convertReserveAuctionToBuyItNow(uint256 _editionId, uint128 _listingPrice, uint128 _startDate) external;
}

interface IKODAV3PrimarySaleMarketplace is IEditionBuyNowMarketplace, IEditionSteppedMarketplace, IEditionOffersMarketplace, IReserveAuctionMarketplace {
    // combo
}

interface ITokenBuyNowMarketplace {
    event TokenListed(uint256 indexed _tokenId, address indexed _seller, uint256 _price);
    event TokenDeListed(uint256 indexed _tokenId);
    event TokenPurchased(uint256 indexed _tokenId, address indexed _buyer, address indexed _seller, uint256 _price);

    function acceptTokenBid(uint256 _tokenId, uint256 _offerPrice) external;

    function rejectTokenBid(uint256 _tokenId) external;

    function withdrawTokenBid(uint256 _tokenId) external;

    function placeTokenBid(uint256 _tokenId) external payable;
}

interface ITokenOffersMarketplace {
    event TokenBidPlaced(uint256 indexed _tokenId, address indexed _currentOwner, address indexed _bidder, uint256 _amount);
    event TokenBidAccepted(uint256 indexed _tokenId, address indexed _currentOwner, address indexed _bidder, uint256 _amount);
    event TokenBidRejected(uint256 indexed _tokenId, address indexed _currentOwner, address indexed _bidder, uint256 _amount);
    event TokenBidWithdrawn(uint256 indexed _tokenId, address indexed _bidder);

    function listToken(uint256 _tokenId, uint128 _listingPrice, uint128 _startDate) external;

    function delistToken(uint256 _tokenId) external;

    function buyToken(uint256 _tokenId) external payable;

    function buyTokenFor(uint256 _tokenId, address _recipient) external payable;}

interface IReserveAuctionSecondaryMarketplace {
    event TokenListedForReserveAuction(uint256 indexed _tokenId, uint256 _reservePrice, uint128 _startDate);
    event BidPlacedOnReserveAuction(uint256 indexed _tokenId, address indexed _bidder, uint256 _amount);
    event ReserveAuctionResulted(uint256 indexed _tokenId, uint256 _finalPrice, address indexed _winner, address indexed _resulter);
    event BidWithdrawnFromReserveAuction(uint256 _tokenId, address indexed _bidder, uint128 _bid);
    event ReservePriceUpdated(uint256 indexed _tokenId, uint256 _reservePrice);
    event ReserveAuctionConvertedToBuyItNow(uint256 indexed _tokenId, uint128 _listingPrice, uint128 _startDate);

    function placeBidOnReserveAuction(uint256 _tokenId) external payable;
    function listTokenForReserveAuction(address _creator, uint256 _tokenId, uint128 _reservePrice, uint128 _startDate) external;
    function resultReserveAuction(uint256 _tokenId) external;
    function withdrawBidFromReserveAuction(uint256 _tokenId) external;
    function updateReservePriceForReserveAuction(uint256 _tokenId, uint128 _reservePrice) external;
    function convertReserveAuctionToBuyItNow(uint256 _tokenId, uint128 _listingPrice, uint128 _startDate) external;
}

interface IKODAV3SecondarySaleMarketplace is ITokenBuyNowMarketplace, ITokenOffersMarketplace, IReserveAuctionSecondaryMarketplace {
    // combo
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IKOAccessControlsLookup {
    function hasAdminRole(address _address) external view returns (bool);

    function isVerifiedArtist(uint256 index, address account, bytes32[] calldata merkleProof) external view returns (bool);

    function hasLegacyMinterRole(address _address) external view returns (bool);

    function hasContractRole(address _address) external view returns (bool);

    function hasContractOrAdminRole(address _address) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}