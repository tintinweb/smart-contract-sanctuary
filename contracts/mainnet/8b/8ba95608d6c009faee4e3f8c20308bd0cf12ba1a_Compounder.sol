pragma solidity >=0.6.2;

import "./IERC20.sol";
import "./ICERC20.sol";
import "./IUniswapV2Router02.sol";

contract Compounder {
  IUniswapV2Router02 constant router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  /**
   * @dev Swaps a token on uniswap, then mints
   * cTokens for the purchased token.
   * Note: Caller must already have approved Compounder
   * to transfer at least sellAmount of sellToken
   * @param sellToken Base token to sell
   * @param buyToken Base token to swap sellToken for
   * @param buyCToken cToken for buyToken
   * @param sellAmount Number of sellToken to sell
   * @param minBuyToken Minimum number of buyToken to receive
   */
  function swapTokenForCToken(
    IERC20 sellToken,
    IERC20 buyToken,
    ICERC20 buyCToken,
    uint256 sellAmount,
    uint256 minBuyToken
  ) public {
    require(
      sellToken.transferFrom(msg.sender, address(this), sellAmount),
      "Transfer failed"
    );
    require(
      sellToken.approve(address(router), sellAmount),
      "Failed to approve router."
    );
    address[] memory path = new address[](2);
    path[0] = address(sellToken);
    path[1] = address(buyToken);

    uint[] memory amounts = router.swapExactTokensForTokens(
      sellAmount,
      minBuyToken,
      path,
      address(this),
      block.timestamp + 1
    );

    uint256 minted = buyCToken.mint(amounts[1]);

    require(
      buyCToken.transfer(msg.sender, minted),
      "Failed to transfer token."
    );
  }

  /**
   * @dev Redeems a cToken for its base token, then swaps it
   * on UniSwap for the desired output token and transfers it
   * to the caller.
   * Note: Caller must already have approved Compounder
   * to transfer at least redeemAmount of sellCToken
   * @param sellToken Base token for the cToken to sell
   * @param sellCToken cToken for sellToken
   * @param buyToken Desired output token
   * @param redeemAmount Number of cTokens to redeem
   * @param minBuyToken Minimum number of output tokens
   */
  function swapCTokenForToken(
    IERC20 sellToken,
    ICERC20 sellCToken,
    IERC20 buyToken,
    uint256 redeemAmount,
    uint256 minBuyToken
  ) public {
    require(
      sellCToken.transferFrom(msg.sender, address(this), redeemAmount),
      "Transfer failed"
    );
    uint256 redeemed = sellCToken.redeem(redeemAmount);
    address[] memory path = new address[](2);
    path[0] = address(sellToken);
    path[1] = address(buyToken);
    require(
      sellToken.approve(address(router), redeemed),
      "Failed to approve router."
    );
    uint[] memory amounts = router.swapExactTokensForTokens(
      redeemed,
      minBuyToken,
      path,
      address(this),
      block.timestamp + 1
    );
    require(
      buyToken.transfer(msg.sender, amounts[1]),
      "Failed to transfer token."
    );
  }

  /**
   * @dev Redeems a cToken for its base token, swaps it
   * on UniSwap for the desired output token, mints cTokens
   * for the output and returns them to the caller.
   * Note: Caller must already have approved Compounder
   * to transfer at least redeemAmount of sellCToken
   * @param sellToken Base token for the cToken to sell
   * @param sellCToken cToken for sellToken
   * @param buyToken Base token for the cToken to buy
   * @param buyCToken cToken for buyToken
   * @param redeemAmount Number of cTokens to redeem
   * @param minBuyToken Minimum number of buyTokens for the swap
   */
  function swapCTokenForCToken(
    IERC20 sellToken,
    ICERC20 sellCToken,
    IERC20 buyToken,
    ICERC20 buyCToken,
    uint256 redeemAmount,
    uint256 minBuyToken
  ) public {
    require(
      sellCToken.transferFrom(msg.sender, address(this), redeemAmount),
      "Transfer failed"
    );
    uint256 redeemed = sellCToken.redeem(redeemAmount);
    address[] memory path = new address[](2);
    path[0] = address(sellToken);
    path[1] = address(buyToken);
    require(
      sellToken.approve(address(router), redeemed),
      "Failed to approve router."
    );
    uint[] memory amounts = router.swapExactTokensForTokens(
      redeemed,
      minBuyToken,
      path,
      address(this),
      block.timestamp + 1
    );
    require(
      sellToken.approve(address(buyCToken), amounts[1]),
      "Failed to approve compound."
    );
    uint256 minted = buyCToken.mint(amounts[1]);
    require(
      buyCToken.transfer(msg.sender, minted),
      "Failed to transfer cToken."
    );
  }
}