//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Tiramisu Savings Club v1
/// @author Jerrall, Luis, Mayuko, Prashant
/// @notice This dapp has a single smart contract architecture. It manages state for all savings clubs in this single contract
/// @notice v1 was developed during a short period of time (DappCamp) with the goal of being a MVP. See whitepaper for future roadmap ideas
/// @dev Contraint #1: A user (address) can only belong to a single group
/// @dev Contraint #2: Only one pending request for money can exist at a time per group
contract TiramisuSavingsClub {
    using Counters for Counters.Counter;
    Counters.Counter private _groupIdCounter;

    struct Group {
        address[] members;
        string[] memberNames;
        uint ownerIndex;
        uint balance;
        uint nextPayee;
    }

    Group[] public groups;

    mapping(address => uint) public memberToGroupId;
    mapping(address => uint) private deposits;
    mapping(address => uint) private withdrawals;

    constructor() {
        // Group id 0 is immediately burned and disallowed for use
        // Otherwise our mapping lookups will be error prone due to Solidity limitations (can't distinguish default value from the group at index 0)
        // First real group will be at index 1
        Group memory burnedGroup;
        groups.push(burnedGroup);
        _groupIdCounter.increment();
    }

    /// Create a savings group
    /// @param _members List of addresses that are members of this goup, sorted by payout order
    /// @param _names List of human readable names that map to addresses - indexed to _members
    /// @param _ownerIndex Index of the address and name of the owner who is allowed to perform special admin functions
    /// @dev Reverts if any of the inputs are invalid
    /// @dev Reverts if any of the member addresses currently belong to another group (not allowed)
    /// @return group id
    function createGroup(address[] memory _members, string[] memory _names, uint _ownerIndex) public returns (uint) {
        require(_members.length > 0, "Can't create empty group");
        require(_members.length == _names.length, "_members/_names len should match");
        require(_ownerIndex >= 0 && _ownerIndex < _members.length, "_owner index invalid");

        uint _groupId = _groupIdCounter.current(); // future id of this group
        groups.push(Group(_members, _names, _ownerIndex, 0, 0));
        _groupIdCounter.increment();

        for (uint i = 0; i < _members.length; i++) {
            address _memberAddress = _members[i];
            require(memberToGroupId[_memberAddress] == 0, "Address already in a group");
            memberToGroupId[_memberAddress] = _groupId;
        }

        assert(groups.length == _groupIdCounter.current());
        
        return _groupId;
    }

    /// Deposit a payment into a savings group
    /// @dev Reverts if _amount is not positive
    /// @dev Reverts if caller is not a member of a group
    function deposit() public payable {
        require(msg.value > 0, "Deposit must be > 0");
        uint _groupId = getGroupId();
        Group storage _group = groups[_groupId];
        
        _group.balance += msg.value;
        deposits[msg.sender] += msg.value;
    }

    /// Withdraw funds from a savings group
    /// @notice Only the next payee is allowed to withdraw at any point in time. Transaction will fail if it's not your turn
    /// @param _amount The amount of ether you want to withdraw (wei)
    /// @dev Reverts if _amount is not positive
    /// @dev Reverts if caller is not a member of a group
    /// @dev Reverts if you attempt to withdraw more than your saving group balance
    /// @dev Reverts if the caller is not the next payee (not your turn)
    function withdraw(uint _amount) public {
        require(_amount > 0, "_amount must be > 0");
        uint _groupId = getGroupId();
        Group storage _group = groups[_groupId];
        require(_amount <= _group.balance, "Can't withdraw > current balance");
        require(_group.members[_group.nextPayee] == msg.sender, "Caller is not the next payee");

        // solhint-disable-next-line avoid-low-level-calls
        (bool _sent, ) = payable(msg.sender).call{value: _amount}("");
        require(_sent, "Failed to send Ether");

        _group.balance -= _amount;
        withdrawals[msg.sender] += _amount;

        // cycle through addresses, starting back at index 0 when we reach the end of the list
        _group.nextPayee = (_group.nextPayee + 1) % _group.members.length;
    }

    /// Dissolve savings group and return funds
    /// @notice Delete state from your savings club, and disburse remaining funds
    /// @notice Delete wipes the state of the group, but does not remove it from the list. That group id cannot be reused
    /// @notice WARNING - disburse funds functionality not implemented yet 
    /// @dev Reverts if caller is not a member of a group
    /// @dev Reverts if caller is not the group owner
    function dissolve() public {
        uint _groupId = getGroupId();
        Group storage _group = groups[_groupId];
        require(msg.sender == _group.members[_group.ownerIndex], "Caller is not the group owner");

        // TODO: Need to implement the functionality to disburse the remaining funds fairly

        for (uint i = 0; i < _group.members.length; i++) {
            address _memberAddress = _group.members[i];

            delete memberToGroupId[_memberAddress];
            delete deposits[_memberAddress];
            delete withdrawals[_memberAddress];
        }

        delete groups[_groupId];
    }

    /// Get the group at a given id
    /// @notice Get the group at a given id
    /// @param _id The id for which you want to fetch a corresponding group
    /// @return group id
    function getGroup(uint _id) public view returns (Group memory) {
        return groups[_id];
    }

    /// Get the group id for the calling address
    /// @notice Get the group id for the calling address
    /// @dev Reverts if the address does not belong to a group
    /// @return group id
    function getGroupId() private view returns (uint) {
        uint _groupId = memberToGroupId[msg.sender];
        require(_groupId > 0, "Caller not member of a group");
        return _groupId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}