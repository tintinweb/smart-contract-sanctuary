// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

pragma solidity 0.8.3;

import "./IUniswapV3Factory.sol";
import "./IUniswapV3LPFactory.sol";
import "./IUniswapV3LPToken.sol";
import "./ITickHelper.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

import "./UniswapV3LPToken.sol";

contract UniswapV3LPFactory is Ownable{
    using EnumerableSet for EnumerableSet.AddressSet;

    address public uniswapV3Factory;
    address public WETH9;
    address public tickHelper;

    mapping(address => mapping(address => mapping(uint24 => address))) public getLPToken;

    uint256 public NUM_TOKENS;
    EnumerableSet.AddressSet private LP_TOKENS; 


    event LPTokenCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        address lpToken,
        address pool
    );
    event UpdatedTickHelper(address newTickHelper);

    constructor(address _uniswapV3Factory, address _WETH9, address _tickHelper) {
        require(_uniswapV3Factory != address(0));
        require(_WETH9 != address(0));
        require(_tickHelper != address(0));
        uniswapV3Factory = _uniswapV3Factory;
        WETH9 = _WETH9;
        tickHelper = _tickHelper;
        emit UpdatedTickHelper(_tickHelper);
    }

    /// @notice Creates a pool for the given two tokens and fee, or updates a pool if it already exists. Creates an LP token.
    /// @param _token0 One of the two tokens in the desired pool
    /// @param _token1 The other of the two tokens in the desired pool
    /// @param _fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0.
    /// The call will revert if the fee is invalid, or the token arguments
    /// are invalid.
    /// @return lpToken The address of the newly created LP Token
    function createOrUpdatePool(address _token0, address _token1, uint24 _fee) external returns (address lpToken) {
        require(IUniswapV3Factory(uniswapV3Factory).feeAmountTickSpacing(_fee) > 0, "Invalid fee selected");
        require(_token0 != address(0));
        require(_token1 != address(0));
        require(getLPToken[_token0][_token1][_fee] == address(0));

        address pool = IUniswapV3Factory(uniswapV3Factory).getPool(_token0, _token1, _fee);

        if(pool == address(0)){
           pool = IUniswapV3Factory(uniswapV3Factory).createPool(_token0, _token1, _fee); 
        } 

        UniswapV3LPToken lpTokenContract = new UniswapV3LPToken("Unicryipt Uniswap V3 LP","UNCX-UNI-V3-LP", _token0, _token1, _fee, pool, WETH9);
        lpToken = address(lpTokenContract);
        getLPToken[_token0][_token1][_fee] = lpToken;
        getLPToken[_token1][_token0][_fee] = lpToken;
        NUM_TOKENS++;
        LP_TOKENS.add(lpToken);

        setTicksOnLPToken(lpToken, _fee);

        emit LPTokenCreated(_token0, _token1, _fee, lpToken, pool);
    }

    /// @notice Returns the LP Token address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param _token0 The contract address of either token0 or token1
    /// @param _token1 The contract address of the other token
    /// @param _fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return lpToken The pool address
    function getLPTokenAddress(address _token0, address _token1, uint24 _fee) external view returns (address) {
        return getLPToken[_token0][_token1][_fee];
    }

    /// @dev sets ticks on LP token. Called upon creation
    function setTicksOnLPToken(address lpTokenAddress, uint24 fee) internal {
        IUniswapV3LPToken lpToken = IUniswapV3LPToken(lpTokenAddress);
        ITickHelper tickHelperContract = ITickHelper(tickHelper);
        int24 tickUpper = tickHelperContract.getMaxTick(fee);
        int24 tickLower = tickHelperContract.getMinTick(fee);
        lpToken.setTicks(tickUpper, tickLower);
    }

    /// @notice Sets the address for the current or desired TickHelper Contract
    /// @dev called only when updating the TickHelper Contract
    /// @param _newtickHelper address of the new contract
    function updateTickHelper(address _newtickHelper) external onlyOwner {
        require(_newtickHelper != address(0));
        tickHelper = _newtickHelper;
        emit UpdatedTickHelper(_newtickHelper);
    }    

    /// @notice Returns the LP Token address for a given index
    /// @dev Use NUM_TOKENS to get the array length, then iterate through the array with this function
    /// @param _index The index
    /// @return lpToken The pool address
    function getLPTokenByIndex(uint256 _index) external view returns (address lpToken) {
        return LP_TOKENS.at(_index);
    }

    /// @notice Returns the LP Token length
    /// @return lpToken array length
    function getLPTokenLength() external view returns (uint256) {
        return LP_TOKENS.length();
    }

    /// @notice Used to check if a lpToken address was generated by the Unicrypt Uniswap V3 Factory
    /// @param _lpToken lpToken address
    /// @return true if generated by this factory
    function isLPToken(address _lpToken) external view returns (bool) {
        return LP_TOKENS.contains(_lpToken);
    }

}