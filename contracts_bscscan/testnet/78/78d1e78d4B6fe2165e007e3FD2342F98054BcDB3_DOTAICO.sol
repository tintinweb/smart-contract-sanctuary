//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./library/SafeMath.sol";
import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./interface/IBEP20.sol";

contract DOTAICO is ReentrancyGuard, Context, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) public contributions;

  IBEP20 public token;
  address payable public payWallet;
  uint256 public rate;
  uint256 public weiRaised;
  uint256 public endICO;
  uint256 public minPurchase;
  uint256 public maxPurchase;
  uint256 public hardCap;
  uint256 public softCap;
  uint256 public availableTokensICO;
  bool public startRefund = false;
  uint256 public refundStartDate;

  event TokensPurchased(
    address purchaser,
    address beneficiary,
    uint256 value,
    uint256 amount
  );
  event Refund(address recipient, uint256 amount);

  constructor(
    uint256 _rate,
    address payable _wallet,
    IBEP20 _token
  ) {
    require(_rate > 0, "Pre-Sale: rate is 0");
    require(_wallet != address(0), "Pre-Sale: wallet is the zero address");
    require(
      address(_token) != address(0),
      "Pre-Sale: token is the zero address"
    );

    rate = _rate;
    payWallet = _wallet;
    token = _token;
  }

  receive() external payable {
    if (endICO > 0 && block.timestamp < endICO) {
      _buyTokens(_msgSender());
    } else {
      endICO = 0;
      revert("Pre-Sale is closed");
    }
  }

  //Start Pre-Sale
  function startICO(
    uint256 endDate,
    uint256 _minPurchase,
    uint256 _maxPurchase,
    uint256 _softCap,
    uint256 _hardCap
  ) external onlyOwner icoNotActive {
    startRefund = false;
    refundStartDate = 0;
    availableTokensICO = token.balanceOf(address(this));
    require(endDate > block.timestamp, "duration should be > 0");
    require(_softCap < _hardCap, "Softcap must be lower than Hardcap");
    require(
      _minPurchase < _maxPurchase,
      "minPurchase must be lower than maxPurchase"
    );
    require(availableTokensICO > 0, "availableTokens must be > 0");
    require(_minPurchase > 0, "_minPurchase should > 0");
    endICO = endDate;
    minPurchase = _minPurchase;
    maxPurchase = _maxPurchase;
    softCap = _softCap;
    hardCap = _hardCap;
    weiRaised = 0;
  }

  function stopICO() external onlyOwner icoActive {
    endICO = 0;
    if (weiRaised >= softCap) {
      _forwardFunds();
    } else {
      startRefund = true;
      refundStartDate = block.timestamp;
    }
  }

  //Pre-Sale
  function buyTokens() public payable nonReentrant icoActive {
    _buyTokens(msg.sender);
  }

  function _buyTokens(address beneficiary) internal {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);
    uint256 tokens = _getTokenAmount(weiAmount);
    weiRaised = weiRaised.add(weiAmount);
    availableTokensICO = availableTokensICO - tokens;
    contributions[beneficiary] = contributions[beneficiary].add(weiAmount);
    emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
  }

  function _preValidatePurchase(address beneficiary, uint256 weiAmount)
    internal
    view
  {
    require(
      beneficiary != address(0),
      "Crowdsale: beneficiary is the zero address"
    );
    require(weiAmount != 0, "Crowdsale: weiAmount is 0");
    require(weiAmount >= minPurchase, "have to send at least: minPurchase");
    require(
      contributions[beneficiary].add(weiAmount) <= maxPurchase,
      "can't buy more than: maxPurchase"
    );
    require((weiRaised + weiAmount) <= hardCap, "Hard Cap reached");
    this;
  }

  function claimTokens() external icoNotActive {
    require(startRefund == false, "refunded");
    uint256 tokensAmt = _getTokenAmount(contributions[msg.sender]);
    contributions[msg.sender] = 0;
    token.transfer(msg.sender, tokensAmt);
  }

  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    return weiAmount.mul(rate);
  }

  function _forwardFunds() internal {
    payWallet.transfer(address(this).balance);
  }

  function withdraw() external onlyOwner icoNotActive {
    require(
      startRefund == false || (refundStartDate + 3 days) < block.timestamp,
      "not allowed to withdraw"
    );
    require(address(this).balance > 0, "Contract has no money");
    payWallet.transfer(address(this).balance);
  }

  function checkContribution(address addr) public view returns (uint256) {
    return contributions[addr];
  }

  function setRate(uint256 newRate) external onlyOwner icoNotActive {
    rate = newRate;
  }

  function setAvailableTokens(uint256 amount) public onlyOwner icoNotActive {
    availableTokensICO = amount;
  }

  function setWalletReceiver(address payable newWallet) external onlyOwner {
    payWallet = newWallet;
  }

  function setHardCap(uint256 value) external onlyOwner {
    hardCap = value;
  }

  function setSoftCap(uint256 value) external onlyOwner {
    softCap = value;
  }

  function setMaxPurchase(uint256 value) external onlyOwner {
    maxPurchase = value;
  }

  function setMinPurchase(uint256 value) external onlyOwner {
    minPurchase = value;
  }

  function takeTokens(IBEP20 tokenAddress) public onlyOwner icoNotActive {
    IBEP20 tokenBEP = tokenAddress;
    uint256 tokenAmt = tokenBEP.balanceOf(address(this));
    require(tokenAmt > 0, "BEP-20 balance is 0");
    tokenBEP.transfer(payWallet, tokenAmt);
  }

  function refundMe() public icoNotActive {
    require(startRefund == true, "no refund available");
    uint256 amount = contributions[msg.sender];
    if (address(this).balance >= amount) {
      contributions[msg.sender] = 0;
      if (amount > 0) {
        address payable recipient = payable(msg.sender);
        recipient.transfer(amount);
        emit Refund(msg.sender, amount);
      }
    }
  }

  modifier icoActive() {
    require(
      endICO > 0 && block.timestamp < endICO && availableTokensICO > 0,
      "ICO must be active"
    );
    _;
  }

  modifier icoNotActive() {
    require(endICO < block.timestamp, "ICO should not be active");
    _;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _setOwner(_msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    _setOwner(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
  }

  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}