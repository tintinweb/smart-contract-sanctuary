/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

contract Ticket {
    
    uint256 ticketPrice = 0.001 ether;
    address owner;
    mapping (address => uint256) public ticketHolders;
    
    constructor() {
        owner = msg.sender; 
    }
    
    modifier onlyOwner() {
    require(msg.sender == owner, "You are not the owner");
    _;
    }
    
    function buyTickets(address _user, uint256 _amount) payable public {
        require(msg.value >= _amount*ticketPrice, "You need to cover the cost of tickets");
        addTickets(_user, _amount);
    }
    
      function useTickets(address _user, uint256 _amount) public {
        substractTickets(_user, _amount);
    }
    
    function addTickets(address _user, uint256 _amount) internal {
        ticketHolders[_user] = ticketHolders[_user] + _amount;
    }
    
    function substractTickets(address _user, uint256 _amount) internal {
         require(ticketHolders[_user] >= _amount, "you don't have that many tickets");
         ticketHolders[_user] = ticketHolders[_user] - _amount;
    }
    
    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success);
    }
}