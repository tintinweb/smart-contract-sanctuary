// SPDX-License-Identifier: MIT
import "./ERC20.sol";
import "./ExchangeCore.sol";
import "./SaleKindInterface.sol";
import "./Ownable.sol";

pragma solidity ^0.8.0;

contract ExchangeOperator is Ownable {
    ExchangeCore core;
    address payable coreAddress;
    
    constructor(address payable _coreAddress) Ownable() {
        coreAddress = _coreAddress;
        core = ExchangeCore(_coreAddress);
    }

    function setCoreAddress(address payable _coreAddress) public onlyOwner {
        coreAddress = _coreAddress;
        core = ExchangeCore(_coreAddress);
    }
    
    /**
     * @dev Call approveOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function approveOrder_ (
        address payable[7] memory addrs,
        uint[9] memory uints,
        ExchangeCore.FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory data,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        bool orderbookInclusionDesired) 
        public
    {
        return core.approveOrder(getOrder(addrs, uints, feeMethod, side, saleKind, howToCall, data, replacementPattern, staticExtradata), orderbookInclusionDesired);
    }

    /**
     * @dev Call cancelOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function cancelOrder_(
        address payable[7] memory addrs,
        uint[9] memory uints,
        ExchangeCore.FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory data,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        uint8 v,
        bytes32[2] memory rs)
        public
    {
        return core.cancelOrder(getOrder(addrs, uints, feeMethod, side, saleKind, howToCall, data, replacementPattern, staticExtradata), ExchangeCore.Sig(v, rs[0], rs[1]));
    }

    /**
     * @dev Call atomicMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function atomicMatch_(
        address payable[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata)
        public
        payable
    {
        coreAddress.transfer(msg.value);
        (ExchangeCore.Order memory buy, ExchangeCore.Order memory sell) = getBuySellOrder(addrs, uints, feeMethodsSidesKindsHowToCalls, calldataBuy, calldataSell, replacementPatternBuy, replacementPatternSell, staticExtradataBuy, staticExtradataSell);
        return core.atomicMatch(
          buy,
          ExchangeCore.Sig(vs[0], rssMetadata[0], rssMetadata[1]),
          sell,
          ExchangeCore.Sig(vs[1], rssMetadata[2], rssMetadata[3]),
          rssMetadata[4]
        );
    }
    
    /**
     * @dev Call hashOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashOrder_(
        address payable[7] memory  addrs,
        uint[9] memory uints,
        ExchangeCore.FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory data,
        bytes memory replacementPattern,
        bytes memory staticExtradata)
        public
        view
        returns (bytes32)
    {
        return core.hashOrder(
          getOrder(addrs, uints, feeMethod, side, saleKind, howToCall, data, replacementPattern, staticExtradata)
        );
    }

    /**
     * @dev Call hashToSign - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashToSign_(
        address payable[7] memory addrs,
        uint[9] memory uints,
        ExchangeCore.FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory data,
        bytes memory replacementPattern,
        bytes memory staticExtradata)
        public
        view
        returns (bytes32)
    {
        return core.hashToSign(
            getOrder(addrs, uints, feeMethod, side, saleKind, howToCall, data, replacementPattern, staticExtradata)        
        );
    }

    /**
     * @dev Call validateOrderParameters - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrderParameters_ (
        address payable[7] memory addrs,
        uint[9] memory uints,
        ExchangeCore.FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory data,
        bytes memory replacementPattern,
        bytes memory staticExtradata)
        public
        view
        returns (bool)
    {
        return core.validateOrderParameters(
          getOrder(addrs, uints, feeMethod, side, saleKind, howToCall, data, replacementPattern, staticExtradata)
        );
    }

    /**
     * @dev Call validateOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrder_ (
        address payable[7] memory addrs,
        uint[9] memory uints,
        ExchangeCore.FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory data,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        uint8 v,
        bytes32[2] memory rs)
        public
    {
        ExchangeCore.Order memory order = getOrder(addrs, uints, feeMethod, side, saleKind, howToCall, data, replacementPattern, staticExtradata);
        require(core.validateOrder(
          core.hashToSign(order),
          order,
          ExchangeCore.Sig(v, rs[0], rs[1])
        ));
    }
    
    /**
     * @dev Call calculateCurrentPrice - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function calculateCurrentPrice_(
        address payable[7] memory addrs,
        uint[9] memory uints,
        ExchangeCore.FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory data,
        bytes memory replacementPattern,
        bytes memory staticExtradata)
        public
        view
        returns (uint)
    {
        return core.calculateCurrentPrice(
            getOrder(addrs, uints, feeMethod, side, saleKind, howToCall, data, replacementPattern, staticExtradata)
        );
    }
    
    /**
     * @dev Call ordersCanMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function ordersCanMatch_(
        address payable[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell)
        public
        view
        returns (bool)
    {
        (ExchangeCore.Order memory buy, ExchangeCore.Order memory sell) = getBuySellOrder(addrs, uints, feeMethodsSidesKindsHowToCalls, calldataBuy, calldataSell, replacementPatternBuy, replacementPatternSell, staticExtradataBuy, staticExtradataSell);
        return core.ordersCanMatch(
          buy,
          sell
        );
    }
    
    /**
     * @dev Call calculateMatchPrice - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function calculateMatchPrice_(
        address payable[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell)
        public
        view
        returns (uint)
    {
        (ExchangeCore.Order memory buy, ExchangeCore.Order memory sell) = getBuySellOrder(addrs, uints, feeMethodsSidesKindsHowToCalls, calldataBuy, calldataSell, replacementPatternBuy, replacementPatternSell, staticExtradataBuy, staticExtradataSell);
        return core.calculateMatchPrice(
          buy,
          sell
        );
    }
    
    /**
     * @dev Call getOrder
     */
    function getOrder(
        address payable[7] memory  addrs,
        uint[9] memory uints,
        ExchangeCore.FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory data,
        bytes memory replacementPattern,
        bytes memory staticExtradata)
        internal
        pure
        returns (ExchangeCore.Order memory)
    {
        return ExchangeCore.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, data, replacementPattern, addrs[5], staticExtradata, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8]);
    }
    
    /**
     * @dev Call getBuySellOrder
     */
    function getBuySellOrder(
    address payable[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell)
        internal
        pure
        returns (ExchangeCore.Order memory, ExchangeCore.Order memory)
    {
        return 
        (ExchangeCore.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], ExchangeCore.FeeMethod(feeMethodsSidesKindsHowToCalls[0]), SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[1]), SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[2]), addrs[4], AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[3]), calldataBuy, replacementPatternBuy, addrs[5], staticExtradataBuy, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8]), 
        ExchangeCore.Order(addrs[7], addrs[8], addrs[9], uints[9], uints[10], uints[11], uints[12], addrs[10], ExchangeCore.FeeMethod(feeMethodsSidesKindsHowToCalls[4]), SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[5]), SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[6]), addrs[11], AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[7]), calldataSell, replacementPatternSell, addrs[12], staticExtradataSell, addrs[13], uints[13], uints[14], uints[15], uints[16], uints[17]));
    }
}