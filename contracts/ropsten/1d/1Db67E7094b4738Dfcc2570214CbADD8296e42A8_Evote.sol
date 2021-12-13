// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./0_Admin.sol";

contract Evote is Admin {

    ////// EVENTS //////

    event EncryptedVote(uint indexed _pollID, string _vote, bytes32 indexed _voteHash, address indexed _voter);

    event VoterAdded(address indexed _voter, address indexed _registrar, uint indexed _pollID);
    event VoterRemoved(address indexed _voter, address indexed _remover, uint indexed _pollID);

    event PollCreated(uint indexed _pollID);
    event PollStatusChanged(uint indexed _pollID);
    

    ////// VAR //////

    mapping(uint => Poll) public idToPoll;
    uint public pollCount;

    mapping(uint => VerificationObject) public pollIdToVerificationObject;

    ////// STRUCTS //////

    struct VerificationObject {
        bytes32 a;
        bytes32 u;
        bytes32 o;
        bytes32 t;
        bytes32 au;
        bytes32 ot;
        bytes32 auot;
    }

    struct Poll {
        uint pollID;
        uint openingTime;
        uint closingTime;
        uint countTime;
        uint voteOptionsCount;
        mapping(uint => VoteOption) idToVoteOption;
        bool verificationHashesAdded;
        bool votersConfirmed;
        bool approved;
        string pollName;
        string contentHash;
        string publicKey;
        mapping(address => uint8) voterStatus; // 0 => no voter; 1 => eligible to vote; 2 => voter voted
        mapping(bytes32 => uint) voteHashStatus; // 0 => no vote hash; 1 => uncounted vote hash; 2 => counted vote hash
    }

    struct VoteOption {
        uint optionID;
        string optionName;
        uint votes;
    }

    ////// CONSTRUCTOR //////

    constructor(address[] memory _registrars, address[] memory _chairpeople, address[] memory _electionBoardMembers) Admin(_registrars, _chairpeople, _electionBoardMembers) {}

    ////// MODIFIERS //////

    modifier pollExists(uint _pollID) {
        require(idToPoll[_pollID].pollID != 0, "Poll doesn't exist");
        _;
    }

    modifier verificationHashesAdded(uint _pollID) {
        require(idToPoll[_pollID].verificationHashesAdded, "Verification hashes not added");
        _;
    }

    modifier pollApproved(uint _pollID) {
        require(idToPoll[_pollID].approved, "Poll isn't approved");
        _;
    }

    modifier votersNotConfirmed(uint _pollID) {
        require(idToPoll[_pollID].votersConfirmed == false, "Voters have already been confirmed");
        _;
    }

    modifier votersConfirmed(uint _pollID) {
        require(idToPoll[_pollID].votersConfirmed, "Voters haven't been confirmed");
        _;
    }

    modifier pollNotApproved(uint _pollID) {
        require(idToPoll[_pollID].approved == false, "Poll is approved");
        _;
    }

    modifier pollNotClosed(uint _pollID) {
        require(idToPoll[_pollID].closingTime > block.timestamp, "Poll already closed");
        _;
    }

    modifier pollClosed(uint _pollID) {
        require(idToPoll[_pollID].closingTime < block.timestamp, "Poll isn't closed yet");
        _;
    }

    modifier pollNotBeingConfirmed(uint _pollID) {
        //Making sure that a poll that is currently being confirmed can't be altered
        require(idToTwoThirdRequest[requestCount].pollID != _pollID, "Poll can't be modified, because it is currently being confirmed");
        _;
    }

    ////// VOTING //////

    function vote(uint _pollID, bytes32 _voteHash, string memory _encryptedVote, address _voter, bytes memory _signature) public pollExists(_pollID) pollApproved(_pollID) pollNotClosed(_pollID) {

        //get the message hash
        bytes32 message = keccak256(
            abi.encodePacked(address(this), _pollID, _voteHash, _voter, _encryptedVote)
        );

        address voter = _recoverSigner(_prefixed(message), _signature);

        //check that the voter in the transaction matches the signer of the transaction
        require(voter == _voter, "Voter address in transaction doesn't match recovered voter");

        //checks the users voter status to make sure they are eligible to vote
        require(idToPoll[_pollID].voterStatus[voter] == 1, "User not eligible to vote");

        //sets the status of the submitted vote hash to 1 (exists, but not counted)
        idToPoll[_pollID].voteHashStatus[_voteHash] = 1;

        //emits an EncryptedVote event to store the vote on the blockchain
        emit EncryptedVote(_pollID, _encryptedVote, _voteHash, voter);
        
        //sets the vote status to 2 (user has voted)
        idToPoll[_pollID].voterStatus[voter] = 2;
    }

    //returns the voter status of a user
    function viewVoterStatus(uint _pollID, address _voter) public view pollExists(_pollID) pollApproved(_pollID) returns (uint8) {
        return (idToPoll[_pollID].voterStatus[_voter]);
    }

    function countVotes(uint _pollID, uint[] memory _optionID, string[] memory _uuid) public pollExists(_pollID) pollApproved(_pollID) pollClosed(_pollID) {
        //make sure the tally time has been reached
        require(idToPoll[_pollID].countTime < block.timestamp, "Tally time not reached");

        //make sure the same amount of optionIDs as uuids is submitted
        require(_optionID.length == _uuid.length, "Amount of optionIDs don't match amount of uuids");

        //count every vote
        for(uint i = 0; i < _uuid.length; i++) {

            //calculate the verification hash for the submitted vote
            bytes32 _verificationHash = keccak256(abi.encodePacked("pollID:", _uintToString(_pollID), ";optionID:", _uintToString(_optionID[i]), ";uuid:", _uuid[i]));
            //require that a vote hash like it has been stored on the blockchain during the voting phase
            require(idToPoll[_pollID].voteHashStatus[_verificationHash] == 1, "Vote hash not valid");
            //if the vote hash is valid, its status is updated to two, so it can't be used to count a vote again
            idToPoll[_pollID].voteHashStatus[_verificationHash] = 2;
            //if the vote hash is valid, the vote count is increased for the vote option that was submitted
            idToPoll[_pollID].idToVoteOption[_optionID[i]].votes++;

        }
    }

    function getVoteHashStatus(uint _pollID, bytes32 _voteHash) public view pollExists(_pollID) pollApproved(_pollID) returns (uint) {
        return (idToPoll[_pollID].voteHashStatus[_voteHash]);
    }

    //returns the vote option name and the number of votes it has received
    function viewVoteOption(uint _pollID, uint _voteOptionID) public view pollExists(_pollID) returns (string memory optionName, uint votes) {
        require(_voteOptionID > 0, "Vote option doesn't exist");
        require(idToPoll[_pollID].voteOptionsCount >= _voteOptionID, "Vote option doesn't exist");
        return(idToPoll[_pollID].idToVoteOption[_voteOptionID].optionName, idToPoll[_pollID].idToVoteOption[_voteOptionID].votes);
    }

    ////// ADMIN //////

    function addVerificationHashes(uint _pollID, bytes32[] memory hashes, bytes[] memory signatures) public registrarOnly pollExists(_pollID) pollNotClosed(_pollID) {
        
        //make sure the verificationHashes haven't already been added
        require(idToPoll[_pollID].verificationHashesAdded == false, "Verification hashes already added");
        //make sure all verififcationHashes have been submitted
        require(hashes.length == 7, "Not all hashes have been specified");

        //store verificatonHashes in a verififcationObject
        VerificationObject storage vObject = pollIdToVerificationObject[_pollID];

        vObject.a = hashes[0];
        vObject.u = hashes[1];
        vObject.o = hashes[2];
        vObject.t = hashes[3];
        vObject.au = hashes[4];
        vObject.ot = hashes[5];
        vObject.auot = hashes[6];


        //calculate combined hashes and validate them
        bytes32 auCalculated = keccak256(abi.encodePacked(hashes[0],hashes[1]));
        require(auCalculated == hashes[4], "Hash au incorrect");

        bytes32 otCalculated = keccak256(abi.encodePacked(hashes[2], hashes[3]));
        require(otCalculated == hashes[5], "Hash ot incorrect");

        bytes32 auotCalculated = keccak256(abi.encodePacked(hashes[4], hashes[5]));
        require(auotCalculated == hashes[6], "Hash auot incorrect");


        // INFO: The code didn't work because the registration app created the signature from the 
        //       string of the hash and the smart contract from bytes32

        //get the message hash
        bytes32 message = _prefixed(hashes[6]);

        //recover the signers from the message and the signature
        address signer1 = _recoverSigner(message, signatures[0]);
        address signer2 = _recoverSigner(message, signatures[1]);
        address signer3 = _recoverSigner(message, signatures[2]);

        //make sure the signers are registrars
        require(isRegistrar[signer1], "Signer is not a registrar");
        require(isRegistrar[signer2], "Signer is not a registrar");
        require(isRegistrar[signer3], "Signer is not a registrar");

        //make sure the same registrar didn't sign the same hash multiple times
        require(signer1 != signer2, "Can't sign hash twice");
        require(signer1 != signer3, "Can't sign hash twice");
        require(signer2 != signer3, "Can't sign hash twice");

        //update the poll
        idToPoll[_pollID].verificationHashesAdded = true;
        emit PollStatusChanged(_pollID);

    }

    //allows the chairpeople to add voters to a poll
    function addVoters(address[] memory _voters, uint _pollID) public chairpersonOnly pollExists(_pollID) verificationHashesAdded(_pollID) votersNotConfirmed(_pollID) pollNotClosed(_pollID) pollNotBeingConfirmed(_pollID) {

        for (uint i=0; i < _voters.length; i++) {

            require(_voters[i] != address(0), "Invalid address");
            require(idToPoll[_pollID].voterStatus[_voters[i]] == 0, "User is already registered");

            idToPoll[_pollID].voterStatus[_voters[i]] = 1;
            emit VoterAdded(_voters[i], msg.sender, _pollID);
            
        }

    }

    //allows the chairpeople to remove voters from a poll
    function removeVoters(address[] memory _voters, uint _pollID) public chairpersonOnly pollExists(_pollID) verificationHashesAdded(_pollID) votersNotConfirmed(_pollID) pollNotClosed(_pollID) pollNotBeingConfirmed(_pollID) {

        for (uint i=0; i < _voters.length; i++) {

                require(idToPoll[_pollID].voterStatus[_voters[i]] == 1, "User can't be removed");

                idToPoll[_pollID].voterStatus[_voters[i]] = 0;
                emit VoterRemoved(_voters[i], msg.sender, _pollID);

        }
        
    }

    //allows the chairpeople to confirm the voters, once all have been added
    function confirmVoters(uint _pollID, uint _requestID) public chairpersonOnly pollExists(_pollID) verificationHashesAdded(_pollID) votersNotConfirmed(_pollID) pollNotClosed(_pollID) {
        if (_requestID == 0) {
            _createTwoThirdRequest(RequestType.confirmVoters, address(0), _pollID);
        } else {
            bool requestFinished = _voteOnRequest(_requestID, RequestType.confirmVoters, address(0), _pollID);
            if (requestFinished) {
                idToPoll[_pollID].votersConfirmed = true;
                emit PollStatusChanged(_pollID);
            }
        }
    }

    //allows the chairpeople to create new polls
    function createPoll(uint _openingTime, uint _closingTime, string[] memory _options, string memory _pollName, string memory _contentHash, string memory _publicKey, uint _tallyTime) public chairpersonOnly {
  
        require(_options.length > 1, "Too few vote options submitted");
        require(_options.length < 6, "Too many vote options submitted");

        require(_openingTime > block.timestamp, "Opening time is in the past");
        require(_tallyTime > _closingTime, "Counting time is before closing time");
        require(_closingTime > block.timestamp, "Closing time is in the past");

        uint pollID = pollCount + 1;

        Poll storage newPoll = idToPoll[pollID];
        newPoll.pollID = pollID;
        newPoll.openingTime = _openingTime;
        newPoll.closingTime = _closingTime;
        newPoll.voteOptionsCount = _options.length;
        newPoll.pollName = _pollName;
        newPoll.contentHash = _contentHash;
        newPoll.publicKey = _publicKey;
        newPoll.countTime = _tallyTime;

        for (uint i=0; i<_options.length; i++) {   
            newPoll.idToVoteOption[i+1] = VoteOption(i+1, _options[i], 0);
        }
        

        pollCount++;

        emit PollCreated(pollID);
    }

    //allows the electoral board to confirm a poll, after they verified that everything is correct with it
    function confirmPoll(uint _pollID, uint _requestID) public electionBoardOnly pollExists(_pollID) votersConfirmed(_pollID) pollNotApproved(_pollID) pollNotClosed(_pollID) votersConfirmed(_pollID) {
        
        if(_requestID == 0) {
            //if 0 is entered as requestID, a new request is created
            _createTwoThirdRequest(RequestType.confirmPoll, address(0), _pollID);
        } else {
            //otherwise the application tries to vote on the request
            bool requestFinished = _voteOnRequest(_requestID, RequestType.confirmPoll, address(0), _pollID);

            //if the request finishes successfully (two-third majority was reached), the poll gets approved
            if (requestFinished) {
                idToPoll[_pollID].approved = true;
                emit PollStatusChanged(_pollID);
            }
        }
        
    }

    ////// UTILS //////

    //https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity answer by Barnabas Ujvari
    function _uintToString(uint _i) internal pure returns (string memory _uintAsString) {
        //TODO: Understand this code...
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /// signature methods. (from the solidity docs copied)

    //TODO: Error probably is in the split signature function
    function _splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function _recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function _prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    
}