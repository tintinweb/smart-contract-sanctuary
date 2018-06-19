pragma solidity ^0.4.0;

contract Bounty {
    struct Talk {
        uint balance;
        mapping(address => uint) witnessedPresenter;
        mapping(address => bool) witnessedBy;
    }
    
    event TalkBounty (bytes32 title);
    
    mapping(bytes32 => Talk) public talks;
    
    modifier onlywitness {
        require(msg.sender == 0x07114957EdBcCc1DA265ea2Aa420a1a22e6afF58
        || msg.sender == 0x75427E62EB560447165a54eEf9B6367d87F98418);
        _;
    }
    
    function add(bytes32 title) payable {
        talks[title].balance += msg.value;
        TalkBounty(title);
    }
    
    function witness(bytes32 title, address presenter) onlywitness returns (uint) {
        if (talks[title].witnessedBy[msg.sender]) {
            revert();
        }
        talks[title].witnessedBy[msg.sender] = true;
        talks[title].witnessedPresenter[presenter] += 1;
        return talks[title].witnessedPresenter[presenter];
    }
    
    function claim(bytes32 title) {
        if (talks[title].witnessedPresenter[msg.sender] < 2) {
            revert();
        }
        uint amount = talks[title].balance;
        talks[title].balance = 0;
        msg.sender.transfer(amount);
    }
}