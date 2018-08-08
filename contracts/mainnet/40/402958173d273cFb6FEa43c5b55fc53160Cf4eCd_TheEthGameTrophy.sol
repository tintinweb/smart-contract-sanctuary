contract TheEthGameTrophy {
    string public name; 
    string public description;
    string public message;
    
    address public creator;
    address public owner;
    address public winner;
    uint public rank;
    
    bool private isAwarded = false;
    
    event Award(uint256 indexed _blockNumber, uint256 indexed _timestamp, address indexed _owner);
    event Transfer (address indexed _from, address indexed _to);

    constructor () public {
        name = "The Eth Game Winner";
        description = "2019-08-17";
        rank = 1;
        creator = msg.sender;
    }
    
    function name() constant public returns (string _name) {
        return name;
    }
    
    function description() constant public returns (string _description) {
        return description;
    }
    
    function message() constant public returns (string _message) {
        return message;
    }
    
    function creator() constant public returns (address _creator) {
        return creator;
    }
    
    function owner() constant public returns (address _owner) {
        return owner;
    }
    
    function winner() constant public returns (address _winner) {
        return winner;
    }
    
    function rank() constant public returns (uint _rank) {
        return rank;
    }
  
    function award(address _address, string _message) public {
        require(msg.sender == creator && !isAwarded);
        isAwarded = true;
        owner = _address;
        winner = _address;
        message = _message;
        
        emit Award(block.number, block.timestamp, _address);
    }
    
    function transfer(address _to) private returns (bool success) {
        require(msg.sender == owner);
        owner = _to;
        emit Transfer(msg.sender, _to);
        return true;
    }
}