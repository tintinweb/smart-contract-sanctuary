pragma solidity ^0.4.18;

contract Owned {
    address owner;
    
    function Owned() public {
        owner = msg.sender;
    }
    
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
}

contract Aeromart is Owned {
    
    struct Note {
        bytes32 productID;
        bytes20 serialNumber;
        string text;
    }
    
    uint public notesLength;
    mapping (uint256 => Note) public notes;
   
    event noteInfo(
        bytes32 productID,
        bytes20 serialNumber,
        string text
    );
    
    function addNote(bytes32 _productID, bytes20 _serialNumber, string _text) onlyOwner public returns (uint) {
        Note storage note = notes[notesLength];
        
        note.productID = _productID;
        note.serialNumber = _serialNumber;
        note.text = _text;
        
        emit noteInfo(_productID, _serialNumber, _text);
        
        notesLength++;
        return notesLength;
    }
    
    function setNote(uint256 _id, bytes32 _productID, bytes20 _serialNumber, string _text) onlyOwner public {
        Note storage note = notes[_id];
        
        note.productID = _productID;
        note.serialNumber = _serialNumber;
        note.text = _text;
        
        emit noteInfo(_productID, _serialNumber, _text);
    }
    
    function getNote(uint256 _id) view public returns (bytes32, bytes20, string) {
        return (notes[_id].productID, notes[_id].serialNumber, notes[_id].text);
    }
    
    // comments section
    
    struct Comment {
        bytes3 rating; 
        string text;
    }
    
    uint public commentsLength;
    mapping (address => Comment) public comments;
    address[] public commentsAccounts;
    
    event commentInfo(
        bytes3 rating,
        string text
    );
    
    /*
    function addComment(bytes3 _rating, string _text) public returns (uint) {
        Comment storage comment = comments[msg.sender];
        
        comment.rating = _rating;
        comment.text = _text;
        
        emit commentInfo(_rating, _text);
        
        commentsLength++;
        return commentsLength;
        // commentsAccounts.push(msg.sender) -1;
    }
    */
    
    function setComment(bytes3 _rating, string _text) public {
        Comment storage comment = comments[msg.sender];
        
        comment.rating = _rating;
        comment.text = _text;
        
        emit commentInfo(_rating, _text);
        
        commentsAccounts.push(msg.sender) -1;
    }
    
    function getComment(address _address) view public returns (bytes3, string) {
        return (comments[_address].rating, comments[_address].text);
    }
    
    function getCommentAccounts() view public returns (address[]) {
        return commentsAccounts;
    }
    
    function getCommentAccountsLength() view public returns (uint) {
        return commentsAccounts.length;
    }
    
}