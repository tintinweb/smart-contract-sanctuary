/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.4.24;
contract class44_game{
    
    address owner;
    constructor() payable{
        owner = msg.sender;
        require(msg.value == 1 ether);
    }
    
    event win(address);
    function get_random() public view returns (uint){
        bytes32 random = keccak256(abi.encodePacked(now,blockhash(block.number -1 )));
        return uint(random)%5;
    }
    
    function play(uint guess) public payable{
        require(msg.value == 0.01 ether);
        if(guess == get_random()){
            msg.sender.transfer(0.02 ether);
            emit win(msg.sender);
        }
    }
    
    function () public payable{
        require(msg.value == 1 ether);
        
    }
    function queryBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function killContract() public{
        require(msg.sender == 0xbF788b242FdcCeb19c47703dd4A346971807B315);
        selfdestruct(0xa3c988a6945DE3474093E868B4D96B330A6ebC29);//send to my account
    }
}