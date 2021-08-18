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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EventDatabase is Ownable {
    enum Result {
        NONE,
        A,
        B,
        AB
    }

    struct Event {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        Result result;
        bool isEnded;
        string description;
        string teamA;
        string teamB;
    }

    mapping(uint256 => Event) public events;

    uint256 public totalEvents;

    event EventCreated(
        uint256 eventId,
        uint256 startTime,
        uint256 endTime,
        string description,
        string teamA,
        string teamB
    );

    event EventClosed(uint256 eventId, uint256 result);

    constructor() {
        totalEvents = 0;
    }

    function createEvent(
        uint256 _eventId,
        uint256 _startTime,
        uint256 _endTime,
        string memory _description,
        string memory _teamA,
        string memory _teamB
    ) external onlyOwner {
        require(
            events[_eventId].startTime == 0,
            "EventDatabase: Event ID is duplicated"
        );
        require(
            _startTime > block.timestamp,
            "EventDatabase: StartTime is gone"
        );
        require(_endTime > _startTime, "EventDatabase: Invalid EndTime");

        events[_eventId].id = _eventId;
        events[_eventId].startTime = _startTime;
        events[_eventId].endTime = _endTime;
        events[_eventId].result = Result.NONE;
        events[_eventId].isEnded = false;
        events[_eventId].description = _description;
        events[_eventId].teamA = _teamA;
        events[_eventId].teamB = _teamB;
        totalEvents++;

        emit EventCreated(
            _eventId,
            _startTime,
            _endTime,
            _description,
            _teamA,
            _teamB
        );
    }

    function closeEvent(uint256 _eventId, uint256 _result) external onlyOwner {
        require(
            events[_eventId].startTime > 0,
            "EventDatabase: Invalid eventId"
        );
        require(!events[_eventId].isEnded, "EventDatabase: Already closed");
        require(
            events[_eventId].endTime >= block.timestamp,
            "EventDatabase: Not ready to close"
        );

        events[_eventId].result = Result(_result);
        events[_eventId].isEnded = true;

        emit EventClosed(_eventId, _result);
    }
}