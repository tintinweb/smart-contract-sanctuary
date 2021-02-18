/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

pragma solidity ^0.4.16;

contract SCRBAC {
    bool public status;
    address public owner;
    string public organizationName;
    uint public numberOfUsers;
    uint public numberOfEndorsees;
    mapping (address => uint) public userId;
    mapping (address => uint) public endorsedUserId;
    User[] public users;
    Endorse[] public endorsedUsers;

    event UserAdded(address UserAddress, string UserRole, string UserNotes);
    event UserRemoved(address UserAddress);
    event UserEndorsed(address Endorser, address Endorsee);
    event EndorseeRemoved(address UserAddress);
    event StatusChanged(string Status);

    struct User {
        address user;
        string role;
        string notes;
        uint userSince;
    }

    struct Endorse {
        address endorser;
        address endorsee;
        string notes;
        uint endorseeSince;
    }

    modifier onlyUsers {
        require(userId[msg.sender] != 0);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function SCRBAC (string enterOrganizationName) public {
        owner = msg.sender;
        status = true;
        addUser(0, "", "");
        addUser(owner, 'Creator and Owner of Smart Contract', "");
        organizationName = enterOrganizationName;
        numberOfUsers = 0;
        addEndorsee(0, "");
        numberOfEndorsees = 0;
    }

    function changeStatus (bool deactivate) onlyOwner public {
        if (deactivate)
        {status = false;}
        StatusChanged("Smart Contract Deactivated");
    }

    function addUser(address userAddress, string userRole, string userNotes) onlyOwner public {
        require(status = true);
        uint id = userId[userAddress];
        if (id == 0) {
            userId[userAddress] = users.length;
            id = users.length++;
        }
        users[id] = User({user: userAddress, userSince: now, role: userRole, notes: userNotes});
        UserAdded(userAddress, userRole, userNotes);
        numberOfUsers++;
    }

    function removeUser(address userAddress) onlyOwner public {
        require(userId[userAddress] != 0);
        for (uint i = userId[userAddress]; i<users.length-1; i++){
            users[i] = users[i+1];
        }
        delete users[users.length-1];
        users.length--;
        UserRemoved(userAddress);
        numberOfUsers--;
    }

    function addEndorsee(address endorseeAddress, string endorseNotes) onlyUsers public {
        uint eid = endorsedUserId[endorseeAddress];
        if (eid == 0) {
            endorsedUserId[endorseeAddress] = endorsedUsers.length;
            eid = endorsedUsers.length++;
        }
        endorsedUsers[eid] = Endorse({endorser: msg.sender, endorsee: endorseeAddress, notes: endorseNotes, endorseeSince: now});
        UserEndorsed(msg.sender, endorseeAddress);
        numberOfEndorsees++;
    }

    function removeEndorsee(address endorseeAddress) onlyUsers public {
        require(endorsedUserId[endorseeAddress] != 0);
        Endorse storage p = endorsedUsers[endorsedUserId[endorseeAddress]];
        require(p.endorser==msg.sender);  
        for (uint i = endorsedUserId[endorseeAddress]; i<endorsedUsers.length-1; i++){
            endorsedUsers[i] = endorsedUsers[i+1];
        }
        delete endorsedUsers[endorsedUsers.length-1];
        endorsedUsers.length--;
        EndorseeRemoved(endorseeAddress);
        numberOfEndorsees--;
    }
}