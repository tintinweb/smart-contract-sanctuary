/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity <=0.8.6;
contract pool {
    struct Record{
        address addr;
        uint price;
        uint time;
        bytes32 hash;
    }
    Record[] records;
    
    uint i = 0;
    receive() external payable{
        records[i]=Record({
           addr: msg.sender,
           price: msg.value,
           time: block.timestamp,
           hash: keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender)
        )});
        i++;
    }
    
    function getRecordByID(uint _id) public view returns(Record memory){
        return records[_id];
    }
    
    function getRecordHash(uint _id) public view returns(bytes32){
        return records[_id].hash;
    }
    
    uint maximum;
    constructor(uint _goal){
        maximum = _goal;
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function withdraw() public{
        if(getBalance()>maximum){
            selfdestruct(payable(msg.sender));
        }
    }
}