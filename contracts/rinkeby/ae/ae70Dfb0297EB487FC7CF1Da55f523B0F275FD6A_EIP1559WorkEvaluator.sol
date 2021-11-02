// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/INativeTokenNativeCurrencyPriceOracle.sol";
import "../interfaces/IBonder.sol";
import "../interfaces/IWorkEvaluator.sol";

error ZeroAddressOracle();
error UnbondedWorker();
error Forbidden();
error InvalidMinimumIncrease();
error InvalidMaximumIncrease();
error InvalidSwapGasUsed();

contract EIP1559WorkEvaluator is IWorkEvaluator, Ownable {
    uint256 public immutable BASE = 10000;

    address public nativeTokenNativeCurrencyPriceOracle;
    address public bonder;
    uint256 public minimumBonus;
    uint256 public maximumBonus;

    constructor(
        address _nativeTokenNativeCurrencyPriceOracle,
        address _bonder,
        uint256 _minimumBonus,
        uint256 _maximumBonus
    ) {
        if (_nativeTokenNativeCurrencyPriceOracle == address(0))
            revert ZeroAddressOracle();
        if (_minimumBonus > BASE) revert InvalidMinimumIncrease();
        if (_maximumBonus > BASE) revert InvalidMaximumIncrease();

        nativeTokenNativeCurrencyPriceOracle = _nativeTokenNativeCurrencyPriceOracle;
        bonder = _bonder;
        minimumBonus = _minimumBonus;
        maximumBonus = _maximumBonus;
    }

    function evaluateCost(address _worker, uint256 _gasUsed)
        external
        view
        returns (uint256)
    {
        uint256 _baseFee;
        assembly {
            _baseFee := basefee()
        }

        uint256 _nativeCurrencyFee = _gasUsed * _baseFee + 2 gwei;

        uint256 _minimumPaid = ((_nativeCurrencyFee * (BASE + minimumBonus)) /
            BASE);
        uint256 _maximumPaid = ((_nativeCurrencyFee * (BASE + maximumBonus)) /
            BASE);

        uint256 _totalBonded = IBonder(bonder).totalBonded();
        uint256 _workerBond = IBonder(bonder).bonded(_worker);
        if (_workerBond == 0) revert UnbondedWorker();

        // TODO: consider using a multiplier to improve precision
        return
            INativeTokenNativeCurrencyPriceOracle(
                nativeTokenNativeCurrencyPriceOracle
            ).quote(
                    _nativeCurrencyFee +
                        (((_maximumPaid - _minimumPaid) * _workerBond) /
                            _totalBonded)
                );
    }

    function setNativeTokenNativeCurrencyPriceOracle(
        address _nativeTokenNativeCurrencyPriceOracle
    ) external {
        if (_msgSender() != owner()) revert Forbidden();
        if (_nativeTokenNativeCurrencyPriceOracle == address(0))
            revert ZeroAddressOracle();
        nativeTokenNativeCurrencyPriceOracle = _nativeTokenNativeCurrencyPriceOracle;
    }

    function setBonder(address _bonder) external {
        if (_msgSender() != owner()) revert Forbidden();
        bonder = _bonder;
    }

    function setMinimumIncrease(uint256 _minimumBonus) external {
        if (_minimumBonus > BASE) revert InvalidMinimumIncrease();
        if (_msgSender() != owner()) revert Forbidden();
        minimumBonus = _minimumBonus;
    }

    function setMaximumIncrease(uint256 _maximumBonus) external {
        if (_maximumBonus > BASE) revert InvalidMaximumIncrease();
        if (_msgSender() != owner()) revert Forbidden();
        maximumBonus = _maximumBonus;
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

pragma solidity >=0.8.9;

/**
 * @title INativeTokenNativeCurrencyPriceOracle
 * @dev INativeTokenNativeCurrencyPriceOracle contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface INativeTokenNativeCurrencyPriceOracle {
    function quote(uint256 _nativeCurrencyAmount)
        external
        view
        returns (uint256);
}

pragma solidity ^0.8.9;

/**
 * @title IBonder
 * @dev IBonder contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IBonder {
    struct Worker {
        uint256 bonded;
        uint256 earned;
        uint256 bonding;
        uint256 bondingTimestamp;
        uint256 unbonding;
        uint256 unbondingTimestamp;
        uint256 activationTimestamp;
    }

    function worker(address) external view returns (Worker memory);

    function totalBonded() external view returns (uint256);

    function bondingTime() external view returns (uint256);

    function unbondingTime() external view returns (uint256);

    function nativeToken() external view returns (address);

    function master() external view returns (address);

    function setBondingTime(uint256 _bondingTime) external;

    function setUnbondingTime(uint256 _unbondingTime) external;

    function setNativeToken(address _nativeToken) external;

    function bond(uint256 _amount) external;

    function bondWithPermit(
        uint256 _amount,
        uint256 _permittedAmount, // can be used for infinite approvals
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function consolidateBond() external;

    function cancelBonding() external;

    function accrueReward(address _address, uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function consolidateUnbonding() external;

    function bonded(address _address) external view returns (uint256);

    function earned(address _address) external view returns (uint256);

    function activationTimestamp(address _address)
        external
        view
        returns (uint256);
}

pragma solidity >=0.8.9;

/**
 * @title IWorkEvaluator
 * @dev IWorkEvaluator contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IWorkEvaluator {
    function evaluateCost(address _worker, uint256 _gasUsed)
        external
        returns (uint256);
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