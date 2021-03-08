/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity >=0.4.22 <0.7.0;

/**
 * @title Pumps
 * Website: https://pumps.wtf
 * Description: Decentralized Twitter on Fantom
 */
 
contract Pumps {
    
    struct User {
        address user;
        string username;
        string metadataHash;
        uint createdAt;
    }
    mapping(address => User) public users;
    mapping (string => bool) public usernameExists;
    
    struct Pump {
        address author;
        string content;
        uint256 createdAt;
    }
    Pump[] public pumps;
    
    struct Reaction {
        uint pumpId;
        uint reactionType;
        address user;
        uint256 createdAt;
    }
    Reaction[] public reactions;
    
    struct Reply {
        uint pumpId;
        string content;
        address user;
        uint256 createdAt;
    }
    Reply[] public replies;

    /** @dev Constants */
    uint public pumpsCharacterLimit = 280;

    /** Setters */ 
    function newUser(string memory _username) public {
        // To-do: Mint NFT for username
        require(usernameExists[_username] != true, "Username exists.");
        User memory user = User(msg.sender, _username, "", now);
        users[msg.sender] = user;
        
        // Create event
        emit NewUser(msg.sender, _username, now); 
    }
    
    function newPump(string memory content) public {
        uint id = pumps.length;
        require(bytes(content).length <= pumpsCharacterLimit, "Content exceeds characters limit.");
        pumps.push(Pump(msg.sender, content, now));
        
        // Create event
        emit NewPump(id, msg.sender, content, now); 
    }
    
    function newReaction(uint pumpId, uint reactionType) public {
        // To-do: Make sure users can vote only once
        reactions.push(Reaction(pumpId, reactionType, msg.sender, now));
        
         // Create event
        emit NewReaction(pumpId, reactionType, msg.sender, now);
    }
    
    function newReply(uint pumpId, string memory content) public {
        uint id = replies.length;
        require(bytes(content).length <= pumpsCharacterLimit, "Content exceeds characters limit.");
        replies.push(Reply(pumpId, content, msg.sender, now));
        
         // Create event
        emit NewReply(id, pumpId, content, msg.sender, now);
    }
    
    function updateUserMetadata(string memory _hash) public {
        User storage user = users[msg.sender];
        user.metadataHash = _hash;
    }
    
    /** Handle events */
    event NewUser(address userAddress, string username, uint createdAt);
    event NewPump(uint id, address author, string content, uint createdAt);
    event NewReaction(uint pumpId, uint reactionType, address sender, uint createdAt);
    event NewReply(uint id, uint pumpId, string content, address sender, uint createdAt);
    
    /** Getters */ 
    function getPump(uint _id) external view returns(
       address author,
       string memory content,
       uint256 createdAt
    ) {
       Pump storage _pump = pumps[_id];
        author = _pump.author;
        content = _pump.content;
        createdAt = _pump.createdAt;
    }
}