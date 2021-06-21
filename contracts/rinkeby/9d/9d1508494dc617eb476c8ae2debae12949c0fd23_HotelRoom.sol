/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

pragma solidity 0.8.4;

contract HotelRoom {

    enum Statuses {Vacant, Occupied}
    Statuses currentStatus;
    
    event Occupy(address _occupant, uint _value);

    address payable public owner;

    constructor() public {
        owner = payable(msg.sender);
        currentStatus = Statuses.Vacant;
    }
    
    modifier whenVacant{
        require(currentStatus == Statuses.Vacant, "Currently occupied");
        _;
    }
    
    modifier itCosts (uint _amount) {
        require(msg.value >= _amount, "Not enough balance");
        _;
    }

    receive() external payable whenVacant itCosts(2 ether){
        currentStatus = Statuses.Occupied;
        owner.transfer(msg.value);
        emit Occupy(msg.sender, msg.value);
    }
    
}