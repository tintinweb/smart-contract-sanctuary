pragma solidity ^0.5.2;

interface MarketplaceToken {
    function transferWithSig(
        bytes calldata sig,
        uint256 tokenIdOrAmount,
        bytes32 data,
        uint256 expiration,
        address to
    ) external returns (address);
}

contract Marketplace {
    struct Order {
        address token;
        bytes sig;
        uint256 tokenIdOrAmount;
    }

    function executeOrder(
        bytes memory data1,
        bytes memory data2,
        bytes32 orderId,
        uint256 expiration,
        address taker
    ) public {
        Order memory order1 = decode(data1);
        Order memory order2 = decode(data2);

        // Transferring order1.token tokens from tradeParticipant1 to address2
        address tradeParticipant1 = MarketplaceToken(order1.token)
            .transferWithSig(
            order1.sig,
            order1.tokenIdOrAmount,
            keccak256(
                abi.encodePacked(orderId, order2.token, order2.tokenIdOrAmount)
            ),
            expiration,
            taker
        );

        // Transferring token2 from tradeParticipant2 to tradeParticipant1
        address tradeParticipant2 = MarketplaceToken(order2.token)
            .transferWithSig(
            order2.sig,
            order2.tokenIdOrAmount,
            keccak256(
                abi.encodePacked(orderId, order1.token, order1.tokenIdOrAmount)
            ),
            expiration,
            tradeParticipant1
        );
        require(taker == tradeParticipant2, "Orders are not complimentary");
    }

    function decode(bytes memory data)
        internal
        pure
        returns (Order memory order)
    {
        (order.token, order.sig, order.tokenIdOrAmount) = abi.decode(
            data,
            (address, bytes, uint256)
        );
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}