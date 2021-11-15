// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title WorkerAuthManager
/// @author Danilo Tuler
pragma solidity >=0.7.0;

interface WorkerAuthManager {
    /// @notice Gives worker permission to act on a DApp
    /// @param _workerAddress address of the worker node to given permission
    /// @param _dappAddress address of the dapp that permission will be given to
    function authorize(address _workerAddress, address _dappAddress) external;

    /// @notice Removes worker's permission to act on a DApp
    /// @param _workerAddress address of the proxy that will lose permission
    /// @param _dappAddresses addresses of dapps that will lose permission
    function deauthorize(address _workerAddress, address _dappAddresses)
        external;

    /// @notice Returns is the dapp is authorized to be called by that worker
    /// @param _workerAddress address of the worker
    /// @param _dappAddress address of the DApp
    function isAuthorized(address _workerAddress, address _dappAddress)
        external
        view
        returns (bool);

    /// @notice Get the owner of the worker node
    /// @param workerAddress address of the worker node
    function getOwner(address workerAddress) external view returns (address);

    /// @notice A DApp has been authorized by a user for a worker
    event Authorization(
        address indexed user,
        address indexed worker,
        address indexed dapp
    );

    /// @notice A DApp has been deauthorized by a user for a worker
    event Deauthorization(
        address indexed user,
        address indexed worker,
        address indexed dapp
    );
}

// Copyright 2010 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title WorkerManager
/// @author Danilo Tuler
pragma solidity >=0.7.0;

interface WorkerManager {
    /// @notice Returns true if worker node is available
    /// @param workerAddress address of the worker node
    function isAvailable(address workerAddress) external view returns (bool);

    /// @notice Returns true if worker node is pending
    /// @param workerAddress address of the worker node
    function isPending(address workerAddress) external view returns (bool);

    /// @notice Get the owner of the worker node
    /// @param workerAddress address of the worker node
    function getOwner(address workerAddress) external view returns (address);

    /// @notice Get the user of the worker node, which may not be the owner yet, or how was the previous owner of a retired node
    function getUser(address workerAddress) external view returns (address);

    /// @notice Returns true if worker node is owned by some user
    function isOwned(address workerAddress) external view returns (bool);

    /// @notice Asks the worker to work for the sender. Sender needs to pay something.
    /// @param workerAddress address of the worker
    function hire(address payable workerAddress) external payable;

    /// @notice Called by the worker to accept the job
    function acceptJob() external;

    /// @notice Called by the worker to reject a job offer
    function rejectJob() external payable;

    /// @notice Called by the user to cancel a job offer
    /// @param workerAddress address of the worker node
    function cancelHire(address workerAddress) external;

    /// @notice Called by the user to retire his worker.
    /// @param workerAddress address of the worker to be retired
    /// @dev this also removes all authorizations in place
    function retire(address payable workerAddress) external;

    /// @notice Returns true if worker node was retired by its owner
    function isRetired(address workerAddress) external view returns (bool);

    /// @notice Events signalling every state transition
    event JobOffer(address indexed worker, address indexed user);
    event JobAccepted(address indexed worker, address indexed user);
    event JobRejected(address indexed worker, address indexed user);
    event Retired(address indexed worker, address indexed user);
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title WorkerManagerAuthManagerImpl
/// @author Danilo Tuler
pragma solidity ^0.8.0;

import "./WorkerManager.sol";
import "./WorkerAuthManager.sol";

contract WorkerManagerAuthManagerImpl is WorkerManager, WorkerAuthManager {
    /// @dev user can only hire a worker if he sends more than minimum value
    uint256 constant MINIMUM_FUNDING = 0.001 ether;

    /// @dev transfers bigger than maximum value should be done directly
    uint256 constant MAXIMUM_FUNDING = 3 ether;

    /// @notice A worker can be in 4 different states, starting from Available
    enum WorkerState {Available, Pending, Owned, Retired}

    /// @dev mapping from worker to its user
    mapping(address => address payable) private userOf;

    /// @dev mapping from worker to its internal state
    mapping(address => WorkerState) private stateOf;

    /// @dev permissions keyed by hash(user, worker, dapp)
    mapping(bytes32 => bool) private permissions;

    function isAvailable(address workerAddress)
        public
        override
        view
        returns (bool)
    {
        return stateOf[workerAddress] == WorkerState.Available;
    }

    function isPending(address workerAddress)
        public
        override
        view
        returns (bool)
    {
        return stateOf[workerAddress] == WorkerState.Pending;
    }

    function getOwner(address _workerAddress)
        public
        override(WorkerManager, WorkerAuthManager)
        view
        returns (address)
    {
        return
            stateOf[_workerAddress] == WorkerState.Owned
                ? userOf[_workerAddress]
                : address(0);
    }

    function getUser(address _workerAddress)
        public
        override
        view
        returns (address)
    {
        return userOf[_workerAddress];
    }

    function isOwned(address _workerAddress)
        public
        override
        view
        returns (bool)
    {
        return stateOf[_workerAddress] == WorkerState.Owned;
    }

    function hire(address payable _workerAddress) public override payable {
        require(isAvailable(_workerAddress), "worker is not available");
        require(_workerAddress != address(0), "worker address can not be 0x0");
        require(msg.value >= MINIMUM_FUNDING, "funding below minimum");
        require(msg.value <= MAXIMUM_FUNDING, "funding above maximum");

        // set owner
        userOf[_workerAddress] = payable(msg.sender);

        // change state
        stateOf[_workerAddress] = WorkerState.Pending;

        // transfer ether to worker
        _workerAddress.transfer(msg.value);

        // emit event
        emit JobOffer(_workerAddress, msg.sender);
    }

    function acceptJob() public override {
        require(
            stateOf[msg.sender] == WorkerState.Pending,
            "worker not is not in pending state"
        );

        // change state
        stateOf[msg.sender] = WorkerState.Owned;
        // from now on getOwner will return the user

        // emit event
        emit JobAccepted(msg.sender, userOf[msg.sender]);
    }

    function rejectJob() public override payable {
        require(
            userOf[msg.sender] != address(0),
            "worker does not have a job offer"
        );

        address payable owner = userOf[msg.sender];

        // reset hirer back to null
        userOf[msg.sender] = payable(address(0));

        // change state
        stateOf[msg.sender] = WorkerState.Available;

        // return the money
        owner.transfer(msg.value);

        // emit event
        emit JobRejected(msg.sender, userOf[msg.sender]);
    }

    function cancelHire(address _workerAddress) public override {
        require(
            userOf[_workerAddress] == msg.sender,
            "only hirer can cancel the offer"
        );

        // change state
        stateOf[_workerAddress] = WorkerState.Retired;

        // emit event
        emit JobRejected(_workerAddress, msg.sender);
    }

    function retire(address payable _workerAddress) public override {
        require(
            stateOf[_workerAddress] == WorkerState.Owned,
            "worker not owned"
        );
        require(
            userOf[_workerAddress] == msg.sender,
            "only owner can retire worker"
        );

        // change state
        stateOf[_workerAddress] = WorkerState.Retired;

        // emit event
        emit Retired(_workerAddress, msg.sender);
    }

    function isRetired(address _workerAddress)
        public
        override
        view
        returns (bool)
    {
        return stateOf[_workerAddress] == WorkerState.Retired;
    }

    modifier onlyByUser(address _workerAddress) {
        require(
            getUser(_workerAddress) == msg.sender,
            "worker not hired by sender"
        );
        _;
    }

    function getAuthorizationKey(
        address _user,
        address _worker,
        address _dapp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_user, _worker, _dapp));
    }

    function authorize(address _workerAddress, address _dappAddress)
        public
        override
        onlyByUser(_workerAddress)
    {
        bytes32 key = getAuthorizationKey(
            msg.sender,
            _workerAddress,
            _dappAddress
        );
        require(permissions[key] == false, "dapp already authorized");

        // record authorization from that user
        permissions[key] = true;

        // emit event
        emit Authorization(msg.sender, _workerAddress, _dappAddress);
    }

    function deauthorize(address _workerAddress, address _dappAddress)
        public
        override
        onlyByUser(_workerAddress)
    {
        bytes32 key = getAuthorizationKey(
            msg.sender,
            _workerAddress,
            _dappAddress
        );
        require(permissions[key] == true, "dapp not authorized");

        // record deauthorization from that user
        permissions[key] = false;

        // emit event
        emit Deauthorization(msg.sender, _workerAddress, _dappAddress);
    }

    function isAuthorized(address _workerAddress, address _dappAddress)
        public
        override
        view
        returns (bool)
    {
        return
            permissions[getAuthorizationKey(
                getOwner(_workerAddress),
                _workerAddress,
                _dappAddress
            )];
    }

    function hireAndAuthorize(
        address payable _workerAddress,
        address _dappAddress
    ) public payable {
        hire(_workerAddress);
        authorize(_workerAddress, _dappAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "./ENS.sol";

abstract contract NameResolver {
    function setName(bytes32 node, string memory name) public virtual;
}

contract ReverseRegistrar {
    // namehash('addr.reverse')
    bytes32 public constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    ENS public ens;
    NameResolver public defaultResolver;

    /**
     * @dev Constructor
     * @param ensAddr The address of the ENS registry.
     * @param resolverAddr The address of the default reverse resolver.
     */
    constructor(ENS ensAddr, NameResolver resolverAddr) public {
        ens = ensAddr;
        defaultResolver = resolverAddr;

        // Assign ownership of the reverse record to our deployer
        ReverseRegistrar oldRegistrar = ReverseRegistrar(ens.owner(ADDR_REVERSE_NODE));
        if (address(oldRegistrar) != address(0x0)) {
            oldRegistrar.claim(msg.sender);
        }
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @return The ENS node hash of the reverse record.
     */
    function claim(address owner) public returns (bytes32) {
        return claimWithResolver(owner, address(0x0));
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @param resolver The address of the resolver to set; 0 to leave unchanged.
     * @return The ENS node hash of the reverse record.
     */
    function claimWithResolver(address owner, address resolver) public returns (bytes32) {
        bytes32 label = sha3HexAddress(msg.sender);
        bytes32 node = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, label));
        address currentOwner = ens.owner(node);

        // Update the resolver if required
        if (resolver != address(0x0) && resolver != ens.resolver(node)) {
            // Transfer the name to us first if it's not already
            if (currentOwner != address(this)) {
                ens.setSubnodeOwner(ADDR_REVERSE_NODE, label, address(this));
                currentOwner = address(this);
            }
            ens.setResolver(node, resolver);
        }

        // Update the owner if required
        if (currentOwner != owner) {
            ens.setSubnodeOwner(ADDR_REVERSE_NODE, label, owner);
        }

        return node;
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the calling account. First updates the resolver to the default reverse
     * resolver if necessary.
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setName(string memory name) public returns (bytes32) {
        bytes32 node = claimWithResolver(address(this), address(defaultResolver));
        defaultResolver.setName(node, name);
        return node;
    }

    /**
     * @dev Returns the node hash for a given account's reverse records.
     * @param addr The address to hash
     * @return The ENS node hash.
     */
    function node(address addr) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr)));
    }

    /**
     * @dev An optimised function to compute the sha3 of the lower-case
     *      hexadecimal representation of an Ethereum address.
     * @param addr The address to hash
     * @return ret The SHA3 hash of the lower-case hexadecimal encoding of the
     *         input address.
     */
    function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
        addr;
        ret; // Stop warning us about unused variables
        assembly {
            let lookup := 0x3031323334353637383961626364656600000000000000000000000000000000

            for { let i := 40 } gt(i, 0) { } {
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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
    constructor () {
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

/// @title Interface staking contract
pragma solidity ^0.8.0;

interface Fee {
    /// @notice calculates the total amount of the reward that will be directed to the PoolManager
    /// @return commissionTotal is the amount subtracted from the rewardAmount
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

/// @title Interface staking contract
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "./Fee.sol";

contract FlatRateCommission is Fee, Ownable {
    uint256 public BASE = 1E4;
    uint256 public rate;

    /// @notice Event emmited when a contract is created
    /// @param commission commission charged by the pool
    event FlatRateCommissionCreated(uint256 commission);

    /// @notice event fired when setRate function is called and successful
    event FlatRateChanged(uint256 newRate);

    constructor(uint256 _rate) {
        rate = _rate;
        emit FlatRateChanged(_rate);
    }

    /// @notice calculates the total amount of the reward that will be directed to the PoolManager
    /// @return commissionTotal is the amount subtracted from the rewardAmount
    function getCommission(uint256, uint256 rewardAmount)
        external
        view
        override
        returns (uint256)
    {
        return (rewardAmount * rate) / BASE;
    }

    /// @notice allows for the poolManager to reduce how much they want to charge for the block production tx
    function setRate(uint256 newRate) external onlyOwner {
        require(
            newRate < rate,
            "newRate needs to be strictly smaller than current rate."
        );
        rate = newRate;
        emit FlatRateChanged(newRate);
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

/// @title Interface staking contract
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "./Fee.sol";

contract GasTaxCommission is Fee, Ownable {
    AggregatorInterface public immutable gasOracle;

    IUniswapV2Pair public immutable priceOracle;

    uint256 public gas;

    /// @notice event fired when setGas function is called and successful
    event GasTaxChanged(uint256 newGas);

    constructor(
        address _chainlinkOracle,
        address _uniswapOracle,
        uint256 _gas
    ) {
        gasOracle = AggregatorInterface(_chainlinkOracle);
        priceOracle = IUniswapV2Pair(_uniswapOracle);
        gas = _gas;
        emit GasTaxChanged(_gas);
    }

    /// @notice calculates the total amount of the reward that will be directed to the PoolManager
    /// @return commissionTotal is the amount subtracted from the rewardAmount
    function getCommission(uint256, uint256 rewardAmount)
        external
        view
        override
        returns (uint256)
    {
        // get gas price from chainlink oracle
        // https://data.chain.link/fast-gas-gwei#operator-chainlayer
        uint256 gasPrice = uint256(gasOracle.latestAnswer());

        // gas fee (in ETH) charged by pool manager
        uint256 gasFee = gasPrice * gas;

        // get CTSI/ETH reserves
        (uint112 reserveCTSI, uint112 reserveETH, uint32 _blockTimestampLast) =
            priceOracle.getReserves();

        // convert gas in ETH to gas in CTSI

        // if there is no ETH reserve, we can't calculate
        if (reserveETH == 0) {
            return 0;
        }
        uint256 gasFeeCTSI = (gasFee * reserveCTSI) / reserveETH;

        // this is the commission, maxed by the reward
        return gasFeeCTSI > rewardAmount ? rewardAmount : gasFeeCTSI;
    }

    /// @notice allows for the poolManager to reduce how much they want to charge for the block production tx
    function setGas(uint256 newGasCommission) external onlyOwner {
        require(
            newGasCommission < gas,
            "newGasCommission needs to be strictly smaller than the current value."
        );
        gas = newGasCommission;
        emit GasTaxChanged(newGasCommission);
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

/// @title Interface staking contract
pragma solidity ^0.8.0;

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

/// @title Interface staking contract
pragma solidity ^0.8.0;

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

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface staking contract
pragma solidity >=0.7.0 <=0.8.4;

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

/// @title Interface staking contract
pragma solidity ^0.8.0;

import "./IStaking.sol";
import "./StakingPoolManagement.sol";

interface StakingPool is IStaking, StakingPoolManagement {
    ///@notice this events is emitted at every produceBlock call
    ///     reward is the block reward
    ///     commission is how much CTSI is directed to the poolManager
    ///     queued is how much currently is being queued to be staked
    ///     notStaked is how much is directed to withdrawal
    event BlockProduced(
        uint256 reward,
        uint256 commission,
        uint256 queued,
        uint256 notStaked
    );

    /// @notice routes produceBlock to POS contract and
    /// updates internal states of the pool
    /// @return true when everything went fine
    function produceBlock(uint256 _index) external returns (bool);

    /// @notice enables pool manager to update staking balances as they mature
    /// on the (main) Staking contract
    function cycleStakeMaturation() external;

    /// @notice enables pool manager to update releasing balances as they get freed
    /// on the (main) Staking contract
    function cycleWithdrawRelease() external;

    /// @notice checks whether or not a call can be made to cycleStakeMaturation
    /// and be successful
    /// @return available true if cycleStakeMaturation can bee called
    ///                   false if it can not
    ///         _currentQueuedTotal how much is waiting to be staked
    function canCycleStakeMaturation()
        external
        view
        returns (bool available, uint256 _currentQueuedTotal, uint256 _currentMaturingTotal);

    /// @notice checks whether or not a call can be made to cycleWithdrawRelease
    /// and be successful
    /// @return available true if cycleWithdrawRelease can bee called
    ///                   false if it can not
    ///         _totalToUnstakeValue how much is waiting to be unstaked
    function canCycleWithdrawRelease()
        external
        view
        returns (bool available, uint256 _totalToUnstakeValue, uint256 _totalUnstaking);
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

/// @title Interface staking contract
pragma solidity ^0.8.0;

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

/// @title Interface staking contract
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/proxy/Clones.sol";
import "@openzeppelin/contracts-0.8/security/Pausable.sol";
import "./StakingPoolFactory.sol";
import "./StakingPoolImpl.sol";
import "./FlatRateCommission.sol";
import "./GasTaxCommission.sol";

contract StakingPoolFactoryImpl is Ownable, Pausable, StakingPoolFactory {
    address public immutable poolImplementationReference;
    address public immutable chainlinkOracle;
    address public immutable uniswapOracle;

    constructor(
        address _referencePool,
        address _chainlinkOracle,
        address _uniswapOracle
    ) {
        require(
            _referencePool != address(0),
            "parameter can not be zero address."
        );
        require(
            _chainlinkOracle != address(0),
            "parameter can not be zero address."
        );
        require(
            _uniswapOracle != address(0),
            "parameter can not be zero address."
        );
        poolImplementationReference = _referencePool;
        chainlinkOracle = _chainlinkOracle;
        uniswapOracle = _uniswapOracle;
    }

    /// @notice Creates a new staking pool
    /// emits NewStakingPool with the parameters of the new pool
    /// @return new pool address
    function createFlatRateCommission(uint256 commission)
        public
        payable
        override
        whenNotPaused
        returns (address)
    {
        FlatRateCommission fee = new FlatRateCommission(commission);
        address payable deployed =
            payable(Clones.clone(poolImplementationReference));
        StakingPoolImpl pool = StakingPoolImpl(deployed);
        pool.initialize(address(fee), msg.sender);
        fee.transferOwnership(msg.sender);
        pool.selfhire{value: msg.value}();

        emit NewFlatRateCommissionStakingPool(address(pool), address(fee));
        return address(pool);
    }

    function createGasTaxCommission(uint256 gas)
        public
        payable
        override
        whenNotPaused
        returns (address)
    {
        GasTaxCommission fee =
            new GasTaxCommission(chainlinkOracle, uniswapOracle, gas);
        address payable deployed =
            payable(Clones.clone(poolImplementationReference));
        StakingPoolImpl pool = StakingPoolImpl(deployed);
        pool.initialize(address(fee), msg.sender);
        fee.transferOwnership(msg.sender);
        pool.selfhire{value: msg.value}();

        emit NewGasTaxCommissionStakingPool(address(pool), address(fee));
        return address(pool);
    }

    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
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

/// @title Interface staking contract
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "./IStaking.sol";
import "./StakingPool.sol";
import "./IRewardManager.sol";
import "./Fee.sol";
import "./StakingPoolManagementImpl.sol";

contract StakingPoolImpl is StakingPool, StakingPoolManagementImpl {
    IERC20 public immutable ctsi;
    IStaking public immutable staking;

    Fee public fee;
    uint256 public rewardQueued;
    uint256 public rewardNotStaked;
    uint256 public rewardMaturing;
    uint256 public currentStakeEpoch;
    uint256 public currentUnstakeEpoch;

    uint256 public immutable timeToStake;
    uint256 public immutable timeToRelease;

    struct StakingVoucher {
        uint256 amountQueued;
        uint256 amountStaked;
        uint256 queueEpoch;
    }

    struct UnstakingVoucher {
        uint256 poolShares;
        uint256 queueEpoch;
    }

    struct UserBalance {
        // @TODO improve state usage reducing variable sizes
        uint256 stakedPoolShares;
        StakingVoucher stakingVoucher;
        UnstakingVoucher unstakingVoucher;
    }
    mapping(address => UserBalance) public userBalance;
    uint256 public immutable FIXED_POINT_DECIMALS = 10E5; //@DEV is this enough zero/precision?
    // this gets updated on every reward income
    uint256[] public stakingVoucherValueAtEpoch; // correction factor for balances outdated by new rewards
    uint256 public currentQueuedTotal; // next cycle staking amout
    uint256 public currentMaturingTotal; // current cycle staking maturing
    uint256 public totalStaked; // "same as" StakeImp.getStakedBalance(this)
    uint256 public totalStakedShares;
    // this tracks the ratio of balances to actual CTSI value
    // withdraw related variables
    uint256 public totalToUnstakeShares; // next withdraw cycle unstake amount
    uint256 public totalUnstaking; // current withdraw cycle unstaking amount
    uint256 public totalWithdrawable; // ready to withdraw user balances
    uint256 public totalUnstakedShares; // tracks shares balances

    // all immutable variables can stay at the constructor
    constructor(
        address _ctsi,
        address _staking,
        address _pos,
        uint256 _timeToStake,
        uint256 _timeToRelease,
        address _ens,
        address _workerManager
    ) StakingPoolManagementImpl(_ens, _workerManager, _pos) {
        require(_ctsi != address(0), "parameter can not be zero address");
        require(_staking != address(0), "parameter can not be zero address");

        ctsi = IERC20(_ctsi);
        staking = IStaking(_staking);
        timeToStake = _timeToStake;
        timeToRelease = _timeToRelease;
    }

    function initialize(address _feeAddress, address owner) public initializer {
        super.initialize(owner);
        require(
            ctsi.approve(address(staking), type(uint256).max),
            "Failed to approve CTSI for staking contract"
        );
        fee = Fee(_feeAddress);
    }

    /// @notice Returns total amount of tokens counted as stake
    /// @param _userAddress user to retrieve staked balance from
    /// @return stakedBalance is the finalized staked of _userAddress
    function getStakedBalance(address _userAddress)
        external
        view
        override
        returns (uint256 stakedBalance)
    {
        UserBalance storage b = userBalance[_userAddress];
        uint256 shares = _getUserMaturatedShares(b.stakingVoucher);
        uint256 withdrawBalance;
        uint256 stakedValue = 0;
        // since it didn't call staking.unstake() yet, it's balance still counts for reward
        if (b.unstakingVoucher.queueEpoch < currentUnstakeEpoch)
            withdrawBalance = b.unstakingVoucher.poolShares;
        if (totalStakedShares > 0) {
            shares += b.stakedPoolShares - withdrawBalance;
            stakedValue = _getStakedSharesInValue(shares);
        }
        if (staking.getMaturingTimestamp(address(this)) < block.timestamp) {
            // effectively 1 cycle has passed and we didn't compute yet
            uint256 _currentStakeEpoch = currentStakeEpoch + 1;
            if (b.stakingVoucher.queueEpoch + 1 == _currentStakeEpoch) {
                stakedValue += b.stakingVoucher.amountStaked;
            } else if (b.stakingVoucher.queueEpoch + 2 == _currentStakeEpoch) {
                stakedValue += b.stakingVoucher.amountQueued;
            }
        }

        return stakedValue;
    }

    /// @notice Returns the timestamp when next deposit can be finalized
    /// @return timestamp of when cycleStakeMaturation() is callable
    function getMaturingTimestamp(address _userAddress)
        external
        view
        override
        returns (uint256)
    {
        if (
            userBalance[_userAddress].stakingVoucher.queueEpoch + 1 ==
            currentStakeEpoch
        ) return staking.getMaturingTimestamp(address(this));
        if (
            userBalance[_userAddress].stakingVoucher.queueEpoch ==
            currentStakeEpoch
        ) return staking.getMaturingTimestamp(address(this)) + timeToStake;
        return 0;
    }

    /// @notice Returns the timestamp when next withdraw can be finalized
    /// @return timestamp of when withdraw() is callable
    function getReleasingTimestamp(address _userAddress)
        external
        view
        override
        returns (uint256)
    {
        uint256 wEpoch = userBalance[_userAddress].unstakingVoucher.queueEpoch;
        if (wEpoch + 1 == currentUnstakeEpoch) {
            return staking.getReleasingTimestamp(address(this));
        } else if (
            staking.getReleasingBalance(address(this)) > 0 &&
            wEpoch == currentUnstakeEpoch
        ) {
            return staking.getReleasingTimestamp(address(this)) + timeToRelease;
        } else if (wEpoch == currentUnstakeEpoch) {
            return block.timestamp + timeToRelease;
        }
        return 0;
    }

    /// @notice Returns the balance waiting/ready to be matured
    /// @return amount that will get staked after finalization
    function getMaturingBalance(address _userAddress)
        external
        view
        override
        returns (uint256)
    {
        UserBalance storage b = userBalance[_userAddress];
        uint256 maturingBalance = 0;
        uint256 _currentStakeEpoch = currentStakeEpoch;
        if (staking.getMaturingTimestamp(address(this)) < block.timestamp)
            _currentStakeEpoch++;
        // if more than one cycle has passed for amountStaked then it's vested already
        if (b.stakingVoucher.queueEpoch + 1 > _currentStakeEpoch)
            maturingBalance += b.stakingVoucher.amountStaked;
        // if more than 2 cycles has passed for amountQueued then it's vested already
        if (b.stakingVoucher.queueEpoch + 2 > _currentStakeEpoch)
            maturingBalance += b.stakingVoucher.amountQueued;
        return maturingBalance;
    }

    /// @notice Returns the balance waiting/ready to be released
    /// @return amount that will get withdrawn after finalization
    function getReleasingBalance(address _userAddress)
        external
        view
        override
        returns (uint256)
    {
        UnstakingVoucher storage voucher =
            userBalance[_userAddress].unstakingVoucher;
        // releasing balance still was not unstaked on IStaking
        if (voucher.queueEpoch == currentUnstakeEpoch && totalStakedShares != 0)
            return _getStakedSharesInValue(voucher.poolShares);

        // releasing(ed) balance was unstaked on IStaking
        if (
            voucher.queueEpoch + 1 <= currentUnstakeEpoch &&
            totalUnstakedShares != 0
        ) return _getUnstakedSharesInValue(voucher.poolShares);
        // avoid division by zero in some scenarios
        return 0;
    }

    /// @notice Deposit CTSI to be staked. The money will turn into staked
    ///         balance after timeToStake days
    /// @param _amount The amount of tokens that are gonna be additionally deposited.
    function stake(uint256 _amount) external override whenNotPaused {
        require(
            ctsi.transferFrom(msg.sender, address(this), _amount),
            "Allowance of CTSI tokens not enough to match amount sent"
        );
        _stakeUpdates(msg.sender, _amount);
    }

    /// @notice routes produceBlock to POS contract and
    /// updates internal states of the pool
    /// @return true when everything went fine
    function produceBlock(uint256 _index) external override returns (bool) {
        bool isLastStakeCycleOver =
            staking.getMaturingTimestamp(address(this)) <= block.timestamp;
        if (isLastStakeCycleOver) computeFinishedStake();

        uint256 reward =
            IRewardManager(pos.getRewardManagerAddress(_index))
                .getCurrentReward();

        pos.produceBlock(_index);

        uint256 commission = fee.getCommission(_index, reward);
        _stakeUpdates(owner(), commission); // directs the commission to the pool manager

        uint256 remainingReward = reward - commission; // this is also a safety check
        // if commission is over the reward amount, it will underflow

        // we first route rewards related to unstakingShares to withdrawal
        // then we add the rest to the staking queue
        uint256 additionalRewardsWithdrawal =
            _calcUnstakingRewards(remainingReward + rewardQueued);
        rewardNotStaked += additionalRewardsWithdrawal;

        // update the possible remaining reward to be staked
        rewardQueued =
            (remainingReward + rewardQueued) -
            additionalRewardsWithdrawal;

        emit BlockProduced(reward, commission, rewardQueued, rewardNotStaked);

        if (isLastStakeCycleOver) startNewStakeCycle();
        cycleWithdrawRelease();
        return true;
    }

    /// @notice Remove tokens from staked balance. The money can
    ///         be released after timeToRelease seconds, if the
    ///         function withdraw is called.
    /// @param _amount The amount of tokens that are gonna be unstaked.
    function unstake(uint256 _amount) external override {
        UserBalance storage user = userBalance[msg.sender];
        require(
            user.unstakingVoucher.poolShares == 0 ||
                user.unstakingVoucher.queueEpoch == currentUnstakeEpoch,
            "You have withdraw being processed"
        );

        _updateUserBalances(msg.sender); // makes sure balances are updated to shares

        uint256 _amountInShares = _getStakedValueInShares(_amount);
        require(_amountInShares > 0, "there are no shares to be unstaked");
        user.unstakingVoucher.poolShares += _amountInShares;

        require(
            user.stakedPoolShares >= user.unstakingVoucher.poolShares,
            "Unstake amount is over staked balance"
        );

        totalToUnstakeShares += _amountInShares;
        user.unstakingVoucher.queueEpoch = currentUnstakeEpoch;

        uint256 releaseTimestamp;
        if (staking.getReleasingBalance(address(this)) > 0)
            releaseTimestamp = staking.getReleasingTimestamp(address(this));
        else {
            releaseTimestamp = block.timestamp;
        }

        emit Unstake(msg.sender, _amount, releaseTimestamp + timeToRelease);
    }

    /// @notice Transfer tokens to user's wallet.
    /// @param _amount The amount of tokens that are gonna be transferred.
    function withdraw(uint256 _amount) external override {
        UserBalance storage user = userBalance[msg.sender];
        require(
            user.unstakingVoucher.poolShares > 0 &&
                user.unstakingVoucher.queueEpoch + 2 <= currentUnstakeEpoch,
            "You don't have realeased balance"
        );
        _updateUserBalances(msg.sender); // makes sure balances are updated to matured
        uint256 shares = _getUnstakedValueInShares(_amount);
        require(
            user.unstakingVoucher.poolShares >= shares,
            "Not enough balance for this withdraw amount"
        );
        user.unstakingVoucher.poolShares -= shares;
        user.stakedPoolShares -= shares;

        totalWithdrawable -= _amount;
        totalUnstakedShares -= shares;
        ctsi.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function _calcUnstakingRewards(uint256 rewards)
        internal
        view
        returns (uint256)
    {
        // @dev review this function when totalStakedShares is Zero.
        // total value related to totalStakedShares
        uint256 totalAccumulatedValue =
            totalStaked + rewardMaturing + rewardNotStaked + rewards;
        // value that will be made available to withdraw in the next full withdraw cycle
        uint256 totalToUnstakeValue =
            (totalToUnstakeShares * totalAccumulatedValue) / totalStakedShares;
        // additional value related to current rewards yet to be set aside
        uint256 toUnstakeValueNotAccounted =
            totalToUnstakeValue - rewardNotStaked;
        if (rewards > toUnstakeValueNotAccounted)
            return toUnstakeValueNotAccounted;
        return rewards; // all this reward will be added to rewardNotStaked
    }

    function _calcValueAtEpoch() internal view returns (uint256) {
        // first time weight is 1
        if (currentStakeEpoch == 1) {
            return FIXED_POINT_DECIMALS;
        }
        // the `ValueAtEpoch` factor is the same as 1 unit of value in shares
        return _getStakedValueInShares(1);
    }

    function _calcTotalShares(uint256 valueAtEpoch)
        internal
        view
        returns (uint256)
    {
        // rewards do not count shares, so we subtract them
        uint256 newStakedValue = currentMaturingTotal - rewardMaturing;
        uint256 additionalShares = newStakedValue * valueAtEpoch;
        return totalStakedShares + additionalShares;
    }

    /// @notice called when a stake is matured in StakeImpl
    /// updating internal state related to it
    function computeFinishedStake() internal {
        if (currentStakeEpoch >= 1) {
            uint256 _valueAtEpoch = _calcValueAtEpoch();
            totalStakedShares = _calcTotalShares(_valueAtEpoch);
            stakingVoucherValueAtEpoch.push(_valueAtEpoch);
            totalStaked = totalStaked + currentMaturingTotal;
            // now we add this because we migth have intermediate
            // calculations that use this state var
            currentMaturingTotal = 0;
        }
    }

    /// @notice called after the finish of cycle
    /// to start with a new stake and reset global state vars
    function startNewStakeCycle() internal {
        currentMaturingTotal = currentQueuedTotal + rewardQueued;
        if (currentMaturingTotal != 0) staking.stake(currentMaturingTotal);
        rewardMaturing = rewardQueued;
        rewardQueued = 0;
        currentQueuedTotal = 0;
        currentStakeEpoch++;
    }

    /// @notice enables pool manager to update staking balances as they mature
    /// on the (main) Staking contract
    function cycleStakeMaturation() public override {
        bool isLastStakeCycleOver =
            staking.getMaturingTimestamp(address(this)) <= block.timestamp;
        if (!isLastStakeCycleOver) return;
        computeFinishedStake();
        startNewStakeCycle();
    }

    /// @notice enables pool manager to update staking balances as they mature
    /// on the (main) Staking contract
    function cycleWithdrawRelease() public override {
        uint256 releasingBalance = staking.getReleasingBalance(address(this));
        if (
            releasingBalance > 0 &&
            staking.getReleasingTimestamp(address(this)) > block.timestamp
        ) return; // last release cycle hasn't finished

        if (totalToUnstakeShares == 0 && totalUnstaking == 0) return; // nothing to do

        // withdraw everything to this contract before reseting the clock
        if (releasingBalance > 0) staking.withdraw(releasingBalance);

        uint256 totalToUnstake = 0;
        if (totalToUnstakeShares > 0) {
            totalToUnstake =
                _getStakedSharesInValue(totalToUnstakeShares) -
                rewardNotStaked;
            if (totalToUnstake > 0) {
                staking.unstake(totalToUnstake);
                totalStaked = totalStaked - totalToUnstake;
            }
        }

        // reset the cycle
        totalStakedShares -= totalToUnstakeShares;
        totalUnstakedShares += totalToUnstakeShares;
        totalToUnstakeShares = 0;
        totalWithdrawable += totalUnstaking + rewardNotStaked;
        rewardNotStaked = 0;
        totalUnstaking = totalToUnstake;
        currentUnstakeEpoch += 1;
    }

    /// @notice this function updates stale balance structure for a user
    /// it has basically 2 scenarios: user is staking since 1 epoch
    /// or it's staking since 2 or more epochs
    function _updateUserBalances(address _user) internal {
        UserBalance storage user = userBalance[_user];
        uint256 userLastUpdateEpoch = user.stakingVoucher.queueEpoch;
        if (
            (user.stakingVoucher.amountQueued == 0 &&
                user.stakingVoucher.amountStaked == 0) ||
            userLastUpdateEpoch == currentStakeEpoch
        ) return; // nothing to do; all up-to-date

        user.stakedPoolShares += _getUserMaturatedShares(user.stakingVoucher);
        // checks for any outdated balances
        if (userLastUpdateEpoch + 1 == currentStakeEpoch) {
            user.stakingVoucher.amountStaked = user.stakingVoucher.amountQueued;
            user.stakingVoucher.amountQueued = 0;
            user.stakingVoucher.queueEpoch = currentStakeEpoch;
        } else if (userLastUpdateEpoch + 2 <= currentStakeEpoch) {
            user.stakingVoucher.amountStaked = 0;
            user.stakingVoucher.amountQueued = 0;
        }
    }

    function _stakeUpdates(address user, uint256 _amount) internal {
        _updateUserBalances(user);

        userBalance[user].stakingVoucher.amountQueued =
            userBalance[user].stakingVoucher.amountQueued +
            _amount;
        userBalance[user].stakingVoucher.queueEpoch = currentStakeEpoch;

        currentQueuedTotal = currentQueuedTotal + _amount;

        emit Stake(
            user,
            _amount,
            staking.getMaturingTimestamp(address(this)) + timeToStake
        );
    }

    function _getStakedValueInShares(uint256 value)
        internal
        view
        returns (uint256 shares)
    {
        uint256 rewardsNotStaked =
            rewardMaturing + rewardQueued + rewardNotStaked;
        // total value related to totalStakedShares
        uint256 totalAccumulatedValue = totalStaked + rewardsNotStaked;
        if (totalAccumulatedValue == 0) return 0;
        return (value * totalStakedShares) / totalAccumulatedValue;
    }

    function _getStakedSharesInValue(uint256 shares)
        internal
        view
        returns (uint256 value)
    {
        if (totalStakedShares == 0) return 0;
        uint256 rewardsNotStaked =
            rewardMaturing + rewardNotStaked + rewardQueued;
        // total value related to totalStakedShares
        uint256 totalAccumulatedValue = totalStaked + rewardsNotStaked;
        return (shares * totalAccumulatedValue) / totalStakedShares;
    }

    function _getUnstakedSharesInValue(uint256 shares)
        internal
        view
        returns (uint256 value)
    {
        if (totalUnstakedShares == 0) return 0;
        // total value related to totalUnstakedShares
        uint256 totalAccumulatedValue = totalUnstaking + totalWithdrawable;
        return (shares * totalAccumulatedValue) / totalUnstakedShares;
    }

    function _getUnstakedValueInShares(uint256 value)
        internal
        view
        returns (uint256 shares)
    {
        // total value related to totalUnstakedShares
        uint256 totalAccumulatedValue = totalUnstaking + totalWithdrawable;
        if (totalAccumulatedValue == 0) return 0;
        return (value * totalUnstakedShares) / totalAccumulatedValue;
    }

    function _getUserMaturatedShares(StakingVoucher storage v)
        internal
        view
        returns (uint256 shares)
    {
        // check whether any balance under 'amountQueued' is already mature
        if (v.queueEpoch + 2 <= currentStakeEpoch) {
            shares = v.amountQueued * stakingVoucherValueAtEpoch[v.queueEpoch];
        }
        // check whether any balance under 'amountStaked' is already mature
        if (v.queueEpoch > 0 && v.queueEpoch + 1 <= currentStakeEpoch) {
            shares +=
                v.amountStaked *
                stakingVoucherValueAtEpoch[v.queueEpoch - 1];
        }
    }

    function canCycleStakeMaturation()
        external
        view
        override
        returns (
            bool available,
            uint256 _currentQueuedTotal,
            uint256 _currentMaturingTotal
        )
    {
        if (staking.getMaturingTimestamp(address(this)) > block.timestamp)
            return (false, currentQueuedTotal, currentMaturingTotal);
        return (true, currentQueuedTotal, currentMaturingTotal);
    }

    function canCycleWithdrawRelease()
        external
        view
        override
        returns (
            bool available,
            uint256 _totalToUnstakeValue,
            uint256 _totalUnstaking
        )
    {
        _totalToUnstakeValue = _getStakedSharesInValue(totalToUnstakeShares);
        if (
            staking.getReleasingBalance(address(this)) > 0 &&
            staking.getReleasingTimestamp(address(this)) > block.timestamp
        ) return (false, _totalToUnstakeValue, totalUnstaking);
        return (true, _totalToUnstakeValue, totalUnstaking);
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

/// @title Interface staking contract
pragma solidity ^0.8.0;

interface StakingPoolManagement {
    /// @notice sets a name for the pool using ENS service
    function setName(string memory name) external;

    /// @notice pauses new staking on the pool
    function pause() external;

    /// @notice unpauses new staking on the pool
    function unpause() external;

    /// @notice Event emmited when a pool is rename
    event StakingPoolRenamed(string name);

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

/// @title Interface staking contract
pragma solidity ^0.8.0;

import "@ensdomains/ens/contracts/ReverseRegistrar.sol";
import "@ensdomains/ens/contracts/ENS.sol";
import "@cartesi/util-0.8/contracts/WorkerManagerAuthManagerImpl.sol";
import "@openzeppelin/contracts-0.8/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-0.8/security/Pausable.sol";

import "./StakingPoolManagement.sol";
import "./IPoS.sol";

contract StakingPoolManagementImpl is
    StakingPoolManagement,
    Initializable,
    Pausable
{
    bytes32 private constant ADDR_REVERSE_NODE =
        0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    ENS public immutable ens;
    IPoS public immutable pos;

    WorkerManagerAuthManagerImpl public immutable workerManager;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    address private _owner;

    // all immutable variables can stay at the constructor
    constructor(
        address _ens,
        address _workerManager,
        address _pos
    ) {
        require(_ens != address(0), "parameter can not be zero address");
        require(
            _workerManager != address(0),
            "parameter can not be zero address"
        );
        require(_pos != address(0), "parameter can not be zero address");

        ens = ENS(_ens);
        workerManager = WorkerManagerAuthManagerImpl(_workerManager);
        pos = IPoS(_pos);
        // make sure reference code is pause so noone stake to it
        initialize(address(0));
        _pause();
    }

    function initialize(address ownerSender) internal initializer {
        _owner = ownerSender;
        emit OwnershipTransferred(address(0), ownerSender);
    }

    receive() external payable {}

    /// @notice sets a name for the pool using ENS service
    function setName(string memory name) external override onlyOwner {
        ReverseRegistrar ensReverseRegistrar =
            ReverseRegistrar(ens.owner(ADDR_REVERSE_NODE));

        // call the ENS reverse registrar resolving pool address to name
        ensReverseRegistrar.setName(name);

        // emit event, for subgraph processing
        emit StakingPoolRenamed(name);
    }

    /// @notice pauses new staking on the pool
    function pause() public override onlyOwner {
        _pause();
    }

    /// @notice unpauses new staking on the pool
    function unpause() external override onlyOwner {
        _unpause();
    }

    /// @notice allows for the pool to act on its own behalf when producing blocks.
    function selfhire() external payable override {
        // pool needs to be both user and worker
        workerManager.hire{value: msg.value}(payable(address(this)));
        workerManager.authorize(address(this), address(pos));
        workerManager.acceptJob();
        payable(_owner).transfer(msg.value);
    }

    /// @notice Asks the worker to work for the sender. Sender needs to pay something.
    /// @param workerAddress address of the worker
    function hire(address payable workerAddress) external payable override {
        workerManager.hire{value: msg.value}(workerAddress);
        workerManager.authorize(workerAddress, address(pos));
    }

    /// @notice Called by the user to cancel a job offer
    /// @param workerAddress address of the worker node
    function cancelHire(address workerAddress) external override {
        workerManager.cancelHire(workerAddress);
    }

    /// @notice Called by the user to retire his worker.
    /// @param workerAddress address of the worker to be retired
    /// @dev this also removes all authorizations in place
    function retire(address payable workerAddress) external override {
        workerManager.retire(workerAddress);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
}

