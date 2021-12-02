// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./interfaces/IFuro.sol";
import "./utils/BoringBatchable.sol";
import "./utils/BoringOwnable.sol";

contract Furo is IFuro, BoringOwnable, BoringBatchable {
    IBentoBoxMinimal public immutable bentoBox;
    uint256 public streamIds;

    mapping(uint256 => Stream) public streams;
    mapping(ISwapReceiver => bool) public whitelistedReceivers;

    modifier onlySenderOrRecipient(uint256 streamId) {
        require(
            msg.sender == streams[streamId].sender ||
                msg.sender == streams[streamId].recipient,
            "Furo: !sender or !recipient"
        );
        _;
    }

    modifier validStream(uint256 streamId) {
        require(streams[streamId].exists, "Furo: Invalid Stream");
        _;
    }

    constructor(IBentoBoxMinimal _bentoBox) {
        bentoBox = _bentoBox;
        streamIds = 1;
        _bentoBox.registerProtocol();
    }

    function setBentoBoxApproval(
        address user,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        bentoBox.setMasterContractApproval(
            user,
            address(this),
            approved,
            v,
            r,
            s
        );
    }

    function createStream(
        address recipient,
        address token,
        uint256 startTime,
        uint256 endTime,
        uint256 amount, /// @dev in token amount and not in shares
        bool fromBentoBox
    )
        external
        override
        returns (
            uint256 streamId,
            uint256 depositedShares,
            uint256 rate
        )
    {
        require(recipient != address(0), "Furo: to address 0");
        require(recipient != address(this), "Furo: to contract");
        require(recipient != msg.sender, "Furo: to caller");
        require(amount > 0, "Furo: 0 deposit");
        require(startTime >= block.timestamp, "Furo: invalid startTime");
        require(endTime > startTime, "Furo: invalid endTime");

        uint256 timeDifference = endTime - startTime;

        if (fromBentoBox) {
            depositedShares = bentoBox.toShare(token, amount, false);
            bentoBox.transfer(
                token,
                msg.sender,
                address(this),
                depositedShares
            );
        } else {
            (, depositedShares) = bentoBox.deposit(
                token,
                msg.sender,
                address(this),
                amount,
                0
            );
        }

        require(depositedShares >= timeDifference, "Furo: deposit too small");
        require(
            depositedShares % timeDifference == 0,
            "Furo: not multiple of time"
        );

        rate = depositedShares / timeDifference;

        streamId = streamIds++;

        streams[streamId] = Stream({
            exists: true,
            sender: msg.sender,
            recipient: recipient,
            token: token,
            depositedShares: uint128(depositedShares),
            rate: rate,
            withdrawnShares: 0,
            startTime: startTime,
            endTime: endTime
        });

        emit LogCreateStream(
            streamId,
            msg.sender,
            recipient,
            token,
            depositedShares,
            startTime,
            endTime,
            fromBentoBox
        );
    }

    function withdrawFromStream(
        uint256 streamId,
        uint256 sharesToWithdraw,
        address withdrawTo,
        bool toBentoBox
    )
        external
        override
        validStream(streamId)
        onlySenderOrRecipient(streamId)
        returns (uint256 recipientBalance, address to)
    {
        Stream storage stream = streams[streamId];
        (, recipientBalance) = _balanceOf(stream);
        require(
            recipientBalance >= sharesToWithdraw,
            "Furo: withdraw too much"
        );
        stream.withdrawnShares += uint128(sharesToWithdraw);
        if (msg.sender == stream.recipient && withdrawTo != address(0)) {
            to = withdrawTo;
        } else {
            to = stream.recipient;
        }
        if (toBentoBox) {
            bentoBox.transfer(
                stream.token,
                address(this),
                to,
                sharesToWithdraw
            );
        } else {
            bentoBox.withdraw(
                stream.token,
                address(this),
                to,
                0,
                sharesToWithdraw
            );
        }

        emit LogWithdrawFromStream(
            streamId,
            sharesToWithdraw,
            withdrawTo,
            stream.token,
            toBentoBox
        );
    }

    function withdrawSwap(
        uint256 streamId,
        uint256 sharesToWithdraw,
        address toToken,
        uint256 amountOutMin,
        ISwapReceiver swapReceiver,
        bytes calldata data,
        bool toBentoBox
    )
        external
        override
        validStream(streamId)
        returns (uint256 recipientBalance)
    {
        require(whitelistedReceivers[swapReceiver], "Furo: !whitelisted");
        Stream storage stream = streams[streamId];
        require(msg.sender == stream.recipient, "Furo: !recipient");
        (, recipientBalance) = _balanceOf(stream);
        require(
            recipientBalance >= sharesToWithdraw,
            "Furo: withdraw too much"
        );
        stream.withdrawnShares += uint128(sharesToWithdraw);
        uint256 toTokenBalanceBefore = bentoBox.balanceOf(
            toToken,
            address(this)
        );
        bentoBox.transfer(
            stream.token,
            address(this),
            address(swapReceiver),
            sharesToWithdraw
        );
        swapReceiver.onSwapReceive(
            stream.token,
            toToken,
            sharesToWithdraw,
            amountOutMin,
            data
        );
        uint256 toTokenBalanceAfter = bentoBox.balanceOf(
            toToken,
            address(this)
        );
        require(
            toTokenBalanceAfter >= toTokenBalanceBefore + amountOutMin,
            "Furo: received too less"
        );
        if (toBentoBox) {
            bentoBox.transfer(
                toToken,
                address(this),
                stream.recipient,
                toTokenBalanceAfter - toTokenBalanceBefore
            );
        } else {
            bentoBox.withdraw(
                toToken,
                address(this),
                stream.recipient,
                0,
                toTokenBalanceAfter - toTokenBalanceBefore
            );
        }

        emit LogWithdrawFromStream(
            streamId,
            sharesToWithdraw,
            stream.recipient,
            toToken,
            toBentoBox
        );
    }

    function cancelStream(uint256 streamId, bool toBentoBox)
        external
        override
        validStream(streamId)
        onlySenderOrRecipient(streamId)
        returns (uint256 senderBalance, uint256 recipientBalance)
    {
        Stream memory stream = streams[streamId];
        (senderBalance, recipientBalance) = _balanceOf(stream);

        delete streams[streamId];

        if (toBentoBox) {
            bentoBox.transfer(
                stream.token,
                address(this),
                stream.recipient,
                recipientBalance
            );
            bentoBox.transfer(
                stream.token,
                address(this),
                stream.sender,
                senderBalance
            );
        } else {
            bentoBox.withdraw(
                stream.token,
                address(this),
                stream.recipient,
                0,
                recipientBalance
            );
            bentoBox.withdraw(
                stream.token,
                address(this),
                stream.sender,
                0,
                senderBalance
            );
        }

        emit LogCancelStream(
            streamId,
            senderBalance,
            recipientBalance,
            stream.token,
            toBentoBox
        );
    }

    function getStream(uint256 streamId)
        external
        view
        override
        validStream(streamId)
        returns (Stream memory)
    {
        return streams[streamId];
    }

    function balanceOf(uint256 streamId)
        external
        view
        override
        validStream(streamId)
        returns (uint256 senderBalance, uint256 recipientBalance)
    {
        return _balanceOf(streams[streamId]);
    }

    function _balanceOf(Stream memory stream)
        internal
        view
        returns (uint256 senderBalance, uint256 recipientBalance)
    {
        if (block.timestamp <= stream.startTime) {
            senderBalance = stream.depositedShares;
            recipientBalance = 0;
        } else if (stream.endTime <= block.timestamp) {
            uint256 timeDelta = stream.endTime - stream.startTime;
            recipientBalance =
                (stream.rate * timeDelta) -
                stream.withdrawnShares;
            senderBalance = 0;
        } else {
            uint256 timeDelta = block.timestamp - stream.startTime;
            recipientBalance =
                (stream.rate * timeDelta) -
                uint256(stream.withdrawnShares);
            senderBalance = uint256(stream.depositedShares) - recipientBalance;
        }
    }

    function whitelistReceiver(ISwapReceiver receiver, bool approved)
        external
        onlyOwner
    {
        whitelistedReceivers[receiver] = approved;
        emit LogWhitelistReceiver(receiver, approved);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./ISwapReceiver.sol";
import "./IBentoBoxMinimal.sol";

interface IFuro {
    function setBentoBoxApproval(
        address user,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function createStream(
        address recipient,
        address token,
        uint256 startTime,
        uint256 endTime,
        uint256 amount, /// @dev in token amount and not in shares
        bool fromBento
    )
        external
        returns (
            uint256 streamId,
            uint256 depositedShares,
            uint256 rate
        );

    function withdrawFromStream(
        uint256 streamId,
        uint256 sharesToWithdraw,
        address withdrawTo,
        bool toBentoBox
    ) external returns (uint256 recipientBalance, address to);

    function withdrawSwap(
        uint256 streamId,
        uint256 sharesToWithdraw,
        address toToken,
        uint256 amountOutMin,
        ISwapReceiver swapReceiver,
        bytes calldata data,
        bool toBentoBox
    ) external returns (uint256 recipientBalance);

    function cancelStream(uint256 streamId, bool toBentoBox)
        external
        returns (uint256 senderBalance, uint256 recipientBalance);

    function balanceOf(uint256 streamId)
        external
        view
        returns (uint256 senderBalance, uint256 recipientBalance);

    function getStream(uint256 streamId) external view returns (Stream memory);

    event LogCreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        bool fromBentoBox
    );

    event LogWithdrawFromStream(
        uint256 indexed streamId,
        uint256 indexed sharesToWithdraw,
        address indexed withdrawTo,
        address token,
        bool toBentoBox
    );

    event LogCancelStream(
        uint256 indexed streamId,
        uint256 indexed senderBalance,
        uint256 indexed recipientBalance,
        address token,
        bool toBentoBox
    );

    event LogWhitelistReceiver(ISwapReceiver indexed swapReceiver, bool approved);

    struct Stream {
        bool exists;
        address sender;
        address recipient;
        address token;
        uint128 depositedShares;
        uint128 withdrawnShares;
        uint256 rate;
        uint256 startTime;
        uint256 endTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

import "../interfaces/IERC20.sol";

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
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
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                calls[i]
            );
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
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
pragma solidity >=0.6.12;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
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
            require(
                newOwner != address(0) || renounce,
                "Ownable: zero address"
            );

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
        require(
            msg.sender == _pendingOwner,
            "Ownable: caller != pending owner"
        );

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

interface ISwapReceiver {
    function onSwapReceive(
        address tokenIn,
        address tokenOut,
        uint256 shares,
        uint256 amountOutMin,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Minimal BentoBox vault interface.
/// @dev `token` is aliased as `address` from `IERC20` for simplicity.
interface IBentoBoxMinimal {
    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address, address) external view returns (uint256);

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    /// @dev Helper function to represent shares back into the `token` amount.
    /// @param token The ERC-20 token.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    /// @notice Registers this contract so that users can approve it for BentoBox.
    function registerProtocol() external;

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token_ The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount represented in shares.
    function deposit(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param token_ The ERC-20 token to withdraw.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
pragma solidity >=0.6.12;

import "../interfaces/IERC20.sol";

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x95d89b41)
        );
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x06fdde03)
        );
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x313ce567)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: Transfer failed"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x23b872dd, from, address(this), amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TransferFrom failed"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./interfaces/ISwapReceiver.sol";
import "./interfaces/IBentoBoxMinimal.sol";
import "./libraries/UniswapV2Library.sol";
import "./libraries/SafeERC20.sol";

contract SwapReceiver is ISwapReceiver {
    using SafeERC20 for IERC20;

    address private immutable factory;

    IBentoBoxMinimal private immutable bentoBox;

    bytes32 private immutable pairCodeHash;

    constructor(
        address _factory,
        IBentoBoxMinimal _bentoBox,
        bytes32 _pairCodeHash
    ) {
        factory = _factory;
        bentoBox = _bentoBox;
        pairCodeHash = _pairCodeHash;
    }

    function onSwapReceive(
        address tokenIn,
        address tokenOut,
        uint256 shares,
        uint256 amountOutMin,
        bytes calldata data
    ) external override {
        (uint256 amountIn, ) = bentoBox.withdraw(
            tokenIn,
            address(this),
            address(this),
            0,
            shares
        );
        address[] memory path = abi.decode(data, (address[]));
        uint256 amountOut = _swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(bentoBox)
        );
        bentoBox.deposit(tokenOut, address(bentoBox), msg.sender, amountOut, 0);
    }

    function _swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to
    ) internal returns (uint256 amountOut) {
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            factory,
            amountIn,
            path,
            pairCodeHash
        );
        amountOut = amounts[amounts.length - 1];
        require(amountOut >= amountOutMin, "insufficient-amount-out");
        IERC20(path[0]).safeTransfer(
            UniswapV2Library.pairFor(factory, path[0], path[1], pairCodeHash),
            amountIn
        );
        _swap(amounts, path, to);
    }

    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(
                    factory,
                    output,
                    path[i + 2],
                    pairCodeHash
                )
                : _to;
            IUniswapV2Pair(
                UniswapV2Library.pairFor(factory, input, output, pairCodeHash)
            ).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMathUniswap for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 pairCodeHash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            pairCodeHash // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 pairCodeHash
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB, pairCodeHash)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path,
        bytes32 pairCodeHash
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1],
                pairCodeHash
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path,
        bytes32 pairCodeHash
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i],
                pairCodeHash
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../interfaces/ISwapReceiver.sol";
import "../interfaces/IBentoBoxMinimal.sol";
import "../libraries/UniswapV2Library.sol";
import "../libraries/SafeERC20.sol";

contract SwapReceiverMalicious is ISwapReceiver {
    using SafeERC20 for IERC20;

    address private immutable factory;

    IBentoBoxMinimal private immutable bentoBox;

    bytes32 private immutable pairCodeHash;

    constructor(
        address _factory,
        IBentoBoxMinimal _bentoBox,
        bytes32 _pairCodeHash
    ) {
        factory = _factory;
        bentoBox = _bentoBox;
        pairCodeHash = _pairCodeHash;
    }

    function onSwapReceive(
        address tokenIn,
        address tokenOut,
        uint256 shares,
        uint256 amountOutMin,
        bytes calldata data
    ) external override {
        (uint256 amountIn, ) = bentoBox.withdraw(
            tokenIn,
            address(this),
            address(this),
            0,
            shares
        );
        address[] memory path = abi.decode(data, (address[]));
        uint256 amountOut = _swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(bentoBox)
        );
        bentoBox.deposit(
            tokenOut,
            address(bentoBox),
            msg.sender,
            amountOut - 1,
            0
        );
    }

    function _swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to
    ) internal returns (uint256 amountOut) {
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            factory,
            amountIn,
            path,
            pairCodeHash
        );
        amountOut = amounts[amounts.length - 1];
        require(amountOut >= amountOutMin, "insufficient-amount-out");
        IERC20(path[0]).safeTransfer(
            UniswapV2Library.pairFor(factory, path[0], path[1], pairCodeHash),
            amountIn
        );
        _swap(amounts, path, to);
    }

    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(
                    factory,
                    output,
                    path[i + 2],
                    pairCodeHash
                )
                : _to;
            IUniswapV2Pair(
                UniswapV2Library.pairFor(factory, input, output, pairCodeHash)
            ).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}