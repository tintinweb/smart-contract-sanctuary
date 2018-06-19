pragma solidity ^0.4.22;

contract Owned {
    address owner;
    
    function constuctor() public {
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
        string textOrImage;
    }
    
    uint public notesLength;
    mapping (uint256 => Note) public notes;
   
    event noteInfo(
        bytes32 productID,
        string textOrImage
    );
    
    function addNote(bytes32 _productID, string _textOrImage) onlyOwner public returns (uint) {
        Note storage note = notes[notesLength];
        
        note.productID = _productID;
        note.textOrImage = _textOrImage;
		
        emit noteInfo(_productID, _textOrImage);
        
        notesLength++;
        return notesLength;
    }
    
    function setNote(uint256 _id, bytes32 _productID, string _textOrImage) onlyOwner public {
        Note storage note = notes[_id];
        
        note.productID = _productID;
        note.textOrImage = _textOrImage;
        
        emit noteInfo(_productID, _textOrImage);
    }
    
    function getNote(uint256 _id) view public returns (bytes32, string) {
        return (notes[_id].productID, notes[_id].textOrImage);
    }
    
    // comments section
    
    struct Comment {
        bytes3 rating; 
        string text;
    }
    
    uint public commentsLength;
    mapping (uint256 => Comment) public comments;
    address[] public commentsAccounts;
    
    event commentInfo(
        bytes3 rating,
        string text
    );
    
    function addComment(bytes3 _rating, string _text) public returns (uint) {
        Comment storage comment = comments[commentsLength];
        
        comment.rating = _rating;
        comment.text = _text;
        
        emit commentInfo(_rating, _text);
        
        commentsLength++;
        return commentsLength;
    }
        
    function setComment(uint256 _id, bytes3 _rating, string _text) public {
        Comment storage comment = comments[_id];
        
        comment.rating = _rating;
        comment.text = _text;
        
        emit commentInfo(_rating, _text);
    }
    
    function getComment(uint256 _id) view public returns (bytes3, string) {
        return (comments[_id].rating, comments[_id].text);
    }
    
}