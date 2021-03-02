/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity >=0.8.0 <0.9.0;

/**
    * @notice this interface is taken from indexed-core commit hash dae7f231d0f58bfc0993f6c01199cd6b74b01895
 */
interface IndexPoolI {
  function getDenormalizedWeight(address token) external view returns (uint256);
  function getBalance(address token) external view returns (uint256);
  function getUsedBalance(address token) external view returns (uint256);
  function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256);
  function getCurrentTokens() external view returns (address[] memory); 
}

interface ERC20I {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
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

    // returns the current tokens held by a pool
    // along with their ERC20 symbol names
    function poolTokensFor(
        address poolAddress
    )
        public view
        returns (address[] memory, string[] memory)
    {
        address[] memory poolTokens = IndexPoolI(poolAddress).getCurrentTokens();
        require(poolTokens.length > 0, "no pool tokens");
        string[] memory symbols = new string[](poolTokens.length);
        for (uint256 i = 0; i < poolTokens.length; i++) {
            symbols[i] = ERC20I(poolTokens[i]).symbol();
        }
        return (poolTokens, symbols);
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

    function getDecimals(
       address[] memory tokens
    )
        public
        view
        returns (address[] memory, uint8[] memory)
    {
        uint8[] memory decimals = new uint8[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            decimals[i] = ERC20I(tokens[i]).decimals();
        }
        return (tokens, decimals);
    }
}