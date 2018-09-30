pragma solidity ^0.4.25;

// ----------------------------------------------------------------------------
// @Name SafeMath
// @Desc Math operations with safety checks that throw on error
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// ----------------------------------------------------------------------------
library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
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
        interviewer = msg.sender;
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
// @Project BlockedIn
// @Creator Johnson Ryu
// ----------------------------------------------------------------------------
contract OPCT is Log, Ownable {
    
    mapping(address => Applicant) ApplicantList;
    
    struct Applicant {
        string      name;
        uint32      birth;
        uint        fingerprint;
        string      portfolioURL;
        bool[1]     confirmRound;
        uint8[1]    score;
    }
    
    function SetApplicant(string _name, uint32 _birth, uint _fingerprint, string _portfolioURL) external {
        ApplicantList[msg.sender].name = _name;
        ApplicantList[msg.sender].birth = _birth;
        ApplicantList[msg.sender].fingerprint = _fingerprint;
        ApplicantList[msg.sender].portfolioURL = _portfolioURL;
    }
    
    function GetApplicant(address _applicant) external view returns(string, uint32, uint, string){
        return (ApplicantList[_applicant].name, ApplicantList[_applicant].birth, ApplicantList[_applicant].fingerprint, ApplicantList[_applicant].portfolioURL);
    }
    
    function SetEvaluate(address _applicant, uint8 _round, uint8 _score) external onlyInterviewer {
        require(ApplicantList[_applicant].score.length >= _round);
        
        ApplicantList[_applicant].score[_round] = _score;
    }
    
    function GetEvaluate(address _applicant, uint8 _round) external view returns(uint8){
        return ApplicantList[_applicant].score[_round];
    }
    
    function SetConfirmRound(address _applicant, uint8 _round, bool _successOrFailure) external onlyInterviewer {
        require(ApplicantList[_applicant].confirmRound.length >= _round);
        
        ApplicantList[_applicant].confirmRound[_round] = _successOrFailure;
    }
}