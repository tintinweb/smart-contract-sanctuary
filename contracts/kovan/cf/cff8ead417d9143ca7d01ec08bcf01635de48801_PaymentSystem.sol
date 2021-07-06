// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "IERC20.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "UniswapLiquidityInterface.sol";
import "LivePrice.sol";

 contract PaymentSystem is Ownable, LiquidityInfo, LivePrice {
  using SafeMath for uint256;

  mapping(address => IERC20) internal token;

  address[] public merchant;
  mapping(address => address) public tokenToReceive;
  UniswapV2RouterInterface SwapRouter;

  constructor() {
    SwapRouter = UniswapV2RouterInterface(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D );

    addPaymentToken(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa, 0x777A68032a88E5A84678A77Af2CD65A7b3c0775a); // xDai
    addPaymentToken(0xd0A1E359811322d97991E03f863a0C30C2cF029C, 0x9326BFA02ADD2366b30bacB125260Af641031331); // Ether
    addPaymentToken(0xe0C9275E44Ea80eF17579d33c55136b7DA269aEb, 0x6135b13325bfC4B00278B4abC5e20bbce2D6580e); // Bitcoin
    addPaymentToken(0x2F375e94FC336Cdec2Dc0cCB5277FE59CBf1cAe5 , 0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60); // USD Coin
  }

  function addPaymentToken(address _token, address _chainlinkPriceFeed)
  public
  onlyOwner
  {
    require(!isPaymentToken(_token), "[Token already accepted]");
    token[_token] = IERC20(_token);
    addPriceFeed(_token, _chainlinkPriceFeed);
  }

  function isPaymentToken(address _token)
      public
      view
      returns(bool)
  {
    if (_token == address(token[_token])) return (true);
    return (false);
  }

  function addMerchant(address _paymentAddress, address _paymentToken)
  public
  onlyOwner
  {
    (bool _isMerchant,) = isMerchant(_paymentAddress);
    require(!_isMerchant, "[Merchant already exists]");
    require(isPaymentToken(_paymentToken), "[Token not supported]");
    merchant.push(_paymentAddress);
    tokenToReceive[_paymentAddress] = _paymentToken;
  }

  function removeMerchant(address _merchant) public onlyOwner {
      (bool _isMerchant, uint256 s) = isMerchant(_merchant);
      if(_isMerchant){
          merchant[s] = merchant[merchant.length - 1];
          merchant.pop();
      }
  }

  function isMerchant(address _merchant) internal view returns(bool, uint256)
      {
          for (uint256 s = 0; s < merchant.length; s += 1){
              if (_merchant == merchant[s]) return (true, s);
          }
          return (false, 0);
      }

  function changePaymentTokenFor(address _merchant, address _newPaymentToken) public onlyOwner {
    (bool _isMerchant,) = isMerchant(_merchant);
    require(_isMerchant, "[Address is not a registered merchant]");
    require(isPaymentToken(_newPaymentToken), "[Token not supported]");
    tokenToReceive[_merchant] = _newPaymentToken;
  }

  function pay(address _merchant, uint256 _amountRequested, address _userPaymentToken) public {
    (bool _isMerchant,) = isMerchant(_merchant);
    require(_isMerchant, "[Unknown merchant address]");
    require(isPaymentToken(_userPaymentToken), "[Token not supported]");
    if(_userPaymentToken == tokenToReceive[_merchant]){
      require(token[_userPaymentToken].allowance(msg.sender, address(this)) >= _amountRequested, "[Insufficient allowance for user payment token]");
      require(token[_userPaymentToken].transferFrom(msg.sender, _merchant, _amountRequested), "[Value not received from customer]");
    }
    else {
      (uint256 amountToMerchant, uint256 amountToRefund) = swapExactOut(_userPaymentToken, tokenToReceive[_merchant], _amountRequested);
      if(tokenToReceive[_merchant] == SwapRouter.WETH()){
        (bool sent,) = _merchant.call{value: amountToMerchant}(""); // Send xDai to merchant
        require(sent, "[Failed to send xDai]");
      }
      else require(token[tokenToReceive[_merchant]].transferFrom(address(this), _merchant, amountToMerchant), "[Post swap token transfer error]"); // Send tokens to merchant

      token[_userPaymentToken].transferFrom(address(this), msg.sender, amountToRefund); // Refund unused tokens to caller
    }
  }

  function payXDAI(address _merchant, uint256 _amountRequested) public payable {
    (bool _isMerchant,) = isMerchant(_merchant);
    require(_isMerchant, "[Unknown merchant address]");
    require(msg.value > 0, "[No value sent]");
    if(SwapRouter.WETH() == tokenToReceive[_merchant]){
      require(msg.value == _amountRequested, "[Amount sent not matching amount requested]");
      (bool sent,) = _merchant.call{value: _amountRequested}("");
      require(sent, "[Failed to send xDai]");
    }
    else {
      (uint256 amountToMerchant, uint256 amountToRefund) = swapExactOut(SwapRouter.WETH(), tokenToReceive[_merchant], _amountRequested);
      token[tokenToReceive[_merchant]].transferFrom(address(this), _merchant, amountToMerchant); // Send tokens to merchant
      (bool sent,) = msg.sender.call{value: amountToRefund}(""); // Refund leftover tokens to customer
      require(sent, "[Failed to refund xDai]");
    }
  }

  function swapExactOut(address _fromToken, address _toToken, uint256 _amountOut)
  internal
  returns(uint256, uint256)
  {
    // amountInMax must be retrieved from an oracle of some kind
    address[] memory path = new address[](2);
    path[0] = _fromToken;
    path[1] = _toToken;

    uint[] memory amounts;

    uint256 amountInMax = calculateMaxIn(_fromToken, _toToken, _amountOut); // Decentralized exchange value call
    require(checkPriceRange(_fromToken, _toToken, _amountOut), "[Transaction rejected due to price fluctuations]"); // Check if it matches with live prices from oracle

    if(_fromToken == SwapRouter.WETH()){
      require(msg.value == amountInMax, "[Amount sent not matching amount requested]");
      amounts = SwapRouter.swapETHForExactTokens{value: amountInMax}(_amountOut, path, msg.sender, block.timestamp);
    }
    else if(_toToken == SwapRouter.WETH()){
      require(token[_fromToken].allowance(msg.sender, address(this)) >= amountInMax, "[Insufficient allowance for user payment token]");
      require(token[_fromToken].transferFrom(msg.sender, address(this), amountInMax), "[Value not received from customer]");
      require(token[_fromToken].approve(address(SwapRouter), amountInMax), "[Approve failed]");
      amounts = SwapRouter.swapTokensForExactETH(_amountOut, amountInMax, path, msg.sender, block.timestamp);
    }
    else {
      require(token[_fromToken].allowance(msg.sender, address(this)) >= amountInMax, "[Insufficient allowance for user payment token]");
      require(token[_fromToken].transferFrom(msg.sender, address(this), amountInMax), "[Value not received from customer]");
      require(token[_fromToken].approve(address(SwapRouter), amountInMax), "[Approve failed]");
      amounts = SwapRouter.swapTokensForExactTokens(_amountOut, amountInMax, path, msg.sender, block.timestamp);
    }
    return(amounts[amounts.length - 1], amountInMax.sub(amounts[0]));

  }

  function calculateMaxIn(address _fromToken, address _toToken, uint256 _amountOut)
  internal
  view
  returns (uint256)
  {
    uint256 amountIn = amountInForExactOut(_fromToken, _toToken, _amountOut);
    amountIn = amountIn.add(amountIn.div(100).mul(2)); // +2% margin
    return amountIn;
  }

  function checkPriceRange(address _fromToken, address _toToken, uint256 _amountOut) internal view returns(bool check) {
    uint256 amountIn = amountInForExactOut(_fromToken, _toToken, _amountOut);
    uint256 fromPriceOracle = uint(getLatestPrice(_fromToken));
    uint256 toPriceOracle = uint(getLatestPrice(_toToken));
    uint256 valueIn = amountIn.mul(fromPriceOracle);
    uint256 valueOut = _amountOut.mul(toPriceOracle);
    if(valueIn > valueOut) {
      uint256 difference = valueIn.sub(valueOut);
      if(valueIn < difference) check = false; // If more than 1% difference
      else check = true;
    }
    else check = true;
}
}
interface UniswapV2RouterInterface {
  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
) external returns (uint[] memory amounts);
function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);
  function WETH() external pure returns (address);
}