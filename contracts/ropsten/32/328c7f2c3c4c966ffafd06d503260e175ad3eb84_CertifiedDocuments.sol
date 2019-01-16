pragma solidity ^0.4.23;

contract CertifiedDocuments {
    address public owner;
    mapping(bytes32 => subtitles) public project;
    mapping(bytes32 => bytes32[]) public ISANSubArray;
    mapping(bytes32 => uint256) public ArrayLength;
    bytes32[] public ISANFilmArray;

    constructor() public {
        owner = msg.sender;
    }

    modifier restricted() {
        require (msg.sender == owner);
        _;
    }
    
    function setOwner(address _owner)
        restricted
        public
    {
        owner = _owner;
    }

    struct subtitles {
        bytes32 ISAN;
        string filmName;
        string contractType;
        string contractHash;
        string signingDate;
        uint256 stripeTxNumber;
    }

    function createSubtitle(
        bytes32 ISANfilm_,
        bytes32 ISANsubtitles_,
        string memory filmName_,
        string memory contractType_,
        string memory contractHash_,
        string memory signingDate_,    
        uint256 stripeTxNumber_
    )
    // restricted
    payable
    public {
    // checks if project does not exist
        require(project[ISANsubtitles_].ISAN == 0);
        ISANFilmArray.push(ISANfilm_);
        ISANSubArray[ISANfilm_].push(ISANsubtitles_);
        ArrayLength[ISANfilm_] = ISANSubArray[ISANfilm_].length;
        project[ISANsubtitles_].ISAN = ISANsubtitles_;
        project[ISANsubtitles_].filmName = filmName_;
        project[ISANsubtitles_].contractType = contractType_;
        project[ISANsubtitles_].contractHash = contractHash_;
        project[ISANsubtitles_].signingDate = signingDate_;
        project[ISANsubtitles_].stripeTxNumber = stripeTxNumber_;
        emit SubtitleCreated(ISANsubtitles_);
    }
        
    function getSubtitleArray(
        bytes32 ISANsubtitles_
    )
    view
    public
    returns (bytes32, string memory, string memory, string memory, string memory, uint256) {
        return (project[ISANsubtitles_].ISAN,
        project[ISANsubtitles_].filmName,
        project[ISANsubtitles_].contractType,
        project[ISANsubtitles_].contractHash,
        project[ISANsubtitles_].signingDate,
        project[ISANsubtitles_].stripeTxNumber);
    }
    
    function getArrayLength(
        bytes32 ISANfilm_
    )
    view
    public
    returns (uint) {
        return ISANSubArray[ISANfilm_].length;
    }

    function getISANsubtitles(
        bytes32 ISANfilm_
    ) 
    view
    public
    returns (bytes32[] memory) {
        return ISANSubArray[ISANfilm_];
    }

    function getFilmName(
        bytes32 ISANsubtitles
    ) 
    view
    public
    returns (string memory) {
        return project[ISANsubtitles].filmName;
    }

    function getContractType(
        bytes32 ISANsubtitles_
    ) 
    view
    public
    returns (string memory) {
        return project[ISANsubtitles_].contractType;
    }

    function getContractHash(
        bytes32 ISANsubtitles_
    ) 
    view
    public
    returns (string memory) {
        return project[ISANsubtitles_].contractHash;
    }

    function getSigningDate(
        bytes32 ISANsubtitles_
    ) 
    view
    public
    returns (string memory) {
        return project[ISANsubtitles_].signingDate;
    }

    function getStripeTxNumber(
        bytes32 ISANsubtitles_
    ) 
    view
    public
    returns (uint256) {
        return project[ISANsubtitles_].stripeTxNumber;
    }

    event SubtitleCreated(bytes32 ISAN);
}