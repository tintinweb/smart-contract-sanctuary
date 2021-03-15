// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import '../interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMathUniswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'fa418eb2c6e15c39605695377d0e364aca1c3c56b333eefe9c0d4b707662f785' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() payable external;
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IWHAssetv2 {
    event Wrap(address indexed account, uint32 indexed tokenId, uint88 cost, uint88 amount, uint48 strike, uint32 expiration);
    event Unwrap(address indexed account, uint32 indexed tokenId, uint128 closePrice, uint128 optionProfit);

    struct Underlying {
        bool active;
        address owner;
        uint88 amount;
        uint48 expiration;
        uint48 strike;
    }

    function wrap(uint128 amount, uint period, address to, bool mintToken, uint minUSDCPremium) payable external returns (uint newTokenId);
    function unwrap(uint tokenId) external;
    function autoUnwrap(uint tokenId, address rewardRecipient) external returns (uint);
    function autoUnwrapAll(uint[] calldata tokenIds, address rewardRecipient) external returns (uint);
    function wrapAfterSwap(uint total, uint protectionPeriod, address to, bool mintToken, uint minUSDCPremium) external returns (uint newTokenId);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IWHSwapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokensAndWrap(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to, 
        uint deadline,
        uint protectionPeriod,
        bool mintToken,
        uint minUSDCPremium
    ) external returns (uint[] memory amounts, uint newTokenId);

    function swapTokensForExactTokensAndWrap(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        uint protectionPeriod, 
        bool mintToken,
        uint minUSDCPremium
    ) external returns (uint[] memory amounts, uint newTokenId);

    function swapExactETHForTokensAndWrap(uint amountOutMin, address[] calldata path, address to, uint deadline, uint protectionPeriod, bool mintToken, uint minUSDCPremium)
        external
        payable
        returns (uint[] memory amounts, uint newTokenId);

    function swapETHForExactTokensAndWrap(uint amountOut, address[] calldata path, address to, uint deadline, uint protectionPeriod, bool mintToken, uint minUSDCPremium)
        external
        payable
        returns (uint[] memory amounts, uint newTokenId);


    function swapExactTokensForETHAndWrap(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint protectionPeriod, bool mintToken, uint minUSDCPremium)
        external
        returns(uint[] memory amounts, uint newTokenId);

    function swapTokensForExactETHAndWrap(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline, uint protectionPeriod, bool mintToken, uint minUSDCPremium)
        external
        returns (uint[] memory amounts, uint newTokenId);

// **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        external
        pure
        returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        external
        pure        
        returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] memory path)
        external
        view        
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] memory path)
        external
        view
        returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Interfaces/IWETH.sol";
import "./Interfaces/IWHAsset.sol";
import "./Interfaces/IWHSwapRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@sushiswap/core/contracts/uniswapv2/libraries/TransferHelper.sol";
import "@sushiswap/core/contracts/uniswapv2/libraries/UniswapV2Library.sol";

/**
 * @author jmonteer
 * @title Whiteheart's Swap+Wrap router using Uniswap-like DEX
 * @notice Contract performing a swap and sending the output to the corresponding WHAsset contract for it to be wrapped into a Hedge Contract
 */
contract WHSwapRouter is IWHSwapRouter, Ownable {
    address public immutable factory; 
    address public immutable WETH;

    // Maps the underlying asset to the corresponding Hedge Contracts
    mapping(address => address) public whAssets;
    
    /**
     * @notice Constructor
     * @param _factory DEX factory contract 
     * @param _WETH Ether ERC20's token address
     */
    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    /**
     * @notice Adds an entry to the underlyingAsset => WHAsset contract. It can be used to set the underlying asset to 0x0 address
     * @param token Asset address
     * @param whAsset WHAsset contract for the underlying asset
     */
    function setWHAsset(address token, address whAsset) external onlyOwner {
        whAssets[token] = whAsset;
    }

    /**
     * @notice Function used by WHAsset contracts to swap underlying assets into USDC, to buy options. Same function than "original" router's function
     * @param amountIn amount of the token being swap
     * @param amountOutMin minimum amount of the asset to be received from the swap
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'insufficient_output_amount');        

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    /**
     * @notice Custom function for swapExactTokensForTokens that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountIn amount of the token being swap
     * @param amountOutMin minimum amount of the asset to be received from the swap
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapExactTokensForTokensAndWrap(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to, 
        uint deadline,
        uint protectionPeriod,
        bool mintToken,
        uint minUSDCPremium
    ) external virtual override ensure(deadline) returns (uint[] memory amounts, uint newTokenId){
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'insufficient_output_amount');        
        
        {
            address[] calldata _path = path;
            TransferHelper.safeTransferFrom(
                _path[0], msg.sender, UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]
            );
        }

        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);
    }

    /**
     * @notice Custom function for swapTokensForExactTokens that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountOut exact amount of output asset expected
     * @param amountInMax maximum amount of tokens to be sent to the DEX
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapTokensForExactTokensAndWrap(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        uint protectionPeriod,
        bool mintToken,
        uint minUSDCPremium
    ) external virtual override ensure(deadline) returns (uint[] memory amounts, uint newTokenId) {
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'excessive_input_amount');
        {
            address[] calldata _path = path;
            TransferHelper.safeTransferFrom(
                _path[0], msg.sender, UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]
            );
        }
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);
    }

    /**
     * @notice Custom function for swapExactETHForTokens that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountOutMin minimum amount of the asset to be received from the swap
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapExactETHForTokensAndWrap(uint amountOutMin, address[] calldata path, address to, uint deadline, uint protectionPeriod,
        bool mintToken, uint minUSDCPremium)
        external
        virtual
        payable
        override
        ensure(deadline)
        returns (uint[] memory amounts, uint newTokenId)
    {           
        address[] memory _path = path; // to avoid stack too deep
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, _path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'insufficient_input_amount');

        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]));   
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);

    }

    /**
     * @notice Custom function for swapETHForExactTokens that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountOut amount of the token being swap
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapETHForExactTokensAndWrap(uint amountOut,
        address[] calldata path,
        address to,
        uint deadline,
        uint protectionPeriod,
        bool mintToken,
        uint minUSDCPremium
    )
        external
        virtual
        payable
        override
        ensure(deadline)
        returns (uint[] memory amounts, uint newTokenId)
    {
        address[] memory _path = path; // to avoid stack too deep
        require(_path[0] == WETH, 'invalid_path');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, _path);
        require(amounts[0] <= msg.value, 'excessive_input_amount');

        IWETH(WETH).deposit{value: amounts[0]}();
        {
            assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]));
        }

        if(msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);
    }

    /**
     * @notice Custom function for swapExactTokensForETH that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountIn amount of the token being swapped
     * @param amountOutMin minimum amount of the output asset to be received
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapExactTokensForETHAndWrap(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint protectionPeriod,
        bool mintToken, uint minUSDCPremium)
        external
        override
        ensure(deadline)
        returns(uint[] memory amounts, uint newTokenId) 
    {
        require(path[path.length - 1] == WETH, 'invalid_path');

        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "insufficient_output_amount");
        {
            address[] calldata _path = path;
            TransferHelper.safeTransferFrom(
                _path[0], msg.sender, UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]
            );
        }        
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);

    }

    /**
     * @notice Custom function for swapTokensForExactETH that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountOut amount of the output asset to be received
     * @param amountInMax maximum amount of input that user is willing to send to the contract to reach amountOut 
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapTokensForExactETHAndWrap(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline, uint protectionPeriod,
        bool mintToken, uint minUSDCPremium)
        external
        override
        ensure(deadline)
        returns (uint[] memory amounts, uint newTokenId)
    {
        require(path[path.length - 1] == WETH, 'invalid_path');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'excessive_input_amount');
        {
            address[] calldata _path = path;
            TransferHelper.safeTransferFrom(
                _path[0], msg.sender, UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]
            );
        } 
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);

    }

    /**
     * @notice Internal function to be called after all swap params have been calc'd. it performs a swap and sends output to corresponding WHAsset contract
     * @param path ordered list of assets to be swap from, to
     * @param amounts list of amounts to send/receive of each of path's asset
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
    */
    function _swapAndWrap(address[] calldata path, uint[] memory amounts, uint protectionPeriod, address to, bool mintToken, uint minUSDCPremium) 
        internal
        returns (uint newTokenId)
    {
        address whAsset = whAssets[path[path.length - 1]];
        require(whAsset != address(0), 'whAsset_does_not_exist');
        _swap(amounts, path, whAsset);
        newTokenId = IWHAssetv2(whAsset).wrapAfterSwap(amounts[amounts.length - 1], protectionPeriod, to, mintToken, minUSDCPremium);
    }

    /**
     * @notice Internal function to be called for actually swapping the involved assets. requires the initial amount to have already been sent to the first pair
     * @param amounts list of amounts to send/receive of each of path's asset
     * @param path ordered list of assets to be swap from, to
     * @param _to recipient of swap's output
      */
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for(uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, )  = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    // **** LIBRARY FUNCTIONS **** 
    // from original Uniswap router
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }
}