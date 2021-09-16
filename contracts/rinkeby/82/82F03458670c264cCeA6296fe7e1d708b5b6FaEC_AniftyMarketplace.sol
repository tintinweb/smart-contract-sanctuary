pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./libraries/SafeERC20.sol";
import "./libraries/Orders.sol";
import "./libraries/Address.sol";
import "./libraries/ERC1155Holder.sol";
import "./libraries/Pausable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC1271.sol";
import "./interfaces/IBaseExchange.sol";
import "./interfaces/IERC1155.sol";

contract AniftyMarketplace is
    ReentrancyGuard,
    IBaseExchange,
    ERC1155Holder,
    Pausable
{
    using SafeERC20 for IERC20;
    using Orders for Orders.MintAsk;
    using Orders for Orders.Bid;
    using Orders for Orders.Ask;
    using Orders for Orders.Commission;
    using Orders for Orders.AskType;
    using Orders for Orders.SecondaryRoyalty;
    using Orders for Orders.SecondaryRoyaltyInfo;
    using Orders for Orders.Offer;

    struct RoyaltyInfo {
        address payable[] recipients;
        uint16[] royalties;
    }

    struct TokenMetadata {
        string name;
        string creatorName;
        string description;
        string mediaUri;
    }

    address public AniftyERC1155;
    address public adminSigner;
    address payable public commissionWallet;

    bytes32 internal immutable _DOMAIN_SEPARATOR;

    mapping(bytes32 => bool) public isCancelled;
    mapping(address => bool) public supportedTokens;
    // address => is owner
    mapping(address => bool) public owners;
    // Purchase hash => tokenId
    mapping(bytes32 => uint256) public mintedHash;
    mapping(bytes32 => uint256) public amountFilled;

    uint256 public maxRoyalty;
    uint16 constant PRECISION = 10000;

    constructor(
        address[] memory _supportTokens,
        address _AniftyERC1155,
        address payable _commissionWallet,
        uint256 _maxRoyalty
    ) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("AniftyMarketplace"),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        AniftyERC1155 = _AniftyERC1155;
        maxRoyalty = _maxRoyalty;
        commissionWallet = _commissionWallet;
        adminSigner = msg.sender;
        for (uint8 i = 0; i < _supportTokens.length; i++) {
            supportedTokens[_supportTokens[i]] = true;
        }
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _DOMAIN_SEPARATOR;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        IERC1155(AniftyERC1155).safeTransferFrom(from, to, tokenId, amount, "");
    }

    function secondaryRoyaltyUpdate(
        Orders.SecondaryRoyalty memory prevSecondaryRoyalty,
        Orders.SecondaryRoyaltyInfo memory secondaryRoyalty
    ) external nonReentrant {
        require(
            prevSecondaryRoyalty.owner == msg.sender ||
                owners[msg.sender] ||
                adminSigner == msg.sender,
            "ANIFTY: FORBIDDEN"
        );
        require(
            prevSecondaryRoyalty.tokenId == secondaryRoyalty.tokenId,
            "ANIFTY: INVALID_TOKENID"
        );
        _validateRoyalty(
            secondaryRoyalty.recipients,
            secondaryRoyalty.royalties
        );
        bytes32 prevHash = prevSecondaryRoyalty.hash();
        isCancelled[prevHash] = true;

        emit SecondaryRoyaltyUpdate(prevHash, secondaryRoyalty);
    }

    function offerCancel(Orders.Offer memory offer) external nonReentrant {
        require(offer.signer == msg.sender, "ANIFTY: FORBIDDEN");
        bytes32 hash = offer.hash();
        isCancelled[hash] = true;

        emit OfferCancel(hash);
    }

    function primaryCancel(Orders.MintAsk memory askOrder)
        external
        nonReentrant
    {
        require(askOrder.signer == msg.sender, "ANIFTY: FORBIDDEN");
        bytes32 hash = askOrder.hash();
        isCancelled[hash] = true;
        if (mintedHash[hash] > 0) {
            // Burn all remaining tokens
            IERC1155(AniftyERC1155).burn(
                mintedHash[hash],
                IERC1155(AniftyERC1155).balanceOf(
                    address(this),
                    mintedHash[hash]
                )
            );
        }

        emit PrimaryCancel(hash);
    }

    function secondaryCancel(Orders.Ask memory askOrder) external nonReentrant {
        require(askOrder.signer == msg.sender, "ANIFTY: FORBIDDEN");
        bytes32 hash = askOrder.hash();
        isCancelled[hash] = true;

        emit SecondaryCancel(hash);
    }

    function askUpdate(
        Orders.MintAsk memory prevAskOrder,
        Orders.MintAsk memory askOrder
    ) external nonReentrant {
        bytes32 prevHash = prevAskOrder.hash();
        bytes32 hash = askOrder.hash();
        require(askOrder.signer == prevAskOrder.signer, "ANIFTY: SIGNER");
        require(askOrder.askType == prevAskOrder.askType, "ANIFTY: TYPE");
        require(!isCancelled[prevHash], "ANIFTY: CANCELLED");
        require(askOrder.amount > amountFilled[hash], "ANIFTY: AMOUNT");
        _verify(hash, askOrder.signer, askOrder.v, askOrder.r, askOrder.s);
        _validate(askOrder, hash);
        isCancelled[prevHash] = true;
        if (mintedHash[prevHash] > 0) {
            require(askOrder.amount <= prevAskOrder.amount, "ANIFTY: AMOUNT");
            mintedHash[hash] = mintedHash[prevHash];
            amountFilled[hash] = amountFilled[prevHash];
            if (askOrder.amount < prevAskOrder.amount) {
                IERC1155(AniftyERC1155).burn(
                    mintedHash[hash],
                    prevAskOrder.amount - askOrder.amount
                );
            }
        }
        emit Update(prevHash, hash, askOrder, mintedHash[prevHash]);
    }

    function primaryBuy(
        Orders.MintAsk memory askOrder,
        Orders.Commission memory commission,
        TokenMetadata memory token,
        uint256 amount
    ) external payable nonReentrant whenNotPaused {
        bytes32 askHash = askOrder.hash();
        uint256 _amountFilled = amountFilled[askHash];
        require(amount > 0, "ANIFTY: INVALID_AMOUNT");
        require(_amountFilled + amount <= askOrder.amount, "ANIFTY: SOLD_OUT");
        require(askHash == commission.askHash, "ANIFTY: UNMATCHED_HASH");
        require(
            askOrder.askType == Orders.AskType.PrimarySale,
            "ANIFTY: ASKTYPE"
        );
        _validate(askOrder, askHash);
        _verify(askHash, askOrder.signer, askOrder.v, askOrder.r, askOrder.s);
        _verify(
            commission.hash(),
            adminSigner,
            commission.v,
            commission.r,
            commission.s
        );
        amountFilled[askHash] = _amountFilled + amount;
        uint256 tokenId = mintedHash[askHash];
        if (tokenId == 0) {
            tokenId = IERC1155(AniftyERC1155).whitelistMint(
                askOrder.amount,
                token.name,
                token.creatorName,
                token.description,
                token.mediaUri,
                ""
            );
            mintedHash[askHash] = tokenId;
        }
        _transferFeesAndFunds(
            askOrder.currency,
            msg.sender,
            askOrder.signer,
            askOrder.price * amount,
            commission.amount,
            RoyaltyInfo({
                recipients: askOrder.royalty.recipients,
                royalties: askOrder.royalty.royalties
            })
        );
        _transfer(address(this), msg.sender, tokenId, amount);
        emit PrimaryBuy(
            askHash,
            msg.sender,
            askOrder.signer,
            amount,
            askOrder.price * amount,
            amountFilled[askHash],
            askOrder.amount
        );
    }

    function primaryClaim(
        Orders.MintAsk memory askOrder,
        Orders.Bid memory bidOrder,
        Orders.Commission memory commission,
        TokenMetadata memory token
    ) external nonReentrant whenNotPaused {
        bytes32 askHash = askOrder.hash();
        bytes32 bidHash = bidOrder.hash();
        require(amountFilled[askHash] == 0, "ANIFTY: SOLD_OUT");
        require(askHash == bidOrder.askHash, "ANIFTY: UNMATCHED_HASH");
        require(askHash == commission.askHash, "ANIFTY: UNMATCHED_HASH");
        require(askOrder.signer == msg.sender, "ANIFTY: CALLER");
        require(bidOrder.price >= askOrder.price, "ANIFTY: PRICE");
        require(
            askOrder.askType == Orders.AskType.PrimaryAuction,
            "ANIFTY: ASKTYPE"
        );
        _validate(askOrder, askHash);
        _verify(askHash, askOrder.signer, askOrder.v, askOrder.r, askOrder.s);
        _verify(bidHash, bidOrder.signer, bidOrder.v, bidOrder.r, bidOrder.s);
        _verify(
            commission.hash(),
            adminSigner,
            commission.v,
            commission.r,
            commission.s
        );
        amountFilled[askHash] = askOrder.amount;
        uint256 tokenId = mintedHash[askHash];
        if (tokenId == 0) {
            tokenId = IERC1155(AniftyERC1155).whitelistMint(
                askOrder.amount,
                token.name,
                token.creatorName,
                token.description,
                token.mediaUri,
                ""
            );
            mintedHash[askHash] = tokenId;
        }
        _transferFeesAndFunds(
            askOrder.currency,
            bidOrder.signer,
            askOrder.signer,
            bidOrder.price,
            commission.amount,
            RoyaltyInfo({
                recipients: askOrder.royalty.recipients,
                royalties: askOrder.royalty.royalties
            })
        );
        _transfer(address(this), bidOrder.signer, tokenId, askOrder.amount);
        emit PrimaryClaim(
            askHash,
            bidHash,
            bidOrder.signer,
            msg.sender,
            askOrder.amount,
            bidOrder.price
        );
    }

    function secondaryBuy(
        Orders.Ask memory askOrder,
        Orders.Commission memory commission,
        Orders.SecondaryRoyalty memory secondaryRoyalty,
        uint256 amount
    ) external payable nonReentrant whenNotPaused {
        bytes32 askHash = askOrder.hash();
        bytes32 royaltyHash = secondaryRoyalty.hash();
        uint256 _amountFilled = amountFilled[askHash];
        require(amount > 0, "ANIFTY: AMOUNT");
        require(_amountFilled + amount <= askOrder.amount, "ANIFTY: SOLD_OUT");
        require(askHash == commission.askHash, "ANIFTY: UNMATCHED_HASH");
        require(askOrder.askType == Orders.AskType.Sale, "ANIFTY: ASKTYPE");
        _validateSecondary(askOrder, secondaryRoyalty, askHash, royaltyHash);
        _verify(askHash, askOrder.signer, askOrder.v, askOrder.r, askOrder.s);
        _verify(
            commission.hash(),
            adminSigner,
            commission.v,
            commission.r,
            commission.s
        );
        _verify(
            royaltyHash,
            adminSigner,
            secondaryRoyalty.v,
            secondaryRoyalty.r,
            secondaryRoyalty.s
        );
        amountFilled[askHash] = _amountFilled + amount;
        _transferFeesAndFunds(
            askOrder.currency,
            msg.sender,
            askOrder.signer,
            askOrder.price * amount,
            commission.amount,
            RoyaltyInfo({
                recipients: secondaryRoyalty.recipients,
                royalties: secondaryRoyalty.royalties
            })
        );
        _transfer(askOrder.signer, msg.sender, askOrder.tokenId, amount);
        emit SecondaryBuy(
            askHash,
            msg.sender,
            askOrder.signer,
            amount,
            askOrder.price * amount,
            amountFilled[askHash],
            askOrder.amount
        );
    }

    function secondaryClaim(
        Orders.Ask memory askOrder,
        Orders.Bid memory bidOrder,
        Orders.Commission memory commission,
        Orders.SecondaryRoyalty memory secondaryRoyalty
    ) external nonReentrant whenNotPaused {
        bytes32 askHash = askOrder.hash();
        bytes32 bidHash = bidOrder.hash();
        bytes32 royaltyHash = secondaryRoyalty.hash();
        require(amountFilled[askHash] == 0, "ANIFTY: SOLD_OUT");
        require(askHash == bidOrder.askHash, "ANIFTY: UNMATCHED_HASH");
        require(askHash == commission.askHash, "ANIFTY: UNMATCHED_HASH");
        require(askOrder.signer == msg.sender, "ANIFTY: CALLER");
        require(bidOrder.price >= askOrder.price, "ANIFTY: PRICE");
        require(askOrder.askType == Orders.AskType.Auction, "ANIFTY: ASKTYPE");
        _validateSecondary(askOrder, secondaryRoyalty, askHash, royaltyHash);
        _verify(askHash, askOrder.signer, askOrder.v, askOrder.r, askOrder.s);
        _verify(bidHash, bidOrder.signer, bidOrder.v, bidOrder.r, bidOrder.s);
        _verify(
            commission.hash(),
            adminSigner,
            commission.v,
            commission.r,
            commission.s
        );
        _verify(
            royaltyHash,
            adminSigner,
            secondaryRoyalty.v,
            secondaryRoyalty.r,
            secondaryRoyalty.s
        );
        amountFilled[askHash] = askOrder.amount;
        _transferFeesAndFunds(
            askOrder.currency,
            bidOrder.signer,
            askOrder.signer,
            bidOrder.price,
            commission.amount,
            RoyaltyInfo({
                recipients: secondaryRoyalty.recipients,
                royalties: secondaryRoyalty.royalties
            })
        );
        _transfer(
            askOrder.signer,
            bidOrder.signer,
            askOrder.tokenId,
            askOrder.amount
        );
        emit SecondaryClaim(
            askHash,
            bidHash,
            bidOrder.signer,
            msg.sender,
            askOrder.amount,
            bidOrder.price
        );
    }

    function offerClaim(
        Orders.Offer memory offer,
        Orders.Commission memory commission,
        Orders.SecondaryRoyalty memory secondaryRoyalty
    ) external nonReentrant whenNotPaused {
        bytes32 offerHash = offer.hash();
        bytes32 royaltyHash = secondaryRoyalty.hash();
        require(offerHash == commission.askHash, "ANIFTY: UNMATCHED_HASH");
        _validateOffer(offer, secondaryRoyalty, offerHash, royaltyHash);
        _verify(offerHash, offer.signer, offer.v, offer.r, offer.s);
        _verify(
            commission.hash(),
            adminSigner,
            commission.v,
            commission.r,
            commission.s
        );
        _verify(
            royaltyHash,
            adminSigner,
            secondaryRoyalty.v,
            secondaryRoyalty.r,
            secondaryRoyalty.s
        );
        _transferFeesAndFunds(
            offer.currency,
            offer.signer,
            payable(msg.sender),
            offer.price,
            commission.amount,
            RoyaltyInfo({
                recipients: secondaryRoyalty.recipients,
                royalties: secondaryRoyalty.royalties
            })
        );
        _transfer(msg.sender, offer.signer, offer.tokenId, offer.amount);
        emit OfferClaim(offerHash, msg.sender);
    }

    function _validateOffer(
        Orders.Offer memory offer,
        Orders.SecondaryRoyalty memory secondaryRoyalty,
        bytes32 offerHash,
        bytes32 royaltyHash
    ) internal view {
        require(!isCancelled[offerHash], "ANIFTY: OFFER_CANCELLED");
        require(!isCancelled[royaltyHash], "ANIFTY: ROYALTY_CANCELLED");
        require(offer.tokenId == secondaryRoyalty.tokenId, "ANIFTY: TOKENID");
        _validateRoyalty(
            secondaryRoyalty.recipients,
            secondaryRoyalty.royalties
        );
        require(offer.signer != address(0), "ANIFTY: MAKER");
        require(offer.amount > 0, "ANIFTY: AMOUNT");
        require(supportedTokens[offer.currency], "ANIFTY: CURRENCY");
    }

    function _validateSecondary(
        Orders.Ask memory askOrder,
        Orders.SecondaryRoyalty memory secondaryRoyalty,
        bytes32 askHash,
        bytes32 royaltyHash
    ) internal view {
        require(!isCancelled[askHash], "ANIFTY: CANCELLED");
        require(!isCancelled[royaltyHash], "ANIFTY: ROYALTY_CANCELLED");
        require(
            askOrder.tokenId == secondaryRoyalty.tokenId,
            "ANIFTY: TOKENID"
        );
        _validateRoyalty(
            secondaryRoyalty.recipients,
            secondaryRoyalty.royalties
        );
        require(askOrder.signer != address(0), "ANIFTY: MAKER");
        require(askOrder.amount > 0, "ANIFTY: AMOUNT");
        require(supportedTokens[askOrder.currency], "ANIFTY: CURRENCY");
    }

    function _validate(Orders.MintAsk memory askOrder, bytes32 askHash)
        internal
        view
    {
        require(!isCancelled[askHash], "ANIFTY: CANCELLED");
        require(askOrder.amount > 0, "ANIFTY: AMOUNT");
        require(supportedTokens[askOrder.currency], "ANIFTY: CURRENCY");
        _validateRoyalty(
            askOrder.royalty.recipients,
            askOrder.royalty.royalties
        );
    }

    function _validateRoyalty(
        address payable[] memory recipients,
        uint16[] memory royalties
    ) internal view {
        require(recipients.length == royalties.length, "ANIFTY: RECIPIENTS");
        uint256 totalRoyalty = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            totalRoyalty = totalRoyalty + royalties[i];
        }
        require(totalRoyalty <= maxRoyalty, "ANIFTY: ROYALTY");
    }

    function _verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hash)
        );
        if (Address.isContract(signer)) {
            require(
                IERC1271(signer).isValidSignature(
                    digest,
                    abi.encodePacked(r, s, v)
                ) == 0x1626ba7e,
                "ANIFTY: UNAUTHORIZED"
            );
        } else {
            require(
                ecrecover(digest, v, r, s) == signer,
                "ANIFTY: UNAUTHORIZED"
            );
        }
    }

    function _transferFeesAndFunds(
        address currency,
        address from,
        address payable to,
        uint256 value,
        uint16 commission,
        RoyaltyInfo memory royaltyInfo
    ) internal {
        bool isEth = currency == address(0);
        if (isEth) {
            require(msg.value == value, "ANIFTY: PAYMENT");
        }
        uint256 remainder = value;
        {
            uint256 commissionFeeAmount = (value * commission) / PRECISION;
            if (isEth) {
                (bool sent, ) = commissionWallet.call{
                    value: commissionFeeAmount
                }("");
                require(sent, "Failed to send commission");
            } else {
                IERC20(currency).transferFrom(
                    from,
                    commissionWallet,
                    commissionFeeAmount
                );
            }
            remainder -= commissionFeeAmount;
        }
        {
            uint256 royaltyFeeAmount;
            for (uint256 i = 0; i < royaltyInfo.recipients.length; i++) {
                royaltyFeeAmount =
                    (value * royaltyInfo.royalties[i]) /
                    PRECISION;
                if (isEth) {
                    (bool sent, ) = royaltyInfo.recipients[i].call{
                        value: royaltyFeeAmount
                    }("");
                    require(sent, "Failed to send royalty");
                } else {
                    IERC20(currency).transferFrom(
                        from,
                        royaltyInfo.recipients[i],
                        royaltyFeeAmount
                    );
                }
                remainder -= royaltyFeeAmount;
            }
        }
        if (isEth) {
            (bool sent, ) = to.call{value: remainder}("");
            require(sent, "Failed to send remainder");
        } else {
            IERC20(currency).transferFrom(from, to, remainder);
        }
    }

    function setSupportedTokens(address[] memory _supportTokens, bool _set)
        external
    {
        require(
            adminSigner == msg.sender || owners[msg.sender],
            "ANIFTY: CALLER"
        );
        for (uint8 i = 0; i < _supportTokens.length; i++) {
            supportedTokens[_supportTokens[i]] = _set;
        }
    }

    function setCommissionWallet(address payable _commissionWallet) external {
        require(
            adminSigner == msg.sender || owners[msg.sender],
            "ANIFTY: CALLER"
        );
        commissionWallet = _commissionWallet;
    }

    function setMaxRoyalty(uint256 _maxRoyalty) external {
        require(
            adminSigner == msg.sender || owners[msg.sender],
            "ANIFTY: CALLER"
        );
        maxRoyalty = _maxRoyalty;
    }

    function pause() external {
        require(
            adminSigner == msg.sender || owners[msg.sender],
            "ANIFTY: CALLER"
        );
        _pause();
    }

    function unpause() internal virtual whenPaused {
        require(
            adminSigner == msg.sender || owners[msg.sender],
            "ANIFTY: CALLER"
        );
        _unpause();
    }

    function setOwners(address[] memory _owners, bool _set) external {
        require(adminSigner == msg.sender, "ANIFTY: CALLER");
        for (uint8 i = 0; i < _owners.length; i++) {
            owners[_owners[i]] = _set;
        }
    }

    function transferAdmin(address _admin) external {
        require(adminSigner == msg.sender, "ANIFTY: CALLER");
        adminSigner = _admin;
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

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Orders {
    enum AskType {
        PrimarySale,
        PrimaryAuction,
        Sale,
        Auction
    }
    // keccak256("Royalty(address[] recipients,uint16[] royalties)")
    bytes32 internal constant ROYALTY_TYPEHASH =
        0x6433d181d88c2d5e698466b2550eb30272772efadcab162439bead15cf3464f3;
    // keccak256("SecondaryRoyalty(address owner,address[] recipients,uint16[] royalties,uint256 tokenId)")
    bytes32 internal constant SECONDARY_ROYALTY_TYPEHASH =
        0xb4f785fd5968eac028f60617116d023598de5bb852d2bdf2e2580d5159b51b72;
    // keccak256("MintAsk(uint8 askType,address signer,address currency,uint256 amount,uint256 price,uint256 nonce,Royalty royalty)Royalty(address[] recipients,uint16[] royalties)")
    bytes32 internal constant MINT_ASK_TYPEHASH =
        0xa6d1c8342f2ece0d79d8c6a92b7adb005ab7deb7a20704b01c653c6463ac2179;
    // keccak256("Ask(uint8 askType,address signer,address currency,uint256 tokenId,uint256 amount,uint256 price,uint256 nonce)")
    bytes32 internal constant ASK_TYPEHASH =
        0x567bec597bdc207236e8d52844b022abb696b71d3307626449e00f24e36ac424;
    // keccak256("Bid(bytes32 askHash,address signer,uint256 price)")
    bytes32 internal constant BID_TYPEHASH =
        0x3d6c210b875bc66ffd362ddc7536b28a723422f11fe15ed6af65e74e177681b4;
    // keccak256("Commission(bytes32 askHash,uint16 amount)")
    bytes32 internal constant COMMISSION_TYPEHASH =
        0x0ffd4a521f9a6730ff71b737a392abbf74e3419b240d8946db65069e7148984c;
    // keccak256("Offer(address signer,address currency,uint256 tokenId,uint256 amount,uint256 price)")
    bytes32 internal constant OFFER_TYPEHASH =
        0x54eddede04b49d0997dcfba948e27bd0097d71e250df7fbb9a96a4aa6378c6fb;

    struct Royalty {
        address payable[] recipients;
        uint16[] royalties;
    }

    struct SecondaryRoyaltyInfo {
        address owner;
        address payable[] recipients;
        uint16[] royalties;
        uint256 tokenId;
    }

    struct SecondaryRoyalty {
        address owner;
        address payable[] recipients;
        uint16[] royalties;
        uint256 tokenId;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct MintAsk {
        AskType askType;
        address payable signer;
        address currency;
        uint256 amount;
        uint256 price;
        uint256 nonce;
        Royalty royalty;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Ask {
        AskType askType;
        address payable signer;
        address currency;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        uint256 nonce;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Bid {
        bytes32 askHash;
        address signer;
        uint256 price;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Commission {
        bytes32 askHash;
        uint16 amount;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Offer {
        address signer;
        address currency;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function hashRoyalty(Royalty memory royalty)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    ROYALTY_TYPEHASH,
                    keccak256(abi.encodePacked(royalty.recipients)),
                    keccak256(abi.encodePacked(royalty.royalties))
                )
            );
    }

    function hash(SecondaryRoyalty memory royalty)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    SECONDARY_ROYALTY_TYPEHASH,
                    royalty.owner,
                    keccak256(abi.encodePacked(royalty.recipients)),
                    keccak256(abi.encodePacked(royalty.royalties)),
                    royalty.tokenId
                )
            );
    }

    function hash(MintAsk memory mintAsk) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MINT_ASK_TYPEHASH,
                    mintAsk.askType,
                    mintAsk.signer,
                    mintAsk.currency,
                    mintAsk.amount,
                    mintAsk.price,
                    mintAsk.nonce,
                    hashRoyalty(mintAsk.royalty)
                )
            );
    }

    function hash(Ask memory ask) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ASK_TYPEHASH,
                    ask.askType,
                    ask.signer,
                    ask.currency,
                    ask.tokenId,
                    ask.amount,
                    ask.price,
                    ask.nonce
                )
            );
    }

    function hash(Bid memory bid) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(BID_TYPEHASH, bid.askHash, bid.signer, bid.price)
            );
    }

    function hash(Commission memory comission) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    COMMISSION_TYPEHASH,
                    comission.askHash,
                    comission.amount
                )
            );
    }

    function hash(Offer memory offer) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    OFFER_TYPEHASH,
                    offer.signer,
                    offer.currency,
                    offer.tokenId,
                    offer.amount,
                    offer.price
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/// @title Interface for verifying contract-based account signatures
/// @notice Interface that verifies provided signature for the data
/// @dev Interface defined by EIP-1271
interface IERC1271 {
    /// @notice Returns whether the provided signature is valid for the provided data
    /// @dev MUST return the bytes4 magic value 0x1626ba7e when function passes.
    /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5).
    /// MUST allow external calls.
    /// @param hash Hash of the data to be signed
    /// @param signature Signature byte array associated with _data
    /// @return magicValue The bytes4 magic value 0x1626ba7e
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "../libraries/Orders.sol";

interface IBaseExchange {
    event SecondaryRoyaltyUpdate(
        bytes32 indexed hash,
        Orders.SecondaryRoyaltyInfo secondaryRoyalty
    );
    event OfferCancel(bytes32 indexed hash);
    event PrimaryCancel(bytes32 indexed hash);
    event SecondaryCancel(bytes32 indexed hash);
    event Update(
        bytes32 indexed prevHash,
        bytes32 indexed hash,
        Orders.MintAsk askOrder,
        uint256 mintedHash
    );
    event PrimaryBuy(
        bytes32 indexed hash,
        address buyer,
        address recipient,
        uint256 amount,
        uint256 price,
        uint256 amountFilled,
        uint256 totalAmount
    );
    event SecondaryBuy(
        bytes32 indexed hash,
        address buyer,
        address recipient,
        uint256 amount,
        uint256 price,
        uint256 amountFilled,
        uint256 totalAmount
    );
    event PrimaryClaim(
        bytes32 indexed hash,
        bytes32 indexed bidHash,
        address buyer,
        address recipient,
        uint256 amount,
        uint256 price
    );
    event SecondaryClaim(
        bytes32 indexed hash,
        bytes32 indexed bidHash,
        address buyer,
        address recipient,
        uint256 amount,
        uint256 price
    );
    event OfferClaim(bytes32 indexed hash, address buyer);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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

    /**
     *
     * Emits a {TransferSingle} event.
     */
    function burn(uint256 id, uint256 amount) external;

    /**
     *
     * Emits a {TransferSingle} event.
     */
    function mint(
        uint256 amount,
        string memory name,
        string memory creatorName,
        string memory description,
        string memory mediaUri,
        bytes calldata data
    ) external returns (uint256);

    /**
     *
     * Emits a {TransferSingle} event.
     */
    function whitelistMint(
        uint256 amount,
        string memory name,
        string memory creatorName,
        string memory description,
        string memory mediaUri,
        bytes calldata data
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC1155Receiver.sol";
import "./ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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

import "../interfaces/IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
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
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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