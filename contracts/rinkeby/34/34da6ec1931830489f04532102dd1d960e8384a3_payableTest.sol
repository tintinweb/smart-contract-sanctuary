/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

pragma solidity ^0.4.23;


contract  payableTest{

    function pay() public payable{

    }

     function getbalance() public view returns(uint){

        return address(this).balance;
    }

    function  getThis() public view returns(address){
        return this;
    }


    function getExternalBalance(address account) public view returns(uint){
        return account.balance;
    }


    function transfer() public payable{
        address account = 0xF966b84a37F9b64Ea588547C40dE23cb62eFa943;
        account.transfer(msg.value);
    }


     function transfer2() public payable{
        address(this).transfer(msg.value);
    }

    function ()  public payable{

    }

    function transfer3() public payable{
        address account = 0xF966b84a37F9b64Ea588547C40dE23cb62eFa943;
        account.transfer(10*10**18);
    }
}