// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISummonerConfig.sol";

contract SummonerConfig is Ownable, ISummonerConfig {
    /// @notice check if a specific network is paused or not
    mapping(uint256 => bool) public pausedNetwork;
    uint256 private transferLockupTime;

    // remote network id => fee token address => fee amount
    mapping(uint256 => mapping(address => uint256)) private feeAmounts;

    event LockupTimeChanged(
        address indexed _owner,
        uint256 _oldVal,
        uint256 _newVal,
        string valType
    );

    event PauseNetwork(address indexed admin, uint256 networkID);
    event UnpauseNetwork(address indexed admin, uint256 networkID);
    event FeeTokenAmountChanged(
        address indexed admin,
        uint256 remoteNetworkId,
        address indexed token,
        uint256 oldAmount,
        uint256 newAmount
    );
    event FeeTokenRemoved(address indexed admin, address indexed token, uint256 remoteNetworkId);

    constructor() {
        transferLockupTime = 0;
    }

    function setTransferLockupTime(uint256 lockupTime) external onlyOwner {
        emit LockupTimeChanged(msg.sender, transferLockupTime, lockupTime, "Transfer");
        transferLockupTime = lockupTime;
    }

    function getTransferLockupTime() external view override returns (uint256) {
        return transferLockupTime;
    }

    function setFeeToken(
        uint256 remoteNetworkId,
        address _feeToken,
        uint256 _feeAmount
    ) external onlyOwner {
        require(_feeAmount > 0, "AMT");
        // address(0) is special for the native token of the chain
        emit FeeTokenAmountChanged(
            msg.sender,
            remoteNetworkId,
            _feeToken,
            feeAmounts[remoteNetworkId][_feeToken],
            _feeAmount
        );
        feeAmounts[remoteNetworkId][_feeToken] = _feeAmount;
    }

    function removeFeeToken(uint256 remoteNetworkId, address _feeToken) external onlyOwner {
        emit FeeTokenRemoved(msg.sender, _feeToken, remoteNetworkId);
        delete feeAmounts[remoteNetworkId][_feeToken];
    }

    function getFeeTokenAmount(uint256 remoteNetworkId, address feeToken)
        external
        view
        override
        returns (uint256)
    {
        return feeAmounts[remoteNetworkId][feeToken];
    }

    /// @notice External callable function to pause the contract
    function pauseNetwork(uint256 networkID) external onlyOwner {
        pausedNetwork[networkID] = true;
        emit PauseNetwork(msg.sender, networkID);
    }

    /// @notice External callable function to unpause the contract
    function unpauseNetwork(uint256 networkID) external onlyOwner {
        pausedNetwork[networkID] = false;
        emit UnpauseNetwork(msg.sender, networkID);
    }

    function getPausedNetwork(uint256 networkId) external view override returns (bool) {
        return pausedNetwork[networkId];
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

interface ISummonerConfig {
    function getTransferLockupTime() external view returns (uint256);

    function getFeeTokenAmount(uint256 remoteNetworkId, address feeToken)
        external
        view
        returns (uint256);

    function getPausedNetwork(uint256 networkId) external view returns (bool);
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