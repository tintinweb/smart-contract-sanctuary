// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

pragma experimental ABIEncoderV2;

import "./ERC721.sol";

contract ownable {
    address public owner;
    mapping(address => bool) isAdmin;
    event OwnerChanged(address indexed _from, address indexed _to);
    event AdminAdded(address indexed Admin_Address);
    event AdminRemoved(address indexed Admin_Address);

    constructor() public {
        owner = msg.sender;
        isAdmin[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "Only Owner has permission to do that action"
        );
        _;
    }
    modifier onlyAdmin() {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin has permission to do that action"
        );
        _;
    }

    function setOwner(address _owner) public onlyOwner returns (bool success) {
        require(msg.sender != _owner, "Already Your the owner");
        owner = _owner;
        emit OwnerChanged(msg.sender, _owner);
        return true;
    }

    function addAdmin(address _address)
        public
        onlyOwner
        returns (bool success)
    {
        require(!isAdmin[_address], "User is already a admin!!!");
        isAdmin[_address] = true;
        emit AdminAdded(_address);
        return true;
    }

    function removeAdmin(address _address)
        public
        onlyOwner
        returns (bool success)
    {
        require(_address != owner, "Can't remove owner from admin");
        require(isAdmin[_address], "User not admin already!");
        isAdmin[_address] = false;
        emit AdminRemoved(_address);
        return true;
    }
}

contract Hospital is ownable {
    uint256 public index;
    mapping(address => bool) isHospital;

    struct hospital {
        uint256 id;
        string hname;
        string haddress;
        string hcontact;
        address addr;
        bool isApproved;
    }
    
    mapping(address => hospital) hospitals;
    address[] public hospitalList;

    modifier onlyHospital() {
        require(isHospital[msg.sender], "Only Hospitals can add patient");
        _;
    }

    function addHospital(
        string memory _hname,
        string memory _haddress,
        string memory _hcontact,
        address _addr
    ) public onlyAdmin {
        require(!isHospital[_addr], "Already a Hospital");

        hospitalList.push(_addr);
        index = index + 1;
        isHospital[_addr] = true;
        hospitals[_addr] = hospital(
            index,
            _hname,
            _haddress,
            _hcontact,
            _addr,
            true
        );
    }

    function getHospitalById(uint256 _id)
        public
        view
        returns (
            uint256 id,
            string memory hname,
            string memory haddress,
            string memory hcontact,
            address addr,
            bool isApproved
        )
    {
        uint256 i = 0;
        for (; i < hospitalList.length; i++) {
            if (hospitals[hospitalList[i]].id == _id) {
                break;
            }
        }
        require(hospitals[hospitalList[i]].id == _id, "Hospital ID doesn't exists");
        hospital memory tmp = hospitals[hospitalList[i]];
        return (
            tmp.id,
            tmp.hname,
            tmp.haddress,
            tmp.hcontact,
            tmp.addr,
            tmp.isApproved
        );
    }

    function getHospitalByAddress(address _address)
        public
        view
        returns (
            uint256 id,
            string memory hname,
            string memory haddress,
            string memory hcontact,
            address addr,
            bool isApproved
        )
    {
        require(hospitals[_address].isApproved, "Hospital is not Approved or doesn't exist");
        hospital memory tmp = hospitals[_address];

        return (
            tmp.id,
            tmp.hname,
            tmp.haddress,
            tmp.hcontact,
            tmp.addr,
            tmp.isApproved
        );
    }
}

contract Insurance is ownable {
    uint256 public insuranceIdx;
    mapping(address => bool) isInsurance;

    struct insurance {
        uint256 id;
        string hname;
        string haddress;
        string hcontact;
        address addr;
        bool isApproved;
    }
    
    mapping(address => insurance) insurances;
    address[] public insuranceList;

    modifier onlyInsurance() {
        require(isInsurance[msg.sender], "Only Insurance can add patient");
        _;
    }

    function addInsurance(
        string memory _hname,
        string memory _haddress,
        string memory _hcontact,
        address _addr
    ) public onlyAdmin {
        require(!isInsurance[_addr], "Already a Insurance");

        insuranceList.push(_addr);
        insuranceIdx = insuranceIdx + 1;
        isInsurance[_addr] = true;
        insurances[_addr] = insurance(
            insuranceIdx,
            _hname,
            _haddress,
            _hcontact,
            _addr,
            true
        );
    }

    function getInsuranceById(uint256 _id)
        public
        view
        returns (
            uint256 id,
            string memory hname,
            string memory haddress,
            string memory hcontact,
            address addr,
            bool isApproved
        )
    {
        uint256 i = 0;
        for (; i < insuranceList.length; i++) {
            if (insurances[insuranceList[i]].id == _id) {
                break;
            }
        }
        require(insurances[insuranceList[i]].id == _id, "Insurance ID doesn't exists");
        insurance memory tmp = insurances[insuranceList[i]];
        return (
            tmp.id,
            tmp.hname,
            tmp.haddress,
            tmp.hcontact,
            tmp.addr,
            tmp.isApproved
        );
    }

    function getInsuranceByAddress(address _address)
        public
        view
        returns (
            uint256 id,
            string memory hname,
            string memory haddress,
            string memory hcontact,
            address addr,
            bool isApproved
        )
    {
        require(insurances[_address].isApproved, "Insurance is not Approved or doesn't exist");
        insurance memory tmp = insurances[_address];

        return (
            tmp.id,
            tmp.hname,
            tmp.haddress,
            tmp.hcontact,
            tmp.addr,
            tmp.isApproved
        );
    }
}

contract Patient is Hospital, Insurance {
    uint256 public pindex = 0;
    // uint256 public rindex = 0;

    struct Records {
        // uint256 id;
        string hname;
        string reason;
        string admittedOn;
        string dischargedOn;
        string ipfs;
    }

    struct patient {
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
    mapping(address => mapping(address => bool)) isAuth;
    mapping(address => patient) patients;
    mapping(address => bool) isPatient;
    // mapping(uint256 => address) public recordToOwner;
    // mapping(address => uint256) public ownerRecordCount;

    // constructor() public{
    // }

    function addRecord(
        address _addr,
        string memory _hname,
        string memory _reason,
        string memory _admittedOn,
        string memory _dischargedOn,
        string memory _ipfs
    ) public {
        require(isPatient[_addr], "User Not registered");
        require(isAuth[_addr][msg.sender], "No permission to add Records");
        // rindex = rindex + 1;
        //patients[_addr].records.push( Records(rindex, _hname, _reason, _admittedOn, _dischargedOn, _ipfs));
        patients[_addr].records.push( Records(_hname, _reason, _admittedOn, _dischargedOn, _ipfs));
        // recordToOwner[rindex] = _addr;
        // ownerRecordCount[_addr] += 1;
    }

    function addPatient(
        string memory _name,
        string memory _phone,
        string memory _gender,
        string memory _dob,
        string memory _bloodgroup,
        string memory _allergies
    ) public {
        require(!isPatient[msg.sender], "Already Patient account exists");
        patientList.push(msg.sender);
        pindex = pindex + 1;
        isPatient[msg.sender] = true;
        isAuth[msg.sender][msg.sender] = true;
        patients[msg.sender].id = pindex;
        patients[msg.sender].name = _name;
        patients[msg.sender].phone = _phone;
        patients[msg.sender].gender = _gender;
        patients[msg.sender].dob = _dob;
        patients[msg.sender].bloodgroup = _bloodgroup;
        patients[msg.sender].allergies = _allergies;
        patients[msg.sender].addr = msg.sender;
    }

    function getPatientDetails(address _addr)
        public
        view
        returns (
            string memory _name,
            string memory _phone,
            string memory _gender,
            string memory _dob,
            string memory _bloodgroup,
            string memory _allergies
        )
    {
        require(isAuth[_addr][msg.sender], "No permission to get Records");
        require(isPatient[_addr], "No Patients found at the given address");
        patient memory tmp = patients[_addr];
        return (
            tmp.name,
            tmp.phone,
            tmp.gender,
            tmp.dob,
            tmp.bloodgroup,
            tmp.allergies
        );
    }

    function getPatientRecords(address _addr)
        public
        view
        returns (
            // uint256[] memory id,
            string[] memory _hname,
            string[] memory _reason,
            string[] memory _admittedOn,
            string[] memory _dischargedOn,
            string[] memory ipfs
        )
    {
        require(isAuth[_addr][msg.sender], "No permission to get Records");
        require(isPatient[_addr], "patient not signed in to our network");
        require(
            patients[_addr].records.length > 0,
            "patient record doesn't exist"
        );
        // uint256[] memory HId = new uint256[](patients[_addr].records.length);
        string[] memory Hname = new string[](patients[_addr].records.length);
        string[] memory Reason = new string[](patients[_addr].records.length);
        string[] memory AdmOn = new string[](patients[_addr].records.length);
        string[] memory DisOn = new string[](patients[_addr].records.length);
        string[] memory IPFS = new string[](patients[_addr].records.length);
        for (uint256 i = 0; i < patients[_addr].records.length; i++) {
            // HId[i] = patients[_addr].records[i].id;
            Hname[i] = patients[_addr].records[i].hname;
            Reason[i] = patients[_addr].records[i].reason;
            AdmOn[i] = patients[_addr].records[i].admittedOn;
            DisOn[i] = patients[_addr].records[i].dischargedOn;
            IPFS[i] = patients[_addr].records[i].ipfs;
        }
        // return (HId, Hname, Reason, AdmOn, DisOn, IPFS);
        return (Hname, Reason, AdmOn, DisOn, IPFS);
    }

    function addAuth(address _addr) public returns (bool success) {
        require(!isAuth[msg.sender][_addr], "Already Authorised");
        require(msg.sender != _addr, "Cant add yourself");
        isAuth[msg.sender][_addr] = true;
        return true;
    }

    function revokeAuth(address _addr) public returns (bool success) {
        require(msg.sender != _addr, "Cant remove yourself");
        require(isAuth[msg.sender][_addr], "Already Not Authorised");
        isAuth[msg.sender][_addr] = false;
        return true;
    }

    function addAuthFromTo(address _from, address _to)
        public
        returns (bool success)
    {
        require(!isAuth[_from][_to], "Already  Auth!!!");
        require(_from != _to, "can't add same person");
        require(
            isAuth[_from][msg.sender],
            "You don't have permission to access"
        );
        require(isPatient[_from], "User Not Registered yet");
        isAuth[_from][_to] = true;
        return true;
    }

    function removeAuthFromTo(address _from, address _to)
        public
        returns (bool success)
    {
        require(isAuth[_from][_to], "Already No Auth!!!");
        require(_from != _to, "can't remove same person");
        require(
            isAuth[_from][msg.sender],
            "You don't have permission to access"
        );
        require(isPatient[_from], "User Not Registered yet");
        isAuth[_from][_to] = false;
        return true;
    }

    // /// This function simply takes an address, and returns how many tokens that address owns.
    // function balanceOf(address _owner) override external view returns (uint256){
    //         return 0;
    //     // return ownerRecordCount[_owner];
    // }

    // ///This function takes a token ID (in our case, a record ID), and returns the address of the person who owns it.
    // function ownerOf(uint256 _tokenId) override external view returns (address){
    //     return address(0);
    //     // return recordToOwner[_tokenId];
    // }

    // function _transfer(address _from, address _to, uint256 _tokenId) private {
    //     // ownerRecordCount[_to] = ownerRecordCount[_to] + 1;
    //     // ownerRecordCount[msg.sender] = ownerRecordCount[msg.sender] - 1;
    //     // recordToOwner[_tokenId] = _to;
    //     emit Transfer(_from, _to, _tokenId);
    // }

    // /**
    // * The first way is the token's owner calls transferFrom with his address as the _from parameter, 
    // * the address he wants to transfer to as the _to parameter, and the _tokenId of the token he wants to transfer.
    // */
    // function transferFrom(address _from, address _to, uint256 _tokenId) override external payable{
    //     // require (recordToOwner[_tokenId] == msg.sender);
    //     _transfer(_from, _to, _tokenId);
    // }

    // /**
    // * The second way is the token's owner first calls approve with the address he wants to transfer to, and the _tokenID . 
    // * The contract then stores who is approved to take a token, usually in a mapping (uint256 => address). 
    // * Then, when the owner or the approved address calls transferFrom, the contract checks if that msg.sender is the owner 
    // * or is approved by the owner to take the token, and if so it transfers the token to him.
    // */
    // function approve(address _approved, uint256 _tokenId) override external payable{
    //     emit Approval(msg.sender, _approved, _tokenId);
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  /// This function simply takes an address, and returns how many tokens that address owns.
  function balanceOf(address _owner) virtual external view returns (uint256);
  ///This function takes a token ID (in our case, a Zombie ID), and returns the address of the person who owns it.
  function ownerOf(uint256 _tokenId) virtual external view returns (address);
  /**
   * The first way is the token's owner calls transferFrom with his address as the _from parameter, 
   * the address he wants to transfer to as the _to parameter, and the _tokenId of the token he wants to transfer.
   */
  function transferFrom(address _from, address _to, uint256 _tokenId) virtual external payable;
  /**
   * The second way is the token's owner first calls approve with the address he wants to transfer to, and the _tokenID . 
   * The contract then stores who is approved to take a token, usually in a mapping (uint256 => address). 
   * Then, when the owner or the approved address calls transferFrom, the contract checks if that msg.sender is the owner 
   * or is approved by the owner to take the token, and if so it transfers the token to him.
   */
  function approve(address _approved, uint256 _tokenId) virtual external payable;
}