/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.7;


struct Annexure{
   
    string ipfsUrl;
    uint256 uploadDate;
}
struct Notesheet{
    
    string ipfsUrl;
    uint256 uploadDate;
}
struct Employee{
    address walletNumber;
    string empNum;
    string empName;
    string designation;
    string plantName;
}

struct UserAction{
    address fromAddress;
    address toAddress;
    string action;
    uint256 actionTime;
}

struct PredefinedNote{
    bytes32 noteId;
    string fileId;
    string subject;
    uint256 creationTime;
    
    //Annexure[] annexures;
  
    Notesheet notesheet;
    
    address initiator;
    //address[] filePaths;
    address currentOwner;
    
    //UserAction[] userActions;
    
    //string currentStatus;
    
}

struct PredefinedNoteTracker{
    bytes32 noteId;
    address currentOwner;
}

contract PredefinedWorkFlow{
    
    //Admin State variable
    address owner;
    
    //Functional state variable
    mapping(bytes32 => PredefinedNote) instantiatedNotes;
    PredefinedNoteTracker[] instantiatedNotesTrackers;
    
    mapping(address=>Employee) validEmployees;
    
    //constructor to set admin varaible
    constructor(){
        
        // Deployer of the contract become owner
        owner=msg.sender;
    }
    
    //Functionality Start
    
    event Response(bytes32,address);
    function createPredefinedNote(string memory _fileId,string memory _subject, address _recipient) public returns(bytes32){
        
        if(_recipient == address(0)){
            _recipient=msg.sender;
        }
        
        bytes32 _noteid=getNoteId();
        uint _currentTime=block.timestamp;
        
        Notesheet memory _notesheet=Notesheet("abc",123456);
        address _initiator=msg.sender;
        
      
        
        PredefinedNote memory _temp=PredefinedNote(_noteid,_fileId,_subject,_currentTime,_notesheet,_initiator,_recipient);
        instantiatedNotes[_noteid]=_temp;
        
        PredefinedNoteTracker memory _tracker=PredefinedNoteTracker(_noteid,_recipient);
        instantiatedNotesTrackers.push(_tracker);
      
        
        emit Response(_noteid,_recipient);
        return _noteid;
        
    }
    
    function getSubject() public view returns(string memory){
        
        string memory _subject;
        for(uint i=0;i<instantiatedNotesTrackers.length;i++){
            PredefinedNoteTracker memory _temp=instantiatedNotesTrackers[i];
            _subject=instantiatedNotes[_temp.noteId].subject;
        }
        
        return _subject;
    }
    
    
    function getListofFilesForAddress(address _address) public view returns(PredefinedNoteTracker[] memory){
        PredefinedNoteTracker[] memory _list=new PredefinedNoteTracker[](instantiatedNotesTrackers.length);
        
        for(uint i=0;i<instantiatedNotesTrackers.length;i++){
            
            PredefinedNoteTracker memory _temp=instantiatedNotesTrackers[i];
            if (_temp.currentOwner == _address){
                _list[i]=_temp;
            }
        }
        
        return _list;
    }
    
    function getPredefinedNote(bytes32 _trackerId) public view returns(PredefinedNote memory){
        
        return instantiatedNotes[_trackerId];
    }
    
    function getNoteId() internal view returns(bytes32)
    {
        // increase nonce
        uint randNonce=instantiatedNotesTrackers.length+1; 
        return (keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) ;
    }
    
}