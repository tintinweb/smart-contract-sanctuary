pragma solidity 0.4.24;

contract StackVotes {
    // Read/write candidate
    address public admin;

   

    mapping (address => uint8) public itemVotes;    
    //item to user
    mapping (address => address) public itemUser;    
    

    event CreateItem(address indexed _item, address indexed _user);
    event VoteItem(address _item, uint8 _vote);

    // Constructor
    constructor () public {
        admin = msg.sender;
    }

    function createItems(address _item) public{        
        require(
            itemUser[_item] == 0x0,
            "This questions have been added."
        );
        itemUser[_item] = msg.sender;
        emit CreateItem(_item, msg.sender);
    }

    function votesItem(address _item, uint8 _vote) public{        
        itemVotes[_item]  = itemVotes[_item] + _vote;
        emit VoteItem(_item, _vote);
    }

    function  transferAdmin(address _adminAddr) public {
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        admin = _adminAddr;
    }

}