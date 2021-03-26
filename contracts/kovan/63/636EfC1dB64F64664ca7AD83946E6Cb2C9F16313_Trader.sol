//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;
import "./Types.sol";

interface IDex {

    function orderIdByHash(bytes32 orderHash) external returns (uint256);

}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

interface ITracer {

    function makeOrder(
        uint256 amount,
        int256 price,
        bool side,
        uint256 expiration
    ) external returns (uint256);

    function permissionedMakeOrder(
        uint256 amount,
        int256 price,
        bool side,
        uint256 expiration,
        address maker
    ) external returns (uint256);

    function takeOrder(uint256 orderId, uint256 amount) external;

    function permissionedTakeOrder(uint256 orderId, uint256 amount, address taker) external;

    function settle(address account) external;

    function tracerBaseToken() external view returns (address);

    function marketId() external view returns(bytes32);

    function leveragedNotionalValue() external view returns(int256);

    function oracle() external view returns(address);

    function gasPriceOracle() external view returns(address);

    function priceMultiplier() external view returns(uint256);

    function feeRate() external view returns(uint256);

    function maxLeverage() external view returns(int256);

    function LIQUIDATION_GAS_COST() external pure returns(uint256);

    function FUNDING_RATE_SENSITIVITY() external pure returns(uint256);

    function currentHour() external view returns(uint8);

    function getOrder(uint orderId) external view returns(uint256, uint256, int256, bool, address, uint256);

    function getOrderTakerAmount(uint256 orderId, address taker) external view returns(uint256);

    function tracerGetBalance(address account) external view returns(
        int256 margin,
        int256 position,
        int256 totalLeveragedValue,
        uint256 deposited,
        int256 lastUpdatedGasPrice,
        uint256 lastUpdatedIndex
    );

    function setUserPermissions(address account, bool permission) external;

    function setInsuranceContract(address insurance) external;

    function setAccountContract(address account) external;

    function setPricingContract(address pricing) external;

    function setOracle(address _oracle) external;

    function setGasOracle(address _gasOracle) external;

    function setFeeRate(uint256 _feeRate) external;

    function setMaxLeverage(int256 _maxLeverage) external;

    function setFundingRateSensitivity(uint256 _fundingRateSensitivity) external;

    function transferOwnership(address newOwner) external;

    function initializePricing() external;

    function matchOrders(uint order1, uint order2) external;
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface Types {

    struct AccountBalance {
        uint256 deposited;
        int256 base; // The amount of units in the base asset
        int256 quote; // The amount of units in the quote asset
        int256 totalLeveragedValue;
        uint256 lastUpdatedIndex;
        int256 lastUpdatedGasPrice;
    }

    struct FundingRate {
        uint256 recordTime;
        int256 recordPrice;
        int256 fundingRate; //positive value = longs pay shorts
        int256 fundingRateValue; //previous rate + (time diff * price * rate)
    }

    struct Order {
        address maker;
        uint256 amount;
        int256 price;
        uint256 filled;
        bool side; //true for long, false for short
        uint256 expiration;
        uint256 creation;
        mapping(address => uint256) takers;
    }

    struct HourlyPrices {
        int256 totalPrice;
        uint256 numTrades;
    }

    struct PricingMetrics {
        Types.HourlyPrices[24] hourlyTracerPrices;
        Types.HourlyPrices[24] hourlyOraclePrices;
    }

    struct LiquidationReceipt {
        address tracer;
        address liquidator;
        address liquidatee;
        int256 price;
        uint256 time;
        uint256 escrowedAmount;
        uint256 releaseTime;
        int256 amountLiquidated;
        bool escrowClaimed;
        bool liquidationSide;
        bool liquidatorRefundClaimed;
    }

    struct LimitOrder {
        uint256 amount;
        int256 price;
        bool side;
        address user;
        uint256 expiration;
        address targetTracer;
        uint256 nonce;
    }

    struct SignedLimitOrder {
        LimitOrder order;
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
    }


}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Interfaces/ITracer.sol";
import "./Interfaces/IDex.sol";
import "./Interfaces/Types.sol";

/**
 * The Trader contract is used to validate and execute off chain signed and matched orders
 */
contract Trader {
    // EIP712 Constants
    // https://eips.ethereum.org/EIPS/eip-712
    string private constant EIP712_DOMAIN_NAME = "Tracer Protocol";
    string private constant EIP712_DOMAIN_VERSION = "1.0";
    bytes32 private constant EIP712_DOMAIN_SEPERATOR =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // EIP712 Types
    bytes32 private constant LIMIT_ORDER_TYPE =
        keccak256(
            "LimitOrder(uint256 amount,int256 price,bool side,address user,uint256 expiration,address targetTracer,uint256 nonce)"
        );

    uint256 public constant chainId = 1337; // Changes per chain
    bytes32 public immutable EIP712_DOMAIN;
    // Trader => nonce
    mapping(address => uint256) public nonces; // Prevents replay attacks

    event Verify(address sig);
    event CheckOrder(uint256 amount, int256 price, bool side, address user, uint256 expiration, address targetTracer);

    constructor() public {
        // Construct the EIP712 Domain
        EIP712_DOMAIN = keccak256(
            abi.encode(
                EIP712_DOMAIN_SEPERATOR,
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @notice Batch executes maker and taker orders against a given market. Currently matching works
     *         by matching orders 1 to 1
     * @param makers An array of signed make orders
     * @param takers An array of signed take orders
     * @param market The market to execute the trade in
     */
    function executeTrade(
        Types.SignedLimitOrder[] memory makers,
        Types.SignedLimitOrder[] memory takers,
        address market
    ) external {
        require(makers.length == takers.length, "TDR: Lengths differ");

        // safe as we've already bounds checked the array lengths
        uint256 n = makers.length;

        require(n > 0, "TDR: Received empty arrays");

        for (uint256 i = 0; i < n; i++) {
            // retrieve orders and verify their signatures
            // if the order does not exist, it is created here
            uint256 makeOrderId = grabOrder(makers, i, market);
            uint256 takeOrderId = grabOrder(takers, i, market);

            address maker = makers[i].order.user;
            address taker = takers[i].order.user;
            nonces[maker]++;
            nonces[taker]++;

            // match orders
            ITracer(market).matchOrders(makeOrderId, takeOrderId);

        }
    }

    /**
     * @notice Retrieves and validates an order from an order array
     * @param orders an array of orders
     * @param index the index into the array where the desired order is
     * @return the specified order
     * @dev Performs its own bounds check on the array access
     */
    function grabOrder(Types.SignedLimitOrder[] memory orders, uint256 index, address market)
        internal
        returns (uint256)
    {
        require(index <= orders.length, "TDR: Out of bounds access");

        IDex dex = IDex(market);

        Types.SignedLimitOrder memory signedOrder = orders[index];

        // verify signature and nonce
        verify(
            signedOrder.order.user,
            signedOrder.order,
            signedOrder.sigR,
            signedOrder.sigS,
            signedOrder.sigV
        );

        bytes32 orderHash = hashOrderForDex(signedOrder.order);
        // check if order exists on chain, if not, create it
        uint orderId = dex.orderIdByHash(orderHash);
        if (orderId == 0) {
            //Create the order
            return ITracer(market).permissionedMakeOrder(
                signedOrder.order.amount,
                signedOrder.order.price,
                signedOrder.order.side,
                signedOrder.order.expiration,
                signedOrder.order.user);
        }

        return (orderId);
    }

    /**
     * @notice hashes a limit order type in order to verify signatures, per EIP712
     * @param order the limit order being hashed
     * @return an EIP712 compliant hash (with headers) of the limit order
     */
    function hashOrder(Types.LimitOrder memory order) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    EIP712_DOMAIN,
                    keccak256(
                        abi.encode(
                            LIMIT_ORDER_TYPE,
                            order.amount,
                            order.price,
                            order.side,
                            order.user,
                            order.expiration,
                            order.targetTracer,
                            order.nonce
                        )
                    )
                )
            );
    }

       /**
     * @notice hashes a limit order type
     * @param order the limit order being hashed
     * @return a simple hash as used by the simple dex to store order ids
     */
    function hashOrderForDex(Types.LimitOrder memory order) public view returns (bytes32) {
        return(
            keccak256(
                abi.encode(order.amount, order.price, order.side, order.user, order.expiration)
            )
        );
    }

    /**
     * @notice Gets the EIP712 domain hash of the contract
     */
    function getDomain() external view returns (bytes32) {
        return EIP712_DOMAIN;
    }

    /**
     * @notice Verifies a given limit order has been signed by a given signer and has a correct nonce
     * @param signer The signer who is being verified against the order
     * @param order The unsigned order to verify the signature of
     * @param sigR R component of the signature
     * @param sigS S component of the signature
     * @param sigV V component of the signature
     * @return true is signer has signed the order as given by the signature components
     *         and if the nonce of the order is correct else false.
     */
    function verify(
        address signer,
        Types.LimitOrder memory order,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public view returns (bool) {
        require(verifySignature(signer, order, sigR, sigS, sigV), "TDR: Signature verification failed");
        require(verifyNonce(order), "TDR: Incorrect nonce");
        return true;
    }

    /**
     * @notice Verifies the signature component of a signed order
     * @param signer The signer who is being verified against the order
     * @param order The unsigned order to verify the signature of
     * @param sigR R component of the signature
     * @param sigS S component of the signature
     * @param sigV V component of the signature
     * @return true is signer has signed the order, else false
     */
    function verifySignature(
        address signer,
        Types.LimitOrder memory order,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public view returns (bool) {
        return signer == ecrecover(hashOrder(order), sigV, sigR, sigS);
    }

    /**
     * @notice Verifies that the nonce of a order is the current user nonce
     * @param order The order being verified
     */
    function verifyNonce(Types.LimitOrder memory order) public view returns (bool) {
        return order.nonce == nonces[order.user];
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