/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

contract BC_BIM_Contract_v4 {
    string public name = 'PIER-BIM-v4';
    
    // Data holders*************************************************
    address userAdmin;
    uint public updatesCount = 0;
    uint public usersCount = 0;
    mapping(address => bool) public wallets;
    
    struct User {
        uint userId;
        string name;
        string company;
        string fileIpfsHash;
        string projectRole;
        string accessLevel;
    }
    mapping(address => User) public users;
    
    
    struct DrawingRecord {
        uint updateId;
        address author;
        address receiver;
        uint updateTime;
        
        string drawingNumber;
        string revision;
        string drawingTitle;
        string fileIpfsHash;
        
        address approver;
        bool approvalStatus;
    }
    mapping(uint256 => DrawingRecord) public drawingRecords;
    
    struct RequestForInspectionRecord {
        uint updateId;
        address author;
        address receiver;
        uint updateTime;
        
        string rfiNumber;
        string rfiDescrip;
        string fileIpfsHash;
        
        address inspector;
        bool inspectionStatus;
        string inspectorComments;
    }
    mapping(uint256 => RequestForInspectionRecord) public requestForInspectionsRecords;
    
    struct DrawingPublish {
        uint updateId;
        address author;
        address [] receiver;
        uint updateTime;
        
        string drawingNumber;
        string drawingStatus;
        string revision;
        string revisionDetails;
        string drawingTitle;
        string fileIpfsHash;
    }
    mapping(uint256 => DrawingPublish) public drawingPublishs;
    
    struct Correspondence {
        uint updateId;
        address author;
        address [] receiver;
        uint updateTime;
        
        string letterNumber;
        string letterTitle;
        string fileIpfsHash;
    }
    mapping(uint256 => Correspondence) public correspondences;
    
    
    
    // Constructor function*************************************************
    constructor() {
        userAdmin = msg.sender;
        wallets[userAdmin]=true;
        User storage u = users[userAdmin];
        u.accessLevel = 'Administrator';
    }
    
    //Modifiers and Events*****************************************************************
    modifier checkForWallet (address _wallet) {
        require(wallets[_wallet] == true, "Only parties who have been assigned wallets can create register or add new updates");
        _;
    }
    
    event Updates(uint indexed updateId, address indexed author,  uint indexed uploadTime, string updateType);
    event NewUserRegistered(uint usersCount, address indexed _wallet, string _name, string _company, string _avatarHash, string indexed _projectRole);
    
    // Functions of the contract*************************************************
    function newRequestForInspection(address _receiver, string memory _rfiNumber, string memory _rfiDescrip, string memory _fileIpfsHash) checkForWallet(msg.sender) public {
        // Make sure the file hash exists
        require(bytes(_fileIpfsHash).length > 0);
        // Make sure drawing number exists
        require(bytes(_rfiNumber).length > 0);
        
        updatesCount ++;
        
        RequestForInspectionRecord storage r = requestForInspectionsRecords[updatesCount];
        r.updateId  = updatesCount;
        r.author = msg.sender;
        r.receiver = _receiver;
        r.updateTime = block.timestamp;
        r.rfiNumber = _rfiNumber;
        r.rfiDescrip = _rfiDescrip;
        r.fileIpfsHash = _fileIpfsHash;
        
        emit Updates(updatesCount, msg.sender, block.timestamp, "New request for inspection (RFI)");
    }
    
    function newRequestForInspectionApproval(bool _inspectionStatus, string memory _inspectorComments, uint _updateNumber) checkForWallet(msg.sender) public {
        // Make sure drawing number exists
        require(requestForInspectionsRecords[_updateNumber].updateId > 0, "The selected RFI does not exist as an update on the blockchain");
        
        RequestForInspectionRecord storage r = requestForInspectionsRecords[_updateNumber];
        r.inspector  = msg.sender;
        r.inspectionStatus = _inspectionStatus;
        r.inspectorComments = _inspectorComments;
        
        emit Updates(updatesCount, msg.sender, block.timestamp, "New request for inspection (RFI) approved");
    }
    
    function newCorrespondence(address[] memory _receiver, string memory _letterNumber, string memory _letterTitle, string memory _fileIpfsHash) checkForWallet(msg.sender) public {
        // Make sure the file hash exists
        require(bytes(_fileIpfsHash).length > 0);
        // Make sure drawing number exists
        require(bytes(_letterNumber).length > 0);
        
        updatesCount ++;
        correspondences[updatesCount] = Correspondence(updatesCount, msg.sender, _receiver, block.timestamp, _letterNumber, _letterTitle, _fileIpfsHash);
        
        emit Updates(updatesCount, msg.sender, block.timestamp, "New correspondence");
    }
    
    function newDrawingPublish(address[] memory _receiver, string memory _drawingNumber, string memory _drawingStatus, string memory _revision, string memory _revisionDetails, string memory _drawingTitle, string memory _fileIpfsHash, uint _updateNumber) checkForWallet(msg.sender) public {
        // Make sure the file hash exists
        require(bytes(_fileIpfsHash).length > 0);
        // Make sure drawing number exists
        require(bytes(_drawingNumber).length > 0);
        //Make sure drawing's status is approved in the drawingRecords
        require(drawingRecords[_updateNumber].approvalStatus == true, "Selected drawing is not on the approved list. Please check if the file was modified or please send the drawing for approval first.");
        
        updatesCount ++;
        drawingPublishs[updatesCount] = DrawingPublish(updatesCount, msg.sender, _receiver, block.timestamp, _drawingNumber, _drawingStatus, _revision, _revisionDetails, _drawingTitle, _fileIpfsHash);
        
        emit Updates(updatesCount, msg.sender, block.timestamp, "New drawing published");
    }
    
    function newDrawingApprovalRequest(address _receiver, string memory _drawingNumber, string memory _revision, string memory _drawingTitle, string memory _fileIpfsHash) checkForWallet(msg.sender) public {
        // Make sure the file hash exists
        require(bytes(_fileIpfsHash).length > 0);
        // Make sure drawing number exists
        require(bytes(_drawingNumber).length > 0);
        
        updatesCount ++;
        
        DrawingRecord storage p = drawingRecords[updatesCount];
        p.updateId  = updatesCount;
        p.author = msg.sender;
        p.receiver = _receiver;
        p.updateTime = block.timestamp;
        p.drawingNumber = _drawingNumber;
        p.revision = _revision;
        p.drawingTitle = _drawingTitle;
        p.fileIpfsHash = _fileIpfsHash;
        
        emit Updates(updatesCount, msg.sender, block.timestamp, "New drawing approval request");
    }
    
    function newDrawingApproval(bool _approvalStatus, uint _updateNumber) checkForWallet(msg.sender) public {
        // Make sure drawing number exists
        require(drawingRecords[_updateNumber].updateId > 0, "The selected drawing does not exist as an update on the blockchain");
        
        DrawingRecord storage p = drawingRecords[_updateNumber];
        p.approver  = msg.sender;
        p.approvalStatus = _approvalStatus;
        
        emit Updates(_updateNumber, msg.sender, block.timestamp, "New drawing approved");
    }
    
    function newWallet(address _wallet, string memory _accessLevel) public{
        require(msg.sender == userAdmin, "Only the party that deployed the smart contract can add assign new wallets for other parties who want to join this project");
        
        wallets[_wallet]=true;
        User storage u = users[_wallet];
        u.accessLevel = _accessLevel;
    }
    
    function newUser(string memory _name, string memory _company, string memory _fileIpfsHash, string memory _projectRole) checkForWallet(msg.sender) public {
        usersCount ++;
        // users[msg.sender] = User(usersCount, _name, _fileIpfsHash, _projectRole, _accessLevel);
        
        User storage u = users[msg.sender];
        u.userId = usersCount;
        u.name = _name;
        u.company = _company;
        u.fileIpfsHash = _fileIpfsHash;
        u.projectRole = _projectRole;
        
        emit NewUserRegistered(usersCount, msg.sender, _name, _company, _fileIpfsHash, _projectRole);
    }
}