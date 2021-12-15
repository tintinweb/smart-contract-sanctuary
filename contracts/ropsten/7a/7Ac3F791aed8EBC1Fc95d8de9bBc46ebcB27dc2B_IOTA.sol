/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity ^0.8.9;      


contract IOTA {
    address private admin;
    mapping (address=>bool) public machine;                                
    uint256[7][5] public cof;    //7 дней недели, 5 видов кофэ

    constructor(address[] memory machines) {
        admin = msg.sender;
        for (uint256 i = 0; i < machines.length; i++) {
            machine[machines[i]] = true; 
        }
    }

    modifier onlyMachine() { 
        require(machine[msg.sender] == true);  
        _; 
    } 

    modifier onlyAdmin() { 
        require(msg.sender == admin);  
        _; 
    } 

    //основные функции: покупка и очистка массива
    function purchase(uint8 day, uint8 kind) onlyMachine() public {
        cof[day][kind] += 1;
    }

    function clear() onlyAdmin() public {
        delete cof;
    }

    //геттеры
    function getByDay(uint8 day) public view returns (uint256,uint256,uint256,uint256,uint256) {
        return(cof[day][0], cof[day][1], cof[day][2], cof[day][3], cof[day][4]);
    }

    function getByWeek() public view returns (uint256[7][5] memory) {
        return cof;
    }

}