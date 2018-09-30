pragma solidity ^0.4.24;

/**
 * @title OathOwnable
 * @dev Modified version of standard Ownable Contract
 * The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract OathAccessControlled {

  /**
   * @dev ownership set via mapping with the following levels of access:
   * 0 (default) ---- general (limited) access
   * 1 (publisher) ---- can see song credits and splits
   * 2 (songwriter) ---- can see all data, sign to add themselves
   * 3 (owner) ---- contract owner
   */

    mapping(address => uint256) public accessLevel;

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        accessLevel[msg.sender] = 3;
    }


    modifier defaultAccessLevel () {
        require(accessLevel[msg.sender] >= 0);
        _;
    }

    modifier RequiresPublisherAccess () {
        require(accessLevel[msg.sender] >= 1);
        _;
    }

    modifier RequiresSongWriterAccess () {
        require(accessLevel[msg.sender] >= 2);
        _;
    }

    modifier RequiresOwnerAccess () {
        require(accessLevel[msg.sender] >= 3);
        _;
    }

    /**
     * @dev setAccessLevel for a user restricted to contract owner
     * @dev Ideally, check for whole number should be implemented (TODO)
     * @param _user address that access level is to be set for
     * @param _access uint256 level of access to give 0, 1, 2, 3.
     */
    function setAccessLevel(address _user, uint256 _access) public RequiresOwnerAccess {
        require(accessLevel[_user] < 3);
        if (_access < 0 || _access > 3) {
            revert();
        } else {
            accessLevel[_user] = _access;
        }
    }

    /**
     * @dev getAccessLevel for a _user given their address
     * @param _user address of user to return access level
     * @return uint256 access level of _user
     */
    function getAccessLevel(address _user) public view returns (uint256) {
        return accessLevel[_user];
    }

    /**
     * @dev helper function to make calls more efficient
     * @return uint256 access level of the caller
     */
    function myAccessLevel() public view returns (uint256) {
        return getAccessLevel(msg.sender);
    }

}

contract OathMusic is OathAccessControlled {
///|=:=|=:=|=:=|=:=|=:=|=:=|=:=|~Type Declarations~|=:=|=:=|=:=|=:=|=:=|=:=|=:=|\\\
    struct SongWriter {
        string name;
        uint256 split;
        uint256 idNumber;
        address signingAddress;
        bool signed;
    }

    /// mapping song writer (address) to SongWriter struct 
    mapping(address => SongWriter) public songWriterDB;

    /// 
    mapping(address => uint256) public pendingSignatures;

    ///|=:=|=:=|=:=|=:=|=:=|=:=|=:=|~~~~~Constants~~~~~|=:=|=:=|=:=|=:=|=:=|=:=|=:=|\\\


    ///|=:=|=:=|=:=|=:=|=:=|=:=|=:=|~~State Variables~~|=:=|=:=|=:=|=:=|=:=|=:=|=:=|\\\
    string public songTitle;
    bytes32 public lyricsStoragePointer;
    bytes32 public audioStoragePointer;
    bytes32 public pdfAttachmentStoragePointer;
    SongWriter[] public songwriters;
    uint256 public songWriterCount;

    ///|=:=|=:=|=:=|=:=|=:=|=:=|=:=|~~~~~~Events~~~~~~~|=:=|=:=|=:=|=:=|=:=|=:=|=:=|\\\

    event SongDataAdded(
        string title,
        bytes32 lyricsHash,
        bytes32 audioHash,
        bytes32 leadsheetHash
    );

    event SongWriterAdded(
        string swName,
        uint256 swSplit,
        uint256 sqId,
        address indexed swAddress
    );

    event SongWriterSigned(address signingSongWriter, bool didTheySign, uint256 sigStatus);

    event SignatureStatusChange(address target, uint256 status);

    ///|=:=|=:=|=:=|=:=|=:=|=:=|=:=|~~~~~Modifiers~~~~~|=:=|=:=|=:=|=:=|=:=|=:=|=:=|\\\


    ///|=:=|=:=|=:=|=:=|=:=|=:=|=:=|~~~~Constructor~~~~|=:=|=:=|=:=|=:=|=:=|=:=|=:=|\\\
    constructor() public {
        songWriterCount = 0;
    }

    ///|=:=|=:=|=:=|=:=|=:=|=:=|=:=|~Public~~Functions~|=:=|=:=|=:=|=:=|=:=|=:=|=:=|\\\

    /// WARNING DEV ENVIRONMENT ONLY!!!!!
    
    function destroy() public {
        selfdestruct(msg.sender);
    }


    /// TEST DATA: "Three Little Birds", "QmS987m3EFH8nQDjqsVubLZqrhmYF49Su7xCmXUvZkbmgN", "QmS987m3EFH8nQDjqsVubLZqrhmYF49Su7xCmXUvZkbmgN", "QmS987m3EFH8nQDjqsVubLZqrhmYF49Su7xCmXUvZkbmgN"
    /**
     * @dev addSongData adds the metadata to the deployed song contract
     * @dev Ideally, should be private and called only via contructor at deployment
     * @param _title string song title
     * @param _string1 string lyricsStoragePointer
     * @param _string2 string audioStoragePointer
     * @param _string3 string pdfAttachmentStoragePointer
     */
    function addSongData(
        string _title,
        string _string1,
        string _string2,
        string _string3
    )
        public
        RequiresOwnerAccess
    {
        songTitle = _title;
        lyricsStoragePointer = hashData(_string1);
        audioStoragePointer = hashData(_string2);
        pdfAttachmentStoragePointer = hashData(_string3);

        emit SongDataAdded(
            songTitle,
            lyricsStoragePointer,
            audioStoragePointer,
            pdfAttachmentStoragePointer
        );
    }

    /**
     * @dev addSongWriter adds the metadata for a Song Writer to the deployed song contract
     * @param _name string name of songwriter
     * @param _split uint256 split of royalties that songwriter is to receive
     * @param _songWriterAddress address used by songwriter for signing
     */
    function addSongWriter(
        string _name,
        uint256 _split,
        address _songWriterAddress
    )
        public
        RequiresOwnerAccess
    {
        if (pendingSignatures[_songWriterAddress] > 0) {
            revert("Duplicate Song Writer");
        }

        /// New SongWriter Struct
        SongWriter memory artist;

        artist.name = _name; /// User input
        artist.split = _split; /// User input
        artist.idNumber = songWriterCount + 1; /// Id set to current count + 1
        artist.signingAddress = _songWriterAddress; /// User input
        artist.signed = false; /// Set signed to false

        /// If song writer does not have owner access (not owner) give artist access
        if (getAccessLevel(_songWriterAddress) != 3) {
            setAccessLevel(_songWriterAddress, 2);
        }

        /// Add address to songwriter mapping
        songWriterDB[_songWriterAddress] = artist;

        /// set songwriter address as having pending signature
        setPendingSignatureStatus(_songWriterAddress, 1);

        /// update songwriter count
        songWriterCount = songWriterCount + 1;

        // event emission
        emit SongWriterAdded(
            _name,
            _split,
            songWriterCount + 1,
            _songWriterAddress
        );

    }
    
    /**
     * @dev songWriterSign allows songwriters added to song contract to sign off on their addition
     * @dev function first checks that they have no already signed and that they are elgibile to sign
     */
    function songWriterSign() public RequiresSongWriterAccess {
        require(songWriterDB[msg.sender].signed == false, "SongWriter already signed");
        require(pendingSignatures[msg.sender] == 1, "SongWriter not found for this song");

        /// Set signature status to 2 from 1 and update SongWriter struct for signer
        pendingSignatures[msg.sender] = 2;
        songWriterDB[msg.sender].signed = true;


        /// New SongWriter Struct
        SongWriter memory artist;

        artist = songWriterDB[msg.sender];
        artist.signed = true; /// Set signed to false
        /// Add struct to array of SongWriter Structs
        songwriters.push(artist);

        /// Event emission
        emit SongWriterSigned(msg.sender, songWriterDB[msg.sender].signed, pendingSignatures[msg.sender]);
    }

///|=:=|=:=|=:=|=:=|=:=|=:=|=:=|View~~Functions|=:=|=:=|=:=|=:=|=:=|=:=|=:=|\\\

    /**
     * @dev returns whether the song writer status is signed
     * @param _songWriter address of the songwriter to return whether they have signed
     * @return bool status of whether _songWriter has signed
     */
    function hasSongWriterSigned(address _songWriter) public view returns (bool) {
        return songWriterDB[_songWriter].signed;
    }

    /**
     * @dev returns the signature status of a given address
     * @param _target address for signature status determination
     * @return uint256 status of signature for _target 0, 1, 2.
     */
    function getPendingSignatureStatus(address _target) public view returns (uint256) {
        return pendingSignatures[_target];
    }

///|=:=|=:=|=:=|=:=|=:=|=:=|=:=|Internal~~Functions|=:=|=:=|=:=|=:=|=:=|=:=|=:=|\\\
    /**
     * @dev Returns the bytes32 hash for a given string
     * @param _input string to hash
     */
    function hashData(string _input) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_input));
    }

    /**
     * @dev sets pending signature status for a target address 
     * @param _target address for pending signature status change
     * @param _access uint256 status code to set for target
     * @dev _access values:
     *      0 - (default) -> not pending + not signed
     *      1 - (added but unsigned) -> pending + not signed
     *      2 - (added and signed) -> not pending + signed
     */
    function setPendingSignatureStatus(address _target, uint256 _access) internal {
        pendingSignatures[_target] = _access;
        emit SignatureStatusChange(_target, _access);
    }

///|=:=|=:=|=:=|=:=|=:=|=:=|=:=|~Private~Functions~|=:=|=:=|=:=|=:=|=:=|=:=|=:=|\\\






}