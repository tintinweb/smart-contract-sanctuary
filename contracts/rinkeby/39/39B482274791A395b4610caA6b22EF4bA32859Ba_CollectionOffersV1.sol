// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.5;

/// ------------ IMPORTS ------------

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC721, IERC165} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721TransferHelper} from "../../../transferHelpers/ERC721TransferHelper.sol";
import {UniversalExchangeEventV1} from "../../UniversalExchangeEvent/V1/UniversalExchangeEventV1.sol";
import {RoyaltyPayoutSupportV1} from "../../../common/RoyaltyPayoutSupport/V1/RoyaltyPayoutSupportV1.sol";
import {IncomingTransferSupportV1} from "../../../common/IncomingTransferSupport/V1/IncomingTransferSupportV1.sol";
import {CollectionOfferBookV1} from "./CollectionOfferBookV1.sol";

/// @title Collection Offers V1
/// @author kulkarohan <[email protected]>
/// @notice This module allows buyers to place offers for any NFT from an ERC-721 collection, and allows sellers to fill an offer
contract CollectionOffersV1 is ReentrancyGuard, UniversalExchangeEventV1, IncomingTransferSupportV1, RoyaltyPayoutSupportV1, CollectionOfferBookV1 {
    address private constant ETH = address(0);
    uint256 private constant USE_ALL_GAS_FLAG = 0;

    /// @notice The ZORA ERC-721 Transfer Helper
    ERC721TransferHelper public immutable erc721TransferHelper;

    /// ------------ EVENTS ------------

    event CollectionOfferCreated(uint256 indexed id, Offer offer);

    event CollectionOfferPriceUpdated(uint256 indexed id, Offer offer);

    event CollectionOfferCanceled(uint256 indexed id, Offer offer);

    event CollectionOfferFilled(uint256 indexed id, address indexed seller, address indexed finder, Offer offer);

    /// ------------ CONSTRUCTOR ------------

    /// @param _erc20TransferHelper The ZORA ERC-20 Transfer Helper address
    /// @param _erc721TransferHelper The ZORA ERC-721 Transfer Helper address
    /// @param _royaltyEngine The Manifold Royalty Engine address
    /// @param _wethAddress WETH token address
    constructor(
        address _erc20TransferHelper,
        address _erc721TransferHelper,
        address _royaltyEngine,
        address _wethAddress
    ) IncomingTransferSupportV1(_erc20TransferHelper) RoyaltyPayoutSupportV1(_royaltyEngine, _wethAddress) {
        erc721TransferHelper = ERC721TransferHelper(_erc721TransferHelper);
    }

    /// ------------ BUYER FUNCTIONS ------------

    /// @notice Places an offer for any NFT in a collection
    /// @param _tokenContract The ERC-721 collection address
    /// @return The ID of the created offer
    function createCollectionOffer(address _tokenContract) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "createCollectionOffer msg value must be greater than 0");

        _handleIncomingTransfer(msg.value, ETH);

        uint256 offerId = _addOffer(_tokenContract, msg.value, msg.sender);

        emit CollectionOfferCreated(offerId, offers[_tokenContract][offerId]);

        return offerId;
    }

    /// @notice Updates the price of a collection offer
    /// @param _tokenContract The ERC-721 collection address
    /// @param _offerId The ID of the created offer
    /// @param _newOfferAmount The new offer price
    function setCollectionOfferAmount(
        address _tokenContract,
        uint256 _offerId,
        uint256 _newOfferAmount
    ) external payable nonReentrant {
        require(offers[_tokenContract][_offerId].active, "setCollectionOfferAmount must be active offer");
        require(msg.sender == offers[_tokenContract][_offerId].buyer, "setCollectionOfferAmount msg sender must be buyer");
        uint256 prevOfferAmount = offers[_tokenContract][_offerId].amount;
        require(
            (_newOfferAmount > 0) && (_newOfferAmount != prevOfferAmount),
            "setCollectionOfferAmount _newOfferAmount must be greater than 0 and not equal to previous offer"
        );

        if (_newOfferAmount > prevOfferAmount) {
            uint256 increaseAmount = _newOfferAmount - prevOfferAmount;

            require(msg.value == increaseAmount, "setCollectionOfferAmount must send exact increase amount");

            _handleIncomingTransfer(increaseAmount, ETH);
            _updateOffer(_tokenContract, _offerId, _newOfferAmount, true);
        } else if (_newOfferAmount < prevOfferAmount) {
            uint256 decreaseAmount = prevOfferAmount - _newOfferAmount;

            _handleOutgoingTransfer(msg.sender, decreaseAmount, ETH, USE_ALL_GAS_FLAG);
            _updateOffer(_tokenContract, _offerId, _newOfferAmount, false);
        }

        emit CollectionOfferPriceUpdated(_offerId, offers[_tokenContract][_offerId]);
    }

    /// @notice Cancels a collection offer
    /// @param _tokenContract The ERC-721 collection address
    /// @param _offerId The ID of the created offer
    function cancelCollectionOffer(address _tokenContract, uint256 _offerId) external nonReentrant {
        require(offers[_tokenContract][_offerId].active, "cancelCollectionOffer must be active offer");
        require(msg.sender == offers[_tokenContract][_offerId].buyer, "cancelCollectionOffer msg sender must be buyer");

        _handleOutgoingTransfer(msg.sender, offers[_tokenContract][_offerId].amount, ETH, USE_ALL_GAS_FLAG);

        emit CollectionOfferCanceled(_offerId, offers[_tokenContract][_offerId]);

        _removeOffer(_tokenContract, _offerId);
    }

    /// ------------ SELLER FUNCTIONS ------------

    /// @notice Fills the highest collection offer available, above a specified minimum
    /// @param _tokenContract The ERC-721 collection address
    /// @param _tokenId The ID of the seller's collection NFT
    /// @param _minAmount The minimum offer price the seller is willing to accept
    /// @param _finder The address of the referrer for this fill
    function fillCollectionOffer(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _minAmount,
        address _finder
    ) external nonReentrant {
        require(_finder != address(0), "fillCollectionOffer _finder must not be 0 address");
        require(msg.sender == IERC721(_tokenContract).ownerOf(_tokenId), "fillCollectionOffer msg sender must own specified token");

        (bool matchFound, uint256 offerId) = _getMatchingOffer(_tokenContract, _minAmount);
        require(matchFound, "fillCollectionOffer offer satisfying specified _minAmount not found");

        Offer memory offer = offers[_tokenContract][offerId];

        (uint256 remainingProfit, ) = _handleRoyaltyPayout(_tokenContract, _tokenId, offer.amount, ETH, USE_ALL_GAS_FLAG);
        uint256 finderFee = remainingProfit / 100; // 1% finder's fee

        _handleOutgoingTransfer(_finder, finderFee, ETH, USE_ALL_GAS_FLAG);

        remainingProfit -= finderFee;

        _handleOutgoingTransfer(msg.sender, remainingProfit, ETH, USE_ALL_GAS_FLAG);

        erc721TransferHelper.transferFrom(_tokenContract, msg.sender, offer.buyer, _tokenId);

        ExchangeDetails memory userAExchangeDetails = ExchangeDetails({tokenContract: _tokenContract, tokenId: _tokenId, amount: 1});
        ExchangeDetails memory userBExchangeDetails = ExchangeDetails({tokenContract: ETH, tokenId: 0, amount: offer.amount});

        emit ExchangeExecuted(msg.sender, offer.buyer, userAExchangeDetails, userBExchangeDetails);
        emit CollectionOfferFilled(offerId, msg.sender, _finder, offer);

        _removeOffer(_tokenContract, offerId);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.5;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ZoraProposalManager} from "../ZoraProposalManager.sol";
import {BaseTransferHelper} from "./BaseTransferHelper.sol";

/// @title ERC-721 Transfer Helper
/// @author tbtstl <[email protected]>
/// @notice This contract provides modules the ability to transfer ZORA user ERC-721s with their permission
contract ERC721TransferHelper is BaseTransferHelper {
    constructor(address _approvalsManager) BaseTransferHelper(_approvalsManager) {}

    function safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) public onlyApprovedModule(_from) {
        IERC721(_token).safeTransferFrom(_from, _to, _tokenId);
    }

    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) public onlyApprovedModule(_from) {
        IERC721(_token).transferFrom(_from, _to, _tokenId);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.5;

/// @title UniversalExchangeEvent V1
/// @author kulkarohan <[email protected]>
/// @notice This module generalizes indexing of all token exchanges across the protocol
contract UniversalExchangeEventV1 {
    /// @notice A ExchangeDetails object that tracks a token exchange
    /// @member tokenContract The address of the token contract
    /// @member tokenId The id of the token
    /// @member amount The amount of tokens being exchanged
    struct ExchangeDetails {
        address tokenContract;
        uint256 tokenId;
        uint256 amount;
    }

    event ExchangeExecuted(address indexed userA, address indexed userB, ExchangeDetails a, ExchangeDetails b);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.5;

import {IRoyaltyEngineV1} from "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyEngineV1.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OutgoingTransferSupportV1} from "../../OutgoingTransferSupport/V1/OutgoingTransferSupportV1.sol";

/// @title RoyaltySupportV1
/// @author tbtstl <[email protected]>
/// @notice This contract extension supports paying out royalties using the Manifold Royalty Registry
contract RoyaltyPayoutSupportV1 is OutgoingTransferSupportV1 {
    IRoyaltyEngineV1 immutable royaltyEngine;

    event RoyaltyPayout(address indexed tokenContract, uint256 indexed tokenId);

    /// @param _royaltyEngine The Manifold Royalty Engine V1 address
    /// @param _wethAddress WETH token address
    constructor(address _royaltyEngine, address _wethAddress) OutgoingTransferSupportV1(_wethAddress) {
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
    }

    /// @notice Pays out royalties for given NFTs
    /// @param _tokenContract The NFT contract address to get royalty information from
    /// @param _tokenId, The Token ID to get royalty information from
    /// @param _amount The total sale amount
    /// @param _payoutCurrency The ERC-20 token address to payout royalties in, or address(0) for ETH
    /// @param _gasLimit The gas limit to use when attempting to payout royalties. Uses gasleft() if not provided.
    /// @return remaining funds after paying out royalties
    function _handleRoyaltyPayout(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency,
        uint256 _gasLimit
    ) internal returns (uint256, bool) {
        // If no gas limit was provided or provided gas limit greater than gas left, just pass the remaining gas.
        uint256 gas = (_gasLimit == 0 || _gasLimit > gasleft()) ? gasleft() : _gasLimit;
        uint256 remainingFunds;
        bool success;

        // External call ensuring contract doesn't run out of gas paying royalties
        try this._handleRoyaltyEnginePayout{gas: gas}(_tokenContract, _tokenId, _amount, _payoutCurrency) returns (uint256 _remainingFunds) {
            remainingFunds = _remainingFunds;
            success = true;

            emit RoyaltyPayout(_tokenContract, _tokenId);
        } catch {
            remainingFunds = _amount;
            success = false;
        }

        return (remainingFunds, success);
    }

    /// @notice Pays out royalties for NFTs based on the information returned by the royalty engine
    /// @dev This method is external to enable setting a gas limit when called - see `_handleRoyaltyPayout`.
    /// @param _tokenContract The NFT Contract to get royalty information from
    /// @param _tokenId, The Token ID to get royalty information from
    /// @param _amount The total sale amount
    /// @param _payoutCurrency The ERC-20 token address to payout royalties in, or address(0) for ETH
    /// @return remaining funds after paying out royalties
    function _handleRoyaltyEnginePayout(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency
    ) external payable returns (uint256) {
        require(msg.sender == address(this), "_handleRoyaltyEnginePayout only self callable");
        uint256 remainingAmount = _amount;

        (address payable[] memory recipients, uint256[] memory amounts) = royaltyEngine.getRoyalty(_tokenContract, _tokenId, _amount);

        for (uint256 i = 0; i < recipients.length; i++) {
            // Ensure that we aren't somehow paying out more than we have
            require(remainingAmount >= amounts[i], "insolvent");
            _handleOutgoingTransfer(recipients[i], amounts[i], _payoutCurrency, 0);

            remainingAmount -= amounts[i];
        }

        return remainingAmount;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.5;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20TransferHelper} from "../../../transferHelpers/ERC20TransferHelper.sol";

contract IncomingTransferSupportV1 {
    using SafeERC20 for IERC20;

    ERC20TransferHelper immutable erc20TransferHelper;

    constructor(address _erc20TransferHelper) {
        erc20TransferHelper = ERC20TransferHelper(_erc20TransferHelper);
    }

    /// @notice Handle an incoming funds transfer, ensuring the sent amount is valid and the sender is solvent
    /// @param _amount The amount to be received
    /// @param _currency The currency to receive funds in, or address(0) for ETH
    function _handleIncomingTransfer(uint256 _amount, address _currency) internal {
        if (_currency == address(0)) {
            require(msg.value >= _amount, "_handleIncomingTransfer msg value less than expected amount");
        } else {
            // We must check the balance that was actually transferred to this contract,
            // as some tokens impose a transfer fee and would not actually transfer the
            // full amount to the market, resulting in potentally locked funds
            IERC20 token = IERC20(_currency);
            uint256 beforeBalance = token.balanceOf(address(this));
            erc20TransferHelper.safeTransferFrom(_currency, msg.sender, address(this), _amount);
            uint256 afterBalance = token.balanceOf(address(this));
            require(beforeBalance + _amount == afterBalance, "_handleIncomingTransfer token transfer call did not transfer expected amount");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.5;

/// ------------ IMPORTS ------------

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

/// @title Collection Offer Book V1
/// @author kulkarohan <[email protected]>
/// @notice This module extension manages offers placed on ERC-721 collections
contract CollectionOfferBookV1 {
    using Counters for Counters.Counter;

    /// @notice The total number of offers
    Counters.Counter public offerCounter;

    /// @notice An individual offer
    struct Offer {
        bool active;
        address buyer;
        uint256 amount;
        uint256 id;
        uint256 prevId;
        uint256 nextId;
    }

    /// ------------ PUBLIC STORAGE ------------

    /// @notice The offer for a given collection + offer ID
    /// @dev NFT address => offer ID
    mapping(address => mapping(uint256 => Offer)) public offers;

    /// @notice The floor offer ID for a given collection
    mapping(address => uint256) public floorOfferId;
    /// @notice The floor offer amount for a given collection
    mapping(address => uint256) public floorOfferAmount;

    /// @notice The ceiling offer ID for a given collection
    mapping(address => uint256) public ceilingOfferId;
    /// @notice The ceiling offer amount for a given collection
    mapping(address => uint256) public ceilingOfferAmount;

    /// ------------ INTERNAL FUNCTIONS ------------

    /// @notice Creates a new offer and places it at the apt location in its collection's offer book
    /// @param _offerAmount The amount of ETH offered
    /// @param _buyer The address of the buyer
    /// @return The ID of the created collection offer
    function _addOffer(
        address _collection,
        uint256 _offerAmount,
        address _buyer
    ) internal returns (uint256) {
        offerCounter.increment();
        uint256 _id = offerCounter.current();

        // If its the first offer for a collection, mark it as both floor and ceiling
        if (_isFirstOffer(_collection)) {
            offers[_collection][_id] = Offer({active: true, buyer: _buyer, amount: _offerAmount, id: _id, prevId: 0, nextId: 0});

            floorOfferId[_collection] = _id;
            floorOfferAmount[_collection] = _offerAmount;

            ceilingOfferId[_collection] = _id;
            ceilingOfferAmount[_collection] = _offerAmount;

            // Else if offer is greater than current ceiling, make it the new ceiling
        } else if (_isNewCeiling(_collection, _offerAmount)) {
            uint256 prevCeilingId = ceilingOfferId[_collection];

            offers[_collection][prevCeilingId].nextId = _id;
            offers[_collection][_id] = Offer({active: true, buyer: _buyer, amount: _offerAmount, id: _id, prevId: prevCeilingId, nextId: 0});

            ceilingOfferId[_collection] = _id;
            ceilingOfferAmount[_collection] = _offerAmount;

            // Else if offer is less than or equal to the current floor, make it the new floor
        } else if (_isNewFloor(_collection, _offerAmount)) {
            uint256 prevFloorId = floorOfferId[_collection];

            offers[_collection][prevFloorId].prevId = _id;
            offers[_collection][_id] = Offer({active: true, buyer: _buyer, amount: _offerAmount, id: _id, prevId: 0, nextId: prevFloorId});

            floorOfferId[_collection] = _id;
            floorOfferAmount[_collection] = _offerAmount;

            // Else offer is between the floor and ceiling --
        } else {
            // Start at the floor
            Offer memory offer = offers[_collection][floorOfferId[_collection]];

            // Traverse towards the ceiling, stop when an offer greater than or equal to (time priority) is reached; insert before
            while ((offer.amount < _offerAmount) && (offer.nextId != 0)) {
                offer = offers[_collection][offer.nextId];
            }

            offers[_collection][_id] = Offer({active: true, buyer: _buyer, amount: _offerAmount, id: _id, prevId: offer.prevId, nextId: offer.id});

            // Update neighboring pointers
            offers[_collection][offer.id].prevId = _id;
            offers[_collection][offer.prevId].nextId = _id;
        }

        return _id;
    }

    /// @notice Updates an offer and (if needed) its location relative to other offers in the collection
    /// @param _collection The ERC-721 collection
    /// @param _offerId The ID of the offer
    /// @param _newAmount The new offer amount
    /// @param _increase Whether the update is an amount increase or decrease
    function _updateOffer(
        address _collection,
        uint256 _offerId,
        uint256 _newAmount,
        bool _increase
    ) internal {
        // If the offer to update is the only offer in the collection, update the floor and ceiling amounts as well
        if (_isOnlyOffer(_collection, _offerId)) {
            offers[_collection][_offerId].amount = _newAmount;
            floorOfferAmount[_collection] = _newAmount;
            ceilingOfferAmount[_collection] = _newAmount;

            // Else if the offer is the ceiling and the update is an increase, just update the ceiling
        } else if (_isCeilingIncrease(_collection, _offerId, _increase)) {
            offers[_collection][_offerId].amount = _newAmount;
            ceilingOfferAmount[_collection] = _newAmount;

            // Else if the offer is the floor and the update is a decrease, just update the floor
        } else if (_isFloorDecrease(_collection, _offerId, _increase)) {
            offers[_collection][_offerId].amount = _newAmount;
            floorOfferAmount[_collection] = _newAmount;

            // Else if the offer is still at the correct location, just update its amount
        } else if (_isUpdateInPlace(_collection, _offerId, _newAmount, _increase)) {
            offers[_collection][_offerId].amount = _newAmount;

            // Else if the offer is the new ceiling --
        } else if (_isNewCeiling(_collection, _newAmount)) {
            uint256 prevId = offers[_collection][_offerId].prevId;
            uint256 nextId = offers[_collection][_offerId].nextId;

            // Update previous neighbors
            _connectPreviousNeighbors(_collection, _offerId, prevId, nextId);

            // Update previous ceiling
            uint256 prevCeilingId = ceilingOfferId[_collection];
            offers[_collection][prevCeilingId].nextId = _offerId;

            // Update offer as new ceiling
            offers[_collection][_offerId].prevId = prevCeilingId;
            offers[_collection][_offerId].nextId = 0;
            offers[_collection][_offerId].amount = _newAmount;

            // Update collection ceiling
            ceilingOfferId[_collection] = _offerId;
            ceilingOfferAmount[_collection] = _newAmount;

            // Else if the offer is the new floor --
        } else if (_isNewFloor(_collection, _newAmount)) {
            uint256 prevId = offers[_collection][_offerId].prevId;
            uint256 nextId = offers[_collection][_offerId].nextId;

            // Update previous neighbors
            _connectPreviousNeighbors(_collection, _offerId, prevId, nextId);

            // Update previous floor
            uint256 prevFloorId = floorOfferId[_collection];
            offers[_collection][prevFloorId].prevId = _offerId;

            // Update offer as new floor
            offers[_collection][_offerId].nextId = prevFloorId;
            offers[_collection][_offerId].prevId = 0;
            offers[_collection][_offerId].amount = _newAmount;

            // Update collection floor
            floorOfferId[_collection] = _offerId;
            floorOfferAmount[_collection] = _newAmount;

            // Else move the offer to the apt middle location
        } else {
            Offer memory offer = offers[_collection][_offerId];

            // Update previous neighbors
            _connectPreviousNeighbors(_collection, _offerId, offer.prevId, offer.nextId);

            if (_increase == true) {
                // Traverse forward until the apt location is found
                _insertIncreasedOffer(offer, _collection, _offerId, _newAmount);
            } else {
                // Traverse backward until the apt location is found
                _insertDecreasedOffer(offer, _collection, _offerId, _newAmount);
            }
        }
    }

    /// @notice Removes an offer from its collection's offer book
    /// @param _collection The ERC-721 collection
    /// @param _offerId The ID of the offer
    function _removeOffer(address _collection, uint256 _offerId) internal {
        // If the offer to remove is the only one for its collection, remove it and reset associated collection data stored
        if (_isOnlyOffer(_collection, _offerId)) {
            delete floorOfferId[_collection];
            delete floorOfferAmount[_collection];
            delete ceilingOfferId[_collection];
            delete ceilingOfferAmount[_collection];
            delete offers[_collection][_offerId];

            // Else if the offer is the current floor, update the collection's floor before removing
        } else if (_isFloorOffer(_collection, _offerId)) {
            uint256 newFloorId = offers[_collection][_offerId].nextId;
            uint256 newFloorAmount = offers[_collection][newFloorId].amount;

            offers[_collection][newFloorId].prevId = 0;

            floorOfferId[_collection] = newFloorId;
            floorOfferAmount[_collection] = newFloorAmount;

            delete offers[_collection][_offerId];

            // Else if the offer is the current ceiling, update the collection's ceiling before removing
        } else if (_isCeilingOffer(_collection, _offerId)) {
            uint256 newCeilingId = offers[_collection][_offerId].prevId;
            uint256 newCeilingAmount = offers[_collection][newCeilingId].amount;

            offers[_collection][newCeilingId].nextId = 0;

            ceilingOfferId[_collection] = newCeilingId;
            ceilingOfferAmount[_collection] = newCeilingAmount;

            delete offers[_collection][_offerId];

            // Else offer is in middle, so update its previous and next neighboring pointers before removing
        } else {
            Offer memory offer = offers[_collection][_offerId];

            offers[_collection][offer.nextId].prevId = offer.prevId;
            offers[_collection][offer.prevId].nextId = offer.nextId;

            delete offers[_collection][_offerId];
        }
    }

    /// @notice Finds a collection offer to fill
    /// @param _collection The ERC-721 collection
    /// @param _minAmount The minimum offer amount valid to match
    function _getMatchingOffer(address _collection, uint256 _minAmount) internal view returns (bool, uint256) {
        // If the current ceiling offer is greater than or equal to the seller's minimum, return its id to fill
        if (ceilingOfferAmount[_collection] >= _minAmount) {
            return (true, ceilingOfferId[_collection]);

            // Else traverse backwards from ceiling to floor
        } else {
            Offer memory offer = offers[_collection][ceilingOfferId[_collection]];

            bool matchFound;
            while ((offer.amount >= _minAmount) && (offer.prevId != 0)) {
                offer = offers[_collection][offer.prevId];

                // If the offer is valid to fill, return its id
                if (offer.amount >= _minAmount) {
                    matchFound = true;
                    break;
                }
                // If not, notify the seller there is no matching offer fitting their specified minimum
            }

            return (matchFound, offer.id);
        }
    }

    /// ------------ PRIVATE FUNCTIONS ------------

    /// @notice Checks whether any offers exist for a collection
    /// @param _collection The ERC-721 collection
    function _isFirstOffer(address _collection) private view returns (bool) {
        return (ceilingOfferId[_collection] == 0) && (floorOfferId[_collection] == 0);
    }

    /// @notice Checks whether a given offer is the only one for a collection
    /// @param _collection The ERC-721 collection
    /// @param _offerId The ID of the offer
    function _isOnlyOffer(address _collection, uint256 _offerId) private view returns (bool) {
        return (_offerId == floorOfferId[_collection]) && (_offerId == ceilingOfferId[_collection]);
    }

    /// @notice Checks whether a given offer is the collection ceiling
    /// @param _collection The ERC-721 collection
    /// @param _offerId The ID of the offer
    function _isCeilingOffer(address _collection, uint256 _offerId) private view returns (bool) {
        return (_offerId == ceilingOfferId[_collection]);
    }

    /// @notice Checks whether a given offer is the collection floor
    /// @param _collection The ERC-721 collection
    /// @param _offerId The ID of the offer
    function _isFloorOffer(address _collection, uint256 _offerId) private view returns (bool) {
        return (_offerId == floorOfferId[_collection]);
    }

    /// @notice Checks whether an offer is greater than the collection ceiling
    /// @param _collection The ERC-721 collection
    /// @param _offerAmount The offer amount
    function _isNewCeiling(address _collection, uint256 _offerAmount) private view returns (bool) {
        return (_offerAmount > ceilingOfferAmount[_collection]);
    }

    /// @notice Checks whether an offer is less than or equal to the collection floor
    /// @param _collection The ERC-721 collection
    /// @param _offerAmount The offer amount
    function _isNewFloor(address _collection, uint256 _offerAmount) private view returns (bool) {
        return (_offerAmount <= floorOfferAmount[_collection]);
    }

    /// @notice Checks whether an offer to increase is the collection ceiling
    /// @param _collection The ERC-721 collection
    /// @param _offerId The ID of the offer
    /// @param _increase Whether the update is an amount increase or decrease
    function _isCeilingIncrease(
        address _collection,
        uint256 _offerId,
        bool _increase
    ) private view returns (bool) {
        return (_offerId == ceilingOfferId[_collection]) && (_increase == true);
    }

    /// @notice Checks whether an offer to decrease is the collection floor
    /// @param _collection The ERC-721 collection
    /// @param _offerId The ID of the offer
    /// @param _increase Whether the update is an amount increase or decrease
    function _isFloorDecrease(
        address _collection,
        uint256 _offerId,
        bool _increase
    ) private view returns (bool) {
        return (_offerId == floorOfferId[_collection]) && (_increase == false);
    }

    /// @notice Checks whether an offer can be updated without relocation
    /// @param _collection The ERC-721 collection
    /// @param _offerId The ID of the offer
    /// @param _newAmount The new offer amount
    /// @param _increase Whether the update is an amount increase or decrease
    function _isUpdateInPlace(
        address _collection,
        uint256 _offerId,
        uint256 _newAmount,
        bool _increase
    ) private view returns (bool) {
        uint256 nextOffer = offers[_collection][_offerId].nextId;
        uint256 prevOffer = offers[_collection][_offerId].prevId;
        return
            ((_increase == true) && (_newAmount <= offers[_collection][nextOffer].amount)) ||
            ((_increase == false) && (_newAmount > offers[_collection][prevOffer].amount));
    }

    /// @notice Connects the pointers of an offer's neighbors
    /// @param _collection The ERC-721 collection
    /// @param _offerId The ID of the offer
    /// @param _prevId The ID of the offer's previous pointer
    /// @param _nextId The ID of the offer's next pointer
    function _connectPreviousNeighbors(
        address _collection,
        uint256 _offerId,
        uint256 _prevId,
        uint256 _nextId
    ) private {
        if (_offerId == floorOfferId[_collection]) {
            offers[_collection][_nextId].prevId = 0;

            floorOfferId[_collection] = _nextId;
            floorOfferAmount[_collection] = offers[_collection][_nextId].amount;
        } else if (_offerId == ceilingOfferId[_collection]) {
            offers[_collection][_prevId].nextId = 0;

            ceilingOfferId[_collection] = _prevId;
            ceilingOfferAmount[_collection] = offers[_collection][_prevId].amount;
        } else {
            offers[_collection][_nextId].prevId = _prevId;
            offers[_collection][_prevId].nextId = _nextId;
        }
    }

    /// @notice Updates the location of an increased offer
    /// @param offer The Offer associated with _offerId
    /// @param _collection The ERC-721 collection
    /// @param _offerId The ID of the offer
    /// @param _newAmount The new offer amount
    function _insertIncreasedOffer(
        Offer memory offer,
        address _collection,
        uint256 _offerId,
        uint256 _newAmount
    ) private {
        offer = offers[_collection][offer.nextId];

        // Traverse forward until the apt location is found
        while ((offer.amount < _newAmount) && (offer.nextId != 0)) {
            offer = offers[_collection][offer.nextId];
        }

        // Update offer pointers
        offers[_collection][_offerId].nextId = offer.id;
        offers[_collection][_offerId].prevId = offer.prevId;

        // Update neighbor pointers
        offers[_collection][offer.id].prevId = _offerId;
        offers[_collection][offer.prevId].nextId = _offerId;

        // Update offer amount
        offers[_collection][_offerId].amount = _newAmount;
    }

    /// @notice Updates the location of a decreased offer
    /// @param offer The Offer associated with _offerId
    /// @param _collection The ERC-721 collection
    /// @param _offerId The ID of the offer
    /// @param _newAmount The new offer amount
    function _insertDecreasedOffer(
        Offer memory offer,
        address _collection,
        uint256 _offerId,
        uint256 _newAmount
    ) private {
        offer = offers[_collection][offer.prevId];

        // Traverse backwards until the apt location is found
        while ((offer.amount >= _newAmount) && (offer.prevId != 0)) {
            offer = offers[_collection][offer.prevId];
        }

        // Update offer pointers
        offers[_collection][_offerId].prevId = offer.id;
        offers[_collection][_offerId].nextId = offer.nextId;

        // Update neighbor pointers
        offers[_collection][offer.id].nextId = _offerId;
        offers[_collection][offer.nextId].prevId = _offerId;

        // Update offer amount
        offers[_collection][_offerId].amount = _newAmount;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.5;

/// @title ZORA Module Proposal Manager
/// @author tbtstl <[email protected]>
/// @notice This contract accepts proposals and registers new modules, granting them access to the ZORA Module Approval Manager
contract ZoraProposalManager {
    enum ProposalStatus {
        Nonexistent,
        Pending,
        Passed,
        Failed
    }
    /// @notice A Proposal object that tracks a proposal and its status
    /// @member proposer The address that created the proposal
    /// @member status The status of the proposal (see ProposalStatus)
    struct Proposal {
        address proposer;
        ProposalStatus status;
    }

    /// @notice The registrar address that can register, or cancel
    address public registrar;
    /// @notice A mapping of module addresses to proposals
    mapping(address => Proposal) public proposedModuleToProposal;

    event ModuleProposed(address indexed contractAddress, address indexed proposer);
    event ModuleRegistered(address indexed contractAddress);
    event ModuleCanceled(address indexed contractAddress);
    event RegistrarChanged(address indexed newRegistrar);

    modifier onlyRegistrar() {
        require(msg.sender == registrar, "ZPM::onlyRegistrar must be registrar");
        _;
    }

    /// @param _registrarAddress The initial registrar for the manager
    constructor(address _registrarAddress) {
        require(_registrarAddress != address(0), "ZPM::must set registrar to non-zero address");

        registrar = _registrarAddress;
    }

    /// @notice Returns true if the module has been registered
    /// @param _proposalImpl The address of the proposed module
    /// @return True if the module has been registered, false otherwise
    function isPassedProposal(address _proposalImpl) public view returns (bool) {
        return proposedModuleToProposal[_proposalImpl].status == ProposalStatus.Passed;
    }

    /// @notice Creates a new proposal for a module
    /// @param _impl The address of the deployed module being proposed
    function proposeModule(address _impl) public {
        require(proposedModuleToProposal[_impl].proposer == address(0), "ZPM::proposeModule proposal already exists");
        require(_impl != address(0), "ZPM::proposeModule proposed contract cannot be zero address");

        Proposal memory proposal = Proposal({proposer: msg.sender, status: ProposalStatus.Pending});
        proposedModuleToProposal[_impl] = proposal;

        emit ModuleProposed(_impl, msg.sender);
    }

    /// @notice Registers a proposed module
    /// @param _proposalAddress The address of the proposed module
    function registerModule(address _proposalAddress) public onlyRegistrar {
        Proposal storage proposal = proposedModuleToProposal[_proposalAddress];

        require(proposal.status == ProposalStatus.Pending, "ZPM::registerModule can only register pending proposals");

        proposal.status = ProposalStatus.Passed;

        emit ModuleRegistered(_proposalAddress);
    }

    /// @notice Cancels a proposed module
    /// @param _proposalAddress The address of the proposed module
    function cancelProposal(address _proposalAddress) public onlyRegistrar {
        Proposal storage proposal = proposedModuleToProposal[_proposalAddress];

        require(proposal.status == ProposalStatus.Pending, "ZPM::cancelProposal can only cancel pending proposals");

        proposal.status = ProposalStatus.Failed;

        emit ModuleCanceled(_proposalAddress);
    }

    /// @notice Sets the registrar for this manager
    /// @param _registrarAddress the address of the new registrar
    function setRegistrar(address _registrarAddress) public onlyRegistrar {
        require(_registrarAddress != address(0), "ZPM::setRegistrar must set registrar to non-zero address");
        registrar = _registrarAddress;

        emit RegistrarChanged(_registrarAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.5;

import {ZoraModuleApprovalsManager} from "../ZoraModuleApprovalsManager.sol";

/// @title Base Transfer Helper
/// @author tbtstl <[email protected]>
/// @notice This contract provides shared utility for ZORA transfer helpers
contract BaseTransferHelper {
    ZoraModuleApprovalsManager approvalsManager;

    /// @param _approvalsManager The ZORA Module Approvals Manager to use as a reference for transfer permissions
    constructor(address _approvalsManager) {
        require(_approvalsManager != address(0), "must set approvals manager to non-zero address");

        approvalsManager = ZoraModuleApprovalsManager(_approvalsManager);
    }

    // Only allows the method to continue if the caller is an approved zora module
    modifier onlyApprovedModule(address _from) {
        require(approvalsManager.isModuleApproved(_from, msg.sender), "module has not been approved by user");

        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.5;

import {ZoraProposalManager} from "./ZoraProposalManager.sol";

/// @title ZORA Module Proposal Manager
/// @author tbtstl <[email protected]>
/// @notice This contract allows users to explicitly allow modules access to the ZORA transfer helpers on their behalf
contract ZoraModuleApprovalsManager {
    /// @notice The address of the proposal manager, manages allowed modules
    ZoraProposalManager public proposalManager;

    /// @notice Mapping of specific approvals for (module, user) pairs in the ZORA registry
    mapping(address => mapping(address => bool)) public userApprovals;

    event ModuleApprovalSet(address indexed user, address indexed module, bool approved);
    event AllModulesApprovalSet(address indexed user, bool approved);

    /// @param _proposalManager The address of the ZORA proposal manager
    constructor(address _proposalManager) {
        proposalManager = ZoraProposalManager(_proposalManager);
    }

    /// @notice Returns true if the user has approved a given module, false otherwise
    /// @param _user The user to check approvals for
    /// @param _module The module to check approvals for
    /// @return True if the module has been approved by the user, false otherwise
    function isModuleApproved(address _user, address _module) external view returns (bool) {
        return userApprovals[_user][_module];
    }

    /// @notice Allows a user to set the approval for a given module
    /// @param _moduleAddress The module to approve
    /// @param _approved A boolean, whether or not to approve a module
    function setApprovalForModule(address _moduleAddress, bool _approved) public {
        require(proposalManager.isPassedProposal(_moduleAddress), "ZMAM::module must be approved");

        userApprovals[msg.sender][_moduleAddress] = _approved;

        emit ModuleApprovalSet(msg.sender, _moduleAddress, _approved);
    }

    /// @notice Sets approvals for multiple modules at once
    /// @param _moduleAddresses The list of module addresses to set approvals for
    /// @param _approved A boolean, whether or not to approve the modules
    function setBatchApprovalForModules(address[] memory _moduleAddresses, bool _approved) public {
        for (uint256 i = 0; i < _moduleAddresses.length; i++) {
            setApprovalForModule(_moduleAddresses[i], _approved);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {

    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) external returns(address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value) external view returns(address payable[] memory recipients, uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.5;

import {IWETH} from "../../../interfaces/common/IWETH.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title OutgoingTransferSupportV1
/// @author tbtstl <[email protected]>
/// @notice This contract extension supports paying out funds to an external recipient
contract OutgoingTransferSupportV1 {
    using SafeERC20 for IERC20;

    IWETH immutable weth;

    constructor(address _wethAddress) {
        weth = IWETH(_wethAddress);
    }

    /// @notice Handle an outgoing funds transfer
    /// @dev Wraps ETH in WETH if the receiver cannot receive ETH, noop if the funds to be sent are 0 or recipient is invalid
    /// @param _dest The destination for the funds
    /// @param _amount The amount to be sent
    /// @param _currency The currency to send funds in, or address(0) for ETH
    /// @param _gasLimit The gas limit to use when attempting a payment (if 0, gasleft() is used)
    function _handleOutgoingTransfer(
        address _dest,
        uint256 _amount,
        address _currency,
        uint256 _gasLimit
    ) internal {
        if (_amount == 0 || _dest == address(0)) {
            return;
        }

        // If no gas limit was provided or provided gas limit greater than gas left, just use the remaining gas.

        // Handle ETH payment
        if (_currency == address(0)) {
            require(address(this).balance >= _amount, "_handleOutgoingTransfer insolvent");

            uint256 gas = (_gasLimit == 0 || _gasLimit > gasleft()) ? gasleft() : _gasLimit;
            (bool success, ) = _dest.call{value: _amount, gas: gas}(new bytes(0));
            // If the ETH transfer fails (sigh), wrap the ETH and try send it as WETH.
            if (!success) {
                weth.deposit{value: _amount}();
                IERC20(address(weth)).safeTransfer(_dest, _amount);
            }
        } else {
            IERC20(_currency).safeTransfer(_dest, _amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.5;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.5;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ZoraProposalManager} from "../ZoraProposalManager.sol";
import {BaseTransferHelper} from "./BaseTransferHelper.sol";

/// @title ERC-20 Transfer Helper
/// @author tbtstl <[email protected]>
/// @notice This contract provides modules the ability to transfer ZORA user ERC-20s with their permission
contract ERC20TransferHelper is BaseTransferHelper {
    using SafeERC20 for IERC20;

    constructor(address _approvalsManager) BaseTransferHelper(_approvalsManager) {}

    function safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) public onlyApprovedModule(_from) {
        IERC20(_token).safeTransferFrom(_from, _to, _value);
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