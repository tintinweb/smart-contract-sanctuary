pragma solidity ^0.4.23;

contract Product {
    uint256 test = 0;
    address sale;

    function setSaleAddr (address addr) public {
        sale = addr;
    }

    function setTest(uint256 num) public {
        require(msg.sender == sale);

        test = num;
    }

    function getTest() public view returns(uint256){
        return test;
    }
}