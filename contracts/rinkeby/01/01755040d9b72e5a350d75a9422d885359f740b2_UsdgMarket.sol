/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity =0.6.6;

/**
 * Math operations with safety checks
 */
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IUniswapV2Pair {
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
}

interface IUniswapV3Pool {
    function observe(uint32[] calldata secondsAgos)
    external
    view
    returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    function observations(uint256 index)
    external
    view
    returns (
        uint32 blockTimestamp,
        int56 tickCumulative,
        uint160 secondsPerLiquidityCumulativeX128,
        bool initialized
    );
}



contract UsdgMarket is Ownable{
    IUniswapV2Pair public pair;
    IUniswapV3Pool public pool;


    constructor(address _pool)public {
//        pair = IUniswapV2Pair(_pair);
        pool = IUniswapV3Pool(_pool);
    }
    function observe(uint32[] calldata secondsAgos)
    external
    view
    returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s){
        return pool.observe(secondsAgos);
    }

    function observe2(uint32 secondsAgo)
    external
    view
    returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s){
        uint32[] memory secondsAgos = new uint32[](1);
        secondsAgos[0] = secondsAgo;
        return pool.observe(secondsAgos);
    }

    function observe3(uint32 secondsAgo)
    external
    view
    returns (uint160 secondsPerLiquidityCumulativeX128s){
        uint32[] memory secondsAgos = new uint32[](1);
        secondsAgos[0] = secondsAgo;

        (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) =
        pool.observe(secondsAgos);
        return secondsPerLiquidityCumulativeX128s[0];
    }

    function observe4(uint32 secondsAgo)
    external
    view
    returns (int56 tickCumulatives){
        uint32[] memory secondsAgos = new uint32[](1);
        secondsAgos[0] = secondsAgo;
        (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) =
        pool.observe(secondsAgos);
        return tickCumulatives[0];
    }

    function observations(uint256 index) external view returns (
        uint32 blockTimestamp,
        int56 tickCumulative,
        uint160 secondsPerLiquidityCumulativeX128,
        bool initialized
    ){
        return pool.observations(index);
    }
    function observationsBlock(uint256 index) external view returns (
        uint32 blockTimestamp
    ){
    (
    uint32 blockTimestamp,
    int56 tickCumulative,
    uint160 secondsPerLiquidityCumulativeX128,
    bool initialized
    ) =  pool.observations(index);
    return blockTimestamp;
    }

    function observationsTick(uint256 index) external view returns (
        int56 tickCumulative
    ){
        (
        uint32 blockTimestamp,
        int56 tickCumulative,
        uint160 secondsPerLiquidityCumulativeX128,
        bool initialized
        ) =  pool.observations(index);
        return tickCumulative;
    }
    function observationsTickSecond(uint256 index) external view returns (
        uint160 secondsPerLiquidityCumulativeX128
    ){
    (
    uint32 blockTimestamp,
    int56 tickCumulative,
    uint160 secondsPerLiquidityCumulativeX128,
    bool initialized
    ) =  pool.observations(index);
    return secondsPerLiquidityCumulativeX128;
    }

//    function price0CumulativeLast() external view returns (uint){
//        return pair.price0CumulativeLast();
//    }
//
//    function price1CumulativeLast() external view returns (uint){
//        return pair.price1CumulativeLast();
//    }
//
//    function token0() external view returns (address){
//        return pair.token0();
//    }
//    function token1() external view returns (address){
//        return pair.token1();
//    }
//    function factory() external view returns (address){
//        return pair.factory();
//    }


}