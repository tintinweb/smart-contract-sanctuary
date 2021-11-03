/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >= 0.8.7;
 
contract Bank
{
    bytes32 password; // Я всё ещё считаю, что пароль следует хешировать-с.
    uint id;
    int balance;
    int last_transaction;
    int8 ALERT;
    string comment;
    uint8 count;
    
    /*
    
    По поводу "программа ваша, улучшайте что хотите":
    
    После трёх неверных попыток ввода пароля происходит деление на ноль,
    чтобы опрокинуть программу и чтобы не дать хакеру подобрать пароль.
    
    После корректно введённого пароля кол-во возможных попыток снова
    становится равно трём.
    */
    
    function check_master(uint id_value, uint password_value) private
    returns (bool)
    {
        if (count >= 3)
            return bool(ALERT / ALERT == 0);
        if (id == id_value && password == keccak256(abi.encodePacked(password_value)))
        {
            count = 0;
            return true;
        }
        count = count + 1;
        return false;
    }
    
    constructor (uint id_value, uint password_value, int money_value)
    {
        balance = money_value;
        id = id_value;
        password = keccak256(abi.encodePacked(password_value));
        ALERT = 0;
        count = 0;
    }
    
    function setBalance(int summ, string memory info) private
    {
        balance += summ;
        last_transaction = summ;
        comment = info;
    }
    
    // Задание кривое. Не сказано, что делать с функцией buy и откуда ей брать
    // информацию, куда идут деньги. Поэтому я сделал так, чтобы все покупки
    // подписывались как 'shopping'.
    function buy(uint id_value, uint password_value, uint summ) public
    {
        if (check_master(id_value, password_value))
        {
            setBalance(-int(summ), "BUING"); // Так как идёт покупка, сумма снимается.
        }
    }
    
    function transfer(uint summ, string memory info) public
    {
        setBalance(int(summ), info);
    }
    
    function change_passord(uint id_value, uint password_value, uint new_password, uint new_password_copy) public
    {
        if (check_master(id_value, password_value) && keccak256(abi.encodePacked(new_password_copy)) == keccak256(abi.encodePacked(new_password)))
            password = keccak256(abi.encodePacked(new_password));
    }
    
    
    function getLastOperation(uint id_value, uint password_value) public
    returns (int, string memory)
    {
        if (check_master(id_value, password_value))
        {
            return (last_transaction, comment); // Так как идёт покупка, сумма снимается.
        }
    }
    
    function getBalance(uint id_value, uint password_value) public
    returns (int)
    {
        
        if (check_master(id_value, password_value))
        {
            return balance; // Так как идёт покупка, сумма снимается.
        }
    }
}