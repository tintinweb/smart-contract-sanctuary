/*
ERC20BaseRewardModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IRewardModule.sol";

/**
 * @title ERC20 base reward module
 *
 * @notice this abstract class implements common ERC20 funding and unlocking
 * logic, which is inherited by other reward modules.
 */
abstract contract ERC20BaseRewardModule is IRewardModule {
    using SafeERC20 for IERC20;

    // single funding/reward schedule
    struct Funding {
        uint256 amount;
        uint256 shares;
        uint256 locked;
        uint256 updated;
        uint256 start;
        uint256 duration;
    }

    // constants
    uint256 public constant INITIAL_SHARES_PER_TOKEN = 10**6;
    uint256 public constant MAX_ACTIVE_FUNDINGS = 16;

    // funding/reward state fields
    mapping(address => Funding[]) private _fundings;
    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _locked;

    /**
     * @notice getter for total token shares
     */
    function totalShares(address token) public view returns (uint256) {
        return _shares[token];
    }

    /**
     * @notice getter for total locked token shares
     */
    function lockedShares(address token) public view returns (uint256) {
        return _locked[token];
    }

    /**
     * @notice getter for funding schedule struct
     */
    function fundings(address token, uint256 index)
        public
        view
        returns (
            uint256 amount,
            uint256 shares,
            uint256 locked,
            uint256 updated,
            uint256 start,
            uint256 duration
        )
    {
        Funding storage f = _fundings[token][index];
        return (f.amount, f.shares, f.locked, f.updated, f.start, f.duration);
    }

    /**
     * @param token contract address of reward token
     * @return number of active funding schedules
     */
    function fundingCount(address token) public view returns (uint256) {
        return _fundings[token].length;
    }

    /**
     * @notice compute number of unlockable shares for a specific funding schedule
     * @param token contract address of reward token
     * @param idx index of the funding
     * @return the number of unlockable shares
     */
    function unlockable(address token, uint256 idx)
        public
        view
        returns (uint256)
    {
        Funding storage funding = _fundings[token][idx];

        // funding schedule is in future
        if (block.timestamp < funding.start) {
            return 0;
        }
        // empty
        if (funding.locked == 0) {
            return 0;
        }
        // handle zero-duration period or leftover dust from integer division
        if (block.timestamp >= funding.start + funding.duration) {
            return funding.locked;
        }

        return
            ((block.timestamp - funding.updated) * funding.shares) /
            funding.duration;
    }

    /**
     * @notice fund pool by locking up reward tokens for future distribution
     * @param token contract address of reward token
     * @param amount number of reward tokens to lock up as funding
     * @param duration period (seconds) over which funding will be unlocked
     * @param start time (seconds) at which funding begins to unlock
     */
    function _fund(
        address token,
        uint256 amount,
        uint256 duration,
        uint256 start
    ) internal {
        requireController();
        // validate
        require(amount > 0, "rm1");
        require(start >= block.timestamp, "rm2");
        require(_fundings[token].length < MAX_ACTIVE_FUNDINGS, "rm3");

        IERC20 rewardToken = IERC20(token);

        // do transfer of funding
        uint256 total = rewardToken.balanceOf(address(this));
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 actual = rewardToken.balanceOf(address(this)) - total;

        // mint shares at current rate
        uint256 minted =
            (total > 0)
                ? (_shares[token] * actual) / total
                : actual * INITIAL_SHARES_PER_TOKEN;

        _locked[token] += minted;
        _shares[token] += minted;

        // create new funding
        _fundings[token].push(
            Funding({
                amount: amount,
                shares: minted,
                locked: minted,
                updated: start,
                start: start,
                duration: duration
            })
        );

        emit RewardsFunded(token, amount, minted, start);
    }

    /**
     * @dev internal function to clean up stale funding schedules
     * @param token contract address of reward token to clean up
     */
    function _clean(address token) internal {
        // check for stale funding schedules to expire
        uint256 removed = 0;
        uint256 originalSize = _fundings[token].length;
        for (uint256 i = 0; i < originalSize; i++) {
            Funding storage funding = _fundings[token][i - removed];
            uint256 idx = i - removed;

            if (
                unlockable(token, idx) == 0 &&
                block.timestamp >= funding.start + funding.duration
            ) {
                emit RewardsExpired(
                    token,
                    funding.amount,
                    funding.shares,
                    funding.start
                );

                // remove at idx by copying last element here, then popping off last
                // (we don't care about order)
                _fundings[token][idx] = _fundings[token][
                    _fundings[token].length - 1
                ];
                _fundings[token].pop();
                removed++;
            }
        }
    }

    /**
     * @dev unlocks reward tokens based on funding schedules
     * @param token contract addres of reward token
     * @return shares number of shares unlocked
     */
    function _unlockTokens(address token) internal returns (uint256 shares) {
        // get unlockable shares for each funding schedule
        for (uint256 i = 0; i < _fundings[token].length; i++) {
            uint256 s = unlockable(token, i);
            Funding storage funding = _fundings[token][i];
            if (s > 0) {
                funding.locked -= s;
                funding.updated = block.timestamp;
                shares += s;
            }
        }

        // do unlocking
        if (shares > 0) {
            _locked[token] -= shares;
            emit RewardsUnlocked(token, shares);
        }
    }

    /**
     * @dev distribute reward tokens to user
     * @param user address of user receiving rweard
     * @param token contract address of reward token
     * @param shares number of shares to be distributed
     * @return amount number of reward tokens distributed
     */
    function _distribute(
        address user,
        address token,
        uint256 shares
    ) internal returns (uint256 amount) {
        // compute reward amount in tokens
        IERC20 rewardToken = IERC20(token);
        amount =
            (rewardToken.balanceOf(address(this)) * shares) /
            _shares[token];

        // update overall reward shares
        _shares[token] -= shares;

        // do reward
        rewardToken.safeTransfer(user, amount);
        emit RewardsDistributed(user, token, amount, shares);
    }
}

/*
ERC20CompetitiveRewardModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "./interfaces/IRewardModule.sol";
import "./ERC20BaseRewardModule.sol";
import "./GysrUtils.sol";

/**
 * @title ERC20 competitive reward module
 *
 * @notice this reward module distributes a single ERC20 token as the staking reward.
 * It is designed to offer competitive and engaging reward mechanics.
 *
 * @dev share seconds are the primary unit of accounting in this module. They
 * are accrued over time and burned during reward distribution. Users can
 * earn a time multiplier as an incentive for longer term staking. They can
 * also receive a GYSR multiplier by spending GYSR at the time of unstaking.
 *
 * h/t https://github.com/ampleforth/token-geyser
 */
contract ERC20CompetitiveRewardModule is ERC20BaseRewardModule {
    using SafeERC20 for IERC20;
    using GysrUtils for uint256;

    // single stake by user
    struct Stake {
        uint256 shares;
        uint256 timestamp;
    }

    mapping(address => Stake[]) public stakes;

    // configuration fields
    uint256 public immutable bonusMin;
    uint256 public immutable bonusMax;
    uint256 public immutable bonusPeriod;
    IERC20 private immutable _token;
    address private immutable _factory;

    // global state fields
    uint256 public totalStakingShares;
    uint256 public totalStakingShareSeconds;
    uint256 public lastUpdated;
    uint256 private _usage;

    /**
     * @param token_ the token that will be rewarded
     * @param bonusMin_ initial time bonus
     * @param bonusMax_ maximum time bonus
     * @param bonusPeriod_ period (in seconds) over which time bonus grows to max
     * @param factory_ address of module factory
     */
    constructor(
        address token_,
        uint256 bonusMin_,
        uint256 bonusMax_,
        uint256 bonusPeriod_,
        address factory_
    ) {
        require(bonusMin_ <= bonusMax_, "crm1");

        _token = IERC20(token_);
        _factory = factory_;

        bonusMin = bonusMin_;
        bonusMax = bonusMax_;
        bonusPeriod = bonusPeriod_;

        lastUpdated = block.timestamp;
    }

    // -- IRewardModule -------------------------------------------------------

    /**
     * @inheritdoc IRewardModule
     */
    function tokens()
        external
        view
        override
        returns (address[] memory tokens_)
    {
        tokens_ = new address[](1);
        tokens_[0] = address(_token);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function balances()
        external
        view
        override
        returns (uint256[] memory balances_)
    {
        balances_ = new uint256[](1);
        balances_[0] = totalLocked();
    }

    /**
     * @inheritdoc IRewardModule
     */
    function usage() external view override returns (uint256) {
        return _usage;
    }

    /**
     * @inheritdoc IRewardModule
     */
    function factory() external view override returns (address) {
        return _factory;
    }

    /**
     * @inheritdoc IRewardModule
     */
    function stake(
        address account,
        address,
        uint256 shares,
        bytes calldata
    ) external override onlyOwner returns (uint256, uint256) {
        _update();
        _stake(account, shares);
        return (0, 0);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function unstake(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) external override onlyOwner returns (uint256, uint256) {
        _update();
        return _unstake(account, user, shares, data);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function claim(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) external override onlyOwner returns (uint256 spent, uint256 vested) {
        _update();
        (spent, vested) = _unstake(account, user, shares, data);
        _stake(account, shares);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function update(address) external override {
        requireOwner();
        _update();
    }

    /**
     * @inheritdoc IRewardModule
     */
    function clean() external override {
        requireOwner();
        _update();
        _clean(address(_token));
    }

    // -- ERC20CompetitiveRewardModule ----------------------------------------

    /**
     * @notice fund module by locking up reward tokens for distribution
     * @param amount number of reward tokens to lock up as funding
     * @param duration period (seconds) over which funding will be unlocked
     */
    function fund(uint256 amount, uint256 duration) external {
        _update();
        _fund(address(_token), amount, duration, block.timestamp);
    }

    /**
     * @notice fund module by locking up reward tokens for distribution
     * @param amount number of reward tokens to lock up as funding
     * @param duration period (seconds) over which funding will be unlocked
     * @param start time (seconds) at which funding begins to unlock
     */
    function fund(
        uint256 amount,
        uint256 duration,
        uint256 start
    ) external {
        _update();
        _fund(address(_token), amount, duration, start);
    }

    /**
     * @notice compute time bonus earned as a function of staking time
     * @param time length of time for which the tokens have been staked
     * @return bonus multiplier for time
     */
    function timeBonus(uint256 time) public view returns (uint256) {
        if (time >= bonusPeriod) {
            return 10**DECIMALS + bonusMax;
        }

        // linearly interpolate between bonus min and bonus max
        uint256 bonus = bonusMin + ((bonusMax - bonusMin) * time) / bonusPeriod;
        return 10**DECIMALS + bonus;
    }

    /**
     * @return total number of locked reward tokens
     */
    function totalLocked() public view returns (uint256) {
        if (lockedShares(address(_token)) == 0) {
            return 0;
        }
        return
            (_token.balanceOf(address(this)) * lockedShares(address(_token))) /
            totalShares(address(_token));
    }

    /**
     * @return total number of unlocked reward tokens
     */
    function totalUnlocked() public view returns (uint256) {
        uint256 unlockedShares =
            totalShares(address(_token)) - lockedShares(address(_token));

        if (unlockedShares == 0) {
            return 0;
        }
        return
            (_token.balanceOf(address(this)) * unlockedShares) /
            totalShares(address(_token));
    }

    /**
     * @param addr address of interest
     * @return number of active stakes for user
     */
    function stakeCount(address addr) public view returns (uint256) {
        return stakes[addr].length;
    }

    // -- ERC20CompetitiveRewardModule internal -------------------------------

    /**
     * @dev internal implementation of stake method
     * @param account address of staking account
     * @param shares number of shares burned
     */
    function _stake(address account, uint256 shares) private {
        // update user staking info
        stakes[account].push(Stake(shares, block.timestamp));

        // add newly minted shares to global total
        totalStakingShares += shares;
    }

    /**
     * @dev internal implementation of unstake method
     * @param account address of staking account
     * @param user address of user
     * @param shares number of shares burned
     * @param data additional data
     * @return spent amount of gysr spent
     * @return vested amount of gysr vested
     */
    function _unstake(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) private returns (uint256 spent, uint256 vested) {
        // validate
        // note: we assume shares has been validated upstream
        require(data.length == 0 || data.length == 32, "crm2");

        // parse GYSR amount from data
        if (data.length == 32) {
            assembly {
                spent := calldataload(164)
            }
        }

        uint256 bonus = spent.gysrBonus(shares, totalStakingShares, _usage);

        // do unstaking, first-in last-out, respecting time bonus
        uint256 shareSeconds;
        uint256 timeWeightedShareSeconds;
        (shareSeconds, timeWeightedShareSeconds) = _unstakeFirstInLastOut(
            account,
            shares
        );

        // compute and apply GYSR token bonus
        uint256 gysrWeightedShareSeconds =
            (bonus * timeWeightedShareSeconds) / 10**DECIMALS;

        // get reward in shares
        uint256 unlockedShares =
            totalShares(address(_token)) - lockedShares(address(_token));

        uint256 rewardShares =
            (unlockedShares * gysrWeightedShareSeconds) /
                (totalStakingShareSeconds + gysrWeightedShareSeconds);

        // reward
        if (rewardShares > 0) {
            _distribute(user, address(_token), rewardShares);

            // update usage
            uint256 ratio;
            if (spent > 0) {
                vested = spent;
                emit GysrSpent(user, spent);
                emit GysrVested(user, vested);
                ratio = ((bonus - 10**DECIMALS) * 10**DECIMALS) / bonus;
            }
            uint256 weight =
                (shareSeconds * 10**DECIMALS) /
                    (totalStakingShareSeconds + shareSeconds);
            _usage =
                _usage -
                (weight * _usage) /
                10**DECIMALS +
                (weight * ratio) /
                10**DECIMALS;
        }
    }

    /**
     * @dev internal implementation of update method to
     * unlock tokens and do global accounting
     */
    function _update() private {
        _unlockTokens(address(_token));

        // global accounting
        totalStakingShareSeconds +=
            (block.timestamp - lastUpdated) *
            totalStakingShares;
        lastUpdated = block.timestamp;
    }

    /**
     * @dev helper function to actually execute unstaking, first-in last-out, 
     while computing and applying time bonus. This function also updates
     user and global totals for shares and share-seconds.
     * @param user address of user
     * @param shares number of staking shares to burn
     * @return rawShareSeconds raw share seconds burned
     * @return bonusShareSeconds time bonus weighted share seconds
     */
    function _unstakeFirstInLastOut(address user, uint256 shares)
        private
        returns (uint256 rawShareSeconds, uint256 bonusShareSeconds)
    {
        // redeem first-in-last-out
        uint256 sharesLeftToBurn = shares;
        Stake[] storage userStakes = stakes[user];
        while (sharesLeftToBurn > 0) {
            Stake storage lastStake = userStakes[userStakes.length - 1];
            uint256 stakeTime = block.timestamp - lastStake.timestamp;

            uint256 bonus = timeBonus(stakeTime);

            if (lastStake.shares <= sharesLeftToBurn) {
                // fully redeem a past stake
                bonusShareSeconds +=
                    (lastStake.shares * stakeTime * bonus) /
                    10**DECIMALS;
                rawShareSeconds += lastStake.shares * stakeTime;
                sharesLeftToBurn -= lastStake.shares;
                userStakes.pop();
            } else {
                // partially redeem a past stake
                bonusShareSeconds +=
                    (sharesLeftToBurn * stakeTime * bonus) /
                    10**DECIMALS;
                rawShareSeconds += sharesLeftToBurn * stakeTime;
                lastStake.shares -= sharesLeftToBurn;
                sharesLeftToBurn = 0;
            }
        }

        // update global totals
        totalStakingShareSeconds -= rawShareSeconds;
        totalStakingShares -= shares;
    }
}

/*
GYSRUtils

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "./MathUtils.sol";

/**
 * @title GYSR utilities
 *
 * @notice this library implements utility methods for the GYSR multiplier
 * and spending mechanics
 */
library GysrUtils {
    using MathUtils for int128;

    // constants
    uint256 public constant DECIMALS = 18;
    uint256 public constant GYSR_PROPORTION = 10**(DECIMALS - 2); // 1%

    /**
     * @notice compute GYSR bonus as a function of usage ratio, stake amount,
     * and GYSR spent
     * @param gysr number of GYSR token applied to bonus
     * @param amount number of tokens or shares to unstake
     * @param total number of tokens or shares in overall pool
     * @param ratio usage ratio from 0 to 1
     * @return multiplier value
     */
    function gysrBonus(
        uint256 gysr,
        uint256 amount,
        uint256 total,
        uint256 ratio
    ) internal pure returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        if (total == 0) {
            return 0;
        }
        if (gysr == 0) {
            return 10**DECIMALS;
        }

        // scale GYSR amount with respect to proportion
        uint256 portion = (GYSR_PROPORTION * total) / 10**DECIMALS;
        if (amount > portion) {
            gysr = (gysr * portion) / amount;
        }

        // 1 + gysr / (0.01 + ratio)
        uint256 x = 2**64 + (2**64 * gysr) / (10**(DECIMALS - 2) + ratio);

        return
            10**DECIMALS +
            (uint256(int256(int128(uint128(x)).logbase10())) * 10**DECIMALS) /
            2**64;
    }
}

/*
MathUtils

https://github.com/gysr-io/core

SPDX-License-Identifier: BSD-4-Clause
*/

pragma solidity 0.8.4;

/**
 * @title Math utilities
 *
 * @notice this library implements various logarithmic math utilies which support
 * other contracts and specifically the GYSR multiplier calculation
 *
 * @dev h/t https://github.com/abdk-consulting/abdk-libraries-solidity
 */
library MathUtils {
    /**
     * @notice calculate binary logarithm of x
     *
     * @param x signed 64.64-bit fixed point number, require x > 0
     * @return signed 64.64-bit fixed point number
     */
    function logbase2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    /**
     * @notice calculate natural logarithm of x
     * @dev magic constant comes from ln(2) * 2^128 -> hex
     * @param x signed 64.64-bit fixed point number, require x > 0
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return
                int128(
                    int256(
                        (uint256(int256(logbase2(x))) *
                            0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128
                    )
                );
        }
    }

    /**
     * @notice calculate logarithm base 10 of x
     * @dev magic constant comes from log10(2) * 2^128 -> hex
     * @param x signed 64.64-bit fixed point number, require x > 0
     * @return signed 64.64-bit fixed point number
     */
    function logbase10(int128 x) internal pure returns (int128) {
        require(x > 0);

        return
            int128(
                int256(
                    (uint256(int256(logbase2(x))) *
                        0x4d104d427de7fce20a6e420e02236748) >> 128
                )
            );
    }

    // wrapper functions to allow testing
    function testlogbase2(int128 x) public pure returns (int128) {
        return logbase2(x);
    }

    function testlogbase10(int128 x) public pure returns (int128) {
        return logbase10(x);
    }
}

/*
OwnerController

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

/**
 * @title Owner controller
 *
 * @notice this base contract implements an owner-controller access model.
 *
 * @dev the contract is an adapted version of the OpenZeppelin Ownable contract.
 * It allows the owner to designate an additional account as the controller to
 * perform restricted operations.
 *
 * Other changes include supporting role verification with a require method
 * in addition to the modifier option, and removing some unneeded functionality.
 *
 * Original contract here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
contract OwnerController {
    address private _owner;
    address private _controller;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event ControlTransferred(
        address indexed previousController,
        address indexed newController
    );

    constructor() {
        _owner = msg.sender;
        _controller = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        emit ControlTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() public view returns (address) {
        return _controller;
    }

    /**
     * @dev Modifier that throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "oc1");
        _;
    }

    /**
     * @dev Modifier that throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(_controller == msg.sender, "oc2");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function requireOwner() internal view {
        require(_owner == msg.sender, "oc1");
    }

    /**
     * @dev Throws if called by any account other than the controller.
     */
    function requireController() internal view {
        require(_controller == msg.sender, "oc2");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`). This can
     * include renouncing ownership by transferring to the zero address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        requireOwner();
        require(newOwner != address(0), "oc3");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the owner.
     */
    function transferControl(address newController) public virtual {
        requireOwner();
        require(newController != address(0), "oc4");
        emit ControlTransferred(_controller, newController);
        _controller = newController;
    }
}

/*
ERC20CompetitiveRewardModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IRewardModule.sol";
import "../ERC20CompetitiveRewardModule.sol";
import "../GysrUtils.sol";

/**
 * @title ERC20 competitive reward module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC20CompetitiveRewardModule contract.
 */
library ERC20CompetitiveRewardModuleInfo {
    using GysrUtils for uint256;

    /**
     * @notice convenience function to get token metadata in a single call
     * @param module address of reward module
     * @return address
     * @return name
     * @return symbol
     * @return decimals
     */
    function token(address module)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint8
        )
    {
        IRewardModule m = IRewardModule(module);
        IERC20Metadata tkn = IERC20Metadata(m.tokens()[0]);
        return (address(tkn), tkn.name(), tkn.symbol(), tkn.decimals());
    }

    /**
     * @notice preview estimated rewards
     * @param module address of reward module
     * @param addr account address of interest for preview
     * @param shares number of shares that would be unstaked
     * @param gysr number of GYSR tokens that would be applied
     * @return estimated reward
     * @return estimated time multiplier
     * @return estimated gysr multiplier
     */
    function rewards(
        address module,
        address addr,
        uint256 shares,
        uint256 gysr
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        ERC20CompetitiveRewardModule m = ERC20CompetitiveRewardModule(module);

        // get associated share seconds
        uint256 rawShareSeconds;
        uint256 bonusShareSeconds;
        (rawShareSeconds, bonusShareSeconds) = userShareSeconds(
            module,
            addr,
            shares
        );
        if (rawShareSeconds == 0) {
            return (0, 0, 0);
        }

        uint256 timeBonus = (bonusShareSeconds * 1e18) / rawShareSeconds;

        // apply gysr bonus
        uint256 gysrBonus =
            gysr.gysrBonus(shares, m.totalStakingShares(), m.usage());
        bonusShareSeconds = (gysrBonus * bonusShareSeconds) / 1e18;

        // compute rewards based on expected updates
        uint256 reward =
            (unlocked(module) * bonusShareSeconds) /
                (totalShareSeconds(module) +
                    bonusShareSeconds -
                    rawShareSeconds);

        return (reward, timeBonus, gysrBonus);
    }

    /**
     * @notice compute effective unlocked rewards
     * @param module address of reward module
     * @return estimated current unlocked rewards
     */
    function unlocked(address module) public view returns (uint256) {
        ERC20CompetitiveRewardModule m = ERC20CompetitiveRewardModule(module);

        // compute expected updates to global totals
        uint256 deltaUnlocked;
        address tkn = m.tokens()[0];
        uint256 totalLockedShares = m.lockedShares(tkn);
        if (totalLockedShares != 0) {
            uint256 sharesToUnlock;
            for (uint256 i = 0; i < m.fundingCount(tkn); i++) {
                sharesToUnlock = sharesToUnlock + m.unlockable(tkn, i);
            }
            deltaUnlocked =
                (sharesToUnlock * m.totalLocked()) /
                totalLockedShares;
        }
        return m.totalUnlocked() + deltaUnlocked;
    }

    /**
     * @notice compute user share seconds for given number of shares
     * @param module module contract address
     * @param addr user address
     * @param shares number of shares
     * @return raw share seconds
     * @return time bonus share seconds
     */
    function userShareSeconds(
        address module,
        address addr,
        uint256 shares
    ) public view returns (uint256, uint256) {
        require(shares > 0, "crmi1");

        ERC20CompetitiveRewardModule m = ERC20CompetitiveRewardModule(module);

        uint256 rawShareSeconds;
        uint256 timeBonusShareSeconds;

        // compute first-in-last-out, time bonus weighted, share seconds
        uint256 i = m.stakeCount(addr);
        while (shares > 0) {
            require(i > 0, "crmi2");
            i -= 1;
            uint256 s;
            uint256 time;
            (s, time) = m.stakes(addr, i);
            time = block.timestamp - time;

            // only redeem partial stake if more shares left than needed to burn
            s = s < shares ? s : shares;

            rawShareSeconds += (s * time);
            timeBonusShareSeconds += ((s * time * m.timeBonus(time)) / 1e18);
            shares -= s;
        }
        return (rawShareSeconds, timeBonusShareSeconds);
    }

    /**
     * @notice compute total expected share seconds for a rewards module
     * @param module address for reward module
     * @return expected total shares seconds
     */
    function totalShareSeconds(address module) public view returns (uint256) {
        ERC20CompetitiveRewardModule m = ERC20CompetitiveRewardModule(module);

        return
            m.totalStakingShareSeconds() +
            (block.timestamp - m.lastUpdated()) *
            m.totalStakingShares();
    }
}

/*
IEvents

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.4;

/**
 * @title GYSR event system
 *
 * @notice common interface to define GYSR event system
 */
interface IEvents {
    // staking
    event Staked(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Unstaked(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Claimed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );

    // rewards
    event RewardsDistributed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event RewardsFunded(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsUnlocked(address indexed token, uint256 shares);
    event RewardsExpired(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    // gysr
    event GysrSpent(address indexed user, uint256 amount);
    event GysrVested(address indexed user, uint256 amount);
    event GysrWithdrawn(uint256 amount);
}

/*
IRewardModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEvents.sol";

import "../OwnerController.sol";

/**
 * @title Reward module interface
 *
 * @notice this contract defines the common interface that any reward module
 * must implement to be compatible with the modular Pool architecture.
 */
abstract contract IRewardModule is OwnerController, IEvents {
    // constants
    uint256 public constant DECIMALS = 18;

    /**
     * @return array of reward tokens
     */
    function tokens() external view virtual returns (address[] memory);

    /**
     * @return array of reward token balances
     */
    function balances() external view virtual returns (uint256[] memory);

    /**
     * @return GYSR usage ratio for reward module
     */
    function usage() external view virtual returns (uint256);

    /**
     * @return address of module factory
     */
    function factory() external view virtual returns (address);

    /**
     * @notice perform any necessary accounting for new stake
     * @param account address of staking account
     * @param user address of user
     * @param shares number of new shares minted
     * @param data addtional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function stake(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) external virtual returns (uint256, uint256);

    /**
     * @notice reward user and perform any necessary accounting for unstake
     * @param account address of staking account
     * @param user address of user
     * @param shares number of shares burned
     * @param data additional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function unstake(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) external virtual returns (uint256, uint256);

    /**
     * @notice reward user and perform and necessary accounting for existing stake
     * @param account address of staking account
     * @param user address of user
     * @param shares number of shares being claimed against
     * @param data addtional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function claim(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) external virtual returns (uint256, uint256);

    /**
     * @notice method called by anyone to update accounting
     * @param user address of user for update
     * @dev will only be called ad hoc and should not contain essential logic
     */
    function update(address user) external virtual;

    /**
     * @notice method called by owner to clean up and perform additional accounting
     * @dev will only be called ad hoc and should not contain any essential logic
     */
    function clean() external virtual;
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 10000
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}