/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

interface WyvernExchange {
    function atomicMatch_(
        address[14] memory addrs,
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
        external
        payable;
}

contract SmartBuyer {

    event MatchSuccessful(bytes32 orderHash);
    event MatchFailed(bytes32 orderHash);

    struct AtomicMatch {
        bytes32 orderHash;
        uint256 value;
        address[14] addrs;
        uint[18] uints;
        uint8[8] feeMethodsSidesKindsHowToCalls;
        bytes calldataBuy;
        bytes calldataSell;
        bytes replacementPatternBuy;
        bytes replacementPatternSell;
        bytes staticExtradataBuy;
        bytes staticExtradataSell;
        uint8[2] vs;
        bytes32[5] rssMetadata;
    }

    function matchOrders(AtomicMatch[] calldata orders, WyvernExchange _exchange)
        public
        payable
    {
        for(uint i = 0; i < orders.length; i++) {
            AtomicMatch memory order = orders[i];
            try _exchange.atomicMatch_{value: order.value}(
                order.addrs, 
                order.uints, 
                order.feeMethodsSidesKindsHowToCalls, 
                order.calldataBuy, 
                order.calldataSell, 
                order.replacementPatternBuy, 
                order.replacementPatternSell, 
                order.staticExtradataBuy, 
                order.staticExtradataSell, 
                order.vs, 
                order.rssMetadata){
                    emit MatchSuccessful(order.orderHash);
                } catch {
                    emit MatchFailed(order.orderHash);
                }
        }

        (payable (msg.sender)).transfer(address(this).balance);
    }
}