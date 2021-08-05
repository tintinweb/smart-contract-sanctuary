/**
 *Submitted for verification at Etherscan.io on 2020-05-12
*/

pragma solidity ^0.6.0;

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
interface UniswapFactoryInterface {
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
interface IGetBancorAddressFromRegistry {
  function getBancorContractAddresByName(string calldata _name) external view returns (address result);
}
interface IGetRatioForBancorAssets {
  function getRatio(address _from, address _to, uint256 _amount) external view returns(uint256 result);
}


interface BancorConverterInterface {
  function connectorTokens(uint index) external view returns(IERC20);
  function fund(uint256 _amount) external;
  function liquidate(uint256 _amount) external;
  function getConnectorBalance(IERC20 _connectorToken) external view returns (uint256);
}


/*
* This contract allow buy/sell pool for Bancor and Uniswap assets
* and provide ratio and addition info for pool assets
*/




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






interface SmartTokenInterface is IERC20 {
  function disableTransfers(bool _disable) external;
  function issue(address _to, uint256 _amount) external;
  function destroy(address _from, uint256 _amount) external;
  function owner() external view returns (address);
}









contract PoolPortal {
  using SafeMath for uint256;

  IGetRatioForBancorAssets public bancorRatio;
  IGetBancorAddressFromRegistry public bancorRegistry;
  UniswapFactoryInterface public uniswapFactory;

  address public BancorEtherToken;

  // CoTrader platform recognize ETH by this address
  IERC20 constant private ETH_TOKEN_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  // Enum
  // NOTE: You can add a new type at the end, but do not change this order
  enum PortalType { Bancor, Uniswap }

  // events
  event BuyPool(address poolToken, uint256 amount, address trader);
  event SellPool(address poolToken, uint256 amount, address trader);

  // Contract for handle tokens types
  ITokensTypeStorage public tokensTypes;

  /**
  * @dev contructor
  *
  * @param _bancorRegistryWrapper  address of GetBancorAddressFromRegistry
  * @param _bancorRatio            address of GetRatioForBancorAssets
  * @param _bancorEtherToken       address of Bancor ETH wrapper
  * @param _uniswapFactory         address of Uniswap factory contract
  * @param _tokensTypes            address of the ITokensTypeStorage
  */
  constructor(
    address _bancorRegistryWrapper,
    address _bancorRatio,
    address _bancorEtherToken,
    address _uniswapFactory,
    address _tokensTypes

  )
  public
  {
    bancorRegistry = IGetBancorAddressFromRegistry(_bancorRegistryWrapper);
    bancorRatio = IGetRatioForBancorAssets(_bancorRatio);
    BancorEtherToken = _bancorEtherToken;
    uniswapFactory = UniswapFactoryInterface(_uniswapFactory);
    tokensTypes = ITokensTypeStorage(_tokensTypes);
  }


  /**
  * @dev buy Bancor or Uniswap pool
  *
  * @param _amount     amount of pool token
  * @param _type       pool type
  * @param _poolToken  pool token address
  */
  function buyPool
  (
    uint256 _amount,
    uint _type,
    IERC20 _poolToken
  )
  external
  payable
  {
    if(_type == uint(PortalType.Bancor)){
      buyBancorPool(_poolToken, _amount);
    }
    else if (_type == uint(PortalType.Uniswap)){
      require(_amount == msg.value, "Not enough ETH");
      buyUniswapPool(address(_poolToken), _amount);
    }
    else{
      // unknown portal type
      revert();
    }

    emit BuyPool(address(_poolToken), _amount, msg.sender);
  }


  /**
  * @dev helper for buy pool in Bancor network
  *
  * @param _poolToken        address of bancor converter
  * @param _amount           amount of bancor relay
  */
  function buyBancorPool(IERC20 _poolToken, uint256 _amount) private {
    // get Bancor converter
    address converterAddress = getBacorConverterAddressByRelay(address(_poolToken));
    // calculate connectors amount for buy certain pool amount
    (uint256 bancorAmount,
     uint256 connectorAmount) = getBancorConnectorsAmountByRelayAmount(_amount, _poolToken);
    // get converter as contract
    BancorConverterInterface converter = BancorConverterInterface(converterAddress);
    // approve bancor and coonector amount to converter
    // get connectors
    (IERC20 bancorConnector,
    IERC20 ercConnector) = getBancorConnectorsByRelay(address(_poolToken));
    // reset approve (some ERC20 not allow do new approve if already approved)
    bancorConnector.approve(converterAddress, 0);
    ercConnector.approve(converterAddress, 0);
    // transfer from fund and approve to converter
    _transferFromSenderAndApproveTo(bancorConnector, bancorAmount, converterAddress);
    _transferFromSenderAndApproveTo(ercConnector, connectorAmount, converterAddress);
    // buy relay from converter
    converter.fund(_amount);

    require(_amount > 0, "BNT pool recieved amount can not be zerro");

    // transfer relay back to smart fund
    _poolToken.transfer(msg.sender, _amount);

    // transfer connectors back if a small amount remains
    uint256 bancorRemains = bancorConnector.balanceOf(address(this));
    if(bancorRemains > 0)
       bancorConnector.transfer(msg.sender, bancorRemains);

    uint256 ercRemains = ercConnector.balanceOf(address(this));
    if(ercRemains > 0)
        ercConnector.transfer(msg.sender, ercRemains);

    setTokenType(address(_poolToken), "BANCOR_ASSET");
  }


  /**
  * @dev helper for buy pool in Uniswap network
  *
  * @param _poolToken        address of Uniswap exchange
  * @param _ethAmount        ETH amount (in wei)
  */
  function buyUniswapPool(address _poolToken, uint256 _ethAmount)
  private
  returns(uint256 poolAmount)
  {
    // get token address
    address tokenAddress = uniswapFactory.getToken(_poolToken);
    // check if such a pool exist
    if(tokenAddress != address(0x0000000000000000000000000000000000000000)){
      // get tokens amd approve to exchange
      uint256 erc20Amount = getUniswapTokenAmountByETH(tokenAddress, _ethAmount);
      _transferFromSenderAndApproveTo(IERC20(tokenAddress), erc20Amount, _poolToken);
      // get exchange contract
      UniswapExchangeInterface exchange = UniswapExchangeInterface(_poolToken);
      // set deadline
      uint256 deadline = now + 15 minutes;
      // buy pool
      poolAmount = exchange.addLiquidity.value(_ethAmount)(
        1,
        erc20Amount,
        deadline);
      // reset approve (some ERC20 not allow do new approve if already approved)
      IERC20(tokenAddress).approve(_poolToken, 0);

      require(poolAmount > 0, "UNI pool recieved amount can not be zerro");

      // transfer pool token back to smart fund
      IERC20(_poolToken).transfer(msg.sender, poolAmount);
      // transfer ERC20 remains
      uint256 remainsERC = IERC20(tokenAddress).balanceOf(address(this));
      if(remainsERC > 0)
          IERC20(tokenAddress).transfer(msg.sender, remainsERC);

      setTokenType(_poolToken, "UNISWAP_POOL");
    }else{
      // throw if such pool not Exist in Uniswap network
      revert();
    }
  }

  /**
  * @dev return token amount by ETH input ratio
  *
  * @param _token     address of ERC20 token
  * @param _amount    ETH amount (in wei)
  */
  function getUniswapTokenAmountByETH(address _token, uint256 _amount)
    public
    view
    returns(uint256)
  {
    UniswapExchangeInterface exchange = UniswapExchangeInterface(
      uniswapFactory.getExchange(_token));
    return exchange.getTokenToEthOutputPrice(_amount);
  }


  /**
  * @dev sell Bancor or Uniswap pool
  *
  * @param _amount     amount of pool token
  * @param _type       pool type
  * @param _poolToken  pool token address
  */
  function sellPool
  (
    uint256 _amount,
    uint _type,
    IERC20 _poolToken
  )
  external
  payable
  {
    if(_type == uint(PortalType.Bancor)){
      sellPoolViaBancor(_poolToken, _amount);
    }
    else if (_type == uint(PortalType.Uniswap)){
      sellPoolViaUniswap(_poolToken, _amount);
    }
    else{
      // unknown portal type
      revert();
    }

    emit SellPool(address(_poolToken), _amount, msg.sender);
  }

  /**
  * @dev helper for sell pool in Bancor network
  *
  * @param _poolToken        address of bancor relay
  * @param _amount           amount of bancor relay
  */
  function sellPoolViaBancor(IERC20 _poolToken, uint256 _amount) private {
    // transfer pool from fund
    _poolToken.transferFrom(msg.sender, address(this), _amount);
    // get Bancor Converter address
    address converterAddress = getBacorConverterAddressByRelay(address(_poolToken));
    // liquidate relay
    BancorConverterInterface(converterAddress).liquidate(_amount);
    // get connectors
    (IERC20 bancorConnector,
    IERC20 ercConnector) = getBancorConnectorsByRelay(address(_poolToken));
    // transfer connectors back to fund
    bancorConnector.transfer(msg.sender, bancorConnector.balanceOf(address(this)));
    ercConnector.transfer(msg.sender, ercConnector.balanceOf(address(this)));
  }


  /**
  * @dev helper for sell pool in Uniswap network
  *
  * @param _poolToken        address of uniswap exchane
  * @param _amount           amount of uniswap pool
  */
  function sellPoolViaUniswap(IERC20 _poolToken, uint256 _amount) private {
    address tokenAddress = uniswapFactory.getToken(address(_poolToken));
    // check if such a pool exist
    if(tokenAddress != address(0x0000000000000000000000000000000000000000)){
      UniswapExchangeInterface exchange = UniswapExchangeInterface(address(_poolToken));
      // approve pool token
      _transferFromSenderAndApproveTo(IERC20(_poolToken), _amount, address(_poolToken));
      // get min returns
      (uint256 minEthAmount,
        uint256 minErcAmount) = getUniswapConnectorsAmountByPoolAmount(
          _amount,
          address(_poolToken));
      // set deadline
      uint256 deadline = now + 15 minutes;
      // liquidate
      (uint256 eth_amount,
       uint256 token_amount) = exchange.removeLiquidity(
         _amount,
         minEthAmount,
         minErcAmount,
         deadline);
      // transfer assets back to smart fund
      msg.sender.transfer(eth_amount);
      IERC20(tokenAddress).transfer(msg.sender, token_amount);
    }else{
      revert();
    }
  }

  /**
  * @dev helper for get bancor converter by bancor relay addrses
  *
  * @param _relay       address of bancor relay
  */
  function getBacorConverterAddressByRelay(address _relay)
    public
    view
    returns(address converter)
  {
    converter = SmartTokenInterface(_relay).owner();
  }


  /**
  * @dev helper for get Bancor ERC20 connectors addresses
  *
  * @param _relay       address of bancor relay
  */
  function getBancorConnectorsByRelay(address _relay)
    public
    view
    returns(
    IERC20 BNTConnector,
    IERC20 ERCConnector
    )
  {
    address converterAddress = getBacorConverterAddressByRelay(_relay);
    BancorConverterInterface converter = BancorConverterInterface(converterAddress);
    BNTConnector = converter.connectorTokens(0);
    ERCConnector = converter.connectorTokens(1);
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
    return uniswapFactory.getToken(_exchange);
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
    IERC20 token = IERC20(uniswapFactory.getToken(_exchange));
    // total_liquidity exchange.totalSupply
    uint256 totalLiquidity = UniswapExchangeInterface(_exchange).totalSupply();
    // ethAmount = amount * exchane.eth.balance / total_liquidity
    ethAmount = _amount.mul(_exchange.balance).div(totalLiquidity);
    // ercAmount = amount * token.balanceOf(exchane) / total_liquidity
    ercAmount = _amount.mul(token.balanceOf(_exchange)).div(totalLiquidity);
  }


  /**
  * @dev helper for get amount for both Bancor connectors for input amount of pool
  *
  * @param _amount      relay amount
  * @param _relay       address of bancor relay
  */
  function getBancorConnectorsAmountByRelayAmount
  (
    uint256 _amount,
    IERC20 _relay
  )
    public
    view
    returns(uint256 bancorAmount, uint256 connectorAmount)
  {
    // get converter contract
    BancorConverterInterface converter = BancorConverterInterface(
      SmartTokenInterface(address(_relay)).owner());
    // calculate BNT and second connector amount
    // get connectors
    IERC20 bancorConnector = converter.connectorTokens(0);
    IERC20 ercConnector = converter.connectorTokens(1);
    // get connectors balance
    uint256 bntBalance = converter.getConnectorBalance(bancorConnector);
    uint256 ercBalance = converter.getConnectorBalance(ercConnector);
    // get bancor formula contract
    IBancorFormula bancorFormula = IBancorFormula(
      bancorRegistry.getBancorContractAddresByName("BancorFormula"));
    // calculate input
    bancorAmount = bancorFormula.calculateFundCost(
      _relay.totalSupply(),
      bntBalance,
      1000000,
       _amount);
    connectorAmount = bancorFormula.calculateFundCost(
      _relay.totalSupply(),
      ercBalance,
      1000000,
       _amount);
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
    // Change ETH to Bancor ETH wrapper
    address fromAddress = IERC20(_from) == ETH_TOKEN_ADDRESS ? BancorEtherToken : _from;
    address toAddress = IERC20(_to) == ETH_TOKEN_ADDRESS ? BancorEtherToken : _to;
    // return Bancor ratio
    return bancorRatio.getRatio(fromAddress, toAddress, _amount);
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

    _source.approve(_to, _sourceAmount);
  }

  // Pool portal can mark each pool token as UNISWAP or BANCOR
  function setTokenType(address _token, string memory _type) private {
    // no need add type, if token alredy registred
    if(tokensTypes.isRegistred(_token))
      return;

    tokensTypes.addNewTokenType(_token,  _type);
  }

  // fallback payable function to receive ether from other contract addresses
  fallback() external payable {}
}