// File: contracts/interfaces/IHiposwapV2Factory.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

abstract contract IHiposwapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view virtual returns (address);
    function uniswapFactory() external view virtual returns (address);
    function WETH() external pure virtual returns (address);

    function getPair(address tokenA, address tokenB) external view virtual returns (address pair);
    function allPairs(uint) external view virtual returns (address pair);
    function allPairsLength() external view virtual returns (uint);

    function createPair(address tokenA, address tokenB) external virtual returns (address pair);

    function setFeeTo(address) external virtual;
    function setUniswapFactory(address _factory) external virtual;
    
    function getContribution(address tokenA, address tokenB, address tokenMain, address mkAddress) external view virtual returns (address pairAddress, uint contribution);
    
    function getMaxMakerAmount(address tokenA, address tokenB) external view virtual returns (uint amountA, uint amountB);
    function getMaxMakerAmountETH(address token) external view virtual returns (uint amount, uint amountETH);
    function addMaker(address tokenA, address tokenB, uint amountA, uint amountB, address to, uint deadline) external virtual returns (address token, uint amount);
    function addMakerETH(address token, uint amountToken, address to, uint deadline) external payable virtual returns (address _token, uint amount);
    function removeMaker(address tokenA, address tokenB, uint amountA, uint amountB, address to, uint deadline) external virtual returns (uint amount0, uint amount1);
    function removeMakerETH(address token, uint amountToken, uint amountETH, address to, uint deadline) external virtual returns (uint _amountToken, uint _amountETH);
    function removeMakerETHSupportingFeeOnTransferTokens(address token, uint amountToken, uint amountETH, address to, uint deadline) external virtual returns (uint _amountETH);
    
    function collectFees(address tokenA, address tokenB) external virtual;
    function collectFees(address pair) external virtual;
    function setFeePercents(address tokenA, address tokenB, uint _feeAdminPercent, uint _feePercent, uint _totalPercent) external virtual;
    function setFeePercents(address pair, uint _feeAdminPercent, uint _feePercent, uint _totalPercent) external virtual;
}

// File: contracts/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: openzeppelin-solidity/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: openzeppelin-solidity/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract Ownable is Context {
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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: contracts/interfaces/IHiposwapV2Pair.sol

pragma solidity >=0.5.0;

interface IHiposwapV2Pair {
    

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
    event Sync(uint reserve0, uint reserve1);
    event _Maker(address indexed sender, address token, uint amount, uint time);

    
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function currentPoolId0() external view returns (uint);
    function currentPoolId1() external view returns (uint);
    function getMakerPool0(uint poolId) external view returns (uint _balance, uint _swapOut, uint _swapIn);
    function getMakerPool1(uint poolId) external view returns (uint _balance, uint _swapOut, uint _swapIn);
    function getReserves() external view returns (uint reserve0, uint reserve1);
    function getBalance() external view returns (uint _balance0, uint _balance1);
    function getMaker(address mkAddress) external view returns (uint,address,uint,uint);
    function getFees() external view returns (uint _fee0, uint _fee1);
    function getFeeAdmins() external view returns (uint _feeAdmin0, uint _feeAdmin1);
    function getAvgTimes() external view returns (uint _avgTime0, uint _avgTime1);
    function transferFeeAdmin(address to) external;
    function getFeePercents() external view returns (uint _feeAdminPercent, uint _feePercent, uint _totalPercent);
    function setFeePercents(uint _feeAdminPercent, uint _feePercent, uint _totalPercent) external;
    function getRemainPercent() external view returns (uint);
    function getTotalPercent() external view returns (uint);
    
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function order(address to) external returns (address token, uint amount);
    function retrieve(uint amount0, uint amount1, address sender, address to) external returns (uint, uint);
    function getAmountA(address to, uint amountB) external view returns(uint amountA, uint _amountB, uint rewardsB, uint remainA);
    function getAmountB(address to, uint amountA) external view returns(uint _amountA, uint amountB, uint rewardsB, uint remainA);

    function initialize(address, address) external;
}

// File: contracts/libraries/SafeMath.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
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

// File: contracts/libraries/HiposwapV2Library.sol

pragma solidity >=0.5.0;






library HiposwapV2Library {
    using SafeMath for uint;
    
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'HiposwapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'HiposwapV2Library: ZERO_ADDRESS');
    }

    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        
        address pair = pairFor(factory, tokenA, tokenB);
        if (pair == address(0)) {
            return (0, 0);
        }
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    
    // calculates the CREATE2 address for a pair without making any external calls
    function makerPairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'2603bd3b15dbef4d28f9036d8301021d5edc3ae2f073f054721f61b9bf1fa5f3' // init code hash
            ))));
    }
    
    function getMakerReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1) = IHiposwapV2Pair(makerPairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'HiposwapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'HiposwapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }
    
    function getMakerAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint makerReserve, uint remainPercent, uint totalPercent) internal pure returns (uint amountOut) {
        require(amountIn >= 10, 'HiposwapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'HiposwapV2Library: INSUFFICIENT_LIQUIDITY');
        amountOut = getAmountOut(amountIn / 10, reserveIn, reserveOut, remainPercent, totalPercent).mul(10);
        require(amountOut <= makerReserve, 'HiposwapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
    }
    
    // function getMakerAmountsOut(address hipoFactory, address uniFactory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
    //     require(path.length >= 2, 'HiposwapV2Library: INVALID_PATH');
    //     amounts = new uint[](path.length);
    //     amounts[0] = amountIn;
    //     for (uint i; i < path.length - 1; i++) {
    //         (uint reserveIn, uint reserveOut) = getReserves(uniFactory, path[i], path[i + 1]);
    //         (, uint makerReserveOut) = getMakerReserves(hipoFactory, path[i], path[i + 1]);
    //         amounts[i + 1] = getMakerAmountOut(amounts[i], reserveIn, reserveOut, makerReserveOut);
    //     }
    // }
    
    function getMakerAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint makerReserve, uint remainPercent, uint totalPercent) internal pure returns (uint amountIn) {
        require(amountOut >= 10 && amountOut <= makerReserve, 'HiposwapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'HiposwapV2Library: INSUFFICIENT_LIQUIDITY');
        amountIn = getAmountIn(amountOut / 10, reserveIn, reserveOut, remainPercent, totalPercent).sub(1).mul(10).add(1);
    }
    
    // function getMakerAmountsIn(address hipoFactory, address uniFactory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
    //     require(path.length >= 2, 'HiposwapV2Library: INVALID_PATH');
    //     amounts = new uint[](path.length);
    //     amounts[amounts.length - 1] = amountOut;
    //     for (uint i = path.length - 1; i > 0; i--) {
    //         (uint reserveIn, uint reserveOut) = getReserves(uniFactory, path[i - 1], path[i]);
    //         (, uint makerReserveOut) = getMakerReserves(hipoFactory, path[i - 1], path[i]);
    //         amounts[i - 1] = getMakerAmountIn(amounts[i], reserveIn, reserveOut, makerReserveOut);
    //     }
    // }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint remainPercent, uint totalPercent) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'HiposwapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'HiposwapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(remainPercent);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(totalPercent).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint remainPercent, uint totalPercent) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'HiposwapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'HiposwapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(totalPercent);
        uint denominator = reserveOut.sub(amountOut).mul(remainPercent);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    // function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
    //     require(path.length >= 2, 'HiposwapV2Library: INVALID_PATH');
    //     amounts = new uint[](path.length);
    //     amounts[0] = amountIn;
    //     for (uint i; i < path.length - 1; i++) {
    //         (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
    //         amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    //     }
    // }

    // performs chained getAmountIn calculations on any number of pairs
    // function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
    //     require(path.length >= 2, 'HiposwapV2Library: INVALID_PATH');
    //     amounts = new uint[](path.length);
    //     amounts[amounts.length - 1] = amountOut;
    //     for (uint i = path.length - 1; i > 0; i--) {
    //         (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
    //         amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    //     }
    // }
}

// File: contracts/libraries/TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

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

// File: contracts/interfaces/IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
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

// File: contracts/interfaces/IHiposwapV2Util.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

interface IHiposwapV2Util {
    function pairCreationCode() external returns (bytes memory bytecode);
}

// File: contracts/HiposwapV2Factory.sol

// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;









// import './interfaces/IHiposwapV2Factory.sol';
// import './HiposwapV2Pair.sol';
// import "openzeppelin-solidity/contracts/access/Ownable.sol";
// import './libraries/HiposwapV2Library.sol';
// import './libraries/TransferHelper.sol';
// import './interfaces/IWETH.sol';

contract HiposwapV2Factory is IHiposwapV2Factory, Ownable {
    using SafeMath for uint;
    address public override feeTo;
    address public immutable override WETH;
    address public util;
    
    address public override uniswapFactory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _util, address _WETH) public {
        util = _util;
        WETH = _WETH;
    }
    
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) public override returns (address pair) {
        require(tokenA != tokenB, 'HiposwapV2Factory: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'HiposwapV2Factory: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'HiposwapV2Factory: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = IHiposwapV2Util(util).pairCreationCode();
        // bytes memory bytecode = type(HiposwapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IHiposwapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override onlyOwner {
        //require(msg.sender == feeToSetter, 'HiposwapV2Factory: FORBIDDEN');
        feeTo = _feeTo;
    }
    
    function setUniswapFactory(address _factory) external override onlyOwner {
        uniswapFactory = _factory;
    }
    
    function getContribution(address tokenA, address tokenB, address tokenMain, address mkAddress) public view override returns (address pairAddress, uint contribution) {
        require(tokenA == tokenMain || tokenB == tokenMain, "HiposwapV2Factory: INVALID_TOKEN");
        (address token0, ) = HiposwapV2Library.sortTokens(tokenA, tokenB);
        pairAddress = HiposwapV2Library.makerPairFor(address(this), tokenA, tokenB);
        IHiposwapV2Pair pair = IHiposwapV2Pair(pairAddress);
        (uint poolId, address token, uint amount, ) = pair.getMaker(mkAddress);
        uint currentPoolId = token == token0 ? pair.currentPoolId0() : pair.currentPoolId1();
        if (poolId == currentPoolId) {
            if (token == tokenMain) {
                contribution =  amount;
            } else {
                (uint r0, uint r1) = HiposwapV2Library.getReserves(uniswapFactory, token, tokenMain);
                if (r0 > 0) {
                    contribution =  amount.mul(r1) / r0;
                }
            }
        }
    }
    
    // MAKER
    
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'HiposwapV2Factory: EXPIRED');
        _;
    }
    
    function getMaxMakerAmount(address tokenA, address tokenB) public view override returns (uint amountA, uint amountB) {
        (address token0, address token1) = HiposwapV2Library.sortTokens(tokenA, tokenB);
        (uint ur0, uint ur1) = HiposwapV2Library.getReserves(uniswapFactory, token0, token1);
        if (ur0 > 0 && ur1 > 0) {
            uint hr0;
            uint hr1;
            address pair = getPair[tokenA][tokenB];
            if (pair != address(0)) {
                (hr0, hr1) = IHiposwapV2Pair(pair).getReserves();
            }
            uint a0 = hr0 < ur0 / 10 ? (ur0 / 10).sub(hr0) : 0;
            uint a1 = hr1 < ur1 / 10 ? (ur1 / 10).sub(hr1) : 0;
            (amountA, amountB) = tokenA == token0 ? (a0, a1) : (a1, a0);
        }
    }
    
    function getMaxMakerAmountETH(address token) external view override returns (uint amount, uint amountETH) {
        return getMaxMakerAmount(token, WETH);
    }
    
    
    function _addMaker(address tokenA, address tokenB) private{
        require(HiposwapV2Library.pairFor(uniswapFactory, tokenA, tokenB) != address(0), "HiposwapV2Factory: PAIR_NOT_EXISTS_IN_UNISWAP");
        if (getPair[tokenA][tokenB] == address(0)) {
            createPair(tokenA, tokenB);
        }
    }

    function addMaker(address tokenA, address tokenB, uint amountA, uint amountB, address to, uint deadline) external virtual override ensure(deadline) returns (address token, uint amount) {
        _addMaker(tokenA, tokenB);
        require((amountA > 0 && amountB == 0) || (amountA == 0 && amountB > 0), "HiposwapV2Factory: INVALID_AMOUNT");
        address pair = HiposwapV2Library.makerPairFor(address(this), tokenA, tokenB);
        require(pair == getPair[tokenA][tokenB], "HiposwapV2Factory: BAD_INIT_CODE_HASH");
        (address token0, address token1) = HiposwapV2Library.sortTokens(tokenA, tokenB);
        (uint a0, uint a1) = token0 == tokenA ? (amountA, amountB) : (amountB, amountA);
        {// avoid stack too deep
        (uint ur0, uint ur1) = HiposwapV2Library.getReserves(uniswapFactory, token0, token1);
        (uint hr0, uint hr1) = IHiposwapV2Pair(pair).getReserves();
        if (a0 > 0) {
            require(ur0 >= hr0.add(a0).mul(10), "HiposwapV2Factory: AMOUNT_TOO_BIG");
        } else {
            require(ur1 >= hr1.add(a1).mul(10), "HiposwapV2Factory: AMOUNT_TOO_BIG");
        }
        }
        
        if(amountA > 0)TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        if(amountB > 0)TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        return IHiposwapV2Pair(pair).order(to);
    }
    
    function addMakerETH(address token, uint amountToken, address to, uint deadline) external virtual override payable ensure(deadline) returns (address _token, uint amount) {
        _addMaker(token, WETH);
        uint amountETH = msg.value;
        require(amountToken > 0 || amountETH > 0, "HiposwapV2Factory: INVALID_AMOUNT");
        address pair = HiposwapV2Library.makerPairFor(address(this), token, WETH);
        if(amountToken > 0)TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        if(amountETH > 0){
            IWETH(WETH).deposit{value: amountETH}();
            assert(IWETH(WETH).transfer(pair, amountETH));
        }
        return IHiposwapV2Pair(pair).order(to);
    }
    
    function removeMaker(address tokenA, address tokenB, uint amountA, uint amountB, address to, uint deadline)
        public virtual override ensure(deadline) returns (uint amount0, uint amount1) {
        require(getPair[tokenA][tokenB] != address(0), "HiposwapV2Factory: PAIR_NOT_EXISTS");
        require(amountA > 0 || amountB > 0, "HiposwapV2Factory: INVALID_AMOUNT");
        address pair = HiposwapV2Library.makerPairFor(address(this), tokenA, tokenB);
        (address token0, ) = HiposwapV2Library.sortTokens(tokenA, tokenB);
        (amount0, amount1) = tokenA == token0 ? (amountA, amountB) : (amountB, amountA);
        (amount0, amount1) = IHiposwapV2Pair(pair).retrieve(amount0, amount1, msg.sender, to);
        // (bool success, bytes memory returnData) =  pair.delegatecall(abi.encodeWithSelector(IHiposwapV2Pair(pair).retrieve.selector, amount0, amount1, to));
        // assert(success);
        // (amount0, amount1) = abi.decode(returnData, (uint, uint));
        return tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    }
    
    function removeMakerETH(address token, uint amountToken, uint amountETH, address to, uint deadline)
        external virtual override ensure(deadline) returns (uint _amountToken, uint _amountETH) {
        (_amountToken, _amountETH) = removeMaker(token, WETH, amountToken, amountETH, address(this), deadline);
        if(_amountToken > 0)TransferHelper.safeTransfer(token, to, _amountToken);
        if(_amountETH > 0){
            IWETH(WETH).withdraw(_amountETH);
            TransferHelper.safeTransferETH(to, _amountETH);
        }
    }

    function removeMakerETHSupportingFeeOnTransferTokens(address token, uint amountToken, uint amountETH, address to, uint deadline)
        external virtual override ensure(deadline) returns (uint _amountETH) {
        (, _amountETH) = removeMaker(token, WETH, amountToken, amountETH, address(this), deadline);
        uint _amountToken = IERC20(token).balanceOf(address(this));
        if(_amountToken > 0){
            TransferHelper.safeTransfer(token, to, _amountToken);
        }
        if(_amountETH > 0){
            IWETH(WETH).withdraw(_amountETH);
            TransferHelper.safeTransferETH(to, _amountETH);
        }
    }
    
    function collectFees(address tokenA, address tokenB) external override onlyOwner {
        require(feeTo != address(0), 'HiposwapV2Factory: ZERO_ADDRESS');
        address pair = getPair[tokenA][tokenB];
        collectFees(pair);
    }
    
    function collectFees(address pair) public override onlyOwner {
        require(pair != address(0), 'HiposwapV2Factory: PAIR_NOT_EXISTS');
        IHiposwapV2Pair(pair).transferFeeAdmin(feeTo);
    }
    
    function setFeePercents(address tokenA, address tokenB, uint _feeAdminPercent, uint _feePercent, uint _totalPercent) external override onlyOwner {
        address pair = getPair[tokenA][tokenB];
        setFeePercents(pair, _feeAdminPercent, _feePercent, _totalPercent);
    }
    
    function setFeePercents(address pair, uint _feeAdminPercent, uint _feePercent, uint _totalPercent) public override onlyOwner {
        require(pair != address(0), 'HiposwapV2Factory: PAIR_NOT_EXISTS');
        IHiposwapV2Pair(pair).setFeePercents(_feeAdminPercent, _feePercent, _totalPercent);
    }
}