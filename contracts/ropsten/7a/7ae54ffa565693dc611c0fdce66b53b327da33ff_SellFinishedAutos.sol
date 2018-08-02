pragma solidity ^0.4.0;
contract SellFinishedAutos {
    address owner;
    uint public autos;
    uint constant price = 1 ether;
    mapping (address => uint) public purchasers;
    
    function SellFinishedAutos() {
        owner = msg.sender;
        autos = 5;

    }
    function() payable {
        buyAutos(1);
    
    }
    function buyAutos(uint amount) payable {
        if (msg.value != ( amount * price) || amount > autos) {
            throw;
        }
       purchasers[msg.sender] += amount;
       autos -= amount;
       
        if ( autos == 0){
            selfdestruct(owner);
        }
        }
}