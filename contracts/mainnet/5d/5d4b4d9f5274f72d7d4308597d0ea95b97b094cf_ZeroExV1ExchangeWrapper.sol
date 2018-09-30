pragma solidity 0.4.24;
pragma experimental "v0.5.0";

/*

    Copyright 2018 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/external/0x/v1/ZeroExExchangeInterfaceV1.sol

/// @title Exchange - Facilitates exchange of ERC20 tokens.
/// @author Amir Bandeali - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0f6e62667d4f3f775f7d60656a6c7b216c6062">[email&#160;protected]</a>>, Will Warren - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6c1b0500002c5c143c1e0306090f18420f0301">[email&#160;protected]</a>>
contract ZeroExExchangeInterfaceV1 {
    // Error Codes
    enum Errors {
        ORDER_EXPIRED,                    // Order has already expired
        ORDER_FULLY_FILLED_OR_CANCELLED,  // Order has already been fully filled or cancelled
        ROUNDING_ERROR_TOO_LARGE,         // Rounding error too large
        INSUFFICIENT_BALANCE_OR_ALLOWANCE // Insufficient balance or allowance for token transfer
    }

    string constant public VERSION = "1.0.0";
    uint16 constant public EXTERNAL_QUERY_GAS_LIMIT = 4999;    // Changes to state require at least 5000 gas

    address public ZRX_TOKEN_CONTRACT;
    address public TOKEN_TRANSFER_PROXY_CONTRACT;

    // Mappings of orderHash => amounts of takerTokenAmount filled or cancelled.
    mapping (bytes32 => uint256) public filled;
    mapping (bytes32 => uint256) public cancelled;

    /*
    * Core exchange functions
    */

    /// @dev Fills the input order.
    /// @param orderAddresses Array of order&#39;s maker, taker, makerToken, takerToken, and feeRecipient.
    /// @param orderValues Array of order&#39;s makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
    /// @param fillTakerTokenAmount Desired amount of takerToken to fill.
    /// @param shouldThrowOnInsufficientBalanceOrAllowance Test if transfer will fail before attempting.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @return Total amount of takerToken filled in trade.
    function fillOrder(
        address[5] orderAddresses,
        uint256[6] orderValues,
        uint256 fillTakerTokenAmount,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8 v,
        bytes32 r,
        bytes32 s)
        public
        returns (uint256 filledTakerTokenAmount);

    /// @dev Cancels the input order.
    /// @param orderAddresses Array of order&#39;s maker, taker, makerToken, takerToken, and feeRecipient.
    /// @param orderValues Array of order&#39;s makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
    /// @param cancelTakerTokenAmount Desired amount of takerToken to cancel in order.
    /// @return Amount of takerToken cancelled.
    function cancelOrder(
        address[5] orderAddresses,
        uint256[6] orderValues,
        uint256 cancelTakerTokenAmount)
        public
        returns (uint256);

    /*
    * Wrapper functions
    */

    /// @dev Fills an order with specified parameters and ECDSA signature, throws if specified amount not filled entirely.
    /// @param orderAddresses Array of order&#39;s maker, taker, makerToken, takerToken, and feeRecipient.
    /// @param orderValues Array of order&#39;s makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
    /// @param fillTakerTokenAmount Desired amount of takerToken to fill.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    function fillOrKillOrder(
        address[5] orderAddresses,
        uint256[6] orderValues,
        uint256 fillTakerTokenAmount,
        uint8 v,
        bytes32 r,
        bytes32 s)
        public;

    /// @dev Synchronously executes multiple fill orders in a single transaction.
    /// @param orderAddresses Array of address arrays containing individual order addresses.
    /// @param orderValues Array of uint256 arrays containing individual order values.
    /// @param fillTakerTokenAmounts Array of desired amounts of takerToken to fill in orders.
    /// @param shouldThrowOnInsufficientBalanceOrAllowance Test if transfers will fail before attempting.
    /// @param v Array ECDSA signature v parameters.
    /// @param r Array of ECDSA signature r parameters.
    /// @param s Array of ECDSA signature s parameters.
    function batchFillOrders(
        address[5][] orderAddresses,
        uint256[6][] orderValues,
        uint256[] fillTakerTokenAmounts,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8[] v,
        bytes32[] r,
        bytes32[] s)
        public;

    /// @dev Synchronously executes multiple fillOrKill orders in a single transaction.
    /// @param orderAddresses Array of address arrays containing individual order addresses.
    /// @param orderValues Array of uint256 arrays containing individual order values.
    /// @param fillTakerTokenAmounts Array of desired amounts of takerToken to fill in orders.
    /// @param v Array ECDSA signature v parameters.
    /// @param r Array of ECDSA signature r parameters.
    /// @param s Array of ECDSA signature s parameters.
    function batchFillOrKillOrders(
        address[5][] orderAddresses,
        uint256[6][] orderValues,
        uint256[] fillTakerTokenAmounts,
        uint8[] v,
        bytes32[] r,
        bytes32[] s)
        public;

    /// @dev Synchronously executes multiple fill orders in a single transaction until total fillTakerTokenAmount filled.
    /// @param orderAddresses Array of address arrays containing individual order addresses.
    /// @param orderValues Array of uint256 arrays containing individual order values.
    /// @param fillTakerTokenAmount Desired total amount of takerToken to fill in orders.
    /// @param shouldThrowOnInsufficientBalanceOrAllowance Test if transfers will fail before attempting.
    /// @param v Array ECDSA signature v parameters.
    /// @param r Array of ECDSA signature r parameters.
    /// @param s Array of ECDSA signature s parameters.
    /// @return Total amount of fillTakerTokenAmount filled in orders.
    function fillOrdersUpTo(
        address[5][] orderAddresses,
        uint256[6][] orderValues,
        uint256 fillTakerTokenAmount,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8[] v,
        bytes32[] r,
        bytes32[] s)
        public
        returns (uint256);

    /// @dev Synchronously cancels multiple orders in a single transaction.
    /// @param orderAddresses Array of address arrays containing individual order addresses.
    /// @param orderValues Array of uint256 arrays containing individual order values.
    /// @param cancelTakerTokenAmounts Array of desired amounts of takerToken to cancel in orders.
    function batchCancelOrders(
        address[5][] orderAddresses,
        uint256[6][] orderValues,
        uint256[] cancelTakerTokenAmounts)
        public;

    /*
    * Constant public functions
    */

    /// @dev Calculates Keccak-256 hash of order with specified parameters.
    /// @param orderAddresses Array of order&#39;s maker, taker, makerToken, takerToken, and feeRecipient.
    /// @param orderValues Array of order&#39;s makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
    /// @return Keccak-256 hash of order.
    function getOrderHash(address[5] orderAddresses, uint256[6] orderValues)
        public
        view
        returns (bytes32);

    /// @dev Verifies that an order signature is valid.
    /// @param signer address of signer.
    /// @param hash Signed Keccak-256 hash.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @return Validity of order signature.
    function isValidSignature(
        address signer,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s)
        public
        pure
        returns (bool);

    /// @dev Checks if rounding error > 0.1%.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return Rounding error is present.
    function isRoundingError(uint256 numerator, uint256 denominator, uint256 target)
        public
        pure
        returns (bool);

    /// @dev Calculates partial value given a numerator and denominator.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target.
    function getPartialAmount(uint256 numerator, uint256 denominator, uint256 target)
        public
        pure
        returns (uint256);

    /// @dev Calculates the sum of values already filled and cancelled for a given order.
    /// @param orderHash The Keccak-256 hash of the given order.
    /// @return Sum of values already filled and cancelled.
    function getUnavailableTakerTokenAmount(bytes32 orderHash)
        public
        view
        returns (uint256);
}

// File: contracts/lib/MathHelpers.sol

/**
 * @title MathHelpers
 * @author dYdX
 *
 * This library helps with common math functions in Solidity
 */
library MathHelpers {
    using SafeMath for uint256;

    /**
     * Calculates partial value given a numerator and denominator.
     *
     * @param  numerator    Numerator
     * @param  denominator  Denominator
     * @param  target       Value to calculate partial of
     * @return              target * numerator / denominator
     */
    function getPartialAmount(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256)
    {
        return numerator.mul(target).div(denominator);
    }

    /**
     * Calculates partial value given a numerator and denominator, rounded up.
     *
     * @param  numerator    Numerator
     * @param  denominator  Denominator
     * @param  target       Value to calculate partial of
     * @return              Rounded-up result of target * numerator / denominator
     */
    function getPartialAmountRoundedUp(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256)
    {
        return divisionRoundedUp(numerator.mul(target), denominator);
    }

    /**
     * Calculates division given a numerator and denominator, rounded up.
     *
     * @param  numerator    Numerator.
     * @param  denominator  Denominator.
     * @return              Rounded-up result of numerator / denominator
     */
    function divisionRoundedUp(
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        assert(denominator != 0); // coverage-enable-line
        if (numerator == 0) {
            return 0;
        }
        return numerator.sub(1).div(denominator).add(1);
    }

    /**
     * Calculates and returns the maximum value for a uint256 in solidity
     *
     * @return  The maximum value for uint256
     */
    function maxUint256(
    )
        internal
        pure
        returns (uint256)
    {
        return 2 ** 256 - 1;
    }

    /**
     * Calculates and returns the maximum value for a uint256 in solidity
     *
     * @return  The maximum value for uint256
     */
    function maxUint32(
    )
        internal
        pure
        returns (uint32)
    {
        return 2 ** 32 - 1;
    }

    /**
     * Returns the number of bits in a uint256. That is, the lowest number, x, such that n >> x == 0
     *
     * @param  n  The uint256 to get the number of bits in
     * @return    The number of bits in n
     */
    function getNumBits(
        uint256 n
    )
        internal
        pure
        returns (uint256)
    {
        uint256 first = 0;
        uint256 last = 256;
        while (first < last) {
            uint256 check = (first + last) / 2;
            if ((n >> check) == 0) {
                last = check;
            } else {
                first = check + 1;
            }
        }
        assert(first <= 256);
        return first;
    }
}

// File: contracts/lib/GeneralERC20.sol

/**
 * @title GeneralERC20
 * @author dYdX
 *
 * Interface for using ERC20 Tokens. We have to use a special interface to call ERC20 functions so
 * that we dont automatically revert when calling non-compliant tokens that have no return value for
 * transfer(), transferFrom(), or approve().
 */
interface GeneralERC20 {
    function totalSupply(
    )
        external
        view
        returns (uint256);

    function balanceOf(
        address who
    )
        external
        view
        returns (uint256);

    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

    function transfer(
        address to,
        uint256 value
    )
        external;


    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external;

    function approve(
        address spender,
        uint256 value
    )
        external;
}

// File: contracts/lib/TokenInteract.sol

/**
 * @title TokenInteract
 * @author dYdX
 *
 * This library contains functions for interacting with ERC20 tokens
 */
library TokenInteract {
    function balanceOf(
        address token,
        address owner
    )
        internal
        view
        returns (uint256)
    {
        return GeneralERC20(token).balanceOf(owner);
    }

    function allowance(
        address token,
        address owner,
        address spender
    )
        internal
        view
        returns (uint256)
    {
        return GeneralERC20(token).allowance(owner, spender);
    }

    function approve(
        address token,
        address spender,
        uint256 amount
    )
        internal
    {
        GeneralERC20(token).approve(spender, amount);

        require(
            checkSuccess(),
            "TokenInteract#approve: Approval failed"
        );
    }

    function transfer(
        address token,
        address to,
        uint256 amount
    )
        internal
    {
        address from = address(this);
        if (
            amount == 0
            || from == to
        ) {
            return;
        }

        GeneralERC20(token).transfer(to, amount);

        require(
            checkSuccess(),
            "TokenInteract#transfer: Transfer failed"
        );
    }

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        if (
            amount == 0
            || from == to
        ) {
            return;
        }

        GeneralERC20(token).transferFrom(from, to, amount);

        require(
            checkSuccess(),
            "TokenInteract#transferFrom: TransferFrom failed"
        );
    }

    // ============ Private Helper-Functions ============

    /**
     * Checks the return value of the previous function up to 32 bytes. Returns true if the previous
     * function returned 0 bytes or 32 bytes that are not all-zero.
     */
    function checkSuccess(
    )
        private
        pure
        returns (bool)
    {
        uint256 returnValue = 0;

        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            // check number of bytes returned from last function call
            switch returndatasize

            // no bytes returned: assume success
            case 0x0 {
                returnValue := 1
            }

            // 32 bytes returned: check if non-zero
            case 0x20 {
                // copy 32 bytes into scratch space
                returndatacopy(0x0, 0x0, 0x20)

                // load those bytes into returnValue
                returnValue := mload(0x0)
            }

            // not sure what was returned: dont mark as success
            default { }
        }

        return returnValue != 0;
    }
}

// File: contracts/margin/interfaces/ExchangeReader.sol

/**
 * @title ExchangeReader
 * @author dYdX
 *
 * Contract interface that wraps an exchange and provides information about the current state of the
 * exchange or particular orders
 */
interface ExchangeReader {

    // ============ Public Functions ============

    /**
     * Get the maxmimum amount of makerToken for some order
     *
     * @param  makerToken           Address of makerToken, the token to receive
     * @param  takerToken           Address of takerToken, the token to pay
     * @param  orderData            Arbitrary bytes data for any information to pass to the exchange
     * @return                      Maximum amount of makerToken
     */
    function getMaxMakerAmount(
        address makerToken,
        address takerToken,
        bytes orderData
    )
        external
        view
        returns (uint256);
}

// File: contracts/margin/interfaces/ExchangeWrapper.sol

/**
 * @title ExchangeWrapper
 * @author dYdX
 *
 * Contract interface that Exchange Wrapper smart contracts must implement in order to interface
 * with other smart contracts through a common interface.
 */
interface ExchangeWrapper {

    // ============ Public Functions ============

    /**
     * Exchange some amount of takerToken for makerToken.
     *
     * @param  tradeOriginator      Address of the initiator of the trade (however, this value
     *                              cannot always be trusted as it is set at the discretion of the
     *                              msg.sender)
     * @param  receiver             Address to set allowance on once the trade has completed
     * @param  makerToken           Address of makerToken, the token to receive
     * @param  takerToken           Address of takerToken, the token to pay
     * @param  requestedFillAmount  Amount of takerToken being paid
     * @param  orderData            Arbitrary bytes data for any information to pass to the exchange
     * @return                      The amount of makerToken received
     */
    function exchange(
        address tradeOriginator,
        address receiver,
        address makerToken,
        address takerToken,
        uint256 requestedFillAmount,
        bytes orderData
    )
        external
        returns (uint256);

    /**
     * Get amount of takerToken required to buy a certain amount of makerToken for a given trade.
     * Should match the takerToken amount used in exchangeForAmount. If the order cannot provide
     * exactly desiredMakerToken, then it must return the price to buy the minimum amount greater
     * than desiredMakerToken
     *
     * @param  makerToken         Address of makerToken, the token to receive
     * @param  takerToken         Address of takerToken, the token to pay
     * @param  desiredMakerToken  Amount of makerToken requested
     * @param  orderData          Arbitrary bytes data for any information to pass to the exchange
     * @return                    Amount of takerToken the needed to complete the transaction
     */
    function getExchangeCost(
        address makerToken,
        address takerToken,
        uint256 desiredMakerToken,
        bytes orderData
    )
        external
        view
        returns (uint256);
}

// File: contracts/margin/external/exchangewrappers/ZeroExV1ExchangeWrapper.sol

/**
 * @title ZeroExV1ExchangeWrapper
 * @author dYdX
 *
 * dYdX ExchangeWrapper to interface with 0x Version 1
 */
contract ZeroExV1ExchangeWrapper is
    ExchangeWrapper,
    ExchangeReader
{
    using SafeMath for uint256;
    using TokenInteract for address;

    // ============ Structs ============

    struct Order {
        address maker;
        address taker;
        address feeRecipient;
        uint256 makerTokenAmount;
        uint256 takerTokenAmount;
        uint256 makerFee;
        uint256 takerFee;
        uint256 expirationUnixTimestampSec;
        uint256 salt;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // ============ State Variables ============

    // msg.senders that will put the correct tradeOriginator in callerData when doing an exchange
    mapping (address => bool) public TRUSTED_MSG_SENDER;

    // address of the ZeroEx V1 Exchange
    address public ZERO_EX_EXCHANGE;

    // address of the ZeroEx V1 TokenTransferProxy
    address public ZERO_EX_TOKEN_PROXY;

    // address of the ZRX token
    address public ZRX;

    // ============ Constructor ============

    constructor(
        address zeroExExchange,
        address zeroExProxy,
        address zrxToken,
        address[] trustedMsgSenders
    )
        public
    {
        ZERO_EX_EXCHANGE = zeroExExchange;
        ZERO_EX_TOKEN_PROXY = zeroExProxy;
        ZRX = zrxToken;

        for (uint256 i = 0; i < trustedMsgSenders.length; i++) {
            TRUSTED_MSG_SENDER[trustedMsgSenders[i]] = true;
        }

        // The ZRX token does not decrement allowance if set to MAX_UINT
        // therefore setting it once to the maximum amount is sufficient
        // NOTE: this is *not* standard behavior for an ERC20, so do not rely on it for other tokens
        ZRX.approve(ZERO_EX_TOKEN_PROXY, MathHelpers.maxUint256());
    }

    // ============ Public Functions ============

    function exchange(
        address tradeOriginator,
        address receiver,
        address makerToken,
        address takerToken,
        uint256 requestedFillAmount,
        bytes orderData
    )
        external
        returns (uint256)
    {
        Order memory order = parseOrder(orderData);

        require(
            requestedFillAmount <= order.takerTokenAmount,
            "ZeroExV1ExchangeWrapper#exchange: Requested fill amount larger than order size"
        );

        require(
            requestedFillAmount <= takerToken.balanceOf(address(this)),
            "ZeroExV1ExchangeWrapper#exchange: Requested fill amount larger than tokens held"
        );

        transferTakerFee(
            order,
            tradeOriginator,
            requestedFillAmount
        );

        ensureAllowance(
            takerToken,
            ZERO_EX_TOKEN_PROXY,
            requestedFillAmount
        );

        uint256 receivedMakerTokenAmount = doTrade(
            order,
            makerToken,
            takerToken,
            requestedFillAmount
        );

        ensureAllowance(
            makerToken,
            receiver,
            receivedMakerTokenAmount
        );

        return receivedMakerTokenAmount;
    }

    function getExchangeCost(
        address /* makerToken */,
        address /* takerToken */,
        uint256 desiredMakerToken,
        bytes orderData
    )
        external
        view
        returns (uint256)
    {
        Order memory order = parseOrder(orderData);

        return MathHelpers.getPartialAmountRoundedUp(
            order.takerTokenAmount,
            order.makerTokenAmount,
            desiredMakerToken
        );
    }

    function getMaxMakerAmount(
        address makerToken,
        address takerToken,
        bytes orderData
    )
        external
        view
        returns (uint256)
    {
        address zeroExExchange = ZERO_EX_EXCHANGE;
        Order memory order = parseOrder(orderData);

        // order cannot be taken if expired
        if (block.timestamp >= order.expirationUnixTimestampSec) {
            return 0;
        }

        bytes32 orderHash = getOrderHash(
            zeroExExchange,
            makerToken,
            takerToken,
            order
        );

        uint256 unavailableTakerAmount =
            ZeroExExchangeInterfaceV1(zeroExExchange).getUnavailableTakerTokenAmount(orderHash);
        uint256 takerAmount = order.takerTokenAmount.sub(unavailableTakerAmount);
        uint256 makerAmount = MathHelpers.getPartialAmount(
            takerAmount,
            order.takerTokenAmount,
            order.makerTokenAmount
        );

        return makerAmount;
    }

    // ============ Private Functions ============

    function transferTakerFee(
        Order memory order,
        address tradeOriginator,
        uint256 requestedFillAmount
    )
        private
    {
        if (order.feeRecipient == address(0)) {
            return;
        }

        uint256 takerFee = MathHelpers.getPartialAmount(
            requestedFillAmount,
            order.takerTokenAmount,
            order.takerFee
        );

        if (takerFee == 0) {
            return;
        }

        require(
            TRUSTED_MSG_SENDER[msg.sender],
            "ZeroExV1ExchangeWrapper#transferTakerFee: Only trusted senders can dictate the fee payer"
        );

        ZRX.transferFrom(
            tradeOriginator,
            address(this),
            takerFee
        );
    }

    function doTrade(
        Order memory order,
        address makerToken,
        address takerToken,
        uint256 requestedFillAmount
    )
        private
        returns (uint256)
    {
        uint256 filledTakerTokenAmount = ZeroExExchangeInterfaceV1(ZERO_EX_EXCHANGE).fillOrder(
            [
                order.maker,
                order.taker,
                makerToken,
                takerToken,
                order.feeRecipient
            ],
            [
                order.makerTokenAmount,
                order.takerTokenAmount,
                order.makerFee,
                order.takerFee,
                order.expirationUnixTimestampSec,
                order.salt
            ],
            requestedFillAmount,
            true,
            order.v,
            order.r,
            order.s
        );

        require(
            filledTakerTokenAmount == requestedFillAmount,
            "ZeroExV1ExchangeWrapper#doTrade: Could not fill requested amount"
        );

        uint256 receivedMakerTokenAmount = MathHelpers.getPartialAmount(
            filledTakerTokenAmount,
            order.takerTokenAmount,
            order.makerTokenAmount
        );

        return receivedMakerTokenAmount;
    }

    function ensureAllowance(
        address token,
        address spender,
        uint256 requiredAmount
    )
        private
    {
        if (token.allowance(address(this), spender) >= requiredAmount) {
            return;
        }

        token.approve(
            spender,
            MathHelpers.maxUint256()
        );
    }

    function getOrderHash(
        address exchangeAddress,
        address makerToken,
        address takerToken,
        Order memory order
    )
        private
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                exchangeAddress,
                order.maker,
                order.taker,
                makerToken,
                takerToken,
                order.feeRecipient,
                order.makerTokenAmount,
                order.takerTokenAmount,
                order.makerFee,
                order.takerFee,
                order.expirationUnixTimestampSec,
                order.salt
            )
        );
    }

    /**
     * Accepts a byte array with each variable padded to 32 bytes
     */
    function parseOrder(
        bytes orderData
    )
        private
        pure
        returns (Order memory)
    {
        Order memory order;

        /**
         * Total: 384 bytes
         * mstore stores 32 bytes at a time, so go in increments of 32 bytes
         *
         * NOTE: The first 32 bytes in an array stores the length, so we start reading from 32
         */
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            mstore(order,           mload(add(orderData, 32)))  // maker
            mstore(add(order, 32),  mload(add(orderData, 64)))  // taker
            mstore(add(order, 64),  mload(add(orderData, 96)))  // feeRecipient
            mstore(add(order, 96),  mload(add(orderData, 128))) // makerTokenAmount
            mstore(add(order, 128), mload(add(orderData, 160))) // takerTokenAmount
            mstore(add(order, 160), mload(add(orderData, 192))) // makerFee
            mstore(add(order, 192), mload(add(orderData, 224))) // takerFee
            mstore(add(order, 224), mload(add(orderData, 256))) // expirationUnixTimestampSec
            mstore(add(order, 256), mload(add(orderData, 288))) // salt
            mstore(add(order, 288), mload(add(orderData, 320))) // v
            mstore(add(order, 320), mload(add(orderData, 352))) // r
            mstore(add(order, 352), mload(add(orderData, 384))) // s
        }

        return order;
    }
}