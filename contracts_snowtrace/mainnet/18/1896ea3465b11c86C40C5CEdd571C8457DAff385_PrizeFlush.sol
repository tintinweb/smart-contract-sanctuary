// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./interfaces/IPrizeFlush.sol";

/**
 * @title  PoolTogether V4 PrizeFlush
 * @author PoolTogether Inc Team
 * @notice The PrizeFlush contract helps capture interest from the PrizePool and move collected funds
           to a designated PrizeDistributor contract. When deployed, the destination, reserve and strategy
           addresses are set and used as static parameters during every "flush" execution. The parameters can be
           reset by the Owner if necessary.
 */
contract PrizeFlush is IPrizeFlush, Manageable {
    /**
     * @notice Destination address for captured interest.
     * @dev Should be set to the PrizeDistributor address.
     */
    address internal destination;

    /// @notice Reserve address.
    IReserve internal reserve;

    /// @notice Strategy address.
    IStrategy internal strategy;

    /**
     * @notice Emitted when contract has been deployed.
     * @param destination Destination address
     * @param reserve Strategy address
     * @param strategy Reserve address
     *
     */
    event Deployed(
        address indexed destination,
        IReserve indexed reserve,
        IStrategy indexed strategy
    );

    /* ============ Constructor ============ */

    /**
     * @notice Deploy Prize Flush.
     * @param _owner Prize Flush owner address
     * @param _destination Destination address
     * @param _strategy Strategy address
     * @param _reserve Reserve address
     *
     */
    constructor(
        address _owner,
        address _destination,
        IStrategy _strategy,
        IReserve _reserve
    ) Ownable(_owner) {
        _setDestination(_destination);
        _setReserve(_reserve);
        _setStrategy(_strategy);

        emit Deployed(_destination, _reserve, _strategy);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizeFlush
    function getDestination() external view override returns (address) {
        return destination;
    }

    /// @inheritdoc IPrizeFlush
    function getReserve() external view override returns (IReserve) {
        return reserve;
    }

    /// @inheritdoc IPrizeFlush
    function getStrategy() external view override returns (IStrategy) {
        return strategy;
    }

    /// @inheritdoc IPrizeFlush
    function setDestination(address _destination) external override onlyOwner returns (address) {
        _setDestination(_destination);
        emit DestinationSet(_destination);
        return _destination;
    }

    /// @inheritdoc IPrizeFlush
    function setReserve(IReserve _reserve) external override onlyOwner returns (IReserve) {
        _setReserve(_reserve);
        emit ReserveSet(_reserve);
        return _reserve;
    }

    /// @inheritdoc IPrizeFlush
    function setStrategy(IStrategy _strategy) external override onlyOwner returns (IStrategy) {
        _setStrategy(_strategy);
        emit StrategySet(_strategy);
        return _strategy;
    }

    /// @inheritdoc IPrizeFlush
    function flush() external override onlyManagerOrOwner returns (bool) {
        // Captures interest from PrizePool and distributes funds using a PrizeSplitStrategy.
        strategy.distribute();

        // After funds are distributed using PrizeSplitStrategy we EXPECT funds to be located in the Reserve.
        IReserve _reserve = reserve;
        IERC20 _token = _reserve.getToken();
        uint256 _amount = _token.balanceOf(address(_reserve));

        // IF the tokens were succesfully moved to the Reserve, now move them to the destination (PrizeDistributor) address.
        if (_amount > 0) {
            address _destination = destination;

            // Create checkpoint and transfers new total balance to PrizeDistributor
            _reserve.withdrawTo(_destination, _amount);

            emit Flushed(_destination, _amount);
            return true;
        }

        return false;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Set global destination variable.
     * @dev `_destination` cannot be the zero address.
     * @param _destination Destination address
     */
    function _setDestination(address _destination) internal {
        require(_destination != address(0), "Flush/destination-not-zero-address");
        destination = _destination;
    }

    /**
     * @notice Set global reserve variable.
     * @dev `_reserve` cannot be the zero address.
     * @param _reserve Reserve address
     */
    function _setReserve(IReserve _reserve) internal {
        require(address(_reserve) != address(0), "Flush/reserve-not-zero-address");
        reserve = _reserve;
    }

    /**
     * @notice Set global strategy variable.
     * @dev `_strategy` cannot be the zero address.
     * @param _strategy Strategy address
     */
    function _setStrategy(IStrategy _strategy) internal {
        require(address(_strategy) != address(0), "Flush/strategy-not-zero-address");
        strategy = _strategy;
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

import "./Ownable.sol";

/**
 * @title Abstract manageable contract that can be inherited by other contracts
 * @notice Contract module based on Ownable which provides a basic access control mechanism, where
 * there is an owner and a manager that can be granted exclusive access to specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */
abstract contract Manageable is Ownable {
    address private _manager;

    /**
     * @dev Emitted when `_manager` has been changed.
     * @param previousManager previous `_manager` address.
     * @param newManager new `_manager` address.
     */
    event ManagerTransferred(address indexed previousManager, address indexed newManager);

    /* ============ External Functions ============ */

    /**
     * @notice Gets current `_manager`.
     * @return Current `_manager` address.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @notice Set or change of manager.
     * @dev Throws if called by any account other than the owner.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function setManager(address _newManager) external onlyOwner returns (bool) {
        return _setManager(_newManager);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Set or change of manager.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function _setManager(address _newManager) private returns (bool) {
        address _previousManager = _manager;

        require(_newManager != _previousManager, "Manageable/existing-manager-address");

        _manager = _newManager;

        emit ManagerTransferred(_previousManager, _newManager);
        return true;
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(manager() == msg.sender, "Manageable/caller-not-manager");
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager or the owner.
     */
    modifier onlyManagerOrOwner() {
        require(manager() == msg.sender || owner() == msg.sender, "Manageable/caller-not-manager-or-owner");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/v4-core/contracts/interfaces/IReserve.sol";
import "@pooltogether/v4-core/contracts/interfaces/IStrategy.sol";

interface IPrizeFlush {
    /**
     * @notice Emit when the flush function has executed.
     * @param destination Address receiving funds
     * @param amount      Amount of tokens transferred
     */
    event Flushed(address indexed destination, uint256 amount);

    /**
     * @notice Emit when destination is set.
     * @param destination Destination address
     */
    event DestinationSet(address destination);

    /**
     * @notice Emit when strategy is set.
     * @param strategy Strategy address
     */
    event StrategySet(IStrategy strategy);

    /**
     * @notice Emit when reserve is set.
     * @param reserve Reserve address
     */
    event ReserveSet(IReserve reserve);

    /// @notice Read global destination variable.
    function getDestination() external view returns (address);

    /// @notice Read global reserve variable.
    function getReserve() external view returns (IReserve);

    /// @notice Read global strategy variable.
    function getStrategy() external view returns (IStrategy);

    /// @notice Set global destination variable.
    function setDestination(address _destination) external returns (address);

    /// @notice Set global reserve variable.
    function setReserve(IReserve _reserve) external returns (IReserve);

    /// @notice Set global strategy variable.
    function setStrategy(IStrategy _strategy) external returns (IStrategy);

    /**
     * @notice Migrate interest from PrizePool to PrizeDistributor in a single transaction.
     * @dev    Captures interest, checkpoint data and transfers tokens to final destination.
     * @return True if operation is successful.
     */
    function flush() external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Abstract ownable contract that can be inherited by other contracts
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Emitted when `_pendingOwner` has been changed.
     * @param pendingOwner new `_pendingOwner` address.
     */
    event OwnershipOffered(address indexed pendingOwner);

    /**
     * @dev Emitted when `_owner` has been changed.
     * @param previousOwner previous `_owner` address.
     * @param newOwner new `_owner` address.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* ============ Deploy ============ */

    /**
     * @notice Initializes the contract setting `_initialOwner` as the initial owner.
     * @param _initialOwner Initial owner of the contract.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Gets current `_pendingOwner`.
     * @return Current `_pendingOwner` address.
     */
    function pendingOwner() external view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Renounce ownership of the contract.
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
    * @notice Allows current owner to set the `_pendingOwner` address.
    * @param _newOwner Address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable/pendingOwner-not-zero-address");

        _pendingOwner = _newOwner;

        emit OwnershipOffered(_newOwner);
    }

    /**
    * @notice Allows the `_pendingOwner` address to finalize the transfer.
    * @dev This function is only callable by the `_pendingOwner`.
    */
    function claimOwnership() external onlyPendingOwner {
        _setOwner(_pendingOwner);
        _pendingOwner = address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Internal function to set the `_owner` of the contract.
     * @param _newOwner New `_owner` address.
     */
    function _setOwner(address _newOwner) private {
        address _oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable/caller-not-owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the `pendingOwner`.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable/caller-not-pendingOwner");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReserve {
    /**
     * @notice Emit when checkpoint is created.
     * @param reserveAccumulated  Total depsosited
     * @param withdrawAccumulated Total withdrawn
     */

    event Checkpoint(uint256 reserveAccumulated, uint256 withdrawAccumulated);
    /**
     * @notice Emit when the withdrawTo function has executed.
     * @param recipient Address receiving funds
     * @param amount    Amount of tokens transfered.
     */
    event Withdrawn(address indexed recipient, uint256 amount);

    /**
     * @notice Create observation checkpoint in ring bufferr.
     * @dev    Calculates total desposited tokens since last checkpoint and creates new accumulator checkpoint.
     */
    function checkpoint() external;

    /**
     * @notice Read global token value.
     * @return IERC20
     */
    function getToken() external view returns (IERC20);

    /**
     * @notice Calculate token accumulation beween timestamp range.
     * @dev    Search the ring buffer for two checkpoint observations and diffs accumulator amount.
     * @param startTimestamp Account address
     * @param endTimestamp   Transfer amount
     */
    function getReserveAccumulatedBetween(uint32 startTimestamp, uint32 endTimestamp)
        external
        returns (uint224);

    /**
     * @notice Transfer Reserve token balance to recipient address.
     * @dev    Creates checkpoint before token transfer. Increments withdrawAccumulator with amount.
     * @param recipient Account address
     * @param amount    Transfer amount
     */
    function withdrawTo(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

interface IStrategy {
    /**
     * @notice Emit when a strategy captures award amount from PrizePool.
     * @param totalPrizeCaptured  Total prize captured from the PrizePool
     */
    event Distributed(uint256 totalPrizeCaptured);

    /**
     * @notice Capture the award balance and distribute to prize splits.
     * @dev    Permissionless function to initialize distribution of interst
     * @return Prize captured from PrizePool
     */
    function distribute() external returns (uint256);
}