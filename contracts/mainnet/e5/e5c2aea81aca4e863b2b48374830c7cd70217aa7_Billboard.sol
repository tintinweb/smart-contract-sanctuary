pragma solidity ^0.4.18;

/*
 * v1.0
 * Created by MyEtheroll.com, feb 2018
 * Feel free to copy and share :)
 * Donations: 0x7e3dc9f40e7ff9db80c3c7a1847cb95f861b3aef
*/

contract Billboard {

    uint public cost = 100000000000000; // 0.0001 eth
    uint16 public messageSpanStep = 1 minutes;
    address owner;

    bytes32 public head;
    uint public length = 0;
    mapping (bytes32 => Message) public messages;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event MessageAdded(address indexed sender, uint validFrom, uint validTo, string message);
    event MessageSpanStepChanged(uint16 newStep);
    event CostChanged(uint newCost);

    struct Message {
    uint validFrom;
    uint validTo;
    address sender;
    string message;
    bytes32 next;
    }

    /*
    * Init.
    */
    function Billboard() public {
        _saveMessage(now, now, msg.sender, "Welcome to MyEtheroll.com!");
        owner = msg.sender;
    }

    /*
    * Adds message to the billboard.
    * If a message already exists that has not expired, the new message will be queued.
    */
    function addMessage(string _message) public payable {
        require(msg.value >= cost || msg.sender == owner); // make sure enough eth is sent
        uint validFrom = messages[head].validTo > now ? messages[head].validTo : now;
        _saveMessage(validFrom, validFrom + calculateDuration(msg.value), msg.sender, _message);
        if(msg.value>0)owner.transfer(msg.value);
    }


    /*
    * Returns the current active message.
    */
    function getActiveMessage() public view returns (uint, uint, address, string, bytes32) {
        bytes32 idx = _getActiveMessageId();
        return (messages[idx].validFrom, messages[idx].validTo, messages[idx].sender, messages[idx].message, messages[idx].next);
    }

    /*
    * Returns the timestamp of next queue opening.
    */
    function getQueueOpening() public view returns (uint) {
        return messages[head].validTo;
    }

    /*
    * Returns guaranteed duration of message based on amount of wei sent with message.
    * For each multiple of the current cost, the duration guarantee is extended by the messageSpan.
    */
    function calculateDuration(uint _wei) public view returns (uint)  {
        return (_wei / cost * messageSpanStep);
    }

    /*
    * Owner can change the message span step, in seconds.
    */
    function setMessageSpan(uint16 _newMessageSpanStep) public onlyOwner {
        messageSpanStep = _newMessageSpanStep;
        MessageSpanStepChanged(_newMessageSpanStep);
    }

    /*
    * Owner can change the cost, in wei.
    */
    function setCost(uint _newCost) public onlyOwner {
        cost = _newCost;
        CostChanged(_newCost);
    }

    /*
    * Save message to the blockchain and add event.
    */
    function _saveMessage (uint _validFrom, uint _validTo, address _sender, string _message) private {
        bytes32 id = _createId(Message(_validFrom, _validTo, _sender, _message, head));
        messages[id] = Message(_validFrom, _validTo, _sender, _message, head);
        length = length+1;
        head = id;
        MessageAdded(_sender, _validFrom, _validTo, _message);
    }

    /*
    * Create message id for linked list.
    */
    function _createId(Message _message) private view returns (bytes32) {
        return keccak256(_message.validFrom, _message.validTo, _message.sender, _message.message, length);
    }

    /*
    * Get message id for current active message.
    */
    function _getActiveMessageId() private view returns (bytes32) {
        bytes32 idx = head;
        while(messages[messages[idx].next].validTo > now){
            idx = messages[idx].next;
        }
        return idx;
    }

    /*
    * Kill contract.
    */
    function kill() public onlyOwner {
        selfdestruct(owner);
    }

}