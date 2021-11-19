// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

contract DemocraticOwnership {

    // all admins
    address private admin1;
    address private admin2;
    address private admin3;
    address private admin4;
    address private admin5;

    //voters
    address public firstVoter;
    address public secondVoter;

    address public addressAuthorized;

    // Democratic Ownership variables
    uint256 public endChangeTime;
    uint256 public endVotingTime;    
    uint256 public Duration;
    
    uint public numberOfVote;
    uint public numberOfChanges;
        
    struct Call {
        uint date;
        string SmartContractName;
        string FunctionName;
    }

    mapping(uint => Call) private calls;
    mapping(address => bool) private authorizedSC;
    mapping(address => bool) private ownership;

    event ChangeRegistered(
        uint time, 
        string scname, 
        string funcname
    );
    
    function checkOwnership(address account) external view returns (bool) {
        return ownership[account];
    }

    function checkCalls(uint callid) external view returns (Call memory) {
        return calls[callid];
    }

    function checkAuthorizedSC(address account) external view returns (bool) {
        return authorizedSC[account];
    }

    function readAuthorizedAddress() external view returns (address) {
        require(authorizedSC[_msgSender()], "Sender must be authorized smart contract");
        return addressAuthorized;
    }

    function readEndChangeTime() external view returns (uint) {
        require(authorizedSC[_msgSender()], "Sender must be authorized smart contract");
        return endChangeTime;
    }

    function addSC(address scToAdd) external onlyAdmins() {
        authorizedSC[scToAdd] = true;
    }

    function RegisterCall(string memory scname, string memory funcname) external {
        require(authorizedSC[_msgSender()], "Sender must be authorized smart contract");
        uint time = block.timestamp;
        require(time <= endChangeTime, 'No Change is possible');
        numberOfChanges += 1;
        Call memory newcall = Call(time, scname, funcname);
        calls[numberOfChanges] = newcall;

        emit ChangeRegistered(time, scname, funcname);
    }

    function reInitVoters() private {
        firstVoter = address(0);
        secondVoter = address(0);
        endVotingTime = 0;
        numberOfVote = 0;
    }

    function voteForChange () external onlyAdmins(){
        
        // If the time of voting has ended but we did not reach 3 votes then we have to reinitialize the number of vote
        if (block.timestamp > endVotingTime && numberOfVote != 0){
            reInitVoters();
        }

        require(_msgSender() != firstVoter, 'You already voted as First Voter');
        require(_msgSender() != secondVoter, 'You already voted as Second Voter');

        numberOfVote +=  1;

        if( numberOfVote == 1) {
            // update the Voting Time
            endVotingTime = block.timestamp + Duration;
            // register first voter
            firstVoter = _msgSender();
        }

        else if (numberOfVote == 2) {
            // register second voter
            secondVoter = _msgSender();
            addressAuthorized = _msgSender();
        }

        else {
            // Update  Voting Time
            endChangeTime = block.timestamp + Duration;
            reInitVoters();
        }

    }

    constructor(address _admin1, 
                address _admin2,
                address _admin3,
                address _admin4,
                address _admin5,
                uint _duration) 
    {
        admin1 = _admin1;
        ownership[admin1] = true;
        admin2 = _admin2;
        ownership[admin2] = true;
        admin3 = _admin3;
        ownership[admin3] = true;
        admin4 = _admin4;
        ownership[admin4] = true;
        admin5 = _admin5;
        ownership[admin5] = true;
        Duration = _duration;
    }

    // modifier
    modifier onlyAdmins() {
        require(ownership[_msgSender()], 'Only admins can call this function');
        _;
    }

    // Context
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

}