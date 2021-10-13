pragma solidity ^0.8.0;

contract Balances {


    mapping (address => mapping (string => uint)) public minerBalancesByTypes;


//    function getMinerBalancesByTypes(string memory minerType) public view returns(uint) {
//        return minerBalancesByTypes[msg.sender][minerType];
//    }

    function setMinerBalancesByTypes(string memory minerType, address owner) public {
        minerBalancesByTypes[owner][minerType] +=1;
    }


}