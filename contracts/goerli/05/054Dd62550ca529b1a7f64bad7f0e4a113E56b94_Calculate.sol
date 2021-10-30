// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "Attendance.sol";

contract Calculate{
    mapping(uint256 => uint256)public Total;
    Attendance[] public AttendanceContractsPending;
    function createAttendance()public returns(Attendance)
    {
       Attendance newAttendance = new Attendance();
       AttendanceContractsPending.push(newAttendance);
       return newAttendance;
    }

    function giveAttendance()public
    {
        while(AttendanceContractsPending.length >0)
        {
            Attendance curr = AttendanceContractsPending[AttendanceContractsPending.length-1];
            AttendanceContractsPending.pop();
            uint256[]memory present = curr.getRequests();
            for(uint i = 0; i < present.length; i++) 
            {
                Total[present[i]] = Total[present[i]]+1;
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Attendance{
    uint256[]rollNumber;

    function request(uint256 _rollNumber)public
    {
        rollNumber.push(_rollNumber);
    }

    function getRequests() public view returns(uint256[] memory)
    {
        return rollNumber;
    }
}