// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "./interfaces/IVestingPools.sol";
import "./interfaces/IRewardPool.sol";
import "./utils/ImmutableOwnable.sol";
import "./utils/Utils.sol";

/**
 * @title RewardPool
 * @notice It vests $ZKP token from the Panther Protocol "Reward Pool".
 * @dev One of the vesting pools (maybe, the major one) which the VestingPools
 * contract vests $ZKP tokens to is the "Reward Pool" (aka "Protocol Pool").
 * This contract assumed to have a "pool wallet" role with the VestingPools,
 * and therefore has a privilege to request vesting $ZKPs from the Reward Pool
 * to the "recipient".
 * The "RewardMaster" contract, that distributes tokens to users as rewards,
 * is assumed to be the "recipient".
 *
 * This contract is expected to be replaced. Therefore it allows the owner
 * to transfer the "pool wallet" role to another account.
 */
contract RewardPool is ImmutableOwnable, Utils, IRewardPool {
    /// @notice Address of the VestingPools instance
    address public immutable VESTING_POOLS;

    /// @notice ID of the pool (in the VestingPools) to vest from
    uint8 public poolId;

    /// @dev (UNIX) Time when vesting gets disabled
    uint32 public endTime;

    /// @notice Address to vest tokens to
    address public recipient;

    constructor(address _vestingPools, address _owner)
        ImmutableOwnable(_owner)
        nonZeroAddress(_vestingPools)
    {
        VESTING_POOLS = _vestingPools;
    }

    /// @inheritdoc IRewardPool
    function releasableAmount() external view override returns (uint256) {
        if (recipient == address(0)) return 0;
        if (timeNow() >= endTime) return 0;

        return _releasableAmount();
    }

    /// @inheritdoc IRewardPool
    function vestRewards() external override returns (uint256 amount) {
        // revert if unauthorized or recipient not yet set
        require(msg.sender == recipient, "RP: unauthorized");
        require(timeNow() < endTime, "RP: expired");

        amount = _releasableAmount();

        if (amount != 0) {
            IVestingPools(VESTING_POOLS).releaseTo(poolId, recipient, amount);
            emit Vested(amount);
        }
    }

    /// @notice Sets the {poolId} and the {recipient} to given values
    /// @dev Owner only may call, once only
    /// This contract address must be set in the VestingPools as the wallet for the pool
    function initialize(
        uint8 _poolId,
        address _recipient,
        uint32 _endTime
    ) external onlyOwner nonZeroAddress(_recipient) {
        // once only
        require(recipient == address(0), "RP: initialized");
        // _endTime can't be in the past
        require(_endTime > timeNow(), "RP: expired");
        // this contract must be registered with the VestingPools
        require(IVestingPools(VESTING_POOLS).getWallet(_poolId) == address(this), "RP:E7");

        poolId = _poolId;
        recipient = _recipient;
        endTime = _endTime;

        emit Initialized(_poolId, _recipient, _endTime);
    }

    /// @notice Calls VestingPools to transfer 'pool wallet' role to given address
    /// @dev Owner only may call, once only
    function transferPoolWalletRole(address newWallet)
        external
        onlyOwner
        nonZeroAddress(newWallet)
    {
        IVestingPools(VESTING_POOLS).updatePoolWallet(poolId, newWallet);
    }

    function _releasableAmount() internal view returns (uint256) {
        return IVestingPools(VESTING_POOLS).releasableAmount(poolId);
    }

    modifier nonZeroAddress(address account) {
        require(account != address(0), "RP: zero address");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVestingPools {
    /**
     * @notice Returns Token address.
     */
    function token() external view returns (address);

    /**
     * @notice Returns the wallet address of the specified pool.
     */
    function getWallet(uint256 poolId) external view returns (address);

    /**
     * @notice Returns the amount that may be vested now from the given pool.
     */
    function releasableAmount(uint256 poolId) external view returns (uint256);

    /**
     * @notice Returns the amount that has been vested from the given pool
     */
    function vestedAmount(uint256 poolId) external view returns (uint256);

    /**
     * @notice Vests the specified amount from the given pool to the pool wallet.
     * If the amount is zero, it vests the entire "releasable" amount.
     * @dev Pool wallet may call only.
     * @return released - Amount released.
     */
    function release(uint256 poolId, uint256 amount)
        external
        returns (uint256 released);

    /**
     * @notice Vests the specified amount from the given pool to the given address.
     * If the amount is zero, it vests the entire "releasable" amount.
     * @dev Pool wallet may call only.
     * @return released - Amount released.
     */
    function releaseTo(
        uint256 poolId,
        address account,
        uint256 amount
    ) external returns (uint256 released);

    /**
     * @notice Updates the wallet for the given pool.
     * @dev Only address with the 'wallet' role may call.
     */
    function updatePoolWallet(uint256 poolId, address newWallet) external;

    /// @notice Emitted on an amount vesting.
    event Released(uint256 indexed poolId, address to, uint256 amount);
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.0;

interface IRewardPool {
    /// @notice Returns token amount that may be released (vested) now
    function releasableAmount() external view returns (uint256);

    /// @notice Vests releasable token amount to the {recipient}
    /// @dev {recipient} only may call
    function vestRewards() external returns (uint256 amount);

    /// @notice Emitted on vesting to the {recipient}
    event Vested(uint256 amount);

    /// @notice Emitted on parameters initialized.
    event Initialized(uint256 _poolId, address _recipient, uint256 _endTime);
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

/// @title Staking
abstract contract ImmutableOwnable {
    /// @notice The owner who has privileged rights
    address public immutable OWNER;

    /// @dev Throws if called by any account other than the {OWNER}.
    modifier onlyOwner() {
        require(OWNER == msg.sender, "ImmOwn: unauthorized");
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "ImmOwn: zero owner address");
        OWNER = _owner;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

abstract contract Utils {
    function safe32(uint256 n) internal pure returns (uint32) {
        require(n < 2**32, "UNSAFE32");
        return uint32(n);
    }

    function safe96(uint256 n) internal pure returns (uint96) {
        require(n < 2**96, "UNSAFE96");
        return uint96(n);
    }

    function safe128(uint256 n) internal pure returns (uint128) {
        require(n < 2**128, "UNSAFE128");
        return uint128(n);
    }

    function safe160(uint256 n) internal pure returns (uint160) {
        require(n < 2**160, "UNSAFE160");
        return uint160(n);
    }

    function safe32TimeNow() internal view returns (uint32) {
        return safe32(timeNow());
    }

    function safe32BlockNow() internal view returns (uint32) {
        return safe32(blockNow());
    }

    /// @dev Returns the current block timestamp (added to ease testing)
    function timeNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @dev Returns the current block number (added to ease testing)
    function blockNow() internal view virtual returns (uint256) {
        return block.number;
    }
}