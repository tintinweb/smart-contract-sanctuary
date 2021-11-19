// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
pragma abicoder v2;

import './IWETH.sol';
import './IMintable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

contract MarketNG is IERC721Receiver, IERC1155Receiver, ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    uint8 public constant KIND_SELL = 1;
    uint8 public constant KIND_BUY = 2;
    uint8 public constant KIND_AUCTION = 3;

    uint8 public constant STATUS_OPEN = 0;
    uint8 public constant STATUS_DONE = 1;
    uint8 public constant STATUS_CANCELLED = 2;

    uint8 public constant OP_MIN = 0; // invalid, for checks only
    uint8 public constant OP_COMPLETE_SELL = 1; // complete sell (off-chain)
    uint8 public constant OP_COMPLETE_BUY = 2; // complete buy (off-chain)
    uint8 public constant OP_BUY = 3; // create KIND_BUY
    uint8 public constant OP_ACCEPT_BUY = 4; // complete KIND_BUY
    uint8 public constant OP_CANCEL_BUY = 5; // cancel KIND_BUY
    uint8 public constant OP_REJECT_BUY = 6; // reject KIND_BUY
    uint8 public constant OP_BID = 7; // bid (create or update KIND_AUCTION)
    uint8 public constant OP_COMPLETE_AUCTION = 8; // complete auction (by anyone)
    uint8 public constant OP_ACCEPT_AUCTION = 9; // accept auction in an early stage (by seller)
    uint8 public constant OP_MAX = 10;

    uint8 public constant TOKEN_MINT = 0; // mint token (do anything)
    uint8 public constant TOKEN_721 = 1; // 721 token
    uint8 public constant TOKEN_1155 = 2; // 1155 token

    uint256 public constant RATE_BASE = 1e6;

    struct Pair721 {
        // swap only
        IERC721 token;
        uint256 tokenId;
    }

    struct TokenPair {
        address token; // token contract address
        uint256 tokenId; // token id (if applicable)
        uint256 amount; // token amount (if applicable)
        uint8 kind; // token kind (721/1151/mint)
        bytes mintData; // mint data (if applicable)
    }

    struct Inventory {
        address seller;
        address buyer;
        IERC20 currency;
        uint256 price; // display price
        uint256 netPrice; // actual price (auction: minus incentive)
        uint256 deadline; // deadline for the inventory
        uint8 kind;
        uint8 status;
    }

    struct Intention {
        address user;
        TokenPair[] bundle;
        IERC20 currency;
        uint256 price;
        uint256 deadline;
        bytes32 salt;
        uint8 kind;
    }

    struct Detail {
        bytes32 intentionHash;
        address signer;
        uint256 txDeadline; // deadline for the transaction
        bytes32 salt;
        uint256 id; // inventory id
        uint8 opcode; // OP_*
        address caller;
        IERC20 currency;
        uint256 price;
        uint256 incentiveRate;
        Settlement settlement;
        TokenPair[] bundle;
        uint256 deadline; // deadline for buy offer
    }

    struct Settlement {
        uint256[] coupons;
        uint256 feeRate;
        uint256 royaltyRate;
        uint256 buyerCashbackRate;
        address feeAddress;
        address royaltyAddress;
    }

    struct Swap {
        bytes32 salt;
        address creator;
        uint256 deadline;
        Pair721[] has;
        Pair721[] wants;
    }

    // events

    event EvCouponSpent(uint256 indexed id, uint256 indexed couponId);
    event EvInventoryUpdate(uint256 indexed id, Inventory inventory);
    event EvAuctionRefund(uint256 indexed id, address bidder, uint256 refund);
    event EvSettingsUpdated();
    event EvMarketSignerUpdate(address addr, bool isRemoval);
    event EvSwapped(Swap req, bytes signature, address swapper);

    // vars

    IWETH public immutable weth;

    mapping(uint256 => Inventory) public inventories;
    mapping(uint256 => bool) public couponSpent;
    mapping(uint256 => mapping(uint256 => TokenPair)) public inventoryTokens;
    mapping(uint256 => uint256) public inventoryTokenCounts;
    mapping(address => bool) public marketSigners;

    // initialized with default value
    uint256 public minAuctionIncrement = (5 * RATE_BASE) / 100;
    uint256 public minAuctionDuration = 10 * 60;

    // internal vars
    bool internal _canReceive = false;

    // constructor

    constructor(IWETH weth_) {
        weth = weth_;
    }

    function updateSettings(uint256 minAuctionIncrement_, uint256 minAuctionDuration_)
        public
        onlyOwner
    {
        minAuctionDuration = minAuctionDuration_;
        minAuctionIncrement = minAuctionIncrement_;
        emit EvSettingsUpdated();
    }

    function updateSigner(address addr, bool remove) public onlyOwner {
        if (remove) {
            delete marketSigners[addr];
        } else {
            marketSigners[addr] = true;
        }
        emit EvMarketSignerUpdate(addr, remove);
    }

    // impls

    receive() external payable {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view override _onTransferOnly returns (bytes4) {
        (operator);
        (from);
        (tokenId);
        (data);
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external view override _onTransferOnly returns (bytes4) {
        (operator);
        (from);
        (id);
        (value);
        (data);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external view override _onTransferOnly returns (bytes4) {
        (operator);
        (from);
        (ids);
        (values);
        (data);
        return this.onERC1155BatchReceived.selector;
    }

    modifier _onTransferOnly() {
        require(_canReceive, 'can not transfer token directly');
        _;
    }

    modifier _allowTransfer() {
        _canReceive = true;
        _;
        _canReceive = false;
    }

    // public

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            (interfaceId == type(IERC721Receiver).interfaceId) ||
            (interfaceId == type(IERC1155Receiver).interfaceId);
    }

    function run(
        Intention calldata intent,
        Detail calldata detail,
        bytes calldata sigIntent,
        bytes calldata sigDetail
    ) public payable nonReentrant whenNotPaused {
        require(detail.txDeadline > block.timestamp, 'transaction deadline reached');
        require(marketSigners[detail.signer], 'unknown market signer');

        _validateOpCode(detail.opcode);
        require(
            isSignatureValid(sigDetail, keccak256(abi.encode(detail)), detail.signer),
            'offer signature error'
        );

        if (hasSignedIntention(detail.opcode)) {
            bytes memory encodedInt = abi.encode(intent);
            require(keccak256(encodedInt) == detail.intentionHash, 'intention hash does not match');
            require(
                isSignatureValid(sigIntent, keccak256(encodedInt), intent.user),
                'intention signature error'
            );
        }

        if (detail.opcode == OP_COMPLETE_SELL) {
            _assertSender(detail.caller);
            require(intent.kind == KIND_SELL, 'intent.kind should be KIND_SELL');
            _newSellDeal(
                detail.id,
                intent.user,
                intent.bundle,
                intent.currency,
                intent.price,
                intent.deadline,
                detail.caller,
                detail.settlement
            );
        } else if (detail.opcode == OP_COMPLETE_BUY) {
            _assertSender(detail.caller);
            require(intent.kind == KIND_BUY, 'intent.kind should be KIND_BUY');
            _newBuyDeal(
                detail.id,
                intent.user, // buyer
                detail.caller, // seller
                intent.bundle,
                intent.currency,
                intent.price,
                intent.deadline,
                detail.settlement
            );
        } else if (detail.opcode == OP_BUY) {
            _assertSender(detail.caller);
            _newBuy(
                detail.id,
                detail.caller,
                detail.currency,
                detail.price,
                detail.bundle,
                detail.deadline
            );
        } else if (detail.opcode == OP_ACCEPT_BUY) {
            _assertSender(detail.caller);
            _acceptBuy(detail.id, detail.caller, detail.settlement);
        } else if (detail.opcode == OP_CANCEL_BUY) {
            _cancelBuyAnyway(detail.id);
        } else if (detail.opcode == OP_REJECT_BUY) {
            _rejectBuy(detail.id);
        } else if (detail.opcode == OP_BID) {
            _assertSender(detail.caller);
            require(intent.kind == KIND_AUCTION, 'intent.kind should be KIND_AUCTION');
            _bid(
                detail.id,
                intent.user,
                intent.bundle,
                intent.currency,
                intent.price,
                intent.deadline,
                detail.caller,
                detail.price,
                detail.incentiveRate
            );
        } else if (detail.opcode == OP_COMPLETE_AUCTION) {
            _completeAuction(detail.id, detail.settlement);
        } else if (detail.opcode == OP_ACCEPT_AUCTION) {
            _assertSender(detail.caller);
            require(detail.caller == intent.user, 'only seller can call');
            _acceptAuction(detail.id, detail.settlement);
        } else {
            revert('impossible');
        }
    }

    function cancelBuys(uint256[] calldata ids) public nonReentrant whenNotPaused {
        for (uint256 i = 0; i < ids.length; i++) {
            _cancelBuy(ids[i]);
        }
    }

    function inCaseMoneyGetsStuck(address to, IERC20 currency, uint256 amount) public onlyOwner {
        _transfer(currency, to, amount);
    }

    // emergency method for flaky contracts
    function emergencyCancelAuction(uint256 id, bool noBundle) public onlyOwner {
        require(isAuction(id), 'not auction');
        require(isStatusOpen(id), 'not open');
        Inventory storage inv = inventories[id];

        if (!noBundle) {
            _transferBundle(id, address(this), inv.seller, false);
        }
        _transfer(inv.currency, inv.buyer, inv.netPrice);

        inv.status = STATUS_CANCELLED;
        emit EvInventoryUpdate(id, inv);
    }

    function swap(Swap memory req, bytes memory signature) public nonReentrant whenNotPaused {
        require(req.deadline > block.timestamp, 'deadline reached');
        require(
            isSignatureValid(signature, keccak256(abi.encode(req)), req.creator),
            'signature error'
        );

        for (uint256 i = 0; i < req.wants.length; i++) {
            req.wants[i].token.safeTransferFrom(msg.sender, req.creator, req.wants[i].tokenId);
        }

        for (uint256 i = 0; i < req.has.length; i++) {
            req.has[i].token.safeTransferFrom(req.creator, msg.sender, req.has[i].tokenId);
        }

        emit EvSwapped(req, signature, msg.sender);
    }

    function send(address to, Pair721[] memory tokens) public nonReentrant whenNotPaused {
        for (uint256 i = 0; i < tokens.length; i++) {
            Pair721 memory p = tokens[i];
            p.token.safeTransferFrom(msg.sender, to, p.tokenId);
        }
    }

    // internal

    function _assertSender(address sender) internal view {
        require(sender == msg.sender, 'wrong sender');
    }

    function _validateOpCode(uint8 opCode) internal pure {
        require(opCode > OP_MIN && opCode < OP_MAX, 'invalid opcode');
    }

    function _saveBundle(uint256 invId, TokenPair[] calldata bundle) internal {
        require(bundle.length > 0, 'empty bundle');
        inventoryTokenCounts[invId] = bundle.length;
        for (uint256 i = 0; i < bundle.length; i++) {
            inventoryTokens[invId][i] = bundle[i];
        }
    }

    // buyer create
    function _newBuy(
        uint256 id,
        address buyer,
        IERC20 currency,
        uint256 price,
        TokenPair[] calldata bundle,
        uint256 deadline
    ) internal {
        require(!hasInv(id), 'inventoryId already exists');
        require(deadline > block.timestamp, 'deadline must be greater than now');
        _saveBundle(id, bundle);

        if (_isNative(currency)) {
            require(price == msg.value, 'price == msg.value');
            weth.deposit{value: price}(); // convert to erc20 (weth)
        } else {
            currency.safeTransferFrom(buyer, address(this), price);
        }

        inventories[id] = Inventory({
            seller: address(0),
            buyer: buyer,
            currency: currency,
            price: price,
            netPrice: price,
            kind: KIND_BUY,
            status: STATUS_OPEN,
            deadline: deadline
        });
        emit EvInventoryUpdate(id, inventories[id]);
    }

    // buyer cancel/expired
    function _cancelBuy(uint256 id) internal {
        Inventory storage inv = inventories[id];
        require(inv.buyer == msg.sender || isExpired(id), 'caller is not buyer');
        _cancelBuyAnyway(id);
    }

    // cancel without checking caller
    function _cancelBuyAnyway(uint256 id) internal {
        require(isBuy(id) && isStatusOpen(id), 'not open buy');
        Inventory storage inv = inventories[id];

        inv.status = STATUS_CANCELLED;
        _transfer(inv.currency, inv.buyer, inv.netPrice);

        emit EvInventoryUpdate(id, inventories[id]);
    }

    function _rejectBuy(uint256 id) internal {
        address caller = msg.sender;
        require(isBuy(id) && isStatusOpen(id), 'not open buy');

        for (uint256 i = 0; i < inventoryTokenCounts[id]; i++) {
            TokenPair storage p = inventoryTokens[id][i];
            if (p.kind == TOKEN_721) {
                IERC721 t = IERC721(p.token);
                require(t.ownerOf(p.tokenId) == caller, 'caller does not own token');
            } else {
                revert('cannot reject non-721 token');
            }
        }

        _cancelBuyAnyway(id);
    }

    // seller call
    function _acceptBuy(
        uint256 id,
        address seller,
        Settlement calldata settlement
    ) internal {
        require(isBuy(id), 'id does not exist');
        Inventory storage inv = inventories[id];
        require(isStatusOpen(id), 'not open');
        require(isBundleApproved(id, seller), 'bundle not approved');
        require(!isExpired(id), 'buy offer expired');

        inv.status = STATUS_DONE;
        inv.seller = seller;
        _transferBundle(id, seller, inv.buyer, true);

        emit EvInventoryUpdate(id, inventories[id]);
        _completeTransaction(id, settlement);
    }

    function _newBuyDeal(
        uint256 id,
        address buyer,
        address seller,
        TokenPair[] calldata bundle,
        IERC20 currency,
        uint256 price,
        uint256 deadline,
        Settlement calldata settlement
    ) internal {
        require(!hasInv(id), 'inventory already exists');
        require(deadline > block.timestamp, 'buy has already ended');
        require(!_isNative(currency), 'cannot use native token');

        _saveBundle(id, bundle);
        _transferBundle(id, seller, buyer, true);
        currency.safeTransferFrom(buyer, address(this), price);

        inventories[id] = Inventory({
            seller: seller,
            buyer: buyer,
            currency: currency,
            price: price,
            netPrice: price,
            kind: KIND_BUY,
            status: STATUS_DONE,
            deadline: deadline
        });
        emit EvInventoryUpdate(id, inventories[id]);

        _completeTransaction(id, settlement);
    }

    // new sell deal / new auction direct buy
    function _newSellDeal(
        uint256 id,
        address seller,
        TokenPair[] calldata bundle,
        IERC20 currency,
        uint256 price,
        uint256 deadline,
        address buyer,
        Settlement calldata settlement
    ) internal {
        require(!hasInv(id), 'duplicate id');
        require(deadline > block.timestamp, 'sell has already ended');

        _saveBundle(id, bundle);
        _transferBundle(id, seller, buyer, true);

        if (_isNative(currency)) {
            require(price == msg.value, 'price == msg.value');
            weth.deposit{value: price}(); // convert to erc20 (weth)
        } else {
            currency.safeTransferFrom(buyer, address(this), price);
        }

        inventories[id] = Inventory({
            seller: seller,
            buyer: buyer,
            currency: currency,
            price: price,
            netPrice: price,
            kind: KIND_SELL,
            status: STATUS_DONE,
            deadline: deadline
        });
        emit EvInventoryUpdate(id, inventories[id]);

        _completeTransaction(id, settlement);
    }

    function _bid(
        uint256 id,
        address seller,
        TokenPair[] calldata bundle,
        IERC20 currency,
        uint256 startPrice,
        uint256 deadline,
        address buyer,
        uint256 price,
        uint256 incentiveRate
    ) internal _allowTransfer {
        require(incentiveRate < RATE_BASE, 'incentiveRate too large');

        if (_isNative(currency)) {
            require(price == msg.value, 'price == msg.value');
            weth.deposit{value: price}(); // convert to erc20 (weth)
        } else {
            currency.safeTransferFrom(buyer, address(this), price);
        }

        if (isAuction(id)) {
            Inventory storage auc = inventories[id];
            require(auc.seller == seller, 'seller does not match'); // TODO check more
            require(auc.status == STATUS_OPEN, 'auction not open');
            require(auc.deadline > block.timestamp, 'auction ended');

            require(
                price >= auc.price + ((auc.price * minAuctionIncrement) / RATE_BASE),
                'bid price too low'
            );

            uint256 incentive = (price * incentiveRate) / RATE_BASE;
            _transfer(currency, auc.buyer, auc.netPrice + incentive);
            emit EvAuctionRefund(id, auc.buyer, auc.netPrice + incentive);

            auc.buyer = buyer;
            auc.price = price;
            auc.netPrice = price - incentive;

            if (block.timestamp + minAuctionDuration >= auc.deadline) {
                auc.deadline += minAuctionDuration;
            }
        } else {
            require(!hasInv(id), 'inventory is not auction');
            require(price >= startPrice, 'bid lower than start price');
            require(deadline > block.timestamp, 'auction ended');

            uint256 deadline0 = deadline;
            if (block.timestamp + minAuctionDuration >= deadline) {
                deadline0 += minAuctionDuration;
            }

            inventories[id] = Inventory({
                seller: seller,
                buyer: buyer,
                currency: currency,
                price: price,
                netPrice: price,
                deadline: deadline0,
                status: STATUS_OPEN,
                kind: KIND_AUCTION
            });
            _saveBundle(id, bundle);
            _transferBundle(id, seller, address(this), false);
        }
        emit EvInventoryUpdate(id, inventories[id]);
    }

    function _completeAuction(uint256 id, Settlement calldata settlement) internal {
        require(inventories[id].deadline < block.timestamp, 'auction still going');
        _acceptAuction(id, settlement);
    }

    function _acceptAuction(uint256 id, Settlement calldata settlement) internal {
        require(isAuction(id), 'auction does not exist');
        require(isStatusOpen(id), 'auction not open');
        Inventory storage auc = inventories[id];

        auc.status = STATUS_DONE;
        emit EvInventoryUpdate(id, inventories[id]);
        _transferBundle(id, address(this), auc.buyer, true);
        _completeTransaction(id, settlement);
    }

    function _completeTransaction(uint256 id, Settlement calldata settlement) internal {
        Inventory storage inv = inventories[id];
        require(hasInv(id) && inv.status == STATUS_DONE, 'no inventory or state error'); // sanity

        _markCoupon(id, settlement.coupons);

        uint256 price = inv.price;
        uint256 fee = (price * settlement.feeRate) / RATE_BASE;
        uint256 royalty = (price * settlement.royaltyRate) / RATE_BASE;
        uint256 buyerAmount = (price * settlement.buyerCashbackRate) / RATE_BASE;
        uint256 sellerAmount = inv.netPrice - fee - royalty - buyerAmount;

        _transfer(inv.currency, inv.seller, sellerAmount);
        _transfer(inv.currency, inv.buyer, buyerAmount);
        _transfer(inv.currency, settlement.feeAddress, fee);
        _transfer(inv.currency, settlement.royaltyAddress, royalty);
    }

    function _markCoupon(uint256 invId, uint256[] calldata coupons) internal {
        for (uint256 i = 0; i < coupons.length; i++) {
            uint256 id = coupons[i];
            require(!couponSpent[id], 'coupon already spent');
            couponSpent[id] = true;
            emit EvCouponSpent(invId, id);
        }
    }

    function _isNative(IERC20 currency) internal pure returns (bool) {
        return address(currency) == address(0);
    }

    function _transfer(
        IERC20 currency,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }
        require(to != address(0), 'cannot transfer to address(0)');
        if (_isNative(currency)) {
            weth.withdraw(amount);
            payable(to).transfer(amount);
        } else {
            currency.safeTransfer(to, amount);
        }
    }

    function _transferBundle(
        uint256 invId,
        address from,
        address to,
        bool doMint
    ) internal {
        uint256 tokenCount = inventoryTokenCounts[invId];
        for (uint256 i = 0; i < tokenCount; i++) {
            TokenPair storage p = inventoryTokens[invId][i];
            if (p.kind == TOKEN_MINT) {
                if (doMint) {
                    // sanity check
                    require(
                        to != address(0) && to != address(this),
                        'mint target cannot be zero or market'
                    );
                    IMintable(p.token).mint(to, p.mintData);
                }
            } else if (p.kind == TOKEN_721) {
                IERC721(p.token).safeTransferFrom(from, to, p.tokenId);
            } else if (p.kind == TOKEN_1155) {
                IERC1155(p.token).safeTransferFrom(from, to, p.tokenId, p.amount, '');
            } else {
                revert('unsupported token');
            }
        }
    }

    // public helpers

    // also checks the right owner
    function isBundleApproved(uint256 invId, address owner) public view returns (bool) {
        require(hasInv(invId), 'no inventory');

        for (uint256 i = 0; i < inventoryTokenCounts[invId]; i++) {
            TokenPair storage p = inventoryTokens[invId][i];
            if (p.kind == TOKEN_MINT) {
                // pass
            } else if (p.kind == TOKEN_721) {
                IERC721 t = IERC721(p.token);
                if (
                    t.ownerOf(p.tokenId) == owner &&
                    (t.getApproved(p.tokenId) == address(this) ||
                        t.isApprovedForAll(owner, address(this)))
                ) {
                    // pass
                } else {
                    return false;
                }
            } else if (p.kind == TOKEN_1155) {
                IERC1155 t = IERC1155(p.token);
                if (
                    t.balanceOf(owner, p.tokenId) >= p.amount &&
                    t.isApprovedForAll(owner, address(this))
                ) {
                    // pass
                } else {
                    return false;
                }
            } else {
                revert('unsupported token');
            }
        }
        return true;
    }

    function isAuctionOpen(uint256 id) public view returns (bool) {
        return
            isAuction(id) &&
            inventories[id].status == STATUS_OPEN &&
            inventories[id].deadline > block.timestamp;
    }

    function isBuyOpen(uint256 id) public view returns (bool) {
        return
            isBuy(id) &&
            inventories[id].status == STATUS_OPEN &&
            inventories[id].deadline > block.timestamp;
    }

    function isAuction(uint256 id) public view returns (bool) {
        return inventories[id].kind == KIND_AUCTION;
    }

    function isBuy(uint256 id) public view returns (bool) {
        return inventories[id].kind == KIND_BUY;
    }

    function isSell(uint256 id) public view returns (bool) {
        return inventories[id].kind == KIND_SELL;
    }

    function hasInv(uint256 id) public view returns (bool) {
        return inventories[id].kind != 0;
    }

    function isStatusOpen(uint256 id) public view returns (bool) {
        return inventories[id].status == STATUS_OPEN;
    }

    function isExpired(uint256 id) public view returns (bool) {
        return block.timestamp >= inventories[id].deadline;
    }

    function isSignatureValid(
        bytes memory signature,
        bytes32 hash,
        address signer
    ) public pure returns (bool) {
        // verify hash signed via `personal_sign`
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature) == signer;
    }

    function hasSignedIntention(uint8 op) public pure returns (bool) {
        return op != OP_BUY && op != OP_CANCEL_BUY && op != OP_ACCEPT_BUY && op != OP_REJECT_BUY;
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IMintable {
    function mint(address to, bytes memory data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

import "../../utils/introspection/IERC165.sol";

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
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}