// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/Constants.sol";
import { PoolParams } from "./interfaces/Types.sol";
import "./interfaces/IVestingPools.sol";
import "./utils/Claimable.sol";
import "./utils/DefaultOwnable.sol";
import { DefaultOwnerAddress, TokenAddress, VestingPoolsAddress } from "./utils/Linking.sol";
import "./utils/ProxyFactory.sol";
import "./utils/SafeUints.sol";

/**
 * @title PoolStakes
 * @notice The contract claims (ERC-20) token from the "VestingPools" contract
 * and then let "stakeholders" withdraw token amounts prorate to their stakes.
 * @dev A few copy of this contract (i.e. proxies created via the {createProxy}
 * method) are supposed to run. Every proxy distributes its own "vesting pool",
 * so it (the proxy) must be registered with the "VestingPools" contract as the
 * "wallet" for that "vesting pool".
 */
contract PoolStakes is
    Claimable,
    SafeUints,
    ProxyFactory,
    DefaultOwnable,
    Constants
{
    // @dev "Stake" of a "stakeholder" in the "vesting pool"
    struct Stake {
        // token amount allocated for the stakeholder
        uint96 allocated;
        // token amount released to the stakeholder so far
        uint96 released;
    }

    /// @notice ID of the vesting pool this contract is the "wallet" for
    uint16 public poolId;
    /// @notice Token amount the vesting pool is set to vest
    uint96 public allocation;
    /// @notice Token amount allocated from {allocation} to stakeholders so far
    /// @dev It is the total amount of all {stakes[..].allocated}
    uint96 public allocated;

    /// @notice Token amount released to stakeholders so far
    /// @dev It is the total amount of all {stakes[..].released}
    uint96 public released;
    /// @notice Share of vested amount attributable to 1 unit of {allocation}
    /// @dev Stakeholder "h" may withdraw from the contract this token amount:
    ///     factor/SCALE * stakes[h].allocated - stakes[h].released
    uint160 public factor;

    // mapping from stakeholder address to stake
    mapping(address => Stake) public stakes;

    event VestingClaimed(uint256 amount);
    event Released(address indexed holder, uint256 amount);
    event StakeAdded(address indexed holder, uint256 allocated);
    event StakeSplit(
        address indexed holder,
        uint256 allocated,
        uint256 released
    );

    /// @notice Returns address of the token being vested
    function token() external view returns (address) {
        return address(_getToken());
    }

    /// @notice Returns address of the {VestingPool} smart contract
    function vestingPools() external view returns (address) {
        return address(_getVestingPools());
    }

    /// @notice Returns token amount the specified stakeholder may withdraw now
    function releasableAmount(address holder) external view returns (uint256) {
        Stake memory stake = _getStake(holder);
        return _releasableAmount(stake, uint256(factor));
    }

    /// @notice Returns token amount the specified stakeholder may withdraw now
    /// on top of the {releasableAmount} should {claimVesting} be called
    function unclaimedShare(address holder) external view returns (uint256) {
        Stake memory stake = _getStake(holder);
        uint256 unclaimed = _getVestingPools().releasableAmount(poolId);
        return (unclaimed * uint256(stake.allocated)) / allocation;
    }

    /// @notice Claims vesting to this contract from the vesting pool
    function claimVesting() external {
        _claimVesting();
    }

    /////////////////////
    //// StakeHolder ////
    /////////////////////

    /// @notice Sends the releasable amount to the message sender
    /// @dev Stakeholder only may call
    function withdraw() external {
        _withdraw(msg.sender); // throws if msg.sender is not a stakeholder
    }

    /// @notice Calls {claimVesting} and sends the releasable amount to the message sender
    /// @dev Stakeholder only may call
    function claimAndWithdraw() external {
        _claimVesting();
        _withdraw(msg.sender); // throws if msg.sender is not a stakeholder
    }

    /// @notice Allots a new stake out of the stake of the message sender
    /// @dev Stakeholder only may call
    function splitStake(address newHolder, uint256 newAmount) external {
        address holder = msg.sender;
        require(newHolder != holder, "PStakes: duplicated address");

        Stake memory stake = _getStake(holder);
        require(newAmount <= stake.allocated, "PStakes: too large allocated");

        uint256 updAmount = uint256(stake.allocated) - newAmount;
        uint256 updReleased = (uint256(stake.released) * updAmount) /
            uint256(stake.allocated);
        stakes[holder] = Stake(_safe96(updAmount), _safe96(updReleased));
        emit StakeSplit(holder, updAmount, updReleased);

        uint256 newVested = uint256(stake.released) - updReleased;
        stakes[newHolder] = Stake(_safe96(newAmount), _safe96(newVested));
        emit StakeSplit(newHolder, newAmount, newVested);
    }

    //////////////////
    //// Owner ////
    //////////////////

    /// @notice Inits the contract and adds stakes
    /// @dev Owner only may call on a proxy (but not on the implementation)
    function addStakes(
        uint256 _poolId,
        address[] calldata holders,
        uint256[] calldata allocations,
        uint256 unallocated
    ) external onlyOwner {
        if (allocation == 0) {
            _init(_poolId);
        } else {
            require(_poolId == poolId, "PStakes: pool mismatch");
        }

        uint256 nEntries = holders.length;
        require(nEntries == allocations.length, "PStakes: length mismatch");
        uint256 updAllocated = uint256(allocated);
        for (uint256 i = 0; i < nEntries; i++) {
            _throwZeroHolderAddress(holders[i]);
            require(
                stakes[holders[i]].allocated == 0,
                "PStakes: holder exists"
            );
            require(allocations[i] > 0, "PStakes: zero allocation");

            updAllocated += allocations[i];
            stakes[holders[i]] = Stake(_safe96(allocations[i]), 0);
            emit StakeAdded(holders[i], allocations[i]);
        }
        require(
            updAllocated + unallocated == allocation,
            "PStakes: invalid allocation"
        );
        allocated = _safe96(updAllocated);
    }

    /// @notice Calls {claimVesting} and sends releasable tokens to specified stakeholders
    /// @dev Owner may call only
    function massWithdraw(address[] calldata holders) external onlyOwner {
        _claimVesting();
        for (uint256 i = 0; i < holders.length; i++) {
            _withdraw(holders[i]);
        }
    }

    /// @notice Withdraws accidentally sent token from this contract
    /// @dev Owner may call only
    function claimErc20(
        address claimedToken,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        IERC20 vestedToken = IERC20(address(_getToken()));
        if (claimedToken == address(vestedToken)) {
            uint256 balance = vestedToken.balanceOf(address(this));
            require(
                balance - amount >= allocation - released,
                "PStakes: too big amount"
            );
        }
        _claimErc20(claimedToken, to, amount);
    }

    /// @notice Removes the contract from blockchain when tokens are released
    /// @dev Owner only may call on a proxy (but not on the implementation)
    function removeContract() external onlyOwner {
        // avoid accidental removing of the implementation
        _throwImplementation();

        require(allocation == released, "PStakes: unpaid stakes");

        IERC20 vestedToken = IERC20(address(_getToken()));
        uint256 balance = vestedToken.balanceOf(address(this));
        require(balance == 0, "PStakes: non-zero balance");

        selfdestruct(payable(msg.sender));
    }

    //////////////////
    //// Internal ////
    //////////////////

    /// @dev Returns the address of the default owner
    // (declared `view` rather than `pure` to facilitate testing)
    function _defaultOwner() internal view virtual override returns (address) {
        return address(DefaultOwnerAddress);
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

    /// @dev Returns the stake of the specified stakeholder reverting on errors
    function _getStake(address holder) internal view returns (Stake memory) {
        _throwZeroHolderAddress(holder);
        Stake memory stake = stakes[holder];
        require(stake.allocated != 0, "PStakes: unknown stake");
        return stake;
    }

    /// @notice Initialize the contract
    /// @dev May be called on a proxy only (but not on the implementation)
    function _init(uint256 _poolId) internal {
        _throwImplementation();
        require(_poolId < 2**16, "PStakes:unsafePoolId");

        IVestingPools pools = _getVestingPools();
        address wallet = pools.getWallet(_poolId);
        require(wallet == address(this), "PStakes:invalidPool");
        PoolParams memory pool = pools.getPool(_poolId);
        require(pool.sAllocation != 0, "PStakes:zeroPool");

        poolId = uint16(_poolId);
        allocation = _safe96(uint256(pool.sAllocation) * SCALE);
    }

    /// @dev Returns amount that may be released for the given stake and factor
    function _releasableAmount(Stake memory stake, uint256 _factor)
        internal
        pure
        returns (uint256)
    {
        uint256 share = (_factor * uint256(stake.allocated)) / SCALE;
        if (share > stake.allocated) {
            // imprecise division safeguard
            share = uint256(stake.allocated);
        }
        return share - uint256(stake.released);
    }

    /// @dev Claims vesting to this contract from the vesting pool
    function _claimVesting() internal {
        // (reentrancy attack impossible - known contract called)
        uint256 justVested = _getVestingPools().release(poolId, 0);
        factor += uint160((justVested * SCALE) / uint256(allocation));
        emit VestingClaimed(justVested);
    }

    /// @dev Sends the releasable amount of the specified placeholder
    function _withdraw(address holder) internal {
        Stake memory stake = _getStake(holder);
        uint256 releasable = _releasableAmount(stake, uint256(factor));
        require(releasable > 0, "PStakes: nothing to withdraw");

        stakes[holder].released = _safe96(uint256(stake.released) + releasable);
        released = _safe96(uint256(released) + releasable);

        // (reentrancy attack impossible - known contract called)
        require(_getToken().transfer(holder, releasable), "PStakes:E1");
        emit Released(holder, releasable);
    }

    function _throwZeroHolderAddress(address holder) private pure {
        require(holder != address(0), "PStakes: zero holder address");
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

/// @dev Address of the PoolStakes._defaultOwner
// (NB: if it's not a multisig, transfer ownership to a Multisig contract)
library DefaultOwnerAddress {
    function neverCallIt() external pure {
        revert("FAKE");
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >0.8.0;

/**
 * @title ProxyFactory
 * @notice It "clones" the (child) contract deploying EIP-1167 proxies
 * @dev Generated proxies:
 * - being the EIP-1167 proxy, DELEGATECALL this (child) contract
 * - support EIP-1967 specs for the "implementation slot"
 *  (it gives explorers/wallets more chances to "understand" it's a proxy)
 */
abstract contract ProxyFactory {
    // Storage slot that the EIP-1967 defines for the "implementation" address
    // (`uint256(keccak256('eip1967.proxy.implementation')) - 1`)
    bytes32 private constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Emits when a new proxy is created
    event NewProxy(address proxy);

    /**
     * @notice Returns `true` if called on a proxy (rather than implementation)
     */
    function isProxy() external view returns (bool) {
        return _isProxy();
    }

    /**
     * @notice Deploys a new proxy instance that DELEGATECALLs this contract
     * @dev Must be called on the implementation (reverts if a proxy is called)
     */
    function createProxy() external returns (address proxy) {
        _throwProxy();

        // CREATE an EIP-1167 proxy instance with the target being this contract
        bytes20 target = bytes20(address(this));
        assembly {
            let initCode := mload(0x40)
            mstore(
                initCode,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(initCode, 0x14), target)
            mstore(
                add(initCode, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            // note, 0x37 (55 bytes) is the init bytecode length
            // while the deployed bytecode length is 0x2d (45 bytes) only
            proxy := create(0, initCode, 0x37)
        }

        // Write this contract address into the proxy' "implementation" slot
        // (reentrancy attack impossible - this contract called)
        ProxyFactory(proxy).initProxy(address(this));

        emit NewProxy(proxy);
    }

    /**
     * @dev Writes given address into the "implementation" slot of a new proxy.
     * !!! It MUST (and may only) be called:
     * - via the implementation instance with the {createProxy} method
     * - on a newly deployed proxy only
     * It reverts if called on the implementation or on initialized proxies.
     */
    function initProxy(address impl) external {
        _throwImplementation();
        require(
            _getImplementation() == address(0),
            "ProxyFactory:ALREADY_INITIALIZED"
        );

        // write into the "implementation" slot
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, impl)
        }
    }

    /// @dev Returns true if called on a proxy instance
    function _isProxy() internal view virtual returns (bool) {
        // for a DELEGATECALLed contract, `this` and `extcodesize`
        // are the address and the code size of the calling contract
        // (for a CALLed contract, they are ones of that called contract)
        uint256 _size;
        address _this = address(this);
        assembly {
            _size := extcodesize(_this)
        }

        // shall be the same as the one the `createProxy` generates
        return _size == 45;
    }

    /// @dev Returns the address stored in the "implementation" slot
    function _getImplementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /// @dev Throws if called on the implementation
    function _throwImplementation() internal view {
        require(_isProxy(), "ProxyFactory:IMPL_CALLED");
    }

    /// @dev Throws if called on a proxy
    function _throwProxy() internal view {
        require(!_isProxy(), "ProxyFactory:PROXY_CALLED");
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