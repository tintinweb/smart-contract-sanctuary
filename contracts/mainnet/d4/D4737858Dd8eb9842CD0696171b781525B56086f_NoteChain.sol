pragma solidity ^0.4.23;

/**
 * @title NoteChain
 * @dev The NoteChain contract provides functions to store notes in blockchain
 */

contract NoteChain {

        // EVENTS
        event NoteCreated(uint64 id, bytes2 publicKey);
        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

        // CONSTANTS
        uint8 constant Deleted = 1;
        uint8 constant IsPrivateBitPosition = 1;

        address public owner;
        uint public noteChainFee = 0.0002 ether; // fee for using noteChain

        struct Note {
                uint16 metadata;
                bytes2 publicKey; 
                // publicKey: generated client-side, 
                // it will create a code for share URL-> publicKey + hex(_noteId)

                bytes12 title;
                bytes content;
        }

        Note[] private notes;

        mapping (uint64 => address) private noteToOwner;
        mapping (address => uint64[]) private ownerNotes;

        // PURE FUNCTIONS
        function isPosBitOne(uint data, uint pos) internal pure returns (bool) {
                return data % (2**(pos+1)) >= (2**pos);
        }

        // MODIFIERS
        modifier onlyOwner() {
                require(msg.sender == owner);
                _;
        }

        modifier onlyOwnerOf(uint64 _noteId) {
                require(msg.sender == noteToOwner[_noteId]);
                _;
        }

        modifier payFee() {
                require(msg.value >= noteChainFee);
                _;
        }

        modifier notDeleted(uint64 _noteId) {
                require(uint8(notes[_noteId].metadata) != Deleted);
                _;
        }

        modifier notPrivate(uint64 _noteId) {
                require(isPosBitOne( uint( notes[_noteId].metadata), uint(IsPrivateBitPosition) ) == false );
                _;
        }

        // constructor
        constructor() public {
                owner = msg.sender;
        }

        function setFee(uint _fee) external onlyOwner {
                noteChainFee = _fee;
        }

        function withdraw(address _address, uint _amount) external onlyOwner {
                require(_amount <= address(this).balance);
                address(_address).transfer(_amount);
        }

        function getBalance() external constant returns(uint){
                return address(this).balance;
        }

        function transferOwnership(address newOwner) external onlyOwner {
                require(newOwner != address(0));
                emit OwnershipTransferred(owner, newOwner);
                owner = newOwner;
        }

        // NOTES related functions
        // payable functions
        function createNote(uint16 _metadata, bytes2 _publicKey, bytes12 _title, bytes _content) external payable payFee {
                uint64 id = uint64(notes.push(Note(_metadata, _publicKey, _title, _content))) - 1;
                noteToOwner[id] = msg.sender;
                ownerNotes[msg.sender].push(id);
                emit NoteCreated(id, _publicKey);
        }

        function deleteNote(uint64 _noteId) external notDeleted(_noteId) onlyOwnerOf(_noteId) payable payFee {
                notes[_noteId].metadata = Deleted;
        }

        function updateNote(uint64 _noteId, uint16 _metadata, bytes12 _title, bytes _content) external notDeleted(_noteId) onlyOwnerOf(_noteId) payable payFee {
                Note storage myNote = notes[_noteId];
                myNote.title = _title;
                myNote.metadata = _metadata;
                myNote.content = _content;
        }

        function updateNoteMetadata(uint64 _noteId, uint16 _metadata) external notDeleted(_noteId) onlyOwnerOf(_noteId) payable payFee {
                Note storage myNote = notes[_noteId];
                myNote.metadata = _metadata;
        }

        function updateNoteContent(uint64 _noteId, bytes _content) external notDeleted(_noteId) onlyOwnerOf(_noteId) payable payFee {
                Note storage myNote = notes[_noteId];
                myNote.content = _content;
        }

        function updateNoteTitle(uint64 _noteId, bytes12 _title) external notDeleted(_noteId) onlyOwnerOf(_noteId) payable payFee {
                Note storage myNote = notes[_noteId];
                myNote.title = _title;
        }

        function updateNoteButContent(uint64 _noteId, uint16 _metadata, bytes12 _title) external notDeleted(_noteId) onlyOwnerOf(_noteId) payable payFee {
                Note storage myNote = notes[_noteId];
                myNote.metadata = _metadata;
                myNote.title = _title;
        }

        // view functions
        function getNotesCount() external view returns (uint64) {
                return uint64(notes.length);
        }

        function getMyNote(uint64 _noteId) external notDeleted(_noteId) onlyOwnerOf(_noteId) view returns (uint16, bytes12, bytes) {
                return (notes[_noteId].metadata, notes[_noteId].title, notes[_noteId].content);
        }

        function getMyNotes(uint64 _startFrom, uint64 _limit) external view returns (uint64[], uint16[], bytes2[], bytes12[], uint64) {
                uint64 len = uint64(ownerNotes[msg.sender].length);
                uint64 maxLoop = (len - _startFrom) > _limit ? _limit : (len - _startFrom);

                uint64[] memory ids = new uint64[](maxLoop);
                uint16[] memory metadatas = new uint16[](maxLoop);
                bytes2[] memory publicKeys = new bytes2[](maxLoop);
                bytes12[] memory titles = new bytes12[](maxLoop);

                for (uint64 i = 0; i < maxLoop; i++) {
                        ids[i] = ownerNotes[msg.sender][i+_startFrom];
                        metadatas[i] = notes[ ids[i] ].metadata;
                        publicKeys[i] = notes[ ids[i] ].publicKey;
                        titles[i] = notes[ ids[i] ].title;
                }
                return (ids, metadatas, publicKeys, titles, len);
        }

        function publicGetNote(uint64 _noteId, bytes2 _publicKey) external notDeleted(_noteId) notPrivate(_noteId) view returns (uint16, bytes12, bytes) {
                require(notes[_noteId].publicKey == _publicKey); // for public to get the note&#39;s data, knowing the publicKey is needed
                return (notes[_noteId].metadata, notes[_noteId].title, notes[_noteId].content);
        }

}