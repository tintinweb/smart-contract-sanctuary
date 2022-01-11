/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

pragma solidity ^0.4.24;
contract class32
{
    address owner;

    constructor() public payable
    {
        owner = msg.sender;
    }    

    function querybalance1() public view returns(uint)
    {
        return owner.balance; //查詢餘額
    }

     function querybalance2() public view returns(uint)
    {
        return address(this).balance; //查詢合約的餘額
    }
    
    function send(uint money) public returns(bool)
    {
        bool reuslt = owner.send(money); //bool
        return reuslt;
    }
    
    function transfer(uint money) public 
    {
        owner.transfer(money); //轉幣，但無回傳值，失敗直接revert(沒收)
    }
}