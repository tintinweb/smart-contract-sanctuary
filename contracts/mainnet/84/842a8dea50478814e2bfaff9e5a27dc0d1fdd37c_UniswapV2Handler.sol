// File: contracts/interfaces/IERC20.sol


pragma solidity ^0.6.8;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts/interfaces/IWETH.sol


pragma solidity ^0.6.8;



interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

// File: contracts/interfaces/IHandler.sol

pragma solidity ^0.6.8;


interface IHandler {
    /// @notice receive ETH
    receive() external payable;

    /**
     * @notice Handle an order execution
     * @param _inputToken - Address of the input token
     * @param _outputToken - Address of the output token
     * @param _inputAmount - uint256 of the input token amount
     * @param _minReturn - uint256 of the min return amount of output token
     * @param _data - Bytes of arbitrary data
     * @return bought - Amount of output token bought
     */
    function handle(
        IERC20 _inputToken,
        IERC20 _outputToken,
        uint256 _inputAmount,
        uint256 _minReturn,
        bytes calldata _data
    ) external payable returns (uint256 bought);

    /**
     * @notice Check whether can handle an order execution
     * @param _inputToken - Address of the input token
     * @param _outputToken - Address of the output token
     * @param _inputAmount - uint256 of the input token amount
     * @param _minReturn - uint256 of the min return amount of output token
     * @param _data - Bytes of arbitrary data
     * @return bool - Whether the execution can be handled or not
     */
    function canHandle(
        IERC20 _inputToken,
        IERC20 _outputToken,
        uint256 _inputAmount,
        uint256 _minReturn,
        bytes calldata _data
    ) external view returns (bool);
}

// File: contracts/interfaces/uniswapV2/IUniswapV2Pair.sol


pragma solidity >0.5.8;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);


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

// File: contracts/libs/SafeMath.sol


pragma solidity ^0.6.8;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/libs/UniswapUtils.sol


pragma solidity ^0.6.8;



library UniswapUtils {
    using SafeMath for uint256;

    /**
     * @notice Returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
     * @return uint32 - block timestamp
     */
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    /**
     * @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order
     * @param _tokenA - Address of the token A
     * @param _tokenB - Address of the token B
     * @return token0 - Address of the lower token
     * @return token1 - Address of the higher token
     */
    function sortTokens(address _tokenA, address _tokenB) internal pure returns (address token0, address token1) {
        require(_tokenA != _tokenB, 'UniswapUtils#sortTokens: IDENTICAL_ADDRESSES');
        (token0, token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        require(token0 != address(0), 'UniswapUtils#sortTokens: ZERO_ADDRESS');
    }

    /**
     * @notice Calculates the CREATE2 address for a pair without making any external calls
     * @param _factory - Address of the uniswapV2 factory contract
     * @param _tokenA - Address of the token A
     * @param _tokenB - Address of the token B
     * @param _initCodeHash - Bytes32 of the uniswap v2 pair contract unit code hash
     * @return pair - Address of the pair
     */
    function pairFor(address _factory, address _tokenA, address _tokenB, bytes32 _initCodeHash) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(_tokenA, _tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                _factory,
                keccak256(abi.encodePacked(token0, token1)),
                _initCodeHash // init code hash
            ))));
    }

    /**
     * @notice Calculates the CREATE2 address for a pair without making any external calls
     * @dev Tokens should be in order
     * @param _factory - Address of the uniswapV2 factory contract
     * @param _token0 - Address of the token 0
     * @param _token1 - Address of the token 1
     * @param _initCodeHash - Bytes32 of the uniswap v2 pair contract unit code hash
     * @return pair - Address of the pair
     */
    function pairForSorted(address _factory, address _token0, address _token1, bytes32 _initCodeHash) internal pure returns (address pair) {
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                _factory,
                keccak256(abi.encodePacked(_token0, _token1)),
                _initCodeHash // init code hash
            ))));
    }

    /**
     * @notice Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
     * @param _amountIn - uint of the input token's amount
     * @param _reserveIn - uint of the input token's reserve
     * @param _reserveOut - uint of the output token's reserve
     * @return amountOut - Maximum output amount
     */
    function getAmountOut(uint _amountIn, uint _reserveIn, uint _reserveOut) internal pure returns (uint amountOut) {
        require(_amountIn > 0, 'UniswapUtils#getAmountOut: INSUFFICIENT_INPUT_AMOUNT');
        require(_reserveIn > 0 && _reserveOut > 0, 'UniswapUtils#getAmountOut: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = _amountIn.mul(997);
        uint numerator = amountInWithFee.mul(_reserveOut);
        uint denominator = _reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
}

// File: contracts/libs/SafeERC20.sol


pragma solidity ^0.6.8;



library SafeERC20 {
    function transfer(IERC20 _token, address _to, uint256 _val) internal returns (bool) {
        (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(_token.transfer.selector, _to, _val));
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }
}

// File: contracts/libs/PineUtils.sol


pragma solidity ^0.6.8;




library PineUtils {
    address internal constant ETH_ADDRESS = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    /**
     * @notice Get the account's balance of token or ETH
     * @param _token - Address of the token
     * @param _addr - Address of the account
     * @return uint256 - Account's balance of token or ETH
     */
    function balanceOf(IERC20 _token, address _addr) internal view returns (uint256) {
        if (ETH_ADDRESS == address(_token)) {
            return _addr.balance;
        }

        return _token.balanceOf(_addr);
    }

     /**
     * @notice Transfer token or ETH to a destinatary
     * @param _token - Address of the token
     * @param _to - Address of the recipient
     * @param _val - Uint256 of the amount to transfer
     * @return bool - Whether the transfer was success or not
     */
    function transfer(IERC20 _token, address _to, uint256 _val) internal returns (bool) {
        if (ETH_ADDRESS == address(_token)) {
            (bool success, ) = _to.call{value:_val}("");
            return success;
        }

        return SafeERC20.transfer(_token, _to, _val);
    }
}

// File: contracts/handlers/UniswapV2Handler.sol


pragma solidity ^0.6.8;









/// @notice UniswapV2 Handler used to execute an order
contract UniswapV2Handler is IHandler {
    using SafeMath for uint256;

    IWETH public immutable WETH;
    address public immutable FACTORY;
    bytes32 public immutable FACTORY_CODE_HASH;

    /**
     * @notice Creates the handler
     * @param _factory - Address of the uniswap v2 factory contract
     * @param _weth - Address of WETH contract
     * @param _codeHash - Bytes32 of the uniswap v2 pair contract unit code hash
     */
    constructor(address _factory, IWETH _weth, bytes32 _codeHash) public {
        FACTORY = _factory;
        WETH = _weth;
        FACTORY_CODE_HASH = _codeHash;
    }

    /// @notice receive ETH
    receive() external override payable {
        require(msg.sender != tx.origin, "UniswapV2Handler#receive: NO_SEND_ETH_PLEASE");
    }

    /**
     * @notice Handle an order execution
     * @param _inputToken - Address of the input token
     * @param _outputToken - Address of the output token
     * @param _data - Bytes of arbitrary data
     * @return bought - Amount of output token bought
     */
    function handle(
        IERC20 _inputToken,
        IERC20 _outputToken,
        uint256,
        uint256,
        bytes calldata _data
    ) external payable override returns (uint256 bought) {
         // Load real initial balance, don't trust provided value
        uint256 amount = PineUtils.balanceOf(_inputToken, address(this));
        address inputToken = address(_inputToken);
        address outputToken = address(_outputToken);
        address weth = address(WETH);

        // Decode extra data
        (,address relayer, uint256 fee) = abi.decode(_data, (address, address, uint256));

        if (inputToken == weth || inputToken == PineUtils.ETH_ADDRESS) {
            // Swap WETH -> outputToken
            amount = amount.sub(fee);

            // Convert from ETH to WETH if necessary
            if (inputToken == PineUtils.ETH_ADDRESS) {
                WETH.deposit{ value: amount }();
                inputToken = weth;
            } else {
                WETH.withdraw(fee);
            }

            // Trade
            bought = _swap(inputToken, outputToken, amount, msg.sender);
        } else if (outputToken == weth || outputToken == PineUtils.ETH_ADDRESS) {
            // Swap inputToken -> WETH
            bought = _swap(inputToken, weth, amount, address(this));

            // Convert from WETH to ETH if necessary
            if (outputToken == PineUtils.ETH_ADDRESS) {
                WETH.withdraw(bought);
            } else {
                WETH.withdraw(fee);
            }

            // Transfer amount to sender
            bought = bought.sub(fee);
            PineUtils.transfer(IERC20(outputToken), msg.sender, bought);
        } else {
            // Swap inputToken -> WETH -> outputToken
            //  - inputToken -> WETH
            bought = _swap(inputToken, weth, amount, address(this));

            // Withdraw fee
            WETH.withdraw(fee);

            // - WETH -> outputToken
            bought = _swap(weth, outputToken, bought.sub(fee), msg.sender);
        }

        // Send fee to relayer
        (bool successRelayer,) = relayer.call{value: fee}("");
        require(successRelayer, "UniswapV2Handler#handle: TRANSFER_ETH_TO_RELAYER_FAILED");
    }

    /**
     * @notice Check whether can handle an order execution
     * @param _inputToken - Address of the input token
     * @param _outputToken - Address of the output token
     * @param _inputAmount - uint256 of the input token amount
     * @param _minReturn - uint256 of the min return amount of output token
     * @param _data - Bytes of arbitrary data
     * @return bool - Whether the execution can be handled or not
     */
    function canHandle(
        IERC20 _inputToken,
        IERC20 _outputToken,
        uint256 _inputAmount,
        uint256 _minReturn,
        bytes calldata _data
    ) external override view returns (bool) {
        address inputToken = address(_inputToken);
        address outputToken = address(_outputToken);
        address weth = address(WETH);

        // Decode extra data
        (,, uint256 fee) = abi.decode(_data, (address, address, uint256));

        if (inputToken == weth || inputToken == PineUtils.ETH_ADDRESS) {
            if (_inputAmount <= fee) {
                 return false;
            }

            return _estimate(weth, outputToken, _inputAmount.sub(fee)) >= _minReturn;
        } else if (outputToken == weth || outputToken == PineUtils.ETH_ADDRESS) {
            uint256 bought = _estimate(inputToken, weth, _inputAmount);

            if (bought <= fee) {
                 return false;
            }

            return bought.sub(fee) >= _minReturn;
        } else {
            uint256 bought = _estimate(inputToken, weth, _inputAmount);
            if (bought <= fee) {
                return false;
            }

            return _estimate(weth, outputToken, bought.sub(fee)) >= _minReturn;
        }
    }

    /**
     * @notice Simulate an order execution
     * @param _inputToken - Address of the input token
     * @param _outputToken - Address of the output token
     * @param _inputAmount - uint256 of the input token amount
     * @param _minReturn - uint256 of the min return amount of output token
     * @param _data - Bytes of arbitrary data
     * @return bool - Whether the execution can be handled or not
     * @return uint256 - Amount of output token bought
     */
    function simulate(
        IERC20 _inputToken,
        IERC20 _outputToken,
        uint256 _inputAmount,
        uint256 _minReturn,
        bytes calldata _data
    ) external view returns (bool, uint256) {
        address inputToken = address(_inputToken);
        address outputToken = address(_outputToken);
        address weth = address(WETH);

        // Decode extra data
        (,, uint256 fee) = abi.decode(_data, (address, address, uint256));

        uint256 bought;

        if (inputToken == weth || inputToken == PineUtils.ETH_ADDRESS) {
            if (_inputAmount <= fee) {
                return (false, 0);
            }

            bought = _estimate(weth, outputToken, _inputAmount.sub(fee));
        } else if (outputToken == weth || outputToken == PineUtils.ETH_ADDRESS) {
            bought = _estimate(inputToken, weth, _inputAmount);
            if (bought <= fee) {
                 return (false, 0);
            }

            bought = bought.sub(fee);
        } else {
            bought = _estimate(inputToken, weth, _inputAmount);
            if (bought <= fee) {
                return (false, 0);
            }

            bought = _estimate(weth, outputToken, bought.sub(fee));
        }
        return (bought >= _minReturn, bought);
    }

    /**
     * @notice Estimate output token amount
     * @param _inputToken - Address of the input token
     * @param _outputToken - Address of the output token
     * @param _inputAmount - uint256 of the input token amount
     * @return bought - Amount of output token bought
     */
    function _estimate(address _inputToken, address _outputToken, uint256 _inputAmount) internal view returns (uint256 bought) {
        // Get uniswap trading pair
        (address token0, address token1) = UniswapUtils.sortTokens(_inputToken, _outputToken);
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapUtils.pairForSorted(FACTORY, token0, token1, FACTORY_CODE_HASH));

        // Compute limit for uniswap trade
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        // Optimal amounts for uniswap trade
        uint256 reserveIn; uint256 reserveOut;
        if (_inputToken == token0) {
            reserveIn = reserve0;
            reserveOut = reserve1;
        } else {
            reserveIn = reserve1;
            reserveOut = reserve0;
        }

        bought = UniswapUtils.getAmountOut(_inputAmount, reserveIn, reserveOut);
    }

    /**
     * @notice Swap input token to output token
     * @param _inputToken - Address of the input token
     * @param _outputToken - Address of the output token
     * @param _inputAmount - uint256 of the input token amount
     * @param _recipient - Address of the recipient
     * @return bought - Amount of output token bought
     */
    function _swap(address _inputToken, address _outputToken, uint256 _inputAmount, address _recipient) internal returns (uint256 bought) {
        // Get uniswap trading pair
        (address token0, address token1) = UniswapUtils.sortTokens(_inputToken, _outputToken);
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapUtils.pairForSorted(FACTORY, token0, token1, FACTORY_CODE_HASH));

        // Send tokens to uniswap pair
        require(SafeERC20.transfer(IERC20(_inputToken), address(pair), _inputAmount), "UniswapV2Handler#_swap: ERROR_SENDING_TOKENS");

        // Get current reserves
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        // Optimal amounts for uniswap trade
        {
            uint256 reserveIn; uint256 reserveOut;
            if (_inputToken == token0) {
                reserveIn = reserve0;
                reserveOut = reserve1;
            } else {
                reserveIn = reserve1;
                reserveOut = reserve0;
            }
            bought = UniswapUtils.getAmountOut(_inputAmount, reserveIn, reserveOut);
        }

        // Determine if output amount is token1 or token0
        uint256 amount1Out; uint256 amount0Out;
        if (_inputToken == token0) {
            amount1Out = bought;
        } else {
            amount0Out = bought;
        }

        // Execute swap
        pair.swap(amount0Out, amount1Out, _recipient, bytes(""));
    }
}