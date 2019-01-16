pragma solidity >=0.4.22 <0.6.0;

contract officialBalance {
    address private owner;
    uint certifiedBalance;

    /* This constructor is executed at initialization and sets the owner of the contract */
    constructor() public { owner = msg.sender; }

    /* Function to recover the funds on the contract */
    function kill() public { if (msg.sender == owner) selfdestruct(msg.sender); }

    /* Modifier to ensure owner only actions are only performed by the owner */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /* Updates the certifiedBalance in the contract */
    function updateBalance(uint Balance) public onlyOwner {
        certifiedBalance = Balance;
    }
    
    /* Returns the certifiedBalance in the contract */
    function getBalance() public view returns (uint) {
        return certifiedBalance;
    }
    
}