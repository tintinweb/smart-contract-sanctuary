// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.0;

/**
 * @title HellBank
 * @dev You can only lose money
 * @author Lorenzo Zaccagnini
 */
contract HellBank {
    mapping(address => bool) public init;
    mapping(address => uint8) public debit;
    mapping(address => uint8) public credit;
    
    modifier checkInit(uint8 _num){
        require(init[msg.sender] == true, "must be greater than 0");
        require(_num > 0, "must be greater than 0");
        _;
    }
    
    function begin() external {
        debit[msg.sender] = 100;
        init[msg.sender] = true;
        credit[msg.sender] = 0;
    }

    function increaseDebit(uint8 _num) external checkInit(_num) {
        debit[msg.sender] = debit[msg.sender] + _num;
    }
    
    function decreaseCredit(uint8 _num) external checkInit(_num){
        require(_num > 0, "must be greater than 0");
        credit[msg.sender] = credit[msg.sender] - _num;
    }

    function retrieve() public view returns (uint8 _debit, uint8 _credit){
        return (debit[msg.sender], credit[msg.sender]);
    }
    
    function win() public view returns (bool win){
        if(debit[msg.sender] == 0 && credit[msg.sender] == 255) {
            return true;
        }
        else {
            return false;
        }
        return false;
    }
}