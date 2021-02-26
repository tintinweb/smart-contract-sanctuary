/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");
    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");
    (bool success, bytes memory returndata) = target.call{ value: value }(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    require((value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

abstract contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor () internal {
    _status = _NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }
}


contract FenumCrowdsale is Context, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Address for address payable;

  bool private _launched;
  IERC20 private _token;

  // Address where funds are collected
  address payable private _wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 private _rate;

  uint256 private _weiRaised;
  uint256 private _purchaseLimit;
  uint256 private _tokensForSale;

  mapping(address => uint256) private _purchases;

  event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event RateChanged(uint256 oldRate, uint256 newRate);
  event TokensDeposited(address indexed payer, uint256 amount);
  event TokensWithdrawn(address indexed payee, uint256 amount);

  /**
   * @param rate_ Number of token units a buyer gets per wei
   * @dev The rate is the conversion between wei and the smallest and indivisible
   * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
   * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
   * @param purchaseLimit_ Limit of tokens for purchase
   * @param wallet_ Address where collected funds will be forwarded to
   * @param token_ Address of the token being sold
   */
  constructor (uint256 rate_, uint256 purchaseLimit_, address payable wallet_, IERC20 token_) public {
    require(rate_ > 0, "FenumCrowdsale: rate is 0");
    require(purchaseLimit_ > 0, "FenumCrowdsale: purchase limit is 0");
    require(wallet_ != address(0), "FenumCrowdsale: wallet is the zero address");
    require(address(token_) != address(0), "FenumCrowdsale: token is the zero address");

    _rate = rate_;
    _wallet = wallet_;
    _token = token_;
    _purchaseLimit = purchaseLimit_;
    _launched = false;
  }

  function launch(bool status) external onlyOwner returns (bool) {
    return _launched = status;
  }

  function launched() public view returns (bool) {
    return _launched;
  }

  function tokensDeposit(uint256 amount) external onlyOwner returns (bool) {
    address msgSender = _msgSender();
    _takeTokens(msgSender, amount);
    _tokensForSale = _tokensForSale.add(amount);
    emit TokensDeposited(msgSender, amount);
    return true;
  }

  function tokensWithdraw(uint256 amount) external onlyOwner returns (bool) {
    address msgSender = _msgSender();
    _deliverTokens(msgSender, amount);
    _tokensForSale = _tokensForSale.sub(amount);
    emit TokensWithdrawn(msgSender, amount);
    return true;
  }

  function tokensTransfer(uint256 amount) external onlyOwner returns (bool) {
    _token.safeTransfer(_msgSender(), amount);
    return true;
  }

  /**
   * @return the number of token units a buyer gets per wei.
   */
  function rate() public view returns (uint256) {
    return _rate;
  }

  function setRate(uint256 rate_) external onlyOwner returns (bool) {
    require(rate_ > 0, "FenumCrowdsale: rate is 0");
    emit RateChanged(_rate, rate_);
    _rate = rate_;
    return true;
  }

  function balance() public view returns (uint256) {
    return _token.balanceOf(address(this));
  }

  /**
   * @return the token being sold.
   */
  function token() public view returns (IERC20) {
    return _token;
  }

  /**
   * @return the address where funds are collected.
   */
  function wallet() public view returns (address payable) {
    return _wallet;
  }

  function setWallet(address payable wallet_) external onlyOwner returns (bool) {
    require(wallet_ != address(0), "FenumCrowdsale: wallet is the zero address");
    _wallet = wallet_;
    return true;
  }

  /**
   * @return the purchase limit of tokens.
   */
  function purchaseLimit() public view returns (uint256) {
    return _purchaseLimit;
  }

  /**
   * @return the number of token available for purchase.
   */
  function purchaseAvailable(address beneficiary) public view returns (uint256) {
    return _purchaseLimit.sub(_purchases[beneficiary]);
  }

  /**
   * @return the amount of wei raised.
   */
  function weiRaised() public view returns (uint256) {
    return _weiRaised;
  }

  /**
   * @return the amount of token for sale.
   */
  function tokensForSale() public view returns (uint256) {
    return _tokensForSale;
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * This function has a non-reentrancy guard, so it shouldn't be called by another `nonReentrant` function.
   * @param beneficiary Recipient of the token purchase
   */
  function buyTokens(address beneficiary) public nonReentrant payable {
    uint256 weiAmount = msg.value;
    uint256 tokens = _getTokenAmount(weiAmount);

    _preValidatePurchase(beneficiary, weiAmount, tokens);

    _processPurchase(beneficiary, tokens);
    emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

    _updatePurchasingState(beneficiary, weiAmount, tokens);

    _forwardFunds();
    _postValidatePurchase(beneficiary, weiAmount);
  }

  function _preValidatePurchase(address beneficiary, uint256 weiAmount, uint256 tokenAmount) internal view {
    require(_launched == true, "FenumCrowdsale: crowdsale not launched");
    require(beneficiary != address(0), "FenumCrowdsale: beneficiary is the zero address");
    require(weiAmount != 0, "FenumCrowdsale: weiAmount is 0");
    require(tokenAmount <= _tokensForSale, "FenumCrowdsale: Not enough tokens to sell");
    require(_purchases[beneficiary].add(tokenAmount) <= _purchaseLimit, "FenumCrowdsale: Your purchase limit is exceeded");
    this;
  }

  /**
   * @dev Validation of an executed purchase. Observe state
   * and use revert statements to undo rollback when valid conditions are not met.
   * @param beneficiary Address performing the token purchase
   * @param weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
    // solhint-disable-previous-line no-empty-blocks
  }

  function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
    _token.safeTransfer(beneficiary, tokenAmount);
  }

  function _takeTokens(address payer, uint256 tokenAmount) internal {
    _token.safeTransferFrom(payer, address(this), tokenAmount);
  }

  function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
    _deliverTokens(beneficiary, tokenAmount);
  }

  function _updatePurchasingState(address beneficiary, uint256 weiAmount, uint256 tokenAmount) internal {
    _weiRaised = _weiRaised.add(weiAmount);
    _tokensForSale = _tokensForSale.sub(tokenAmount);
    _purchases[beneficiary] = _purchases[beneficiary].add(tokenAmount);
  }

  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    return weiAmount.mul(_rate);
  }

  function _forwardFunds() internal {
    _wallet.sendValue(msg.value);
  }

  receive() external payable {
    buyTokens(_msgSender());
  }

  fallback() external {
    revert("FenumCrowdsale: contract action not found.");
  }
}