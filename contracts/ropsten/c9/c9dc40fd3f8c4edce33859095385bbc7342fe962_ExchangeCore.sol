// SPDX-License-Identifier: MIT
import "./ERC20.sol";
import "./ERC20Basic.sol";
import "./SaleKindInterface.sol";

import "./Ownable.sol";
import "./AuthenticatedProxy.sol";
import "./ProxyRegistry.sol";
import "./TokenTransferProxy.sol";
import "./ReentrancyGuard.sol";
import "./ArrayUtils.sol";

pragma solidity ^0.8.0;

contract ExchangeCore is ReentrancyGuard, Ownable {

    /* The token used to pay exchange fees. */
    ERC20 public exchangeToken;

    /* User registry. */
    ProxyRegistry public registry;
    
    /* Operator. */
    address payable public operator;

    /* Token transfer proxy. */
    TokenTransferProxy public tokenTransferProxy;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /* Orders verified by on-chain approval (alternative to ECDSA signatures so that smart contracts can place orders directly). */
    mapping(bytes32 => bool) public approvedOrders;

    /* For split fee orders, minimum required protocol maker fee, in basis points. Paid to owner (who can change it). */
    uint public minimumMakerProtocolFee;

    /* For split fee orders, minimum required protocol taker fee, in basis points. Paid to owner (who can change it). */
    uint public minimumTakerProtocolFee;

    /* Recipient of protocol fees. */
    address payable public protocolFeeRecipient;

    /* Fee method: protocol fee or split fee. */
    enum FeeMethod { ProtocolFee, SplitFee }

    /* Inverse basis point. */
    uint public constant INVERSE_BASIS_POINT = 10000;

    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    /* An order on the exchange. */
    struct Order {
        /* Exchange address, intended as a versioning mechanism. */
        address exchange;
        /* Order maker address. */
        address payable maker;
        /* Order taker address, if specified. */
        address taker;
        /* Maker relayer fee of the order, unused for taker order. */
        uint makerRelayerFee;
        /* Taker relayer fee of the order, or maximum taker fee for a taker order. */
        uint takerRelayerFee;
        /* Maker protocol fee of the order, unused for taker order. */
        uint makerProtocolFee;
        /* Taker protocol fee of the order, or maximum taker fee for a taker order. */
        uint takerProtocolFee;
        /* Order fee recipient or zero address for taker order. */
        address payable feeRecipient;
        /* Fee method (protocol token or split fee). */
        FeeMethod feeMethod;
        /* Side (buy/sell). */
        SaleKindInterface.Side side;
        /* Kind of sale. */
        SaleKindInterface.SaleKind saleKind;
        /* Target. */
        address target;
        /* HowToCall. */
        AuthenticatedProxy.HowToCall howToCall;
        /* Calldata. */
        bytes data;
        /* Calldata replacement pattern, or an empty byte array for no replacement. */
        bytes replacementPattern;
        /* Static call target, zero-address for no static call. */
        address staticTarget;
        /* Static call extra data. */
        bytes staticExtradata;
        /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
        /* Base price of the order (in paymentTokens). */
        uint basePrice;
        /* Auction extra parameter - minimum bid increment for English auctions, starting/ending price difference. */
        uint extra;
        /* Listing timestamp. */
        uint listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint salt;
    }
    
    event OrderApprovedPartOne    (bytes32 indexed hash, address exchange, address indexed maker, address taker, uint makerRelayerFee, uint takerRelayerFee, uint makerProtocolFee, uint takerProtocolFee, address indexed feeRecipient, FeeMethod feeMethod, SaleKindInterface.Side side, SaleKindInterface.SaleKind saleKind, address target);
    event OrderApprovedPartTwo    (bytes32 indexed hash, AuthenticatedProxy.HowToCall howToCall, bytes data, bytes replacementPattern, address staticTarget, bytes staticExtradata, address paymentToken, uint basePrice, uint extra, uint listingTime, uint expirationTime, uint salt, bool orderbookInclusionDesired);
    event OrderCancelled          (bytes32 indexed hash);
    event OrdersMatched           (bytes32 buyHash, bytes32 sellHash, address indexed maker, address indexed taker, uint price, bytes32 indexed metadata);
    
    constructor (ProxyRegistry registryAddress, TokenTransferProxy tokenTransferProxyAddress, ERC20 tokenAddress, address payable protocolFeeAddress) Ownable() {
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
        exchangeToken = tokenAddress;
        protocolFeeRecipient = protocolFeeAddress;
    }
    
    function setOperator(address payable addr)
    public
    onlyOwner
    {
        operator = addr;
    }
    
    modifier onlyOperator {
        require(msg.sender == operator);
        _;
    }
    
    /**
     * @dev Change the minimum maker fee paid to the protocol (owner only)
     * @param newMinimumMakerProtocolFee New fee to set in basis points
     */
    function changeMinimumMakerProtocolFee(uint newMinimumMakerProtocolFee)
    public
    onlyOwner
    {
        minimumMakerProtocolFee = newMinimumMakerProtocolFee;
    }
    
    /**
     * @dev Change the minimum taker fee paid to the protocol (owner only)
     * @param newMinimumTakerProtocolFee New fee to set in basis points
     */
    function changeMinimumTakerProtocolFee(uint newMinimumTakerProtocolFee)
    public
    onlyOwner
    {
        minimumTakerProtocolFee = newMinimumTakerProtocolFee;
    }
    
    /**
     * @dev Change the protocol fee recipient (owner only)
     * @param newProtocolFeeRecipient New protocol fee recipient address
     */
    function changeProtocolFeeRecipient(address payable newProtocolFeeRecipient)
    public
    onlyOwner
    {
        protocolFeeRecipient = newProtocolFeeRecipient;
    }
    
    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function transferTokens(address token, address from, address to, uint amount)
    internal
    {
        if (amount > 0) {
            require(tokenTransferProxy.transferFrom(token, from, to, amount));
        }
    }
    
    /**
     * @dev Charge a fee in protocol tokens
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function chargeProtocolFee(address from, address to, uint amount)
    internal
    {
        transferTokens(address(exchangeToken), from, to, amount);
    }
    
    /**
     * @dev Execute a STATICCALL (introduced with Ethereum Metropolis, non-state-modifying external call)
     * @param target Contract to call
     * @param data Calldata (appended to extradata)
     * @param extradata Base data for STATICCALL (probably function selector and argument encoding)
     * @return result of the call (success or failure)
     */
    function staticCall(address target, bytes memory data, bytes memory extradata)
    public
    view
    returns (bool result)
    {
        bytes memory combined = new bytes(data.length + extradata.length);
        uint index;
        assembly {
            index := add(combined, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes(index, extradata);
        ArrayUtils.unsafeWriteBytes(index, data);
        assembly {
            result := staticcall(gas(), target, add(combined, 0x20), mload(combined), mload(0x40), 0)
        }
        return result;
    }
    
    /**
     * Calculate size of an order struct when tightly packed
     *
     * @param order Order to calculate size of
     * @return Size in bytes
     */
    function sizeOf(Order memory order)
    internal
    pure
    returns (uint)
    {
        return ((0x14 * 7) + (0x20 * 9) + 4 + order.data.length + order.replacementPattern.length + order.staticExtradata.length);
    }
    
    /**
     * @dev Hash an order, returning the canonical order hash, without the message prefix
     * @param order Order to hash
     * @return hash of order
     */
    function hashOrder(Order memory order)
    public
    pure
    returns (bytes32 hash)
    {
        /* Unfortunately abi.encodePacked doesn't work here, stack size constraints. */
        uint size = sizeOf(order);
        bytes memory array = new bytes(size);
        uint index;
        assembly {
            index := add(array, 0x20)
        }
        index = ArrayUtils.unsafeWriteAddress(index, order.exchange);
        index = ArrayUtils.unsafeWriteAddress(index, order.maker);
        index = ArrayUtils.unsafeWriteAddress(index, order.taker);
        index = ArrayUtils.unsafeWriteUint(index, order.makerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.makerProtocolFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerProtocolFee);
        index = ArrayUtils.unsafeWriteAddress(index, order.feeRecipient);
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.feeMethod));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.side));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.saleKind));
        index = ArrayUtils.unsafeWriteAddress(index, order.target);
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.howToCall));
        index = ArrayUtils.unsafeWriteBytes(index, order.data);
        index = ArrayUtils.unsafeWriteBytes(index, order.replacementPattern);
        index = ArrayUtils.unsafeWriteAddress(index, order.staticTarget);
        index = ArrayUtils.unsafeWriteBytes(index, order.staticExtradata);
        index = ArrayUtils.unsafeWriteAddress(index, order.paymentToken);
        index = ArrayUtils.unsafeWriteUint(index, order.basePrice);
        index = ArrayUtils.unsafeWriteUint(index, order.extra);
        index = ArrayUtils.unsafeWriteUint(index, order.listingTime);
        index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);
        index = ArrayUtils.unsafeWriteUint(index, order.salt);
        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
        return hash;
    }
    
    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @param order Order to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Order memory order)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encode("\x19Ethereum Signed Message:\n32", hashOrder(order)));
    }
    
    /**
     * @dev Assert an order is valid and return its hash
     * @param order Order to validate
     * @param sig ECDSA signature
     */
    function requireValidOrder(Order memory order, Sig memory sig)
    internal
    view
    returns (bytes32)
    {
        bytes32 hash = hashToSign(order);
        require(validateOrder(hash, order, sig));
        return hash;
    }
    
    /**
     * @dev Validate order parameters (does *not* check signature validity)
     * @param order Order to validate
     */
    function validateOrderParameters(Order memory order)
    public
    view
    returns (bool)
    {
        /* Order must be targeted at this protocol version (this Exchange contract). */
        if (order.exchange != address(this)) {
            return false;
        }
    
        /* Order must possess valid sale kind parameter combination. */
        if (!SaleKindInterface.validateParameters(order.saleKind, order.expirationTime)) {
            return false;
        }
        
        /* If using the split fee method, order must have sufficient protocol fees. */
        if (order.feeMethod == FeeMethod.SplitFee && (order.makerProtocolFee < minimumMakerProtocolFee || order.takerProtocolFee < minimumTakerProtocolFee)) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param hash Order hash (already calculated, passed to avoid recalculation)
     * @param order Order to validate
     * @param sig ECDSA signature
     */
    function validateOrder(bytes32 hash, Order memory order, Sig memory sig)
    public
    view
    returns (bool)
    {
        /* Not done in an if-conditional to prevent unnecessary ecrecover evaluation, which seems to happen even though it should short-circuit. */
        
        /* Order must have valid parameters. */
        if (!validateOrderParameters(order)) {
            return false;
        }
        
        /* Order must have not been canceled or already filled. */
        if (cancelledOrFinalized[hash]) {
            return false;
        }
        
        /* Order authentication. Order must be either:
        /* (a) previously approved */
        if (approvedOrders[hash]) {
            return true;
        }
        
        /* or (b) ECDSA-signed by maker. */
        if (ecrecover(hash, sig.v, sig.r, sig.s) == order.maker) {
            return true;
        }
        
        return false;
    }
    
    /**
     * @dev Approve an order and optionally mark it for orderbook inclusion. Must be called by the maker of the order
     * @param order Order to approve
     * @param orderbookInclusionDesired Whether orderbook providers should include the order in their orderbooks
     */
    function approveOrder(Order memory order, bool orderbookInclusionDesired)
    public
    onlyOperator
    {
        /* CHECKS */
        
        /* Assert sender is authorized to approve order. */
        require(msg.sender == order.maker);
        
        /* Calculate order hash. */
        bytes32 hash = hashToSign(order);
        
        /* Assert order has not already been approved. */
        require(!approvedOrders[hash]);
        
        /* EFFECTS */
        
        /* Mark order as approved. */
        approvedOrders[hash] = true;
        
        /* Log approval event. Must be split in two due to Solidity stack size limitations. */
        {
            emit OrderApprovedPartOne(hash, order.exchange, order.maker, order.taker, order.makerRelayerFee, order.takerRelayerFee, order.makerProtocolFee, order.takerProtocolFee, order.feeRecipient, order.feeMethod, order.side, order.saleKind, order.target);
        }
        {
            emit OrderApprovedPartTwo(hash, order.howToCall, order.data, order.replacementPattern, order.staticTarget, order.staticExtradata, order.paymentToken, order.basePrice, order.extra, order.listingTime, order.expirationTime, order.salt, orderbookInclusionDesired);
        }
    }
    
    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param sig ECDSA signature
     */
    function cancelOrder(Order memory order, Sig memory sig)
    public
    onlyOperator
    {
        /* CHECKS */
        
        /* Calculate order hash. */
        bytes32 hash = requireValidOrder(order, sig);
        
        /* Assert sender is authorized to cancel order. */
        require(msg.sender == order.maker);
        
        /* EFFECTS */
        
        /* Mark order as cancelled, preventing it from being matched. */
        cancelledOrFinalized[hash] = true;
        
        /* Log cancel event. */
        emit OrderCancelled(hash);
    }
    
    /**
     * @dev Calculate the current price of an order (convenience function)
     * @param order Order to calculate the price of
     * @return The current price of the order
     */
    function calculateCurrentPrice (Order memory order)
    public
    view
    returns (uint)
    {
        return SaleKindInterface.calculateFinalPrice(order.side, order.saleKind, order.basePrice, order.extra, order.listingTime, order.expirationTime);
    }
    
    /**
     * @dev Calculate the price two orders would match at, if in fact they would match (otherwise fail)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Match price
     */
    function calculateMatchPrice(Order memory buy, Order memory sell)
    public
    view
    returns (uint)
    {
        /* Calculate sell price. */
        uint sellPrice = SaleKindInterface.calculateFinalPrice(sell.side, sell.saleKind, sell.basePrice, sell.extra, sell.listingTime, sell.expirationTime);
        
        /* Calculate buy price. */
        uint buyPrice = SaleKindInterface.calculateFinalPrice(buy.side, buy.saleKind, buy.basePrice, buy.extra, buy.listingTime, buy.expirationTime);
        
        /* Require price cross. */
        require(buyPrice >= sellPrice);
        
        /* Maker/taker priority. */
        return sell.feeRecipient != address(0) ? sellPrice : buyPrice;
    }
    
    /**
     * @dev Execute all ERC20 token / Ether transfers associated with an order match (fees and buyer => seller transfer)
     * @param buy Buy-side order
     * @param sell Sell-side order
     */
    function executeFundsTransfer(Order memory buy, Order memory sell)
    internal
    returns (uint)
    {
        /* Only payable in the special case of unwrapped Ether. */
        if (sell.paymentToken != address(0)) {
            require(msg.value == 0);
        }
    
        /* Calculate match price. */
        uint price = calculateMatchPrice(buy, sell);
        
        /* If paying using a token (not Ether), transfer tokens. This is done prior to fee payments to that a seller will have tokens before being charged fees. */
        if (price > 0 && sell.paymentToken != address(0)) {
            transferTokens(sell.paymentToken, buy.maker, sell.maker, price);
        }
        
        /* Amount that will be received by seller (for Ether). */
        uint receiveAmount = price;
        
        /* Amount that must be sent by buyer (for Ether). */
        uint requiredAmount = price;
        
        /* Determine maker/taker and charge fees accordingly. */
        if (sell.feeRecipient != address(0)) {
            /* Sell-side order is maker. */
        
            /* Assert taker fee is less than or equal to maximum fee specified by buyer. */
            require(sell.takerRelayerFee <= buy.takerRelayerFee);
            
            if (sell.feeMethod == FeeMethod.SplitFee) {
                /* Assert taker fee is less than or equal to maximum fee specified by buyer. */
                require(sell.takerProtocolFee <= buy.takerProtocolFee);
                
                /* Maker fees are deducted from the token amount that the maker receives. Taker fees are extra tokens that must be paid by the taker. */
                
                if (sell.makerRelayerFee > 0) {
                    uint makerRelayerFee = sell.makerRelayerFee * price / INVERSE_BASIS_POINT;
                    if (sell.paymentToken == address(0)) {
                        receiveAmount = receiveAmount - makerRelayerFee;
                        sell.feeRecipient.transfer(makerRelayerFee);
                    } else {
                        transferTokens(sell.paymentToken, sell.maker, sell.feeRecipient, makerRelayerFee);
                    }
                }
                
                if (sell.takerRelayerFee > 0) {
                    uint takerRelayerFee = sell.takerRelayerFee * price / INVERSE_BASIS_POINT;
                    if (sell.paymentToken == address(0)) {
                        requiredAmount = requiredAmount + takerRelayerFee;
                        sell.feeRecipient.transfer(takerRelayerFee);
                    } else {
                        transferTokens(sell.paymentToken, buy.maker, sell.feeRecipient, takerRelayerFee);
                    }
                }
                
                if (sell.makerProtocolFee > 0) {
                    uint makerProtocolFee = sell.makerProtocolFee * price / INVERSE_BASIS_POINT;
                    if (sell.paymentToken == address(0)) {
                        receiveAmount = receiveAmount - makerProtocolFee;
                        protocolFeeRecipient.transfer(makerProtocolFee);
                    } else {
                        transferTokens(sell.paymentToken, sell.maker, protocolFeeRecipient, makerProtocolFee);
                    }
                }
                
                if (sell.takerProtocolFee > 0) {
                    uint takerProtocolFee = sell.takerProtocolFee * price / INVERSE_BASIS_POINT;
                    if (sell.paymentToken == address(0)) {
                        requiredAmount = requiredAmount + takerProtocolFee;
                        protocolFeeRecipient.transfer(takerProtocolFee);
                    } else {
                        transferTokens(sell.paymentToken, buy.maker, protocolFeeRecipient, takerProtocolFee);
                    }
                }
            
            } else {
                /* Charge maker fee to seller. */
                chargeProtocolFee(sell.maker, sell.feeRecipient, sell.makerRelayerFee);
                
                /* Charge taker fee to buyer. */
                chargeProtocolFee(buy.maker, sell.feeRecipient, sell.takerRelayerFee);
            }
        } else {
            /* Buy-side order is maker. */
            
            /* Assert taker fee is less than or equal to maximum fee specified by seller. */
            require(buy.takerRelayerFee <= sell.takerRelayerFee);
            
            if (sell.feeMethod == FeeMethod.SplitFee) {
                /* The Exchange does not escrow Ether, so direct Ether can only be used to with sell-side maker / buy-side taker orders. */
                require(sell.paymentToken != address(0));
                
                /* Assert taker fee is less than or equal to maximum fee specified by seller. */
                require(buy.takerProtocolFee <= sell.takerProtocolFee);
                
                if (buy.makerRelayerFee > 0) {
                    uint makerRelayerFee = buy.makerRelayerFee * price / INVERSE_BASIS_POINT;
                    transferTokens(sell.paymentToken, buy.maker, buy.feeRecipient, makerRelayerFee);
                }
                
                if (buy.takerRelayerFee > 0) {
                    uint takerRelayerFee = buy.takerRelayerFee * price / INVERSE_BASIS_POINT;
                    transferTokens(sell.paymentToken, sell.maker, buy.feeRecipient, takerRelayerFee);
                }
                
                if (buy.makerProtocolFee > 0) {
                    uint makerProtocolFee = buy.makerProtocolFee * price / INVERSE_BASIS_POINT;
                    transferTokens(sell.paymentToken, buy.maker, protocolFeeRecipient, makerProtocolFee);
                }
                
                if (buy.takerProtocolFee > 0) {
                    uint takerProtocolFee = buy.takerProtocolFee * price / INVERSE_BASIS_POINT;
                    transferTokens(sell.paymentToken, sell.maker, protocolFeeRecipient, takerProtocolFee);
                }
        
            } else {
                /* Charge maker fee to buyer. */
                chargeProtocolFee(buy.maker, buy.feeRecipient, buy.makerRelayerFee);
                
                /* Charge taker fee to seller. */
                chargeProtocolFee(sell.maker, buy.feeRecipient, buy.takerRelayerFee);
            }
        }
        
        if (sell.paymentToken == address(0)) {
            /* Special-case Ether, order must be matched by buyer. */
            require(msg.value >= requiredAmount);
            sell.maker.transfer(receiveAmount);
            /* Allow overshoot for variable-price auctions, refund difference. */
            uint diff = msg.value - requiredAmount;
            if (diff > 0) {
                buy.maker.transfer(diff);
            }
        }
        
        /* This contract should never hold Ether, however, we cannot assert this, since it is impossible to prevent anyone from sending Ether e.g. with selfdestruct. */
        
        return price;
    }
    
    /**
     * @dev Return whether or not two orders can be matched with each other by basic parameters (does not check order signatures / calldata or perform static calls)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Whether or not the two orders can be matched
     */
    function ordersCanMatch(Order memory buy, Order memory sell)
    public
    view
    returns (bool)
    {
        return (
            /* Must be opposite-side. */
            (buy.side == SaleKindInterface.Side.Buy && sell.side == SaleKindInterface.Side.Sell) &&
            /* Must use same fee method. */
            (buy.feeMethod == sell.feeMethod) &&
            /* Must use same payment token. */
            (buy.paymentToken == sell.paymentToken) &&
            /* Must match maker/taker addresses. */
            (sell.taker == address(0) || sell.taker == buy.maker) &&
            (buy.taker == address(0) || buy.taker == sell.maker) &&
            /* One must be maker and the other must be taker (no bool XOR in Solidity). */
            ((sell.feeRecipient == address(0) && buy.feeRecipient != address(0)) || (sell.feeRecipient != address(0) && buy.feeRecipient == address(0))) &&
            /* Must match target. */
            (buy.target == sell.target) &&
            /* Must match howToCall. */
            (buy.howToCall == sell.howToCall) &&
            /* Buy-side order must be settleable. */
            SaleKindInterface.canSettleOrder(buy.listingTime, buy.expirationTime) &&
            /* Sell-side order must be settleable. */
            SaleKindInterface.canSettleOrder(sell.listingTime, sell.expirationTime)
        );
    }
    
    /**
     * @dev Atomically match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by a contract-global lock.
     * @param buy Buy-side order
     * @param buySig Buy-side order signature
     * @param sell Sell-side order
     * @param sellSig Sell-side order signature
     */
    function atomicMatch(Order memory buy, Sig memory buySig, Order memory sell, Sig memory sellSig, bytes32 metadata)
    public
    onlyOperator
    nonReentrant
    {
        /* CHECKS */
        
        /* Ensure buy order validity and calculate hash if necessary. */
        bytes32 buyHash;
        if (buy.maker == msg.sender) {
            require(validateOrderParameters(buy));
        } else {
            buyHash = requireValidOrder(buy, buySig);
        }
    
        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 sellHash;
        if (sell.maker == msg.sender) {
            require(validateOrderParameters(sell));
        } else {
            sellHash = requireValidOrder(sell, sellSig);
        }
    
        /* Must be matchable. */
        require(ordersCanMatch(buy, sell));
        
        /* Target must exist (prevent malicious selfdestructs just prior to order settlement). */
        uint size;
        address target = sell.target;
        assembly {
            size := extcodesize(target)
        }
        require(size > 0);
        
        
        if (sell.data.length != 0) {
            /* Must match calldata after replacement, if specified. */
            if (buy.replacementPattern.length > 0) {
                ArrayUtils.guardedArrayReplace(buy.data, sell.data, buy.replacementPattern);
            }
            if (sell.replacementPattern.length > 0) {
                ArrayUtils.guardedArrayReplace(sell.data, buy.data, sell.replacementPattern);
            }
            require(ArrayUtils.arrayEq(buy.data, sell.data));
        } else {
            sell.data = buy.data;
        }
        
        /* Retrieve delegateProxy contract. */
        OwnableDelegateProxy delegateProxy = registry.proxies(sell.maker);
        
        /* Proxy must exist. */
        require(address(delegateProxy) != address(0));
        
        /* Assert implementation. */
        require(delegateProxy.implementation() == registry.delegateProxyImplementation());
        
        /* Access the passthrough AuthenticatedProxy. */
        AuthenticatedProxy proxy = AuthenticatedProxy(address(delegateProxy));
        
        /* EFFECTS */
        
        /* Mark previously signed or approved orders as finalized. */
        if (msg.sender != buy.maker) {
            cancelledOrFinalized[buyHash] = true;
        }
        if (msg.sender != sell.maker) {
            cancelledOrFinalized[sellHash] = true;
        }
        
        /* INTERACTIONS */
        
        /* Execute funds transfer and pay fees. */
        uint price = executeFundsTransfer(buy, sell);
        
        /* Execute specified call through proxy. */
        require(proxy.proxy(sell.target, sell.howToCall, sell.data));
        
        /* Static calls are intentionally done after the effectful call so they can check resulting state. */
        
        /* Handle buy-side static call if specified. */
        if (buy.staticTarget != address(0)) {
            require(staticCall(buy.staticTarget, sell.data, buy.staticExtradata));
        }
        
        /* Handle sell-side static call if specified. */
        if (sell.staticTarget != address(0)) {
            require(staticCall(sell.staticTarget, sell.data, sell.staticExtradata));
        }
        
        /* Log match event. */
        emit OrdersMatched(buyHash, sellHash, sell.feeRecipient != address(0) ? sell.maker : buy.maker, sell.feeRecipient != address(0) ? buy.maker : sell.maker, price, metadata);
    }
}