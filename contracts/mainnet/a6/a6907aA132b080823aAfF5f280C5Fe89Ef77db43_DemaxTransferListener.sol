// Dependency file: contracts/libraries/SafeMath.sol

// pragma solidity >=0.5.0;

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

// Dependency file: contracts/libraries/DemaxSwapLibrary.sol

// pragma solidity >=0.5.0;

// import '../interfaces/IDemaxPair.sol';
// import '../interfaces/IDemaxFactory.sol';
// import "./SafeMath.sol";

library DemaxSwapLibrary {
    using SafeMath for uint;

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'DemaxSwapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'DemaxSwapLibrary: ZERO_ADDRESS');
    }

     function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        bytes32 rawAddress = keccak256(
         abi.encodePacked(
            bytes1(0xff),
            factory,
            salt,
            IDemaxFactory(factory).contractCodeHash()
            )
        );
     return address(bytes20(rawAddress << 96));
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IDemaxPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    
    function quoteEnhance(address factory, address tokenA, address tokenB, uint amountA) internal view returns(uint amountB) {
        (uint reserveA, uint reserveB) = getReserves(factory, tokenA, tokenB);
        return quote(amountA, reserveA, reserveB);
    }

    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'DemaxSwapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'DemaxSwapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'DemaxSwapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'DemaxSwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = amountIn.mul(reserveOut);
        uint denominator = reserveIn.add(amountIn);
        amountOut = numerator / denominator;
    }
    
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'DemaxSwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'DemaxSwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut);
        uint denominator = reserveOut.sub(amountOut);
        amountIn = (numerator / denominator).add(1);
    }

}
// Dependency file: contracts/interfaces/IDemaxPair.sol

// pragma solidity >=0.5.0;

interface IDemaxPair {
  
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
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address from, address to, uint amount) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address tokenA, address tokenB, address platform, address dgas) external;
    function swapFee(uint amount, address token, address to) external ;
    function queryReward() external view returns (uint rewardAmount, uint blockNumber);
    function mintReward() external returns (uint rewardAmount);
    function getDGASReserve() external view returns (uint);
}

// Dependency file: contracts/interfaces/IERC20.sol

// pragma solidity >=0.5.0;

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

// Dependency file: contracts/interfaces/IDemaxFactory.sol

// pragma solidity >=0.5.0;

interface IDemaxFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function contractCodeHash() external view returns (bytes32);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function isPair(address pair) external view returns (bool);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function playerPairs(address player, uint index) external view returns (address pair);
    function getPlayerPairCount(address player) external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function addPlayerPair(address player, address _pair) external returns (bool);
}

// Dependency file: contracts/interfaces/IDgas.sol

// pragma solidity >=0.5.0;

interface IDgas {
    function amountPerBlock() external view returns (uint);
    function changeAmountPerBlock(uint value) external returns (bool);
    function getProductivity(address user) external view returns (uint, uint);
    function increaseProductivity(address user, uint value) external returns (bool);
    function decreaseProductivity(address user, uint value) external returns (bool);
    function take() external view returns (uint);
    function takes() external view returns (uint, uint);
    function mint() external returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function upgradeImpl(address _newImpl) external;
    function upgradeGovernance(address _newGovernor) external;
}
// Dependency file: contracts/modules/Ownable.sol

// pragma solidity >=0.5.16;

contract Ownable {
    address public owner;

    event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: FORBIDDEN');
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), 'Ownable: INVALID_ADDRESS');
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.6;
// import './modules/Ownable.sol';
// import './interfaces/IDgas.sol';
// import './interfaces/IDemaxFactory.sol';
// import './interfaces/IERC20.sol';
// import './interfaces/IDemaxPair.sol';
// import './libraries/DemaxSwapLibrary.sol';
// import './libraries/SafeMath.sol';

contract DemaxTransferListener is Ownable {
    uint256 public version = 1;
    address public DGAS;
    address public PLATFORM;
    address public WETH;
    address public FACTORY;
    event Transfer(address indexed from, address indexed to, address indexed token, uint256 amount);

    function initialize(
        address _DGAS,
        address _FACTORY,
        address _WETH,
        address _PLATFORM
    ) external onlyOwner {
        require(
            _DGAS != address(0) && _FACTORY != address(0) && _WETH != address(0) && _PLATFORM != address(0),
            'DEMAX TRANSFER LISTENER : INPUT ADDRESS IS ZERO'
        );
        DGAS = _DGAS;
        FACTORY = _FACTORY;
        WETH = _WETH;
        PLATFORM = _PLATFORM;
    }

    function updateDGASImpl(address _newImpl) external onlyOwner {
        IDgas(DGAS).upgradeImpl(_newImpl);
    }

    function transferNotify(
        address from,
        address to,
        address token,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == PLATFORM, 'DEMAX TRANSFER LISTENER: PERMISSION');
        if (token == WETH) {
            if (IDemaxFactory(FACTORY).isPair(from)) {
                uint256 decreasePower = IDemaxFactory(FACTORY).getPair(DGAS, WETH) == from
                    ? SafeMath.mul(amount, 2)
                    : amount;
                IDgas(DGAS).decreaseProductivity(from, decreasePower);
            }
            if (IDemaxFactory(FACTORY).isPair(to)) {
                uint256 increasePower = IDemaxFactory(FACTORY).getPair(DGAS, WETH) == to
                    ? SafeMath.mul(amount, 2)
                    : amount;
                IDgas(DGAS).increaseProductivity(to, increasePower);
            }
        } else if (token == DGAS) {
            (uint256 reserveDGAS, uint256 reserveWETH) = DemaxSwapLibrary.getReserves(FACTORY, DGAS, WETH);
            if (IDemaxFactory(FACTORY).isPair(to) && IDemaxFactory(FACTORY).getPair(DGAS, WETH) != to) {
                IDgas(DGAS).increaseProductivity(to, DemaxSwapLibrary.quote(amount, reserveDGAS, reserveWETH));
            }
            if (IDemaxFactory(FACTORY).isPair(from) && IDemaxFactory(FACTORY).getPair(DGAS, WETH) != from) {
                (uint256 pairPower, ) = IDgas(DGAS).getProductivity(from);
                uint256 balance = IDemaxPair(from).getDGASReserve();
                uint256 decrasePower = (SafeMath.mul(amount, pairPower)) / (SafeMath.add(balance, amount));
                if (decrasePower > 0) IDgas(DGAS).decreaseProductivity(from, decrasePower);
            }
        }
        emit Transfer(from, to, token, amount);
        return true;
    }
}