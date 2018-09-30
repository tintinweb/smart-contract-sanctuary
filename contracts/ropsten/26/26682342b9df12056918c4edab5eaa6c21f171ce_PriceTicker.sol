pragma solidity ^0.4.20;
contract Owned {

    address public owner;
    address newOwner;

    modifier only(address _allowed) {
        require(msg.sender == _allowed);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) only(owner) public {
        newOwner = _newOwner;
    }

    function acceptOwnership() only(newOwner) public {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);

}

contract PriceTicker is Owned {

    uint public ethJOT;
    uint public updatedTimestamp;

    event NewPrice(uint _price);

    function constructor() {}

    function updatePrice(uint _ethJOT) only(owner) {
        //some error checks
		require(_ethJOT !=0);
        ethJOT = _ethJOT;
        updatedTimestamp = now;
        emit NewPrice(_ethJOT);
	}


}