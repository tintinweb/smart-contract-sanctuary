// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface PoS
pragma solidity >=0.7.0 <0.9.0;

interface IPoS {
    /// @notice Produce a block
    /// @param _index the index of the instance of pos you want to interact with
    /// @dev this function can only be called by a worker, user never calls it directly
    function produceBlock(uint256 _index) external returns (bool);

    /// @notice Get reward manager address
    /// @param _index index of instance
    /// @return address of instance's RewardManager
    function getRewardManagerAddress(uint256 _index)
        external
        view
        returns (address);

    /// @notice Get block selector address
    /// @param _index index of instance
    /// @return address of instance's block selector
    function getBlockSelectorAddress(uint256 _index)
        external
        view
        returns (address);

    /// @notice Get block selector index
    /// @param _index index of instance
    /// @return index of instance's block selector
    function getBlockSelectorIndex(uint256 _index)
        external
        view
        returns (uint256);

    /// @notice Get staking address
    /// @param _index index of instance
    /// @return address of instance's staking contract
    function getStakingAddress(uint256 _index) external view returns (address);

    /// @notice Get state of a particular instance
    /// @param _index index of instance
    /// @param _user address of user
    /// @return bool if user is eligible to produce next block
    /// @return address of user that was chosen to build the block
    /// @return current reward paid by the network for that block
    function getState(uint256 _index, address _user)
        external
        view
        returns (
            bool,
            address,
            uint256
        );

    function terminate(uint256 _index) external;
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface RewardManager
pragma solidity >=0.7.0 <0.9.0;

interface IRewardManager {
    /// @notice Rewards address
    /// @param _address address be rewarded
    /// @param _amount reward
    /// @dev only the pos contract can call this
    function reward(address _address, uint256 _amount) external;

    /// @notice Get RewardManager's balance
    function getBalance() external view returns (uint256);

    /// @notice Get current reward amount
    function getCurrentReward() external view returns (uint256);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface Staking
pragma solidity >=0.7.0 <0.9.0;

interface IStaking {
    /// @notice Returns total amount of tokens counted as stake
    /// @param _userAddress user to retrieve staked balance from
    /// @return finalized staked of _userAddress
    function getStakedBalance(address _userAddress)
        external
        view
        returns (uint256);

    /// @notice Returns the timestamp when next deposit can be finalized
    /// @return timestamp of when finalizeStakes() is callable
    function getMaturingTimestamp(address _userAddress)
        external
        view
        returns (uint256);

    /// @notice Returns the timestamp when next withdraw can be finalized
    /// @return timestamp of when finalizeWithdraw() is callable
    function getReleasingTimestamp(address _userAddress)
        external
        view
        returns (uint256);

    /// @notice Returns the balance waiting/ready to be matured
    /// @return amount that will get staked after finalization
    function getMaturingBalance(address _userAddress)
        external
        view
        returns (uint256);

    /// @notice Returns the balance waiting/ready to be released
    /// @return amount that will get withdrew after finalization
    function getReleasingBalance(address _userAddress)
        external
        view
        returns (uint256);

    /// @notice Deposit CTSI to be staked. The money will turn into staked
    ///         balance after timeToStake days
    /// @param _amount The amount of tokens that are gonna be deposited.
    function stake(uint256 _amount) external;

    /// @notice Remove tokens from staked balance. The money can
    ///         be released after timeToRelease seconds, if the
    ///         function withdraw is called.
    /// @param _amount The amount of tokens that are gonna be unstaked.
    function unstake(uint256 _amount) external;

    /// @notice Transfer tokens to user's wallet.
    /// @param _amount The amount of tokens that are gonna be transferred.
    function withdraw(uint256 _amount) external;

    // events
    /// @notice CTSI tokens were deposited, they count as stake after _maturationDate
    /// @param user address of msg.sender
    /// @param amount amount deposited for staking
    /// @param maturationDate date when the stake can be finalized
    event Stake(address indexed user, uint256 amount, uint256 maturationDate);

    /// @notice Unstake tokens, moving them to releasing structure
    /// @param user address of msg.sender
    /// @param amount amount of tokens to be released
    /// @param maturationDate date when the tokens can be withdrew
    event Unstake(address indexed user, uint256 amount, uint256 maturationDate);

    /// @notice Withdraw process was finalized
    /// @param user address of msg.sender
    /// @param amount amount of tokens withdrawn
    event Withdraw(address indexed user, uint256 amount);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface WorkerManager
/// @author Danilo Tuler
pragma solidity >=0.7.0 <0.9.0;

interface IWorkerManagerAuthManager {
    /// @notice Asks the worker to work for the sender. Sender needs to pay something.
    /// @param workerAddress address of the worker
    function hire(address payable workerAddress) external payable;

    /// @notice Called by the user to cancel a job offer
    /// @param workerAddress address of the worker node
    function cancelHire(address workerAddress) external;

    /// @notice Called by the user to retire his worker.
    /// @param workerAddress address of the worker to be retired
    /// @dev this also removes all authorizations in place
    function retire(address payable workerAddress) external;

    /// @notice Gives worker permission to act on a DApp
    /// @param _workerAddress address of the worker node to given permission
    /// @param _dappAddress address of the dapp that permission will be given to
    function authorize(address _workerAddress, address _dappAddress) external;

    /// @notice Called by the worker to accept the job
    function acceptJob() external;

    /// @notice Called by the worker to reject a job offer
    function rejectJob() external payable;
}

pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

pragma solidity >=0.8.4;

import "./ENS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../root/Controllable.sol";

abstract contract NameResolver {
    function setName(bytes32 node, string memory name) public virtual;
}

bytes32 constant lookup = 0x3031323334353637383961626364656600000000000000000000000000000000;

bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

// namehash('addr.reverse')

contract ReverseRegistrar is Ownable, Controllable {
    ENS public ens;
    NameResolver public defaultResolver;

    event ReverseClaimed(address indexed addr, bytes32 indexed node);

    /**
     * @dev Constructor
     * @param ensAddr The address of the ENS registry.
     * @param resolverAddr The address of the default reverse resolver.
     */
    constructor(ENS ensAddr, NameResolver resolverAddr) {
        ens = ensAddr;
        defaultResolver = resolverAddr;

        // Assign ownership of the reverse record to our deployer
        ReverseRegistrar oldRegistrar = ReverseRegistrar(
            ens.owner(ADDR_REVERSE_NODE)
        );
        if (address(oldRegistrar) != address(0x0)) {
            oldRegistrar.claim(msg.sender);
        }
    }

    modifier authorised(address addr) {
        require(
            addr == msg.sender ||
                controllers[msg.sender] ||
                ens.isApprovedForAll(addr, msg.sender) ||
                ownsContract(addr),
            "Caller is not a controller or authorised by address or the address itself"
        );
        _;
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @return The ENS node hash of the reverse record.
     */
    function claim(address owner) public returns (bytes32) {
        return _claimWithResolver(msg.sender, owner, address(0x0));
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param addr The reverse record to set
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @return The ENS node hash of the reverse record.
     */
    function claimForAddr(address addr, address owner)
        public
        authorised(addr)
        returns (bytes32)
    {
        return _claimWithResolver(addr, owner, address(0x0));
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @param resolver The address of the resolver to set; 0 to leave unchanged.
     * @return The ENS node hash of the reverse record.
     */
    function claimWithResolver(address owner, address resolver)
        public
        returns (bytes32)
    {
        return _claimWithResolver(msg.sender, owner, resolver);
    }

    /**
     * @dev Transfers ownership of the reverse ENS record specified with the
     *      address provided
     * @param addr The reverse record to set
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @param resolver The address of the resolver to set; 0 to leave unchanged.
     * @return The ENS node hash of the reverse record.
     */
    function claimWithResolverForAddr(
        address addr,
        address owner,
        address resolver
    ) public authorised(addr) returns (bytes32) {
        return _claimWithResolver(addr, owner, resolver);
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the calling account. First updates the resolver to the default reverse
     * resolver if necessary.
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setName(string memory name) public returns (bytes32) {
        bytes32 node = _claimWithResolver(
            msg.sender,
            address(this),
            address(defaultResolver)
        );
        defaultResolver.setName(node, name);
        return node;
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the account provided. First updates the resolver to the default reverse
     * resolver if necessary.
     * Only callable by controllers and authorised users
     * @param addr The reverse record to set
     * @param owner The owner of the reverse node
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setNameForAddr(
        address addr,
        address owner,
        string memory name
    ) public authorised(addr) returns (bytes32) {
        bytes32 node = _claimWithResolver(
            addr,
            address(this),
            address(defaultResolver)
        );
        defaultResolver.setName(node, name);
        ens.setSubnodeOwner(ADDR_REVERSE_NODE, sha3HexAddress(addr), owner);
        return node;
    }

    /**
     * @dev Returns the node hash for a given account's reverse records.
     * @param addr The address to hash
     * @return The ENS node hash.
     */
    function node(address addr) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr))
            );
    }

    /**
     * @dev An optimised function to compute the sha3 of the lower-case
     *      hexadecimal representation of an Ethereum address.
     * @param addr The address to hash
     * @return ret The SHA3 hash of the lower-case hexadecimal encoding of the
     *         input address.
     */
    function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
        assembly {
            for {
                let i := 40
            } gt(i, 0) {

            } {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
    }

    /* Internal functions */

    function _claimWithResolver(
        address addr,
        address owner,
        address resolver
    ) internal returns (bytes32) {
        bytes32 label = sha3HexAddress(addr);
        bytes32 node = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, label));
        address currentResolver = ens.resolver(node);
        bool shouldUpdateResolver = (resolver != address(0x0) &&
            resolver != currentResolver);
        address newResolver = shouldUpdateResolver ? resolver : currentResolver;

        ens.setSubnodeRecord(ADDR_REVERSE_NODE, label, owner, newResolver, 0);

        emit ReverseClaimed(addr, node);

        return node;
    }

    function ownsContract(address addr) internal view returns (bool) {
        try Ownable(addr).owner() returns (address owner) {
            return owner == msg.sender;
        } catch {
            return false;
        }
    }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controllable is Ownable {
    mapping(address => bool) public controllers;

    event ControllerChanged(address indexed controller, bool enabled);

    modifier onlyController {
        require(
            controllers[msg.sender],
            "Controllable: Caller is not a controller"
        );
        _;
    }

    function setController(address controller, bool enabled) public onlyOwner {
        controllers[controller] = enabled;
        emit ControllerChanged(controller, enabled);
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@cartesi/pos/contracts/IPoS.sol";

import "./utils/WadRayMath.sol";

contract StakingPoolData is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using WadRayMath for uint256;
    uint256 public shares; // total number of shares
    uint256 public amount; // amount of staked tokens (no matter where it is)
    uint256 public requiredLiquidity; // amount of required tokens for withdraw requests

    IPoS public pos;

    struct UserBalance {
        uint256 balance; // amount of free tokens belonging to this user
        uint256 shares; // amount of shares belonging to this user
        uint256 depositTimestamp; // timestamp of when user deposited for the last time
    }
    mapping(address => UserBalance) public userBalance;

    function amountToShares(uint256 _amount) public view returns (uint256) {
        if (amount == 0) {
            // no shares yet, return 1 to 1 ratio
            return _amount.wad2ray();
        }
        return _amount.wmul(shares).wdiv(amount);
    }

    function sharesToAmount(uint256 _shares) public view returns (uint256) {
        if (shares == 0) {
            // no shares yet, return 1 to 1 ratio
            return _shares.ray2wad();
        }
        return _shares.rmul(amount).rdiv(shares);
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

import "./interfaces/StakingPool.sol";
import "./StakingPoolData.sol";
import "./StakingPoolManagementImpl.sol";
import "./StakingPoolProducerImpl.sol";
import "./StakingPoolStakingImpl.sol";
import "./StakingPoolUserImpl.sol";
import "./StakingPoolWorkerImpl.sol";

contract StakingPoolImpl is
    StakingPool,
    StakingPoolData,
    StakingPoolManagementImpl,
    StakingPoolProducerImpl,
    StakingPoolStakingImpl,
    StakingPoolUserImpl,
    StakingPoolWorkerImpl
{
    constructor(
        address _ctsi,
        address _staking,
        address _workerManager,
        address _ens,
        uint256 _stakeLock
    )
        StakingPoolManagementImpl(_ens)
        StakingPoolProducerImpl(_ctsi)
        StakingPoolStakingImpl(_ctsi, _staking)
        StakingPoolUserImpl(_ctsi, _stakeLock)
        StakingPoolWorkerImpl(_workerManager)
    {}

    function initialize(address _fee, address _pos)
        external
        override
        initializer
    {
        __Pausable_init();
        __Ownable_init();
        __StakingPoolProducer_init(_fee, _pos);
        __StakingPoolStaking_init();
        __StakingPoolManagementImpl_init();
    }

    /// @notice updates the internal settings for important pieces of the Cartesi PoS system
    function update() external override onlyOwner {
        address _pos = factory.getPoS();
        __StakingPoolWorkerImpl_update(_pos);
    }

    function transferOwnership(address newOwner)
        public
        override(StakingPool, OwnableUpgradeable)
    {
        OwnableUpgradeable.transferOwnership(newOwner);
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

import "@ensdomains/ens-contracts/contracts/registry/ReverseRegistrar.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";

import "./interfaces/StakingPoolManagement.sol";
import "./interfaces/StakingPoolFactory.sol";
import "./StakingPoolData.sol";

contract StakingPoolManagementImpl is StakingPoolManagement, StakingPoolData {
    bytes32 private constant ADDR_REVERSE_NODE =
        0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    ENS public immutable ens;
    StakingPoolFactory public factory;

    // all immutable variables can stay at the constructor
    constructor(address _ens) initializer {
        require(_ens != address(0), "parameter can not be zero address");
        ens = ENS(_ens);

        // make sure reference code is pause so no one stake to it
        _pause();
    }

    function __StakingPoolManagementImpl_init() internal {
        factory = StakingPoolFactory(msg.sender);
    }

    /// @notice sets a name for the pool using ENS service
    function setName(string memory name) external override onlyOwner {
        ReverseRegistrar ensReverseRegistrar = ReverseRegistrar(
            ens.owner(ADDR_REVERSE_NODE)
        );

        // call the ENS reverse registrar resolving pool address to name
        ensReverseRegistrar.setName(name);

        // emit event, for subgraph processing
        emit StakingPoolRenamed(name);
    }

    /// @notice pauses new staking on the pool
    function pause() external override onlyOwner {
        _pause();
    }

    /// @notice unpauses new staking on the pool
    function unpause() external override onlyOwner {
        _unpause();
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@cartesi/pos/contracts/IPoS.sol";
import "@cartesi/pos/contracts/IRewardManager.sol";
import "./interfaces/Fee.sol";
import "./interfaces/StakingPoolProducer.sol";
import "./StakingPoolData.sol";

contract StakingPoolProducerImpl is StakingPoolProducer, StakingPoolData {
    IERC20 public immutable ctsi;
    Fee public fee;

    constructor(address _ctsi) {
        ctsi = IERC20(_ctsi);
    }

    function __StakingPoolProducer_init(address _fee, address _pos) internal {
        fee = Fee(_fee);
        pos = IPoS(_pos);
    }

    /// @notice routes produceBlock to POS contract and
    /// updates internal states of the pool
    /// @return true when everything went fine
    function produceBlock(uint256 _index) external override returns (bool) {
        IRewardManager rewardManager = IRewardManager(
            pos.getRewardManagerAddress(_index)
        );

        // get block reward
        uint256 reward = rewardManager.getCurrentReward();

        // produce block in the PoS
        require(
            pos.produceBlock(_index),
            "StakingPoolProducerImpl: failed to produce block"
        );

        // calculate pool commission
        uint256 commission = fee.getCommission(_index, reward);
        require(
            commission <= reward,
            "StakingPoolProducerImpl: commission is greater than block reward"
        );

        uint256 remainingReward = reward - commission; // this is a safety check
        // if commission is over the reward amount, it will underflow

        // increase pool amount, this will change the pool exchange rate
        amount += remainingReward;

        // send commission directly to pool owner
        if (commission > 0) {
            require(
                ctsi.transfer(owner(), commission),
                "StakingPoolProducerImpl: failed to transfer commission"
            );
        }

        // remainingReward is part of the balance, so it will automatically be staked by StakingPoolStakingImpl
        emit BlockProduced(reward, commission);

        return true;
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@cartesi/pos/contracts/IStaking.sol";
import "./interfaces/StakingPoolStaking.sol";
import "./StakingPoolData.sol";

/// @notice This contract takes care of the interaction between the pool and the staking contract
/// It makes sure that there is enough liquidity in the pool to fullfil all unstake request from
/// users, by requesting to withdraw or unstake from Staking contract.
/// The remaining balance is staked.
contract StakingPoolStakingImpl is StakingPoolStaking, StakingPoolData {
    IERC20 private immutable ctsi;
    IStaking private immutable staking;

    constructor(address _ctsi, address _staking) {
        ctsi = IERC20(_ctsi);
        staking = IStaking(_staking);
    }

    function __StakingPoolStaking_init() internal {
        require(
            ctsi.approve(address(staking), type(uint256).max),
            "Failed to approve CTSI for staking contract"
        );
    }

    function rebalance() external override {
        // get amounts
        (uint256 _stake, uint256 _unstake, uint256 _withdraw) = amounts();

        if (_stake > 0) {
            // we can stake
            staking.stake(_stake);
        }

        if (_unstake > 0) {
            // we need to provide liquidity
            staking.unstake(_unstake);
        }

        if (_withdraw > 0) {
            // we need to provide liquidity
            staking.withdraw(_withdraw);
        }
    }

    function amounts()
        public
        view
        override
        returns (
            uint256 stake,
            uint256 unstake,
            uint256 withdraw
        )
    {
        // get this contract balance first
        uint256 balance = ctsi.balanceOf(address(this));

        if (balance > requiredLiquidity) {
            // we have spare tokens we can stake
            // check if there is anything already maturing, to avoid reset the maturation clock
            uint256 maturing = staking.getMaturingBalance(address(this));
            if (maturing == 0) {
                // nothing is maturing, we can stake the balance, preserving the liquidity
                stake = balance - requiredLiquidity;
            }
        } else if (requiredLiquidity > balance) {
            // we don't have enough tokens to provide liquidity
            uint256 missingLiquidity = requiredLiquidity - balance;

            // let's first check releasing balance
            uint256 releasing = staking.getReleasingBalance(address(this));
            if (releasing > 0) {
                // some is already releasing

                // let's check timestamp to see if we can withdrawn it
                uint256 timestamp = staking.getReleasingTimestamp(
                    address(this)
                );
                if (timestamp < block.timestamp) {
                    // there it is, let's grab it
                    withdraw = releasing;
                }

                // requiredLiquidity may be more than what is already releasing
                // but we won't unstake more to not reset the clock
            } else {
                // no unstake maturing, let's queue some
                unstake = missingLiquidity;
            }
        } else {
            // balance is exactly required liquidity, we can't move any tokens around
        }
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/StakingPoolUser.sol";
import "./StakingPoolData.sol";

contract StakingPoolUserImpl is StakingPoolUser, StakingPoolData {
    IERC20 private immutable ctsi;
    uint256 public immutable lockTime;

    /// @dev Constructor
    /// @param _ctsi The contract that provides the staking pool's token
    /// @param _lockTime The user deposit lock period
    constructor(address _ctsi, uint256 _lockTime) {
        ctsi = IERC20(_ctsi);
        lockTime = _lockTime;
    }

    function deposit(uint256 _amount) external override whenNotPaused {
        // transfer tokens from caller to this contract
        // user must have approved the transfer a priori
        // tokens will be lying around, until actually staked by pool owner at a later time
        require(
            _amount > 0,
            "StakingPoolUserImpl: amount must be greater than 0"
        );

        // add tokens to user's balance
        UserBalance storage user = userBalance[msg.sender];
        user.balance += _amount;

        // reset deposit timestamp
        user.depositTimestamp = block.timestamp;

        // reserve the balance as required liquidity (don't stake to Staking)
        requiredLiquidity += _amount;

        require(
            ctsi.transferFrom(msg.sender, address(this), _amount),
            "StakingPoolUserImpl: failed to transfer tokens"
        );

        // emit event containing user and amount
        emit Deposit(msg.sender, _amount, block.timestamp + lockTime);
    }

    /// @notice Stake an amount of tokens, immediately earning pool shares in returns
    /// @param _amount amount of tokens to convert from user's balance
    function stake(uint256 _amount) external override whenNotPaused {
        // get user balance
        UserBalance storage user = userBalance[msg.sender];

        // transfer tokens from caller to this contract
        // user must have approved the transfer a priori
        // tokens will be lying around, until actually staked by pool owner at a later time
        require(
            _amount > 0,
            "StakingPoolUserImpl: amount must be greater than 0"
        );
        require(
            _amount <= user.balance,
            "StakingPoolUserImpl: not enough tokens available for staking"
        );

        // check if user can already stake or if it's too early
        require(
            block.timestamp >= user.depositTimestamp + lockTime,
            "StakingPoolUserImpl: not enough time has passed since last deposit"
        );

        // calculate amount of shares as of now
        uint256 _shares = amountToShares(_amount);

        // make sure he get at least one share (rounding errors)
        require(
            _shares > 0,
            "StakingPoolUserImpl: stake not enough to emit 1 share"
        );

        // allocate new shares to user, immediately
        user.shares += _shares;
        user.balance -= _amount;

        // increase total shares and amount (not changing share value)
        amount += _amount;
        shares += _shares;

        // remove from required liquidity, as it's moving to Staking
        requiredLiquidity -= _amount;

        // emit event containing user, amount, shares and unlock time
        emit Stake(msg.sender, _amount, _shares);
    }

    /// @notice allow for users to defined exactly how many shares they
    /// want to unstake. Estimated value is then emitted on Unstake event
    function unstake(uint256 _shares) external override {
        UserBalance storage user = userBalance[msg.sender];

        // check if shares is valid value
        require(_shares > 0, "StakingPoolUserImpl: invalid amount of shares");

        // check if user has enough shares to unstake
        require(
            user.shares >= _shares,
            "StakingPoolUserImpl: insufficient shares"
        );

        // reduce user number of shares
        user.shares -= _shares;

        // calculate amount of tokens from shares
        uint256 _amount = sharesToAmount(_shares);

        // reduce total shares and amount
        shares -= _shares;
        amount -= _amount;

        // add amount user can withdraw (if available)
        user.balance += _amount;

        // increase required liquidity
        requiredLiquidity += _amount;

        // emit event containing user, amount and shares
        emit Unstake(msg.sender, _amount, _shares);
    }

    /// @notice Transfer tokens back to calling user wallet
    /// @dev this will transfer all free tokens for the calling user
    function withdraw(uint256 _amount) external override {
        UserBalance storage user = userBalance[msg.sender];

        // check user released value
        require(
            user.balance > 0,
            "StakingPoolUserImpl: no balance to withdraw"
        );

        // clear user released value
        user.balance -= _amount; // if _amount >  user.balance this will revert

        // decrease required liquidity
        requiredLiquidity -= _amount; // if _amount >  requiredLiquidity this will revert

        // transfer token back to user
        require(
            ctsi.transfer(msg.sender, _amount),
            "StakingPoolUserImpl: failed to transfer tokens"
        );

        // emit event containing user and token amount
        emit Withdraw(msg.sender, _amount);
    }

    function getWithdrawBalance() external view override returns (uint256) {
        UserBalance storage user = userBalance[msg.sender];

        // get maximum amount user can withdraw (his balance)
        uint256 _amount = user.balance;

        // check contract balance
        uint256 balance = ctsi.balanceOf(address(this));

        // he can withdraw whatever is available at the contract, up to his balance
        return balance >= _amount ? _amount : balance;
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

import "@cartesi/pos/contracts/IWorkerManagerAuthManager.sol";
import "./interfaces/StakingPoolWorker.sol";
import "./StakingPoolData.sol";

contract StakingPoolWorkerImpl is StakingPoolWorker, StakingPoolData {
    IWorkerManagerAuthManager immutable workerManager;

    // all immutable variables can stay at the constructor
    constructor(address _workerManager) {
        require(
            _workerManager != address(0),
            "parameter can not be zero address"
        );
        workerManager = IWorkerManagerAuthManager(_workerManager);
    }

    receive() external payable {}

    function __StakingPoolWorkerImpl_update(address _pos) internal {
        workerManager.authorize(address(this), _pos);
        pos = IPoS(_pos);
    }

    /// @notice allows for the pool to act on its own behalf when producing blocks.
    function selfhire() external payable override {
        // pool needs to be both user and worker
        workerManager.hire{value: msg.value}(payable(address(this)));
        workerManager.authorize(address(this), address(pos));
        workerManager.acceptJob();
        payable(msg.sender).transfer(msg.value);
    }

    /// @notice Asks the worker to work for the sender. Sender needs to pay something.
    /// @param workerAddress address of the worker
    function hire(address payable workerAddress)
        external
        payable
        override
        onlyOwner
    {
        workerManager.hire{value: msg.value}(workerAddress);
        workerManager.authorize(workerAddress, address(pos));
    }

    /// @notice Called by the user to cancel a job offer
    /// @param workerAddress address of the worker node
    function cancelHire(address workerAddress) external override onlyOwner {
        workerManager.cancelHire(workerAddress);
    }

    /// @notice Called by the user to retire his worker.
    /// @param workerAddress address of the worker to be retired
    /// @dev this also removes all authorizations in place
    function retire(address payable workerAddress) external override onlyOwner {
        workerManager.retire(workerAddress);
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0 <0.9.0;

/// @title Calculator of pool owner commission for each block reward
/// @author Danilo Tuler
/// @notice This provides flexibility for different commission models
interface Fee {
    /// @notice calculates the total amount of the reward that will be directed to the pool owner
    /// @return amount of tokens taken by the pool owner as commission
    function getCommission(uint256 posIndex, uint256 rewardAmount)
        external
        view
        returns (uint256);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

import "./StakingPoolManagement.sol";
import "./StakingPoolProducer.sol";
import "./StakingPoolStaking.sol";
import "./StakingPoolUser.sol";
import "./StakingPoolWorker.sol";

/// @title Staking Pool interface
/// @author Danilo Tuler
/// @notice This interface aggregates all facets of a staking pool.
/// It is broken down into the following sub-interfaces:
/// - StakingPoolManagement: management operations on the pool, called by the owner
/// - StakingPoolProducer: operations related to block production
/// - StakingPoolStaking: interaction between the pool and the staking contract
/// - StakingPoolUser: interaction between the pool users and the pool
/// - StakingPoolWorker: interaction between the pool and the worker node
interface StakingPool is
    StakingPoolManagement,
    StakingPoolProducer,
    StakingPoolStaking,
    StakingPoolUser,
    StakingPoolWorker
{
    /// @notice initialize pool (from reference)
    function initialize(address fee, address _pos) external;

    /// @notice Transfer ownership of pool to its deployer
    function transferOwnership(address newOwner) external;

    /// @notice updates the internal settings for important pieces of the Cartesi PoS system
    function update() external;
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

interface StakingPoolFactory {
    /// @notice Creates a new staking pool using a flat commission model
    /// emits NewFlatRateCommissionStakingPool with the parameters of the new pool
    /// @return new pool address
    function createFlatRateCommission(uint256 commission)
        external
        payable
        returns (address);

    /// @notice Creates a new staking pool using a gas tax commission model
    /// emits NewGasTaxCommissionStakingPool with the parameters of the new pool
    /// @return new pool address
    function createGasTaxCommission(uint256 gas)
        external
        payable
        returns (address);

    /// @notice Returns configuration for the working pools of the current version
    /// @return _pos address for the PoS contract
    function getPoS() external view returns (address _pos);

    /// @notice Event emmited when a pool is created
    /// @param pool address of the new pool
    /// @param fee address of the commission contract
    event NewFlatRateCommissionStakingPool(address indexed pool, address fee);

    /// @notice Event emmited when a pool is created
    /// @param pool address of the new pool
    /// @param fee address of thhe commission contract
    event NewGasTaxCommissionStakingPool(address indexed pool, address fee);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

interface StakingPoolManagement {
    /// @notice sets a name for the pool using ENS service
    function setName(string memory name) external;

    /// @notice pauses new staking on the pool
    function pause() external;

    /// @notice unpauses new staking on the pool
    function unpause() external;

    /// @notice Event emmited when a pool is rename
    event StakingPoolRenamed(string name);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

/// @title Interaction between a pool and the PoS block production.
/// @author Danilo Tuler
/// @notice This interface provides an opportunity to handle the necessary logic
/// after a block is produced.
/// A commission is taken from the block reward, and the remaining stays in the pool,
/// raising the pool share value, and being further staked.
interface StakingPoolProducer {
    /// @notice routes produceBlock to POS contract and
    /// updates internal states of the pool
    /// @return true when everything went fine
    function produceBlock(uint256 _index) external returns (bool);

    /// @notice this event is emitted at every produceBlock call
    /// reward is the block reward
    /// commission is how much CTSI is directed to the pool owner
    event BlockProduced(uint256 reward, uint256 commission);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

/// @title Interaction between a pool and the staking contract
/// @author Danilo Tuler
/// @notice This interface models all interactions between a pool and the staking contract,
/// including staking, unstaking and withdrawing.
/// Tokens staked by pool users will stay at the pool until the pool owner decides to
/// stake them in the staking contract. On the other hand, tokens unstaked by pool users
/// are added to a required liquidity accumulator, and must be unstaked and withdrawn from
/// the staking contract.
interface StakingPoolStaking {
    /// @notice Move tokens from pool to staking or vice-versa, according to required liquidity.
    /// If the pool has more liquidity then necessary, it stakes tokens.
    /// If the pool has less liquidity then necessary, and has not started an unstake, it unstakes.
    /// If the pool has less liquity than necessary, and has started an unstake, it withdraws if possible.
    function rebalance() external;

    /// @notice provide information for offchain about the amount for each
    /// staking operation on the main Staking contract
    /// @return stake amount of tokens that can be staked
    /// @return unstake amount of tokens that must be unstaked to add liquidity
    /// @return withdraw amount of tokens that can be withdrawn to add liquidity
    function amounts()
        external
        view
        returns (
            uint256 stake,
            uint256 unstake,
            uint256 withdraw
        );
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

/// @title Interaction between a pool user and a pool
/// @author Danilo Tuler
/// @notice This interface models all interactions between a pool user and a pool,
/// including staking, unstaking and withdrawing. A pool user always holds pool shares.
/// When a user stakes tokens, he immediately receive shares. When he unstakes shares
/// he is asking to release tokens. Those tokens need to be withdrawn by an additional
/// call to withdraw()
interface StakingPoolUser {
    /// @notice Deposit tokens to user pool balance
    /// @param amount amount of token deposited in the pool
    function deposit(uint256 amount) external;

    /// @notice Stake an amount of tokens, immediately earning pool shares in returns
    /// @param amount amount of tokens to convert to shares
    function stake(uint256 amount) external;

    /// @notice Unstake an specified amount of shares of the calling user
    /// @dev Shares are immediately converted to tokens, and added to the pool liquidity requirement
    function unstake(uint256 shares) external;

    /// @notice Transfer tokens back to calling user wallet
    /// @dev this will transfer tokens from user pool account to user's wallet
    function withdraw(uint256 amount) external;

    /// @notice Returns the amount of tokens that can be immediately withdrawn by the calling user
    /// @dev there is no way to know the exact time in the future the requested tokens will be available
    /// @return the amount of tokens that can be immediately withdrawn by the calling user
    function getWithdrawBalance() external returns (uint256);

    /// @notice Tokens were deposited, available for staking or withdrawal
    /// @param user address of msg.sender
    /// @param amount amount of tokens deposited by the user
    /// @param stakeTimestamp instant when the amount can be staked
    event Deposit(address indexed user, uint256 amount, uint256 stakeTimestamp);

    /// @notice Tokens were deposited, they count as shares immediatly
    /// @param user address of msg.sender
    /// @param amount amount deposited by the user
    /// @param shares number of shares emitted for user
    event Stake(address indexed user, uint256 amount, uint256 shares);

    /// @notice Request to unstake tokens. Additional liquidity requested for the pool
    /// @param user address of msg.sender
    /// @param amount amount of tokens to be released
    /// @param shares number of shares being liquidated
    event Unstake(address indexed user, uint256 amount, uint256 shares);

    /// @notice Withdraw performed by a user
    /// @param user address of msg.sender
    /// @param amount amount of tokens withdrawn
    event Withdraw(address indexed user, uint256 amount);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

interface StakingPoolWorker {
    /// @notice allows for the pool to act on its own behalf when producing blocks.
    function selfhire() external payable;

    /// @notice Asks the worker to work for the sender. Sender needs to pay something.
    /// @param workerAddress address of the worker
    function hire(address payable workerAddress) external payable;

    /// @notice Called by the user to cancel a job offer
    /// @param workerAddress address of the worker node
    function cancelHire(address workerAddress) external;

    /// @notice Called by the user to retire his worker.
    /// @param workerAddress address of the worker to be retired
    /// @dev this also removes all authorizations in place
    function retire(address payable workerAddress) external;
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Wad and Ray Math library
/// @dev Math operations for wads (fixed point with 18 digits) and rays (fixed points with 27 digits)
pragma solidity ^0.8.0;

library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RATIO = 1e9;

    function wmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return ((WAD / 2) + (a * b)) / WAD;
    }

    function wdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;
        return (halfB + (a * WAD)) / b;
    }

    function rmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return ((RAY / 2) + (a * b)) / RAY;
    }

    function rdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;
        return (halfB + (a * RAY)) / b;
    }

    function ray2wad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = RATIO / 2;
        return (halfRatio + a) / RATIO;
    }

    function wad2ray(uint256 a) internal pure returns (uint256) {
        return a * RATIO;
    }
}

