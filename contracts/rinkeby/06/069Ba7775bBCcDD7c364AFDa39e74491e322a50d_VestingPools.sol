// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/Constants.sol";
import { PoolParams } from "./interfaces/Types.sol";
import "./interfaces/IMintable.sol";
import "./interfaces/IVestingPools.sol";
import "./utils/Claimable.sol";
import { TokenAddress } from "./utils/Linking.sol";
import "./utils/SafeUints.sol";

/**
 * @title VestingPools
 * @notice It mints and vests a (mintable) ERC-20 token to "Vesting Pools".
 * @dev Each "Vesting Pool" (or a "pool") has a `wallet` and `PoolParams`.
 * The `wallet` requests vesting and receives vested tokens, or nominate
 * another address that receives them.
 * `PoolParams` deterministically define minting and unlocking schedule.
 * Once added, a pool can not be removed. Subject to strict limitations,
 * owner may update a few parameters of a pool.
 */
contract VestingPools is
    Ownable,
    Claimable,
    SafeUints,
    Constants,
    IVestingPools
{
    /// @notice Accumulated amount to be vested to all pools
    uint96 public totalAllocation;
    /// @notice Total amount already vested to all pools
    uint96 public totalVested;

    // ID of a pool (i.e. `poolId`) is the index in these two arrays
    address[] internal _wallets;
    PoolParams[] internal _pools;

    /// @inheritdoc IVestingPools
    function token() external view override returns (address) {
        return _getToken();
    }

    /// @inheritdoc IVestingPools
    function getWallet(uint256 poolId)
        external
        view
        override
        returns (address)
    {
        _throwInvalidPoolId(poolId);
        return _wallets[poolId];
    }

    /// @inheritdoc IVestingPools
    function getPool(uint256 poolId)
        external
        view
        override
        returns (PoolParams memory)
    {
        return _getPool(poolId);
    }

    /// @inheritdoc IVestingPools
    function releasableAmount(uint256 poolId)
        external
        view
        override
        returns (uint256)
    {
        PoolParams memory pool = _getPool(poolId);
        return _getReleasable(pool, _timeNow());
    }

    /// @inheritdoc IVestingPools
    function vestedAmount(uint256 poolId)
        external
        view
        override
        returns (uint256)
    {
        PoolParams memory pool = _getPool(poolId);
        return uint256(pool.vested);
    }

    /// @inheritdoc IVestingPools
    function release(uint256 poolId, uint256 amount)
        external
        override
        returns (uint256 released)
    {
        return _releaseTo(poolId, msg.sender, amount);
    }

    /// @inheritdoc IVestingPools
    function releaseTo(
        uint256 poolId,
        address account,
        uint256 amount
    ) external override returns (uint256 released) {
        _throwZeroAddress(account);
        return _releaseTo(poolId, account, amount);
    }

    /// @inheritdoc IVestingPools
    function updatePoolWallet(uint256 poolId, address newWallet)
        external
        override
    {
        _throwZeroAddress(newWallet);
        _throwUnauthorizedWallet(poolId, msg.sender);

        _wallets[poolId] = newWallet;
        emit WalletUpdated(poolId, newWallet);
    }

    /// @inheritdoc IVestingPools
    function addVestingPools(
        address[] memory wallets,
        PoolParams[] memory pools
    ) external override onlyOwner {
        require(wallets.length == pools.length, "VPools: length mismatch");

        uint256 timeNow = _timeNow();
        IMintable theToken = IMintable(_getToken());
        uint256 updAllocation = uint256(totalAllocation);
        uint256 preMinted = 0;
        uint256 poolId = _pools.length;
        for (uint256 i = 0; i < wallets.length; i++) {
            _throwZeroAddress(wallets[i]);
            require(pools[i].start >= timeNow, "VPools: start already passed");
            require(pools[i].sAllocation != 0, "VPools: zero sAllocation");
            require(
                pools[i].sAllocation >= pools[i].sUnlocked,
                "VPools: too big sUnlocked"
            );
            require(pools[i].vested == 0, "VPools: zero vested expected");

            uint256 allocation = uint256(pools[i].sAllocation) * SCALE;
            updAllocation += allocation;

            _wallets.push(wallets[i]);
            _pools.push(pools[i]);
            emit PoolAdded(poolId++, wallets[i], allocation);

            if (pools[i].isPreMinted) {
                preMinted += allocation;
            }
        }
        // left outside the cycle to save gas for a non-reverting transaction
        require(updAllocation <= MAX_SUPPLY, "VPools: supply exceeded");
        totalAllocation = _safe96(updAllocation);

        if (preMinted != 0) {
            require(theToken.mint(address(this), preMinted), "VPools:E5");
        }
    }

    /// @inheritdoc IVestingPools
    /// @dev Vesting schedule for a pool may be significantly altered by this.
    /// However, pool allocation (i.e. token amount to vest) remains unchanged.
    function updatePoolTime(
        uint256 poolId,
        uint32 start,
        uint16 vestingDays
    ) external override onlyOwner {
        PoolParams memory pool = _getPool(poolId);

        require(pool.isAdjustable, "VPools: non-adjustable");
        require(
            uint256(pool.sAllocation) * SCALE > uint256(pool.vested),
            "VPools: fully vested"
        );
        uint256 end = uint256(start) + uint256(vestingDays) * 1 days;
        // `end` may NOT be in the past, unlike `start` that may be even zero
        require(_timeNow() > end, "VPools: too late updates");

        pool.start = start;
        pool.vestingDays = vestingDays;
        _pools[poolId] = pool;

        emit PoolUpdated(poolId, start, vestingDays);
    }

    /**
     * @notice Withdraws accidentally sent token from this contract.
     * @dev Owner may call only.
     */
    function claimErc20(
        address claimedToken,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        IERC20 vestedToken = IERC20(_getToken());
        if (claimedToken == address(vestedToken)) {
            uint256 actual = vestedToken.balanceOf(address(this));
            uint256 expected = vestedToken.totalSupply() - totalVested;
            require(actual >= expected + amount, "VPools: too big amount");
        }
        _claimErc20(claimedToken, to, amount);
    }

    /// @notice Removes the contract from blockchain if there is no tokens to vest.
    /// @dev Owner may call only.
    function removeContract() external onlyOwner {
        // intended "strict comparison"
        require(totalAllocation == totalVested, "VPools:E1");
        selfdestruct(payable(msg.sender));
    }

    //////////////////
    //// Internal ////
    //////////////////

    /// @dev Returns token contract address
    // (declared `view` rather than `pure` to facilitate testing)
    function _getToken() internal view virtual returns (address) {
        return address(TokenAddress);
    }

    /// @dev Returns pool params for the pool with the given ID
    function _getPool(uint256 poolId)
        internal
        view
        returns (PoolParams memory)
    {
        _throwInvalidPoolId(poolId);
        return _pools[poolId];
    }

    /// @dev Returns amount that may be released now for the pool given
    function _getReleasable(PoolParams memory pool, uint256 timeNow)
        internal
        pure
        returns (uint256)
    {
        if (timeNow < pool.start) return 0;

        uint256 allocation = uint256(pool.sAllocation) * SCALE;
        if (pool.vested >= allocation) return 0;

        uint256 releasable = allocation - uint256(pool.vested);
        uint256 duration = uint256(pool.vestingDays) * 1 days;
        uint256 end = uint256(pool.start) + duration;
        if (timeNow < end) {
            uint256 unlocked = uint256(pool.sUnlocked) * SCALE;
            uint256 locked = ((allocation - unlocked) * (end - timeNow)) /
                duration; // can't be 0 here

            releasable = locked > releasable ? 0 : releasable - locked;
        }

        return releasable;
    }

    /// @dev Vests from the pool the given or releasable amount to the given address
    function _releaseTo(
        uint256 poolId,
        address to,
        uint256 amount
    ) internal returns (uint256 released) {
        PoolParams memory pool = _getPool(poolId);
        _throwUnauthorizedWallet(poolId, msg.sender);

        uint256 releasable = _getReleasable(pool, _timeNow());
        require(releasable >= amount, "VPools: not enough to release");

        released = amount == 0 ? releasable : amount;

        _pools[poolId].vested = _safe96(released + uint256(pool.vested));
        totalVested = _safe96(released + uint256(totalVested));

        // reentrancy impossible (known contract called)
        if (pool.isPreMinted) {
            require(IERC20(_getToken()).transfer(to, released), "VPools:E6");
        } else {
            require(IMintable(_getToken()).mint(to, released), "VPools:E7");
        }
        emit Released(poolId, to, released);
    }

    function _throwZeroAddress(address account) private pure {
        require(account != address(0), "VPools: zero address(account|wallet)");
    }

    function _throwInvalidPoolId(uint256 poolId) private view {
        require(poolId < _pools.length, "VPools: invalid pool id");
    }

    function _throwUnauthorizedWallet(uint256 poolId, address wallet)
        private
        view
    {
        _throwZeroAddress(wallet);
        require(_wallets[poolId] == wallet, "VPools: unauthorized");
    }

    /// @dev Returns the current block timestamp (added to ease testing)
    function _timeNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }
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

contract Constants {
    // $ZKP token max supply
    uint256 internal constant MAX_SUPPLY = 1e27;

    // Scaling factor in token amount calculations
    uint256 internal constant SCALE = 1e12;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintable is IERC20 {
    function mint(address account, uint256 amount) external returns (bool);
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
pragma solidity >0.8.0;

/**
 * @title Claimable
 * @notice It withdraws accidentally sent tokens from this contract.
 * @dev It provides reentrancy guard. The code borrowed from openzeppelin-contracts.
 * Unlike original code, this version does not require `constructor` call.
 */
contract Claimable {
    bytes4 private constant SELECTOR_TRANSFER =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _reentrancyStatus;

    /// @dev Withdraws ERC20 tokens from this contract
    /// (take care of reentrancy attack risk mitigation)
    function _claimErc20(
        address token,
        address to,
        uint256 amount
    ) internal {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR_TRANSFER, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "claimErc20: TRANSFER_FAILED"
        );
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_reentrancyStatus != _ENTERED, "claimErc20: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = _NOT_ENTERED;
    }
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

/// @dev Address of the RootChainManager
library RootChainManagerAddress {
    function neverCallIt() external pure {
        revert("FAKE");
    }
}

/// @dev Address of the RootChainManagerProxy
library RootChainManagerProxyAddress {
    function neverCallIt() external pure {
        revert("FAKE");
    }
}

/// @dev Address of the Privacy Staking contract
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