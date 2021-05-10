/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.0 <0.8.0;

contract C98MSiGrc7 {

    address[] private _owners;
    mapping(address => uint16) private _voteWeights;
    VoteRequirement private _voteRequirement;

    uint32 private _requestId;
    Request private _request;
    mapping(address => uint32) private _votes;
    VoteProgress private _voteProgress;

    /// @dev Initialize wallet, with a list of initial owners, assume all owners have a weight of 1
    /// @param owners_ List of owners's address
    /// @param requiredVote_ Number of votes needed to execute the request
    constructor(address[] memory owners_, uint16 requiredVote_) {
        VoteRequirement memory requirement;
        if (owners_.length == 0) {
            _owners = new address[](1);
            _owners[0] = msg.sender;
            _voteWeights[msg.sender] = 1;
            requirement.totalVote = 1;
        }
        else {
            uint256 i;
            for (i = 0; i < owners_.length; i++) {
                address owner = owners_[i];
                if (_voteWeights[owner] == 0) {
                    _owners.push(owner);
                    _voteWeights[owner] = 1;
                }
            }
            requirement.totalVote = uint16(_owners.length);
        }
        if (requiredVote_ == 0 || requiredVote_ > requirement.totalVote) {
            requirement.requiredVote = requirement.totalVote;
        }
        else {
            requirement.requiredVote = requiredVote_;
        }
        _voteRequirement = requirement;
    }

    event Requested(uint256 requestId, address indexed destination, uint256 value, bytes data, uint16 currentVote, uint16 requiredVote);
    event Voted(address owner, uint256 requestId, uint16 currentVote, uint16 requiredVote);
    event Revoked(address owner, uint256 requestId, uint16 currentVote, uint16 requiredVote);
    event Executed(bool status, uint256 requestId, address indexed destination, uint256 value, bytes data);
    event Cancelled(uint256 requestId);
    event OwnersChanged(address[] owners, uint16 requireVote, uint16 totalVote);
    event Deposited(address indexed sender, uint256 value);

    // Data structure to store information of a request
    struct Request {
        address destination;
        uint256 value;
        bytes data;
    }

    // Data structure to store information for the vote of current request
    struct VoteProgress {
        uint32 requestId;
        uint64 timestamp;
        uint16 currentVote;
        uint16 requiredVote;
    }

    // Data structure to store information about voting weight
    struct VoteRequirement {
        uint16 requiredVote;
        uint16 totalVote;
    }

    modifier selfOnly() {
        require(msg.sender == address(this), "C98MSiG: Wallet only");
        _;
    }

    modifier isOwner(address owner) {
        require(_voteWeights[owner] > 0, "C98MSiG: Not an owner");
        _;
    }

    modifier notOwner(address owner) {
        require(_voteWeights[owner] == 0, "C98MSiG: Already an owner");
        _;
    }

    modifier validVotingPower(uint256 vPower) {
        require(vPower > 0, "C98MSiG: Invalid vote weight");
        _;
    }

    fallback() external payable {
        if (msg.value > 0) {
            emit Deposited(msg.sender, msg.value);
        }
    }

    /// @dev enable wallet to receive ETH
    receive() external payable {
        if (msg.value > 0) {
            emit Deposited(msg.sender, msg.value);
        }
    }

    /// @dev return list of currents owners and their respective voting weight
    /// @return Returns (Array of owners's address, Array of owner's voting weight)
    function owners() public view returns (address[] memory, uint256[] memory) {
        uint256[] memory values = new uint256[](_owners.length);
        uint256 i;
        for (i = 0; i < _owners.length; i++) {
            values[i] = (_voteWeights[_owners[i]]);
        }
        return (_owners, values);
    }

    /// @dev Return current request information
    /// @return destination destination address of the recipient to interface with (address/contract...)
    /// @return value value of ETH to send
    /// @return data data data of the function call in ABI encoded format
    function request() public view returns (address destination, uint256 value, bytes memory data) {
        Request memory req = _request;
        return (req.destination, req.value, req.data);
    }

    /// @dev Return current number of votes vs required number of votes to execute request
    /// @return requestId ID of current request
    /// @return timestamp Timestamp when the request is created
    /// @return currentVote Number of votes for current request
    /// @return requiredVote Required number of votes to execute current request
    function requestProgress() public view returns (uint32 requestId, uint64 timestamp, uint16 currentVote, uint16 requiredVote) {
        VoteProgress memory progress = _voteProgress;
        return (progress.requestId, progress.timestamp, progress.currentVote, progress.requiredVote);
    }

    /// @dev Return required number of votes vs total number of votes of all owners
    /// @return requiredVote Required number of votes to execute request
    /// @return totalVote Total number of votes of all owners
    function voteRequirement() public view returns (uint16 requiredVote, uint16 totalVote) {
        VoteRequirement memory requirement = _voteRequirement;
        return (requirement.requiredVote, requirement.totalVote);
    }

    /// @dev Submit a new request for voting, the owner submitting request will count as voted.
    /// @param destination address of the recipient to interface with (address/contract...)
    /// @param value of ETH to send
    /// @param data data of the function call in ABI encoded format
    function createRequest(address destination, uint256 value, bytes memory data)
        isOwner(msg.sender)
        public returns (bool) {
        VoteProgress memory progress = _voteProgress;
        require(progress.requestId == 0, "C98MSiG: Request pending");

        Request memory req;
        req.destination = destination;
        req.value = value;
        req.data = data;
        progress.requestId = _requestId + 1;
        progress.timestamp = uint64(block.timestamp);
        progress.requiredVote = _voteRequirement.requiredVote;
        _request = req;
        _requestId = progress.requestId;
        _voteProgress = progress;
        vote();

        emit Requested(progress.requestId, req.destination, req.value, req.data, progress.currentVote, progress.requiredVote);
        return true;
    }

    /// @dev Owner vote for the current request. Then execute the request if enough votes
    function vote()
        isOwner(msg.sender)
        public returns (bool) {
        VoteProgress memory progress = _voteProgress;
        require(progress.requestId > 0, "C98MSiG: No pending request");
        if (_votes[msg.sender] < progress.requestId) {
            _votes[msg.sender] = progress.requestId;
            progress.currentVote += _voteWeights[msg.sender];
            _voteProgress = progress;
            emit Voted(msg.sender, progress.requestId, progress.currentVote, progress.requiredVote);
        }
        if (progress.currentVote >= progress.requiredVote) {
            Request memory req = _request;
            (bool success,) = req.destination.call{value: req.value}(req.data);
            if (success) {
                delete _request;
                delete _voteProgress;
                Executed(true, progress.requestId, req.destination, req.value, req.data);
            }
            else {
                Executed(false, progress.requestId, req.destination, req.value, req.data);
            }
        }
        return true;
    }

    /// @dev Owner cancel their vote for the current request
    function revoke()
        isOwner(msg.sender)
        public returns (bool) {
        VoteProgress memory progress = _voteProgress;
        require(progress.requestId > 0, "C98MSiG: No pending request");
        require(_votes[msg.sender] == progress.requestId, "C98MSiG: User not voted");
        delete _votes[msg.sender];
        progress.currentVote -= _voteWeights[msg.sender];
        _voteProgress = progress;
        emit Revoked(msg.sender, progress.requestId, progress.currentVote, progress.requiredVote);
        return true;
    }

    /// @dev Cancel current request. Throw error if request does not exist
    function cancelRequest()
        isOwner(msg.sender)
        public returns (bool) {
        VoteProgress memory progress = _voteProgress;
        require(progress.requestId > 0, "C98MSiG: No pending request");
        require(block.timestamp - progress.timestamp > 600, "C98MSiG: 10mins note passed");

        delete _request;
        delete _voteProgress;

        emit Cancelled(progress.requestId);
        return true;
    }

    /// @dev Add/remove/change owner, with their respective voting weight,
    /// and number of votes needed to perform the request
    /// @param nOwners Array of owners' address that need to change
    /// @param vPowers Array of voting weight of the nOwners, vPower == 0 will remove the respective user
    /// @param vRate New number of required votes to perform the request. vRate == 0 will keep the current number of required votes
    function changeOwners(address[] memory nOwners, uint16[] memory vPowers, uint16 vRate)
        selfOnly()
        public returns (bool) {

        VoteRequirement memory requirement = _voteRequirement;
        uint256 i;
        for (i = 0; i < nOwners.length; i++) {
            address nOwner = nOwners[i];
            uint16 cPower = _voteWeights[nOwner];
            uint16 vPower = vPowers[i];
            require(vPower <= 256, "C98MSiG: Invalid vRate");
            if (cPower > 0) {
                if (vPower == 0) {
                    uint256 j;
                    for(j = 0; j < _owners.length; j++) {
                        if (_owners[j] == nOwner) {
                            _owners[j] = _owners[_owners.length - 1];
                            _owners.pop();
                            delete _votes[nOwner];
                            break;
                        }
                    }
                }
                requirement.totalVote -= cPower;
            }
            else {
                if (vPower > 0) {
                    _owners.push(nOwner);
                }
            }
            _voteWeights[nOwner] = vPower;
            requirement.totalVote += vPower;
        }
        if (vRate > 0) {
            requirement.requiredVote = vRate;
        }
        uint256 ownerCount = _owners.length;
        require(requirement.requiredVote > 0, "C98MSiG: Invalid vRate");
        require(requirement.requiredVote <= requirement.totalVote, "C98MSiG: Invalid vRate");
        require(requirement.totalVote <= 4096, "C98MSiG: Max weight reached");
        require(ownerCount > 0, "C98MSiG: At least 1 owner");
        require(ownerCount <= 64, "C98MSiG: Max owner reached");
        _voteRequirement = requirement;

        OwnersChanged(nOwners, requirement.requiredVote, requirement.totalVote);
        return true;
    }
}

contract C98MSiGrc7Factory {
    /// @dev Create a new multisig wallet
    /// @param owners_ List of intial owners. If the list is empty, sending adress will be assigned as owner
    /// @param requiredVote_ Number of votes needed to perform the request
    function createMulitSig(address[] memory owners_, uint16 requiredVote_)
        public returns (C98MSiGrc7 wallet) {
        wallet = new C98MSiGrc7(owners_, requiredVote_);
    }
}