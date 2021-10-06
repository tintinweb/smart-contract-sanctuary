pragma solidity ^0.8.4;

contract IdentityManager {
    
    event CreateIdentity(address indexed addr, string indexed username, string name, string twitter);
    event UpdateIdentity(address indexed addr, string indexed username, string name, string twitter);
    event DeleteIdentity(address indexed addr, string indexed username);
    
    struct User {
        string username;
        string name;
        string twitter;
    }
    
    mapping(address => User) private users;
    mapping(string => address) internal usernames;
    
    function createIdentity(string calldata username, string calldata name, string calldata twitter) public {
        User storage user = users[msg.sender];
        require(bytes(user.username).length == 0, "Existing identity");
        require(usernames[username] == address(0), "Duplicate username");
        
        user.username = username;
        user.name = name;
        user.twitter = twitter;
        usernames[username] = msg.sender;
        
        emit CreateIdentity(msg.sender, username, name, twitter);
    }
    
    function updateIdentity(string calldata username, string calldata name, string calldata twitter) public {
        User storage user = users[msg.sender];
        string memory oldUsername = user.username;
        string memory oldName = user.name;
        string memory oldTwitter = user.twitter;

        if(keccak256(abi.encode(oldUsername)) != keccak256(abi.encode(username))) {
            require(usernames[username] == address(0), "Duplicate username");
            delete usernames[oldUsername];
            user.username = username;
            usernames[username] = msg.sender;
        }
        if(keccak256(abi.encode(oldName)) != keccak256(abi.encode(name))) {
            user.name = name;
        }
        if(keccak256(abi.encode(oldTwitter)) != keccak256(abi.encode(twitter))) {
            user.twitter = twitter;
        }
        emit UpdateIdentity(msg.sender, username, name, twitter);
    }
    
    function deleteIdentity() public {
        User storage user = users[msg.sender];
        string memory uname = user.username;
        require(bytes(uname).length != 0, "Identity is not exist");
        
        delete users[msg.sender];
        delete usernames[uname];
        
        emit DeleteIdentity(msg.sender, uname);
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}