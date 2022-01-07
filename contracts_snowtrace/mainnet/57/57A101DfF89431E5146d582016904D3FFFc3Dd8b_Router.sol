// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interface/IERC20.sol";
import "./interface/IWETH9.sol";
import "./lib/SafeERC20.sol";
import "./lib/Ownable.sol";

abstract contract Adapter is Ownable {
    using SafeERC20 for IERC20;

    event AdapterSwap(
        address indexed _tokenFrom,
        address indexed _tokenTo,
        uint256 _amountIn,
        uint256 _amountOut
    );

    event UpdatedGasEstimate(address indexed _adapter, uint256 _newEstimate);

    event Recovered(address indexed _asset, uint256 amount);

    address payable internal WGAS;
    address internal constant GAS = address(0);
    uint256 internal constant UINT_MAX = type(uint256).max;

    uint256 public swapGasEstimate;
    string public name;

    function setSwapGasEstimate(uint256 _estimate) public onlyOwner {
        swapGasEstimate = _estimate;
        emit UpdatedGasEstimate(address(this), _estimate);
    }

    /**
     * @notice Revoke token allowance
     * @param _token address
     * @param _spender address
     */
    function revokeAllowance(address _token, address _spender)
        external
        onlyOwner
    {
        IERC20(_token).safeApprove(_spender, 0);
    }

    /**
     * @notice Recover ERC20 from contract
     * @param _tokenAddress token address
     * @param _tokenAmount amount to recover
     */
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(_tokenAmount > 0, "Adapter: Nothing to recover");
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Recover GAS from contract
     * @param _amount amount
     */
    function recoverETH(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Adapter: Nothing to recover");
        payable(msg.sender).transfer(_amount);
        emit Recovered(address(0), _amount);
    }

    function query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view returns (uint256) {
        return _query(_amountIn, _tokenIn, _tokenOut);
    }

    /**
     * Execute a swap from token to token assuming this contract already holds input tokens
     * @notice Interact through the router
     * @param _amountIn input amount in starting token
     * @param _amountOut amount out in ending token
     * @param _fromToken ERC20 token being sold
     * @param _toToken ERC20 token being bought
     * @param _to address where swapped funds should be sent to
     */
    function swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _fromToken,
        address _toToken,
        address _to
    ) external {
        _approveIfNeeded(_fromToken, _amountIn);
        _swap(_amountIn, _amountOut, _fromToken, _toToken, _to);
        emit AdapterSwap(_fromToken, _toToken, _amountIn, _amountOut);
    }

    /**
     * @notice Return expected funds to user
     * @dev Skip if funds should stay in the contract
     * @param _token address
     * @param _amount tokens to return
     * @param _to address where funds should be sent to
     */
    function _returnTo(
        address _token,
        uint256 _amount,
        address _to
    ) internal {
        if (address(this) != _to) {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice Wrap GAS
     * @param _amount amount
     */
    function _wrap(uint256 _amount) internal {
        IWETH9(WGAS).deposit{value: _amount}();
    }

    /**
     * @notice Unwrap WGAS
     * @param _amount amount
     */
    function _unwrap(uint256 _amount) internal {
        IWETH9(WGAS).withdraw(_amount);
    }

    /**
     * @notice Internal implementation of a swap
     * @dev Must return tokens to address(this)
     * @dev Wrapping is handled external to this function
     * @param _amountIn amount being sold
     * @param _amountOut amount being bought
     * @param _fromToken ERC20 token being sold
     * @param _toToken ERC20 token being bought
     * @param _to Where recieved tokens are sent to
     */
    function _swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _fromToken,
        address _toToken,
        address _to
    ) internal virtual;

    function _query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) internal view virtual returns (uint256);

    /**
     * @notice Approve tokens for use in Strategy
     * @dev Should use modifier `onlyOwner` to avoid griefing
     */
    function setAllowances() public virtual;

    function _approveIfNeeded(address _tokenIn, uint256 _amount)
        internal
        virtual;

    receive() external payable {}
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function nonces(address) external view returns (uint256); // Only tokens that support permit

    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external; // Only tokens that support permit

    function mint(address to, uint256 amount) external; // only tokens that support minting
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

interface IWETH9 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

// This is a simplified version of OpenZepplin's SafeERC20 library
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interface/IERC20.sol";
import "./SafeMath.sol";


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Context.sol";
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
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "Ownable: Caller is not the owner");
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
        require(newOwner != address(0), "Ownable: New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'SafeMath: ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'SafeMath: ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'SafeMath: ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interface/IUnilikeFactory.sol";
import "../interface/IUnilikePair.sol";
import "../interface/IERC20.sol";
import "../lib/SafeERC20.sol";
import "../lib/SafeMath.sol";
import "../Adapter.sol";

contract UnilikeAdapter is Adapter {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant ID = keccak256("UnilikeAdapter");
    uint256 internal constant FEE_DENOMINATOR = 1e3;
    uint256 public immutable feeCompliment;
    address public immutable factory;

    constructor(
        string memory _name,
        address _factory,
        uint256 _fee,
        uint256 _swapGasEstimate,
        address payable _weth
    ) public {
        require(
            FEE_DENOMINATOR > _fee,
            "UnilikeAdapter: Fee greater than the denominator"
        );
        factory = _factory;
        name = _name;
        feeCompliment = FEE_DENOMINATOR.sub(_fee);
        setSwapGasEstimate(_swapGasEstimate);
        WGAS = _weth;
        setAllowances();
    }

    function setAllowances() public override onlyOwner {
        IERC20(WGAS).safeApprove(WGAS, UINT_MAX);
    }

    function _approveIfNeeded(address tokenIn, uint256 amount)
        internal
        override
    {}

    function _getAmountOut(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut
    ) internal view returns (uint256 amountOut) {
        // Based on https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/UniswapV2Router02.sol
        uint256 amountInWithFee = _amountIn.mul(feeCompliment);
        uint256 numerator = amountInWithFee.mul(_reserveOut);
        uint256 denominator = _reserveIn.mul(FEE_DENOMINATOR).add(
            amountInWithFee
        );
        amountOut = numerator / denominator;
    }

    function _query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) internal view override returns (uint256) {
        if (_tokenIn == _tokenOut || _amountIn == 0) {
            return 0;
        }
        address pair = IUnilikeFactory(factory).getPair(_tokenIn, _tokenOut);
        if (pair == address(0)) {
            return 0;
        }
        (uint256 r0, uint256 r1, ) = IUnilikePair(pair).getReserves();
        (uint256 reserveIn, uint256 reserveOut) = _tokenIn < _tokenOut
            ? (r0, r1)
            : (r1, r0);
        if (reserveIn > 0 && reserveOut > 0) {
            return _getAmountOut(_amountIn, reserveIn, reserveOut);
        }
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut,
        address to
    ) internal override {
        address pair = IUnilikeFactory(factory).getPair(_tokenIn, _tokenOut);
        (uint256 amount0Out, uint256 amount1Out) = (_tokenIn < _tokenOut)
            ? (uint256(0), _amountOut)
            : (_amountOut, uint256(0));
        IERC20(_tokenIn).safeTransfer(pair, _amountIn);
        IUnilikePair(pair).swap(amount0Out, amount1Out, to, new bytes(0));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IUnilikeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IUnilikePair {
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interface/IMetaSynapse.sol";
import "../interface/IERC20.sol";
import "../lib/SafeERC20.sol";
import "../lib/SafeMath.sol";
import "../Adapter.sol";

contract SynapseMetaAdapter is Adapter {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant id = keccak256("SynapseMetaAdapter");
    uint256 public constant poolFeeCompliment = 9996; // In bips
    uint256 public constant bips = 1e4;
    mapping(address => bool) public isPoolToken;
    mapping(address => uint8) public tokenIndex;
    address public pool;

    constructor(
        string memory _name,
        address _pool,
        uint256 _swapGasEstimate
    ) public {
        pool = _pool;
        name = _name;
        _setPoolTokens();
        setSwapGasEstimate(_swapGasEstimate);
    }

    // Mapping indicator which tokens are included in the pool
    function _setPoolTokens() internal {
        // Get stables from pool
        for (uint8 i = 0; true; i++) {
            try IMetaSynapse(pool).getToken(i) returns (IERC20 token) {
                isPoolToken[address(token)] = true;
                tokenIndex[address(token)] = i;
            } catch {
                break;
            }
        }
        // // Get nUSD from this pool
        // address lpToken = IMetaSynapse(pool).metaLPToken();
        // isPoolToken[lpToken] = true;
        // tokenIndex[lpToken] = 4;
    }

    function setAllowances() public override onlyOwner {}

    function _approveIfNeeded(address _tokenIn, uint256 _amount)
        internal
        override
    {
        uint256 allowance = IERC20(_tokenIn).allowance(address(this), pool);
        if (allowance < _amount) {
            IERC20(_tokenIn).safeApprove(pool, UINT_MAX);
        }
    }

    function _query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) internal view override returns (uint256) {
        if (
            _amountIn == 0 ||
            _tokenIn == _tokenOut ||
            !isPoolToken[_tokenIn] ||
            !isPoolToken[_tokenOut]
        ) {
            return 0;
        }
        if (tokenIndex[_tokenIn] != 4 && tokenIndex[_tokenOut] != 4) {
            try
                IMetaSynapse(pool).calculateSwap(
                    tokenIndex[_tokenIn],
                    tokenIndex[_tokenOut],
                    _amountIn
                )
            returns (uint256 amountOut) {
                return amountOut.mul(poolFeeCompliment) / bips;
            } catch {
                return 0;
            }
        } else {
            if (tokenIndex[_tokenOut] == 4) {
                uint256[] memory amounts = new uint256[](3);
                amounts[(tokenIndex[_tokenIn])] = _amountIn;
                try IMetaSynapse(pool).calculateTokenAmount(amounts, true) returns (
                    uint256 amountOut
                ) {
                    return amountOut.mul(poolFeeCompliment) / bips;
                } catch {
                    return 0;
                }
            } else if (tokenIndex[_tokenIn] == 4) {
                // remove liquidity
                try
                    IMetaSynapse(pool).calculateRemoveLiquidityOneToken(
                        _amountIn,
                        tokenIndex[_tokenOut]
                    )
                returns (uint256 amountOut) {
                    return amountOut.mul(poolFeeCompliment) / bips;
                } catch {
                    return 0;
                }
            } else {
                return 0;
            }
        }
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut,
        address _to
    ) internal override {
        if (tokenIndex[_tokenIn] != 4 && tokenIndex[_tokenOut] != 4) {
            IMetaSynapse(pool).swap(
                tokenIndex[_tokenIn],
                tokenIndex[_tokenOut],
                _amountIn,
                _amountOut,
                block.timestamp
            );
            // Confidently transfer amount-out
            _returnTo(_tokenOut, _amountOut, _to);
        } else {
            // add liquidity
            if (tokenIndex[_tokenOut] == 4) {
                uint256[] memory amounts = new uint256[](3);
                amounts[(tokenIndex[_tokenIn])] = _amountIn;

                IMetaSynapse(pool).addLiquidity(
                    amounts,
                    _amountOut,
                    block.timestamp
                );
                _returnTo(_tokenOut, _amountOut, _to);
            }
            if (tokenIndex[_tokenIn] == 4) {
                // remove liquidity
                IMetaSynapse(pool).removeLiquidityOneToken(
                    _amountIn,
                    tokenIndex[_tokenOut],
                    _amountOut,
                    block.timestamp
                );
                _returnTo(_tokenOut, _amountOut, _to);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";

interface IMetaSynapse {
    // pool data view functions
    function getA() external view returns (uint256);

    function getToken(uint256 index) external view returns (IERC20);

    function paused() external view returns (bool);

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
        external
        view
        returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    function metaLPToken() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./lib/BytesManipulation.sol";
import "./interface/IAdapter.sol";
import "./interface/IWETH9.sol";
import "./interface/IBridge.sol";
import "./lib/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Router is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address payable public WGAS;
    address public constant GAS = address(0);
    uint256 public constant FEE_DENOMINATOR = 1e4;
    uint256 public MIN_FEE = 0;
    address public FEE_CLAIMER;
    address[] public TRUSTED_TOKENS;
    address[] public ADAPTERS;
    address public BRIDGE;
    bytes32 constant REDEEM = keccak256("REDEEM");
    bytes32 constant DEPOSIT = keccak256("REDEEM");

    event Recovered(address indexed _asset, uint256 amount);

    event UpdatedTrustedTokens(address[] _newTrustedTokens);

    event UpdatedAdapters(address[] _newAdapters);

    event UpdatedMinFee(uint256 _oldMinFee, uint256 _newMinFee);

    event UpdatedFeeClaimer(address _oldFeeClaimer, address _newFeeClaimer);

    event Swap(
        address indexed _tokenIn,
        address indexed _tokenOut,
        uint256 _amountIn,
        uint256 _amountOut
    );

    struct Query {
        address adapter;
        address tokenIn;
        address tokenOut;
        uint256 amountOut;
    }

    struct OfferWithGas {
        bytes amounts;
        bytes adapters;
        bytes path;
        uint256 gasEstimate;
    }

    struct FormattedOfferWithGas {
        uint256[] amounts;
        address[] adapters;
        address[] path;
        uint256 gasEstimate;
    }

    struct Trade {
        uint256 amountIn;
        uint256 amountOut;
        address[] path;
        address[] adapters;
    }

    constructor(
        address[] memory _adapters,
        address[] memory _trustedTokens,
        address _feeClaimer,
        address payable _weth,
        address _bridge
    ) public {
        setTrustedTokens(_trustedTokens);
        setFeeClaimer(_feeClaimer);
        setAdapters(_adapters);
        WGAS = _weth;
        BRIDGE = _bridge;
        
        _setAllowances();
    }

    // -- SETTERS --

    function _setAllowances() internal {
        IERC20(WGAS).safeApprove(WGAS, type(uint256).max);
    }

    function setTrustedTokens(address[] memory _trustedTokens)
        public
        onlyOwner
    {
        emit UpdatedTrustedTokens(_trustedTokens);
        TRUSTED_TOKENS = _trustedTokens;
    }

    function setAdapters(address[] memory _adapters) public onlyOwner {
        emit UpdatedAdapters(_adapters);
        ADAPTERS = _adapters;
    }

    function setMinFee(uint256 _fee) external onlyOwner {
        emit UpdatedMinFee(MIN_FEE, _fee);
        MIN_FEE = _fee;
    }

    function setFeeClaimer(address _claimer) public onlyOwner {
        emit UpdatedFeeClaimer(FEE_CLAIMER, _claimer);
        FEE_CLAIMER = _claimer;
    }

    //  -- GENERAL --

    function trustedTokensCount() external view returns (uint256) {
        return TRUSTED_TOKENS.length;
    }

    function adaptersCount() external view returns (uint256) {
        return ADAPTERS.length;
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(_tokenAmount > 0, "Router: Nothing to recover");
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    function recoverGAS(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Router: Nothing to recover");
        payable(msg.sender).transfer(_amount);
        emit Recovered(address(0), _amount);
    }

    // Fallback
    receive() external payable {}

    // -- HELPERS --

    function _applyFee(uint256 _amountIn, uint256 _fee)
        internal
        view
        returns (uint256)
    {
        require(_fee >= MIN_FEE, "Router: Insufficient fee");
        return _amountIn.mul(FEE_DENOMINATOR.sub(_fee)) / FEE_DENOMINATOR;
    }

    function _wrap(uint256 _amount) internal {
        IWETH9(WGAS).deposit{value: _amount}();
    }

    function _unwrap(uint256 _amount) internal {
        IWETH9(WGAS).withdraw(_amount);
    }

    /**
     * @notice Return tokens to user
     * @dev Pass address(0) for GAS
     * @param _token address
     * @param _amount tokens to return
     * @param _to address where funds should be sent to
     */
    function _returnTokensTo(
        address _token,
        uint256 _amount,
        address _to
    ) internal {
        if (address(this) != _to) {
            if (_token == GAS) {
                payable(_to).transfer(_amount);
            } else {
                IERC20(_token).safeTransfer(_to, _amount);
            }
        }
    }

    /**
     * Makes a deep copy of OfferWithGas struct
     */
    function _cloneOfferWithGas(OfferWithGas memory _queries)
        internal
        pure
        returns (OfferWithGas memory)
    {
        return
            OfferWithGas(
                _queries.amounts,
                _queries.adapters,
                _queries.path,
                _queries.gasEstimate
            );
    }

    /**
     * Appends Query elements to Offer struct
     */
    function _addQueryWithGas(
        OfferWithGas memory _queries,
        uint256 _amount,
        address _adapter,
        address _tokenOut,
        uint256 _gasEstimate
    ) internal pure {
        _queries.path = BytesManipulation.mergeBytes(
            _queries.path,
            BytesManipulation.toBytes(_tokenOut)
        );
        _queries.amounts = BytesManipulation.mergeBytes(
            _queries.amounts,
            BytesManipulation.toBytes(_amount)
        );
        _queries.adapters = BytesManipulation.mergeBytes(
            _queries.adapters,
            BytesManipulation.toBytes(_adapter)
        );
        _queries.gasEstimate += _gasEstimate;
    }

    /**
     * Converts byte-arrays to an array of integers
     */
    function _formatAmounts(bytes memory _amounts)
        internal
        pure
        returns (uint256[] memory)
    {
        // Format amounts
        uint256 chunks = _amounts.length / 32;
        uint256[] memory amountsFormatted = new uint256[](chunks);
        for (uint256 i = 0; i < chunks; i++) {
            amountsFormatted[i] = BytesManipulation.bytesToUint256(
                i * 32 + 32,
                _amounts
            );
        }
        return amountsFormatted;
    }

    /**
     * Converts byte-array to an array of addresses
     */
    function _formatAddresses(bytes memory _addresses)
        internal
        pure
        returns (address[] memory)
    {
        uint256 chunks = _addresses.length / 32;
        address[] memory addressesFormatted = new address[](chunks);
        for (uint256 i = 0; i < chunks; i++) {
            addressesFormatted[i] = BytesManipulation.bytesToAddress(
                i * 32 + 32,
                _addresses
            );
        }
        return addressesFormatted;
    }

    /**
     * Formats elements in the Offer object from byte-arrays to integers and addresses
     */
    function _formatOfferWithGas(OfferWithGas memory _queries)
        internal
        pure
        returns (FormattedOfferWithGas memory)
    {
        return
            FormattedOfferWithGas(
                _formatAmounts(_queries.amounts),
                _formatAddresses(_queries.adapters),
                _formatAddresses(_queries.path),
                _queries.gasEstimate
            );
    }

    // -- QUERIES --

    /**
     * Query single adapter
     */
    function queryAdapter(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint8 _index
    ) external view returns (uint256) {
        IAdapter _adapter = IAdapter(ADAPTERS[_index]);
        uint256 amountOut = _adapter.query(_amountIn, _tokenIn, _tokenOut);
        return amountOut;
    }

    /**
     * Query specified adapters
     */
    function query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint8[] calldata _options
    ) public view returns (Query memory) {
        Query memory bestQuery;
        for (uint8 i; i < _options.length; i++) {
            address _adapter = ADAPTERS[_options[i]];
            uint256 amountOut = IAdapter(_adapter).query(
                _amountIn,
                _tokenIn,
                _tokenOut
            );
            if (i == 0 || amountOut > bestQuery.amountOut) {
                bestQuery = Query(_adapter, _tokenIn, _tokenOut, amountOut);
            }
        }
        return bestQuery;
    }

    /**
     * Query all adapters
     */
    function query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) public view returns (Query memory) {
        Query memory bestQuery;
        for (uint8 i; i < ADAPTERS.length; i++) {
            address _adapter = ADAPTERS[i];
            uint256 amountOut = IAdapter(_adapter).query(
                _amountIn,
                _tokenIn,
                _tokenOut
            );
            if (i == 0 || amountOut > bestQuery.amountOut) {
                bestQuery = Query(_adapter, _tokenIn, _tokenOut, amountOut);
            }
        }
        return bestQuery;
    }

    /**
     * Return path with best returns between two tokens
     * Takes gas-cost into account
     */
    function findBestPathWithGas(
        uint256 _amountIn, 
        address _tokenIn, 
        address _tokenOut, 
        uint _maxSteps,
        uint _gasPrice
    ) external view returns (FormattedOfferWithGas memory) {
        require(_maxSteps>0 && _maxSteps<5, 'YakRouter: Invalid max-steps');
        OfferWithGas memory queries;
        uint tknOutPriceNwei = 0;
        queries.amounts = BytesManipulation.toBytes(_amountIn);
        queries.path = BytesManipulation.toBytes(_tokenIn);
        // Find the market price between AVAX and token-out and express gas price in token-out currency
        if(_gasPrice == 0){
            OfferWithGas memory gasQueries;
            gasQueries.amounts = BytesManipulation.toBytes(1e18);
            gasQueries.path = BytesManipulation.toBytes(WGAS);
            OfferWithGas memory gasQuery = _findBestPathWithGas(
                1e18, 
                WGAS, 
                _tokenOut, 
                2,
                gasQueries, 
                tknOutPriceNwei
            );  // Avoid low-liquidity price appreciation
            uint[] memory tokenOutAmounts = _formatAmounts(gasQuery.amounts);
            // Leave result nWei to preserve digits for assets with low decimal places
            tknOutPriceNwei = tokenOutAmounts[tokenOutAmounts.length-1].mul(_gasPrice/1e9);
        }
        queries = _findBestPathWithGas(
            _amountIn, 
            _tokenIn, 
            _tokenOut, 
            _maxSteps,
            queries, 
            tknOutPriceNwei
        );
        
        // If no paths are found return empty struct
        if (queries.adapters.length==0) {
            queries.amounts = '';
            queries.path = '';
        }
        return _formatOfferWithGas(queries);
    } 

    function _findBestPathWithGas(
        uint256 _amountIn, 
        address _tokenIn, 
        address _tokenOut, 
        uint _maxSteps,
        OfferWithGas memory _queries, 
        uint _tknOutPriceNwei
    ) internal view returns (OfferWithGas memory) {
        OfferWithGas memory bestOption = _cloneOfferWithGas(_queries);
        uint256 bestAmountOut;
        bool isGasIncluded = (_tknOutPriceNwei == 0);
        // First check if there is a path directly from tokenIn to tokenOut
        Query memory queryDirect = query(_amountIn, _tokenIn, _tokenOut);
        if (queryDirect.amountOut!=0) {
            uint gasEstimate = 0;
            if(isGasIncluded){
                gasEstimate = IAdapter(queryDirect.adapter).swapGasEstimate();
            }
            _addQueryWithGas(
                bestOption, 
                queryDirect.amountOut, 
                queryDirect.adapter, 
                queryDirect.tokenOut, 
                gasEstimate
            );
            bestAmountOut = queryDirect.amountOut;
        }
        // Only check the rest if they would go beyond step limit (Need at least 2 more steps)
        if (_maxSteps>1 && _queries.adapters.length/32<=_maxSteps-2) {
            // Check for paths that pass through trusted tokens
            for (uint256 i=0; i<TRUSTED_TOKENS.length; i++) {
                if (_tokenIn == TRUSTED_TOKENS[i]) {
                    continue;
                }
                // Loop through all adapters to find the best one for swapping tokenIn for one of the trusted tokens
                Query memory bestSwap = query(_amountIn, _tokenIn, TRUSTED_TOKENS[i]);
                if (bestSwap.amountOut==0) {
                    continue;
                }
                // Explore options that connect the current path to the tokenOut
                OfferWithGas memory newOffer = _cloneOfferWithGas(_queries);
                uint gasEstimate = 0;
                if(isGasIncluded){
                    gasEstimate = IAdapter(queryDirect.adapter).swapGasEstimate();
                }
                _addQueryWithGas(newOffer, bestSwap.amountOut, bestSwap.adapter, bestSwap.tokenOut, gasEstimate);
                newOffer = _findBestPathWithGas(
                    bestSwap.amountOut, 
                    TRUSTED_TOKENS[i], 
                    _tokenOut, 
                    _maxSteps, 
                    newOffer, 
                    _tknOutPriceNwei
                );
                address tokenOut = BytesManipulation.bytesToAddress(newOffer.path.length, newOffer.path);
                uint256 amountOut = BytesManipulation.bytesToUint256(newOffer.amounts.length, newOffer.amounts);
                // Check that the last token in the path is the tokenOut and update the new best option if neccesary
                if (_tokenOut == tokenOut && amountOut > bestAmountOut) {
                    if (isGasIncluded && newOffer.gasEstimate > bestOption.gasEstimate) {
                        uint gasCostDiff = _tknOutPriceNwei.mul(newOffer.gasEstimate-bestOption.gasEstimate) / 1e9;
                        uint priceDiff = amountOut - bestAmountOut;
                        if (gasCostDiff > priceDiff) { continue; }
                    }
                    bestAmountOut = amountOut;
                    bestOption = newOffer;
                }
            }
        }
        return bestOption;   
    }

    // -- SWAPPERS --

    function _swap(
        Trade calldata _trade,
        address _from,
        address _to,
        uint256 _fee
    ) internal returns (uint256) {
        uint256[] memory amounts = new uint256[](_trade.path.length);
        if (_fee > 0 || MIN_FEE > 0) {
            // Transfer fees to the claimer account and decrease initial amount
            amounts[0] = _applyFee(_trade.amountIn, _fee);
            IERC20(_trade.path[0]).safeTransferFrom(
                _from,
                FEE_CLAIMER,
                _trade.amountIn.sub(amounts[0])
            );
        } else {
            amounts[0] = _trade.amountIn;
        }
        IERC20(_trade.path[0]).safeTransferFrom(
            _from,
            _trade.adapters[0],
            amounts[0]
        );
        // Get amounts that will be swapped
        for (uint256 i = 0; i < _trade.adapters.length; i++) {
            amounts[i + 1] = IAdapter(_trade.adapters[i]).query(
                amounts[i],
                _trade.path[i],
                _trade.path[i + 1]
            );
        }
        require(
            amounts[amounts.length - 1] >= _trade.amountOut,
            "Router: Insufficient output amount"
        );
        for (uint256 i = 0; i < _trade.adapters.length; i++) {
            // All adapters should transfer output token to the following target
            // All targets are the adapters, expect for the last swap where tokens are sent out
            address targetAddress = i < _trade.adapters.length - 1
                ? _trade.adapters[i + 1]
                : _to;
            IAdapter(_trade.adapters[i]).swap(
                amounts[i],
                amounts[i + 1],
                _trade.path[i],
                _trade.path[i + 1],
                targetAddress
            );
        }
        emit Swap(
            _trade.path[0],
            _trade.path[_trade.path.length - 1],
            _trade.amountIn,
            amounts[amounts.length - 1]
        );
        return amounts[amounts.length - 1];
    }

    function swap(
        Trade calldata _trade,
        address _to,
        uint256 _fee
    ) public {
        _swap(_trade, msg.sender, _to, _fee);
    }

    function swapFromGAS(
        Trade calldata _trade,
        address _to,
        uint256 _fee
    ) external payable {
        require(
            _trade.path[0] == WGAS,
            "Router: Path needs to begin with WGAS"
        );
        _wrap(_trade.amountIn);
        _swap(_trade, address(this), _to, _fee);
    }

    function swapToGAS(
        Trade calldata _trade,
        address _to,
        uint256 _fee
    ) public {
        require(
            _trade.path[_trade.path.length - 1] == WGAS,
            "Router: Path needs to end with WGAS"
        );
        uint256 returnAmount = _swap(
            _trade,
            msg.sender,
            address(this),
            _fee
        );
        _unwrap(returnAmount);
        _returnTokensTo(GAS, returnAmount, _to);
    }

    /**
     * Swap token to token without the need to approve the first token
     */
    function swapWithPermit(
        Trade calldata _trade,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        IERC20(_trade.path[0]).permit(
            msg.sender,
            address(this),
            _trade.amountIn,
            _deadline,
            _v,
            _r,
            _s
        );
        swap(_trade, _to, _fee);
    }

    /**
     * Swap token to GAS without the need to approve the first token
     */
    function swapToGASWithPermit(
        Trade calldata _trade,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        IERC20(_trade.path[0]).permit(
            msg.sender,
            address(this),
            _trade.amountIn,
            _deadline,
            _v,
            _r,
            _s
        );
        swapToGAS(_trade, _to, _fee);
    }


    // **************************************************************** 
    // BRIDGE DEPOSIT FUNCTIONS
    // **************************************************************** 

    // function swap(
    //     Trade calldata _trade,
    //     address _to,
    //     uint256 _fee,
    //     bytes calldata bridgeaction
    // ) external {
    //     _swap(_trade, msg.sender, address(this), _fee);
    //     // _trade.path[length];
    //     IERC20(address(0xCFc37A6AB183dd4aED08C204D1c2773c0b1BDf46)).approve(BRIDGE, (type(uint256).max));
    //     (bool success, bytes memory result) = BRIDGE.call(bridgeaction);
    //     require(success);
    // }

    // function swapFromGASIntoBridge(
    //     Trade calldata _trade,
    //     address _to,
    //     uint256 _fee,
    //     bytes calldata bridgeaction
    // ) external payable {
    //     require(
    //         _trade.path[0] == WGAS,
    //         "Router: Path needs to begin with WGAS"
    //     );
    //     _wrap(_trade.amountIn);
    //     _swap(_trade, address(this), _to, _fee);
    // }

    // function swapToGASBridgeDeposit(
    //     Trade calldata _trade,
    //     address _to,
    //     uint256 _fee,
    //     bytes calldata bridgeaction
    // ) public {
    //     require(
    //         _trade.path[_trade.path.length - 1] == WGAS,
    //         "Router: Path needs to end with WGAS"
    //     );
    //     uint256 returnAmount = _swap(
    //         _trade,
    //         msg.sender,
    //         address(this),
    //         _fee
    //     );
    //     _unwrap(returnAmount);
    //     _returnTokensTo(GAS, returnAmount, _to);
    // }

    // /**
    //  * Swap token to token without the need to approve the first token
    //  */
    // function swapWithPermitBridgeDeposit(
    //     Trade calldata _trade,
    //     address _to,
    //     uint256 _fee,
    //     uint256 _deadline,
    //     uint8 _v,
    //     bytes32 _r,
    //     bytes32 _s,
    //     bytes calldata bridgeaction
    // ) external {
    //     IERC20(_trade.path[0]).permit(
    //         msg.sender,
    //         address(this),
    //         _trade.amountIn,
    //         _deadline,
    //         _v,
    //         _r,
    //         _s
    //     );
    //     swap(_trade, _to, _fee);
    // }

    // /**
    //  * Swap token to GAS without the need to approve the first token
    //  */
    // function swapToGASWithPermit(
    //     Trade calldata _trade,
    //     address _to,
    //     uint256 _fee,
    //     uint256 _deadline,
    //     uint8 _v,
    //     bytes32 _r,
    //     bytes32 _s,
    //     bytes calldata bridgeaction
    // ) external {
    //     IERC20(_trade.path[0]).permit(
    //         msg.sender,
    //         address(this),
    //         _trade.amountIn,
    //         _deadline,
    //         _v,
    //         _r,
    //         _s
    //     );
    //     swapToGAS(_trade, _to, _fee);
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./BytesToTypes.sol";

library BytesManipulation {

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function toBytes(address x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function mergeBytes(bytes memory a, bytes memory b) public pure returns (bytes memory c) {
        // From https://ethereum.stackexchange.com/a/40456
        uint alen = a.length;
        uint totallen = alen + b.length;
        uint loopsa = (a.length + 31) / 32;
        uint loopsb = (b.length + 31) / 32;
        assembly {
            let m := mload(0x40)
            mstore(m, totallen)
            for {  let i := 0 } lt(i, loopsa) { i := add(1, i) } { mstore(add(m, mul(32, add(1, i))), mload(add(a, mul(32, add(1, i))))) }
            for {  let i := 0 } lt(i, loopsb) { i := add(1, i) } { mstore(add(m, add(mul(32, add(1, i)), alen)), mload(add(b, mul(32, add(1, i))))) }
            mstore(0x40, add(m, add(32, totallen)))
            c := m
        }
    }

    function bytesToAddress(uint _offst, bytes memory _input) internal pure returns (address) {
        return BytesToTypes.bytesToAddress(_offst, _input);
    }

    function bytesToUint256(uint _offst, bytes memory _input) internal pure returns (uint256) {
        return BytesToTypes.bytesToUint256(_offst, _input);
    } 

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IAdapter {
    function name() external view returns (string memory);
    function swapGasEstimate() external view returns (uint);
    function swap(uint256, uint256, address, address, address) external;
    function query(uint256, address, address) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";

interface ISynapseBridge {

  function deposit(
    address to,
    uint256 chainId,
    IERC20 token,
    uint256 amount
  ) external;

  function depositAndSwap(
    address to,
    uint256 chainId,
    IERC20 token,
    uint256 amount,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 minDy,
    uint256 deadline
  ) external;

  function redeem(
    address to,
    uint256 chainId,
    IERC20 token,
    uint256 amount
  ) external;

  function redeemAndSwap(
    address to,
    uint256 chainId,
    IERC20 token,
    uint256 amount,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 minDy,
    uint256 deadline
  ) external;

  function redeemAndRemove(
    address to,
    uint256 chainId,
    IERC20 token,
    uint256 amount,
    uint8 liqTokenIndex,
    uint256 liqMinAmount,
    uint256 liqDeadline
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// From https://github.com/pouladzade/Seriality/blob/master/src/BytesToTypes.sol (Licensed under Apache2.0)

pragma solidity 0.6.12;

library BytesToTypes {

    function bytesToAddress(uint _offst, bytes memory _input) internal pure returns (address _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint256(uint _offst, bytes memory _input) internal pure returns (uint256 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 
}

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
pragma solidity 0.6.12;

import "./IERC20.sol";

interface ICurveFi {
  function get_virtual_price() external view returns (uint256);
  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);
  function get_dy_underlying(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);
  function coins(int128 arg0) external view returns (address);
  function underlying_coins(int128 arg0) external view returns (address);
  function balances(int128 arg0) external view returns (uint256);

  function add_liquidity(
    uint256[2] calldata amounts,
    uint256 deadline
  ) external;
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy,
    uint256 deadline
  ) external;
  function exchange_underlying(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy,
    uint256 deadline
  ) external;
  function remove_liquidity(
    uint256 _amount,
    uint256 deadline,
    uint256[2] calldata min_amounts
  ) external;
  function remove_liquidity_imbalance(
    uint256[2] calldata amounts,
    uint256 deadline
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interface/ISynapse.sol";
import "../interface/IERC20.sol";
import "../lib/SafeERC20.sol";
import "../lib/SafeMath.sol";
import "../Adapter.sol";

contract SynapseBaseAdapter is Adapter {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant id = keccak256("SynapseBaseAdapter");
    uint256 public constant poolFeeCompliment = 9996; // In bips
    uint256 public constant bips = 1e4;
    mapping(address => bool) public isPoolToken;
    mapping(address => uint8) public tokenIndex;
    uint8 public numberOfTokens = 0;
    address public pool;

    constructor(
        string memory _name,
        address _pool,
        uint256 _swapGasEstimate
    ) public {
        pool = _pool;
        name = _name;
        _setPoolTokens();
        setSwapGasEstimate(_swapGasEstimate);
    }

    // Mapping indicator which tokens are included in the pool
    function _setPoolTokens() internal {
        // Get stables from pool
        for (uint8 i = 0; true; i++) {
            try ISynapse(pool).getToken(i) returns (IERC20 token) {
                isPoolToken[address(token)] = true;
                tokenIndex[address(token)] = i;
                numberOfTokens = numberOfTokens + 1;
            } catch {
                break;
            }
        }
        // Get nUSD from this pool
        (, , , , , , address lpToken) = ISynapse(pool).swapStorage();
        isPoolToken[lpToken] = true;
        numberOfTokens = numberOfTokens + 1;
        tokenIndex[lpToken] = numberOfTokens;
    }

    function setAllowances() public override onlyOwner {}

    function _approveIfNeeded(address _tokenIn, uint256 _amount)
        internal
        override
    {
        uint256 allowance = IERC20(_tokenIn).allowance(address(this), pool);
        if (allowance < _amount) {
            IERC20(_tokenIn).safeApprove(pool, UINT_MAX);
        }
    }

    function _isPaused() internal view returns (bool) {
        return ISynapse(pool).paused();
    }

    function _query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) internal view override returns (uint256) {
        if (
            _amountIn == 0 ||
            _tokenIn == _tokenOut ||
            !isPoolToken[_tokenIn] ||
            !isPoolToken[_tokenOut] ||
            _isPaused()
        ) {
            return 0;
        }
        if (tokenIndex[_tokenIn] != numberOfTokens && tokenIndex[_tokenOut] != numberOfTokens) {
            try
                ISynapse(pool).calculateSwap(
                    tokenIndex[_tokenIn],
                    tokenIndex[_tokenOut],
                    _amountIn
                )
            returns (uint256 amountOut) {
                return amountOut.mul(poolFeeCompliment) / bips;
            } catch {
                return 0;
            }
        } else {
            if (tokenIndex[_tokenOut] == numberOfTokens) {
                uint256[] memory amounts = new uint256[](3);
                amounts[(tokenIndex[_tokenIn])] = _amountIn;
                try ISynapse(pool).calculateTokenAmount(amounts, true) returns (
                    uint256 amountOut
                ) {
                    return amountOut.mul(poolFeeCompliment) / bips;
                } catch {
                    return 0;
                }
            } else if (tokenIndex[_tokenIn] == numberOfTokens) {
                // remove liquidity
                try
                    ISynapse(pool).calculateRemoveLiquidityOneToken(
                        _amountIn,
                        tokenIndex[_tokenOut]
                    )
                returns (uint256 amountOut) {
                    return amountOut.mul(poolFeeCompliment) / bips;
                } catch {
                    return 0;
                }
            } else {
                return 0;
            }
        }
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut,
        address _to
    ) internal override {
        if (tokenIndex[_tokenIn] != numberOfTokens && tokenIndex[_tokenOut] != numberOfTokens) {
            ISynapse(pool).swap(
                tokenIndex[_tokenIn],
                tokenIndex[_tokenOut],
                _amountIn,
                _amountOut,
                block.timestamp
            );
            // Confidently transfer amount-out
            _returnTo(_tokenOut, _amountOut, _to);
        } else {
            // add liquidity
            if (tokenIndex[_tokenOut] == numberOfTokens) {
                uint256[] memory amounts = new uint256[](3);
                amounts[(tokenIndex[_tokenIn])] = _amountIn;

                ISynapse(pool).addLiquidity(
                    amounts,
                    _amountOut,
                    block.timestamp
                );
                _returnTo(_tokenOut, _amountOut, _to);
            }
            if (tokenIndex[_tokenIn] == numberOfTokens) {
                // remove liquidity
                ISynapse(pool).removeLiquidityOneToken(
                    _amountIn,
                    tokenIndex[_tokenOut],
                    _amountOut,
                    block.timestamp
                );
                _returnTo(_tokenOut, _amountOut, _to);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";

interface ISynapse {
    function LP_TOKEN() external view returns (address);
    
    // pool data view functions
    function getA() external view returns (uint256);

    function getToken(uint8 index) external view returns (IERC20);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function paused() external view returns (bool);

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
        external
        view
        returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    function swapStorage()
        external
        view
        returns (
            uint256 initialA,
            uint256 futureA,
            uint256 initialATime,
            uint256 futureATime,
            uint256 swapFee,
            uint256 adminFee,
            address lpToken
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interface/ISynapse.sol";
import "../interface/IERC20.sol";
import "../lib/SafeERC20.sol";
import "../lib/SafeMath.sol";
import "../Adapter.sol";

contract SynapseAaveAdapter is Adapter {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant id = keccak256("SynapseBaseAdapter");
    uint256 public constant poolFeeCompliment = 9996; // In bips
    uint256 public constant bips = 1e4;
    mapping(address => bool) public isPoolToken;
    mapping(address => uint8) public tokenIndex;
    uint8 public numberOfTokens = 0;
    address public pool;

    constructor(
        string memory _name,
        address _pool,
        uint256 _swapGasEstimate
    ) public {
        pool = _pool;
        name = _name;
        _setPoolTokens();
        setSwapGasEstimate(_swapGasEstimate);
    }

    // Mapping indicator which tokens are included in the pool
    function _setPoolTokens() internal {
        // Get stables from pool
        for (uint8 i = 0; true; i++) {
            try ISynapse(pool).getToken(i) returns (IERC20 token) {
                isPoolToken[address(token)] = true;
                tokenIndex[address(token)] = i;
                numberOfTokens = numberOfTokens + 1;
            } catch {
                break;
            }
        }
        // Get nUSD from this pool
        address lpToken = ISynapse(pool).LP_TOKEN();
        isPoolToken[lpToken] = true;
        numberOfTokens = numberOfTokens + 1;
        tokenIndex[lpToken] = numberOfTokens;
    }

    function setAllowances() public override onlyOwner {}

    function _approveIfNeeded(address _tokenIn, uint256 _amount)
        internal
        override
    {
        uint256 allowance = IERC20(_tokenIn).allowance(address(this), pool);
        if (allowance < _amount) {
            IERC20(_tokenIn).safeApprove(pool, UINT_MAX);
        }
    }

    function _isPaused() internal view returns (bool) {
        return ISynapse(pool).paused();
    }

    function _query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) internal view override returns (uint256) {
        if (
            _amountIn == 0 ||
            _tokenIn == _tokenOut ||
            !isPoolToken[_tokenIn] ||
            !isPoolToken[_tokenOut] ||
            _isPaused()
        ) {
            return 0;
        }
        if (tokenIndex[_tokenIn] != numberOfTokens && tokenIndex[_tokenOut] != numberOfTokens) {
            try
                ISynapse(pool).calculateSwap(
                    tokenIndex[_tokenIn],
                    tokenIndex[_tokenOut],
                    _amountIn
                )
            returns (uint256 amountOut) {
                return amountOut.mul(poolFeeCompliment) / bips;
            } catch {
                return 0;
            }
        } else {
            if (tokenIndex[_tokenOut] == numberOfTokens) {
                uint256[] memory amounts = new uint256[](3);
                amounts[(tokenIndex[_tokenIn])] = _amountIn;
                try ISynapse(pool).calculateTokenAmount(amounts, true) returns (
                    uint256 amountOut
                ) {
                    return amountOut.mul(poolFeeCompliment) / bips;
                } catch {
                    return 0;
                }
            } else if (tokenIndex[_tokenIn] == numberOfTokens) {
                // remove liquidity
                try
                    ISynapse(pool).calculateRemoveLiquidityOneToken(
                        _amountIn,
                        tokenIndex[_tokenOut]
                    )
                returns (uint256 amountOut) {
                    return amountOut.mul(poolFeeCompliment) / bips;
                } catch {
                    return 0;
                }
            } else {
                return 0;
            }
        }
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut,
        address _to
    ) internal override {
        if (tokenIndex[_tokenIn] != numberOfTokens && tokenIndex[_tokenOut] != numberOfTokens) {
            ISynapse(pool).swap(
                tokenIndex[_tokenIn],
                tokenIndex[_tokenOut],
                _amountIn,
                _amountOut,
                block.timestamp
            );
            // Confidently transfer amount-out
            _returnTo(_tokenOut, _amountOut, _to);
        } else {
            // add liquidity
            if (tokenIndex[_tokenOut] == numberOfTokens) {
                uint256[] memory amounts = new uint256[](3);
                amounts[(tokenIndex[_tokenIn])] = _amountIn;

                ISynapse(pool).addLiquidity(
                    amounts,
                    _amountOut,
                    block.timestamp
                );
                _returnTo(_tokenOut, _amountOut, _to);
            }
            if (tokenIndex[_tokenIn] == numberOfTokens) {
                // remove liquidity
                ISynapse(pool).removeLiquidityOneToken(
                    _amountIn,
                    tokenIndex[_tokenOut],
                    _amountOut,
                    block.timestamp
                );
                _returnTo(_tokenOut, _amountOut, _to);
            }
        }
    }
}