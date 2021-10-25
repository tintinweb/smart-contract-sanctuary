/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Stupid_bank {
    mapping(address => Customer) _account;
    
    uint256 retentionPrice = ethToWei(1);
    uint256 retentionPeriod = 30;
    address owner = 0x6032692257DAb7a4DCbD153ece2a540F069208Fa;
    
    struct Customer {
        address addr;
        bool retention;
        uint256 retentionTime;
    }
    
    
    function retentionPay() public payable{
        require(_account[msg.sender].retention == false && msg.value >= retentionPrice , "Not possible");
        _account[msg.sender].retention = true;
        _account[msg.sender].retentionTime = block.timestamp + retentionPeriod;
    }
    
    function getRetention() public payable{
        require(_account[msg.sender].retention == true && block.timestamp >= _account[msg.sender].retentionTime, "You have to paid first!");
        payable(msg.sender).transfer(retentionPrice);
        _account[msg.sender].retention == false;
    }
    
    function takeRetention(address cus_addr) public payable{
        require(_account[cus_addr].retention == true, "Customer didnt paid retention");
        payable(owner).transfer(retentionPrice);
        _account[cus_addr].retention == false;
    }
    
    
    function ethToWei(uint256 eth_value) internal returns(uint256 ethwei){
        return uint256(eth_value * 1000000000000000000);
    }
    
    function weiToEth(uint256 wei_value) internal returns(uint256 weieth){
        return uint256(wei_value / 1000000000000000000);
    }
    function testtime() public view returns(uint256 time){
        return block.timestamp;
    }
    function testusertime() public view returns(uint256 potato2){
        return _account[msg.sender].retentionTime;
    }
}