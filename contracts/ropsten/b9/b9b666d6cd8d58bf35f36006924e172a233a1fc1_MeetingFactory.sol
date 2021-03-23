/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Meeting {
    struct Interval {
        uint256 start;
        uint256 end;
    }

    struct Condition {
        uint256 start;
        uint256 end;
    }

    struct Attendee {
        address _address;
        Interval[] freetimes;
    }

    enum MeetingStatus {CREATED, PENDING_APPROVAL, APPROVED}

    event Proposed();
    event Approved();

    address public host;
    string public name;
    string public descriptoin;
    Condition public condition;
    Interval public proposal;
    MeetingStatus public status;

    address[] public attendeeList;
    mapping(address => Attendee) attendees;

    mapping(address => bool) public approvals;
    uint256 public approvalCount;

    modifier restricted() {
        require(msg.sender == host, "restricted");
        _;
    }

    constructor(address msgSender, address[] memory _attendeeList) {
        host = msgSender;
        attendeeList = _attendeeList;

        uint256 i;
        for (i = 0; i < attendeeList.length; i++) {
            address _attendee = attendeeList[i];
            attendees[_attendee]._address = _attendee;
        }
    }

    function putFreeTime(uint256 start, uint256 end) public {
        attendees[msg.sender].freetimes.push(Interval(start, end));
    }

    function putFreeTimes(uint256[][] memory intervalList) public {
        uint256 i;
        for (i = 0; i < intervalList.length; i++) {
            uint256 start = intervalList[i][0];
            uint256 end = intervalList[i][1];
            putFreeTime(start, end);
        }
    }

    function getAttendees() public view returns (Attendee[] memory) {
        uint256 i;
        uint256 n = attendeeList.length;
        Attendee[] memory _attendees = new Attendee[](n);

        for (i = 0; i < n; i++) {
            _attendees[i] = attendees[attendeeList[i]];
        }
        return _attendees;
    }

    function propose(uint256 start, uint256 end) public restricted {
        uint256 i;
        uint256 j;
        for (i = 0; i < attendeeList.length; i++) {
            bool okFlag = false;
            address acc = attendeeList[i];
            Interval[] storage freetimes = attendees[acc].freetimes;
            for (j = 0; j < freetimes.length; j++) {
                Interval storage x = freetimes[j];
                if ((x.start <= start) && (end <= x.end)) {
                    okFlag = true;
                    break;
                }
            }
            require(okFlag, "conflicts someone's schedule");
        }

        proposal.start = start;
        proposal.end = end;

        setStatusPendingApproval();
    }

    function approve() public {
        require(!approvals[msg.sender], "already approved");

        approvals[msg.sender] = true;
        approvalCount++;

        if (approvalCount == attendeeList.length) {
            setStatusApproved();
        }
    }

    function setStatusPendingApproval() internal {
        require(status == MeetingStatus.CREATED);
        status = MeetingStatus.PENDING_APPROVAL;

        emit Proposed();
    }

    function setStatusApproved() internal {
        require(status == MeetingStatus.PENDING_APPROVAL);
        status = MeetingStatus.APPROVED;

        emit Approved();
    }
}

contract MeetingFactory {
    Meeting[] public meetings;

    function create(address[] memory attendeeList) public {
        Meeting m = new Meeting(msg.sender, attendeeList);
        meetings.push(m);
    }

    function getMeetings() public view returns (Meeting[] memory) {
        return meetings;
    }
}