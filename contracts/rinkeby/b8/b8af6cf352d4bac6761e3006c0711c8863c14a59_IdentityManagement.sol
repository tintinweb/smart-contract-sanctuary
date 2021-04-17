/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity ^0.4.0;

contract IdentityManagement
{

    address ContractOwner;
    
    function IdentityManagement() {
        ContractOwner = msg.sender;
    }

    struct UserInfo{
		string FullName;
		string EmailID;
		uint MobileNo;
    }
    
    struct UserDL{
		string DL_No;
		string DL_Name;
		string DL_DOB;
		bytes DL_Hash;
		string DL_Address;
    }

    struct DLRequest{
		string RequestedBy;
		uint DL_No;
		uint DL_Name;
		uint DL_DOB;
		uint DL_Hash;
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

    mapping(address => UserInfo[]) UserMap;
	mapping(address => UserDL[]) UserDLMap;
	mapping(address => DLRequest[]) DLRequestMap;
	
    function AddUser(address UserAddress,string FullName,string EmailID,uint MobileNo)
    {
        UserMap[UserAddress].push(UserInfo(FullName,EmailID,MobileNo));
    }

    function AddUserDL(address UserAddress,string DL_No, string DL_Name, string DL_DOB, bytes DL_Hash, string DL_Address)
    {
        UserDLMap[UserAddress].push(UserDL(DL_No, DL_Name, DL_DOB, DL_Hash, DL_Address));
    }

    function AddDLRequest(address UserAddress,string RequestedBy, uint DL_No, uint DL_Name, uint DL_DOB, uint DL_Hash, uint DL_Address, uint DL_OverAll_Status)
    {
        DLRequestMap[UserAddress].push(DLRequest(RequestedBy, DL_No, DL_Name, DL_DOB, DL_Hash, DL_Address, DL_OverAll_Status));
    }

    function ViewDLRequestLength(address UserAddress) constant returns(uint)
    {
        return DLRequestMap[UserAddress].length;
    }

    function ViewDLRequestHeader(address UserAddress, uint RequestIndex) constant returns(string RequestedBy, uint DL_OverAll_Status)
    {
        DLRequest ThisDLRequest=DLRequestMap[UserAddress][RequestIndex];
        return (ThisDLRequest.RequestedBy, ThisDLRequest.DL_OverAll_Status);
    }
	
    function ViewDLRequestDetail(address UserAddress, uint RequestIndex) constant returns(string RequestedBy, uint DL_No, uint DL_Name, uint DL_DOB, uint DL_Hash, uint DL_Address, uint DL_OverAll_Status)
    {
        DLRequest ThisDLRequest=DLRequestMap[UserAddress][RequestIndex];
        return (ThisDLRequest.RequestedBy, ThisDLRequest.DL_No, ThisDLRequest.DL_Name, ThisDLRequest.DL_DOB, ThisDLRequest.DL_Hash, ThisDLRequest.DL_Address, ThisDLRequest.DL_OverAll_Status);
    }

    function UpdateRequestStatus(address UserAddress, uint RequestIndex, uint DL_No, uint DL_Name, uint DL_DOB, uint DL_Hash, uint DL_Address, uint DL_OverAll_Status)
    {
        DLRequestMap[UserAddress][RequestIndex].DL_No=DL_No;
		DLRequestMap[UserAddress][RequestIndex].DL_Name=DL_Name;
		DLRequestMap[UserAddress][RequestIndex].DL_DOB=DL_DOB;
		DLRequestMap[UserAddress][RequestIndex].DL_Hash=DL_Hash;
		DLRequestMap[UserAddress][RequestIndex].DL_Address=DL_Address;
		DLRequestMap[UserAddress][RequestIndex].DL_OverAll_Status=DL_OverAll_Status;
    }

    function viewUser(address UserAddress, uint UserIndex) constant returns(string FullName,string EmailID,uint MobileNo)
    {
        UserInfo ThisUser=UserMap[UserAddress][UserIndex];
        return (ThisUser.FullName, ThisUser.EmailID, ThisUser.MobileNo);
    }

    function viewUserDL(address UserAddress, uint RequestIndex) constant returns(uint DL_No_S, string DL_No_V, uint DL_Name_S, string DL_Name_V, uint DL_DOB_S, string DL_DOB_V, uint DL_Hash_S, bytes DL_Hash_V, uint DL_Address_S, string DL_Address_V)
    {
        UserDL ThisUserDL=UserDLMap[UserAddress][0];
		DLRequest ThisDLRequest=DLRequestMap[UserAddress][RequestIndex];
        return (ThisDLRequest.DL_No, ThisUserDL.DL_No, ThisDLRequest.DL_Name, ThisUserDL.DL_Name, ThisDLRequest.DL_DOB, ThisUserDL.DL_DOB, ThisDLRequest.DL_Hash, ThisUserDL.DL_Hash, ThisDLRequest.DL_Address, ThisUserDL.DL_Address);
    }

}