pragma solidity ^0.4.13;

contract Storychain {
    
    // Price to add a sentence
    uint constant APPEND_PRICE = 10 finney;

    // Maximum allowed sentence length
    uint8 constant MAX_SENTENCE_LENGTH = 255;

    // Structure to store a sentence of the story
    struct Node {
        address author;
        string text;
        uint parent;
    }
    
    event Write(uint index, address indexed author, uint indexed parent, string text);

    // The nodes that make up the story tree
    Node[] public nodes;
    
    // ETH balances
    mapping (address => uint) public balances;
    
    modifier costs(uint _amount) {
        if (balances[msg.sender] >= _amount) {
            balances[msg.sender] -= _amount;
            _amount = 0;
        } else require(msg.value >= _amount);
        _;
        if (msg.value > _amount) {
            msg.sender.transfer(msg.value - _amount);
        }
    }
    
    // String length function, from https://ethereum.stackexchange.com/a/13886
    function stringLength(string str) pure internal returns (uint length)
    {
        uint i=0;
        bytes memory string_rep = bytes(str);

        while (i<string_rep.length)
        {
            if (string_rep[i]>>7==0)
                i+=1;
            else if (string_rep[i]>>5==0x6)
                i+=2;
            else if (string_rep[i]>>4==0xE)
                i+=3;
            else if (string_rep[i]>>3==0x1E)
                i+=4;
            else
                //For safety
                i+=1;

            length++;
        }
    }

    // Constructor
    function Storychain() public {
        // Genesis block
        string memory text = &quot;[Genesis Block]&quot;;
        nodes.push(Node(msg.sender, text, 0));
        Write(0, msg.sender, 0, text);
    }
    
    // Add a node
    function write(string text, uint parent) public payable costs(APPEND_PRICE) {
        require(stringLength(text) <= MAX_SENTENCE_LENGTH);
        uint index = nodes.length;
        require(parent < index);
        nodes.push(Node(msg.sender, text, parent));
        balances[nodes[parent].author] += APPEND_PRICE;
        Write(index, msg.sender, parent, text);
    }
    
    function withdraw() public {
        uint amount = balances[msg.sender];
        require(amount > 0);
        balances[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    
    // Read a sentence, by index
    function read(uint index) public constant returns (address, string, uint) {
        Node storage node = nodes[index];
        return (node.author, node.text, node.parent);
    }
    
    function getBalance(address author) public constant returns (uint) {
        return balances[author];
    }
     
}