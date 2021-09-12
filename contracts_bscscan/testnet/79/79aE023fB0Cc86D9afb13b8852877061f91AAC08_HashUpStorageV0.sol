/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

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

    mapping(address => Creator) public creators;

    //1. Right after GameContract Creation
    mapping(address => GameContract[]) public userContracts;

    //2. After user submission
    mapping(address => GameContract[]) public requestedContracts;
    mapping(address => address) public GameContractToCreatorAddress;

    //3. After our approval
    GameContract[] approvedContracts;

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

    function requestContract(address requestedContract_) public returns (address) {
        requestedContracts[msg.sender].push(
            GameContract(
                requestedContract_,
                creators[msg.sender]
            ));
        GameContractToCreatorAddress[requestedContract_] = msg.sender;
        return requestedContract_;
    }

    function getUserRequestedGameContracts(address user) public view returns (GameContract[] memory) {
        return requestedContracts[user];
    }

    function approveGameContract(address GameContractAddress) public isAdminOrModerator returns (address) {
        approvedContracts.push(
            GameContract(
                GameContractAddress,
                creators[GameContractToCreatorAddress[GameContractAddress]]
            ));
        return GameContractAddress;
    }

    function getApprovedGameContracts() public view returns (GameContract[] memory) {
        return approvedContracts;
    }
    
    event Push(
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