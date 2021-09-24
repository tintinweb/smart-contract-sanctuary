/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

/**
*Submitted for verification at BscScan.com on 2021-04-23
*/

// File: @uniswap\lib\contracts\libraries\TransferHelper.sol

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

// File: contracts\interfaces\IEcoRouter01.sol

pragma solidity >=0.6.2;

interface IEcoRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external payable returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountInETH,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external payable returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external payable returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v, bytes32 r, bytes32 s,
        uint8 wantToOffSetTransc
    ) external payable returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v, bytes32 r, bytes32 s,
        uint8 wantToOffSetTransc
    ) external payable returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external payable returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external payable returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint8 wantToOffSetTransc)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline, uint8 wantToOffSetTransc)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint8 wantToOffSetTransc)
        external
        payable
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline, uint8 wantToOffSetTransc)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts\interfaces\IEcoRouter02.sol

pragma solidity >=0.6.2;

interface IEcoRouter02 is IEcoRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external payable returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v, bytes32 r, bytes32 s,
        uint8 wantToOffSetTransc
    ) external payable returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external payable;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountInMin,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external payable;
}

// File: contracts\interfaces\IEcoFactory.sol

pragma solidity >=0.5.0;

interface IEcoFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

// File: contracts\libraries\SafeMath.sol

pragma solidity =0.6.6;

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

// File: contracts\interfaces\IEcoPair.sol

pragma solidity >=0.5.0;

interface IEcoPair {
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

// File: contracts\libraries\EcoLibrary.sol

pragma solidity >=0.5.0;



library EcoLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'EcoLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'EcoLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'3a40ad7f5639c2df322c88c71d54804a335ef91997006525e9a1e34efcd1e8f3' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IEcoPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'EcoLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'EcoLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'EcoLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'EcoLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(9978);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'EcoLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'EcoLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(9978);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'EcoLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'EcoLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts\interfaces\IERC20.sol

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

// File: contracts\interfaces\IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts\EcoRouter.sol

pragma solidity =0.6.6;

contract EcoRouter is IEcoRouter02 {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;
    address public immutable cc_address; // carbon credit token address
    address constant public burnAddress = address(0x000000000000000000000000000000000000dEaD);
    mapping (address => uint256) public transcationCnt;
    mapping (address => uint256) public offSetTranscationCnt;
    uint256 public carbonCreditPerGas = 10**12;
    address public ccOffSetSetter;
    uint256 constant public B_GAS_CONSUMPTION = 113000; //approx gas required to burn carboncredit using ETH
    uint256 constant public C_GAS_CONSUMPTION = 48500;  //approx gas required to burn carboncredit token direct

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EcoRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH, address _ccAddress, address _ccOffSetSetter) public {
        factory = _factory;
        WETH = _WETH;
        cc_address = _ccAddress;
        ccOffSetSetter = _ccOffSetSetter;
    }

    receive() external payable {
        require(msg.sender == WETH,'recieved failed'); // only accept ETH via fallback from the WETH contract
    }

    /**
    * @dev  return amount ETH required to offset
    *       transaction that consume gasSpent amount of gas.
    * @param gasSpent amount if gas Spent in transaction.
    */
    function _calcOffSetAmount(
        uint256 gasSpent
    ) public view virtual returns (uint256) {
        uint256 ccOffSetAmount = gasSpent * carbonCreditPerGas;
        address[] memory offSetpath = new address[](2);
        offSetpath[0] = WETH;
        offSetpath[1] = cc_address;
        uint256[] memory offSetAmounts = EcoLibrary.getAmountsIn(factory, ccOffSetAmount, offSetpath);
        
        return offSetAmounts[0];
    }

    /**
     * @dev  calculate carbonCredit required to offset transaction and 
                burn token to offSet transaction 
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * @param gasSpent amount if gas Spent in transaction.	
     * @param inCallWETH amount ETH sent by user for AMM transaction, 
                            inCallWETH doesn't include ETH amount requried
                            to offSet transaction 
    **/
    function _burnOutCarbonCreditOffSet(
        uint8 wantToOffSetTransc,
        uint gasSpent,
        uint inCallWETH
    ) internal virtual {
        uint256 ccOffsetAmount;
        if (wantToOffSetTransc == 1){
            ccOffsetAmount = gasSpent * carbonCreditPerGas;
            TransferHelper.safeTransferFrom(cc_address, msg.sender, burnAddress, ccOffsetAmount);

            // refund dust eth, if any
            if (msg.value > inCallWETH) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(inCallWETH));
        } else {
            ccOffsetAmount = _calcOffSetAmount(gasSpent);
            require(msg.value >= ccOffsetAmount.add(inCallWETH), 'EcoRouter: INSUFFICIENT_OFFSET_AMOUNT');
            address[] memory offSetpath = new address[](2);
            offSetpath[0] = WETH;
            offSetpath[1] = cc_address;
            uint[] memory amounts = EcoLibrary.getAmountsOut(factory, ccOffsetAmount, offSetpath);
            IWETH(WETH).deposit{value: amounts[0]}();
            require(IWETH(WETH).transfer(EcoLibrary.pairFor(factory, offSetpath[0], offSetpath[1]), amounts[0]), '_burnOutCarbonCreditOffSet failed');
            _swap(amounts, offSetpath, address(this));
            TransferHelper.safeTransferFrom(cc_address, address(this), burnAddress, amounts[amounts.length - 1]);

            // refund dust eth, if any
            if (msg.value > ccOffsetAmount.add(inCallWETH)) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(ccOffsetAmount.add(inCallWETH)));
        }
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IEcoFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IEcoFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = EcoLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = EcoLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'EcoRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = EcoLibrary.quote(amountBDesired, reserveB, reserveA);
                require(amountAOptimal <= amountADesired, '_addLiquidity: failed');
                require(amountAOptimal >= amountAMin, 'EcoRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    
    function internalAddLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    ) internal virtual returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = EcoLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IEcoPair(pair).mint(to);
    }

    function internalRemoveLiquidity(
            address tokenA,
            address tokenB,
            uint liquidity,
            uint amountAMin,
            uint amountBMin,
            address to
        ) internal virtual returns (uint amountA, uint amountB) {
        address pair = EcoLibrary.pairFor(factory, tokenA, tokenB);
        IEcoPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IEcoPair(pair).burn(to);
        (address token0,) = EcoLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'EcoRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'EcoRouter: INSUFFICIENT_B_AMOUNT');
    }

    function internalRemoveLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v, bytes32 r, bytes32 s
    ) internal virtual returns (uint amountA, uint amountB) {
        address pair = EcoLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IEcoPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = internalRemoveLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to);
    }

    function internalRemoveLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v, bytes32 r, bytes32 s
    ) internal virtual returns (uint amountToken, uint amountETH) {
        address pair = EcoLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IEcoPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = internalRemoveLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this)
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function internalRemoveLiquidityETHSupportingFeeOnTransferTokens(
            address token,
            uint liquidity,
            uint amountTokenMin,
            uint amountETHMin,
            address to
    ) internal virtual returns (uint amountETH) {
        (, amountETH) = internalRemoveLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this)
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function internalRemoveLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v, bytes32 r, bytes32 s
    ) internal virtual returns (uint amountETH) {
        address pair = EcoLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IEcoPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = internalRemoveLiquidityETHSupportingFeeOnTransferTokens(token, liquidity, amountTokenMin, amountETHMin, to);
    }

    /**
     * @dev  Adds liquidity to an ERC-20⇄ERC-20 pool.
     * @param tokenA A pool token address.
     * @param tokenB B pool token address.
     * @param amountADesired The amount of tokenA to add as liquidity if the B/A price 
                             is <= amountBDesired/amountADesired (A depreciates).
     * @param amountBDesired The amount of tokenB to add as liquidity if the A/B price
                             is <= amountADesired/amountBDesired (B depreciates).
     * @param amountAMin Bounds the extent to which the B/A price can go up before
                         the transaction reverts. Must be <= amountADesired.
     * @param amountBMin Bounds the extent to which the A/B price can go up before 
                         the transaction reverts. Must be <= amountBDesired.
     * @param to Recipient of the liquidity tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH required to offSet transaction if user 
                        wants to offSet transaction using ETH.
     * @return amountA The amount of tokenA sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
    **/
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        
        uint256 gasStart = gasleft();
        (amountA, amountB, liquidity) = internalAddLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to);

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, 0);
            offSetTranscationCnt[msg.sender]++;
        }
        transcationCnt[msg.sender]++;
    }

    /**
     * @dev  Adds liquidity to an ERC20-20⇄WETH pool with ETH.
     * @param token A pool token address.
     * @param amountInETH The amount of ETH sent to add liquidity
     * @param amountTokenDesired The amount of token to add as liquidity if the 
                                 WETH/token price is <= msg.value/amountTokenDesired (token depreciates).
     * @param amountTokenMin Bounds the extent to which the WETH/token price can go up
                             before the transaction reverts. Must be <= amountTokenDesired.
     * @param amountETHMin Bounds the extent to which the token/WETH price can go up before 
                           the transaction reverts. Must be <= msg.value.
     * @param to Recipient of the liquidity tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH to add as liquidity + amount of ETH required 
                        to offSet transaction, if user wants to offSet transaction using ETH.
                        if the token/WETH price is <= amountTokenDesired/msg.value-offSetAmountInETH (WETH depreciates).
     * @return amountToken The amount of token sent to the pool.
     * @return amountETH The amount of ETH converted to WETH and sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
    **/
    function addLiquidityETH(
        address token,
        uint amountInETH,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        uint256 gasStart = gasleft();
        require(msg.value >= amountInETH, 'INSUFFICIENT_INPUT_AMOUNT');
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            amountInETH,
            amountTokenMin,
            amountETHMin
        );
        address pair = EcoLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        require(IWETH(WETH).transfer(pair, amountETH),'addLiquidityETH: failed');
        liquidity = IEcoPair(pair).mint(to);

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, amountETH);
            offSetTranscationCnt[msg.sender]++;
        } else {
            // refund dust eth, if any
            if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(amountETH));
        }
        transcationCnt[msg.sender]++;
    }
    
    /**
     * @dev  Removes liquidity from an ERC-20⇄ERC-20 pool.
     * @param tokenA A pool token address.
     * @param tokenB B pool token address.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountAMin The minimum amount of tokenA that must be received 
                         for the transaction not to revert.
     * @param amountBMin The minimum amount of tokenB that must be received
                         for the transaction not to revert.
     * @param to Recipient of the underlying assets.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH required to offSet transaction if user 
                        wants to offSet transaction using ETH.
     * @return amountA The amount of tokenA received.
     * @return amountB The amount of tokenA received.
    **/
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) returns (uint amountA, uint amountB) {
        uint256 gasStart = gasleft();
        (amountA, amountB) = internalRemoveLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to);
        
        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, 0);
            offSetTranscationCnt[msg.sender]++;
        }
        transcationCnt[msg.sender]++;
    }
    
    /**
     * @dev Removes liquidity from an ERC-20⇄WETH pool and receive ETH.
     * @param token A pool token address.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountTokenMin The minimum amount of token that must be received 
                         for the transaction not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received
                         for the transaction not to revert.
     * @param to Recipient of the underlying assets.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH required to offSet transaction if user 
                        wants to offSet transaction using ETH.
     * @return amountToken The amount of token received.
     * @return amountETH The amount of ETH received.
    **/    
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH) {
        uint256 gasStart = gasleft();
        (amountToken, amountETH) = internalRemoveLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this)
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, 0);
            offSetTranscationCnt[msg.sender]++;
        }
        transcationCnt[msg.sender]++;       
    }

    /**
     * @dev Removes liquidity from an ERC-20⇄ERC-20 pool without pre-approval
            using permit
     * @param tokenA A pool token address.
     * @param tokenB B pool token address.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountAMin The minimum amount of tokenA that must be received 
                         for the transaction not to revert.
     * @param amountBMin The minimum amount of tokenB that must be received
                         for the transaction not to revert.
     * @param to Recipient of the underlying assets.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param approveMax Whether or not the approval amount in the signature
                         is for liquidity or uint(-1).
     * @param v The v component of the permit signature.
     * @param r The r component of the permit signature.
     * @param s The s component of the permit signature.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH required to offSet transaction if user 
                        wants to offSet transaction using ETH.
     * @return amountA The amount of tokenA received.
     * @return amountB The amount of tokenA received.
    **/ 
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v, bytes32 r, bytes32 s,
        uint8 wantToOffSetTransc
    ) external virtual override payable returns (uint amountA, uint amountB) {
        require(deadline >= block.timestamp, 'EcoRouter: EXPIRED');
        uint256 gasStart = gasleft();
        (amountA, amountB) = internalRemoveLiquidityWithPermit(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline, approveMax, v, r, s);

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, 0);
            offSetTranscationCnt[msg.sender]++;
        }
        transcationCnt[msg.sender]++;
    }

    /**
     * @dev Removes liquidity from an ERC-20⇄WETTH pool and receive ETH
            without pre-approval using permit
     * @param token A pool token address.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountTokenMin The minimum amount of token that must be received 
                         for the transaction not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received
                         for the transaction not to revert.
     * @param to Recipient of the underlying assets.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param approveMax Whether or not the approval amount in the signature
                         is for liquidity or uint(-1).
     * @param v The v component of the permit signature.
     * @param r The r component of the permit signature.
     * @param s The s component of the permit signature.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH required to offSet transaction if user 
                        wants to offSet transaction using ETH.
     * @return amountToken The amount of token received.
     * @return amountETH The amount of ETH received.
    **/   
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v, bytes32 r, bytes32 s,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH) {
        uint256 gasStart = gasleft();
        (amountToken, amountETH) = internalRemoveLiquidityETHWithPermit(token, liquidity, amountTokenMin, amountETHMin, to, deadline, approveMax, v, r, s);

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, 0);
            offSetTranscationCnt[msg.sender]++;
        }
        transcationCnt[msg.sender]++;
    }

    /**
     * @dev Identical to removeLiquidityETH, but succeeds for tokens that
            take a fee on transfer.
     * @param token A pool token address.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountTokenMin The minimum amount of token that must be received 
                         for the transaction not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received
                         for the transaction not to revert.
     * @param to Recipient of the underlying assets.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH required to offSet transaction if user 
                        wants to offSet transaction using ETH.
     * @return amountETH The amount of ETH received.
    **/
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) returns (uint amountETH) {
        uint256 gasStart = gasleft();
        amountETH = internalRemoveLiquidityETHSupportingFeeOnTransferTokens(token, liquidity, amountTokenMin, amountETHMin, to);

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, 0);
            offSetTranscationCnt[msg.sender]++;
        }
        transcationCnt[msg.sender]++;
    }

    /**
     * @dev Identical to removeLiquidityETHWithPermit, but succeeds for 
            tokens that take a fee on transfer.
     * @param token A pool token address.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountTokenMin The minimum amount of token that must be received 
                         for the transaction not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received
                         for the transaction not to revert.
     * @param to Recipient of the underlying assets.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param approveMax Whether or not the approval amount in the signature
                         is for liquidity or uint(-1).
     * @param v The v component of the permit signature.
     * @param r The r component of the permit signature.
     * @param s The s component of the permit signature.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH required to offSet transaction if user 
                        wants to offSet transaction using ETH.
     * @return amountETH The amount of ETH received.
    **/
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v, bytes32 r, bytes32 s,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) returns (uint amountETH) {
        uint256 gasStart = gasleft();
        amountETH = internalRemoveLiquidityETHWithPermitSupportingFeeOnTransferTokens(token, liquidity, amountTokenMin, amountETHMin, to, deadline, approveMax, v, r, s);

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, 0);
            offSetTranscationCnt[msg.sender]++;
        }
        transcationCnt[msg.sender]++;
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint[] memory amounts, 
        address[] memory path, 
        address _to
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = EcoLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? EcoLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IEcoPair(EcoLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    /**
     * @dev Swaps an exact amount of input tokens for as many output tokens
            as possible, along the route determined by the path
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be 
                           received for the transaction not to revert.
     * @param path An array of token addresses. path.length must be >= 2. 
                   Pools for each consecutive pair of addresses must exist 
                   and have liquidity.
     * @param to Recipient of the output tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH required to offSet transaction if user 
                        wants to offSet transaction using ETH.
     * @return amounts The input token amount and all subsequent output token amounts
    **/
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) returns (uint[] memory amounts) {
        uint256 gasStart = gasleft();
        amounts = EcoLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'EcoRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, EcoLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, 0);
            offSetTranscationCnt[msg.sender]++;
        }
        transcationCnt[msg.sender]++;
    }
    
    /**
     * @dev Receive an exact amount of output tokens for as few input tokens as 
            possible, along the route determined by the path. The first element 
            of path is the input token, the last is the output token, and any 
            intermediate elements represent intermediate tokens to trade through 
     * @param amountOut The amount of output tokens to receive.
     * @param amountInMax The maximum amount of input tokens that can be
                          required before the transaction reverts.
     * @param path An array of token addresses. path.length must be >= 2. 
                   Pools for each consecutive pair of addresses must exist 
                   and have liquidity.
     * @param to Recipient of the output tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH required to offSet transaction if user 
                        wants to offSet transaction using ETH.
     * @return amounts The input token amount and all subsequent output token amounts
    **/
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) returns (uint[] memory amounts) {
    
        uint256 gasStart = gasleft();   
        amounts = EcoLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'EcoRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, EcoLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, 0);
            offSetTranscationCnt[msg.sender]++;
        }
        transcationCnt[msg.sender]++;
    }
    
    /**
     * @dev Swaps an exact amount of ETH for as many output tokens
            as possible, along the route determined by the path. 
            The first element of path must be WETH, the last is the
            output token, and any intermediate elements represent 
            intermediate pairs to trade through
     * @param amountIn The amount of ETH tokens to be sent for SWAP.
     * @param amountOutMin 	The minimum amount of output tokens that must
                            be received for the transaction not to revert
     * @param path An array of token addresses. path.length must be >= 2. 
                   Pools for each consecutive pair of addresses must exist 
                   and have liquidity.
     * @param to Recipient of the output tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH to send for swap + amount of ETH required 
                        to offSet transaction, if user wants to offSet transaction using ETH.
     * @return amounts The input token amount and all subsequent output token amounts
    **/
    function swapExactETHForTokens(
        uint amountIn,
        uint amountOutMin, 
        address[] calldata path, 
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) returns (uint[] memory amounts) {
        uint256 gasStart = gasleft();
        require(path[0] == WETH, 'EcoRouter: INVALID_PATH');
        require(msg.value >= amountIn, 'EcoRouter: INSUFFICIENT_INPUT_AMOUNT');
        amounts = EcoLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'EcoRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        require(IWETH(WETH).transfer(EcoLibrary.pairFor(factory, path[0], path[1]), amounts[0]), 'swapExactETHForTokens: failed');
        _swap(amounts, path, to);

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, amounts[0]);
            offSetTranscationCnt[msg.sender]++;
        } else {
            // refund dust eth, if any
            if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(amounts[0]));
        }
        transcationCnt[msg.sender]++;
    }
    
    /**
     * @dev Receive an exact amount of ETH for as few input tokens as 
            possible, along the route determined by the path. The first
            element of path is the input token, the last must be WETH, 
            and any intermediate elements represent intermediate pairs
            to trade through.
     * @param amountOut The amount of ETH to receive.
     * @param amountInMax The maximum amount of input tokens that can be
                          required before the transaction reverts.
     * @param path An array of token addresses. path.length must be >= 2. 
                   Pools for each consecutive pair of addresses must exist 
                   and have liquidity.
     * @param to Recipient of the ETH.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH required to offSet transaction if user 
                        wants to offSet transaction using ETH.
     * @return amounts The input token amount and all subsequent output token amounts
    **/
    function swapTokensForExactETH(
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address to,  
        uint deadline,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) returns (uint[] memory amounts) {
        uint256 gasStart = gasleft();
        require(path[path.length - 1] == WETH, 'EcoRouter: INVALID_PATH');
        amounts = EcoLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'EcoRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, EcoLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, 0);
            offSetTranscationCnt[msg.sender]++;
        }
        transcationCnt[msg.sender]++;
    }
    
    /**
     * @dev Swaps an exact amount of tokens for as much ETH as possible,
            along the route determined by the path. The first element of
            path is the input token, the last must be WETH, and any 
            intermediate elements represent intermediate pairs to trade through
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must 
                           be received for the transaction not to revert.
     * @param path An array of token addresses. path.length must be >= 2. 
                   Pools for each consecutive pair of addresses must exist 
                   and have liquidity.
     * @param to Recipient of the ETH.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH required to offSet transaction if user 
                        wants to offSet transaction using ETH.
     * @return amounts The input token amount and all subsequent output token amounts
    **/
    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to,  
        uint deadline,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) returns (uint[] memory amounts) {
        uint256 gasStart = gasleft();
        require(path[path.length - 1] == WETH, 'EcoRouter: INVALID_PATH');
        amounts = EcoLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'EcoRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, EcoLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, 0);
            offSetTranscationCnt[msg.sender]++;
        }
        transcationCnt[msg.sender]++;
    }
    
    /**
     * @dev Receive an exact amount of tokens for as little ETH as possible,
            along the route determined by the path. The first element of path
            must be WETH, the last is the output token and any intermediate 
            elements represent intermediate pairs to trade through.
     * @param amountOut The amount of tokens to receive.
     * @param path An array of token addresses. path.length must be >= 2. 
                   Pools for each consecutive pair of addresses must exist 
                   and have liquidity.
     * @param to Recipient of the ETH.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
    * NOTE: msg.value The amount of ETH to send for swap + amount of ETH required 
                        to offSet transaction, if user wants to offSet transaction using ETH.
     * @return amounts The input token amount and all subsequent output token amounts
    **/
    function swapETHForExactTokens(
        uint amountOut, 
        address[] calldata path, 
        address to,  
        uint deadline,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) returns (uint[] memory amounts) {
        uint256 gasStart = gasleft();
        require(path[0] == WETH, 'EcoRouter: INVALID_PATH');
        amounts = EcoLibrary.getAmountsIn(factory, amountOut, path);
        require(msg.value >= amounts[0], 'EcoRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        require(IWETH(WETH).transfer(EcoLibrary.pairFor(factory, path[0], path[1]), amounts[0]), 'swapETHForExactTokens: failed');
        _swap(amounts, path, to);

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, amounts[0]);
            offSetTranscationCnt[msg.sender]++;
        } else {
            // refund dust eth, if any
            if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(amounts[0]));
        }
        transcationCnt[msg.sender]++;
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(
        address[] memory path, 
        address _to
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = EcoLibrary.sortTokens(input, output);
            IEcoPair pair = IEcoPair(EcoLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = EcoLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? EcoLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    
    /**
     * @dev Identical to swapExactTokensForTokens, but succeeds for 
            tokens that take a fee on transfer.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be 
                           received for the transaction not to revert.
     * @param path An array of token addresses. path.length must be >= 2. 
                   Pools for each consecutive pair of addresses must exist 
                   and have liquidity.
     * @param to Recipient of the output tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH required to offSet transaction if user 
                        wants to offSet transaction using ETH.
    **/
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) {
        uint256 gasStart = gasleft();
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, EcoLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'EcoRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, amountIn);
            offSetTranscationCnt[msg.sender]++;
        }
        transcationCnt[msg.sender]++;
    }

    /**
     * @dev Identical to swapExactETHForTokens, but succeeds for tokens 
            that take a fee on transfer.
     * @param amountInMin The amount of ETH tokens to be sent for SWAP.
     * @param amountOutMin 	The minimum amount of output tokens that must
                            be received for the transaction not to revert
     * @param path An array of token addresses. path.length must be >= 2. 
                   Pools for each consecutive pair of addresses must exist 
                   and have liquidity.
     * @param to Recipient of the output tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH to send for swap + amount of ETH required 
                        to offSet transaction, if user wants to offSet transaction using ETH.
    **/
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountInMin,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) {
        uint256 gasStart = gasleft();
        require(path[0] == WETH, 'EcoRouter: INVALID_PATH');
        require(msg.value >= amountInMin, 'EcoRouter: INSUFFICIENT_INPUT_AMOUNT');
        uint amountIn = amountInMin;
        IWETH(WETH).deposit{value: amountIn}();
        require(IWETH(WETH).transfer(EcoLibrary.pairFor(factory, path[0], path[1]), amountIn), 'swapExactETHForTokensSupportingFeeOnTransferTokens: failes');
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'EcoRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, amountIn);  
            offSetTranscationCnt[msg.sender]++;
        } else {
            // refund dust eth, if any
            if (msg.value > amountIn) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(amountIn));
        }
        transcationCnt[msg.sender]++;
    }

    /**
     * @dev Identical to swapExactTokensForETH, but succeeds for tokens
            that take a fee on transfer.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must 
                           be received for the transaction not to revert.
     * @param path An array of token addresses. path.length must be >= 2. 
                   Pools for each consecutive pair of addresses must exist 
                   and have liquidity.
     * @param to Recipient of the ETH.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param wantToOffSetTransc indicate how user want to offSet transaction
                                 by burn CC token direct from user wallet or
                                 by send extra ETH for offSetting.
     * NOTE: msg.value The amount of ETH required to offSet transaction if user 
                        wants to offSet transaction using ETH.
    **/
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint8 wantToOffSetTransc
    ) external virtual override payable ensure(deadline) {
        uint256 gasStart = gasleft();
        require(path[path.length - 1] == WETH, 'EcoRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, EcoLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'EcoRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);

        if (wantToOffSetTransc > 0) {
            uint256 gasSpent = ((wantToOffSetTransc == 1 ? C_GAS_CONSUMPTION : B_GAS_CONSUMPTION) + gasStart - gasleft());
            _burnOutCarbonCreditOffSet(wantToOffSetTransc, gasSpent, 0);
            offSetTranscationCnt[msg.sender]++;
        }
        transcationCnt[msg.sender]++;
    }

    /**
     * @dev update offSetSetter address which has right to update
            amount CarbonCredit per gas need to burn to offset transaction 
     * @param _ccOffSetSetter offSetSetter Address
    **/
    function setCarbonCerditOffSetSetter(
        address _ccOffSetSetter
    ) external {
        require(msg.sender == ccOffSetSetter, 'EcoRouter: FORBIDDEN');
        require(_ccOffSetSetter != address(0), 'EcoRouter: _ccOffSetSetter should be valid Address');
        
        ccOffSetSetter = _ccOffSetSetter;
    }

    /**
     * @dev update amount CarbonCredit per gas need to burn 
            to offset transaction, One ccOffSetSetter has
            pervilaged to call these function 
     * @param _carbonCreditPerGas CarbonCerdit token amount per Gas
    **/
    function setCarbonCreditOffSetPerGas(
        uint256 _carbonCreditPerGas
    ) external {
        require(msg.sender == ccOffSetSetter, 'EcoRouter: FORBIDDEN');
        carbonCreditPerGas = _carbonCreditPerGas;
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint amountA, 
        uint reserveA, 
        uint reserveB
    ) public pure virtual override returns (uint amountB) {
        return EcoLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual override returns (uint amountOut) {
        return EcoLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint amountOut, 
        uint reserveIn, 
        uint reserveOut
    ) public pure virtual override returns (uint amountIn) {
        return EcoLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(
        uint amountIn, 
        address[] memory path
    ) public view virtual override returns (uint[] memory amounts) {
        return EcoLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(
        uint amountOut, 
        address[] memory path
    ) public view virtual override returns (uint[] memory amounts) {
        return EcoLibrary.getAmountsIn(factory, amountOut, path);
    }
}