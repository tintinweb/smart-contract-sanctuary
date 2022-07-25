// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "./ILazyMint.sol";

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

        require(order.expiration_time >= block.timestamp && order.listing_time <= block.timestamp, "Time error");
        require(order.maker_nonce == userNonce[maker], "Maker nonce doesn't match");
        require(order.royalty_rate <= maxRoyaltyRate, "Royalty rate is too high");
        require(allNftAllowed || allowedNft[order.nft_contract], "NFT contract is not supported");
        uint256 min_price = allowedPayment[order.payment_token];
        require(order.fixed_price >= min_price && min_price > 0, "Payment token contract is not supported or price is too low");

        order_bytes = fixedPriceOrderEIP712Encode(order);
        order_digest = _hashTypedDataV4(keccak256(order_bytes));
        require((!finalizedOrder[order_digest]) && (!canceledOrder[maker][order_digest]) && (!canceledOrder[taker][order_digest]), "The order is finalized or canceled");
        checkSignature(order_digest, maker, maker_sig);
        checkSignature(order_digest, taker, taker_sig);

        return (order_digest, order_bytes);
    }

    // https://ethereum.stackexchange.com/questions/83174/is-it-best-practice-to-check-signature-malleability-in-ecrecover
    // https://crypto.iacr.org/2019/affevents/wac/medias/Heninger-BiasedNonceSense.pdf
    function checkSignature(bytes32 digest, address signer, Sig memory signature) public pure {
        require(signer != address (0), "Invalid signer");
        require(uint256(signature.s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Invalid s parameter");
        require(signature.v == 27 || signature.v == 28, "Invalid v parameter");
        require(signer == ecrecover(digest, signature.v, signature.r, signature.s), "Invalid signature");
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ILazyMint {
    function exists(uint256 tokenId) external view returns (bool);
    function lazyMint(address to, uint256 tokenId, address receiver, uint96 royaltyRate) external;
    function setRoyaltyInfo(uint256 tokenId, address receiver, uint96 royaltyRate) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "./ILazyMint.sol";

interface Burnable {
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract D1verseNFT is IERC721, IERC721Metadata, IERC2981, ILazyMint {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    uint256 private _totalSupply;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 constant public feeDenominator = 1000000000;

    mapping(address => bool) public D1verseDEX;

    address public nftDAO;

    mapping(address => bool) public operators;

    string public baseURI;

    address public contractURI;

    address public migration = 0xD21E29e051C9a993215FCa7d70fbD03012AFafd4;

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyRate;
    }

    // TokenID => RoyaltyInfo
    mapping(uint256 => RoyaltyInfo) private _royaltyInfo;

    event RoyaltyInfoSet(uint256 indexed tokenId, address receiver, uint96 royaltyRate);

    modifier onlyD1verseDEX() {
        require(D1verseDEX[msg.sender], "Caller is not NFT Dex Contract");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == nftDAO, "Caller is not NFT-DAO");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender] || msg.sender == nftDAO, "Caller is not Operator nor NFT-DAO");
        _;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    constructor(address nft_dao, string memory nft_name, string memory nft_symbol, string memory base_uri) {
        nftDAO = nft_dao;
        _name = nft_name;
        _symbol = nft_symbol;
        baseURI = base_uri;
    }

    function setNftDao(address nft_dao) external onlyDAO {
        nftDAO = nft_dao;
    }

    function setOperator(address addr, bool flag) external onlyDAO {
        if (!flag) {
            delete operators[addr];
        } else {
            operators[addr] = true;
        }
    }

    function setNftName(string memory nft_name) external onlyDAO {
        _name = nft_name;
    }

    function setNftSymbol(string memory nft_symbol) external onlyDAO {
        _symbol = nft_symbol;
    }

    function setContractURI(address contract_uri) external onlyOperator {
        contractURI = contract_uri;
    }

    function setBaseURI(string memory base_uri) external onlyOperator {
        baseURI = base_uri;
    }

    function setD1verseDex(address addr, bool flag) external onlyOperator {
        if (!flag) {
            delete D1verseDEX[addr];
        } else {
            D1verseDEX[addr] = true;
        }
    }

    function setMigration(address migration_contract) external onlyOperator {
        migration = migration_contract;
    }

    function migrate(uint256[] memory tokenIds, bool burn_old) external onlyDAO {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ILazyMint(migration).lazyMint(
                ownerOf(tokenIds[i]),
                tokenIds[i],
                _royaltyInfo[tokenIds[i]].receiver,
                _royaltyInfo[tokenIds[i]].royaltyRate
            );
            if (burn_old) {
                _burn(tokenIds[i]);
            }
        }
    }

    function migrateFrom(bool burn_old, uint256 begin_id, uint96 royaltyRate, uint256[] memory tokenIds) external onlyOperator {
        address[] memory recipients = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 old_id = begin_id + i;
            recipients[i] = Burnable(migration).ownerOf(old_id);
            if (burn_old) {
                Burnable(migration).burn(old_id);
            }
        }
        mintToRecipients(recipients, tokenIds, royaltyRate);
    }

    function mintToRecipients(address[] memory recipients, uint256[] memory tokenIds, uint96 royaltyRate) public onlyOperator {
        require(recipients.length == tokenIds.length, "Length mismatch");
        for (uint i = 0; i < recipients.length; ++i) {
            // _mint(recipients[i], tokenIds[i]);
            address creator = address(uint160(tokenIds[i] >> 96));
            require(recipients[i] != address(0), "ERC721: mint to the zero address");
            require(!_exists(tokenIds[i]), "ERC721: token already minted");

            _balances[recipients[i]] += 1;
            _owners[tokenIds[i]] = recipients[i];
            _totalSupply += 1;

            emit Transfer(address(0), creator, tokenIds[i]);
            if (creator != recipients[i]) {
                emit Transfer(creator, recipients[i], tokenIds[i]);
            }

            _setRoyaltyInfo(tokenIds[i], creator, royaltyRate);
        }
    }

    function mintToCreators(uint256[] memory tokenIds, uint96 royaltyRate) external onlyOperator {
        for (uint i = 0; i < tokenIds.length; ++i) {
            address creator= address(uint160(tokenIds[i] >> 96));
            _mint(creator, tokenIds[i]);
            _setRoyaltyInfo(tokenIds[i], creator, royaltyRate);
        }
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
        interfaceId == type(IERC165).interfaceId ||
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC2981).interfaceId ||
        interfaceId == type(ILazyMint).interfaceId;
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (contractURI != address(0)) {
            return IERC721Metadata(contractURI).tokenURI(tokenId);
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        // _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        _totalSupply += 1;

        emit Transfer(address(0), to, tokenId);

        // _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);

        // _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        delete _royaltyInfo[tokenId];

        _balances[owner] -= 1;
        delete _owners[tokenId];
        _totalSupply -= 1;

        emit Transfer(owner, address(0), tokenId);

        // _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        // _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        uint256 royaltyAmount = (salePrice * _royaltyInfo[tokenId].royaltyRate) / feeDenominator;
        address receiver = _royaltyInfo[tokenId].receiver;
        return (receiver, royaltyAmount);
    }

    function _setRoyaltyInfo(uint256 tokenId, address receiver, uint96 royaltyRate) internal {
        _royaltyInfo[tokenId] = RoyaltyInfo(receiver, royaltyRate);
        emit RoyaltyInfoSet(tokenId, receiver, royaltyRate);
    }

    function setRoyaltyInfo(uint256 tokenId, address receiver, uint96 royaltyRate) public onlyD1verseDEX {
        _setRoyaltyInfo(tokenId, receiver, royaltyRate);
    }

    function lazyMint(address to, uint256 tokenId, address receiver, uint96 royaltyRate) external onlyD1verseDEX {
        // _mint(to, tokenId);
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;
        _totalSupply += 1;

        _setRoyaltyInfo(tokenId, receiver, royaltyRate);

        address creator = address(uint160(tokenId >> 96));
        emit Transfer(address(0), creator, tokenId);
        if (creator != to) {
            emit Transfer(creator, to, tokenId);
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint8 private _decimals;
    string private _name;
    string private _symbol;

    uint256 private _totalSupply;

    address public deployer;
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(uint8 decimals_, string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        deployer = _msgSender();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
    }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function mint(address account, uint256 amount) public virtual {
        require(_msgSender() == deployer, "ERC20: minter is not admin/deployer");
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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