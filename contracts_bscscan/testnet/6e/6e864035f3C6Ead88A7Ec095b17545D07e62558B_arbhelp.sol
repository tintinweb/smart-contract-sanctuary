/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

// SPDX-License-Identifier: MIXED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

contract arbhelp is BoringOwnable{

    address public lastSender;
    uint256 public lastSize;

    function testFun(uint size) public {
        lastSender = msg.sender;
        lastSize = size;
    }

    function pairReserves(address[] calldata pairs) public view returns(uint256[] memory reserves) {
        reserves = new uint[](2*pairs.length);
        for(uint i=0;i<pairs.length;i++){
            (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pairs[i]).getReserves();
            reserves[2*i]=reserve0;
            reserves[2*i+1]=reserve1;
        }
    }


    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getProfit(uint amountIn, address baseToken,address pair0,address pair1) external view returns (uint amountOut) {
        address token00 = IUniswapV2Pair(pair0).token0();
        address token01 = IUniswapV2Pair(pair0).token1();
        (uint256 reserve00,uint256 reserve01,) = IUniswapV2Pair(pair0).getReserves();
        address token10 = IUniswapV2Pair(pair1).token0();
        address token11 = IUniswapV2Pair(pair1).token1();
        (uint256 reserve10,uint256 reserve11,) = IUniswapV2Pair(pair1).getReserves();
        address quoteToken;
        uint256 quoteOut;
        if(baseToken==token00){
            quoteToken = token01;
            quoteOut=getAmountOut(amountIn,reserve00,reserve01);
        }else if(baseToken==token01){
            quoteToken = token00;
            quoteOut=getAmountOut(amountIn,reserve01,reserve00);
        }else{
            revert("xx");
        }
        if(quoteToken==token10 && baseToken == token11){
            amountOut = getAmountOut(quoteOut,reserve10,reserve11);
        }else if(quoteToken==token11 && baseToken == token10){
            amountOut = getAmountOut(quoteOut,reserve11,reserve10);
        }else{
            revert("xx");
        }
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 9975;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn*10000+amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn*amountOut*10000;
        uint denominator = (reserveOut-amountOut)*9975;
        amountIn = (numerator / denominator)+1;
    }

}