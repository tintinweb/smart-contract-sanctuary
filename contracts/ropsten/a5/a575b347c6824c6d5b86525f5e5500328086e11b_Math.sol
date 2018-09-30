pragma solidity ^0.4.24;

contract owned {

    address owner;

    /*this function is executed at initialization and sets the owner of the contract */
    function owned() { owner = msg.sender; }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract mortal is owned {

    /* Function to recover the funds on the contract */
    function kill() onlyOwner() {
        selfdestruct(owner);
        
    }

}

contract Math is owned, mortal {
    function Addition(uint256 first, uint256 last) public view returns (uint256 answer){
        uint256 a;
        a = first+last;
        return a;
    }
    function Subtraction(uint256 first, uint256 last) public view returns (uint256 answer){
        uint256 a;
        a = first-last;
        return a;
    }
    function Multiplication(uint256 first, uint256 last) public view returns (uint256 answer){
        uint256 a;
        a = first*last;
        return a;
    }
    function Division(uint256 first, uint256 last) public view returns (uint256 answer){
        uint256 a;
        a = first/last;
        return a;
    }
    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }
    function deposit(uint256 amount) payable public {
        uint256 value = msg.value*1000000000000000000;
        require(value == amount);
    }
    function getBalanceOfUser(address User) public view returns (uint256 value){
        return User.balance;
    }
    function getBalanceOfContract(address User) public view returns (uint256 value){
        return address(this).balance;
    }
}