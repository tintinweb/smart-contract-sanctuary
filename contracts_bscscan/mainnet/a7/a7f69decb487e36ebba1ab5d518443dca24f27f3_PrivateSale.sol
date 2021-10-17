/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

pragma solidity ^0.8.0;

//SPDX-License-Identifier: LicenseRef-LICENSE

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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



interface ILPLocker {
    function lock(address _token, address _owner, uint _amount, uint unlocksAt) external returns (uint);

    function unlock(uint lockId) external;

    function unlockWithSpecifiedAmount(uint lockId, uint _amount) external;
}

contract PrivateSale is OwnableUpgradeable {
    address public tokenAddress;
    uint constant rate = 19455; // 19455 Coins per BNB
    uint constant referral = 500; // 5% to referral
    uint constant minBuy = 1e16; // 0.01BNB
    uint constant maxBuy = 15 * 1e18;// 15BNB

    ILPLocker public _lpLocker;

    mapping (address => uint[]) public vestingLedger;

    function initialize(address _tokenAddress, address lpLocker) public initializer {
        __Ownable_init();
        tokenAddress = _tokenAddress;
        _lpLocker = ILPLocker(lpLocker);
    }

    function calcBP(uint _bp, uint _base) internal returns (uint) {
        return (_bp * _base) / 10000;
    }

    function calcPurchasedAmount(uint _amount) internal returns (uint) {
        uint baseAmount = (_amount * rate * (10 ** IERC20Metadata(tokenAddress).decimals())) / 1e18;

        // Cashback
        uint currentPstHour = (((block.timestamp % 86400) * 100) / 3600) - 800;

        uint pstEveCashback;
        if (currentPstHour >= 1900 && currentPstHour < 2000) {
            pstEveCashback = (baseAmount * 10) / 100;
        }

        return baseAmount + pstEveCashback;
    }

    function _buy(address _buyer, address _referrer, uint _amount) internal {
        require(_amount >= minBuy, "DPAD PS: Cannot buy for less then 0.01 BNB");
        require(_amount <= maxBuy, "DPAD PS: Cannot buy for more then 15 BNB");
        require(_buyer != _referrer, "DPAD PS: You cannot referer to yourself");

        uint tokenPurchased = calcPurchasedAmount(_amount);

        // Send 20% to user directly
        require(IERC20(tokenAddress).transfer(_buyer, calcBP(2000, tokenPurchased)), "DPAD PS: Token transfer to buyer failed");

        require(IERC20(tokenAddress).approve(address(_lpLocker), calcBP(8000, tokenPurchased)), "DPAD PS: Approval to locker failed");
        // lock next 20% for 1 month
        vestingLedger[_buyer].push(_lpLocker.lock(tokenAddress, _buyer, calcBP(2000, tokenPurchased), block.timestamp + 30 days));
        // lock next 20% for 1 month
        vestingLedger[_buyer].push(_lpLocker.lock(tokenAddress, _buyer, calcBP(2000, tokenPurchased), block.timestamp + 60 days));
        // lock next 20% for 1 month
        vestingLedger[_buyer].push(_lpLocker.lock(tokenAddress, _buyer, calcBP(2000, tokenPurchased), block.timestamp + 90 days));
        // lock next 20% for 1 month
        vestingLedger[_buyer].push(_lpLocker.lock(tokenAddress, _buyer, calcBP(2000, tokenPurchased), block.timestamp + 120 days));

        if (_referrer != address(0)) {
            uint _referral = calcBP(referral, tokenPurchased);
            require(IERC20(tokenAddress).transfer(_referrer, _referral), "DPAD PS: Token transfer to referrer failed");
        }
    }

    function buy(address _referrer) public payable {
        _buy(msg.sender, _referrer, msg.value);
    }

    function withdrawBNB() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawToken(address _tokenAddress) public onlyOwner {
        require(IERC20(_tokenAddress).transfer(owner(), IERC20(_tokenAddress).balanceOf(address(this))), "DPAD PS: Token transfer failed");
    }

    receive() external payable {
        _buy(msg.sender, address(0), msg.value);
    }
}