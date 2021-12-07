/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

/**
 *Submitted for verification at polygonscan.com on 2021-07-27
*/

pragma solidity >=0.5.0;

interface IDXswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function INIT_CODE_PAIR_HASH() external pure returns (bytes32);
    function feeTo() external view returns (address);
    function protocolFeeDenominator() external view returns (uint8);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setProtocolFee(uint8 _protocolFee) external;
    function setSwapFee(address pair, uint32 swapFee) external;
}

// File: contracts/interfaces/IDXswapPair.sol

pragma solidity >=0.5.0;

interface IDXswapPair {
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
    function swapFee() external view returns (uint32);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setSwapFee(uint32) external;
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

// File: contracts/interfaces/IRewardManager.sol

pragma solidity >=0.5.0;

contract IRewardManager {
    function rebalance() external;
}

// File: contracts/libraries/TransferHelper.sol

pragma solidity =0.5.16;

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
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts/libraries/SafeMath.sol

pragma solidity =0.5.16;

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

// File: contracts/DXswapFeeReceiver.sol

pragma solidity =0.5.16;








contract DXswapFeeReceiver {
    using SafeMath for uint;

    uint256 public constant ONE_HUNDRED_PERCENT = 10**10;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public owner;
    IDXswapFactory public factory;
    IERC20 public honeyToken;
    IERC20 public hsfToken;
    address public honeyReceiver;
    IRewardManager public hsfReceiver;
    uint256 public splitHoneyProportion;

    constructor(
        address _owner, address _factory, IERC20 _honeyToken, IERC20 _hsfToken, address _honeyReceiver,
        IRewardManager _hsfReceiver, uint256 _splitHoneyProportion
    ) public {
        require(_splitHoneyProportion <= ONE_HUNDRED_PERCENT / 2, 'DXswapFeeReceiver: HONEY_PROPORTION_TOO_HIGH');
        owner = _owner;
        factory = IDXswapFactory(_factory);
        honeyToken = _honeyToken;
        hsfToken = _hsfToken;
        honeyReceiver = _honeyReceiver;
        hsfReceiver = _hsfReceiver;
        splitHoneyProportion = _splitHoneyProportion;
    }

    function() external payable {}

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, 'DXswapFeeReceiver: FORBIDDEN');
        owner = newOwner;
    }

    function changeReceivers(address _honeyReceiver, IRewardManager _hsfReceiver) external {
        require(msg.sender == owner, 'DXswapFeeReceiver: FORBIDDEN');
        honeyReceiver = _honeyReceiver;
        hsfReceiver = _hsfReceiver;
    }

    function changeSplitHoneyProportion(uint256 _splitHoneyProportion) external {
        require(msg.sender == owner, 'DXswapFeeReceiver: FORBIDDEN');
        require(_splitHoneyProportion <= ONE_HUNDRED_PERCENT / 2, 'DXswapFeeReceiver: HONEY_PROPORTION_TOO_HIGH');
        splitHoneyProportion = _splitHoneyProportion;
    }

    // Returns sorted token addresses, used to handle return values from pairs sorted in this order
    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'DXswapFeeReceiver: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'DXswapFeeReceiver: ZERO_ADDRESS');
    }

    // Helper function to know if an address is a contract, extcodesize returns the size of the code of a smart
    //  contract in a specific address
    function _isContract(address addr) internal returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    // Calculates the CREATE2 address for a pair without making any external calls
    // Taken from DXswapLibrary, removed the factory parameter
    function _pairFor(address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'ae81bbc68f315fbbf7617eb881349af83b1e95241f616966e1e0583ecd0793fe' // matic init code hash
//                hex'd306a548755b9295ee49cc729e13ca4a45e00199bbd890fa146da43a50571776' // init code hash original
            ))));
    }

    // Done with code from DXswapRouter and DXswapLibrary, removed the deadline argument
    function _swapTokens(uint amountIn, address fromToken, address toToken)
        internal returns (uint256 amountOut)
    {
        IDXswapPair pairToUse = IDXswapPair(_pairFor(fromToken, toToken));

        (uint reserve0, uint reserve1,) = pairToUse.getReserves();
        (uint reserveIn, uint reserveOut) = fromToken < toToken ? (reserve0, reserve1) : (reserve1, reserve0);

        require(reserveIn > 0 && reserveOut > 0, 'DXswapFeeReceiver: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(uint(10000).sub(pairToUse.swapFee()));
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;

        TransferHelper.safeTransfer(
            fromToken, address(pairToUse), amountIn
        );

        (uint amount0Out, uint amount1Out) = fromToken < toToken ? (uint(0), amountOut) : (amountOut, uint(0));

        pairToUse.swap(
            amount0Out, amount1Out, address(this), new bytes(0)
        );
    }

    function _swapForHoney(address token, uint amount) internal {
        require(_isContract(_pairFor(token, address(honeyToken))), 'DXswapFeeReceiver: NO_HONEY_PAIR');
        _swapTokens(amount, token, address(honeyToken));
    }

    // Take what was charged as protocol fee from the DXswap pair liquidity
    function takeProtocolFee(IDXswapPair[] calldata pairs) external {
        for (uint i = 0; i < pairs.length; i++) {
            address token0 = pairs[i].token0();
            address token1 = pairs[i].token1();
            pairs[i].transfer(address(pairs[i]), pairs[i].balanceOf(address(this)));
            (uint amount0, uint amount1) = pairs[i].burn(address(this));

            if (amount0 > 0 && token0 != address(honeyToken))
                _swapForHoney(token0, amount0);
            if (amount1 > 0 && token1 != address(honeyToken))
                _swapForHoney(token1, amount1);

            uint256 honeyBalance = honeyToken.balanceOf(address(this));
            uint256 honeyEarned = (honeyBalance.mul(splitHoneyProportion)) / ONE_HUNDRED_PERCENT;
            TransferHelper.safeTransfer(address(honeyToken), honeyReceiver, honeyEarned);

            uint256 honeyToConvertToHsf = honeyBalance.sub(honeyEarned);
            uint256 hsfEarned = _swapTokens(honeyToConvertToHsf, address(honeyToken), address(hsfToken));
            uint256 halfHsfEarned = hsfEarned / 2;
            TransferHelper.safeTransfer(address(hsfToken), BURN_ADDRESS, halfHsfEarned);
            TransferHelper.safeTransfer(address(hsfToken), address(hsfReceiver), halfHsfEarned);
            hsfReceiver.rebalance();
        }
    }
}