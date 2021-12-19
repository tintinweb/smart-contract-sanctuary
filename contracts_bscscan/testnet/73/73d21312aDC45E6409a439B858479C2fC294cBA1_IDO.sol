// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;


interface IBlacklist {

    function addBlacklist(address _account, string calldata _info) external;
    function removeBlacklist(address _account) external;
    function inBlacklist(address _account) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITierConfig.sol";
import "./IBlacklist.sol";
import "./IIDO.sol";

// IDO contract
contract IDO is IIDOUserQuery, IIDO, Ownable, Pausable {
    event UserDeposited(address indexed user, uint256 amount);
    event Setuped(address indexed operator);
    event AddedWhitelist(address indexed _account);
    event RemovedWhitelist(address indexed _account);
    event Withdrawed(address indexed _operator, address indexed _walletAddress, uint256 _tokenAmount, uint256 _etherAmount);

    struct UserDepositInfo {
        address account;
        uint256 amount;
    }

    // enumerable participant deposit amount mapping
    mapping(address => uint256) private userAmountMapping;
    address[] private userArray;

    // payment token address
    // if 0x0 use native token BNB/ETH, else use ERC20 token at address
    address public paymentTokenAddress;
    // max amount of tokens that can be deposited
    uint256 public paymentTokenCap;
    // current amount of tokens that have been deposited
    uint256 public paymentTokenTotalAmount;
    // current amount of tokens that have been withdrawn
    uint256 public paymentTokenWithdrawAmount;
    // min amount of tokens that can be deposited
    uint256 public paymentMinAmount;
    // max amount of tokens that can be deposited
    uint256 public paymentMaxAmount;
    // ido start time
    uint256 public startTime;
    // ido end time
    uint256 public endTime;
    // [0, 1, 2, 3] 0: Public, 1: Tier 1, 2: Tier 2, 3: Tier 3
    uint8[] public availableTiers;

    // global blacklist for platform to block user
    IBlacklist public blacklist;
    // global tier config, to query user's tier
    ITierConfig public tierConfig;
    // skip check tier whitelist
    mapping(address => bool) public isWhitelisted;

    constructor(IBlacklist _blacklist, ITierConfig _tierConfig) {
        blacklist = _blacklist;
        tierConfig = _tierConfig;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setup(
        address _paymentTokenAddress,
        uint256 _paymentTokenCap,
        uint256 _paymentMinAmount,
        uint256 _paymentMaxAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint8[] memory _availableTiers,
        bool _pauseVal
    ) public onlyOwner {
        paymentTokenAddress = _paymentTokenAddress;
        paymentTokenCap = _paymentTokenCap;
        paymentMinAmount = _paymentMinAmount;
        paymentMaxAmount = _paymentMaxAmount;
        startTime = _startTime;
        endTime = _endTime;
        availableTiers = _availableTiers;
        if (_pauseVal != paused()) {
            _pauseVal ? _pause() : _unpause();
        }

        emit Setuped(msg.sender);
    }

    function getAvailableTiers() public view returns (uint8[] memory) {
        return availableTiers;
    }

    function isIDOTime() override public view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    function isPoolFull() override public view returns (bool) {
        return paymentTokenTotalAmount >= paymentTokenCap;
    }

    function isUserAvailableTier(address _user) override public view returns (bool) {
        // public
        if (availableTiers.length == 0 || availableTiers[0] == 0) {
            return true;
        }
        // user best tier at IDO startTime
        uint8 tier = tierConfig.getHandsomeTierAtTimestamp(_user, startTime);
        for (uint8 i = 0; i < availableTiers.length; i++) {
            // public
            if (availableTiers[i] == 0) {
                return true;
            }
            // user's tier satisfy availableTiers
            if (tier != 0 && tier <= availableTiers[i]) {
                return true;
            }
        }
        return false;
    }

    function isPaymentERC20() private view returns (bool) {
        return paymentTokenAddress != address(0);
    }

    function isUserDeposited(address _user) override public view returns (bool) {
        return userAmountMapping[_user] != 0;
    }

    function getUserArrayLength() override external view returns (uint256) {
        return userArray.length;
    }

    // for vesting contract query user amount
    function getUserDepositedAmount(address _user)
        public
        view
        override
        returns (uint256)
    {
        return userAmountMapping[_user];
    }

    // for admin download all user deposit info
    function getUserDepositedArray()
        public
        view
        returns (UserDepositInfo[] memory)
    {
        UserDepositInfo[] memory result = new UserDepositInfo[](
            userArray.length
        );
        for (uint256 i = 0; i < userArray.length; i++) {
            result[i] = UserDepositInfo(
                userArray[i],
                userAmountMapping[userArray[i]]
            );
        }
        return result;
    }

    function tokenBalance() public view returns (uint256) {
        return paymentTokenTotalAmount - paymentTokenWithdrawAmount;
    }

    function addWhitelist(address _account) external onlyOwner {
        isWhitelisted[_account] = true;
        emit AddedWhitelist(_account);
    }

    function removeWhitelist(address _account) external onlyOwner {
        isWhitelisted[_account] = false;
        emit RemovedWhitelist(_account);
    }

    function inWhitelist(address _account) override public view returns (bool) {
        return isWhitelisted[_account];
    }

    // Participate in IDO
    function deposit(uint256 _amount) override external payable whenNotPaused {
        require(isIDOTime(), "IDO: not ido time");
        require(!isPoolFull(), "IDO: pool is full");
        if (!isPaymentERC20()) {
            require(
                _amount == msg.value,
                "IDO: amount is not equal to msg.value"
            );
        }
        require(_amount >= paymentMinAmount, "IDO: amount < minAmount");
        require(_amount <= paymentMaxAmount, "IDO: amount > maxAmount");
        address user = msg.sender;
        require(!blacklist.inBlacklist(user), "IDO: blacklisted");
        require(!isUserDeposited(user), "IDO: already deposited");

        // in whitelist skip check tier
        if (!inWhitelist(user)) {
            require(
                isUserAvailableTier(user),
                "IDO: user is not available tier"
            );
        }
        userAmountMapping[user] = _amount;
        userArray.push(user);
        paymentTokenTotalAmount += _amount;

        if (isPaymentERC20()) {
            IERC20(paymentTokenAddress).transferFrom(
                address(user),
                address(this),
                _amount
            );
        }

        emit UserDeposited(user, _amount);
    }

    // Withdraw IDO token to admin's wallet
    function finalWithdraw(address payable withdrawWalletAddress)
        public
        onlyOwner
    {
        require(
            withdrawWalletAddress != address(0),
            "IDO: withdrawWalletAddress is not valid"
        );
        require(
            paymentTokenTotalAmount > 0,
            "IDO: paymentTokenTotalAmount is not valid"
        );
        require(tokenBalance() > 0, "IDO: balance is empty");
        paymentTokenWithdrawAmount = paymentTokenTotalAmount;
        uint256 withdrawTokenAmount = 0;
        if (isPaymentERC20()) {
            withdrawTokenAmount = IERC20(paymentTokenAddress).balanceOf(address(this));
            IERC20(paymentTokenAddress).transfer(
                withdrawWalletAddress,
                withdrawTokenAmount
            );
        }
        uint256 nativeBalance = address(this).balance;
        if (nativeBalance > 0) {
            withdrawWalletAddress.transfer(nativeBalance);
        }
        emit Withdrawed(msg.sender, withdrawWalletAddress, withdrawTokenAmount, nativeBalance);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "./IIDOUserQuery.sol";

interface IIDO is IIDOUserQuery {
    function paymentTokenTotalAmount() external view returns (uint256);
    function isIDOTime() external view returns (bool);
    function isPoolFull() external view returns (bool);
    function getUserArrayLength() external view returns (uint256);
    function isUserAvailableTier(address _user) external view returns (bool);
    function isUserDeposited(address _user) external view returns (bool);
    function inWhitelist(address _account) external view returns (bool);
    function deposit(uint256 _amount) external payable;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;


interface IIDOUserQuery {
    function getUserDepositedAmount(address _user) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface ITierConfig {
    function isTier(address account, uint8 tier) external view returns (bool);
    function isTierAtTimestamp(address account, uint8 tier, uint256 t) external view  returns (bool);
    
    // get account best tier
    function getHandsomeTier(address account) external view returns (uint8);
    function getHandsomeTierAtTimestamp(address account, uint256 t) external view returns (uint8);
}