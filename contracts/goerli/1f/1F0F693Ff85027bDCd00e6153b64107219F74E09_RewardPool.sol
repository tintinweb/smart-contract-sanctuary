// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IVestingPools.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/IRootChainManager.sol";
import { DefaultOwnerAddress, TokenAddress, VestingPoolsAddress, PrivacyStakingAddress, RootChainManagerAddress } from "./utils/Linking.sol";
import "./utils/DefaultOwnable.sol";
import "./utils/SafeUints.sol";

/**
 * @title RewardPool
 * @notice It mints and vests a (mintable) ERC-20 token to "Vesting Pools".
 * @dev One of the vesting pools (may be the major one) which the Vesting
 * contract vests $ZKP tokens to is the "Reward Pool".
 * Tokens from the Reward Pool shall be distributed to users as privacy staking rewards.
 */
contract RewardPool is DefaultOwnable, IRewardPool {
    // ID of vesting pool of RewardPool
    uint256 public poolId;

    /// @notice Calls {release} and sends the releasable amount to the polygon root chain manager
    /// @dev Stakeholder only may call
    function vestRewards() external override returns (bool) {
        uint256 amount = IVestingPools(_getVestingPools()).releasableAmount(
            poolId
        );

        if (amount != 0) {
            _getVestingPools().release(poolId, amount);

            // if allowance amount is less than deposit amount, approve it to increase allowance
            if (
                _getToken().allowance(
                    address(this),
                    address(_getRootChainManager())
                ) < amount
            ) {
                _getToken().approve(
                    address(_getRootChainManager()),
                    2**256 - 1
                );
            }

            _getRootChainManager().depositFor(
                address(PrivacyStakingAddress),
                address(_getToken()),
                abi.encodePacked(amount)
            );
            return true;
        }

        return false;
    }

    // @notice Returns address of the {VestingPool} smart contract
    function vestingPools() external view override returns (address) {
        return address(_getVestingPools());
    }

    // @notice Returns address of RootChainManager smart contract
    function rootChainManager() external view override returns (address) {
        return address(_getRootChainManager());
    }

    /// @inheritdoc IRewardPool
    function token() external view override returns (address) {
        return address(_getToken());
    }

    function updatePoolId(uint256 _poolId) external onlyOwner {
        poolId = _poolId;
    }

    //////////////////
    //// Internal ////
    //////////////////

    /// @dev Returns the address of the default owner
    // (declared `view` rather than `pure` to facilitate testing)
    function _defaultOwner() internal view virtual override returns (address) {
        return address(DefaultOwnerAddress);
    }

    /// @dev Returns RootChainManager contract address
    // (declared `view` rather than `pure` to facilitate testing)
    function _getRootChainManager()
        internal
        view
        virtual
        returns (IRootChainManager)
    {
        return IRootChainManager(address(RootChainManagerAddress));
    }

    /// @dev Returns Token contract address
    // (declared `view` rather than `pure` to facilitate testing)
    function _getToken() internal view virtual returns (IERC20) {
        return IERC20(address(TokenAddress));
    }

    /// @dev Returns VestingPools contract address
    // (declared `view` rather than `pure` to facilitate testing)
    function _getVestingPools() internal view virtual returns (IVestingPools) {
        return IVestingPools(address(VestingPoolsAddress));
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

import { PoolParams } from "./Types.sol";

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
     * @notice Returns parameters of the specified pool.
     */
    function getPool(uint256 poolId) external view returns (PoolParams memory);

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
     * @dev (Current) wallet may call only.
     */
    function updatePoolWallet(uint256 poolId, address newWallet) external;

    /**
     * @notice Adds new vesting pools with given wallets and parameters.
     * @dev Owner may call only.
     */
    function addVestingPools(
        address[] memory wallets,
        PoolParams[] memory params
    ) external;

    /**
     * @notice Update `start` and `duration` for the given pool.
     * @param start - new (UNIX) time vesting starts at
     * @param vestingDays - new period in days, when vesting lasts
     * @dev Owner may call only.
     */
    function updatePoolTime(
        uint256 poolId,
        uint32 start,
        uint16 vestingDays
    ) external;

    /// @notice Emitted on an amount vesting.
    event Released(uint256 indexed poolId, address to, uint256 amount);

    /// @notice Emitted on a pool wallet update.
    event WalletUpdated(uint256 indexedpoolId, address indexed newWallet);

    /// @notice Emitted on a new pool added.
    event PoolAdded(
        uint256 indexed poolId,
        address indexed wallet,
        uint256 allocation
    );

    /// @notice Emitted on a pool params update.
    event PoolUpdated(
        uint256 indexed poolId,
        uint256 start,
        uint256 vestingDays
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardPool {
    /**
     * @notice Returns Token address.
     */
    function token() external view returns (address);

    /**
     * @notice Returns VestingPools contract address.
     */
    function vestingPools() external view returns (address);

    /**
     * @notice Returns RootChainManager contract address.
     */
    function rootChainManager() external view returns (address);

    /**
     * @notice VestRewards from VestingPools
     */
    function vestRewards() external returns (bool);

    /// @notice Emitted on poolId updated.
    event PoolIDUpdated(uint256 poolId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRootChainManager {
    event TokenMapped(
        address indexed rootToken,
        address indexed childToken,
        bytes32 indexed tokenType
    );

    event PredicateRegistered(
        bytes32 indexed tokenType,
        address indexed predicateAddress
    );

    function registerPredicate(bytes32 tokenType, address predicateAddress)
        external;

    function mapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function cleanMapToken(address rootToken, address childToken) external;

    function remapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function depositEtherFor(address user) external payable;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;

    function exit(bytes calldata inputData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This file contains fake libs just for static linking.
 * These fake libs' code is assumed to never run.
 * On compilation of dependant contracts, instead of fake libs addresses,
 * indicate addresses of deployed real contracts (or accounts).
 */

/// @dev Address of the ZKPToken contract ('../ZKPToken.sol') instance
library TokenAddress {
    function neverCallIt() external pure {
        revert("FAKE");
    }
}

/// @dev Address of the VestingPools ('../VestingPools.sol') instance
library VestingPoolsAddress {
    function neverCallIt() external pure {
        revert("FAKE");
    }
}

/// @dev Address of the RootChainManager from polygon
library RootChainManagerAddress {
    function neverCallIt() external pure {
        revert("FAKE");
    }
}

/// @dev Address of the Privacy Staking contract in polygon
library PrivacyStakingAddress {
    function neverCallIt() external pure {
        revert("FAKE");
    }
}

/// @dev Address of the PoolStakes._defaultOwner
// (NB: if it's not a multisig, transfer ownership to a Multisig contract)
library DefaultOwnerAddress {
    function neverCallIt() external pure {
        revert("FAKE");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * Inspired and borrowed by/from the openzeppelin/contracts` {Ownable}.
 * Unlike openzeppelin` version:
 * - by default, the owner account is the one returned by the {_defaultOwner}
 * function, but not the deployer address;
 * - this contract has no constructor and may run w/o initialization;
 * - the {renounceOwnership} function removed.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 * The child contract must define the {_defaultOwner} function.
 */
abstract contract DefaultOwnable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev Returns the current owner address, if it's defined, or the default owner address otherwise.
    function owner() public view virtual returns (address) {
        return _owner == address(0) ? _defaultOwner() : _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// @dev Transfers ownership of the contract to the `newOwner`. The owner can only call.
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function _defaultOwner() internal view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

/**
 * @title SafeUints
 * @notice Util functions which throws if a uint256 can't fit into smaller uints.
 */
contract SafeUints {
    // @dev Checks if the given uint256 does not overflow uint96
    function _safe96(uint256 n) internal pure returns (uint96) {
        require(n < 2**96, "VPools: Unsafe96");
        return uint96(n);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev To save gas, params are packed to fit into a single storage slot.
 * Some amounts are scaled (divided) by {SCALE} - note names starting with
 * the letter "s" (stands for "scaled") followed by a capital letter.
 */
struct PoolParams {
    // if `true`, allocation gets pre-minted, otherwise minted when vested
    bool isPreMinted;
    // if `true`, the owner may change {start} and {duration}
    bool isAdjustable;
    // (UNIX) time when vesting starts
    uint32 start;
    // period in days (since the {start}) of vesting
    uint16 vestingDays;
    // scaled total amount to (ever) vest from the pool
    uint48 sAllocation;
    // out of {sAllocation}, amount (also scaled) to be unlocked on the {start}
    uint48 sUnlocked;
    // amount vested from the pool so far (without scaling)
    uint96 vested;
}