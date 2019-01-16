pragma solidity ^0.4.2;

contract test {
    //event multiplylog(address sender, uint indexed number, uint result);
    event multiplylog(address sender, string indexed testStr, uint result);
    //event memChangelog(uint mem);
    uint mem;
    
    constructor () public payable {}
    
    function multiply(uint a) public returns(uint d){
        uint result = a * 7;
        emit multiplylog(msg.sender, "hello,tester", result);
        return result;
    }
    
    function setMem(uint newMem) public {
        mem = newMem;
        //memChangelog(mem);
    }
    function getMem() public view returns(uint){
        return mem;
    }
    
    //合约给用户转账，指定amount
    function transferToUser(address to,uint amount) public payable {
        to.transfer(amount);
    }
    // 合约给用户转账，使用msg.value
    function userTransferUser(address to) public payable {
        to.transfer(msg.value);
    }
    function getBalance(address user) public view returns (uint) {
        return user.balance;
    }
    function getMsgSender() public view returns(address, uint){
        return (msg.sender,6);
    }
    
    function returnString() public returns(string){
        //string public str1;
        //return str1;
        return "stringTest1foralongStringMorethan32Byte41";
    }
    
    function returnMixType() public returns(uint, string){
        uint a3 = 666;
        return (a3,"stringTest2forMixTypeReturn");
    }
    
    function getTxOrigin() public returns(address){
        return tx.origin;
    }
}