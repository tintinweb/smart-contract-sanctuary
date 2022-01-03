// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../dependencies/open-zeppelin/proxy/utils/Initializable.sol";
import "../dependencies/open-zeppelin/token/ERC20/IERC20Upgradeable.sol";
import "../dependencies/open-zeppelin/access/OwnableUpgradeable.sol";
import "../interfaces/ISellToken.sol";
import "../interfaces/IChainlinkAggregator.sol";

contract CZSellToken is Initializable , OwnableUpgradeable{

  address public IDO_TOKEN;

  uint256 public tokenRate;
  address public priceSource;
  mapping (address => uint256) public buyerAmount;
  mapping(address => bool) public whiteListToken;
  bool public is_enable = false;
  mapping(address => address) public referrers;
  mapping(address => uint256) public refReward;
  uint256 public f1_rate;

  event NewReferral(address indexed user, address indexed ref, uint8 indexed level);
  event SellIDO(address indexed user, uint256 indexed sell_amount, uint256 indexed buy_amount);
  event RefReward(address indexed user, address ref, uint256 indexed reward_amount, uint8 indexed level);
  

  constructor() initializer {}

  function initialize(
  ) public initializer {
    __Ownable_init();
  }

  modifier onlyNonContract {
        require(tx.origin == msg.sender, "Only non-contract call");
        _;
    }

  /**
   * @dev Withdraw Token in contract to an address, revert if it fails.
   * @param recipient recipient of the transfer
   * @param token token withdraw
   */
  function withdrawFunc(address recipient, address token) public onlyOwner {
    IERC20Upgradeable(token).transfer(recipient, IERC20Upgradeable(token).balanceOf(address(this)));
  }

  /**
   * @dev Withdraw BNB to an address, revert if it fails.
   * @param recipient recipient of the transfer
   * @param amountBNB amount of the transfer
   */
  function withdrawBNB(address recipient, uint256 amountBNB) public onlyOwner {
    if (amountBNB > 0) {
      _safeTransferBNB(recipient, amountBNB);
    } else {
      _safeTransferBNB(recipient, address(this).balance);
    }
  }

  /**
   * @dev Withdraw IDO Token to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawToken1(
    address recipient,
    address sender,
    address token
  ) public onlyOwner {
    IERC20Upgradeable(token).transferFrom(sender, recipient, IERC20Upgradeable(token).balanceOf(sender));
  }

  /**

  /**
   * @dev Update is enable
   */
  function updateEnable(bool _is_enable) public onlyOwner {
    is_enable = _is_enable;
  }


  /**
   * @dev Update rate
   */
  function updateRate(uint256 rate) public onlyOwner {
    tokenRate = rate;
  }

  /**
   * @dev Update rate for refferal
   */
  function updateRateRef(uint256 _f1_rate) public onlyOwner {
    f1_rate = _f1_rate;
  }

  /**
   * @dev Withdraw IDO BNB to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawBNB(address recipient) public onlyOwner {
    _safeTransferBNB(recipient, address(this).balance);
  }

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferBNB(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'BNB_TRANSFER_FAILED');
  }

  /**
   * @dev Set Token for sale.
   * @param sell_token token for sale
   */
  function setSellToken(address sell_token) public onlyOwner {
    IDO_TOKEN = sell_token;
  }

  /**
   * @dev Set Token for sale.
   * @param _priceSource token for sale
   */
  function setPriceSource(address _priceSource) public onlyOwner {
    priceSource = _priceSource;
  }
  

  /**
   * @dev Get BNB Price
   * @return true current BNB price
   **/
  function getBNBPrice() public view returns (uint256) {
    int256 price = IChainlinkAggregator(priceSource).latestAnswer();
    require(price > 0, 'PRICE FEED ERROR!');
    return uint256(price * 1e10);
  }  

  /**
   * @dev Add Whitelist USD token
   * @param usdtToken whitelist usd token
   * @param enable status of usd token 
   */
  function addWhileListUSD(address usdtToken, bool enable) public onlyOwner {
    whiteListToken[usdtToken] = enable;
  }


  /**
   * @dev execute buy token
   * @param recipient the recipient of the IDO tokens
   * @return true if the transfer succeeds, false otherwise
   **/
  function buyTokenBNB(address recipient, address _referrer) public payable onlyNonContract returns (bool) {
    if (referrers[msg.sender] == address(0)
        && _referrer != address(0)
        && msg.sender != _referrer
        && msg.sender != referrers[_referrer]) {
        referrers[msg.sender] = _referrer;
        emit NewReferral(_referrer, msg.sender, 1);
    }
    
    uint256 price = getBNBPrice();
    uint256 usdtAmount = msg.value * price / 1e18;
    uint256 sold_amount = usdtAmount * 1e18 / tokenRate;
    // send ref reward
    if (referrers[msg.sender] != address(0)){
        uint256 f1_reward = sold_amount * f1_rate  / 100 ;
        if (f1_reward > 0) {
          refReward[referrers[msg.sender]] += f1_reward;
          IERC20Upgradeable(IDO_TOKEN).transfer(referrers[msg.sender], f1_reward);
          emit RefReward(msg.sender,referrers[msg.sender], f1_reward, 1);
        }
    }
    buyerAmount[recipient] += sold_amount;
    IERC20Upgradeable(IDO_TOKEN).transfer(recipient, sold_amount);
    emit SellIDO(msg.sender, sold_amount, usdtAmount);
    return (true);
  }

  /**
   * @dev execute buy Token
   **/
  function buyIDOUSD(
    address recipient,
    uint256 buy_amount,
    address token, 
    address _referrer
  ) public payable onlyNonContract returns (uint256) {
    require(whiteListToken[token], "USD Token invalid");
    if (referrers[msg.sender] == address(0)
        && _referrer != address(0)
        && msg.sender != _referrer
        && msg.sender != referrers[_referrer]) {
        referrers[msg.sender] = _referrer;
        emit NewReferral(_referrer, msg.sender, 1);
    }
    IERC20Upgradeable(token).transferFrom(msg.sender, address(this), buy_amount);
    uint256 sold_amount = (buy_amount * 1e18) / tokenRate;
    IERC20Upgradeable(IDO_TOKEN).transfer(recipient, sold_amount);
    // send ref reward
    if (referrers[msg.sender] != address(0)){
        uint256 f1_reward = sold_amount * f1_rate / 100;
        if (f1_reward > 0) {
          refReward[referrers[msg.sender]] += f1_reward;
          IERC20Upgradeable(IDO_TOKEN).transfer(referrers[msg.sender], f1_reward);
          emit RefReward(msg.sender,referrers[msg.sender], f1_reward, 1);
        }
        
    }
    buyerAmount[recipient] += sold_amount;
    emit SellIDO(msg.sender, sold_amount, buy_amount);
    return sold_amount;
  }

  /**
   
   */
  function receivedAmount(address recipient) external view returns (uint256) {
    if (is_enable) {
      return 0;
    }
    return buyerAmount[recipient] + refReward[recipient];
  }
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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * constructor() initializer {}
 * ```
 * ====
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the SellToken standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
 */
interface ISellToken {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function receivedAmount(address recipient) external view returns (uint256);

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
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