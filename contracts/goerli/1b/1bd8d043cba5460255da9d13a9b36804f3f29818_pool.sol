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
    }
    Record[] records;
    uint i = 0;
    receive() external payable{
        records[i]=Record({
           addr: msg.sender,
           price: msg.value,
           time: block.timestamp
        });
        i++;
    }
    
    uint maximum = 100;
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function withdraw() public{
        if(getBalance()>maximum){
            selfdestruct(payable(msg.sender));
        }
    }
}