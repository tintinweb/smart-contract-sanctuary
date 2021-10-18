/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

pragma solidity 0.8.4;


// SPDX-License-Identifier: MIT;


contract CaseManager {
    
    mapping(address => bool )public isFirstResponder;
    mapping(address => bool ) public isInvestigator;
    mapping(address=> bool) public isProsecutor;
    mapping(uint256 => Evidence)  getEvidence; // case_id returns array of evidence struct
    mapping(string => Evidence[]) _getAllEvidence;
    mapping (uint256 => Case) _getCase;
    mapping(address => bool) public claimed;
    mapping(string => uint256[]) caseEvidenceIds; // get all case evidenceIds with caseId
    struct Evidence{
        address personnel;
        string evidenceHash;
        uint256 timestamp;
        uint256 evidenceId;
    }
    
    struct Case{
        string caseId;
        address initializer;
        
        Stage stage;
    }
    
    enum Stage{
         opened, closed
    }
    
    uint256 public evidenceID = 0;
    address public owner;
    event UpdateEvidence(address person, string evidence_hash, string case_id);
    event CaseCompleted( address person, uint256 case_id);
    
    modifier OnlyFirstResponder(){
        require(isFirstResponder[msg.sender], "first responder role is required");
        _;
    }
    
     modifier OnlyInvestigator(){
        require(isInvestigator[msg.sender],  "investigator role is required");
        _;
    }
    
    modifier OnlyProsecutor(){
        require(isProsecutor[msg.sender],  "prosecutor role is required");
        _;
    }
    
    // Admin should be a DAO
    modifier OnlyAdmin(){
        require(msg.sender ==owner, "unauthorized call");
        _;
    }
    
    modifier OnlyResponderOrInvestigator(){
        require(isFirstResponder[msg.sender] || isInvestigator[msg.sender], "unauthorized");
        _;
    }
    
    event ProsecutorAdded(address admin, address prosecutor);
    event FirstResponderAdded(address admin, address responder);
    event InvestigatorAdded(address admin, address investigator);
    event AdminChanged(address admin, address newAdmin);
    event CaseCompleted(address person, Stage stage);
    event DeleteCase(address person, uint256 caseId);
    event Claimed(address person, uint256 value);
    
    function addProsecutor(address _prosecutor) OnlyAdmin external{
        isProsecutor[_prosecutor] =true;
        emit ProsecutorAdded(msg.sender, _prosecutor);
    }
    
    function addFisrtResponder(address responder) OnlyAdmin external{
        isFirstResponder[responder] =true;
        emit FirstResponderAdded(msg.sender, responder);
    }
    
    function addInvestigator(address investigator) OnlyAdmin external{
        isInvestigator[investigator]=true;
        emit InvestigatorAdded(msg.sender, investigator);
    }
    
    function changeAdmin(address admin) OnlyAdmin external{
        owner = admin;
        emit AdminChanged(owner, admin);
    }
    
    constructor(){
        owner = msg.sender;
        isFirstResponder[msg.sender];
        isInvestigator[msg.sender];
        isProsecutor[msg.sender];
        
    }
    
 
    
    
    function getCase(uint256 _caseId) external view returns(Case memory){
        return _getCase[_caseId];
    }
    
    
    // caseId as input
    event Initialized(address initializer, string hash, string caseId, uint256 evidenceId);
    function initializeCase( string calldata evidence_hash, string calldata _caseId) external /*OnlyFirstResponder*/{
        Evidence memory evidence;
        evidenceID +=1;
        evidence.evidenceHash = evidence_hash;
        evidence.personnel =msg.sender;
        evidence.timestamp = block.timestamp;
        evidence.evidenceId = evidenceID;
        Case memory _case;
        _case.caseId = _caseId;
        _case.stage =Stage.opened;
        _case.initializer = msg.sender;
        caseEvidenceIds[_caseId].push(evidenceID);
        _getAllEvidence[_caseId].push(evidence);
        emit Initialized(msg.sender,evidence_hash, _caseId, evidenceID );
    }
    
    function updateCase( string calldata _caseId, string calldata evidenceHash) external OnlyResponderOrInvestigator{
        evidenceID +=1;
         Evidence memory evidence;
        evidence.evidenceHash = evidenceHash;
        evidence.personnel =msg.sender;
        evidence.timestamp = block.timestamp;
        evidence.evidenceId = evidenceID;
         _getAllEvidence[_caseId].push(evidence);
        caseEvidenceIds[_caseId].push(evidenceID);
        emit UpdateEvidence(msg.sender, evidenceHash, _caseId);
        
    }
    
    
    function completeCase(uint256 _caseId) external OnlyProsecutor{
        Case storage _case = _getCase[_caseId];
        _case.stage = Stage.closed;
        emit CaseCompleted(msg.sender, Stage.closed);
    }
    
    
    function deleteCase(uint256 _caseId) external OnlyProsecutor{
        delete _getCase[_caseId];
        emit DeleteCase(msg.sender, _caseId);
    }
    
    
    receive() external payable {
        
    }
    
    function getEther() external {
        require(!claimed[msg.sender], "claimed");
        (bool success, ) = address(msg.sender).call{value: 0.01 *10**17}("");
        require(success, "failed");
        claimed[msg.sender] = true;
        emit Claimed(msg.sender, 0.01 *10**17);
    }
    
    function getExcess() external OnlyAdmin{
        
        (bool success, ) = address(msg.sender).call{value: address(this).balance}("");
        require(success, "failed");
         emit Claimed(msg.sender, address(this).balance);
    }
    
}