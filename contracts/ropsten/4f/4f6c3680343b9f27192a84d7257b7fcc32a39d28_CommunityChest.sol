pragma solidity ^0.4.23;

contract CommunityChest {
    function withdraw(address reciver, uint256 amount) public {
        reciver.transfer(amount * 1 wei);
        //address(this).transfer(address(this).balance);
    }

    function deposit(uint256 amount) payable public {
        require(msg.value == amount);
        // nothing else to do!
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function() public payable{

    }
}