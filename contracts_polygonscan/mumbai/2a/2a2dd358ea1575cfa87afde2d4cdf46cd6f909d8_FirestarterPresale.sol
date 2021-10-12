// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
pragma abicoder v2;

import "./interfaces/IVesting.sol";
import "./Presale.sol";

/// @title Firestarter Presale Contract
/// @author Michael, Daniel Lee
/// @notice You can use this contract for presale of projects
/// @dev All function calls are currently implemented without side effects
contract FirestarterPresale is Presale {
    /**
     * @notice Deposit reward token when private sale
     * @dev Only owner can do this operation
     * @param user address of the participant
     * @param amount amount of reward token
     */
    function depositPrivateSale(address user, uint256 amount) external whileDeposited onlyOwner {
        require(isPrivateSaleOver == false, "depositPrivateSale: Private Sale is ended!");

        uint256 ftAmount = (amount * (10**IERC20Extended(fundToken).decimals()) * exchangeRate) /
            ACCURACY /
            (10**IERC20Extended(rewardToken).decimals());

        Recipient storage recp = recipients[user];
        recp.rtBalance = recp.rtBalance + amount;
        recp.ftBalance = recp.ftBalance + ftAmount;
        privateSoldAmount = privateSoldAmount + amount;
        privateSoldFunds[user] = privateSoldFunds[user] + ftAmount;

        if (inserted[user] == false) {
            inserted[user] = true;
            indexOf[user] = participants.length;
            participants.push(user);
        }

        IVesting(vesting).updateRecipient(user, recp.rtBalance);

        emit Vested(user, recp.rtBalance, true, block.timestamp);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IVesting {
    function updateRecipient(address, uint256) external;

    function setStartTime(uint256) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./libraries/AddressPagination.sol";
import "./interfaces/IERC20Extended.sol";
import "./interfaces/IWhitelist.sol";
import "./interfaces/IVesting.sol";

/// @title Firestarter Presale Contract
/// @author Michael, Daniel Lee
/// @notice You can use this contract for presale of projects
/// @dev All function calls are currently implemented without side effects
contract Presale is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressPagination for address[];

    struct Recipient {
        // Deposited Funds token amount of the recipient
        uint256 ftBalance;
        // Rewards Token amount that needs to be vested
        uint256 rtBalance;
    }

    struct AddressParams {
        // Fund token
        address fundToken;
        // Reward token(from the project)
        address rewardToken;
        // Owner of this project
        address projectOwner;
        // Contract that managers whitelisted users
        address whitelist;
        // Presale Vesting Contract
        address vesting;
    }

    struct PresaleParams {
        // Exchange rate between the Fund token and Reward token
        uint256 rate;
        // Timestamp when presale starts
        uint256 startTime;
        // Presale period
        uint256 period;
        // Service Fee : if `ACCURACY` is 1e10(default), 1e9 is 10%
        uint256 serviceFee;
        // Initial Deposited rewardToken amount
        uint256 initialRewardsAmount;
    }

    /// @notice General decimal values ACCURACY unless specified differently (e.g. fees, exchange rates)
    uint256 public constant ACCURACY = 1e10;

    /********************** Address Infos ***********************/

    /// @notice Token for funderside. (Maybe it will be the stable coin)
    address public fundToken;

    /// @notice Token for distribution as rewards.
    address public rewardToken;

    /// @notice Project Owner: The address where to withdraw funds token to after presale
    address public projectOwner;

    /// @dev WhiteList Contract: For checking if the user has passed the KYC
    address internal whitelist;

    /// @notice Vesting Contract
    address public vesting;

    /********************** Presale Params ***********************/

    /// @notice Fixed Rate between fundToken vs rewardsToken = rewards / funds * ACCURACY
    uint256 public exchangeRate;

    /// @notice Presale Period
    uint256 public presalePeriod;

    /// @notice Presale Start Time
    uint256 public startTime;

    /// @notice Service Fee : if `ACCURACY` is 1e10(default), 1e9 is 10%
    uint256 public serviceFee;

    /// @notice Initial Deposited rewardToken amount
    uint256 public initialRewardAmount;

    /********************** Status Infos ***********************/

    /// @dev Private sale status
    bool public isPrivateSaleOver;

    /// @notice Presale pause status
    bool public isPresalePaused;

    /// @notice If unsold reward token is withdrawn, set to true(false by default)
    bool public unsoldTokenWithdrawn;

    /// @notice Presale remaining time if paused
    uint256 public currentPresalePeriod;

    /// @dev Reward token amount sold by Private Sale (init with default value)
    uint256 public privateSoldAmount;

    /// @notice Reward token amount sold by Public Sale (init with default value)
    uint256 public publicSoldAmount;

    /// @notice Record of fund token amount sold in Private Presale (init with default value)
    mapping(address => uint256) public privateSoldFunds;

    /// @notice Participants information (init with default value)
    mapping(address => Recipient) public recipients;

    // Participants list (init with default value)
    address[] internal participants;
    mapping(address => uint256) internal indexOf;
    mapping(address => bool) internal inserted;

    /// @notice An event emitted when the private sale is done
    event PrivateSaleDone(uint256);

    /// @notice An event emitted when presale is started
    event PresaleManuallyStarted(uint256);

    /// @notice An event emitted when presale is paused
    event PresalePaused(uint256);

    /// @notice An event emitted when presale is resumed
    event PresaleResumed(uint256);

    /// @notice An event emitted when a user vested reward token
    event Vested(address indexed user, uint256 amount, bool isPrivate, uint256 timestamp);

    /// @notice An event emitted when the remaining reward token is withdrawn
    event WithdrawUnsoldToken(address indexed receiver, uint256 amount, uint256 timestamp);

    /// @notice An event emitted when funded token is withdrawn(project owner and service fee)
    event WithdrawFunds(address indexed receiver, uint256 amount, uint256 timestamp);

    /// @notice An event emitted when startTime is set
    event StartTimeSet(uint256 startTime);

    modifier whileOnGoing() {
        require(isPresaleGoing(), "Presale is not in progress");
        _;
    }

    modifier whilePaused() {
        require(isPresalePaused, "Presale is not paused");
        _;
    }

    modifier whileFinished() {
        require(
            block.timestamp > startTime + currentPresalePeriod,
            "Presale has not been ended yet!"
        );
        _;
    }

    modifier whileDeposited() {
        require(
            _getDepositedRewardTokenAmount() >= initialRewardAmount,
            "Deposit enough rewardToken tokens to the vesting contract first!"
        );
        _;
    }

    function initialize(AddressParams memory _addrs, PresaleParams memory _presale)
        external
        initializer
    {
        require(_addrs.fundToken != address(0), "fund token address cannot be zero");
        require(_addrs.rewardToken != address(0), "reward token address cannot be zero");
        require(_addrs.projectOwner != address(0), "project owner address cannot be zero");
        require(_addrs.whitelist != address(0), "whitelisting contract address cannot be zero");
        require(_addrs.vesting != address(0), "init: vesting contract address cannot be zero");

        require(_presale.startTime > block.timestamp, "start time must be in the future");
        require(_presale.rate > 0, "exchange rate cannot be zero");
        require(_presale.period > 0, "presale period cannot be zero");

        __Ownable_init();

        fundToken = _addrs.fundToken;
        rewardToken = _addrs.rewardToken;
        projectOwner = _addrs.projectOwner;
        whitelist = _addrs.whitelist;
        vesting = _addrs.vesting;

        exchangeRate = _presale.rate;
        startTime = _presale.startTime;
        presalePeriod = _presale.period;
        serviceFee = _presale.serviceFee;
        initialRewardAmount = _presale.initialRewardsAmount;

        currentPresalePeriod = presalePeriod;
    }

    /**
     * @notice Return the number of participants
     */
    function participantCount() external view returns (uint256) {
        return participants.length;
    }

    /**
     * @notice Return the list of participants
     */
    function getParticipants(uint256 page, uint256 limit)
        external
        view
        returns (address[] memory)
    {
        return participants.paginate(page, limit);
    }

    /**
     * @notice Finish Private Sale
     * @dev Only owner can end private sale
     */
    function endPrivateSale() external onlyOwner {
        isPrivateSaleOver = true;

        if (startTime < block.timestamp) startTime = block.timestamp;

        emit PrivateSaleDone(block.timestamp);
    }

    /**
     * @notice Set presale start time
     * @dev This should be called before presale starts
     * @param newStartTime New start time
     */
    function setStartTime(uint256 newStartTime) external onlyOwner {
        require(
            startTime >= block.timestamp || isPrivateSaleOver == false,
            "setStartTime: Presale already started"
        );
        require(newStartTime > block.timestamp, "setStartTime: Should be time in future");

        startTime = newStartTime;

        emit StartTimeSet(newStartTime);
    }

    /**
     * @notice Start presale
     * @dev Need to check if requirements are satisfied
     */
    function startPresale() external whileDeposited onlyOwner {
        require(isPrivateSaleOver == true, "startPresale: Private Sale has not been done yet!");

        require(startTime > block.timestamp, "startPresale: Presale has been already started!");

        startTime = block.timestamp;

        emit PresaleManuallyStarted(block.timestamp);
    }

    /**
     * @notice Pause the ongoing presale by mergency
     * @dev Remaining time is not considered
     */
    function pausePresaleByEmergency() external whileOnGoing onlyOwner {
        isPresalePaused = true;
        currentPresalePeriod = startTime + currentPresalePeriod - block.timestamp;
        emit PresalePaused(block.timestamp);
    }

    /**
     * @notice Resume presale
     * @dev Need to check if requirements are satisfied
     */
    function resumePresale() external whilePaused onlyOwner {
        isPresalePaused = false;
        startTime = block.timestamp;
        emit PresaleResumed(block.timestamp);
    }

    /**
     * @notice Deposit fund token to the pool
     * @dev Receive funds token from the participants with checking the requirements.
     * @param amount amount of fund token
     */
    function deposit(uint256 amount) external whileOnGoing {
        // check if user is in white list
        (address user, bool isKycPassed, uint256 publicMaxAlloc, , ) = IWhitelist(whitelist)
            .getUser(msg.sender);
        require(user != address(0), "Deposit: Not exist on the whitelist");
        require(isKycPassed, "Deposit: Not passed KYC");

        // calculate fund token balance after deposit
        // we assume private sale is always finished before public sale starts
        // thus rtBalance includes the private sale amount as well
        Recipient storage recp = recipients[msg.sender];
        uint256 newFundBalance = recp.ftBalance + amount;

        // `newFundBalance` includes sold token amount both in private presale and public presale,
        // but `publicMaxAlloc` is only for public presale
        require(
            publicMaxAlloc + privateSoldFunds[user] >= newFundBalance,
            "Deposit: Can't exceed the publicMaxAlloc!"
        );

        IERC20Upgradeable(fundToken).safeTransferFrom(msg.sender, address(this), amount);

        // calculate reward token amount from fund token amount
        uint256 rtAmount = (amount * (10**IERC20Extended(rewardToken).decimals()) * ACCURACY) /
            exchangeRate /
            (10**IERC20Extended(fundToken).decimals());

        recp.ftBalance = newFundBalance;
        recp.rtBalance = recp.rtBalance + rtAmount;
        publicSoldAmount = publicSoldAmount + rtAmount;

        if (inserted[user] == false) {
            inserted[user] = true;
            indexOf[user] = participants.length;
            participants.push(user);
        }

        IVesting(vesting).updateRecipient(msg.sender, recp.rtBalance);

        emit Vested(msg.sender, recp.rtBalance, false, block.timestamp);
    }

    /**
     * @notice Withdraw fund tokens to the project owner / charge service fee
     * @dev After presale ends, we withdraw funds to project owner by charging a service fee
     * @param treasury address of the participant
     */
    function withdrawFunds(address treasury) external whileFinished onlyOwner {
        require(treasury != address(0), "withdraw: Treasury can't be zero address");

        uint256 balance = IERC20Upgradeable(fundToken).balanceOf(address(this));
        uint256 feeAmount = (balance * serviceFee) / ACCURACY;
        uint256 actualFunds = balance - feeAmount;

        emit WithdrawFunds(projectOwner, actualFunds, block.timestamp);
        emit WithdrawFunds(treasury, feeAmount, block.timestamp);

        IERC20Upgradeable(fundToken).safeTransfer(projectOwner, actualFunds);
        IERC20Upgradeable(fundToken).safeTransfer(treasury, feeAmount);
    }

    /**
     * @notice Withdraw Unsold reward token to the project owner
     * @dev After presale ends, we withdraw unsold rewardToken token to project owner.
     */
    function withdrawUnsoldToken() external whileFinished onlyOwner {
        unsoldTokenWithdrawn = true;

        uint256 totalBalance = _getDepositedRewardTokenAmount();
        uint256 totalSoldAmount = privateSoldAmount + publicSoldAmount;
        uint256 unsoldAmount = totalBalance - totalSoldAmount;

        emit WithdrawUnsoldToken(projectOwner, unsoldAmount, block.timestamp);

        IERC20Upgradeable(rewardToken).safeTransferFrom(address(vesting), projectOwner, unsoldAmount);
    }

    /**
     * @notice Start vesting
     * @dev Check if presale is finished
     */
    function startVesting() external whileFinished onlyOwner {
        require(
            unsoldTokenWithdrawn,
            "startVesting: can only start vesting after withdrawing unsold tokens"
        );

        IVesting(vesting).setStartTime(block.timestamp + 1);
    }

    /**
     * @notice Check if Presale is in progress
     * @return True: in Presale, False: not started or already ended
     */
    function isPresaleGoing() public view returns (bool) {
        if (isPresalePaused || isPrivateSaleOver == false) return false;

        if (_getDepositedRewardTokenAmount() < initialRewardAmount) return false;

        uint256 endTime = startTime + currentPresalePeriod;
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    /**
     * @notice Returns the total vested reward token amount
     * @dev Get the rewardToken token amount of vesting contract
     * @return Reward token balance of vesting contract
     */
    function _getDepositedRewardTokenAmount() internal view returns (uint256) {
        return IERC20Upgradeable(rewardToken).balanceOf(vesting);
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library AddressPagination {
    function paginate(
        address[] memory array,
        uint256 page,
        uint256 limit
    ) internal pure returns (address[] memory result) {
        result = new address[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (page * limit + i >= array.length) {
                result[i] = address(0);
            } else {
                result[i] = array[page * limit + i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IERC20Extended {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IWhitelist {
    function addToWhitelist(address[] memory, uint256[] memory) external;

    function removeFromWhitelist(address[] memory _user) external;

    function getUser(address _user)
        external
        view
        returns (
            address,
            bool,
            uint256,
            bool,
            uint256
        );
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

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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