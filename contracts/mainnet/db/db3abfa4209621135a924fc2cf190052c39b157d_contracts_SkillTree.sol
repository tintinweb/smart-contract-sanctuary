pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "@nomiclabs/buidler/console.sol";

contract SkillTree is Ownable {
  address public admin;

  // States
  uint constant nonexistent    = 0;
  uint constant needs_approval = 1;
  
  uint constant approved       = 2;
  uint constant active         = 2;

  uint constant declined       = 3;
  uint constant canceled       = 4;

  // Certificate Levels
  uint constant attendance     = 1;
  uint constant material       = 2;
  uint constant exams          = 3;
  uint constant extra          = 4;

  // actions to approve
  byte constant a_expert = 0x01;
  byte constant a_issuer = 0x02; 

  // =========================================
  //  Events
  // =========================================
  event NewUser(address user,string name,bool issuer,bool expert,string dataHash);
  event UserChanged(address user,string name,bool issuer,bool expert,string dataHash);
  event ApprovalNeeded(address sender, bytes32 id);
  event DecideApproval(address sender, bytes32 user, bool decision);
  event NewCourse(bytes32 course, address user, string name, string dataHash);
  event CourseChanged(bytes32 course, address user, string name, string dataHash);
  event NewEndorsement(bytes32 endorsement, address endorser, bytes32 course);
  event DecideEndorsement(bytes32 endorsement, address decider, bytes32 course, bool decision);
  event CancelEndorsement(bytes32 endorsement, address endorser);
  event NewCertificateTemplate(bytes32 courseId, string _title, uint level);
  event NewCertificate(bytes32 templateId, address issuer, address recipient);

  // =========================================
  //  Users
  // =========================================
  // 0: nonexistent
  // 1: needs_approval
  // 2: active
  // 3: disabled
  
  struct User {
    string     name;
    string     dataHash;  // ipfs hash?
    bool       issuer;
    bool       expert;
    uint       state;
    bytes32[]  courseArray;
    bytes32[]  pendingEndorsementArray;
    bytes32[]  receivedCertificateArray;
    bytes32[]  issuedCertificateArray;
    bytes32[]  approvalArray;
    bytes32[] endorsementArray;
  }


  address[]  private userArray;
  mapping (address => User) private Users;

  // =========================================
  //  Courses
  // =========================================
  struct Course {
    string name;
    address issuer;
    string dataHash;
    bytes32[] endorsementArray;
    bytes32[] certificateTemplateArray;
    uint state;
  }

  bytes32[] public courseArray;
  mapping (bytes32 => Course) private Courses;

  // =========================================
  // Endorsements
  // =========================================
  struct Endorsement {
    bytes32 certificateTemplateId;
    address endorser;
    uint    level;
    uint    state;
  }
  
  bytes32[] private endorsementArray;
  mapping (bytes32 => Endorsement) private Endorsements;

  // =========================================
  // Certificate Templates
  // =========================================
  struct CertificateTemplate {
    string    title;
    string    description;
    string    dataHash;
    address   issuer;
    bytes32   courseId;
    bytes32[] certificateArray;
    uint      level;          // attendance, material, exams, extra
    uint      state;
  }

  uint private certificateTemplateNonce;
  mapping(bytes32 => CertificateTemplate) private CertificateTemplates;

  // =========================================
  // Certificates
  // =========================================
  struct Certificate {
    bytes32 templateId;
    address recipient;
    address issuer;
    string dataHash;
    uint state;
  }

  bytes32[] private certificateArray;
  mapping (bytes32 => Certificate) private Certificates;

  // =========================================
  // Approvals
  // =========================================
  struct Approval {
    address subject;
    address approver;
    byte    permission;
    uint    state;
  }
  mapping (bytes32 => Approval) private Approvals;
  bytes32[] private approvalArray;

  // =========================================
  //
  //  Constructor
  //
  // =========================================
  constructor() public{
    admin = msg.sender;
  }

  // =========================================
  //
  //  User Management
  //
  // =========================================
  function update_user(string calldata _name, string calldata _dataHash, bool _issuer, bool _expert) external {
    require((Users[msg.sender].state > nonexistent), "Create user first");
    
    Users[msg.sender].name       = _name;
    Users[msg.sender].dataHash = _dataHash;
    
    if (_issuer && !(Users[msg.sender].issuer)) {
      request_approval(a_issuer);
    } else if(_expert && !(Users[msg.sender].expert)) {
      request_approval(a_expert);
    } else {
      Users[msg.sender].state      = active;
    }
      
    emit UserChanged(msg.sender, _name, _issuer, _expert, _dataHash);
  }
  
  function sign_up(string calldata _name, string calldata _dataHash, bool _issuer, bool _expert) external {
    require((Users[msg.sender].state == nonexistent), "This user already exists");
   
    Users[msg.sender].name       = _name;
    Users[msg.sender].dataHash   = _dataHash;
    Users[msg.sender].state      = active;
    
    if (_issuer) {
      request_approval(a_issuer);
    }

    if(_expert) {
      request_approval(a_expert);
    }
    userArray.push(msg.sender);
    emit NewUser(msg.sender, _name, _issuer, _expert, _dataHash);
  }

  function update_user_dataHash(string memory _dataHash) public {
    require((Users[msg.sender].state > nonexistent), "Create user first");
    Users[msg.sender].dataHash = _dataHash;
    emit UserChanged(msg.sender, Users[msg.sender].name, Users[msg.sender].issuer, Users[msg.sender].expert, _dataHash);
  }
  
  function number_of_users() public view returns (uint256) {
    return userArray.length;
  }
  
  // =========================================
  //
  //  Approvals & decisions
  //
  // =========================================
  
  // TODO As of now, once granted, admin can NOT take away expert and issuer privileges.

  function request_approval(byte permission) internal {
    Approval memory a;
    a.subject = msg.sender;
    a.permission = permission;
    a.approver = admin;
    a.state = needs_approval;
    bytes32 id = keccak256(abi.encodePacked(a.subject, a.permission, a.approver, approvalArray.length));
    Approvals[id] = a;
    Users[admin].approvalArray.push(id);
    approvalArray.push(id);
    emit ApprovalNeeded(msg.sender, id);
  }
 
  function decide_approval(uint _pos, bool _decision) public{
    require((msg.sender == admin), "Only admin can approve");
    
    bytes32 approval_id = Users[msg.sender].approvalArray[_pos]; // bytes32 id of the approval

    require((Approvals[approval_id].state == needs_approval), "No approval needed for this");

    //delete Users[Approvals[approval_id].approver].approvalArray[_pos];

    if(_decision) {
      Approvals[approval_id].state = approved;
      if(Approvals[approval_id].permission == a_expert) {
        Users[Approvals[approval_id].subject].expert = true;
      }

      if(Approvals[approval_id].permission == a_issuer) {
        Users[Approvals[approval_id].subject].issuer = true;
      }
    } else {
      Approvals[approval_id].state = declined;
    }


    emit DecideApproval(msg.sender, approval_id, _decision);
  }

  function get_approval(bytes32 id) external view returns(Approval memory){
    return(Approvals[id]);
  }

  function get_approvals(address _address) external view returns(bytes32[] memory){
    return(Users[_address].approvalArray);
  }

  // =========================================
  // Admin functions
  // =========================================
  function set_admin (address _admin) external onlyOwner{
    admin = _admin;
  }   

  //
  // getter functions to check account state
  //

  function account_state(address _address) public view returns (uint) {
    return(Users[_address].state);
  }

  // get user by address
  function get_user(address _address) public view returns (User memory) {
    return(Users[_address]);
  }

  // get user by position
  function get_user_by_position(uint _position) public view returns (User memory) {
    require((_position < userArray.length), "No such user");
    return(Users[userArray[_position]]);
  }
  
  // Determining user type
  function expert(address _address) public view returns (bool) {
    return(Users[_address].expert);
  }

  function issuer(address _address) public view returns (bool) {
    return(Users[_address].issuer);
  }
  
  function get_user_dataHash(address _address) public view returns (string memory) {
    return(Users[_address].dataHash);
  }
  
  function get_user_state(address _address) public view returns (string memory) {
    if(Users[_address].state == 0){ return("nonexistent"); }
    if(Users[_address].state == 1){ return("needs approval"); }
    if(Users[_address].state == 2){ return("approved"); }
    if(Users[_address].state == 3){ return("declined"); }
    if(Users[_address].state == 3){ return("canceled"); }
    return("error");
  }
  
  // =========================================
  //
  //  Course Management
  //
  // =========================================

  function add_course(string calldata _name, string calldata _dataHash) external{
    require((Users[msg.sender].state == approved), "An approved user is required");
    require((Users[msg.sender].issuer), "Account has no issuer privilege");

    bytes32 id = keccak256(abi.encodePacked(_name, _dataHash, courseArray.length));
    require((Courses[id].state == nonexistent ), "Already a course exists with this id. This is very unlikely.");

    Courses[id].name = _name;
    Courses[id].dataHash = _dataHash;
    Courses[id].issuer = msg.sender;
    Courses[id].state = active;

    courseArray.push(id);
    Users[msg.sender].courseArray.push(id);
    emit NewCourse(id, msg.sender, _name, _dataHash);
  }

  function update_course(bytes32 _id, string calldata _name, string calldata _dataHash) external {
    require((Users[msg.sender].state == approved), "An approved user is required");
    require((Courses[_id].issuer == msg.sender), "You don't have permission to edit this course"); 
    
    Courses[_id].name = _name;
    Courses[_id].dataHash = _dataHash;
    emit CourseChanged(_id, msg.sender, _name, _dataHash);
  }
 
  function get_course(bytes32 _id) external view returns (Course memory){
    return(Courses[_id]);
  }

  function get_courses() external view returns(bytes32[] memory){
    return(courseArray);
  }
  
  function get_courses_by_issuer(address _address) external view returns(bytes32[] memory){
    return(Users[_address].courseArray);
  }
  
  // =========================================
  //
  //  Endorsement Management
  //
  // =========================================
  function add_endorsement(bytes32 _certificateTemplateId, uint _endorsement_level) external{
    require(Users[msg.sender].expert, "You need to be an expert to endorse");
    require((CertificateTemplates[_certificateTemplateId].state > nonexistent), "CertificateTemplate not found");

    // get unique ID
    bytes32 id = keccak256(abi.encodePacked(_certificateTemplateId, msg.sender, endorsementArray.length));
    require((Endorsements[id].state == nonexistent ), "Already an endorsement exists with this id. This is very unlikely.");
    
    // Create and save endorsement
    Endorsements[id].certificateTemplateId  = _certificateTemplateId;
    Endorsements[id].endorser  = msg.sender;
    Endorsements[id].level     = _endorsement_level;
    Endorsements[id].state     = 1; 

    Courses[CertificateTemplates[_certificateTemplateId].courseId].endorsementArray.push(id);
    Users[msg.sender].endorsementArray.push(id);
    endorsementArray.push(id);
    
    // update a list of endorsements requiring approval by issuer
    Users[CertificateTemplates[_certificateTemplateId].issuer].pendingEndorsementArray.push(id);

    // emit event
    emit NewEndorsement(id, msg.sender, _certificateTemplateId);
  }

  // cancel endorsement (by endorser)
  function cancel_endorsement(bytes32 _endorsement) external{
    require((Endorsements[_endorsement].endorser == msg.sender), "Not your endorsement to cancel");
    Endorsements[_endorsement].state = canceled;
    emit CancelEndorsement(_endorsement, msg.sender);
  }

  // accept (or refuse) endorsement (by certificate template issuer)
  function decide_endorsement(bytes32 _endorsement, bool _decision) external{
    require((Endorsements[_endorsement].state == needs_approval), "This endorsement does not need approval");
    bytes32 certificateTemplateId = Endorsements[_endorsement].certificateTemplateId;
    require((CertificateTemplates[certificateTemplateId].issuer == msg.sender), "Not your endorsement to decide");

    Endorsements[_endorsement].state = _decision ? approved : declined;
    emit DecideEndorsement(_endorsement, msg.sender, certificateTemplateId, _decision);
  }

  function get_endorsement(bytes32 _id) external view returns (Endorsement memory){
    return(Endorsements[_id]);
  }
  
  // =========================================
  //
  //  Certificate template Management
  //
  // =========================================
  function add_certificate_template(bytes32 _courseId, string calldata _title, string calldata _description, string calldata _dataHash, uint _level) external{
    require(Users[msg.sender].issuer, "You need to be an Issuer to create a certificate template");
    require((Courses[_courseId].issuer == msg.sender), "That is not your course");
    // get unique ID
    bytes32 id = keccak256(abi.encodePacked(_courseId, msg.sender, certificateTemplateNonce++));
    require((CertificateTemplates[id].state == nonexistent ), "Already a cerificate template exists with this id. This is very unlikely.");
   
    CertificateTemplates[id].title       = _title;
    CertificateTemplates[id].description = _description;
    CertificateTemplates[id].dataHash    = _dataHash;
    CertificateTemplates[id].level       = _level;          // attendance, material, exams, extra
    CertificateTemplates[id].state       = active;
    CertificateTemplates[id].issuer      = msg.sender;
    CertificateTemplates[id].courseId    = _courseId;


    Courses[_courseId].certificateTemplateArray.push(id);
    emit NewCertificateTemplate(_courseId, _title, _level);
  }

  function get_certificate_template(bytes32 _id) public view returns(CertificateTemplate memory){
    return(CertificateTemplates[_id]);
  }

  // =========================================
  //
  //  Certificate Management
  //
  // =========================================
  function issue_certificate(bytes32 _templateId, address _recipient, string calldata _dataHash) external{
    CertificateTemplate memory ct = CertificateTemplates[_templateId];
    require( (ct.issuer == msg.sender), "This is not your certificate template.");
    require((Users[_recipient].state != nonexistent), "The recipient does not exist");

    // get unique ID
    bytes32 id = keccak256(abi.encodePacked(_templateId, msg.sender, certificateArray.length));
    require((Certificates[id].state == nonexistent ), "Already a cerificate template exists with this id. This is very unlikely.");
    
    Certificates[id].templateId = _templateId; 
    Certificates[id].recipient  = _recipient;
    Certificates[id].issuer     = msg.sender;
    Certificates[id].dataHash   = _dataHash;
    Certificates[id].state      = active;

    // add the cert to various lists
    certificateArray.push(id);
    CertificateTemplates[_templateId].certificateArray.push(id);
    Users[msg.sender].issuedCertificateArray.push(id);
    Users[_recipient].receivedCertificateArray.push(id);
    emit NewCertificate(_templateId, msg.sender, _recipient);
  }

  function get_certificate(bytes32 _id) external view returns(Certificate memory){
    return(Certificates[_id]);
  }
  
  function number_of_certificates() external view returns (uint256) {
    return certificateArray.length;
  }
} 
