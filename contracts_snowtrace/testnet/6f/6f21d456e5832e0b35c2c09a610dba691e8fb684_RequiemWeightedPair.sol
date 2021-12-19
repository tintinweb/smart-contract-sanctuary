/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-18
*/

// File: contracts/interfaces/IUniswapV2Callee.sol



pragma solidity >=0.5.16;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// File: contracts/interfaces/IRequiemWeightedPairFactory.sol



pragma solidity >=0.8.10;

interface IRequiemWeightedPairFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint32 tokenWeight0, uint32 swapFee, uint256);

    function feeTo() external view returns (address);

    function formula() external view returns (address);

    function protocolFee() external view returns (uint256);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB,
        uint32 tokenWeightA,
        uint32 swapFee
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function isPair(address) external view returns (bool);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        uint32 tokenWeightA,
        uint32 swapFee
    ) external returns (address pair);

    function getWeightsAndSwapFee(address pair)
        external
        view
        returns (
            uint32 tokenWeight0,
            uint32 tokenWeight1,
            uint32 swapFee
        );

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setProtocolFee(uint256) external;
}

// File: contracts/interfaces/ERC20/IERC20.sol



pragma solidity ^0.8.10;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/libraries/UQ112x112.sol



pragma solidity >=0.8.10;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 private constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// File: contracts/libraries/TransferHelper.sol



pragma solidity >=0.8.10;

// solhint-disable avoid-low-level-calls, reason-string

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// File: contracts/libraries/Math.sol



pragma solidity >=0.8.10;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: contracts/interfaces/IRequiemFormula.sol


pragma solidity >=0.8.10;

/*
    Bancor Formula interface
*/
interface IRequiemFormula {

    function getReserveAndWeights(address pair, address tokenA) external view returns (
        address tokenB,
        uint reserveA,
        uint reserveB,
        uint32 tokenWeightA,
        uint32 tokenWeightB,
        uint32 swapFee
    );

    function getFactoryReserveAndWeights(address factory, address pair, address tokenA) external view returns (
        address tokenB,
        uint reserveA,
        uint reserveB,
        uint32 tokenWeightA,
        uint32 tokenWeightB,
        uint32 swapFee
    );

    function getAmountIn(
        uint amountOut,
        uint reserveIn, uint reserveOut,
        uint32 tokenWeightIn, uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint amountIn);

    function getPairAmountIn(address pair, address tokenIn, uint amountOut) external view returns (uint amountIn);

    function getAmountOut(
        uint amountIn,
        uint reserveIn, uint reserveOut,
        uint32 tokenWeightIn, uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint amountOut);

    function getPairAmountOut(address pair, address tokenIn, uint amountIn) external view returns (uint amountOut);

    function getAmountsIn(
        address tokenIn,
        address tokenOut,
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getFactoryAmountsIn(
        address factory,
        address tokenIn,
        address tokenOut,
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsOut(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getFactoryAmountsOut(
        address factory,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function ensureConstantValue(uint reserve0, uint reserve1, uint balance0Adjusted, uint balance1Adjusted, uint32 tokenWeight0) external view returns (bool);
    function getReserves(address pair, address tokenA, address tokenB) external view returns (uint reserveA, uint reserveB);
    function getOtherToken(address pair, address tokenA) external view returns (address tokenB);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);
    function mintLiquidityFee(
        uint totalLiquidity,
        uint112 reserve0,
        uint112  reserve1,
        uint32 tokenWeight0,
        uint32 tokenWeight1,
        uint112  collectedFee0,
        uint112 collectedFee1) external view returns (uint amount);
}

// File: contracts/interfaces/IRequiemSwap.sol



pragma solidity ^0.8.10;

interface IRequiemSwap {
    // this funtion requires the correctly calculated amounts as input
    // the others are supposed to implement that calculation
    // no return value required since the amounts are already known
    function onSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address to
    ) external;

    //
    function onSwapGivenIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external returns (uint256);

    function onSwapGivenOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMax,
        address to
    ) external returns (uint256);

    function calculateSwapGivenIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256);

    function calculateSwapGivenOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external view returns (uint256);
}

// File: contracts/interfaces/IRequiemPairERC20.sol



pragma solidity ^0.8.10;

// solhint-disable func-name-mixedcase

interface IRequiemPairERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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
}

// File: contracts/RequiemPairERC20.sol



pragma solidity ^0.8.10;


// solhint-disable not-rely-on-time, no-inline-assembly, var-name-mixedcase, max-line-length

contract RequiemPairERC20 is IRequiemPairERC20 {

    string public constant name = "Requiem Pair Liquidity Provider";
    string public constant symbol = "RPLP";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"), keccak256(bytes(name)), keccak256(bytes("1")), chainId, address(this))
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "RLP: EXPIRED");
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))));
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "RLP: IS");
        _approve(owner, spender, value);
    }
}

// File: contracts/interfaces/IRequiemWeightedPair.sol



pragma solidity ^0.8.10;


// solhint-disable func-name-mixedcase

interface IRequiemWeightedPair is IRequiemPairERC20 {
    event PaidProtocolFee(uint112 collectedFee0, uint112 collectedFee1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function getCollectedFees() external view returns (uint112 _collectedFee0, uint112 _collectedFee1);

    function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);

    function getSwapFee() external view returns (uint32);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(
        address,
        address,
        uint32,
        uint32
    ) external;
}

// File: contracts/RequiemWeightedPair.sol



pragma solidity ^0.8.10;











// solhint-disable not-rely-on-time, var-name-mixedcase, max-line-length, reason-string, avoid-low-level-calls

contract RequiemWeightedPair is IRequiemSwap, IRequiemWeightedPair, RequiemPairERC20 {
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 private unlocked = 1;
    address public formula;

    uint112 private collectedFee0; // uses single storage slot, accessible via getReserves
    uint112 private collectedFee1; // uses single storage slot, accessible via getReserves

    uint32 private tokenWeight0;
    uint32 private tokenWeight1;
    uint32 private swapFee;

    modifier lock() {
        require(unlocked == 1, "REQLP: L");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function getCollectedFees() public view returns (uint112 _collectedFee0, uint112 _collectedFee1) {
        _collectedFee0 = collectedFee0;
        _collectedFee1 = collectedFee1;
    }

    function getTokenWeights() public view returns (uint32 _tokenWeight0, uint32 _tokenWeight1) {
        _tokenWeight0 = tokenWeight0;
        _tokenWeight1 = tokenWeight1;
    }

    function getSwapFee() public view returns (uint32 _swapFee) {
        _swapFee = swapFee;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "REQLP: TF");
    }

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(
        address _token0,
        address _token1,
        uint32 _tokenWeight0,
        uint32 _swapFee
    ) external {
        require(msg.sender == factory, "REQLP: F");
        // sufficient check
        token0 = _token0;
        token1 = _token1;
        tokenWeight0 = _tokenWeight0;
        tokenWeight1 = 100 - tokenWeight0;
        swapFee = _swapFee;
        formula = IRequiemWeightedPairFactory(factory).formula();
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        uint32 _tokenWeight0 = tokenWeight0;
        require(balance0 * (100 - _tokenWeight0) <= type(uint112).max && balance1 * _tokenWeight0 <= type(uint112).max, "REQLP: O");
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            uint112 mReserve0 = _reserve0 * (100 - _tokenWeight0);
            uint112 mReserve1 = _reserve1 * _tokenWeight0;
            price0CumulativeLast += uint256(UQ112x112.encode(mReserve1).uqdiv(mReserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(mReserve0).uqdiv(mReserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IRequiemWeightedPairFactory(factory).feeTo();
        uint112 protocolFee = uint112(IRequiemWeightedPairFactory(factory).protocolFee());
        feeOn = feeTo != address(0);
        (uint112 _collectedFee0, uint112 _collectedFee1) = getCollectedFees();
        if (protocolFee > 0 && feeOn && (_collectedFee0 > 0 || _collectedFee1 > 0)) {
            uint32 _tokenWeight0 = tokenWeight0;
            uint256 liquidity = IRequiemFormula(formula).mintLiquidityFee(
                totalSupply,
                _reserve0,
                _reserve1,
                _tokenWeight0,
                100 - _tokenWeight0,
                _collectedFee0 / protocolFee,
                _collectedFee1 / protocolFee
            );
            if (liquidity > 0) _mint(feeTo, liquidity);
        }
        if (_collectedFee0 > 0) collectedFee0 = 0;
        if (_collectedFee1 > 0) collectedFee1 = 0;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply;
        // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
            // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min((amount0 * _totalSupply) / _reserve0, (amount1 * _totalSupply) / _reserve1);
        }
        require(liquidity > 0, "REQLP: ILM");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];
        _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (liquidity * balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (liquidity * balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "REQLP: ILB");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata
    ) external lock {
        _swap(amount0Out, amount1Out, to);
    }

    //
    function calculateSwapGivenIn(
        address tokenIn,
        address,
        uint256 amountIn
    ) external view returns (uint256) {
        (uint256 reserveIn, uint256 reserveOut, uint32 tokenWeightIn, uint32 tokenWeightOut) = tokenIn == token0
            ? (reserve0, reserve1, tokenWeight0, tokenWeight1)
            : (reserve1, reserve0, tokenWeight1, tokenWeight0);
        return IRequiemFormula(formula).getAmountOut(amountIn, reserveIn, reserveOut, tokenWeightIn, tokenWeightOut, swapFee);
    }

    function calculateSwapGivenOut(
        address tokenIn,
        address,
        uint256 amountOut
    ) external view returns (uint256) {
        (uint256 reserveIn, uint256 reserveOut, uint32 tokenWeightIn, uint32 tokenWeightOut) = tokenIn == token0
            ? (reserve0, reserve1, tokenWeight0, tokenWeight1)
            : (reserve1, reserve0, tokenWeight1, tokenWeight0);
        return IRequiemFormula(formula).getAmountIn(amountOut, reserveIn, reserveOut, tokenWeightIn, tokenWeightOut, swapFee);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    // calculates output amount for given input and executes the respective trade
    // viable for use in multi swaps as it returns the output value
    // requires the amount in to be sent to this address beforehand
    function onSwapGivenIn(
        address tokenIn,
        address,
        uint256 amountIn,
        uint256,
        address to
    ) external override lock returns (uint256) {
        bool inToken0 = tokenIn == token0;
        (uint256 reserveIn, uint256 reserveOut, uint32 tokenWeightIn, uint32 tokenWeightOut) = inToken0
            ? (reserve0, reserve1, tokenWeight0, tokenWeight1)
            : (reserve1, reserve0, tokenWeight1, tokenWeight0);
        uint256 amountOut = IRequiemFormula(formula).getAmountOut(amountIn, reserveIn, reserveOut, tokenWeightIn, tokenWeightOut, swapFee);
        (uint256 amount0Out, uint256 amount1Out) = inToken0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
        return _swap(amount0Out, amount1Out, to);
    }

    // calculates input amount for given output and executes the respective trade
    // calling this one only makes sense if a single trade is supposd to be executed in the tx
    // requires the amount in to be sent to this address beforehand
    function onSwapGivenOut(
        address tokenIn,
        address,
        uint256 amountOut,
        uint256,
        address to
    ) external override lock returns (uint256) {
        bool inToken0 = tokenIn == token0;
        (uint256 reserveIn, uint256 reserveOut, uint32 tokenWeightIn, uint32 tokenWeightOut) = tokenIn == token0
            ? (reserve0, reserve1, tokenWeight0, tokenWeight1)
            : (reserve1, reserve0, tokenWeight1, tokenWeight0);
        uint256 amountIn = IRequiemFormula(formula).getAmountIn(amountOut, reserveIn, reserveOut, tokenWeightIn, tokenWeightOut, swapFee);
        (uint256 amount0Out, uint256 amount1Out) = inToken0 ? (uint256(0), amountIn) : (amountIn, uint256(0));
        return _swap(amount0Out, amount1Out, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function _swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) internal returns (uint256) {
        require(amount0Out > 0 || amount1Out > 0, "REQLP: IOA");
        uint112 _reserve0 = reserve0; // gas savings
        uint112 _reserve1 = reserve1; // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "REQLP: IL");

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "REQLP: IT");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;

        require(amount0In > 0 || amount1In > 0, "REQLP: IIA");
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0 * 10000;
            uint256 balance1Adjusted = balance1 * 10000;
            {
                // avoids stack too deep errors
                if (amount0In > 0) {
                    uint256 amount0InFee = amount0In * swapFee;
                    balance0Adjusted -= amount0InFee;
                    collectedFee0 = uint112(uint256(collectedFee0) + amount0InFee);
                }
                if (amount1In > 0) {
                    uint256 amount1InFee = amount1In * swapFee;
                    balance1Adjusted -= amount1InFee;
                    collectedFee1 = uint112(uint256(collectedFee1) + amount1InFee);
                }
                uint32 _tokenWeight0 = tokenWeight0; // gas savings
                if (_tokenWeight0 == 50) {
                    // gas savings for pair 50/50
                    require(balance0Adjusted * balance1Adjusted >= uint256(_reserve0) * _reserve1 * (10000**2), "REQLP: K");
                } else {
                    require(IRequiemFormula(formula).ensureConstantValue(uint256(_reserve0) * 10000, uint256(_reserve1) * 10000, balance0Adjusted, balance1Adjusted, _tokenWeight0), "REQLP: K");
                }
            }
        }
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
        return amount0Out > 0 ? amount0Out : amount1Out;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function onSwap(
        address tokenIn,
        address,
        uint256,
        uint256 amountOut,
        address to
    ) external override lock {
        (uint256 amount0Out, uint256 amount1Out) = token0 == tokenIn ? (uint256(0), amountOut) : (amountOut, uint256(0));
        require(amount0Out > 0 || amount1Out > 0, "REQLP: IOA");
        uint112 _reserve0 = reserve0; // gas savings
        uint112 _reserve1 = reserve1; // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "REQLP: IL");

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "REQLP: IT");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;

        require(amount0In > 0 || amount1In > 0, "REQLP: IIA");
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0 * 10000;
            uint256 balance1Adjusted = balance1 * 10000;
            {
                // avoids stack too deep errors
                if (amount0In > 0) {
                    uint256 amount0InFee = amount0In * swapFee;
                    balance0Adjusted -= amount0InFee;
                    collectedFee0 = uint112(uint256(collectedFee0) + amount0InFee);
                }
                if (amount1In > 0) {
                    uint256 amount1InFee = amount1In * swapFee;
                    balance1Adjusted -= amount1InFee;
                    collectedFee1 = uint112(uint256(collectedFee1) + amount1InFee);
                }
                uint32 _tokenWeight0 = tokenWeight0; // gas savings
                if (_tokenWeight0 == 50) {
                    // gas savings for pair 50/50
                    require(balance0Adjusted * balance1Adjusted >= uint256(_reserve0) * _reserve1 * (10000**2), "REQLP: K");
                } else {
                    require(IRequiemFormula(formula).ensureConstantValue(uint256(_reserve0) * 10000, uint256(_reserve1) * 10000, balance0Adjusted, balance1Adjusted, _tokenWeight0), "REQLP: K");
                }
            }
        }
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
}