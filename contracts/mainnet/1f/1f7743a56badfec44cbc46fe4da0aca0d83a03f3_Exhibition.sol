pragma solidity ^0.4.17;

contract Exhibition {
    address private organizer;
    address private winnerAddress;
    bool private isWinnerSelected = false;
    struct Participant {
        string name;
        string phone;
        string email;
    }
    function Exhibition() public {
        organizer = msg.sender;
    }
    mapping(address => Participant) private participants;
    address[] private participantList;
    function registration(string _name, string _phone, string _email) public payable {
        require(msg.value > .00001 ether);
        require(!isWinnerSelected);
        Participant storage participant = participants[msg.sender];
        participant.name = _name;
        participant.phone = _phone;
        participant.email = _email;
        participantList.push(msg.sender);
        sendAmount(msg.value, organizer);
    }
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