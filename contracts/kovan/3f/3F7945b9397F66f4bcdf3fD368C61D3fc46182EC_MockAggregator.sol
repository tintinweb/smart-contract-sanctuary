/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// File: contracts/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity >=0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
    * @dev Returns the decimals.
    */
    function decimals() external view returns (uint256);
    
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/IUniswapV2Pair.sol


pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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
// File: contracts/MockAggregator.sol


pragma solidity 0.6.12;



contract MockAggregator {
  uint256 private _latestAnswer;
  string public symbol;
  address public addr;
  uint256 public decimals;
  mapping(bytes32=> address) symbolPairs;

  bytes32 ETH=keccak256(abi.encodePacked('ETH'));
  bytes32 DAI=keccak256(abi.encodePacked('DAI'));
  bytes32 WBTC=keccak256(abi.encodePacked('WBTC'));
  bytes32 CHAINLINK=keccak256(abi.encodePacked('CHAINLINK'));

  //dai: token0
  //eth: token1
  address public daiEthPairAddr = 0xc2a84f8e6a1a6011ccE0854C482217def6FbA8eE;
  address public wbtcDAIPairAddr = 0x7a30b9AAe79374c440D5f7A0388696C8bfB76677;
  address public chainlinkDAIPairAddr = 0xCdD4b06f6FF77B8D338FAB21606B8356A1C7ed14;

  constructor(string memory _symbol, uint256 _decimals) public {
    symbolPairs[ETH] = daiEthPairAddr;
    symbolPairs[DAI] = daiEthPairAddr;
    symbolPairs[WBTC] = wbtcDAIPairAddr;
    symbolPairs[CHAINLINK] = chainlinkDAIPairAddr;

    bytes32 symbol_ = keccak256(abi.encodePacked(_symbol));
    require(symbolPairs[symbol_]!= address(0), "not support token symbol!"); 
    symbol = _symbol;
    decimals = _decimals;
  }

  function latestAnswer() external view returns (uint256) {
    bytes32 symbol_ = keccak256(abi.encodePacked(symbol));

    if (symbol_== ETH){
      return getEthDaiPairPrice()*10**decimals;
    } else if (symbol_ == DAI) {
      return 10**decimals/ getEthDaiPairPrice();  
    } else {
      return getTokenPriceToEth(symbolPairs[symbol_]);
    }
  }

   // calculate price based on pair reserves
   function getTokenPriceToDai(address pairAddress) public view returns(uint){
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    IERC20 token0 = IERC20(pair.token0());
    (uint Res0, uint Res1,) = pair.getReserves();
    
    // decimals
    uint res1 = Res1*(10**token0.decimals());
    return (res1/Res0);
   }

   // calculate price based on pair reserves
   function getTokenPriceToEth(address pairAddress) public view returns(uint){
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    IERC20 token0 = IERC20(pair.token0());
    (uint Res0, uint Res1,) = pair.getReserves();
    
    // decimals
    uint res1 = Res1*(10**token0.decimals());
    
    //eg. chainlink: 19988562730373826151
    uint toDaiPrice = res1/Res0;
    return toDaiPrice/getEthDaiPairPrice();
   }


    // calculate price based on pair reserves
   function getEthDaiPairPrice() public view returns(uint){
    IUniswapV2Pair pair = IUniswapV2Pair(daiEthPairAddr);
    IERC20 token1 = IERC20(pair.token1());
    IERC20 token0 = IERC20(pair.token0());
    (uint Res0, uint Res1,) = pair.getReserves();
    
    // decimals
    uint res0 = Res0*(10**token1.decimals());

    //103453
    return((res0)/Res1/10**token0.decimals()); // return amount of token0 needed to buy token1
   }
}