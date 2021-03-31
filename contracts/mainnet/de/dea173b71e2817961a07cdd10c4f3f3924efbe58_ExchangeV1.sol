pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./libs.sol";
import "./Roles.sol";
import "./ERC165.sol";
import "./IERC20.sol";
import "./TransferProxy.sol";

/// @title ExchangeDomainV1
/// @notice Describes all the structs that are used in exchnages.
contract ExchangeDomainV1 {

    enum AssetType {ETH, ERC20, ERC1155, ERC721, ERC721Deprecated}

    struct Asset {
        address token;
        uint tokenId;
        AssetType assetType;
    }

    struct OrderKey {
        /* who signed the order */
        address owner;
        /* random number */
        uint salt;

        /* what has owner */
        Asset sellAsset;

        /* what wants owner */
        Asset buyAsset;
    }

    struct Order {
        OrderKey key;

        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint buying;

        /* fee for selling. Represented as percents * 100 (100% - 10000. 1% - 100)*/
        uint sellerFee;
    }

    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }
}

/// @title ExchangeStateV1
/// @notice Tracks the amount of selled tokens in the order.
contract ExchangeStateV1 is OwnableOperatorRole {

    // keccak256(OrderKey) => completed
    mapping(bytes32 => uint256) public completed;

    /// @notice Get the amount of selled tokens.
    /// @param key - the `OrderKey` struct.
    /// @return Selled tokens count for the order.
    function getCompleted(ExchangeDomainV1.OrderKey calldata key) view external returns (uint256) {
        return completed[getCompletedKey(key)];
    }

    /// @notice Sets the new amount of selled tokens. Can be called only by the contract operator.
    /// @param key - the `OrderKey` struct.
    /// @param newCompleted - The new value to set.
    function setCompleted(ExchangeDomainV1.OrderKey calldata key, uint256 newCompleted) external onlyOperator {
        completed[getCompletedKey(key)] = newCompleted;
    }

    /// @notice Encode order key to use as the mapping key.
    /// @param key - the `OrderKey` struct.
    /// @return Encoded order key.
    function getCompletedKey(ExchangeDomainV1.OrderKey memory key) pure public returns (bytes32) {
        return keccak256(abi.encodePacked(key.owner, key.sellAsset.token, key.sellAsset.tokenId, key.buyAsset.token, key.buyAsset.tokenId, key.salt));
    }
}

/// @title ExchangeOrdersHolderV1
/// @notice Optionally holds orders, which can be exchanged without order's holder signature.
contract ExchangeOrdersHolderV1 {

    mapping(bytes32 => OrderParams) internal orders;

    struct OrderParams {
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint buying;

        /* fee for selling */
        uint sellerFee;
    }

    /// @notice This function can be called to add the order to the contract, so it can be exchanged without signature.
    ///         Can be called only by the order owner.
    /// @param order - The order struct to add.
    function add(ExchangeDomainV1.Order calldata order) external {
        require(msg.sender == order.key.owner, "order could be added by owner only");
        bytes32 key = prepareKey(order);
        orders[key] = OrderParams(order.selling, order.buying, order.sellerFee);
    }

    /// @notice This function checks if order was added to the orders holder contract.
    /// @param order - The order struct to check.
    /// @return true if order is present in the contract's data.
    function exists(ExchangeDomainV1.Order calldata order) external view returns (bool) {
        bytes32 key = prepareKey(order);
        OrderParams memory params = orders[key];
        return params.buying == order.buying && params.selling == order.selling && params.sellerFee == order.sellerFee;
    }

    function prepareKey(ExchangeDomainV1.Order memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                order.key.sellAsset.token,
                order.key.sellAsset.tokenId,
                order.key.owner,
                order.key.buyAsset.token,
                order.key.buyAsset.tokenId,
                order.key.salt
            ));
    }
}

/// @title Token Exchange contract.
/// @notice Supports ETH, ERC20, ERC721 and ERC1155 tokens.
/// @notice This contracts relies on offchain signatures for order and fees verification.
contract ExchangeV1 is Ownable, ExchangeDomainV1 {
    using SafeMath for uint;
    using UintLibrary for uint;
    using StringLibrary for string;
    using BytesLibrary for bytes32;

    enum FeeSide {NONE, SELL, BUY}

    event Buy(
        address indexed sellToken, uint256 indexed sellTokenId, uint256 sellValue,
        address owner,
        address buyToken, uint256 buyTokenId, uint256 buyValue,
        address buyer,
        uint256 amount,
        uint256 salt
    );

    event Cancel(
        address indexed sellToken, uint256 indexed sellTokenId,
        address owner,
        address buyToken, uint256 buyTokenId,
        uint256 salt
    );

    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
    uint256 private constant UINT256_MAX = 2 ** 256 - 1;

    address payable public beneficiary;
    address public buyerFeeSigner;

    /// @notice The address of a transfer proxy for ERC721 and ERC1155 tokens.
    TransferProxy public transferProxy;
    /// @notice The address of a transfer proxy for deprecated ERC721 tokens. Does not use safe transfer.
    TransferProxyForDeprecated public transferProxyForDeprecated;
    /// @notice The address of a transfer proxy for ERC20 tokens.
    ERC20TransferProxy public erc20TransferProxy;
    /// @notice The address of a state contract, which counts the amount of selled tokens.
    ExchangeStateV1 public state;
    /// @notice The address of a orders holder contract, which can contain unsigned orders.
    ExchangeOrdersHolderV1 public ordersHolder;

    /// @notice Contract constructor.
    /// @param _transferProxy - The address of a deployed TransferProxy contract.
    /// @param _transferProxyForDeprecated - The address of a deployed TransferProxyForDeprecated contract.
    /// @param _erc20TransferProxy - The address of a deployed ERC20TransferProxy contract.
    /// @param _state - The address of a deployed ExchangeStateV1 contract.
    /// @param _ordersHolder - The address of a deployed ExchangeOrdersHolderV1 contract.
    /// @param _beneficiary - The address wich will receive collected fees.
    /// @param _buyerFeeSigner - The address to sign buyer's fees for orders.
    constructor(
        TransferProxy _transferProxy, TransferProxyForDeprecated _transferProxyForDeprecated, ERC20TransferProxy _erc20TransferProxy, ExchangeStateV1 _state,
        ExchangeOrdersHolderV1 _ordersHolder, address payable _beneficiary, address _buyerFeeSigner
    ) public {
        transferProxy = _transferProxy;
        transferProxyForDeprecated = _transferProxyForDeprecated;
        erc20TransferProxy = _erc20TransferProxy;
        state = _state;
        ordersHolder = _ordersHolder;
        beneficiary = _beneficiary;
        buyerFeeSigner = _buyerFeeSigner;
    }

    /// @notice This function is called by contract owner and sets fee receiver address.
    /// @param newBeneficiary - new address, who where all the fees will be transfered
    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        beneficiary = newBeneficiary;
    }

    /// @notice This function is called by contract owner and sets fee signer address.
    /// @param newBuyerFeeSigner - new address, which will sign buyer's fees for orders
    function setBuyerFeeSigner(address newBuyerFeeSigner) external onlyOwner {
        buyerFeeSigner = newBuyerFeeSigner;
    }

    /// @notice This function is called to execute the exchange.
    /// @notice ERC20, ERC721 or ERC1155 tokens from buyer's or seller's side must be approved for this contract before calling this function.
    /// @notice To pay with ETH, transaction must send ether within the calling transaction.
    /// @notice Buyer's payment value is calculated as `order.buying * amount / order.selling + buyerFee%`.
    /// @dev Emits Buy event.
    /// @param order - Order struct (see ExchangeDomainV1).
    /// @param sig - Signed order message. To generate the message call `prepareMessage` function.
    ///        Message must be prefixed with: `"\x19Ethereum Signed Message:\n" + message.length`.
    ///        For example, web3.accounts.sign will automatically prefix the message.
    ///        Also, the signature might be all zeroes, if specified order record was added to the ordersHolder.
    /// @param buyerFee - Amount for buyer's fee. Represented as percents * 100 (100% => 10000. 1% => 100).
    /// @param buyerFeeSig - Signed order + buyerFee message. To generate the message call prepareBuyerFeeMessage function.
    ///        Message must be prefixed with: `"\x19Ethereum Signed Message:\n" + message.length`.
    ///        For example, web3.accounts.sign will automatically prefix the message.
    /// @param amount - Amount of tokens to buy.
    /// @param buyer - The buyer's address.
    function exchange(
        Order calldata order,
        Sig calldata sig,
        uint buyerFee,
        Sig calldata buyerFeeSig,
        uint amount,
        address buyer
    ) payable external {
        validateOrderSig(order, sig);
        validateBuyerFeeSig(order, buyerFee, buyerFeeSig);
        uint paying = order.buying.mul(amount).div(order.selling);
        verifyOpenAndModifyOrderState(order.key, order.selling, amount);
        require(order.key.sellAsset.assetType != AssetType.ETH, "ETH is not supported on sell side");
        if (order.key.buyAsset.assetType == AssetType.ETH) {
            validateEthTransfer(paying, buyerFee);
        }
        FeeSide feeSide = getFeeSide(order.key.sellAsset.assetType, order.key.buyAsset.assetType);
        if (buyer == address(0x0)) {
            buyer = msg.sender;
        }
        transferWithFeesPossibility(order.key.sellAsset, amount, order.key.owner, buyer, feeSide == FeeSide.SELL, buyerFee, order.sellerFee, order.key.buyAsset);
        transferWithFeesPossibility(order.key.buyAsset, paying, msg.sender, order.key.owner, feeSide == FeeSide.BUY, order.sellerFee, buyerFee, order.key.sellAsset);
        emitBuy(order, amount, buyer);
    }

    function validateEthTransfer(uint value, uint buyerFee) internal view {
        uint256 buyerFeeValue = value.bp(buyerFee);
        require(msg.value == value + buyerFeeValue, "msg.value is incorrect");
    }

    /// @notice Cancel the token exchange order. Can be called only by the order owner.
    ///         The function makes all exchnage calls for this order revert with error.
    /// @param key - The OrderKey struct of the order.
    function cancel(OrderKey calldata key) external {
        require(key.owner == msg.sender, "not an owner");
        state.setCompleted(key, UINT256_MAX);
        emit Cancel(key.sellAsset.token, key.sellAsset.tokenId, msg.sender, key.buyAsset.token, key.buyAsset.tokenId, key.salt);
    }

    function validateOrderSig(
        Order memory order,
        Sig memory sig
    ) internal view {
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            require(ordersHolder.exists(order), "incorrect signature");
        } else {
            require(prepareMessage(order).recover(sig.v, sig.r, sig.s) == order.key.owner, "incorrect signature");
        }
    }

    function validateBuyerFeeSig(
        Order memory order,
        uint buyerFee,
        Sig memory sig
    ) internal view {
        require(prepareBuyerFeeMessage(order, buyerFee).recover(sig.v, sig.r, sig.s) == buyerFeeSigner, "incorrect buyer fee signature");
    }

    /// @notice This function generates fee message to sign for exchange call.
    /// @param order - Order struct.
    /// @param fee - Fee amount.
    /// @return Encoded (order, fee) message, wich should be signed by the buyerFeeSigner. Does not contain standard prefix.
    function prepareBuyerFeeMessage(Order memory order, uint fee) public pure returns (string memory) {
        return keccak256(abi.encode(order, fee)).toString();
    }

    /// @notice This function generates order message to sign for exchange call.
    /// @param order - Order struct.
    /// @return Encoded order message, wich should be signed by the token owner. Does not contain standard prefix.
    function prepareMessage(Order memory order) public pure returns (string memory) {
        return keccak256(abi.encode(order)).toString();
    }

    function transferWithFeesPossibility(Asset memory firstType, uint value, address from, address to, bool hasFee, uint256 sellerFee, uint256 buyerFee, Asset memory secondType) internal {
        if (!hasFee) {
            transfer(firstType, value, from, to);
        } else {
            transferWithFees(firstType, value, from, to, sellerFee, buyerFee, secondType);
        }
    }

    function transfer(Asset memory asset, uint value, address from, address to) internal {
        if (asset.assetType == AssetType.ETH) {
            address payable toPayable = address(uint160(to));
            toPayable.transfer(value);
        } else if (asset.assetType == AssetType.ERC20) {
            require(asset.tokenId == 0, "tokenId should be 0");
            erc20TransferProxy.erc20safeTransferFrom(IERC20(asset.token), from, to, value);
        } else if (asset.assetType == AssetType.ERC721) {
            require(value == 1, "value should be 1 for ERC-721");
            transferProxy.erc721safeTransferFrom(IERC721(asset.token), from, to, asset.tokenId);
        } else if (asset.assetType == AssetType.ERC721Deprecated) {
            require(value == 1, "value should be 1 for ERC-721");
            transferProxyForDeprecated.erc721TransferFrom(IERC721(asset.token), from, to, asset.tokenId);
        } else {
            transferProxy.erc1155safeTransferFrom(IERC1155(asset.token), from, to, asset.tokenId, value, "");
        }
    }

    function transferWithFees(Asset memory firstType, uint value, address from, address to, uint256 sellerFee, uint256 buyerFee, Asset memory secondType) internal {
        uint restValue = transferFeeToBeneficiary(firstType, from, value, sellerFee, buyerFee);
        if (
            secondType.assetType == AssetType.ERC1155 && IERC1155(secondType.token).supportsInterface(_INTERFACE_ID_FEES) ||
            (secondType.assetType == AssetType.ERC721 || secondType.assetType == AssetType.ERC721Deprecated) && IERC721(secondType.token).supportsInterface(_INTERFACE_ID_FEES)
        ) {
            HasSecondarySaleFees withFees = HasSecondarySaleFees(secondType.token);
            address payable[] memory recipients = withFees.getFeeRecipients(secondType.tokenId);
            uint[] memory fees = withFees.getFeeBps(secondType.tokenId);
            require(fees.length == recipients.length);
            for (uint256 i = 0; i < fees.length; i++) {
                (uint newRestValue, uint current) = subFeeInBp(restValue, value, fees[i]);
                restValue = newRestValue;
                transfer(firstType, current, from, recipients[i]);
            }
        }
        address payable toPayable = address(uint160(to));
        transfer(firstType, restValue, from, toPayable);
    }

    function transferFeeToBeneficiary(Asset memory asset, address from, uint total, uint sellerFee, uint buyerFee) internal returns (uint) {
        (uint restValue, uint sellerFeeValue) = subFeeInBp(total, total, sellerFee);
        uint buyerFeeValue = total.bp(buyerFee);
        uint beneficiaryFee = buyerFeeValue.add(sellerFeeValue);
        if (beneficiaryFee > 0) {
            transfer(asset, beneficiaryFee, from, beneficiary);
        }
        return restValue;
    }

    function emitBuy(Order memory order, uint amount, address buyer) internal {
        emit Buy(order.key.sellAsset.token, order.key.sellAsset.tokenId, order.selling,
            order.key.owner,
            order.key.buyAsset.token, order.key.buyAsset.tokenId, order.buying,
            buyer,
            amount,
            order.key.salt
        );
    }

    function subFeeInBp(uint value, uint total, uint feeInBp) internal pure returns (uint newValue, uint realFee) {
        return subFee(value, total.bp(feeInBp));
    }

    function subFee(uint value, uint fee) internal pure returns (uint newValue, uint realFee) {
        if (value > fee) {
            newValue = value - fee;
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }

    function verifyOpenAndModifyOrderState(OrderKey memory key, uint selling, uint amount) internal {
        uint completed = state.getCompleted(key);
        uint newCompleted = completed.add(amount);
        require(newCompleted <= selling, "not enough stock of order for buying");
        state.setCompleted(key, newCompleted);
    }

    function getFeeSide(AssetType sellType, AssetType buyType) internal pure returns (FeeSide) {
        if ((sellType == AssetType.ERC721 || sellType == AssetType.ERC721Deprecated) &&
            (buyType == AssetType.ERC721 || buyType == AssetType.ERC721Deprecated)) {
            return FeeSide.NONE;
        }
        if (uint(sellType) > uint(buyType)) {
            return FeeSide.BUY;
        }
        return FeeSide.SELL;
    }
}