/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via _msgSender() and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    // old code will return error: stack overflow
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// mapping vs array for storing data, also says iterating over array of length 50 is efficient
// https://ethereum.stackexchange.com/questions/2592/store-data-in-mapping-vs-array


contract Marketplace is Context {
    string public name;
    uint8 public committeeAddressesMin;
    uint8 public committeeAddressesMax;

    // address[50] public committeeAddresses; // minimum 5, maximum 50
    uint8 public committeeCount;
    mapping(address => bool) public committeeAddressMap;
    address[] public committeeAddressArray;
    // https://stackoverflow.com/questions/48898355/soldity-iterate-through-address-mapping in order to know the committee members
    
    address public baseTokenAddress; 
    address private oracleAddress;

    uint256 public committeeProposalPeriodLength;
    uint256 public proposalPeriodLength;
    uint256 public proposalCommitteePreapprovalPeriodLength;

    CommitteeProposal[] public committeeProposals;
    Proposal[] public proposals;

    // Section of array utilities from here: https://github.com/cryptofinlabs/cryptofin-solidity/blob/master/contracts/array-utils/AddressArrayUtils.sol

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

    /**
    * Alternate implementation
    * Assumes there are no duplicates
    */
    function unionB(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        bool[] memory includeMap = new bool[](A.length + B.length);
        uint256 i = 0;
        uint256 count = 0;
        for (i = 0; i < A.length; i++) {
            includeMap[i] = true;
            count++;
        }
        for (i = 0; i < B.length; i++) {
            if (!contains(A, B[i])) {
                includeMap[A.length + i] = true;
                count++;
            }
        }
        address[] memory newAddresses = new address[](count);
        uint256 j = 0;
        for (i = 0; i < A.length; i++) {
            if (includeMap[i]) {
                newAddresses[j] = A[i];
                j++;
            }
        }
        for (i = 0; i < B.length; i++) {
            if (includeMap[A.length + i]) {
                newAddresses[j] = B[i];
                j++;
            }
        }
        return newAddresses;
    }

    /**
    * Computes the difference of two arrays. Assumes there are no duplicates.
    * @param A The first array
    * @param B The second array
    * @return The difference of the two arrays
    */
    function difference(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 count = 0;
        // First count the new length because can't push for in-memory arrays
        for (uint256 i = 0; i < length; i++) {
            address e = A[i];
            if (!contains(B, e)) {
                includeMap[i] = true;
                count++;
            }
        }
        address[] memory newAddresses = new address[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < length; i++) {
            if (includeMap[i]) {
                newAddresses[j] = A[i];
                j++;
            }
        }
        return newAddresses;
    }

    event CommitteeChangeProposal (
        uint256 index, 
        // string proposalType, // add remove or replace
        address proposer,
        address[] addCommitteeAddresses,
        address[] removeCommitteeAddresses,
        uint256 startTime,
        uint256 endTime);

    // maintains committee members
    struct CommitteeProposal {
        // string proposalType; // add remove or replace
        address proposer;
        address[] addCommitteeAddresses;
        address[] removeCommitteeAddresses;
        uint256 startTime;
        uint256 endTime;
        address[] votedAddress;
        mapping(address => bool) votedYesNo;
        bool voteResultSubmitted;
        bool voteEnded;
        bool voteResult;
    }

    function getCommitteeProposalLength() public view returns (uint256) {
        return committeeProposals.length;
    }

    function getProposalsLength() public view returns (uint256) {
        return proposals.length;
    }

    function getCommitteeProposalsVotedAddressLength(uint256 index) public view returns (uint256) {
        require(index < committeeProposals.length, "Index out of bound for committee proposals");
        return committeeProposals[index].votedAddress.length;
    }

    function getCommitteeProposalsVotedAddress(uint256 proposalIndex, uint256 addressIndex) public view returns (address) {
        require(proposalIndex < committeeProposals.length, "Index out of bound for committee proposals");
        require(addressIndex < committeeProposals[proposalIndex].votedAddress.length, "Index out of bound for committee proposals");
        return committeeProposals[proposalIndex].votedAddress[addressIndex];
    }

    function getCommitteeProposalsVotedYesOrNo(uint256 proposalIndex, address voterAddress) public view returns (bool) {
        require(proposalIndex < committeeProposals.length, "Index out of bound for committee proposals");
        return committeeProposals[proposalIndex].votedYesNo[voterAddress];
    }

    function addComitteeProposal(address[] memory addCommitteeAddresses, address[] memory removeCommitteeAddresses) public returns (bool) {
        require(addCommitteeAddresses.length < committeeAddressesMax, "Add committee address exceed committee address max limit");
        require(removeCommitteeAddresses.length < committeeAddressesMax, "Remove committee address exceed committee address max limit");
        require(!hasDuplicate(addCommitteeAddresses), "Add committee address cannot have duplicates");
        require(!hasDuplicate(removeCommitteeAddresses), "Remove committee address cannot have duplicates");
        require(intersect(addCommitteeAddresses, removeCommitteeAddresses).length == 0, 
            "Add and remove addresses cannot intersect");

        CommitteeProposal memory proposal;
        // proposal.proposalType = "remove";
        proposal.proposer =  _msgSender();
        proposal.addCommitteeAddresses = addCommitteeAddresses; 
        proposal.removeCommitteeAddresses = removeCommitteeAddresses; 
        proposal.startTime = now;
        proposal.endTime = now + committeeProposalPeriodLength;

        committeeProposals.push(proposal);

        emit CommitteeChangeProposal(
            committeeProposals.length - 1,
            proposal.proposer,
            proposal.addCommitteeAddresses,
            proposal.removeCommitteeAddresses,
            proposal.startTime,
            proposal.endTime);

        return true;
    }

    event Vote (
        string proposalType,
        uint256 index,
        address voter,
        bool yesOrNo
    );

    function voteCommitteeProposal(uint256 proposalIndex, bool yesOrNo) public returns (bool) {
        require(proposalIndex < committeeProposals.length, "Wrong proposalIndex");
        require(now < committeeProposals[proposalIndex].endTime, "Committee proposal voting has ended");
        committeeProposals[proposalIndex].votedAddress.push(_msgSender());
        committeeProposals[proposalIndex].votedYesNo[_msgSender()] = yesOrNo;
        emit Vote("CommitteeProposal", proposalIndex, _msgSender(), yesOrNo);
        return true;
    }

    // function getAll() public view returns (address[] memory){
    //     address[] memory ret = new address[](addressRegistryCount);
    //     for (uint i = 0; i < addressRegistryCount; i++) {
    //         ret[i] = addresses[i];
    //     }
    //     return ret;
    // }

    modifier onlyOracle(){
        require(oracleAddress == _msgSender(), "Oracle only");
        _;
    }

    function getOracleAddress() public view returns (address) {
        return oracleAddress;
    }

    function setOracleAddress(address newOracle) onlyOracle public returns (bool) {
        oracleAddress = newOracle;
    }

    // uint256 public committeeProposalPeriodLength;
    // uint256 public proposalPeriodLength;
    // uint256 public proposalCommitteePreapprovalPeriodLength;

    function setCommitteeProposalPeriodLength(uint256 newCommitteeProposalPeriodLength) onlyOracle public returns (bool) {
        committeeProposalPeriodLength = newCommitteeProposalPeriodLength;
    }

    function setProposalPeriodLength(uint256 newProposalPeriodLength) onlyOracle public returns (bool) {
        proposalPeriodLength = newProposalPeriodLength;
    }

    function setProposalCommitteePreapprovalPeriodLength(uint256 newProposalCommitteePreapprovalPeriodLength) onlyOracle public returns (bool) {
        proposalCommitteePreapprovalPeriodLength = newProposalCommitteePreapprovalPeriodLength;
    }

    function submitCommitteeVoteResult(uint256 proposalIndex, bool yesOrNo) onlyOracle public returns (bool) {
        require(now > committeeProposals[proposalIndex].endTime, "Comittee proposal vote has not ended");
        committeeProposals[proposalIndex].voteEnded = true;
        committeeProposals[proposalIndex].voteResultSubmitted = true;
        committeeProposals[proposalIndex].voteResult = yesOrNo;
    }

    modifier onlyCommittee(){
        require(committeeAddressMap[_msgSender()], "Committee member only");
        _;
    }

    function updateCommitteeArray(
        address[] memory addCommitteeAddresses, address[] memory removeCommitteeAddresses) internal returns (bool) {
        address[] memory result = difference(unionB(committeeAddressArray, addCommitteeAddresses), removeCommitteeAddresses);
        while(committeeAddressArray.length > result.length) {
            committeeAddressArray.pop();
        }
        for (uint256 i = 0; i < result.length; i++) {
            committeeAddressArray[i] = result[i];
        }
        return true;
    }

    function executeCommitteeProposal(uint256 proposalIndex) onlyOracle public returns (bool) {
        uint256 addCount;
        uint256 removeCount;

        for (uint8 i = 0; i < committeeProposals[proposalIndex].addCommitteeAddresses.length; i++) {
            if (committeeAddressMap[committeeProposals[proposalIndex].addCommitteeAddresses[i]] == false) {
                addCount += 1;
            }
        }

        for (uint8 i = 0; i < committeeProposals[proposalIndex].removeCommitteeAddresses.length; i++) {
            if (committeeAddressMap[committeeProposals[proposalIndex].removeCommitteeAddresses[i]] == true) {
                removeCount += 1;
            }
        }

        uint256 lengthAfterExecution = committeeCount + addCount - removeCount;
        require(lengthAfterExecution >= committeeAddressesMin, 
            "Final committeeCount cannot be less than committeeAddressesMin");
        require(lengthAfterExecution <= committeeAddressesMax, 
            "Final committeeCount cannot exceed committeeAddressesMax");
        for (uint8 i = 0; i < committeeProposals[proposalIndex].addCommitteeAddresses.length; i++) {
            committeeAddressMap[committeeProposals[proposalIndex].addCommitteeAddresses[i]] = true;
        }
        for (uint8 i = 0; i < committeeProposals[proposalIndex].removeCommitteeAddresses.length; i++) {
            committeeAddressMap[committeeProposals[proposalIndex].removeCommitteeAddresses[i]] = false;
        }

        committeeCount = uint8(lengthAfterExecution); // TODO(Henry): CommitteeCount is not necesary if we use committeeArray

        updateCommitteeArray(
            committeeProposals[proposalIndex].addCommitteeAddresses,
            committeeProposals[proposalIndex].removeCommitteeAddresses);

        return true;
    }

    event NewProposal(
        uint256 index,
        string proposalContent,
        address proposer,
        uint256 startTime,
        uint256 endTime,
        uint256 committeePreapprovalStartTime,
        uint256 committeePreapprovalEndTime
    );

    event CommitteePreapprovedProposal(
        uint256 index,
        string proposalContent,
        address proposer,
        uint256 startTime,
        uint256 endTime,
        uint256 committeePreapprovalStartTime,
        uint256 committeePreapprovalEndTime
    );

    struct Proposal {
        string proposalContent;
        address proposer;
        uint256 startTime;
        uint256 endTime;

        uint256 committeePreapprovalStartTime;
        uint256 committeePreapprovalEndTime;

        address[] committeePreapprovalVotedAddress;
        mapping(address => bool) committePreapprovalVotedYesNo;

        address[] votedAddress;
        mapping(address => bool) votedYesNo;

        bool committeePreapprovalVoteEnded;
        bool committeePreapprovalSubmitted;
        bool committeePreapproved;

        bool voteEnded;
        bool voteResultSubmitted;
        bool voteResult;
    }

    function getProposalCommitteePreapprovalAddressLength(uint256 index) public view returns (uint256) {
        require(index < proposals.length, "Index out of bound for proposal committee preapproval");
        return proposals[index].committeePreapprovalVotedAddress.length;
    }

    function getProposalCommitteePreapprovalAddress(uint256 proposalIndex, uint256 addressIndex) public view returns (address) {
        require(proposalIndex < proposals.length, "Index out of bound for committee proposals");
        require(addressIndex < proposals[proposalIndex].committeePreapprovalVotedAddress.length, "Index out of bound for committee proposals");
        return proposals[proposalIndex].committeePreapprovalVotedAddress[addressIndex];
    }

    function getProposalCommitteePreapprovalVotedYesOrNo(uint256 proposalIndex, address voterAddress) public view returns (bool) {
        require(proposalIndex < proposals.length, "Index out of bound for committee proposals");
        return proposals[proposalIndex].committePreapprovalVotedYesNo[voterAddress];
    }

    function getProposalsVotedAddressLength(uint256 index) public view returns (uint256) {
        require(index < proposals.length, "Index out of bound for committee proposals");
        return proposals[index].votedAddress.length;
    }

    function getProposalsVotedAddress(uint256 proposalIndex, uint256 addressIndex) public view returns (address) {
        require(proposalIndex < proposals.length, "Index out of bound for committee proposals");
        require(addressIndex < proposals[proposalIndex].votedAddress.length, "Index out of bound for committee proposals");
        return proposals[proposalIndex].votedAddress[addressIndex];
    }

    function getProposalsVotedYesOrNo(uint256 proposalIndex, address voterAddress) public view returns (bool) {
        require(proposalIndex < proposals.length, "Index out of bound for committee proposals");
        return proposals[proposalIndex].votedYesNo[voterAddress];
    }

    function addProposal(string memory proposalContent) public returns (bool) {
        Proposal memory proposal;
        proposal.proposalContent = proposalContent;
        proposal.proposer =  _msgSender();
        uint256 proposalTime = now;
        proposal.committeePreapprovalStartTime = proposalTime;
        proposal.committeePreapprovalEndTime = proposalTime + proposalCommitteePreapprovalPeriodLength;
        proposal.startTime = proposalTime;  // TODO(Henry): proposal start and end relative to committee end? proposal.committeePreapprovalEndTime + 1 days
        proposal.endTime = proposalTime + committeeProposalPeriodLength;
        proposals.push(proposal);

        emit NewProposal(
            proposals.length - 1,
            proposal.proposalContent,
            proposal.proposer,
            proposal.startTime,
            proposal.endTime,
            proposal.committeePreapprovalStartTime,
            proposal.committeePreapprovalEndTime);

        return true;
    }

    function committeePreapprovalVote(uint256 proposalIndex, bool yesOrNo) onlyCommittee public returns (bool) {
        require(proposalIndex < proposals.length, "Wrong proposalIndex");
        require(now < proposals[proposalIndex].committeePreapprovalEndTime, "Committee preapproval ended");
        proposals[proposalIndex].votedAddress.push(_msgSender());
        proposals[proposalIndex].votedYesNo[_msgSender()] = yesOrNo;
        emit Vote("ProposalCommitteePreapproval", proposalIndex, _msgSender(), yesOrNo);
        return true;
    }

    // TODO(Henry): emit event?
    function submitCommitteePreapproval(uint256 proposalIndex, bool yesOrNo) onlyCommittee public returns (bool) {
        require(proposalIndex < committeeProposals.length, "Wrong proposalIndex"); // TODO(Henry): replace with modifier?
        require(now > proposals[proposalIndex].committeePreapprovalEndTime, "Committee preapprove has not ended");
        proposals[proposalIndex].committeePreapprovalVoteEnded = true;
        proposals[proposalIndex].committeePreapprovalSubmitted = true;
        proposals[proposalIndex].committeePreapproved = yesOrNo;
    }

    function voteProposal(uint256 proposalIndex, bool yesOrNo) public returns (bool) {
        require(proposalIndex < proposals.length, "Wrong proposalIndex");
        require(proposals[proposalIndex].committeePreapproved, "Proposal is not committee preapproved");
        require(now < proposals[proposalIndex].endTime, "Voting period ended");
        proposals[proposalIndex].votedAddress.push(_msgSender());
        proposals[proposalIndex].votedYesNo[_msgSender()] = yesOrNo;
        emit Vote("Proposal", proposalIndex, _msgSender(), yesOrNo);
        return true;
    }

    // function calculateProposal() public returns (bool) {}

    // TODO(Henry): emit event?
    function submitProposalResult(uint256 proposalIndex, bool yesOrNo) onlyCommittee public returns (bool) {
        require(proposals[proposalIndex].committeePreapproved, "Proposal was not committee preapproved");
        require(now > proposals[proposalIndex].endTime, "Proposal vote has not ended");
        proposals[proposalIndex].voteEnded = true;
        proposals[proposalIndex].voteResultSubmitted = true;
        proposals[proposalIndex].voteResult = yesOrNo;
    }

    constructor() public {
        name = "Dapp University Marketplace";
        committeeAddressesMin = 5;
        committeeAddressesMax = 50;

        // just for unit test
        oracleAddress = _msgSender();
        committeeProposalPeriodLength = 14 days;
        proposalCommitteePreapprovalPeriodLength = 14 days;

        // addCommitteeProposal();
        addProposal('test proposal');
    }
}