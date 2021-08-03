/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

pragma solidity 0.8.6;

contract IdentityManagement
{

    address ContractOwner;
    
    constructor() {
        ContractOwner = msg.sender;
    }

    struct UserInfo{
		uint RequestIndex;
		string FullName;
		string EmailID;
		uint MobileNo;
    }
    
    struct UserDL{
		string DL_No;
		string DL_Name;
		string DL_DOB;
		string DL_Address;
    }

    struct DLRequest{
		string RequestedBy;
		uint DL_No;
		uint DL_Name;
		uint DL_DOB;
		uint DL_Address;
		uint DL_OverAll_Status;
    }

    /*
            ApprovalStatus
        -------------
        0 --  default status
        1 --  Requested
        2 --  Approved
        3 --  Rejected
    */
    uint requestIndex;
    mapping(address => UserInfo) UserMap;
	mapping(address => UserDL) UserDLMap;
	mapping(address => DLRequest) DLRequestMap;
	
    function AddUser(address UserAddress,string memory FullName,string memory EmailID,uint MobileNo) public
    {
        UserMap[UserAddress].FullName=FullName;
        UserMap[UserAddress].EmailID=EmailID;
        UserMap[UserAddress].MobileNo=MobileNo;
        requestIndex++;
        UserMap[UserAddress].RequestIndex=requestIndex;
    }

    function AddUserDL(address UserAddress,string memory DL_No, string memory DL_Name, string memory DL_DOB, string memory DL_Address) public
    {
        UserDLMap[UserAddress].DL_No=DL_No;
        UserDLMap[UserAddress].DL_Name=DL_Name;
        UserDLMap[UserAddress].DL_DOB=DL_DOB;
        UserDLMap[UserAddress].DL_Address=DL_Address;
    }

    function AddDLRequest(address UserAddress,string memory RequestedBy, uint DL_No, uint DL_Name, uint DL_DOB, uint DL_Address, uint DL_OverAll_Status) public
    {
        DLRequestMap[UserAddress].RequestedBy=RequestedBy;
        DLRequestMap[UserAddress].DL_No=DL_No;
        DLRequestMap[UserAddress].DL_Name=DL_Name;
        DLRequestMap[UserAddress].DL_DOB=DL_DOB;
        DLRequestMap[UserAddress].DL_Address=DL_Address;
        DLRequestMap[UserAddress].DL_OverAll_Status=DL_OverAll_Status;
    }

    function ViewDLRequestLength(address UserAddress) public view returns(uint)
    {
        return UserMap[UserAddress].RequestIndex;
    }

    function ViewDLRequestHeader(address UserAddress) public view returns(string memory RequestedBy, uint DL_OverAll_Status)
    {
        return (DLRequestMap[UserAddress].RequestedBy, DLRequestMap[UserAddress].DL_OverAll_Status);
    }
	
    function ViewDLRequestDetail(address UserAddress) public view returns(string memory RequestedBy, uint DL_No, uint DL_Name, uint DL_DOB, uint DL_Address)
    {
        return (DLRequestMap[UserAddress].RequestedBy, DLRequestMap[UserAddress].DL_No, DLRequestMap[UserAddress].DL_Name, DLRequestMap[UserAddress].DL_DOB, DLRequestMap[UserAddress].DL_Address);

    }

    function UpdateRequestStatus(address UserAddress, uint DL_No, uint DL_Name, uint DL_DOB, uint DL_Address, uint DL_OverAll_Status) public 
    {
        DLRequestMap[UserAddress].DL_No=DL_No;
		DLRequestMap[UserAddress].DL_Name=DL_Name;
		DLRequestMap[UserAddress].DL_DOB=DL_DOB;
		DLRequestMap[UserAddress].DL_Address=DL_Address;
		DLRequestMap[UserAddress].DL_OverAll_Status=DL_OverAll_Status;
    }

    function viewUser(address UserAddress) public view returns(string memory FullName,string memory EmailID,uint MobileNo)
    {
        
        return (UserMap[UserAddress].FullName, UserMap[UserAddress].EmailID, UserMap[UserAddress].MobileNo);
    }

}