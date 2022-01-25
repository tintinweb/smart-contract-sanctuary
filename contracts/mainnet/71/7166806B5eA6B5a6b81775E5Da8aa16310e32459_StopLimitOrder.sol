//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "./interfaces/ILimitOrderReceiver.sol";
import "./interfaces/IOracle.sol";

// TODO: Run prettier?
contract StopLimitOrder is BoringOwnable, BoringBatchable {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;
    using RebaseLibrary for Rebase;

    struct OrderArgs {
        address maker; 
        uint256 amountIn; 
        uint256 amountOut; 
        address recipient; 
        uint256 startTime;
        uint256 endTime;
        uint256 stopPrice;
        IOracle oracleAddress;
        bytes oracleData;
        uint256 amountToFill;
        uint8 v; 
        bytes32 r;
        bytes32 s;
    }

    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 private constant ORDER_TYPEHASH = keccak256("LimitOrder(address maker,address tokenIn,address tokenOut,uint256 amountIn,uint256 amountOut,address recipient,uint256 startTime,uint256 endTime,uint256 stopPrice,address oracleAddress,bytes32 oracleData)");
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 public immutable deploymentChainId;
    IBentoBoxV1 private immutable bentoBox;

    uint256 public constant FEE_DIVISOR=1e6;
    
    // what should the externalOrderFee be? Can it be a constant
    uint256 public externalOrderFee;
    address public feeTo;

    mapping(ILimitOrderReceiver => bool) private isWhiteListed;
    mapping(address => mapping(bytes32 => bool)) public cancelledOrder;
    mapping(bytes32 => uint256) public orderStatus;

    mapping(IERC20 => uint256) public feesCollected;

    // what should be logged for UI purposes
    event LogFillOrder(address indexed maker, bytes32 indexed digest, ILimitOrderReceiver receiver, uint256 fillAmount);
    event LogOrderCancelled(address indexed user, bytes32 indexed digest);
    event LogSetFees(address indexed feeTo, uint256 externalOrderFee);
    event LogWhiteListReceiver(ILimitOrderReceiver indexed receiver);
    event LogFeesCollected(IERC20 indexed token, address indexed feeTo, uint256 amount);
    
    constructor(uint256 _externalOrderFee, IBentoBoxV1 _bentoBox) public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        deploymentChainId = chainId;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(chainId);

        externalOrderFee = _externalOrderFee;

        feeTo = msg.sender;

        bentoBox = _bentoBox;

        _bentoBox.registerProtocol();
    }

    /// @dev Calculate the DOMAIN_SEPARATOR
    function _calculateDomainSeparator(uint256 chainId) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_SIGNATURE_HASH,
                keccak256("LimitOrder"),
                chainId,
                address(this)
            )
        );
    }

    /// @dev Return the DOMAIN_SEPARATOR
    function DOMAIN_SEPARATOR() internal view returns (bytes32) {
        uint256 chainId;
        assembly {chainId := chainid()}
        return chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    function _getDigest(OrderArgs memory order, IERC20 tokenIn, IERC20 tokenOut) internal view returns(bytes32 digest) {
        bytes32 encoded = keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                order.maker,
                tokenIn,
                tokenOut,
                order.amountIn,
                order.amountOut,
                order.recipient,
                order.startTime,
                order.endTime,
                order.stopPrice,
                order.oracleAddress,
                keccak256(order.oracleData)
            )
        );
        
        digest =
            keccak256(
                abi.encodePacked(
                    EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                    DOMAIN_SEPARATOR(),
                    encoded
                )
            );
    }


    function _preFillOrder(OrderArgs memory order, IERC20 tokenIn, IERC20 tokenOut, ILimitOrderReceiver receiver) internal returns (bytes32 digest, uint256 amountToBeReturned, uint256 amountToBeFilled) {
        
        {
            if(order.oracleAddress != IOracle(0)){
                (bool success, uint256 rate) = order.oracleAddress.get(order.oracleData);
                require(success && rate > order.stopPrice, "Stop price not reached");
            }
        }

        digest = _getDigest(order, tokenIn, tokenOut);
        
        require(!cancelledOrder[order.maker][digest], "LimitOrder: Cancelled");

        require(order.startTime <= block.timestamp && block.timestamp <= order.endTime, "order-expired");

        require(ecrecover(digest, order.v, order.r, order.s) == order.maker, "Limit: not maker");


        uint256 newFilledAmount;
        {
        uint256 currentFilledAmount = orderStatus[digest];
        newFilledAmount = currentFilledAmount.add(order.amountToFill);
        amountToBeFilled = newFilledAmount <= order.amountIn ? 
                                order.amountToFill :
                                order.amountIn.sub(currentFilledAmount);
        }
        // Amount is either the right amount or short changed
        amountToBeReturned = order.amountOut.mul(amountToBeFilled) / order.amountIn;
        // Effects
        orderStatus[digest] = newFilledAmount;

        bentoBox.transfer(tokenIn, order.maker, address(receiver), bentoBox.toShare(tokenIn, amountToBeFilled, true));

        emit LogFillOrder(order.maker, digest, receiver, amountToBeFilled);
    }

    function _fillOrderInternal(
        IERC20 tokenIn, 
        IERC20 tokenOut, 
        ILimitOrderReceiver receiver, 
        bytes calldata data, 
        uint256 amountToFill, 
        uint256 amountToBeReturned, 
        uint256 fee)
    internal returns(uint256 _feesCollected){
        receiver.onLimitOrder(tokenIn, tokenOut, amountToFill, amountToBeReturned.add(fee), data);

        _feesCollected = feesCollected[tokenOut];
        require(bentoBox.balanceOf(tokenOut, address(this)) >= bentoBox.toShare(tokenOut, amountToBeReturned.add(fee), true).add(_feesCollected), "Limit: not enough");
    }

    function fillOrder(
            OrderArgs memory order,
            IERC20 tokenIn,
            IERC20 tokenOut, 
            ILimitOrderReceiver receiver, 
            bytes calldata data) 
    public {
        require(isWhiteListed[receiver], "LimitOrder: not whitelisted");
        
        (, uint256 amountToBeReturned, uint256 amountToBeFilled) = _preFillOrder(order, tokenIn, tokenOut, receiver);
        
        _fillOrderInternal(tokenIn, tokenOut, receiver, data, amountToBeFilled, amountToBeReturned, 0);

        bentoBox.transfer(tokenOut, address(this), order.recipient, bentoBox.toShare(tokenOut, amountToBeReturned, false));

    }

    function fillOrderOpen(
            OrderArgs memory order,
            IERC20 tokenIn,
            IERC20 tokenOut, 
            ILimitOrderReceiver receiver, 
            bytes calldata data) 
    public {
        (, uint256 amountToBeReturned, uint256 amountToBeFilled) = _preFillOrder(order, tokenIn, tokenOut, receiver);
        uint256 fee = amountToBeReturned.mul(externalOrderFee) / FEE_DIVISOR;

        uint256 _feesCollected = _fillOrderInternal(tokenIn, tokenOut, receiver, data, amountToBeFilled, amountToBeReturned, fee);

        feesCollected[tokenOut] = _feesCollected.add(bentoBox.toShare(tokenOut, fee, true));

        bentoBox.transfer(tokenOut, address(this), order.recipient, bentoBox.toShare(tokenOut, amountToBeReturned, false));
    }

    function batchFillOrder(
            OrderArgs[] memory order,
            IERC20 tokenIn,
            IERC20 tokenOut,
            ILimitOrderReceiver receiver, 
            bytes calldata data) 
    external {
        require(isWhiteListed[receiver], "LimitOrder: not whitelisted");

        uint256[] memory amountToBeReturned = new uint256[](order.length);
        uint256 totalAmountToBeFilled;
        uint256 totalAmountToBeReturned;

        for(uint256 i = 0; i < order.length; i++) {
            uint256 amountToBeFilled;
            (, amountToBeReturned[i], amountToBeFilled) = _preFillOrder(order[i], tokenIn, tokenOut, receiver);

            totalAmountToBeFilled = totalAmountToBeFilled.add(amountToBeFilled);
            totalAmountToBeReturned = totalAmountToBeReturned.add(amountToBeReturned[i]);
        }
        _fillOrderInternal(tokenIn, tokenOut, receiver, data, totalAmountToBeFilled, totalAmountToBeReturned, 0);

        Rebase memory bentoBoxTotals = bentoBox.totals(tokenOut);

        for(uint256 i = 0; i < order.length; i++) {
            bentoBox.transfer(tokenOut, address(this), order[i].recipient, bentoBoxTotals.toBase(amountToBeReturned[i], false));
        }
    }

    function batchFillOrderOpen(
            OrderArgs[] memory order,
            IERC20 tokenIn,
            IERC20 tokenOut,
            ILimitOrderReceiver receiver, 
            bytes calldata data) 
    external {
        uint256[] memory amountToBeReturned = new uint256[](order.length);
        uint256 totalAmountToBeFilled;
        uint256 totalAmountToBeReturned;

        for(uint256 i = 0; i < order.length; i++) {
            uint256 amountToBeFilled;
            (, amountToBeReturned[i], amountToBeFilled) = _preFillOrder(order[i], tokenIn, tokenOut, receiver);

            totalAmountToBeFilled = totalAmountToBeFilled.add(amountToBeFilled);
            totalAmountToBeReturned = totalAmountToBeReturned.add(amountToBeReturned[i]);
        }
        
        uint256 totalFee = totalAmountToBeReturned.mul(externalOrderFee) / FEE_DIVISOR;

        {
            
        uint256 _feesCollected = _fillOrderInternal(tokenIn, tokenOut, receiver, data, totalAmountToBeFilled, totalAmountToBeReturned, totalFee);
        feesCollected[tokenOut] = _feesCollected.add(bentoBox.toShare(tokenOut, totalFee, true));

        }

        Rebase memory bentoBoxTotals = bentoBox.totals(tokenOut);

        for(uint256 i = 0; i < order.length; i++) {
            bentoBox.transfer(tokenOut, address(this), order[i].recipient, bentoBoxTotals.toBase(amountToBeReturned[i], false));
        }


    }
    
    function cancelOrder(bytes32 hash) public {
        cancelledOrder[msg.sender][hash] = true;
        emit LogOrderCancelled(msg.sender, hash);
    }

    function swipeFees(IERC20 token) public {
        feesCollected[token] = 1;
        uint256 balance = bentoBox.balanceOf(token, address(this)).sub(1);
        bentoBox.transfer(token, address(this), feeTo, balance);
        emit LogFeesCollected(token, feeTo, balance);
    }

    function swipe (IERC20 token) public {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(feeTo, balance);
    }

    function setFees(address _feeTo, uint256 _externalOrderFee) external onlyOwner {
        feeTo = _feeTo;
        externalOrderFee = _externalOrderFee;
        emit LogSetFees(_feeTo, _externalOrderFee);
    }

    function whiteListReceiver(ILimitOrderReceiver receiver) external onlyOwner {
        isWhiteListed[receiver] = true;
        emit LogWhiteListReceiver(receiver);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// Audit on 5-Jan-2021 by Keno and BoringCrypto

import "./libraries/BoringERC20.sol";

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    /// @return successes An array indicating the success of a call, mapped one-to-one to `calls`.
    /// @return results An array with the returned data of each function call, mapped one-to-one to `calls`.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results) {
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = result;
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while(i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./BoringMath.sol";

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    using BoringMath for uint256;
    using BoringMath128 for uint128;

    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = elastic.mul(total.base) / total.elastic;
            if (roundUp && base.mul(total.elastic) / total.base < elastic) {
                base = base.add(1);
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = base.mul(total.elastic) / total.base;
            if (roundUp && elastic.mul(total.base) / total.elastic < base) {
                elastic = elastic.add(1);
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic = total.elastic.add(elastic.to128());
        total.base = total.base.add(base.to128());
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic = total.elastic.sub(elastic.to128());
        total.base = total.base.sub(base.to128());
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic.add(elastic.to128());
        total.base = total.base.add(base.to128());
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic.sub(elastic.to128());
        total.base = total.base.sub(base.to128());
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic.add(elastic.to128());
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic.sub(elastic.to128());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol';
import '@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol';
import './IBatchFlashBorrower.sol';
import './IFlashBorrower.sol';
import './IStrategy.sol';

interface IBentoBoxV1 {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);
    event LogDeposit(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event LogFlashLoan(address indexed borrower, address indexed token, uint256 amount, uint256 feeAmount, address indexed receiver);
    event LogRegisterProtocol(address indexed protocol);
    event LogSetMasterContractApproval(address indexed masterContract, address indexed user, bool approved);
    event LogStrategyDivest(address indexed token, uint256 amount);
    event LogStrategyInvest(address indexed token, uint256 amount);
    event LogStrategyLoss(address indexed token, uint256 amount);
    event LogStrategyProfit(address indexed token, uint256 amount);
    event LogStrategyQueued(address indexed token, address indexed strategy);
    event LogStrategySet(address indexed token, address indexed strategy);
    event LogStrategyTargetPercentage(address indexed token, uint256 targetPercentage);
    event LogTransfer(address indexed token, address indexed from, address indexed to, uint256 share);
    event LogWhiteListMasterContract(address indexed masterContract, bool approved);
    event LogWithdraw(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function balanceOf(IERC20, address) external view returns (uint256);
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results);
    function batchFlashLoan(IBatchFlashBorrower borrower, address[] calldata receivers, IERC20[] calldata tokens, uint256[] calldata amounts, bytes calldata data) external;
    function claimOwnership() external;
    function deploy(address masterContract, bytes calldata data, bool useCreate2) external payable;
    function deposit(IERC20 token_, address from, address to, uint256 amount, uint256 share) external payable returns (uint256 amountOut, uint256 shareOut);
    function flashLoan(IFlashBorrower borrower, address receiver, IERC20 token, uint256 amount, bytes calldata data) external;
    function harvest(IERC20 token, bool balance, uint256 maxChangeAmount) external;
    function masterContractApproved(address, address) external view returns (bool);
    function masterContractOf(address) external view returns (address);
    function nonces(address) external view returns (uint256);
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function pendingStrategy(IERC20) external view returns (IStrategy);
    function permitToken(IERC20 token, address from, address to, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function registerProtocol() external;
    function setMasterContractApproval(address user, address masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) external;
    function setStrategy(IERC20 token, IStrategy newStrategy) external;
    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) external;
    function strategy(IERC20) external view returns (IStrategy);
    function strategyData(IERC20) external view returns (uint64 strategyStartDate, uint64 targetPercentage, uint128 balance);
    function toAmount(IERC20 token, uint256 share, bool roundUp) external view returns (uint256 amount);
    function toShare(IERC20 token, uint256 amount, bool roundUp) external view returns (uint256 share);
    function totals(IERC20) external view returns (Rebase memory totals_);
    function transfer(IERC20 token, address from, address to, uint256 share) external;
    function transferMultiple(IERC20 token, address from, address[] calldata tos, uint256[] calldata shares) external;
    function transferOwnership(address newOwner, bool direct, bool renounce) external;
    function whitelistMasterContract(address masterContract, bool approved) external;
    function whitelistedMasterContracts(address) external view returns (bool);
    function withdraw(IERC20 token_, address from, address to, uint256 amount, uint256 share) external returns (uint256 amountOut, uint256 shareOut);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

interface ILimitOrderReceiver {
    using BoringERC20 for IERC20;
    function onLimitOrder (IERC20 tokenIn, IERC20 tokenOut, uint256 amountIn, uint256 amountMinOut, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import '@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol';

interface IBatchFlashBorrower {
    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import '@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol';

interface IFlashBorrower {
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IStrategy {
    // Send the assets to the Strategy and call skim to invest them
    function skim(uint256 amount) external;

    // Harvest any profits made converted to the asset and pass them to the caller
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    // Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    // The actualAmount should be very close to the amount. The difference should NOT be used to report a loss. That's what harvest is for.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    // Withdraw all assets in the safest way possible. This shouldn't fail.
    function exit(uint256 balance) external returns (int256 amountAdded);
}