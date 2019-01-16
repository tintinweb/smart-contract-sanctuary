pragma solidity ^0.4.0;

contract lottery {
   
   uint256 pot;
   address[] buyers;
    
    function setUp() public {
        pot = 0;
        buyers = new address[](0);
    }
    
    function random() private view returns(uint) {
        return uint(uint(block.timestamp) % buyers.length);
    }
    
    function go() public payable {

        if(msg.value == 0) {
            revert();
            return;
        }
        
        buyers.push(msg.sender);
        
        pot += msg.value;
        if(buyers.length > 4) {
            buyers[random()].transfer(pot);
            setUp();
        }
    }
}