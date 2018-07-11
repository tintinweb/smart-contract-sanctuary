// Specifies the version of solidity that code is written with
pragma solidity ^0.4.24;


contract Exhibition {

    // It maintains organizer address who create the contract.
    address private organizer;

    // It maintains winner address
    address private winnerAddress;

    // It maintains Exhibition status, by default it&#39;s false
    // and it will become true once pick up the winner
    bool private isWinnerSelected = false;

    // A struct is a custom type. It can be defined with a
    // name and associated properties inside of it.
    // Here, we have a struct of Participant, which will store their name, phone and email.
    struct Participant {
        string name;
        string phone;
        string email;
    }

    // A constructor is an optional function with the same name as the contract which is
    // executed upon contract creation
    // It registers the creator as organizer
    constructor() public {
        // Assign organizer address
        organizer = msg.sender;
    }

    // This declares a state variable that
    // stores a &#39;Participant&#39; struct for each possible Ethereum address.
    mapping(address => Participant) private participants;

    // It maintains all the participants address list.
    address[] private participantList;

    // This function is used to create a new registeration.
    // The keyword &quot;public&quot; allows function to accessable from outside.
    // The keyword &quot;payable&quot; is required for the function to
    // be able to receive Ether.
    function registration(string _name, string _phone, string _email) public payable {
        // require function used to ensure condition are met.

        // check ether value should be greater than &#39;.00001&#39;
        require(msg.value > .00001 ether);
        // check isWinnerSelected should be &#39;false&#39;
        require(!isWinnerSelected);

        // assigns reference
        Participant storage participant = participants[msg.sender];

        participant.name = _name;
        participant.phone = _phone;
        participant.email = _email;

        // Add address to participant list
        participantList.push(msg.sender);

        // send ether to organizer account
        sendAmount(msg.value, organizer);
    }

    // This function is used to pick the winner.
    function pickWinner() public {
        // Check the sender address should be equal to organizer since the organizer can only pick the winner
        require(msg.sender == organizer);

        // Randamloy select one participant among all the participants.
        uint index = random() % participantList.length;

        // Assign winner participant address
        winnerAddress = participantList[index];

        // Change isWinnerSelected to &#39;true&#39;
        isWinnerSelected = true;
    }

    // This function is used to send ether to winner address
    function transferAmount() public payable {
        // check ether value should be greater than &#39;.0001&#39;
        require(msg.value > .0001 ether);
        // Check the sender address should be equal to organizer address
        // since the organizer can only send ether to winner
        require(msg.sender == organizer);
        // check isWinnerSelected should be &#39;true&#39;
        require(isWinnerSelected);
        // send ether to winner
        sendAmount(msg.value, winnerAddress);
    }

    // This function is used to return isWinnerSelected
    function getIsWinnerSelected() public view returns (bool) {
        return isWinnerSelected;
    }

    // This function is used to return participantList
    function getParticipants() public view returns (address[]) {
        return participantList;
    }

    // This function is used to return winner name
    function getWinner() public view returns (string) {
        // check isWinnerSelected should be &#39;true&#39;
        require(isWinnerSelected);
        return participants[winnerAddress].name;
    }

    // This function is used to return organizer
    function getOrganizer() public view returns (address) {
        return organizer;
    }

    // This function is used to transfer ether to particular address
    function sendAmount(uint _amount, address _account) private {
        _account.transfer(_amount);
    }

    // This function is used to return one number randomly from participantList
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, participantList));
    }

}