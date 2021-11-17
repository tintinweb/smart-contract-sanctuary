pragma solidity ^0.8.0;

contract BBS_Management {
    address payable public manager_address;
    address payable[] public participants;
    uint256 public participants_amount;
    mapping(address => bool) public participant_allowance;
    mapping(address => bool) public participant_registred;

    struct Participant {
        address payable participant_address;
        bool allowed;
    }

    constructor() public {
        manager_address = payable(msg.sender);
        participants.push(manager_address);
        participant_allowance[manager_address] = true;
        participant_registred[manager_address] = true;
        participants_amount = 1;
    }

    modifier onlyManager() {
        require(
            msg.sender == manager_address,
            "Only the manager can call this function."
        );
        _;
    }

    function set_manager_address(address payable _manager_address)
        public
        onlyManager
    {
        manager_address = _manager_address;
    }

    function newParticipant(address payable _participant) public onlyManager {
        require(
            participant_registred[_participant] == false,
            "This participant is already registrated"
        );
        participant_registred[_participant] = true;
        participant_allowance[_participant] = true;
        participants.push(_participant);
        participants_amount += 1;
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