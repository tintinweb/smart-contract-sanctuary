pragma solidity ^0.4.0;


contract DonateContract {

    struct Donation {
        uint value;
        string donor;
    }
    mapping (address => Donation[]) history;
    event NewDonation(uint value, string donor, string message, address raddr);

    function donate(address _receiver, string _name, string _message) public payable {
        require(msg.value >= 0);
        history[msg.sender].push(Donation(msg.value, _name));
        NewDonation(msg.value, _name, _message, _receiver);
        _receiver.transfer(msg.value);
    }

    function getDonation(address _addr, uint _id) public view returns(uint value, string name) {
        require(_id >= 0 && _id < history[_addr].length);
        return(history[_addr][_id].value, history[_addr][_id].donor);
    }

    function getDonationsCount(address _addr) public view returns(uint length) {
        return(history[_addr].length);
    }
}