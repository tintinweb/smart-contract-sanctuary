pragma solidity 0.5.2;

contract Merunas {
    address payable public owner = msg.sender;
    
    function () external {}
    function receiveDonation() public payable {}
    function extractFunds() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
    function showBalance() public view returns(uint256) {
        return address(this).balance;
    }
}