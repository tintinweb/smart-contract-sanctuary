/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract ReferralContractSingle {

    address public admin;
    // Config programs
    bool public paused;

    string public programCode;
    uint256 public endTime;

    uint256 public tokenAllocation;
    uint256 public incentiveRate;

    // Config users
    mapping(string => address) public uidJoined;
    mapping(string => string[]) public refereesList;
    string[] public joiners;

    // Check
    mapping(address => string) public addressJoined; // user address => uid

    constructor(string memory _programCode, uint256 _tokenAllocation, uint256 _incentiveRate, uint256 _endTime){

        programCode = _programCode;
        tokenAllocation = _tokenAllocation;
        incentiveRate = _incentiveRate;
        endTime = _endTime;

        admin = msg.sender;
    }

    function joinProgram(string memory _uid, string memory _referCode) public {

        require(paused == false , "Program is pausing");
        // Check start/end time
        require(endTime > block.timestamp, "The program has expired");

        require(uidJoined[_uid] == address(0) , "The user joined");
        bytes memory haveReferralCode = bytes(_referCode);

        if (haveReferralCode.length>0) {
            refereesList[_referCode].push(_uid);
        }
        uidJoined[_uid] = msg.sender;
        addressJoined[msg.sender] = _uid;
        joiners.push(_uid);
    }

    function setPause(bool _pause) onlyOwner public {
        paused = _pause;
    }

    function setProgram(string memory _programCode, uint256 _tokenAllocation, uint256 _incentiveRate, uint256 _endTime) onlyOwner public {
        programCode = _programCode;
        tokenAllocation = _tokenAllocation;
        incentiveRate = _incentiveRate;
        endTime = _endTime;
    }

    function getJoiners() public view returns(string[] memory) {
        return joiners;
    }
    function getJoinerReferees(string memory _uid) public view returns(string[] memory) {
        return refereesList[_uid];
    }

    modifier onlyOwner() {
        require(admin == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}