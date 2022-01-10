// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./interfaces/ICVIOracle.sol";
import "./interfaces/AggregatorV3Interface.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract CVIOracle is ICVIOracle, Ownable {

    uint256 private constant PRECISION_DECIMALS = 10000;
    uint256 private constant CVI_DECIMALS_TRUNCATE = 1e16;

    AggregatorV3Interface public immutable cviAggregator;
    AggregatorV3Interface public cviDeviationAggregator;
    bool public deviationCheck = false;
    uint16 public maxDeviation = 1000;

    uint256 public maxCVIValue;

    constructor(AggregatorV3Interface _cviAggregator, AggregatorV3Interface _cviDeviationAggregator, uint256 _maxCVIValue) {
    	cviAggregator = _cviAggregator;
        cviDeviationAggregator = _cviDeviationAggregator;
        maxCVIValue = _maxCVIValue;
    }

    function getCVIRoundData(uint80 _roundId) external view override returns (uint16 cviValue, uint256 cviTimestamp) {
        (, int256 cviOracleValue,, uint256 cviOracleTimestamp,) = cviAggregator.getRoundData(_roundId);
        cviTimestamp = cviOracleTimestamp;
        cviValue = getTruncatedCVIValue(cviOracleValue);
    }

    function getCVILatestRoundData() external view override returns (uint16 cviValue, uint80 cviRoundId, uint256 cviTimestamp) {
        (uint80 oracleRoundId, int256 cviOracleValue,, uint256 oracleTimestamp,) = cviAggregator.latestRoundData();
        uint16 truncatedCVIOracleValue = getTruncatedCVIValue(cviOracleValue);

        if (deviationCheck) {
            (, int256 cviDeviationOracleValue,,,) = cviDeviationAggregator.latestRoundData();
            uint16 truncatedCVIDeviationOracleValue = getTruncatedCVIValue(cviDeviationOracleValue);

            uint256 deviation = truncatedCVIDeviationOracleValue > truncatedCVIOracleValue ? truncatedCVIDeviationOracleValue - truncatedCVIOracleValue : truncatedCVIOracleValue - truncatedCVIDeviationOracleValue;

            require(deviation * PRECISION_DECIMALS / truncatedCVIDeviationOracleValue <= maxDeviation, "Deviation too large");
        }

        return (truncatedCVIOracleValue, oracleRoundId, oracleTimestamp);
    }

    function setDeviationCheck(bool _newDeviationCheck) external override onlyOwner {
        deviationCheck = _newDeviationCheck;
    }

    function setMaxDeviation(uint16 _newMaxDeviation) external override onlyOwner {
        maxDeviation = _newMaxDeviation;
    }

    function getTruncatedCVIValue(int256 cviOracleValue) private view returns (uint16) {
        uint256 cviValue = uint256(cviOracleValue);
        if (cviValue > maxCVIValue) {
            require(uint16(maxCVIValue / CVI_DECIMALS_TRUNCATE) > 0, "CVI must be positive");
            return uint16(maxCVIValue / CVI_DECIMALS_TRUNCATE);
        }

        require(uint16(cviValue / CVI_DECIMALS_TRUNCATE) > 0, "CVI must be positive");
        return uint16(cviValue / CVI_DECIMALS_TRUNCATE);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface ICVIOracle {
    function getCVIRoundData(uint80 roundId) external view returns (uint16 cviValue, uint256 cviTimestamp);
    function getCVILatestRoundData() external view returns (uint16 cviValue, uint80 cviRoundId, uint256 cviTimestamp);

    function setDeviationCheck(bool newDeviationCheck) external;
    function setMaxDeviation(uint16 newMaxDeviation) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface AggregatorV3Interface {

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

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