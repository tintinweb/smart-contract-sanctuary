// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
* @title Decentralized Exchange Contract (DEX)
* @notice This contract automatically changes price as the ratio of reserves moves away 
* from equilibrium: Automated Market Maker (AMM).
* @author tobias, with a lot of help from Scaffold-ETH
* Reference: https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90 
*/

contract DEX {

  /*
    * @notice Removed SafeMath due to Solidity 0.8.0 
  */
    //using SafeMath for uint256; 

    IERC20 token;

    uint256 public totalLiquidity;

    //users liquidity
    mapping(address => uint256) public liquidity;

  /*
    * @notice The constructor assigns token to the deployed ERC20 token (Balloons) address.  
  */
    constructor(address token_addr) {

      token = IERC20(token_addr);
    }

  /*
    * @notice This function initializes the Dex by loading the contract
    * with test ETH and Balloons. This ensures some liquidity at the start.
    * Starting ratio of ETH to tokens in this contract is 1:1. 
    * This function is called in the deploy script.
    * @param ERC20 tokens.
  */
    function init(uint256 tokens) public payable returns (uint256) {

    require(totalLiquidity == 0,"DEX:init - already has liquidity");

    totalLiquidity = address(this).balance;

    liquidity[msg.sender] = totalLiquidity;

    require(token.transferFrom(msg.sender, address(this), tokens), "Token:init - transfer to contract failed");

    return totalLiquidity;
  }

  /*
    * @dev This is a pure function because no state variables will be altered or read. 
    * Determines the exchange rate between ETH and tokens.
    * @notice This function is based on the formula (x * y) = k,
    * where "x" = amt of ETH in DEX, "y" = amt of tokens, and "k" = an invariant(meaning
    * it only changes based on changes in liquidity and NOT during a trade).
    * The plot of this forumla produces a curve and is shown on the frontend.
    * In short, we are swapping. The market will always have liquidity, however the ratio will change
    * and a better price will be provided for the lesser asset, encouraging equilibrium.
    * In other words, an inverese relationsip of reserves to input asset. 
    * @param input_amount is value from the caller.
    * @param input_reserve is value used to maintain proper ratio.
    * @param output_reserve is value used to maintain proper ratio.
  */
  function price(
    uint256 input_amount, 
    uint256 input_reserve, 
    uint256 output_reserve
    ) public pure returns (uint256) {

    //includes a 0.3% fee collected by the contract on each trade.
    uint256 input_amount_with_fee = input_amount * 997;

    uint256 numerator = input_amount_with_fee * output_reserve;

    uint256 denominator = input_reserve * 1000 + input_amount_with_fee;

    return numerator / denominator;
  }


  /*
    * @dev This function is payable so it can receive ETH.
    * @notice This function takes users ETH and transfers out tokens.
    * Uses price function to figure ratio of reserves vs. input asset. 
  */
  function ethToToken() public payable returns (uint256) {

    uint256 token_reserve = token.balanceOf(address(this));

    uint256 tokens_bought = price(msg.value, address(this).balance - msg.value, token_reserve);

    require(token.transfer(msg.sender, tokens_bought), "Token transfer to caller failed");

    return tokens_bought;
  }


  /*
    * @notice This function receives callers tokens and pays out ETH. 
    * Uses price function to figure ratio of reserves vs. input asset.
    * @param amount of tokens.
  */
  function tokenToEth(uint256 tokens) public returns (uint256) {

    uint256 token_reserve = token.balanceOf(address(this));

    uint256 eth_bought = price(tokens, token_reserve, address(this).balance);

    (bool success, ) = msg.sender.call{value: eth_bought}("");

    require(success, "Failed to send user ETH");

    require(token.transferFrom(msg.sender, address(this), tokens), "Token transfer to contract failed");

    return eth_bought;
  }

  /*
    * @dev Receives ETH and transfers tokens from the caller to contract at
    * the right ratio. 
    * @notice This function allows you to deposit to the contract. This means 
    * anyone can add liquidity to the contract. 
    * The contract tracks amt of liquidity the caller owns vs totalLiquidity.
  */
  function deposit() public payable returns (uint256) {

    uint256 eth_reserve = address(this).balance - msg.value;

    uint256 token_reserve = token.balanceOf(address(this));

    uint256 token_amount = ((msg.value * token_reserve) / eth_reserve) + 1;

    uint256 liquidity_minted = (msg.value * totalLiquidity) / eth_reserve;

    liquidity[msg.sender] += liquidity_minted;

    totalLiquidity += liquidity_minted;

    require(token.transferFrom(msg.sender, address(this), token_amount), "Token transfer to contract failed");

    return liquidity_minted;
  }

  /*
    * @notice This function allows caller to take both ETH or tokens out of contract.  
    * The actual amt withdrawn will be higher that what the caller deposited because of the 
    * 0.3% fee that's collect on each trade. => This incentivizes a 3rd party to provide liquidity.
    * @param The amount of liquidity to be withdrawn. 
  */
  function withdraw(uint256 liquid_amount) public returns (uint256, uint256) {

    uint256 token_reserve = token.balanceOf(address(this));

    uint256 eth_amount = (liquid_amount * address(this).balance) / totalLiquidity;

    uint256 token_amount = (liquid_amount * token_reserve) / totalLiquidity;

    liquidity[msg.sender] -= liquid_amount;

    totalLiquidity -= liquid_amount;

    (bool success, ) = msg.sender.call{value: eth_amount}("");

    require(success, "Failed to send user ETH");

    require(token.transfer(msg.sender, token_amount), "Token transfer to caller failed");

    return (eth_amount, token_amount);
  }

}