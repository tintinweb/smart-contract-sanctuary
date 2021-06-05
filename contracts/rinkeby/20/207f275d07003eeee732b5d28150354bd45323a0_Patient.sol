/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-02
*/
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

contract ownable {
    
    address public owner;
    mapping(address=>bool) isAdmin;
    event OwnerChanged(address indexed _from,address indexed _to);
    event AdminAdded(address indexed Admin_Address);
    event AdminRemoved(address indexed Admin_Address);
    constructor() public{
        owner=msg.sender;
        isAdmin[msg.sender]=true;
    }
    
    modifier onlyOwner(){
        require(owner == msg.sender,"Only Owner has permission to do that action");
        _;
    }
    modifier onlyAdmin(){
        require(isAdmin[msg.sender] == true,"Only Admin has permission to do that action");
        _;
    }
    
    function setOwner(address _owner) public onlyOwner returns(bool success){
        require(msg.sender!=_owner,"Already Your the owner");
        owner = _owner;
        emit OwnerChanged(msg.sender, _owner);
        return true;
    }
    function addAdmin(address _address) public onlyOwner returns(bool success){
        require(!isAdmin[_address],"User is already a admin!!!");
        isAdmin[_address]=true;
        emit AdminAdded(_address);
        return true;
    }
    function removeAdmin(address _address) public onlyOwner returns(bool success){
        require(_address!=owner,"Can't remove owner from admin");
        require(isAdmin[_address],"User not admin already!!!");
        isAdmin[_address]=false;
        emit AdminRemoved(_address);
        return true;
    }
}



contract Hospital is ownable {
    uint256 public index;
    mapping(address=>bool) isHospital;
    struct hospital {
        uint256 id;
        string hname;
        string haddress;
        string hcontact;
        address addr;
        bool isApproved;
    }
    mapping(address=>hospital) hospitals;
    address[] public hospitalList;
    
    modifier onlyHospital(){
        require(isHospital[msg.sender],"Only Hospitals can add patient");
        _;
    }
    
    function addHospital(string memory _hname,string memory _haddress,string memory _hcontact,address _addr) public onlyAdmin{
        require(!isHospital[_addr],"Already a Hospital");
        hospitalList.push(_addr);
        index = index + 1;
        isHospital[_addr]=true;
        hospitals[_addr]=hospital(index,_hname,_haddress,_hcontact,_addr,true);
    }
    
    function getHospitalById(uint256 _id) public view returns(uint256 id,string memory hname,string memory haddress , string memory hcontact ,address addr , bool isApproved)  {
        uint256 i=0;
        for(;i<hospitalList.length;i++){
        if(hospitals[hospitalList[i]].id==_id){
            break;
        }
    }    
        require(hospitals[hospitalList[i]].id==_id,"Hospital ID doesn't exists");
        hospital memory tmp = hospitals[hospitalList[i]];
        return (tmp.id,tmp.hname,tmp.haddress,tmp.hcontact,tmp.addr,tmp.isApproved);
    }
    
    function getHospitalByAddress(address _address) public view returns(uint256 id,string memory hname,string memory haddress , string memory hcontact ,address addr , bool isApproved) {
        require(hospitals[_address].isApproved,"Hospital is not Approved or doesn't exist");
        hospital memory tmp = hospitals[_address];
        return (tmp.id,tmp.hname,tmp.haddress,tmp.hcontact,tmp.addr,tmp.isApproved);
    }    
    
}

contract Patient is Hospital{
    
    uint256 public pindex=0;
    
    struct Records {
    string hname;
    string reason;
    string admittedOn;
    string dischargedOn;
    string ipfs;
    }
    
    struct patient{
        uint256 id;
        string name;
        string phone;
        string gender;
        string dob;
        string bloodgroup;
        string allergies;
        Records[] records;
        address addr;
    }

    address[] private patientList;
    mapping(address=>mapping(address=>bool)) isAuth;
    mapping(address=>patient) patients;
    mapping(address=>bool) isPatient;

    
    function addRecord(address _addr,string memory _hname,string memory _reason,string memory _admittedOn,string memory _dischargedOn,string memory _ipfs) public{
        require(isPatient[_addr],"User Not registered");
        require(isAuth[_addr][msg.sender],"No permission to add Records");
        patients[_addr].records.push(Records(_hname,_reason,_admittedOn,_dischargedOn,_ipfs));
        
    }
    
    function addPatient(string memory _name,string memory _phone,string memory _gender,string memory _dob,string memory _bloodgroup,string memory _allergies) public {
        require(!isPatient[msg.sender],"Already Patient account exists");
        patientList.push(msg.sender);
        pindex = pindex + 1;
        isPatient[msg.sender]=true;
        isAuth[msg.sender][msg.sender]=true;
        patients[msg.sender].id=pindex;
        patients[msg.sender].name=_name;
        patients[msg.sender].phone=_phone;
        patients[msg.sender].gender=_gender;
        patients[msg.sender].dob=_dob;
        patients[msg.sender].bloodgroup=_bloodgroup;
        patients[msg.sender].allergies=_allergies;
        patients[msg.sender].addr=msg.sender;
    }
    
    function getPatientDetails(address _addr) public view returns(string memory _name,string memory _phone,string memory _gender,string memory _dob,string memory _bloodgroup,string memory _allergies){
        require(isAuth[_addr][msg.sender],"No permission to get Records");
        require(isPatient[_addr],"No Patients found at the given address");
        patient memory tmp = patients[_addr];
        return (tmp.name,tmp.phone,tmp.gender,tmp.dob,tmp.bloodgroup,tmp.allergies);
    }
    
    function getPatientRecords(address _addr) public view returns(string[] memory _hname,string[] memory _reason,string[] memory _admittedOn,string[] memory _dischargedOn,string[] memory ipfs){
        require(isAuth[_addr][msg.sender],"No permission to get Records");
        require(isPatient[_addr],"patient not signed in to our network");
        require(patients[_addr].records.length>0,"patient record doesn't exist");
        string[] memory Hname = new string[](patients[_addr].records.length);
        string[] memory Reason = new string[](patients[_addr].records.length);
        string[] memory AdmOn = new string[](patients[_addr].records.length);
        string[] memory DisOn = new string[](patients[_addr].records.length);
        string[] memory IPFS = new string[](patients[_addr].records.length);
        for(uint256 i=0;i<patients[_addr].records.length;i++){
            Hname[i]=patients[_addr].records[i].hname;
            Reason[i]=patients[_addr].records[i].reason;
            AdmOn[i]=patients[_addr].records[i].admittedOn;
            DisOn[i]=patients[_addr].records[i].dischargedOn;
            IPFS[i]=patients[_addr].records[i].ipfs;
        }
        return(Hname,Reason,AdmOn,DisOn,IPFS);
    }
    
    function addAuth(address _addr) public returns(bool success) {
        require(!isAuth[msg.sender][_addr],"Already Authorised");
        require(msg.sender!=_addr,"Cant add yourself");
        isAuth[msg.sender][_addr] = true;
        return true;
    }

    function revokeAuth(address _addr) public returns(bool success) {
        require(msg.sender!=_addr,"Cant remove yourself");
        require(isAuth[msg.sender][_addr],"Already Not Authorised");
        isAuth[msg.sender][_addr] = false;
        return true;
    }
    
    function addAuthFromTo(address _from,address _to) public returns(bool success) {
        require(!isAuth[_from][_to],"Already  Auth!!!");
        require(_from!=_to,"can't add same person");
        require(isAuth[_from][msg.sender],"You don't have permission to access");
        require(isPatient[_from],"User Not Registered yet");
        isAuth[_from][_to] = true;
        return true;
    }
    
    function removeAuthFromTo(address _from,address _to) public returns(bool success) {
        require(isAuth[_from][_to],"Already No Auth!!!");
        require(_from!=_to,"can't remove same person");
        require(isAuth[_from][msg.sender],"You don't have permission to access");
        require(isPatient[_from],"User Not Registered yet");
        isAuth[_from][_to] = false;
        return true;
    }
    

}