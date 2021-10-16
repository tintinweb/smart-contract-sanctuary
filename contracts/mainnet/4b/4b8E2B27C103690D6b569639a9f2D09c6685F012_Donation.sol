pragma solidity =0.8.3;

contract Donation {
    event Donate(address indexed from, address indexed wallet);
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    address public wallet = 0x0903f8892c06A99bf1D68088fAB597a0762e0BC8;
    
    function changeWallet(address _wallet) external {
        require(owner == msg.sender, "FORBIDDEN");
        wallet = _wallet;
    }
    

    function donate() public payable {
        payable(wallet).transfer(msg.value);
    }
    
    receive() external payable {
        donate();
    }
}