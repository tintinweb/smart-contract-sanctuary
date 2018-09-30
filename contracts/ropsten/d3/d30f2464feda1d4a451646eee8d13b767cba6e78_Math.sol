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
    function Addition(uint256 first, uint256 last) public view returns (uint256){
        uint256 a;
        a = first+last;
        return a;
    }
    function Subtraction(uint256 first, uint256 last) {}
    function Multiplication(uint256 frst, uint256 last) {}
    function Division(uint256 first, uint256 last) {}
}