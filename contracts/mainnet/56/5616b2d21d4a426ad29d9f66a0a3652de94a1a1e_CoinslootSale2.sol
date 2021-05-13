/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.2;


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract CoinslootSale2 {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Multisig smart contract address to which funds will be sent
  address payable public wallet = 0x1eFD3738e4Cb360ea0FB5FA6aB0cd49BBba516e2;

  address public owner;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  constructor(uint256 _rate, ERC20 _token) {
    owner = msg.sender;
    rate = _rate;
    token = _token;
  }

  function getRate() public view returns (uint256) {
    return rate;
  }

  function changeRate(uint256 _newRate) public {
    require(msg.sender == owner);
    rate = _newRate;
  }

  function withdrawTokensToOwner(uint256 _amount) public {
    require(msg.sender == owner);
    _deliverTokens(owner, _amount);
  }

  receive() external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    uint256 tokens = _getTokenAmount(weiAmount);

    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {}

  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {}

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256){
    assert(rate != 0);
    return (_weiAmount / rate) * 10**18;
  }

  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}