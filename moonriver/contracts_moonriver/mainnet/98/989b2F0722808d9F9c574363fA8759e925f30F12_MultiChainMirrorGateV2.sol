// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import "./multichain/IAnyswapV6CallProxy.sol";
import "./multichain/IApp.sol";

struct LockedBalance {
    int128 amount;
    uint256 end;
}

struct MirroredChain {
    uint256 chain_id;
    uint256 escrow_count;
}

interface IVotingEscrow {
    function locked(address _user) external view returns(LockedBalance memory);
}

interface IMirroredVotingEscrow {

    function voting_escrows(uint256 _index) external view returns(address);

    function mirrored_locks(address _user, uint256 _chain, uint256 _escrow_id) external view returns(LockedBalance memory);

    function mirror_lock(
        address _to,
        uint256 _chain,
        uint256 _escrow_id,
        uint256 _value,
        uint256 _unlock_time
    ) external;
}

contract MultiChainMirrorGateV2 is Ownable, Pausable, IApp {

    uint256 immutable chainId;

    IMirroredVotingEscrow public mirrorEscrow;

    IAnyswapV6CallProxy public endpoint;

    mapping(address => mapping(uint256 => bool)) public isAllowedCaller;

    constructor(
        IAnyswapV6CallProxy _endpoint,
        IMirroredVotingEscrow _mirrorEscrow,
        uint256 _chainId
    ) {
        endpoint = _endpoint;
        mirrorEscrow = _mirrorEscrow;
        chainId = _chainId;
    }

    function mirrorLocks(
        uint256 _toChainId,
        address _toMirrorGate,
        uint256[] memory _chainIds,
        uint256[] memory _escrowIds,
        int128[] memory _lockAmounts,
        uint256[] memory _lockEnds
    ) external payable whenNotPaused {
        require(_toChainId != chainId, "Cannot mirror from/to same chain");

        uint256 nbLocks_ = _chainIds.length;
        address user_ = _msgSender();
        for (uint256 i = 0; i < nbLocks_; i++) {
            require(_chainIds[i] != _toChainId, "Cannot mirror target chain locks");

            if (_chainIds[i] == chainId) {
                address escrow_ = mirrorEscrow.voting_escrows(i);
                LockedBalance memory lock_ = IVotingEscrow(escrow_).locked(user_);

                require(lock_.amount == _lockAmounts[i], "Incorrect lock amount");
                require(lock_.end == _lockEnds[i], "Incorrect lock end");
            } else {
                LockedBalance memory mirroredLock_ = mirrorEscrow.mirrored_locks(user_, _chainIds[i], _escrowIds[i]);

                require(mirroredLock_.amount == _lockAmounts[i], "Incorrect lock amount");
                require(mirroredLock_.end == _lockEnds[i], "Incorrect lock end");
            }
        }

        bytes memory payload = abi.encode(user_, _chainIds, _escrowIds, _lockAmounts, _lockEnds);
        endpoint.anyCall{value: msg.value}(_toMirrorGate, payload, address(0), _toChainId, 2);
    }

    function calculateFee(
        address _user,
        uint256 _toChainID,
        uint256[] memory _chainIds,
        uint256[] memory _escrowIds,
        int128[] memory _lockAmounts,
        uint256[] memory _lockEnds
    ) external view returns (uint256) {
        bytes memory payload = abi.encode(_user, _chainIds, _escrowIds, _lockAmounts, _lockEnds);
        return endpoint.calcSrcFees(address(this), _toChainID, payload.length);
    }

    function anyFallback(address _to, bytes calldata _data) override external {}

    function anyExecute(bytes calldata _data) override external returns (bool success, bytes memory result) {
        require(_msgSender() == address(endpoint.executor()), "Only multichain endpoint can trigger mirroring");

        (address from, uint256 fromChainId,) = endpoint.executor().context();
        require(isAllowedCaller[from][fromChainId], "Caller is not allowed from source chain");

        (address user_,
        uint256[] memory chainIds_,
        uint256[] memory escrowIds_,
        uint256[] memory lockAmounts_,
        uint256[] memory lockEnds_) = abi.decode(_data, (address, uint256[], uint256[], uint256[], uint256[]));

        uint256 nbLocks = chainIds_.length;
        for (uint256 i = 0; i < nbLocks; i++) {
            mirrorEscrow.mirror_lock(
                user_,
                chainIds_[i],
                escrowIds_[i],
                lockAmounts_[i],
                lockEnds_[i]
            );
        }

        return (true, "");
    }

    function recoverExecutionBudget() external onlyOwner {
        uint256 amount_ = endpoint.executionBudget(address(this));
        endpoint.withdraw(amount_);

        uint256 balance_ = address(this).balance;

        (bool success, ) = msg.sender.call{value: balance_}("");
        require(success, "Fee transfer failed");
    }

    function setEndpoint(IAnyswapV6CallProxy _endpoint) external onlyOwner {
        endpoint = _endpoint;
    }

    function setMirrorEscrow(IMirroredVotingEscrow _mirrorEscrow) external onlyOwner {
        mirrorEscrow = _mirrorEscrow;
    }

    function setupAllowedCallers(
        address[] memory _callers,
        uint256[] memory _chainIds,
        bool[] memory _areAllowed
    ) external onlyOwner {
        uint256 nbCallers_ = _callers.length;
        for (uint256 i = 0; i < nbCallers_; i++) {
            isAllowedCaller[_callers[i]][_chainIds[i]] = _areAllowed[i];
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
    constructor() {
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

import "./AnyCallExecutor.sol";

interface IAnyswapV6CallProxy {

    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;

    function calcSrcFees(
        address _app,
        uint256 _toChainID,
        uint256 _dataLength
    ) external view returns (uint256);

    function deposit(address _account) external payable;

    function withdraw(uint256 _amount) external;

    function executionBudget(address _account) external returns(uint256);

    function executor() external returns(AnyCallExecutor);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IApp {
    function anyExecute(bytes calldata _data) external returns (bool success, bytes memory result);

    function anyFallback(address _to, bytes calldata _data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

import "./IApp.sol";

contract AnyCallExecutor {
    struct Context {
        address from;
        uint256 fromChainID;
        uint256 nonce;
    }

    Context public context;
    address public creator;

    constructor() {
        creator = msg.sender;
    }

    function execute(
        address _to,
        bytes calldata _data,
        address _from,
        uint256 _fromChainID,
        uint256 _nonce
    ) external returns (bool success, bytes memory result) {
        if (msg.sender != creator) {
            return (false, "AnyCallExecutor: caller is not the creator");
        }
        context = Context({from: _from, fromChainID: _fromChainID, nonce: _nonce});
        (success, result) = IApp(_to).anyExecute(_data);
        context = Context({from: address(0), fromChainID: 0, nonce: 0});
    }
}