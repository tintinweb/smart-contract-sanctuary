pragma solidity 0.4.25;

contract EthDegreeValidation {
    
    address public owner;
    address public pendingOwner;

    event DegreeAdded(bytes32 indexed _hash, address indexed _by);
    event ModeratorAdded(address _address);
    event ModeratorRemoved(address _address);

    modifier onlyOwner() {
        require(msg.sender == owner, "This function is only available to the \"owner\" address of this contract.");
        _;
    }
    
    modifier onlyMod() {
        require(isMod(msg.sender), "This function is only available to Moderator addresses.");
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "This function can only be executed by the pending Owner address.");
        _;
    }
    
    struct DegreeOwnership {
        uint date;
        string name;
    }
    
    struct Moderator {
        //pointer to moderatorsList entry
        uint index;
        //descreption
        string universityName;
    }
    
    mapping (bytes32 => DegreeOwnership) private degrees;
    bytes32[] private sha256HashesOfDegrees;
    
    mapping (address => Moderator) private moderators;
    address[] private moderatorsList;

    //constructor runs only once on contract creation
    constructor() public {
        owner = msg.sender;
        //change pendingOwner so that pendingOwner != 0x0
        pendingOwner = msg.sender;
        //add owner as a moderator
        addModerator(msg.sender, "Contract owner");
        //instead of checking if _sha256ofpdf != 0x0 on every addition of a degree
        addNewDegree("Invalid Hash", 0x0);
    }
    
    function addNewDegree(string _name, bytes32 _sha256ofpdf) onlyMod public {
        //check input string to be < 256bytes ie 8words
        require(bytes(_name).length < 256, "Provided name is of unrealistic length.");
        //check user supplied a name
        require(bytes(_name).length > 0, "A name was not provided.");
        //check if degree already exists/ prevent change on an existing degree
        require(degrees[_sha256ofpdf].date == 0, "This degree is already validated.");
        
        DegreeOwnership storage degree = degrees[_sha256ofpdf];
        
        degree.name = _name;
        degree.date = block.timestamp;
        
        sha256HashesOfDegrees.push(_sha256ofpdf);
        emit DegreeAdded(_sha256ofpdf, msg.sender);
    }
    
    //Add a moderator that can register degrees
    function addModerator(address _moderatorAddress, string _uniName) onlyOwner public {
        //check inputs
        require(_moderatorAddress != address(0x0), "An ethereum address was not provided.");
        require(bytes(_uniName).length > 0, "A university name was not provided.");
        //Ensure _moderatorAddress doesnt already belong to a moderator
        require(!isMod(_moderatorAddress), "This is already a moderator address.");
        
        //Moderator instance to work with
        Moderator storage moderator = moderators[_moderatorAddress];
        //writing the values
        moderator.universityName = _uniName;
        //======================================================================//
        //Non combined version:
        //moderator.index = moderatorsList.length;
        //moderatorsList.push(_moderatorAddress);
        //push returns the new array length so using it here saves a bit of gas
        moderator.index = moderatorsList.push(_moderatorAddress)-1;
        //======================================================================//
        emit ModeratorAdded(_moderatorAddress);
    }
    
    //check if address belongs to a moderator
    function isMod(address _moderatorAddress) public view returns(bool) {
        if (moderatorsList.length == 0) {
            return false;
        }
        if (moderators[_moderatorAddress].index > (moderatorsList.length - 1)) {
            return false;
        }
        return (moderatorsList[moderators[_moderatorAddress].index] == _moderatorAddress);
    }
    
    //remove a moderator
    function removeModerator(address _moderatorAddress) onlyOwner public {
        //Ensure the _moderatorAddress belongs to a moderator
        require(isMod(_moderatorAddress), "The provided address does not belong to a moderator.");
        
        //remove entry from table of moderators
        //initialize rowToDelete and keyToMove in preparation of reorganizement
        uint rowToDelete = moderators[_moderatorAddress].index;
        address keyToMove = moderatorsList[moderatorsList.length-1];
        //3-step reorganizement of unorderedlist:
        //step1 - move the last row to the row we want to delete
        moderatorsList[rowToDelete] = keyToMove;
        //step2 - update the pointer(index) of the Moderator struct
        moderators[keyToMove].index = rowToDelete;
        //step3 - delete last row (underflow check already done at isMod)
        moderatorsList.length--;
        emit ModeratorRemoved(_moderatorAddress);
    }
    
    //return hash of a degree by id (used only if it&#39;s needed to transfer degrees to new contract)
    function getDegreeAtIndex(uint _index) public view returns (bytes32) {
        require(_index < sha256HashesOfDegrees.length, "The provided Index is higher than then total number of degrees. There is nothing there.");
        return sha256HashesOfDegrees[_index];
    }
    
    function getDegree(bytes32 _sha256ofpdf) public view returns(bytes32, string, uint) {
        require(degrees[_sha256ofpdf].date != 0, "The provided hash does not belong to any validated degree.");
        return (_sha256ofpdf, degrees[_sha256ofpdf].name, degrees[_sha256ofpdf].date);
    }
    
    function getDegreeCount() public view returns(uint) {
        return sha256HashesOfDegrees.length;
    }
    
    function getModeratorAtIndex(uint _index) public view returns(address) {
        require(_index < moderatorsList.length, "The provided Index is higher than then total number of moderators. There is nothing there.");
        return moderatorsList[_index];
    }
    
    function getModerator(address _moderatorAddress) public view returns(address, uint, string) {
        require(isMod(_moderatorAddress),"The provided address does not belong to a moderator.");
        return (_moderatorAddress, moderators[_moderatorAddress].index, moderators[_moderatorAddress].universityName);
    }
    
    function getModeratorCount() public view returns(uint) {
        return moderatorsList.length;
    }

    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner !=address(0x0), "An ethereum address was not provided.");
        pendingOwner = _newOwner;
    }

    function claimOwnership() onlyPendingOwner public {
        owner = pendingOwner;
    }

}