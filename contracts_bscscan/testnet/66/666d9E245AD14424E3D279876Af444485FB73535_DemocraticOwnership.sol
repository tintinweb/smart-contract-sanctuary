/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;


contract DemocraticOwnership {

    // all admins
    address public admin1 = 0x35BE2BF3523c820b66dD44908d4753d53F064fd5;
    address public admin2 = 0x40f87A386aC140F61ab3AbE14BebfC408Dd09D29;
    address public admin3 = 0xafeC54BE872D0a787F2cc9DA99fC703F558e3a79;
    address public admin4 = 0x79B9C03fdab99b27A249251236cbFFf7178fed71;
    address public admin5 = 0xD459a5DF783b619D3b95570d65f366EE1a2307AC;

    //voters
    address public firstVoter;
    address public secondVoter;

    address public addressAuthorized;

    // Democratic Ownership variables
    uint256 public endChangeTime = 0;
    uint256 public endVotingTime = 0;
    uint public numberOfVote = 0;
    
    uint256 public authChangeDuration = 1800; // 30 minutes
    uint256 public votingDuration = 1800; // 30 minutes

    uint public numberOfChanges = 0;
        
    struct Call {
        uint date;
        string SmartContractName;
        string FunctionName;
    }

    mapping(uint => Call) private calls;
    mapping(address => bool) private authorizedSC;
    mapping(address => bool) private ownership;
    
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
    }

    // functions
    function reInitVoters() private {
        firstVoter = 0x0000000000000000000000000000000000000000;
        secondVoter = 0x0000000000000000000000000000000000000000;
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
            endVotingTime = block.timestamp + votingDuration;
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
            endChangeTime = block.timestamp + authChangeDuration;
            reInitVoters();
        }

    }

    constructor() {
        ownership[admin1] = true;
        ownership[admin2] = true;
        ownership[admin3] = true;
        ownership[admin4] = true;
        ownership[admin5] = true;
    }

    // modifier
    modifier onlyAdmins() {
        require(ownership[_msgSender()], 'Only admins can call this function');
        _;
    }

    // context functions
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

}