pragma solidity ^0.4.25;
// ----------------------------------------------------------------------------
// @title Log
// ----------------------------------------------------------------------------
contract Log {
   
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event InterviewerTransferred(address indexed previousInterviewer, address indexed newInterviewer);
}
// ----------------------------------------------------------------------------
// @title Ownable
// ----------------------------------------------------------------------------
contract Ownable is Log {
    
    address public owner;
    address public interviewer;

    constructor() public {
        owner    = msg.sender;
        interviewer = 0x19AbE8f977334afff9665da709ECe6cE4B5B263E;
    }

    modifier onlyOwner() { require(msg.sender == owner); _; }
    modifier onlyInterviewer() { require(msg.sender == interviewer); _; }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
  
    function transferInterviewer(address _newInterviewer) external onlyOwner {
        require(_newInterviewer != address(0));
        emit InterviewerTransferred(interviewer, _newInterviewer);
        interviewer = _newInterviewer;
    }
}
// ----------------------------------------------------------------------------
// @Project BLiKTHON
// @Creator SungtaeKim
// ----------------------------------------------------------------------------
contract BLiKTHON_final is Log, Ownable {
    
    mapping(address => Applicant) ApplicantList;
    
    struct Applicant {
        bool        applicant; 
        bool[2]     confirmRound;
        uint[2]     score;
    }
    
    function SetApplicant(address[] _hash) external onlyOwner {
        
        for (uint16 ui = 0; ui < _hash.length; ui++) {
            ApplicantList[_hash[ui]].applicant = true;
        }
    }
    
    function GetApplicant(address _hash) external view returns(bool) {
        return ApplicantList[_hash].applicant;
    }

    // OnlyInterViewer
   function SetEvaluate(address[] _hash, uint8 _round, uint64[] _score) external onlyInterviewer {
        require(ApplicantList[_hash[0]].score.length >= _round);
        require(_hash.length == _score.length);
        
        for(uint16 ui = 0; ui < _hash.length; ui++) {
            ApplicantList[_hash[ui]].score[_round] = _score[ui];
        }
    }
    
    function GetEvaluate(address _hash, uint8 _round) external view returns(uint) {
        return ApplicantList[_hash].score[_round];
    }
    
   // OnlyInterViewer
    function SetConfirmRound(address _hash, uint8 _round, bool _successOrFailure) external onlyInterviewer {
        require(ApplicantList[_hash].confirmRound.length >= _round);
        
        ApplicantList[_hash].confirmRound[_round] = _successOrFailure;
    }
    
    function GetConfirmRound(address _hash, uint8 _round) external view returns(bool) {
        return ApplicantList[_hash].confirmRound[_round];
    }
}