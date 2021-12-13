// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../libraries/Errors.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IBentPool.sol";
import "../interfaces/IBentPoolManager.sol";
import "../interfaces/convex/IConvexBooster.sol";
import "../interfaces/convex/IBaseRewardPool.sol";
import "../interfaces/convex/IConvexToken.sol";
import "../interfaces/convex/IVirtualBalanceRewardPool.sol";
import "./BentBasePoolUpgradeable.sol";

contract BentBasePool is BentBasePoolUpgradeable {
    constructor(
        address _poolManager,
        string memory _name,
        uint256 _cvxPoolId,
        address[] memory _extraRewardTokens,
        uint256 _windowLength // around 7 days
    ) {
        initialize(
            _poolManager,
            _name,
            _cvxPoolId,
            _extraRewardTokens,
            _windowLength
        );
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Errors {
    string public constant ZERO_ADDRESS = "100";
    string public constant ZERO_AMOUNT = "101";
    string public constant INVALID_ADDRESS = "102";
    string public constant INVALID_AMOUNT = "103";
    string public constant NO_PENDING_REWARD = "104";
    string public constant INVALID_PID = "105";
    string public constant INVALID_POOL_ADDRESS = "106";
    string public constant UNAUTHORIZED = "107";
    string public constant ALREADY_EXISTS = "108";
    string public constant SAME_ALLOCPOINT = "109";
    string public constant INVALID_REWARD_PER_BLOCK = "110";
    string public constant INSUFFICIENT_REWARDS = "111";
    string public constant EXCEED_MAX_HARVESTER_FEE = "112";
    string public constant EXCEED_MAX_FEE = "113";
    string public constant INVALID_INDEX = "114";
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOwnable {
    function owner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBentPool {
    function lpToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBentPoolManager {
    function feeInfo()
        external
        view
        returns (
            uint256,
            address,
            uint256,
            address,
            uint256
        );

    function rewardToken() external view returns (address);

    function mint(address user, uint256 cvxAmount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IConvexBooster {
    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );

    function deposit(
        uint256,
        uint256,
        bool
    ) external returns (bool);

    function depositAll(uint256, bool) external returns (bool);

    function withdraw(uint256, uint256) external returns (bool);

    function withdrawAll(uint256) external returns (bool);

    function rewardClaimed(
        uint256,
        address,
        uint256
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IBaseRewardPool {
    function getReward(address, bool) external returns (bool);

    function getReward() external returns (bool);

    function earned(address) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function extraRewards(uint256) external view returns (address);

    function withdrawAndUnwrap(uint256, bool) external returns (bool);

    function extraRewardsLength() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IConvexToken is IERC20 {
    function reductionPerCliff() external view returns (uint256);

    function totalCliffs() external view returns (uint256);

    function maxSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IVirtualBalanceRewardPool {
    function getReward(address) external;

    function getReward() external;

    function balanceOf(address) external view returns (uint256);

    function earned(address) external view returns (uint256);

    function rewardToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../libraries/Errors.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IBentPool.sol";
import "../interfaces/IBentPoolManager.sol";
import "../interfaces/convex/IConvexBooster.sol";
import "../interfaces/convex/IBaseRewardPool.sol";
import "../interfaces/convex/IConvexToken.sol";
import "../interfaces/convex/IVirtualBalanceRewardPool.sol";
import "./BentBaseMasterchef.sol";

contract BentBasePoolUpgradeable is
    BentBaseMasterchef,
    ReentrancyGuardUpgradeable,
    IBentPool
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user);
    event UpdateVersion(uint256 _version);

    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant CONVEX_BOOSTER =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;

    address public bent;

    address public poolManager;
    address public override lpToken;
    uint256 public cvxPoolId;
    address public crvRewards;

    string public name;

    uint256 public windowLength;
    uint256 public endRewardBlock; // end block of rewards stream
    uint256 public lastRewardBlock; // last block of rewards streamed

    uint256 public version;

    function initialize(
        address _poolManager,
        string memory _name,
        uint256 _cvxPoolId,
        address[] memory _extraRewardTokens,
        uint256 _windowLength // around 7 days
    ) public initializer {
        __ReentrancyGuard_init();

        poolManager = _poolManager;
        cvxPoolId = _cvxPoolId;
        name = _name;

        bent = IBentPoolManager(poolManager).rewardToken();

        rewardPools[0].rewardToken = IERC20Upgradeable(CRV);
        rewardPools[1].rewardToken = IERC20Upgradeable(CVX);

        (lpToken, , , crvRewards, , ) = IConvexBooster(CONVEX_BOOSTER).poolInfo(
            _cvxPoolId
        );
        uint256 extraRewardsLength = _extraRewardTokens.length;
        for (uint256 i = 0; i < extraRewardsLength; i++) {
            rewardPools[i + 2].rewardToken = IERC20Upgradeable(
                _extraRewardTokens[i]
            );
        }
        rewardPoolsCount = 2 + extraRewardsLength;

        windowLength = _windowLength;

        // for new pools
        version = 2;
    }

    function pendingReward(address user)
        external
        view
        returns (uint256[] memory pending)
    {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        pending = new uint256[](_rewardPoolsCount + 1);

        uint256[] memory addedRewards = _calcAddedRewards();
        for (uint256 i = 0; i < _rewardPoolsCount; i++) {
            uint256 reward = super.pendingReward(i, user, addedRewards[i]);
            if (i == 1) {
                // calculate bent rewards amount based on CVX reward
                pending[0] = _getBentEarned(reward);
            }
            pending[i + 1] = reward;
        }
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount != 0, Errors.ZERO_AMOUNT);

        _updateAccPerShare(true);

        uint256 _before = IERC20(lpToken).balanceOf(address(this));
        IERC20Upgradeable(lpToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        uint256 _after = IERC20(lpToken).balanceOf(address(this));
        // Additional check for deflationary tokens
        _amount = _after - _before;

        _mint(msg.sender, _amount);

        // deposit to the convex booster
        IERC20Upgradeable(lpToken).safeApprove(CONVEX_BOOSTER, 0);
        IERC20Upgradeable(lpToken).safeApprove(CONVEX_BOOSTER, _amount);
        IConvexBooster(CONVEX_BOOSTER).deposit(cvxPoolId, _amount, true);

        _updateUserRewardDebt();

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(
            balanceOf[msg.sender] >= _amount && _amount != 0,
            Errors.INVALID_AMOUNT
        );

        _updateAccPerShare(true);

        _burn(msg.sender, _amount);

        // withdraw from the convex booster
        IBaseRewardPool(crvRewards).withdrawAndUnwrap(_amount, false);

        // transfer to msg.sender
        IERC20Upgradeable(lpToken).safeTransfer(msg.sender, _amount);

        _updateUserRewardDebt();

        emit Withdraw(msg.sender, _amount);
    }

    function harvest() external virtual nonReentrant {
        _updateAccPerShare(true);

        require(_harvest(), Errors.NO_PENDING_REWARD);

        _updateUserRewardDebt();

        emit Harvest(msg.sender);
    }

    function harvestFromConvex() external nonReentrant {
        _updateAccPerShare(false);

        uint256 i;
        uint256[] memory claimBalances = new uint256[](rewardPoolsCount);
        // save balances before claim
        for (i = 0; i < rewardPoolsCount; i++) {
            claimBalances[i] = rewardPools[i].rewardToken.balanceOf(
                address(this)
            );
        }

        IBaseRewardPool(crvRewards).getReward(address(this), true);

        (
            uint256 harvesterFee,
            address bentStaker,
            uint256 bentStakerFee,
            address cvxStaker,
            uint256 cvxStakerFee
        ) = IBentPoolManager(poolManager).feeInfo();

        require(
            harvesterFee + bentStakerFee + cvxStakerFee <= 1700,
            Errors.EXCEED_MAX_FEE
        ); // max 17% fee
        require(harvesterFee <= 100, Errors.EXCEED_MAX_HARVESTER_FEE); // max 1% fee

        for (i = 0; i < rewardPoolsCount; i++) {
            claimBalances[i] =
                rewardPools[i].rewardToken.balanceOf(address(this)) -
                claimBalances[i];

            uint256 remaining = claimBalances[i];
            if (claimBalances[i] > 0) {
                if (harvesterFee > 0) {
                    // harvesterFee to msg.sender
                    uint256 fee = (claimBalances[i] * harvesterFee) / 10000;
                    rewardPools[i].rewardToken.safeTransfer(msg.sender, fee);
                    remaining -= fee;
                }

                if (bentStakerFee > 0) {
                    // bentStakerFee to bentStaker
                    uint256 fee = (claimBalances[i] * bentStakerFee) / 10000;
                    rewardPools[i].rewardToken.safeTransfer(bentStaker, fee);
                    remaining -= fee;
                }

                if (cvxStakerFee > 0) {
                    // cvxStakerFee to cvxStaker
                    uint256 fee = (claimBalances[i] * cvxStakerFee) / 10000;
                    rewardPools[i].rewardToken.safeTransfer(cvxStaker, fee);
                    remaining -= fee;
                }
            }

            if (endRewardBlock > lastRewardBlock) {
                rewardPools[i].rewardRate =
                    (rewardPools[i].rewardRate *
                        (endRewardBlock - lastRewardBlock) +
                        remaining *
                        1e36) /
                    windowLength;
            } else {
                rewardPools[i].rewardRate = (remaining * 1e36) / windowLength;
            }
        }

        endRewardBlock = lastRewardBlock + windowLength;
    }

    // Internal Functions

    function _updateAccPerShare(bool withdrawReward) internal {
        uint256[] memory addedRewards = _calcAddedRewards();
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; i++) {
            super.updateAccPerShare(i, addedRewards[i]);
            if (withdrawReward) {
                super.withdrawReward(i, msg.sender);
            }
        }

        lastRewardBlock = block.number;
    }

    function _calcAddedRewards()
        internal
        view
        returns (uint256[] memory addedRewards)
    {
        uint256 startBlock = endRewardBlock > lastRewardBlock + windowLength
            ? endRewardBlock - windowLength
            : lastRewardBlock;
        uint256 endBlock = block.number > endRewardBlock
            ? endRewardBlock
            : block.number;
        uint256 duration = endBlock > startBlock ? endBlock - startBlock : 0;

        uint256 _rewardPoolsCount = rewardPoolsCount;
        addedRewards = new uint256[](_rewardPoolsCount);
        for (uint256 i = 0; i < _rewardPoolsCount; i++) {
            addedRewards[i] = (rewardPools[i].rewardRate * duration) / 1e36;
        }
    }

    function _updateUserRewardDebt() internal {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; i++) {
            super.updateUserRewardDebt(i, msg.sender);
        }
    }

    function _harvest() internal returns (bool harvested) {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; i++) {
            uint256 harvestAmount = super.harvest(i, msg.sender);
            if (harvestAmount > 0) {
                if (i == 1) {
                    // CVX
                    IBentPoolManager(poolManager).mint(
                        msg.sender,
                        harvestAmount
                    );
                }

                rewardPools[i].rewardToken.safeTransfer(
                    msg.sender,
                    harvestAmount
                );
                harvested = true;
            }
        }
    }

    function _mint(address _user, uint256 _amount) internal {
        balanceOf[_user] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _user, uint256 _amount) internal {
        balanceOf[_user] -= _amount;
        totalSupply -= _amount;
    }

    /**
     * @notice from bent token contract
     */
    function _getBentEarned(uint256 cvxEarned) internal view returns (uint256) {
        uint256 supply = IConvexToken(bent).totalSupply();
        if (supply == 0) {
            return cvxEarned;
        }
        uint256 totalCliffs = IConvexToken(bent).totalCliffs();
        uint256 cliff = supply / IConvexToken(bent).reductionPerCliff();

        if (cliff < totalCliffs) {
            uint256 reduction = totalCliffs - cliff;
            uint256 _amount = cvxEarned;

            _amount = ((_amount * reduction) * 20) / totalCliffs;

            //supply cap check
            uint256 amtTillMax = IConvexToken(bent).maxSupply() - supply;
            if (_amount > amtTillMax) {
                _amount = amtTillMax;
            }
            return _amount;
        }
        return 0;
    }

    function updateVersion(uint256 _version) external {
        require(
            msg.sender == IOwnable(poolManager).owner(),
            Errors.UNAUTHORIZED
        );
        version = _version;

        emit UpdateVersion(_version);
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

abstract contract BentBaseMasterchef {
    struct PoolData {
        IERC20Upgradeable rewardToken;
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e36. See below.
        uint256 rewardRate;
    }

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    uint256 public rewardPoolsCount;
    mapping(uint256 => PoolData) public rewardPools;
    mapping(uint256 => mapping(address => uint256)) internal userRewardDebt;
    mapping(uint256 => mapping(address => uint256)) internal userPendingRewards;

    function updateAccPerShare(uint256 pid, uint256 addedReward) internal {
        PoolData storage pool = rewardPools[pid];

        if (totalSupply == 0) {
            pool.accRewardPerShare = block.number;
            return;
        }

        if (addedReward > 0) {
            pool.accRewardPerShare += (addedReward * (1e36)) / totalSupply;
        }
    }

    function withdrawReward(uint256 pid, address user) internal {
        PoolData storage pool = rewardPools[pid];
        uint256 pending = ((balanceOf[user] * pool.accRewardPerShare) / 1e36) -
            userRewardDebt[pid][user];

        if (pending > 0) {
            userPendingRewards[pid][user] += pending;
        }
    }

    function harvest(uint256 pid, address user)
        internal
        returns (uint256 harvested)
    {
        harvested = userPendingRewards[pid][user];
        if (harvested > 0) {
            userPendingRewards[pid][user] = 0;
        }
    }

    function updateUserRewardDebt(uint256 pid, address user) internal {
        userRewardDebt[pid][user] =
            (balanceOf[user] * rewardPools[pid].accRewardPerShare) /
            1e36;
    }

    function pendingReward(
        uint256 pid,
        address user,
        uint256 addedReward
    ) internal view returns (uint256) {
        if (totalSupply == 0) return 0;

        uint256 newAccRewardPerShare = rewardPools[pid].accRewardPerShare +
            ((addedReward * 1e36) / totalSupply);

        return
            userPendingRewards[pid][user] +
            ((balanceOf[user] * newAccRewardPerShare) / 1e36) -
            userRewardDebt[pid][user];
    }
}