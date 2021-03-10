/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

contract Task09 {

    enum Operator { Megafon, Beeline, MTS, TELE2, YOTA }
    
    struct User {
        uint number;
        uint balance;
        Operator operator;
    }

    User[] private users;

    event ChangeStruct(
        address indexed sender,
        uint indexed number,
        uint balance,
        Operator operator
    );
    
    function getOperatorKeyByValue(Operator _operator) internal pure returns (string memory) {
        
        require(uint8(_operator) <= 5);
            
        // Loop through possible options
        if (Operator.Megafon == _operator) return "Megafon";
        if (Operator.Beeline == _operator) return "Beeline";
        if (Operator.MTS == _operator) return "MTS";
        if (Operator.TELE2 == _operator) return "TELE2";
        if (Operator.YOTA == _operator) return "YOTA";
}
    
    function addUser(uint number, uint balance, Operator operator) external {
        (uint current_number, , ) = getUserByNumber(number);
        require (current_number == 0);
        
        users.push(User(number, balance, operator));
        emit ChangeStruct(msg.sender, number, balance, operator);
    }
    
    function getLength() external view returns(uint) { 
        return users.length;
    }
    
    function getUserByID(uint index) external view returns(uint, uint, string memory) {
        return (users[index-1].number, users[index-1].balance, getOperatorKeyByValue(users[index-1].operator));
    }
    
    function getUserByNumber(uint num) public view returns(uint, uint, string memory) { 
        for (uint i = 0; i<users.length; i++) {
            if (num == users[i].number) {
                return (users[i].number, users[i].balance, getOperatorKeyByValue(users[i].operator));
            }
        }    
    }
    
    function removeLast() external { 
        users.pop();
    }

    function removeIndex(uint index) external {
        if (index < users.length) {
            for (uint i = index; i<users.length-1; i++){
                users[i] = users[i+1];
            }
            users.pop();
        }
    }
    
    function updateUser(uint number, uint balance) external {
        for (uint i = 0; i<users.length; i++){
            if (users[i].number == number) {
                users[i].balance = balance;
            }
        }
    }
    
    function changeOperator(uint number, Operator operator) external {
        for (uint i = 0; i<users.length; i++){
            if (users[i].number == number) {
                users[i].operator = operator;
            }
        }
    }
    
    function increaseBalance() external {
        for (uint i = 0; i<users.length; i++){
            if (users[i].balance >= 0) {
                users[i].balance += 1;
            }
        }
    }
    
    function getSumOfAllBalances() public view returns(uint) {
        uint i = 0;
        uint sum = 0;
        while (i < users.length) {
            sum += users[i].balance;
            i++;
        }
        return sum;
    }
    
}