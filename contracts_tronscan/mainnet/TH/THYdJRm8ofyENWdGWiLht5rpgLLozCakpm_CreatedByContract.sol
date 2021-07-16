//SourceUnit: IJustswapExchange.sol

pragma solidity ^0.5.8;

interface IJustswapExchange {
  event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);
  event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);
  event AddLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
  event RemoveLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);

   /**
   * @notice Convert TRX to Tokens.
   * @dev User specifies exact input (msg.value).
   * @dev User cannot specify minimum output or deadline.
   */
  function () external payable;

 /**
   * @dev Pricing function for converting between TRX && Tokens.
   * @param input_amount Amount of TRX or Tokens being sold.
   * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
   * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
   * @return Amount of TRX or Tokens bought.
   */
  function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);

 /**
   * @dev Pricing function for converting between TRX && Tokens.
   * @param output_amount Amount of TRX or Tokens being bought.
   * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
   * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
   * @return Amount of TRX or Tokens sold.
   */
  function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);


  /** 
   * @notice Convert TRX to Tokens.
   * @dev User specifies exact input (msg.value) && minimum output.
   * @param min_tokens Minimum Tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of Tokens bought.
   */ 
  function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);

  /** 
   * @notice Convert TRX to Tokens && transfers Tokens to recipient.
   * @dev User specifies exact input (msg.value) && minimum output
   * @param min_tokens Minimum Tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output Tokens.
   * @return  Amount of Tokens bought.
   */
  function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns(uint256);


  /** 
   * @notice Convert TRX to Tokens.
   * @dev User specifies maximum input (msg.value) && exact output.
   * @param tokens_bought Amount of tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of TRX sold.
   */
  function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns(uint256);
  /** 
   * @notice Convert TRX to Tokens && transfers Tokens to recipient.
   * @dev User specifies maximum input (msg.value) && exact output.
   * @param tokens_bought Amount of tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output Tokens.
   * @return Amount of TRX sold.
   */
  function trxToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256);

  /** 
   * @notice Convert Tokens to TRX.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_trx Minimum TRX purchased.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of TRX bought.
   */
  function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline) external returns (uint256);

  /** 
   * @notice Convert Tokens to TRX && transfers TRX to recipient.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_trx Minimum TRX purchased.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output TRX.
   * @return  Amount of TRX bought.
   */
  function tokenToTrxTransferInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline, address recipient) external returns (uint256);

  /** 
   * @notice Convert Tokens to TRX.
   * @dev User specifies maximum input && exact output.
   * @param trx_bought Amount of TRX purchased.
   * @param max_tokens Maximum Tokens sold.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of Tokens sold.
   */
  function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline) external returns (uint256);

  /**
   * @notice Convert Tokens to TRX && transfers TRX to recipient.
   * @dev User specifies maximum input && exact output.
   * @param trx_bought Amount of TRX purchased.
   * @param max_tokens Maximum Tokens sold.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output TRX.
   * @return Amount of Tokens sold.
   */
  function tokenToTrxTransferOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256);

  /**
   * @notice Convert Tokens (token) to Tokens (token_addr).
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_trx_bought Minimum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token_addr) bought.
   */
  function tokenToTokenSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_trx_bought, 
    uint256 deadline, 
    address token_addr) 
    external returns (uint256);

  /**
   * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
   *         Tokens (token_addr) to recipient.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_trx_bought Minimum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output TRX.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token_addr) bought.
   */
  function tokenToTokenTransferInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_trx_bought, 
    uint256 deadline, 
    address recipient, 
    address token_addr) 
    external returns (uint256);


  /**
   * @notice Convert Tokens (token) to Tokens (token_addr).
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_trx_sold Maximum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToTokenSwapOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_trx_sold, 
    uint256 deadline, 
    address token_addr) 
    external returns (uint256);

  /**
   * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
   *         Tokens (token_addr) to recipient.
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_trx_sold Maximum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output TRX.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToTokenTransferOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_trx_sold, 
    uint256 deadline, 
    address recipient, 
    address token_addr) 
    external returns (uint256);

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_trx_bought Minimum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (exchange_addr.token) bought.
   */
  function tokenToExchangeSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_trx_bought, 
    uint256 deadline, 
    address exchange_addr) 
    external returns (uint256);

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
   *         Tokens (exchange_addr.token) to recipient.
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_trx_bought Minimum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output TRX.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (exchange_addr.token) bought.
   */
  function tokenToExchangeTransferInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_trx_bought, 
    uint256 deadline, 
    address recipient, 
    address exchange_addr) 
    external returns (uint256);

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_trx_sold Maximum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToExchangeSwapOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_trx_sold, 
    uint256 deadline, 
    address exchange_addr) 
    external returns (uint256);

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
   *         Tokens (exchange_addr.token) to recipient.
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_trx_sold Maximum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output TRX.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToExchangeTransferOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_trx_sold, 
    uint256 deadline, 
    address recipient, 
    address exchange_addr) 
    external returns (uint256);


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @notice external price function for TRX to Token trades with an exact input.
   * @param trx_sold Amount of TRX sold.
   * @return Amount of Tokens that can be bought with input TRX.
   */
  function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);

  /**
   * @notice external price function for TRX to Token trades with an exact output.
   * @param tokens_bought Amount of Tokens bought.
   * @return Amount of TRX needed to buy output Tokens.
   */
  function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);

  /**
   * @notice external price function for Token to TRX trades with an exact input.
   * @param tokens_sold Amount of Tokens sold.
   * @return Amount of TRX that can be bought with input Tokens.
   */
  function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);

  /**
   * @notice external price function for Token to TRX trades with an exact output.
   * @param trx_bought Amount of output TRX.
   * @return Amount of Tokens needed to buy output TRX.
   */
  function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);

  /** 
   * @return Address of Token that is sold on this exchange.
   */
  function tokenAddress() external view returns (address);

  /**
   * @return Address of factory that created this exchange.
   */
  function factoryAddress() external view returns (address);


  /***********************************|
  |        Liquidity Functions        |
  |__________________________________*/

  /** 
   * @notice Deposit TRX && Tokens (token) at current ratio to mint UNI tokens.
   * @dev min_liquidity does nothing when total UNI supply is 0.
   * @param min_liquidity Minimum number of UNI sender will mint if total UNI supply is greater than 0.
   * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total UNI supply is 0.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return The amount of UNI minted.
   */
  function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);

  /**
   * @dev Burn UNI tokens to withdraw TRX && Tokens at current ratio.
   * @param amount Amount of UNI burned.
   * @param min_trx Minimum TRX withdrawn.
   * @param min_tokens Minimum Tokens withdrawn.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return The amount of TRX && Tokens withdrawn.
   */
  function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
}

//SourceUnit: IJustswapFactory.sol

pragma solidity ^0.5.8;

interface IJustswapFactory {
  event NewExchange(address indexed token, address indexed exchange);

  function initializeFactory(address template) external;
  function createExchange(address token) external returns (address payable);
  function getExchange(address token) external view returns (address payable);
  function getToken(address token) external view returns (address);
  function getTokenWihId(uint256 token_id) external view returns (address);
}

//SourceUnit: ITRC20.sol

pragma solidity ^0.5.8;

/**
 * @title TRC20 interface
 */
interface ITRC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: JustswapExchange.sol

pragma solidity ^0.5.8;
import "./TRC20.sol";
import "./ITRC20.sol";
import "./IJustswapFactory.sol";
import "./IJustswapExchange.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";



contract JustswapExchange is TRC20,ReentrancyGuard {

  /***********************************|
  |        Variables && Events        |
  |__________________________________*/

  // Variables
  string public name;         // Justswap V1
  string public symbol;       // JUSTSWAP-V1
  uint256 public decimals;     // 6
  ITRC20 token;                // address of the TRC20 token traded on this contract
  IJustswapFactory factory;     // interface for the factory that created this contract
  using TransferHelper for address;

  // Events
  event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);
  event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);
  event AddLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
  event RemoveLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
  event Snapshot(address indexed operator, uint256 indexed trx_balance, uint256 indexed token_balance);


  /***********************************|
  |            Constsructor           |
  |__________________________________*/

  /**
   * @dev This function acts as a contract constructor which is not currently supported in contracts deployed
   *      using create_with_code_of(). It is called once by the factory during contract creation.
   */
  function setup(address token_addr) public {
    require(
      address(factory) == address(0) && address(token) == address(0) && token_addr != address(0),
      "INVALID_ADDRESS"
    );
    factory = IJustswapFactory(msg.sender);
    token = ITRC20(token_addr);
    name = "Justswap V1";
    symbol = "JUSTSWAP-V1";
    decimals = 6;
  }


  /***********************************|
  |        Exchange Functions         |
  |__________________________________*/


  /**
   * @notice Convert TRX to Tokens.
   * @dev User specifies exact input (msg.value).
   * @dev User cannot specify minimum output or deadline.
   */
  function () external payable {
    trxToTokenInput(msg.value, 1, block.timestamp, msg.sender, msg.sender);
  }

  /**
    * @dev Pricing function for converting between TRX && Tokens.
    * @param input_amount Amount of TRX or Tokens being sold.
    * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
    * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
    * @return Amount of TRX or Tokens bought.
    */

  // ȥ��������amount=input_amount*997=input_amount_with_fee
  // new_output_reserve=output_reserve-output_amount
  // new_input_reserve=input_reserve+amount
  // new_output_reserve*new_input_reserve=output_reserve*input_reserve=�����Kֵ
  // new_output_reserve*new_input_reserve=(output_reserve-output_amount)*(input_reserve+amount)
  // x*y=(x-a)*(y+b)
  // => x*y=x*y+x*b-a*y-a*b => a*y+a*b=x*b => a*(y+b)=x*b
  // => a=x*b/(y+b)
  // output_amount = output_reserve*input_amount_with_fee/(input_reserve+input_amount_with_fee)
  function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public view returns (uint256) {
    require(input_reserve > 0 && output_reserve > 0, "INVALID_VALUE");
    uint256 input_amount_with_fee = input_amount.mul(997);
    uint256 numerator = input_amount_with_fee.mul(output_reserve);
    uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
    return numerator.div(denominator);

  }

  /**
    * @dev Pricing function for converting between TRX && Tokens.
    * @param output_amount Amount of TRX or Tokens being bought.
    * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
    * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
    * @return Amount of TRX or Tokens sold.
    */
  // new_output_reserve=output_reserve-output_amount
  // new_input_reserve=input_reserve+input_amount
  // new_output_reserve*new_input_reserve=output_reserve*input_reserve=�����Kֵ
  // new_output_reserve*new_input_reserve=(output_reserve-output_amount)*(input_reserve+input_amount)
  // x*y=(x-a)*(y+b)
  // => x*y=x*y+x*b-a*y-a*b => a*y=x*b-a*b => a*y=(x-a)*b
  // => b=y*a/(x-a)
  // input_amount = input_reserve*output_amount/(output_reserve-output_amount)
  // real_intput_amount=input_amount/0.997+1
  function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) public view returns (uint256) {
    require(input_reserve > 0 && output_reserve > 0);
    uint256 numerator = input_reserve.mul(output_amount).mul(1000);
    uint256 denominator = (output_reserve.sub(output_amount)).mul(997);
    return (numerator.div(denominator)).add(1);
  }

  function trxToTokenInput(uint256 trx_sold, uint256 min_tokens, uint256 deadline, address buyer, address recipient) private nonReentrant returns (uint256) {
    require(deadline >= block.timestamp && trx_sold > 0 && min_tokens > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 tokens_bought = getInputPrice(trx_sold, address(this).balance.sub(trx_sold), token_reserve);
    require(tokens_bought >= min_tokens);

    require(address(token).safeTransfer(address(recipient),tokens_bought));
    emit TokenPurchase(buyer, trx_sold, tokens_bought);
    emit Snapshot(buyer,address(this).balance,token.balanceOf(address(this)));
    return tokens_bought;
  }

  /**
   * @notice Convert TRX to Tokens.
   * @dev User specifies exact input (msg.value) && minimum output.
   * @param min_tokens Minimum Tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of Tokens bought.
   */
  function  trxToTokenSwapInput(uint256 min_tokens, uint256 deadline)  public payable returns (uint256)  {
    return trxToTokenInput(msg.value, min_tokens, deadline, msg.sender, msg.sender);
  }

  /**
   * @notice Convert TRX to Tokens && transfers Tokens to recipient.
   * @dev User specifies exact input (msg.value) && minimum output
   * @param min_tokens Minimum Tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output Tokens.
   * @return  Amount of Tokens bought.
   */
  function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) public payable returns(uint256) {
    require(recipient != address(this) && recipient != address(0));
    return trxToTokenInput(msg.value, min_tokens, deadline, msg.sender, recipient);
  }

  function trxToTokenOutput(uint256 tokens_bought, uint256 max_trx, uint256 deadline, address payable buyer, address recipient) private nonReentrant returns (uint256) {
    require(deadline >= block.timestamp && tokens_bought > 0 && max_trx > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 trx_sold = getOutputPrice(tokens_bought, address(this).balance.sub(max_trx), token_reserve);
    // Throws if trx_sold > max_trx
    uint256 trx_refund = max_trx.sub(trx_sold);
    if (trx_refund > 0) {
      buyer.transfer(trx_refund);
    }

    require(address(token).safeTransfer(recipient,tokens_bought));
    emit TokenPurchase(buyer, trx_sold, tokens_bought);
    emit Snapshot(buyer,address(this).balance,token.balanceOf(address(this)));
    return trx_sold;
  }

  /**
   * @notice Convert TRX to Tokens.
   * @dev User specifies maximum input (msg.value) && exact output.
   * @param tokens_bought Amount of tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of TRX sold.
   */
  function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) public payable returns(uint256) {
    return trxToTokenOutput(tokens_bought, msg.value, deadline, msg.sender, msg.sender);
  }

  /**
   * @notice Convert TRX to Tokens && transfers Tokens to recipient.
   * @dev User specifies maximum input (msg.value) && exact output.
   * @param tokens_bought Amount of tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output Tokens.
   * @return Amount of TRX sold.
   */
  function trxToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) public payable returns (uint256) {
    require(recipient != address(this) && recipient != address(0));
    //ͨ��msg.value���ƻ��� , �����trx����
    return trxToTokenOutput(tokens_bought, msg.value, deadline, msg.sender, recipient);
  }

  // 997 * tokens_sold / 1000 =  ����
  // 3 * tokens_sold / 1000 = fee
  // tokens_reserve +  (997 * tokens_sold / 1000) = trx_reserve - x
  // x = ?
  // token_amount = token_reserve*trx_amount/(trx_reserve-trx_amount)
  // real_token_amount=toekn_amount/0.997+1

  function tokenToTrxInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline, address buyer, address payable recipient) private nonReentrant returns (uint256) {
    require(deadline >= block.timestamp && tokens_sold > 0 && min_trx > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 trx_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
    uint256 wei_bought = trx_bought;
    require(wei_bought >= min_trx);
    recipient.transfer(wei_bought);

    require(address(token).safeTransferFrom(buyer, address(this), tokens_sold));
    emit TrxPurchase(buyer, tokens_sold, wei_bought);
    emit Snapshot(buyer,address(this).balance,token.balanceOf(address(this)));

    return wei_bought;
  }

  /**
   * @notice Convert Tokens to TRX.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_trx Minimum TRX purchased.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of TRX bought.
   */
  function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline) public returns (uint256) {
    return tokenToTrxInput(tokens_sold, min_trx, deadline, msg.sender, msg.sender);
  }

  /**
   * @notice Convert Tokens to TRX && transfers TRX to recipient.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_trx Minimum TRX purchased.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output TRX.
   * @return  Amount of TRX bought.
   */
  function tokenToTrxTransferInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline, address payable recipient) public returns (uint256) {
    require(recipient != address(this) && recipient != address(0));
    return tokenToTrxInput(tokens_sold, min_trx, deadline, msg.sender, recipient);
  }


  function tokenToTrxOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline, address buyer, address payable recipient) private nonReentrant returns (uint256) {
    require(deadline >= block.timestamp && trx_bought > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 tokens_sold = getOutputPrice(trx_bought, token_reserve, address(this).balance);
    // tokens sold is always > 0
    require(max_tokens >= tokens_sold);
    recipient.transfer(trx_bought);

    require(address(token).safeTransferFrom(buyer, address(this), tokens_sold));
    emit TrxPurchase(buyer, tokens_sold, trx_bought);
    emit Snapshot(buyer,address(this).balance,token.balanceOf(address(this)));
    return tokens_sold;
  }

  /**
   * @notice Convert Tokens to TRX.
   * @dev User specifies maximum input && exact output.
   * @param trx_bought Amount of TRX purchased.
   * @param max_tokens Maximum Tokens sold.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of Tokens sold.
   */
  function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline) public returns (uint256) {
    return tokenToTrxOutput(trx_bought, max_tokens, deadline, msg.sender, msg.sender);
  }

  /**
   * @notice Convert Tokens to TRX && transfers TRX to recipient.
   * @dev User specifies maximum input && exact output.
   * @param trx_bought Amount of TRX purchased.
   * @param max_tokens Maximum Tokens sold.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output TRX.
   * @return Amount of Tokens sold.
   */
  function tokenToTrxTransferOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline, address payable recipient) public returns (uint256) {
    require(recipient != address(this) && recipient != address(0));
    return tokenToTrxOutput(trx_bought, max_tokens, deadline, msg.sender, recipient);
  }

  function tokenToTokenInput(
    uint256 tokens_sold,
    uint256 min_tokens_bought,
    uint256 min_trx_bought,
    uint256 deadline,
    address buyer,
    address recipient,
    address payable exchange_addr)
  nonReentrant
  private returns (uint256)
  {
    require(deadline >= block.timestamp && tokens_sold > 0 && min_tokens_bought > 0 && min_trx_bought > 0, "illegal input parameters");
    require(exchange_addr != address(this) && exchange_addr != address(0), "illegal exchange addr");
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 trx_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
    uint256 wei_bought = trx_bought;
    require(wei_bought >= min_trx_bought, "min trx bought not matched");

    require(address(token).safeTransferFrom(buyer, address(this), tokens_sold), "transfer failed");
    uint256 tokens_bought = IJustswapExchange(exchange_addr).trxToTokenTransferInput.value(wei_bought)(min_tokens_bought, deadline, recipient);
    emit TrxPurchase(buyer, tokens_sold, wei_bought);
    emit Snapshot(buyer,address(this).balance,token.balanceOf(address(this)));
    return tokens_bought;
  }

  /**
   * @notice Convert Tokens (token) to Tokens (token_addr).
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_trx_bought Minimum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token_addr) bought.
   */
  function tokenToTokenSwapInput(
    uint256 tokens_sold,
    uint256 min_tokens_bought,
    uint256 min_trx_bought,
    uint256 deadline,
    address token_addr)
  public returns (uint256)
  {
    address payable exchange_addr = factory.getExchange(token_addr);
    return tokenToTokenInput(tokens_sold, min_tokens_bought, min_trx_bought, deadline, msg.sender, msg.sender, exchange_addr);
  }

  /**
   * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
   *         Tokens (token_addr) to recipient.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_trx_bought Minimum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output TRX.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token_addr) bought.
   */
  function tokenToTokenTransferInput(
    uint256 tokens_sold,
    uint256 min_tokens_bought,
    uint256 min_trx_bought,
    uint256 deadline,
    address recipient,
    address token_addr)
  public returns (uint256)
  {
    address payable exchange_addr = factory.getExchange(token_addr);
    return tokenToTokenInput(tokens_sold, min_tokens_bought, min_trx_bought, deadline, msg.sender, recipient, exchange_addr);
  }

  function tokenToTokenOutput(
    uint256 tokens_bought,
    uint256 max_tokens_sold,
    uint256 max_trx_sold,
    uint256 deadline,
    address buyer,
    address recipient,
    address payable exchange_addr)
  nonReentrant
  private returns (uint256)
  {
    require(deadline >= block.timestamp && (tokens_bought > 0 && max_trx_sold > 0), "illegal input parameters");
    require(exchange_addr != address(this) && exchange_addr != address(0), "illegal exchange addr");
    uint256 trx_bought = IJustswapExchange(exchange_addr).getTrxToTokenOutputPrice(tokens_bought);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 tokens_sold = getOutputPrice(trx_bought, token_reserve, address(this).balance);
    // tokens sold is always > 0
    require(max_tokens_sold >= tokens_sold && max_trx_sold >= trx_bought, "max token sold not matched");

    require(address(token).safeTransferFrom(buyer, address(this), tokens_sold), "transfer failed");
    uint256 trx_sold = IJustswapExchange(exchange_addr).trxToTokenTransferOutput.value(trx_bought)(tokens_bought, deadline, recipient);
    emit TrxPurchase(buyer, tokens_sold, trx_bought);
    emit Snapshot(buyer,address(this).balance,token.balanceOf(address(this)));
    return tokens_sold;
  }

  /**
   * @notice Convert Tokens (token) to Tokens (token_addr).
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_trx_sold Maximum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToTokenSwapOutput(
    uint256 tokens_bought,
    uint256 max_tokens_sold,
    uint256 max_trx_sold,
    uint256 deadline,
    address token_addr)
  public returns (uint256)
  {
    address payable exchange_addr = factory.getExchange(token_addr);
    return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_trx_sold, deadline, msg.sender, msg.sender, exchange_addr);
  }

  /**
   * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
   *         Tokens (token_addr) to recipient.
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_trx_sold Maximum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output TRX.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToTokenTransferOutput(
    uint256 tokens_bought,
    uint256 max_tokens_sold,
    uint256 max_trx_sold,
    uint256 deadline,
    address recipient,
    address token_addr)
  public returns (uint256)
  {
    address payable exchange_addr = factory.getExchange(token_addr);
    return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_trx_sold, deadline, msg.sender, recipient, exchange_addr);
  }

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_trx_bought Minimum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (exchange_addr.token) bought.
   */
  function tokenToExchangeSwapInput(
    uint256 tokens_sold,
    uint256 min_tokens_bought,
    uint256 min_trx_bought,
    uint256 deadline,
    address payable exchange_addr)
  public returns (uint256)
  {
    return tokenToTokenInput(tokens_sold, min_tokens_bought, min_trx_bought, deadline, msg.sender, msg.sender, exchange_addr);
  }

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
   *         Tokens (exchange_addr.token) to recipient.
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_trx_bought Minimum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output TRX.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (exchange_addr.token) bought.
   */
  function tokenToExchangeTransferInput(
    uint256 tokens_sold,
    uint256 min_tokens_bought,
    uint256 min_trx_bought,
    uint256 deadline,
    address recipient,
    address payable exchange_addr)
  public returns (uint256)
  {
    require(recipient != address(this), "illegal recipient");
    return tokenToTokenInput(tokens_sold, min_tokens_bought, min_trx_bought, deadline, msg.sender, recipient, exchange_addr);
  }

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_trx_sold Maximum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToExchangeSwapOutput(
    uint256 tokens_bought,
    uint256 max_tokens_sold,
    uint256 max_trx_sold,
    uint256 deadline,
    address payable exchange_addr)
  public returns (uint256)
  {
    return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_trx_sold, deadline, msg.sender, msg.sender, exchange_addr);
  }

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
   *         Tokens (exchange_addr.token) to recipient.
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_trx_sold Maximum TRX purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output TRX.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToExchangeTransferOutput(
    uint256 tokens_bought,
    uint256 max_tokens_sold,
    uint256 max_trx_sold,
    uint256 deadline,
    address recipient,
    address payable exchange_addr)
  public returns (uint256)
  {
    require(recipient != address(this), "illegal recipient");
    return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_trx_sold, deadline, msg.sender, recipient, exchange_addr);
  }


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @notice Public price function for TRX to Token trades with an exact input.
   * @param trx_sold Amount of TRX sold.
   * @return Amount of Tokens that can be bought with input TRX.
   */
  function getTrxToTokenInputPrice(uint256 trx_sold) public view returns (uint256) {
    require(trx_sold > 0, "trx sold must greater than 0");
    uint256 token_reserve = token.balanceOf(address(this));
    return getInputPrice(trx_sold, address(this).balance, token_reserve);
  }

  /**
   * @notice Public price function for TRX to Token trades with an exact output.
   * @param tokens_bought Amount of Tokens bought.
   * @return Amount of TRX needed to buy output Tokens.
   */
  function getTrxToTokenOutputPrice(uint256 tokens_bought) public view returns (uint256) {
    require(tokens_bought > 0, "tokens bought must greater than 0");
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 trx_sold = getOutputPrice(tokens_bought, address(this).balance, token_reserve);
    return trx_sold;
  }

  /**
   * @notice Public price function for Token to TRX trades with an exact input.
   * @param tokens_sold Amount of Tokens sold.
   * @return Amount of TRX that can be bought with input Tokens.
   */
  function getTokenToTrxInputPrice(uint256 tokens_sold) public view returns (uint256) {
    require(tokens_sold > 0, "tokens sold must greater than 0");
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 trx_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
    return trx_bought;
  }

  /**
   * @notice Public price function for Token to TRX trades with an exact output.
   * @param trx_bought Amount of output TRX.
   * @return Amount of Tokens needed to buy output TRX.
   */
  function getTokenToTrxOutputPrice(uint256 trx_bought) public view returns (uint256) {
    require(trx_bought > 0, "trx bought must greater than 0");
    uint256 token_reserve = token.balanceOf(address(this));
    return getOutputPrice(trx_bought, token_reserve, address(this).balance);
  }

  /**
   * @return Address of Token that is sold on this exchange.
   */
  function tokenAddress() public view returns (address) {
    return address(token);
  }

  /**
   * @return Address of factory that created this exchange.
   */
  function factoryAddress() public view returns (address) {
    return address(factory);
  }


  /***********************************|
  |        Liquidity Functions        |
  |__________________________________*/

  /**
   * @notice Deposit TRX && Tokens (token) at current ratio to mint JUSTSWAP tokens.
   * @dev min_liquidity does nothing when total JUSTSWAP supply is 0.
   * @param min_liquidity Minimum number of JUSTSWAP sender will mint if total JUSTSWAP supply is greater than 0.
   * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total JUSTSWAP supply is 0.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return The amount of JUSTSWAP minted.
   */
  function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) public payable nonReentrant returns (uint256) {
    require(deadline > block.timestamp && max_tokens > 0 && msg.value > 0, 'JustExchange#addLiquidity: INVALID_ARGUMENT');
    uint256 total_liquidity = _totalSupply;

    if (total_liquidity > 0) {
      require(min_liquidity > 0, "min_liquidity must greater than 0");
      uint256 trx_reserve = address(this).balance.sub(msg.value);
      uint256 token_reserve = token.balanceOf(address(this));
      uint256 token_amount = (msg.value.mul(token_reserve).div(trx_reserve)).add(1);
      uint256 liquidity_minted = msg.value.mul(total_liquidity).div(trx_reserve);

      require(max_tokens >= token_amount && liquidity_minted >= min_liquidity, "max tokens not meet or liquidity_minted not meet min_liquidity");
      _balances[msg.sender] = _balances[msg.sender].add(liquidity_minted);
      _totalSupply = total_liquidity.add(liquidity_minted);

      require(address(token).safeTransferFrom(msg.sender, address(this), token_amount), "transfer failed");
      emit AddLiquidity(msg.sender, msg.value, token_amount);
      emit Snapshot(msg.sender,address(this).balance,token.balanceOf(address(this)));
      emit Transfer(address(0), msg.sender, liquidity_minted);
      return liquidity_minted;

    } else {
      require(address(factory) != address(0) && address(token) != address(0) && msg.value >= 10_000_000, "INVALID_VALUE");
      require(factory.getExchange(address(token)) == address(this), "token address not meet exchange");
      uint256 token_amount = max_tokens;
      uint256 initial_liquidity = address(this).balance;
      _totalSupply = initial_liquidity;
      _balances[msg.sender] = initial_liquidity;

      require(address(token).safeTransferFrom(msg.sender, address(this), token_amount), "tranfer failed");
      emit AddLiquidity(msg.sender, msg.value, token_amount);
      emit Snapshot(msg.sender,address(this).balance,token.balanceOf(address(this)));
      emit Transfer(address(0), msg.sender, initial_liquidity);
      return initial_liquidity;
    }
  }

  /**
   * @dev Burn JUSTSWAP tokens to withdraw TRX && Tokens at current ratio.
   * @param amount Amount of JUSTSWAP burned.
   * @param min_trx Minimum TRX withdrawn.
   * @param min_tokens Minimum Tokens withdrawn.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return The amount of TRX && Tokens withdrawn.
   */
  function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens, uint256 deadline) public nonReentrant returns (uint256, uint256) {
    require(amount > 0 && deadline > block.timestamp && min_trx > 0 && min_tokens > 0, "illegal input parameters");
    uint256 total_liquidity = _totalSupply;
    require(total_liquidity > 0, "total_liquidity must greater than 0");
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 trx_amount = amount.mul(address(this).balance) / total_liquidity;
    uint256 token_amount = amount.mul(token_reserve) / total_liquidity;
    require(trx_amount >= min_trx && token_amount >= min_tokens, "min_token or min_trx not meet");

    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    _totalSupply = total_liquidity.sub(amount);
    msg.sender.transfer(trx_amount);

    require(address(token).safeTransfer(msg.sender, token_amount), "transfer failed");
    emit RemoveLiquidity(msg.sender, trx_amount, token_amount);
    emit Snapshot(msg.sender,address(this).balance,token.balanceOf(address(this)));
    emit Transfer(msg.sender, address(0), amount);
    return (trx_amount, token_amount);
  }


}


//SourceUnit: ReentrancyGuard.sol

pragma solidity ^0.5.8;
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;
    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
        _;
        // By storing the original value once again, a refund is triggered (see
        _notEntered = true;
    }
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
}

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }

}

//SourceUnit: TRC20.sol

pragma solidity ^0.5.8;
import "./SafeMath.sol";


/**
 * @title Standard TRC20 token
 *
 * @dev Implementation of the basic standard token.
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract TRC20 {
  using SafeMath for uint256;

  mapping (address => uint256) internal _balances;
  mapping (address => mapping (address => uint256)) internal _allowed;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  uint256 internal _totalSupply;

  /**
    * @dev Total number of tokens in existence
    */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return A uint256 representing the amount owned by the passed address.
    */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  /**
    * @dev Transfer token to a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
  function approve(address spender, uint256 value) public returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  /**
    * @dev Transfer tokens from one address to another.
    * Note that while this function emits an Approval event, this is not required as per the specification,
    * and other compliant implementations may not emit the event.
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }

  /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when _allowed[msg.sender][spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * Emits an Approval event.
    * @param spender The address which will spend the funds.
    * @param addedValue The amount of tokens to increase the allowance by.
    */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }

  /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * Emits an Approval event.
    * @param spender The address which will spend the funds.
    * @param subtractedValue The amount of tokens to decrease the allowance by.
    */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
    return true;
  }

  /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
    * @dev Internal function that mints an amount of the token and assigns it to
    * an account. This encapsulates the modification of balances such that the
    * proper events are emitted.
    * @param account The account that will receive the created tokens.
    * @param value The amount that will be created.
    */
  function _mint(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
    * @dev Internal function that burns an amount of the token of a given
    * account.
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */
  function _burn(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
    * @dev Approve an address to spend another addresses' tokens.
    * @param owner The address that owns the tokens.
    * @param spender The address that will spend the tokens.
    * @param value The number of tokens that can be spent.
    */
  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0));
    require(owner != address(0));

    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /**
    * @dev Internal function that burns an amount of the token of a given
    * account, deducting from the sender's allowance for said account. Uses the
    * internal burn function.
    * Emits an Approval event (reflecting the reduced allowance).
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */
  function _burnFrom(address account, uint256 value) internal {
    _burn(account, value);
    _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
  }
}


//SourceUnit: TransferHelper.sol

// helper methods for interacting with TRC20 tokens  that do not consistently return true/false
library TransferHelper {
    //TODO: Replace in deloy script
    address constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;

    function safeApprove(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (token == USDTAddr) {
            return success;
        }
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}