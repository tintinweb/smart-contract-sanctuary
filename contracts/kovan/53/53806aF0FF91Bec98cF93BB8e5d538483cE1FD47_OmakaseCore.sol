// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import "./access/BCAOwnable.sol";
import "./libraries/LinkedList.sol";

contract OmakaseCore is BCAOwnable, KeeperCompatibleInterface {
    using LinkedList_MinPriorityQueue for LinkedList;

    struct Flight {
        uint256 nextCheck;
        bool departed;
        uint256 departureTime;
        bytes32[] policies;
    }

    struct Policy {
        bytes32 flightId;
    }

    uint256 public totalPolicies;
    uint256 public totalFlights;

    mapping(bytes32 => Policy) public policies;
    mapping(bytes32 => Flight) public flights;

    LinkedList public flightQueue;

    uint256 public constant DELAY_INTERVAL = 12 hours;

    event NewInsurance(bytes32 indexed policyId, address creator);
    event NewFlight(bytes32 indexed flightId, address creator);
    event RequestStatusUpdate(bytes32 flightId);

    function createInsurance(
        bytes32 policyId,
        bytes32 flightId,
        uint256 departureTime
    ) external onlyBCA {
        require(
            policies[policyId].flightId == 0x0,
            "Policy has already been registered"
        );

        _createFlightIfNotExists(flightId, departureTime);

        policies[policyId] = Policy({flightId: flightId});
        flights[flightId].policies.push(policyId);

        totalPolicies++;

        emit NewInsurance(policyId, msg.sender);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bytes32 headFlightId = flightQueue.head;
        if (
            headFlightId != 0 &&
            block.timestamp >= flights[headFlightId].nextCheck
        ) {
            upkeepNeeded = true;
        }
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        bytes32 currFlightId = flightQueue.head;
        while (
            currFlightId != 0 &&
            block.timestamp >= flights[currFlightId].nextCheck
        ) {
            bytes32 next = flightQueue.next[currFlightId];

            emit RequestStatusUpdate(currFlightId);

            delete flightQueue.next[currFlightId];
            delete flightQueue.priorities[currFlightId];

            currFlightId = next;
        }

        flightQueue.head = currFlightId;
    }

    function updateFlightStatus(
        bytes32 flightId,
        bool departed,
        uint256 actualDepartureTime
    ) external onlyBCA {
        Flight storage flight = flights[flightId];

        require(!flight.departed, "Flight has already been departed");

        if (departed) {
            uint256 delay = (actualDepartureTime - flight.departureTime) /
                DELAY_INTERVAL;
            if (delay > 0) {
                // TODO: Request Payout
            }
            flight.departed = true;
        } else {
            uint256 nextCheck = flight.nextCheck + DELAY_INTERVAL;

            flight.nextCheck = nextCheck;
            flightQueue.insert(flightId, nextCheck);
        }
    }

    function getNextFlightQueue(bytes32 flightId)
        external
        view
        returns (bytes32)
    {
        return flightQueue.next[flightId];
    }

    function _createFlightIfNotExists(bytes32 flightId, uint256 departureTime)
        internal
    {
        require(departureTime > block.timestamp, "Invalid flight time");

        if (flights[flightId].departureTime != 0) {
            return;
        }

        flights[flightId].nextCheck = departureTime;
        flights[flightId].departureTime = departureTime;

        flightQueue.insert(flightId, departureTime);
        totalFlights++;

        emit NewFlight(flightId, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract BCAOwnable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @notice `owner` means BCA.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner (BCA).
     */
    modifier onlyBCA() {
        require(owner() == _msgSender(), "Ownable: caller is not BCA");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyBCA {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct LinkedList {
    bytes32 head;
    uint256 totalData;
    mapping(bytes32 => bytes32) next;
    mapping(bytes32 => uint256) priorities;
}

library LinkedList_MinPriorityQueue {
    function insert(
        LinkedList storage list,
        bytes32 id,
        uint256 priority
    ) internal {
        if (list.head == 0) {
            list.head = id;
            list.priorities[id] = priority;
            return;
        }

        bytes32 curr = list.head;
        if (priority < list.priorities[curr]) {
            list.head = id;
            list.next[id] = curr;
            list.priorities[id] = priority;
            return;
        }

        bytes32 next;
        while (true) {
            next = list.next[curr];
            if (next == 0 || list.priorities[next] > priority) {
                break;
            }

            curr = next;
        }

        list.next[id] = next;
        list.priorities[id] = priority;
        list.next[curr] = id;

        list.totalData++;
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}