pragma solidity ^0.4.21;

contract DonationGuestbook {
    struct Entry{
        // structure for an guestbook entry
        address owner;
        string alias;
        uint timestamp;
        uint blocknumber;
        uint donation;
        string message;
    }

    address public owner; // Guestbook creator
    address public donationWallet; // wallet to store donations
    
    uint public running_id = 0; // number of guestbook entries
    mapping(uint=>Entry) public entries; // guestbook entries
    uint public minimum_donation = 0; // to prevent spam in the guestbook

    function DonationGuestbook() public { 
    // called at creation of contract
        owner = msg.sender;
        donationWallet = msg.sender;
    }
    
    function() payable public {
    // fallback function. In case somebody sends ether directly to the contract.
        donationWallet.transfer(msg.value);
    } 

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeDonationWallet(address _new_storage) public onlyOwner {
    // in case the donation wallet address ever changes
        donationWallet = _new_storage; 
    }

    function changeOwner(address _new_owner) public onlyOwner {
    // in case the owner ever changes
        owner = _new_owner;
    }

    function changeMinimumDonation(uint _minDonation) public onlyOwner {
    // in case people spam into the guestbook
        minimum_donation = _minDonation;
    }

    function destroy() onlyOwner public {
    // kills the contract and sends all funds (which should be impossible to have) to the owner
        selfdestruct(owner);
    }

    function createEntry(string _alias, string _message) payable public {
    // called by a donator to make a donation + guestbook entry
        require(msg.value > minimum_donation); // entries only for those that donate something
        entries[running_id] = Entry(msg.sender, _alias, block.timestamp, block.number, msg.value, _message);
        running_id++;
        donationWallet.transfer(msg.value);
    }

    function getEntry(uint entry_id) public constant returns (address, string, uint, uint, uint, string) {
    // for reading the entries of the guestbook
        return (entries[entry_id].owner, entries[entry_id].alias, entries[entry_id].blocknumber,  entries[entry_id].timestamp,
                entries[entry_id].donation, entries[entry_id].message);
    }
}