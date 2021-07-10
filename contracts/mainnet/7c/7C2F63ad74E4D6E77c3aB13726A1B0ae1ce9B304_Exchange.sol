// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Constants {
    bytes32 constant ROLE_OWNER = keccak256(bytes("ROLE_OWNER"));
    bytes32 constant ROLE_CREATOR = keccak256(bytes("ROLE_CREATOR"));
    bytes32 constant _DOMAIN_SEPARATOR = keccak256(abi.encode(
        keccak256("EIP712Domain(string name,string version)"),
        keccak256("LiveArt"),
        keccak256("1")
    ));
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./Structs.sol";
import "./IERC755.sol";
import "./Constants.sol";

contract Exchange is Initializable, Context {
    using AddressUpgradeable for address;

    struct TokenByNowDeal {
        uint256 tokenId;
        uint256 price;
        Structs.Policy[] rights;
    }
    struct TokenAuction {
        uint256 id;
        uint256 tokenId;

        uint256 highestBid;
        address highestBidder;

        uint256 initialPrice;
        Structs.Policy[] rights;
        uint256 endTime;
        uint256 maxDuration;
    }

    event TokenRightsListed(
        uint256 tokenId,
        uint256 price,
        Structs.Policy[] rights,
        uint256 timestamp
    );
    event TokenRightsSold(
        uint256 tokenId,
        uint256 price,
        Structs.Policy[] rights,
        address from,
        address to,
        uint256 timestamp
    );
    event TokenAuctionStarted(
        uint256 id,
        uint256 tokenId,
        uint256 initialPrice,
        Structs.Policy[] rights,
        uint256 endTime,
        uint256 timestamp
    );
    event BidPlaced(
        uint256 tokenId,
        uint256 auctionId,
        address bidder,
        uint256 price,
        uint256 timestamp
    );

    IERC755 private _tokenContract;
    address private _owner;
    uint256 private _marketFee;
    address private _marketWallet;

    mapping(uint256 => TokenByNowDeal[]) private _buyNowTokenDeals;

    mapping(uint256 => TokenAuction[]) private _tokenAuctions;

    mapping(uint256 => bool) private _signedTimestamp;

    uint256 private constant _MAX_AUCTION_DURATION = 100 days;
    uint256 private constant _EXTENSION_DURATION = 15 minutes;

    mapping(uint256 => uint256) private _auctionIdByToken;

    function initialize(
        IERC755 tokenContract,
        uint256 marketFee,
        address marketWallet
    ) external initializer {
        require(
            marketWallet != address(0),
            "invalid market address"
        );
        require(
            address(tokenContract) != address(0),
            "invalid token contract"
        );

        _tokenContract = tokenContract;
        _owner = _msgSender();

        _marketFee = marketFee;
        _marketWallet = marketWallet;
    }

    modifier onlyOwner() {
        require(
            _owner == _msgSender(),
            "caller is not the owner"
        );
        _;
    }

    function _requireMessageSigned(
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) private {
        require(
            !_signedTimestamp[timestamp],
            "timestamp already signed"
        );
        require(
            _msgSender() == ecrecover(
            keccak256(abi.encodePacked(
                "\x19\x01",
                Constants._DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    keccak256("BasicOperation(uint256 timestamp)"),
                    timestamp
                ))
            )),
            v,
            r,
            s
        ),
            "invalid sig"
        );

        _signedTimestamp[timestamp] = true;
    }

    function _requireCanSellTokenRights(
        Structs.Policy[] memory sellRights,
        uint256 tokenId,
        address seller
    ) internal view {
        if (_msgSender() != seller) {
            require(
                _tokenContract.isApprovedForAll(seller, _msgSender()) ||
                _tokenContract.getApproved(
                    seller,
                    tokenId
                ) == _msgSender(),
                "not approved nor operator"
            );
        }

        require(
            _tokenContract.rightsOwned(
                seller,
                sellRights,
                tokenId
            ),
            "rights not owned by seller"
        );
    }

    function getTokenBuyNowDeals(
        uint256 tokenId
    ) external view returns (TokenByNowDeal[] memory) {
        return _buyNowTokenDeals[tokenId];
    }

    function _requireTokenIsApprovedForExchange(
        address seller,
        uint256 tokenId
    ) internal view {
        require(
            _tokenContract.getApproved(seller, tokenId) == address(this),
            "exchange is not approved for the token by seller"
        );
    }

    function setBuyNowPrice(
        Structs.Policy[] memory sellRights,
        uint256 tokenId,
        address seller,
        uint256 price,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external {
        _requireMessageSigned(r, s, v, timestamp);
        _requireCanSellTokenRights(sellRights, tokenId, seller);
        require(price > 0, "price <= 0");

        _requireTokenIsApprovedForExchange(seller, tokenId);

        TokenByNowDeal storage deal = _buyNowTokenDeals[tokenId].push();
        deal.tokenId = tokenId;
        deal.price = price;
        for (uint256 i = 0; i < sellRights.length; i++) {
            _requireRightIsNotOnSale(tokenId, sellRights[i]);
            deal.rights.push(sellRights[i]);
        }
        require(
            _buyNowTokenDeals[tokenId][_buyNowTokenDeals[tokenId].length - 1].rights.length > 0,
            "no rights added to the deal"
        );

        emit TokenRightsListed(
            tokenId,
            price,
            sellRights,
            block.timestamp
        );
    }

    function _requireRightIsNotOnSale(
        uint256 tokenId,
        Structs.Policy memory right
    ) internal view {
        for (uint256 i = 0; i < _buyNowTokenDeals[tokenId].length; i++) {
            Structs.Policy[] memory dealRights = _buyNowTokenDeals[tokenId][i].rights;
            for (uint256 j = 0; j < dealRights.length; j++) {
                if (
                    compareStrings(dealRights[j].action, right.action) &&
                    dealRights[j].permission.wallet == right.permission.wallet
                ) {
                    revert("right is already listed for sale");
                }
            }
        }
    }

    function _rightsEqual(
        Structs.Policy[] memory bundle1,
        Structs.Policy[] memory bundle2
    ) internal pure returns (bool) {
        if (bundle1.length != bundle2.length) {
            return false;
        }

        for (uint256 i = 0; i < bundle1.length; i++) {
            bool foundRight = false;
            for (uint256 j = 0; j < bundle2.length; j++) {
                if (
                    compareStrings(bundle1[i].action, bundle2[j].action) &&
                    bundle1[i].permission.wallet == bundle2[j].permission.wallet
                ) {
                    foundRight = true;
                }
            }
            if (!foundRight) {
                return false;
            }
        }
        return true;
    }

    function removeBuyNowPrice(
        uint256 tokenId,
        uint256 price,
        Structs.Policy[] memory sellRights,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external {
        _requireMessageSigned(r, s, v, timestamp);
        _removeBuyNowPrice(
            tokenId,
            price,
            sellRights
        );
    }

    function _removeBuyNowPrice(
        uint256 tokenId,
        uint256 price,
        Structs.Policy[] memory sellRights
    ) private {
        for (uint256 i = 0; i < _buyNowTokenDeals[tokenId].length; i++) {
            if (_buyNowTokenDeals[tokenId][i].price == price) {
                if (_rightsEqual(_buyNowTokenDeals[tokenId][i].rights, sellRights)) {
                    if (i == _buyNowTokenDeals[tokenId].length - 1) {
                        _buyNowTokenDeals[tokenId].pop();
                    } else {
                        for (uint256 j = i; j < _buyNowTokenDeals[tokenId].length - 1; j++) {
                            _buyNowTokenDeals[tokenId][j] = _buyNowTokenDeals[tokenId][j + 1];
                        }
                        _buyNowTokenDeals[tokenId].pop();
                    }
                }
            }
        }
    }

    function _findTokenDealRights(
        uint256 tokenId,
        Structs.Policy[] memory sellRights,
        uint256 price
    ) internal view returns (Structs.Policy[] memory) {
        for (uint256 i = 0; i < _buyNowTokenDeals[tokenId].length; i++) {
            if (_buyNowTokenDeals[tokenId][i].price == price) {
                if (
                    _rightsEqual(
                        _buyNowTokenDeals[tokenId][i].rights,
                        sellRights
                    )
                ) {
                    return _buyNowTokenDeals[tokenId][i].rights;
                }
            }
        }
        Structs.Policy[] memory emptyRights = new Structs.Policy[](0);
        return emptyRights;
    }

    function _calculatePercentage(
        uint256 number,
        uint256 percentage
    ) private pure returns (uint256) {
        // https://ethereum.stackexchange.com/a/55702
        // https://www.investopedia.com/terms/b/basispoint.asp
        return number * percentage / 10000;
    }

    function _findAuctionByRights(
        uint256 tokenId,
        Structs.Policy[] memory sellRights
    ) internal view returns (TokenAuction memory) {
        for (uint256 i = 0; i < _tokenAuctions[tokenId].length; i++) {
            if (
                _rightsEqual(
                    _tokenAuctions[tokenId][i].rights,
                    sellRights
                )
            ) {
                return _tokenAuctions[tokenId][i];
            }
        }
        return TokenAuction(0, 0, 0, address(0), 0, new Structs.Policy[](0), 0, 0);
    }

    function _payMarketFee(
        uint256 price
    ) internal returns (uint256) {
        uint256 marketFee = _calculatePercentage(price, _marketFee);
        AddressUpgradeable.sendValue(
            payable(_marketWallet),
            marketFee
        );

        return price - marketFee;
    }

    function buyNow(
        uint256 tokenId,
        Structs.Policy[] memory sellRights,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external payable {
        _requireMessageSigned(r, s, v, timestamp);
        uint256 price = msg.value;

        Structs.Policy[] memory buyRights = _findTokenDealRights(
            tokenId,
            sellRights,
            price
        );
        require(
            buyRights.length > 0,
            "no deals for this price and rights"
        );

        uint256 priceAfterMarketFee = _payMarketFee(price);
        _tokenContract.payForTransfer{value: priceAfterMarketFee}(
            buyRights[0].permission.wallet,
            _msgSender(),
            tokenId,
            buyRights
        );
        _tokenContract.safeTransferFrom(
            buyRights[0].permission.wallet,
            _msgSender(),
            tokenId,
            buyRights,
            ""
        );

        _removeBuyNowPrice(tokenId, price, buyRights);

        TokenAuction memory auctionWithRights = _findAuctionByRights(
            tokenId,
            buyRights
        );
        if (auctionWithRights.id > 0) {
            _cancelAuction(
                tokenId,
                auctionWithRights.id
            );
        }

        emit TokenRightsSold(
            tokenId,
            price,
            buyRights,
            buyRights[0].permission.wallet,
            _msgSender(),
            block.timestamp
        );
    }

    function _requireRightIsNotOnAuction(
        uint256 tokenId,
        Structs.Policy memory right
    ) internal view {
        for (uint256 i = 0; i < _tokenAuctions[tokenId].length; i++) {
            Structs.Policy[] memory auctionRights = _tokenAuctions[tokenId][i].rights;
            for (uint256 j = 0; j < auctionRights.length; j++) {
                if (
                    compareStrings(auctionRights[j].action, right.action) &&
                    auctionRights[j].permission.wallet == right.permission.wallet
                ) {
                    revert("right is already on another auction");
                }
            }
        }
    }

    function getTokenAuctions(
        uint256 tokenId
    ) external view returns (TokenAuction[] memory)  {
        return _tokenAuctions[tokenId];
    }

    function startAuction(
        Structs.Policy[] memory sellRights,
        uint256 startPrice,
        uint256 auctionEndTime,
        uint256 tokenId,
        address seller,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external {
        _requireMessageSigned(r, s, v, timestamp);
        _requireCanSellTokenRights(sellRights, tokenId, seller);
        require(startPrice > 0, "initial price should be positive");

        _requireTokenIsApprovedForExchange(seller, tokenId);
        require(
            _numDigits(block.timestamp) == _numDigits(auctionEndTime),
            "incorrect timestamp"
        );
        require(block.timestamp < auctionEndTime, "can't start auction in past");

        TokenAuction storage auction = _tokenAuctions[tokenId].push();
        auction.id = ++_auctionIdByToken[tokenId];
        auction.tokenId = tokenId;
        auction.initialPrice = startPrice;
        auction.endTime = auctionEndTime;
        auction.maxDuration = block.timestamp + _MAX_AUCTION_DURATION;
        for (uint256 i = 0; i < sellRights.length; i++) {
            _requireRightIsNotOnAuction(tokenId, sellRights[i]);
            auction.rights.push(sellRights[i]);
        }

        emit TokenAuctionStarted(
            auction.id,
            auction.tokenId,
            startPrice,
            sellRights,
            auctionEndTime,
            block.timestamp
        );
    }

    function _deleteAuction(
        uint256 tokenId,
        uint256 auctionIndex
    ) internal {
        uint256 i = auctionIndex;

        if (i == _tokenAuctions[tokenId].length - 1) {
            _tokenAuctions[tokenId].pop();
        } else {
            for (uint256 j = i; j < _tokenAuctions[tokenId].length - 1; j++) {
                _tokenAuctions[tokenId][j] = _tokenAuctions[tokenId][j + 1];
            }
            _tokenAuctions[tokenId].pop();
        }
    }

    function cancelAuction(
        uint256 tokenId,
        uint256 auctionId,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external {
        _requireMessageSigned(r, s, v, timestamp);
        _cancelAuction(
            tokenId,
            auctionId
        );
    }

    function _cancelAuction(
        uint256 tokenId,
        uint256 auctionId
    ) private {
        for (uint256 i = 0; i < _tokenAuctions[tokenId].length; i++) {
            if (_tokenAuctions[tokenId][i].id == auctionId) {
                TokenAuction memory auction = _tokenAuctions[tokenId][i];
                if (
                    auction.highestBid > 0 &&
                    auction.highestBidder != address(0)
                ) {
                    // withdraw bid
                    AddressUpgradeable.sendValue(
                        payable(auction.highestBidder),
                        auction.highestBid
                    );
                }

                _deleteAuction(tokenId, i);
            }
        }
    }

    function _findTokenDealByRights(
        uint256 tokenId,
        Structs.Policy[] memory sellRights
    ) internal view returns (TokenByNowDeal memory) {
        for (uint256 i = 0; i < _buyNowTokenDeals[tokenId].length; i++) {
            if (
                _rightsEqual(
                    _buyNowTokenDeals[tokenId][i].rights,
                    sellRights
                )
            ) {
                return _buyNowTokenDeals[tokenId][i];
            }
        }
        return TokenByNowDeal(0, 0, new Structs.Policy[](0));
    }

    function bid(
        uint256 tokenId,
        uint256 auctionId,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external payable {
        _requireMessageSigned(r, s, v, timestamp);
        uint256 bidPrice = msg.value;
        require(bidPrice > 0, "bid should be positive");

        bool auctionExists = false;
        for (uint256 i = 0; i < _tokenAuctions[tokenId].length; i++) {
            if (_tokenAuctions[tokenId][i].id == auctionId) {
                TokenAuction memory auction = _tokenAuctions[tokenId][i];

                require(
                    block.timestamp < auction.endTime,
                    "can't bid on closed auction"
                );
                require(
                    bidPrice > auction.highestBid &&
                    bidPrice > auction.initialPrice,
                    "bid should be higher than initial price & highest bid"
                );

                if (auction.highestBid > 0) {
                    // return previous bid
                    AddressUpgradeable.sendValue(
                        payable(auction.highestBidder),
                        auction.highestBid
                    );
                }

                TokenByNowDeal memory dealWithRights = _findTokenDealByRights(
                    tokenId,
                    auction.rights
                );
                if (
                    dealWithRights.price > 0 &&
                    bidPrice >= _calculatePercentage(dealWithRights.price, 50 * 100)
                ) {
                    _removeBuyNowPrice(
                        tokenId,
                        dealWithRights.price,
                        dealWithRights.rights
                    );
                }

                _tokenAuctions[tokenId][i].highestBid = bidPrice;
                _tokenAuctions[tokenId][i].highestBidder = _msgSender();

                if ((auction.endTime - block.timestamp) <= _EXTENSION_DURATION) {
                    if ((auction.endTime + _EXTENSION_DURATION) < auction.maxDuration) {
                        _tokenAuctions[tokenId][i].endTime += _EXTENSION_DURATION;
                    }
                }

                emit BidPlaced(
                    tokenId,
                    auction.id,
                    _msgSender(),
                    bidPrice,
                    block.timestamp
                );

                auctionExists = true;
            }
        }
        require(auctionExists, "no auction to bid");
    }

    function _numDigits(uint256 number) internal pure returns (uint8) {
        uint8 digits = 0;
        while (number != 0) {
            number /= 10;
            digits++;
        }
        return digits;
    }

    function endAuction(
        uint256 tokenId,
        uint256 auctionId
    ) external {
        bool auctionExists = false;
        for (uint256 i = 0; i < _tokenAuctions[tokenId].length; i++) {
            if (_tokenAuctions[tokenId][i].id == auctionId) {
                TokenAuction memory auction = _tokenAuctions[tokenId][i];

                require(
                    block.timestamp >= auction.endTime,
                    "auction is not ended"
                );

                if (auction.highestBid > 0) {
                    TokenByNowDeal memory dealWithRights = _findTokenDealByRights(
                        tokenId,
                        auction.rights
                    );
                    if (dealWithRights.rights.length > 0) {
                        _removeBuyNowPrice(
                            tokenId,
                            dealWithRights.price,
                            dealWithRights.rights
                        );
                    }

                    uint256 priceAfterMarketFee = _payMarketFee(auction.highestBid);
                    _tokenContract.payForTransfer{value: priceAfterMarketFee}(
                        auction.rights[0].permission.wallet,
                        auction.highestBidder,
                        tokenId,
                        auction.rights
                    );
                    _tokenContract.safeTransferFrom(
                        auction.rights[0].permission.wallet,
                        auction.highestBidder,
                        tokenId,
                        auction.rights,
                        ""
                    );

                    emit TokenRightsSold(
                        tokenId,
                        auction.highestBid,
                        auction.rights,
                        auction.rights[0].permission.wallet,
                        auction.highestBidder,
                        block.timestamp
                    );
                }

                _deleteAuction(tokenId, i);

                auctionExists = true;
            }
        }
        require(auctionExists, "no auction to end");
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function version() external virtual pure returns (uint256) {
        return 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./Structs.sol";

interface IERC755 is IERC165 {
    event PaymentReceived(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        Structs.Policy[] transferRights,
        uint256 timestamp
    );
    event ArtworkCreated(
        uint256 tokenId,
        Structs.Policy[] creationRights,
        string tokenURI,
        uint256 editionOf,
        uint256 maxTokenSupply,
        uint256 timestamp
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        Structs.Policy[] rights,
        uint256 timestamp
    );

    event Approval(
        address indexed approver,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed approver,
        address indexed operator,
        bool approved
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies,
        bytes calldata data
    ) external payable;

    function payForTransfer(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) external payable;

    function approve(
        address to,
        uint256 tokenId
    ) external payable;

    function getApproved(
        address from,
        uint256 tokenId
    ) external view returns (address);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function editions(uint256 tokenId) external view returns (uint256[] memory);

    function totalSupply() external view returns (uint256);

    function tokenSupply(uint256 tokenId) external view returns (uint256);

    function rights(uint256 tokenId) external view returns (Structs.Policy[] memory);

    function supportedActions() external view returns (string[] memory);

    function rightsOwned(
        address owner,
        Structs.Policy[] memory policies,
        uint256 tokenId
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Structs {
    struct RoyaltyReceiver {
        address payable wallet;
        string role;
        uint256 percentage;
        uint256 resalePercentage;
        uint256 CAPPS;
        uint256 fixedCut;
    }

    struct Party {
        string role;
        address wallet;
    }

    struct Policy {
        string action;
        uint256 target;
        Party permission;
    }

    struct SupportedAction {
        string action;
        string group;
    }

    struct BasicOperation {
        string operation;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}