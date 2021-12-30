// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract StakingReward is Context, Ownable, Initializable {
    address public stakedToken;
    address public rewardToken;
    address public devWallet;
    uint256 public stakedSum;

    uint256 private globalCoefficient;
    uint256 private startProcess;
    uint256 private lastUpdate;
    uint256 private tokenRate;
    uint256 private holdersAmount;
    uint256 private campaignDuration;

    uint256 private constant percentToDev = 3;
    uint256 private constant percentToDead = 3;
    uint256 private constant PERCENT_BASE = 100;

    uint256 private constant MULTIPLIER = 10**20;
    uint256 private constant LOCK_UP_PERIOD = 60 * 60 * 24 * 30;
    address private constant DEAD_WALLET =
        0x000000000000000000000000000000000000dEaD;

    mapping(address => UserInfo) private users;

    struct UserInfo {
        uint256 amount;
        uint256 start;
        uint256 globalCoefficientMinus;
        int256 assignedReward;
    }

    event DepositTokenForUser(
        address investor,
        uint256 amountStaked,
        uint256 start
    );

    event ClaimForUser(address investor, uint256 amountRewarded);

    event WithdrawForUser(address investor, uint256 amountStaked);

    event OwnerGotTokens(address to, uint256 amount);

    event EmergencyExit(uint256 amount);

    modifier contractWasInitiated() {
        require(tokenRate > 0, "Staking: not init");
        _;
    }

    /**
     * @param _stakedToken token for staking
     * @param _rewardToken token for rewarding
     * @param _devWallet address for devWallet
     * @param _period duration of staking process
     */
    function initStaking(
        address _stakedToken,
        address _rewardToken,
        address _devWallet,
        uint256 _period
    ) external initializer {
        require(
            _rewardToken != address(0) &&
                _stakedToken != address(0) &&
                _period > 0 &&
                _devWallet != address(0),
            "Staking: Uncorrect data for init"
        );

        uint256 balance = IERC20(_rewardToken).balanceOf(address(this));
        require(balance > 0, "Staking: Uncorrect data for init");

        rewardToken = _rewardToken;
        stakedToken = _stakedToken;
        devWallet = _devWallet;
        tokenRate = (balance * MULTIPLIER) / _period;
        campaignDuration = _period;
    }

    /**
     * @param _amount tokens for depositing
     */
    function deposit(uint256 _amount) external contractWasInitiated {
        require(_amount > 0, "Staking: amount == 0");

        if (startProcess == 0) startProcess = block.timestamp;
        else {
            require(
                block.timestamp - startProcess < campaignDuration,
                "Staking: out of time"
            );
        }

        uint256 amountBefore = IERC20(stakedToken).balanceOf(address(this));
        address investor = _msgSender();

        if (users[investor].amount == 0) {
            holdersAmount += 1;
            if (users[investor].start == 0)
                users[investor].start = block.timestamp;
        }

        require(
            IERC20(stakedToken).transferFrom(investor, address(this), _amount),
            "Staking: deposited !transfer"
        );

        _amount = IERC20(stakedToken).balanceOf(address(this)) - amountBefore;
        updateVars(investor, int256(_amount));

        emit DepositTokenForUser(investor, _amount, users[investor].start);
    }

    /**
     * @param _amount tokens for withdrawing
     */
    function withdraw(uint256 _amount) external contractWasInitiated {
        address investor = _msgSender();
        UserInfo memory _user = users[investor];

        require(_amount > 0, "Staking: amount > 0");
        require(_user.amount >= _amount, "Staking: _user.amount >= amount");

        updateVars(investor, (-1) * int256(_amount));

        if (block.timestamp - _user.start < LOCK_UP_PERIOD) {
            uint256 toDead;
            uint256 toDev;
            toDead = (_amount * percentToDead) / PERCENT_BASE;
            toDev = (_amount * percentToDev) / PERCENT_BASE;
            _amount -= toDead;
            _amount -= toDev;

            if (toDead > 0) {
                require(
                    IERC20(stakedToken).transfer(DEAD_WALLET, toDead),
                    "Staking: !transfer"
                );
            }
            if (toDev > 0) {
                require(
                    IERC20(stakedToken).transfer(devWallet, toDev),
                    "Staking: !transfer"
                );
            }
        }

        require(
            IERC20(stakedToken).transfer(investor, _amount),
            "Staking: !transfer"
        );

        if (users[investor].amount == 0) {
            users[investor].start = 0;
            if (getReward(investor) > 0) claim();
            if (block.timestamp - startProcess <= campaignDuration)
                holdersAmount -= 1;
        }

        if (
            stakedSum == 0 && block.timestamp - startProcess < campaignDuration
        ) {
            campaignDuration =
                campaignDuration -
                (block.timestamp - startProcess);
            startProcess = 0;
        }

        emit WithdrawForUser(investor, _amount);
    }

    function claim() public contractWasInitiated {
        address investor = _msgSender();
        UserInfo memory _user = users[investor];

        uint256 multiplier = MULTIPLIER;
        int256 rewards = calculateReward(investor);

        require(rewards > 0, "Staking: rewards != 0");

        uint256 amountForTransfer;

        if (block.timestamp - startProcess <= campaignDuration)
            amountForTransfer = uint256(
                rewards / int256(multiplier * multiplier)
            );
        else {
            holdersAmount -= 1;
            if (holdersAmount == 0) {
                amountForTransfer = IERC20(rewardToken).balanceOf(
                    address(this)
                );
            } else {
                amountForTransfer = uint256(
                    rewards / int256(multiplier * multiplier)
                );
            }
        }

        require(
            IERC20(rewardToken).transfer(investor, amountForTransfer),
            "Staking: reward !transfer"
        );

        users[investor].assignedReward = _user.assignedReward - rewards;
        emit ClaimForUser(investor, amountForTransfer);
    }

    /**
     * @param _investor address of user
     * @return rewards next rewards for investor
     */
    function getReward(address _investor) public view returns (int256 rewards) {
        uint256 multiplier = MULTIPLIER;
        rewards = calculateReward(_investor);
        rewards = (rewards / int256(multiplier * multiplier));
    }

    /**
     * @param _to user for transfering
     */
    function getTokensForOwner(address _to) external onlyOwner {
        uint256 balance = IERC20(stakedToken).balanceOf(address(this));
        require(balance > stakedSum, "Staking:balance <= stakedSum");
        uint256 amount = balance - stakedSum;
        if (amount > 0) {
            require(
                IERC20(stakedToken).transfer(_to, amount),
                "Staking: !transfer"
            );
        }
        emit OwnerGotTokens(_to, amount);
    }

    function emergencyExit() external onlyOwner {
        uint256 amount = IERC20(rewardToken).balanceOf(address(this));
        if (amount > 0) {
            require(
                IERC20(rewardToken).transfer(owner(), amount),
                "Staking: !transfer"
            );
        }
        emit EmergencyExit(amount);
    }

    /**
     * @param _investor address of user
     * @return amount of tokens in stake
     * @return start is when user staked first time
     */
    function getUserInfo(address _investor)
        external
        view
        returns (
            uint256 amount,
            uint256 start,
            uint256 globalCoefficientMinus,
            int256 assignedReward
        )
    {
        amount = users[_investor].amount;
        start = users[_investor].start;
        globalCoefficientMinus = users[_investor].globalCoefficientMinus;
        assignedReward = users[_investor].assignedReward;
    }

    function getPoolInfo()
        external
        view
        returns (
            address _stakedToken,
            address _devWallet,
            uint256 _globalCoefficient,
            uint256 _lastUpdate,
            uint256 _tokenRate,
            uint256 _stakedSum,
            uint256 _holdersAmount
        )
    {
        _stakedToken = stakedToken;
        _devWallet = devWallet;
        _globalCoefficient = globalCoefficient;
        _lastUpdate = lastUpdate;
        _tokenRate = tokenRate;
        _stakedSum = stakedSum;
        _holdersAmount = holdersAmount;
    }

    function calculateReward(address investor)
        internal
        view
        returns (int256 rewards)
    {
        UserInfo memory _user = users[investor];
        uint256 stamp = getStamp();
        if (stakedSum != 0)
            rewards = int256(
                (_user.amount * tokenRate * (stamp - lastUpdate) * MULTIPLIER) /
                    stakedSum
            );
        rewards =
            rewards +
            _user.assignedReward +
            int256(
                _user.amount *
                    tokenRate *
                    (globalCoefficient - _user.globalCoefficientMinus)
            );
    }

    function updateVars(address investor, int256 _amount) private {
        uint256 stamp = getStamp();
        users[investor].assignedReward = calculateReward(investor);
        if (stakedSum != 0)
            globalCoefficient +=
                ((stamp - lastUpdate) * MULTIPLIER) /
                stakedSum;
        users[investor].globalCoefficientMinus = globalCoefficient;
        users[investor].amount = uint256(
            int256(users[investor].amount) + _amount
        );
        stakedSum = uint256(int256(stakedSum) + _amount);
        lastUpdate = stamp;
    }

    function getStamp() private view returns (uint256 stamp) {
        if (block.timestamp - startProcess < campaignDuration) {
            stamp = block.timestamp;
        } else {
            stamp = startProcess + campaignDuration;
        }
    }
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