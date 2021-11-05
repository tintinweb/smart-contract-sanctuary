pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier IsOwner() {
        require(msg.sender == owner, "You're not the owner");
        _;
    }
}

contract HotelRoom is Ownable {
    //address public owner;

    constructor() {
        //    super;
    }

    enum Statuses {
        Vacant,
        Occupied
    }
    Statuses currentStatus;

    struct People {
        string Name;
        address Address;
    }

    People[] person;

    modifier IsVacant() {
        require(currentStatus == Statuses.Vacant, "Room is already booked");
        _;
    }

    modifier Cost(uint256 _amount) {
        require(msg.value > _amount, "Not Enough Money");
        _;
    }

    event Occupy(address _occupant, uint256 _value);

    function Book(string memory _Name, address _Address)
        public
        payable
        IsVacant
        IsOwner
        Cost(10 wei)
    {
        payable(owner).transfer(msg.value);
        currentStatus = Statuses.Occupied;
        person.push(People(_Name, _Address));
        emit Occupy(msg.sender, msg.value);
    }

    function ViewPeople() public view returns (People[] memory) {
        return person;
    }

    function ShowBalance() public view returns (uint256) {
        return address(owner).balance;
    }
}