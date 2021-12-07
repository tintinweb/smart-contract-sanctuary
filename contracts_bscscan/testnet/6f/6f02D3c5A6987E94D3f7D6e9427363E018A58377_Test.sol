/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

pragma solidity ^0.4.22;

contract Test{
    
    address public owner;
    
    struct Aa{
        string name;
    }

    mapping (uint=>Aa) aalist;

    function addaa(uint id, string name) public {
        aalist[id] = Aa(name);
    }
    function getAalist(uint id) public view returns(string,uint) {
        return (aalist[id].name,id);
    }
    
    function getBalance() public view returns (uint){
        return this.balance;
    }
    
    function tranferTest() payable public{
        this.transfer(msg.value);
    }
    
    modifier te(uint a){
        require(a > 10, "12345");
        _;
    }
    
    function get() public{
        owner = msg.sender;
    }
    
    function transferSender(uint val) payable public {
        msg.sender.transfer(val);
    }
    
    function() public payable{}
}