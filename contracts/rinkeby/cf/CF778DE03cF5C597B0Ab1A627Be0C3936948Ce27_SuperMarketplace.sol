// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

import "./V1/Exchange.sol";

/**
 * @title SuperMarketplace
 * @author Rostislav Khlebnikov
 */
contract SuperMarketplace is Exchange {

    string public constant name = "Super Marketplace";
  
    string public constant marketplaceVersion = "1";

    /**
    * @param _registry  existing registry address
    * @param _personalSignPrefix  "\x19Ethereum Signed Message:\n"
    */
    constructor (address _registry, bytes memory _personalSignPrefix, address _tokenTransferProxy, address _platformFeeAddress, uint _minimumPlatformFee) ExchangeCore(name, marketplaceVersion){
        registry = _registry;
        tokenTransferProxy = _tokenTransferProxy;
        platformFeeAddress = _platformFeeAddress;
        minimumPlatformFee = _minimumPlatformFee;
        if (_personalSignPrefix.length > 0) {
          personalSignPrefix = _personalSignPrefix;
        }
        setPermit(_msgSender(), UNIVERSAL, FEE_CONFIG, type(uint256).max);
    }

}

pragma solidity ^0.8.8;

import "./ExchangeCore.sol";

/**
 * @title modified WyvernExchangeV2 contract
 * @author Project Wyvern Developers
 * @author Rostislav Khlebnikov
 */
abstract contract Exchange is ExchangeCore {

    /**
     * @dev Change the minimum taker fee paid to the platform
     * @param newMinimumPlatformFee New fee to set in basis points
     */
    function changeMinimumPlatformFee(uint newMinimumPlatformFee)
        external
        hasValidPermit(UNIVERSAL, FEE_CONFIG)
    {
        minimumPlatformFee = newMinimumPlatformFee;
    }

      /**
     * @dev Change the address of platform for royalty fees
     * @param newPlatformFeeAddress New fee to set in basis points
     */
    function changePlatformFeeAddress(address newPlatformFeeAddress)
        external
        hasValidPermit(UNIVERSAL, FEE_CONFIG)
    {
        platformFeeAddress = newPlatformFeeAddress;
    }

    /**
     * @dev Call calculateFinalPrice 
     */
    function calculateFinalPrice(Sales.SaleKind saleKind, uint basePrice, uint[] calldata extra, uint listingTime)
        external view
        returns (uint)
    {
        return Sales.calculateFinalPrice(saleKind, basePrice, extra, listingTime);
    }

    /**
     * @dev Call hashOrder
     */
    function hashOrder(Order calldata order)
        external pure
        returns (bytes32)
    {
        return _hash(order);
    }

    /**
     * @dev Call hashToSign
     */
    function hashToSign(Order calldata order) external view returns (bytes32)
    { 
        return _hashToSign(order);
    }

    /**
     * @dev Call validateOrderParameters
     */
    function validateOrderParameters(Order calldata order)
        external view
        returns (bool)
    {   
        return _validateOrderParameters(order);
    }

    /**
     * @dev Call validateOrder
     */
    function validateOrderAthentication(Order calldata order, Sig calldata sig)
        external view
        returns (bool)
    {
        return authenticateOrder(_hashToSign(order), order.outline.maker, sig);
    }

    /**
     * @dev Call approveOrder
     */
    function approveOrder_(Order calldata order)
        external
    {
        return _approveOrder(order);
    }

    /**
     * @dev Call cancelOrder
     */
    function cancelOrder_(Order calldata order,Sig calldata sig)
        external
    {
        return _cancelOrder(order, sig);
    }

    /**
     * @dev Call calculateCurrentPrice
     */
    function calculateCurrentPrice(Order calldata order)
        external view
        returns (uint)
    {
        return _calculateCurrentPrice(order);
    }

    /**
     * @dev Call ordersCanMatch
     */
    function ordersMatch(Order calldata buy, Order calldata sell)
        external view
        returns (bool)
    {
        return _ordersMatch(buy, sell);
    }

    /**
     * @dev Return whether or not two orders' calldata specifications can match
     * @param buyCalldata Buy-side order calldata
     * @param buyReplacementPattern Buy-side order calldata replacement mask
     * @param sellCalldata Sell-side order calldata
     * @param sellReplacementPattern Sell-side order calldata replacement mask
     * @return Whether the orders' calldata can be matched
     */
    function orderCalldataCanMatch(bytes calldata buyCalldata, bytes calldata buyReplacementPattern, bytes calldata sellCalldata, bytes calldata sellReplacementPattern)
        external pure
        returns (bool)
    {
        if (buyReplacementPattern.length > 0) {
          ArrayUtils.guardedArrayReplace(buyCalldata, sellCalldata, buyReplacementPattern);
        }
        if (sellReplacementPattern.length > 0) {
          ArrayUtils.guardedArrayReplace(sellCalldata, buyCalldata, sellReplacementPattern);
        }
        return ArrayUtils.arrayEq(buyCalldata, sellCalldata);
    }

    /**
     * @dev Call calculateMatchPrice 
     */
    function calculateMatchPrice(Order calldata buy, Order calldata sell)
        external view
        returns (uint)
    {
       return _calculateMatchPrice(buy, sell);
    }

    /**
     * @dev Call atomicMatch
     */
    function atomicMatch_(
        Order calldata buy,
        Sig calldata sigBuy,
        Order calldata sell,
        Sig calldata sigSell,
        Order[] calldata toInvalidate,
        Sig[] calldata sigs
        )
        external payable
        nonReentrant
    {
        return _atomicMatch(buy, sigBuy, sell, sigSell, toInvalidate, sigs);
    }

}

pragma solidity ^0.8.8;
 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../access/PermitControl.sol";
import "../../interfaces/IProxyRegistry.sol";
import "../../proxy/TokenTransferProxy.sol";
import "../../proxy/AuthenticatedProxy.sol";
import "../../utils/Utils.sol";
import "../../libraries/Sales.sol";
import "../../libraries/EIP712.sol";
import "../../libraries/EIP1271.sol";

/**
    @title modified ExchangeCore of ProjectWyvernV2
    @author Project Wyvern Developers
    @author Rostislav Khlebnikov
 */
abstract contract ExchangeCore is ReentrancyGuard, EIP712, PermitControl {

    /**  The public identifier for the right to set new items. */
    bytes32 public constant FEE_CONFIG = keccak256("FEE_CONFIG");

    bytes32 public constant OUTLINE_TYPEHASH =
        keccak256(
            "Outline(uint256 basePrice,uint256 listingTime,uint256 expirationTime,address exchange,address maker,uint8 side,address taker,uint8 saleKind,address target,uint8 callType,address paymentToken)"
        );

    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(Outline outline,uint256[] extra,uint256 salt,uint256[] fees,address[] addresses,address staticTarget,bytes data,bytes replacementPattern,bytes staticExtradata)Outline(uint256 basePrice,uint256 listingTime,uint256 expirationTime,address exchange,address maker,uint8 side,address taker,uint8 saleKind,address target,uint8 callType,address paymentToken)"
        );

    bytes4 constant internal EIP_1271_MAGICVALUE = 0x20c13b0b;

    /** Token transfer proxy. */
    address public tokenTransferProxy;

    /** User registry. */
    address public registry;

    /** Trusted proxy registry contracts. */
    mapping(address => bool) public registries;

    /** Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /** Orders verified by on-chain approval (alternative to ECDSA signatures so that smart contracts can place orders directly). */
    mapping(bytes32 => bool) public approvedOrders;

    /** The royalty fee for this platform. */
    uint public minimumPlatformFee; 

    /** The royalty fee address of the platform */
    address public platformFeeAddress;

     /* An ECDSA signature. */ 
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    /** supporting struct for order to avoid stack too deep */
    struct Outline{
        /** Base price of the order (in paymentTokens). */
        uint256 basePrice;
        /** Listing timestamp. */
        uint256 listingTime;
        /** Expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /** Exchange address, intended as a versioning mechanism. */
        address exchange;
        /** Order maker address. */
        address maker;
        /** Side (buy/sell). */
        Sales.Side side;
        /** Order taker address, if specified. */
        address taker;
        /** Kind of sale. */
        Sales.SaleKind saleKind;
        /** Target. */
        address target;
        /** callType. */
        AuthenticatedProxy.CallType callType;
        /** Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
    }

    /** An order on the exchange. */
    struct Order {
        /** order essentials */
        Outline outline;
        /** ending time + ending price.*/
        uint256[] extra;
        /** Order salt, used to prevent duplicate hashes. */
        uint256 salt;
        /** Royalty fees*/ 
        uint256[] fees;
        /** Royalty fees receivers*/ 
        address[] addresses; 
        /** Static call target, zero-address for no static call. */
        address staticTarget;
        /** Calldata. */
        bytes data;
        /** Calldata replacement pattern, or an empty byte array for no replacement. */
        bytes replacementPattern;
        /** Static call extra data. */
        bytes staticExtradata;
    }

    event OrderApproved(bytes32 indexed hash, address indexed maker, address indexed taker, bytes data);
    event OrderCancelled(bytes32 indexed hash, address indexed maker, bytes data);
    event OrdersMatched (bytes32 buyHash, bytes32 sellHash, address indexed maker, address indexed taker, bytes data);
    
    constructor(string memory name, string memory version) EIP712(name, version){}

    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of platform tokens to charge
     */
    function transferTokens(address token, address from, address to, uint amount)
        internal
    {
        if (amount > 0) {
            require(TokenTransferProxy(tokenTransferProxy).transferFrom(token, from, to, amount));
        }
    }

    /**
     * @dev Execute a STATICCALL (introduced with Ethereum Metropolis, non-state-modifying external call)
     * @param target Contract to call
     * @param data Calldata (appended to extradata)
     * @param extradata Base data for STATICCALL (probably function selector and argument encoding)
     * @return result The result of the call (success or failure)
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
     * @dev Hash an order, returning the canonical order hash, without the message prefix
     * @param order Order to hash
     * @return hash Hash of order
     */
    function _hash(Order memory order)
        internal
        pure
        returns (bytes32){
        return keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                _hash(order.outline),
                keccak256(abi.encodePacked(order.extra)),
                order.salt,
                keccak256(abi.encodePacked(order.fees)),
                keccak256(abi.encodePacked(order.addresses)),
                order.staticTarget,
                keccak256(order.data),
                keccak256(order.replacementPattern),
                keccak256(order.staticExtradata)
            ));
    }

    function _hash(Outline memory outline)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    OUTLINE_TYPEHASH,
                    outline.basePrice,
                    outline.listingTime,
                    outline.expirationTime,
                    outline.exchange,
                    outline.maker,
                    outline.side,
                    outline.taker,
                    outline.saleKind,
                    outline.target,
                    outline.callType,
                    outline.paymentToken
                )
            );
    }
    

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @param order Order to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function _hashToSign(Order memory order)
        internal
        view
        returns (bytes32)
    {
       return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            _hash(order)
        ));
    }

    function recover(Order memory order, Sig memory sig) external view returns(address result){
        result = ecrecover(_hashToSign(order), sig.v, sig.r, sig.s);
        return result;
    }

     /**
     * @dev Validate order parameters (does *not* check signature validity)
     * @param order Order to validate
     */
    function _validateOrderParameters(Order memory order)
        internal
        view
        returns (bool)
    {
        /** Order must be targeted at this platform version (this Exchange contract). */
        if (order.outline.exchange != address(this)) {
            return false;
        }
        /** Target must exist (prevent malicious selfdestructs just prior to order settlement). */
        if(!Address.isContract(order.outline.target)){
            return false;
        }

        /** Order must possess valid sale kind parameter combination. */
        if(!Sales.canSettleOrder(order.outline.listingTime, order.outline.expirationTime)){
            return false;
        }

        if (!Sales.validateParameters(order.outline.saleKind, order.outline.expirationTime)) {
            return false;
        }

        return true;
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param hash Order hash (already calculated, passed to avoid recalculation)
     * @param maker order maker
     * @param sig ECDSA signature
     */
    function authenticateOrder(bytes32 hash, address maker, Sig memory sig) 
        internal
        view
        returns (bool)
    {   
        /** Order is cancelled or executed in the past.*/
        if (cancelledOrFinalized[hash]) {
            return false;
        }
        /** Order maker initiated transaction. */
        if (maker == msg.sender){
            return true;
        }
        /** Order is previously approved. */
        if (approvedOrders[hash]) {
            return true;
        }

        /** Contract-only authentication: EIP/ERC 1271. */
        if (Address.isContract(maker)) {
            bytes memory signature = abi.encodePacked(sig.r, sig.s, sig.v);
            if (ERC1271(maker).isValidSignature(abi.encodePacked(hash), signature) == EIP_1271_MAGICVALUE) {
                return true;
            }
            return false;
        }

        /** Account-only authentication: ECDSA-signed by maker. */
        if (ecrecover(hash, sig.v, sig.r, sig.s) == maker) {
            return true;
        }

        return false;
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
        /** Calculate match price. */
        uint requiredAmount = _calculateMatchPrice(buy, sell);

        /** Calculate amount for seller to receive */
        uint receiveAmount =  requiredAmount;
        uint fee;
        if (requiredAmount > 0){
            /** If paying using a token (not Ether), transfer tokens. */
            if (sell.outline.paymentToken != address(0)){
                require(msg.value == 0);
                for(uint256 i = 0; i < sell.addresses.length; i++){
                    fee = (requiredAmount*sell.fees[i])/10000;
                    receiveAmount -= fee;
                    transferTokens(buy.outline.paymentToken, buy.outline.maker, sell.addresses[i], fee);
                }
                transferTokens(sell.outline.paymentToken, buy.outline.maker, sell.outline.maker, receiveAmount);
            } else {
                /** Special-case Ether, order must be matched by buyer. */
                require(msg.value >= requiredAmount);
                /** transfer fees */
                for(uint256 i = 0; i < sell.addresses.length; i++){
                    fee = (requiredAmount*sell.fees[i])/10000;
                    receiveAmount -= fee;
                    payable(sell.addresses[i]).transfer(fee);
                }
                payable(sell.outline.maker).transfer(receiveAmount);

                /** Allow overshoot for variable-price auctions, refund difference. */
                uint diff = msg.value - requiredAmount;
                if (diff > 0) {
                    payable(buy.outline.maker).transfer(diff);
                }
            }
        }   

        return requiredAmount;
    }

     /**
     * @dev Return whether or not two orders can be matched with each other by basic parameters (does not check order signatures / calldata or perform static calls)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Whether or not the two orders can be matched
     */
    function _ordersMatch(Order memory buy, Order memory sell)
        internal
        view
        returns (bool)
    {
            /** Must be opposite-side. */
            if(!(buy.outline.side == Sales.Side.Buy && sell.outline.side == Sales.Side.Sell)){ 
                return false;
            }     
            /** Must use same payment token. */
            if(!(buy.outline.paymentToken == sell.outline.paymentToken)){
                return false;
            }
            /** Must match maker/taker addresses. */
            if(!(sell.outline.taker == address(0) || sell.outline.taker == buy.outline.maker)){
                return false;
            }
            if(!(buy.outline.taker == address(0) || buy.outline.taker == sell.outline.maker)){
                return false;
            }
            /** Platform fees address is  */
            if(!(sell.addresses[0] == platformFeeAddress)){
                return false;
            }
            /** One must have platform fee on seller side */
            if(!(sell.fees[0] >= minimumPlatformFee)){
                return false;
            }
            /** Must match target. */
            if(!(buy.outline.target == sell.outline.target)){
                return false;
            }
            /** Must match callType. */
            if(!(buy.outline.callType == sell.outline.callType)){
                return false;
            }
            return true;
    }

    /**
     * @dev Atomically match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by a contract-global lock.
     * @param buy Buy-side order.
     * @param sigBuy Buy-side order signature.
     * @param sell Sell-side order.
     * @param sigSell Sell-side order signature.
     * @param additionalSales Additional sell-orders to invalidate.
     * @param sigs Signatures for additional sales.
     */
    function _atomicMatch(Order memory buy, Sig memory sigBuy, Order memory sell, Sig memory sigSell, Order[] calldata additionalSales, Sig[] calldata sigs )
        internal
    {   
        /** CHECKS */

        /** Orders should match. */
        require(_ordersMatch(buy, sell), "Marketplace: orders do not match.");

        /** Get buy order hash. */
        bytes32 buyHash = _hashToSign(buy);

        /** Validate buy order. */
        require(_validateOrderParameters(buy), "Marketplace: buy order invalid.");

        /** Get sell order hash. */
        bytes32 sellHash = _hashToSign(sell);

        /** Validate sell order. */
        require(_validateOrderParameters(sell), "Marketplace: sell order invalid.");

        /** Prevent self-matching. */
        require(buyHash != sellHash, "Marketplace: self-matching is prohibited.");

        /** Authenticate buy order. */
        require(authenticateOrder(buyHash, buy.outline.maker, sigBuy), "Marketplace: can not autheticate buy order.");

        /** Authenticate sell order. */
        require(authenticateOrder(sellHash, sell.outline.maker, sigSell), "Marketplace: can not autheticate buy order.");
   
        /** Must match calldata after replacement, if specified. */
        if (buy.replacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(buy.data, sell.data, buy.replacementPattern);
        }
        if (sell.replacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(sell.data, buy.data, sell.replacementPattern);
        }
        require(ArrayUtils.arrayEq(buy.data, sell.data), "Marketplace: orders function call is not matched.");
        
        /** Retrieve delegateProxy contract. */
        address delegateProxy = IProxyRegistry(registry).proxies(sell.outline.maker);

        /** Proxy must exist. */
        require(Address.isContract(delegateProxy));

        /** Assert implementation. */
        require(OwnableDelegateProxy(payable(delegateProxy)).implementation() == IProxyRegistry(registry).delegateProxyImplementation());
        
        /** Access the passthrough AuthenticatedProxy. */
        AuthenticatedProxy proxy= AuthenticatedProxy(payable(delegateProxy));
        
        /** EFFECTS */

        /** Mark previously signed or approved orders as finalized. */
        cancelledOrFinalized[buyHash] = true;
        cancelledOrFinalized[sellHash] = true;
    
        /** INTERACTIONS */

        /** Execute funds transfer and pay fees. */
        uint price = executeFundsTransfer(buy, sell);

        /** Execute asset transfer call through proxy. */
        require(proxy.call(sell.outline.target, sell.outline.callType, sell.data));

        /** Static calls are intentionally done after the effectful call so they can check resulting state. */

        /** Handle buy-side static call if specified. */
        if (buy.staticTarget != address(0)) {
            require(staticCall(buy.staticTarget, sell.data, buy.staticExtradata));
        }

        /** Handle sell-side static call if specified. */
        if (sell.staticTarget != address(0)) {
            require(staticCall(sell.staticTarget, sell.data, sell.staticExtradata));
        }

        if (additionalSales.length > 0){
            require(additionalSales.length == sigs.length, "Marketplace: wrong arguments for invalidation.");
            for(uint i; i < additionalSales.length; i++){
                _cancelOrder(additionalSales[i], sigs[i]);
            }
        }

        /** Log match */
        bytes memory settledParameters = abi.encode(price, sell.outline.target, buy.data);

        emit OrdersMatched(buyHash, sellHash,sell.outline.maker, buy.outline.maker, settledParameters);
    }

    /**
     * @dev Calculate the current price of an order (convenience function)
     * @param order Order to calculate the price of
     * @return The current price of the order
     */
    function _calculateCurrentPrice (Order memory order)
        internal  
        view
        returns (uint)
    {
        return Sales.calculateFinalPrice(order.outline.saleKind, order.outline.basePrice, order.extra, order.outline.listingTime);
    }

   /**
     * @dev Calculate the price two orders would matchs at, if in fact they would match (otherwise fail)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Match price
     */
    function _calculateMatchPrice(Order memory buy, Order memory sell)
        view
        internal
        returns (uint)
    {
        /** Calculate sell price. */
        uint sellPrice = Sales.calculateFinalPrice(sell.outline.saleKind, sell.outline.basePrice, sell.extra, sell.outline.listingTime);

        /** Calculate buy price. */
        uint buyPrice = Sales.calculateFinalPrice(buy.outline.saleKind, buy.outline.basePrice, buy.extra, buy.outline.listingTime);

        /** Require price cross. */
        require(buyPrice >= sellPrice);

        /** Maker/taker priority. */
        if (sell.outline.saleKind == Sales.SaleKind.Auction || sell.outline.saleKind == Sales.SaleKind.Offer) {
            return buyPrice;
        } else {
            return sellPrice;
        }
    }
    /**
     * @dev Approve an order and optionally mark it for orderbook inclusion. Must be called by the maker of the order
     * @param order Order to approve
     */
    function _approveOrder(Order memory order)
        internal
    {
        /** CHECKS */

        /** Assert sender is authorized to approve order. */
        require(msg.sender == order.outline.maker);

        require(order.outline.taker != address(0));

        /** Calculate order hash. */
        bytes32 hash = _hashToSign(order);

        /** Assert order has not already been approved. */
        require(!approvedOrders[hash]);

        /** EFFECTS */
    
         /** Mark order as approved. */
        approvedOrders[hash] = true;
  
        emit OrderApproved(hash, order.outline.maker, order.outline.taker, order.data);
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param sig ECDSA signature
     */
    function _cancelOrder(Order memory order, Sig memory sig) 
        internal
    {
        /** CHECKS */

        /** Calculate order hash. */
        bytes32 hash = _hashToSign(order);
        
        /** Assert sender is authorized to cancel order. */
        require(msg.sender == order.outline.maker || authenticateOrder(hash, order.outline.maker, sig));

        /** EFFECTS */
      
        /** Mark order as cancelled, preventing it from being matched. */
        cancelledOrFinalized[hash] = true;

        /** Log cancel event. */
        emit OrderCancelled(hash, msg.sender, order.data);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
  @title An advanced permission-management contract.
  @author Tim Clancy

  This contract allows for a contract owner to delegate specific rights to
  external addresses. Additionally, these rights can be gated behind certain
  sets of circumstances and granted expiration times. This is useful for some
  more finely-grained access control in contracts.

  The owner of this contract is always a fully-permissioned super-administrator.

  August 23rd, 2021.
*/
abstract contract PermitControl is Ownable {
  using Address for address;

  /// A special reserved constant for representing no rights.
  bytes32 public constant ZERO_RIGHT = hex"00000000000000000000000000000000";

  /// A special constant specifying the unique, universal-rights circumstance.
  bytes32 public constant UNIVERSAL = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

  /*
    A special constant specifying the unique manager right. This right allows an
    address to freely-manipulate the `managedRight` mapping.
  **/
  bytes32 public constant MANAGER = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

  /**
    A mapping of per-address permissions to the circumstances, represented as
    an additional layer of generic bytes32 data, under which the addresses have
    various permits. A permit in this sense is represented by a per-circumstance
    mapping which couples some right, represented as a generic bytes32, to an
    expiration time wherein the right may no longer be exercised. An expiration
    time of 0 indicates that there is in fact no permit for the specified
    address to exercise the specified right under the specified circumstance.

    @dev Universal rights MUST be stored under the 0xFFFFFFFFFFFFFFFFFFFFFFFF...
    max-integer circumstance. Perpetual rights may be given an expiry time of
    max-integer.
  */
  mapping( address => mapping( bytes32 => mapping( bytes32 => uint256 )))
    public permissions;

  /**
    An additional mapping of managed rights to manager rights. This mapping
    represents the administrator relationship that various rights have with one
    another. An address with a manager right may freely set permits for that
    manager right's managed rights. Each right may be managed by only one other
    right.
  */
  mapping( bytes32 => bytes32 ) public managerRight;

  /**
    An event emitted when an address has a permit updated. This event captures,
    through its various parameter combinations, the cases of granting a permit,
    updating the expiration time of a permit, or revoking a permit.

    @param updator The address which has updated the permit.
    @param updatee The address whose permit was updated.
    @param circumstance The circumstance wherein the permit was updated.
    @param role The role which was updated.
    @param expirationTime The time when the permit expires.
  */
  event PermitUpdated(
    address indexed updator,
    address indexed updatee,
    bytes32 circumstance,
    bytes32 indexed role,
    uint256 expirationTime
  );

//   /**
//     A version of PermitUpdated for work with setPermits() function.
    
//     @param updator The address which has updated the permit.
//     @param updatees The addresses whose permit were updated.
//     @param circumstances The circumstances wherein the permits were updated.
//     @param roles The roles which were updated.
//     @param expirationTimes The times when the permits expire.
//   */
//   event PermitsUpdated(
//     address indexed updator,
//     address[] indexed updatees,
//     bytes32[] circumstances,
//     bytes32[] indexed roles,
//     uint256[] expirationTimes
//   );

  /**
    An event emitted when a management relationship in `managerRight` is
    updated. This event captures adding and revoking management permissions via
    observing the update history of the `managerRight` value.

    @param manager The address of the manager performing this update.
    @param managedRight The right which had its manager updated.
    @param managerRight The new manager right which was updated to.
  */
  event ManagementUpdated(
    address indexed manager,
    bytes32 indexed managedRight,
    bytes32 indexed managerRight
  );

  /**
    A modifier which allows only the super-administrative owner or addresses
    with a specified valid right to perform a call.

    @param _circumstance The circumstance under which to check for the validity
      of the specified `right`.
    @param _right The right to validate for the calling address. It must be
      non-expired and exist within the specified `_circumstance`.
  */
  modifier hasValidPermit(
    bytes32 _circumstance,
    bytes32 _right
  ) {
    require(_msgSender() == owner()
      || hasRight(_msgSender(), _circumstance, _right),
      "P1");
    _;
  }

  /**
    Return a version number for this contract's interface.
  */
  function version() external virtual pure returns (uint256) {
    return 1;
  }

  /**
    Determine whether or not an address has some rights under the given
    circumstance, and if they do have the right, until when.

    @param _address The address to check for the specified `_right`.
    @param _circumstance The circumstance to check the specified `_right` for.
    @param _right The right to check for validity.
    @return The timestamp in seconds when the `_right` expires. If the timestamp
      is zero, we can assume that the user never had the right.
  */
  function hasRightUntil(
    address _address,
    bytes32 _circumstance,
    bytes32 _right
  ) public view returns (uint256) {
    return permissions[_address][_circumstance][_right];
  }

   /**
    Determine whether or not an address has some rights under the given
    circumstance,

    @param _address The address to check for the specified `_right`.
    @param _circumstance The circumstance to check the specified `_right` for.
    @param _right The right to check for validity.
    @return true or false, whether user has rights and time is valid.
  */
  function hasRight(
    address _address,
    bytes32 _circumstance,
    bytes32 _right
  ) public view returns (bool) {
    return permissions[_address][_circumstance][_right] > block.timestamp;
  }

  /**
    Set the permit to a specific address under some circumstances. A permit may
    only be set by the super-administrative contract owner or an address holding
    some delegated management permit.

    @param _address The address to assign the specified `_right` to.
    @param _circumstance The circumstance in which the `_right` is valid.
    @param _right The specific right to assign.
    @param _expirationTime The time when the `_right` expires for the provided
      `_circumstance`.
  */
  function setPermit(
    address _address,
    bytes32 _circumstance,
    bytes32 _right,
    uint256 _expirationTime
  ) public virtual hasValidPermit(UNIVERSAL, managerRight[_right]) {
    require(_right != ZERO_RIGHT,
      "P2");
    permissions[_address][_circumstance][_right] = _expirationTime;
    emit PermitUpdated(_msgSender(), _address, _circumstance, _right,
      _expirationTime);
  }

//   /**
//     Version of setPermit() that works with multiple addresses in one transaction.

//     @param _addresses The array of addresses to assign the specified `_right` to.
//     @param _circumstances The array of circumstances in which the `_right` is 
//                           valid.
//     @param _rights The array of specific rights to assign.
//     @param _expirationTimes The array of times when the `_rights` expires for 
//                             the provided _circumstance`.
//   */
//   function setPermits(
//     address[] memory _addresses,
//     bytes32[] memory _circumstances, 
//     bytes32[] memory _rights, 
//     uint256[] memory _expirationTimes
//   ) public virtual {
//     require((_addresses.length == _circumstances.length)
//              && (_circumstances.length == _rights.length)
//              && (_rights.length == _expirationTimes.length),
//              "leghts of input arrays are not equal"
//     );
//     bytes32 lastRight;
//     for(uint i = 0; i < _rights.length; i++) {
//       if (lastRight != _rights[i] || (i == 0)) { 
//         require(_msgSender() == owner() || hasRight(_msgSender(), _circumstances[i], _rights[i]), "P1");
//         require(_rights[i] != ZERO_RIGHT, "P2");
//         lastRight = _rights[i];
//       }
//       permissions[_addresses[i]][_circumstances[i]][_rights[i]] = _expirationTimes[i];
//     }
//     emit PermitsUpdated(
//       _msgSender(), 
//       _addresses,
//       _circumstances,
//       _rights,
//       _expirationTimes
//     );
//   }

  /**
    Set the `_managerRight` whose `UNIVERSAL` holders may freely manage the
    specified `_managedRight`.

    @param _managedRight The right which is to have its manager set to
      `_managerRight`.
    @param _managerRight The right whose `UNIVERSAL` holders may manage
      `_managedRight`.
  */
  function setManagerRight(
    bytes32 _managedRight,
    bytes32 _managerRight
  ) external virtual hasValidPermit(UNIVERSAL, MANAGER) {
    require(_managedRight != ZERO_RIGHT,
      "P3");
    managerRight[_managedRight] = _managerRight;
    emit ManagementUpdated(_msgSender(), _managedRight, _managerRight);
  }
}

pragma solidity ^0.8.8;

import "../proxy/OwnableMutableDelegateProxy.sol";

/**
 * @title ProxyRegistry Interface
 * @author Rostislav Khlebnikov
 */
interface IProxyRegistry {

    /// returns address of  current valid implementation of delegate proxy.
    function delegateProxyImplementation() external view returns (address);

    /**
        Returns address of a proxy which was registered for the user address before listing NFTs.
        @param owner address of NFTs lister.
     */
    function proxies(address owner) external view returns (address);

    /**
        Returns true if `caller` to the proxy registry is eligible and registered.
        @param caller address of the caller.
     */
    function authorizedCallers(address caller) external view returns (bool);

}

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IProxyRegistry.sol";

contract TokenTransferProxy {

    /* Authentication registry. */
    IProxyRegistry public registry;

    /**
        @param _registry address of the proxy registry
     */
    constructor (address _registry){
        registry = IProxyRegistry(_registry);
    }

    /**
     * Call ERC20 `transferFrom`
     *
     * @dev Authenticated contract only
     * @param token ERC20 token address
     * @param from From address
     * @param to To address
     * @param amount Transfer amount
     */
    function transferFrom(address token, address from, address to, uint amount)
        public
        returns (bool)
    {   
        require(registry.authorizedCallers(msg.sender));
        return IERC20(token).transferFrom(from, to, amount);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./TokenRecipient.sol";
import "../interfaces/IProxyRegistry.sol";

/**
  @title An ownable call-delegating proxy which can receive tokens and only make
    calls against contracts that have been approved by a `ProxyRegistry`.
  @author Protinam, Project Wyvern
  @author Tim Clancy

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  a component of the primary exchange contract for OpenSea. It has been modified
  to support a more modern version of Solidity with associated best practices.
  The documentation has also been improved to provide more clarity.
*/
contract AuthenticatedProxy is Ownable, TokenRecipient {

  /// Whether or not this proxy is initialized. It may only be initialized once.
  bool public initialized = false;

  /// The associated `ProxyRegistry` contract with authentication information.
  address public registry;

  /// Whether or not access has been revoked.
  bool public revoked;

  /**
    An enumerable type for selecting the method by which we would like to
    perform a call in the `proxy` function.

    @param Call This call type specifies that we perform a direct call.
    @param DelegateCall This call type can be used to automatically transfer
      multiple assets owned by the proxy contract with one order.
  */
  enum CallType {
    Call,
    DelegateCall
  }

  /**
    An event fired when the proxy contract's access is revoked or unrevoked.

    @param revoked The status of the revocation call; true if access is
    revoked and false if access is unrevoked.
  */
  event Revoked(bool revoked);

  /**
    Initialize this authenticated proxy for its owner against a specified
    `ProxyRegistry`. The registry controls the eligible targets.

    @param _registry The registry to create this proxy against.
  */
  function initialize(address _registry) external {
    require(!initialized,
      "AuthenticatedProxy: this proxy may only be initialized once");
    initialized = true;
    registry = _registry;
  }

  /**
    Allow the owner of this proxy to set the revocation flag. This permits them
    to revoke access from the associated `ProxyRegistry` if needed.
  */
  function setRevoke(bool revoke) external onlyOwner {
    revoked = revoke;
    emit Revoked(revoke);
  }

  /**
    Trigger this proxy to call a specific address with the provided data. The
    proxy may perform a direct or a delegate call. This proxy can only be called
    by the owner, or on behalf of the owner by a caller authorized by the
    registry. Unless the user has revoked access to the registry, that is.

    @param _target The target address to make the call to.
    @param _type The type of call to make: direct or delegated.
    @param _data The call data to send to `_target`.
    @return Whether or not the call succeeded.
  */
  function call(address _target, CallType _type, bytes calldata _data) public
    returns (bool) {
    require(_msgSender() == owner()
      || (!revoked && IProxyRegistry(registry).authorizedCallers(_msgSender())),
      "AuthenticatedProxy: not owner, not authorized by an unrevoked registry");

    // The call is authorized to be performed, now select a type and return.
    if (_type == CallType.Call) {
      (bool success, ) = _target.call(_data);
      return success;
    } else if (_type == CallType.DelegateCall) {
      (bool success, ) = _target.delegatecall(_data);
      return success;
    }
    return false;
  }

  /**
    Trigger this proxy to call a specific address with the provided data and
    require success. Otherwise identical to `call()`.

    @param _target The target address to make the call to.
    @param _type The type of call to make: direct or delegated.
    @param _data The call data to send to `_target`.
  */
  function callAssert(address _target, CallType _type, bytes calldata _data)
    external {
    require(call(_target, _type, _data),
      "AuthenticatedProxy: the asserted call did not succeed");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

library Utils {

    // this is struct for aligning function memory 
    struct Slice { 
        uint length;
        uint pointer;
    }

  function Concat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e)
        internal pure
        returns (string memory)
    {
        bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function Concat(string memory _a, string memory _b, string memory _c, string memory _d)
        internal pure
        returns (string memory)
    {
        return Concat(_a, _b, _c, _d, "");
    }

    function Concat(string memory _a, string memory _b, string memory _c)
        internal pure
        returns (string memory)
    {
        return Concat(_a, _b, _c, "", "");
    }

    function Concat(string memory _a, string memory _b)
        internal pure
        returns (string memory)
    {
        return Concat(_a, _b, "", "", "");
    }

    function uint2str(uint _i)
        internal pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        return string(bstr);
    }

    function copyToMemory(uint _destination, uint _source, uint _length)
        private pure
    {
        // Copy word-length chunks while possible
        for(_length ; _length >= 32; _length -= 32) {
            assembly {
                mstore(_destination, mload(_source))
            }
            _destination += 32;
            _source += 32;
        }

        // Copy remaining bytes
        if(_length >0){
            uint mask = 256 ** (32 - _length) - 1;
            assembly {
                let source := and(mload(_source), not(mask))
                let destination := and(mload(_destination), mask)
                mstore(_destination, or(destination, source))
            }
        }
    }

    // make struct slice out of string
    function toSlice(string memory input)
        internal pure
        returns (Slice memory)
    {
        uint ptr;
        assembly {
            ptr := add(input, 0x20)
        }
        return Slice(bytes(input).length, ptr);
    }

    function findPointer(uint inputLength, uint inputPointer, uint toSearchLength, uint toSearchPointer)
        private pure
        returns (uint)
    {
        uint pointer = inputPointer;

        if (toSearchLength <= inputLength) {
            if (toSearchLength <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - toSearchLength)) - 1));

                bytes32 toSearchdata;
                assembly { toSearchdata := and(mload(toSearchPointer), mask) }

                uint end = inputPointer + inputLength - toSearchLength;
                bytes32 data;
                assembly { data := and(mload(pointer), mask) }

                while (data != toSearchdata) {
                    if (pointer >= end)
                        return inputPointer + inputLength;
                    pointer++;
                    assembly { data := and(mload(pointer), mask) }
                }
                return pointer;
            } else {
                // For long toSearchs, use hashing
                bytes32 hash;
                assembly { hash := keccak256(toSearchPointer, toSearchLength) }

                for (uint i = 0; i <= inputLength - toSearchLength; i++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(pointer, toSearchLength) }
                    if (hash == testHash)
                        return pointer;
                    pointer += 1;
                }
            }
        }
        return inputPointer + inputLength;
    }

    function afterMatch(Slice memory input, Slice memory toSearch)
        internal pure
        returns (Slice memory)
    {
        uint pointer = findPointer(input.length, input.pointer, toSearch.length, toSearch.pointer);
        if (pointer == input.pointer + input.length) {
            // Not found
            input.length = 0;
            return input;
        } 
        input.length -= pointer - input.pointer + 1; // escape void space
        input.pointer = pointer +1; // escape token
        return input;
    }

    function beforeMatch(Slice memory input, Slice memory toSearch)
        internal pure
        returns (Slice memory token)
    {
        beforeMatch(input, toSearch, token);
    }

    function beforeMatch(Slice memory input, Slice memory toSearch, Slice memory token)
        internal pure
        returns (Slice memory)
    {
        uint pointer = findPointer(input.length, input.pointer, toSearch.length, toSearch.pointer);
        token.pointer = input.pointer;
        token.length = pointer - input.pointer;
        if (pointer == input.pointer + input.length) {
            // Not found
            input.length = 0;
        } else {
            input.length -= token.length + toSearch.length;
            input.pointer = pointer + toSearch.length;
        }
        return token;
    }

    function toString(Slice memory input)
        internal pure
        returns (string memory)
    {
        string memory result = new string(input.length);
        uint resultPointer;
        assembly { resultPointer := add(result, 32) }

        copyToMemory(resultPointer, input.pointer, input.length);
        return result;
    }

    function split(bytes calldata blob)
        internal
        pure
        returns (uint256, bytes memory)
    {
        int256 index = indexOf(blob, ":", 0);
        require(index >= 0, "Separator must exist");
        // Trim the { and } from the parameters
        uint256 tokenID = toUint(blob[1:uint256(index) - 1]);
        uint256 blueprintLength = blob.length - uint256(index) - 3;
        if (blueprintLength == 0) {
            return (tokenID, bytes(""));
        }
        bytes calldata blueprint = blob[uint256(index) + 2:blob.length - 1];
        return (tokenID, blueprint);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(
        bytes memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (int256) {
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _base.length; i++) {
            if (_base[i] == _valueBytes[0]) {
                return int256(i);
            }
        }

        return -1;
    }

    function toUint(bytes memory b) internal pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 val = uint256(uint8(b[i]));
            if (val >= 48 && val <= 57) {
                result = result * 10 + (val - 48);
            }
        }
        return result;
    }

    function interpolate(string memory source, uint value) internal pure returns (string memory result){
        Slice memory slice1 = toSlice(source);
        Slice memory slice2 = toSlice(source);
        string memory tokenFirst = "{";
        string memory tokenLast = "}";
        Slice memory firstSlice = toSlice(tokenFirst);
        Slice memory secondSlice = toSlice(tokenLast);
        firstSlice = beforeMatch(slice1, firstSlice);
        secondSlice = afterMatch(slice2, secondSlice);
        string memory first = toString(firstSlice);
        string memory second = toString(secondSlice);
        result = Concat(first, uint2str(value), second);
        return result;
    }
}

/**
 * @title ArrayUtils
 * @author Project Wyvern Developers
 */
library ArrayUtils {

    /**
     * Replace bytes in an array with bytes in another array, guarded by a bitmask
     * Efficiency of this function is a bit unpredictable because of the EVM's word-specific model (arrays under 32 bytes will be slower)
     * 
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     */
    function guardedArrayReplace(bytes memory array, bytes memory desired, bytes memory mask)
        internal
        pure
    {
        require(array.length == desired.length);
        require(array.length == mask.length);

        uint words = array.length / 0x20;
        uint index = words * 0x20;
        assert(index / 0x20 == words);
        uint i;

        for (i = 0; i < words; i++) {
            /* Conceptually: array[i] = (!mask[i] && array[i]) || (mask[i] && desired[i]), bitwise in word chunks. */
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            /* This overlaps with bytes already set but is still more efficient than iterating through each of the remaining bytes individually. */
            i = words;
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
               (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] = ((mask[i] ^ 0xff) & array[i]) | (mask[i] & desired[i]);
            }
        }
    }

    /**
     * Test if two arrays are equal
     * Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     * 
     * @dev Arrays must be of equal length, otherwise will return false
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(a)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(b))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(a, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(b, 0x20)
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint index, bytes memory source)
        internal
        pure
        returns (uint)
    {
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for { } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }

    /**
     * Unsafe write address array into a memory location
     *
     * @param index Memory location
     * @param source uint array to write
     * @return End memory index
     */
    function unsafeWriteUintArray(uint index, uint[] memory source)
        internal 
        pure
        returns (uint)
    {   
        for (uint i = 0; i < source.length; i++){
            uint conv = source[i];
            assembly {
                mstore(index, conv)
                index := add(index, 0x20)
            }
        }
        return index;
    }

    /**
     * Unsafe write address nested array into a memory location
     *
     * @param index Memory location
     * @param source Address array to write
     * @return End memory index
     */
    function unsafeWriteAddressArray(uint index, address[] memory source)
        internal 
        pure
        returns (uint)
    {   
        for (uint i = 0; i < source.length; i++){
            uint conv = uint(uint160(source[i])) << 0x60;
            assembly {
                    mstore(index, conv)
                    index := add(index, 0x14)
            }
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location
     *
     * @param index Memory location
     * @param source Address to write
     * @return End memory index
     */
    function unsafeWriteAddress(uint index, address source)
        internal
        pure
        returns (uint)
    {
        uint conv = uint(uint160(source)) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    /**
     * Unsafe write uint into a memory location
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint(uint index, uint source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location
     *
     * @param index Memory location
     * @param source uint8 to write
     * @return End memory index
     */
    function unsafeWriteUint8(uint index, uint8 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }

    function summOfUintArray(uint[] memory source)
    internal pure
    returns (uint sum)
    {
        for (uint i =0; i < source.length; i++){
            sum += source[i];
        }
        return sum;
    }
    
}

/*
  Abstract over fixed-price sales and Dutch auctions, with the intent of easily supporting additional methods of sale later.
  Separated into a library for convenience, all the functions are inlined.
*/

pragma solidity ^0.8.8;

/**
 * @title SaleKindInterface
 * @author Project Wyvern Developers
 */
library Sales {

    /**
     * Side: buy or sell.
     */
    enum Side { Buy, Sell }

    /**
     * Currently supported kinds of sale: fixed price, Dutch auction, DecreasingPrice. 
     * English auctions cannot be supported without stronger escrow guarantees.
     * Future interesting options: Vickrey auction, nonlinear Dutch auctions.
     */

    enum SaleKind {
        SaleFixedPrice,
        SaleDecreasingPrice,
        Auction,
        Offer
    }

    /**
     * @dev Check whether the parameters of a sale are valid
     * @param saleKind Kind of sale
     * @param expirationTime Order expiration time
     * @return Whether the parameters were valid
     */
    function validateParameters(SaleKind saleKind, uint expirationTime)
        pure
        internal
        returns (bool)
    {
        /* Auctions must have a set expiration date. */
        return (saleKind == SaleKind.SaleFixedPrice || saleKind == SaleKind.SaleDecreasingPrice || saleKind == SaleKind.Offer || (saleKind == SaleKind.Auction && expirationTime > 0));
    }

    /**
     * @dev Return whether or not an order can be settled
     * @dev Precondition: parameters have passed validateParameters
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function canSettleOrder(uint listingTime, uint expirationTime)
        view
        internal
        returns (bool)
    {
        return (listingTime < block.timestamp) && (expirationTime == 0 || block.timestamp < expirationTime);
    }

    /**
     * @dev Calculate the settlement price of an order
     * @dev Precondition: parameters have passed validateParameters.
     * @param saleKind Method of sale
     * @param basePrice Order base price
     * @param extra Order extra price and time data
     * @param listingTime Order listing time
     */
    function calculateFinalPrice(SaleKind saleKind, uint basePrice, uint[] memory extra, uint listingTime)
        view
        internal
        returns (uint finalPrice)
    {
        if (saleKind == SaleKind.SaleDecreasingPrice) {
            if(block.timestamp <= listingTime) {
                return basePrice;
            }
            if(block.timestamp >= extra[1]) {
                return extra[0];
            }
            uint res = (basePrice - extra[0])*((extra[1] - block.timestamp) / 60)/((extra[1] - listingTime)/60); // priceMaxRange * minutesPassed / totalListingMinutes
            return extra[0] + res;
        } else {
            return basePrice;
        }
    }

}

pragma solidity ^0.8.8;

abstract contract EIP712 {

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes internal personalSignPrefix = "\x19Ethereum Signed Message:\n";

    bytes32 immutable public DOMAIN_SEPARATOR;
    
    constructor(string memory name, string memory version){
        uint chainId_;
        assembly{
            chainId_ := chainid()
        }
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name              : name,
            version           : version,
            chainId           : chainId_,
            verifyingContract : address(this)
        }));
    }

    function hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function parseSignature(bytes memory signature)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        return(v,r,s);
    }
}

pragma solidity ^0.8.8;

abstract contract ERC1271 {

  // bytes4(keccak256("isValidSignature(bytes,bytes)")
  bytes4 constant internal EIP_1271_MAGICVALUE = 0x20c13b0b;

  /**
   * @dev Should return whether the signature provided is valid for the provided data
   * @param _data Arbitrary length data signed on the behalf of address(this)
   * @param _signature Signature byte array associated with _data
   *
   * MUST return the bytes4 magic value 0x20c13b0b when function passes.
   * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
   * MUST allow external calls
   */
  function isValidSignature(
      bytes memory _data,
      bytes memory _signature)
      virtual
      public
      view
      returns (bytes4 magicValue);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./OwnableDelegateProxy.sol";

/**
  @title A call-delegating proxy whose owner may mutate its target.
  @author Protinam, Project Wyvern
  @author Tim Clancy

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  a component of the primary exchange contract for OpenSea. It has been modified
  to support a more modern version of Solidity with associated best practices.
  The documentation has also been improved to provide more clarity.
*/
contract OwnableMutableDelegateProxy is OwnableDelegateProxy {

  /// The ERC-897 proxy type: this proxy is mutable.
  uint256 public override constant proxyType = 2;

  /**
    This event is emitted each time the target of this proxy is changed.

    @param previousTarget The previous target of this proxy.
    @param newTarget The new target of this proxy.
  */
  event TargetChanged(address indexed previousTarget,
    address indexed newTarget);

  /**
    Construct this delegate proxy with an owner, initial target, and an initial
    call sent to the target.

    @param _owner The address which should own this proxy.
    @param _target The initial target of this proxy.
    @param _data The initial call to delegate to `_target`.
  */
  constructor (address _owner, address _target, bytes memory _data)
    OwnableDelegateProxy(_owner, _target, _data) { }

  /**
    Allows the owner of this proxy to change the proxy's current target.

    @param _target The new target of this proxy.
  */
  function changeTarget(address _target) public onlyOwner {
    require(proxyType == 2,
      "OwnableDelegateProxy: cannot retarget an immutable proxy");
    require(target != _target,
      "OwnableDelegateProxy: cannot retarget to the current target");
    address oldTarget = target;
    target = _target;

    // Emit an event that this proxy's target has been changed.
    emit TargetChanged(oldTarget, _target);
  }

  /**
    Allows the owner of this proxy to change the proxy's current target and
    immediately delegate a call to the new target.

    @param _target The new target of this proxy.
    @param _data A call to delegate to `_target`.
  */
  function changeTargetAndCall(address _target, bytes calldata _data) external
    onlyOwner {
    changeTarget(_target);
    (bool success, ) = address(this).delegatecall(_data);
    require(success,
      "OwnableDelegateProxy: the call to the new target must succeed");
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./DelegateProxy.sol";

/**
  @title A call-delegating proxy with an owner.
  @author Protinam, Project Wyvern
  @author Tim Clancy
  @author Rostislav Khlebnikov

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  a component of the primary exchange contract for OpenSea. It has been modified
  to support a more modern version of Solidity with associated best practices.
  The documentation has also been improved to provide more clarity.

  July 19th, 2021.
*/
abstract contract OwnableDelegateProxy is Ownable, DelegateProxy {

  // Shows if user proxy was initialized
  bool public initialized;
  /// escape slot to match AuthenticatedProxy storage uint8(bool)+uint184 = 192 bits, so target (160 bits) can't be put in this storage slot
  uint184 internal escape;
  /// The address of the proxy's current target.
  address public target;

  /**
    Construct this delegate proxy with an owner, initial target, and an initial
    call sent to the target.

    @param _owner The address which should own this proxy.
    @param _target The initial target of this proxy.
    @param _data The initial call to delegate to `_target`.
  */
  constructor(address _owner, address _target, bytes memory _data) {

    // Do not perform a redundant ownership transfer if the deployer should
    // remain as the owner of this contract.
    if (_owner != owner()) {
      transferOwnership(_owner);
    }
    target = _target;

    // Immediately delegate a call to the initial implementation and require it
    // to succeed. This is often used to trigger some kind of initialization
    // function on the target.
    (bool success, ) = _target.delegatecall(_data);
    require(success,
      "OwnableDelegateProxy: the initial call to target must succeed");
  }

  /**
    Return the current address where all calls to this proxy are delegated. If
    `proxyType()` returns `1`, ERC-897 dictates that this address MUST not
    change.

    @return The current address where calls to this proxy are delegated.
  */
  function implementation() public override view returns (address) {
    return target;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

/**
  @title A basic call-delegating proxy contract which is compliant with the
    current draft version of ERC-897.
  @author Facu Spagnuolo, OpenZeppelin
  @author Protinam, Project Wyvern
  @author Tim Clancy

  This contract was originally developed by OpenZeppelin, then used by
  Project Wyvern (https://github.com/ProjectWyvern/) where it currently enjoys
  great success as a component of the OpenSea exchange system. It has been
  modified to support a more modern version of Solidity with associated best
  practices. The documentation has also been improved to provide more clarity.

  July 19th, 2021.
*/
abstract contract DelegateProxy {

  /**
    The ERC-897 specification seeks to standardize a system of proxy types.

    @return proxyTypeId The type of this proxy. A return value of `1` indicates that this is
      a strictly-forwarding proxy pointed to an unchanging address. A return
      value of `2` indicates that this proxy is upgradeable. The implementation
      address may change at any time based on some arbitrary external logic.
  */
  function proxyType() external virtual pure returns (uint256 proxyTypeId);

  /**
    Return the current address where all calls to this proxy are delegated. If
    `proxyType()` returns `1`, ERC-897 dictates that this address MUST not
    change.

    @return The current address where calls to this proxy are delegated.
  */
  function implementation() public virtual view returns (address);

  /**
    This payable fallback function exists to automatically delegate all calls to
    this proxy to the contract specified from `implementation()`. Anything
    returned from the delegated call will also be returned here.
  */
  fallback() external virtual payable {
    address target = implementation();
    require(target != address(0));

    // Perform the actual call delegation using Yul.
    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), target, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
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
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
  @title A contract which may receive Ether and tokens.
  @author Protinam, Project Wyvern
  @author Tim Clancy

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  a component of the exchange used by OpenSea. It has been modified to support a
  more modern version of Solidity with associated best practices. The
  documentation has also been improved to provide more clarity.
*/
contract TokenRecipient is Context {

  /**
    An event emitted when this contract receives Ether.

    @param sender The sender of the received Ether.
    @param amount The amount of Ether received.
  */
  event ReceivedEther(address indexed sender, uint256 amount);

  /**
    An event emitted when this contract receives ERC-20 tokens.

    @param from The sender of the tokens.
    @param value The amount of token received.
    @param token The address of the token received.
    @param extraData Any extra data associated with the transfer.
  */
  event ReceivedTokens(address indexed from, uint256 value,
    address indexed token, bytes extraData);

  /**
    Receive tokens from address `_from` and emit an event.

    @param _from The address from which tokens are transferred.
    @param _value The amount of tokens to transfer.
    @param _token The address of the tokens to receive.
    @param _extraData Any additional data with this token receipt to emit.
  */
  function receiveApproval(address _from, uint256 _value, address _token,
    bytes calldata _extraData) external {
    bool transferSuccess = IERC20(_token).transferFrom(_from, address(this),
      _value);
    require(transferSuccess,
      "TokenRecipient: failed to transfer tokens from ERC-20");
    emit ReceivedTokens(_from, _value, _token, _extraData);
  }

  /**
    Receive Ether and emit an event.
  */
  receive() external virtual payable {
    emit ReceivedEther(_msgSender(), msg.value);
  }
}