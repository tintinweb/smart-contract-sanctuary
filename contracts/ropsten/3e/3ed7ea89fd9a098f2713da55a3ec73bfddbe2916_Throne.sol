pragma solidity ^0.4.22;

contract Throne {
    address public king;

    event LogKingChanged(address indexed previousKing, address indexed newKing, uint deposit);

    constructor() payable public {
        king = msg.sender;
    }

    function capture() payable public {
        // msg.value that was sent is already counted in this.balance.
        // We want balanceBefore + msg.value == this.balance => balanceBefore == this.balance - msg.value
        // We want msg.value > before => msg.value > this.balance - msg.value => this.balance < 2 * msg.value
        require(address(this).balance < 2 * msg.value);
        address previousKing = king;        
        king = msg.sender;
        emit LogKingChanged(previousKing, msg.sender, msg.value);
        previousKing.transfer(address(this).balance - msg.value);
    }
    
    function getBalanceInRemix(address who) public view returns(uint) {
        return who.balance;
    }
}


// In-browser address of yours



// Ropsten address of yours