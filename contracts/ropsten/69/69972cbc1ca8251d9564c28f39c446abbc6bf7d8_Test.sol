/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity >=0.7.0 <0.8.0;
contract Test {
    uint data;
    
    function setData(uint newData) public{
        data = newData;
    }

    function getData() public returns(uint){
        
        return data;
    }    
    
    function getBlance( address adds ) public payable returns(uint ){
        require(msg.value % 2 == 0);
        return adds.balance;
    }    
    
}