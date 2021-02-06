/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

pragma solidity >=0.7.0 <0.8.0;

/**
    * @notice this interface is taken from indexed-core commit hash dae7f231d0f58bfc0993f6c01199cd6b74b01895
 */
interface IndexPoolI {
  function getDenormalizedWeight(address token) external view returns (uint256);
  function getBalance(address token) external view returns (uint256);
  function getUsedBalance(address token) external view returns (uint256);
  function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256);    
}

interface ERC20I {
    function totalSupply() external view returns (uint256);
}

/**
    * @notice SimpleMultiCall is a multicall-like contract for reading IndexPool information
    * @notice it is intended to minimize the need for manual abi encoding/decoding
    * @notice and leverage Golang's abigen to do the heavy lifting
 */
contract SimpleMultiCall {

    // index pool methods

    function getDenormalizedWeights(
        address poolAddress,
        address[] memory tokens
    ) 
        public 
        view
        returns (address[] memory, uint256[] memory) 
    {
        uint256[] memory weights = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            weights[i] = IndexPoolI(poolAddress).getDenormalizedWeight(tokens[i]);
        }
        return (tokens, weights);
    }

    function getBalances(
        address poolAddress,
        address[] memory tokens
    ) 
        public 
        view
        returns (address[] memory, uint256[] memory) 
    {
        uint256[] memory balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = IndexPoolI(poolAddress).getBalance(tokens[i]);
        }
        return (tokens, balances);
    }

    function getUsedBalances(
        address poolAddress,
        address[] memory tokens
    ) 
        public 
        view
        returns (address[] memory, uint256[] memory) 
    {
        uint256[] memory balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = IndexPoolI(poolAddress).getUsedBalance(tokens[i]);
        }
        return (tokens, balances);
    }

    function getSpotPrices(
        address poolAddress,
        address[] memory inTokens,
        address[] memory outTokens
    )
        public
        view 
        returns (address[] memory, address[] memory, uint256[] memory)
    {
        require(inTokens.length == outTokens.length);
        uint256[] memory prices = new uint256[](inTokens.length);
        for (uint256 i = 0; i < inTokens.length; i++) {
            prices[i] = IndexPoolI(poolAddress).getSpotPrice(inTokens[i], outTokens[i]);
        }
        return (inTokens, outTokens, prices);
    }

    // erc20 methods

    function getTotalSupplies(
        address[] memory tokens
    )
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256[] memory supplies = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            supplies[i] = ERC20I(tokens[i]).totalSupply();
        }
        return (tokens, supplies);
    }
}