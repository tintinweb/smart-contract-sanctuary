pragma solidity ^0.4.24;

interface fetch {
    function getNum(uint num) external returns(uint);
}

contract NumContract {

    address public dataContract;
    constructor(address setAddr) public {
        dataContract = setAddr;
    }

    function getNumData(uint num) public view returns(uint) {
        fetch someData = fetch(dataContract);
        uint fetchNum = someData.getNum(num);
        return fetchNum;
    }

}