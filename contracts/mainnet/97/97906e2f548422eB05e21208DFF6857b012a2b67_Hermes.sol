contract Hermes {
    
    string public constant name = "↓ See Code Of The Contract ↓";
    
    string public constant symbol = "Code ✓✓✓";
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    address owner;
    
    uint public index;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function() public payable {}
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    
    function resetIndex(uint _n) public onlyOwner {
        index = _n;
    }
    
    function massSending(address[]  _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            _addresses[i].send(777);
            emit Transfer(0x0, _addresses[i], 777);
        }
    }
    
    function withdrawBalance() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}