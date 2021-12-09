pragma solidity ^0.8.0;
import "../dependencies/open-zeppelin/proxy/utils/Initializable.sol";
import "../dependencies/open-zeppelin/token/ERC20/IERC20Upgradeable.sol";
import "../dependencies/open-zeppelin/access/OwnableUpgradeable.sol";

contract PrivateSale is Initializable , OwnableUpgradeable{
    
    constructor() initializer {}

    function initialize() initializer public {
        __Ownable_init();
    }

  struct UserData {
    uint256 lockAmount;
    uint256 claimedAmount;
    uint256 firstRelease;
    uint firstReleaseBlock;
  }  

  struct RefInfo {
    bool enable;
    uint256 limitSell;
    uint256 totalSold;
  }  

  address public vaultAddress;
  mapping(address => RefInfo) public whiteList;
  mapping(address => UserData) public SellLockUser;  
  address public SELL_TOKEN;
  uint256 public startUnlockBlock;
  uint256 public totalUnlockBlock;
  uint256 public totalCiffBlock;
  bool public startSell;
  uint256 public tokenPrice;
  mapping(address => bool) public whiteListToken;

  event buyStableTokenExecuted(address indexed buyer, uint256 usdtAmount, uint256 tokenAmount);

  modifier unlockEnabled() {
    require(startUnlockBlock != 0, 'Unlock disabled');
    _;
  }

  modifier sellEnabled() {
    require(startSell, 'Private Sale disabled');
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
   * @dev transfer BNB to an address, revert if it fails.
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
    SELL_TOKEN = sell_token;
  }

  /**
   * @dev Start sale token
   
   */
  function enableSellToken(bool isEnable) public onlyOwner {
    startSell = isEnable;
  }

  /**
   * @dev Reset Wrong.
   * @param ref Address claim
   */
  function resetWrongClaim(address ref) public onlyOwner {
    SellLockUser[ref].firstReleaseBlock = 0;
  }

  /**
   * @dev Set Token Price for sale.
   * @param _tokenPrice price token for sale
   */
  function setSellTokenPrice(uint256 _tokenPrice) public onlyOwner {
    tokenPrice = _tokenPrice;
  }

  /**
   * @dev Set start unlock token
   */
  function startUnlock() public onlyOwner {
    require(startUnlockBlock == 0, 'cannot update start time');
    startUnlockBlock = block.number;
  }

  /**
   * @dev Set vault address
   */
  function setVaultAddress(address vaultAd) public onlyOwner {
    vaultAddress = vaultAd;
  }


  /**
   * @dev Set set Total Ciff Block
   */
  function setTotalCiffBlock(uint256 ciffBlock) public onlyOwner {
    totalCiffBlock = ciffBlock;
  }

  /**
   * @dev Set total unlock block
   * @param totalBlock Total Lock Block
   */
  function setTotalUnlockBlock(uint totalBlock) public onlyOwner {
    totalUnlockBlock = totalBlock;
  }  

  /**
   * @dev Add Whitelist ref
   * @param ref whitelist ref
   * @param limitSell limit Token
   * @param enable status of ref
   */
  function addWhileList(address ref, uint256 limitSell, bool enable) public onlyOwner {
    whiteList[ref] = RefInfo(enable, limitSell, whiteList[ref].totalSold);
  }

  /**
   * @dev Add invester
   * @param ref whitelist ref
   * @param totalInvest total invest
   */
  function addInvester(address ref, uint256 totalInvest) public onlyOwner {
    whiteList[ref] = RefInfo(true, totalInvest, totalInvest);
    uint256 lockAmount = totalInvest * 935 /1000;
    SellLockUser[ref].lockAmount = lockAmount;
    SellLockUser[ref].firstRelease = totalInvest - lockAmount;
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
   * @dev remove white list
   * @param ref ref
   */
  function removeWhiteList(address ref) public onlyOwner {
    whiteList[ref] = RefInfo(false, 0, 0);
    SellLockUser[ref].firstRelease = 0;
    SellLockUser[ref].lockAmount = 0;
  }

  /**
   * @dev Get Claimable sell oken
   * @param buyerAddress Adddress of buyer
   * @return Amount sell token can claimed
   **/
  function getClaimable(address buyerAddress) public view returns (uint256) {
    if (startUnlockBlock == 0){
        return 0;
    }  

    uint256 totalLockAmount = SellLockUser[buyerAddress].lockAmount;
    if (totalLockAmount == 0 ) {
        return 0;    
    }
    if (SellLockUser[buyerAddress].firstReleaseBlock == 0 ) {
        return SellLockUser[buyerAddress].firstRelease;    
    }

    uint256 userStartUnlockBlock = SellLockUser[buyerAddress].firstReleaseBlock + totalCiffBlock;
    if (block.number < userStartUnlockBlock) {
        return 0;
    }
    uint256 tokenPerBlock = totalLockAmount / totalUnlockBlock;
    uint progressBlock = block.number - userStartUnlockBlock;
    uint256 fullclaimableAmount;
    if (progressBlock > totalUnlockBlock) {
        fullclaimableAmount = totalLockAmount;
    } else {
        fullclaimableAmount = progressBlock * tokenPerBlock;
    }
    return fullclaimableAmount - SellLockUser[buyerAddress].claimedAmount;
  }  

  /**
   * @dev Set total unlock block
   * @param recipient receipt address token
   */
  function claim(address recipient) public unlockEnabled {
    require(whiteList[recipient].enable, "the address is not valid");
    uint256 claimableAmount = getClaimable(recipient);
    if (SellLockUser[recipient].firstReleaseBlock == 0 ){
      SellLockUser[recipient].firstReleaseBlock = block.number;
    } else {
      SellLockUser[recipient].claimedAmount += claimableAmount;
    }
    IERC20Upgradeable(SELL_TOKEN).transfer(recipient, claimableAmount);
  }   

  /**
   * @dev execute buy token
   * @param recipient the recipient of the IDO tokens
   * @param usdAmount USD Amount 
   * @return true if the transfer succeeds, false otherwise
   **/
  function buyTokenByUSD(address recipient, uint256 usdAmount, address usdToken) public sellEnabled returns (bool) {
    require(whiteList[recipient].enable, "the address is not valid");
    require(whiteListToken[usdToken], "the buy token is not valid");
    require(msg.sender == recipient, "the buyer is not valid");
    uint256 tokenAmount = usdAmount * 1e18 / tokenPrice;
    uint256 availableTokenAmount = whiteList[recipient].limitSell - whiteList[recipient].totalSold;
    uint256 soldToken = tokenAmount > availableTokenAmount ? availableTokenAmount : tokenAmount;
    uint256 soldUsdtAmount = soldToken * tokenPrice / 1e18;
    if (soldToken > 0) {
        uint256 lockAmount = soldToken * 935 / 1000;
        SellLockUser[msg.sender].lockAmount += lockAmount;
        whiteList[recipient].totalSold += soldToken;
        SellLockUser[msg.sender].firstRelease += soldToken - lockAmount;
        IERC20Upgradeable(usdToken).transferFrom(msg.sender, vaultAddress, soldUsdtAmount);
        emit buyStableTokenExecuted(recipient, soldUsdtAmount, soldToken);
    }
    return (true);
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