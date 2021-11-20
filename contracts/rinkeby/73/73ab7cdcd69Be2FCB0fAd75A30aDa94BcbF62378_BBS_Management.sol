pragma solidity ^0.8.0;

contract BBS_Management {
    address payable[] public participants;
    address payable public supreme_manager;
    uint256 public participants_amount;
    mapping(address => bool) public participant_allowance;
    mapping(address => bool) public is_manager;
    mapping(address => bool) public participant_registred;

    struct Participant {
        address payable participant_address;
        bool allowed;
    }

    constructor() public {
        supreme_manager = payable(msg.sender);
        is_manager[payable(msg.sender)] = true;
        participants.push(payable(msg.sender));
        participant_allowance[msg.sender] = true;
        participant_registred[msg.sender] = true;
        participants_amount = 1;
    }

    modifier onlyManager() {
        require(
            is_manager[tx.origin],
            "Only the manager can call this function."
        );
        _;
    }

    modifier onlySupreme() {
        require(
            tx.origin == supreme_manager,
            "Only the supreme manager can call this function."
        );
        _;
    }

    function add_manager(address payable _manager_address) public onlySupreme {
        participants.push(_manager_address);
        participant_allowance[_manager_address] = true;
        participant_registred[_manager_address] = true;
        participants_amount = 1;
        is_manager[_manager_address] = true;
    }

    function remove_manager(address payable _manager_address)
        public
        onlySupreme
    {
        require(is_manager[_manager_address] == true, "This is not an owner");
        require(
            _manager_address != supreme_manager,
            "Supreme manager cannot be removed"
        );
        is_manager[_manager_address] = false;
    }

    function newParticipant(address payable _participant) public onlyManager {
        if (participant_registred[_participant] == false) {
            participant_registred[_participant] = true;
            participant_allowance[_participant] = true;
            participants.push(_participant);
            participants_amount += 1;
        }
    }

    function allowParticipant(address payable _participant) public onlyManager {
        require(
            participant_registred[_participant] == true,
            "This participant is not registrated"
        );
        participant_allowance[_participant] = true;
    }

    function unAllowParticipant(address payable _participant)
        public
        onlyManager
    {
        require(
            participant_registred[_participant] == true,
            "This participant is not registrated"
        );
        participant_allowance[_participant] = false;
    }

    function getParticipants() public view returns (Participant[] memory) {
        Participant[] memory _participants = new Participant[](
            participants.length
        );
        for (uint256 i = 0; i < participants.length; i++) {
            _participants[i].participant_address = participants[i];
            _participants[i].allowed = participant_allowance[participants[i]];
        }
        return _participants;
    }
}