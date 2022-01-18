//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./RarumNFTAuction.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract AuthorizedNFTAuction is RarumNFTAuction, AccessControlEnumerableUpgradeable {

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    modifier onlyOperator() {
        require(
            hasRole(OPERATOR_ROLE, _msgSender()),
            "RarumNFTAuction: sender is not an OPERATOR"
        );
        _;
    }

    function initialize()
        public
        initializer
    {
        __RarumNFTAuction_init();
        __AccessControlEnumerable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    function authorizedAuction(NewAuctionRequest calldata _newAuction, address _seller)
        external
        onlyOperator
    {
        _createAuction(_newAuction, _seller);
    }

    function authorizedBid(
        uint256 _auctionId,
        address _erc20Token,
        uint256 _tokenAmount,
        address _bidder
    )
        external
        onlyOperator
    {
        _bid(_auctionId, _erc20Token, _tokenAmount, _bidder);
    }

    function authorizedWithdrawAuction(
        uint256 _auctionId,
        address _seller
    )
        external
        onlyOperator
    {
        _withdrawAuction(_auctionId, _seller);
    }

    function authorizedUpdateMinimumPrice(
        uint256 _auctionId,
        address _seller,
        uint256 _newMinPrice
    )
        external
        onlyOperator
    {
       _updateMinimumPrice(_auctionId, _seller, _newMinPrice);
    }

    function takeHighestBid(uint256 _auctionId, address _seller)
        external
        onlyOperator
    {
        _takeHighestBid(_auctionId, _seller);
    }

    function updateExtendBidPeriod(uint32 _newPeriod)
        external
        onlyOperator
    {
        require(_newPeriod > 0, "Invalid extend period");

        defaultBidExtendPeriod = _newPeriod;
    }

     function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerableUpgradeable, RarumNFTAuction) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/** 
  * @title An Auction Contract for bidding and selling ERC1155 tokens
  * @author onepercent.io
  * @dev This contract can be used for auctioning any ERC1155 tokens accepting any ERC20 tokens as payment
  * @notice inspired by Avo Lags GmbH Unstoppable Auctions V1 https://github.com/avolabs-io/nft-auction
  */
contract RarumNFTAuction is ERC1155HolderUpgradeable, ReentrancyGuardUpgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    /*
     * Default values that are used if not specified by the NFT seller.
     */
    uint32 public constant ONE_HOUR = 3600; //1 hour
    uint32 public constant defaultBidIncreasePercentage = 100;
    uint32 public constant bidPercentageConversionFactor = 10000;

    CountersUpgradeable.Counter public _ids;

    uint32 public defaultBidExtendPeriod;

    mapping(uint256 => Auction) public auctions;
    mapping(bytes32 => EnumerableSetUpgradeable.UintSet) private activeAuctionsByToken;
    mapping(address => EnumerableSetUpgradeable.UintSet) private activeAuctionIdsByHolder;
    mapping(address => EnumerableSetUpgradeable.Bytes32Set) private activeAuctionHashesByHolder;

    enum AUCTION_STATUS {
        ACTIVE,
        SETTLED,
        WITHDRAWN
    }

    struct NewAuctionRequest {
        address nftContractAddress;
        uint256 tokenId;
        uint256 amount;
        address erc20Token;
        uint256 minPrice;
        uint256 start;
        uint256 end;
        uint128 bidIncreasePercentage;
        uint128 bidExtendPeriod;
        address[] feeRecipients;
        uint32[] feePercentages;
    }

    struct Auction {
        uint256 amount; // amount of tokens being auctioned
        uint256 tokenId;
        uint128 bidIncreasePercentage;
        uint128 bidExtendPeriod;
        uint256 minPrice;
        uint256 minNextBid;
        uint256 start;
        uint256 end;
        uint256 highestBid;
        address highestBidder;
        address nftContractAddress;
        address nftSeller;
        address ERC20Token; // The seller can specify an ERC20 token that can be used to bid or purchase the NFT.
        address[] feeRecipients;
        uint32[] feePercentages;
        AUCTION_STATUS status;
    }

    event NftAuctionCreated(uint256 indexed auctionId, Auction auction);

    event BidMade(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint256 indexed auctionId,
        address bidder,
        address erc20Token,
        uint256 tokenAmount
    );

    event AuctionEndUpdated(
        uint256 auctionId,
        uint256 auctionEnd
    );

    event NFTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        uint256 amount,
        address nftSeller,
        uint256 highestBid,
        address highestBidder
    );

    event AuctionSettled(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        address indexed auctionSettler
    );

    event AuctionWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address nftOwner
    );

    event MinimumPriceUpdated(
        uint256 auctionId,
        uint256 newMinPrice
    );

    event BuyNowPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newBuyNowPrice
    );

    event HighestBidTaken(uint256 auctionId, address bidder, uint256 bid);

    modifier auctionOngoing(uint256 _auctionId) {
        require(
            _isAuctionOngoing(_auctionId),
            "RarumNFTAuction: auction has ended"
        );
        _;
    }

    modifier onlyActiveAuction(uint256 _auctionId) {
        require(auctions[_auctionId].status == AUCTION_STATUS.ACTIVE, "Auction has been settled");
        _;
    }

    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "RarumNFTAuction: price cannot be zero");
        _;
    }

    modifier onlyNftSeller(uint256 _auctionId, address _seller) {
        require(
            _seller == auctions[_auctionId].nftSeller,
            "Only nft seller"
        );
        _;
    }

    modifier minimumBidNotMade(uint _auctionId) {
        require(
            !_isMinimumBidMade(_auctionId),
            "RarumNFTAuction: auction has a valid bid made"
        );
        _;
    }

    modifier isAuctionOver(uint256 _auctionId) {
        require(
            !_isAuctionOngoing(_auctionId),
            "RarumNFTAuction: auction is not yet over"
        );
        _;
    }

    modifier isFeePercentagesLessThanMaximum(uint32[] memory _feePercentages) {
        uint32 totalPercent;
        for (uint256 i = 0; i < _feePercentages.length; i++) {
            totalPercent = totalPercent + _feePercentages[i];
        }
        require(totalPercent <= 10000, "RarumNFTAuction: fee percentages exceed maximum");
        _;
    }

    function __RarumNFTAuction_init()
        public
        initializer
    {
        __ERC1155Holder_init();

        defaultBidExtendPeriod = ONE_HOUR;
    }

    function __ERC1155_init_unchained()
        public
        initializer
    {
        defaultBidExtendPeriod = ONE_HOUR;
    }

    /*************************************************
     * PUBLIC WRITE METHODS                          *
     *************************************************/

      function settleAuction(uint256 _auctionId)
        external
        isAuctionOver(_auctionId)
        onlyActiveAuction(_auctionId)
        nonReentrant
    {
        Auction memory auction = auctions[_auctionId];

        auctions[_auctionId].status = AUCTION_STATUS.SETTLED;

        if (auction.highestBid < auction.minPrice) {
            _unlockTokens(auction);
        } else {
            _transferNftAndPaySeller(_auctionId);
        }

        emit AuctionSettled(auction.nftContractAddress, auction.tokenId, msg.sender);

        _removeActiveAuction(_auctionId, auction);
    }

    /*************************************************
     * PUBLIC READ METHODS                           *
     *************************************************/

    function getActiveAuctionsByHolder(address _holder)
        external
        view
        returns (Auction[] memory activeAuctions)
    {
        uint256[] memory auctionIdList = activeAuctionIdsByHolder[_holder].values();
        Auction[] memory list = new Auction[](auctionIdList.length);

        for (uint256 i = 0; i < list.length; i++) {
            list[i] = auctions[auctionIdList[i]];
        }

        return list;
    }

    function getActiveAuctionsByToken(address _nftContractAddress, uint256 _tokenId)
        external
        view
        returns (Auction[] memory)
    {
        bytes32 tokenHash = _hashToken(_nftContractAddress, _tokenId);
        uint256[] memory auctionIdList = activeAuctionsByToken[tokenHash].values();
        Auction[] memory list = new Auction[](auctionIdList.length);

        for (uint256 i = 0; i < list.length; i++) {
            list[i] = auctions[auctionIdList[i]];
        }

        return list;
    }

    /*************************************************
     * INTERNAL WRITE METHODS                        *
     *************************************************/

    function _createAuction(
        NewAuctionRequest calldata _newAuction,
        address _seller
    ) internal {
        _validateNewAuction(_newAuction, _seller);

        _ids.increment();

        uint256 auctionId = _ids.current();

        uint128 increasePercentage = _newAuction.bidIncreasePercentage == 0
            ? defaultBidIncreasePercentage
            :_newAuction.bidIncreasePercentage;

        uint128 bidExtendPeriod = _newAuction.bidExtendPeriod == 0
            ? defaultBidExtendPeriod
            :_newAuction.bidExtendPeriod;

        Auction memory auction = Auction({
            amount: _newAuction.amount,
            nftContractAddress: _newAuction.nftContractAddress,
            tokenId: _newAuction.tokenId,
            bidIncreasePercentage: increasePercentage,
            bidExtendPeriod: bidExtendPeriod,
            minPrice: _newAuction.minPrice,
            minNextBid: _newAuction.minPrice,
            start: _newAuction.start,
            end: _newAuction.end,
            highestBid: 0,
            highestBidder: address(0),
            nftSeller: _seller,
            ERC20Token: _newAuction.erc20Token,
            feeRecipients: _newAuction.feeRecipients,
            feePercentages: _newAuction.feePercentages,
            status: AUCTION_STATUS.ACTIVE
        });

        auctions[auctionId] = auction;

        _addActiveAuction(auctionId, auction);

        _lockNFT(auction);

        emit NftAuctionCreated(auctionId, auction);
    }

    function _bid(
        uint256 _auctionId,
        address _erc20Token,
        uint256 _tokenAmount,
        address _bidder
    ) 
        internal
        nonReentrant
        auctionOngoing(_auctionId)
    {
        Auction storage auction = auctions[_auctionId];

        require(_bidder != auction.nftSeller, "RarumNFTAuction: owner cannot bid on own NFT");
        require(block.timestamp <= auction.end, "RarumNFTAuction: auction has ended");
        require(_erc20Token == auction.ERC20Token, "RarumNFTAuction: bid token not accepted");
        require(_tokenAmount >= auction.minNextBid, "RarumNFTAuction: bid amount too low");

        _lockERC20Tokens(_erc20Token, _bidder, _tokenAmount);

        if (auction.highestBidder != address(0)) {
            // return tokens to previous bidder if there is one
            IERC20Upgradeable(auction.ERC20Token).transfer(auction.highestBidder, auction.highestBid);
        }

        // update highest bid
        auction.highestBid = _tokenAmount;
        auction.highestBidder = _bidder;
        auction.minNextBid = _tokenAmount * (bidPercentageConversionFactor + auction.bidIncreasePercentage) / bidPercentageConversionFactor;

        _maybeExtendAuctionEnd(_auctionId);

        emit BidMade(
            auction.nftContractAddress,
            auction.tokenId,
            _auctionId,
            _bidder,
            _erc20Token,
            _tokenAmount
        );
    }

    function _withdrawAuction(uint256 _auctionId, address _seller)
        internal
        onlyNftSeller(_auctionId, _seller)
        onlyActiveAuction(_auctionId)
        minimumBidNotMade(_auctionId)
        nonReentrant
    {
        Auction storage auction = auctions[_auctionId];

        auctions[_auctionId].status = AUCTION_STATUS.WITHDRAWN;

        _unlockTokens(auction);

        emit AuctionWithdrawn(auction.nftContractAddress, auction.tokenId, msg.sender);

        _removeActiveAuction(_auctionId, auction);
    }

    function _updateMinimumPrice(
        uint256 _auctionId,
        address _seller,
        uint256 _newMinPrice
    )
        internal
        onlyNftSeller(_auctionId, _seller)
        minimumBidNotMade(_auctionId)
        priceGreaterThanZero(_newMinPrice)
    {
        Auction storage auction = auctions[_auctionId];

        auction.minPrice = _newMinPrice;

        emit MinimumPriceUpdated(_auctionId, _newMinPrice);

        _maybeExtendAuctionEnd(_auctionId);
    }

    /*
     * The NFT seller can opt to end an auction by taking the current highest bid.
     */
    function _takeHighestBid(uint256 _auctionId, address _seller)
        internal
        onlyNftSeller(_auctionId, _seller)
        nonReentrant
    {
        require(
            _isABidMade(_auctionId),
            "Cannot payout 0 bid"
        );

        Auction memory auction = auctions[_auctionId];

        auctions[_auctionId].status = AUCTION_STATUS.SETTLED;

        _transferNftAndPaySeller(_auctionId);
    
        emit HighestBidTaken(_auctionId, auction.highestBidder, auction.highestBid);

        _removeActiveAuction(_auctionId, auction);
    }

    function _addActiveAuction(uint256 _auctionId, Auction memory _auction)
        internal
    {
        bytes32 tokenHash = _hashToken(_auction.nftContractAddress, _auction.tokenId);

        activeAuctionsByToken[tokenHash].add(_auctionId);
        activeAuctionIdsByHolder[_auction.nftSeller].add(_auctionId);
        activeAuctionHashesByHolder[_auction.nftSeller].add(tokenHash);
    }

    function _removeActiveAuction(uint256 _auctionId, Auction memory _auction)
        internal
    {
        bytes32 tokenHash = _hashToken(_auction.nftContractAddress, _auction.tokenId);

        activeAuctionsByToken[tokenHash].remove(_auctionId);
        activeAuctionIdsByHolder[_auction.nftSeller].remove(_auctionId);
        activeAuctionHashesByHolder[_auction.nftSeller].remove(tokenHash);
    }

    function _lockNFT(Auction memory _auction) internal {
        IERC1155Upgradeable nftContract = IERC1155Upgradeable(_auction.nftContractAddress);

        uint256 balanceBeforeTransfer = nftContract.balanceOf(address(this), _auction.tokenId);

        nftContract.safeTransferFrom(
            _auction.nftSeller,
            address(this),
            _auction.tokenId,
            _auction.amount,
            new bytes(0)
        );

        uint256 balanceAfterTransfer = nftContract.balanceOf(address(this), _auction.tokenId);

        require(balanceAfterTransfer == balanceBeforeTransfer + _auction.amount, "NFT transfer failed");
    }

    function _lockERC20Tokens(address _erc20Token, address _bidder, uint256 _tokenAmount) internal {
        IERC20Upgradeable erc20Contract = IERC20Upgradeable(_erc20Token);

        uint256 balanceBeforeTransfer = erc20Contract.balanceOf(address(this));

        IERC20Upgradeable(_erc20Token).transferFrom(
            _bidder,
            address(this),
            _tokenAmount
        );

        uint256 balanceAfterTransfer = erc20Contract.balanceOf(address(this));

        require(balanceAfterTransfer == balanceBeforeTransfer + _tokenAmount, "ERC20 transfer failed");
    }

     /// @dev transfer back tokens to their original owners
    function _unlockTokens(Auction memory _auction) internal {
        IERC1155Upgradeable(_auction.nftContractAddress).safeTransferFrom(
            address(this),
            _auction.nftSeller,
            _auction.tokenId,
            _auction.amount,
            new bytes(0)
        );

        if (_auction.highestBidder != address(0)) {
            IERC20Upgradeable(_auction.ERC20Token).transfer(
                _auction.highestBidder,
                _auction.highestBid
            );
        }
    }

    function _transferNftAndPaySeller(uint256 _auctionId) internal {
        Auction memory auction = auctions[_auctionId];

        _payFeesAndSeller(auction);

        IERC1155Upgradeable(auction.nftContractAddress).safeTransferFrom(
            address(this),
            auction.highestBidder,
            auction.tokenId,
            auction.amount,
            new bytes(0)
        );

        emit NFTTransferredAndSellerPaid(
            auction.nftContractAddress,
            auction.tokenId,
            auction.amount,
            auction.nftSeller,
            auction.highestBid,
            auction.highestBidder
        );
    }

    function _payFeesAndSeller(Auction memory _auction) internal {
        uint256 feesPaid;
        // pay fees
        for (uint256 i = 0; i < _auction.feeRecipients.length; i++) {
            uint256 fee = _calculateFee(_auction.highestBid, _auction.feePercentages[i]);
            IERC20Upgradeable(_auction.ERC20Token).transfer(_auction.feeRecipients[i], fee);
            feesPaid += fee;
        }
        // pay seller
        IERC20Upgradeable(_auction.ERC20Token).transfer(_auction.nftSeller, (_auction.highestBid - feesPaid));
    }

    function _maybeExtendAuctionEnd(uint256 _auctionId) internal {
        Auction memory auction = auctions[_auctionId];
        if (block.timestamp > auction.end - auction.bidExtendPeriod) {
            auction.end += auction.bidExtendPeriod;

            emit AuctionEndUpdated(_auctionId, auction.end);
        }
    }

    /*************************************************
     * INTERNAL READ METHODS                         *
     *************************************************/

    function _isAuctionOngoing(uint256 _auctionId)
        internal
        view
        returns (bool)
    {
        Auction memory auction = auctions[_auctionId];

        return (
            (block.timestamp >= auction.start && block.timestamp <= auction.end)
            && auction.status == AUCTION_STATUS.ACTIVE
        );
    }

    /*
     * Check if a bid has been made.
     */
    function _isABidMade(uint256 _auctionId)
        internal
        view
        returns (bool)
    {
        return auctions[_auctionId].highestBid > 0;
    }

    /*
     *if the minPrice is set by the seller, check that the highest bid meets or exceeds that price.
     */
    function _isMinimumBidMade(uint256 _auctionId)
        internal
        view
        returns (bool)
    {
        Auction memory auction = auctions[_auctionId];
        return auction.minPrice > 0 && (auction.highestBid >= auction.minPrice);
    }

    function _validateNewAuction(NewAuctionRequest memory _newAuction, address _seller)
        internal
        view
        isFeePercentagesLessThanMaximum(_newAuction.feePercentages)
    {
        require(_newAuction.amount > 0, "RarumNFTAuction: amount cannot be zero");
        require(_newAuction.minPrice > 0, "RarumNFTAuction: price cannot be zero");
        require(_newAuction.bidIncreasePercentage > 0, "RarumNFTAuction: bid increase percentage cannot be zero");
        require(_newAuction.start >= block.timestamp, "RarumNFTAuction: invalid start time");
        require(_newAuction.end >= _newAuction.start, "RarumNFTAuction: invalid end time");
        require(_newAuction.erc20Token != address(0), "RarumNFTAuction: invalid token address");
        require(_newAuction.feeRecipients.length == _newAuction.feePercentages.length, "RarumNFTAuction: recipients != percentages");
        require(
            !activeAuctionHashesByHolder[_seller].contains(_hashToken(_newAuction.nftContractAddress, _newAuction.tokenId)),
            "RarumNFTAuction: sender has an active auction for this token"
        );
    }

    function _hashToken(address _nftContractAddress, uint256 _tokenId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_nftContractAddress, _tokenId));
    }

    /*
     * Returns the percentage of the total bid (used to calculate fee payments)
     */
    function _calculateFee(uint256 _totalBid, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_totalBid * (_percentage)) / 10000;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155ReceiverUpgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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
interface IERC165Upgradeable {
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

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}