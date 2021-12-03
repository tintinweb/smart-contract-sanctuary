// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./utils/EmergencyWithdraw.sol";

contract MemepadProject is OwnableUpgradeable, EmergencyWithdraw, ReentrancyGuardUpgradeable {
  struct WhitelistInput {
    address wallet;
    uint256 maxPayableAmount;
  }

  struct Whitelist {
    address wallet;
    uint256 amount;
    uint256 maxPayableAmount;
    uint256 rewardedAmount;
    bool whitelist;
    bool redeemed;
  }

  // Whitelist map
  mapping(address => Whitelist) private whitelist;
  address[] public whitelistUsers;

  // Private
  IERC20Metadata private _token;
  // Public
  uint256 public startTime;
  uint256 public tokenRate;
  uint256 public soldAmount;
  uint256 public totalRaise;
  uint256 public totalParticipant;
  uint256 public totalRedeemed;
  uint256 public totalRewardTokens;
  bool public isFinished;
  bool public isClosed;
  bool public isFailedSale;
  uint256 public maxPublicPayableAmount;
  mapping(address => bool) public publicSaleList;
  mapping(address => bool) public refundedList;
  uint256 public publicTime;
  uint256 public publicTimeHolder;
  uint256 public reduceTokenAmount;

  // Events
  event ESetAcceptedTokenAddress(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply);
  event ESetTokenAddress(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply);
  event ESetTokenRate(uint256 _tokenRate);
  event EOpenSale(uint256 _startTime, bool _isStart);
  event EBuyTokens(
    address _sender,
    uint256 _value,
    uint256 _totalToken,
    uint256 _rewardedAmount,
    uint256 _senderTotalAmount,
    uint256 _senderTotalRewardedAmount,
    uint256 _senderSoldAmount,
    uint256 _senderTotalRise,
    uint256 _totalParticipant,
    uint256 _totalRedeemed
  );
  event ECloseSale(bool _isClosed);
  event EFinishSale(bool _isFinished);
  event ERedeemTokens(address _wallet, uint256 _rewardedAmount);
  event ERefundBNB(address _wallet, uint256 _refundedAmount);
  event EAddWhiteList(WhitelistInput[] _addresses);
  event ERemoveWhiteList(address[] _addresses);
  event EWithdrawBNBBalance(address _sender, uint256 _balance);
  event EWithdrawRemainingTokens(address _sender, uint256 _remainingAmount);
  event EAddRewardTokens(address _sender, uint256 _amount, uint256 _remaingRewardTokens);

  /**
   * @dev Upgradable initializer
   */
  function __MemepadProject_init() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    // Default token rate is 0.01
    tokenRate = 10000000000000000;
  }

  // Read: Get token address
  function getTokenAddress() public view returns (address tokenAddress) {
    return address(_token);
  }

  // Read: Get Total Token
  function getTotalToken() public view returns (uint256) {
    return _token.balanceOf(address(this));
  }

  function isInitialized() public view returns (bool) {
    return startTime != 0;
  }

  // Read: Is Sale Start
  function isStart() public view returns (bool) {
    return isInitialized() && startTime > 0 && block.timestamp >= startTime;
  }

  //read token in BNB
  function getTokenInBNB(uint256 tokens) public view returns (uint256) {
    uint256 tokenDecimal = 10**uint256(_token.decimals());
    return (tokens * tokenRate) / tokenDecimal;
  }

  // Read: Calculate Token
  function calculateAmount(uint256 acceptedAmount) public view returns (uint256) {
    uint256 tokenDecimal = 10**uint256(_token.decimals());
    return (acceptedAmount * tokenDecimal) / tokenRate;
  }

  // Read: Get max payable amount against whitelisted address
  function getMaxPayableAmount(address _address) public view returns (uint256) {
    Whitelist memory whitelistWallet = whitelist[_address];
    return whitelistWallet.maxPayableAmount;
  }

  // Read: Get whitelist wallet
  function getWhitelist(address _address)
    public
    view
    returns (
      address _wallet,
      uint256 _amount,
      uint256 _maxPayableAmount,
      uint256 _rewardedAmount,
      bool _redeemed,
      bool _whitelist
    )
  {
    Whitelist memory whitelistWallet = whitelist[_address];
    return (
      _address,
      whitelistWallet.amount,
      whitelistWallet.maxPayableAmount,
      whitelistWallet.rewardedAmount,
      whitelistWallet.redeemed,
      whitelistWallet.whitelist
    );
  }

  //Read return remaining reward
  function getRemainingReward() public view returns (uint256) {
    return totalRewardTokens - soldAmount - reduceTokenAmount;
  }

  // Read return whitelistUsers length
  function getWhitelistUsersLength() external view returns (uint256) {
    return whitelistUsers.length;
  }

  //Read return whitelist paging
  function getUsersPaging(uint _offset, uint _limit)
    public
    view
    returns (
      Whitelist[] memory users,
      uint nextOffset,
      uint total
    )
  {
    uint totalUsers = whitelistUsers.length;
    if (_limit == 0) {
      _limit = 1;
    }

    if (_limit > totalUsers - _offset) {
      _limit = totalUsers - _offset;
    }

    Whitelist[] memory values = new Whitelist[](_limit);
    for (uint i = 0; i < _limit; i++) {
      values[i] = whitelist[whitelistUsers[_offset + i]];
    }

    return (values, _offset + _limit, totalUsers);
  }

  // Write: Token Address
  function setTokenAddress(IERC20Metadata token) external onlyOwner {
    require(startTime == 0, "Must before sale");

    _token = token;
    // Emit event
    emit ESetTokenAddress(token.name(), token.symbol(), token.decimals(), token.totalSupply());
  }

  // Write: Owner set exchange rate
  function setTokenRate(uint256 _tokenRate) external onlyOwner {
    require(!isInitialized(), "Initialized");
    require(_tokenRate > 0, "Not zero");

    tokenRate = _tokenRate;
    // Emit event
    emit ESetTokenRate(tokenRate);
  }

  // Write: Open sale
  // Ex _startTime = 1618835669
  function openSale(uint256 _startTime) external onlyOwner {
    require(!isInitialized(), "Initialized");
    require(_startTime >= block.timestamp, "Must >= current time");
    require(getTokenAddress() != address(0), "Token address is empty");
    require(getTotalToken() > 0, "Total token != zero");

    startTime = _startTime;
    isClosed = false;
    isFinished = false;
    // Emit event
    emit EOpenSale(startTime, isStart());
  }

  // Enable public sale with max amount
  function setMaxPublicPayableAmount(uint256 _maxAmount) external onlyOwner {
    maxPublicPayableAmount = _maxAmount;
  }

  // Set reduce token amount on total reward tokens
  function setReduceTokenAmount(uint256 _amount) external onlyOwner {
    require(_amount <= (totalRewardTokens - soldAmount), "Wrong amount");
    reduceTokenAmount = _amount;
  }

  // Set public sale time.
  // In public sale, only holder can not during this time
  function setPublicTime(uint256 _publicTime, uint256 _publicTimeHolder) external onlyOwner {
    publicTime = _publicTime;
    publicTimeHolder = _publicTimeHolder;
  }

  // Check public sale
  function isPublicSale() public view returns (bool) {
    return maxPublicPayableAmount > 0 && block.timestamp >= publicTime;
  }

  ///////////////////////////////////////////////////
  // IN SALE
  // Write: User buy token by sending BNB
  // Convert Accepted bnb to Sale token
  function buyTokens() external payable nonReentrant {
    address payable senderAddress = payable(_msgSender());
    uint256 acceptedAmount = msg.value;
    Whitelist memory whitelistSnapshot = whitelist[senderAddress];

    // Asserts
    require(isStart(), "Sale is not started yet");
    require(!isClosed, "Sale is closed");
    require(!isFinished, "Sale is finished");

    // Public sale after 24hrs
    bool isPublicSale_ = isPublicSale();

    // First hours of public sale is just for holder
    if (isPublicSale_ && block.timestamp <= publicTimeHolder) {
      require(whitelistSnapshot.whitelist, "Mempad holder first");
    }

    if (!isPublicSale_) {
      require(!publicSaleList[senderAddress], "Not for public sale");
    } else if (whitelistSnapshot.wallet == address(0)) {
      publicSaleList[senderAddress] = true;
      whitelistUsers.push(senderAddress);
      whitelistSnapshot.wallet = senderAddress;
      whitelistSnapshot.maxPayableAmount = maxPublicPayableAmount;
      whitelistSnapshot.whitelist = true;
      whitelist[senderAddress] = whitelistSnapshot;
    }

    require(whitelistSnapshot.whitelist, "You are not in whitelist");
    require(acceptedAmount > 0, "Pay some BNB to get tokens");

    uint256 rewardedAmount = calculateAmount(acceptedAmount);
    // In public sale mode, just check with maxPublicPayableAmount
    if (!isPublicSale_) {
      require(
        whitelistSnapshot.maxPayableAmount >= whitelistSnapshot.rewardedAmount + rewardedAmount,
        "max payable amount reached"
      );
    } else {
      require(
        maxPublicPayableAmount >= whitelistSnapshot.rewardedAmount + rewardedAmount,
        "max public payable reached"
      );
    }

    uint256 totalToken = getTotalToken();
    uint256 unsoldTokens = getRemainingReward();
    uint256 tokenValueInBNB = getTokenInBNB(unsoldTokens);

    if (acceptedAmount >= tokenValueInBNB) {
      //refund excess amount
      uint256 excessAmount = acceptedAmount - tokenValueInBNB;
      //remaining amount
      acceptedAmount = acceptedAmount - excessAmount;
      //close the sale
      isClosed = true;
      rewardedAmount = calculateAmount(acceptedAmount);
      emit ECloseSale(isClosed);
      // solhint-disable
      if (excessAmount > 0) {
        senderAddress.transfer(excessAmount);
      }
    }

    require(rewardedAmount > 0, "Zero rewarded amount");

    // Update total participant
    // Check if current whitelist amount is zero and will be deposit
    // then increase totalParticipant variable
    if (whitelistSnapshot.amount == 0 && acceptedAmount > 0) {
      totalParticipant = totalParticipant + 1;
    }
    // Update whitelist detail info
    whitelist[senderAddress].amount = whitelistSnapshot.amount + acceptedAmount;
    whitelist[senderAddress].rewardedAmount = whitelistSnapshot.rewardedAmount + rewardedAmount;
    // Update global info
    soldAmount = soldAmount + rewardedAmount;
    totalRaise = totalRaise + acceptedAmount;

    // Emit buy event
    emit EBuyTokens(
      senderAddress,
      acceptedAmount,
      totalToken,
      rewardedAmount,
      whitelist[senderAddress].amount,
      whitelist[senderAddress].rewardedAmount,
      soldAmount,
      totalRaise,
      totalParticipant,
      totalRedeemed
    );
  }

  // Write: Finish sale
  function finishSale() external onlyOwner returns (bool) {
    isFinished = true;
    // Emit event
    emit EFinishSale(isFinished);
    return isFinished;
  }

  ///////////////////////////////////////////////////
  // AFTER SALE
  // Write: Redeem Rewarded Tokens
  function redeemTokens() external nonReentrant {
    address senderAddress = _msgSender();

    require(whitelist[senderAddress].whitelist, "Sender is not in whitelist");

    Whitelist memory whitelistWallet = whitelist[senderAddress];

    require(isFinished, "Sale is not finalized yet");
    require(!isFailedSale, "Sale is failed");
    require(!whitelistWallet.redeemed, "Redeemed already");

    whitelist[senderAddress].redeemed = true;
    _token.transfer(whitelistWallet.wallet, whitelistWallet.rewardedAmount);

    // Update total redeem
    totalRedeemed = totalRedeemed + whitelistWallet.rewardedAmount;

    // Emit event
    emit ERedeemTokens(whitelistWallet.wallet, whitelistWallet.rewardedAmount);
  }

  // Write: Allow user withdraw their BNB if the sale is failed
  function refundBNB() external nonReentrant {
    address payable senderAddress = payable(_msgSender());

    require(isClosed, "Sale is not closed yet");
    require(isFailedSale, "Sale is not failed");
    require(whitelist[senderAddress].whitelist, "Sender is not in whitelist");
    require(!refundedList[senderAddress], "Already refunded");
    refundedList[senderAddress] = true;

    Whitelist memory whitelistWallet = whitelist[senderAddress];
    senderAddress.transfer(whitelistWallet.amount);

    // Emit event
    emit ERefundBNB(senderAddress, whitelistWallet.amount);
  }

  ///////////////////////////////////////////////////
  // FREE STATE
  // Write: Add Whitelist
  function addWhitelist(WhitelistInput[] memory inputs) external onlyOwner {
    require(!isStart(), "Sale is started");

    uint256 addressesLength = inputs.length;

    for (uint256 i = 0; i < addressesLength; i++) {
      WhitelistInput memory input = inputs[i];
      if (whitelist[input.wallet].wallet == address(0)) {
        whitelistUsers.push(input.wallet);
      }
      Whitelist memory _whitelist = Whitelist(input.wallet, 0, input.maxPayableAmount, 0, true, false);

      whitelist[input.wallet] = _whitelist;
    }
    // Emit event
    emit EAddWhiteList(inputs);
  }

  // Write: Remove Whitelist
  function removeWhitelist(address[] memory addresses) external onlyOwner {
    require(!isStart(), "Sale is started");

    uint256 addressesLength = addresses.length;

    for (uint256 i = 0; i < addressesLength; i++) {
      address _address = addresses[i];
      Whitelist memory _whitelistSnapshot = whitelist[_address];
      whitelist[_address] = Whitelist(
        _address,
        _whitelistSnapshot.amount,
        _whitelistSnapshot.maxPayableAmount,
        _whitelistSnapshot.rewardedAmount,
        false,
        _whitelistSnapshot.redeemed
      );
    }

    // Emit event
    emit ERemoveWhiteList(addresses);
  }

  // Write: Mark failed sale to allow user withdraw their fund
  function markFailedSale(bool status) external onlyOwner {
    isFailedSale = status;
  }

  // Write: Close sale - stop buying
  function closeSale(bool status) external onlyOwner {
    isClosed = status;
    emit ECloseSale(isClosed);
  }

  // Write: owner can withdraw all BNB
  function withdrawBNBBalance() external onlyOwner {
    address payable sender = payable(_msgSender());

    uint256 balance = address(this).balance;
    sender.transfer(balance);

    // Emit event
    emit EWithdrawBNBBalance(sender, balance);
  }

  // Write: Owner withdraw tokens which are not sold
  function withdrawRemainingTokens() external onlyOwner {
    address sender = _msgSender();
    uint256 lockAmount = soldAmount - totalRedeemed;
    uint256 remainingAmount = getTotalToken() - lockAmount;

    _token.transfer(sender, remainingAmount);

    // Emit event
    emit EWithdrawRemainingTokens(sender, remainingAmount);
  }

  // Write: Owner can add reward tokens
  function addRewardTokens(uint256 _amount) external onlyOwner {
    require(getTokenAddress() != address(0), "Token address has not initialized yet");
    require(_amount > 0, "Amount should not be 0");

    address sender = _msgSender();
    _token.transferFrom(sender, address(this), _amount);
    totalRewardTokens = totalRewardTokens + _amount;

    emit EAddRewardTokens(sender, _amount, totalRewardTokens);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EmergencyWithdraw is OwnableUpgradeable {
  event Received(address sender, uint amount);

  /**
   * @dev allow contract to receive ethers
   */
  receive() external payable {
    emit Received(_msgSender(), msg.value);
  }

  /**
   * @dev get the eth balance on the contract
   * @return eth balance
   */
  function getEthBalance() public view onlyOwner returns (uint) {
    return address(this).balance;
  }

  /**
   * @dev withdraw eth balance
   */
  function withdrawEthBalance() external onlyOwner {
    payable(owner()).transfer(getEthBalance());
  }

  /**
   * @dev get the token balance
   * @param _tokenAddress token address
   */
  function getTokenBalance(address _tokenAddress) public view onlyOwner returns (uint) {
    IERC20 erc20 = IERC20(_tokenAddress);
    return erc20.balanceOf(address(this));
  }

  /**
   * @dev withdraw token balance
   * @param _tokenAddress token address
   */
  function withdrawTokenBalance(address _tokenAddress) external onlyOwner {
    IERC20 erc20 = IERC20(_tokenAddress);
    erc20.transfer(owner(), getTokenBalance(_tokenAddress));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}