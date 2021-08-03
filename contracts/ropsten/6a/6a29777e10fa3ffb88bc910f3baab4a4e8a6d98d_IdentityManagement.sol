/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

//SPDX-License-Identifier: UNLICENSED
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

    function AddUserDL(address UserAddress,string memory DL_No, string memory DL_Name, string memory DL_DOB, bytes memory DL_Hash, string memory DL_Address) public
    {
        UserDLMap[UserAddress].DL_No=DL_No;
        UserDLMap[UserAddress].DL_Name=DL_Name;
        UserDLMap[UserAddress].DL_DOB=DL_DOB;
        UserDLMap[UserAddress].DL_Hash=DL_Hash;
        UserDLMap[UserAddress].DL_Address=DL_Address;
    }

    function AddDLRequest(address UserAddress,string memory RequestedBy, uint DL_No, uint DL_Name, uint DL_DOB, uint DL_Hash, uint DL_Address, uint DL_OverAll_Status) public
    {
        DLRequestMap[UserAddress].RequestedBy=RequestedBy;
        DLRequestMap[UserAddress].DL_No=DL_No;
        DLRequestMap[UserAddress].DL_Name=DL_Name;
        DLRequestMap[UserAddress].DL_DOB=DL_DOB;
        DLRequestMap[UserAddress].DL_Hash=DL_Hash;
        DLRequestMap[UserAddress].DL_Address=DL_Address;
        DLRequestMap[UserAddress].DL_OverAll_Status=DL_OverAll_Status;
    }

    function ViewDLRequestLength(address UserAddress) public view returns(uint)
    {
        return UserMap[UserAddress].RequestIndex;
    }

    function ViewDLRequestHeader(address UserAddress, uint RequestIndex) public view returns(string memory RequestedBy, uint DL_OverAll_Status)
    {
        return (DLRequestMap[UserAddress].RequestedBy, DLRequestMap[UserAddress].DL_OverAll_Status);
    }
	
    function ViewDLRequestDetail(address UserAddress, uint RequestIndex) public view returns(string memory RequestedBy, uint DL_No, uint DL_Name, uint DL_DOB, uint DL_Hash, uint DL_Address)
    {
        return (DLRequestMap[UserAddress].RequestedBy, DLRequestMap[UserAddress].DL_No, DLRequestMap[UserAddress].DL_Name, DLRequestMap[UserAddress].DL_DOB, DLRequestMap[UserAddress].DL_Hash, DLRequestMap[UserAddress].DL_Address);

    }

    function UpdateRequestStatus(address UserAddress, uint RequestIndex, uint DL_No, uint DL_Name, uint DL_DOB, uint DL_Hash, uint DL_Address, uint DL_OverAll_Status) public 
    {
        DLRequestMap[UserAddress].DL_No=DL_No;
		DLRequestMap[UserAddress].DL_Name=DL_Name;
		DLRequestMap[UserAddress].DL_DOB=DL_DOB;
		DLRequestMap[UserAddress].DL_Hash=DL_Hash;
		DLRequestMap[UserAddress].DL_Address=DL_Address;
		DLRequestMap[UserAddress].DL_OverAll_Status=DL_OverAll_Status;
    }

    function viewUser(address UserAddress, uint UserIndex) public view returns(string memory FullName,string memory EmailID,uint MobileNo)
    {
        
        return (UserMap[UserAddress].FullName, UserMap[UserAddress].EmailID, UserMap[UserAddress].MobileNo);
    }

    /*function viewUserDL(address UserAddress, uint RequestIndex) public view returns(uint DL_No_S, string memory DL_No_V, uint DL_Name_S, string memory DL_Name_V, uint DL_DOB_S, string memory DL_DOB_V, uint DL_Hash_S, bytes memory DL_Hash_V, uint DL_Address_S, string memory DL_Address_V)
    {
        UserDL memory ThisUserDL=UserDLMap[UserAddress][0];
		DLRequest memory ThisDLRequest=DLRequestMap[UserAddress][RequestIndex];
        return (ThisDLRequest.DL_No, ThisUserDL.DL_No, ThisDLRequest.DL_Name, ThisUserDL.DL_Name, ThisDLRequest.DL_DOB, ThisUserDL.DL_DOB, ThisDLRequest.DL_Hash, ThisUserDL.DL_Hash, ThisDLRequest.DL_Address, ThisUserDL.DL_Address);
    }*/

}