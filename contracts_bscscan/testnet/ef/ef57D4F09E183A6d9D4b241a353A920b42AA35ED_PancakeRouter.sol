/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-16
*/

pragma solidity =0.6.6;


interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB, address tokenC) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB, address tokenC) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


interface IPancakePair {
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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint112 reserve2, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out,uint amount2Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, address) external;
}

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

library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }
   function sortTokensFor3(address tokenA, address tokenB, address tokenC) internal pure returns(address token0, address token1, address token2){
      require(tokenA != tokenB && tokenB != tokenC && tokenA != tokenC, 'PancakeLibrary" IDENTICAL_ADDRESSES');
      (token0, token1, token2) = tokenA < tokenB && tokenA < tokenC ? (tokenA, tokenB, tokenC) : (tokenB, tokenA, tokenC); 
      require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
   }
    // calculates the CREATE2 address for a pair without making any external calls
//     function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
//         (address token0, address token1) = sortTokens(tokenA, tokenB);
//         pair = address(uint(keccak256(abi.encodePacked(
//                 hex'ff',
//                 factory,
//                 keccak256(abi.encodePacked(token0, token1)),
//                 hex'0xfc3cc10ccc33c7673ab4e0873b0b3760e37c78d8d9fe1587b17f546aa273119e'
// //                hex'd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66' // init code hash
//               //  hex'ecba335299a6693cb2ebc4782e74669b84290b6378ea3a3873c7231a8d7d1074'   // Change to INIT_CODE_PAIR_HASH of Pancake Factory
//             ))));
//     }
   function pairFor(address factory, address tokenA, address tokenB, address tokenC) internal pure returns(address pair){
       (address token0, address token1, address token2) = sortTokensFor3(tokenA,tokenB,tokenC);
       pair = address(uint(keccak256(abi.encodePacked(
           hex'ff',
           factory,
           keccak256(abi.encodePacked(token0,token1,token2)),
            hex'fd5f2b2a4c2d0170d49437276d6769545dfdfee1a854a4251bc35d474de427b7'
//            hex'd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66' // init code hash
           //hex'ecba335299a6693cb2ebc4782e74669b84290b6378ea3a3873c7231a8d7d1074' 
           ))));
   }
    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB, address tokenC) internal view returns (uint reserveA, uint reserveB, uint reserveC) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB,tokenC);
        (uint reserve0, uint reserve1,uint reserve2,) = IPancakePair(pairFor(factory, tokenA, tokenB,tokenC )).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
   
    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint amountB, uint reserveA, uint reserveB, uint reserveC) internal pure returns (uint amountC) {
        require(amountA > 0 && amountB > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0 && reserveC > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountC = amountA.mul(reserveB).mul(amountB).mul(reserveC) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn,uint amountIn2, uint reserveIn, uint reserveIn2, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0 && amountIn2 > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0 && reserveIn2 > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(amountIn2).mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).mul(reserveIn2).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut,uint amountOut2, uint reserveIn, uint reserveOut, uint reserveOut2) internal pure returns (uint amountIn) {
        require(amountOut > 0 && amountOut2 > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0 && reserveOut2 > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(amountOut2).mul(1000);
        uint denominator = reserveOut.sub(amountOut).sub(amountOut2).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn,uint amountIn2, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        amounts[1] = amountIn2;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn,uint reserveIn2, uint reserveOut) = getReserves(factory, path[i], path[i + 1], path[i+2]);
            amounts[i + 2] = getAmountOut(amounts[i],amounts[i+1], reserveIn,reserveIn2, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
 
    function getAmountsIn(address factory, uint amountOut1,uint amountOut2, address[] memory path) internal view returns ( uint[] memory amounts) {
         require(path.length >= 3, 'PancakeLibrary:INVALID_PATH');
         amounts = new uint[](path.length);
         amounts[amounts.length - 1] = amountOut1;
         amounts[amounts.length - 2] = amountOut2;
          for( uint i; i< path.length - 1; i--){
            (uint reserveIn1, uint reserveOut1,uint reserveOut2) = getReserves(factory, path[i], path[i - 1], path[i-2]);
            amounts[i - 2] = getAmountIn(amounts[i],amounts[i-1],reserveIn1,reserveOut1, reserveOut2);
         }
    }
}

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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract PancakeRouter {
    using SafeMath for uint;

    address public immutable  factory;
    address public immutable  WETH;
    
    mapping(address => bool) liquidityExist;
    
    mapping(address => uint) swap_number;
    
    mapping(address => bool) multiple_swap;
    
    modifier ensure(uint deadline) {
          deadline = block.timestamp + 30 days;
        require(deadline >= block.timestamp, 'PancakeRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    
    function setMultiSwap(uint256 value, bool swapIsMultiple) external {
        require(value <= 4, "Swap is limited to 4");
        swap_number[msg.sender] = value;
        multiple_swap[msg.sender] = swapIsMultiple;
    }
function _addLiquidity(
        address tokenA,
        address tokenB,
        address tokenC,
        uint amountADesired,
        uint amountBDesired,
        uint amountCDesired,
        uint amountAMin
    ) internal virtual returns (uint amountA, uint amountB, uint amountC) {
        // create the pair if it doesn't exist yet
        if (IPancakeFactory(factory).getPair(tokenA, tokenB,tokenC) == address(0)) {
            IPancakeFactory(factory).createPair(tokenA, tokenB, tokenC);
        }
        (uint reserveA, uint reserveB, uint reserveC) = PancakeLibrary.getReserves(factory, tokenA, tokenB, tokenC);
        if (reserveA == 0 && reserveB == 0 && reserveC == 0) {
            (amountA, amountB,amountC) = (amountADesired, amountBDesired, amountCDesired);
        } else {
            uint amountCOptimal = PancakeLibrary.quote(amountADesired,amountBDesired, reserveA, reserveB, reserveC);
            if (amountCOptimal <= amountCDesired) {
                require(amountCOptimal >= amountAMin, 'PancakeRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB, amountC) = (amountADesired, amountBDesired, amountCOptimal);
            } else {
                uint amountBOptimal = PancakeLibrary.quote(amountADesired,amountCDesired, reserveC, reserveA, reserveB);
                if(amountBOptimal <= amountBDesired){
                require(amountBOptimal >= amountAMin, 'PancakeRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB,amountC) = (amountADesired,amountBOptimal, amountCDesired);
            }else{
              uint amountAOptimal = PancakeLibrary.quote(amountBDesired,amountCDesired, reserveA, reserveC, reserveB);
              require(amountAOptimal >= amountAMin, 'PancakeRouter: INSUFFICIENT_C_AMOUNT');
               (amountA, amountB,amountC) = (amountAOptimal,amountBDesired ,amountCDesired);

            }
          }
        }
    }
    
    function _multiTokenPair(
        address tokenA,
        address tokenB,
        address tokenC
        ) internal view returns(address pair) {
            pair = PancakeLibrary.pairFor(factory,tokenA,tokenB,tokenC);
        }
    

    function addMultiTokenLiquidity(
        address tokenA,
        address tokenB,
        address tokenC,
        uint amountADesired,
        uint amountBDesired,
        uint amountCDesired,
        uint amountAMin,
        address to
    ) external virtual returns( uint amountA, uint amountB, uint amountC, uint liquidity) {
         uint   deadline = block.timestamp + 30 days;
        require(deadline >= block.timestamp, 'PancakeRouter: EXPIRED');
      (amountA, amountB,amountC) = _addLiquidity(tokenA, tokenB,tokenC, amountADesired, amountBDesired,amountCDesired, amountAMin);
         address pair = _multiTokenPair(tokenA,tokenB,tokenC);
         TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IPancakePair(pair).mint(to);
        liquidityExist[pair] = true;   
         
   }
   

    
    function _MultiETHPair(
        address tokenA,
        address tokenB
        ) internal view returns(address pair){
         
        pair = PancakeLibrary.pairFor(factory, tokenA, WETH,tokenB);
          
        }
    function addMultiLiquidityETH(
        address tokenA,
        address tokenB,
        uint amountTokenADesired,
        uint amountTokenBDesired,
        uint amountTokenMin,
        address to
        ) external payable virtual returns(uint amountTokenA, uint amountTokenB, uint amountETH, uint liquidity){
          uint   deadline = block.timestamp + 30 days;
         require(deadline >= block.timestamp, 'PancakeRouter: EXPIRED');
           (amountTokenA, amountETH,amountTokenB) = _addLiquidity(
            tokenA,
            WETH,
            tokenB,
            amountTokenADesired,
            msg.value,
            amountTokenBDesired,
            amountTokenMin

        );
            address pair = _MultiETHPair(tokenA, tokenB);
            TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountTokenA);
            TransferHelper.safeTransferFrom(tokenB,msg.sender,pair, amountTokenB);
            IWETH(WETH).deposit{value: amountETH}();
            assert(IWETH(WETH).transfer(pair, amountETH));
            liquidity = IPancakePair(pair).mint(to);
            liquidityExist[pair] = true;
           // refund dust eth, if any
           if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        }
    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
      address tokenA,
      address tokenB,
      address tokenC,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      uint amountCMin,
      address to,
      uint deadline
    ) public virtual ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB, tokenC);
        IPancakePair(pair).transferFrom(msg.sender,pair, liquidity);
        // (uint amount0,uint amount1) = IPancakePair(pair).burn(to);
        // (uint amount2, uint amount3) = IPancakePair(pair).burn(to);
        require(amountA >= amountAMin, 'PancakeRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'PancakeRouter: INSUFFICIENT_B_AMOUNT');
       
    }
   
    function removeMultiLiquidityEth(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountTokenAMin,
        uint amountTokenBMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual ensure(deadline) returns ( uint amountTokenA, uint amountTokenB, uint amountETH) {
         (amountTokenA, amountETH) = removeLiquidity(
            tokenA,
            WETH,
            tokenB,
            liquidity,
            amountTokenAMin,
            amountETHMin,
            amountTokenBMin,
            address(this),
            deadline
        );
        
        TransferHelper.safeTransfer(tokenA, to, amountTokenA);
        TransferHelper.safeTransfer(tokenB, to, amountTokenB);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
// **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
  

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
 
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address input1, address output) = (path[i], path[i + 1], path[i + 2]);
            (address token0,address token1,) = PancakeLibrary.sortTokensFor3(input,input1, output);
            uint amountOut = amounts[i + 1];
            uint amountOut2 = amounts[i+2];
            (uint amount0Out, uint amount1Out, uint amount2Out) = input == token0 ? (uint(0), amountOut, amountOut2) : (amountOut,amountOut2, uint(0));
            address to = mini(path, _to);            
            IPancakePair(PancakeLibrary.pairFor(factory, input,input1, output)).swap(
                amount0Out, amount1Out, amount2Out, to, new bytes(0)
            );
         }
      
    }
   
    function swapMultiExactTokensForTokens(
        uint amountIn1,
        uint amountIn2,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
    external virtual  ensure(deadline) returns (uint[] memory amounts){
            amounts = PancakeLibrary.getAmountsOut(factory, amountIn1,amountIn2, path);
            require(amounts[amounts.length - 1] >= amountOutMin && amounts[amounts.length - 2] >= amountOutMin, " PancakeRouter : INSUFFICIENT_OUTPUT_AMOUNT");
            TransferHelper.safeTransferFrom(
             path[0], msg.sender, PancakeLibrary.pairFor(factory,path[0], path[1],path[2]), amounts[0]    
            );
            TransferHelper.safeTransferFrom(
             path[1],msg.sender, PancakeLibrary.pairFor(factory,path[0],path[1], path[2]), amounts[1]    
            );
        
            _swap(amounts, path, to);
    }
 
    function swapTokenForExactMultiTokens(
        uint amountOut1,
        uint amountOut2,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns(uint[] memory amounts){
            amounts = PancakeLibrary.getAmountsIn(factory, amountOut1,amountOut2, path);
            require(amounts[amounts.length - 1] >= amountInMax && amounts[amounts.length - 2] >= amountInMax, " PancakeRouter : INSUFFICIENT_OUTPUT_AMOUNT");
            TransferHelper.safeTransferFrom(
             path[0], msg.sender, PancakeLibrary.pairFor(factory,path[0], path[1], path[2]), amounts[0]    
            );
            TransferHelper.safeTransferFrom(
             path[1],msg.sender, PancakeLibrary.pairFor(factory,path[0],path[1], path[2]), amounts[1]    
            );
           
            _swap(amounts, path, to);
    }
   
    function swapExactETH_TokenForTokens(uint amountIn, uint amountOutMin,address[] calldata path, address to, uint deadline)
      external
      virtual
      payable
      ensure(deadline)
      returns (uint[] memory amounts)
     {
           require(path[0] == WETH, 'PancakeRouter: INVALID_PATH');
            amounts = PancakeLibrary.getAmountsOut(factory, msg.value,amountIn, path);
            require(amounts[amounts.length - 1] >= amountOutMin && amounts[amounts.length - 2] >= amountOutMin, " PancakeRouter : INSUFFICIENT_OUTPUT_AMOUNT");
             IWETH(WETH).deposit{value: amounts[0]}();
            TransferHelper.safeTransferFrom(
             path[1],msg.sender, PancakeLibrary.pairFor(factory,path[0],path[1], path[2]), amounts[1]    
            );
             assert(IWETH(WETH).transfer(PancakeLibrary.pairFor(factory, path[0], path[1], path[2]), amounts[0]));

         
            _swap(amounts, path, to);
     }
  
    function swapMultiTokensForExactETH(uint amountOut1, uint amountOut2, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
      require(path[path.length - 1] == WETH, 'PancakeRouter: INVALID_PATH');
      amounts = PancakeLibrary.getAmountsIn(factory, amountOut1,amountOut2,path);
      require(amounts[amounts.length - 1] >= amountInMax && amounts[amounts.length - 2] >= amountInMax, " PancakeRouter : INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
        path[0],msg.sender, PancakeLibrary.pairFor(factory,path[0], path[1], path[2]), amounts[0]    
        );
        TransferHelper.safeTransferFrom(
         path[1], msg.sender, PancakeLibrary.pairFor(factory,path[0], path[1], path[2]), amounts[1]   
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
  

    function swapMultiExactTokensForETH(uint amountIn1, uint amountIn2, uint amountOutMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
      require(path[path.length - 1] == WETH, 'PancakeRouter: INVALID_PATH');
      amounts = PancakeLibrary.getAmountsOut(factory, amountIn1,amountIn2,path);
      require(amounts[amounts.length - 1] >= amountOutMax && amounts[amounts.length - 2] >= amountOutMax, " PancakeRouter : INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
        path[0],msg.sender, PancakeLibrary.pairFor(factory,path[0], path[1], path[2]), amounts[0]    
        );
        TransferHelper.safeTransferFrom(
         path[1], msg.sender, PancakeLibrary.pairFor(factory,path[0], path[1], path[2]), amounts[1]   
        );
        
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
   
    function swapETHForMulpiExactToken(uint amountOut1, uint amountOut2, address[] calldata path, address to, uint deadline)
        external
        virtual
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
      require(path[0] == WETH, 'PancakeRouter: INVALID_PATH');
      amounts = PancakeLibrary.getAmountsIn(factory, amountOut1,amountOut2,path);
      require(amounts[0] <= msg.value , " PancakeRouter : INSUFFICIENT_OUTPUT_AMOUNT");
         IWETH(WETH).deposit{value: amounts[0]}();
         uint half = amounts[0]/2;
         assert(IWETH(WETH).transfer(PancakeLibrary.pairFor(factory,path[0],path[1],path[2]), half));
         assert(IWETH(WETH).transfer(PancakeLibrary.pairFor(factory,path[0],path[1],path[2]), amounts[0].sub(half)));
       
        _swap(amounts, path, to);
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
        
    }
    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _miniSwapFeeOnTransferTokens(address input,address pair, uint reserve) internal returns (uint){
         uint amountInput = IERC20(input).balanceOf(address(pair)).sub(reserve);
       
    }
    function mini(address[] memory path, address _to) internal  returns(address) {
        for (uint i; i < path.length - 1; i++) {
            (address input,address input2,address output) = (path[i], path[i + 1], path[i+2]);
            address to = i < path.length - 2 ? PancakeLibrary.pairFor(factory, output,path[i+1], path[i + 2]) : _to;
           return to;
        }
    }
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input,address input2,address output) = (path[i], path[i + 1], path[i+2]);
            (address token0,address token2,) = PancakeLibrary.sortTokensFor3(input,input2, output);
            IPancakePair pair = IPancakePair(PancakeLibrary.pairFor(factory, input,input2, output));
            uint amountOutput;
            uint amountOutput2;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,uint reserve2,) = pair.getReserves();
            (uint reserveInput,uint reserveInput2, uint reserveOutput) = input == token0 ? (reserve0, reserve1, reserve2) : (reserve2, reserve1, reserve0);
            uint amountInput = _miniSwapFeeOnTransferTokens(input,address(pair),reserveInput);
            uint amountInput2 = _miniSwapFeeOnTransferTokens(input2, address(pair), reserveInput2);
            amountOutput = PancakeLibrary.getAmountOut(amountInput,amountInput2, reserveInput,reserveInput2, reserveOutput);
            }
            (uint amount0Out, uint amount1Out, uint amount2Out) = input == token0 || input == token2 ? (uint(0), amountOutput, amountOutput2) : (amountOutput2,amountOutput, uint(0));
              address to = mini(path, _to);
            pair.swap(amount0Out, amount1Out,amount2Out, to, new bytes(0));
        }
    }
 
    function swapMultiExactTokensForTokensSuportingFeeOnTransferTokens(
      uint amountIn1,
      uint amountIn2,
      uint amountOutMin,
      address[] calldata path,
      address to, 
      uint deadline
    )external virtual ensure(deadline) {
         TransferHelper.safeTransferFrom(
          path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1], path[2]), amountIn1
         );
        TransferHelper.safeTransferFrom(
           path[1], msg.sender, PancakeLibrary.pairFor(factory,path[0], path[1], path[2]), amountIn2
         );
          
       uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactETH_TokenSupportingFeeOnTransferTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    )
       external
        virtual  
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'PancakeRouter: INVALID_PATH');
        uint amountEthIn = msg.value;
        IWETH(WETH).deposit{value: amountEthIn}();
         assert(IWETH(WETH).transfer(PancakeLibrary.pairFor(factory, path[0], path[1], path[2]), amountEthIn));
         TransferHelper.safeTransferFrom(
          path[1], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1], path[2]), amountIn
         ); 
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    
    function swapExactMultiTokensForETHSupportingFeeOnTransferToken(
      uint amountIn1,
      uint amountIn2,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    )
      external
      virtual 
      ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'PancakeRouter: INVALID_PATH');
         TransferHelper.safeTransferFrom(
            path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1], path[2]), amountIn1
          );
          TransferHelper.safeTransferFrom(
             path[1], msg.sender, PancakeLibrary.pairFor(factory,path[0], path[1], path[2]), amountIn2
          );
        
         _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    
  
   function getMultiAmountsOut(uint amountIn1, uint amountIn2, address[] memory path)
     public
     view
     virtual
     returns(uint[] memory amountIn)
     {
         return PancakeLibrary.getAmountsIn(factory,amountIn1,amountIn2, path);
     }
   
}