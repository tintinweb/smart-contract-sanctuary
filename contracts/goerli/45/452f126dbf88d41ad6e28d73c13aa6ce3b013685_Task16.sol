/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface CellOperatorsInterface {
    function getUserByNumber(uint num) external view returns(uint, uint, string memory);
    function updateUser(uint number, uint balance) external;
}

contract Task16 {
    CellOperatorsInterface cellOperatorsContract;
    uint master_number;

    function setCellOperatorsContractConfig(address _address, uint _new_master_number) external{
        cellOperatorsContract = CellOperatorsInterface(_address);
        master_number = _new_master_number;
    }
        
    function putMoneyIntoAccount(uint number, uint money) external {
        (uint current_number, uint balance, ) = cellOperatorsContract.getUserByNumber(number);
        (, uint master_balance, ) = cellOperatorsContract.getUserByNumber(master_number);
        require (current_number == 0 || number > 0, "Wrong number");
        uint fee;
        if ((balance < 10) && (money >= 100)) {
        //Special offer fee - 5%
            fee = master_balance + (money / 20);
        }
        else {
        //Standard fee - 10%
            fee = master_balance + (money / 10);
        }
        money = money - fee + balance;
        
        cellOperatorsContract.updateUser(number, money);
        cellOperatorsContract.updateUser(master_number, fee);
    }
}