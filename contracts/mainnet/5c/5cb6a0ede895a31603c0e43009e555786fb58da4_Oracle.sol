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

contract Oracle {
    
    UniswapFactory public univ2Factory = UniswapFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
    function getPairs(uint256 start, uint256 cnt) public view returns (address[] memory) {
        address[] memory out = new address[](cnt);
        for(uint256 i = 0; i < cnt; i++){
            out[i] = univ2Factory.allPairs(i+start);
        }
        return out;
    }
}