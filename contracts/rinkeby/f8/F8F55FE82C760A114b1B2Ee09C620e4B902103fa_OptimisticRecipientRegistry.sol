// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';

import './BaseRecipientRegistry.sol';

/**
 * @dev Recipient registry with optimistic execution of registrations and removals.
 */
contract OptimisticRecipientRegistry is Ownable, BaseRecipientRegistry {

  // Enums
  enum RequestType {
    Registration,
    Removal
  }

  // Structs
  struct Request {
    RequestType requestType;
    address payable requester;
    uint256 submissionTime;
    uint256 deposit;
    address recipientAddress; // Only for registration requests
    string recipientMetadata; // Only for registration requests
  }

  // State
  uint256 public baseDeposit;
  uint256 public challengePeriodDuration;
  mapping(bytes32 => Request) private requests;

  // Events
  event RequestSubmitted(
    bytes32 indexed _recipientId,
    RequestType indexed _type,
    address _recipient,
    string _metadata,
    uint256 _timestamp
  );
  event RequestResolved(
    bytes32 indexed _recipientId,
    RequestType indexed _type,
    bool indexed _rejected,
    uint256 _recipientIndex, // Only for accepted registration requests
    uint256 _timestamp
  );

  /**
    * @dev Deploy the registry.
    * @param _baseDeposit Deposit required to add or remove item.
    * @param _challengePeriodDuration The time owner has to challenge a request (seconds).
    * @param _controller Controller address. Normally it's a funding round factory contract.
    */
  constructor(
    uint256 _baseDeposit,
    uint256 _challengePeriodDuration,
    address _controller
  )
    public
  {
    baseDeposit = _baseDeposit;
    challengePeriodDuration = _challengePeriodDuration;
    controller = _controller;
  }

  /**
    * @dev Change base deposit.
    */
  function setBaseDeposit(uint256 _baseDeposit)
    external
    onlyOwner
  {
    baseDeposit = _baseDeposit;
  }

  /**
    * @dev Change challenge period duration.
    */
  function setChallengePeriodDuration(uint256 _challengePeriodDuration)
    external
    onlyOwner
  {
    challengePeriodDuration = _challengePeriodDuration;
  }

  /**
    * @dev Submit recipient registration request.
    * @param _recipient The address that receives funds.
    * @param _metadata The metadata info of the recipient.
    */
  function addRecipient(address _recipient, string calldata _metadata)
    external
    payable
  {
    require(_recipient != address(0), 'RecipientRegistry: Recipient address is zero');
    require(bytes(_metadata).length != 0, 'RecipientRegistry: Metadata info is empty string');
    bytes32 recipientId = keccak256(abi.encodePacked(_recipient, _metadata));
    require(recipients[recipientId].index == 0, 'RecipientRegistry: Recipient already registered');
    require(requests[recipientId].submissionTime == 0, 'RecipientRegistry: Request already submitted');
    require(msg.value == baseDeposit, 'RecipientRegistry: Incorrect deposit amount');
    requests[recipientId] = Request(
      RequestType.Registration,
      msg.sender,
      block.timestamp,
      msg.value,
      _recipient,
      _metadata
    );
    emit RequestSubmitted(
      recipientId,
      RequestType.Registration,
      _recipient,
      _metadata,
      block.timestamp
    );
  }

  /**
    * @dev Submit recipient removal request.
    * @param _recipientId The ID of recipient.
    */
  function removeRecipient(bytes32 _recipientId)
    external
    payable
  {
    require(recipients[_recipientId].index != 0, 'RecipientRegistry: Recipient is not in the registry');
    require(recipients[_recipientId].removedAt == 0, 'RecipientRegistry: Recipient already removed');
    require(requests[_recipientId].submissionTime == 0, 'RecipientRegistry: Request already submitted');
    require(msg.value == baseDeposit, 'RecipientRegistry: Incorrect deposit amount');
    requests[_recipientId] = Request(
      RequestType.Removal,
      msg.sender,
      block.timestamp,
      msg.value,
      address(0),
      ''
    );
    emit RequestSubmitted(
      _recipientId,
      RequestType.Removal,
      address(0),
      '',
      block.timestamp
    );
  }

  /**
    * @dev Reject request.
    * @param _recipientId The ID of recipient.
    * @param _beneficiary Address to which the deposit should be transferred.
    */
  function challengeRequest(bytes32 _recipientId, address payable _beneficiary)
    external
    onlyOwner
    returns (bool)
  {
    Request memory request = requests[_recipientId];
    require(request.submissionTime != 0, 'RecipientRegistry: Request does not exist');
    delete requests[_recipientId];
    bool isSent = _beneficiary.send(request.deposit);
    emit RequestResolved(
      _recipientId,
      request.requestType,
      true,
      0,
      block.timestamp
    );
    return isSent;
  }

  /**
    * @dev Execute request.
    * @param _recipientId The ID of recipient.
    */
  function executeRequest(bytes32 _recipientId)
    external
    returns (bool)
  {
    Request memory request = requests[_recipientId];
    require(request.submissionTime != 0, 'RecipientRegistry: Request does not exist');
    if (msg.sender != owner()) {
      require(
        block.timestamp - request.submissionTime >= challengePeriodDuration,
        'RecipientRegistry: Challenge period is not over'
      );
    }
    uint256 recipientIndex = 0;
    if (request.requestType == RequestType.Removal) {
      _removeRecipient(_recipientId);
    } else {
      // WARNING: Could revert if no slots are available or if recipient limit is not set
      recipientIndex = _addRecipient(_recipientId, request.recipientAddress);
    }
    delete requests[_recipientId];
    bool isSent = request.requester.send(request.deposit);
    emit RequestResolved(
      _recipientId,
      request.requestType,
      false,
      recipientIndex,
      block.timestamp
    );
    return isSent;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import './IRecipientRegistry.sol';

/**
 * @dev Abstract contract containing common methods for recipient registries.
 */
abstract contract BaseRecipientRegistry is IRecipientRegistry {

  // Structs
  struct Recipient {
    address addr;
    uint256 index;
    uint256 addedAt;
    uint256 removedAt;
  }

  // State
  address public controller;
  uint256 public maxRecipients;
  mapping(bytes32 => Recipient) internal recipients;
  bytes32[] private removed;
  // Slot 0 corresponds to index 1
  // Each slot contains a history of recipients who occupied it
  bytes32[][] private slots;

  /**
    * @dev Set maximum number of recipients.
    * @param _maxRecipients Maximum number of recipients.
    * @return True if operation is successful.
    */
  function setMaxRecipients(uint256 _maxRecipients)
    override
    external
    returns (bool)
  {
    require(
      _maxRecipients >= maxRecipients,
      'RecipientRegistry: Max number of recipients can not be decreased'
    );
    if (controller != msg.sender) {
      // This allows other clrfund instances to use the registry
      // but only controller can actually increase the limit.
      return false;
    }
    maxRecipients = _maxRecipients;
    return true;
  }

  /**
    * @dev Register recipient as eligible for funding allocation.
    * @param _recipientId The ID of recipient.
    * @param _recipient The address that receives funds.
    * @return Recipient index.
    */
  function _addRecipient(bytes32 _recipientId, address _recipient)
    internal
    returns (uint256)
  {
    require(maxRecipients > 0, 'RecipientRegistry: Recipient limit is not set');
    require(recipients[_recipientId].index == 0, 'RecipientRegistry: Recipient already registered');
    uint256 recipientIndex = 0;
    uint256 nextRecipientIndex = slots.length + 1;
    if (nextRecipientIndex <= maxRecipients) {
      // Assign next index in sequence
      recipientIndex = nextRecipientIndex;
      bytes32[] memory history = new bytes32[](1);
      history[0] = _recipientId;
      slots.push(history);
    } else {
      // Assign one of the vacant recipient indexes
      require(removed.length > 0, 'RecipientRegistry: Recipient limit reached');
      bytes32 removedRecipient = removed[removed.length - 1];
      removed.pop();
      recipientIndex = recipients[removedRecipient].index;
      slots[recipientIndex - 1].push(_recipientId);
    }
    recipients[_recipientId] = Recipient(_recipient, recipientIndex, block.timestamp, 0);
    return recipientIndex;
  }

  /**
    * @dev Remove recipient from the registry.
    * @param _recipientId The ID of recipient.
    */
  function _removeRecipient(bytes32 _recipientId)
    internal
  {
    require(recipients[_recipientId].index != 0, 'RecipientRegistry: Recipient is not in the registry');
    require(recipients[_recipientId].removedAt == 0, 'RecipientRegistry: Recipient already removed');
    recipients[_recipientId].removedAt = block.timestamp;
    removed.push(_recipientId);
  }

  /**
    * @dev Get recipient address by index.
    * @param _index Recipient index.
    * @param _startTime The start time of the funding round.
    * @param _endTime The end time of the funding round.
    * @return Recipient address.
    */
  function getRecipientAddress(
    uint256 _index,
    uint256 _startTime,
    uint256 _endTime
  )
    override
    external
    view
    returns (address)
  {
    if (_index == 0 || _index > slots.length) {
      return address(0);
    }
    bytes32[] memory history = slots[_index - 1];
    if (history.length == 0) {
      // Slot is not occupied
      return address(0);
    }
    address prevRecipientAddress = address(0);
    for (uint256 idx = history.length; idx > 0; idx--) {
      bytes32 recipientId = history[idx - 1];
      Recipient memory recipient = recipients[recipientId];
      if (recipient.addedAt > _endTime) {
        // Recipient added after the end of the funding round, skip
        continue;
      }
      else if (recipient.removedAt != 0 && recipient.removedAt <= _startTime) {
        // Recipient had been already removed when the round started
        // Stop search because subsequent items were removed even earlier
        return prevRecipientAddress;
      }
      // This recipient is valid, but the recipient who occupied
      // this slot before also needs to be checked.
      prevRecipientAddress = recipient.addr;
    }
    return prevRecipientAddress;
  }

  /**
    * @dev Get recipient count.
    * @return count of active recipients in the registry.
    */
  function getRecipientCount() public view returns(uint256) {
      return slots.length - removed.length;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

/**
 * @dev Interface of the recipient registry.
 *
 * This contract must do the following:
 *
 * - Add recipients to the registry.
 * - Allow only legitimate recipients into the registry.
 * - Assign an unique index to each recipient.
 * - Limit the maximum number of entries according to a parameter set by the funding round factory.
 * - Remove invalid entries.
 * - Prevent indices from changing during the funding round.
 * - Find address of a recipient by their unique index.
 */
interface IRecipientRegistry {

  function setMaxRecipients(uint256 _maxRecipients) external returns (bool);

  function getRecipientAddress(uint256 _index, uint256 _startBlock, uint256 _endBlock) external view returns (address);

}