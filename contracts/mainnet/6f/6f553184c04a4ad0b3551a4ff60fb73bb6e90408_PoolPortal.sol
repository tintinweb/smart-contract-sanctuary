pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
interface ITokensTypeStorage {
  function isRegistred(address _address) external view returns(bool);

  function getType(address _address) external view returns(bytes32);

  function isPermittedAddress(address _address) external view returns(bool);

  function owner() external view returns(address);

  function addNewTokenType(address _token, string calldata _type) external;

  function setTokenTypeAsOwner(address _token, string calldata _type) external;
}
interface IBalancerPool {
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;
    function getCurrentTokens() external view returns (address[] memory tokens);
}
interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
}
interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface UniswapFactoryInterfaceV1 {
    // Create Exchange
    function createExchange(address token) external returns (address exchange);
    // Get Exchange and Token Info
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    // Never use
    function initializeFactory(address template) external;
}
interface UniswapExchangeInterface {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);

    // ERC20 comaptibility for liquidity tokens
    function name() external view returns(bytes32);
    function symbol() external view returns(bytes32);
    function decimals() external view returns(uint256);

    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    // Never use
    function setup(address token_addr) external;
}
interface IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _reserveBalance, uint32 _reserveRatio, uint256 _depositAmount) external view returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _reserveBalance, uint32 _reserveRatio, uint256 _sellAmount) external view returns (uint256);
    function calculateCrossReserveReturn(uint256 _fromReserveBalance, uint32 _fromReserveRatio, uint256 _toReserveBalance, uint32 _toReserveRatio, uint256 _amount) external view returns (uint256);
    function calculateFundCost(uint256 _supply, uint256 _reserveBalance, uint32 _totalRatio, uint256 _amount) external view returns (uint256);
    function calculateLiquidateReturn(uint256 _supply, uint256 _reserveBalance, uint32 _totalRatio, uint256 _amount) external view returns (uint256);
}
interface SmartTokenInterface {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function disableTransfers(bool _disable) external;
  function issue(address _to, uint256 _amount) external;
  function destroy(address _from, uint256 _amount) external;
  function owner() external view returns (address);
}


interface IGetBancorData {
  function getBancorContractAddresByName(string calldata _name) external view returns (address result);
  function getBancorRatioForAssets(IERC20 _from, IERC20 _to, uint256 _amount) external view returns(uint256 result);
  function getBancorPathForAssets(IERC20 _from, IERC20 _to) external view returns(address[] memory);
}


interface BancorConverterInterfaceV2 {
  function addLiquidity(address _reserveToken, uint256 _amount, uint256 _minReturn) external payable;
  function removeLiquidity(address _poolToken, uint256 _amount, uint256 _minReturn) external;

  function poolToken(address _reserveToken) external view returns(address);
  function connectorTokenCount() external view returns (uint16);
  function connectorTokens(uint index) external view returns(IERC20);
}


interface BancorConverterInterfaceV1 {

  function addLiquidity(
    address[] calldata _reserveTokens,
    uint256[] calldata _reserveAmounts,
    uint256 _minReturn) external payable;

  function removeLiquidity(
    uint256 _amount,
    address[] calldata _reserveTokens,
    uint256[] calldata _reserveMinReturnAmounts) external;
}


interface BancorConverterInterface {
  function connectorTokens(uint index) external view returns(IERC20);
  function fund(uint256 _amount) external payable;
  function liquidate(uint256 _amount) external;
  function getConnectorBalance(IERC20 _connectorToken) external view returns (uint256);
  function connectorTokenCount() external view returns (uint16);
}


/*
* This contract allow buy/sell pool for Bancor and Uniswap assets
* and provide ratio and addition info for pool assets
*/





/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


















contract PoolPortal is Ownable{
  using SafeMath for uint256;

  uint public version = 4;

  IGetBancorData public bancorData;
  UniswapFactoryInterfaceV1 public uniswapFactoryV1;
  IUniswapV2Router public uniswapV2Router;

  // CoTrader platform recognize ETH by this address
  IERC20 constant private ETH_TOKEN_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  // Enum
  // NOTE: You can add a new type at the end, but do not change this order
  enum PortalType { Bancor, Uniswap, Balancer }

  // events
  event BuyPool(address poolToken, uint256 amount, address trader);
  event SellPool(address poolToken, uint256 amount, address trader);

  // Contract for handle tokens types
  ITokensTypeStorage public tokensTypes;


  /**
  * @dev contructor
  *
  * @param _bancorData               address of helper contract GetBancorData
  * @param _uniswapFactoryV1         address of Uniswap V1 factory contract
  * @param _uniswapV2Router          address of Uniswap V2 router
  * @param _tokensTypes              address of the ITokensTypeStorage
  */
  constructor(
    address _bancorData,
    address _uniswapFactoryV1,
    address _uniswapV2Router,
    address _tokensTypes

  )
  public
  {
    bancorData = IGetBancorData(_bancorData);
    uniswapFactoryV1 = UniswapFactoryInterfaceV1(_uniswapFactoryV1);
    uniswapV2Router = IUniswapV2Router(_uniswapV2Router);
    tokensTypes = ITokensTypeStorage(_tokensTypes);
  }

  /**
  * @dev this function provide necessary data for buy a old BNT and UNI v1 pools by input amount
  *
  * @param _amount     amount of pool token (NOTE: amount of ETH for Uniswap)
  * @param _type       pool type
  * @param _poolToken  pool token address
  */
  function getDataForBuyingPool(IERC20 _poolToken, uint _type, uint256 _amount)
    public
    view
    returns(
      address[] memory connectorsAddress,
      uint256[] memory connectorsAmount
    )
  {
    // Buy Bancor pool
    if(_type == uint(PortalType.Bancor)){
      // get Bancor converter
      address converterAddress = getBacorConverterAddressByRelay(address(_poolToken), 0);
      // get converter as contract
      BancorConverterInterface converter = BancorConverterInterface(converterAddress);
      uint256 connectorsCount = converter.connectorTokenCount();

      // create arrays for data
      connectorsAddress = new address[](connectorsCount);
      connectorsAmount = new uint256[](connectorsCount);

      // push data
      for(uint8 i = 0; i < connectorsCount; i++){
        // get current connector address
        IERC20 currentConnector = converter.connectorTokens(i);
        // push address of current connector
        connectorsAddress[i] = address(currentConnector);
        // push amount for current connector
        connectorsAmount[i] = getBancorConnectorsAmountByRelayAmount(
          _amount, _poolToken, address(currentConnector));
      }
    }
    // Buy Uniswap pool
    else if(_type == uint(PortalType.Uniswap)){
      // get token address
      address tokenAddress = uniswapFactoryV1.getToken(address(_poolToken));
      // get tokens amd approve to exchange
      uint256 erc20Amount = getUniswapTokenAmountByETH(tokenAddress, _amount);

      // return data
      connectorsAddress = new address[](2);
      connectorsAmount = new uint256[](2);
      connectorsAddress[0] = address(ETH_TOKEN_ADDRESS);
      connectorsAddress[1] = tokenAddress;
      connectorsAmount[0] = _amount;
      connectorsAmount[1] = erc20Amount;

    }
    else {
      revert("Unknown pool type");
    }
  }


  /**
  * @dev buy Bancor or Uniswap pool
  *
  * @param _amount             amount of pool token
  * @param _type               pool type
  * @param _poolToken          pool token address (NOTE: for Bancor type 2 don't forget extract pool address from container)
  * @param _connectorsAddress  address of pool connectors (NOTE: for Uniswap ETH should be pass in [0], ERC20 in [1])
  * @param _connectorsAmount   amount of pool connectors (NOTE: for Uniswap ETH amount should be pass in [0], ERC20 in [1])
  * @param _additionalArgs     bytes32 array for case if need pass some extra params, can be empty
  * @param _additionalData     for provide any additional data, if not used just set "0x",
  * for Bancor _additionalData[0] should be converterVersion and _additionalData[1] should be converterType
  *
  */
  function buyPool
  (
    uint256 _amount,
    uint _type,
    address _poolToken,
    address[] calldata _connectorsAddress,
    uint256[] calldata _connectorsAmount,
    bytes32[] calldata _additionalArgs,
    bytes calldata _additionalData
  )
  external
  payable
  returns(uint256 poolAmountReceive, uint256[] memory connectorsSpended)
  {
    // Buy Bancor pool
    if(_type == uint(PortalType.Bancor)){
      (poolAmountReceive) = buyBancorPool(
        _amount,
        _poolToken,
        _connectorsAddress,
        _connectorsAmount,
        _additionalArgs,
        _additionalData
      );
    }
    // Buy Uniswap pool
    else if (_type == uint(PortalType.Uniswap)){
      (poolAmountReceive) = buyUniswapPool(
        _amount,
        _poolToken,
        _connectorsAddress,
        _connectorsAmount,
        _additionalArgs,
        _additionalData
      );
    }
    // Buy Balancer pool
    else if (_type == uint(PortalType.Balancer)){
      (poolAmountReceive) = buyBalancerPool(
        _amount,
        _poolToken,
        _connectorsAddress,
        _connectorsAmount
      );
    }
    else{
      // unknown portal type
      revert("Unknown portal type");
    }

    // transfer pool token to fund
    IERC20(_poolToken).transfer(msg.sender, poolAmountReceive);

    // transfer connectors remains to fund
    // and calculate how much connectors was spended (current - remains)
    connectorsSpended = _transferPoolConnectorsRemains(
      _connectorsAddress,
      _connectorsAmount);

    // trigger event
    emit BuyPool(address(_poolToken), poolAmountReceive, msg.sender);
  }


  /**
  * @dev helper for buying Bancor pool token by a certain converter version and converter type
  * Bancor has 3 cases for different converter version and type
  */
  function buyBancorPool(
    uint256 _amount,
    address _poolToken,
    address[] calldata _connectorsAddress,
    uint256[] calldata _connectorsAmount,
    bytes32[] calldata _additionalArgs,
    bytes calldata _additionalData
  )
    private
    returns(uint256 poolAmountReceive)
  {
    // get Bancor converter address by pool token and pool type
    address converterAddress = getBacorConverterAddressByRelay(
      _poolToken,
      uint256(_additionalArgs[1])
    );

    // transfer from sender and approve to converter
    // for detect if there are ETH in connectors or not we use etherAmount
    uint256 etherAmount = _approvePoolConnectors(
      _connectorsAddress,
      _connectorsAmount,
      converterAddress
    );

    // Buy Bancor pool according converter version and type
    // encode and compare converter version
    if(uint256(_additionalArgs[0]) >= 28) {
      // encode and compare converter type
      if(uint256(_additionalArgs[1]) == 2) {
        // buy Bancor v2 case
        _buyBancorPoolV2(
          converterAddress,
          etherAmount,
          _connectorsAddress,
          _connectorsAmount,
          _additionalData
        );
      } else{
        // buy Bancor v1 case
        _buyBancorPoolV1(
          converterAddress,
          etherAmount,
          _connectorsAddress,
          _connectorsAmount,
          _additionalData
        );
      }
    }
    else {
      // buy Bancor old v0 case
      _buyBancorPoolOldV(
        converterAddress,
        etherAmount,
        _amount
      );
    }

    // get recieved pool amount
    poolAmountReceive = IERC20(_poolToken).balanceOf(address(this));
    // make sure we recieved pool
    require(poolAmountReceive > 0, "ERR BNT pool received 0");
    // set token type for this asset
    tokensTypes.addNewTokenType(_poolToken, "BANCOR_ASSET");
  }


  /**
  * @dev helper for buy pool in Bancor network for old converter version
  */
  function _buyBancorPoolOldV(
    address converterAddress,
    uint256 etherAmount,
    uint256 _amount)
   private
  {
    // get converter as contract
    BancorConverterInterface converter = BancorConverterInterface(converterAddress);
    // buy relay from converter
    if(etherAmount > 0){
      // payable
      converter.fund.value(etherAmount)(_amount);
    }else{
      // non payable
      converter.fund(_amount);
    }
  }


  /**
  * @dev helper for buy pool in Bancor network for new converter type 1
  */
  function _buyBancorPoolV1(
    address converterAddress,
    uint256 etherAmount,
    address[] calldata _connectorsAddress,
    uint256[] calldata _connectorsAmount,
    bytes memory _additionalData
  )
    private
  {
    BancorConverterInterfaceV1 converter = BancorConverterInterfaceV1(converterAddress);
    // get additional data
    (uint256 minReturn) = abi.decode(_additionalData, (uint256));
    // buy relay from converter
    if(etherAmount > 0){
      // payable
      converter.addLiquidity.value(etherAmount)(_connectorsAddress, _connectorsAmount, minReturn);
    }else{
      // non payable
      converter.addLiquidity(_connectorsAddress, _connectorsAmount, minReturn);
    }
  }

  /**
  * @dev helper for buy pool in Bancor network for new converter type 2
  */
  function _buyBancorPoolV2(
    address converterAddress,
    uint256 etherAmount,
    address[] calldata _connectorsAddress,
    uint256[] calldata _connectorsAmount,
    bytes memory _additionalData
  )
    private
  {
    // get converter as contract
    BancorConverterInterfaceV2 converter = BancorConverterInterfaceV2(converterAddress);
    // get additional data
    (uint256 minReturn) = abi.decode(_additionalData, (uint256));

    // buy relay from converter
    if(etherAmount > 0){
      // payable
      converter.addLiquidity.value(etherAmount)(_connectorsAddress[0], _connectorsAmount[0], minReturn);
    }else{
      // non payable
      converter.addLiquidity(_connectorsAddress[0], _connectorsAmount[0], minReturn);
    }
  }


  /**
  * @dev helper for buying Uniswap v1 or v2 pool
  */
  function buyUniswapPool(
    uint256 _amount,
    address _poolToken,
    address[] calldata _connectorsAddress,
    uint256[] calldata _connectorsAmount,
    bytes32[] calldata _additionalArgs,
    bytes calldata _additionalData
  )
   private
   returns(uint256 poolAmountReceive)
  {
    // define spender dependse of UNI pool version
    address spender = uint256(_additionalArgs[0]) == 1
    ? _poolToken
    : address(uniswapV2Router);

    // approve pool tokens to Uni pool exchange
    _approvePoolConnectors(
      _connectorsAddress,
      _connectorsAmount,
      spender);

    // Buy Uni pool dependse of version
    if(uint256(_additionalArgs[0]) == 1){
      _buyUniswapPoolV1(
        _poolToken,
        _connectorsAddress[1], // connector ERC20 token address
        _connectorsAmount[1],  // connector ERC20 token amount
        _amount);
    }else{
      _buyUniswapPoolV2(
        _poolToken,
        _connectorsAddress,
        _connectorsAmount,
        _additionalData
        );
    }
    // get pool amount
    poolAmountReceive = IERC20(_poolToken).balanceOf(address(this));
    // check if we recieved pool token
    require(poolAmountReceive > 0, "ERR UNI pool received 0");
  }


  /**
  * @dev helper for buy pool in Uniswap network v1
  *
  * @param _poolToken        address of Uniswap exchange
  * @param _tokenAddress     address of ERC20 conenctor
  * @param _erc20Amount      amount of ERC20 connector
  * @param _ethAmount        ETH amount (in wei)
  */
  function _buyUniswapPoolV1(
    address _poolToken,
    address _tokenAddress,
    uint256 _erc20Amount,
    uint256 _ethAmount
  )
   private
  {
    require(_ethAmount == msg.value, "Not enough ETH");
    // get exchange contract
    UniswapExchangeInterface exchange = UniswapExchangeInterface(_poolToken);
    // set deadline
    uint256 deadline = now + 15 minutes;
    // buy pool
    exchange.addLiquidity.value(_ethAmount)(
      1,
      _erc20Amount,
      deadline
    );
    // Set token type
    tokensTypes.addNewTokenType(_poolToken, "UNISWAP_POOL");
  }


  /**
  * @dev helper for buy pool in Uniswap network v2
  */
  function _buyUniswapPoolV2(
    address _poolToken,
    address[] calldata _connectorsAddress,
    uint256[] calldata _connectorsAmount,
    bytes calldata _additionalData
  )
   private
  {
    // set deadline
    uint256 deadline = now + 15 minutes;
    // get additional data
    (uint256 amountAMinReturn,
      uint256 amountBMinReturn) = abi.decode(_additionalData, (uint256, uint256));

    // Buy UNI V2 pool
    // ETH connector case
    if(_connectorsAddress[0] == address(ETH_TOKEN_ADDRESS)){
      uniswapV2Router.addLiquidityETH.value(_connectorsAmount[0])(
       _connectorsAddress[1],
       _connectorsAmount[1],
       amountBMinReturn,
       amountAMinReturn,
       address(this),
       deadline
      );
    }
    // ERC20 connector case
    else{
      uniswapV2Router.addLiquidity(
        _connectorsAddress[0],
        _connectorsAddress[1],
        _connectorsAmount[0],
        _connectorsAmount[1],
        amountAMinReturn,
        amountBMinReturn,
        address(this),
        deadline
      );
    }
    // Set token type
    tokensTypes.addNewTokenType(_poolToken, "UNISWAP_POOL_V2");
  }


  /**
  * @dev helper for buying Balancer pool
  */
  function buyBalancerPool(
    uint256 _amount,
    address _poolToken,
    address[] calldata _connectorsAddress,
    uint256[] calldata _connectorsAmount
  )
    private
    returns(uint256 poolAmountReceive)
  {
    // approve pool tokens to Balancer pool exchange
    _approvePoolConnectors(
      _connectorsAddress,
      _connectorsAmount,
      _poolToken);
    // buy pool
    IBalancerPool(_poolToken).joinPool(_amount, _connectorsAmount);
    // get balance
    poolAmountReceive = IERC20(_poolToken).balanceOf(address(this));
    // check
    require(poolAmountReceive > 0, "ERR BALANCER pool received 0");
    // update type
    tokensTypes.addNewTokenType(_poolToken, "BALANCER_POOL");
  }

  /**
  * @dev helper for buying BNT or UNI pools, approve connectors from msg.sender to spender address
  * return ETH amount if connectorsAddress contains ETH address
  */
  function _approvePoolConnectors(
    address[] memory connectorsAddress,
    uint256[] memory connectorsAmount,
    address spender
  )
    private
    returns(uint256 etherAmount)
  {
    // approve from portal to spender
    for(uint8 i = 0; i < connectorsAddress.length; i++){
      if(connectorsAddress[i] != address(ETH_TOKEN_ADDRESS)){
        // transfer from msg.sender and approve to
        _transferFromSenderAndApproveTo(
          IERC20(connectorsAddress[i]),
          connectorsAmount[i],
          spender);
      }else{
        etherAmount = connectorsAmount[i];
      }
    }
  }

  /**
  * @dev helper for buying BNT or UNI pools, transfer ERC20 tokens and ETH remains after bying pool,
  * if the balance is positive on this contract, and calculate how many assets was spent.
  */
  function _transferPoolConnectorsRemains(
    address[] memory connectorsAddress,
    uint256[] memory currentConnectorsAmount
  )
    private
    returns (uint256[] memory connectorsSpended)
  {
    // set length for connectorsSpended
    connectorsSpended = new uint256[](currentConnectorsAmount.length);

    // transfer connectors back to fund if some amount remains
    uint256 remains = 0;
    for(uint8 i = 0; i < connectorsAddress.length; i++){
      // ERC20 case
      if(connectorsAddress[i] != address(ETH_TOKEN_ADDRESS)){
        // check balance
        remains = IERC20(connectorsAddress[i]).balanceOf(address(this));
        // transfer ERC20
        if(remains > 0)
           IERC20(connectorsAddress[i]).transfer(msg.sender, remains);
      }
      // ETH case
      else {
        remains = address(this).balance;
        // transfer ETH
        if(remains > 0)
           (msg.sender).transfer(remains);
      }

      // calculate how many assets was spent
      connectorsSpended[i] = currentConnectorsAmount[i].sub(remains);
    }
  }

  /**
  * @dev return token ration in ETH in Uniswap network
  *
  * @param _token     address of ERC20 token
  * @param _amount    ETH amount
  */
  function getUniswapTokenAmountByETH(address _token, uint256 _amount)
    public
    view
    returns(uint256)
  {
    UniswapExchangeInterface exchange = UniswapExchangeInterface(
      uniswapFactoryV1.getExchange(_token));

    return exchange.getTokenToEthOutputPrice(_amount);
  }


  /**
  * @dev sell Bancor or Uniswap pool
  *
  * @param _amount            amount of pool token
  * @param _type              pool type
  * @param _poolToken         pool token address
  * @param _additionalArgs    bytes32 array for case if need pass some extra params, can be empty
  * @param _additionalData    for provide any additional data, if not used just set "0x"
  */
  function sellPool
  (
    uint256 _amount,
    uint _type,
    IERC20 _poolToken,
    bytes32[] calldata _additionalArgs,
    bytes calldata _additionalData
  )
  external
  returns(
    address[] memory connectorsAddress,
    uint256[] memory connectorsAmount
  )
  {
    // sell Bancor Pool
    if(_type == uint(PortalType.Bancor)){
      (connectorsAddress, connectorsAmount) = sellBancorPool(
         _amount,
         _poolToken,
        _additionalArgs,
        _additionalData);
    }
    // sell Uniswap pool
    else if (_type == uint(PortalType.Uniswap)){
      (connectorsAddress, connectorsAmount) = sellUniswapPool(
        _poolToken,
        _amount,
        _additionalArgs,
        _additionalData);
    }
    // sell Balancer pool
    else if (_type == uint(PortalType.Balancer)){
      (connectorsAddress, connectorsAmount) = sellBalancerPool(
        _amount,
        _poolToken,
        _additionalData);
    }
    else{
      revert("Unknown portal type");
    }

    emit SellPool(address(_poolToken), _amount, msg.sender);
  }



  /**
  * @dev helper for sell pool in Bancor network dependse of converter version and type
  */
  function sellBancorPool(
    uint256 _amount,
    IERC20 _poolToken,
    bytes32[] calldata _additionalArgs,
    bytes calldata _additionalData
  )
  private
  returns(
    address[] memory connectorsAddress,
    uint256[] memory connectorsAmount
  )
  {
    // transfer pool from fund
    _poolToken.transferFrom(msg.sender, address(this), _amount);

    // get Bancor converter version and type
    uint256 bancorPoolVersion = uint256(_additionalArgs[0]);
    uint256 bancorConverterType = uint256(_additionalArgs[1]);

    // sell pool according converter version and type
    if(bancorPoolVersion >= 28){
      // sell new Bancor v2 pool
      if(bancorConverterType == 2){
        (connectorsAddress) = sellPoolViaBancorV2(
          _poolToken,
          _amount,
          _additionalData
        );
      }
      // sell new Bancor v1 pool
      else{
        (connectorsAddress) = sellPoolViaBancorV1(_poolToken, _amount, _additionalData);
      }
    }
    // sell old Bancor pool
    else{
      (connectorsAddress) = sellPoolViaBancorOldV(_poolToken, _amount);
    }

    // transfer pool connectors back to fund
    connectorsAmount = transferConnectorsToSender(connectorsAddress);
  }

  /**
  * @dev helper for sell pool in Bancor network for old converter version
  *
  * @param _poolToken        address of bancor relay
  * @param _amount           amount of bancor relay
  */
  function sellPoolViaBancorOldV(IERC20 _poolToken, uint256 _amount)
   private
   returns(address[] memory connectorsAddress)
  {
    // get Bancor Converter instance
    address converterAddress = getBacorConverterAddressByRelay(address(_poolToken), 0);
    BancorConverterInterface converter = BancorConverterInterface(converterAddress);

    // liquidate relay
    converter.liquidate(_amount);

    // return connectors addresses
    uint256 connectorsCount = converter.connectorTokenCount();
    connectorsAddress = new address[](connectorsCount);

    for(uint8 i = 0; i<connectorsCount; i++){
      connectorsAddress[i] = address(converter.connectorTokens(i));
    }
  }


  /**
  * @dev helper for sell pool in Bancor network converter type v1
  */
  function sellPoolViaBancorV1(
    IERC20 _poolToken,
    uint256 _amount,
    bytes memory _additionalData
  )
   private
   returns(address[] memory connectorsAddress)
  {
    // get Bancor Converter address
    address converterAddress = getBacorConverterAddressByRelay(address(_poolToken), 1);
    // get min returns
    uint256[] memory reserveMinReturnAmounts;
    // get connetor tokens data for remove liquidity
    (connectorsAddress, reserveMinReturnAmounts) = abi.decode(_additionalData, (address[], uint256[]));
    // get coneverter v1 contract
    BancorConverterInterfaceV1 converter = BancorConverterInterfaceV1(converterAddress);
    // remove liquidity (v1)
    converter.removeLiquidity(_amount, connectorsAddress, reserveMinReturnAmounts);
  }

  /**
  * @dev helper for sell pool in Bancor network converter type v2
  */
  function sellPoolViaBancorV2(
    IERC20 _poolToken,
    uint256 _amount,
    bytes calldata _additionalData
  )
   private
   returns(address[] memory connectorsAddress)
  {
    // get Bancor Converter address
    address converterAddress = getBacorConverterAddressByRelay(address(_poolToken), 2);
    // get converter v2 contract
    BancorConverterInterfaceV2 converter = BancorConverterInterfaceV2(converterAddress);
    // get additional data
    uint256 minReturn;
    // get pool connectors
    (connectorsAddress, minReturn) = abi.decode(_additionalData, (address[], uint256));
    // remove liquidity (v2)
    converter.removeLiquidity(address(_poolToken), _amount, minReturn);
  }

  /**
  * @dev helper for sell pool in Uniswap network for v1 and v2
  */
  function sellUniswapPool(
    IERC20 _poolToken,
    uint256 _amount,
    bytes32[] calldata _additionalArgs,
    bytes calldata _additionalData
  )
   private
   returns(
     address[] memory connectorsAddress,
     uint256[] memory connectorsAmount
  )
  {
    // define spender dependse of UNI pool version
    address spender = uint256(_additionalArgs[0]) == 1
    ? address(_poolToken)
    : address(uniswapV2Router);

    // approve pool token
    _transferFromSenderAndApproveTo(_poolToken, _amount, spender);

    // sell Uni v1 or v2 pool
    if(uint256(_additionalArgs[0]) == 1){
      (connectorsAddress) = sellPoolViaUniswapV1(_poolToken, _amount);
    }else{
      (connectorsAddress) = sellPoolViaUniswapV2(_amount, _additionalData);
    }

    // transfer pool connectors back to fund
    connectorsAmount = transferConnectorsToSender(connectorsAddress);
  }


  /**
  * @dev helper for sell pool in Uniswap network v1
  */
  function sellPoolViaUniswapV1(
    IERC20 _poolToken,
    uint256 _amount
  )
    private
    returns(address[] memory connectorsAddress)
  {
    // get token by pool token
    address tokenAddress = uniswapFactoryV1.getToken(address(_poolToken));
    // check if such a pool exist
    if(tokenAddress != address(0x0000000000000000000000000000000000000000)){
      // get UNI exchane
      UniswapExchangeInterface exchange = UniswapExchangeInterface(address(_poolToken));

      // get min returns
      (uint256 minEthAmount,
       uint256 minErcAmount) = getUniswapConnectorsAmountByPoolAmount(_amount, address(_poolToken));

      // set deadline
      uint256 deadline = now + 15 minutes;

      // liquidate
      exchange.removeLiquidity(
         _amount,
         minEthAmount,
         minErcAmount,
         deadline);

      // return data
      connectorsAddress = new address[](2);
      connectorsAddress[0] = address(ETH_TOKEN_ADDRESS);
      connectorsAddress[1] = tokenAddress;
    }
    else{
      revert("Not exist UNI v1 pool");
    }
  }

  /**
  * @dev helper for sell pool in Uniswap network v2
  */
  function sellPoolViaUniswapV2(
    uint256 _amount,
    bytes calldata _additionalData
  )
    private
    returns(address[] memory connectorsAddress)
  {
    // get additional data
    uint256 minReturnA;
    uint256 minReturnB;

    // get connectors and min return from bytes
    (connectorsAddress,
      minReturnA,
      minReturnB) = abi.decode(_additionalData, (address[], uint256, uint256));

    // get deadline
    uint256 deadline = now + 15 minutes;

    // sell pool with include eth connector
    if(connectorsAddress[0] == address(ETH_TOKEN_ADDRESS)){
      uniswapV2Router.removeLiquidityETH(
          connectorsAddress[1],
          _amount,
          minReturnB,
          minReturnA,
          address(this),
          deadline
      );
    }
    // sell pool only with erc20 connectors
    else{
      uniswapV2Router.removeLiquidity(
          connectorsAddress[0],
          connectorsAddress[1],
          _amount,
          minReturnA,
          minReturnB,
          address(this),
          deadline
      );
    }
  }

  /**
  * @dev helper for sell Balancer pool
  */

  function sellBalancerPool(
    uint256 _amount,
    IERC20 _poolToken,
    bytes calldata _additionalData
  )
  private
  returns(
    address[] memory connectorsAddress,
    uint256[] memory connectorsAmount
  )
  {
    // get additional data
    uint256[] memory minConnectorsAmount;
    (connectorsAddress,
      minConnectorsAmount) = abi.decode(_additionalData, (address[], uint256[]));
    // approve pool
    _transferFromSenderAndApproveTo(
      _poolToken,
      _amount,
      address(_poolToken));
    // sell pool
    IBalancerPool(address(_poolToken)).exitPool(_amount, minConnectorsAmount);
    // transfer connectors back to fund
    connectorsAmount = transferConnectorsToSender(connectorsAddress);
  }

  /**
  * @dev helper for sell Bancor and Uniswap pools
  * transfer pool connectors from sold pool back to sender
  * return array with amount of recieved connectors
  */
  function transferConnectorsToSender(address[] memory connectorsAddress)
    private
    returns(uint256[] memory connectorsAmount)
  {
    // define connectors amount length
    connectorsAmount = new uint256[](connectorsAddress.length);

    uint256 received = 0;
    // transfer connectors back to fund
    for(uint8 i = 0; i < connectorsAddress.length; i++){
      // ETH case
      if(connectorsAddress[i] == address(ETH_TOKEN_ADDRESS)){
        // update ETH data
        received = address(this).balance;
        connectorsAmount[i] = received;
        // tarnsfer ETH
        if(received > 0)
          payable(msg.sender).transfer(received);
      }
      // ERC20 case
      else{
        // update ERC20 data
        received = IERC20(connectorsAddress[i]).balanceOf(address(this));
        connectorsAmount[i] = received;
        // transfer ERC20
        if(received > 0)
          IERC20(connectorsAddress[i]).transfer(msg.sender, received);
      }
    }
  }

  /**
  * @dev helper for get bancor converter by bancor relay addrses
  *
  * @param _relay       address of bancor relay
  * @param _poolType    bancor pool type
  */
  function getBacorConverterAddressByRelay(address _relay, uint256 _poolType)
    public
    view
    returns(address converter)
  {
    if(_poolType == 2){
      address smartTokenContainer = SmartTokenInterface(_relay).owner();
      converter = SmartTokenInterface(smartTokenContainer).owner();
    }else{
      converter = SmartTokenInterface(_relay).owner();
    }
  }


  /**
  * @dev return ERC20 address from Uniswap exchange address
  *
  * @param _exchange       address of uniswap exchane
  */
  function getTokenByUniswapExchange(address _exchange)
    external
    view
    returns(address)
  {
    return uniswapFactoryV1.getToken(_exchange);
  }


  /**
  * @dev helper for get amounts for both Uniswap connectors for input amount of pool
  *
  * @param _amount         relay amount
  * @param _exchange       address of uniswap exchane
  */
  function getUniswapConnectorsAmountByPoolAmount(
    uint256 _amount,
    address _exchange
  )
    public
    view
    returns(uint256 ethAmount, uint256 ercAmount)
  {
    IERC20 token = IERC20(uniswapFactoryV1.getToken(_exchange));
    // total_liquidity exchange.totalSupply
    uint256 totalLiquidity = UniswapExchangeInterface(_exchange).totalSupply();
    // ethAmount = amount * exchane.eth.balance / total_liquidity
    ethAmount = _amount.mul(_exchange.balance).div(totalLiquidity);
    // ercAmount = amount * token.balanceOf(exchane) / total_liquidity
    ercAmount = _amount.mul(token.balanceOf(_exchange)).div(totalLiquidity);
  }

  /**
  * @dev helper for get amounts for both Uniswap connectors for input amount of pool
  * for Uniswap version 2
  *
  * @param _amount         pool amount
  * @param _exchange       address of uniswap exchane
  */
  function getUniswapV2ConnectorsAmountByPoolAmount(
    uint256 _amount,
    address _exchange
  )
    public
    view
    returns(
      uint256 tokenAmountOne,
      uint256 tokenAmountTwo,
      address tokenAddressOne,
      address tokenAddressTwo
    )
  {
    tokenAddressOne = IUniswapV2Pair(_exchange).token0();
    tokenAddressTwo = IUniswapV2Pair(_exchange).token1();
    // total_liquidity exchange.totalSupply
    uint256 totalLiquidity = IERC20(_exchange).totalSupply();
    // ethAmount = amount * exchane.eth.balance / total_liquidity
    tokenAmountOne = _amount.mul(IERC20(tokenAddressOne).balanceOf(_exchange)).div(totalLiquidity);
    // ercAmount = amount * token.balanceOf(exchane) / total_liquidity
    tokenAmountTwo = _amount.mul(IERC20(tokenAddressTwo).balanceOf(_exchange)).div(totalLiquidity);
  }


  /**
  * @dev helper for get amounts all Balancer connectors for input amount of pool
  * for Balancer
  *
  * step 1 get all tokens
  * step 2 get user amount from each token by a user pool share
  *
  * @param _amount         pool amount
  * @param _pool           address of balancer pool
  */
  function getBalancerConnectorsAmountByPoolAmount(
    uint256 _amount,
    address _pool
  )
    public
    view
    returns(
      address[] memory tokens,
      uint256[] memory tokensAmount
    )
  {
    IBalancerPool balancerPool = IBalancerPool(_pool);
    // get all pool tokens
    tokens = balancerPool.getCurrentTokens();
    // set tokens amount length
    tokensAmount = new uint256[](tokens.length);
    // get total pool shares
    uint256 totalShares = IERC20(_pool).totalSupply();
    // calculate all tokens from the pool
    for(uint i = 0; i < tokens.length; i++){
      // get a certain total token amount in pool
      uint256 totalTokenAmount = IERC20(tokens[i]).balanceOf(_pool);
      // get a certain pool share (_amount) from a certain token amount in pool
      tokensAmount[i] = totalTokenAmount.mul(_amount).div(totalShares);
    }
  }


  /**
  * @dev helper for get value in pool for a certain connector address
  *
  * @param _amount      relay amount
  * @param _relay       address of bancor relay
  * @param _connector   address of relay connector
  */
  function getBancorConnectorsAmountByRelayAmount
  (
    uint256 _amount,
    IERC20  _relay,
    address _connector
  )
    public
    view
    returns(uint256 connectorAmount)
  {
    // get converter contract
    BancorConverterInterface converter = BancorConverterInterface(
      SmartTokenInterface(address(_relay)).owner());

    // get connector balance
    uint256 connectorBalance = converter.getConnectorBalance(IERC20(_connector));

    // get bancor formula contract
    IBancorFormula bancorFormula = IBancorFormula(
      bancorData.getBancorContractAddresByName("BancorFormula"));

    // calculate input
    connectorAmount = bancorFormula.calculateFundCost(
      _relay.totalSupply(),
      connectorBalance,
      1000000,
       _amount);
  }


  /**
  * @dev helper for get Bancor ERC20 connectors addresses for old Bancor version
  *
  * @param _relay       address of bancor relay
  */
  function getBancorConnectorsByRelay(address _relay)
    public
    view
    returns(
    IERC20[] memory connectors
    )
  {
    address converterAddress = getBacorConverterAddressByRelay(_relay, 0);
    BancorConverterInterface converter = BancorConverterInterface(converterAddress);
    uint256 connectorTokenCount = converter.connectorTokenCount();
    connectors = new IERC20[](connectorTokenCount);

    for(uint8 i; i < connectorTokenCount; i++){
      connectors[i] = converter.connectorTokens(i);
    }
  }


  /**
  * @dev helper for get ratio between assets in bancor newtork
  *
  * @param _from      token or relay address
  * @param _to        token or relay address
  * @param _amount    amount from
  */
  function getBancorRatio(address _from, address _to, uint256 _amount)
  external
  view
  returns(uint256)
  {
    // return Bancor ratio
    return bancorData.getBancorRatioForAssets(IERC20(_from), IERC20(_to), _amount);
  }

  // owner of portal can change getBancorData helper, for case if Bancor do some major updates
  function setNewGetBancorData(address _bancorData) public onlyOwner {
    bancorData = IGetBancorData(_bancorData);
  }


  /**
  * @dev Transfers tokens to this contract and approves them to another address
  *
  * @param _source          Token to transfer and approve
  * @param _sourceAmount    The amount to transfer and approve (in _source token)
  * @param _to              Address to approve to
  */
  function _transferFromSenderAndApproveTo(IERC20 _source, uint256 _sourceAmount, address _to) private {
    require(_source.transferFrom(msg.sender, address(this), _sourceAmount));
    // reset previous approve (some ERC20 not allow do new approve if already approved)
    _source.approve(_to, 0);
    // approve
    _source.approve(_to, _sourceAmount);
  }

  // fallback payable function to receive ether from other contract addresses
  fallback() external payable {}
}