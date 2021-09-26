/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// File: viralswap/interfaces/IERC20Mintable.sol



pragma solidity >=0.5.0;

interface IERC20Viralswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


pragma solidity >=0.5.0;


interface IERC20ViralswapMintable is IERC20Viralswap {
    function mint(address account, uint256 amount) external;
}

// File: viralswap/interfaces/IUniswapRouter01.sol



pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function VIRAL() external pure returns (address);
    function altRouter() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function quoteVault(address tokenIn, address tokenOut, uint amountIn) external view returns (uint amountOut);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
// File: viralswap/interfaces/IViralswapRouter02.sol



pragma solidity >=0.6.2;


interface IViralswapRouter02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactViralForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForViralSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function buyExactTokensForTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}
// File: viralswap/interfaces/IViralswapVault.sol



pragma solidity >=0.5.0;

interface IViralswapVault {

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
    function tokenIn() external view returns (address);
    function tokenOut() external view returns (address);
    function viralswapRouter02() external view returns (address);
    function availableQuota() external view returns (uint);
    function tokenOutPerTokenIn() external view returns (uint);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function getQuote(address _tokenIn, uint _amountIn) external view returns (uint amountOut);

    function buy(uint amountOut, address to) external;
    function sync() external;

    function initialize(address, address) external;
    function addQuota(uint) external;
}
// File: viralswap/interfaces/IViralswapPair.sol



pragma solidity >=0.5.0;

interface IViralswapPair {
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
// File: viralswap/libraries/ViralswapLibrary.sol



pragma solidity >=0.5.0;




library ViralswapLibrary {
    using SafeMathViralswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'ViralswapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ViralswapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        // pair = IViralswapFactory(factory).getPair(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'd1d5b10d6c13b56711918c86096b714c0907fa2f9c136645d1dfcdee49d2094e' // init code hash
            ))));
    }

    // calculates the CREATE2 address for a vault without making any external calls
    function vaultFor(address factory, address tokenA, address tokenB) internal pure returns (address vault) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        // vault = IViralswapFactory(factory).getVault(tokenA, tokenB);
        vault = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'9d37be631483859cc31ba72b9fa6bec30467e0dc3a87c1c4baeb76f5facc55d2' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IViralswapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'ViralswapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'ViralswapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset, return the quoted output amount of the other asset
    function quoteVault(address factory, address tokenIn, address tokenOut, uint amountIn) internal view returns (uint amountOut) {
        amountOut = IViralswapVault(vaultFor(factory, tokenIn, tokenOut)).getQuote(tokenIn, amountIn);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'ViralswapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ViralswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'ViralswapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ViralswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'ViralswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'ViralswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: viralswap/ViralswapVault.sol



pragma solidity =0.6.12;

/*
BEGIN KEYBASE SALTPACK SIGNED MESSAGE. kXR7VktZdyH7rvq v5weRa0zkYfegFM 5cM6gB7cyPatQvp 6KyygX8PsvQVo4n Ugo6Il5bm6R9KJH KEkg77qc0o0lY6W yvqrtLgZxgKJVAH FTy5ayHJfkisnFM Shi7gaWAfQezYkC M1U9mZfY9OhthMn VhuwjWDrIqu8IaO mBL830YhemOeyZ9 0sNJhblIzLSskfq ii978jFlUJwCtMI 3dKs4NZuJkhW86Q F0ZdHRWO9lUnhvJ Uge2AAymBbtvrmx Z6QE88Wuj10K5wV 96BePfhF27S. END KEYBASE SALTPACK SIGNED MESSAGE.
*/







/**
 * @dev Implementation of the VIRAL Vault.
 *
 * ViralSwap Vault supports a fixed price buying of tokenOut when sent tokenIn.
 * 
 * The tokenIn recieved are then used to add liquidity to the corresponding ViralSwap Pair.
 * The Vault does not hold tokenOut, they're minted each time a buy is made (the Vault MUST have the ability to mint tokens).
 */
contract ViralswapVault {
    using SafeMathViralswap for uint;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public tokenIn;
    address public tokenOut;
    address public viralswapRouter02;

    uint256 public availableQuota;
    uint256 public tokenOutPerTokenIn;

    uint112 private reserveIn;           // uses single storage slot, accessible via getReserves
    uint112 private reserveOut;          // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'Viralswap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserveIn, uint112 _reserveOut, uint32 _blockTimestampLast) {
        _reserveIn = reserveIn;
        _reserveOut = reserveOut;
        _blockTimestampLast = blockTimestampLast;
    }

    function getQuote(address _tokenIn, uint _amountIn) external view returns (uint amountOut) {
        if(_tokenIn == tokenIn) {
            return _amountIn.mul(tokenOutPerTokenIn);
        }
        return 0;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Viralswap: TRANSFER_FAILED');
    }

    event Swap(address indexed sender,uint amountIn,uint amountOut,address indexed to);
    event Sync(uint112 reserveIn, uint112 reserveOut);
    event AddQuota(uint quota);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at the time of deployment
    function initialize(uint _tokenOutPerTokenIn, address _tokenIn, address _tokenOut, address _viralswapRouter02) external {
        require(msg.sender == factory, 'Viralswap: FORBIDDEN'); // sufficient check
        tokenOutPerTokenIn = _tokenOutPerTokenIn;
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        viralswapRouter02 = _viralswapRouter02;
    }

    // called by factory to update the ViralRouter address
    function updateRouter(address _viralswapRouter02) external {
        require(msg.sender == factory, 'Viralswap: FORBIDDEN'); // sufficient check
        viralswapRouter02 = _viralswapRouter02;
    }

    // called by factory to add minting quota for tokenOut
    function addQuota(uint quota) external {
        require(msg.sender == factory, 'Viralswap: FORBIDDEN'); // sufficient check
        availableQuota = availableQuota.add(quota);
        emit AddQuota(quota);
    }

    function withdrawERC20(address _token, address _to) external {
        require(msg.sender == factory, 'Viralswap: FORBIDDEN'); // sufficient check
        uint256 balance = IERC20Viralswap(_token).balanceOf(address(this));
        IERC20Viralswap(_token).transfer(_to, balance);
        _update();
    }

    // called by self to mint tokenOut
    function _mint(uint _amount) private {
        require(availableQuota >= _amount, 'Viralswap: INSUFFICIENT_QUOTA_AVAILABLE');
        availableQuota = availableQuota.sub(_amount);
        IERC20ViralswapMintable(tokenOut).mint(address(this), _amount);
    }

    // update reserves to match current balances
    function _update() private {
        uint256 balanceIn = IERC20Viralswap(tokenIn).balanceOf(address(this));
        uint256 balanceOut = IERC20Viralswap(tokenOut).balanceOf(address(this));
        require(balanceIn <= uint112(-1) && balanceOut <= uint112(-1), 'Viralswap: OVERFLOW');
        reserveIn = uint112(balanceIn);
        reserveOut = uint112(balanceOut);
        blockTimestampLast = uint32(block.timestamp % 2**32);
        emit Sync(reserveIn, reserveOut);
    }

    function _addLiquidity(uint amountInDesired, uint amountOutDesired) private {
        IERC20Viralswap(tokenIn).approve(viralswapRouter02, amountInDesired);
        IERC20Viralswap(tokenOut).approve(viralswapRouter02, amountOutDesired);

        IViralswapRouter02(viralswapRouter02).addLiquidity(
            tokenIn,
            tokenOut,
            amountInDesired,
            amountOutDesired,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    // this low-level function should be called from a contract which performs important safety checks
    // What actually is happening in the function:
    //  - calculate amount of tokenIn sent to the vault, check if it is atleast the expected amount, refund excess
    //  - calculate the tokenOut needed to add to liquidity
    //  - mint the required amount of tokenOut (buy + liquidity)
    //  - transfer tokenOut to the `to` address
    //  - add liquidity to the corresponding pair
    //  - update reserves
    function buy(uint amountOut, address to) external lock {
        require(msg.sender == viralswapRouter02, "Viralswap: FORBIDDEN");
        require(amountOut > tokenOutPerTokenIn, 'Viralswap: INSUFFICIENT_OUTPUT_AMOUNT');

        (uint112 _reserveIn,,) = getReserves();

        uint balanceIn = IERC20Viralswap(tokenIn).balanceOf(address(this));
        uint amountIn = balanceIn.sub(_reserveIn);
        uint amountInExpected = amountOut / tokenOutPerTokenIn;
        require(amountIn >= amountInExpected, 'Viralswap: INSUFFICIENT_INPUT_AMOUNT');

        if(amountIn > amountInExpected) {
            _safeTransfer(tokenIn, to, amountIn.sub(amountInExpected));
        }

        (uint swapReserveIn, uint swapReserveOut) = ViralswapLibrary.getReserves(factory, tokenIn, tokenOut);
        uint amountOutOptimal = ViralswapLibrary.quote(amountInExpected, swapReserveIn, swapReserveOut);
        _mint(amountOut.add(amountOutOptimal));

        _safeTransfer(tokenOut, to, amountOut);
        _addLiquidity(amountInExpected, amountOutOptimal);
        _update();
        emit Swap(msg.sender, amountInExpected, amountOut, to);
    }

    // force reserves to match balances
    function sync() external lock {
        _update();
    }
}

// File: viralswap/interfaces/IViralswapCallee.sol



pragma solidity >=0.5.0;

interface IViralswapCallee {
    function viralswapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// File: viralswap/interfaces/IERC20.sol


// File: viralswap/libraries/UQ112x112.sol



pragma solidity =0.6.12;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// File: viralswap/libraries/Math.sol



pragma solidity =0.6.12;

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

// File: viralswap/libraries/SafeMath.sol



pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathViralswap {
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

// File: viralswap/ViralswapERC20.sol



pragma solidity =0.6.12;


contract ViralswapERC20 {
    using SafeMathViralswap for uint;

    string public constant name = 'ViralSwap LP Token';
    string public constant symbol = 'VLP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'Viralswap: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Viralswap: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// File: viralswap/ViralswapPair.sol



pragma solidity =0.6.12;







interface IMigrator {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}

contract ViralswapPair is ViralswapERC20 {
    using SafeMathViralswap  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Viralswap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Viralswap: TRANSFER_FAILED');
    }

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

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'Viralswap: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'Viralswap: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IViralswapFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20Viralswap(token0).balanceOf(address(this));
        uint balance1 = IERC20Viralswap(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            address migrator = IViralswapFactory(factory).migrator();
            if (msg.sender == migrator) {
                liquidity = IMigrator(migrator).desiredLiquidity();
                require(liquidity > 0 && liquidity != uint256(-1), "Bad desired liquidity");
            } else {
                require(migrator == address(0), "Must not have migrator");
                liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
                _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            }
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'Viralswap: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20Viralswap(_token0).balanceOf(address(this));
        uint balance1 = IERC20Viralswap(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'Viralswap: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20Viralswap(_token0).balanceOf(address(this));
        balance1 = IERC20Viralswap(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'Viralswap: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Viralswap: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'Viralswap: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IViralswapCallee(to).viralswapCall(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20Viralswap(_token0).balanceOf(address(this));
        balance1 = IERC20Viralswap(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'Viralswap: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'Viralswap: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20Viralswap(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20Viralswap(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20Viralswap(token0).balanceOf(address(this)), IERC20Viralswap(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}

// File: viralswap/interfaces/IViralswapFactory.sol



pragma solidity >=0.5.0;

interface IViralswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function getVault(address tokenA, address tokenB) external view returns (address vault);
    function allVaults(uint) external view returns (address vault);
    function allVaultsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function createVault(uint tokenOutPerTokenIn, address tokenIn, address tokenOut, address router) external returns (address vault);

    function addQuota(address tokenA, address tokenB, uint quota) external;
    function updateRouterInVault(address tokenA, address tokenB, address _viralswapRouter02) external;
    function withdrawERC20FromVault(address tokenA, address tokenB, address tokenToWithdraw, address to) external;

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// File: viralswap/ViralswapFactory.sol



pragma solidity =0.6.12;




contract ViralswapFactory is IViralswapFactory {
    address public override feeTo;
    address public override feeToSetter;
    address public override migrator;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    mapping(address => mapping(address => address)) public override getVault;
    address[] public override allVaults;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event VaultCreated(address indexed tokenIn, address indexed tokenOut, address vault, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function allVaultsLength() external override view returns (uint) {
        return allVaults.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(ViralswapPair).creationCode);
    }

    function vaultCodeHash() external pure returns (bytes32) {
        return keccak256(type(ViralswapVault).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'Viralswap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Viralswap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Viralswap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(ViralswapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ViralswapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /**
     * @dev Function to create a VIRAL Vault for the specified tokens.
     *
     * @param tokenOutPerTokenIn : number of tokenOut to distribute per tokenIn
     * @param tokenIn : the input token address
     * @param tokenOut : the output token address
     * @param router : address of the ViralSwap router
    **/
    function createVault(uint tokenOutPerTokenIn, address tokenIn, address tokenOut, address router) external override returns (address vault) {
        require(msg.sender == feeToSetter, 'Viralswap: FORBIDDEN');
        require(tokenIn != tokenOut, 'Viralswap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenIn < tokenOut ? (tokenIn, tokenOut) : (tokenOut, tokenIn);
        require(token0 != address(0), 'Viralswap: ZERO_ADDRESS');
        require(getVault[token0][token1] == address(0), 'Viralswap: VAULT_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(ViralswapVault).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ViralswapVault(vault).initialize(tokenOutPerTokenIn, tokenIn, tokenOut, router);
        getVault[token0][token1] = vault;
        getVault[token1][token0] = vault; // populate mapping in the reverse direction
        allVaults.push(vault);
        emit VaultCreated(tokenIn, tokenOut, vault, allVaults.length);
    }

    /**
     * @dev Function to increase the minting quota for the VIRAL Vault for the specified tokens.
     *
     * @param tokenA : the first token address
     * @param tokenB : the second token address
     * @param quota : the minting quota to add
    **/
    function addQuota(address tokenA, address tokenB, uint quota) external override {
        require(msg.sender == feeToSetter, 'Viralswap: FORBIDDEN');
        address vault = getVault[tokenA][tokenB];
        require(vault != address(0), 'Viralswap: VAULT_DOES_NOT_EXIST');
        ViralswapVault(vault).addQuota(quota);
    }

    /**
     * @dev Function to update the router address for the VIRAL Vault for the specified tokens.
     *
     * @param tokenA : the first token address
     * @param tokenB : the second token address
     * @param _viralswapRouter02 : the new router address
    **/
    function updateRouterInVault(address tokenA, address tokenB, address _viralswapRouter02) external override {
        require(msg.sender == feeToSetter, 'Viralswap: FORBIDDEN');
        address vault = getVault[tokenA][tokenB];
        require(vault != address(0), 'Viralswap: VAULT_DOES_NOT_EXIST');
        ViralswapVault(vault).updateRouter(_viralswapRouter02);
    }

    function withdrawERC20FromVault(address tokenA, address tokenB, address tokenToWithdraw, address to) external override {
        require(msg.sender == feeToSetter, 'Viralswap: FORBIDDEN');
        address vault = getVault[tokenA][tokenB];
        require(vault != address(0), 'Viralswap: VAULT_DOES_NOT_EXIST');
        ViralswapVault(vault).withdrawERC20(tokenToWithdraw, to);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'Viralswap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setMigrator(address _migrator) external override {
        require(msg.sender == feeToSetter, 'Viralswap: FORBIDDEN');
        migrator = _migrator;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'Viralswap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

}