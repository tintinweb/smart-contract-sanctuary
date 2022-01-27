/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.6;


contract CryptoNotes{

    // Contract owner (address)
    address public owner;


    // Dev wallet
    address public devWallet;

    
    // Users
    struct User{
        uint256 idUser;
        string nickName;
        uint totalNotes;
        bool isUser;
    }


    // Users key
    address[] internal kUser;


    // Mapping wallets to users
    mapping(address => User) internal users;


    // Notes
    struct Note{
        uint256 idUser;     // id de usuario que crea la nota
        string noteTitle;  // Titulo de la nota
        string noteBody;   // Cuerpo de la nota
        uint256 noteId;     // indice
        uint256 dayz;       // días que dura
        uint256 created_at;  // timestamp fecha de creacion
        bool isValid;
        mapping(address => bool) canSee; // wallets que pueden ver la nota
    }


    // Notes key
    uint256[] internal kNote;


    // Mapping Notes to ID
    mapping(uint256 => Note) notes;
    
    // Create notes is allowed?
    bool allowNewNotes;


    event NoteCreated(uint256 idNote, string title);
    event NicknameChanged(string oldNickname, string newNickname);
    event NewNotesEnabled(bool _npe);


    constructor() payable {
        owner = msg.sender;
        devWallet = 0xc69Be15252dBaC509009Af7c944b8E24C6d04887; // BSC testnet & mainnet
        //devWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; // Javascript or ganache
        allowNewNotes = true;
    }


    function createNote(string calldata _noteTitle, string calldata _noteBody, uint256 _dayz) external returns(uint256 noteId){
        require( allowNewNotes, "Cryptonotes: New notes are not allowed at this time." );
        User memory u;
        // Step 1: Check if sender already is a registred user, if not, create user
        if(! _isUserRegistered(msg.sender)){
            _createUser(msg.sender);
        }
        // Step 2: Get user ID
        u = users[msg.sender];
        // Step 3: Save note
        uint256 pp =_createNote(u.idUser, _noteTitle, _noteBody, _dayz);
        users[msg.sender].totalNotes++;
        emit NoteCreated(pp, _noteTitle);
        
        return pp;

    }


    function createAccount() external{
        _createUser(msg.sender);
    }


    function isUserRegistered(address account) external view returns(bool RegisteredUser){
        return _isUserRegistered(account);
    }


    function getUserInfo(address account) external view returns(User memory user){
        require(_isUserRegistered(account), "Cryptonotes: User not registered");
        return users[account];
    }
    
    
    function countUserNotes(address _user) external view returns(uint256 totalNotes){
        require (_isUserRegistered(_user), "User not registered");
        return users[_user].totalNotes;
    }
    
    
    function countNotes() external view returns(uint256 totalNotes){
        return kNote.length;
    }
    
    
    function countUsers() external view returns(uint256 totalUsers){
        return kUser.length;
    }
    
    
    function changeNickName(string calldata _nickname) external {
        require (_isUserRegistered(msg.sender), "User not registered");
        string calldata old = _nickname;
        users[msg.sender].nickName = _nickname;
        emit NicknameChanged(old, _nickname);
    }


    function about() external pure returns(string memory){
        return "Cryptonotes by Underdog1987. Made with love in MX";
    }
    
    
    function setPermissionToNote( uint256 _noteid, address _account, bool _canSee) external{
        require( _isValidNote(_noteid), "Cryptonotes: Note not found!" );
        require(notes[_noteid].canSee[_account] != _canSee, "This note already has that permission");
        // only note's author can manage permission
        require( kUser[notes[_noteid].idUser] == msg.sender, "Cryptonotes: Only author can manage permissions" );
        
        notes[_noteid].canSee[_account] = _canSee;
    }


    function getNote(uint256 i) external view returns(address author, string memory title, string memory noteBody, string memory nickName, uint256 createdAt){
        require( _isValidNote(i), "Cryptonotes: Note not found!" );
        require( (notes[i].canSee[msg.sender]) || (kUser[notes[i].idUser] == msg.sender), "Cryptonotes: You are not allowed to see this note" );
        
        uint256 tsExpired = notes[i].created_at + (notes[i].dayz * 24 * 60 *60);
        
        require(block.timestamp < tsExpired, "Cryptonotes: This note has expired");
        
        return (
            kUser[notes[i].idUser]
            ,notes[i].noteTitle
            ,notes[i].noteBody
            ,users[kUser[notes[i].idUser]].nickName
            ,notes[i].created_at
        );
    }


    receive() external payable {
        // receive BNB
  	}
  	
  	
  	function getBalance() external view returns(uint256){
  	    return address(this).balance;
  	}
  	
  	
  	function setDevWallet(address _newDevWallet) external {
  	    require(owner == msg.sender, "Cryptonotes: No owner");
  	    require(devWallet != _newDevWallet, "Cryptonotes: Dev weallet already is that address");
  	    _setDevWallet(_newDevWallet);
  	}
  	
  	
    function devWithdraw() external payable {
        require(owner == msg.sender, "Cryptonotes: No owner");
        require(address(this).balance > 0, "Cryptonotes: Cannot send 0 BNB");

        bool sent = payable(devWallet).send(address(this).balance);
        require(sent, "Failed to send Balance");
    }
    
    
    function AllowOrDisallowNewNotes() external{
         require(owner == msg.sender, "Cryptonotes: No owner");
         allowNewNotes = !allowNewNotes;
         emit NewNotesEnabled(allowNewNotes);
    }
    
    
    function newNotesEnabled() external view returns(bool){
        return allowNewNotes;
    }
  	
  	
    /**
     * Internal functions
     */
    // check if wallet is already registered
    function _isUserRegistered(address uZer) internal view returns(bool){
        if(kUser.length == 0) return false;
        return users[uZer].isUser && kUser[ users[uZer].idUser ] == uZer;
    }


    // register a wallet as user
    function _createUser(address _newUser) internal{
        require(!_isUserRegistered(_newUser), "Cryptonotes: User already registered");
        kUser.push(_newUser);
        users[_newUser].idUser =  kUser.length -1;
        users[_newUser].nickName = "Anonymous User";
        users[_newUser].totalNotes = 0;
        users[_newUser].isUser = true;
    }


    // create note
    function _createNote(uint256 userId, string calldata pt, string calldata pb, uint256 d) internal returns(uint256 pid) {
        require(d > 0, "Visibility must be greater than 0 days");
        kNote.push(userId);
        uint256 l = kNote.length -1;
        notes[l].idUser = userId;
        notes[l].noteTitle = pt;
        
        notes[l].noteBody = pb;
        notes[l].dayz = d;
        notes[l].created_at = block.timestamp;
        notes[l].noteId = l;
        notes[l].isValid = true;

        return l;
    }
    
    
    function _isValidNote(uint256 index) internal view returns( bool valid){
        if(kNote.length == 0) return false;
        return notes[index].isValid;
    }
    
    
    function _setDevWallet(address _ndw) internal{
        devWallet = _ndw;
    }
    
}