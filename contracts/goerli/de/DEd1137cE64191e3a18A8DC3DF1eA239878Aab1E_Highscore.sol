// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

contract Highscore {
    // struct Entry - score, URL, text
    struct Entry {
        uint score;
        string title;
        string url;
        address author;
    }

    // array of structs sorted by date added, not by score (this is done on front-end)
    Entry[] public entries;
    
    // owner address (set in constructor)
    address payable public owner;

    // min required score (to avoid dust and spamming)
    uint public minScore = 1 * 10**16; // 0.01 

    // modifiers
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    // events
    event Create(address author, string title, uint value);

    // constructor
    constructor(address _owner) {
        owner = payable(_owner);

        entries.push(Entry({
            score: 1 * 10**16,
            title: "Tesla - Electric Cars, Solar & Clean Energy",
            url: "https://www.tesla.com/",
            author: msg.sender
        }));

        entries.push(Entry({
            score: 33 * 10**15,
            title: "Wikipedia, Free Online Encyclopedia",
            url: "https://www.wikipedia.org/",
            author: _owner
        }));

        entries.push(Entry({
            score: 2020 * 10**13,
            title: "Mr. F was here",
            url: "(no url)",
            author: _owner
        }));
    }

    // add a new entry
    function addNewEntry(string memory _title, string memory _url) public payable {
        require(msg.value > minScore, "Payment must be bigger than the minimum required amount.");

        entries.push(Entry({
            score: msg.value,
            title: _title,
            url: _url,
            author: msg.sender
        }));

        emit Create(msg.sender, _title, msg.value);

        owner.transfer(msg.value);
    }

    // get array length
    function getEntriesArrayLength() public view returns (uint) {
        return entries.length;
    }

    // get array item by index
    function getEntryByIndex(uint _index) public view returns (uint, string memory, string memory, address) {
        return (entries[_index].score, entries[_index].title, entries[_index].url, entries[_index].author);
    }

    // change owner address (onlyOwner)
    function setNewOwner(address newOwner) public onlyOwner {
        owner = payable(newOwner);
    }

    // owner collect funds (onlyOwner)
    function collectFunds() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    // delete an entry (onlyOwner)
    function deleteEntry(uint _index) public onlyOwner {
        entries[_index] = entries[entries.length-1];
        entries.pop();
    }

    // set min score (onlyOwner)
    function setMinScore(uint _minScore) public onlyOwner {
        minScore = _minScore;
    }
    
}

