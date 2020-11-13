pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IERC20Token {
	function balanceOf(address) external pure returns (uint256);
}

interface UniswapFactory {
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

interface UniswapV2Pair {
	struct reserves {
		uint112 reserve0;
		uint112 reserve1;
		uint32 blockTimestampLast;
	}
	function getReserves() external view returns (reserves memory);
	function token0() external view returns (address);
	function token1() external view returns (address);
}


contract Oracle {
    
    UniswapFactory public univ2Factory = UniswapFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
    function getPairs(uint256 start) public view returns (address[] memory) {
        uint256 length = univ2Factory.allPairsLength();
        address[] memory out = new address[](length-start);
        for(uint256 i = start; i < length; i++){
            out[i-start] = univ2Factory.allPairs(i);
        }
        return out;
    }
    
    function getAllPairs() public view returns (address[] memory) {
        return getPairs(0);
    }
}