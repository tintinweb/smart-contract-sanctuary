/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity^0.5.5;
contract DBook {
    address public owner;
    
    mapping(address=>Police) public policeProfile;
    mapping(address=>PolicePhoto) public policePhotoDB;
    mapping(address=>PoliceLoginIDs) public policeLogin;
    mapping(address=>string) public matchAddrToBadgeNum;
    mapping(address=>uint) public policeRegisterStatus;
    mapping(string=>uint) public policeRegisteredStatus;
    mapping(address=>uint) public policeLoginStatus;
    mapping(string=>MissingPerson) public missingPersonDB;
    mapping(string=>MissingPersonProfile) public missingPersonProfile;
    mapping(string=>MissingPersonComplaint) public missingCaseRegistration;
    mapping(uint=>string) public missingPeopleList;
    string[] skinComplexionsFair;
    string[] skinComplexionsDark;
    event PrinterWord(string);
    
    string public pol_badgenum;
    string public pol_name;
    string public pol_rank;
    string public pol_unit;
    string public pol_station;
    string public pol_gender;
    uint public polCount;
    string public mp_id;
    string public mp_name;
    uint public mp_age;
    string public mp_gender;
    uint public mp_height;
    string public mp_haircolor;
    string public mp_skincolor;
    string public mp_status;
    string public mp_build;
    uint public mp_weight;
    string public mp_eyecolor;
    string public mp_missingsince;
    string public mp_missingplace;
    string public mp_remarks;
    string public mp_caseRegisteredBy;
    uint public mpCount;
    
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }
    modifier onlySignedInPolice {
        require(policeLoginStatus[msg.sender]==1);
        _;
    }
    struct Police {
        string policeBadgeNum;
        string policePassword;
        string policeName;
        string policeRank;
        string policeUnit;
        string policeStation;
        string policeGender;
    }
    struct PolicePhoto{
        string policeBadge;
        bool policePhoto;
    }
    struct PoliceLoginIDs {
        string userid;
        string userpassword;
    }
    struct MissingPerson {
        string mpIDnum;
        string mpName;
        uint mpAge;
        string mpGender;
        uint mpHeight;
        string mpHairColor;
        string mpSkinColor;
        string mpStatus;
    }
    struct MissingPersonProfile {
        string mpIDnum;
        string mpBuild;
        uint mpWeight;
        string mpEyeColor;
        string mpMissingSince;
        string mpMissingFromPlace;
        string mpRemarks;
    }
    struct MissingPersonComplaint {
        string mpIDnum;
        string policeBadge;
        bool mpBool;
    }
    function registerMissingPerson(string memory _id, string memory _name,uint _age,string memory _gender,
    uint _height, string memory _hair, string memory _skin,string memory _build,
    uint _weight,string memory _eye,string memory _since,string memory _place,string memory _remarks) public onlySignedInPolice {
        require(missingCaseRegistration[_id].mpBool==false);
        missingPersonDB[_id] = MissingPerson(_id,_name,_age,_gender,_height,_hair,_skin,"MISSING");
        missingPersonProfile[_id] = MissingPersonProfile(_id,_build,_weight,_eye,_since,_place,_remarks);
        missingCaseRegistration[_id] = MissingPersonComplaint(_id,policeProfile[msg.sender].policeBadgeNum,true);
        mpCount++;
        missingPeopleList[mpCount] = _id;
        addArrayComplexion(_skin,_id);
    }
    function addArrayComplexion(string memory _complexion,string memory _id) public {
        if(keccak256(abi.encodePacked(_complexion))==keccak256(abi.encodePacked("fair"))){
            skinComplexionsFair.push(_id);
        } else 
        if(keccak256(abi.encodePacked(_complexion))==keccak256(abi.encodePacked("dark"))){
            skinComplexionsDark.push(_id);
        }
    }
    function getArrayLength() public view returns(uint) {
        return skinComplexionsFair.length;
    }
    function registerPolice(string memory _policeId,string memory _policePassword,
    string memory _policeName,string memory _policeRank,string memory _policeUnit,
    string memory _policeStation,string memory _policeGender) public {
        require(policeRegisterStatus[msg.sender]==0);
        require(policeRegisteredStatus[_policeId]==0);
        policeProfile[msg.sender] = Police(_policeId,_policePassword,_policeName,_policeRank,_policeUnit,_policeStation,_policeGender);
        addPoliceLogin(_policeId,_policePassword);
        matchAddrToBadgeNum[msg.sender] = _policeId;
        policeRegisterStatus[msg.sender] = 1;
        policeRegisteredStatus[_policeId] = 1;
        polCount++;
    }
    function addPoliceLogin(string memory _addPoliceUserid, string memory _addPolicePassword) public {
        policeLogin[msg.sender] = PoliceLoginIDs(_addPoliceUserid,_addPolicePassword);
    }
    function signinPolice(string memory _policeusername, string memory _policepassword) public {
        require(keccak256(abi.encodePacked(matchAddrToBadgeNum[msg.sender]))==keccak256(abi.encodePacked(_policeusername)));
        require(keccak256(abi.encodePacked(policeLogin[msg.sender].userpassword))==keccak256(abi.encodePacked(_policepassword)));
        require(policeLoginStatus[msg.sender]==0);
        policeLoginStatus[msg.sender] = 1;
    }
    function addPolicePhoto(string memory _policeBadge) public onlySignedInPolice{
        require(keccak256(abi.encodePacked(_policeBadge))==keccak256(abi.encodePacked(policeProfile[msg.sender].policeBadgeNum)));
        policePhotoDB[msg.sender] = PolicePhoto(_policeBadge,true);
    }
    function getPoliceDetails() public {
        pol_badgenum = policeProfile[msg.sender].policeBadgeNum;
        pol_name = policeProfile[msg.sender].policeName;
        pol_rank = policeProfile[msg.sender].policeRank;
        pol_unit = policeProfile[msg.sender].policeUnit;
        pol_station = policeProfile[msg.sender].policeStation;
        pol_gender = policeProfile[msg.sender].policeGender;
    }
    function getPoliceBadgeNum() public view returns(string memory) {
        return pol_badgenum;
    }
    function getPoliceFullName() public view returns(string memory) {
        return pol_name;
    }
    function getPoliceRank() public view returns(string memory) {
        return pol_rank;
    }
    function getPoliceUnit() public view returns(string memory) {
        return pol_unit;
    }
    function getPoliceStaion() public view returns(string memory) {
        return pol_station;
    }
    function getPoliceGender() public view returns(string memory) {
        return pol_gender;
    }
    function getMissingPersonDetails(string memory _mpid) public {
        mp_id = missingPersonDB[_mpid].mpIDnum;
        mp_name = missingPersonDB[_mpid].mpName;
        mp_age = missingPersonDB[_mpid].mpAge;
        mp_gender = missingPersonDB[_mpid].mpGender;
        mp_height = missingPersonDB[_mpid].mpHeight;
        mp_haircolor = missingPersonDB[_mpid].mpHairColor;
        mp_skincolor = missingPersonDB[_mpid].mpSkinColor;
        mp_status = missingPersonDB[_mpid].mpStatus;
        mp_build = missingPersonProfile[_mpid].mpBuild;
        mp_weight = missingPersonProfile[_mpid].mpWeight;
        mp_eyecolor = missingPersonProfile[_mpid].mpEyeColor;
        mp_missingsince = missingPersonProfile[_mpid].mpMissingSince;
        mp_missingplace = missingPersonProfile[_mpid].mpMissingFromPlace;
        mp_remarks = missingPersonProfile[_mpid].mpRemarks;
        mp_caseRegisteredBy = missingCaseRegistration[_mpid].policeBadge;
    }
    
    function getMpID() public view returns(string memory) {
        return mp_id;
    }
    function getMpName() public view returns(string memory) {
        return mp_name;
    }
    function getMpAge() public view returns(uint) {
        return mp_age;
    }
    function getMpGender() public view returns(string memory) {
        return mp_gender;
    }
    function getMpHeight() public view returns(uint) {
        return mp_height;
    }
    function getMpHairColor() public view returns(string memory) {
        return mp_haircolor;
    }
    function getMpSkinColor() public view returns(string memory) {
        return mp_skincolor;
    }
    function getMpStatus() public view returns(string memory) {
        return mp_status;
    }
    function getMpBuild() public view returns(string memory) {
        return mp_build;
    }
    function getMpWeight() public view returns(uint) {
        return mp_weight;
    }
    function getMpEyeColor() public view returns(string memory) {
        return mp_eyecolor;
    }
    function getMpMissingSince() public view returns(string memory) {
        return mp_missingsince;
    }
    function getMpMissingPlace() public view returns(string memory) {
        return mp_missingplace;
    }
    function getMpRemarks() public view returns(string memory) {
        return mp_remarks;
    }
    function getPolCount() public view returns(uint) {
        return polCount;
    }
    function getNumRegMissingPerson() public view returns(uint) {
        return mpCount;
    }
    function logoutPolice() public onlySignedInPolice {
        if(policeLoginStatus[msg.sender]==1){
            policeLoginStatus[msg.sender]=0;
        }
    }
}