pragma solidity =0.8.3;

contract Donation {
    event Donate(address indexed from, address indexed wallet);
    
    address public wallet = 0x0903f8892c06A99bf1D68088fAB597a0762e0BC8;
    

    function donate() public payable {
        payable(wallet).transfer(msg.value);
        
        emit Donate(msg.sender, wallet);
    }
    
    receive() external payable {
        donate();
    }
}