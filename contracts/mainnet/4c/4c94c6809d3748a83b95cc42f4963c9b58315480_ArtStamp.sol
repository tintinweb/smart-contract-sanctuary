pragma solidity ^0.4.23;

contract ArtStamp { 
    
    /************************** */
    /*        STORAGE           */
    /************************** */
    struct Piece {
        string metadata;
        string title;
        bytes32 proof;
        address owner;
        //this currently does nothing, but i believe it will make it much easier if/when we make a future 
        //version of this app in which buying and selling pieces with ethereum is allowed
        bool forSale; 
        //witnesses have to sign off on any transfer or sale, but have no rights to initiate them
        //typically the witness will be the artist or anyone with rights to the pieces
        //as of right now witnesses can only be added when a piece is created and cannot be altered
        address witness;
    }

    //structure to keep track of a party to a contract and whether they have signed or not,
    //  and how much ether they have contributed
    struct Signature {
        address signee;
        bool hasSigned;
    }

    //structure to represent escrow situation and keep track of all parties to contract
    struct Escrow {
        Signature sender;
        Signature recipient;
        Signature witness;
        //block number when escrow is initiated, recorded so that escrow can timeout
        uint blockNum;
    }
    
    //contains all pieces on the market
    mapping (uint => Piece) pieces;

    //number of pieces
    uint piecesLength;

    //list of all escrow situations currently in progress
    mapping (uint => Escrow) escrowLedger;

    //this is used to ensure that no piece can be uploaded twice. 
    //dataRecord[(hash of a piece goes here)] will be true if that piece has already been uploaded
    mapping (bytes32 => bool) dataRecord;

    /************************** */
    /*         LOGIC            */
    /************************** */


    //



    /****** PUBLIC READ */

    //get data relating to escrow
    function getEscrowData(uint i) view public returns (address, bool, address, bool, address, bool, uint){
        return (escrowLedger[i].sender.signee, escrowLedger[i].sender.hasSigned, 
        escrowLedger[i].recipient.signee, escrowLedger[i].recipient.hasSigned, 
        escrowLedger[i].witness.signee, escrowLedger[i].witness.hasSigned, 
        escrowLedger[i].blockNum);
    }

    //returns total number of pieces
    function getNumPieces() view public returns (uint) {
        return piecesLength;
    }

    function getOwner(uint id) view public returns (address) {
        return pieces[id].owner;
    }

    function getPiece(uint id) view public returns (string, string, bytes32, bool, address, address) {
        Piece memory piece = pieces[id];
        return (piece.metadata, piece.title, piece.proof, piece.forSale, piece.owner, piece.witness);
    }
    
    function hashExists(bytes32 proof) view public returns (bool) {
        return dataRecord[proof];
    }

    function hasOwnership(uint id) view public returns (bool)
    {
        return pieces[id].owner == msg.sender;
    }


    //




    /****** PUBLIC WRITE */

    function addPieceAndHash(string _metadata, string _title, string data, address witness) public {
        bytes32 _proof = keccak256(abi.encodePacked(data));
        //check for hash collisions to see if the piece has already been uploaded
        addPiece(_metadata,_title,_proof,witness);
    }
    
    function addPiece(string _metadata, string _title, bytes32 _proof, address witness) public {
        bool exists = hashExists(_proof);
        require(!exists, "This piece has already been uploaded");
        dataRecord[_proof] = true;
        pieces[piecesLength] = Piece(_metadata,  _title, _proof, msg.sender, false, witness);
        piecesLength++;
    }

    //edit both title and metadata with one transaction, will make things easier on the front end
    function editPieceData(uint id, string newTitle, string newMetadata) public {
        bool ownership = hasOwnership(id);
        require(ownership, "You don&#39;t own this piece");
        pieces[id].metadata = newMetadata;
        pieces[id].title = newTitle;
    }

    function editMetadata(uint id, string newMetadata) public {
        bool ownership = hasOwnership(id);
        require(ownership, "You don&#39;t own this piece");
        pieces[id].metadata = newMetadata;
    }

    function editTitle(uint id, string newTitle) public {
        bool ownership = hasOwnership(id);
        require(ownership, "You don&#39;t own this piece");
        pieces[id].title = newTitle;
    }

    function escrowTransfer(uint id, address recipient) public {
        bool ownership = hasOwnership(id);
        require(ownership, "You don&#39;t own this piece");

        //set owner of piece to artstamp smart contract
        pieces[id].owner = address(this);

        //upadte escrow ledger
        escrowLedger[id] = Escrow({
            sender: Signature(msg.sender,false),
            recipient: Signature(recipient,false),
            witness: Signature(pieces[id].witness,false),
            blockNum: block.number});
    }
    

    //100000 blocks should be about 20 days which seems reasonable
    //TODO: should make it so contracts owner can change this
    uint timeout = 100000; 

    //timeout where piece will be returned to original owner if people dont sign
    function retrievePieceFromEscrow(uint id) public {
        //reject transaction if piece is not in escrow 
        require(pieces[id].owner == address(this));

        require(block.number > escrowLedger[id].blockNum + timeout);

        address sender = escrowLedger[id].sender.signee;

        delete escrowLedger[id];

        pieces[id].owner = sender;

    } 

    function signEscrow(uint id) public {
        //reject transaction if piece is not in escrow 
        require(pieces[id].owner == address(this));

        //reject transaction if signee isnt any of the parties involved
        require(msg.sender == escrowLedger[id].sender.signee ||
            msg.sender == escrowLedger[id].recipient.signee || 
            msg.sender == escrowLedger[id].witness.signee, 
            "You don&#39;t own this piece");

        bool allHaveSigned = true;

        if(msg.sender == escrowLedger[id].sender.signee){
            escrowLedger[id].sender.hasSigned = true;
        }  
        allHaveSigned = allHaveSigned && escrowLedger[id].sender.hasSigned;
        
        if(msg.sender == escrowLedger[id].recipient.signee){
            escrowLedger[id].recipient.hasSigned = true;
        }
        allHaveSigned = allHaveSigned && escrowLedger[id].recipient.hasSigned;
        

        if(msg.sender == escrowLedger[id].witness.signee){
            escrowLedger[id].witness.hasSigned = true;
        }        
        
        allHaveSigned = allHaveSigned && 
            (escrowLedger[id].witness.hasSigned || 
            escrowLedger[id].witness.signee == 0x0000000000000000000000000000000000000000);

        //transfer the pieces
        if(allHaveSigned)
        {
            address recipient = escrowLedger[id].recipient.signee;
            delete escrowLedger[id];
            pieces[id].owner = recipient;
        }
    }



    function transferPiece(uint id, address _to) public
    {
        bool ownership = hasOwnership(id);
        require(ownership, "You don&#39;t own this piece");

        //check if there is a witness, if so initiate escrow
        if(pieces[id].witness != 0x0000000000000000000000000000000000000000){
            escrowTransfer(id, _to);
            return;
        }

        pieces[id].owner = _to;
    }



}