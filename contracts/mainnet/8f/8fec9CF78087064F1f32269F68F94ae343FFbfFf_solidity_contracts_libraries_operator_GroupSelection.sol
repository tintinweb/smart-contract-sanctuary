pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../utils/BytesLib.sol";

/// @title Group Selection
/// @notice The group selection protocol is an interactive method of selecting
/// candidate group from the set of all stakers given a pseudorandom seed value.
///
/// The protocol produces a representative result, where each staker's profit is
/// proportional to the number of tokens they have staked. Produced candidate
/// groups are of constant size.
///
/// Group selection protocol accepts seed as an input - a pseudorandom value
/// used to construct candidate tickets. Each candidate group member can
/// submit their tickets. The maximum number of tickets one can submit depends
/// on their staking weight - relation of the minimum stake to the candidate's
/// stake.
///
/// There is a certain timeout, expressed in blocks, when tickets can be
/// submitted. Each ticket is a mix of staker's address, virtual staker index
/// and group selection seed. Candidate group members are selected based on
/// the best tickets submitted. There has to be a minimum number of tickets
/// submitted, equal to the candidate group size so that the protocol can
/// complete successfully.
library GroupSelection {

    using SafeMath for uint256;
    using BytesLib for bytes;

    struct Storage {
        // Tickets submitted by member candidates during the current group
        // selection execution and accepted by the protocol for the
        // consideration.
        uint64[] tickets;

        // Information about ticket submitters (group member candidates).
        mapping(uint256 => address) candidate;

        // Pseudorandom seed value used as an input for the group selection.
        uint256 seed;

        // Timeout in blocks after which the ticket submission is finished.
        uint256 ticketSubmissionTimeout;

        // Number of block at which the group selection started and from which
        // ticket submissions are accepted.
        uint256 ticketSubmissionStartBlock;

        // Indicates whether a group selection is currently in progress.
        // Concurrent group selections are not allowed.
        bool inProgress;

        // Captures the minimum stake when group selection starts. This is to ensure the
        // same staking weight divisor is applied for all member candidates participating.
        uint256 minimumStake;

        // Map simulates a sorted linked list of ticket values by their indexes.
        // key -> value represent indices from the tickets[] array.
        // 'key' index holds an index of a ticket and 'value' holds an index
        // of the next ticket. Tickets are sorted by their value in
        // descending order starting from the tail.
        // Ex. tickets = [151, 42, 175, 7]
        // tail: 2 because tickets[2] = 175
        // previousTicketIndex[0] -> 1
        // previousTicketIndex[1] -> 3
        // previousTicketIndex[2] -> 0
        // previousTicketIndex[3] -> 3 note: index that holds a lowest
        // value points to itself because there is no `nil` in Solidity.
        // Traversing from tail: [2]->[0]->[1]->[3] result in 175->151->42->7
        bytes previousTicketIndices;

        // Tail represents an index of a ticket in a tickets[] array which holds
        // the highest ticket value. It is a tail of the linked list defined by
        // `previousTicketIndex`.
        uint256 tail;

        // Size of a group in the threshold relay.
        uint256 groupSize;
    }

    /// @notice Starts group selection protocol.
    /// @param _seed pseudorandom seed value used as an input for the group
    /// selection. All submitted tickets needs to have the seed mixed-in into the
    /// value.
    function start(Storage storage self, uint256 _seed) public {
        // We execute the minimum required cleanup here needed in case the
        // previous group selection failed and did not clean up properly in
        // finish function.
        cleanupTickets(self);
        self.inProgress = true;
        self.seed = _seed;
        self.ticketSubmissionStartBlock = block.number;
    }

    /// @notice Finishes group selection protocol clearing up all the submitted
    /// tickets. This function may be expensive if not executed as a part of
    /// another transaction consuming a lot of gas and as a result, getting
    /// gas refund for clearing up the storage.
    function finish(Storage storage self) public {
        cleanupCandidates(self);
        cleanupTickets(self);
        self.inProgress = false;
    }

    /// @notice Submits ticket to request to participate in a new candidate group.
    /// @param ticket Bytes representation of a ticket that holds the following:
    /// - ticketValue: first 8 bytes of a result of keccak256 cryptography hash
    ///   function on the combination of the group selection seed (previous
    ///   beacon output), staker-specific value (address) and virtual staker index.
    /// - stakerValue: a staker-specific value which is the address of the staker.
    /// - virtualStakerIndex: 4-bytes number within a range of 1 to staker's weight;
    ///   has to be unique for all tickets submitted by the given staker for the
    ///   current candidate group selection.
    /// @param stakingWeight Ratio of the minimum stake to the candidate's
    /// stake.
    function submitTicket(
        Storage storage self,
        bytes32 ticket,
        uint256 stakingWeight
    ) public {
        uint64 ticketValue;
        uint160 stakerValue;
        uint32 virtualStakerIndex;

        bytes memory ticketBytes = abi.encodePacked(ticket);
        /* solium-disable-next-line */
        assembly {
            // ticket value is 8 bytes long
            ticketValue := mload(add(ticketBytes, 8))
            // staker value is 20 bytes long
            stakerValue := mload(add(ticketBytes, 28))
            // virtual staker index is 4 bytes long
            virtualStakerIndex := mload(add(ticketBytes, 32))
        }

        submitTicket(
            self,
            ticketValue,
            uint256(stakerValue),
            uint256(virtualStakerIndex),
            stakingWeight
        );
    }

    /// @notice Submits ticket to request to participate in a new candidate group.
    /// @param ticketValue First 8 bytes of a result of keccak256 cryptography hash
    /// function on the combination of the group selection seed (previous
    /// beacon output), staker-specific value (address) and virtual staker index.
    /// @param stakerValue Staker-specific value which is the address of the staker.
    /// @param virtualStakerIndex 4-bytes number within a range of 1 to staker's weight;
    /// has to be unique for all tickets submitted by the given staker for the
    /// current candidate group selection.
    /// @param stakingWeight Ratio of the minimum stake to the candidate's
    /// stake.
    function submitTicket(
        Storage storage self,
        uint64 ticketValue,
        uint256 stakerValue,
        uint256 virtualStakerIndex,
        uint256 stakingWeight
    ) public {
        if (block.number > self.ticketSubmissionStartBlock.add(self.ticketSubmissionTimeout)) {
            revert("Ticket submission is over");
        }

        if (self.candidate[ticketValue] != address(0)) {
            revert("Duplicate ticket");
        }

        if (isTicketValid(
            ticketValue,
            stakerValue,
            virtualStakerIndex,
            stakingWeight,
            self.seed
        )) {
            addTicket(self, ticketValue);
        } else {
            revert("Invalid ticket");
        }
    }

    /// @notice Performs full verification of the ticket.
    function isTicketValid(
        uint64 ticketValue,
        uint256 stakerValue,
        uint256 virtualStakerIndex,
        uint256 stakingWeight,
        uint256 groupSelectionSeed
    ) internal view returns(bool) {
        uint64 ticketValueExpected;
        bytes memory ticketBytes = abi.encodePacked(
            keccak256(
                abi.encodePacked(
                    groupSelectionSeed,
                    stakerValue,
                    virtualStakerIndex
                )
            )
        );
        // use first 8 bytes to compare ticket values
        /* solium-disable-next-line */
        assembly {
            ticketValueExpected := mload(add(ticketBytes, 8))
        }

        bool isVirtualStakerIndexValid = virtualStakerIndex > 0 && virtualStakerIndex <= stakingWeight;
        bool isStakerValueValid = stakerValue == uint256(msg.sender);
        bool isTicketValueValid = ticketValue == ticketValueExpected;

        return isVirtualStakerIndexValid && isStakerValueValid && isTicketValueValid;
    }

    /// @notice Adds a new, verified ticket. Ticket is accepted when it is lower
    /// than the currently highest ticket or when the number of tickets is still
    /// below the group size.
    function addTicket(Storage storage self, uint64 newTicketValue) internal {
        uint256[] memory previousTicketIndex = readPreviousTicketIndices(self);
        uint256[] memory ordered = getTicketValueOrderedIndices(
            self,
            previousTicketIndex
        );

        // any ticket goes when the tickets array size is lower than the group size
        if (self.tickets.length < self.groupSize) {
            // no tickets
            if (self.tickets.length == 0) {
                self.tickets.push(newTicketValue);
            // higher than the current highest
            } else if (newTicketValue > self.tickets[self.tail]) {
                self.tickets.push(newTicketValue);
                uint256 oldTail = self.tail;
                self.tail = self.tickets.length-1;
                previousTicketIndex[self.tail] = oldTail;
            // lower than the current lowest
            } else if (newTicketValue < self.tickets[ordered[0]]) {
                self.tickets.push(newTicketValue);
                // last element points to itself
                previousTicketIndex[self.tickets.length - 1] = self.tickets.length - 1;
                // previous lowest ticket points to the new lowest
                previousTicketIndex[ordered[0]] = self.tickets.length - 1;
            // higher than the lowest ticket value and lower than the highest ticket value
            } else {
                self.tickets.push(newTicketValue);
                uint256 j = findReplacementIndex(self, newTicketValue, ordered);
                previousTicketIndex[self.tickets.length - 1] = previousTicketIndex[j];
                previousTicketIndex[j] = self.tickets.length - 1;
            }
            self.candidate[newTicketValue] = msg.sender;
        } else if (newTicketValue < self.tickets[self.tail]) {
            uint256 ticketToRemove = self.tickets[self.tail];
            // new ticket is lower than currently lowest
            if (newTicketValue < self.tickets[ordered[0]]) {
                // replacing highest ticket with the new lowest
                self.tickets[self.tail] = newTicketValue;
                uint256 newTail = previousTicketIndex[self.tail];
                previousTicketIndex[ordered[0]] = self.tail;
                previousTicketIndex[self.tail] = self.tail;
                self.tail = newTail;
            } else { // new ticket is between lowest and highest
                uint256 j = findReplacementIndex(self, newTicketValue, ordered);
                self.tickets[self.tail] = newTicketValue;
                // do not change the order if a new ticket is still highest
                if (j != self.tail) {
                    uint newTail = previousTicketIndex[self.tail];
                    previousTicketIndex[self.tail] = previousTicketIndex[j];
                    previousTicketIndex[j] = self.tail;
                    self.tail = newTail;
                }
            }
            // we are replacing tickets so we also need to replace information
            // about the submitter
            delete self.candidate[ticketToRemove];
            self.candidate[newTicketValue] = msg.sender;
        }
        storePreviousTicketIndices(self, previousTicketIndex);
    }

    /// @notice Use binary search to find an index for a new ticket in the tickets[] array
    function findReplacementIndex(
        Storage storage self,
        uint64 newTicketValue,
        uint256[] memory ordered
    ) internal view returns (uint256) {
        uint256 lo = 0;
        uint256 hi = ordered.length - 1;
        uint256 mid = 0;
        while (lo <= hi) {
            mid = (lo + hi) >> 1;
            if (newTicketValue < self.tickets[ordered[mid]]) {
                hi = mid - 1;
            } else if (newTicketValue > self.tickets[ordered[mid]]) {
                lo = mid + 1;
            } else {
                return ordered[mid];
            }
        }

        return ordered[lo];
    }

    function readPreviousTicketIndices(Storage storage self)
        internal view returns (uint256[] memory uncompressed)
    {
        bytes memory compressed = self.previousTicketIndices;
        uncompressed = new uint256[](self.groupSize);
        for (uint256 i = 0; i < compressed.length; i++) {
            uncompressed[i] = uint256(uint8(compressed[i]));
        }
    }

    function storePreviousTicketIndices(
        Storage storage self,
        uint256[] memory uncompressed
    ) internal {
        bytes memory compressed = new bytes(uncompressed.length);
        for (uint256 i = 0; i < compressed.length; i++) {
            compressed[i] = bytes1(uint8(uncompressed[i]));
        }
        self.previousTicketIndices = compressed;
    }

    /// @notice Creates an array of ticket indexes based on their values in the
    ///  ascending order:
    ///
    /// ordered[n-1] = tail
    /// ordered[n-2] = previousTicketIndex[tail]
    /// ordered[n-3] = previousTicketIndex[ordered[n-2]]
    function getTicketValueOrderedIndices(
        Storage storage self,
        uint256[] memory previousIndices
    ) internal view returns (uint256[] memory) {
        uint256[] memory ordered = new uint256[](self.tickets.length);
        if (ordered.length > 0) {
            ordered[self.tickets.length-1] = self.tail;
            if (ordered.length > 1) {
                for (uint256 i = self.tickets.length - 1; i > 0; i--) {
                    ordered[i-1] = previousIndices[ordered[i]];
                }
            }
        }

        return ordered;
    }

    /// @notice Gets selected participants in ascending order of their tickets.
    function selectedParticipants(Storage storage self) public view returns (address[] memory) {
        require(
            block.number >= self.ticketSubmissionStartBlock.add(self.ticketSubmissionTimeout),
            "Ticket submission in progress"
        );

        require(self.tickets.length >= self.groupSize, "Not enough tickets submitted");

        uint256[] memory previousTicketIndex = readPreviousTicketIndices(self);
        address[] memory selected = new address[](self.groupSize);
        uint256 ticketIndex = self.tail;
        selected[self.tickets.length - 1] = self.candidate[self.tickets[ticketIndex]];
        for (uint256 i = self.tickets.length - 1; i > 0; i--) {
            ticketIndex = previousTicketIndex[ticketIndex];
            selected[i-1] = self.candidate[self.tickets[ticketIndex]];
        }

        return selected;
    }

    /// @notice Clears up data of the group selection tickets.
    function cleanupTickets(Storage storage self) internal {
        delete self.tickets;
        self.tail = 0;
    }

    /// @notice Clears up data of the group selection candidates.
    /// This operation may have a significant cost if not executed as a part of
    /// another transaction consuming a lot of gas and as a result, getting
    /// gas refund for clearing up the storage.
    function cleanupCandidates(Storage storage self) internal {
        for (uint i = 0; i < self.tickets.length; i++) {
            delete self.candidate[self.tickets[i]];
        }
    }
}
