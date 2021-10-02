/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Bank{
    // uint _balance;
    
    // 0xc822207dEbB0B26496Ffa324c8bCDE5b29a4ac58
    // get balance by address
    mapping(address  => uint) _balances;
    uint _totalSupply;
    // ສາມາດຝາກເງີນທີ່ເປ  ETH ເຂົ້າມາໄດ້
    function deposit() public payable{
       
        _balances[msg.sender] +=  msg.value;
        _totalSupply +=  msg.value;
    }
    
    function withdraw(uint amount) public payable{
        require(amount<= _balances[msg.sender], "not enough money");
        //ສົ່ງເງີນທີ່ເປັນ ETH ຄືນ address ທີ່ຝາກເຂົ້າມາ
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
    }
    
    function check_balance()public view returns (uint balance){
        // return _balance;
        return _balances[msg.sender];
    }
    
    function check_totalsupply() public view returns(uint totalSupply){
        return _totalSupply;
    }
}