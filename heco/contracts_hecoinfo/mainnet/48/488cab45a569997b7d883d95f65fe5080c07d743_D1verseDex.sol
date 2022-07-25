/**
 *Submitted for verification at hecoinfo.com on 2022-05-14
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org
// SPDX-License-Identifier: MIT
// File @openzeppelin/contracts/token/ERC20/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/interfaces/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts/interfaces/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}


// File contracts/ILazyMint.sol

// License-Identifier: MIT
pragma solidity ^0.8.9;

interface ILazyMint {
    function exists(uint256 tokenId) external view returns (bool);
    function lazyMint(address to, uint256 tokenId, address receiver, uint96 royaltyRate) external;
    function setRoyaltyInfo(uint256 tokenId, address receiver, uint96 royaltyRate) external;
}


// File contracts/D1verseDex.sol

// License-Identifier: MIT
pragma solidity ^0.8.9;



contract D1verseDex {

    bytes32 public constant HashEIP712Domain = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant HashOrderStruct = keccak256(
        "FixedPriceOrder(address taker,address maker,uint256 maker_nonce,uint64 listing_time,uint64 expiration_time,address nft_contract,uint256 token_id,address payment_token,uint256 fixed_price,uint96 royalty_rate,address royalty_recipient)"
    );
    bytes32 public HashEIP712Version;
    bytes32 public HashEIP712Name;
    string public name;
    string public version;

    address public dexDAO;
    mapping(address => bool) public operators;
    mapping(address => bool) public D1verseNFT;

    uint256 constant public feeDenominator = 1000000000; // 1,000,000,000
    uint256 public maxRoyaltyRate = feeDenominator / 10; // 10%
    uint256 public feeRate = 20000000;  // 20,000,000 / 1,000,000,000 == 2%
    address public feeRecipient;

    mapping(address => bool) public allowedNft;
    bool public allNftAllowed;
    mapping(address => uint256) public allowedPayment;
    mapping(bytes32 => bool) public finalizedOrder;
    mapping(address => uint256) public userNonce;
    mapping(address => mapping(bytes32 => bool)) public canceledOrder;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    struct OrderQuery {
        uint8 state;
        bytes32 digest;
        bytes bys;
    }

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    
    // OrderType: FixedPrice; EnglishAuction; DutchAuction
    // D1verseNFT TokenID(256bit) => | 160bit(CreatorAddress) | 48bit(CollectionID) | 48bit(InternalTokenID) |
    struct FixedPriceOrder {
        address taker; // address(0) means anyone can trade
        address maker;
        uint256 maker_nonce;
        uint64 listing_time;
        uint64 expiration_time;
        address nft_contract;
        uint256 token_id;
        address payment_token; // address(0) means the coin of the public chain (ETH, HT, MATIC...)
        uint256 fixed_price;
        uint96 royalty_rate;
        address royalty_recipient;
    }

    event OrderCancelled(address indexed maker, bytes32 indexed order_digest);
    event AllOrdersCancelled(address indexed maker, uint256 current_nonce);
    event FixedPriceOrderMatched(address tx_origin, address taker, address maker, bytes32 order_digest, bytes order_bytes); // FixedPriceOrder order);

    modifier onlyDAO() {
        require(dexDAO == msg.sender, "Caller is not DEX-DAO");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender] || msg.sender == dexDAO, "Caller is not Operator nor DEX-DAO");
        _;
    }

    constructor (string memory _name, string memory _version, address _feeRecipient, address _dexDAO, uint256 min_price) {
        dexDAO = _dexDAO;
        feeRecipient = _feeRecipient;
        allNftAllowed = false;
        allowedPayment[address(0)] = min_price;
        name = _name;
        version = _version;
        HashEIP712Name = keccak256(bytes(name));
        HashEIP712Version = keccak256(bytes(version));
        _status = _NOT_ENTERED;
    }

    function setDexDAO(address _dexDAO) external onlyDAO {
        dexDAO = _dexDAO;
    }

    function setOperator(address addr, bool flag) external onlyDAO {
        if (!flag) {
            delete operators[addr];
        } else {
            operators[addr] = true;
        }
    }

    function setNameVersion(string memory _name, string memory _version) external onlyDAO {
        name = _name;
        version = _version;
        HashEIP712Name = keccak256(bytes(name));
        HashEIP712Version = keccak256(bytes(version));
    }

    function setFeeRate(uint256 _feeRate) external onlyDAO {
        require(_feeRate <= feeDenominator, "Fee rate is too high");
        feeRate = _feeRate;
    }

    function setFeeRecipient(address _feeRecipient) external onlyDAO {
        require(_feeRecipient != address(0), "Fee recipient rate is address(0)");
        feeRecipient = _feeRecipient;
    }

    function setMaxRoyaltyRate(uint256 _maxRoyaltyRate) external onlyDAO {
        require(_maxRoyaltyRate <= feeDenominator, "Royalty rate is too high");
        maxRoyaltyRate = _maxRoyaltyRate;
    }

    function setAllNftAllowed(bool _allNftAllowed) external onlyOperator {
        allNftAllowed = _allNftAllowed;
    }

    function setNftAllowed(address _contract, bool flag) external onlyOperator {
        if (!flag) {
            delete allowedNft[_contract];
        } else {
            allowedNft[_contract] = true;
        }
    }

    function setPaymentAllowed(address _contract, uint256 min_price) external onlyOperator {
        if (min_price == 0) {
            delete allowedPayment[_contract];
        } else {
            allowedPayment[_contract] = min_price;
        }
    }

    function setD1verseNFT(address _contract, bool flag) external onlyOperator {
        if (!flag) {
            delete allowedNft[_contract];
            delete D1verseNFT[_contract];
        } else {
            D1verseNFT[_contract] = true;
            allowedNft[_contract] = true;
        }
    }

    function exchangeFixedPrice(
        bool maker_sells_nft,
        address taker,
        FixedPriceOrder memory order,
        Sig memory maker_sig,
        Sig memory taker_sig
    ) external payable nonReentrant {

        (bytes32 order_digest, bytes memory order_bytes) = checkOrder(taker, order, maker_sig, taker_sig);

        address nft_seller = order.maker;
        address nft_buyer = taker;
        if (!maker_sells_nft) {
            nft_seller = taker;
            nft_buyer = order.maker;
        }

        if (D1verseNFT[order.nft_contract]) {
            if (!ILazyMint(order.nft_contract).exists(order.token_id)) {
                require(address(uint160(order.token_id >> 96)) == nft_seller, "TokenID's address part doesn't match creator/seller");
                ILazyMint(order.nft_contract).lazyMint(nft_buyer, order.token_id, order.royalty_recipient, order.royalty_rate);
            } else {
                checkRoyaltyInfo(order);
                IERC721(order.nft_contract).transferFrom(nft_seller, nft_buyer, order.token_id);
            }
        } else {
            checkNFT(order, nft_seller);
            IERC721(order.nft_contract).transferFrom(nft_seller, nft_buyer, order.token_id);
        }

        payToken(order, nft_seller, nft_buyer);

        finalizedOrder[order_digest] = true;

        emit FixedPriceOrderMatched(tx.origin, taker, order.maker, order_digest, order_bytes);

    }

    function checkOrder(
        address taker,
        FixedPriceOrder memory order,
        Sig memory maker_sig,
        Sig memory taker_sig
    ) public view returns(bytes32 order_digest, bytes memory order_bytes) {
        address maker = order.maker;
        if (order.taker != address(0)) {
            require(taker == order.taker, "Taker is not the one set by maker");
        }
        require(maker != taker, "Taker is same as maker");
        require(maker != address(0) && taker != address(0), "Maker or Taker is address(0)");
        require(order.expiration_time >= block.timestamp && order.listing_time <= block.timestamp, "Time error");
        require(order.maker_nonce == userNonce[maker], "Maker nonce doesn't match");
        require(order.royalty_rate <= maxRoyaltyRate, "Royalty rate is too high");
        require(allNftAllowed || allowedNft[order.nft_contract], "NFT contract is not supported");
        uint256 min_price = allowedPayment[order.payment_token];
        require(order.fixed_price > min_price && min_price > 0, "Payment token contract is not supported or price is too low");

        order_bytes = fixedPriceOrderEIP712Encode(order);
        order_digest = _hashTypedDataV4(keccak256(order_bytes));

        require((!finalizedOrder[order_digest]) && (!canceledOrder[maker][order_digest]) && (!canceledOrder[taker][order_digest]), "The order is finalized or canceled");
        require(maker == ecrecover(order_digest, maker_sig.v, maker_sig.r, maker_sig.s), "Maker's signature doesn't match");
        require(taker == ecrecover(order_digest, taker_sig.v, taker_sig.r, taker_sig.s), "Taker's signature doesn't match");

        return (order_digest, order_bytes);
    }

    function checkNFT(FixedPriceOrder memory order, address nft_seller) public view {
        address nft_owner = IERC721(order.nft_contract).ownerOf(order.token_id); // May Revert!!!
        require(nft_owner == nft_seller, "The NFT seller is not the NFT owner");
        try IERC721(order.nft_contract).supportsInterface(type(IERC2981).interfaceId) returns (bool support) {
            if (support) {
                checkRoyaltyInfo(order);
            }
        } catch {

        }
    }

    function checkRoyaltyInfo(FixedPriceOrder memory order) private view {
        uint256 royalty_amount = order.fixed_price * order.royalty_rate / feeDenominator;
        (address receiver, uint256 royaltyAmount) = IERC2981(order.nft_contract).royaltyInfo(order.token_id, order.fixed_price);
        if (royaltyAmount != 0 || receiver != address(0)) {
            require(order.royalty_recipient == receiver && royalty_amount >= royaltyAmount, "Royalty information doesn't match");
        }
    }

    function checkOrderAndNFT(
        bool maker_sells_nft,
        address taker,
        FixedPriceOrder memory order,
        Sig memory maker_sig,
        Sig memory taker_sig
    ) external view returns(bytes32, bytes memory) {
        (bytes32 order_digest, bytes memory order_bytes) = checkOrder(taker, order, maker_sig, taker_sig);

        address nft_seller = order.maker;
        address nft_buyer = taker;
        if (!maker_sells_nft) {
            nft_seller = taker;
            nft_buyer = order.maker;
        }

        if (!D1verseNFT[order.nft_contract] || ILazyMint(order.nft_contract).exists(order.token_id)) {
            address nft_owner = IERC721(order.nft_contract).ownerOf(order.token_id); // May Revert!!!
            require(nft_owner == nft_seller, "The NFT seller is not the NFT owner");
        }

        try IERC721(order.nft_contract).supportsInterface(type(IERC2981).interfaceId) returns (bool support) {
            if (support) {
                checkRoyaltyInfo(order);
            }
        } catch {

        }

        uint256 approved_amount;
        if (order.payment_token == address(0)) {
            approved_amount = nft_buyer.balance;
        } else {
            approved_amount = IERC20(order.payment_token).allowance(nft_buyer, address(this));
        }
        require(approved_amount >= order.fixed_price, "NFT buyer's balance or approved-amount is not enough");

        return (order_digest, order_bytes);
    }

    function orderStateWithDigest(address maker, address taker, uint256 order_nonce, bytes32 order_digest) public view returns(uint8) {
        uint8 order_state = 0;
        if (finalizedOrder[order_digest]) {
            order_state = 1;
        } else if (order_nonce != userNonce[maker]) {
            order_state = 2;
        } else if (canceledOrder[maker][order_digest]) {
            order_state = 3;
        } else if (canceledOrder[taker][order_digest]) {
            order_state = 4;
        }
        return order_state;
    }

//    function orderStateWithDigestBatch(
//        address[] memory makers,
//        address[] memory takers,
//        uint256[] memory order_nonces,
//        bytes32[] memory order_digests
//    ) external view returns(uint8[] memory) {
//        require(
//            order_digests.length == makers.length &&
//            order_digests.length == takers.length &&
//            order_digests.length == order_nonces.length,
//            "Array.length Error"
//        );
//        uint8[] memory order_state_array = new uint8[](order_digests.length);
//        for (uint256 i = 0; i < order_digests.length; i++) {
//            order_state_array[i] = orderStateWithDigest(makers[i], takers[i], order_nonces[i], order_digests[i]);
//        }
//        return order_state_array;
//    }

    function orderState(FixedPriceOrder memory order) external view returns(OrderQuery memory) {
        bytes memory order_bytes = fixedPriceOrderEIP712Encode(order);
        bytes32 order_digest = _hashTypedDataV4(keccak256(order_bytes));
        uint8 order_state = orderStateWithDigest(order.maker, order.taker, order.maker_nonce, order_digest);
        return OrderQuery(order_state, order_digest, order_bytes);
    }

//    function orderStateBatch(FixedPriceOrder[] memory orders) external view returns(OrderQuery[] memory) {
//        OrderQuery[] memory order_query_array = new OrderQuery[](orders.length);
//        for (uint256 i = 0; i < orders.length; i++) {
//            order_query_array[i] = orderState(orders[i]);
//        }
//        return order_query_array;
//    }

    function payToken(FixedPriceOrder memory order, address nft_seller, address nft_buyer) private {
        uint256 royalty_amount = order.fixed_price * order.royalty_rate / feeDenominator;
        uint256 platform_amount = order.fixed_price * feeRate / feeDenominator;
        uint256 remain_amount = order.fixed_price  - (royalty_amount + platform_amount);

        if (order.payment_token != address(0)) {
            require(msg.value == 0, "Msg.value should be zero");
            require(IERC20(order.payment_token).transferFrom(nft_buyer, order.royalty_recipient, royalty_amount), "Token payment (royalty fee) failed");
            require(IERC20(order.payment_token).transferFrom(nft_buyer, feeRecipient, platform_amount), "Token payment (platform fee) failed");
            require(IERC20(order.payment_token).transferFrom(nft_buyer, nft_seller, remain_amount), "Token payment (to seller) failed");
        } else {
            require(msg.value >= order.fixed_price, "Msg.value is not enough");
            if (msg.value > order.fixed_price) {
                sendValue(payable(msg.sender), msg.value - order.fixed_price);
            }
            sendValue(payable(order.royalty_recipient), royalty_amount);
            sendValue(payable(feeRecipient), platform_amount);
            sendValue(payable(nft_seller), remain_amount);
        }
    }

    // openzeppelin/contracts/utils/Address.sol
    function sendValue(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send value, recipient may have reverted");
    }

    function cancelOrder(bytes32 order_digest) external {
        require(!finalizedOrder[order_digest], "Order is finalized");
        canceledOrder[msg.sender][order_digest] = true;

        emit OrderCancelled(msg.sender, order_digest);
    }

    function cancelAllOrders() external {
        ++userNonce[msg.sender];
        uint256 nonce = userNonce[msg.sender];

        emit AllOrdersCancelled(msg.sender, nonce);
    }

//    // https://eips.ethereum.org/EIPS/eip-712
//    function fixedPriceOrderDigest(FixedPriceOrder memory order) public view returns(bytes32) {
//        bytes memory order_bytes = fixedPriceOrderEIP712Encode(order);
//        bytes32 order_digest = _hashTypedDataV4(keccak256(order_bytes));
//        return order_digest;
//    }

    // https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct
    function fixedPriceOrderEIP712Encode(FixedPriceOrder memory order) internal pure returns(bytes memory) {
        bytes memory order_bytes = abi.encode(
            HashOrderStruct,
            order.taker,
            order.maker,
            order.maker_nonce,
            order.listing_time,
            order.expiration_time,
            order.nft_contract,
            order.token_id,
            order.payment_token,
            order.fixed_price,
            order.royalty_rate,
            order.royalty_recipient
        );
        return order_bytes;
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        // return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
        return _toTypedDataHash(_domainSeparatorV4(), structHash);
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
    function _toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return keccak256(abi.encode(HashEIP712Domain, HashEIP712Name, HashEIP712Version, block.chainid, address(this)));
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

    // openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol
    // openzeppelin/contracts/utils/cryptography/draft-EIP712.sol
    // openzeppelin/contracts/security/ReentrancyGuard.sol

}