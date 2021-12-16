/**
 *Submitted for verification at polygonscan.com on 2021-12-15
*/

// File: contracts/IStructs.sol



pragma solidity ^0.8.0;

interface IStructs {
    struct Sentry {
        uint16 id; 
        // 0=Human, 1=cyborg, 2=alien
        uint8 species;
        uint dna; 
        uint8 attack;
        uint8 defense; 
        uint8 luck;
        bool infected;

    }


    struct GameplayStats {
      uint16 sentryId;
      bool isDeployed;
      uint8 riskCode;
      uint cooldownTimestamp;
      uint16 daysSurvived;
      uint16 longestStreak;
      uint deploymentTimestamp;
      uint16 successfulAttacks;
      uint16 successfulDefends;
    }


    struct DeploymentParty {
        uint id;
        uint16[] listOfIds;
        address leaderAddress;
        bool isDeployed;
    }
}
// File: contracts/ISentryFactory.sol



pragma solidity ^0.8.0;


interface ISentryFactory is IStructs  {
    // Interface used by gameplay contract
    // Need to get traits for gameplay RNG
    // Need owner to return $BITS upond evac
    
    // get owner address of a sentry
    function getSentryOwner(uint16 tokenId) external view returns (address);

    // retrieve sentry traits for gameplay
    function getSentryTraits(uint16 tokenId) external view returns (Sentry memory);
    // get number of sentries byy owner
    // ensures an address actually owns a token
    function getOwnerSentryCount(address owner) external view returns (uint);


    // Infect sentry
    // Called by gameplay
    function infectSentry(uint16 tokenId) external;
}
// File: contracts/IDeadzone.sol



pragma solidity ^0.8.0;


interface IDeadzone is IStructs {

    function setPartyId(uint16 sentryId ,uint partyId) external;
    function getStatsFromId(uint16 tokenId) external view returns(GameplayStats memory);
    function editRiskCode(uint16 sentryId ,uint8 newCode) external;

    function evac(uint16 sentryId) external;
}
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/DeploymentParty.sol


pragma solidity ^0.8.0;





contract DeploymentParty is Ownable, IStructs {
///*EVENTS*
    event PartyCreated(uint partyId, address owner, uint timestamp);
    event PartyDeployUpdate(uint partyId, uint timestamp);
    event PartyMemberUpdate(uint16 sentryId, uint partyId, uint timestamp);
    
///*VARS*
    uint allTimePartyCount;
    uint8 maxPartyCount;
    DeploymentParty[] public parties;
    uint randNonce = 1;

///*MAPPINGS*
    mapping(uint => DeploymentParty) public idToParty;
    mapping(address => bool) public controllers;

    //Map identifies sentry, and then relays to map for invitation boolean
    mapping(uint16 => mapping(uint=> bool)) sentryIdToPartyInvites;

    mapping(uint16 => uint) sentryIdToParty;

///*CONTRACT_REFS*
    IDeadzone public deadzone;
    ISentryFactory public factory;

    constructor(){
        maxPartyCount = 8;
        allTimePartyCount = 1;
    }

///*MODIFIERS*
    modifier onlyControllers() {
        require(controllers[msg.sender], "You do not have permission to access this functionality!");
        _;
    }
    modifier onlyPartyLeader(uint partyId) {
        require(msg.sender == idToParty[partyId].leaderAddress, "Only the party leader can do this!");
        _;
    }

    modifier onlyTokenOwner(uint16 sentryId) {
        require(factory.getSentryOwner(sentryId) == msg.sender);
        _;
    }
    // What needs to be done
///*PUBLIC_FUNCTIONS*

    function createParty(uint16[] memory idArray, uint8[] memory riskArray, bool deploy) external {
        require(factory.getOwnerSentryCount(msg.sender) > 0, "You do not own any Sentries!");
        for(uint i = 0; i < idArray.length; i++) {
            require(!factory.getSentryTraits(idArray[i]).infected, "You cannot add an infected Sentry!");
            GameplayStats memory stats = deadzone.getStatsFromId(idArray[i]);
            require(!stats.isDeployed, "This Sentry is already deployed!");
            require(sentryIdToParty[idArray[i]] == 0, "This Sentry is already in a party!");
            if(deadzone.getStatsFromId(idArray[i]).riskCode != riskArray[i]) {
                deadzone.editRiskCode(idArray[i], riskArray[i]);
            }
        }
        DeploymentParty memory party = DeploymentParty(allTimePartyCount, idArray, msg.sender, false);

        emit PartyCreated(allTimePartyCount, msg.sender, block.timestamp);
        allTimePartyCount++;

        // Option deploy would occur down here
    }

    function sendPartyInvitation(uint16 sentryId, uint partyId) external onlyPartyLeader(partyId) {
        require(!sentryIdToPartyInvites[sentryId][partyId], "You have already invited this Sentry!");
        sentryIdToPartyInvites[sentryId][partyId] = true;
        emit PartyMemberUpdate(sentryId, partyId, block.timestamp);
    }

    function joinParty(uint16 sentryId, uint partyId) public onlyTokenOwner(sentryId) {
        require(!factory.getSentryTraits(sentryId).infected, "Infected Sentries cannot join parties.");
        require(!deadzone.getStatsFromId(sentryId).isDeployed, "Your Sentry is current deployed! It cannot join a party until is returns!");
        require(sentryIdToPartyInvites[sentryId][partyId], "This Sentry does not have an invitation to this party!");
        sentryIdToParty[sentryId] = partyId;
        emit PartyMemberUpdate(sentryId, partyId, block.timestamp); 
    }

    function leaveParty(uint16 sentryId) public onlyTokenOwner(sentryId) {
        sentryIdToParty[sentryId] = 0;
        emit PartyMemberUpdate(sentryId, 0, block.timestamp); 
    }


    // Create party function -> with option immediate deploy 
    // Response to party invitation
        //Accept or decline functionality 
        //Join or leave functionality which accesses gameplay stats interface
    
///*INTERFACE*
    function getSentryPartyId(uint16 sentryId) external onlyControllers returns(uint) {
        return sentryIdToParty[sentryId];
    }
    // used for transfering party leader token
    function checkAndTransferPartyOwnership(uint16 sentryId, address checkAddress, address newAddress) external onlyControllers {
        if(sentryIdToParty[sentryId] != 0) {
            if(idToParty[sentryIdToParty[sentryId]].leaderAddress == checkAddress) {
                idToParty[sentryIdToParty[sentryId]].leaderAddress = newAddress;
            }
        }
    }


    function leavePartyAfterAttack(uint16 sentryId) external onlyControllers {
        if(sentryIdToParty[sentryId] != 0) {
            DeploymentParty memory party = parties[getpartyIndex(sentryIdToParty[sentryId])];
            for(uint i = 0; i < party.listOfIds.length; i++) {
                if(party.listOfIds[i] == sentryId) {
                    party.listOfIds[i] = 0;
                }
            }
            sentryIdToParty[sentryId] = 0;
            emit PartyMemberUpdate(sentryId, 0, block.timestamp); 
        }
    }

    function getListOfDeployedParties() external view returns(DeploymentParty[] memory) {
        DeploymentParty[] memory list;
        for(uint i = 0; i < parties.length; i++) {
            if(parties[i].isDeployed) {
                list[i] = parties[i];
            }
        }
        return list;
    }
    function deployParty(uint partyId) external {
        idToParty[partyId].isDeployed = true;
        parties[getpartyIndex(partyId)].isDeployed=true;
        emit PartyDeployUpdate(partyId, block.timestamp);
    }
    function evacuateParty(uint partyId) external onlyPartyLeader(partyId) {
        idToParty[partyId].isDeployed = false;
        parties[getpartyIndex(partyId)].isDeployed=false;
        for(uint i = 0; i < idToParty[partyId].listOfIds.length; i++) {
            deadzone.evac(idToParty[partyId].listOfIds[i]);
        }
    }
    function randomPartyMemberFromId(uint16 sentryId) external onlyControllers returns (uint16){
        uint partyId = sentryIdToParty[sentryId];
        return idToParty[partyId].listOfIds[rng(idToParty[partyId].listOfIds.length)];
    }

///*HELPERS*
    function getpartyIndex(uint partyId) private view returns(uint) {
        for(uint i = 0; i< parties.length; i++) {
            if(parties[i].id == partyId) {
                return i;
            }
        }
    }
    function rng(uint max) private returns (uint) {
        // Eventual replacement will be chainlink vrf
           randNonce++; 
            return uint(keccak256(abi.encodePacked(block.timestamp,
                                          msg.sender,
                                          randNonce))) %
                                          max;
    }

///*OWNER*
    function addController(address _address) public onlyOwner {
        controllers[_address] = true;
    }
    function removeController(address _address) public onlyOwner {
        controllers[_address] = false;
    }

    function setDeadzoneRef(address _address) public onlyOwner{
        deadzone = IDeadzone(_address);
    }
    function setFactoryRef(address _address) public onlyOwner {
        factory = ISentryFactory(_address);
    }
    function setMaxPartyCount(uint8 newCount) public onlyOwner {
        maxPartyCount = newCount;
    }
    function setRandNonce(uint nonce) public onlyOwner {
        randNonce = nonce;
    }
}