/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract HashUpStorageV0 {

    struct Creator {
        string name;
        string company;
        string logoUrl;
        string description;
        address CreatorAddress;
    }

    struct GameContract {
        address GameContractAddress;
        Creator creator;
    }
    
    address Hash = 0xecE74A8ca5c1eA2037a36EA54B69A256803FD6ea;

    mapping(address => Creator) public creators;

    /**
     *  1. Right after GameContract Creation - user's private store.
     */ 
    mapping(address => GameContract[]) public userContracts;

    /**
     *  2. After user submission.
     */
    GameContract[] public waitingForApprovalContracts;
    mapping(address => GameContract[]) public requestedContracts;
    
    mapping(address => address) public GameContractToCreatorAddress;

    /**
     *  3. After approval.
     */
    GameContract[] approvedContracts;
    mapping(address => GameContract[]) public userApprovedContracts;


    address admin;
    address moderator;

    modifier isAdmin() {
        require(msg.sender == admin, "Caller is not owner");
        _;
    }

    modifier isAdminOrModerator() {
        require(msg.sender == admin || msg.sender == moderator);
        _;
    }
    
    modifier isExperienced() {
        require(
            IERC20(Hash).balanceOf(msg.sender) >= 1_000_000_000_000_000_000_000_000,
            "Not experienced"
        );
        _;
    }
    
    modifier isPublisherOrExperienced() {
        require(
            msg.sender == admin ||
            IERC20(Hash).balanceOf(msg.sender) >= 1_000_000_000_000_000_000_000_000,
            "Not a publisher nor experienced"
        );
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setCreator(
        string memory name_,
        string memory company_,
        string memory logoUrl_,
        string memory description_
    ) public returns (Creator memory) {
        creators[msg.sender] = Creator(
            name_,
            company_,
            logoUrl_,
            description_,
            msg.sender
        );
        return creators[msg.sender];
    }

    function getCreator(address user) public view returns (Creator memory) {
        return creators[user];
    }

    function setNewAdmin(address newAdmin) public isAdmin returns (address) {
        admin = newAdmin;
        return newAdmin;
    }

    function getAdmin() public view returns (address) {
        return admin;
    }

    function setModerator(address moderator_) public isAdmin returns (address) {
        moderator = moderator_;
        return moderator_;
    }

    function getModerator() public view returns (address) {
        return moderator;
    }

    function pushUserGameContract(address userContract_) public returns (address) {
        userContracts[msg.sender].push(
            GameContract(
                userContract_,
                creators[msg.sender]
            ));

        emit Push(userContract_);
        
        return userContract_;
    }

    function getUserGameContracts(address user) public view returns (GameContract[] memory) {
        return userContracts[user];
    }

    /**
     * Moves user's private store -> requested.
     */
    function requestContract(address requestedContract_, uint256 requestedContractIndex_) public returns (address) {
        GameContract memory requestedGameContract = GameContract(
            requestedContract_,
            creators[msg.sender]
        );
        
        requestedContracts[msg.sender].push(
            requestedGameContract
        );
        waitingForApprovalContracts.push(
            requestedGameContract
        );
        
        GameContractToCreatorAddress[requestedContract_] = msg.sender;

        // Previous store cleanup
        userContracts[msg.sender][requestedContractIndex_] = 
            userContracts[msg.sender][userContracts[msg.sender].length - 1];
        userContracts[msg.sender].pop();
        
        return requestedContract_;
    }

    function getUserRequestedGameContracts(address user) public view returns (GameContract[] memory) {
        return requestedContracts[user];
    }
    
    /**
     * Moves requested -> user's private store.
     * 
     * Called from the 'global' game requests view as the entry disappears from users private list, 
     * therefore the private list index does not matter here, only the global view one.
     */ 
    function withdrawContractRequest(address requestedContract_, uint256 requestedContractIndex_) 
        public
        isPublisherOrExperienced
    {
        this.pushUserGameContract(
            requestedContract_
        );
        
        // TODO: particluar users store has to be cleared based on an address -> index mapping; 
        //      i.e. calculated based on the passed contract address only, and the local address -> index mapping store.
        // requestedContracts[msg.sender][requestedContractIndex_] = 
        //     requestedContracts[msg.sender][requestedContracts[msg.sender].length - 1];
        // requestedContracts[msg.sender].pop();
        
        // global store reduce, based on the request-passed index
        waitingForApprovalContracts[requestedContractIndex_] = 
            waitingForApprovalContracts[waitingForApprovalContracts.length - 1];
        waitingForApprovalContracts.pop();
    }

    /**
     * Moves requested -> approved.
     */
    function approveGameContract(address GameContractAddress, uint256 approvedGameContractIndex) 
        public
        isExperienced
        returns (address) 
    {
        GameContract memory approvedGameContract = GameContract(
            GameContractAddress,
            creators[GameContractToCreatorAddress[GameContractAddress]]
        );
        
        approvedContracts.push(
            approvedGameContract
        );
        userApprovedContracts[msg.sender].push(
            approvedGameContract
        );
            
        // TODO: particluar users store has to be cleared based on an address -> index mapping; 
        //      i.e. calculated based on the passed contract address only, and the local address -> index mapping store.
        // requestedContracts[msg.sender][GameContractToRequestedContractsIndices[GameContractAddress]] = 
        //     requestedContracts[msg.sender][requestedContracts[msg.sender].length - 1];
        // requestedContracts[msg.sender].pop();
        
        // global store reduce, based on the request-passed index
        waitingForApprovalContracts[approvedGameContractIndex] = 
            waitingForApprovalContracts[waitingForApprovalContracts.length - 1];
        waitingForApprovalContracts.pop();

        emit AddToGameCap(GameContractAddress);
        
        return GameContractAddress;
    }

    function getApprovedGameContracts() public view returns (GameContract[] memory) {
        return approvedContracts;
    }
    
    event Push(
        address indexed userContract
    );
    
    event AddToGameCap(
        address indexed userContract
    );
    
    struct JsonInterface {
        Creator                 creator;

        GameContract[]          userContracts;
    
        GameContract[]          requestedContracts;

        GameContract[]          approvedContracts;
    
        address                 admin;
        address                 moderator;
    }

    /*
     * Dumps all public contract data based on a given user.
     */
    function toJson(address user) public view returns (JsonInterface memory) {
        return JsonInterface(   
            creators[user],
            userContracts[user],
            requestedContracts[user],
            approvedContracts,
            admin,
            moderator
        );
    }
}