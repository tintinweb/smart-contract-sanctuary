contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}