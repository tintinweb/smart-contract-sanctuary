/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

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

// mapping vs array for storing data, also says iterating over array of length 50 is efficient
// https://ethereum.stackexchange.com/questions/2592/store-data-in-mapping-vs-array


contract Marketplace is Context {
    string public name;
    uint8 public committeeAddressesMin; // TODO(Henry): add setter, only oracle
    uint8 public committeeAddressesMax; // TODO(Henry): add setter
    uint8 public committeeCount;
    mapping(address => bool) public committeeAddressMap;
    // address[] public committeeAddressArray;
    // https://stackoverflow.com/questions/48898355/soldity-iterate-through-address-mapping in order to kblock.timestamp the committee members
    
    // address public baseTokenAddress; 
    address private oracleAddress;

    uint256 public committeeProposalPeriodLength;
    uint256 public proposalPeriodLength;
    uint256 public proposalCommitteePreapprovalPeriodLength;

    uint256 public committeeProposalsCount;
    uint256 public proposalsCount;
    mapping(uint256 => CommitteeProposal) private committeeProposals;
    mapping(uint256 => Proposal) private proposals;

    uint8 public thresholdsCount;
    mapping (uint8 => Threshold) public thresholds;

    struct Threshold {
        string name;
        uint256 quorumNumerator;
        uint256 quorumDenominator;
        uint256 approvalNumerator;
        uint256 approvalDenominator;
    }

    event ThresholdChange(
        bool newThresh,
        uint8 id,
        string name,
        uint256 quorumNumerator,
        uint256 quorumDenominator,
        uint256 approvalNumerator,
        uint256 approvalDenominator);

    // For add, set newThresh to true, changeThresholdID to 0
    // else set newThresh to false and assign changeThresholdID
    function changeThreshold(string memory newName, 
        uint256 quorumNumerator,
        uint256 quorumDenominator,
        uint256 approvalNumerator,
        uint256 approvalDenominator, bool newThresh, uint8 changeThresholdID) public returns (bool) {
        onlyOracle();
        require(thresholdsCount < 255, "Index OOB");
        uint8 thresholdID = changeThresholdID;
        if (newThresh) {
            thresholdID = thresholdsCount;
            thresholdsCount++;
        }
        thresholds[thresholdID].name = newName;
        thresholds[thresholdID].quorumNumerator = quorumNumerator;
        thresholds[thresholdID].quorumDenominator = quorumDenominator;
        thresholds[thresholdID].approvalNumerator = approvalNumerator;
        thresholds[thresholdID].approvalDenominator = approvalDenominator;
        emit ThresholdChange(
            newThresh,
            thresholdID,
            thresholds[thresholdID].name,
            thresholds[thresholdID].quorumNumerator,
            thresholds[thresholdID].quorumDenominator,
            thresholds[thresholdID].approvalNumerator,
            thresholds[thresholdID].approvalDenominator);
        return true;
    }

    struct Vote {
        address voterAddress;
        uint8 yesNoAbstain; // vote 0 for no, 1 for yes, 2 for abstain
    }

    struct VotingInfo {
        uint256 startTime;
        uint256 endTime;

        bool voteResultCalculated;
        bool voteResult;

        uint256 votedAddressCount;
        mapping(uint256 => Vote) votes;
        // mapping(uint256 => address) voterAddress;
        // mapping(address => uint8) yesNoAbstain;
    }

    struct Proposal {
        // uint256 proposalID;
        // string proposalContent;
        bytes32 proposalHash;
        address proposer;

        uint8 proposalType; // 0 for MetaMine Fund Usage, 1 for Token Circulation

        VotingInfo preapprovalVotingInfo;
        VotingInfo votingInfo;
    }

    // maintains committee members
    struct CommitteeProposal {
        // string proposalType; // add remove or replace
        // uint256 proposalID;
        address proposer;

        address[] addCommitteeAddresses;
        address[] removeCommitteeAddresses;

        VotingInfo votingInfo;
    }

    // CommitteeProposal[] public committeeProposals;
    // Proposal[] public proposals;

    // Section of array utilities from here: 
    // https://github.com/cryptofinlabs/cryptofin-solidity/blob/master/contracts/array-utils/AddressArrayUtils.sol

    /**
    * Finds the index of the first occurrence of the given element.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns (index and isIn) for the first occurrence starting from index 0
    */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
        if (A[i] == a) {
            return (i, true);
        }
        }
        return (0, false);
    }

    /**
    * Returns whether or not there's a duplicate. Runs in O(n^2).
    * @param A Array to search
    * @return Returns true if duplicate, false otherwise
    */
    function hasDuplicate(address[] memory A) internal pure returns (bool) {
        if (A.length == 0) {
        return false;
        }
        for (uint256 i = 0; i < A.length - 1; i++) {
        for (uint256 j = i + 1; j < A.length; j++) {
            if (A[i] == A[j]) {
            return true;
            }
        }
        }
        return false;
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
    * Returns the intersection of two arrays. Arrays are treated as collections, so duplicates are kept.
    * @param A The first array
    * @param B The second array
    * @return The intersection of the two arrays
    */
    function intersect(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 newLength = 0;
        for (uint256 i = 0; i < length; i++) {
        if (contains(B, A[i])) {
            includeMap[i] = true;
            newLength++;
            }
        }
        address[] memory newAddresses = new address[](newLength);
        uint256 j = 0;
        for (uint256 i = 0; i < length; i++) {
        if (includeMap[i]) {
            newAddresses[j] = A[i];
            j++;
        }
        }
        return newAddresses;
    }

    // /**
    // * Alternate implementation
    // * Assumes there are no duplicates
    // */
    // function unionB(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
    //     bool[] memory includeMap = new bool[](A.length + B.length);
    //     uint256 i = 0;
    //     uint256 count = 0;
    //     for (i = 0; i < A.length; i++) {
    //         includeMap[i] = true;
    //         count++;
    //     }
    //     for (i = 0; i < B.length; i++) {
    //         if (!contains(A, B[i])) {
    //             includeMap[A.length + i] = true;
    //             count++;
    //         }
    //     }
    //     address[] memory newAddresses = new address[](count);
    //     uint256 j = 0;
    //     for (i = 0; i < A.length; i++) {
    //         if (includeMap[i]) {
    //             newAddresses[j] = A[i];
    //             j++;
    //         }
    //     }
    //     for (i = 0; i < B.length; i++) {
    //         if (includeMap[A.length + i]) {
    //             newAddresses[j] = B[i];
    //             j++;
    //         }
    //     }
    //     return newAddresses;
    // }

    // /**
    // * Computes the difference of two arrays. Assumes there are no duplicates.
    // * @param A The first array
    // * @param B The second array
    // * @return The difference of the two arrays
    // */
    // function difference(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
    //     uint256 length = A.length;
    //     bool[] memory includeMap = new bool[](length);
    //     uint256 count = 0;
    //     // First count the new length because can't push for in-memory arrays
    //     for (uint256 i = 0; i < length; i++) {
    //         address e = A[i];
    //         if (!contains(B, e)) {
    //             includeMap[i] = true;
    //             count++;
    //         }
    //     }
    //     address[] memory newAddresses = new address[](count);
    //     uint256 j = 0;
    //     for (uint256 i = 0; i < length; i++) {
    //         if (includeMap[i]) {
    //             newAddresses[j] = A[i];
    //             j++;
    //         }
    //     }
    //     return newAddresses;
    // }

    function onlyOracle() internal view returns (bool) {
        require(oracleAddress == _msgSender(), "Oracle");
        return true;
    }

    function onlyCommittee() internal view returns (bool) {
        require(committeeAddressMap[_msgSender()], "Committee");
        return true;
    }

    event CommitteeProposalEvent (
        uint256 index, 
        // string proposalType, // add remove or replace
        address proposer,
        address[] addCommitteeAddresses,
        address[] removeCommitteeAddresses,
        uint256 startTime,
        uint256 endTime);

    // https://medium.com/coinmonks/solidity-tutorial-returning-structs-from-public-functions-e78e48efb378
    function getCommitteeProposal(uint256 index) external view returns (address, // proposer,
        // address[] memory, //addCommitteeAddresses,
        // address[] memory, //removeCommitteeAddresses,
        uint256, // startTime,
        uint256, // endTime,
        bool, // voteResultCalculated,
        bool, // voteResult,
        uint256 // votedAddressCount
        ){
        require(index < committeeProposalsCount, "Index OOB");
        return (committeeProposals[index].proposer, 
            // committeeProposals[index].addCommitteeAddresses,
            // committeeProposals[index].removeCommitteeAddresses,
            committeeProposals[index].votingInfo.startTime,
            committeeProposals[index].votingInfo.endTime,
            committeeProposals[index].votingInfo.voteResultCalculated,
            committeeProposals[index].votingInfo.voteResult,
            committeeProposals[index].votingInfo.votedAddressCount);
    }

    function getCommitteeProposalArrays(uint256 index) external view returns (
        address[] memory, //addCommitteeAddresses,
        address[] memory //removeCommitteeAddresses
        ){
        require(index < committeeProposalsCount, "Index OOB");
        return (
            committeeProposals[index].addCommitteeAddresses,
            committeeProposals[index].removeCommitteeAddresses);
    }

    function getCommitteeProposalsVotes(uint256 proposalIndex, uint256 addressIndex) external view returns (Vote memory) {
        require(proposalIndex < committeeProposalsCount, "Index1 OOB");
        require(addressIndex < committeeProposals[proposalIndex].votingInfo.votedAddressCount, "Index2 OOB");
        return committeeProposals[proposalIndex].votingInfo.votes[addressIndex];
    }

    // function getCommitteeProposalsVotedAddress(uint256 proposalIndex, uint256 addressIndex) public view returns (address) {
    //     require(proposalIndex < committeeProposalsCount, "Index1 OOB");
    //     require(addressIndex < committeeProposals[proposalIndex].votingInfo.votedAddressCount, "Index2 OOB");
    //     return committeeProposals[proposalIndex].votingInfo.voterAddress[addressIndex];
    // }

    // function getCommitteeProposalsVotedYesOrNo(uint256 proposalIndex, address voterAddress) public view returns (uint8) {
    //     require(proposalIndex < committeeProposalsCount, "Index OOB");
    //     return committeeProposals[proposalIndex].votingInfo.yesNoAbstain[voterAddress];
    // }

    function getOracleAddress() external view returns (address) {
        return oracleAddress;
    }

    function setCommitteeAddressesMin(uint8 newCommitteeAddressesMin) external returns (bool) {
        onlyOracle();
        committeeAddressesMin = newCommitteeAddressesMin;
        return true;
    }

    function setCommitteeAddressesMax(uint8 newCommitteeAddressesMax) external returns (bool) {
        onlyOracle();
        committeeAddressesMax = newCommitteeAddressesMax;
        return true;
    }

    function setOracleAddress(address newOracle) external returns (bool) {
        onlyOracle();
        oracleAddress = newOracle;
        return true;
    }

    function setCommitteeProposalPeriodLength(uint256 newCommitteeProposalPeriodLength) external returns (bool) {
        onlyOracle();
        committeeProposalPeriodLength = newCommitteeProposalPeriodLength;
        return true;
    }

    function setProposalPeriodLength(uint256 newProposalPeriodLength) external returns (bool) {
        onlyOracle();
        proposalPeriodLength = newProposalPeriodLength;
        return true;
    }

    function setProposalCommitteePreapprovalPeriodLength(uint256 newProposalCommitteePreapprovalPeriodLength) external returns (bool) {
        onlyOracle();
        proposalCommitteePreapprovalPeriodLength = newProposalCommitteePreapprovalPeriodLength;
        return true;
    }

    function addCommitteeProposal(address[] memory addCommitteeAddresses, address[] memory removeCommitteeAddresses) external returns (bool) {
        require(addCommitteeAddresses.length < committeeAddressesMax, "+ limit");
        require(removeCommitteeAddresses.length < committeeAddressesMax, "- limit");
        require(!hasDuplicate(addCommitteeAddresses), "+ dupplicates");
        require(!hasDuplicate(removeCommitteeAddresses), "- duplicates");
        require(intersect(addCommitteeAddresses, removeCommitteeAddresses).length == 0, 
            "+- overlap");

        uint256 proposalID = committeeProposalsCount;
        committeeProposalsCount++;

        // committeeProposals[committeeProposalsCount].proposalID = proposalID;
        committeeProposals[proposalID].proposer =  _msgSender();
        committeeProposals[proposalID].addCommitteeAddresses = addCommitteeAddresses; 
        committeeProposals[proposalID].removeCommitteeAddresses = removeCommitteeAddresses; 
        committeeProposals[proposalID].votingInfo.startTime = block.timestamp;
        committeeProposals[proposalID].votingInfo.endTime = block.timestamp + committeeProposalPeriodLength;

        emit CommitteeProposalEvent(
            proposalID,
            // committeeProposals[proposalID].proposalID,
            committeeProposals[proposalID].proposer,
            committeeProposals[proposalID].addCommitteeAddresses,
            committeeProposals[proposalID].removeCommitteeAddresses,
            committeeProposals[proposalID].votingInfo.startTime,
            committeeProposals[proposalID].votingInfo.endTime);

        return true;
    }

    event VoteCasted (
        string proposalType,
        uint256 index,
        address voter,
        uint8 yesOrNo
    );

    function voteCommitteeProposal(uint256 proposalIndex, uint8 yesNoAbstain) external returns (bool) {
        require(proposalIndex < committeeProposalsCount, "Index OOB");
        require(block.timestamp < committeeProposals[proposalIndex].votingInfo.endTime, "Vote Ended");
        uint256 votedAddressID = committeeProposals[proposalIndex].votingInfo.votedAddressCount;
        committeeProposals[proposalIndex].votingInfo.votedAddressCount++;
        committeeProposals[proposalIndex].votingInfo.votes[votedAddressID].voterAddress = _msgSender();
        committeeProposals[proposalIndex].votingInfo.votes[votedAddressID].yesNoAbstain = yesNoAbstain;

        // committeeProposals[proposalIndex].votingInfo.voterAddress[votedAddressID] = _msgSender();
        // committeeProposals[proposalIndex].votingInfo.yesNoAbstain[_msgSender()] = yesNoAbstain;
        emit VoteCasted("CommitteeProposal", proposalIndex, _msgSender(), yesNoAbstain);
        return true;
    }

    function submitCommitteeVoteResult(uint256 proposalIndex, bool yesOrNo) external returns (bool) {
        onlyOracle();
        require(proposalIndex < committeeProposalsCount, "Index OOB");
        require(block.timestamp > committeeProposals[proposalIndex].votingInfo.endTime, "Not Ended");
        committeeProposals[proposalIndex].votingInfo.voteResultCalculated = true;
        committeeProposals[proposalIndex].votingInfo.voteResult = yesOrNo;
        return true;
    }

    // function updateCommitteeArray(
    //     address[] memory addCommitteeAddresses, address[] memory removeCommitteeAddresses) internal returns (bool) {
    //     address[] memory result = difference(unionB(committeeAddressArray, addCommitteeAddresses), removeCommitteeAddresses);
    //     while(committeeAddressArray.length > result.length) {
    //         committeeAddressArray.pop();
    //     }
    //     for (uint256 i = 0; i < result.length; i++) {
    //         committeeAddressArray[i] = result[i];
    //     }
    //     return true;
    // }

    function executeCommitteeProposal(uint256 proposalIndex) external returns (bool) {
        require(proposalIndex < committeeProposalsCount, "Index OOB");
        // require(block.timestamp > committeeProposals[proposalIndex].endTime, "Committee proposal vote has not ended"); 
        // The above check is not necessary since voteResultCalculated can only be true after end time
        require(committeeProposals[proposalIndex].votingInfo.voteResultCalculated, "Not calculated");
        require(committeeProposals[proposalIndex].votingInfo.voteResult, "Not passed");

        uint256 addCount;
        uint256 removeCount;

        for (uint8 i = 0; i < committeeProposals[proposalIndex].addCommitteeAddresses.length; i++) {
            if (committeeAddressMap[committeeProposals[proposalIndex].addCommitteeAddresses[i]] == false) {
                addCount++;
            }
        }

        for (uint8 i = 0; i < committeeProposals[proposalIndex].removeCommitteeAddresses.length; i++) {
            if (committeeAddressMap[committeeProposals[proposalIndex].removeCommitteeAddresses[i]] == true) {
                removeCount++;
            }
        }

        uint256 lengthAfterExecution = committeeCount + addCount - removeCount;
        require(lengthAfterExecution >= committeeAddressesMin, "result < min");
        require(lengthAfterExecution <= committeeAddressesMax, "result > max");
        for (uint8 i = 0; i < committeeProposals[proposalIndex].addCommitteeAddresses.length; i++) {
            committeeAddressMap[committeeProposals[proposalIndex].addCommitteeAddresses[i]] = true;
        }
        for (uint8 i = 0; i < committeeProposals[proposalIndex].removeCommitteeAddresses.length; i++) {
            committeeAddressMap[committeeProposals[proposalIndex].removeCommitteeAddresses[i]] = false;
        }

        committeeCount = uint8(lengthAfterExecution); // TODO(Henry): CommitteeCount is not necesary if we use committeeArray

        return true;
    }

    event ProposalEvent(
        // string eventType,
        uint256 index,
        // string proposalContent,
        uint8 proposalType,
        bytes32 proposalHash,
        address proposer,
        uint256 startTime,
        uint256 endTime,
        uint256 committeePreapprovalStartTime,
        uint256 committeePreapprovalEndTime
    );

    // event NewProposal(
    //     uint256 index,
    //     // string proposalContent,
    //     bytes32 proposalHash,
    //     address proposer,
    //     uint256 startTime,
    //     uint256 endTime,
    //     uint256 committeePreapprovalStartTime,
    //     uint256 committeePreapprovalEndTime
    // );

    // event CommitteePreapprovedProposal(
    //     uint256 index,
    //     // string proposalContent,
    //     bytes32 proposalHash,
    //     address proposer,
    //     uint256 startTime,
    //     uint256 endTime,
    //     uint256 committeePreapprovalStartTime,
    //     uint256 committeePreapprovalEndTime
    // );

    function getProposalBase(uint256 index) external view returns (address, // proposer,
        // address[] memory, //addCommitteeAddresses,
        // address[] memory, //removeCommitteeAddresses,
        bytes32,// proposalHash;
        uint8 // proposalType; // 0 for MetaMine Fund Usage, 1 for Token Circulation
        //preapproval voting info
        // uint256, // startTime,
        // uint256, // endTime,
        // bool, // voteResultCalculated,
        // bool, // voteResult,
        // uint256 // votedAddressCount
        //general voting info
        // uint256, // startTime,
        // uint256, // endTime,
        // bool, // voteResultCalculated,
        // bool, // voteResult,
        // uint256 // votedAddressCount
        ){
        require(index < proposalsCount, "Index OOB");
        return (proposals[index].proposer, 
            // committeeProposals[index].addCommitteeAddresses,
            // committeeProposals[index].removeCommitteeAddresses,
            proposals[index].proposalHash,
            proposals[index].proposalType
            // proposals[index].preapprovalVotingInfo.startTime,
            // proposals[index].preapprovalVotingInfo.endTime,
            // proposals[index].preapprovalVotingInfo.voteResultCalculated,
            // proposals[index].preapprovalVotingInfo.voteResult,
            // proposals[index].preapprovalVotingInfo.votedAddressCount
            // proposals[index].votingInfo.startTime,
            // proposals[index].votingInfo.endTime,
            // proposals[index].votingInfo.voteResultCalculated,
            // proposals[index].votingInfo.voteResult,
            // proposals[index].votingInfo.votedAddressCount
        );
    }

    function getProposalPreapprovalVotingInfo(uint256 index) external view returns (
        // address, // proposer,
        // address[] memory, //addCommitteeAddresses,
        // address[] memory, //removeCommitteeAddresses,
        // bytes32,// proposalHash;
        // uint8, // proposalType; // 0 for MetaMine Fund Usage, 1 for Token Circulation
        //preapproval voting info
        uint256, // startTime,
        uint256, // endTime,
        bool, // voteResultCalculated,
        bool, // voteResult,
        uint256 // votedAddressCount
        //general voting info
        // uint256, // startTime,
        // uint256, // endTime,
        // bool, // voteResultCalculated,
        // bool, // voteResult,
        // uint256 // votedAddressCount
        ){
        require(index < proposalsCount, "Index OOB");
        return (
            // proposals[index].proposer, 
            // committeeProposals[index].addCommitteeAddresses,
            // committeeProposals[index].removeCommitteeAddresses,
            // proposals[index].proposalHash,
            // proposals[index].proposalType,
            proposals[index].preapprovalVotingInfo.startTime,
            proposals[index].preapprovalVotingInfo.endTime,
            proposals[index].preapprovalVotingInfo.voteResultCalculated,
            proposals[index].preapprovalVotingInfo.voteResult,
            proposals[index].preapprovalVotingInfo.votedAddressCount
            // proposals[index].votingInfo.startTime,
            // proposals[index].votingInfo.endTime,
            // proposals[index].votingInfo.voteResultCalculated,
            // proposals[index].votingInfo.voteResult,
            // proposals[index].votingInfo.votedAddressCount
        );
    }

    function getProposalVotingInfo(uint256 index) external view returns (
        // address, // proposer,
        // address[] memory, //addCommitteeAddresses,
        // address[] memory, //removeCommitteeAddresses,
        // bytes32,// proposalHash;
        // uint8, // proposalType; // 0 for MetaMine Fund Usage, 1 for Token Circulation
        // //preapproval voting info
        // uint256, // startTime,
        // uint256, // endTime,
        // bool, // voteResultCalculated,
        // bool, // voteResult,
        // uint256, // votedAddressCount
        //general voting info
        uint256, // startTime,
        uint256, // endTime,
        bool, // voteResultCalculated,
        bool, // voteResult,
        uint256 // votedAddressCount
        ){
        require(index < proposalsCount, "Index OOB");
        return (
            // proposals[index].proposer, 
            // committeeProposals[index].addCommitteeAddresses,
            // committeeProposals[index].removeCommitteeAddresses,
            // proposals[index].proposalHash,
            // proposals[index].proposalType,
            // proposals[index].preapprovalVotingInfo.startTime,
            // proposals[index].preapprovalVotingInfo.endTime,
            // proposals[index].preapprovalVotingInfo.voteResultCalculated,
            // proposals[index].preapprovalVotingInfo.voteResult,
            // proposals[index].preapprovalVotingInfo.votedAddressCount,
            proposals[index].votingInfo.startTime,
            proposals[index].votingInfo.endTime,
            proposals[index].votingInfo.voteResultCalculated,
            proposals[index].votingInfo.voteResult,
            proposals[index].votingInfo.votedAddressCount
        );
    }

    // function getProposalCommitteePreapprovalVotedAddressLength(uint256 index) external view returns (uint256) {
    //     require(index < proposalsCount, "Index OOB");
    //     return proposals[index].preapprovalVotingInfo.votedAddressCount;
    // }

    function getProposalCommitteePreapprovalVote(uint256 proposalIndex, uint8 addressIndex) external view returns (Vote memory) {
        require(proposalIndex < proposalsCount, "Index1 OOB");
        require(addressIndex < proposals[proposalIndex].preapprovalVotingInfo.votedAddressCount, "Index2 OOB");
        return proposals[proposalIndex].preapprovalVotingInfo.votes[addressIndex];
    }

    // function getProposalCommitteePreapprovalVotedAddress(uint256 proposalIndex, uint8 addressIndex) public view returns (address) {
    //     require(proposalIndex < proposalsCount, "Index1 OOB");
    //     require(addressIndex < proposals[proposalIndex].preapprovalVotingInfo.votedAddressCount, "Index2 OOB");
    //     return proposals[proposalIndex].preapprovalVotingInfo.voterAddress[addressIndex];
    // }

    // function getProposalCommitteePreapprovalVotedYesOrNo(uint256 proposalIndex, address voterAddress) public view returns (uint8) {
    //     require(proposalIndex < proposalsCount, "Index OOB");
    //     return proposals[proposalIndex].preapprovalVotingInfo.yesNoAbstain[voterAddress];
    // }

    // function getProposalsVotedAddressLength(uint256 index) external view returns (uint256) {
    //     require(index < proposalsCount, "Index OOB");
    //     return proposals[index].votingInfo.votedAddressCount;
    // }

    function getProposalsVotes(uint256 proposalIndex, uint256 addressIndex) external view returns (Vote memory) {
        require(proposalIndex < proposalsCount, "Index1 OOB");
        require(addressIndex < proposals[proposalIndex].votingInfo.votedAddressCount, "Index2 OOB");
        return proposals[proposalIndex].votingInfo.votes[addressIndex];
    }

    // function getProposalsVotedAddress(uint256 proposalIndex, uint256 addressIndex) public view returns (address) {
    //     require(proposalIndex < proposalsCount, "Index1 OOB");
    //     require(addressIndex < proposals[proposalIndex].votingInfo.votedAddressCount, "Index2 OOB");
    //     return proposals[proposalIndex].votingInfo.voterAddress[addressIndex];
    // }

    // function getProposalsVotedYesOrNo(uint256 proposalIndex, address voterAddress) public view returns (uint8) {
    //     require(proposalIndex < proposalsCount, "Index OOB");
    //     return proposals[proposalIndex].votingInfo.yesNoAbstain[voterAddress];
    // }

    // function addProposal(string memory proposalContent) public returns (bool) {
    function addProposal(uint8 proposalType, bytes32 proposalHash) external returns (bool) {
        uint256 proposalID = proposalsCount;
        proposalsCount++;
        // proposals[proposalID].proposalID = proposalID;
        // proposal.proposalContent = proposalContent;
        proposals[proposalID].proposalHash = proposalHash;
        proposals[proposalID].proposalType = proposalType;
        proposals[proposalID].proposer =  _msgSender();
        uint256 proposalTime = block.timestamp;
        proposals[proposalID].preapprovalVotingInfo.startTime = proposalTime;
        proposals[proposalID].preapprovalVotingInfo.endTime = proposalTime + proposalCommitteePreapprovalPeriodLength;
        proposals[proposalID].votingInfo.startTime = proposals[proposalID].preapprovalVotingInfo.endTime;
        proposals[proposalID].votingInfo.endTime = proposals[proposalID].preapprovalVotingInfo.endTime + proposalPeriodLength;

        emit ProposalEvent(
            // "NewProposal",
            proposalID,
            // proposals[proposalID].proposalID,
            // proposal.proposalContent,
            proposals[proposalID].proposalType,
            proposals[proposalID].proposalHash,
            proposals[proposalID].proposer,
            proposals[proposalID].votingInfo.startTime,
            proposals[proposalID].votingInfo.endTime,
            proposals[proposalID].preapprovalVotingInfo.startTime,
            proposals[proposalID].preapprovalVotingInfo.endTime);

        return true;
    }

    function committeePreapprovalVote(uint256 proposalIndex, bool yesOrNo) external returns (bool) {
        onlyCommittee();
        require(proposalIndex < proposalsCount, "Index OOB");
        require(block.timestamp < proposals[proposalIndex].preapprovalVotingInfo.endTime, "Ended");
        uint256 committeeVoterID = proposals[proposalIndex].preapprovalVotingInfo.votedAddressCount;
        proposals[proposalIndex].preapprovalVotingInfo.votedAddressCount++;
        proposals[proposalIndex].preapprovalVotingInfo.votes[committeeVoterID].voterAddress = _msgSender();
        proposals[proposalIndex].preapprovalVotingInfo.votes[committeeVoterID].yesNoAbstain = yesOrNo ? 1 : 0;

        // proposals[proposalIndex].preapprovalVotingInfo.voterAddress[committeeVoterID] = _msgSender();
        // proposals[proposalIndex].preapprovalVotingInfo.yesNoAbstain[_msgSender()] = yesOrNo ? 1 : 0;
        emit VoteCasted("ProposalCommitteePreapproval", proposalIndex, _msgSender(), yesOrNo ? 1 : 0);
        return true;
    }

    event ProposalVoteStarting(
        uint256 proposalID,
        uint256 startTime,
        uint256 endTime);

    function submitCommitteePreapproval(uint256 proposalIndex, bool yesOrNo) external returns (bool) {
        onlyOracle();
        require(proposalIndex < proposalsCount, "Index OOB");
        uint256 timestamp = block.timestamp;
        require(timestamp > proposals[proposalIndex].preapprovalVotingInfo.endTime, "Not ended");
        proposals[proposalIndex].preapprovalVotingInfo.voteResultCalculated = true;
        proposals[proposalIndex].preapprovalVotingInfo.voteResult = yesOrNo;

        if (proposals[proposalIndex].preapprovalVotingInfo.voteResult) {
            proposals[proposalIndex].votingInfo.startTime = timestamp;
            proposals[proposalIndex].votingInfo.endTime = timestamp + proposalPeriodLength;
            emit ProposalVoteStarting(proposalIndex, 
                proposals[proposalIndex].votingInfo.startTime, proposals[proposalIndex].votingInfo.endTime);
        }
        return true;
    }

    function voteProposal(uint256 proposalIndex, uint8 vote) external returns (bool) {
        require(proposalIndex < proposalsCount, "Index OOB");
        require(proposals[proposalIndex].preapprovalVotingInfo.voteResult, "Not preapproved"); 
        require(block.timestamp < proposals[proposalIndex].votingInfo.endTime, "Ended");
        uint256 voterID = proposals[proposalIndex].votingInfo.votedAddressCount;
        proposals[proposalIndex].votingInfo.votedAddressCount++;
        proposals[proposalIndex].votingInfo.votes[voterID].voterAddress = _msgSender();
        proposals[proposalIndex].votingInfo.votes[voterID].yesNoAbstain = vote;

        // proposals[proposalIndex].votingInfo.voterAddress[voterID] = _msgSender();
        // proposals[proposalIndex].votingInfo.yesNoAbstain[_msgSender()] = vote;
        emit VoteCasted("Proposal", proposalIndex, _msgSender(), vote);
        return true;
    }

    function submitProposalResult(uint256 proposalIndex, bool yesOrNo) external returns (bool) {
        onlyOracle();
        require(proposalIndex < proposalsCount, "Index OOB");
        require(proposals[proposalIndex].preapprovalVotingInfo.voteResult, "Not preapproved");
        require(block.timestamp > proposals[proposalIndex].votingInfo.endTime, "Not ended");
        proposals[proposalIndex].votingInfo.voteResultCalculated = true;
        proposals[proposalIndex].votingInfo.voteResult = yesOrNo;
        return true;
    }

    constructor () {
        name = "MINE Governance";
        committeeAddressesMin = 5;
        committeeAddressesMax = 50;

        // just for unit test
        oracleAddress = _msgSender();
        committeeProposalPeriodLength = 14 days;
        proposalCommitteePreapprovalPeriodLength = 14 days;
        proposalPeriodLength = 21 days;

        changeThreshold("Fund", 30, 100, 50, 100, true, 0);
        changeThreshold("Token", 80, 100, 60, 100, true, 0);

        // addCommitteeProposal();
        // addProposal('test proposal');
    }
}