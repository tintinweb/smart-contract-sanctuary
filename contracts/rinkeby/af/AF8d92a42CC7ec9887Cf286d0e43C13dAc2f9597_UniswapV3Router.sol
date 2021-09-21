// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
pragma abicoder v2;

import "./Router.sol";

import "./libraries/Path.sol";
import "./libraries/SafeMath.sol";

import "./Interfaces/IUniswapV3Router.sol";
import "./Interfaces/IUniswapStorage.sol";

contract UniswapV3Router is Router, IUniswapStorage {
    using SafeMath for *;
    using BytesLib for bytes;
    using Path for bytes;
    using TransferHelper for address;

    IUniswapV3Router uniswapV3Router;

    address public uniswapV3RouterAddress;

    event GreenSwapped(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 excessSlippage
    );

    constructor(
        address _uniswapV3RouterAddress,
        address _treasury,
        address _redeem
    ) Router(_treasury, _redeem) {
        uniswapV3RouterAddress = _uniswapV3RouterAddress;
        uniswapV3Router = IUniswapV3Router(_uniswapV3RouterAddress);
    }

    function transferFromAndApproveInput(address tokenIn, uint256 amount)
        private
    {
        tokenIn.safeTransferFrom(msg.sender, address(this), amount);
        tokenIn.safeApprove(uniswapV3RouterAddress, amount);
    }

    function exactInputSingle(UniExactInputSingleParams memory params)
        public
        payable
        returns (uint256 excessSlippage)
    {
        validateTokens(params.tokenIn, params.tokenOut);

        transferFromAndApproveInput(params.tokenIn, params.amountIn);

        address userAddress = params.recipient;
        params.recipient = address(this);

        uint256 amountOut = _exactInputSingle(params);

        excessSlippage = amountOut.sub(params.amountOutMinimum);

        uint256 outputAmount = excessSlippage > 0
            ? params.amountOutMinimum
            : amountOut;

        params.tokenOut.safeTransfer(userAddress, outputAmount);

        if (excessSlippage > 0) {
            redeemSeeds(userAddress, params.tokenOut, excessSlippage);
        }

        emit GreenSwapped(
            params.tokenIn,
            params.tokenOut,
            userAddress,
            excessSlippage
        );
    }

    function _exactInputSingle(UniExactInputSingleParams memory params)
        private
        returns (uint256 amountOut)
    {
        amountOut = uniswapV3Router.exactInputSingle(params);

        require(
            amountOut >= params.amountOutMinimum,
            "GreenRouter::exactInputSingle:INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function exactInput(UniExactInputParams memory params)
        public
        payable
        returns (uint256 excessSlippage)
    {
        address tokenIn = params.path.toAddress(0);
        address tokenOut = params.path.getLastToken().toAddress(0);

        validateTokens(tokenIn, tokenOut);

        transferFromAndApproveInput(tokenIn, params.amountIn);

        address userAddress = params.recipient;
        params.recipient = address(this);

        uint256 amountOut = _exactInput(params);

        excessSlippage = amountOut.sub(params.amountOutMinimum);

        uint256 outputAmount = excessSlippage > 0
            ? params.amountOutMinimum
            : amountOut;

        tokenOut.safeTransfer(userAddress, outputAmount);

        if (excessSlippage > 0) {
            redeemSeeds(userAddress, tokenOut, excessSlippage);
        }

        emit GreenSwapped(tokenIn, tokenOut, userAddress, excessSlippage);
    }

    function _exactInput(UniExactInputParams memory params)
        private
        returns (uint256 amountOut)
    {
        amountOut = uniswapV3Router.exactInput(params);

        require(
            amountOut >= params.amountOutMinimum,
            "GreenRouter::exactInput:INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function exactOutputSingle(UniExactOutputSingleParams memory params)
        public
        payable
        returns (uint256 excessSlippage)
    {
        validateTokens(params.tokenIn, params.tokenOut);

        transferFromAndApproveInput(params.tokenIn, params.amountInMaximum);

        address userAddress = params.recipient;
        params.recipient = address(this);

        uint256 amountIn = _exactOutputSingle(params);

        excessSlippage = params.amountInMaximum.sub(amountIn);

        params.tokenOut.safeTransfer(userAddress, params.amountOut);

        if (excessSlippage > 0) {
            redeemSeeds(userAddress, params.tokenIn, excessSlippage);
        }

        emit GreenSwapped(
            params.tokenIn,
            params.tokenOut,
            userAddress,
            excessSlippage
        );
    }

    function _exactOutputSingle(UniExactOutputSingleParams memory params)
        private
        returns (uint256 amountIn)
    {
        amountIn = uniswapV3Router.exactOutputSingle(params);

        require(
            amountIn <= params.amountInMaximum,
            "GreenRouter::exactOutputSingle:TOO_MUCH_INPUT_AMOUNT"
        );
    }

    function exactOutput(UniExactOutputParams memory params)
        public
        payable
        returns (uint256 excessSlippage)
    {
        address tokenIn = params.path.toAddress(0);
        address tokenOut = params.path.getLastToken().toAddress(0);

        validateTokens(tokenIn, tokenOut);

        transferFromAndApproveInput(tokenIn, params.amountInMaximum);

        address userAddress = params.recipient;
        params.recipient = address(this);

        uint256 amountIn = _exactOutput(params);

        excessSlippage = params.amountInMaximum.sub(amountIn);

        tokenOut.safeTransfer(userAddress, params.amountOut);

        if (excessSlippage > 0) {
            redeemSeeds(userAddress, tokenIn, excessSlippage);
        }

        emit GreenSwapped(tokenIn, tokenOut, userAddress, excessSlippage);
    }

    function _exactOutput(UniExactOutputParams memory params)
        private
        returns (uint256 amountIn)
    {
        amountIn = uniswapV3Router.exactOutput(params);

        require(
            amountIn <= params.amountInMaximum,
            "GreenRouter::exactOutputSingle:TOO_MUCH_INPUT_AMOUNT"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
pragma abicoder v2;

import "./whitelisted/Whitelisted.sol";

import "./Interfaces/IRedeem.sol";
import "./libraries/TransferHelper.sol";

contract Router is Whitelisted {
    using TransferHelper for address;

    address public redeem;
    address public treasury;

    event RedeemedSeeds(
        address recipient,
        address tokenAddress,
        uint256 tokenAmount
    );

    constructor(address _treasury, address _redeem) {
        treasury = _treasury;
        redeem = _redeem;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setRedeem(address _redeem) external onlyOwner {
        redeem = _redeem;
    }

    function redeemSeeds(
        address recipient,
        address tokenAddress,
        uint256 tokenAmount
    ) internal {
        beforeRedeemSeeds(tokenAddress, tokenAmount);

        IRedeem(redeem).redeemSeeds(recipient, tokenAddress, tokenAmount);

        afterRedeemSeeds(tokenAddress, tokenAmount);

        emit RedeemedSeeds(recipient, tokenAddress, tokenAmount);
    }

    function beforeRedeemSeeds(address tokenAddress, uint256 tokenAmount)
        internal
    {}

    function afterRedeemSeeds(address tokenAddress, uint256 tokenAmount)
        internal
    {
        tokenAddress.safeTransfer(treasury, tokenAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./BytesLib.sol";

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH =
        POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path)
        internal
        pure
        returns (bytes memory)
    {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getLastToken(bytes memory path)
        public
        pure
        returns (bytes memory)
    {
        uint256 poolNum = numPools(path);
        uint256 from = (ADDR_SIZE * poolNum) + (FEE_SIZE * poolNum);
        return path.slice(from, ADDR_SIZE);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstToken(bytes memory path)
        public
        pure
        returns (bytes memory)
    {
        uint256 to = ADDR_SIZE;
        return path.slice(0, to);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return rest The remaining token + fee elements in the path
    /// @return skipped the skipped token
    function skipToken(bytes memory path)
        internal
        pure
        returns (bytes memory rest, bytes memory skipped)
    {
        rest = path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
        skipped = path.slice(0, ADDR_SIZE);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library SafeMath {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IUniswapStorage.sol";

interface IUniswapV3Router is IUniswapStorage {
    function exactInputSingle(UniExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    function exactInput(UniExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    function exactOutputSingle(UniExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    function exactOutput(UniExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    function refundETH() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IUniswapStorage {
    struct UniExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct UniExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct UniExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    struct UniExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelisted is Ownable {
    mapping(address => bool) public whitelisted;

    event TokenWhitelisted(address[] indexed accounts);
    event TokenNotWhitelisted(address[] indexed accounts);

    modifier onlyWhitelisted(address addr) {
        require(whitelisted[addr] == true, "Token has not been whitelisted");
        _;
    }

    function addWhitelisted(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true;
        }

        emit TokenWhitelisted(addresses);
    }

    function removeWhitelisted(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = false;
        }

        emit TokenNotWhitelisted(addresses);
    }

    function validateTokens(address tokenIn, address tokenOut) internal view {
        require(whitelisted[tokenIn], "token in has not been white listed");
        require(whitelisted[tokenOut], "token out has not been white listed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IRedeem {
    function redeemSeeds(
        address recipient,
        address token,
        uint256 amount
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../Interfaces/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "STF"
        );
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ST"
        );
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SA"
        );
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }
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

/*
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (address)
    {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint24)
    {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000000
  },
  "metadata": {
    "bytecodeHash": "none"
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {
    "contracts/libraries/BytesLib.sol": {
      "BytesLib": "0x61a477dffb0840bc6dbe9a5e983f7249c5b85f26"
    },
    "contracts/libraries/Path.sol": {
      "Path": "0x3e5a7ee301923eefbe198db962b9d685aa20e927"
    }
  }
}