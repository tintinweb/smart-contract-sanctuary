/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// File: overloadedEvent.sol

pragma solidity ^0.6.0;

contract OverloadedEvent {

    struct TxMetaData {
        string source;
        bytes32 transactionHash;
        uint256 settleAmount;
        uint256 receivedAmount;
        uint16 feeFactor;
        uint16 subsidyFactor;
    }

    struct Order {
        address makerAddr;
        address takerAssetAddr;
        address makerAssetAddr;
        uint256 takerAssetAmount;
        uint256 makerAssetAmount;
        address userAddr;
        address payable receiverAddr;
        uint256 salt;
        uint256 deadline;
    }

    event Swapped(
        string source,
        bytes32 indexed transactionHash,
        address indexed userAddr,
        address takerAssetAddr,
        uint256 takerAssetAmount,
        address makerAddr,
        address makerAssetAddr,
        uint256 makerAssetAmount,
        address receiverAddr,
        uint256 settleAmount,
        uint256 receivedAmount,
        uint16 feeFactor,
        uint16 subsidyFactor
    );

    function emitAddrEvent(address _a, uint256 _n) external {
        emit Swapped(
            "OLD",
            bytes32(_n),
            _a,
            _a,
            _n,
            _a,
            _a,
            _n,
            _a,
            _n,
            _n,
            uint16(4),
            uint16(5)
        );
    }
}

// File: overloadedEventInherited.sol

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


contract OverloadedEventInherited is OverloadedEvent {

    event Swapped(TxMetaData, Order order);
    
    function emitUintEvent(address _a, uint256 _n) external {
        TxMetaData memory txMetaData = TxMetaData(
            "NEW",
            bytes32(_n),
            _n,
            _n,
            uint16(4),
            uint16(5)
        );

        Order memory order = Order(
            _a,
            _a,
            _a,
            _n,
            _n,
            _a,
            payable(_a),
            _n,
            _n
        );

        emit Swapped(
            txMetaData,
            order
        );
    }
}