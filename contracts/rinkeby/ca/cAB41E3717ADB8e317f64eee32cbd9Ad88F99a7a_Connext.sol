// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./interface.sol";
import "../../common/interfaces.sol";
import {Helpers} from "./helpers.sol";

contract Connext is Helpers {
    string public name = "Connext-v1";

    address constant NATIVE_ASSETID = address(0);

    ITransactionManager private immutable transactionManager;

    constructor() public {
        transactionManager = ITransactionManager(connextTransactionManager);
    }

    function crosschainTransfer(
        ITransactionManager.InvariantTransactionData calldata invariantData,
        uint256 amount,
        uint256 expiry,
        bytes calldata encryptedCallData,
        bytes calldata encodedBid,
        bytes calldata bidSignature,
        uint256 getId
    ) external payable {
        uint256 sendAmount = getUint(getId, amount);
        uint256 nativeAssetAmount = 0;
        if (invariantData.sendingAssetId != NATIVE_ASSETID) {
            TokenInterface(invariantData.sendingAssetId).approve(
                address(transactionManager),
                sendAmount
            );
        } else {
            nativeAssetAmount = sendAmount;
        }

        ITransactionManager.PrepareArgs memory args = ITransactionManager
            .PrepareArgs(
                invariantData,
                sendAmount,
                expiry,
                encryptedCallData,
                encodedBid,
                bidSignature,
                bytes("0x0") //todo cross verify the constant value
            );

        transactionManager.prepare{value: nativeAssetAmount}(args);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

interface ITransactionManager {
    // Structs

    // Holds all data that is constant between sending and
    // receiving chains. The hash of this is what gets signed
    // to ensure the signature can be used on both chains.
    struct InvariantTransactionData {
        address receivingChainTxManagerAddress;
        address user;
        address router;
        address initiator; // msg.sender of sending side
        address sendingAssetId;
        address receivingAssetId;
        address sendingChainFallback; // funds sent here on cancel
        address receivingAddress;
        address callTo;
        uint256 sendingChainId;
        uint256 receivingChainId;
        bytes32 callDataHash; // hashed to prevent free option
        bytes32 transactionId;
    }

    // Holds all data that varies between sending and receiving
    // chains. The hash of this is stored onchain to ensure the
    // information passed in is valid.
    struct VariantTransactionData {
        uint256 amount;
        uint256 expiry;
        uint256 preparedBlockNumber;
    }

    // All Transaction data, constant and variable
    struct TransactionData {
        address receivingChainTxManagerAddress;
        address user;
        address router;
        address initiator; // msg.sender of sending side
        address sendingAssetId;
        address receivingAssetId;
        address sendingChainFallback;
        address receivingAddress;
        address callTo;
        bytes32 callDataHash;
        bytes32 transactionId;
        uint256 sendingChainId;
        uint256 receivingChainId;
        uint256 amount;
        uint256 expiry;
        uint256 preparedBlockNumber; // Needed for removal of active blocks on fulfill/cancel
    }

    // The structure of the signed data for fulfill
    struct SignedFulfillData {
        bytes32 transactionId;
        uint256 relayerFee;
        string functionIdentifier; // "fulfill" or "cancel"
        uint256 receivingChainId; // For domain separation
        address receivingChainTxManagerAddress; // For domain separation
    }

    // The structure of the signed data for cancellation
    struct SignedCancelData {
        bytes32 transactionId;
        string functionIdentifier;
        uint256 receivingChainId;
        address receivingChainTxManagerAddress; // For domain separation
    }

    /**
     * Arguments for calling prepare()
     * @param invariantData The data for a crosschain transaction that will
     *                      not change between sending and receiving chains.
     *                      The hash of this data is used as the key to store
     *                      the inforamtion that does change between chains
     *                      (amount,expiry,preparedBlock) for verification
     * @param amount The amount of the transaction on this chain
     * @param expiry The block.timestamp when the transaction will no longer be
     *               fulfillable and is freely cancellable on this chain
     * @param encryptedCallData The calldata to be executed when the tx is
     *                          fulfilled. Used in the function to allow the user
     *                          to reconstruct the tx from events. Hash is stored
     *                          onchain to prevent shenanigans.
     * @param encodedBid The encoded bid that was accepted by the user for this
     *                   crosschain transfer. It is supplied as a param to the
     *                   function but is only used in event emission
     * @param bidSignature The signature of the bidder on the encoded bid for
     *                     this transaction. Only used within the function for
     *                     event emission. The validity of the bid and
     *                     bidSignature are enforced offchain
     * @param encodedMeta The meta for the function
     */
    struct PrepareArgs {
        InvariantTransactionData invariantData;
        uint256 amount;
        uint256 expiry;
        bytes encryptedCallData;
        bytes encodedBid;
        bytes bidSignature;
        bytes encodedMeta;
    }

    /**
     * @param txData All of the data (invariant and variant) for a crosschain
     *               transaction. The variant data provided is checked against
     *               what was stored when the `prepare` function was called.
     * @param relayerFee The fee that should go to the relayer when they are
     *                   calling the function on the receiving chain for the user
     * @param signature The users signature on the transaction id + fee that
     *                  can be used by the router to unlock the transaction on
     *                  the sending chain
     * @param callData The calldata to be sent to and executed by the
     *                 `FulfillHelper`
     * @param encodedMeta The meta for the function
     */
    struct FulfillArgs {
        TransactionData txData;
        uint256 relayerFee;
        bytes signature;
        bytes callData;
        bytes encodedMeta;
    }

    /**
     * Arguments for calling cancel()
     * @param txData All of the data (invariant and variant) for a crosschain
     *               transaction. The variant data provided is checked against
     *               what was stored when the `prepare` function was called.
     * @param signature The user's signature that allows a transaction to be
     *                  cancelled by a relayer
     * @param encodedMeta The meta for the function
     */
    struct CancelArgs {
        TransactionData txData;
        bytes signature;
        bytes encodedMeta;
    }

    // Adding/removing asset events
    event RouterAdded(address indexed addedRouter, address indexed caller);

    event RouterRemoved(address indexed removedRouter, address indexed caller);

    // Adding/removing router events
    event AssetAdded(address indexed addedAssetId, address indexed caller);

    event AssetRemoved(address indexed removedAssetId, address indexed caller);

    // Liquidity events
    event LiquidityAdded(
        address indexed router,
        address indexed assetId,
        uint256 amount,
        address caller
    );

    event LiquidityRemoved(
        address indexed router,
        address indexed assetId,
        uint256 amount,
        address recipient
    );

    // Transaction events
    event TransactionPrepared(
        address indexed user,
        address indexed router,
        bytes32 indexed transactionId,
        TransactionData txData,
        address caller,
        PrepareArgs args
    );

    event TransactionFulfilled(
        address indexed user,
        address indexed router,
        bytes32 indexed transactionId,
        FulfillArgs args,
        bool success,
        bool isContract,
        bytes returnData,
        address caller
    );

    event TransactionCancelled(
        address indexed user,
        address indexed router,
        bytes32 indexed transactionId,
        CancelArgs args,
        address caller
    );

    // Getters
    function getChainId() external view returns (uint256);

    function getStoredChainId() external view returns (uint256);

    // Owner only methods
    function addRouter(address router) external;

    function removeRouter(address router) external;

    function addAssetId(address assetId) external;

    function removeAssetId(address assetId) external;

    // Router only methods
    function addLiquidityFor(
        uint256 amount,
        address assetId,
        address router
    ) external payable;

    function addLiquidity(uint256 amount, address assetId) external payable;

    function removeLiquidity(
        uint256 amount,
        address assetId,
        address payable recipient
    ) external;

    // Methods for crosschain transfers
    // called in the following order (in happy case)
    // 1. prepare by user on sending chain
    // 2. prepare by router on receiving chain
    // 3. fulfill by user on receiving chain
    // 4. fulfill by router on sending chain
    function prepare(PrepareArgs calldata args)
        external
        payable
        returns (TransactionData memory);

    function fulfill(FulfillArgs calldata args)
        external
        returns (TransactionData memory);

    function cancel(CancelArgs calldata args)
        external
        returns (TransactionData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint256);
}

interface MemoryInterface {
    function getUint(uint256 id) external returns (uint256 num);

    function setUint(uint256 id, uint256 val) external;
}

interface AccountInterface {
    function enable(address) external;

    function disable(address) external;

    function isAuth(address) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";

abstract contract Helpers is DSMath, Basic {
    address connextTransactionManager =
        0x9492224B81aCf442da114ea1313C0284A584f858;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(x, y);
    }

    function sub(uint256 x, uint256 y)
        internal
        pure
        virtual
        returns (uint256 z)
    {
        z = SafeMath.sub(x, y);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.mul(x, y);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.div(x, y);
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
    }

    function toInt(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint256 wad) internal pure returns (uint256 rad) {
        rad = mul(wad, 10**27);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import {TokenInterface} from "./interfaces.sol";
import {Stores} from "./stores.sol";
import {DSMath} from "./math.sol";

abstract contract Basic is DSMath, Stores {
    function convert18ToDec(uint256 _dec, uint256 _amt)
        internal
        pure
        returns (uint256 amt)
    {
        amt = (_amt / 10**(18 - _dec));
    }

    function convertTo18(uint256 _dec, uint256 _amt)
        internal
        pure
        returns (uint256 amt)
    {
        amt = mul(_amt, 10**(18 - _dec));
    }

    function getTokenBal(TokenInterface token)
        internal
        view
        returns (uint256 _amt)
    {
        _amt = address(token) == ethAddr
            ? address(this).balance
            : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr)
        internal
        view
        returns (uint256 buyDec, uint256 sellDec)
    {
        buyDec = address(buyAddr) == ethAddr ? 18 : buyAddr.decimals();
        sellDec = address(sellAddr) == ethAddr ? 18 : sellAddr.decimals();
    }

    function encodeEvent(string memory eventName, bytes memory eventParam)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(eventName, eventParam);
    }

    function approve(
        TokenInterface token,
        address spender,
        uint256 amount
    ) internal {
        try token.approve(spender, amount) {} catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

    function changeEthAddress(address buy, address sell)
        internal
        pure
        returns (TokenInterface _buy, TokenInterface _sell)
    {
        _buy = buy == ethAddr ? TokenInterface(wethAddr) : TokenInterface(buy);
        _sell = sell == ethAddr
            ? TokenInterface(wethAddr)
            : TokenInterface(sell);
    }

    function convertEthToWeth(
        bool isEth,
        TokenInterface token,
        uint256 amount
    ) internal {
        if (isEth) token.deposit{value: amount}();
    }

    function convertWethToEth(
        bool isEth,
        TokenInterface token,
        uint256 amount
    ) internal {
        if (isEth) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import {MemoryInterface} from "./interfaces.sol";

abstract contract Stores {
    /**
     * @dev Return ethereum address
     */
    address internal constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev Return Wrapped ETH address
     */
    address internal constant wethAddr =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /**
     * @dev Return memory variable address
     */
    MemoryInterface internal constant stakeAllMemory =
        MemoryInterface(0x0A25F019be4C4aAa0B04C0d43dff519dc720D275);

    uint256 public constant PORTIONS_SUM = 1000000;

    /**
     * @dev Get Uint value from StakeAllMemory Contract.
     */
    function getUint(uint256 getId, uint256 val)
        internal
        returns (uint256 returnVal)
    {
        returnVal = getId == 0 ? val : stakeAllMemory.getUint(getId);
    }

    /**
     * @dev Set Uint value in StakeAllMemory Contract.
     */
    function setUint(uint256 setId, uint256 val) internal virtual {
        if (setId != 0) stakeAllMemory.setUint(setId, val);
    }
}