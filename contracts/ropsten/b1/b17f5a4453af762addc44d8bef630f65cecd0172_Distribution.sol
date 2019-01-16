contract Distribution {
    
    string public constant name = "↓ See Code ↓";
    
    string public constant symbol = "Code ✓";
    
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
    
    function transferOwnership(address _new) public onlyOwner {
        owner = _new;
    }
    
    function resetIndex(uint _n) public onlyOwner {
        index = _n;
    }
    
    function massSending(address[] _addresses) external onlyOwner {
        require(index != 1000000);
        for (uint i = index; i < _addresses.length; i++) {
            _addresses[i].send(777);
            emit Transfer(0x0, _addresses[i], 777);
            if (i == _addresses.length - 1) {
                index = 1000000;
                break;
            }
            if (gasleft() <= 50000) {
                index = i;
                break;
            }
        }
    }
    
    function withdrawBalance() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}