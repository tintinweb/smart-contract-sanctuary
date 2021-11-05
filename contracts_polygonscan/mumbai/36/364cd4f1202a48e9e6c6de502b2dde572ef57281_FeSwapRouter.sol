/**
 *Submitted for verification at polygonscan.com on 2021-11-04
*/

// Dependency file: contracts\libraries\TransferHelper.sol

// SPDX-License-Identifier: MIT
// pragma solidity =0.6.12;


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

// Dependency file: contracts\interfaces\IFeSwapRouter.sol

// pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

interface IFeSwapRouter {

    struct AddLiquidityParams {
        address tokenA;
        address tokenB;
        uint    amountADesired;
        uint    amountBDesired;
        uint    amountAMin;
        uint    amountBMin;
        uint    ratio;
    }

    struct AddLiquidityETHParams {
        address token;
        uint    amountTokenDesired;
        uint    amountTokenMin;
        uint    amountETHMin;
        uint    ratio;
    }

    struct RemoveLiquidityParams {
        address tokenA;
        address tokenB;
        uint    liquidityAAB;
        uint    liquidityABB;        
        uint    amountAMin;
        uint    amountBMin;
    }

    struct Signature {
        uint8       v;
        bytes32     r;
        bytes32     s;
    }

    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        AddLiquidityParams calldata addParams,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidityAAB, uint liquidityABB);

    function addLiquidityETH(
        AddLiquidityETHParams calldata addParams,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidityTTE, uint liquidityTEE);

    function removeLiquidity(
        RemoveLiquidityParams calldata removeParams,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        RemoveLiquidityParams calldata removeParams,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        RemoveLiquidityParams calldata removeParams,
        address to,
        uint deadline,
        bool approveMax, 
        Signature   calldata sigAAB,
        Signature   calldata sigABB
    ) external returns (uint amountA, uint amountB);        

    function removeLiquidityETHWithPermit(
        RemoveLiquidityParams calldata removeParams,
        address to,
        uint deadline,
        bool approveMax, 
        Signature   calldata sigTTE,
        Signature   calldata sigTEE
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityETHFeeOnTransfer(
        RemoveLiquidityParams calldata removeParams,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitFeeOnTransfer(
        RemoveLiquidityParams calldata removeParams,
        address to,
        uint deadline,
        bool approveMax, 
        Signature   calldata sigTTE,
        Signature   calldata sigTEE
    ) external returns (uint amountETH);

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

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);     

    function swapExactTokensForTokensFeeOnTransfer(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensFeeOnTransfer(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHFeeOnTransfer(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function estimateAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function estimateAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// Dependency file: contracts\interfaces\IFeSwapERC20.sol

// pragma solidity =0.6.12;

interface IFeSwapERC20 {
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
}

// Dependency file: contracts\interfaces\IFeSwapPair.sol

// pragma solidity =0.6.12;

// import 'contracts\interfaces\IFeSwapERC20.sol';

interface IFeSwapPair is IFeSwapERC20 {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount1Out, address indexed to );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function pairOwner() external view returns (address);
    function tokenIn() external view returns (address);
    function tokenOut() external view returns (address);
    function getReserves() external view returns ( uint112 _reserveIn, uint112 _reserveOut, uint32 _blockTimestampLast);
    function getTriggerRate() external view returns (uint);
    function getOracleInfo() external view returns (uint, uint, uint);
    
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amountOut, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, uint, uint) external;
}

// Dependency file: contracts\interfaces\IFeSwapFactory.sol

// pragma solidity =0.6.12;

interface IFeSwapFactory {
    event PairCreated(address indexed tokenA, address indexed tokenB, address pairAAB, address pairABB, uint);

    function feeTo() external view returns (address);
    function getFeeInfo() external view returns (address, uint256);
    function factoryAdmin() external view returns (address);
    function routerFeSwap() external view returns (address);  
    function nftFeSwap() external view returns (address);  
    function rateTriggerFactory() external view returns (uint16);  
    function rateCapArbitrage() external view returns (uint16);     
    function rateProfitShare() external view returns (uint16); 

    function getPair(address tokenA, address tokenB) external view returns (address pairAB, address pairBA);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createUpdatePair(address tokenA, address tokenB, address pairOwner, uint256 rateTrigger, uint256 switchOracle) 
                                external returns (address pairAAB,address pairABB);

    function setFeeTo(address) external;
    function setFactoryAdmin(address) external;
    function setRouterFeSwap(address) external;
    function configFactory(uint16, uint16, uint16) external;
//  function managePair(address, address, address, address, uint256) external;
    function getPairTokens() external view returns (address pairIn, address pairOut);
}

// Dependency file: contracts\libraries\SafeMath.sol

// pragma solidity =0.6.12;

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

// Dependency file: contracts\libraries\FeSwapLibrary.sol

// pragma solidity =0.6.12;

// import 'contracts\interfaces\IFeSwapPair.sol';
// import 'contracts\interfaces\IFeSwapFactory.sol';
// import 'contracts\libraries\TransferHelper.sol';
// import "contracts\libraries\SafeMath.sol";

library FeSwapLibrary {
    using SafeMath for uint;

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
       pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(tokenA, tokenB)),
                hex'02a87956ec2f5e710fa13bbfe751d68112c843cdd501d3fcc9e744ade9c32428' // init code hash // save 9916 gas
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) 
                        internal view returns (uint reserveA, uint reserveB, address pair) {
        pair = pairFor(factory, tokenA, tokenB);
        (reserveA, reserveB, ) = IFeSwapPair(pair).getReserves();
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'FeSwapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'FeSwapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'FeSwapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'FeSwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = amountIn.mul(reserveOut);
        uint denominator = reserveIn.add(amountIn);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'FeSwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'FeSwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut);
        uint denominator = reserveOut.sub(amountOut);
        amountIn = (numerator.add(denominator)) / denominator;
    }

    function arbitragePairPools(address factory, address tokenA, address tokenB) 
                                    internal returns (uint reserveIn, uint reserveOut, address pair) {
        (reserveIn, reserveOut, pair) = getReserves(factory, tokenA, tokenB);
        uint rateTriggerArbitrage = IFeSwapPair(pair).getTriggerRate();
        (uint reserveInMate, uint reserveOutMate, address PairMate) = getReserves(factory, tokenB, tokenA); 
        uint productIn = uint(reserveIn).mul(reserveInMate);
        uint productOut = uint(reserveOut).mul(reserveOutMate);
        if(productIn.mul(10000) > productOut.mul(rateTriggerArbitrage)){                 
            productIn = productIn.sub(productOut);                                  // productIn are re-used
            uint totalTokenA = (uint(reserveIn).add(reserveOutMate)).mul(2);               
            uint totalTokenB = (uint(reserveOut).add(reserveInMate)).mul(2);
            TransferHelper.safeTransferFrom(tokenA, pair, PairMate, productIn / totalTokenB);          
            TransferHelper.safeTransferFrom(tokenB, PairMate, pair, productIn / totalTokenA); 
            IFeSwapPair(pair).sync();
            IFeSwapPair(PairMate).sync();
            (reserveIn, reserveOut, ) = getReserves(factory, tokenA, tokenB);
        }
    }   

    function culculatePairPools(address factory, address tokenA, address tokenB) internal view returns (uint reserveIn, uint reserveOut, address pair) {
        (reserveIn, reserveOut, pair) = getReserves(factory, tokenA, tokenB);
        uint rateTriggerArbitrage = IFeSwapPair(pair).getTriggerRate();
        (uint reserveInMate, uint reserveOutMate, ) = getReserves(factory, tokenB, tokenA); 
        uint productIn = uint(reserveIn).mul(reserveInMate);
        uint productOut = uint(reserveOut).mul(reserveOutMate);
        if(productIn.mul(10000) > productOut.mul(rateTriggerArbitrage)){                 
            productIn = productIn.sub(productOut);
            uint totalTokenA = (uint(reserveIn).add(reserveOutMate)).mul(2);               
            uint totalTokenB = (uint(reserveOut).add(reserveInMate)).mul(2);
            reserveIn = reserveIn.sub(productIn / totalTokenB);
            reserveOut = reserveOut.add(productIn / totalTokenA);
        }
    }   

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] calldata path) internal returns (address firstPair, uint[] memory amounts) {
        require(path.length >= 2, 'FeSwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i = 0; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut, address _firstPair) = arbitragePairPools(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
            if ( i == 0 ) firstPair = _firstPair;
        }
    }

    // performs aritrage beforehand
    function executeArbitrage(address factory, address[] calldata path) internal {
        require(path.length >= 2, 'FeSwapLibrary: INVALID_PATH');
        for (uint i = 0; i < path.length - 1; i++) {
            arbitragePairPools(factory, path[i], path[i + 1]);
        }
    }

    // performs chained estimateAmountsOut calculations on any number of pairs
    function estimateAmountsOut(address factory, uint amountIn, address[] calldata path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'FeSwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i = 0; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut, ) = culculatePairPools(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] calldata path) internal returns (address firstPair, uint[] memory amounts) {
        require(path.length >= 2, 'FeSwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        uint reserveIn;
        uint reserveOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (reserveIn, reserveOut, firstPair) = arbitragePairPools(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    function estimateAmountsIn(address factory, uint amountOut, address[] calldata path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'FeSwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut, ) = culculatePairPools(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// Dependency file: contracts\interfaces\IERC20.sol

// pragma solidity =0.6.12;

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

// Dependency file: contracts\interfaces\IWETH.sol

// pragma solidity =0.6.12;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// Dependency file: contracts\patch\RouterPatchCaller.sol

// pragma solidity >=0.6.12;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to the patch 
 *      using the EVM instruction `delegatecall`. The success and return data of the delegated call 
 *      will be returned back to the caller of the proxy.
 */
abstract contract RouterPatchCaller {
    // DELEGATE_TARGET = uint160(                      // downcast to match the address type.
    //                      uint256(                    // convert to uint to truncate upper digits.
    //                          keccak256(                // compute the CREATE2 hash using 4 inputs.
    //                              abi.encodePacked(       // pack all inputs to the hash together.
    //                                  hex"ff",              // start with 0xff to distinguish from RLP.
    //                                  address(this),        // this contract will be the caller.
    //                                  salt,                 // pass in the supplied salt value.
    //                                  _metamorphicContractInitializationCodeHash // the init code hash.
    //                              )
    //                          )
    //                      )
    //                   )
    //
    // salt = keccak256("Feswap Router Patch") = 0xA79A80C68DB5352E173057DB3DAFDC42FD6ABC2DAB19BFB02F55B49E402B3322
    // metamorphicContractInitializationCode = 0x60006020816004601c335a63aaf10f428752fa60185780fd5b808151803b80938091923cf3
    // _metamorphicContractInitializationCodeHash = keccak256(metamorphicContractInitializationCode)
    //                                            = 0x15bfb1132dc67a984de77a9eef294f7e58964d02c62a359fd6f3c0c1d443e35c 
    // address(this): 0x0BDb999cFA9c47d6d62323a1905F8Eb7B3c9B119 (Test) 
    // address(this): 0x8565570A7cB2b2508F9180AD83e8f58F25e41596 (Goerli) 
    // address(this): 0x6A8FE4753AB456e85E1379432d92ABF1fB49B5Df (Rinkeby/BSC/Polygon/Harmoney/Arbitrum/Fantom/Avalance/Heco) 
   
//  address public constant DELEGATE_TARGET = 0x92DD76703DACF9BE7F61CBC7ADAF77319084DBF8;   // (Goerli)
//  address public constant DELEGATE_TARGET = 0x1127DfBBa70B8FbF4352A749a79A5090091Ce615;   // (Test)
    address public constant DELEGATE_TARGET = 0x9D41A432A707f74D8fEBDC7118c9e1c49C063D37;   // (BSC/MATIC)
     
    /**
     * @dev Delegates the current call to `DELEGATE_TARGET`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */

    receive() external virtual payable {
        revert("Refused!");
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
       // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), DELEGATE_TARGET, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}


// Root file: contracts\FeSwapRouter.sol

pragma solidity =0.6.12;
// pragma experimental ABIEncoderV2;

// import 'contracts\libraries\TransferHelper.sol';
// import 'contracts\interfaces\IFeSwapRouter.sol';
// import 'contracts\libraries\FeSwapLibrary.sol';
// import 'contracts\libraries\SafeMath.sol';
// import 'contracts\interfaces\IERC20.sol';
// import 'contracts\interfaces\IWETH.sol';
// import 'contracts\patch\RouterPatchCaller.sol';

contract FeSwapRouter is IFeSwapRouter, RouterPatchCaller{

    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'FeSwapRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external override payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity( address tokenIn, 
                            address tokenOut, 
                            uint amountInDesired, 
                            uint amountOutDesired,
                            uint amountInMin,
                            uint amountOutMin 
    ) internal virtual view returns (uint amountIn, uint amountOut, address pair) {
        pair = FeSwapLibrary.pairFor(factory, tokenIn, tokenOut);        
        require(pair != address(0), 'FeSwap: NOT CREATED');
        (uint reserveIn, uint reserveOut, ) = IFeSwapPair(pair).getReserves();
        if (reserveIn == 0 && reserveOut == 0) {
            (amountIn, amountOut) = (amountInDesired, amountOutDesired);
        } else {
            uint amountOutOptimal = FeSwapLibrary.quote(amountInDesired, reserveIn, reserveOut);
            if (amountOutOptimal <= amountOutDesired) {
                require(amountOutOptimal >= amountOutMin, 'FeSwap: LESS_OUT_AMOUNT');
                (amountIn, amountOut) = (amountInDesired, amountOutOptimal);
            } else {
                uint amountInOptimal = FeSwapLibrary.quote(amountOutDesired, reserveOut, reserveIn);
                assert(amountInOptimal <= amountInDesired);
                require(amountInOptimal >= amountInMin, 'FeSwap: LESS_IN_AMOUNT');
                (amountIn, amountOut) = (amountInOptimal, amountOutDesired);
            }
        }
    }

    function addLiquidity(  AddLiquidityParams calldata addParams, 
                            address to, 
                            uint deadline ) 
                external virtual override ensure(deadline) 
                returns (uint amountA, uint amountB, uint liquidityAAB, uint liquidityABB)
    {
        require(addParams.ratio <= 100,  'FeSwap: RATIO EER');
        if(addParams.ratio != uint(0)) {
            address pairA2B;
            uint liquidityA = addParams.amountADesired.mul(addParams.ratio)/100; 
            uint liquidityB = addParams.amountBDesired.mul(addParams.ratio)/100;
            uint amountAMin = addParams.amountAMin.mul(addParams.ratio)/100; 
            uint amountBMin = addParams.amountBMin.mul(addParams.ratio)/100;
            (amountA, amountB, pairA2B) = 
                            _addLiquidity(addParams.tokenA, addParams.tokenB, liquidityA, liquidityB, amountAMin, amountBMin);
            TransferHelper.safeTransferFrom(addParams.tokenA, msg.sender, pairA2B, amountA);
            TransferHelper.safeTransferFrom(addParams.tokenB, msg.sender, pairA2B, amountB);
            liquidityAAB = IFeSwapPair(pairA2B).mint(to);
        }
        if(addParams.ratio != uint(100)) {
            address pairB2A; 
            uint liquidityA = addParams.amountADesired - amountA; 
            uint liquidityB = addParams.amountBDesired - amountB;
            uint amountAMin = (addParams.amountAMin > amountA) ? (addParams.amountAMin - amountA) : 0 ; 
            uint amountBMin = (addParams.amountBMin > amountB) ? (addParams.amountBMin - amountB) : 0 ;
            (liquidityB, liquidityA, pairB2A) = 
                        _addLiquidity(addParams.tokenB, addParams.tokenA, liquidityB, liquidityA, amountBMin, amountAMin);
            TransferHelper.safeTransferFrom(addParams.tokenA, msg.sender, pairB2A, liquidityA);
            TransferHelper.safeTransferFrom(addParams.tokenB, msg.sender, pairB2A, liquidityB);
            liquidityABB = IFeSwapPair(pairB2A).mint(to);
            amountA += liquidityA;
            amountB += liquidityB;
        }
    }

    function addLiquidityETH(   AddLiquidityETHParams calldata addParams,
                                address to,
                                uint deadline )
                external virtual override payable ensure(deadline) 
                returns (uint amountToken, uint amountETH, uint liquidityTTE, uint liquidityTEE) 
    {
        require(addParams.ratio <= 100,  'FeSwap: RATIO EER');
        if(addParams.ratio != uint(0)) {        
            address pairTTE;
            uint liquidityToken = addParams.amountTokenDesired.mul(addParams.ratio)/100; 
            uint liquidityETH   = msg.value.mul(addParams.ratio)/100;
            uint amountTokenMin = addParams.amountTokenMin.mul(addParams.ratio)/100; 
            uint amountETHMin   = addParams.amountETHMin.mul(addParams.ratio)/100;
            (amountToken, amountETH, pairTTE) =
                        _addLiquidity(addParams.token, WETH, liquidityToken, liquidityETH, amountTokenMin, amountETHMin);
            TransferHelper.safeTransferFrom(addParams.token, msg.sender, pairTTE, amountToken);
            IWETH(WETH).deposit{value: amountETH}();
            assert(IWETH(WETH).transfer(pairTTE, amountETH));
            liquidityTTE = IFeSwapPair(pairTTE).mint(to);
        }
        if(addParams.ratio != uint(100)){
            address pairTEE;
            uint liquidityToken = addParams.amountTokenDesired - amountToken; 
            uint liquidityETH   = msg.value - amountETH;
            uint amountTokenMin = (addParams.amountTokenMin > amountToken) ? (addParams.amountTokenMin - amountToken) : 0 ;
            uint amountETHMin   = (addParams.amountETHMin > amountETH) ? (addParams.amountETHMin - amountETH) : 0 ;
            (liquidityETH, liquidityToken, pairTEE) = 
                    _addLiquidity(WETH, addParams.token, liquidityETH,  liquidityToken, amountETHMin, amountTokenMin);
            TransferHelper.safeTransferFrom(addParams.token, msg.sender, pairTEE, liquidityToken);
            IWETH(WETH).deposit{value: liquidityETH}();
            assert(IWETH(WETH).transfer(pairTEE, liquidityETH));
            liquidityTEE = IFeSwapPair(pairTEE).mint(to);     
            amountToken += liquidityToken;
            amountETH   += liquidityETH;       
        }

        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        RemoveLiquidityParams calldata removeParams,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        if(removeParams.liquidityAAB != uint(0)) {
            address pairAAB = FeSwapLibrary.pairFor(factory, removeParams.tokenA, removeParams.tokenB);
            IFeSwapPair(pairAAB).transferFrom(msg.sender, pairAAB, removeParams.liquidityAAB);  // send liquidity to pair
            (amountA, amountB) = IFeSwapPair(pairAAB).burn(to);
        }
        if(removeParams.liquidityABB != uint(0)) {
            address pairABB = FeSwapLibrary.pairFor(factory, removeParams.tokenB, removeParams.tokenA);
            IFeSwapPair(pairABB).transferFrom(msg.sender, pairABB, removeParams.liquidityABB);  // send liquidity to pair
            (uint amountB0, uint amountA0) = IFeSwapPair(pairABB).burn(to);
            amountA += amountA0;
            amountB += amountB0;
        }
        require(amountA >= removeParams.amountAMin, 'FeSwapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= removeParams.amountBMin, 'FeSwapRouter: INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityETH(
        RemoveLiquidityParams calldata removeParams,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        require(removeParams.tokenB == WETH,  'FeSwap: WRONG WETH');
        (amountToken, amountETH) = removeLiquidity(
            removeParams,    
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(removeParams.tokenA, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removePermit(
        RemoveLiquidityParams calldata removeParams,
        uint deadline,
        bool approveMax, 
        Signature   calldata sigAAB,
        Signature   calldata sigABB
    ) internal {
        if(sigAAB.s != 0){
            address pairAAB = FeSwapLibrary.pairFor(factory, removeParams.tokenA, removeParams.tokenB);
            uint value = approveMax ? uint(-1) : removeParams.liquidityAAB; 
            IFeSwapPair(pairAAB).permit(msg.sender, address(this), value, deadline, sigAAB.v, sigAAB.r, sigAAB.s);
        }
        if(sigABB.s != 0){
            address pairABB = FeSwapLibrary.pairFor(factory, removeParams.tokenB, removeParams.tokenA);
            uint value = approveMax ? uint(-1) : removeParams.liquidityABB; 
            IFeSwapPair(pairABB).permit(msg.sender, address(this), value, deadline, sigABB.v, sigABB.r, sigABB.s);
        }    
    }

    function removeLiquidityWithPermit(
        RemoveLiquidityParams calldata removeParams,
        address to,
        uint deadline,
        bool approveMax, 
        Signature   calldata sigAAB,
        Signature   calldata sigABB
    ) external virtual override returns (uint amountA, uint amountB) {
        removePermit(removeParams, deadline, approveMax, sigAAB, sigABB);
        (amountA, amountB) = removeLiquidity(removeParams, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        RemoveLiquidityParams calldata removeParams,
        address to,
        uint deadline,
        bool approveMax, 
        Signature   calldata sigTTE,
        Signature   calldata sigTEE
    ) external virtual override returns (uint amountToken, uint amountETH) {
        removePermit(removeParams, deadline, approveMax, sigTTE, sigTEE);
        (amountToken, amountETH) = removeLiquidityETH(removeParams, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting deflation tokens) ****
    function removeLiquidityETHFeeOnTransfer(
        RemoveLiquidityParams calldata removeParams,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        require(removeParams.tokenB == WETH,  'FeSwap: WRONG WETH');
        uint amountToken;
        uint balanceToken;
        (amountToken, amountETH) = removeLiquidity( removeParams,    
                                                    address(this),
                                                    deadline );
        balanceToken = IERC20(removeParams.tokenA).balanceOf(address(this));
        if(balanceToken < amountToken) amountToken = balanceToken;
        TransferHelper.safeTransfer(removeParams.tokenA, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityETHWithPermitFeeOnTransfer(
        RemoveLiquidityParams calldata removeParams,
        address to,
        uint deadline,
        bool approveMax, 
        Signature   calldata sigTTE,
        Signature   calldata sigTEE
    ) external virtual override returns (uint amountETH) {
        removePermit(removeParams, deadline, approveMax, sigTTE, sigTEE);
        amountETH = removeLiquidityETHFeeOnTransfer(removeParams, to, deadline);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i = 0; i < path.length - 1; i++) {
            (address tokenInput, address tokenOutput) = (path[i], path[i + 1]);
            uint amountOut = amounts[i + 1];
            address to = i < path.length - 2 ? FeSwapLibrary.pairFor(factory, tokenOutput, path[i + 2]) : _to;
            IFeSwapPair(FeSwapLibrary.pairFor(factory, tokenInput, tokenOutput))
                .swap(amountOut, to, new bytes(0));
        }
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        address firstPair;
        (firstPair, amounts) = FeSwapLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'FeSwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, firstPair , amountIn);
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        address firstPair;
        uint amountsTokenIn;
        (firstPair, amounts) = FeSwapLibrary.getAmountsIn(factory, amountOut, path);
        amountsTokenIn = amounts[0];
        require(amountsTokenIn <= amountInMax, 'FeSwapRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, firstPair, amountsTokenIn);
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external virtual override payable ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'FeSwapRouter: INVALID_PATH');
        address firstPair;
//      uint amountsETHIn = msg.value;
        (firstPair, amounts) = FeSwapLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'FeSwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(firstPair, msg.value));
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external virtual override ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'FeSwapRouter: INVALID_PATH');
        address firstPair;
        (firstPair, amounts) = FeSwapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'FeSwapRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, firstPair, amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external virtual override ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'FeSwapRouter: INVALID_PATH');
        address firstPair;
        uint amountsETHOut;
        (firstPair, amounts) = FeSwapLibrary.getAmountsOut(factory, amountIn, path);
        amountsETHOut = amounts[amounts.length - 1];
        require(amountsETHOut >= amountOutMin, 'FeSwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, firstPair, amountIn);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amountsETHOut);
        TransferHelper.safeTransferETH(to, amountsETHOut);
    }

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external virtual override payable ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'FeSwapRouter: INVALID_PATH');
        address firstPair;
        uint amountsETHIn;
        (firstPair, amounts) = FeSwapLibrary.getAmountsIn(factory, amountOut, path);
        amountsETHIn = amounts[0];
        require(amountsETHIn <= msg.value, 'FeSwapRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amountsETHIn}();
        assert(IWETH(WETH).transfer(firstPair, amountsETHIn));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amountsETHIn) TransferHelper.safeTransferETH(msg.sender, msg.value - amountsETHIn);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapTokensFeeOnTransfer(address[] memory path, address _to) internal virtual {
        for (uint i = 0; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (uint reserveInput, uint reserveOutput, address pair) = FeSwapLibrary.getReserves(factory, input, output);
            uint amountInput = IERC20(input).balanceOf(pair).sub(reserveInput);
            uint amountOutput = FeSwapLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            address to = i < path.length - 2 ? FeSwapLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IFeSwapPair(pair).swap(amountOutput, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensFeeOnTransfer(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        FeSwapLibrary.executeArbitrage(factory, path);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, FeSwapLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapTokensFeeOnTransfer(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'FeSwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensFeeOnTransfer(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) {
        require(path[0] == WETH, 'FeSwapRouter: INVALID_PATH');
        FeSwapLibrary.executeArbitrage(factory, path);
//      uint amountIn = msg.value;
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(FeSwapLibrary.pairFor(factory, path[0], path[1]), msg.value));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapTokensFeeOnTransfer(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'FeSwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHFeeOnTransfer(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == WETH, 'FeSwapRouter: INVALID_PATH');
        FeSwapLibrary.executeArbitrage(factory, path);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, FeSwapLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapTokensFeeOnTransfer(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'FeSwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) 
                public pure virtual override returns (uint amountB) 
    {
        return FeSwapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
                public pure virtual override returns (uint amountOut)
    {
        return FeSwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
                public pure virtual override returns (uint amountIn)
    {
        return FeSwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function estimateAmountsOut(uint amountIn, address[] calldata path)
                public view virtual override returns (uint[] memory amounts)
    {
        return FeSwapLibrary.estimateAmountsOut(factory, amountIn, path);
    }

    function estimateAmountsIn(uint amountOut, address[] calldata path)
                public view virtual override returns (uint[] memory amounts)
    {
        return FeSwapLibrary.estimateAmountsIn(factory, amountOut, path);
    }
}