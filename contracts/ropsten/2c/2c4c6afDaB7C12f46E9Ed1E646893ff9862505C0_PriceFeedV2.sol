// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPriceFeedV2.sol";

contract PriceFeedV2 is Ownable {
    uint80 latestUpdateRoundId;
    uint80 currentRoundId;
    address public operator;

    struct RoundInfo {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    mapping(uint80 => RoundInfo) roundData;

    event UpdateRoundInfo(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    event UpdateOperator(address operatorAddr);

    constructor(address _operator) {
        operator = _operator;
        roundData[currentRoundId] = RoundInfo({
            roundId: latestUpdateRoundId,
            answer: 0,
            startedAt: block.timestamp,
            updatedAt: 0,
            answeredInRound: 0
        });
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Not operator");
        _;
    }

    function decimals() external view returns (uint8) {
        return 18;
    }

    function description() external view returns (string memory) {
        return "Oracle for feeding ETH Price";
    }

    function version() external view returns (uint256) {
        return 3;
    }

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
        )
    {
        require(currentRoundId != 0, "No data present");
        require(roundData[_roundId].updatedAt != 0, "Round not updated yet");
        roundId = _roundId;
        answer = roundData[_roundId].answer;
        startedAt = roundData[_roundId].startedAt;
        updatedAt = roundData[_roundId].updatedAt;
        answeredInRound = roundData[_roundId].answeredInRound;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = roundData[latestUpdateRoundId].roundId;
        answer = roundData[latestUpdateRoundId].answer;
        startedAt = roundData[latestUpdateRoundId].startedAt;
        updatedAt = roundData[latestUpdateRoundId].updatedAt;
        answeredInRound = roundData[latestUpdateRoundId].answeredInRound;
    }

    function _setNewOperator(address _newOperator) public onlyOwner {
        operator = _newOperator;
        emit UpdateOperator(_newOperator);
    }

    function updateRoundData(int256 answer) public onlyOperator {
        require(
            roundData[latestUpdateRoundId].startedAt != block.timestamp,
            "Already update answer"
        );
        roundData[currentRoundId].answer = answer;
        roundData[currentRoundId].updatedAt = block.timestamp;
        roundData[currentRoundId].answeredInRound = 1;
        latestUpdateRoundId = currentRoundId;
        currentRoundId++;
        roundData[currentRoundId] = RoundInfo({
            roundId: latestUpdateRoundId,
            answer: 0,
            startedAt: block.timestamp,
            updatedAt: 0,
            answeredInRound: 0
        });
        emit UpdateRoundInfo(
            latestUpdateRoundId,
            answer,
            roundData[latestUpdateRoundId].startedAt,
            block.timestamp,
            1
        );
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

interface IPriceFeedV2 {
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