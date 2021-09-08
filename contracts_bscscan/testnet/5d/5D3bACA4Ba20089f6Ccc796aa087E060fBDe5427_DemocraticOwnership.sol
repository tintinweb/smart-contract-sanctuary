/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


contract DemocraticOwnership {

    // all admins
    address public admin1 = 0x35BE2BF3523c820b66dD44908d4753d53F064fd5;
    address public admin2 = 0x40f87A386aC140F61ab3AbE14BebfC408Dd09D29;
    address public admin3 = 0xD459a5DF783b619D3b95570d65f366EE1a2307AC;
    address public admin4 = 0x79B9C03fdab99b27A249251236cbFFf7178fed71;
    address public admin5 = 0xD459a5DF783b619D3b95570d65f366EE1a2307AC;

    //voters
    address public firstVoter;
    address public secondVoter;
    mapping(address => bool) private _ownership;


    // Democratic Ownership variables
    uint256 public endChangeTime = 0;
    
    uint256 public endVotingTime = 0;
    uint public numberOfVote = 0;
    
    uint256 public authChangeDuration = 1800; // 30 minutes
    uint256 public votingDuration = 1800; // 30 minutes
    
    address public addressAuthorized;
    
    struct CallsRegistered {
        uint date;
        string SmartContractName;
        string FunctionName;
    }

    CallsRegistered [] private _calls;

    function RegisterCall(uint blocktime, string memory scname, string memory funcname) public {
        
        CallsRegistered memory newcall = CallsRegistered(blocktime, scname, funcname);
        _calls.push(newcall);

    }

    // functions
    function reInitVoters() public {
        firstVoter = 0x0000000000000000000000000000000000000000;
        secondVoter = 0x0000000000000000000000000000000000000000;
        endVotingTime = 0;
        numberOfVote = 0;
    }

    function voteForChange () public onlyAdmins(){
        
        require(_msgSender() != firstVoter, 'You already voted as First Voter');
        require(_msgSender() != secondVoter, 'You already voted as Second Voter');

        // If the time of voting has ended but we did not reach 3 votes then we have to reinitialize the number of vote
        if (block.timestamp > endVotingTime && numberOfVote != 0){
            reInitVoters();
        }

        numberOfVote +=  1;

        if( numberOfVote == 1 ) {
            // update the Voting Time
            endVotingTime = block.timestamp + votingDuration;
            // register first voter
            firstVoter = _msgSender();
        }

        else if (numberOfVote == 2) {
            // register second voter
            secondVoter = _msgSender();
        }

        else {
            // Update  Voting Time
            endChangeTime = block.timestamp + authChangeDuration;
            reInitVoters();
        }

    }

    constructor() {
        _ownership[admin1] = true;
        _ownership[admin2] = true;
        _ownership[admin3] = true;
        _ownership[admin4] = true;
        _ownership[admin5] = true;
    }

    // modifier
    modifier onlyAdmins() {
        require( _ownership[_msgSender()], 'Only admins can call this function');
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